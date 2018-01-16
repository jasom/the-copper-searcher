# shellcheck source=option_parse.sh
. "$(dirname "$0")/option_parse.sh"

define_simple_option fixed_strings -Q --literal -F --fixed-strings
define_simple_option smart_case -S --smart-case
define_simple_option grep_passthrough -w --word-regexp
define_simple_option grep_passthrough -v --invert-match
define_simple_option list_matched_files -l --files-with-matches
define_simple_option list_unmatched_files -L --files-without-match
define_simple_option grep_passthrough -o --only-matching
define_simple_option grep_passthrough -c --count
define_simple_option unrestricted -u --unrestricted
define_simple_option skip_vcs_ignores -U --skip-vcs-ignores
define_simple_option all_types -a --all-types
define_simple_option all_text -t --al-text
define_toggle_option one_device cuopt_ONE_DEVICE SET --one-device
define_argument_option grep_passthrough_arg -A --after
define_argument_option grep_passthrough_arg -B --before
define_argument_option grep_passthrough_arg -C --context
define_argument_option grep_passthrough_arg -m --max-count
define_argument_option search_depth --depth
define_argument_option filename_search -g
define_argument_option filename_pattern -G
define_argument_option ignore_file --ignore --ignore-dir
define_argument_option path_to_ignore -p --path-to-ignore
define_toggle_option no_color cuopt_NO_COLOR SET --nocolor CLEAR --color
define_toggle_option hidden_files cuopt_HIDDEN_FILES SET --hidden CLEAR --nohidden
define_toggle_option no_filename cuopt_NO_FILENAME SET -H --with-filename --heading CLEAR --no-filename --no-heading
define_toggle_option search_binary cuopt_SEARCH_BINARY SET --search-binary
define_toggle_option no_numbers cuopt_NO_NUMBERS SET --nonumbers CLEAR --numbers
define_toggle_option no_group cuopt_NO_GROUP SET --nogroup --no-group CLEAR --group

# This var actually has 3 states (yes, cleared, smart), but handle the simple ones here
define_toggle_option ignore_case cuopt_IGNORE_CASE SET -i --ignore-case CLEAR -s --case-sensitive

. "$(dirname "$0")"/filetypes.sh

emit_option_parser
