function main() {
  local lib bin
  lib=$(<lib)
  for bin in $(echo "$lib" | grep function | grep -v err | grep -v _ | awk '{print $2}' | sed 's/()//g'); do
    genBin "$bin"
  done
}

function genBin() {
  local bin
  bin=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  header > "$bin"
  echo "$1 \$@" >> "$bin"
  chmod +x "$bin"
}

function header()
{
cat <<'EOF'
#!/bin/bash -e
cd "$(dirname "$0")" || { echo "Failed to change directory" 1>&2; exit 2; }
[ -f lib ] || { echo "File lib not found" 1>&2; exit 2; }
source lib
EOF
}

main "$@"
