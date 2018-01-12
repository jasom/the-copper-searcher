#!/bin/sh
set -e

cu_XARGS_NULL=yes
cu_XARGS_PARALLEL=8
cu_STRICT_PARALLEL=yes
#unset cu_STRICT_PARALLEL

#unset cu_XARGS_PARALLEL

cu_RS="$(printf '\036')"

cuopt_IGNORE_CASE=smart
# Usages of this get compiled in by build.sh
# But we have it here so changes to the scripts can be tested without building
cu_INCLUDE() {
    eval "$(sh "$(dirname "$0")/$1")"
}

quiet() {
    "$@" > /dev/null
}

#Safer echo
ech() {
    printf '%s\n' "$*"
}

pattern_match() {
    test -z "${1##$2}"
}

rsecho() {
    for item in "$@"; do
        printf '%s%s' "$item" "$cu_RS"
    done
}

die() {
    ech "$*" >&2
    exit 127
}

shescape() {
    if test "${1%%\'*}" = "${1}"; then
        printf \''%s'\' "$1"
    else
        printf \'%s\'\\\\\' "${1%%\'*}"
        shescape "${1#*\'}"
    fi
}

fixed_strings() {
    cuopt_PATTERN_FORMAT=fixed
}

smart_case() {
    cuopt_IGNORE_CASE=smart
}

filetype() {
    cuopt_FILETYPE="$2"
}

grep_passthrough() {
    cuopt_GREP_OPTIONS="${cuopt_GREP_OPTIONS}${cuopt_GREP_OPTIONS+$cu_RS}$1"
}

list_matched_files() {
    grep_passthrough -l
    cuopt_NO_GROUP=yes
}

list_unmatched_files() {
    grep_passthrough -L
    cuopt_NO_GROUP=yes
}

grep_passthrough_arg() {
    grep_passthrough "$1"
    grep_passthrough "$2"
}

search_depth() {
    if test "$2" -eq "-1"; then
        unset cuopt_SEARCH_DEPTH
    else
        cuopt_SEARCH_DEPTH="$2"
    fi
}

filename_search() {
    cuopt_PATTERN=''
    cuopt_FILE_MATCH_GLOB="$2"
    grep_passthrough -l
}

filename_pattern() {
    cuopt_FILE_MATCH_GLOB="$2"
}

starting_point() {
    if test "${1%%"${cu_RS}*"}" != "${1}"; then
        die "ASCII RS not allowed in pathnames"
    fi
    if test -n "${cuopt_STARTING_POINT+x}"; then
        cuopt_STARTING_POINT="${cuopt_STARTING_POINT}${cu_RS}$1"
    else
        cuopt_STARTING_POINT="$1"
    fi
}

positional_parameter() {
    if test -z "${cuopt_PATTERN+x}"; then
        cuopt_PATTERN="$1"
    else
        starting_point "$1"
    fi
}

cu_INCLUDE options.sh

add_option() {
    pattern_match "$1x" "*$cu_RS*" && die "Option '$1' contained our record separator character!"
    if test -z "$cu_OPTION_PRINTED"; then
        printf '%s' "$1"
        cu_OPTION_PRINTED=yes
    else
        printf '%s%s' "$cu_RS" "$1"
    fi
}

add_options() {
    for opt in "$@"; do add_option "$opt"; done
}

## This will be expanded unquoted!!
grep_options() {
    # if we aren't printing filenames, groups don't matter
    if test -n "$cuopt_NO_FILENAME"; then
        cuopt_NO_GROUP=yes
    fi
    if test "$cuopt_IGNORE_CASE" = smart; then
        if pattern_match "$cuopt_PATTERN" '*[[:upper:]]*'; then
            unset cuopt_IGNORE_CASE
        else
            cuopt_IGNORE_CASE=yes
        fi
    fi
    for option in $cuopt_GREP_OPTIONS; do
        add_option "$option"
    done

    if test -z "$cuopt_NO_FILENAME"; then
        add_option -H
    else
        add_option -h
    fi

    test -n "$cuopt_IGNORE_CASE" && add_option -i
    test -z "$cuopt_NO_COLOR" && add_option '--color=always'
    case "${cuopt_PATTERN_FORMAT:-basic}" in
        basic   ) add_option -G ;;
        perl    ) add_option -P ;;
        fixed   ) add_option -F ;;
        extended) add_option -E ;;
    esac
    if test -z "${cuopt_NO_GROUP}"; then
        add_option -Z
    fi
    add_options -- "$cuopt_PATTERN"
    #printf '%s' "$cuopt_GREP_OPTIONS"
}

