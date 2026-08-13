#!/usr/bin/env bash
#
# Checks the published security.txt of every website against expiry.
#
#   .github/scripts/check-security-txt.sh
#
# RFC 9116 makes "Expires" mandatory and a file past that date invalid. The
# websites generate the date at build time (src/pages/.well-known/), so it only
# moves forward on a deploy. A monthly cron in each deploy.yml provides that,
# but the cron itself can stop: GitHub disables scheduled workflows after 60
# days without repository activity, and a red build deploys nothing either.
#
# This probe therefore checks the served result rather than the source, which
# covers every cause at once: no deploy, disabled cron, broken build, deleted
# file. It lives here because kubernetes-homelab is the repo that is guaranteed
# to stay active, so its own schedule keeps running.
#
# Fails while there is still time to react, not once the file is already
# invalid.

set -uo pipefail

# Days of remaining validity below which the check fails. A monthly deploy has
# to miss twice before this trips, so it flags a real standstill rather than a
# single skipped run.
THRESHOLD_DAYS=60

URLS=(
  https://seb-it.com/.well-known/security.txt
  https://homeworx.solutions/.well-known/security.txt
  https://haushelden-service.de/.well-known/security.txt
  https://peters.club/.well-known/security.txt
  https://www.elmstreet79.de/.well-known/security.txt
)

now=$(date -u +%s)
failed=0

for url in "${URLS[@]}"; do
  # Status and body in one request. Without the status a WAF or bot challenge
  # is indistinguishable from a network problem, and the two need opposite
  # fixes.
  response=$(curl -sSL --max-time 20 -w '\n%{http_code}' "$url" 2>/dev/null)
  status=${response##*$'\n'}
  body=${response%$'\n'*}

  if [[ "$status" != "200" ]]; then
    echo "FAIL  $url: HTTP $status"
    failed=1
    continue
  fi
  if [[ -z "$body" ]]; then
    echo "FAIL  $url: empty body"
    failed=1
    continue
  fi

  # Field names are case-insensitive per RFC 9116.
  expires=$(grep -i '^Expires:' <<<"$body" | head -1 | sed 's/^[^:]*: *//' | tr -d '\r')
  if [[ -z "$expires" ]]; then
    echo "FAIL  $url: no Expires field"
    failed=1
    continue
  fi

  # Parsed with python3, not `date -d`: that is GNU-only and the script is
  # meant to run on the Ubuntu runner and on macOS alike.
  if ! expires_ts=$(python3 -c 'import sys,datetime; print(int(datetime.datetime.fromisoformat(sys.argv[1].replace("Z","+00:00")).timestamp()))' "$expires" 2>/dev/null); then
    echo "FAIL  $url: Expires not parsable ($expires)"
    failed=1
    continue
  fi

  days=$(((expires_ts - now) / 86400))
  if ((days < THRESHOLD_DAYS)); then
    echo "FAIL  $url: expires in ${days}d ($expires)"
    failed=1
  else
    echo "ok    $url: expires in ${days}d"
  fi
done

if ((failed)); then
  echo
  echo "Deploy the affected site to move its Expires forward. The date comes"
  echo "from the build, so a run of its deploy workflow is enough."
fi

exit "$failed"
