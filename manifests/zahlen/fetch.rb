# Pulls the App Store Connect reports of all Seb-IT apps into DATA_DIR/raw and
# renders DATA_DIR/site/data.json, which the static dashboard reads.
#
# Standard library only, so it runs on the plain ruby image without a gem
# install (same reasoning as rpi5-fan: no build chain, no registry).
#
# Why the raw reports are archived instead of just the totals: Apple keeps
# daily reports for 365 days, monthly ones for 12 months and analytics report
# instances for roughly 35 days. Only the archive lets the history grow past
# that. Yearly sales reports stay available indefinitely and fill in what
# happened before the oldest archived day.
#
# Every fetch is idempotent: a file that exists is not fetched again, except
# for the last few days, which are re-read in case Apple completed them late.
# The job exits 1 on unexpected API errors so KubeJobFailed reports it, but
# writes data.json first with whatever it has.
require 'date'
require 'digest'
require 'fileutils'
require 'json'
require 'net/http'
require 'openssl'
require 'stringio'
require 'time'
require 'zlib'

DATA = ENV.fetch('DATA_DIR', '/data')
RAW = File.join(DATA, 'raw')
SITE = File.join(DATA, 'site')
VENDOR = ENV.fetch('ASC_VENDOR_NUMBER')
FIRST_YEAR = Integer(ENV.fetch('FIRST_YEAR', '2025'))
FIXED_COSTS_EUR_PER_YEAR = Float(ENV.fetch('FIXED_COSTS_EUR_PER_YEAR', '99'))
# Re-read this many recent days every run, even when the file exists.
REFRESH_DAYS = 3
ANALYTICS_REPORTS = ENV.fetch('ANALYTICS_REPORTS', [
  'App Downloads Standard',
  'App Downloads Detailed',
  'App Store Discovery and Engagement Standard',
  'App Store Discovery and Engagement Detailed',
  'App Store Installation and Deletion Standard',
  'App Sessions Standard',
  'App Crashes'
].join('|')).split('|').map(&:strip)

TODAY = Time.now.utc.to_date
$errors = []
$stats = Hash.new(0)

# stdout is a pipe in the pod, which Ruby block-buffers: without this,
# kubectl logs shows nothing until the run ends, and nothing at all when the
# job is killed at its deadline.
$stdout.sync = true

def log(msg) = puts("[#{Time.now.utc.strftime('%H:%M:%S')}] #{msg}")

def error(msg)
  $errors << msg
  log("FEHLER: #{msg}")
end

# --- App Store Connect access -------------------------------------------------

# pack instead of the base64 library, which is only a bundled gem since 3.4.
def b64url(bytes) = [bytes].pack('m0').tr('+/', '-_').delete('=')

