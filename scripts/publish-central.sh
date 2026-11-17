#!/usr/bin/env bash
set -euo pipefail

bundle="${1:?Usage: publish-central.sh BUNDLE [DEPLOYMENT_NAME]}"
deployment_name="${2:-dwdash release}"
: "${CENTRAL_USERNAME:?CENTRAL_USERNAME is required}"
: "${CENTRAL_PASSWORD:?CENTRAL_PASSWORD is required}"

if [[ ! -f "$bundle" ]]; then
  echo "Maven Central bundle not found: $bundle" >&2
  exit 1
fi

auth_token="$(printf '%s:%s' "$CENTRAL_USERNAME" "$CENTRAL_PASSWORD" | base64 | tr -d '\n')"
encoded_name="$(jq -rn --arg value "$deployment_name" '$value|@uri')"
upload_url="https://central.sonatype.com/api/v1/publisher/upload?publishingType=AUTOMATIC&name=${encoded_name}"

deployment_id="$(curl --fail-with-body --silent --show-error \
  --request POST \
  --header "Authorization: Bearer ${auth_token}" \
  --form "bundle=@${bundle};type=application/octet-stream" \
  "$upload_url")"

if [[ -z "$deployment_id" ]]; then
  echo "Maven Central did not return a deployment ID" >&2
  exit 1
fi

echo "Maven Central deployment: $deployment_id"

for attempt in $(seq 1 180); do
  status="$(curl --fail-with-body --silent --show-error \
    --request POST \
    --header "Authorization: Bearer ${auth_token}" \
    "https://central.sonatype.com/api/v1/publisher/status?id=${deployment_id}")"
  state="$(jq -r '.deploymentState' <<< "$status")"

  case "$state" in
    PUBLISHED)
      echo "Maven Central publication completed"
      exit 0
      ;;
    FAILED)
      echo "Maven Central publication failed:" >&2
      jq '.errors // .' <<< "$status" >&2
      exit 1
      ;;
    PENDING|VALIDATING|VALIDATED|PUBLISHING)
      echo "Maven Central state: $state"
      ;;
    *)
      echo "Unexpected Maven Central state: $state" >&2
      jq . <<< "$status" >&2
      exit 1
      ;;
  esac

  sleep 10
done

echo "Timed out waiting for Maven Central deployment $deployment_id" >&2
exit 1
