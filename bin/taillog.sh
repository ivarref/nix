#!/usr/bin/env bash

set -euo pipefail

NEED_NEWLINE='false'
PREV_LINE='xyz'

getdate() {
  date '+%H:%M:%S'
}

BEGIN_EPOCH="$(date '+%s')"

log_status() {
  if [[ "$PREV_LINE" == "$1" ]]; then
    NOW_EPOCH="$(date '+%s')"
    WAITED="$((NOW_EPOCH-BEGIN_EPOCH))"
    printf "\r%s" "$(getdate) $1 waited ${WAITED} seconds"
  else
    PREV_LINE="$1"
    BEGIN_EPOCH="$(date '+%s')"
    if [[ "$NEED_NEWLINE" == "true" ]]; then
      printf "\n%s" "$(getdate) $1 waited 0 seconds"
    else
      printf "%s" "$(getdate) $1 waited 0 seconds"
    fi
  fi
  NEED_NEWLINE='true'
}

log_info() {
  if [[ "$NEED_NEWLINE" == "true" ]]; then
    printf "\n%s\n" "$(getdate) $1"
  else
    printf "%s\n" "$(getdate) $1"
  fi
  PREV_LINE='xyz'
  NEED_NEWLINE='false'
}

log_error() {
  if [[ "$NEED_NEWLINE" == "true" ]]; then
    printf "\n\e[31m%s\e[0m\n" "$(getdate) ERROR $1"
  else
    printf "\e[31m%s\e[0m\n" "$(getdate) ERROR $1"
  fi
  PREV_LINE='xyz'
  NEED_NEWLINE='false'
}

log_ok() {
  if [[ "$NEED_NEWLINE" == "true" ]]; then
    printf "\n\e[32m%s\e[0m\n" "$(getdate) INFO $1"
  else
    printf "\e[32m%s\e[0m\n" "$(getdate) INFO $1"
  fi
  PREV_LINE='xyz'
  NEED_NEWLINE='false'
}

GLAB_EXIT_CODE=''
GLAB_OUTPUT=''

get_glab_output() {
  set +e
  GLAB_OUTPUT="$( bash -c 'glab ci get --output json 2>&1' )"
  GLAB_EXIT_CODE="$?"
  set -e
  if [[ "${GLAB_EXIT_CODE}" == "0" ]]; then
    :
  elif [[ "$GLAB_OUTPUT" == 'ERROR: no open merge request available for "main"' ]]; then
    GLAB_OUTPUT='{}'
  else
    log_error "Unexpected exit code ${GLAB_EXIT_CODE} stdout/stderr was: ${GLAB_OUTPUT}"
    exit "${GLAB_EXIT_CODE}"
  fi
}

LAST_PIPELINE_ID='INIT'
while true; do
  get_glab_output
  PIPELINE="$( echo "$GLAB_OUTPUT" | { jq -r '.' 2>/dev/null || echo '{}'; })"
  PIPELINE_ID="$(echo "${PIPELINE}" | jq -r '.id')"
  if [[ "${PIPELINE_ID}" == "${LAST_PIPELINE_ID}" ]]; then
    log_status "waiting for new pipeline ..."
    sleep 1
  elif [[ "${PIPELINE_ID}" == 'null' ]]; then
    log_status "waiting for new pipeline ..."
    sleep 1
  else
    LAST_PIPELINE_ID="${PIPELINE_ID}"
    while true; do
      get_glab_output
      PIPELINE="$( echo "$GLAB_OUTPUT" | { jq -r '.' 2>/dev/null || echo '{}'; })"
      PIPELINE_ID="$(echo "${PIPELINE}" | jq -r '.id')"
      PIPELINE_STATUS="$(echo "${PIPELINE}" | jq -r '.status')"

      if [[ "${PIPELINE_ID}" == "${LAST_PIPELINE_ID}" ]]; then
        if [[ "${PIPELINE_STATUS}" == "running" ]]; then
          log_status "waiting for pipeline ${PIPELINE_ID} (${PIPELINE_STATUS}) to finish ..."
          sleep 1
        elif [[ "${PIPELINE_STATUS}" == "pending" ]]; then
          log_status "waiting for pipeline ${PIPELINE_ID} (${PIPELINE_STATUS}) to finish ..."
          sleep 1
        elif [[ "${PIPELINE_STATUS}" == "null" ]]; then
          sleep 1
        elif [[ "${PIPELINE_STATUS}" == "failed" ]]; then
          if [[ "[]" == "$(echo "${PIPELINE}" | jq -r '.jobs')" ]]; then
            log_error "pipeline ${PIPELINE_ID} failed and no jobs available"
            break
          else
            printf '\033[3J' # clear scrollback
            printf '\033[2J' # clear whole screen without moving the cursor
            printf '\033[H' # move cursor to top left of the screen
            log_error "pipeline ${PIPELINE_ID} failed, dumping logs:"
            JOB_ID="$(echo "${PIPELINE}" | jq -r '.jobs[-1].id')"
            glab ci trace "${JOB_ID}"
            log_error "pipeline ${PIPELINE_ID} failed"
            break
          fi
        elif [[ "${PIPELINE_STATUS}" == "success" ]]; then
          printf '\033[3J' # clear scrollback
          printf '\033[2J' # clear whole screen without moving the cursor
          printf '\033[H' # move cursor to top left of the screen
          log_ok "pipeline ${PIPELINE_ID} succeeded. Dumping logs:"
          JOB_ID="$(echo "${PIPELINE}" | jq -r '.jobs[-1].id')"
          glab ci trace "${JOB_ID}"
          log_ok "pipeline ${PIPELINE_ID} succeeded"
          break
        else
          log_error "unhandled pipeline status '${PIPELINE_STATUS}'"
          sleep 1
        fi
      else
        log_info "pipeline changed to ${PIPELINE_ID}"
        break
      fi
    done
  fi
done