# ES256 needs the raw r||s signature; OpenSSL hands out DER, so it is unpacked
# here instead of pulling in a JWT gem.
def asc_token
  return @token if @token && Time.now < @token_until

  key = OpenSSL::PKey.read(File.read(ENV.fetch('ASC_KEY_PATH')))
  now = Time.now.to_i
  head = b64url({ alg: 'ES256', kid: ENV.fetch('ASC_KEY_ID'), typ: 'JWT' }.to_json)
  body = b64url({ iss: ENV.fetch('ASC_ISSUER_ID'), iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' }.to_json)
  der = key.sign(OpenSSL::Digest.new('SHA256'), "#{head}.#{body}")
  sig = OpenSSL::ASN1.decode(der).value.map { |i| i.value.to_s(2).rjust(32, "\0")[-32, 32] }.join
  @token_until = Time.now + 900
  @token = "#{head}.#{body}.#{b64url(sig)}"
end

# Returns [status, body]. Retries throttling and server errors; everything else
# is the caller's business, because a 404 means very different things per
# endpoint.
def http_get(url, accept: 'application/json', auth: true)
  uri = URI(url.start_with?('http') ? url : "https://api.appstoreconnect.apple.com#{url}")
  4.times do |attempt|
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{asc_token}" if auth
    req['Accept'] = accept
    begin
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 20, read_timeout: 120) { |h| h.request(req) }
    rescue StandardError => e
      raise if attempt == 3

      log("  Netzwerkfehler (#{e.class}), neuer Versuch")
      sleep(5 * (attempt + 1))
      next
    end
    $stats[:requests] += 1
    code = res.code.to_i
    return [code, res.body.to_s] unless code == 429 || code >= 500

    log("  HTTP #{code}, neuer Versuch") if attempt < 3
    sleep(10 * (attempt + 1))
    return [code, res.body.to_s] if attempt == 3
  end
end

def api_detail(body)
  JSON.parse(body)['errors'].map { |e| e['detail'] }.join('; ')
rescue StandardError
  body.to_s[0, 200]
end

def api_json(path)
  code, body = http_get(path)
  raise "#{path}: HTTP #{code} #{api_detail(body)}" unless code == 200

  JSON.parse(body)
end

# Follows links.next until the collection is complete.
def api_all(path)
  items = []
  while path
    page = api_json(path)
    items.concat(page['data'] || [])
    path = page.dig('links', 'next')
  end
  items
end

def write_atomic(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  tmp = "#{path}.tmp"
  File.binwrite(tmp, content)
  File.rename(tmp, path)
end

def gunzip(bytes) = Zlib::GzipReader.new(StringIO.new(bytes)).read

# --- Sales reports ----------------------------------------------------------

def sales_query(frequency, date, version)
  URI.encode_www_form('filter[frequency]' => frequency, 'filter[reportDate]' => date,
                      'filter[reportSubType]' => 'SUMMARY', 'filter[reportType]' => 'SALES',
                      'filter[vendorNumber]' => VENDOR, 'filter[version]' => version)
end

# 200 = report, 404 "no sales" = a real day with nothing in it (kept as a
# .none marker so it reads as zero, not as missing), 404 "not available yet" =
# ask again next run, 410 = Apple dropped it already.
def fetch_sales(kind, date_str, version, file_base, refresh: false)
  gz = "#{file_base}.tsv.gz"
  none = "#{file_base}.none"
  return :cached if !refresh && (File.exist?(gz) || File.exist?(none))

  code, body = http_get("/v1/salesReports?#{sales_query(kind, date_str, version)}", accept: 'application/a-gzip')
  detail = code == 200 ? '' : api_detail(body)
  if code == 200
    write_atomic(gz, body)
    FileUtils.rm_f(none)
    :fetched
  elsif code == 404 && detail.include?('no sales')
    write_atomic(none, '')
    FileUtils.rm_f(gz)
    :none
  elsif code == 404 && detail.include?('not available yet')
    :pending
  elsif code == 410
    :gone
  else
    error("Verkaufsbericht #{kind} #{date_str}: HTTP #{code} #{detail}")
    :error
  end
end

def fetch_all_sales
  log('Verkaufsberichte (täglich) ...')
  counts = Hash.new(0)
  (TODAY - 365..TODAY - 1).each do |day|
    r = fetch_sales('DAILY', day.iso8601, '1_1', File.join(RAW, 'sales', 'daily', day.iso8601),
                    refresh: day >= TODAY - REFRESH_DAYS)
    counts[r] += 1
  end
  log("  #{counts.map { |k, v| "#{k}=#{v}" }.join(' ')}")

  log('Verkaufsberichte (jährlich) ...')
  (FIRST_YEAR...TODAY.year).each do |year|
    r = fetch_sales('YEARLY', year.to_s, '1_0', File.join(RAW, 'sales', 'yearly', year.to_s))
    log("  #{year}: #{r}")
  end
end

# --- Finance reports ----------------------------------------------------------

# Finance reports are keyed by Apple's fiscal calendar: "2026-11" is fiscal
# year 2026, period 11, which is August 2026. The fiscal year starts at the end
# of September. The exact dates come from the report itself; this estimate only
# decides whether a period can exist yet.
def fiscal_period_start_estimate(fy, period) = Date.new(fy - 1, 9, 27) + ((period - 1) * 30.4).round

def fetch_all_finance
  log('Finanzberichte ...')
  counts = Hash.new(0)
  current_fy = TODAY >= Date.new(TODAY.year, 9, 27) ? TODAY.year + 1 : TODAY.year
  (FIRST_YEAR..current_fy).each do |fy|
    (1..12).each do |period|
      start = fiscal_period_start_estimate(fy, period)
      next if start > TODAY

      key = format('%04d-%02d', fy, period)
      base = File.join(RAW, 'finance', "#{key}_FINANCE_DETAIL_Z1")
      if File.exist?("#{base}.tsv.gz") || File.exist?("#{base}.none")
        counts[:cached] += 1
        next
      end
      q = URI.encode_www_form('filter[regionCode]' => 'Z1', 'filter[reportDate]' => key,
                              'filter[reportType]' => 'FINANCE_DETAIL', 'filter[vendorNumber]' => VENDOR)
      code, body = http_get("/v1/financeReports?#{q}", accept: 'application/a-gzip')
      if code == 200
        write_atomic("#{base}.tsv.gz", body)
        counts[:fetched] += 1
      elsif code == 404
        # Old periods without a report had no proceeds; recent ones are just
        # not closed yet and get asked again.
        if start + 120 < TODAY
          write_atomic("#{base}.none", '')
          counts[:none] += 1
        else
          counts[:pending] += 1
        end
      else
        error("Finanzbericht #{key}: HTTP #{code} #{api_detail(body)}")
      end
    end
  end
  log("  #{counts.map { |k, v| "#{k}=#{v}" }.join(' ')}")
end

# --- Exchange rates -----------------------------------------------------------

# Apple pays out at its own rates and the API does not expose them, so EUR
# amounts are converted with the ECB reference rates (free, no key). The full
# history is fetched once, the 90-day file on every run.
ECB = 'https://www.ecb.europa.eu/stats/eurofxref'

def fetch_fx
  log('EZB-Kurse ...')
  full = File.join(RAW, 'fx', 'eurofxref-hist.xml')
  { full => "#{ECB}/eurofxref-hist.xml", File.join(RAW, 'fx', 'eurofxref-hist-90d.xml') => "#{ECB}/eurofxref-hist-90d.xml" }.each do |path, url|
    next if path == full && File.exist?(path)

    code, body = http_get(url, accept: 'application/xml', auth: false)
    if code == 200 && body.include?('<Cube time=')
      write_atomic(path, body)
    else
      error("EZB-Kurse #{File.basename(path)}: HTTP #{code}")
    end
  end
end

def load_fx
  rates = {}
  Dir[File.join(RAW, 'fx', '*.xml')].sort.each do |path|
    File.read(path).scan(%r{<Cube time="(\d{4}-\d{2}-\d{2})">(.*?)</Cube>}m) do |day, inner|
      rates[day] = inner.scan(/currency="([A-Z]{3})" rate="([\d.]+)"/).to_h { |c, r| [c, r.to_f] }.merge('EUR' => 1.0)
    end
  end
  days = rates.keys.sort
  { rates: rates, days: days }
end

# Currencies the ECB does not publish but that are pegged to the US dollar
# (units per USD). Apple pays proceeds in several of them.
USD_PEGS = { 'SAR' => 3.75, 'AED' => 3.6725, 'QAR' => 3.64, 'BHD' => 0.376, 'OMR' => 0.3845, 'JOD' => 0.709 }.freeze

# Rate for a calendar day, falling back to the last ECB business day before it.
# Returns nil for a currency without a rate; the caller keeps those amounts
# apart instead of pretending they are zero.
def eur(fx, amount, currency, day)
  return amount if currency == 'EUR'
  return nil if fx[:days].empty?

  iso = day.iso8601
  idx = fx[:days].bsearch_index { |d| d > iso }
  idx = idx.nil? ? fx[:days].size - 1 : idx - 1
  return nil if idx.negative?

  rates = fx[:rates][fx[:days][idx]]
  rate = rates[currency] || (USD_PEGS[currency] && rates['USD'] && USD_PEGS[currency] * rates['USD'])
  rate ? amount / rate : nil
end

# --- Analytics reports --------------------------------------------------------

def slug(name) = name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')

def fetch_analytics(apps)
  log('Analytics-Berichte ...')
  apps.each do |app|
    api_all("/v1/apps/#{app[:id]}/analyticsReportRequests").each do |request|
      api_all("/v1/analyticsReportRequests/#{request['id']}/reports?limit=200").each do |report|
        name = report.dig('attributes', 'name').to_s.strip
        next unless ANALYTICS_REPORTS.include?(name)

        dir = File.join(RAW, 'analytics', app[:id], slug(name))
        api_all("/v1/analyticsReports/#{report['id']}/instances?filter[granularity]=DAILY&limit=200").each do |inst|
          stem = "#{inst.dig('attributes', 'processingDate')}_#{inst['id']}"
          next if Dir[File.join(dir, "#{stem}_*")].any?

          api_all("/v1/analyticsReportInstances/#{inst['id']}/segments").each_with_index do |seg, i|
            # The segment URL is pre-signed; an Authorization header breaks it.
            code, body = http_get(seg.dig('attributes', 'url'), accept: '*/*', auth: false)
            if code != 200
              error("Analytics #{app[:name]} / #{name}: Segment HTTP #{code}")
              next
            end
            sum = seg.dig('attributes', 'checksum')
            if sum && Digest::MD5.hexdigest(body) != sum
              error("Analytics #{app[:name]} / #{name}: Prüfsumme stimmt nicht")
              next
            end
            write_atomic(File.join(dir, "#{stem}_#{i}.csv.gz"), body)
            $stats[:analytics_segments] += 1
          end
        end
      end
    end
  rescue StandardError => e
    error("Analytics #{app[:name]}: #{e.message}")
  end
  log("  neue Segmente: #{$stats[:analytics_segments]}")
end

# --- Aggregation --------------------------------------------------------------

# Product type identifiers from Apple's sales report reference. The platform
# comes from the Device column instead: with Universal Purchase a Mac download
# of an iOS app arrives as type 1F with device "Desktop". "1-B" is an app
# bundle purchase; it carries the bundle's own Apple ID and is kept as an entry
# of its own, since its proceeds are not split across the member apps.
FIRST = %w[1 1F 1T 1E 1EP 1EU F1 1-B].freeze
REDOWNLOAD = %w[3 3F 3T F3].freeze
UPDATE = %w[7 7F 7T F7].freeze
IAP = %w[IA1 IA9 IAY IAC FI1 IA1-M IA9-M IAY-M].freeze

def platform(device)
  case device.to_s
  when 'Desktop' then :mac
  when /iPhone|iPad|iPod/ then :ios
  else :other
  end
end

def parse_tsv(text)
  rows = text.lines.map { |l| l.chomp.split("\t", -1) }
  head = rows.shift || []
  [head, rows]
end

# Reads one sales report into rows of
#   [day, app_id, country, ios, mac, other, redownloads, updates, iap, promo, proceeds_eur]
# keyed by the report's own Begin Date for daily reports.
def sales_rows(text, fx, sku_to_app, fallback_day)
  head, rows = parse_tsv(text)
  col = ->(n) { head.index(n) }
  c = %w[SKU Product\ Type\ Identifier Units Developer\ Proceeds Country\ Code Currency\ of\ Proceeds
         Apple\ Identifier Promo\ Code Parent\ Identifier Device Begin\ Date].to_h { |n| [n, col.(n)] }
  missing = c.select { |_, v| v.nil? }.keys
  raise "Spalten fehlen: #{missing.join(', ')}" unless missing.empty?

  out = Hash.new { |h, k| h[k] = Array.new(8, 0.0) }
  unconverted = Hash.new(0.0)
  rows.each do |r|
    next if r.size < head.size - 2

    type = r[c['Product Type Identifier']].strip
    units = r[c['Units']].to_i
    app = if IAP.include?(type)
            sku_to_app[r[c['Parent Identifier']].strip]
          else
            r[c['Apple Identifier']].strip
          end
    next if app.nil? || app.empty?

    day = (Date.strptime(r[c['Begin Date']], '%m/%d/%Y') rescue fallback_day)
    key = [day.iso8601, app, r[c['Country Code']].strip]
    v = out[key]
    if FIRST.include?(type)
      v[{ ios: 0, mac: 1, other: 2 }[platform(r[c['Device']])]] += units
      v[6] += units unless r[c['Promo Code']].strip.empty?
    elsif REDOWNLOAD.include?(type) then v[3] += units
    elsif UPDATE.include?(type) then v[4] += units
    elsif IAP.include?(type) then v[5] += units
    end
    proceeds = units * r[c['Developer Proceeds']].to_f
    next if proceeds.zero?

    currency = r[c['Currency of Proceeds']].strip
    amount = eur(fx, proceeds, currency, day)
    if amount
      v[7] += amount
    else
      unconverted[currency] += proceeds
    end
  end
  [out, unconverted]
end

# What the sales reports know about the catalogue: SKU -> app, in-app purchase
# -> parent app (finance reports list an in-app purchase under its own ID),
# and titles for IDs the apps endpoint does not return, such as bundles.
def collect_catalog
  sku_to_app = {}
  iap_rows = []
  titles = {}
  bundles = []
  Dir[File.join(RAW, 'sales', '{daily,yearly}', '*.tsv.gz')].sort.each do |path|
    head, rows = parse_tsv(gunzip(File.binread(path)))
    c = %w[SKU Apple\ Identifier Product\ Type\ Identifier Parent\ Identifier Title].to_h { |n| [n, head.index(n)] }
    next if c.values.any?(&:nil?)

    rows.each do |r|
      next if r.size < head.size - 2

      type, id = r[c['Product Type Identifier']].strip, r[c['Apple Identifier']].strip
      if IAP.include?(type)
        iap_rows << [id, r[c['Parent Identifier']].strip]
      else
        sku_to_app[r[c['SKU']].strip] = id
        titles[id] = r[c['Title']].strip
        bundles << id if type == '1-B'
      end
    end
  end
  iap_to_app = iap_rows.to_h { |id, parent| [id, sku_to_app[parent]] }.compact
  { sku_to_app: sku_to_app, iap_to_app: iap_to_app, titles: titles, bundles: bundles.uniq }
end

def aggregate_sales(fx, sku_to_app)
  daily = {}
  unconverted = Hash.new(0.0)
  daily_days = []
  Dir[File.join(RAW, 'sales', 'daily', '*.{tsv.gz,none}')].sort.each do |path|
    day = Date.iso8601(File.basename(path)[0, 10])
    daily_days << day
    next if path.end_with?('.none')

    rows, unc = sales_rows(gunzip(File.binread(path)), fx, sku_to_app, day)
    daily.merge!(rows) { |_, a, b| a.zip(b).map(&:sum) }
    unc.each { |k, v| unconverted[k] += v }
  rescue StandardError => e
    error("#{File.basename(path)}: #{e.message}")
  end

  # Yearly totals minus the archived days of the same year leave what happened
  # before the archive started. A yearly report does not split by day, so its
  # rows carry the year's first day and are summed per app.
  residual = Hash.new { |h, k| h[k] = Array.new(8, 0.0) }
  Dir[File.join(RAW, 'sales', 'yearly', '*.tsv.gz')].sort.each do |path|
    year = File.basename(path)[0, 4].to_i
    rows, = sales_rows(gunzip(File.binread(path)), fx, sku_to_app, Date.new(year, 1, 1))
    rows.each { |(_, app, _), v| residual[[year, app]] = residual[[year, app]].zip(v).map(&:sum) }
    daily.each do |(d, app, _), v|
      next unless d.start_with?(year.to_s)

      residual[[year, app]] = residual[[year, app]].zip(v).map { |a, b| a - b }
    end
  rescue StandardError => e
    error("#{File.basename(path)}: #{e.message}")
  end
  [daily, residual, unconverted, daily_days]
end

def aggregate_finance(fx, iap_to_app)
  periods = []
  Dir[File.join(RAW, 'finance', '*_FINANCE_DETAIL_Z1.tsv.gz')].sort.each do |path|
    key = File.basename(path)[0, 7]
    lines = gunzip(File.binread(path)).lines.map { |l| l.chomp.split("\t", -1) }
    start = Date.strptime(lines.find { |l| l[0] == 'Start Date' }[1], '%m/%d/%Y')
    finish = Date.strptime(lines.find { |l| l[0] == 'End Date' }[1], '%m/%d/%Y')
    hi = lines.index { |l| l[0] == 'Transaction Date' }
    head = lines[hi]
    c = %w[Apple\ Identifier Quantity Extended\ Partner\ Share Partner\ Share\ Currency Country\ of\ Sale].to_h { |n| [n, head.index(n)] }
    apps = Hash.new { |h, k| h[k] = { units: 0, eur: 0.0 } }
    unconverted = Hash.new(0.0)
    lines[(hi + 1)..].each do |r|
      break if r.size < head.size - 2 || r[0].to_s.empty?

      amount = r[c['Extended Partner Share']].to_f
      currency = r[c['Partner Share Currency']].strip
      # Converted at the period's last day: close to when Apple fixes its
      # rates for the payout, without pretending to know them.
      value = eur(fx, amount, currency, finish)
      id = r[c['Apple Identifier']].strip
      a = apps[iap_to_app[id] || id]
      a[:units] += r[c['Quantity']].to_i
      if value then a[:eur] += value else unconverted[currency] += amount end
    end
    periods << { key: key, start: start.iso8601, end: finish.iso8601,
                 apps: apps.transform_values { |v| { units: v[:units], eur: v[:eur].round(2) } },
                 unconverted: unconverted.transform_values { |v| v.round(2) } }
  rescue StandardError => e
    error("#{File.basename(path)}: #{e.message}")
  end
  periods.sort_by { |p| p[:start] }
end

# Analytics CSVs are summed per day, app and a few dimensions. The column names
# are looked up by header, and a report whose header lacks one is reported in
# meta instead of guessed. When several instances cover the same day (the
# snapshot and the ongoing request overlap), the latest processing date wins.
ANALYTICS_DIMENSIONS = {
  'app-downloads-standard' => ['Download Type', 'Source Type'],
  'app-downloads-detailed' => ['Source Type', 'Campaign'],
  'app-store-discovery-and-engagement-standard' => ['Event', 'Source Type'],
  'app-store-discovery-and-engagement-detailed' => ['Event', 'Campaign']
}.freeze

def aggregate_analytics
  out = []
  notes = []
  files = Dir[File.join(RAW, 'analytics', '*', '*', '*.csv.gz')]
  files.group_by { |f| f.split('/')[-3, 2] }.each do |(app, report), paths|
    dims = ANALYTICS_DIMENSIONS[report]
    next unless dims

    by_day = {}
    paths.sort.each do |path|
      text = gunzip(File.binread(path))
      sep = text.lines.first.to_s.include?("\t") ? "\t" : ','
      rows = text.lines.map { |l| l.chomp.split(sep, -1).map { |v| v.delete('"') } }
      head = rows.shift || []
      date_i, count_i = head.index('Date'), head.index('Counts')
      dim_i = dims.map { |d| head.index(d) }
      if date_i.nil? || count_i.nil? || dim_i.any?(&:nil?)
        notes << "#{report}: Spalten #{head.first(20).join(', ')}"
        break
      end
      rows.group_by { |r| r[date_i] }.each do |day, rs|
        by_day[day] = rs.group_by { |r| dim_i.map { |i| r[i] } }.transform_values { |g| g.sum { |r| r[count_i].to_i } }
      end
    rescue StandardError => e
      notes << "#{File.basename(path)}: #{e.message}"
    end
    by_day.each do |day, groups|
      groups.each { |dim, n| out << [day, app, report, *dim, n] }
    end
  end
  [out.sort, notes.uniq, files.size]
end

# --- Main ---------------------------------------------------------------------

def main
  FileUtils.mkdir_p([RAW, SITE])
  apps = api_all('/v1/apps?fields[apps]=name,bundleId&limit=200').map do |a|
    { id: a['id'], name: a.dig('attributes', 'name'), bundle_id: a.dig('attributes', 'bundleId') }
  end
  write_atomic(File.join(RAW, 'apps.json'), JSON.pretty_generate(apps))
  log("#{apps.size} Apps")

  steps = [-> { fetch_all_sales }, -> { fetch_all_finance }, -> { fetch_fx }, -> { fetch_analytics(apps) }]
  steps.each do |step|
    step.call
  rescue StandardError => e
    error("#{e.class}: #{e.message}")
  end

  log('Rechne data.json ...')
  fx = load_fx
  catalog = collect_catalog
  daily, residual, unconverted, daily_days = aggregate_sales(fx, catalog[:sku_to_app])
  finance = aggregate_finance(fx, catalog[:iap_to_app])
  analytics, analytics_notes, analytics_files = aggregate_analytics

  # Entries are ordered by the first day they show up in any report, so a new
  # app is appended and never takes over the colour of an existing one. Apps
  # without any data yet come last and get no colour.
  # A residual that is only proceeds is conversion noise (the yearly report is
  # converted at one rate, the days at their own), not activity before the
  # archive, and would otherwise move first_seen and with it the colours.
  residual.select! { |_, v| v[0, 7].any? { |n| n.round != 0 } }
  first_seen = {}
  seen = ->(id, day) { first_seen[id] = [first_seen[id], day].compact.min }
  residual.each_key { |(year, app)| seen.(app, "#{year}-01-01") }
  daily.each_key { |(day, app, _)| seen.(app, day) }
  finance.each { |p| p[:apps].each_key { |app| seen.(app, p[:start]) } }
  known = apps.to_h { |a| [a[:id], a[:name]] }
  entries = (known.keys | first_seen.keys).map do |id|
    { id: id, name: known[id] || catalog[:titles][id] || id, first_seen: first_seen[id],
      bundle: catalog[:bundles].include?(id) }
  end
  entries.sort_by! { |e| [e[:first_seen] || '9999', e[:id].to_i] }

  data = {
    meta: {
      generated_at: Time.now.utc.iso8601,
      daily_from: daily_days.min&.iso8601,
      daily_to: daily_days.max&.iso8601,
      fx_latest: fx[:days].last,
      fixed_costs_eur_per_year: FIXED_COSTS_EUR_PER_YEAR,
      unconverted_daily: unconverted.transform_values { |v| v.round(2) },
      analytics_files: analytics_files,
      analytics_notes: analytics_notes,
      errors: $errors,
      requests: $stats[:requests]
    },
    apps: entries,
    # [day, app, country, ios, mac, other, redownloads, updates, iap, promo, proceeds_eur]
    daily: daily.sort.map { |(d, app, cc), v| [d, app, cc, *v[0, 7].map(&:to_i), v[7].round(2)] },
    # [year, app, ios, mac, other, redownloads, updates, iap, promo, proceeds_eur]
    before_archive: residual.sort.map { |(year, app), v| [year, app, *v[0, 7].map(&:round), v[7].round(2)] },
    finance: finance,
    # [day, app, report, dimension values..., count]
    analytics: analytics
  }
  write_atomic(File.join(SITE, 'data.json'), JSON.generate(data))
  log("Fertig: #{data[:daily].size} Tageszeilen, #{finance.size} Abrechnungen, #{$stats[:requests]} Anfragen, #{$errors.size} Fehler")
  exit(1) unless $errors.empty?
end

main if $PROGRAM_NAME == __FILE__
