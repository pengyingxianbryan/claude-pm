#!/usr/bin/env bash
# PM PreToolUse hook — blocks `git commit` / `git push` when the staged diff
# (commit) or the branch diff vs main (push) contains a secret-shaped string.
# Prose rules get rationalised past; an exit-2 hook does not.
#
# Receives the tool call as JSON on stdin. Exit 0 = allow, exit 2 = block
# (stderr is shown to Claude as the reason).
set -uo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)

case "$cmd" in
  *"git commit"*) range="--cached" ;;
  *"git push"*)   range="main...HEAD" ;;
  *) exit 0 ;;
esac

# Not a git repo / no main yet — nothing to gate.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
if [[ "$range" == "main...HEAD" ]] && ! git rev-parse --verify main >/dev/null 2>&1; then
  exit 0
fi

# Added lines only. Skip lockfiles, .env.example, and this hook itself.
# shellcheck disable=SC2086
diff=$(git diff $range --unified=0 -- . \
  ':(exclude)*.lock' ':(exclude)*-lock.*' ':(exclude)*.env.example' ':(exclude)*secrets-gate.sh' \
  2>/dev/null | grep -E '^\+[^+]' || true)
[[ -z "$diff" ]] && exit 0

pattern='AKIA[0-9A-Z]{16}'
pattern+='|sk-(live|test|proj)?-?[A-Za-z0-9]{20,}'
pattern+='|gh[pousr]_[A-Za-z0-9]{36,}'
pattern+='|xox[baprs]-[A-Za-z0-9-]{10,}'
pattern+='|-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY'
pattern+='|eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'
pattern+='|(api[_-]?key|secret[_-]?key|client[_-]?secret|password|passwd|access[_-]?token|auth[_-]?token|private[_-]?key)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][A-Za-z0-9/+_=.-]{12,}["'"'"']'

hits=$(printf '%s\n' "$diff" | grep -inE "$pattern" | grep -viE 'example|placeholder|changeme|your[_-]|xxx|<[a-z_]+>|process\.env|os\.environ|\$\{' || true)
[[ -z "$hits" ]] && exit 0

{
  echo "SECRETS GATE — blocked $(printf '%s' "$cmd" | cut -c1-60)"
  echo "Secret-shaped strings in added lines ($range):"
  printf '%s\n' "$hits" | cut -c1-160 | head -10
  echo
  echo "Move the value to an env var, document it in .env.example, and re-run."
  echo "If it was ever pushed, rotate it — removing it from git does not unleak it."
} >&2
exit 2
