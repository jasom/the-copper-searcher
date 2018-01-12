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
    opt_OPTION_PARSER="$(printf '%s\n%s) %s "$1"; shift ;;' "$opt_OPTION_PARSER" "$option" "$fname")"
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
    opt_OPTION_PARSER="$(printf '%s\n%s) %s "$1" "$2"; shift 2;;' "$opt_OPTION_PARSER" "$option" "$fname")"
    # shellcheck disable=SC2016
    opt_OPTION_PARSER="$(printf '%s\n%s=*) %s "$1{%%=*}" "${1#*=}"; shift ;;' "$opt_OPTION_PARSER" "$option" "$fname")"
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
        case "$1" in 
            SET) toggle_state=SET ;;
            CLEAR) toggle_state=CLEAR ;;
            *) define_simple_option "${toggle_state}_${toggle_fname}" "$1" ;;
        esac
        shift
    done
}

emit_option_parser() {
    cat <<EOF
parse_options() {
    while test -n "\$*"; do
        if printf '%s' "\$1" | quiet grep '^-'; then
            case "\$1" in
                $opt_OPTION_PARSER
                -[!-][!-]*) arg="\$1"; shift; set -- "\$(ech "\$arg"|head -c2)" "-\${arg#??}" "\$@"; continue ;;
                *) die "Unknown option: \$1" ;;
            esac
        else
            positional_parameter "\$1"
            shift
        fi
    done
}
EOF
}
