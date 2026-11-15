'use strict';

// Dashboard for the App Store reports archived by fetch.rb. Everything is
// computed in the browser from data.json, so a filter change never refetches.
(() => {
  const NF = new Intl.NumberFormat('de-DE');
  const PCT = new Intl.NumberFormat('de-DE', { style: 'percent', maximumFractionDigits: 0 });
  const EUR = new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' });
  const EUR0 = new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR', maximumFractionDigits: 0 });
  const DAY = new Intl.DateTimeFormat('de-DE', { day: '2-digit', month: '2-digit', year: 'numeric', timeZone: 'UTC' });
  const DAY_SHORT = new Intl.DateTimeFormat('de-DE', { day: '2-digit', month: '2-digit', timeZone: 'UTC' });
  const MONTH = new Intl.DateTimeFormat('de-DE', { month: 'short', year: 'numeric', timeZone: 'UTC' });
  const MONTH_LONG = new Intl.DateTimeFormat('de-DE', { month: 'long', year: 'numeric', timeZone: 'UTC' });
  const STAMP = new Intl.DateTimeFormat('de-DE', { dateStyle: 'medium', timeStyle: 'short' });
  let REGION = null;
  try { REGION = new Intl.DisplayNames(['de'], { type: 'region' }); } catch (e) { /* older browser */ }

  // Daily row layout written by fetch.rb.
  const D = { day: 0, app: 1, cc: 2, ios: 3, mac: 4, other: 5, redl: 6, upd: 7, iap: 8, promo: 9, eur: 10 };
  const RANGE_LABEL = { 7: '7 Tagen', 30: '30 Tagen', 90: '90 Tagen', 365: '12 Monaten' };
  const SLOTS = 8;

  let DATA = null;
  let ENTITIES = [];
  let BY_ID = new Map();
  const state = { range: '30', app: 'all' };

  // ---------- helpers ----------

  function h(tag, attrs, ...children) {
    const node = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) {
      if (v == null || v === false) continue;
      if (k === 'class') node.className = v;
      else if (k === 'style') node.style.cssText = v;
      else node.setAttribute(k, v === true ? '' : v);
    }
    for (const c of children.flat()) {
      if (c == null || c === false) continue;
      node.append(c instanceof Node ? c : document.createTextNode(String(c)));
    }
    return node;
  }

  // Fills go through the CSSOM rather than an attribute: var() is then
  // resolved everywhere, and the CSP (no inline style attributes) allows it.
  function s(tag, attrs) {
    const node = document.createElementNS('http://www.w3.org/2000/svg', tag);
    for (const [k, v] of Object.entries(attrs || {})) {
      if (k === 'fill') node.style.fill = v;
      else node.setAttribute(k, v);
    }
    return node;
  }

  const parse = (iso) => new Date(`${iso}T00:00:00Z`);
  const iso = (d) => d.toISOString().slice(0, 10);
  const addDays = (isoDay, n) => { const d = parse(isoDay); d.setUTCDate(d.getUTCDate() + n); return iso(d); };
  const daysBetween = (a, b) => Math.round((parse(b) - parse(a)) / 86400000) + 1;
  const fmtDay = (isoDay) => DAY.format(parse(isoDay));
  const downloads = (r) => r[D.ios] + r[D.mac] + r[D.other];
  const color = (e) => (e && e.slot ? `var(--s${e.slot})` : 'var(--s-other)');
  const country = (cc) => { try { return (REGION && REGION.of(cc)) || cc; } catch (e) { return cc; } };

  function mondayOf(isoDay) {
    const d = parse(isoDay);
    d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
    return iso(d);
  }

  function isoWeek(isoDay) {
    const d = parse(isoDay);
    d.setUTCDate(d.getUTCDate() + 3 - ((d.getUTCDay() + 6) % 7));
    const jan4 = new Date(Date.UTC(d.getUTCFullYear(), 0, 4));
    return 1 + Math.round(((d - jan4) / 86400000 - 3 + ((jan4.getUTCDay() + 6) % 7)) / 7);
  }

  function niceStep(max, count) {
    const raw = max / count;
    const mag = Math.pow(10, Math.floor(Math.log10(raw)));
    const n = raw / mag;
    return (n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10) * mag;
  }

  // ---------- state ----------

  function readState() {
    const p = new URLSearchParams(location.hash.slice(1));
    if (['7', '30', '90', '365', 'all'].includes(p.get('range'))) state.range = p.get('range');
    if (p.get('app') && (p.get('app') === 'all' || BY_ID.has(p.get('app')))) state.app = p.get('app');
  }

  function writeState() {
    const p = new URLSearchParams({ range: state.range, app: state.app });
    history.replaceState(null, '', `#${p}`);
  }

  function period() {
    const end = DATA.meta.daily_to;
    const first = DATA.meta.daily_from;
    if (state.range === 'all') return { start: first, end, bucket: 'month', label: 'seit Beginn der Tagesdaten' };
    const n = Number(state.range);
    let start = addDays(end, -(n - 1));
    if (start < first) start = first;
    const prevEnd = addDays(start, -1);
    const prevStart = addDays(start, -n);
    return {
      start, end, n,
      bucket: n <= 90 ? 'day' : 'week',
      label: `letzte ${RANGE_LABEL[n]}`,
      prev: prevStart >= first ? { start: prevStart, end: prevEnd } : null
    };
  }

  function rows(start, end) {
    return DATA.daily.filter((r) => r[D.day] >= start && r[D.day] <= end && (state.app === 'all' || r[D.app] === state.app));
  }

  function sum(list) {
    const t = { dl: 0, ios: 0, mac: 0, other: 0, redl: 0, upd: 0, iap: 0, promo: 0, eur: 0 };
    for (const r of list) {
      t.ios += r[D.ios]; t.mac += r[D.mac]; t.other += r[D.other];
      t.redl += r[D.redl]; t.upd += r[D.upd]; t.iap += r[D.iap];
      t.promo += r[D.promo]; t.eur += r[D.eur];
    }
    t.dl = t.ios + t.mac + t.other;
    return t;
  }

  // ---------- tiles ----------

  function delta(cur, prev, p, money) {
    if (!p.prev) return h('div', { class: 'delta' }, state.range === 'all' ? 'Gesamter Zeitraum' : 'Kein Vergleichszeitraum im Archiv');
    const label = `ggü. den ${RANGE_LABEL[p.n]} davor`;
    if (prev === 0 && cur === 0) return h('div', { class: 'delta' }, `unverändert ${label}`);
    if (prev === 0) return h('div', { class: 'delta up' }, `▲ neu, davor ${money ? EUR.format(0) : 0}`);
    const change = (cur - prev) / Math.abs(prev);
    const dir = change > 0 ? 'up' : change < 0 ? 'down' : '';
    const arrow = change > 0 ? '▲' : change < 0 ? '▼' : '';
    const sign = change > 0 ? '+' : '';
    return h('div', { class: `delta ${dir}` }, `${arrow} ${sign}${PCT.format(change)} ${label}`.trim(),
      h('span', { class: 'muted' }, ` (${money ? EUR.format(prev) : NF.format(prev)})`));
  }

  function renderTiles(p, cur, prev) {
    const box = document.getElementById('tiles');
    const pv = prev || sum([]);
    const tile = (label, value, detail, d) => h('div', { class: 'tile' },
      h('div', { class: 'label' }, label), h('div', { class: 'value' }, value),
      detail ? h('div', { class: 'detail' }, detail) : null, d);
    box.replaceChildren(
      tile('Erst-Downloads', NF.format(cur.dl), `iOS ${NF.format(cur.ios)} · Mac ${NF.format(cur.mac)}${cur.other ? ` · andere ${NF.format(cur.other)}` : ''}`,
        delta(cur.dl, pv.dl, p, false)),
      tile('Erlös', EUR.format(cur.eur), 'nach Provision, EZB-Kurs', delta(cur.eur, pv.eur, p, true)),
      tile('Updates', NF.format(cur.upd), `erneute Downloads ${NF.format(cur.redl)}`, delta(cur.upd, pv.upd, p, false)),
      tile('Käufe in Apps', NF.format(cur.iap), `Promo-Codes eingelöst ${NF.format(cur.promo)}`, delta(cur.iap, pv.iap, p, false))
    );
  }

  // ---------- stacked column chart ----------

  function buckets(p) {
    const list = [];
    if (p.bucket === 'day') {
      for (let d = p.start; d <= p.end; d = addDays(d, 1)) {
        list.push({ key: d, short: DAY_SHORT.format(parse(d)), long: fmtDay(d) });
      }
    } else if (p.bucket === 'week') {
      for (let d = mondayOf(p.start); d <= p.end; d = addDays(d, 7)) {
        const from = d < p.start ? p.start : d;
        const to = addDays(d, 6) > p.end ? p.end : addDays(d, 6);
        list.push({ key: d, short: `KW ${isoWeek(d)}`, long: `KW ${isoWeek(d)}: ${DAY_SHORT.format(parse(from))} bis ${fmtDay(to)}` });
      }
    } else {
      for (let d = `${p.start.slice(0, 7)}-01`; d <= p.end; ) {
        list.push({ key: d.slice(0, 7), short: MONTH.format(parse(d)), long: MONTH_LONG.format(parse(d)) });
        const n = parse(d); n.setUTCMonth(n.getUTCMonth() + 1); d = iso(n);
      }
    }
    return list;
  }

  function bucketKey(p, day) {
    if (p.bucket === 'day') return day;
    if (p.bucket === 'week') return mondayOf(day);
    return day.slice(0, 7);
  }

  // Series follow the entity: every coloured app keeps its slot no matter
  // which others are filtered out; apps past slot 8 fold into "Weitere".
  function seriesFor(list, value) {
    const present = new Map();
    for (const r of list) if (value(r) !== 0) present.set(r[D.app], true);
    const series = [];
    let other = false;
    for (const e of ENTITIES) {
      if (!present.has(e.id)) continue;
      if (e.slot) series.push({ id: e.id, name: e.short, color: color(e), match: (id) => id === e.id });
      else other = true;
    }
    if (other) series.push({ id: '_other', name: 'Weitere', color: 'var(--s-other)', match: (id) => !(BY_ID.get(id) || {}).slot });
    return series;
  }

  function chartData(p, list, value) {
    const bs = buckets(p);
    const index = new Map(bs.map((b, i) => [b.key, i]));
    const series = seriesFor(list, value);
    const values = series.map(() => new Array(bs.length).fill(0));
    for (const r of list) {
      const i = index.get(bucketKey(p, r[D.day]));
      const si = series.findIndex((x) => x.match(r[D.app]));
      if (i == null || si < 0) continue;
      values[si][i] += value(r);
    }
    return { buckets: bs, series, values };
  }

  function renderChart(container, title, data, fmt, axisFmt) {
    const { buckets: bs, series, values } = data;
    // Net totals for the readout; the geometry uses the positive stack only,
    // since a refund (negative units or proceeds) draws no segment and would
    // otherwise let the column overshoot the axis.
    const totals = bs.map((_, i) => values.reduce((acc, v) => acc + v[i], 0));
    const stacks = bs.map((_, i) => values.reduce((acc, v) => acc + Math.max(0, v[i]), 0));
    const max = Math.max(0, ...stacks);
    container.replaceChildren();

    if (series.length >= 2) {
      container.append(h('ul', { class: 'legend', 'aria-label': 'Legende' },
        series.map((x) => h('li', {}, h('span', { class: 'key', style: `background:${x.color}` }), x.name))));
    }

    const width = Math.max(280, container.clientWidth || 600);
    const height = width < 560 ? 220 : 260;
    const step = max > 0 ? niceStep(max, 4) : 1;
    const top = Math.ceil(max / step) * step || 1;
    const ticks = [];
    for (let v = 0; v <= top + step / 2; v += step) ticks.push(v);
    const tickLabels = ticks.map((v) => axisFmt(v));
    const m = { l: Math.max(28, Math.max(...tickLabels.map((t) => t.length)) * 6.6 + 10), r: 8, t: 10, b: 26 };
    const pw = width - m.l - m.r;
    const ph = height - m.t - m.b;
    const band = pw / bs.length;
    const colW = Math.max(1.5, Math.min(24, band * 0.7));
    const y = (v) => m.t + ph - (v / top) * ph;

    const peak = stacks.indexOf(max);
    const summary = max > 0
      ? `${title}: insgesamt ${fmt(totals.reduce((a, b) => a + b, 0))}, höchster Wert ${fmt(totals[peak])} am ${bs[peak].long}. Pfeiltasten wählen einzelne Säulen.`
      : `${title}: keine Werte im Zeitraum.`;
    const svg = s('svg', { viewBox: `0 0 ${width} ${height}`, width, height, tabindex: '0', role: 'img', 'aria-label': summary });

    for (let i = 0; i < ticks.length; i++) {
      const ty = y(ticks[i]);
      svg.append(s('line', { class: i === 0 ? 'base' : 'grid', x1: m.l, x2: width - m.r, y1: ty, y2: ty }));
      const label = s('text', { class: 'tick', x: m.l - 6, y: ty + 4, 'text-anchor': 'end' });
      label.textContent = tickLabels[i];
      svg.append(label);
    }

    const hover = s('rect', { class: 'hover', x: 0, y: m.t, width: band, height: ph, visibility: 'hidden' });
    svg.append(hover);

    if (max === 0) {
      const t = s('text', { class: 'empty', x: m.l + pw / 2, y: m.t + ph / 2, 'text-anchor': 'middle' });
      t.textContent = 'Keine Werte im Zeitraum';
      svg.append(t);
    }

    // Columns: segments stacked from the baseline with a 2px surface gap,
    // the topmost segment carries the 4px rounded data end.
    for (let i = 0; i < bs.length; i++) {
      if (stacks[i] <= 0) continue;
      const x = m.l + i * band + (band - colW) / 2;
      let base = 0;
      const segs = series.map((x2, si) => ({ si, v: values[si][i] })).filter((g) => g.v > 0);
      segs.forEach((g, k) => {
        const y0 = y(base);
        const y1 = y(base + g.v);
        base += g.v;
        const hgt = Math.max(0.5, y0 - y1 - (k > 0 ? 2 : 0));
        const yTop = y0 - (k > 0 ? 2 : 0) - hgt;
        if (k === segs.length - 1) {
          const r = Math.min(4, colW / 2, hgt);
          svg.append(s('path', {
            d: `M${x},${yTop + hgt}V${yTop + r}Q${x},${yTop} ${x + r},${yTop}H${x + colW - r}Q${x + colW},${yTop} ${x + colW},${yTop + r}V${yTop + hgt}Z`,
            fill: series[g.si].color
          }));
        } else {
          svg.append(s('rect', { x, y: yTop, width: colW, height: hgt, fill: series[g.si].color }));
        }
      });
    }

    const every = Math.max(1, Math.ceil(bs.length / Math.max(2, Math.floor(pw / 64))));
    for (let i = 0; i < bs.length; i += every) {
      const t = s('text', { class: 'tick', x: m.l + i * band + band / 2, y: height - 8, 'text-anchor': 'middle' });
      t.textContent = bs[i].short;
      svg.append(t);
    }

    container.append(svg);

    // Hover and keyboard share one readout: the column under the pointer or
    // the one picked with the arrow keys.
    const live = h('p', { class: 'skip', 'aria-live': 'polite' });
    container.append(live);
    let current = -1;
    const show = (i, clientX, clientY) => {
      if (i < 0 || i >= bs.length) return hide();
      current = i;
      hover.setAttribute('x', m.l + i * band);
      hover.setAttribute('visibility', 'visible');
      const rowsOut = series.map((x, si) => ({ x, v: values[si][i] })).filter((g) => g.v !== 0).reverse();
      tooltip(bs[i].long, rowsOut.map((g) => ({ color: g.x.color, name: g.x.name, value: fmt(g.v) })),
        series.length > 1 ? fmt(totals[i]) : null, clientX, clientY);
      live.textContent = `${bs[i].long}: ${fmt(totals[i])}${rowsOut.length > 1 ? `; ${rowsOut.map((g) => `${g.x.name} ${fmt(g.v)}`).join(', ')}` : ''}`;
    };
    const hide = () => { current = -1; hover.setAttribute('visibility', 'hidden'); tooltip(null); };
    svg.addEventListener('pointermove', (e) => {
      const rect = svg.getBoundingClientRect();
      const x = (e.clientX - rect.left) * (width / rect.width);
      if (x < m.l || x > width - m.r) return hide();
      show(Math.floor((x - m.l) / band), e.clientX, e.clientY);
    });
    svg.addEventListener('pointerleave', hide);
    svg.addEventListener('blur', hide);
    svg.addEventListener('keydown', (e) => {
      const keys = { ArrowLeft: -1, ArrowRight: 1, Home: -Infinity, End: Infinity };
      if (!(e.key in keys)) { if (e.key === 'Escape') hide(); return; }
      e.preventDefault();
      let i = current < 0 ? (e.key === 'ArrowLeft' ? bs.length - 1 : 0) : current + keys[e.key];
      if (e.key === 'Home') i = 0;
      if (e.key === 'End') i = bs.length - 1;
      i = Math.max(0, Math.min(bs.length - 1, i));
      const rect = svg.getBoundingClientRect();
      const scale = rect.width / width;
      show(i, rect.left + (m.l + i * band + band / 2) * scale, rect.top + y(stacks[i]) * scale);
    });

    // The table view keeps every value reachable without hovering.
    const head = h('tr', {}, h('th', { scope: 'col' }, 'Zeitraum'), series.map((x) => h('th', { scope: 'col' }, x.name)),
      series.length > 1 ? h('th', { scope: 'col' }, 'Gesamt') : null);
    const body = bs.map((b, i) => totals[i] === 0 ? null : h('tr', {}, h('th', { scope: 'row' }, b.long),
      series.map((_, si) => h('td', {}, fmt(values[si][i]))), series.length > 1 ? h('td', {}, fmt(totals[i])) : null)).filter(Boolean);
    container.append(h('details', {}, h('summary', {}, 'Als Tabelle anzeigen'),
      h('div', { class: 'table-wrap' }, h('table', {}, h('caption', {}, title), h('thead', {}, head),
        h('tbody', {}, body.length ? body : h('tr', {}, h('td', { colspan: series.length + 2 }, 'Keine Werte im Zeitraum.')))))));
  }

  function tooltip(head, items, total, x, y) {
    const tip = document.getElementById('tooltip');
    if (!head) { tip.hidden = true; return; }
    tip.replaceChildren(h('div', { class: 't-head' }, head),
      items.map((it) => h('div', { class: 't-row' }, h('span', { class: 't-key', style: `background:${it.color}` }),
        h('span', { class: 't-val' }, it.value), h('span', { class: 't-name' }, it.name))),
      total != null ? h('div', { class: 't-row t-total' }, h('span'), h('span', { class: 't-val' }, total), h('span', { class: 't-name' }, 'Gesamt')) : null);
    tip.hidden = false;
    const r = tip.getBoundingClientRect();
    let left = x + 14;
    let top = y + 14;
    if (left + r.width > window.innerWidth - 8) left = x - r.width - 14;
    if (top + r.height > window.innerHeight - 8) top = y - r.height - 14;
    tip.style.left = `${Math.max(8, left)}px`;
    tip.style.top = `${Math.max(8, top)}px`;
  }

  // ---------- tables ----------

  function table(caption, headers, bodyRows, footRow) {
    return h('table', {}, caption ? h('caption', {}, caption) : null,
      h('thead', {}, h('tr', {}, headers.map((x) => h('th', { scope: 'col' }, x)))),
      h('tbody', {}, bodyRows),
      footRow ? h('tfoot', {}, footRow) : null);
  }

  function appCell(e) {
    return h('th', { scope: 'row' }, h('span', { class: 'swatch', style: `background:${color(e)}`, 'aria-hidden': 'true' }),
      e.name, e.bundle ? h('span', { class: 'muted' }, ' (Bündel)') : null);
  }

  function renderApps(p, list) {
    const per = new Map();
    for (const r of list) { if (!per.has(r[D.app])) per.set(r[D.app], []); per.get(r[D.app]).push(r); }
    const all = new Map();
    for (const r of DATA.daily) {
      const t = all.get(r[D.app]) || { dl: 0, eur: 0 };
      t.dl += downloads(r); t.eur += r[D.eur];
      all.set(r[D.app], t);
    }
    for (const b of DATA.before_archive) {
      const t = all.get(b[1]) || { dl: 0, eur: 0 };
      t.dl += b[2] + b[3] + b[4]; t.eur += b[9];
      all.set(b[1], t);
    }
    const shown = ENTITIES.filter((e) => (state.app === 'all' || e.id === state.app) && (per.has(e.id) || all.has(e.id)));
    const tot = { dl: 0, mac: 0, redl: 0, upd: 0, iap: 0, eur: 0, adl: 0, aeur: 0 };
    const bodyRows = shown.map((e) => {
      const t = sum(per.get(e.id) || []);
      const a = all.get(e.id) || { dl: 0, eur: 0 };
      tot.dl += t.dl; tot.mac += t.mac; tot.redl += t.redl; tot.upd += t.upd; tot.iap += t.iap; tot.eur += t.eur;
      tot.adl += a.dl; tot.aeur += a.eur;
      return h('tr', {}, appCell(e), h('td', {}, NF.format(t.dl)), h('td', {}, NF.format(t.mac)), h('td', {}, NF.format(t.redl)),
        h('td', {}, NF.format(t.upd)), h('td', {}, NF.format(t.iap)), h('td', {}, EUR.format(t.eur)),
        h('td', {}, NF.format(a.dl)), h('td', {}, EUR.format(a.eur)));
    });
    const foot = shown.length > 1 ? h('tr', {}, h('th', { scope: 'row' }, 'Summe'), [tot.dl, tot.mac, tot.redl, tot.upd, tot.iap].map((v) => h('td', {}, NF.format(v))),
      h('td', {}, EUR.format(tot.eur)), h('td', {}, NF.format(tot.adl)), h('td', {}, EUR.format(tot.aeur))) : null;
    document.getElementById('table-apps').replaceChildren(table(`Im Zeitraum (${p.label}) und seit Beginn`,
      ['App', 'Erst-Downloads', 'davon Mac', 'Erneute Downloads', 'Updates', 'Käufe in Apps', 'Erlös', 'Downloads seit Beginn', 'Erlös seit Beginn'],
      bodyRows.length ? bodyRows : h('tr', {}, h('td', { colspan: 9 }, 'Keine Daten.')), foot));
  }

  function renderCountries(p, list) {
    const per = new Map();
    for (const r of list) {
      const t = per.get(r[D.cc]) || { dl: 0, eur: 0 };
      t.dl += downloads(r); t.eur += r[D.eur];
      per.set(r[D.cc], t);
    }
    const sorted = [...per.entries()].filter(([, t]) => t.dl || t.eur).sort((a, b) => b[1].dl - a[1].dl || b[1].eur - a[1].eur);
    const total = sorted.reduce((acc, [, t]) => acc + t.dl, 0);
    const top = sorted.slice(0, 15);
    const rest = sorted.slice(15);
    const bodyRows = top.map(([cc, t]) => h('tr', {}, h('th', { scope: 'row' }, country(cc)), h('td', {}, NF.format(t.dl)),
      h('td', {}, total ? PCT.format(t.dl / total) : '–'), h('td', {}, EUR.format(t.eur))));
    if (rest.length) {
      const r = rest.reduce((acc, [, t]) => ({ dl: acc.dl + t.dl, eur: acc.eur + t.eur }), { dl: 0, eur: 0 });
      bodyRows.push(h('tr', {}, h('th', { scope: 'row', class: 'muted' }, `${rest.length} weitere Länder`), h('td', {}, NF.format(r.dl)),
        h('td', {}, total ? PCT.format(r.dl / total) : '–'), h('td', {}, EUR.format(r.eur))));
    }
    document.getElementById('table-countries').replaceChildren(table(`Nach Erst-Downloads, ${p.label}`,
      ['Land', 'Erst-Downloads', 'Anteil', 'Erlös'], bodyRows.length ? bodyRows : h('tr', {}, h('td', { colspan: 4 }, 'Keine Daten im Zeitraum.'))));
  }

  function renderFinance(p) {
    const box = document.getElementById('finance');
    const perYear = DATA.meta.fixed_costs_eur_per_year || 0;
    const allApps = state.app === 'all';
    // Months without proceeds have no finance report at all. The gaps between
    // two reports become rows of their own, so their fixed costs count too.
    const seq = [];
    DATA.finance.forEach((f, i) => {
      const prev = DATA.finance[i - 1];
      if (prev && addDays(prev.end, 1) < f.start) seq.push({ start: addDays(prev.end, 1), end: addDays(f.start, -1), apps: {}, gap: true });
      seq.push(f);
    });
    const list = seq.filter((f) => (state.range === 'all' || (f.end >= p.start && f.start <= p.end)) && (allApps || !f.gap));
    // Apple's fiscal months straddle calendar months; the midpoint names the
    // month they mostly cover.
    const label = (f) => {
      if (f.gap) return 'ohne Abrechnung';
      const mid = parse(f.start); mid.setUTCDate(mid.getUTCDate() + Math.floor(daysBetween(f.start, f.end) / 2));
      return MONTH_LONG.format(mid);
    };
    let units = 0; let eur = 0; let costs = 0;
    const bodyRows = list.slice().reverse().map((f) => {
      const apps = Object.entries(f.apps).filter(([id]) => allApps || id === state.app);
      const u = apps.reduce((acc, [, a]) => acc + a.units, 0);
      const e = apps.reduce((acc, [, a]) => acc + a.eur, 0);
      const c = allApps ? (perYear * daysBetween(f.start, f.end)) / 365.25 : 0;
      units += u; eur += e; costs += c;
      return h('tr', {}, h('th', { scope: 'row', class: f.gap ? 'muted' : null }, label(f)),
        h('td', { class: 'muted' }, `${(f.start.slice(0, 4) === f.end.slice(0, 4) ? DAY_SHORT : DAY).format(parse(f.start))} bis ${fmtDay(f.end)}`),
        h('td', {}, NF.format(u)), h('td', {}, EUR.format(e)),
        h('td', {}, allApps ? `−${EUR.format(c)}` : '–'),
        h('td', { class: e - c < 0 ? 'neg' : '' }, EUR.format(e - c)));
    });
    const result = eur - costs;
    const reports = list.filter((f) => !f.gap).length;
    const tiles = h('div', { class: 'tiles' },
      h('div', { class: 'tile' }, h('div', { class: 'label' }, 'Erlös abgerechnet'), h('div', { class: 'value' }, EUR0.format(eur)),
        h('div', { class: 'detail' }, `${NF.format(units)} Einheiten, ${reports} ${reports === 1 ? 'Abrechnung' : 'Abrechnungen'}`)),
      h('div', { class: 'tile' }, h('div', { class: 'label' }, 'Fixkosten'), h('div', { class: 'value' }, allApps ? EUR0.format(costs) : '–'),
        h('div', { class: 'detail' }, allApps ? `Developer Program, ${EUR0.format(perYear)} pro Jahr anteilig` : 'nur bei „Alle Apps“')),
      h('div', { class: 'tile' }, h('div', { class: 'label' }, 'Ergebnis'), h('div', { class: 'value' }, EUR0.format(result)),
        h('div', { class: 'detail' }, 'ohne Werbekosten und Steuern')));
    box.replaceChildren(tiles, h('div', { class: 'table-wrap' }, table(state.range === 'all' ? 'Alle Abrechnungen' : `Abrechnungen, die in den Zeitraum fallen (${p.label})`,
      ['Abrechnungsmonat', 'Zeitraum', 'Einheiten', 'Erlös', 'Fixkosten', 'Ergebnis'],
      bodyRows.length ? bodyRows : h('tr', {}, h('td', { colspan: 6 }, 'Im Zeitraum endet keine Abrechnung. Apple rechnet monatlich ab, der Zeitraum „Gesamt“ zeigt alle.')),
      list.length > 1 ? h('tr', {}, h('th', { scope: 'row' }, 'Summe'), h('td'), h('td', {}, NF.format(units)), h('td', {}, EUR.format(eur)),
        h('td', {}, allApps ? `−${EUR.format(costs)}` : '–'), h('td', { class: result < 0 ? 'neg' : '' }, EUR.format(result))) : null)));
  }

  // Apple's dimension values are English; the common ones get a German label.
  const SOURCE = {
    'App Store search': 'Suche im App Store', 'App Store Search': 'Suche im App Store',
    'App Store browse': 'Stöbern im App Store', 'App Store Browse': 'Stöbern im App Store',
    'Web referrer': 'Verweis von Webseite', 'Web Referrer': 'Verweis von Webseite',
    'App referrer': 'Verweis aus App', 'App Referrer': 'Verweis aus App',
    'Institutional purchase': 'Volumenkauf', Unavailable: 'Unbekannt', 'Event notification': 'Event-Hinweis',
    'First-time download': 'Erst-Download', Redownload: 'Erneuter Download', Update: 'Update',
    Impression: 'Impressionen', 'Page view': 'Seitenaufrufe', Tap: 'Tipps'
  };
  const de = (v) => SOURCE[v] || v || '–';

  function renderAnalytics(p) {
    const box = document.getElementById('analytics');
    const list = DATA.analytics.filter((r) => r[0] >= p.start && r[0] <= p.end && (state.app === 'all' || r[1] === state.app));
    if (!DATA.analytics.length) {
      box.replaceChildren(h('p', { class: 'card-sub' },
        'Noch keine Analytics-Daten. Apple liefert die ersten Berichte 24 bis 48 Stunden nach der Anforderung (angefordert am 15.11.2026) ',
        'und hält sie nur rund 35 Tage vor; der tägliche Abruf archiviert sie, sobald sie da sind.'));
      if (DATA.meta.analytics_notes.length) box.append(h('ul', {}, DATA.meta.analytics_notes.map((n) => h('li', { class: 'muted' }, n))));
      return;
    }
    const group = (report, dimIndex) => {
      const m = new Map();
      for (const r of list) if (r[2] === report) m.set(r[3 + dimIndex], (m.get(r[3 + dimIndex]) || 0) + r[r.length - 1]);
      return [...m.entries()].filter(([, n]) => n).sort((a, b) => b[1] - a[1]);
    };
    const source = group('app-downloads-standard', 1);
    const events = group('app-store-discovery-and-engagement-standard', 0);
    const campaigns = new Map();
    for (const r of list) {
      if (r[2] === 'app-downloads-detailed' && r[4]) {
        const c = campaigns.get(r[4]) || { dl: 0, ev: {} }; c.dl += r[5]; campaigns.set(r[4], c);
      }
      if (r[2] === 'app-store-discovery-and-engagement-detailed' && r[4]) {
        const c = campaigns.get(r[4]) || { dl: 0, ev: {} }; c.ev[r[3]] = (c.ev[r[3]] || 0) + r[5]; campaigns.set(r[4], c);
      }
    }
    const evNames = [...new Set([...campaigns.values()].flatMap((c) => Object.keys(c.ev)))].sort();
    const parts = [];
    parts.push(h('div', { class: 'table-wrap' }, table(`Produktseite, ${p.label}`, ['Ereignis', 'Anzahl'],
      events.length ? events.map(([k, n]) => h('tr', {}, h('th', { scope: 'row' }, de(k)), h('td', {}, NF.format(n)))) : h('tr', {}, h('td', { colspan: 2 }, 'Keine Daten im Zeitraum.')))));
    parts.push(h('div', { class: 'table-wrap' }, table(`Downloads nach Herkunft, ${p.label}`, ['Herkunft', 'Downloads'],
      source.length ? source.map(([k, n]) => h('tr', {}, h('th', { scope: 'row' }, de(k)), h('td', {}, NF.format(n)))) : h('tr', {}, h('td', { colspan: 2 }, 'Keine Daten im Zeitraum.')))));
    const camp = [...campaigns.entries()].sort((a, b) => b[1].dl - a[1].dl);
    parts.push(h('div', { class: 'table-wrap' }, table(`Kampagnen, ${p.label}`, ['Kampagne', 'Downloads', ...evNames.map(de)],
      camp.length ? camp.map(([k, c]) => h('tr', {}, h('th', { scope: 'row' }, k), h('td', {}, NF.format(c.dl)), evNames.map((e) => h('td', {}, NF.format(c.ev[e] || 0)))))
        : h('tr', {}, h('td', { colspan: 2 + evNames.length }, 'Keine Kampagnen im Zeitraum.')))));
    box.replaceChildren(...parts);
  }

  function renderNotes() {
    const m = DATA.meta;
    const items = [
      `Tagesberichte vom ${fmtDay(m.daily_from)} bis ${fmtDay(m.daily_to)}; der Abruf läuft täglich, Apple stellt einen Tag am Folgetag bereit.`,
      `Euro-Beträge mit EZB-Referenzkursen, zuletzt vom ${fmtDay(m.fx_latest)}; an Dollar gebundene Golfwährungen über den festen Kurs.`
    ];
    if (DATA.before_archive.length) {
      const years = [...new Set(DATA.before_archive.map((b) => b[0]))].join(', ');
      items.push(`Vor dem ${fmtDay(m.daily_from)} gibt es nur Jahressummen (${years}); sie stecken in den Spalten „seit Beginn“, nicht in den Diagrammen.`);
    }
    const bundles = ENTITIES.filter((e) => e.bundle);
    if (bundles.length) items.push(`${bundles.map((e) => e.name).join(', ')}: App-Bündel; Apple teilt den Erlös nicht auf die einzelnen Apps auf.`);
    const unc = Object.entries(m.unconverted_daily || {});
    if (unc.length) items.push(`Nicht umgerechnet (keine EZB-Kurse): ${unc.map(([c, v]) => `${NF.format(v)} ${c}`).join(', ')}.`);
    for (const f of DATA.finance) {
      const u = Object.entries(f.unconverted || {});
      if (u.length) items.push(`Abrechnung ${MONTH_LONG.format(parse(f.end))} nicht umgerechnet: ${u.map(([c, v]) => `${NF.format(v)} ${c}`).join(', ')}.`);
    }
    const list = h('ul', {}, items.map((t) => h('li', {}, t)));
    const errs = m.errors && m.errors.length ? h('ul', {}, m.errors.map((e) => h('li', { class: 'err' }, `Fehler beim letzten Abruf: ${e}`))) : null;
    document.getElementById('notes').replaceChildren(list, errs || '');
  }

  // ---------- main ----------

  function render() {
    const p = period();
    const list = rows(p.start, p.end);
    const cur = sum(list);
    const prev = p.prev ? sum(rows(p.prev.start, p.prev.end)) : null;
    const name = state.app === 'all' ? 'alle Apps' : (BY_ID.get(state.app) || {}).name;
    document.getElementById('range-note').textContent = `${fmtDay(p.start)} bis ${fmtDay(p.end)} · ${name}`;
    renderTiles(p, cur, prev);
    renderChart(document.getElementById('chart-downloads'), 'Erst-Downloads', chartData(p, list, downloads), (v) => NF.format(v), (v) => NF.format(v));
    renderChart(document.getElementById('chart-proceeds'), 'Erlös', chartData(p, list, (r) => r[D.eur]), (v) => EUR.format(v), (v) => EUR0.format(v));
    renderApps(p, list);
    renderCountries(p, list);
    renderFinance(p);
    renderAnalytics(p);
    renderNotes();
  }

  function setup() {
    let slot = 0;
    ENTITIES = DATA.apps.map((a) => ({
      ...a,
      short: a.name.split(':')[0].trim(),
      slot: a.first_seen && slot < SLOTS ? ++slot : null
    }));
    BY_ID = new Map(ENTITIES.map((e) => [e.id, e]));
    const select = document.getElementById('app-select');
    for (const e of ENTITIES.filter((x) => x.first_seen)) select.append(h('option', { value: e.id }, e.name));
    readState();
    const form = document.getElementById('filter');
    form.elements.range.value = state.range;
    select.value = state.app;
    form.addEventListener('change', () => {
      state.range = form.elements.range.value;
      state.app = select.value;
      writeState();
      render();
    });
    document.getElementById('stand').textContent =
      `Seb-IT · Stand ${STAMP.format(new Date(DATA.meta.generated_at))} · Tagesdaten bis ${fmtDay(DATA.meta.daily_to)}`;
    let last = document.body.clientWidth;
    new ResizeObserver(() => {
      if (Math.abs(document.body.clientWidth - last) < 8) return;
      last = document.body.clientWidth;
      render();
    }).observe(document.body);
    render();
  }

  fetch('data.json', { cache: 'no-store' })
    .then((r) => { if (!r.ok) throw new Error(`HTTP ${r.status}`); return r.json(); })
    .then((json) => { DATA = json; setup(); })
    .catch((e) => {
      document.getElementById('stand').textContent = `Daten nicht ladbar (${e.message}). Läuft der Abruf schon?`;
    });
})();
