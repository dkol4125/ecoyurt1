#!/usr/bin/env bash
set -euo pipefail

# Translate every English setup guide under docs/en/ into Uzbek and Russian.
# For each `docs/en/NAME.md`, produce:
#   docs/uz/NAME.md  – Uzbek translation
#   docs/ru/NAME.md  – Russian translation

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_LANG_DIR="${ROOT_DIR}/docs/en"
TARGET_LANG_DIRS=("${ROOT_DIR}/docs/uz" "${ROOT_DIR}/docs/ru")
LANGS=("Uzbek" "Russian")

API_KEY="${OPENAI_API_KEY:-}"
MODEL="${OPENAI_MODEL:-gpt-4o-mini}"
API_URL="${OPENAI_API_URL:-https://api.openai.com/v1/chat/completions}"

if [[ -z "${API_KEY}" ]]; then
  echo "ERROR: OPENAI_API_KEY environment variable is not set." >&2
  exit 1
fi

for bin in curl jq; do
  if ! command -v "${bin}" >/dev/null 2>&1; then
    echo "ERROR: Required dependency '${bin}' is not installed or not on PATH." >&2
    exit 1
  fi
done

if [[ ! -d "${SOURCE_LANG_DIR}" ]]; then
  echo "ERROR: Expected source directory docs/en/ not found at ${SOURCE_LANG_DIR}" >&2
  exit 1
fi

for dir in "${TARGET_LANG_DIRS[@]}"; do
  mkdir -p "${dir}"
done

SYSTEM_PROMPT=$(cat <<'EOF'
You are a meticulous technical translator. Take the provided Markdown documentation
and translate it into the requested target language while preserving headings, bullet
structure, code blocks, inline code, and formatting. Keep all technical, financial, and
legal terminology accurate and natural for professionals. Do not add commentary or omit
sections. Ensure front-matter or Markdown syntax remains valid.
EOF
)

translate_file() {
  local source_file="$1"
  local language="$2"
  local destination_file="$3"

  echo "Translating ${source_file} → ${destination_file} (${language})"

  local content
  content="$(cat "${source_file}")"

  local payload
  payload=$(jq -n \
    --arg model "${MODEL}" \
    --arg system "${SYSTEM_PROMPT}" \
    --arg user "Translate the following document into ${language}. Output valid Markdown only." \
    --arg src "${content}" \
    '{
        model: $model,
        temperature: 0.2,
        messages: [
          {role: "system", content: $system},
          {role: "user", content: ($user + "\n\n" + $src)}
        ]
      }'
  )

  local response
  response=$(curl -sS \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    "${API_URL}" )

  local api_error
  api_error="$(echo "${response}" | jq -r '.error.message? // empty' 2>/dev/null || true)"
  if [[ -n "${api_error}" ]]; then
    echo "ERROR: OpenAI API error for ${language} translation:" >&2
    echo "${api_error}" >&2
    echo "Full response:" >&2
    echo "${response}" >&2
    exit 1
  fi

  if [[ -z "${response}" ]]; then
    echo "ERROR: Empty response from OpenAI API for ${language} translation." >&2
    exit 1
  fi

  local translation
  translation="$(echo "${response}" | jq -r '.choices[0].message.content' 2>/dev/null || true)"

  if [[ -z "${translation}" || "${translation}" == "null" ]]; then
    echo "ERROR: Failed to extract translation for ${language} from API response." >&2
    echo "Full response:" >&2
    echo "${response}" >&2
    exit 1
  fi

  printf '%s\n' "${translation}" > "${destination_file}"
  echo "Wrote ${destination_file}"
}

for source_path in "${SOURCE_LANG_DIR}"/*.md; do
  base_name="$(basename "${source_path}")"
  for idx in "${!LANGS[@]}"; do
    dest_dir="${TARGET_LANG_DIRS[$idx]}"
    dest_file="${dest_dir}/${base_name}"
    translate_file "${source_path}" "${LANGS[$idx]}" "${dest_file}"
  done
done