find_options() {
    # Options
    add_option -H
    add_option -O2
    add_option --

    # Starting Points
    for arg in "$@"; do
        if pattern_match "$arg" "-*"; then
            add_option "./$arg"
        else
            add_option "$arg"
        fi
    done

    # Expression
    test -n "$cuopt_SEARCH_DEPTH" && \
        add_options -maxdepth "$cuopt_SEARCH_DEPTH"
    test -z "${cuopt_HIDDEN_FILES}" && \
        add_options -name '.?*' -prune -o
    add_options -xtype f
    if test -n "${cuopt_FILETYPE}"; then
        add_option \(
        language_expr "${cuopt_FILETYPE-none}"
        add_option \)
    fi
    test -n "$cuopt_FILE_MATCH_GLOB" && \
        add_options -name "$cuopt_FILE_MATCH_GLOB"
    if test -z "$cu_XARGS_NULL"; then
        add_options -exec grep
        grep_options
        add_options {} +
    else
        add_options -print0
    fi
    unset cu_OPTION_PRINTED
}
    
serialize_results() {
    while true; do
        for item in "$1"/*.done; do
            cat "$item"
            rm -f "$item"
        done
        test -e "$1"/*.done && test -e "$1/alldone" && break
        sleep 0.1
    done
}

xargs_options() {
    add_options -L 1024 -0
    test -n "$cu_XARGS_PARALLEL" && add_options -P "$cu_XARGS_PARALLEL"
    if test -n "$cu_STRICT_PARALLEL"; then
        # shellcheck disable=SC2016
        add_options sh -c 'outdir="$1"; shift; outname="$(mktemp "$outdir/output.XXXXXXXX")"; grep "$@" > $outname; mv "$outname" "$outname.done"' -- "$1"
    else
        add_option grep
    fi
    grep_options
    unset cu_OPTION_PRINTED
}

group() {
    if test -n "$cuopt_NO_GROUP" || test -n "$cuopt_NO_FILENAME"; then
        cat
    else
        gawk 'BEGIN {OFS=FS="\000"} fname!=$1 {fname=$1; printf("%s\n",fname)} NF > 0 {for (i=1;i<NF;++i) $i = $(i+1); NF-=1; printf("%s\n",$0)}'
    fi
}

dispatch_results() {
    if test -z "$cu_STRICT_PARALLEL"; then
        # shellcheck disable=SC2046
        xargs $(xargs_options)
    else
        tmpdir="$(mktemp -d)"
        # shellcheck disable=SC2046
        xargs $(xargs_options "$tmpdir")
        set +f
        cat "$tmpdir"/*
        set -f
        rm -rf "$tmpdir"
    fi
}

invoke_search() {
    oldOPTS="$(set +o)"
    set -f
    # default field splitting needed
    IFS="$cu_RS"
    # shellcheck disable=SC2046,SC2014,SC2038
    if test -z "$cu_XARGS_NULL"; then
        find  $(find_options "$@")
    else
        find $(find_options "$@") | dispatch_results
        #find $(find_options "$@") | parallel --null --will-cite -P 8 -m -L 1024 grep $(grep_options)
    fi | group
    #find $(find_options "$@") -print0 |xargs -P 8 -L 256 -0 grep  $(grep_options) -- "$cuopt_PATTERN"
    eval "$oldOPTS"
}

parse_options "$@"
oldIFS="$IFS"
IFS="$cu_RS"
set -f
# shellcheck disable=SC2086
invoke_search $cuopt_STARTING_POINT
IFS="$oldIFS"
