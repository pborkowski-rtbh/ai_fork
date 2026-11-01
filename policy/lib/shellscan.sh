# Quote-aware shell scanner shared by the guard hooks. Works on bash 3.2.
#
# scan_command "<text>" fills:
#   SCAN_SEGMENTS  one entry per simple command, tokens joined by the unit separator
#   SCAN_UNQUOTED  operators, redirects, newlines and substitutions seen outside single quotes
#
# Command substitution counts as a segment boundary, so `echo $(gh pr merge 1)`
# yields a segment for `gh pr merge 1`.

SCAN_US=$'\037'

scan_command() {
  local s="$1" len=${#1} i=0 c n
  local state=plain token="" have_token=0 segment="" have_segment=0
  SCAN_SEGMENTS=()
  SCAN_UNQUOTED=""

  _scan_end_token() {
    if [ "$have_token" = 1 ]; then
      if [ "$have_segment" = 1 ]; then segment="$segment$SCAN_US$token"; else segment="$token"; have_segment=1; fi
    fi
    token=""; have_token=0
  }
  _scan_end_segment() {
    _scan_end_token
    if [ "$have_segment" = 1 ]; then SCAN_SEGMENTS[${#SCAN_SEGMENTS[@]}]="$segment"; fi
    segment=""; have_segment=0
  }

  while [ "$i" -lt "$len" ]; do
    c="${s:$i:1}"; n="${s:$((i+1)):1}"
    case "$state" in
      single)
        if [ "$c" = "'" ]; then state=plain; else token="$token$c"; fi
        ;;
      double)
        case "$c" in
          '"') state=plain ;;
          '\') token="$token$n"; i=$((i+1)) ;;
          '`') SCAN_UNQUOTED="$SCAN_UNQUOTED \`"; _scan_end_segment; have_token=1 ;;
          '$')
            SCAN_UNQUOTED="$SCAN_UNQUOTED \$"
            if [ "$n" = "(" ]; then _scan_end_segment; i=$((i+1)); else token="$token$c"; fi
            ;;
          ')') _scan_end_segment; have_token=0 ;;
          *) token="$token$c" ;;
        esac
        ;;
      *)
        case "$c" in
          "'") state=single; have_token=1 ;;
          '"') state=double; have_token=1 ;;
          '\') token="$token$n"; have_token=1; i=$((i+1)) ;;
          ' '|$'\t') _scan_end_token ;;
          $'\n') SCAN_UNQUOTED="$SCAN_UNQUOTED newline"; _scan_end_segment ;;
          ';'|'&'|'|'|'('|')') SCAN_UNQUOTED="$SCAN_UNQUOTED $c"; _scan_end_segment ;;
          '<'|'>') SCAN_UNQUOTED="$SCAN_UNQUOTED $c"; _scan_end_token ;;
          '`') SCAN_UNQUOTED="$SCAN_UNQUOTED \`"; _scan_end_segment ;;
          '$')
            SCAN_UNQUOTED="$SCAN_UNQUOTED \$"
            if [ "$n" = "(" ]; then _scan_end_segment; i=$((i+1)); else token="$token$c"; have_token=1; fi
            ;;
          *) token="$token$c"; have_token=1 ;;
        esac
        ;;
    esac
    i=$((i+1))
  done
  if [ "$state" != plain ]; then SCAN_UNQUOTED="$SCAN_UNQUOTED unterminated-quote"; fi
  _scan_end_segment
  unset -f _scan_end_token _scan_end_segment
}
