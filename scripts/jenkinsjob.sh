#!/usr/bin/env bash
# Triggers the Jenkins job, waits for it, prints the console, and downloads the image tar.
# Required env: JENKINS_URL JENKINS_USER JENKINS_TOKEN COMMIT_SHA IMAGE_NAME STAGING
# Optional env: JENKINS_JOB (default: poc-build)
set -eu

AUTH="$JENKINS_USER:$JENKINS_TOKEN"
JOB="$JENKINS_URL/job/${JENKINS_JOB:-poc-build}"

echo "Triggering Jenkins build for commit $COMMIT_SHA"
QUEUE_ID=$(curl -sS -D - -o /dev/null -u "$AUTH" -X POST "$JOB/buildWithParameters" \
  --data-urlencode "COMMIT_SHA=$COMMIT_SHA" \
  | tr -d '\r' | grep -i '^location:' | sed 's#.*/queue/item/\([0-9]*\)/.*#\1#')
echo "Queue item: $QUEUE_ID"

BUILD_NO=""
for _ in $(seq 1 60); do
  BUILD_NO=$(curl -sS -u "$AUTH" "$JENKINS_URL/queue/item/$QUEUE_ID/api/json" \
    | grep -o '"executable":{[^}]*}' | grep -o '"number":[0-9]*' | cut -d: -f2 || true)
  [ -n "$BUILD_NO" ] && break
  sleep 5
done
[ -n "$BUILD_NO" ] || { echo "Build never left the queue"; exit 1; }
echo "Jenkins build #$BUILD_NO"

RESULT=""
for _ in $(seq 1 120); do
  RESULT=$(curl -sS -u "$AUTH" "$JOB/$BUILD_NO/api/json?tree=result" \
    | grep -o '"result":"[A-Z]*"' | cut -d'"' -f4 || true)
  [ -n "$RESULT" ] && break
  sleep 5
done

echo "=========== Jenkins console ==========="
curl -sS -u "$AUTH" "$JOB/$BUILD_NO/consoleText"
echo "======================================="
echo "Jenkins result: $RESULT"
[ "$RESULT" = "SUCCESS" ] || exit 1

mkdir -p "$STAGING"
curl -sS -f -u "$AUTH" -o "$STAGING/$IMAGE_NAME.tar" "$JOB/$BUILD_NO/artifact/$IMAGE_NAME.tar"
ls -lh "$STAGING"