#!/usr/bin/env bash

usage() {
cat << EOF
Usage: $(basename $0) -c <cookie_value> [-b <backup_file>] [-v] [-h]

Options:
  -c <cookie_value>  Value of the 't' cookie from an authenticated web session
  -b <backup_file>   Location of a backup file to append deleted tasks to (optional)
  -v                 Show verbose output (optional)
  -h                 Shows this message
EOF
    exit
}

join_by() {
    local IFS="$1";
    shift;
    echo "$*";
}

COOKIE_VALUE=
BACKUP_FILE=
VERBOSE=

while [[ "${1}" != "" ]]; do
    case "${1}" in
        -c ) COOKIE_VALUE="${2}";;
        -b ) BACKUP_FILE="${2}";;
        -v ) VERBOSE=true;;
        -h ) usage; exit;;
    esac
    shift
done

if [ -z "${COOKIE_VALUE}" ]; then
    usage
    exit 1
fi

# Common headers for all requests
HEADERS=(
  -H 'accept: application/json, text/plain, */*'
  -H 'Accept-Language: en-US,en;q=0.9'
  -H 'hl: en'
  -H 'Priority: u=1, i'
  -H 'Sec-CH-UA: "Not.A/Brand";v="99", "Chromium";v="136"'
  -H 'Sec-CH-UA-Mobile: ?0'
  -H 'Sec-CH-UA-Platform: "macOS"'
  -H 'Sec-Fetch-Dest: empty'
  -H 'Sec-Fetch-Mode: cors'
  -H 'Sec-Fetch-Site: same-site'
  -H 'X-CSRFToken: '
  -H 'X-Device: {"platform":"web","os":"macOS","device":"Chrome","name":"","version":6306,"channel":"website"}'
  -H 'X-TZ: UTC'
  -H "Cookie: t=$COOKIE_VALUE"
  -e 'https://ticktick.com/'
  --compressed
)

TMP_FILE=$(mktemp --suffix '-ticktick-delete-completed-tasks.json')

function fetch_completed_tasks() {
    curl 'https://api.ticktick.com/api/v2/project/all/completedInAll/' "${HEADERS[@]}" > "${TMP_FILE}"
}

fetch_completed_tasks

if [ -n "${BACKUP_FILE}" ]; then
    echo "" > ${BACKUP_FILE}
fi

TOTAL_COUNT=0

while [[ $(wc -c "${TMP_FILE}" | cut -d " " -f1) -gt 10 ]]; do
    while read -r TASK; do
        if [ -n "${BACKUP_FILE}" ]; then
            echo ${TASK} >> ${BACKUP_FILE}
        fi

        PROJECT_ID=$(echo "${TASK}" | jq -r '.projectId')
        TASK_ID=$(echo "${TASK}" | jq -r '.id')

        COMMANDS+=('{"taskId": "'${TASK_ID}'", "projectId": "'${PROJECT_ID}'"}')

        if [ "${VERBOSE}" == "true" ]; then
            TOTAL_COUNT=$((TOTAL_COUNT + 1))
            if [[ $((TOTAL_COUNT % 100)) -eq 0 ]]; then
                echo "Total Count: ${TOTAL_COUNT}"
            fi
        fi
    done < <(cat "${TMP_FILE}" | jq -c '.[]')

    COMMANDS=$(join_by , "${COMMANDS[@]}")

    curl 'https://api.ticktick.com/api/v2/batch/task' "${HEADERS[@]}" \
      -H 'content-type: application/json;charset=UTF-8' \
      --data-raw '{"add":[],"update":[],"delete":['"${COMMANDS}"'],"addAttachments":[],"updateAttachments":[],"deleteAttachments":[]}'

    COMMANDS=()

    fetch_completed_tasks

done

rm -f "${TMP_FILE}"
