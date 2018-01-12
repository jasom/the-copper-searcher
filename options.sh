cu_INCLUDE() {
    eval "$(sh "$(dirname "$0")/$1")"
}

define_simple_option() {
    fname="$1"
    shift
    option="'$1'"
    shift
    while test -n "$*"; do
        option="$option | '$1'"
        shift
    done
    # shellcheck disable=SC2016
    cu_OPTION_PARSER="$(printf '%s\n%s) %s "$1"; shift ;;' "$cu_OPTION_PARSER" "$option" "$fname")"
}

define_argument_option() {
    fname="$1"
    shift
    option="'$1'"
    shift
    while test -n "$*"; do
        option="$option | '$1'"
        shift
    done
    # shellcheck disable=SC2016
    cu_OPTION_PARSER="$(printf '%s\n%s) %s "$1" "$2"; shift 2;;' "$cu_OPTION_PARSER" "$option" "$fname")"
    # shellcheck disable=SC2016
    cu_OPTION_PARSER="$(printf '%s\n%s=*) %s "$1{%%=*}" "${1#*=}"; shift ;;' "$cu_OPTION_PARSER" "$option" "$fname")"
}

define_toggle_option() {
    toggle_fname="$1"
    option_name="$2"
    shift 2
    cat <<EOF
SET_$toggle_fname() {
    $option_name=yes
}

CLEAR_$toggle_fname() {
    unset $option_name
}

EOF
    while test -n "$*"; do
        define_simple_option "$1_$toggle_fname" "$2"
        shift 2
    done
}



define_simple_option ignore_case -i --ignore-case
define_simple_option case_sensitive -s --case-sensitive
define_simple_option fixed_strings -Q --literal -F --fixed-strings
define_simple_option smart_case -S --smart-case
define_simple_option hidden_files --hidden
define_argument_option filetype --type
define_simple_option grep_passthrough -w --word-regexp
define_simple_option grep_passthrough -v --invert-match
define_simple_option list_matched_files -l --files-with-matches
define_simple_option list_unmatched_files -L --files-without-match
define_simple_option grep_passthrough -o --only-matching
define_simple_option no_numbers --nonumbers
define_simple_option numbers --numbers
define_simple_option grep_passthrough -c --count
define_argument_option grep_passthrough_arg -A --after
define_argument_option grep_passthrough_arg -B --before
define_argument_option grep_passthrough_arg -C --context
define_argument_option grep_passthrough_arg -m --max-count
define_simple_option no_filename --no-filename --no-heading
define_simple_option with_filename -H --with-filename --heading
define_argument_option search_depth --depth
define_argument_option filename_search -g
define_argument_option filename_pattern -G
define_toggle_option no_color cuopt_NO_COLOR SET --nocolor CLEAR --color

. "$(dirname "$0")"/filetypes.sh

cat <<'EOF'
parse_options() {
    while test -n "$*"; do
        if printf '%s' "$1" | quiet grep '^-'; then
            case "$1" in
EOF
printf '%s\n' "$cu_OPTION_PARSER"
cat <<'EOF'
                -[!-][!-]*) arg="$1"; shift; set -- "$(ech "$arg"|head -c2)" "-${arg#??}" "$@"; continue ;;
                *) die "Unknown option: $1" ;;
            esac
        elif test -z "${cuopt_PATTERN+x}"; then
            cuopt_PATTERN="$1"; shift
        else
            starting_point "$1"
            shift
        fi
    done
}
EOF
