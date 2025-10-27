#!/usr/bin/env bash
set -euo pipefail

# Translate README.md into localized variants using the OpenAI API.
# Outputs:
#   README.uz.md  – Uzbek translation
#   README.ru.md  – Russian translation
#
# Requirements:
#   - curl and jq must be available on PATH
#   - OPENAI_API_KEY must be set with a valid API token
#   - Optional overrides: OPENAI_MODEL (default: gpt-4o-mini),
#     OPENAI_API_URL (default: https://api.openai.com/v1/chat/completions)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_FILE="${ROOT_DIR}/README.md"
FILES=(
  "README.uz.md"
  "README.ru.md"
)

LANGS=(
  "Uzbek"
  "Russian"
)

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

if [[ ! -f "${SOURCE_FILE}" ]]; then
  echo "ERROR: README.md not found at ${SOURCE_FILE}" >&2
  exit 1
fi

SOURCE_CONTENT="$(cat "${SOURCE_FILE}")"

SYSTEM_PROMPT=$(cat <<'EOF'
You are a meticulous technical translator. Take the provided Markdown documentation
and translate it into the requested target language while preserving headings, bullet
structure, code blocks, inline code, and formatting. Keep all technical and legal terminology
accurate and natural for professionals. Do not add commentary or omit sections. Ensure
front-matter or Markdown syntax remains valid.
EOF
)

translate() {
  local target_file="$1"
  local language="$2"

  echo "Translating README.md → ${target_file} (${language})"

  payload=$(
    jq -n \
      --arg model "${MODEL}" \
      --arg system "${SYSTEM_PROMPT}" \
      --arg user "Translate the following README into ${language}. Output valid Markdown only." \
      --arg content "${SOURCE_CONTENT}" \
      '{
        model: $model,
        temperature: 0.2,
        messages: [
          {role: "system", content: $system},
          {role: "user", content: ($user + "\n\n" + $content)}
        ]
      }'
  )

  response="$(
    curl -sS \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "${payload}" \
      "${API_URL}"
  )"

  api_error="$(echo "${response}" | jq -r '.error.message? // empty' 2>/dev/null || true)"
  if [[ -n "${api_error}" ]]; then
    echo "ERROR: OpenAI API returned an error for ${language} translation:" >&2
    echo "${api_error}" >&2
    echo "Full response:" >&2
    echo "${response}" >&2
    exit 1
  fi

  if [[ -z "${response}" ]]; then
    echo "ERROR: Empty response from OpenAI API for ${language} translation." >&2
    exit 1
  fi

  translation="$(echo "${response}" | jq -r '.choices[0].message.content' 2>/dev/null || true)"

  if [[ -z "${translation}" || "${translation}" == "null" ]]; then
    echo "ERROR: Failed to extract translation for ${language} from API response." >&2
    echo "Full response:" >&2
    echo "${response}" >&2
    exit 1
  fi

  printf '%s\n' "${translation}" > "${ROOT_DIR}/${target_file}"
  echo "Wrote ${target_file}"
}

for i in "${!FILES[@]}"; do
  translate "${FILES[$i]}" "${LANGS[$i]}"
done
