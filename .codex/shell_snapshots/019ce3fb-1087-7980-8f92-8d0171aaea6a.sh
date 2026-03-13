# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
VCS_INFO_formats () {
	setopt localoptions noksharrays NO_shwordsplit
	local msg tmp
	local -i i
	local -A hook_com
	hook_com=(action "$1" action_orig "$1" branch "$2" branch_orig "$2" base "$3" base_orig "$3" staged "$4" staged_orig "$4" unstaged "$5" unstaged_orig "$5" revision "$6" revision_orig "$6" misc "$7" misc_orig "$7" vcs "${vcs}" vcs_orig "${vcs}") 
	hook_com[base-name]="${${hook_com[base]}:t}" 
	hook_com[base-name_orig]="${hook_com[base-name]}" 
	hook_com[subdir]="$(VCS_INFO_reposub ${hook_com[base]})" 
	hook_com[subdir_orig]="${hook_com[subdir]}" 
	: vcs_info-patch-9b9840f2-91e5-4471-af84-9e9a0dc68c1b
	for tmp in base base-name branch misc revision subdir
	do
		hook_com[$tmp]="${hook_com[$tmp]//\%/%%}" 
	done
	VCS_INFO_hook 'post-backend'
	if [[ -n ${hook_com[action]} ]]
	then
		zstyle -a ":vcs_info:${vcs}:${usercontext}:${rrn}" actionformats msgs
		(( ${#msgs} < 1 )) && msgs[1]=' (%s)-[%b|%a]%u%c-' 
	else
		zstyle -a ":vcs_info:${vcs}:${usercontext}:${rrn}" formats msgs
		(( ${#msgs} < 1 )) && msgs[1]=' (%s)-[%b]%u%c-' 
	fi
	if [[ -n ${hook_com[staged]} ]]
	then
		zstyle -s ":vcs_info:${vcs}:${usercontext}:${rrn}" stagedstr tmp
		[[ -z ${tmp} ]] && hook_com[staged]='S'  || hook_com[staged]=${tmp} 
	fi
	if [[ -n ${hook_com[unstaged]} ]]
	then
		zstyle -s ":vcs_info:${vcs}:${usercontext}:${rrn}" unstagedstr tmp
		[[ -z ${tmp} ]] && hook_com[unstaged]='U'  || hook_com[unstaged]=${tmp} 
	fi
	if [[ ${quiltmode} != 'standalone' ]] && VCS_INFO_hook "pre-addon-quilt"
	then
		local REPLY
		VCS_INFO_quilt addon
		hook_com[quilt]="${REPLY}" 
		unset REPLY
	elif [[ ${quiltmode} == 'standalone' ]]
	then
		hook_com[quilt]=${hook_com[misc]} 
	fi
	(( ${#msgs} > maxexports )) && msgs[$(( maxexports + 1 )),-1]=() 
	for i in {1..${#msgs}}
	do
		if VCS_INFO_hook "set-message" $(( $i - 1 )) "${msgs[$i]}"
		then
			zformat -f msg ${msgs[$i]} a:${hook_com[action]} b:${hook_com[branch]} c:${hook_com[staged]} i:${hook_com[revision]} m:${hook_com[misc]} r:${hook_com[base-name]} s:${hook_com[vcs]} u:${hook_com[unstaged]} Q:${hook_com[quilt]} R:${hook_com[base]} S:${hook_com[subdir]}
			msgs[$i]=${msg} 
		else
			msgs[$i]=${hook_com[message]} 
		fi
	done
	hook_com=() 
	backend_misc=() 
	return 0
}
_SUSEconfig () {
	# undefined
	builtin autoload -XUz
}
___sdkman_check_candidates_cache () {
	local candidates_cache="$1" 
	if [[ -f "$candidates_cache" && -z "$(< "$candidates_cache")" ]]
	then
		__sdkman_echo_red 'WARNING: Cache is corrupt. SDKMAN cannot be used until updated.'
		echo ''
		__sdkman_echo_no_colour '  $ sdk update'
		echo ''
		return 1
	else
		__sdkman_echo_debug "Using existing cache: $SDKMAN_CANDIDATES_CSV"
		return 0
	fi
}
___sdkman_help () {
	if [[ -f "$SDKMAN_DIR/libexec/help" ]]
	then
		"$SDKMAN_DIR/libexec/help"
	else
		__sdk_help
	fi
}
__arguments () {
	# undefined
	builtin autoload -XUz
}
__bun_dynamic_comp () {
	local comp="" 
	for arg in scripts
	do
		local line
		while read -r line
		do
			local name="$line" 
			local desc="$line" 
			name="${name%$'\t'*}" 
			desc="${desc/*$'\t'/}" 
			echo
		done <<< "$arg"
	done
	return $comp
}
__function_on_stack () {
	__rvm_string_includes "${FUNCNAME[*]}" "$@" || return $?
}
__function_unset () {
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		unset -f "$1"
	else
		unset "$1"
	fi
}
__git_prompt_git () {
	GIT_OPTIONAL_LOCKS=0 command git "$@"
}
__list_remote_all () {
	\typeset _iterator rvm_remote_server_url rvm_remote_server_path
	_iterator="" 
	while __rvm_db "rvm_remote_server_url${_iterator:-}" rvm_remote_server_url
	do
		if __rvm_include_travis_binaries
		then
			__rvm_system_path "" "${_iterator}"
			rvm_debug "__list_remote_all${_iterator:-} $rvm_remote_server_url $rvm_remote_server_path"
			__list_remote_for "${rvm_remote_server_url}" "$rvm_remote_server_path"
		fi
		: $(( _iterator+=1 ))
	done | \command \sort -u | __rvm_version_sort
}
__list_remote_for () {
	__list_remote_for_local "$@" || __list_remote_for_index "$@" || __list_remote_for_s3 "$@" || return $?
}
__list_remote_for_index () {
	if file_exists_at_url "${1}/index.txt"
	then
		rvm_debug "__list_remote_for_index ${1}/index.txt"
		__rvm_curl -s "${1}/index.txt" | GREP_OPTIONS="" \command \grep -E "${1}/${2}/.*\.tar\.(gz|bz2)$"
	elif file_exists_at_url "${1}/${2}/index.txt"
	then
		rvm_debug "__list_remote_for_index ${1}/${2}/index.txt"
		__rvm_curl -s "${1}/${2}/index.txt" | GREP_OPTIONS="" \command \grep -E "${1}/${2}/.*\.tar\.(gz|bz2)$"
	else
		return 1
	fi
	true
}
__list_remote_for_local () {
	\typeset __status1 __status2
	__status1=0 
	__status2=0 
	if [[ -f $rvm_user_path/remote ]]
	then
		__rvm_grep "${1}/${2}" < $rvm_user_path/remote || __status1=$? 
	fi
	__rvm_grep "${1}/${2}" < $rvm_path/config/remote || __status2=$? 
	if (( __status1 || __status2 ))
	then
		return 1
	else
		rvm_debug "__list_remote_for_local found"
	fi
	true
}
__list_remote_for_s3 () {
	curl -ILfs "${1}" | __rvm_grep "Server: AmazonS3" > /dev/null || return $?
	\typeset __tmp_name __iterator __next __local_url
	__iterator=0 
	__next="" 
	__tmp_name="$(
    : ${TMPDIR:=${rvm_tmp_path:-/tmp}}
    mktemp "${TMPDIR}/tmp.XXXXXXXXXXXXXXXXXX"
  )" 
	while [[ __iterator -eq 0 || -n "${__next}" ]]
	do
		__local_url="${1}?prefix=${2}/${__next:+&marker=${__next}}" 
		rvm_debug "__list_remote_for_s3-${__iterator} ${__local_url}"
		__rvm_curl -s "${__local_url}" > "${__tmp_name}${__iterator}"
		GREP_OPTIONS="" \command \grep -oE "<Key>[^<]*</Key>" < "${__tmp_name}${__iterator}" | __rvm_awk -F"[<>]" '{print $3}' > "${__tmp_name}"
		if __rvm_grep "<IsTruncated>true</IsTruncated>" < "${__tmp_name}${__iterator}"
		then
			__next="$(__rvm_tail -n 1 "${__tmp_name}")" 
		else
			__next="" 
		fi
		rm "${__tmp_name}${__iterator}"
		: $(( __iterator+=1 ))
	done
	GREP_OPTIONS="" \command \grep -E "${2}/.*\.tar\.(gz|bz2)$" < "${__tmp_name}" | GREP_OPTIONS="" \command \grep -v -- "-src-" | __rvm_awk "{ print "'"'$1/'"'"\$1 }"
	rm "${__tmp_name}"*
}
__map_tar_excludes () {
	\typeset __exclude_element
	for __exclude_element
	do
		__exclude_elements+=(--exclude "${__exclude_element}") 
	done
}
__nvm () {
	declare previous_word
	previous_word="${COMP_WORDS[COMP_CWORD - 1]}" 
	case "${previous_word}" in
		(use | run | exec | ls | list | uninstall) __nvm_installed_nodes ;;
		(alias | unalias) __nvm_alias ;;
		(*) __nvm_commands ;;
	esac
	return 0
}
__nvm_alias () {
	__nvm_generate_completion "$(__nvm_aliases)"
}
__nvm_aliases () {
	declare aliases
	aliases="" 
	if [ -d "${NVM_DIR}/alias" ]
	then
		aliases="$(command cd "${NVM_DIR}/alias" && command find "${PWD}" -type f | command sed "s:${PWD}/::")" 
	fi
	echo "${aliases} node stable unstable iojs"
}
__nvm_commands () {
	declare current_word
	declare command
	current_word="${COMP_WORDS[COMP_CWORD]}" 
	COMMANDS='
    help install uninstall use run exec
    alias unalias reinstall-packages
    current list ls list-remote ls-remote
    install-latest-npm
    cache deactivate unload
    version version-remote which' 
	if [ ${#COMP_WORDS[@]} == 4 ]
	then
		command="${COMP_WORDS[COMP_CWORD - 2]}" 
		case "${command}" in
			(alias) __nvm_installed_nodes ;;
		esac
	else
		case "${current_word}" in
			(-*) __nvm_options ;;
			(*) __nvm_generate_completion "${COMMANDS}" ;;
		esac
	fi
}
__nvm_generate_completion () {
	declare current_word
	current_word="${COMP_WORDS[COMP_CWORD]}" 
	COMPREPLY=($(compgen -W "$1" -- "${current_word}")) 
	return 0
}
__nvm_installed_nodes () {
	__nvm_generate_completion "$(nvm_ls) $(__nvm_aliases)"
}
__nvm_options () {
	OPTIONS='' 
	__nvm_generate_completion "${OPTIONS}"
}
__rvm_add_once () {
	\typeset IFS
	IFS="|" 
	eval "[[ \"${IFS}\${${1}[*]}${IFS}\" == \*\"${IFS}\${2}${IFS}\"\* ]] || ${1}+=( \"\${2}\" )"
}
__rvm_add_to_path () {
	export PATH
	if (( $# != 2 )) || [[ -z "$2" ]]
	then
		rvm_error "__rvm_add_to_path requires two parameters"
		return 1
	fi
	__rvm_remove_from_path "$2"
	case "$1" in
		(prepend) PATH="$2:$PATH"  ;;
		(append) PATH="$PATH:$2"  ;;
	esac
	if [[ -n "${rvm_user_path_prefix:-}" ]]
	then
		__rvm_remove_from_path "${rvm_user_path_prefix}"
		PATH="${rvm_user_path_prefix}:$PATH" 
	fi
	builtin hash -r
}
__rvm_after_cd () {
	\typeset rvm_hook
	rvm_hook="after_cd" 
	if [[ -n "${rvm_scripts_path:-}" || -n "${rvm_path:-}" ]]
	then
		source "${rvm_scripts_path:-$rvm_path/scripts}/hook"
	fi
}
__rvm_ant () {
	\ant "$@" || return $?
}
__rvm_array_add_or_update () {
	\typeset _array_name _variable _separator _value _local_value
	\typeset -a _array_value_old _array_value_new
	_array_name="$1" 
	_variable="$2" 
	_separator="$3" 
	_value="${4##${_separator}}" 
	_array_value_new=() 
	eval "_array_value_old=( \"\${${_array_name}[@]}\" )"
	case " ${_array_value_old[*]} " in
		(*[[:space:]]${_variable}*) for _local_value in "${_array_value_old[@]}"
			do
				case "${_local_value}" in
					(${_variable}*) _array_value_new+=("${_local_value}${_separator}${_value}")  ;;
					(*) _array_value_new+=("${_local_value}")  ;;
				esac
			done ;;
		(*) _array_value_new=("${_array_value_old[@]}" "${_variable}${_value}")  ;;
	esac
	eval "${_array_name}=( \"\${_array_value_new[@]}\" )"
}
__rvm_array_contains () {
	\typeset _search _iterator
	_search="$1" 
	shift
	for _iterator
	do
		case "${_iterator}" in
			(${_search}) return 0 ;;
		esac
	done
	return 1
}
__rvm_array_prepend_or_ignore () {
	\typeset _array_name _variable _separator _value _prefix _local_value
	\typeset -a _array_value_old _array_value_new
	_array_name="$1" 
	_variable="$2" 
	_separator="$3" 
	_value="$4" 
	_prefix="$5" 
	_array_value_new=() 
	eval "_array_value_old=( \"\${${_array_name}[@]}\" )"
	case " ${_array_value_old[*]} " in
		(*[[:space:]]${_variable}*) for _local_value in "${_array_value_old[@]}"
			do
				case "${_local_value}" in
					(${_variable}*${_prefix}*) rvm_debug "__rvm_array_prepend_or_ignore ${_array_name} ${_local_value}"
						_array_value_new+=("${_local_value}")  ;;
					(${_variable}*) rvm_debug "__rvm_array_prepend_or_ignore ${_array_name} ${_variable}\"${_value}${_separator}${_local_value#${_variable}}\""
						_array_value_new+=("${_variable}${_value}${_separator}${_local_value#${_variable}}")  ;;
					(*) _array_value_new+=("${_local_value}")  ;;
				esac
			done
			eval "${_array_name}=( \"\${_array_value_new[@]}\" )" ;;
	esac
}
__rvm_ask_for () {
	\typeset response
	rvm_warn "$1"
	printf "%b" "(anything other than '$2' will cancel) > "
	if read response && [[ "$2" == "$response" ]]
	then
		return 0
	else
		return 1
	fi
}
__rvm_ask_to_trust () {
	\typeset trusted value anykey _rvmrc _rvmrc_base
	_rvmrc="${1}" 
	_rvmrc_base="$(basename "${_rvmrc}")" 
	if [[ ! -t 0 || -n "$MC_SID" ]] || (( ${rvm_promptless:=0} == 1 ))
	then
		return 2
	fi
	__rvm_file_notice_initial
	trusted=0 
	while (( ! trusted ))
	do
		printf "%b" 'y[es], n[o], v[iew], c[ancel]> '
		builtin read response
		value="$(echo -n "${response}" | \command \tr '[[:upper:]]' '[[:lower:]]' | __rvm_strip)" 
		case "${value:-n}" in
			(v | view) __rvm_display_rvmrc ;;
			(y | yes) trusted=1  ;;
			(n | no) break ;;
			(c | cancel) return 1 ;;
		esac
	done
	if (( trusted ))
	then
		__rvm_trust_rvmrc "$1"
		return 0
	else
		__rvm_untrust_rvmrc "$1"
		return 1
	fi
}
__rvm_automake () {
	\automake "$@" || return $?
}
__rvm_autoreconf () {
	\autoreconf "$@" || return $?
}
__rvm_awk () {
	\awk "$@" || return $?
}
__rvm_become () {
	\typeset string rvm_rvmrc_flag
	string="$1" 
	rvm_rvmrc_flag=0 
	[[ -n "$string" ]] && {
		rvm_ruby_string="$string" 
		rvm_gemset_name="" 
	}
	__rvm_use > /dev/null || return $?
	rvm_ruby_string="${rvm_ruby_string}${rvm_gemset_name:+${rvm_gemset_separator:-'@'}}${rvm_gemset_name:-}" 
	return 0
}
__rvm_calculate_remote_file () {
	rvm_remote_server_url="$( __rvm_db "rvm_remote_server_url${3:-}" )" 
	[[ -n "$rvm_remote_server_url" ]] || {
		rvm_debug "rvm_remote_server_url${3:-} not found"
		return $1
	}
	__rvm_include_travis_binaries || return $1
	__rvm_system_path "" "${3:-}"
	__rvm_ruby_package_file "${4:-}"
	__remote_file="${rvm_remote_server_url}/${rvm_remote_server_path}${rvm_ruby_package_file}" 
}
__rvm_calculate_space_free () {
	__free_space="$( \command \df -Pk "$1" | __rvm_awk 'BEGIN{x=4} /Free/{x=3} $3=="Avail"{x=3} END{print $x}' )" 
	if [[ "${__free_space}" == *M ]]
	then
		__free_space="${__free_space%M}" 
	else
		__free_space="$(( __free_space / 1024 ))" 
	fi
}
__rvm_calculate_space_used () {
	__used_space="$( \command \du -msc "$@" | __rvm_awk 'END {print $1}' )" 
	__used_space="${__used_space%M}" 
}
__rvm_call_with_restored_umask () {
	rvm_umask="$(umask)" 
	if [[ -n "${rvm_stored_umask:-}" ]]
	then
		umask ${rvm_stored_umask}
	fi
	"$@"
	umask "${rvm_umask}"
	unset rvm_umask
}
__rvm_cd () {
	\typeset old_cdpath ret
	ret=0 
	old_cdpath="${CDPATH}" 
	CDPATH="." 
	chpwd_functions="" builtin cd "$@" || ret=$? 
	CDPATH="${old_cdpath}" 
	return $ret
}
__rvm_cd_functions_set () {
	__rvm_do_with_env_before
	if [[ -n "${rvm_current_rvmrc:-""}" && "$OLDPWD" == "$PWD" ]]
	then
		rvm_current_rvmrc="" 
	fi
	__rvm_project_rvmrc >&2 || true
	__rvm_after_cd || true
	__rvm_do_with_env_after
	return 0
}
__rvm_check_pipestatus () {
	for __iterator
	do
		case "${__iterator}" in
			("") true ;;
			(0) true ;;
			(*) return ${__iterator} ;;
		esac
	done
	return 0
}
__rvm_check_rvmrc_trustworthiness () {
	(( ${rvm_trust_rvmrcs_flag:-0} == 0 )) || return 0
	[[ -n "$1" ]] || (( $# > 1 )) || return 1
	\typeset _first _second saveIFS
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		_first=1 
	else
		_first=0 
	fi
	_second=$(( _first + 1 )) 
	saveIFS="$IFS" 
	IFS=$';' 
	\typeset -a trust
	trust=($( __rvm_rvmrc_stored_trust "$1" )) 
	IFS="$saveIFS" 
	if [[ "${trust[${_second}]:-'#'}" == "$(__rvm_checksum_for_contents "$1")" ]]
	then
		[[ "${trust[${_first}]}" == '1' ]] || return $?
	else
		__rvm_ask_to_trust "$@" || return $?
	fi
	true
}
__rvm_checksum_all () {
	[[ -n "${_checksum_md5:-}" && -n "${_checksum_sha512:-}" ]]
}
__rvm_checksum_any () {
	[[ -n "${_checksum_md5:-}" || -n "${_checksum_sha512:-}" ]]
}
__rvm_checksum_calculate_file () {
	rvm_debug "Calculate checksums for file ${1}"
	_checksum_md5="$(    __rvm_md5_calculate      "${1:-}" )" 
	_checksum_sha512="$( __rvm_sha__calculate 512 "${1:-}" )" 
}
__rvm_checksum_for_contents () {
	\typeset __sum
	__sum=$(  echo "$1" | \command \cat - "$1" | __rvm_md5_for_contents   )  || {
		rvm_error "Neither md5 nor md5sum were found in the PATH"
		return 1
	}
	__sum+=$( echo "$1" | \command \cat - "$1" | __rvm_sha256_for_contents )  || {
		rvm_error "Neither sha256sum nor shasum found in the PATH"
		return 1
	}
	echo ${__sum}
}
__rvm_checksum_none () {
	[[ -z "${_checksum_md5:-}" && -z "${_checksum_sha512:-}" ]]
}
__rvm_checksum_read () {
	rvm_debug "Load checksums for $1"
	__rvm_checksum_any && return 0
	\typeset _type _value _name
	\typeset -a _list
	list=() 
	for _name in "$@"
	do
		if [[ "$_name" == *"?"* ]]
		then
			list+=("${_name%\?*}") 
		else
			list+=("$_name") 
		fi
	done
	for _name in "${list[@]}"
	do
		rvm_debug "Searching checksum config files for $_name"
		_checksum_md5="$(      __rvm_db_ "$rvm_path/config/md5"    "$_name" | \command \head -n 1 )" 
		[[ -n "${_checksum_md5:-}" ]] || _checksum_md5="$(    __rvm_db_ "$rvm_user_path/md5"      "$_name" | \command \head -n 1 )" 
		_checksum_sha512="$(   __rvm_db_ "$rvm_path/config/sha512" "$_name" | \command \head -n 1 )" 
		[[ -n "${_checksum_sha512:-}" ]] || _checksum_sha512="$( __rvm_db_ "$rvm_user_path/sha512"   "$_name" | \command \head -n 1 )" 
		__rvm_checksum_any && return 0
	done
	for _name in "${list[@]}"
	do
		if [[ $_name == http*rubinius* ]]
		then
			if [[ -z "${_checksum_md5:-}" ]]
			then
				_checksum_md5="$(__rvm_curl -s -L $_name.md5)" 
			fi
			if [[ -z "${_checksum_sha512:-}" ]]
			then
				_checksum_sha512="$(__rvm_curl -s -L $_name.sha512)" 
			fi
		fi
		__rvm_checksum_any && return 0
	done
	rvm_debug "    ...checksums not found"
	return 1
}
__rvm_checksum_validate_file () {
	rvm_debug "Validating checksums for file ${1}"
	if __rvm_checksum_any
	then
		rvm_debug "    ...checksums found in db"
	else
		rvm_debug "    ...checksums not found in db"
		return 1
	fi
	if [[ -n "${_checksum_md5:-}" ]]
	then
		rvm_debug "Validating md5 checksum"
		if [[ "$(__rvm_md5_calculate "${1:-}")" == "${_checksum_md5:-}" ]]
		then
			rvm_debug "    ...md5 checksum is valid!"
		else
			rvm_debug "    ...md5 checksum is not valid!!!"
			return 2
		fi
	fi
	if [[ -n "${_checksum_sha512:-}" ]]
	then
		rvm_debug "Validating sha15 checksum"
		if [[ "$(__rvm_sha__calculate 512 "${1:-}")" == "${_checksum_sha512:-}" ]]
		then
			rvm_debug "    ...sha512 checksum is valid!"
		else
			rvm_debug "    ...sha512 checksum is not valid!!!"
			return 3
		fi
	fi
	return 0
}
__rvm_checksum_write () {
	[[ -n "${1:-}" ]] || return 1
	__rvm_checksum_any || return 1
	[[ -z "${_checksum_md5:-}" ]] || __rvm_db_ "$rvm_user_path/md5" "${1:-}" "${_checksum_md5:-}"
	[[ -z "${_checksum_sha512:-}" ]] || __rvm_db_ "$rvm_user_path/sha512" "${1:-}" "${_checksum_sha512:-}"
	return 0
}
__rvm_cleanse_variables () {
	__rvm_unset_ruby_variables
	if [[ ${rvm_sticky_flag:-0} -eq 1 ]]
	then
		export rvm_gemset_name
	else
		unset rvm_gemset_name
	fi
	unset rvm_configure_flags rvm_patch_names rvm_make_flags
	unset rvm_env_string rvm_ruby_string rvm_action rvm_error_message rvm_force_flag rvm_debug_flag rvm_delete_flag rvm_summary_flag rvm_json_flag rvm_yaml_flag rvm_file_name rvm_user_flag rvm_system_flag rvm_install_flag rvm_llvm_flag rvm_sticky_flag rvm_rvmrc_flag rvm_gems_flag rvm_docs_flag rvm_ruby_alias rvm_static_flag rvm_archive_extension rvm_hook rvm_ruby_name rvm_remote_flag
	__rvm_load_rvmrc
}
__rvm_cleanup_tmp () {
	if [[ -d "${rvm_tmp_path}/" ]]
	then
		case "${rvm_tmp_path%\/}" in
			(*tmp) __rvm_rm_rf "${rvm_tmp_path}/${1:-$$}*" ;;
		esac
	fi
	true
}
__rvm_cli_autoreload () {
	if [[ ${rvm_reload_flag:-0} -eq 1 ]]
	then
		if [[ -s "$rvm_scripts_path/rvm" ]]
		then
			__rvm_project_rvmrc_lock=0 
			source "$rvm_scripts_path/rvm"
		else
			echo "rvm not found in $rvm_path, please install and run 'rvm reload'"
			__rvm_teardown
		fi
	else
		__rvm_teardown
	fi
}
__rvm_cli_autoupdate () {
	[[ " $* " == *" install "* && " $* " != *" help install "* ]] || [[ " $* " == *" list known "* ]] || return 0
	\typeset online_version version_release
	case "${rvm_autoupdate_flag:-1}" in
		(0|disabled) true ;;
		(1|warn) if __rvm_cli_autoupdate_version_old
			then
				__rvm_cli_autoupdate_warning
			fi ;;
		(2|enabled) if __rvm_cli_autoupdate_version_old
			then
				__rvm_cli_autoupdate_execute || return $?
			fi ;;
	esac
	true
}
__rvm_cli_autoupdate_execute () {
	printf "%b" "Found old RVM ${rvm_version%% *} - updating.\n"
	__rvm_cli_rvm_get "${version_release}" || return $?
	__rvm_cli_rvm_reload
}
__rvm_cli_autoupdate_version_old () {
	online_version="$( __rvm_version_remote )" 
	version_release="$(\command \cat "$rvm_path/RELEASE" 2>/dev/null)" 
	: version_release:"${version_release:=master}"
	if [[ "${online_version}-next" == "${rvm_version%% *}" ]]
	then
		return 1
	fi
	[[ -s "$rvm_path/VERSION" && -n "${online_version:-}" ]] && __rvm_version_compare "${rvm_version%% *}" -lt "${online_version:-}" || return $?
}
__rvm_cli_autoupdate_warning () {
	rvm_warn "Warning, new version of rvm available '${online_version}', you are using older version '${rvm_version%% *}'.
You can disable this warning with:   echo rvm_autoupdate_flag=0 >> ~/.rvmrc
You can enable auto-update with:     echo rvm_autoupdate_flag=2 >> ~/.rvmrc
You can update manually with:        rvm get VERSION                         (e.g. 'rvm get stable')
"
}
__rvm_cli_get_and_execute_installer () {
	__rvm_cli_get_installer_cleanup || return $?
	rvm_log "Downloading https://get.rvm.io"
	__rvm_curl -s https://get.rvm.io -o "${rvm_archives_path}/rvm-installer" || {
		\typeset _ret=$?
		rvm_error "Could not download rvm-installer, please report to https://github.com/rvm/rvm/issues"
		return ${_ret}
	}
	__rvm_cli_get_and_verify_pgp || return $?
	bash "${rvm_archives_path}/rvm-installer" "$@" || {
		\typeset _ret=$?
		rvm_error "Could not update RVM, please report to https://github.com/rvm/rvm/issues"
		return ${_ret}
	}
}
__rvm_cli_get_and_verify_pgp () {
	\typeset rvm_gpg_command
	if rvm_install_gpg_setup
	then
		pgp_signature_url="$( __rvm_curl -sSI https://get.rvm.io | \tr "\r" " " | __rvm_awk '/Location:/{print $2".asc"}' )" 
		rvm_notify "Downloading $pgp_signature_url"
		__rvm_curl -s "${pgp_signature_url}" -o "${rvm_archives_path}/rvm-installer.asc" || return $?
		rvm_notify "Verifying ${rvm_archives_path}/rvm-installer.asc"
		verify_package_pgp "${rvm_archives_path}/rvm-installer" "${rvm_archives_path}/rvm-installer.asc" "$pgp_signature_url" || return $?
	else
		rvm_warn "No GPG software exists to validate rvm-installer, skipping."
	fi
}
__rvm_cli_get_installer_cleanup () {
	[[ -w "${rvm_archives_path}" ]] || {
		rvm_error "Archives path '${rvm_archives_path}' not writable, aborting."
		return 1
	}
	[[ ! -e "${rvm_archives_path}/rvm-installer" ]] || rm -f "${rvm_archives_path}/rvm-installer" || {
		rvm_error "Previous installer '${rvm_archives_path}/rvm-installer' exists and can not be removed, aborting."
		return 2
	}
}
__rvm_cli_install_ruby () {
	(
		if [[ -n "$1" ]]
		then
			\typeset __rubies __installed __missing __search_list
			\typeset -a __search
			__rvm_custom_separated_array __search , "$1"
			__rubies="$1" 
			__search_list="" 
			__rvm_cli_rubies_select || return $?
			if __rvm_cli_rubies_not_installed
			then
				__rvm_run_wrapper manage install "${__rubies}" || return $?
			fi
		else
			rvm_error "Can not use or install 'all' rubies. You can get a list of installable rubies with 'rvm list known'."
			false
		fi
	)
}
__rvm_cli_load_rvmrc () {
	if (( ${rvm_ignore_rvmrc:=0} == 0 ))
	then
		[[ -n "${rvm_stored_umask:-}" ]] || export rvm_stored_umask=$(umask) 
		rvm_rvmrc_files=("/etc/rvmrc" "$HOME/.rvmrc") 
		if [[ -n "${rvm_prefix:-}" ]] && [[ ! "$HOME/.rvmrc" -ef "${rvm_prefix}/.rvmrc" ]]
		then
			rvm_rvmrc_files+=("${rvm_prefix}/.rvmrc") 
		fi
		for rvmrc in "${rvm_rvmrc_files[@]}"
		do
			if [[ -f "$rvmrc" ]]
			then
				if __rvm_grep '^\s*rvm .*$' "$rvmrc" > /dev/null 2>&1
				then
					printf "%b" "
Error:
        $rvmrc is for rvm settings only.
        rvm CLI may NOT be called from within $rvmrc.
        Skipping the loading of $rvmrc"
					return 1
				else
					source "$rvmrc"
				fi
			fi
		done
		unset rvm_rvmrc_files
	fi
}
__rvm_cli_posix_check () {
	if __rvm_has_opt "posix"
	then
		echo "RVM can not be run with \`set -o posix\`, please turn it off and try again."
		return 100
	fi
}
__rvm_cli_rubies_not_installed () {
	if (( ${rvm_force_flag:-0} == 0 )) && __installed="$(
      __rvm_list_strings | __rvm_grep -E "${__search_list}"
    )"  && [[ -n "${__installed}" ]]
	then
		rvm_warn "Already installed ${__installed//|/,}.
To reinstall use:

    rvm reinstall ${__installed//|/,}
"
		return 2
	fi
	true
}
__rvm_cli_rubies_select () {
	\typeset __ruby
	for __ruby in "${__search[@]}"
	do
		rvm_ruby_string="${__ruby}" 
		__rvm_select && if [[ -n "$rvm_ruby_string" ]]
		then
			__search_list+="^$rvm_ruby_string\$|" 
		else
			rvm_error "Could not detect ruby version/name for installation '${__ruby}', please be more specific."
			return 1
		fi
	done
	__search_list="${__search_list%|}" 
}
__rvm_cli_rvm_get () {
	case "$1" in
		([0-9]*.[0-9]*.[0-9]*) rvm_warn "
Hi there, it looks like you have requested updating rvm to version $1,
if your intention was ruby installation use instead: rvm install $1
" ;;
	esac
	case "$1" in
		(stable|master|head|branch|latest|latest-*|[0-9]*.[0-9]*.[0-9]*) __rvm_cli_get_and_execute_installer "$@" || return $?
			\typeset -x rvm_hook
			rvm_hook="after_update" 
			source "${rvm_scripts_path:-"$rvm_path/scripts"}/hook"
			rvm_reload_flag=1  ;;
		(*) rvm_help get ;;
	esac
}
__rvm_cli_rvm_reload () {
	__rvm_project_rvmrc_lock=0 
	rvm_reload_flag=1 
	source "${rvm_scripts_path:-${rvm_path}/scripts}/rvm"
}
__rvm_cli_version_check () {
	\typeset disk_version
	disk_version="$( __rvm_version_installed )" 
	if [[ -s "$rvm_path/VERSION" && "${rvm_version:-}" != "${disk_version:-}" && " $* " != *" reload "* ]]
	then
		if (( ${rvm_auto_reload_flag:-0} ))
		then
			__rvm_cli_rvm_reload
		else
			rvm_warn "RVM version <notify>${disk_version}</notify> is installed, yet version <error>${rvm_version}</error> is loaded.

Please open a new shell or run one of the following commands:

    <code>rvm reload</code>
    <code>echo rvm_auto_reload_flag=1 >> ~/.rvmrc</code> <comment># OR for auto reload with msg</comment>
    <code>echo rvm_auto_reload_flag=2 >> ~/.rvmrc</code> <comment># OR for silent auto reload</comment>
"
			return 1
		fi
	fi
}
__rvm_conditionally_add_bin_path () {
	[[ ":${PATH}:" == *":${rvm_bin_path}:"* ]] || {
		if [[ "${rvm_ruby_string:-"system"}" == "system" && -z "$GEM_HOME" ]]
		then
			PATH="$PATH:${rvm_bin_path}" 
		else
			PATH="${rvm_bin_path}:$PATH" 
		fi
	}
}
__rvm_conditionally_do_with_env () {
	if (( __rvm_env_loaded > 0 ))
	then
		"$@"
	else
		__rvm_do_with_env "$@"
	fi
}
__rvm_cp () {
	\cp "$@" || return $?
}
__rvm_curl () {
	(
		\typeset curl_path
		if [[ "${_system_name} ${_system_version}" == "Solaris 10" ]] && ! __rvm_which curl > /dev/null 2>&1
		then
			curl_path=/opt/csw/bin/ 
		else
			curl_path="" 
		fi
		__rvm_which ${curl_path}curl > /dev/null 2>&1 || {
			rvm_error "RVM requires 'curl'. Install 'curl' first and try again."
			return 200
		}
		\typeset -a __flags
		__flags=(--fail --location) 
		if [[ -n "${rvm_curl_flags[*]}" ]]
		then
			__flags+=("${rvm_curl_flags[@]}") 
		else
			__flags+=(--max-redirs 10 --max-time 1800) 
		fi
		[[ "$*" == *"--max-time"* ]] || [[ "$*" == *"--connect-timeout"* ]] || [[ "${__flags[*]}" == *"--connect-timeout"* ]] || __flags+=(--connect-timeout 30 --retry-delay 2 --retry 3) 
		if [[ -n "${rvm_proxy:-}" ]]
		then
			__flags+=(--proxy "${rvm_proxy:-}") 
		fi
		__rvm_curl_output_control
		unset curl
		__rvm_debug_command ${curl_path}curl "${__flags[@]}" "$@" || return $?
	)
}
__rvm_curl_output_control () {
	if (( ${rvm_quiet_curl_flag:-0} == 1 ))
	then
		__flags+=("--silent" "--show-error") 
	elif [[ " $*" == *" -s"* || " $*" == *" --silent"* ]]
	then
		[[ " $*" == *" -S"* || " $*" == *" -sS"* || " $*" == *" --show-error"* ]] || {
			__flags+=("--show-error") 
		}
	fi
}
__rvm_current_gemset () {
	\typeset current_gemset
	current_gemset="${GEM_HOME:-}" 
	current_gemset="${current_gemset##*${rvm_gemset_separator:-@}}" 
	if [[ "${current_gemset}" == "${GEM_HOME:-}" ]]
	then
		echo ''
	else
		echo "${current_gemset}"
	fi
}
__rvm_custom_separated_array () {
	\typeset IFS
	IFS=$2 
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		eval "$1+=( \${=3} )"
	else
		eval "$1+=( \$3 )"
	fi
}
__rvm_date () {
	\date "$@" || return $?
}
__rvm_db () {
	\typeset value key variable
	key="${1:-}" 
	variable="${2:-}" 
	value="" 
	if [[ -f "$rvm_user_path/db" ]]
	then
		value="$( __rvm_db_ "$rvm_user_path/db"   "$key" )" 
	fi
	if [[ -z "$value" && -f "$rvm_path/config/db" ]]
	then
		value="$( __rvm_db_ "$rvm_path/config/db" "$key" )" 
	fi
	[[ -n "$value" ]] || return 1
	if [[ -n "$variable" ]]
	then
		eval "$variable='$value'"
	else
		echo "$value"
	fi
	true
}
__rvm_db_ () {
	\typeset __db __key __value
	__db="$1" 
	__key="${2%%\?*}" 
	shift 2
	__value="$*" 
	case "${__value}" in
		(unset|delete) __rvm_db_remove "${__db}" "${__key}" ;;
		("") __rvm_db_get "${__db}" "${__key}" ;;
		(*) __rvm_db_add "${__db}" "${__key}" "${__value}" ;;
	esac
}
__rvm_db_add () {
	\typeset __dir="${1%/*}"
	if [[ -f "${1}" ]]
	then
		__rvm_db_remove "${1}" "${2}"
	elif [[ ! -d "${__dir}" ]]
	then
		mkdir -p "${__dir}"
	fi
	printf "%b=%b\n" "$2" "$3" >> "$1"
}
__rvm_db_get () {
	if [[ -f "$1" ]]
	then
		__rvm_sed -n -e "\#^$2=# { s#^$2=##;; p; }" -e '/^$/d' < "$1"
	else
		echo -n ""
	fi
}
__rvm_db_remove () {
	if [[ -f "$1" ]]
	then
		__rvm_sed -e "\#^$2=# d" -e '/^$/d' "$1" > "$1.new"
		\command \mv -f "$1.new" "$1"
	fi
}
__rvm_db_system () {
	\typeset __key __message
	for __key in "${_system_name}_${_system_version}_$1" "${_system_name}_$1" "$1"
	do
		if __rvm_db "${__key}_error" __message
		then
			rvm_error "${__message}"
		fi
		if __rvm_db "${__key}_warn" __message
		then
			rvm_warn "${__message}"
		fi
		if __rvm_db "${__key}" "$2"
		then
			return 0
		fi
	done
	true
}
__rvm_debug_command () {
	rvm_debug "Running($#): $*"
	"$@" || return $?
}
__rvm_detect_debian_major_version_from_codename () {
	case $_system_version in
		(buster*) _system_version="10"  ;;
		(stretch*) _system_version="9"  ;;
		(jessie*) _system_version="8"  ;;
		(wheezy*) _system_version="7"  ;;
		(squeeze*) _system_version="6"  ;;
		(lenny*) _system_version="5"  ;;
		(etch*) _system_version="4"  ;;
		(sarge*) _system_version="3"  ;;
		(woody*) _system_version="3"  ;;
		(potato*) _system_version="2"  ;;
		(slink*) _system_version="2"  ;;
		(hamm*) _system_version="2"  ;;
	esac
}
__rvm_detect_system () {
	unset _system_type _system_name _system_version _system_arch
	export _system_type _system_name _system_version _system_arch
	_system_info="$(command uname -a)" 
	_system_type="unknown" 
	_system_name="unknown" 
	_system_name_lowercase="unknown" 
	_system_version="unknown" 
	_system_arch="$(command uname -m)" 
	case "$(command uname)" in
		(Linux|GNU*) source "$rvm_scripts_path/functions/detect/system_name/lsb_release"
			source "$rvm_scripts_path/functions/detect/system_name/os_release"
			_system_type="Linux" 
			if [[ -f /etc/lsb-release ]] && __rvm_detect_system_from_lsb_release
			then
				:
			elif [[ -f /etc/os-release ]] && __rvm_detect_system_from_os_release
			then
				:
			elif [[ -f /etc/altlinux-release ]]
			then
				_system_name="Arch" 
				_system_version="libc-$(ldd --version  | \command \awk 'NR==1 {print $NF}' | \command \awk -F. '{print $1"."$2}' | head -n 1)" 
			elif [[ -f /etc/SuSE-release ]]
			then
				_system_name="SuSE" 
				_system_version="$( \command \awk -F'=' '{gsub(/ /,"")} $1~/VERSION/ {version=$2} $1~/PATCHLEVEL/ {patch=$2} END {print version"."patch}' < /etc/SuSE-release )" 
			elif [[ -f /etc/devuan_version ]]
			then
				_system_name="Devuan" 
				_system_version="$(\command \cat /etc/devuan_version | \command \awk -F. '{print $1}' | head -n 1)" 
				_system_arch="$( dpkg --print-architecture )" 
			elif [[ -f /etc/sabayon-release ]]
			then
				_system_name="Sabayon" 
				_system_version="$(\command \cat /etc/sabayon-release | \command \awk 'NR==1 {print $NF}' | \command \awk -F. '{print $1"."$2}' | head -n 1)" 
			elif [[ -f /etc/gentoo-release ]]
			then
				_system_name="Gentoo" 
				_system_version="base-$(\command \cat /etc/gentoo-release | \command \awk 'NR==1 {print $NF}' | \command \awk -F. '{print $1"."$2}' | head -n 1)" 
			elif [[ -f /etc/arch-release ]]
			then
				_system_name="Arch" 
				_system_version="libc-$(ldd --version  | \command \awk 'NR==1 {print $NF}' | \command \awk -F. '{print $1"."$2}' | head -n 1)" 
			elif [[ -f /etc/fedora-release ]]
			then
				_system_name="Fedora" 
				_system_version="$(GREP_OPTIONS="" \command \grep -Eo '[0-9]+' /etc/fedora-release | head -n 1)" 
			elif [[ -f /etc/oracle-release ]]
			then
				_system_name="Oracle" 
				_system_version="$(GREP_OPTIONS="" \command \grep -Eo '[0-9\.]+' /etc/oracle-release  | \command \awk -F. '{print $1}' | head -n 1)" 
			elif [[ -f /etc/redhat-release ]]
			then
				_system_name="$( GREP_OPTIONS="" \command \grep -Eo 'CentOS|PCLinuxOS|ClearOS|Mageia|Scientific|ROSA Desktop|OpenMandriva' /etc/redhat-release 2>/dev/null | \command \head -n 1 | \command \sed "s/ //" )" 
				_system_name="${_system_name:-CentOS}" 
				_system_version="$(GREP_OPTIONS="" \command \grep -Eo '[0-9\.]+' /etc/redhat-release  | \command \awk -F. 'NR==1{print $1}' | head -n 1)" 
				_system_arch="$( uname -m )" 
			elif [[ -f /etc/centos-release ]]
			then
				_system_name="CentOS" 
				_system_version="$(GREP_OPTIONS="" \command \grep -Eo '[0-9\.]+' /etc/centos-release  | \command \awk -F. '{print $1}' | head -n 1)" 
			elif [[ -f /etc/debian_version ]]
			then
				_system_name="Debian" 
				_system_version="$(\command \cat /etc/debian_version | \command \awk -F. '{print $1}' | head -n 1)" 
				_system_arch="$( dpkg --print-architecture )" 
				__rvm_detect_debian_major_version_from_codename
			elif [[ -f /proc/devices ]] && GREP_OPTIONS="" \command \grep -Eo "synobios" /proc/devices > /dev/null
			then
				_system_type="BSD" 
				_system_name="Synology" 
				_system_version="libc-$(ldd --version  | \command \awk 'NR==1 {print $NF}' | \command \awk -F. '{print $1"."$2}' | head -n 1)" 
			elif [[ "$(command uname -o)" == "Android" ]]
			then
				_system_name="Termux" 
				_system_version="$(command uname -r)" 
			else
				_system_version="libc-$(ldd --version  | \command \awk 'NR==1 {print $NF}' | \command \awk -F. '{print $1"."$2}' | head -n 1)" 
			fi ;;
		(SunOS) _system_type="SunOS" 
			_system_name="Solaris" 
			_system_version="$(command uname -v)" 
			_system_arch="$(command isainfo -k)" 
			if [[ "${_system_version}" == joyent* ]]
			then
				_system_name="SmartOS" 
				_system_version="${_system_version#* }" 
			elif [[ "${_system_version}" == omnios* ]]
			then
				_system_name="OmniOS" 
				_system_version="${_system_version#* }" 
			elif [[ "${_system_version}" == oi* || "${_system_version}" == illumos* ]]
			then
				_system_name="OpenIndiana" 
				_system_version="${_system_version#* }" 
			elif [[ "${_system_version}" == Generic* ]]
			then
				_system_version="10" 
			elif [[ "${_system_version}" == *11* ]]
			then
				_system_version="11" 
			fi ;;
		(FreeBSD) _system_type="BSD" 
			_system_name="FreeBSD" 
			_system_version="$(command uname -r)" 
			_system_version="${_system_version%%-*}"  ;;
		(OpenBSD) _system_type="BSD" 
			_system_name="OpenBSD" 
			_system_version="$(command uname -r)"  ;;
		(DragonFly) _system_type="BSD" 
			_system_name="DragonFly" 
			_system_version="$(command uname -r)" 
			_system_version="${_system_version%%-*}"  ;;
		(NetBSD) _system_type="BSD" 
			_system_name="NetBSD" 
			_system_version_full="$(command uname -r)" 
			_system_version="$(echo ${_system_version_full} | \command \awk -F. '{print $1"."$2}')"  ;;
		(Darwin) _system_type="Darwin" 
			_system_name="OSX" 
			_system_version="$(sw_vers -productVersion | \command \awk -F. '{print $1"."$2}')"  ;;
		(CYGWIN*) _system_type="Windows" 
			_system_name="Cygwin"  ;;
		(MINGW*) _system_type="Windows" 
			_system_name="Mingw"  ;;
		(*) return 1 ;;
	esac
	_system_type="${_system_type//[ \/]/_}" 
	_system_name="${_system_name//[ \/]/_}" 
	_system_name_lowercase="$(echo ${_system_name} | \command \tr '[A-Z]' '[a-z]')" 
	_system_version="${_system_version//[ \/]/_}" 
	_system_arch="${_system_arch//[ \/]/_}" 
	_system_arch="${_system_arch/amd64/x86_64}" 
	_system_arch="${_system_arch/i[123456789]86/i386}" 
}
__rvm_detect_system_override () {
	\typeset _var
	for _var in system_type system_name system_name_lowercase system_version system_arch
	do
		__rvm_db ${_var} _${_var}
	done
}
__rvm_display_rvmrc () {
	__rvm_file_notice_display_pre
	__rvm_wait_anykey "(( press a key to review the ${_rvmrc_base} file ))"
	printf "%b" "${rvm_warn_clr}"
	command cat -v "${_rvmrc}"
	printf "%b" "${rvm_reset_clr}"
	__rvm_file_notice_display_post
}
__rvm_do_with_env () {
	\typeset result
	__rvm_do_with_env_before
	"$@"
	result=$? 
	__rvm_do_with_env_after
	return ${result:-0}
}
__rvm_do_with_env_after () {
	__rvm_teardown
}
__rvm_do_with_env_before () {
	if [[ -n "${rvm_scripts_path:-}" || -n "${rvm_path:-}" ]]
	then
		source "${rvm_scripts_path:-"$rvm_path/scripts"}/initialize"
		__rvm_setup
	fi
}
__rvm_dotted () {
	set +x
	\typeset flush
	if (( $# ))
	then
		printf "%b" "${rvm_notify_clr:-}$*${rvm_reset_clr:-}"
	fi
	if __rvm_awk '{fflush;}' <<< EO 2> /dev/null
	then
		flush=fflush 
	else
		flush=flush 
	fi
	awk -v go_back="$( tput cub1 2>/dev/null || true)" '
  BEGIN{
    spin[0]="|"go_back;
    spin[1]="/"go_back;
    spin[2]="-"go_back;
    spin[3]="\\"go_back }
  {
    if ((NR-1)%(10)==9)
      printf ".";
    else
      if (go_back!="") printf spin[(NR-1)%4];
    '${flush}' }
  END{
    print "." }
  '
}
__rvm_ensure_has_environment_files () {
	\typeset file_name variable value environment_id __path __gem_home
	__gem_home="${rvm_ruby_gem_home}" 
	file_name="${__gem_home}/environment" 
	__path="" 
	if [[ "${__gem_home##*@}" != "global" ]]
	then
		__path+="${__gem_home}/bin:" 
	fi
	__path+="${rvm_ruby_global_gems_path}/bin:${rvm_ruby_home}/bin" 
	\command \rm -f "$file_name"
	\command \mkdir -p "${__gem_home}/wrappers" "${rvm_environments_path}" "${rvm_wrappers_path}"
	printf "%b" "export PATH=\"${__path}:\$PATH\"\n" > "$file_name"
	for variable in GEM_HOME GEM_PATH MY_RUBY_HOME IRBRC MAGLEV_HOME RBXOPT RUBY_VERSION
	do
		eval "value=\${${variable}:-""}"
		if [[ -n "$value" ]]
		then
			printf "export %b='%b'\n" "${variable}" "${value}" >> "$file_name"
		else
			printf "unset %b\n" "${variable}" >> "$file_name"
		fi
	done
	environment_id="${__gem_home##*/}" 
	[[ -L "${rvm_environments_path}/${environment_id}" ]] || {
		if [[ -f "${rvm_environments_path}/${environment_id}" ]]
		then
			rm -rf "${rvm_environments_path}/${environment_id}"
		fi
		ln -nfs "${__gem_home}/environment" "${rvm_environments_path}/${environment_id}"
	}
	ln -nfs "${__gem_home}/wrappers" "$rvm_wrappers_path/${environment_id}"
	return 0
}
__rvm_ensure_is_a_function () {
	if [[ ${rvm_reload_flag:=0} == 1 ]] || ! is_a_function rvm
	then
		for script in functions/version functions/selector cd functions/cli cli override_gem
		do
			if [[ -f "$rvm_scripts_path/$script" ]]
			then
				source "$rvm_scripts_path/$script"
			else
				printf "%b" "WARNING:
        Could not source '$rvm_scripts_path/$script' as file does not exist.
        RVM will likely not work as expected.\n"
			fi
		done
	fi
}
__rvm_env_file_notice_display_post () {
	__rvm_table "Viewing of ${_rvmrc} complete." <<TEXT
Trusting an ${_rvmrc_base} file means that whenever you cd into this directory, RVM will export environment variables from ${_rvmrc_base}.
Note that if the contents of the file change, you will be re-prompted to review the file and adjust its trust settings. You may also change the trust settings manually at any time with the 'rvm rvmrc' command.
TEXT
}
__rvm_env_file_notice_initial () {
	__rvm_table "NOTICE" <<TEXT
RVM has encountered a new or modified ${_rvmrc_base} file in the current directory, environment variables from this file will be exported and therefore may influence your shell.

Examine the contents of this file carefully to be sure the contents are safe before trusting it!
Do you wish to trust '${_rvmrc}'?
Choose v[iew] below to view the contents
TEXT
}
__rvm_env_print () {
	environment_file_path="$rvm_environments_path/$(__rvm_env_string)" 
	if [[ "$rvm_path_flag" == "1" || "$*" == *"--path"* ]]
	then
		echo "$environment_file_path"
	elif [[ "$rvm_cron_flag" == "1" || "$*" == *"--cron"* ]]
	then
		\command \cat "$environment_file_path" | __rvm_grep -Eo "[^ ]+=[^;]+" | __rvm_sed -e 's/\$PATH/'"${PATH//\//\\/}"'/' -e 's/\${PATH}/'"${PATH//\//\\/}"'/'
	else
		\command \cat "$environment_file_path"
	fi
}
__rvm_env_string () {
	\typeset _string
	_string="${GEM_HOME:-}" 
	_string="${_string##*/}" 
	printf "%b" "${_string:-system}\n"
}
__rvm_expand_ruby_string () {
	\typeset string current_ruby
	string="$1" 
	case "${string:-all}" in
		(all) __rvm_list_strings | \command \tr ' ' "\n" ;;
		(all-gemsets) __rvm_list_gemset_strings ;;
		(default-with-rvmrc | rvmrc) "$rvm_scripts_path/tools" path-identifier "$PWD" ;;
		(all-rubies | rubies) __rvm_list_strings ;;
		(current-ruby | gemsets) current_ruby="$(__rvm_env_string)" 
			current_ruby="${current_ruby%@*}" 
			rvm_silence_logging=1 "$rvm_scripts_path/gemsets" list strings | __rvm_sed "s/ (default)//; s/^/$current_ruby${rvm_gemset_separator:-@}/ ; s/@default// ;" ;;
		(current) __rvm_env_string ;;
		(aliases) __rvm_awk -F= '{print $string}' < "$rvm_path/config/alias" ;;
		(*) __rvm_ruby_strings_exist $( echo "$string" | \command \tr "," "\n" | __rvm_strip ) ;;
	esac
}
__rvm_export () {
	\typeset name
	name=${1%%\=*} 
	builtin export rvm_old_$name=${!name}
	export "$@"
	return $?
}
__rvm_file_env_check_unload () {
	if (( ${#rvm_saved_env[@]} > 0 ))
	then
		__rvm_set_env "" "${rvm_saved_env[@]}"
	fi
	rvm_saved_env=() 
}
__rvm_file_load_env () {
	\typeset -a __sed_commands
	__sed_commands=() 
	if [[ -n "${2:-}" ]]
	then
		__sed_commands+=(-e "/^$2/ !d" -e "s/^$2//") 
	else
		__sed_commands+=(-e "/^#/ d" -e "/^$/ d") 
	fi
	__rvm_read_lines __file_env_variables <( { cat "$1"; echo ""; } | __rvm_sed "${__sed_commands[@]}" )
}
__rvm_file_load_env_and_trust () {
	[[ -f "$1" ]] || return 0
	__rvm_file_load_env "$1" "${2:-}"
	if (( ${#__file_env_variables[@]} == 0 )) || __rvm_check_rvmrc_trustworthiness "$1"
	then
		true
	else
		rvm_debug "Envirionment variables variables from '$1' wont be loaded because of lack of trust (status=$?)."
		__file_env_variables=() 
	fi
}
__rvm_file_notice_display_post () {
	case "${_rvmrc}" in
		(*/.rvmrc) __rvm_rvmrc_notice_display_post ;;
		(*) __rvm_env_file_notice_display_post ;;
	esac
}
__rvm_file_notice_display_pre () {
	__rvm_table <<TEXT
The contents of the ${_rvmrc_base} file will now be displayed.
After reading the file, you will be prompted again for 'yes or no' to set the trust level for this particular version of the file.

Note: You will be re-prompted each time the ${_rvmrc_base} file's contents change
changes, and may change the trust setting manually at any time.
TEXT
}
__rvm_file_notice_initial () {
	case "${_rvmrc}" in
		(*/.rvmrc) __rvm_rvmrc_notice_initial ;;
		(*) __rvm_env_file_notice_initial ;;
	esac
}
__rvm_file_set_env () {
	__rvm_file_env_check_unload
	__rvm_set_env "rvm_saved_env" "${__file_env_variables[@]}"
}
__rvm_find () {
	\find "$@" || return $?
}
__rvm_find_first_file () {
	\typeset _first_file _variable_first_file __file_enum
	_first_file="" 
	_variable_first_file="$1" 
	shift
	for __file_enum in "$@"
	do
		if [[ -f "$__file_enum" ]]
		then
			eval "$_variable_first_file=\"\$__file_enum\""
			return 0
		fi
	done
	eval "$_variable_first_file=\"\""
	return 1
}
__rvm_fix_group_permissions () {
	if \umask -S | __rvm_grep 'g=rw' > /dev/null
	then
		chmod -R g+rwX "$@"
	fi
}
__rvm_fix_path_from_gem_path () {
	[[ -n "${GEM_PATH:-}" ]] || return 0
	export PATH
	\typeset IFS _iterator_path
	\typeset -a _gem_path _new_path
	IFS=: 
	_gem_path=() 
	_new_path=() 
	__rvm_custom_separated_array _gem_path : "${GEM_PATH}"
	for _iterator_path in "${_gem_path[@]}"
	do
		_new_path+=("${_iterator_path}/bin") 
	done
	_new_path+=("${MY_RUBY_HOME:-${GEM_HOME/gems/rubies}}/bin") 
	_new_path+=("${rvm_bin_path}") 
	PATH="${_new_path[*]}:$PATH" 
	builtin hash -r
}
__rvm_fix_selected_ruby () {
	\typeset __ret=0
	if (( $# ))
	then
		"$@" || __ret=$? 
	fi
	[[ -d "$GEM_HOME" && -d "$MY_RUBY_HOME" ]] || {
		if [[ -d ${MY_RUBY_HOME%/*}/defaul ]]
		then
			__rvm_use default
		else
			__rvm_use system
		fi
	}
}
__rvm_fold () {
	if fold -s -w 10 <<< bla > /dev/null
	then
		fold -s -w $1
	else
		fold -w $1
	fi
}
__rvm_gemset_handle_default () {
	rvm_gemset_name="${rvm_gemset_separator:-@}${rvm_gemset_name:-}${rvm_gemset_separator:-@}" 
	rvm_gemset_name="${rvm_gemset_name/${rvm_gemset_separator:-@}default${rvm_gemset_separator:-@}/}" 
	rvm_gemset_name="${rvm_gemset_name//${rvm_gemset_separator:-@}/}" 
}
__rvm_gemset_pristine () {
	__rvm_log_command "gemset.pristine-$1" "Making gemset $1 pristine" __rvm_with "$1" gemset_pristine
}
__rvm_gemset_select () {
	__rvm_gemset_select_only && __rvm_gemset_select_validation || return $?
}
__rvm_gemset_select_cli () {
	__rvm_gemset_select_cli_validation && __rvm_gemset_select || return $?
}
__rvm_gemset_select_cli_validation () {
	\typeset orig_gemset
	if ! builtin command -v gem > /dev/null
	then
		rvm_log "'gem' command not found, cannot select a gemset."
		return 0
	fi
	orig_gemset="${rvm_gemset_name:-}" 
	__rvm_gemset_handle_default
	if [[ -z "${rvm_gemset_name:-}" && "$orig_gemset" != "default" && ${rvm_sticky_flag:-0} -eq 1 ]]
	then
		if [[ -n "${rvm_ruby_gem_home:-}" ]]
		then
			rvm_gemset_name="$rvm_ruby_gem_home" 
		elif [[ -n "${GEM_HOME:-}" ]]
		then
			rvm_gemset_name="$GEM_HOME" 
		fi
		rvm_gemset_name="${rvm_gemset_name##*/}" 
		rvm_gemset_name="${rvm_gemset_name#*${rvm_gemset_separator:-"@"}}" 
	fi
	if [[ -z "${rvm_ruby_string:-}" && -n "${GEM_HOME:-}" && -n "${GEM_HOME%@*}" ]]
	then
		rvm_ruby_string="${GEM_HOME%@*}" 
		rvm_ruby_string="${rvm_ruby_string##*/}" 
	fi
	if [[ -z "${rvm_ruby_string:-}" ]]
	then
		rvm_error "Gemsets can not be used with non rvm controlled rubies (currently)."
		return 3
	fi
}
__rvm_gemset_select_only () {
	rvm_ruby_gem_home="${rvm_gems_path:-"$rvm_path/gems"}/$rvm_ruby_string" 
	: rvm_ignore_gemsets_flag:${rvm_ignore_gemsets_flag:=0}:
	if (( rvm_ignore_gemsets_flag ))
	then
		rvm_ruby_global_gems_path="${rvm_ruby_gem_home}" 
		rvm_ruby_gem_path="${rvm_ruby_gem_home}" 
		rvm_gemset_name="" 
	else
		rvm_ruby_global_gems_path="${rvm_ruby_gem_home}${rvm_gemset_separator:-"@"}global" 
		__rvm_gemset_handle_default
		[[ -z "$rvm_gemset_name" ]] || rvm_ruby_gem_home="${rvm_ruby_gem_home}${rvm_gemset_separator:-"@"}${rvm_gemset_name}" 
		if [[ "$rvm_gemset_name" == "global" ]]
		then
			rvm_ruby_gem_path="${rvm_ruby_gem_home}" 
		else
			rvm_ruby_gem_path="${rvm_ruby_gem_home}:${rvm_ruby_global_gems_path}" 
		fi
	fi
	if [[ -n "${rvm_gemset_name}" ]]
	then
		rvm_env_string="${rvm_ruby_string}@${rvm_gemset_name}" 
	else
		rvm_env_string=${rvm_ruby_string} 
	fi
	true
}
__rvm_gemset_select_validation () {
	if [[ ! -d "${rvm_ruby_gem_home}" ]]
	then
		if (( ${rvm_gemset_create_on_use_flag:=0} == 0 && ${rvm_create_flag:=0} == 0 && ${rvm_delete_flag:=0} == 0 ))
		then
			rvm_expected_gemset_name="${rvm_gemset_name}" 
			rvm_gemset_name="" 
			__rvm_gemset_select_only
			return 2
		fi
	elif (( ${rvm_delete_flag:=0} == 1 ))
	then
		return 4
	fi
	case "${rvm_gemset_name}" in
		(*/*) rvm_error "Gemsets can not contain path separator '/'."
			return 5 ;;
		(*:*) rvm_error "Gemsets can not contain PATH separator ':'."
			return 5 ;;
	esac
	\typeset rvm_ruby_gem_home_254
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		rvm_ruby_gem_home_254="${rvm_ruby_gem_home[0,254]}" 
	else
		rvm_ruby_gem_home_254="${rvm_ruby_gem_home:0:254}" 
	fi
	if [[ "${rvm_ruby_gem_home}" != "${rvm_ruby_gem_home_254}" ]]
	then
		rvm_error "Gemset gem home to long ${#rvm_ruby_gem_home}."
		return 6
	fi
}
__rvm_gemset_use () {
	if [[ "$(__rvm_env_string)" == "system" ]]
	then
		rvm_error "System ruby is not controlled by RVM, but you can use it with 'rvm automount', read more: 'rvm help mount'."
		return 2
	elif __rvm_gemset_select_cli
	then
		rvm_log "Using $rvm_ruby_string with gemset ${rvm_gemset_name:-default}"
		__rvm_use
	elif [[ -n "${rvm_expected_gemset_name}" ]]
	then
		__rvm_gemset_use_ensure
	else
		rvm_error "Gemset was not given.\n  Usage:\n    rvm gemset use <gemsetname>\n"
		return 1
	fi
}
__rvm_gemset_use_ensure () {
	if [[ ! -d "$rvm_ruby_gem_home" ]] || [[ -n "${rvm_expected_gemset_name}" && ! -d "${rvm_ruby_gem_home%@*}@${rvm_expected_gemset_name}" ]]
	then
		if (( ${rvm_gemset_create_on_use_flag:=0} == 1 || ${rvm_create_flag:=0} == 1 ))
		then
			gemset_create "${rvm_expected_gemset_name:-${rvm_gemset_name:-}}"
		else
			rvm_error "Gemset '${rvm_expected_gemset_name:-${rvm_gemset_name:-}}' does not exist, 'rvm $rvm_ruby_string do rvm gemset create ${rvm_expected_gemset_name:-${rvm_gemset_name:-}}' first, or append '--create'."
			return 2
		fi
	fi
}
__rvm_get_user_shell () {
	case "${_system_type}:${_system_name}" in
		(Linux:*|SunOS:*|BSD:*|Windows:Cygwin) __shell="$( getent passwd $USER )"  || {
				rvm_error "Error checking user shell via getent ... something went wrong, report a bug."
				return 2
			}
			echo "${__shell##*:}" ;;
		(Windows:Mingw) __shell="$( echo $SHELL )"  || {
				rvm_error "Error checking user shell from echo $SHELL ... something went wrong, report a bug."
				return 2
			}
			echo "${__shell##*:}" ;;
		(Darwin:*) \typeset __version
			__version="$(dscl localhost -read "/Search/Users/$USER" UserShell)"  || {
				rvm_error "Error checking user shell via dscl ... something went wrong, report a bug."
				return 3
			}
			echo ${__version#*: } ;;
		(*) rvm_error "Do not know how to check user shell on '$(command uname)'."
			return 1 ;;
	esac
}
__rvm_grep () {
	GREP_OPTIONS="" \command \grep "$@" || return $?
}
__rvm_has_opt () {
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		setopt | GREP_OPTIONS="" \command \grep "^${1:-}$" > /dev/null 2>&1 || return $?
	elif [[ -n "${KSH_VERSION:-}" ]]
	then
		set +o | GREP_OPTIONS="" \command \grep "-o ${1:-}$" > /dev/null 2>&1 || return $?
	elif [[ -n "${BASH_VERSION:-}" ]]
	then
		[[ ":${SHELLOPTS:-}:" == *":${1:-}:"* ]] || return $?
	else
		return 1
	fi
}
__rvm_include_travis_binaries () {
	if [[ $rvm_remote_server_url == *"travis"* && $TRAVIS != true && $_system_name_lowercase == "osx" ]]
	then
		rvm_debug "Travis binaries for OSX are not movable and can't be used outside of Travis environment. Skip that source."
		return 1
	fi
	return 0
}
__rvm_initial_gemsets_create () {
	__rvm_initial_gemsets_setup "$1" && __rvm_initial_gemsets_create_gemsets
}
__rvm_initial_gemsets_create_gemsets () {
	gemset_create "global" && __rvm_with "${rvm_ruby_string}@global" __rvm_remove_without_gems && gemset_create ""
}
__rvm_initial_gemsets_create_without_rubygems () {
	__rvm_rubygems_create_link "$1" && __rvm_initial_gemsets_create_gemsets
}
__rvm_initial_gemsets_setup () {
	__rvm_log_command "chmod.bin" "$rvm_ruby_string - #making binaries executable" __rvm_set_executable "$rvm_ruby_home/bin"/* && __rvm_rubygems_create_link "$1" && (
		rvm_ruby_binary="${1:-$rvm_ruby_home/bin/ruby}" rubygems_setup ${rvm_rubygems_version:-latest}
	)
}
__rvm_initialize () {
	true ${rvm_scripts_path:="$rvm_path/scripts"}
	export rvm_scripts_path
	source "$rvm_scripts_path/base"
	__rvm_conditionally_add_bin_path
	export PATH
	[[ -d "${rvm_tmp_path:-/tmp}" ]] || command mkdir -p "${rvm_tmp_path}"
	return 0
}
__rvm_join_array () {
	\typeset IFS
	IFS="$2" 
	eval "$1=\"\${$3[*]}\""
}
__rvm_libtoolize () {
	\libtoolize "$@" || return $?
}
__rvm_lines_with_gems () {
	\typeset -a __gems_to_add
	__gems_to_add=() 
	case "${1}" in
		(global) __rvm_custom_separated_array __gems_to_add " " "${rvm_with_gems:-}" ;;
		(default) __rvm_custom_separated_array __gems_to_add " " "${rvm_with_default_gems:-}" ;;
		(*) return 0 ;;
	esac
	(( ${#__gems_to_add[@]} )) || return 0
	\typeset __gem __version
	for __gem in "${__gems_to_add[@]}"
	do
		__version="${__gem#*=}" 
		__gem="${__gem%%=*}" 
		if [[ "${__gem}" == "${__version}" ]]
		then
			lines+=("${__gem}") 
		else
			lines+=("${__gem} -v ${__version}") 
		fi
	done
}
__rvm_lines_without_comments () {
	__rvm_remove_from_array lines "#*|+( )" "${lines[@]}"
}
__rvm_lines_without_gems () {
	[[ -n "${rvm_without_gems}" ]] || return 0
	\typeset -a __gems_to_remove
	__gems_to_remove=() 
	__rvm_custom_separated_array __gems_to_remove " " "${rvm_without_gems}"
	(( ${#__gems_to_remove[@]} )) || return 0
	\typeset __gem
	for __gem in "${__gems_to_remove[@]}"
	do
		__rvm_remove_from_array lines "${__gem}|${__gem% *} *" "${lines[@]}"
	done
}
__rvm_list_gems () {
	\typeset __checks __names
	__checks="${1:-}" 
	shift || true
	__names="$*" 
	if [[ -n "${__names}" ]]
	then
		__checks="%w{${__names}}.include?(gem.name)${__checks:+" && ( ${__checks} )"}" 
	fi
	if [[ -n "${__checks}" ]]
	then
		__checks="if ${__checks}" 
	fi
	rvm_debug "gem list check: ${__checks}"
	ruby -rrubygems -e "
    Gem::Specification.each{|gem|
      puts \"#{gem.name} #{gem.version}\" ${__checks}
    }
  " 2> /dev/null || gem list $@ | __rvm_sed '/\*\*\*/ d ; /^$/ d; s/ (/,/; s/, /,/g; s/)//;' | __rvm_awk -F ',' '{for(i=2;i<=NF;i++) print $1" "$i }'
}
__rvm_list_gemset_strings () {
	\typeset all_rubies ruby_name gemset
	all_rubies="$(__rvm_list_strings | tr "\n" ":")" 
	for gemset in "${rvm_gems_path:-"$rvm_path/gems"}"/*
	do
		case "$gemset" in
			(*/\*|@*|doc|cache|system) continue ;;
		esac
		ruby_name="${gemset%%@*}" 
		ruby_name="${ruby_name##*/}" 
		case ":$all_rubies" in
			(*:${ruby_name}:*) true ;;
			(*) continue ;;
		esac
		echo "${gemset##*/}"
	done | sort
	return 0
}
__rvm_list_known_strings () {
	__rvm_sed -e 's/#.*$//g' -e 's#\[##g' -e 's#\]##g' < "$rvm_path/config/known" | sort -r | uniq
	return $?
}
__rvm_list_strings () {
	__rvm_find "$rvm_rubies_path" -mindepth 1 -maxdepth 1 -type d | __rvm_awk -F'/' '{print $NF}'
}
__rvm_load_environment () {
	\typeset __hook
	if [[ -f "$rvm_environments_path/$1" ]]
	then
		unset GEM_HOME GEM_PATH
		__rvm_remove_rvm_from_path
		__rvm_conditionally_add_bin_path
		\. "$rvm_environments_path/$1"
		rvm_hook="after_use" 
		if [[ -n "${rvm_scripts_path:-}" || -n "${rvm_path:-}" ]]
		then
			source "${rvm_scripts_path:-$rvm_path/scripts}/hook"
		fi
		builtin hash -r
	else
		__rvm_use "$1"
	fi
}
__rvm_load_project_config () {
	rvm_debug "__rvm_load_project_config $1"
	\typeset __gemfile _bundle_install
	\typeset -a __file_env_variables
	__file_env_variables=() 
	__gemfile="" 
	rvm_previous_environment="$(__rvm_env_string)" 
	: rvm_autoinstall_bundler_flag:${rvm_autoinstall_bundler_flag:=0}
	case "$1" in
		(*/.rvmrc) __rvmrc_warning_display_for_rvmrc "$1"
			if __rvm_check_rvmrc_trustworthiness "$1"
			then
				__rvm_remove_rvm_from_path
				__rvm_conditionally_add_bin_path
				rvm_current_rvmrc="$1" 
				__rvm_ensure_is_a_function
				unset GEM_HOME GEM_PATH
				rvm_ruby_string="${rvm_previous_environment/system/default}" rvm_action=use source "$1" || return $?
			else
				return $?
			fi ;;
		(*/.versions.conf) __rvm_ensure_is_a_function
			rvm_current_rvmrc="$1" 
			rvm_ruby_string="$( \command \tr -d '\r' <"$1" | __rvm_sed -n '/^ruby=/ {s/ruby=//;p;}' | tail -n 1 )" 
			[[ -n "${rvm_ruby_string}" ]] || return 2
			rvm_gemset_name="$( \command \tr -d '\r' <"$1" | __rvm_sed -n '/^ruby-gemset=/ {s/ruby-gemset=//;p;}' | tail -n 1 )" 
			rvm_create_flag=1 __rvm_use || return 3
			__rvm_file_load_env_and_trust "$1" "env-"
			_bundle_install="$( \command \tr -d '\r' <"$1" | __rvm_sed -n '/^ruby-bundle-install=/ {s/ruby-bundle-install=//;p;}' )" 
			if [[ -n "${_bundle_install}" ]]
			then
				if [[ -f "${_bundle_install}" ]]
				then
					__gemfile="${_bundle_install}" 
				else
					__gemfile="${1%/*}/Gemfile" 
				fi
			fi ;;
		(*/Gemfile) __rvm_ensure_is_a_function
			rvm_current_rvmrc="$1" 
			rvm_ruby_string="$( \command \tr -d '\r' <"$1" | __rvm_sed -n '/^#ruby=/ {s/#ruby=//;p;}' | tail -n 1 )" 
			[[ -n "${rvm_ruby_string}" ]] || {
				rvm_ruby_string="$(
          \command \tr -d '\r' <"$1" |
          __rvm_sed -n "s/[[:space:]]+rescue[[:space:]]+nil$//; /^\s*ruby[[:space:](]/ {s/^\s*ruby//; s/[[:space:]()'\"]//g; p;}" |
          \tail -n 1
        )" 
				[[ -n "${rvm_ruby_string}" ]] || return 2
				rvm_ruby_string="${rvm_ruby_string%%\#*}" 
				rvm_ruby_string="${rvm_ruby_string/,:engine=>/-}" 
				rvm_ruby_string="${rvm_ruby_string/,engine:/-}" 
				rvm_ruby_string="${rvm_ruby_string/,:engine_version=>[^,]*/}" 
				rvm_ruby_string="${rvm_ruby_string/,engine_version:[^,]*/}" 
				rvm_ruby_string="${rvm_ruby_string/,:patchlevel=>/-p}" 
				rvm_ruby_string="${rvm_ruby_string/,patchlevel:/-p}" 
			}
			rvm_gemset_name="$( \command \tr -d '\r' <"$1" | __rvm_sed -n '/^#ruby-gemset=/ {s/#ruby-gemset=//;p;}' | tail -n 1 )" 
			if [[ -z "${rvm_gemset_name:-}" && -f "${1%/*}/.ruby-gemset" ]]
			then
				rvm_gemset_name="$( \command \tr -d '\r' <"${1%/*}/.ruby-gemset" )" 
			fi
			__rvmrc_warning_display_for_Gemfile "$1"
			rvm_create_flag=1 __rvm_use || return 3
			__rvm_file_load_env_and_trust "$1" "#ruby-env-"
			__gemfile="$1"  ;;
		(*/.ruby-version|*/.rbfu-version|*/.rbenv-version) __rvm_ensure_is_a_function
			rvm_current_rvmrc="$1" 
			rvm_ruby_string="$( \command \tr -d '\r' <"$1" )" 
			if [[ -z "${rvm_ruby_string}" ]]
			then
				return 2
			fi
			if [[ -f "${1%/*}/.ruby-gemset" ]]
			then
				rvm_gemset_name="$( \command \tr -d '\r' <"${1%/*}/.ruby-gemset" )" 
			else
				rvm_gemset_name="" 
			fi
			rvm_create_flag=1 __rvm_use || return 3
			__rvm_file_load_env_and_trust "${1%/*}/.ruby-env"
			__rvm_file_load_env_and_trust "${1%/*}/.rbenv-vars"
			__gemfile="${1%/*}/Gemfile"  ;;
		(*) rvm_error "Unsupported file format for '$1'"
			return 1 ;;
	esac
	__rvm_file_set_env
	if [[ "${rvm_autoinstall_bundler_flag:-0}" == 1 && -n "${__gemfile:-}" && -f "${__gemfile:-}" ]]
	then
		__rvm_which bundle > /dev/null 2>&1 || gem install --remote bundler
		bundle install --gemfile="${__gemfile}" | __rvm_grep -vE '^Using|Your bundle is complete'
	fi
}
__rvm_load_rvmrc () {
	\typeset _file
	\typeset -a rvm_rvmrc_files
	if (( ${rvm_ignore_rvmrc:=0} == 1 ))
	then
		return 0
	fi
	[[ -n "${rvm_stored_umask:-}" ]] || export rvm_stored_umask=$(umask) 
	rvm_rvmrc_files=("/etc/rvmrc" "$HOME/.rvmrc") 
	if [[ -n "${rvm_prefix:-}" ]] && ! [[ "$HOME/.rvmrc" -ef "${rvm_prefix}/.rvmrc" ]]
	then
		rvm_rvmrc_files+=("${rvm_prefix}/.rvmrc") 
	fi
	for _file in "${rvm_rvmrc_files[@]}"
	do
		if [[ -s "$_file" ]]
		then
			if __rvm_grep '^\s*rvm .*$' "$_file" > /dev/null 2>&1
			then
				rvm_error "
$_file is for rvm settings only.
rvm CLI may NOT be called from within $_file.
Skipping the loading of $_file
"
				return 1
			else
				source "$_file"
			fi
		fi
	done
	return 0
}
__rvm_log_command () {
	\typeset name message _command_start _command_name
	\typeset -a _command
	name="${1:-}" 
	message="${2:-}" 
	shift 2
	_command=("$@") 
	_command_start="$1" 
	while (( $# )) && [[ "$1" == *"="* ]]
	do
		shift
	done
	_command_name="$1" 
	[[ "${_command_start}" != *"="* ]] || _command=("env" "${_command[@]}") 
	if __function_on_stack __rvm_log_command_internal
	then
		__rvm_log_command_simple "$@" || return $?
	else
		__rvm_log_command_internal "$@" || return $?
	fi
}
__rvm_log_command_caclulate_log_file_name () {
	[[ -n "${rvm_log_timestamp:-}" ]] || __rvm_log_command_caclulate_log_timestamp
	[[ -n "${rvm_log_filesystem:-}" ]] || __rvm_log_command_caclulate_log_filesystem
	[[ -n "${rvm_log_namelen:-}" ]] || __rvm_log_command_caclulate_log_namelen
	name="${name//[ \/]/_}" 
	_log="${rvm_log_path}/${rvm_log_timestamp}${rvm_ruby_string:+_}${rvm_ruby_string:-}/${name}" 
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		_log="${_log[0,${rvm_log_namelen}]}.log" 
	else
		_log="${_log:0:${rvm_log_namelen}}.log" 
	fi
}
__rvm_log_command_caclulate_log_filesystem () {
	export rvm_log_filesystem="$(
    __rvm_mount 2>/dev/null | __rvm_awk -v rvm_path=$rvm_path '
      BEGIN{longest=""; fstype=""}
      {if (index(rvm_path,$3)==1 && length($3)>length(longest)){longest=$3; fstype=$5}}
      END{print fstype}
    '
  )" 
	rvm_debug "Log filesystem: ${rvm_log_filesystem}"
}
__rvm_log_command_caclulate_log_namelen () {
	case "${rvm_log_filesystem}" in
		(ecryptfs) export rvm_log_namelen=138  ;;
		(*) export rvm_log_namelen=250  ;;
	esac
	rvm_debug "Log max name length: ${rvm_log_namelen}"
}
__rvm_log_command_caclulate_log_timestamp () {
	export rvm_log_timestamp="$(__rvm_date "+%s")" 
	rvm_debug "Log prefix: ${rvm_log_path}/${rvm_log_timestamp}${rvm_ruby_string:+_}${rvm_ruby_string:-}/"
}
__rvm_log_command_debug () {
	printf "%b" "[$(__rvm_date +'%Y-%m-%d %H:%M:%S')] ${_command_name}\n"
	if is_a_function "${_command_name}"
	then
		\typeset -f "${_command_name}"
	fi
	printf "%b" "current path: $PWD\n"
	env | __rvm_grep -E '^GEM_HOME=|^GEM_PATH=|^PATH='
	printf "%b" "command(${#_command[@]}): ${_command[*]}\n"
}
__rvm_log_command_internal () {
	\typeset _log
	(( ${rvm_niceness:-0} == 0 )) || _command=(nice -n $rvm_niceness "${_command[@]}") 
	__rvm_log_command_caclulate_log_file_name
	rvm_debug "Log file: ${_log}"
	[[ -d "${_log%\/*}" ]] || \command \mkdir -p "${_log%\/*}"
	[[ -f "${_log}" ]] || \command \rm -f "${_log}"
	__rvm_log_command_debug | tee "${_log}" | rvm_debug_stream
	__rvm_log_dotted "${_log}" "$message" "${_command[@]}" || {
		\typeset result=$?
		\typeset __show_lines="${rvm_show_log_lines_on_error:-0}"
		rvm_error "Error running '${_command[*]}',"
		case "${__show_lines}" in
			(0) rvm_error "please read ${_log}" ;;
			(all) rvm_error "content of log ${_log}"
				cat "${_log}" >&6 ;;
			(*) rvm_error "showing last ${__show_lines} lines of ${_log}"
				tail -n "${__show_lines}" "${_log}" >&6 ;;
		esac
		return ${result}
	}
}
__rvm_log_command_simple () {
	__rvm_log_command_debug
	rvm_log "$message"
	"$@" || return $?
}
__rvm_log_dotted () {
	\typeset __log_file __message __iterator __result __local_rvm_trace_flag
	__log_file="$1" 
	__message="$2" 
	shift 2
	__result=0 
	__local_rvm_trace_flag=${rvm_trace_flag:-0} 
	if (( ${rvm_trace_flag:-0} ))
	then
		{
			set -x
			"$@" 2>&1 | tee -a "${__log_file}"
			__rvm_check_pipestatus ${PIPESTATUS[@]} ${pipestatus[@]} || __result=$? 
			(( __local_rvm_trace_flag > 0 )) || set +x
		} >&2
	elif [[ -n "${ZSH_VERSION:-}" ]]
	then
		rvm_log "${__message} - please wait"
		{
			set -x
			"$@" > "${__log_file}" 2>&1 || __result=$? 
			(( __local_rvm_trace_flag > 0 )) || set +x
		} 2> /dev/null
	else
		{
			set -x
			"$@" 2>&1 | tee -a "${__log_file}" | __rvm_dotted "${__message}"
			__rvm_check_pipestatus ${PIPESTATUS[@]} ${pipestatus[@]} || __result=$? 
			(( __local_rvm_trace_flag > 0 )) || set +x
		} 2> /dev/null
	fi
	return $__result
}
__rvm_ls () {
	\command \ls "$@" || return $?
}
__rvm_make () {
	\make "$@" || return $?
}
__rvm_md5_calculate () {
	rvm_debug "Calculate md5 checksum for $@"
	\typeset _sum
	if builtin command -v md5 > /dev/null 2>&1
	then
		_sum=$(md5 "$@") 
		echo ${_sum##* }
		return 0
	elif builtin command -v md5sum > /dev/null 2>&1
	then
		_sum=$(md5sum "$@") 
		echo ${_sum%% *}
		return 0
	elif builtin command -v gmd5sum > /dev/null 2>&1
	then
		_sum=$(gmd5sum "$@") 
		echo ${_sum%% *}
		return 0
	else
		for _path in /usr/gnu/bin /opt/csw/bin /sbin /bin /usr/bin /usr/sbin
		do
			if [[ -x "${_path}/md5" ]]
			then
				_sum=$(${_path}/md5 "$@") 
				echo ${_sum##* }
				return 0
			elif [[ -x "${_path}/md5sum" ]]
			then
				_sum=$(${_path}/md5sum "$@") 
				echo ${_sum%% *}
				return 0
			elif [[ -x "${_path}/gmd5sum" ]]
			then
				_sum=$(${_path}/gmd5sum "$@") 
				echo ${_sum%% *}
				return 0
			fi
		done
	fi
	rvm_error "Neither of md5sum, md5, gmd5sum found in the PATH"
	return 1
}
__rvm_md5_for_contents () {
	if builtin command -v md5 > /dev/null
	then
		md5 | __rvm_awk '{print $1}'
	elif builtin command -v md5sum > /dev/null
	then
		md5sum | __rvm_awk '{print $1}'
	elif builtin command -v openssl > /dev/null
	then
		openssl md5 | __rvm_awk '{print $1}'
	else
		return 1
	fi
	true
}
__rvm_mount () {
	\mount "$@" || return $?
}
__rvm_nuke_rvm_variables () {
	unset rvm_head_flag $(env | __rvm_awk -F= '/^rvm_/{print $1" "}')
}
__rvm_package_create () {
	rvm_debug __rvm_package_create:$#: "$@"
	case "$1" in
		(*.tar.bz2) if [[ -z "${3:-}" ]]
			then
				__rvm_tar cjf "$1" "$2"
			else
				__rvm_tar cjf "$1" -C "$2" "$3"
			fi ;;
		(*.tar.gz | *.tgz) if [[ -z "${3:-}" ]]
			then
				__rvm_tar czf "$1" "$2"
			else
				__rvm_tar czf "$1" -C "$2" "$3"
			fi ;;
		(*) return 199 ;;
	esac
}
__rvm_package_extract () {
	rvm_debug __rvm_package_extract:$#: "$@"
	\typeset __extract_src __extract_target __tempdir __path __file __return
	__extract_src="$1" 
	__extract_target="$2" 
	shift 2
	__return=0 
	__tempdir="$( TMPDIR="${rvm_tmp_path}" mktemp -d -t rvm-tmp.XXXXXXXXX )" 
	__rvm_package_extract_run "$__extract_src" "$__tempdir" "$@" || __return=$? 
	if (( __return == 0 ))
	then
		for __path in "$__tempdir"/*
		do
			__file="${__path##*/}" 
			if [[ -n "${__file}" && -e "$__extract_target/${__file}" ]]
			then
				\command \rm -rf "$__extract_target/${__file}" || __return=$? 
			fi
			\command \mv -f "${__path}" "$__extract_target/" || __return=$? 
		done
	fi
	if [[ -n "$__tempdir" ]]
	then
		\command \rm -rf "$__tempdir"
	fi
	return $__return
}
__rvm_package_extract_run () {
	\typeset __extract_run_src __extract_run_target __exclude_elements
	__extract_run_src="$1" 
	__extract_run_target="$2" 
	shift 2
	__exclude_elements=() 
	if [[ " ${rvm_tar_options:-} " != *" --no-same-owner "* ]] && __rvm_tar --help 2>&1 | __rvm_grep -- --no-same-owner > /dev/null
	then
		rvm_tar_options="${rvm_tar_options:-}${rvm_tar_options:+ }--no-same-owner" 
	fi
	[[ -d "$__extract_run_target" ]] || mkdir -p "$__extract_run_target"
	case "$__extract_run_src" in
		(*.zip) unzip -q -o "$__extract_run_src" -d "$__extract_run_target" ;;
		(*.tar.bz2) __map_tar_excludes "$@"
			if [[ -n "$ZSH_VERSION" ]]
			then
				__rvm_tar "${__exclude_elements[@]}" -xjf "$__extract_run_src" -C "$__extract_run_target" ${=rvm_tar_options:-}
			else
				__rvm_tar "${__exclude_elements[@]}" -xjf "$__extract_run_src" -C "$__extract_run_target" ${rvm_tar_options:-}
			fi ;;
		(*.tar.gz | *.tgz) __map_tar_excludes "$@"
			if [[ -n "$ZSH_VERSION" ]]
			then
				__rvm_tar "${__exclude_elements[@]}" -xzf "$__extract_run_src" -C "$__extract_run_target" ${=rvm_tar_options:-}
			else
				__rvm_tar "${__exclude_elements[@]}" -xzf "$__extract_run_src" -C "$__extract_run_target" ${rvm_tar_options:-}
			fi ;;
		(*) return 199 ;;
	esac && __rvm_fix_group_permissions "$__extract_run_target"/* || return $?
}
__rvm_package_list () {
	rvm_debug __rvm_package_list:$#: "$@"
	case "$1" in
		(*.zip) unzip -Z -1 "$1" ;;
		(*.tar.bz2) __rvm_tar tjf "$1" ;;
		(*.tar.gz | *.tgz) __rvm_tar tzf "$1" ;;
		(*) return 199 ;;
	esac
}
__rvm_pager_or_cat_v () {
	eval "${PAGER:-\command \cat} '$1'"
}
__rvm_parse_args () {
	\typeset _string
	export rvm_ruby_string
	rvm_action="${rvm_action:-""}" 
	rvm_parse_break=0 
	if [[ " $* " == *" --trace "* ]]
	then
		echo "$@"
		__rvm_print_headline
	fi
	while [[ -n "$next_token" ]]
	do
		rvm_token="$next_token" 
		if (( $# > 0 ))
		then
			next_token="$1" 
			shift
		else
			next_token="" 
		fi
		case "$rvm_token" in
			([0-9a-zA-ZuU]* | @*) case "$rvm_token" in
					(use) rvm_action="$rvm_token" 
						rvm_verbose_flag=1 
						__rvm_file_env_check_unload
						if [[ -n "${next_token:-}" && ! -d "${next_token:-}" && "${next_token:-}" != "-"* && "${next_token:-}" != "@"* ]]
						then
							rvm_ruby_interpreter="$next_token" 
							rvm_ruby_string="$next_token" 
							rvm_ruby_strings="$next_token" 
							next_token="${1:-}" 
							(( $# == 0 )) || shift
						elif [[ -z "${next_token:-}" ]] && __rvm_project_dir_check .
						then
							__rvm_rvmrc_tools try_to_read_ruby . || __rvm_parse_args_error_finding_project_file
						fi ;;
					(install | uninstall | reinstall | try_install) export ${rvm_token}_flag=1
						rvm_action=$rvm_token  ;;
					(gemset) rvm_action=$rvm_token 
						rvm_ruby_args=() 
						__rvm_parse_args_find_known_flags rvm_ruby_args "$next_token" "$@"
						: rvm_ruby_args:${#rvm_ruby_args[@]}:${rvm_ruby_args[*]}:
						next_token="${rvm_ruby_args[__array_start]}" 
						rvm_gemset_name="${rvm_ruby_args[__array_start+1]}" 
						case "${next_token:-help}" in
							(help) true ;;
							(use|delete|remove) [[ "delete" != "$next_token" ]] || [[ "remove" != "$next_token" ]] || rvm_delete_flag=1 
								[[ "use" != "$next_token" ]] || rvm_action+="_$next_token" 
								case "$rvm_gemset_name" in
									(*${rvm_gemset_separator:-"@"}*) rvm_ruby_string="${rvm_gemset_name%%${rvm_gemset_separator:-"@"}*}" 
										rvm_gemset_name="${rvm_gemset_name##*${rvm_gemset_separator:-"@"}}" 
										if [[ "${rvm_ruby_string:-""}" != "${rvm_gemset_name:-""}" ]]
										then
											rvm_ruby_string="$rvm_ruby_string${rvm_gemset_separator:-"@"}$rvm_gemset_name" 
										fi
										rvm_ruby_gem_home="$rvm_ruby_gem_home${rvm_gemset_separator:-"@"}$rvm_gemset_name"  ;;
									("") rvm_error "Gemset was not given.\n  Usage:\n    rvm gemset $rvm_gemset_name <gemsetname>\n"
										return 1 ;;
								esac ;;
						esac
						rvm_parse_break=1  ;;
					(gemdir | gempath | gemhome) rvm_ruby_args=("$rvm_token") 
						rvm_action="gemset" 
						rvm_gemdir_flag=1 
						if [[ "system" == "$next_token" ]]
						then
							rvm_system_flag=1 
							next_token="${1:-}" 
							(( $# == 0 )) || shift
						fi
						if [[ "user" == "$next_token" ]]
						then
							rvm_user_flag=1 
							next_token="${1:-}" 
							(( $# == 0 )) || shift
						fi ;;
					(pkg) rvm_action="$rvm_token" 
						__rvm_parse_args_find_known_flags rvm_ruby_args "$next_token" "$@"
						rvm_parse_break=1  ;;
					(do | exec) if [[ -z "$next_token" ]]
						then
							rvm_action="error" 
							rvm_error_message="'rvm $rvm_token' must be followed by arguments." 
							break
						fi
						rvm_action="do" 
						rvm_ruby_args=("$next_token" "$@") 
						rvm_parse_break=1  ;;
					(gem | rake | ruby) [[ "$rvm_token" == "ruby" ]] && case $rvm_action in
							(install | reinstall | use | delete | remove) rvm_ruby_string=ruby 
								rvm_ruby_strings=ruby 
								continue ;;
						esac
						rvm_action=error 
						rvm_error_message="Please note that \`rvm $rvm_token ...\` was removed, try \`$rvm_token $next_token $*\` or \`rvm all do $rvm_token $next_token $*\` instead."  ;;
					(fetch | version | remote_version | reset | debug | reload | update | monitor | notes | implode | seppuku | env | unexport | automount | prepare) rvm_action=$rvm_token  ;;
					(doctor) rvm_action=notes  ;;
					(mount) rvm_action=$rvm_token 
						while [[ -n "${next_token:-}" ]] && [[ -x "${next_token:-}" || -d "${next_token:-}" || "${next_token:-}" == http* || "${next_token:-}" == *tar.bz2 || "${next_token:-}" == *tar.gz ]]
						do
							rvm_ruby_args=("$next_token" "${rvm_ruby_args[@]}") 
							next_token="${1:-}" 
							(( $# == 0 )) || shift
						done ;;
					(rm | remove | delete) rvm_action="remove" 
						rvm_remove_flag=1  ;;
					(rtfm | RTFM | rvmrc | help | inspect | list | ls | info | strings | get | current | docs | alias | rubygems | cleanup | tools | disk-usage | snapshot | repair | migrate | downgrade | upgrade | cron | group | switch | which | config-get | requirements | autolibs | osx-ssl-certs | fix-permissions) case "$rvm_token" in
							(downgrade) rvm_action="upgrade"  ;;
							(ls) rvm_action="list"  ;;
							(RTFM) rvm_action="rtfm"  ;;
							(*) rvm_action="$rvm_token"  ;;
						esac
						rvm_ruby_args=() 
						__rvm_parse_args_find_known_flags rvm_ruby_args "$next_token" "$@"
						rvm_parse_break=1  ;;
					(user) rvm_action="tools" 
						rvm_ruby_args=("$rvm_token" "$next_token" "$@") 
						rvm_parse_break=1  ;;
					(load-rvmrc) rvm_action="rvmrc" 
						rvm_ruby_args=("load" "$next_token" "$@") 
						rvm_parse_break=1  ;;
					(specs | tests) rvm_action="rake" 
						rvm_ruby_args=("${rvm_token/%ss/s}")  ;;
					(export) if [[ -n "$next_token" ]]
						then
							\typeset -a ___args
							___args=("$next_token" "$@") 
							rvm_export_args="${___args[*]}" 
							rvm_action="export" 
							rvm_parse_break=1 
						else
							rvm_action="error" 
							rvm_error_message="rvm export must be followed by a NAME=VALUE argument" 
						fi ;;
					(alt*) rvm_action="help" 
						rvm_ruby_args=("alt.md") 
						rvm_parse_break=1  ;;
					(wrapper) rvm_action="wrapper" 
						rvm_ruby_args=("$next_token" "$@") 
						rvm_parse_break=1  ;;
					(in) rvm_token="${next_token}" 
						next_token="${1:-}" 
						(( $# == 0 )) || shift
						export rvm_in_flag="$rvm_token" 
						__rvm_project_dir_check "$rvm_token" && __rvm_rvmrc_tools try_to_read_ruby $rvm_token || __rvm_parse_args_error_finding_project_file ;;
					(usage) rvm_action="deprecated" 
						rvm_error_message="This command has been deprecated. Use ${rvm_notify_clr:-}rvm help${rvm_error_clr:-} instead." 
						rvm_parse_break=1  ;;
					(*,*) rvm_ruby_strings="$rvm_token" 
						[[ -n "${rvm_action:-""}" ]] || rvm_action="ruby"  ;;
					(${rvm_gemset_separator:-"@"}*) rvm_action="${rvm_action:-use}" 
						rvm_gemset_name="${rvm_token#${rvm_gemset_separator:-"@"}}" 
						rvm_ruby_string="${rvm_ruby_string:-${GEM_HOME##*/}}" 
						rvm_ruby_string="${rvm_ruby_string%%${rvm_gemset_separator:-"@"}*}" 
						rvm_ruby_strings="${rvm_ruby_string}${rvm_gemset_separator:-"@"}${rvm_gemset_name}"  ;;
					(*${rvm_gemset_separator:-"@"}*) rvm_verbose_flag=1 
						rvm_action="${rvm_action:-use}" 
						rvm_gemset_name="${rvm_token/*${rvm_gemset_separator:-"@"}/}" 
						rvm_ruby_string="$rvm_token" 
						rvm_ruby_strings="$rvm_token"  ;;
					(*+*) rvm_action="${rvm_action:-use}" 
						rvm_ruby_alias="${rvm_token/*+/}" 
						rvm_ruby_string="${rvm_token/+*/}" 
						rvm_ruby_strings="$rvm_ruby_string"  ;;
					(*-* | +([0-9]).+([0-9])*) rvm_verbose_flag=1 
						rvm_action="${rvm_action:-use}" 
						rvm_ruby_string="$rvm_token" 
						rvm_ruby_strings="$rvm_token"  ;;
					(opal* | jruby* | ree* | macruby* | rbx* | rubinius* | mruby | ironruby* | default* | maglev* | topaz* | truffleruby* | ruby* | system | default | all) rvm_action="${rvm_action:-use}" 
						rvm_ruby_interpreter="$rvm_token" 
						rvm_ruby_string="$rvm_token" 
						rvm_ruby_strings="$rvm_token"  ;;
					(kiji* | tcs* | jamesgolick*) rvm_error_message="The $rvm_token was removed from RVM, use: rvm install ruby-head-<name> --url https://github.com/github/ruby.git --branch 2.1" 
						rvm_action="error"  ;;
					(old) case "${rvm_action:-action-missing}" in
							(remove) rvm_ruby_strings="old:${next_token:-}" 
								next_token="${1:-}" 
								(( $# == 0 )) || shift ;;
							(action-missing) rvm_error_message="what do you want to do with old rubies? rvm can only remove old rubies." 
								rvm_action="error"  ;;
							(*) rvm_error_message="rvm can not $rvm_action old rubies, rvm can only remove old rubies." 
								rvm_action="error"  ;;
						esac ;;
					(*.rb) rvm_ruby_args=("$rvm_token") 
						rvm_ruby_file="$rvm_token" 
						if [[ -z "${rvm_action:-""}" || "$rvm_action" == "use" ]]
						then
							rvm_action="ruby" 
						fi ;;
					(*.gems) rvm_file_name="${rvm_token}"  ;;
					("") rvm_action="error" 
						rvm_error_message="Unrecognized command line argument(s): $@"  ;;
					(*) if [[ "gemset" == "$rvm_action" ]]
						then
							rvm_gemset_name="${rvm_token/.gems/}" 
							rvm_file_name="$rvm_gemset_name.gems" 
						elif [[ -f "$rvm_rubies_path/$rvm_token" || -L "$rvm_rubies_path/$rvm_token" ]]
						then
							rvm_ruby_string=$rvm_token 
							rvm_ruby_strings="$rvm_token" 
							rvm_action="${rvm_action:-use}" 
						elif [[ -d "$rvm_token" ]] || __rvm_project_dir_check "$rvm_token"
						then
							__rvm_rvmrc_tools try_to_read_ruby $rvm_token || __rvm_parse_args_error_finding_project_file
						else
							rvm_action="error" 
							rvm_error_message="Unrecognized command line argument: $rvm_token" 
						fi ;;
				esac ;;
			(-*) case "$rvm_token" in
					(-S) rvm_action="ruby" 
						rvm_ruby_args=("$rvm_token" "$next_token" "$@") 
						rvm_parse_break=1  ;;
					(-e) rvm_action="ruby" 
						IFS="\n" 
						rvm_ruby_args=("$rvm_token" "'$next_token $@'") 
						IFS=" " 
						rvm_parse_break=1  ;;
					(-v | --version) if [[ -z "$next_token" ]]
						then
							rvm_action="version" 
						else
							rvm_ruby_version="$next_token" 
							next_token="${1:-}" 
							(( $# == 0 )) || shift
						fi ;;
					(-n | --name) rvm_ruby_name="$next_token" 
						next_token="${1:-}" 
						(( $# == 0 )) || shift ;;
					(--branch) rvm_ruby_repo_branch="$next_token" 
						next_token="${1:-}" 
						(( $# == 0 )) || shift
						rvm_disable_binary_flag=1  ;;
					(--tag) rvm_ruby_repo_tag="$next_token" 
						next_token="${1:-}" 
						(( $# == 0 )) || shift
						rvm_disable_binary_flag=1  ;;
					(--repository | --repo | --url) rvm_ruby_repo_url="$next_token" 
						next_token="${1:-}" 
						(( $# == 0 )) || shift
						rvm_disable_binary_flag=1  ;;
					(-r | --remote | --binary | --latest-binary) rvm_remote_flag=1 
						if [[ "$rvm_token" == "--latest-binary" ]]
						then
							rvm_fuzzy_flag=1 
						fi
						while [[ -n "${next_token:-}" ]] && [[ "${next_token:-}" == http* || "${next_token:-}" == *tar.bz2 || "${next_token:-}" == *tar.gz || "${next_token:-}" == *":"* ]]
						do
							rvm_ruby_args=("${rvm_ruby_args[@]}" "$next_token") 
							next_token="${1:-}" 
							(( $# == 0 )) || shift
						done ;;
					(--ree-options) if [[ -n "$next_token" ]]
						then
							__rvm_custom_separated_array rvm_ree_options , "${next_token}"
							next_token="${1:-}" 
							(( $# == 0 )) || shift
						else
							rvm_action="error" 
							rvm_error_message="--ree-options *must* be followed by... well... comma,separated,list,of,options." 
						fi ;;
					(--patches | --patch) __rvm_custom_separated_array rvm_patch_names , "$next_token"
						next_token="${1:-}" 
						(( $# == 0 )) || shift
						rvm_patch_original_pwd="$PWD" 
						rvm_disable_binary_flag=1  ;;
					(--arch | --archflags) rvm_architectures+=("${next_token#-arch }") 
						next_token="${1:-}" 
						(( $# == 0 )) || shift
						rvm_disable_binary_flag=1  ;;
					(--with-arch=*) rvm_architectures+=("${rvm_token#--with-arch=}") 
						rvm_disable_binary_flag=1  ;;
					(--32 | --64) rvm_architectures+=("${rvm_token#--}") 
						rvm_disable_binary_flag=1  ;;
					(--universal) rvm_architectures+=("32" "64") 
						rvm_disable_binary_flag=1  ;;
					(--bin) rvm_bin_path="$next_token" 
						next_token="${1:-}" 
						(( $# == 0 )) || shift ;;
					(--rdoc | --yard) rvm_docs_type="$rvm_token" 
						rvm_docs_type ;;
					(-f | --file) rvm_action="ruby" 
						rvm_ruby_file="$next_token" 
						next_token="${1:-}" 
						(( $# == 0 )) || shift ;;
					(--passenger | --editor) rvm_warn "NOTE: ${rvm_token} flag is deprecated, RVM now automatically generates wrappers" ;;
					(-h | --help) rvm_action=help  ;;
					(-l | --level) rvm_ruby_patch_level="p$next_token" 
						next_token="${1:-}" 
						(( $# == 0 )) || shift ;;
					(--sha | --make | --make-install) rvm_token=${rvm_token#--} 
						rvm_token=${rvm_token//-/_} 
						export "rvm_ruby_${rvm_token}"="$next_token"
						next_token="${1:-}" 
						rvm_disable_binary_flag=1 
						(( $# == 0 )) || shift ;;
					(--nice | --sdk | --autoconf-flags | --proxy) rvm_token=${rvm_token#--} 
						rvm_token=${rvm_token//-/_} 
						export "rvm_${rvm_token}"="$next_token"
						next_token="${1:-}" 
						(( $# == 0 )) || shift ;;
					(--disable-llvm | --disable-jit) rvm_llvm_flag=0  ;;
					(--enable-llvm | --enable-jit) rvm_llvm_flag=1  ;;
					(--install) rvm_install_on_use_flag=1  ;;
					(--autolibs=*) export rvm_autolibs_flag="${rvm_token#*=}"  ;;
					(--color=*) rvm_pretty_print_flag=${rvm_token#--color=}  ;;
					(--pretty) rvm_pretty_print_flag=auto  ;;
					(--1.8 | --1.9 | --2.0 | --2.1 | --18 | --19 | --20 | --21) rvm_token=${rvm_token#--} 
						rvm_token=${rvm_token//\./} 
						export "rvm_${rvm_token}_flag"=1
						rvm_disable_binary_flag=1  ;;
					(--rvmrc | --versions-conf | --ruby-version) rvm_token=${rvm_token#--} 
						rvm_token=${rvm_token//-/_} 
						export rvm_rvmrc_flag="${rvm_token}"  ;;
					(--list-missing-packages) export rvm_list_missing_packages_flag=1 
						export rvm_quiet_flag=1  ;;
					(--list-undesired-packages) export rvm_list_undesired_packages_flag=1 
						export rvm_quiet_flag=1  ;;
					(--list-installed-packages) export rvm_list_installed_packages_flag=1 
						export rvm_quiet_flag=1  ;;
					(--list-all-packages) export rvm_list_missing_packages_flag=1 
						export rvm_list_undesired_packages_flag=1 
						export rvm_list_installed_packages_flag=1 
						export rvm_quiet_flag=1  ;;
					(--head | --static | --self | --gem | --reconfigure | --default | --force | --export | --summary | --latest | --yaml | --json | --archive | --shebang | --path | --cron | --tail | --delete | --verbose | --import | --sticky | --create | --gems | --docs | --skip-autoreconf | --force-autoconf | --auto-dotfiles | --autoinstall-bundler | --disable-binary | --ignore-gemsets | --skip-gemsets | --debug | --quiet | --silent | --skip-openssl | --fuzzy | --quiet-curl | --skip-pristine | --dynamic-extensions) rvm_token=${rvm_token#--} 
						rvm_token=${rvm_token//-/_} 
						export "rvm_${rvm_token}_flag"=1 ;;
					(--no-docs) rvm_token=${rvm_token#--no-} 
						rvm_token=${rvm_token//-/_} 
						export "rvm_${rvm_token}_flag"=0 ;;
					(--auto) export "rvm_auto_dotfiles_flag"=1
						rvm_warn "Warning, --auto is deprecated in favor of --auto-dotfiles." ;;
					(--rubygems) rvm_token=${rvm_token#--} 
						rvm_token=${rvm_token//-/_} 
						export "rvm_${rvm_token}_version"="$next_token"
						next_token="${1:-}" 
						(( $# == 0 )) || shift ;;
					(--dump-environment | --max-time) rvm_token=${rvm_token#--} 
						rvm_token=${rvm_token//-/_} 
						export "rvm_${rvm_token}_flag"="$next_token"
						next_token="${1:-}" 
						(( $# == 0 )) || shift ;;
					(--verify-downloads) rvm_token=${rvm_token#--} 
						rvm_token=${rvm_token//-/_} 
						export "rvm_${rvm_token}_flag_cli"="$next_token"
						next_token="${1:-}" 
						(( $# == 0 )) || shift ;;
					(--clang) export CC=clang 
						export CXX=clang++ 
						rvm_disable_binary_flag=1  ;;
					(-M) if [[ -n "$next_token" ]]
						then
							__rvm_custom_separated_array rvm_make_flags , "${next_token}"
							next_token="${1:-}" 
							(( $# == 0 )) || shift
							rvm_disable_binary_flag=1 
						else
							rvm_action="error" 
							rvm_error_message="--make *must* be followed by make flags." 
						fi ;;
					(-j) if [[ -n "$next_token" ]]
						then
							rvm_make_flags+=(-j$next_token) 
							next_token="${1:-}" 
							(( $# == 0 )) || shift
						else
							rvm_action="error" 
							rvm_error_message="-j *must* be followed by an integer (normally the # of CPU's in your machine)." 
						fi ;;
					(--with-rubies) rvm_ruby_strings="$next_token" 
						next_token="${1:-}" 
						(( $# == 0 )) || shift ;;
					(-C | --configure) if [[ -n "$next_token" ]]
						then
							__rvm_custom_separated_array rvm_configure_flags , "${next_token}"
							next_token="${1:-}" 
							(( $# == 0 )) || shift
							rvm_disable_binary_flag=1 
						else
							rvm_action="error" 
							rvm_error_message="--configure *must* be followed by configure flags." 
						fi ;;
					(-E | --env) if [[ -n "$next_token" ]]
						then
							__rvm_custom_separated_array rvm_configure_env , "${next_token}"
							next_token="${1:-}" 
							(( $# == 0 )) || shift
							rvm_disable_binary_flag=1 
						else
							rvm_action="error" 
							rvm_error_message="--configure *must* be followed by configure flags." 
						fi ;;
					(--movable) rvm_movable_flag=1 
						rvm_disable_binary_flag=1  ;;
					(--with-* | --without-* | --enable-* | --disable-*) rvm_configure_flags+=("$rvm_token") 
						rvm_disable_binary_flag=1  ;;
					(--trace) export rvm_trace_flag=1 
						if [[ -n "${BASH_VERSION:-}" ]]
						then
							export PS4="+ \$(__rvm_date \"+%s.%N\" 2>/dev/null) \${BASH_SOURCE##\${rvm_path:-}} : \${FUNCNAME[0]:+\${FUNCNAME[0]}()}  \${LINENO} > " 
						elif [[ -n "${ZSH_VERSION:-}" ]]
						then
							export PS4="+ %* %F{red}%x:%I %F{green}%N:%i%F{white} %_" 
						fi
						set -o xtrace ;;
					(--) if [[ "${rvm_action}" == *install ]]
						then
							rvm_configure_flags+=("$next_token" "$@") 
						else
							rvm_ruby_args=("$next_token" "$@") 
						fi
						rvm_disable_binary_flag=1 
						rvm_parse_break=1  ;;
					(*) rvm_action="error" 
						rvm_error_message="Unrecognized command line flag: '$rvm_token'"  ;;
				esac ;;
			(*) if [[ -d "$rvm_token" ]] || __rvm_project_dir_check "$rvm_token"
				then
					__rvm_rvmrc_tools try_to_read_ruby "$rvm_token" || __rvm_parse_args_error_finding_project_file
				else
					rvm_action="error" 
					rvm_error_message="Unrecognized command line argument(s): '$rvm_token $@'" 
				fi ;;
		esac
		if [[ -z "${rvm_action:-""}" && -n "${rvm_ruby_string:-""}" ]]
		then
			rvm_action="use" 
		fi
		if [[ "error" == "${rvm_action:-""}" || ${rvm_parse_break:-0} -eq 1 || -n "${rvm_error_message:-""}" ]]
		then
			break
		fi
	done
	: rvm_ruby_args:${#rvm_ruby_args[@]}:${rvm_ruby_args[*]}:
	if [[ -n "${rvm_error_message:-""}" ]]
	then
		if [[ "${rvm_action}" == "deprecated" ]]
		then
			rvm_error "$rvm_error_message"
		else
			rvm_error "$rvm_error_message"
			rvm_out "Run \`rvm help\` to see usage information"
		fi
		unset rvm_error_message
		return 1
	fi
}
__rvm_parse_args_error_finding_project_file () {
	unset RVM_PROJECT_PATH
	case $? in
		(101) true ;;
		(*) rvm_error_message="Could not determine which Ruby to use; $rvm_token should contain .rvmrc or .versions.conf or .ruby-version or .rbfu-version or .rbenv-version, or an appropriate line in Gemfile."  ;;
	esac
	rvm_action="error" 
}
__rvm_parse_args_find_known_flags () {
	\typeset _args_array_name _temp_var
	\typeset -a _new_args
	_args_array_name="$1" 
	(( $# == 0 )) || shift
	_new_args=() 
	while (( $# ))
	do
		case "$1" in
			(--verify-downloads) export "rvm_verify_downloads_flag_cli"="${2:-}"
				shift ;;
			(--force|--verbose|--debug|--quiet|--silent|--create) export "rvm_${1#--}_flag=1" ;;
			(--only-path) _temp_var="${1#--}" 
				export "rvm_${_temp_var//-/_}_flag=1" ;;
			(--32|--64) rvm_architectures+=("${1#--}") 
				rvm_disable_binary_flag=1  ;;
			(--universal) rvm_architectures+=("32" "64") 
				rvm_disable_binary_flag=1  ;;
			(--patches|--patch) __rvm_custom_separated_array rvm_patch_names , "${2:-}"
				rvm_patch_original_pwd="$PWD" 
				rvm_disable_binary_flag=1 
				shift ;;
			(--autolibs=*) export rvm_autolibs_flag="${1#*=}"  ;;
			(--) shift
				_new_args+=("$@") 
				shift $# ;;
			(*) _new_args+=("$1")  ;;
		esac
		(( $# == 0 )) || shift
	done
	eval "${_args_array_name}+=( \"\${_new_args[@]}\" )"
}
__rvm_parse_gems_args () {
	\typeset gem="${*%%;*}"
	if __rvm_string_match "$gem" "*.gem$"
	then
		gem_name="$(basename "${gem/.gem/}" |  __rvm_awk -F'-' '{$NF=NULL;print}')" 
		gem_version="$(basename "${gem/.gem/}" |  __rvm_awk -F'-' '{print $NF}' )" 
	else
		gem_name="${gem/ */}" 
		case "$gem" in
			(*--version*) gem_version=$(
          echo "$gem" | __rvm_sed -e 's#.*--version[=]*[ ]*##' | __rvm_awk '{print $1}'
        )  ;;
			(*-v*) gem_version=$(
          echo "$gem" | __rvm_sed -e 's#.*-v[=]*[ ]*##' | __rvm_awk '{print $1}'
        )  ;;
		esac
	fi
}
__rvm_patch () {
	\patch "$@" || return $?
}
__rvm_path_match_gem_home_check () {
	(( ${rvm_silence_path_mismatch_check_flag:-0} == 0 )) || return 0
	if [[ -n "${GEM_HOME:-}" ]]
	then
		case "$PATH:" in
			($GEM_HOME/bin:*) true ;;
			(*:$GEM_HOME/bin:*) __rvm_path_match_gem_home_check_warning "is not at first place" ;;
			(*) __rvm_path_match_gem_home_check_warning "is not available" ;;
		esac
	else
		\typeset __path_to_ruby
		if __path_to_ruby="$( builtin command -v ruby 2>/dev/null )"  && [[ "${__path_to_ruby}" == "${rvm_path}"* ]]
		then
			__path_to_ruby="${__path_to_ruby%/bin/ruby}" 
			__path_to_ruby="${__path_to_ruby##*/}" 
			__rvm_path_match_gem_home_check_warning_missing "${__path_to_ruby}"
		fi
	fi
}
__rvm_path_match_gem_home_check_warn () {
	rvm_warn "Warning! PATH is not properly set up, $1.
         <log>Usually this is caused by shell initialization files. Search for <code>PATH=...</code> entries.
         You can also re-add RVM to your profile by running: <code>rvm get stable --auto-dotfiles</code>
         To fix it temporarily in this shell session run: <code>rvm use $2</code>
         To ignore this error add <code>rvm_silence_path_mismatch_check_flag=1</code> to your <code>~/.rvmrc</code> file."
}
__rvm_path_match_gem_home_check_warning () {
	__rvm_path_match_gem_home_check_warn "$GEM_HOME/bin $1" "${GEM_HOME##*/}"
}
__rvm_path_match_gem_home_check_warning_missing () {
	__rvm_path_match_gem_home_check_warn "\$GEM_HOME is not set" "$1"
}
__rvm_print_headline () {
	rvm_log "Ruby enVironment Manager ${rvm_version} $(__rvm_version_copyright)
"
}
__rvm_project_dir_check () {
	\typeset _found_file path_to_check variable variable_default
	\typeset -a _valid_files
	path_to_check="$1" 
	variable="${2:-}" 
	variable_default="${3:-}" 
	_valid_files=("$path_to_check" "$path_to_check/.rvmrc" "$path_to_check/.versions.conf" "$path_to_check/.ruby-version" "$path_to_check/.rbfu-version" "$path_to_check/.rbenv-version" "$path_to_check/Gemfile") 
	__rvm_find_first_file _found_file "${_valid_files[@]}" || true
	if [[ ! -s "$_found_file" || "${_found_file}" == "$HOME/.rvmrc" ]]
	then
		_found_file="" 
	elif [[ "${_found_file##*/}" == "Gemfile" ]] && ! __rvm_grep "^#ruby=" "$_found_file" > /dev/null && ! __rvm_grep -E "^\s*ruby" "$_found_file" > /dev/null
	then
		_found_file="" 
	fi
	if [[ -n "$variable" ]]
	then
		eval "$variable=\"\${_found_file:-$variable_default}\""
	fi
	if [[ -n "${_found_file:-$variable_default}" ]]
	then
		RVM_PROJECT_PATH="${_found_file:-$variable_default}" 
		RVM_PROJECT_PATH="${RVM_PROJECT_PATH%/*}" 
	else
		\typeset __result=$?
		unset RVM_PROJECT_PATH
		return $__result
	fi
}
__rvm_project_rvmrc () {
	export __rvm_project_rvmrc_lock
	: __rvm_project_rvmrc_lock:${__rvm_project_rvmrc_lock:=0}
	: __rvm_project_rvmrc_lock:$((__rvm_project_rvmrc_lock+=1))
	if (( __rvm_project_rvmrc_lock > 1 ))
	then
		return 0
	fi
	\typeset working_dir found_file rvm_trustworthiness_result save_PATH
	working_dir="${1:-"$PWD"}" 
	save_PATH="${PATH}" 
	while :
	do
		if [[ -z "$working_dir" || "$HOME" == "$working_dir" || "${rvm_prefix:-}" == "$working_dir" || "$working_dir" == "." ]]
		then
			if (( ${rvm_project_rvmrc_default:-0} >= 1 ))
			then
				rvm_previous_environment=default 
			fi
			if [[ -n "${rvm_previous_environment:-""}" ]] && (( ${rvm_project_rvmrc_default:-0} < 2 ))
			then
				__rvm_load_environment "$rvm_previous_environment"
			fi
			__rvm_file_env_check_unload
			unset rvm_current_rvmrc rvm_previous_environment
			break
		else
			if __rvm_project_dir_check "$working_dir" found_file
			then
				rvm_trustworthiness_result=0 
				if [[ "${found_file}" != "${rvm_current_rvmrc:-""}" ]]
				then
					__rvm_conditionally_do_with_env __rvm_load_project_config "${found_file}" || {
						rvm_trustworthiness_result=$? 
						PATH="${save_PATH}" 
						unset RVM_PROJECT_PATH
					}
				fi
				unset __rvm_project_rvmrc_lock
				return "$rvm_trustworthiness_result"
			else
				working_dir="${working_dir%/*}" 
			fi
		fi
	done
	unset __rvm_project_rvmrc_lock
	return 1
}
__rvm_read_lines () {
	\typeset IFS
	IFS="
" 
	if [[ "${2:--}" == "-" ]]
	then
		eval "$1=( \$( \command \cat - ) )"
	else
		eval "$1=( \$( \command \cat \"\${2:--}\" ) )"
	fi
}
__rvm_readlink () {
	\readlink "$@" || return $?
}
__rvm_readlink_deep () {
	eval "
    while [[ -n \"\${$1}\" && -L \"\${$1}\" ]]
    do $1=\"\$(__rvm_readlink \"\${$1}\")\"
    done
  "
}
__rvm_record_install () {
	[[ -n "$1" ]] || return
	\typeset recorded_ruby_name rvm_install_record_file
	recorded_ruby_name="$( "$rvm_scripts_path/tools" strings "$1" )" 
	rvm_install_record_file="$rvm_user_path/installs" 
	[[ -f "$rvm_install_record_file" ]] || \command \touch "$rvm_install_record_file"
	__rvm_sed_i "$rvm_install_record_file" -e "/^$recorded_ruby_name/d"
	printf "%b" "$recorded_ruby_name -- ${rvm_configure_flags[*]}\n" >> "$rvm_install_record_file"
}
__rvm_record_ruby_configs () {
	\typeset __dir
	for __dir in "$rvm_path/rubies/"*
	do
		if [[ ! -L "${__dir}" && ! -s "${__dir}/config" && -x "${__dir}/bin/ruby" ]]
		then
			__rvm_ruby_config_save "${__dir}/bin/ruby" "${__dir}/config" || {
				\typeset string="${__dir##*/}"
				rvm_error "    Can not save config data for ruby: '${string}', most likely it is broken installation and you can:
    - try fix it: 'rvm reinstall ${string}', OR:
    - remove  it: 'rvm uninstall ${string} --gems'"
			}
		fi
	done
}
__rvm_recorded_install_command () {
	\typeset recorded_ruby_name
	recorded_ruby_name="$( "$rvm_scripts_path/tools" strings "$1" )" 
	recorded_ruby_name=${recorded_ruby_name%%${rvm_gemset_seperator:-"@"}*} 
	[[ -n "$recorded_ruby_name" ]] || return 1
	if [[ -s "$rvm_user_path/installs" ]] && __rvm_grep "^$recorded_ruby_name " "$rvm_user_path/installs" > /dev/null 2>&1
	then
		__rvm_grep "^$recorded_ruby_name " "$rvm_user_path/installs" | \command \head -n 1
	else
		return 1
	fi
}
__rvm_remote_extension () {
	case "$1" in
		(*.tar.*) rvm_remote_extension="tar${1##*tar}"  ;;
		(jruby-*) rvm_remote_extension="tar.gz"  ;;
		(*) rvm_remote_extension="tar.bz2"  ;;
	esac
	[[ "$2" != "-" ]] || printf "%b" "${rvm_remote_extension}"
}
__rvm_remote_server_path () {
	\typeset _iterator
	_iterator="" 
	while ! __rvm_remote_server_path_single 0 1 "${_iterator}" "${1:-}"
	do
		: $(( _iterator+=1 ))
	done
}
__rvm_remote_server_path_single () {
	\typeset __remote_file
	__rvm_calculate_remote_file "$@" || return $?
	if [[ -z "${__remote_file:-}" ]]
	then
		rvm_debug "No remote file name found"
		return $1
	elif file_exists_at_url "${__remote_file}"
	then
		rvm_debug "Remote file exists ${__remote_file}"
		printf "%b" "$( __rvm_db "rvm_remote_server_verify_downloads${3:-}" ):${__remote_file}"
	elif [[ -f "${rvm_archives_path}/${rvm_ruby_package_file##*/}" && "${rvm_ruby_package_file##*/}" == *bin-* ]]
	then
		rvm_debug "Cached file exists ${__remote_file}"
		printf "%b" "$( __rvm_db "rvm_remote_server_verify_downloads${3:-}" ):${rvm_archives_path}/${rvm_ruby_package_file##*/}"
	else
		rvm_debug "Remote file does not exist ${__remote_file}"
		return $2
	fi
}
__rvm_remove_broken_symlinks () {
	if [[ ! -e "$1" && -L "$1" ]]
	then
		__rvm_rm_rf "$1"
	fi
}
__rvm_remove_from_array () {
	\typeset _array_name _iterator _search
	\typeset -a _temp_array
	_array_name="$1" 
	_search="$2" 
	shift 2
	_temp_array=() 
	for _iterator
	do
		__rvm_string_match "$_iterator" "$_search" || _temp_array+=("$_iterator") 
	done
	eval "$_array_name=( \"\${_temp_array[@]}\" )"
}
__rvm_remove_from_path () {
	export PATH
	\typeset _value
	_value="${1//+(\/)//}" 
	if [[ $_value == "/*" ]]
	then
		return
	fi
	while [[ "$PATH" == *"//"* ]]
	do
		PATH="${PATH/\/\///}" 
	done
	while [[ "$PATH" == *"/:"* ]]
	do
		PATH="${PATH/\/:/:}" 
	done
	if __rvm_string_match ":$PATH:" "*:${_value}:*"
	then
		\typeset -a _path
		_path=() 
		__rvm_custom_separated_array _path : "${PATH}"
		__rvm_remove_from_array _path "${_value}" "${_path[@]}"
		__rvm_join_array PATH : _path
	fi
}
__rvm_remove_install_record () {
	\typeset recorded_ruby_name rvm_install_record_file
	recorded_ruby_name="$( "$rvm_scripts_path/tools" strings "$1" )" 
	rvm_install_record_file="$rvm_user_path/installs" 
	if [[ -s "$rvm_install_record_file" ]]
	then
		__rvm_sed_i "$rvm_install_record_file" -e "/^$recorded_ruby_name/d"
	fi
}
__rvm_remove_rvm_from_path () {
	\typeset local_rvm_path
	__rvm_remove_from_path "${rvm_path%/}/*"
	__rvm_remove_from_path "${rvm_gems_path%/}/*"
	__rvm_remove_from_path "${rvm_bin_path}"
	while local_rvm_path="$( __rvm_which rvm 2>/dev/null )" 
	do
		__rvm_remove_from_path "${local_rvm_path%/*}"
	done
	builtin hash -r
}
__rvm_remove_without_gems () {
	[[ -n "${rvm_without_gems}" ]] || return 0
	\typeset -a __gems_to_remove __extra_flags
	__rvm_read_lines __gems_to_remove <(
    GEM_PATH="$GEM_HOME" __rvm_list_gems "" "${rvm_without_gems}"
  )
	(( ${#__gems_to_remove[@]} )) || return 0
	__extra_flags=() 
	if __rvm_version_compare "$(\command \gem --version)" -ge 2.1.0
	then
		__extra_flags+=(--abort-on-dependent) 
	fi
	\typeset __gem __name __version
	for __gem in "${__gems_to_remove[@]}"
	do
		__name="${__gem% *}" 
		__version="${__gem##* }" 
		__rvm_log_command "gem.uninstall.${__name}-${__version}" "$rvm_ruby_string - #uninstalling gem ${__name}-${__version}" \command \gem uninstall "${__name}" -v "${__version}" -x "${__extra_flags[@]}" || true
	done
}
__rvm_replace_colors () {
	\typeset ___text
	___text="${1//<error>/$rvm_error_clr}" 
	___text="${___text//<warn>/$rvm_warn_clr}" 
	___text="${___text//<debug>/$rvm_debug_clr}" 
	___text="${___text//<notify>/$rvm_notify_clr}" 
	___text="${___text//<code>/$rvm_code_clr}" 
	___text="${___text//<comment>/$rvm_comment_clr}" 
	___text="${___text//<log>/$rvm_reset_clr}" 
	___text="${___text//<\/error>/$rvm_reset_clr}" 
	___text="${___text//<\/warn>/$rvm_reset_clr}" 
	___text="${___text//<\/debug>/$rvm_reset_clr}" 
	___text="${___text//<\/notify>/$rvm_reset_clr}" 
	___text="${___text//<\/code>/$rvm_reset_clr}" 
	___text="${___text//<\/comment>/$rvm_reset_clr}" 
	___text="${___text//<\/log>/$rvm_reset_clr}" 
	printf "%b" "${___text}$rvm_reset_clr"
}
__rvm_require () {
	[[ -f "$1" ]] && source "$1"
}
__rvm_reset_rvmrc_trust () {
	if [[ "$1" == all ]]
	then
		echo "" > "${rvm_user_path:-${rvm_path}/user}/rvmrcs"
	else
		__rvm_db_ "${rvm_user_path:-${rvm_path}/user}/rvmrcs" "$(__rvm_rvmrc_key "$1")" "delete" > /dev/null 2>&1
	fi
}
__rvm_rm_rf () {
	__rvm_rm_rf_verbose "$@"
}
__rvm_rm_rf_verbose () {
	\typeset target
	target="${1%%+(/|.)}" 
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		\builtin setopt extendedglob
	elif [[ -n "${BASH_VERSION:-}" ]]
	then
		\builtin shopt -s extglob
	else
		rvm_error "What the heck kind of shell are you running here???"
	fi
	case "${target}" in
		(*(/|.)@(|/Applications|/Developer|/Guides|/Information|/Library|/Network|/System|/User|/Users|/Volumes|/backups|/bdsm|/bin|/boot|/cores|/data|/dev|/etc|/home|/lib|/lib64|/mach_kernel|/media|/misc|/mnt|/net|/opt|/private|/proc|/root|/sbin|/selinux|/srv|/sys|/tmp|/usr|/var)) rvm_debug "__rvm_rm_rf target is not valid - can not remove"
			return 1 ;;
		(*) if [[ -z "${target}" ]]
			then
				rvm_debug "__rvm_rm_rf target not given"
				return 1
			elif [[ -d "${target}" ]]
			then
				\command \rm -rf "${target}" || {
					\typeset ret=$?
					rvm_debug "__rvm_rm_rf error removing target dir '${target}'."
					return $ret
				}
			elif [[ -f "${target}" || -L "${target}" ]]
			then
				\command \rm -f "${target}" || {
					\typeset ret=$?
					rvm_debug "__rvm_rm_rf error removing target file/link '${target}'."
					return $ret
				}
			else
				rvm_debug "__rvm_rm_rf already gone: $*"
			fi ;;
	esac
	true
}
__rvm_ruby_config_get () {
	\typeset variable_name ruby_path
	variable_name="$1" 
	ruby_path="${2:-$rvm_ruby_home/bin/ruby}" 
	__rvm_string_match "$ruby_path" "*mruby*" && return
	case "${variable_name:---all}" in
		(--all) "$ruby_path" -rrbconfig -e 'puts RbConfig::CONFIG.sort.map{|k,v| "#{k}: #{v}" }' 2> /dev/null || return $? ;;
		(*) "$ruby_path" -rrbconfig -e 'puts RbConfig::CONFIG["'"$variable_name"'"]' 2> /dev/null || return $? ;;
	esac
}
__rvm_ruby_config_save () {
	\typeset ruby_path
	ruby_path="${1:-$rvm_ruby_home/bin/ruby}" 
	case "$ruby_path" in
		(*/mruby*) __rvm_ruby_config_save_mruby "${2:-${ruby_path%%/bin/ruby}/config}" ;;
		(*) __rvm_ruby_config_save_generic "$2" ;;
	esac
}
__rvm_ruby_config_save_generic () {
	\typeset config_path default_config_path
	default_config_path="#{RbConfig::CONFIG[\"prefix\"]}/config" 
	config_path="${1:-$default_config_path}" 
	"$ruby_path" -rrbconfig -e '\
    File.open("'"$config_path"'","w") { |file|
      RbConfig::CONFIG.sort.each{|key,value|
        file.write("#{key.gsub(/\.|-/,"_")}=\"#{value.to_s.gsub("$","\\$")}\"\n")
      }
    }
  ' > /dev/null 2>&1
}
__rvm_ruby_config_save_mruby () {
	echo "target_cpu=\"$_system_arch\"" > "$1"
}
__rvm_ruby_package_file () {
	case "$1" in
		(*.tar.*) rvm_ruby_package_file="/$1"  ;;
		(rbx* | rubinius*) rvm_ruby_package_file="/${1//rbx/rubinius}.$(__rvm_remote_extension "$1" -)"  ;;
		(jruby-head) rvm_ruby_package_file="/jruby-head.$(__rvm_remote_extension "$1" -)"  ;;
		(jruby*) \typeset __version
			__version="$(
        rvm_ruby_string="$1"
        rvm_remote_flag=0 __rvm_ruby_string
        echo "$rvm_ruby_version"
      )" 
			rvm_ruby_package_file="/${__version}/jruby-dist-${__version}-bin.$(__rvm_remote_extension "$1" -)"  ;;
		("") rvm_ruby_package_file=""  ;;
		(ruby* | mruby*) rvm_ruby_package_file="/$1.$(__rvm_remote_extension "$1" -)"  ;;
		(*) rvm_ruby_package_file="/ruby-$1.$(__rvm_remote_extension "$1" -)"  ;;
	esac
}
__rvm_ruby_string () {
	true ${rvm_head_flag:=0} ${rvm_delete_flag:=0}
	rvm_expanding_aliases='' 
	true "${rvm_ruby_version:=}" "${rvm_gemset_name:=}" "${rvm_ruby_interpreter:=}" "${rvm_ruby_version:=}" "${rvm_ruby_tag:=}" "${rvm_ruby_patch_level:=}" "${rvm_ruby_revision:=}" ${rvm_gemset_separator:="@"} "${rvm_ruby_string:=}" ${rvm_expanding_aliases:=0} ${rvm_head_flag:=0}
	if [[ "$rvm_ruby_string" == *"${rvm_gemset_separator}"* ]]
	then
		rvm_gemset_name="${rvm_ruby_string/*${rvm_gemset_separator}/}" 
		rvm_ruby_string="${rvm_ruby_string/${rvm_gemset_separator}*/}" 
	fi
	if (( rvm_expanding_aliases == 0 )) && [[ -n "${rvm_ruby_string}" && "$rvm_ruby_string" != "system" ]]
	then
		if [[ -f "$rvm_path/config/known_aliases" && -s "$rvm_path/config/known_aliases" ]] && expanded_alias_name="$(__rvm_db_ "$rvm_path/config/known_aliases" "$rvm_ruby_string")"  && [[ -n "$expanded_alias_name" ]]
		then
			rvm_ruby_string="$expanded_alias_name" 
		fi
	fi
	if (( rvm_expanding_aliases == 0 )) && [[ -n "${rvm_ruby_string}" && "$rvm_ruby_string" != "system" ]]
	then
		if [[ -f "$rvm_path/config/alias" && -s "$rvm_path/config/alias" ]] && expanded_alias_name="$(__rvm_db_ "$rvm_path/config/alias" "$rvm_ruby_string")"  && [[ -n "$expanded_alias_name" ]]
		then
			rvm_ruby_string="$expanded_alias_name" 
		elif [[ "$rvm_ruby_string" == default ]]
		then
			rvm_ruby_string="system" 
		fi
		if [[ "$rvm_ruby_string" == *"${rvm_gemset_separator}"* ]]
		then
			rvm_gemset_name="${rvm_ruby_string/*${rvm_gemset_separator}/}" 
			rvm_ruby_string="${rvm_ruby_string/${rvm_gemset_separator}*/}" 
		fi
	fi
	if [[ -n "$gemset_name" ]]
	then
		rvm_gemset_name="$gemset_name" 
		rvm_sticky_flag=1 
	fi
	__rvm_ruby_string_parse || return $?
	__rvm_ruby_string_find
	detected_rvm_ruby_name="${rvm_ruby_name:-}" 
	rvm_ruby_name="" 
	true
}
__rvm_ruby_string_autodetect () {
	if [[ -z "${rvm_ruby_version:-}" && "${rvm_ruby_interpreter}" != "ext" && "${rvm_ruby_interpreter}" != "system" ]] && (( ${rvm_head_flag:=0} == 0 ))
	then
		if (( ${rvm_fuzzy_flag:-0} == 1 ))
		then
			rvm_ruby_version="$(
        __rvm_list_strings |
        __rvm_grep "^${rvm_ruby_interpreter}-.*${rvm_ruby_name:-}" |
        __rvm_awk -F- '{print $2}' |
        __rvm_version_sort |
        __rvm_tail -n 1
      )" 
		fi
		rvm_ruby_version="${rvm_ruby_version:-"$(
      __rvm_db "${rvm_ruby_interpreter}_version"
    )"}" 
	fi
	if (( ${rvm_head_flag:=0} )) && [[ "${rvm_ruby_interpreter}" == "ruby" ]] && __rvm_version_compare "${rvm_ruby_version}" -ge 2.1
	then
		__rvm_take_n rvm_ruby_version 2 .
	fi
	rvm_ruby_string="${rvm_ruby_interpreter}${rvm_ruby_version:+-}${rvm_ruby_version:-}" 
	if [[ "${rvm_ruby_interpreter}" == "ext" ]]
	then
		true
	elif [[ "${rvm_head_flag:=0}" == "1" || -n "${rvm_ruby_sha:-}" || -n "${rvm_ruby_tag:-}" || -n "${rvm_ruby_repo_tag:-}" ]]
	then
		if [[ "${rvm_head_flag:=0}" == "1" ]]
		then
			rvm_ruby_string="${rvm_ruby_string}-head" 
		fi
		if [[ -n "${rvm_ruby_sha:-}" ]]
		then
			rvm_ruby_string="${rvm_ruby_string}-s${rvm_ruby_sha}" 
		elif [[ -n "${rvm_ruby_repo_tag:-}" ]]
		then
			rvm_ruby_string="${rvm_ruby_string}-tag${rvm_ruby_repo_tag}" 
		elif [[ -n "${rvm_ruby_tag:-}" ]]
		then
			rvm_ruby_string="${rvm_ruby_string}-${rvm_ruby_tag}" 
		fi
		if [[ ! -d "${rvm_rubies_path}/${rvm_ruby_string}" ]] && (( ${rvm_fuzzy_flag:-0} == 1 ))
		then
			\typeset new_ruby_string
			new_ruby_string="$(
        __rvm_list_strings |
        __rvm_grep "^${rvm_ruby_string}.*${rvm_ruby_name:-}" |
        __rvm_version_sort |
        __rvm_tail -n 1
      )" 
			rvm_ruby_string="${new_ruby_string:-$rvm_ruby_string}" 
		fi
	elif [[ -n "${rvm_ruby_revision:-}" ]]
	then
		rvm_ruby_string="${rvm_ruby_string}-${rvm_ruby_revision}" 
	elif [[ -n "${rvm_ruby_patch_level:-}" ]]
	then
		rvm_ruby_string="${rvm_ruby_string}-${rvm_ruby_patch_level}" 
	elif [[ -n "${rvm_ruby_user_tag:-}" ]]
	then
		rvm_ruby_string="${rvm_ruby_string}-${rvm_ruby_user_tag}" 
	else
		if (( ${rvm_fuzzy_flag:-0} == 1 )) && [[ "${rvm_ruby_interpreter}" == "ruby" || "${rvm_ruby_interpreter}" == "ree" ]]
		then
			rvm_ruby_patch_level="$(
        __rvm_list_strings |
        __rvm_grep "^${rvm_ruby_interpreter}-${rvm_ruby_version}-.*${rvm_ruby_name:-}" |
        __rvm_awk -F- '{print $3}' |
        __rvm_version_sort |
        __rvm_tail -n 1
      )" 
		fi
		[[ -n "${rvm_ruby_patch_level:-""}" ]] || __rvm_db_system "${rvm_ruby_interpreter}_${rvm_ruby_version}_patch_level" rvm_ruby_patch_level
		if [[ -n "${rvm_ruby_patch_level:-""}" ]]
		then
			rvm_ruby_string="${rvm_ruby_string}-${rvm_ruby_patch_level}" 
		fi
	fi
	true
}
__rvm_ruby_string_find () {
	if __rvm_ruby_string_installed
	then
		true
	elif __rvm_ruby_string_remotely_available
	then
		true
	else
		__rvm_ruby_string_autodetect
		case "${rvm_ruby_string}" in
			(ruby-+([1-9])|ruby-+([1-9]).+([0-9])|ruby-1.+([1-9]).+([0-9])|jruby-[19]*) __rvm_ruby_string_latest && __rvm_ruby_string_parse_ || return $? ;;
		esac
	fi
	if [[ -n "${rvm_ruby_name:-}" && ! "${rvm_ruby_string}" == *"-${rvm_ruby_name}" ]]
	then
		rvm_ruby_string="${rvm_ruby_string}${rvm_ruby_name:+-}${rvm_ruby_name:-}" 
	fi
}
__rvm_ruby_string_fuzzy () {
	\typeset new_ruby_string __search
	__search="${rvm_ruby_string}" 
	if [[ -n "${rvm_ruby_name:-}" ]]
	then
		__search="${__search%${rvm_ruby_name:-}}.*${rvm_ruby_name:-}" 
	fi
	new_ruby_string="$(
    __rvm_list_strings |
    __rvm_grep "${__search//\./\\.}" |
    __rvm_version_sort |
    __rvm_tail -n 1
  )" 
	if [[ -n "${new_ruby_string}" ]]
	then
		rvm_ruby_string="${new_ruby_string}" 
	else
		return $?
	fi
}
__rvm_ruby_string_fuzzy_remote () {
	\typeset new_ruby_string __search
	__search="${rvm_ruby_string}" 
	if [[ -n "${rvm_ruby_name:-}" ]]
	then
		__search="${__search%${rvm_ruby_name:-}}.*${rvm_ruby_name:-}" 
	fi
	new_ruby_string="$(
    __list_remote_all |
    __rvm_awk -F/ '{ x=$NF;
      gsub(".tar.*","",x);
      gsub("jruby-bin","jruby",x);
      gsub("rubinius","rbx",x);
      print x}' |
    __rvm_version_sort |
    __rvm_awk '
BEGIN{found=""; any=""}
/^'"${__search}"'$/ {found=$1}
/^'"${__search}"'/ {any=$1}
END{if (found) print found; else if (any) print any;}
'
  )" 
	rvm_ruby_string="${new_ruby_string:-$rvm_ruby_string}" 
}
__rvm_ruby_string_installed () {
	\typeset __ruby_inst_dir="$rvm_rubies_path/${rvm_ruby_string}"
	if [[ -n "${rvm_ruby_name:-}" && ! "${rvm_ruby_string}" == *"-${rvm_ruby_name}" ]]
	then
		__ruby_inst_dir="${__ruby_inst_dir}-${rvm_ruby_name}" 
	fi
	[[ -n "$rvm_ruby_interpreter" && -n "${rvm_ruby_string}" && -d "${__ruby_inst_dir}" ]] && [[ -z "${rvm_gemset_name}" || ${rvm_create_flag:-0} -eq 1 || -d "${__ruby_inst_dir}${rvm_gemset_separator}${rvm_gemset_name}" ]]
}
__rvm_ruby_string_latest () {
	\typeset check_ruby_string new_ruby_string
	check_ruby_string="" 
	if [[ -n "${rvm_ruby_interpreter}" ]]
	then
		check_ruby_string+="${rvm_ruby_interpreter}-" 
	fi
	if [[ -n "${rvm_ruby_version}" ]]
	then
		check_ruby_string+="${rvm_ruby_version//\./\.}.*" 
	fi
	if [[ -n "${rvm_ruby_patch_level}" ]]
	then
		check_ruby_string+="${rvm_ruby_patch_level//\./\.}.*" 
	fi
	if [[ -z "${check_ruby_string}" ]]
	then
		check_ruby_string="$rvm_ruby_string" 
	fi
	new_ruby_string="$(
    \command \cat "$rvm_path/config/known_strings" |
    __rvm_grep "${check_ruby_string}" |
    __rvm_version_sort |
    __rvm_tail -n 1
  )" 
	if [[ -n "${new_ruby_string}" ]]
	then
		rvm_ruby_string="${new_ruby_string}" 
	else
		rvm_error "Unknown ruby string (do not know how to handle): $rvm_ruby_string."
		return 1
	fi
}
__rvm_ruby_string_parse () {
	__rvm_ruby_string_parse_ || true
	if (( ${rvm_fuzzy_flag:-0} == 1 )) && [[ ! -d "${rvm_rubies_path}/${rvm_ruby_string}" ]]
	then
		if (( ${rvm_remote_flag:-0} == 1 ))
		then
			__rvm_ruby_string_fuzzy || __rvm_ruby_string_fuzzy_remote || return $?
		else
			__rvm_ruby_string_fuzzy || true
		fi
	fi
	__rvm_ruby_string_parse_ || return $?
	if [[ -z "${rvm_ruby_interpreter}" ]]
	then
		rvm_error "Unknown ruby interpreter version (do not know how to handle): $rvm_ruby_string."
		return 1
	fi
}
__rvm_ruby_string_parse_ () {
	\typeset ruby_string gemset_name expanded_alias_name repo_url branch_name ruby_name tag_name
	ruby_string="${rvm_ruby_string:-}" 
	gemset_name="${rvm_gemset_name:-}" 
	repo_url="${rvm_ruby_repo_url:-}" 
	branch_name="${rvm_ruby_repo_branch:-}" 
	ruby_name="${rvm_ruby_name:-}" 
	tag_name="${rvm_ruby_repo_tag:-}" 
	__rvm_unset_ruby_variables
	rvm_ruby_repo_url="${repo_url:-}" 
	rvm_ruby_repo_branch="${branch_name:-}" 
	rvm_ruby_name="$ruby_name" 
	rvm_ruby_repo_tag="${rvm_ruby_repo_tag:-}" 
	export rvm_head_flag=0 
	if [[ -z "${ruby_string}" || "${ruby_string}" == "current" ]]
	then
		if [[ "${GEM_HOME:-}" == *"${rvm_gems_path}"* ]]
		then
			ruby_string="${GEM_HOME##*\/}" 
			ruby_string="${ruby_string/%${rvm_gemset_separator:-"@"}*}" 
		else
			ruby_string="system" 
		fi
	fi
	strings=() 
	__rvm_custom_separated_array strings - "${ruby_string}"
	rvm_ruby_string="${ruby_string}" 
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		setopt LOCAL_OPTIONS KSH_GLOB
	fi
	for string in ${strings[@]}
	do
		case "$string" in
			(head) rvm_ruby_patch_level="" 
				rvm_ruby_revision="" 
				rvm_ruby_tag="" 
				rvm_head_flag=1  ;;
			(system) rvm_ruby_interpreter="system" 
				rvm_ruby_patch_level="" 
				rvm_ruby_tag="" 
				rvm_ruby_revision="" 
				rvm_ruby_version="" 
				rvm_gemset_name="" 
				rvm_head_flag=0 
				return 0 ;;
			(ext|external) rvm_ruby_interpreter="ext" 
				rvm_ruby_patch_level="" 
				rvm_ruby_tag="" 
				rvm_ruby_revision="" 
				rvm_ruby_version="" 
				rvm_head_flag=0 
				rvm_ruby_name="${ruby_string:-${rvm_ruby_string}}" 
				rvm_ruby_name="${rvm_ruby_name#*-}" 
				break ;;
			(nightly|weekly|monthly) case "${rvm_ruby_interpreter}" in
					(rbx|rubinius) rvm_ruby_patch_level="$string"  ;;
					(*) rvm_ruby_version="$string"  ;;
				esac
				rvm_nightly_flag=1  ;;
			(nightly*|weekly*|monthly*) case "${rvm_ruby_interpreter}" in
					(rbx|rubinius) rvm_ruby_patch_level="$string"  ;;
					(*) rvm_ruby_version="$string"  ;;
				esac ;;
			(preview*) rvm_ruby_patch_level="$string"  ;;
			(rc[0-9]*) rvm_ruby_patch_level="$string"  ;;
			(+([0-9]).+([0-9]).[0-9]*) rvm_ruby_version="${string}" 
				rvm_ruby_revision="" 
				rvm_ruby_tag=""  ;;
			([0-9][0-9]*) case "${rvm_ruby_interpreter:-""}" in
					(ree) rvm_ruby_patch_level="$string" 
						rvm_ruby_revision=""  ;;
					(maglev) rvm_ruby_version="$string" 
						rvm_ruby_revision="" 
						rvm_ruby_patch_level=""  ;;
					(*) rvm_ruby_version="${string}" 
						rvm_ruby_revision="" 
						rvm_ruby_tag=""  ;;
				esac ;;
			([0-9]*) rvm_ruby_version="${string}" 
				rvm_ruby_revision="" 
				rvm_ruby_tag=""  ;;
			(p[0-9]*) rvm_ruby_patch_level="$string"  ;;
			(r[0-9]*) rvm_ruby_patch_level="" 
				rvm_ruby_revision="$string"  ;;
			(s[0-9a-zA-ZuU]*) rvm_ruby_revision="" 
				rvm_ruby_sha="${string#s}"  ;;
			(tag[0-9]) rvm_ruby_repo_tag="$string"  ;;
			(tv[0-9]*|t[0-9]*) rvm_ruby_patch_level="" 
				rvm_ruby_revision="" 
				rvm_ruby_tag="$string"  ;;
			(m[0-9]*) rvm_ruby_mode="$string"  ;;
			(u[0-9a-zA-ZuU]*) rvm_ruby_patch_level="" 
				rvm_ruby_revision="" 
				rvm_ruby_tag="" 
				rvm_ruby_patch="" 
				rvm_ruby_user_tag="$string"  ;;
			(b[0-9]*) rvm_ruby_repo_branch="${string}" 
				rvm_head_flag=1  ;;
			(rubinius) rvm_ruby_interpreter="rbx"  ;;
			(opal|ruby|rbx|jruby|macruby|ree|maglev|ironruby|mruby|topaz|truffleruby) rvm_ruby_interpreter="$string"  ;;
			([a-zA-ZuU]*([0-9a-zA-ZuU]|_)) rvm_ruby_name="$string"  ;;
			(*) rvm_ruby_string="${ruby_string:-}" 
				return 0 ;;
		esac
	done
	if [[ -z "${rvm_ruby_interpreter}" && -n "${rvm_ruby_version}" ]]
	then
		case "${rvm_ruby_version}" in
			(1.[5-7]*|9*) rvm_ruby_interpreter=jruby  ;;
			(1.[8-9]*|2*|3*) rvm_ruby_interpreter=ruby  ;;
		esac
		if [[ -n "${rvm_ruby_interpreter}" ]]
		then
			rvm_ruby_string="${rvm_ruby_interpreter}-${rvm_ruby_string}" 
		fi
	fi
	true
}
__rvm_ruby_string_paths_under () {
	\typeset __search_path part parts IFS
	IFS=" " 
	__search_path="${1%/}" 
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		parts=(${=rvm_ruby_string//-/ }) 
	else
		parts=(${rvm_ruby_string//-/ }) 
	fi
	echo "$__search_path"
	for part in "${parts[@]}"
	do
		__search_path="$__search_path/$part" 
		echo "$__search_path"
	done
}
__rvm_ruby_string_remotely_available () {
	(( ${rvm_remote_flag:-0} == 1 )) && [[ -n "$rvm_ruby_interpreter" && -n "${rvm_ruby_string}" ]] && __rvm_remote_server_path "${rvm_ruby_string}" > /dev/null
}
__rvm_ruby_strings_exist () {
	for rvm_ruby_string in ${@//,/ }
	do
		rvm_gemset_name="" 
		rvm_verbose_flag=0 __rvm_use "${rvm_ruby_string}" > /dev/null 2>&1 || return $?
		true rvm_gemset_name:${rvm_gemset_name:=${rvm_expected_gemset_name}}
		printf "%b" "${rvm_ruby_string}${rvm_gemset_name:+@}${rvm_gemset_name:-}\n"
	done
	unset rvm_ruby_string
}
__rvm_rubygems_create_link () {
	\typeset ruby_lib_gem_path
	\command \mkdir -p "$rvm_ruby_gem_home/bin"
	rubygems_detect_ruby_lib_gem_path "${1:-ruby}" || return 0
	if [[ -L "$ruby_lib_gem_path" && -w "$ruby_lib_gem_path" ]]
	then
		rm -rf "$ruby_lib_gem_path"
	fi
	if [[ -e "$rvm_ruby_global_gems_path" && ! -L "$rvm_ruby_global_gems_path" ]]
	then
		rm -rf "$rvm_ruby_global_gems_path"
	fi
	[[ -d "$ruby_lib_gem_path" ]] || \command \mkdir -p "$ruby_lib_gem_path"
	if [[ -w "$ruby_lib_gem_path" ]]
	then
		[[ -L "$rvm_ruby_global_gems_path" ]] || ln -fs "$ruby_lib_gem_path" "$rvm_ruby_global_gems_path"
	else
		[[ -d "$rvm_ruby_global_gems_path" ]] || \command \mkdir -p "$rvm_ruby_global_gems_path"
	fi
	\command \mkdir -p "$rvm_ruby_global_gems_path/bin"
}
__rvm_run_wrapper () {
	(
		file="$1" 
		action="${2:-}" 
		shift 2
		rubies_string="${1:-}" 
		args=($@) 
		source "$rvm_scripts_path"/base
		source "$rvm_scripts_path"/$file
	)
}
__rvm_rvmrc_key () {
	printf "%b" "$1" | \command \tr '[#/.=()]' _
	return $?
}
__rvm_rvmrc_match_all () {
	[[ "${1:-}" == "all" || "${1:-}" == "all.rvmrcs" || "${1:-}" == "allGemfiles" ]]
}
__rvm_rvmrc_notice_display_post () {
	__rvm_table "Viewing of ${_rvmrc} complete." <<TEXT
Trusting an ${_rvmrc_base} file means that whenever you cd into this directory, RVM will run this ${_rvmrc_base} shell script.
Note that if the contents of the file change, you will be re-prompted to review the file and adjust its trust settings. You may also change the trust settings manually at any time with the 'rvm rvmrc' command.
TEXT
}
__rvm_rvmrc_notice_initial () {
	__rvm_table "NOTICE" <<TEXT
RVM has encountered a new or modified ${_rvmrc_base} file in the current directory, this is a shell script and therefore may contain any shell commands.

Examine the contents of this file carefully to be sure the contents are safe before trusting it!
Do you wish to trust '${_rvmrc}'?
Choose v[iew] below to view the contents
TEXT
}
__rvm_rvmrc_stored_trust () {
	[[ -f "$1" ]] || return 1
	__rvm_db_ "${rvm_user_path:-${rvm_path}/user}/rvmrcs" "$(__rvm_rvmrc_key "$1")" || return $?
}
__rvm_rvmrc_stored_trust_check () {
	\typeset _first _second _rvmrc _rvmrc_base
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		_first=1 
	else
		_first=0 
	fi
	_second=$(( _first + 1 )) 
	_rvmrc="${1}" 
	_rvmrc_base="$(basename "${_rvmrc}")" 
	if [[ -f "$_rvmrc" ]]
	then
		saveIFS=$IFS 
		IFS=$';' 
		trust=($(__rvm_rvmrc_stored_trust "$_rvmrc")) 
		IFS=$saveIFS 
		if [[ "${trust[${_second}]:-'#'}" != "$(__rvm_checksum_for_contents "$_rvmrc")" ]]
		then
			echo "The '$_rvmrc' contains unreviewed changes."
			return 1
		elif [[ "${trust[${_first}]}" == '1' ]]
		then
			echo "The '$_rvmrc' is currently trusted."
			return 0
		elif [[ "${trust[${_first}]}" == '0' ]]
		then
			echo "The '$_rvmrc' is currently untrusted."
			return 1
		else
			echo "The trustiworthiness of '$_rvmrc' is currently unknown."
			return 1
		fi
	else
		echo "There is no '$_rvmrc'"
		return 1
	fi
}
__rvm_rvmrc_to () {
	case "${1:-help}" in
		(.ruby-version|ruby-version) __rvm_rvmrc_to_ruby_version || return $? ;;
		(help) rvm_help rvmrc to
			return 0 ;;
		(*) rvm_error_help "Unknown subcommand '$1'" rvmrc to
			return 1 ;;
	esac
}
__rvm_rvmrc_to_ruby_version () {
	(
		[[ -s "$PWD/.rvmrc" ]] || {
			rvm_error "No .rvmrc to convert"
			return 2
		}
		__rvm_load_project_config "$PWD/.rvmrc" || {
			rvm_error "Could not load .rvmrc"
			return 3
		}
		__rvm_set_ruby_version
		\command \rm .rvmrc || {
			rvm_error "Could not remove .rvmrc"
			return 4
		}
	)
}
__rvm_rvmrc_tools () {
	\typeset rvmrc_action rvmrc_warning_action rvmrc_path saveIFS trust rvmrc_ruby
	rvmrc_action="$1" 
	(( $# )) && shift || true
	if [[ "${rvmrc_action}" == "warning" ]]
	then
		rvmrc_warning_action="${1:-}" 
		(( $# )) && shift || true
	fi
	if [[ "${rvmrc_action}" == "create" ]]
	then
		rvmrc_ruby="${1:-${GEM_HOME##*/}}" 
		rvmrc_path="$(__rvm_cd "$PWD" >/dev/null 2>&1; pwd)/${2:-.rvmrc}" 
	elif [[ "$1" == ".rvmrc" ]]
	then
		rvmrc_path="$PWD/.rvmrc" 
	elif [[ "${rvmrc_action}" == "to" || "${rvmrc_action}" == "warning" ]] || [[ -n "${1:-}" ]]
	then
		rvmrc_path="$1" 
	else
		rvmrc_path="$PWD/.rvmrc" 
	fi
	if [[ "${rvmrc_action}" == "to" || "${rvmrc_action}" == "warning" || "${rvmrc_action}" == "create" ]] || __rvm_rvmrc_match_all "${rvmrc_path:-}"
	then
		true
	else
		__rvm_project_dir_check "${rvmrc_path}" rvmrc_path "${rvmrc_path}/.rvmrc"
	fi
	rvmrc_path="${rvmrc_path//\/\///}" 
	rvmrc_path="${rvmrc_path%/}" 
	case "$rvmrc_action" in
		(warning) __rvmrc_warning "${rvmrc_warning_action:-}" "$rvmrc_path" || return $? ;;
		(to) __rvm_rvmrc_to "$rvmrc_path" || return $? ;;
		(create) (
				rvm_create_flag=1 __rvm_use "${rvmrc_ruby}"
				case "${rvmrc_path}" in
					(*/.rvmrc|*/--rvmrc) __rvm_set_rvmrc ;;
					(*/.ruby-version|*/--ruby-version) __rvm_set_ruby_version ;;
					(*/.versions.conf|*/--versions-conf) __rvm_set_versions_conf ;;
					(*) rvm_error "Unrecognized project file format."
						return 1 ;;
				esac
			) ;;
		(reset) __rvm_reset_rvmrc_trust "$rvmrc_path" && rvm_log "Reset trust for $rvmrc_path" || rvm_error "Reset trust for $rvmrc_path - failed" ;;
		(trust) __rvm_trust_rvmrc "$rvmrc_path" && rvm_log "Marked $rvmrc_path as trusted" || rvm_error "Marked $rvmrc_path as trusted - failed" ;;
		(untrust) __rvm_untrust_rvmrc "$rvmrc_path" && rvm_log "Marked $rvmrc_path as untrusted" || rvm_error "Marked $rvmrc_path as untrusted - failed" ;;
		(trusted) __rvm_rvmrc_stored_trust_check "$rvmrc_path" || return $? ;;
		(is_trusted) __rvm_rvmrc_stored_trust_check "$rvmrc_path" > /dev/null ;;
		(load) rvm_current_rvmrc="" rvm_trust_rvmrcs_flag=1 __rvm_project_rvmrc "${rvmrc_path%/.rvmrc}" ;;
		(try_to_read_ruby) __rvm_rvmrc_tools_try_to_read_ruby "$@" || return $? ;;
		(*) rvm_error "Usage: rvm rvmrc {trust,untrust,trusted,load,reset,is_trusted,try_to_read_ruby,create}"
			return 1 ;;
	esac
	return $?
}
__rvm_rvmrc_tools_read_ruby () {
	\typeset __result
	\typeset -a rvmrc_tools_read_ruby
	rvmrc_tools_read_ruby=() 
	__rvm_save_variables rvmrc_tools_read_ruby rvm_current_rvmrc result current_result rvm_token next_token rvm_action _string
	rvm_current_rvmrc="" 
	rvm_action="${rvm_action:-use}" rvm_trust_rvmrcs_flag=1 __rvm_project_rvmrc "$rvmrc_path" > /dev/null && rvm_ruby_string="${GEM_HOME##*/}"  && rvm_ruby_strings="$rvm_ruby_string"  || __result=101 
	__rvm_set_env "" "${rvmrc_tools_read_ruby[@]}"
	return ${__result:-0}
}
__rvm_rvmrc_tools_try_to_read_ruby () {
	case "$rvmrc_path" in
		(*/.rvmrc) if [[ -n "${rvm_trust_rvmrcs_flag:-}" ]]
			then
				export rvm_trust_rvmrcs_flag
			fi
			rvmrc_path="$(cd "$(dirname "$rvmrc_path")"; pwd)/.rvmrc" 
			__rvm_rvmrc_tools is_trusted "$(dirname "$rvmrc_path")" .rvmrc || (
				rvm_promptless=1 __rvm_project_rvmrc "$rvmrc_path" > /dev/null 2>&1
			)
			if __rvm_rvmrc_tools is_trusted "$(dirname "$rvmrc_path")" .rvmrc
			then
				__rvm_rvmrc_tools_read_ruby "$@" || return $?
			else
				return 1
			fi ;;
		(*) __rvm_rvmrc_tools_read_ruby "$@" || return $? ;;
	esac
}
__rvm_save_variables () {
	\typeset __save_to __key
	__save_to="$1" 
	shift
	for __key in "$@"
	do
		eval "${__save_to}+=( \"\${__key}=\${${__key}}\" )"
	done
}
__rvm_sed () {
	\sed "$@" || return $?
}
__rvm_sed_i () {
	\typeset _filename _executable _user
	[[ -n "${1:-}" ]] || {
		rvm_debug "no file given for __rvm_sed_i"
		return 0
	}
	_filename="$1" 
	shift
	if [[ -x "${_filename}" ]]
	then
		_executable=true 
	fi
	_user="$( __rvm_statf "%u:%g" "%u:%g" "${_filename}" )" 
	{
		__rvm_sed "$@" < "${_filename}" > "${_filename}.new" && \command \mv -f "${_filename}.new" "${_filename}"
	} 2>&1 | rvm_debug_stream
	if [[ -n "${_executable:-}" && ! -x "${_filename}" ]]
	then
		chmod +x "${_filename}"
	fi
	if [[ "$_user" != "$( __rvm_statf "%u:%g" "%u:%g" "${_filename}" )" ]]
	then
		chown "$_user" "${_filename}"
	fi
}
__rvm_select () {
	true ${rvm_gemset_name:=}
	__rvm_select_set_variable_defaults && __rvm_select_detect_ruby_string "${1:-}" && __rvm_ruby_string && __rvm_select_after_parse || return $?
}
__rvm_select_after_parse () {
	__rvm_select_interpreter_variables && __rvm_select_version_variables && __rvm_select_default_variables || return $?
	[[ "system" == "$rvm_ruby_interpreter" ]] || __rvm_gemset_select || return $result
	rvm_ruby_selected_flag=1 
}
__rvm_select_default_variables () {
	if [[ "${rvm_ruby_interpreter}" != ext ]]
	then
		rvm_ruby_package_name="${rvm_ruby_package_name:-${rvm_ruby_string//-n*}}" 
	fi
	rvm_ruby_home="$rvm_rubies_path/$rvm_ruby_string" 
	rvm_ruby_binary="$rvm_ruby_home/bin/ruby" 
	rvm_ruby_irbrc="$rvm_ruby_home/.irbrc" 
}
__rvm_select_detect_ruby_string () {
	rvm_ruby_string="${1:-${rvm_ruby_string:-${rvm_env_string:-}}}" 
	if [[ -z "${rvm_ruby_string:-}" ]]
	then
		rvm_ruby_string="${rvm_ruby_interpreter:-}" 
		rvm_ruby_string="${rvm_ruby_string:-}${rvm_ruby_version:+-}${rvm_ruby_version:-}" 
		rvm_ruby_string="${rvm_ruby_string:-}${rvm_ruby_patch_level:+-}${rvm_ruby_patch_level:-}" 
		rvm_ruby_string="${rvm_ruby_string:-}${rvm_ruby_revision:+-}${rvm_ruby_revision:-}" 
		if [[ -n "${rvm_ruby_name:-}" ]]
		then
			rvm_ruby_name="$rvm_ruby_string-$rvm_ruby_name" 
		fi
	fi
}
__rvm_select_interpreter_common () {
	rvm_ruby_interpreter="${1}" 
	rvm_ruby_version="head" 
	rvm_ruby_patch_level="" 
	export rvm_head_flag=1 
	rvm_ruby_repo_url="${rvm_ruby_repo_url:-$(__rvm_db "${1}_repo_url")}" 
	rvm_ruby_url=$rvm_ruby_repo_url 
	rvm_ruby_configure="" 
	rvm_ruby_make="" 
	rvm_ruby_make_install="" 
}
__rvm_select_interpreter_current () {
	ruby_binary="$(builtin command -v ruby)" 
	if (( $? == 0)) && __rvm_string_match "$ruby_binary" "*rvm*"
	then
		rvm_ruby_string="$(dirname "$ruby_binary" | __rvm_xargs dirname | __rvm_xargs basename)" 
	else
		rvm_ruby_interpreter="system" 
	fi
}
__rvm_select_interpreter_default () {
	true
}
__rvm_select_interpreter_ext () {
	if [[ -z "${rvm_ruby_name:-${detected_rvm_ruby_name:-}}" ]]
	then
		rvm_error "External ruby name was not specified!"
		return 1
	fi
}
__rvm_select_interpreter_ironruby () {
	rvm_ruby_patch_level="" 
	if (( ${rvm_head_flag:=0} == 1 ))
	then
		rvm_ruby_version="head" 
		rvm_ruby_package_name="${rvm_ruby_string}" 
		rvm_ruby_repo_url="${rvm_ruby_repo_url:-$(__rvm_db "ironruby_repo_url")}" 
		rvm_ruby_url="${rvm_ruby_repo_url:-$(__rvm_db "ironruby_repo_url")}" 
		rvm_disable_binary_flag=1 
	else
		rvm_archive_extension="zip" 
		rvm_ruby_version=${rvm_ruby_version:-"$(__rvm_db "ironruby_version")"} 
		rvm_ruby_package_name="${rvm_ruby_interpreter}-${rvm_ruby_version}" 
		rvm_ruby_package_file="${rvm_ruby_interpreter}-${rvm_ruby_version}.${rvm_archive_extension}" 
		rvm_ruby_url="$(__rvm_db "ironruby_${rvm_ruby_version}_url")" 
	fi
	export rvm_ruby_version rvm_ruby_string rvm_ruby_package_name rvm_ruby_repo_url rvm_ruby_url rvm_archive_extension
	true
}
__rvm_select_interpreter_jruby () {
	rvm_ruby_patch_level="" 
	rvm_ruby_repo_url="${rvm_ruby_repo_url:-$(__rvm_db "jruby_repo_url")}" 
	rvm_ruby_url="${rvm_ruby_repo_url:-$(__rvm_db "jruby_repo_url")}" 
	if (( ${rvm_head_flag:=0} == 1 ))
	then
		(( ${rvm_remote_flag:-0} == 1 )) || rvm_disable_binary_flag=1 
		rvm_ruby_version="head" 
	else
		if (( ${rvm_18_flag:-0} || ${rvm_19_flag:-0} || ${rvm_20_flag:-0} || ${#rvm_patch_names[@]} ))
		then
			rvm_disable_binary_flag=1 
		fi
		rvm_ruby_version="${rvm_ruby_version:-"$(__rvm_db "jruby_version")"}" 
		rvm_ruby_tag="${rvm_ruby_tag:-${rvm_ruby_version}}" 
	fi
	alias jruby_ng="jruby --ng"
	alias jruby_ng_server="jruby --ng-server"
	true
}
__rvm_select_interpreter_macruby () {
	if [[ "Darwin" == "${_system_type}" ]]
	then
		rvm_ruby_package_name="${rvm_ruby_interpreter}-${rvm_ruby_version}" 
		if (( ${rvm_head_flag:=0} == 1 ))
		then
			rvm_ruby_version="" 
			rvm_ruby_tag="" 
			rvm_ruby_revision="head" 
			__rvm_db "macruby_repo_url" "rvm_ruby_repo_url"
			rvm_ruby_url="$rvm_ruby_repo_url" 
			rvm_disable_binary_flag=1 
		elif [[ "${rvm_ruby_version:-}" == *"nightly"* ]]
		then
			__rvm_select_macruby_nightly
		elif [[ -n "${rvm_ruby_version:-}" ]]
		then
			__rvm_db "macruby_${rvm_ruby_version}_url" "rvm_ruby_url"
			[[ -n "${rvm_ruby_url:-}" ]] || __rvm_db "macruby_url" "rvm_ruby_url"
			rvm_ruby_package_name="MacRuby%20${rvm_ruby_version}.zip" 
			rvm_ruby_package_file="$rvm_ruby_package_name" 
			rvm_ruby_url="$rvm_ruby_url/$rvm_ruby_package_name" 
		else
			__rvm_db "macruby_version" "rvm_ruby_version"
			__rvm_db "macruby_url" "rvm_ruby_url"
			rvm_ruby_package_name="MacRuby%20${rvm_ruby_version}.zip" 
			rvm_ruby_package_file="$rvm_ruby_package_name" 
			rvm_ruby_url="$rvm_ruby_url/$rvm_ruby_package_name" 
		fi
		rvm_ruby_patch_level="" 
	else
		rvm_error "MacRuby can only be installed on a Darwin OS."
	fi
	true
}
__rvm_select_interpreter_maglev () {
	rvm_ruby_patch_level="" 
	maglev_url="$(__rvm_db "maglev_url")" 
	system="${_system_type}" 
	if [[ "$MACHTYPE" == x86_64-apple-darwin* ]]
	then
		arch="i386" 
	else
		arch="${_system_arch}" 
	fi
	if (( ${rvm_head_flag:=0} == 1 )) || [[ "$rvm_ruby_version" == "head" ]]
	then
		rvm_head_flag=1 
		rvm_ruby_version="head" 
		rvm_ruby_repo_url="${rvm_ruby_repo_url:-$(__rvm_db "maglev_repo_url")}" 
		rvm_ruby_url="${rvm_ruby_repo_url:-$(__rvm_db "maglev_repo_url")}" 
		rvm_gemstone_version=$(
      __rvm_curl -s https://raw.githubusercontent.com/MagLev/maglev/master/version.txt |
        __rvm_grep "^GEMSTONE" | cut -f2 -d-
    ) 
		rvm_gemstone_package_file="GemStone-${rvm_gemstone_version}.${system}-${arch}" 
		rvm_disable_binary_flag=1 
	else
		rvm_ruby_package_file="MagLev-${rvm_ruby_version}" 
		rvm_ruby_version="${rvm_ruby_version:-"$(__rvm_db "maglev_version")"}" 
		rvm_ruby_package_name="${rvm_ruby_interpreter}-${rvm_ruby_version}" 
		rvm_ruby_url="${rvm_ruby_url:-"$maglev_url/${rvm_ruby_package_file}.${rvm_archive_extension}"}" 
		rvm_gemstone_version=$(
      __rvm_curl -s https://raw.githubusercontent.com/MagLev/maglev/MagLev-${rvm_ruby_version}/version.txt |
        __rvm_grep "^GEMSTONE" | cut -f2 -d-
    ) 
		rvm_gemstone_package_file="GemStone-${rvm_gemstone_version}.${system}-${arch}" 
	fi
	export MAGLEV_HOME="$rvm_ruby_home" 
	export GEMSTONE_GLOBAL_DIR=$MAGLEV_HOME 
	rvm_gemstone_url="$maglev_url/${rvm_gemstone_package_file}.${rvm_archive_extension}" 
	true
}
__rvm_select_interpreter_missing () {
	return 2
}
__rvm_select_interpreter_mruby () {
	rvm_ruby_interpreter="mruby" 
	rvm_ruby_patch_level="" 
	rvm_ruby_repo_url="${rvm_ruby_repo_url:-$(__rvm_db "mruby_repo_url")}" 
	rvm_ruby_url=$rvm_ruby_repo_url 
	rvm_ruby_configure="" 
	rvm_ruby_make="" 
	rvm_ruby_make_install="" 
	export rvm_skip_autoreconf_flag=1 
	if [[ -z "${rvm_ruby_version:-}" ]]
	then
		rvm_head_flag=1 
	else
		rvm_head_flag=0 
		rvm_archive_extension="tar.gz" 
		rvm_ruby_package_file="${rvm_ruby_version}" 
	fi
}
__rvm_select_interpreter_opal () {
	__rvm_select_interpreter_common "opal"
}
__rvm_select_interpreter_rbx () {
	__rvm_select_rbx_nightly || return $?
	rvm_ruby_interpreter="rbx" 
	__rvm_select_rbx_compatibility_branch
	if (( ${rvm_head_flag:=1} == 0 )) && [[ -z "${rvm_ruby_repo_branch:-}" ]] && [[ "${rvm_ruby_version}" != "head" ]]
	then
		if __rvm_version_compare "${rvm_ruby_version}" -ge "2.0.0"
		then
			rbx_url="$( __rvm_db "rbx_url_2.0_and_newer" )" 
			rvm_archive_extension="tar.bz2" 
			rvm_ruby_package_file="rubinius-${rvm_ruby_version}" 
			rvm_ruby_url="${rbx_url}/${rvm_ruby_package_file}.${rvm_archive_extension}" 
		else
			rbx_url=${rbx_url:-$(__rvm_db "rbx_url")} 
			rvm_archive_extension="tar.gz" 
			rvm_ruby_package_file="rubinius-${rvm_ruby_version}" 
			rvm_ruby_url="${rbx_url}/$rvm_ruby_package_file.${rvm_archive_extension}" 
		fi
	else
		rvm_ruby_repo_url=${rvm_rbx_repo_url:-$(__rvm_db "rbx_repo_url")} 
		rvm_head_flag=1 
		rvm_ruby_patch_level="" 
		rvm_ruby_tag="${rvm_ruby_version:+v}${rvm_ruby_version:-}" 
		rvm_ruby_version="head" 
		rvm_disable_binary_flag=1 
	fi
	if [[ -n "${rvm_rbx_opt:-}" ]]
	then
		export RBXOPT="${RBXOPT:=${rvm_rbx_opt}}" 
	fi
	true
}
__rvm_select_interpreter_ree () {
	rvm_ruby_interpreter=ree 
	rvm_ruby_version=${rvm_ruby_version:-"$(__rvm_db "ree_version")"} 
	case "$rvm_ruby_version" in
		(1.8.*) true ;;
		(*) rvm_error "Unknown Ruby Enterprise Edition version: $rvm_ruby_version" ;;
	esac
	if [[ -n "${rvm_ruby_patch_level:-0}" ]]
	then
		rvm_ruby_patch_level="${rvm_ruby_patch_level#p}" 
	fi
	rvm_ruby_package_file="ruby-enterprise-$rvm_ruby_version-$rvm_ruby_patch_level" 
	rvm_ruby_url="$(__rvm_db "${rvm_ruby_interpreter}_${rvm_ruby_version}_${rvm_ruby_patch_level}_url")" 
	rvm_ruby_url="${rvm_ruby_url:-$(__rvm_db "${rvm_ruby_interpreter}_${rvm_ruby_version}_url")}" 
	rvm_ruby_url="${rvm_ruby_url}/$rvm_ruby_package_file.tar.gz" 
	true
}
__rvm_select_interpreter_rubinius () {
	__rvm_select_interpreter_rbx || return $?
}
__rvm_select_interpreter_ruby () {
	if [[ "${rvm_ruby_patch_level:-}" == "p0" ]] && __rvm_version_compare "${rvm_ruby_version}" -ge 2.1.0 && [[ ! -d "$rvm_rubies_path/$rvm_ruby_string" ]]
	then
		rvm_ruby_patch_level="" 
		rvm_ruby_string="${rvm_ruby_string%-p0}" 
	fi
	rvm_ruby_package_name="${rvm_ruby_interpreter}-${rvm_ruby_version}${rvm_ruby_patch_level:+-}${rvm_ruby_patch_level:-}" 
	rvm_ruby_package_file="${rvm_ruby_package_name}" 
	if [[ -z "${rvm_ruby_version:-""}" ]] && (( ${rvm_head_flag:=0} == 0 ))
	then
		rvm_error "Ruby version was not specified!"
	else
		rvm_ruby_repo_url="${rvm_ruby_repo_url:-"$(__rvm_db "ruby_repo_url")"}" 
		if (( ${rvm_head_flag:=0} == 0 ))
		then
			if __rvm_version_compare "${rvm_ruby_version}" -ge "3.0.0"
			then
				rvm_archive_extension="tar.gz" 
			elif __rvm_version_compare "${rvm_ruby_version}" -lt "1.8.5"
			then
				rvm_archive_extension="tar.gz" 
			else
				rvm_archive_extension="tar.bz2" 
			fi
		else
			rvm_disable_binary_flag=1 
		fi
	fi
	true
}
__rvm_select_interpreter_system () {
	true
}
__rvm_select_interpreter_topaz () {
	__rvm_select_interpreter_common "topaz"
}
__rvm_select_interpreter_truffleruby () {
	__rvm_truffleruby_set_version
	__rvm_truffleruby_set_rvm_ruby_url
	true
}
__rvm_select_interpreter_user () {
	true
}
__rvm_select_interpreter_variables () {
	rvm_archive_extension="tar.gz" 
	if [[ -z "${rvm_ruby_interpreter:-}" ]]
	then
		rvm_ruby_interpreter="${rvm_ruby_string//-*/}" 
	fi
	rvm_ruby_interpreter="${rvm_ruby_interpreter:-missing}" 
	if is_a_function __rvm_select_interpreter_${rvm_ruby_interpreter}
	then
		__rvm_select_interpreter_${rvm_ruby_interpreter} || return $?
	elif [[ -n "${MY_RUBY_HOME:-""}" ]]
	then
		__rvm_select "${MY_RUBY_HOME##*/}" || return $?
	elif [[ -z "${rvm_ruby_string:-""}" ]]
	then
		rvm_error "Ruby implementation '$rvm_ruby_interpreter' is not known."
		return 1
	fi
}
__rvm_select_late () {
	if is_a_function __rvm_select_late_${rvm_ruby_interpreter}
	then
		__rvm_select_late_${rvm_ruby_interpreter}
	fi
}
__rvm_select_late_rbx () {
	if {
			[[ -n "${rvm_ruby_package_file:-}" && -f "${rvm_archives_path}/${rvm_ruby_package_file}" && -s "${rvm_archives_path}/${rvm_ruby_package_file}" ]]
		} || {
			[[ -n "${rvm_ruby_url:-}" ]] && file_exists_at_url "${rvm_ruby_url}"
		} || {
			[[ -n "${rbx_url:-}" && -n "${rvm_ruby_version:-}" ]] && __rvm_select_late_rbx_partial "${rbx_url}" "${rvm_ruby_version}"
		}
	then
		rvm_head_flag=0 
	else
		rvm_head_flag=1 
		if [[ "${rvm_ruby_version}" == 'head' ]]
		then
			true ${rvm_ruby_repo_branch:="master"}
		else
			true ${rvm_ruby_repo_branch:="master"} ${rvm_ruby_tag:="${rvm_ruby_version}"}
		fi
	fi
}
__rvm_select_late_rbx_partial () {
	\typeset __found __ext __patern
	__ext=".${rvm_archive_extension}" 
	__patern="${2//\./\.}.*\.${rvm_archive_extension//\./\.}\$" 
	__found="$(
    __rvm_curl -s $1/index.txt "rubinius-" |
    __rvm_awk -F"${__ext}" "/${__patern}/"'{print $1}' |
    __rvm_version_sort |
    __rvm_tail -n 1
  )" 
	if [[ -n "${__found}" ]]
	then
		rvm_ruby_version="${__found#rubinius-}" 
		rvm_ruby_string="rbx-${rvm_ruby_version}" 
		rvm_ruby_package_file="${__found}" 
		rvm_ruby_url="$1/${__found}.${rvm_archive_extension}" 
		return 0
	else
		return 1
	fi
}
__rvm_select_macruby_nightly () {
	__rvm_db "macruby_nightly_url" "rvm_ruby_url"
	case "${rvm_ruby_version:-}" in
		(nightly_*) __rvm_select_macruby_nightly_selected ;;
		(*) __rvm_select_macruby_nightly_detect ;;
	esac
	rvm_ruby_url+="/${rvm_ruby_package_file}" 
	rvm_verify_downloads_flag=1 
	rvm_debug "selected macruby $rvm_ruby_string => $rvm_ruby_url"
	true
}
__rvm_select_macruby_nightly_detect () {
	\typeset __string_version
	rvm_ruby_version="$(
    __rvm_curl -s "$rvm_ruby_url" |
    __rvm_grep -oE "<a href=\"macruby_nightly-[^<]+\.pkg</a>" |
    __rvm_awk -F"[<>]" '{print $3}' |
    __rvm_version_sort |
    __rvm_tail -n 1
  )" 
	[[ -n "${rvm_ruby_version}" ]] || {
		rvm_error "Could not find MacRuby nightly binary."
		return 1
	}
	rvm_ruby_package_file="${rvm_ruby_version}" 
	rvm_ruby_package_name="${rvm_ruby_package_file%.pkg}" 
	__string_version="${rvm_ruby_package_name#macruby_nightly-}" 
	__string_version="${__string_version//-/.}" 
	rvm_ruby_version="nightly_${__string_version}" 
	rvm_ruby_string="macruby-${rvm_ruby_version}${rvm_ruby_name:+-}${rvm_ruby_name:-}" 
	true
}
__rvm_select_macruby_nightly_selected () {
	\typeset __string_version
	__string_version="${rvm_ruby_version//./-}" 
	__string_version="${__string_version#nightly_}" 
	rvm_ruby_package_name="${rvm_ruby_interpreter}_nightly-${__string_version}" 
	rvm_ruby_package_file="$rvm_ruby_package_name.pkg" 
}
__rvm_select_rbx_compatibility_branch () {
	case "${rvm_ruby_version}" in
		(2.0pre) rvm_ruby_repo_branch="master"  ;;
		(2.0.testing) rvm_ruby_repo_branch="${rvm_ruby_version}"  ;;
	esac
	if [[ ${rvm_19_flag:-0} == 1 ]]
	then
		rvm_ruby_repo_branch="1.9.3" 
		rvm_head_flag=1 
	elif [[ ${rvm_18_flag:-0} == 1 ]]
	then
		rvm_ruby_repo_branch="1.8.7" 
		rvm_head_flag=1 
	fi
	true
}
__rvm_select_rbx_nightly () {
	(( ${rvm_nightly_flag:=0} == 1 )) || return 0
	\typeset org_rvm_ruby_patch_level _rvm_ruby_name
	if [[ "$rvm_ruby_version" == head ]]
	then
		rvm_ruby_version="" 
	fi
	rvm_debug "searching for binary rbx ${rvm_ruby_version:-}${rvm_ruby_version:+-}${rvm_ruby_patch_level}*${rvm_ruby_name:+-}${rvm_ruby_name:-}"
	org_rvm_ruby_patch_level="$rvm_ruby_patch_level" 
	_rvm_ruby_name="${rvm_ruby_name:-${detected_rvm_ruby_name:-}}" 
	rvm_ruby_patch_level="$(
    __list_remote_all |
      __rvm_grep ${rvm_ruby_version:-}${rvm_ruby_version:+-}${org_rvm_ruby_patch_level}.*${_rvm_ruby_name:+-}${_rvm_ruby_name:-} |
      __rvm_tail -n 1
  )" 
	[[ -n "${rvm_ruby_patch_level:-}" ]] || {
		rvm_error "Could not find rbx binary '${rvm_ruby_version:-}${rvm_ruby_version:+-}${org_rvm_ruby_patch_level}*${rvm_ruby_name:+-}${rvm_ruby_name:-}' binary release."
		return 1
	}
	rvm_ruby_patch_level="${rvm_ruby_patch_level##*/}" 
	rvm_ruby_patch_level="${rvm_ruby_patch_level%.tar.*}" 
	if [[ -z "${rvm_ruby_version:-}" ]]
	then
		rvm_ruby_patch_level="${rvm_ruby_patch_level#rubinius-}" 
		rvm_ruby_version="${rvm_ruby_patch_level%%-*}" 
	fi
	if [[ -z "${rvm_ruby_name:-}" ]]
	then
		rvm_ruby_name="${rvm_ruby_patch_level##*-}" 
	fi
	rvm_ruby_patch_level="${rvm_ruby_patch_level##*${org_rvm_ruby_patch_level}}" 
	rvm_ruby_patch_level="${rvm_ruby_patch_level%%-*}" 
	rvm_ruby_patch_level="${org_rvm_ruby_patch_level}${rvm_ruby_patch_level}" 
	rvm_ruby_string="rubinius-${rvm_ruby_version}-${rvm_ruby_patch_level}-${rvm_ruby_name}" 
	rvm_debug "detected rbx ${rvm_ruby_string}"
	rvm_verify_downloads_flag=1 
	true
}
__rvm_select_set_variable_defaults () {
	export GEM_HOME GEM_PATH MY_RUBY_HOME RUBY_VERSION IRBRC
	export rvm_env_string rvm_action rvm_alias_expanded rvm_archive_extension rvm_bin_flag rvm_bin_path rvm_debug_flag rvm_default_flag rvm_delete_flag rvm_docs_type rvm_dump_environment_flag rvm_error_message rvm_expanding_aliases rvm_file_name rvm_gemdir_flag rvm_gemset_name rvm_gemstone_package_file rvm_gemstone_url rvm_head_flag rvm_hook rvm_install_on_use_flag rvm_llvm_flag rvm_loaded_flag rvm_niceness rvm_nightly_flag rvm_only_path_flag rvm_parse_break rvm_patch_original_pwd rvm_pretty_print_flag rvm_proxy rvm_quiet_flag rvm_reload_flag rvm_remove_flag rvm_ruby_alias rvm_ruby_args rvm_ruby_binary rvm_ruby_bits rvm_ruby_configure rvm_ruby_file rvm_ruby_gem_home rvm_ruby_gem_path rvm_ruby_global_gems_path rvm_ruby_home rvm_ruby_interpreter rvm_ruby_irbrc rvm_ruby_major_version rvm_ruby_make rvm_ruby_make_install rvm_ruby_minor_version rvm_ruby_mode rvm_ruby_name rvm_ruby_package_file rvm_ruby_package_name rvm_ruby_patch rvm_ruby_patch_level rvm_ruby_release_version rvm_ruby_repo_url rvm_ruby_revision rvm_ruby_selected_flag rvm_ruby_sha rvm_ruby_string rvm_ruby_strings rvm_ruby_tag rvm_ruby_url rvm_ruby_user_tag rvm_ruby_version rvm_script_name rvm_sdk rvm_silent_flag rvm_sticky_flag rvm_system_flag rvm_token rvm_trace_flag rvm_use_flag rvm_user_flag rvm_verbose_flag rvm_ruby_repo_tag
}
__rvm_select_version_variables () {
	case "$rvm_ruby_version" in
		(+([0-9]).+([0-9]).+([0-9])) rvm_ruby_release_version="${rvm_ruby_version/.*/}" 
			rvm_ruby_major_version=${rvm_ruby_version%.*} 
			rvm_ruby_major_version=${rvm_ruby_major_version#*.} 
			rvm_ruby_minor_version="${rvm_ruby_version//*.}"  ;;
		(+([0-9]).+([0-9])) rvm_ruby_release_version="${rvm_ruby_version/.*/}" 
			rvm_ruby_major_version="${rvm_ruby_version#*.}" 
			rvm_ruby_minor_version=""  ;;
	esac
}
__rvm_set_color () {
	\typeset __buffer __variable
	__buffer=$'\E[' 
	__variable="$1" 
	shift
	while (( $# ))
	do
		__rvm_set_color_single "$1"
		shift
		if (( $# ))
		then
			__buffer+=';' 
		fi
	done
	__buffer+='m' 
	if [[ "${__variable}" == "" || "${__variable}" == "print" ]]
	then
		printf "${__buffer}"
	else
		eval "${__variable}='${__buffer}'"
	fi
}
__rvm_set_color_single () {
	case "$1" in
		(bold) __buffer+='7'  ;;
		(offbold) __buffer+='27'  ;;
		(black) __buffer+='30'  ;;
		(red) __buffer+='31'  ;;
		(green) __buffer+='32'  ;;
		(yellow) __buffer+='33'  ;;
		(blue) __buffer+='34'  ;;
		(magenta) __buffer+='35'  ;;
		(cyan) __buffer+='36'  ;;
		(white) __buffer+='37'  ;;
		(default) __buffer+='39'  ;;
		(iblack) __buffer+='30;1'  ;;
		(ired) __buffer+='31;1'  ;;
		(igreen) __buffer+='32;1'  ;;
		(iyellow) __buffer+='33;1'  ;;
		(iblue) __buffer+='34;1'  ;;
		(imagenta) __buffer+='35;1'  ;;
		(icyan) __buffer+='36;1'  ;;
		(iwhite) __buffer+='37;1'  ;;
		(bblack) __buffer+='40'  ;;
		(bred) __buffer+='41'  ;;
		(bgreen) __buffer+='42'  ;;
		(byellow) __buffer+='43'  ;;
		(bblue) __buffer+='44'  ;;
		(bmagenta) __buffer+='45'  ;;
		(bcyan) __buffer+='46'  ;;
		(bwhite) __buffer+='47'  ;;
		(bdefault) __buffer+='49'  ;;
		(*) __buffer+='0'  ;;
	esac
}
__rvm_set_colors () {
	case "${TERM:-dumb}" in
		(dumb|unknown) rvm_error_clr="" 
			rvm_warn_clr="" 
			rvm_debug_clr="" 
			rvm_notify_clr="" 
			rvm_code_clr="" 
			rvm_comment_clr="" 
			rvm_reset_clr=""  ;;
		(*) __rvm_set_color rvm_error_clr "${rvm_error_color:-red}"
			__rvm_set_color rvm_warn_clr "${rvm_warn_color:-yellow}"
			__rvm_set_color rvm_debug_clr "${rvm_debug_color:-magenta}"
			__rvm_set_color rvm_notify_clr "${rvm_notify_color:-green}"
			__rvm_set_color rvm_code_clr "${rvm_code_color:-blue}"
			__rvm_set_color rvm_comment_clr "${rvm_comment_color:-iblack}"
			__rvm_set_color rvm_reset_clr "${rvm_reset_color:-reset}" ;;
	esac
}
__rvm_set_env () {
	\typeset __save_to __set __key __value
	__save_to="$1" 
	shift
	for __set in "$@"
	do
		__key="${__set%%=*}" 
		__value="${__set#*=}" 
		case "$__value" in
			(\"*\") __value="${__value#\"}" 
				__value="${__value%\"}"  ;;
			(\'*\') __value="${__value#\'}" 
				__value="${__value%\'}"  ;;
		esac
		rvm_debug "key=$__key; value=$__value;"
		if [[ -n "${__save_to}" ]]
		then
			eval "${__save_to}+=( \"\${__key}=\${${__key}}\" )"
		fi
		if [[ -n "${__value}" ]]
		then
			eval "export \${__key}=\"\${__value}\""
		else
			eval "unset \${__key}"
		fi
	done
}
__rvm_set_executable () {
	for __file
	do
		[[ -x "${__file}" ]] || chmod +x "${__file}"
	done
}
__rvm_set_ruby_version () {
	if [[ -s .ruby-version ]]
	then
		\command \mv .ruby-version .ruby-version.$(__rvm_date +%m.%d.%Y-%H:%M:%S)
		rvm_warn ".ruby-version is not empty, moving aside to preserve."
	fi
	\typeset __version="$(__rvm_env_string)"
	case "${__version}" in
		(*@*) if [[ -s .ruby-gemset ]]
			then
				\command \mv .ruby-gemset .ruby-gemset.$(__rvm_date +%m.%d.%Y-%H:%M:%S)
				rvm_warn ".ruby-gemset is not empty, moving aside to preserve."
			fi
			echo "${__version##*@}" > .ruby-gemset ;;
		(*) if [[ -s .ruby-gemset ]]
			then
				\command \mv .ruby-gemset .ruby-gemset.$(__rvm_date +%m.%d.%Y-%H:%M:%S)
				rvm_warn ".ruby-gemset not needed, moving aside to preserve."
			fi ;;
	esac
	echo "${__version%@*}" > .ruby-version
}
__rvm_set_rvmrc () {
	\typeset flags identifier short_identifier gem_file
	true ${rvm_verbose_flag:=0}
	if [[ "$HOME" != "$PWD" && "${rvm_prefix:-}" != "$PWD" ]]
	then
		if (( rvm_verbose_flag ))
		then
			flags="use " 
		fi
		if [[ -s .rvmrc ]]
		then
			\command \mv .rvmrc .rvmrc.$(__rvm_date +%m.%d.%Y-%H:%M:%S)
			rvm_warn ".rvmrc is not empty, moving aside to preserve."
		fi
		identifier=$(__rvm_env_string) 
		short_identifier="${identifier#ruby-}" 
		short_identifier="${short_identifier%%-*}" 
		printf "%b" "#!/usr/bin/env bash

# This is an RVM Project .rvmrc file, used to automatically load the ruby
# development environment upon cd'ing into the directory

# First we specify our desired <ruby>[@<gemset>], the @gemset name is optional,
# Only full ruby name is supported here, for short names use:
#     echo \"rvm use ${short_identifier}\" > .rvmrc
environment_id=\"$identifier\"

# Uncomment the following lines if you want to verify rvm version per project
# rvmrc_rvm_version=\"${rvm_version}\" # 1.10.1 seems like a safe start
# eval \"\$(echo \${rvm_version}.\${rvmrc_rvm_version} | awk -F. '{print \"[[ \"\$1*65536+\$2*256+\$3\" -ge \"\$4*65536+\$5*256+\$6\" ]]\"}' )\" || {
#   echo \"This .rvmrc file requires at least RVM \${rvmrc_rvm_version}, aborting loading.\"
#   exit 1
# }
" >> .rvmrc
		if __rvm_string_match "$identifier" "jruby*"
		then
			printf "%b" "
# Uncomment following line if you want options to be set only for given project.
# PROJECT_JRUBY_OPTS=( --1.9 )
# The variable PROJECT_JRUBY_OPTS requires the following to be run in shell:
#    chmod +x \${rvm_path}/hooks/after_use_jruby_opts
" >> .rvmrc
		fi
		printf "%b" "
# First we attempt to load the desired environment directly from the environment
# file. This is very fast and efficient compared to running through the entire
# CLI and selector. If you want feedback on which environment was used then
# insert the word 'use' after --create as this triggers verbose mode.
if [[ -d \"\${rvm_path:-\$HOME/.rvm}/environments\"
  && -s \"\${rvm_path:-\$HOME/.rvm}/environments/\$environment_id\" ]]
then
  \\. \"\${rvm_path:-\$HOME/.rvm}/environments/\$environment_id\"
  for __hook in \"\${rvm_path:-\$HOME/.rvm}/hooks/after_use\"*
  do
    if [[ -f \"\${__hook}\" && -x \"\${__hook}\" && -s \"\${__hook}\" ]]
    then \\. \"\${__hook}\" || true
    fi
  done
  unset __hook
" >> .rvmrc
		if [[ " $flags " == *" use "* ]]
		then
			printf "%b" "  if (( \${rvm_use_flag:=1} >= 1 )) # display automatically" >> .rvmrc
		else
			printf "%b" "  if (( \${rvm_use_flag:=1} >= 2 )) # display only when forced" >> .rvmrc
		fi
		printf "%b" "
  then
    if [[ \$- == *i* ]] # check for interactive shells
    then printf \"%b\" \"Using: \$(tput setaf 2 2>/dev/null)\$GEM_HOME\$(tput sgr0 2>/dev/null)\\\\n\" # show the user the ruby and gemset they are using in green
    else printf \"%b\" \"Using: \$GEM_HOME\\\\n\" # don't use colors in non-interactive shells
    fi
  fi
" >> .rvmrc
		printf "%b" "else
  # If the environment file has not yet been created, use the RVM CLI to select.
  rvm --create $flags \"\$environment_id\" || {
    echo \"Failed to create RVM environment '\${environment_id}'.\"
    return 1
  }
fi
" >> .rvmrc
		for gem_file in *.gems
		do
			case "$gem_file" in
				(\*.gems) continue ;;
			esac
			printf "%b" "
# If you use an RVM gemset file to install a list of gems (*.gems), you can have
# it be automatically loaded. Uncomment the following and adjust the filename if
# necessary.
#
# filename=\".gems\"
# if [[ -s \"\$filename\" ]]
# then
#   rvm gemset import \"\$filename\" | GREP_OPTIONS=\"\" \\\\command \\grep -v already | GREP_OPTIONS=\"\" \command \grep -v listed | GREP_OPTIONS=\"\" \command \grep -v complete | \command \sed '/^$/d'
# fi
" >> .rvmrc
		done
		if [[ -s Gemfile ]]
		then
			printf "%b" "
# If you use bundler, this might be useful to you:
# if [[ -s Gemfile ]] && {
#   ! builtin command -v bundle >/dev/null ||
#   builtin command -v bundle | GREP_OPTIONS=\"\" \\\\command \\grep \$rvm_path/bin/bundle >/dev/null
# }
# then
#   printf \"%b\" \"The rubygem 'bundler' is not installed. Installing it now.\\\\n\"
#   gem install bundler
# fi
# if [[ -s Gemfile ]] && builtin command -v bundle >/dev/null
# then
#   bundle install | GREP_OPTIONS=\"\" \\\\command \\grep -vE '^Using|Your bundle is complete'
# fi
" >> .rvmrc
		fi
	else
		rvm_error ".rvmrc cannot be set in your home directory.      \nThe home .rvmrc is for global rvm settings only."
	fi
}
__rvm_set_versions_conf () {
	\typeset gemset identifier
	if [[ -s .versions.conf ]]
	then
		\command \mv .versions.conf .versions.conf.$(__rvm_date +%m.%d.%Y-%H:%M:%S)
		rvm_warn ".version.conf is not empty, moving aside to preserve."
	fi
	identifier=$(__rvm_env_string) 
	gemset=${identifier#*@} 
	identifier=${identifier%@*} 
	printf "%b" "ruby=$identifier
" >> .versions.conf
	if [[ -n "$gemset" && "$gemset" != "$identifier" ]]
	then
		printf "%b" "ruby-gemset=$gemset
" >> .versions.conf
	else
		printf "%b" "#ruby-gemset=my-projectit
" >> .versions.conf
	fi
	printf "%b" "#ruby-gem-install=bundler rake
#ruby-bundle-install=true
" >> .versions.conf
}
__rvm_setup () {
	__variables_definition export
	if (( __rvm_env_loaded != 1 ))
	then
		return 0
	fi
	if [[ -n "${BASH_VERSION:-}" ]] && ! __function_on_stack cd pushd popd
	then
		export rvm_shell_nounset
		if __rvm_has_opt "nounset"
		then
			rvm_bash_nounset=1 
		else
			rvm_bash_nounset=0 
		fi
		set +o nounset
		_rvm_old_traps=$( trap | __rvm_grep -E 'EXIT|HUP|INT|QUIT|TERM' || true ) 
		trap '__rvm_teardown_final ; set +x' EXIT HUP INT QUIT TERM
	fi
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		export rvm_zsh_clobber rvm_zsh_nomatch
		if setopt | __rvm_grep -s '^noclobber$' > /dev/null 2>&1
		then
			rvm_zsh_clobber=0 
		else
			rvm_zsh_clobber=1 
		fi
		setopt clobber
		if setopt | __rvm_grep -s '^nonomatch$' > /dev/null 2>&1
		then
			rvm_zsh_nomatch=0 
		else
			rvm_zsh_nomatch=1 
		fi
		setopt no_nomatch
	fi
}
__rvm_setup_statf_function () {
	if [[ "${_system_type}" == Darwin || "${_system_type}" == BSD ]]
	then
		__rvm_statf () {
			__rvm_stat -f "$2" "$3"
		}
	else
		__rvm_statf () {
			__rvm_stat -c "$1" "$3"
		}
	fi
}
__rvm_setup_sudo_function () {
	if is_a_function __rvm_setup_sudo_function_${_system_name}
	then
		__rvm_setup_sudo_function_${_system_name} "$@" || return $?
	else
		__rvm_setup_sudo_function_Other "$@" || return $?
	fi
}
__rvm_setup_sudo_function_Other () {
	if __rvm_which sudo > /dev/null 2>&1
	then
		__rvm_sudo () {
			\command \sudo "$@"
		}
	else
		rvm_debug "Warning: No 'sudo' found."
	fi
}
__rvm_setup_sudo_function_PCLinuxOS () {
	__rvm_sudo () {
		if [[ "$1" == "-p" ]]
		then
			rvm_printf_to_stderr "${2//%p/[root]/}"
			shift 2
		fi
		su -c "$*"
	}
}
__rvm_setup_sudo_function_Solaris () {
	if [[ -x /opt/csw/bin/sudo ]]
	then
		__rvm_sudo () {
			/opt/csw/bin/sudo "$@"
		}
	elif [[ -x /usr/bin/sudo ]]
	then
		__rvm_sudo () {
			/usr/bin/sudo "$@"
		}
	else
		rvm_debug "Warning: No '/opt/csw/bin/sudo' found."
	fi
}
__rvm_setup_utils_functions () {
	\typeset gnu_tools_path gnu_prefix gnu_util
	\typeset -a gnu_utils gnu_missing
	gnu_utils=(awk cp date find sed tail tar xargs) 
	gnu_missing=() 
	if is_a_function __rvm_setup_utils_functions_${_system_name}
	then
		__rvm_setup_utils_functions_${_system_name} "$@" || return $?
	else
		__rvm_setup_utils_functions_Other "$@" || return $?
	fi
}
__rvm_setup_utils_functions_OSX () {
	if [[ -x /usr/bin/stat ]]
	then
		__rvm_stat () {
			/usr/bin/stat "$@" || return $?
		}
	else
		rvm_error "ERROR: Missing (executable) /usr/bin/stat. Falling back to '\\\\command \\\\stat' which might be something else."
		__rvm_stat () {
			\command \stat "$@" || return $?
		}
	fi
	__rvm_setup_utils_functions_common
}
__rvm_setup_utils_functions_Other () {
	__rvm_stat () {
		\command \stat "$@" || return $?
	}
	__rvm_setup_utils_functions_common
}
__rvm_setup_utils_functions_Solaris () {
	case "${_system_version}" in
		(10) gnu_tools_path=/opt/csw/bin 
			gnu_prefix="g"  ;;
		(11) gnu_tools_path=/usr/gnu/bin 
			gnu_prefix=""  ;;
	esac
	if [[ -x $gnu_tools_path/${gnu_prefix}grep ]]
	then
		eval "__rvm_grep() { GREP_OPTIONS=\"\" $gnu_tools_path/${gnu_prefix}grep \"\$@\" || return \$?; }"
	else
		gnu_missing+=(${gnu_prefix}grep) 
	fi
	if [[ "${_system_name}" == "OpenIndiana" || "${_system_version}" == "11" ]]
	then
		__rvm_stat () {
			\command \stat "$@" || return $?
		}
	elif [[ -x $gnu_tools_path/${gnu_prefix}stat ]]
	then
		eval "__rvm_stat() { $gnu_tools_path/${gnu_prefix}stat \"\$@\" || return \$?; }"
	else
		gnu_missing+=(${gnu_prefix}stat) 
	fi
	if [[ "${_system_name}" == "SmartOS" ]]
	then
		__rvm_which () {
			\command \which "$@" || return $?
		}
	elif [[ -x $gnu_tools_path/${gnu_prefix}which ]]
	then
		eval "__rvm_which() { $gnu_tools_path/${gnu_prefix}which \"\$@\" || return \$?; }"
	else
		gnu_missing+=(${gnu_prefix}which) 
	fi
	for gnu_util in "${gnu_utils[@]}"
	do
		if [[ -x $gnu_tools_path/$gnu_prefix$gnu_util ]]
		then
			eval "__rvm_$gnu_util() { $gnu_tools_path/$gnu_prefix$gnu_util \"\$@\" || return \$?; }"
		else
			gnu_missing+=($gnu_prefix$gnu_util) 
		fi
	done
	if (( ${#gnu_missing[@]} ))
	then
		rvm_error "ERROR: Missing GNU tools: ${gnu_missing[@]}. Make sure they are installed in '$gnu_tools_path/' before using RVM!"
		if [[ "${_system_name} ${_system_version}" == "Solaris 10" ]]
		then
			rvm_error "You might want to look at OpenCSW project to install the above mentioned tools (https://www.opencsw.org/about)"
		fi
		exit 200
	fi
}
__rvm_setup_utils_functions_common () {
	__rvm_grep () {
		GREP_OPTIONS="" \command \grep "$@" || return $?
	}
	if \command \which --skip-alias --skip-functions which > /dev/null 2>&1
	then
		__rvm_which () {
			\command \which --skip-alias --skip-functions "$@" || return $?
		}
	elif \command \which whence > /dev/null 2>&1 && \command \whence whence > /dev/null 2>&1
	then
		__rvm_which () {
			\command \whence -p "$@" || return $?
		}
	elif \command \which which > /dev/null 2>&1
	then
		__rvm_which () {
			\command \which "$@" || return $?
		}
	elif \which which > /dev/null 2>&1
	then
		__rvm_which () {
			\which "$@" || return $?
		}
	else
		\typeset __result=$?
		rvm_error "ERROR: Missing proper 'which' command. Make sure it is installed before using RVM!"
		return ${__result}
	fi
	for gnu_util in "${gnu_utils[@]}"
	do
		eval "__rvm_$gnu_util() { \\$gnu_util \"\$@\" || return \$?; }"
	done
}
__rvm_sha256_for_contents () {
	if builtin command -v sha256sum > /dev/null
	then
		sha256sum | __rvm_awk '{print $1}'
	elif builtin command -v sha256 > /dev/null
	then
		sha256 | __rvm_awk '{print $1}'
	elif builtin command -v shasum > /dev/null
	then
		shasum -a256 | __rvm_awk '{print $1}'
	elif builtin command -v openssl > /dev/null
	then
		openssl sha -sha256 | __rvm_awk '{print $1}'
	else
		return 1
	fi
	true
}
__rvm_sha__calculate () {
	rvm_debug "Calculate sha512 checksum for $@"
	\typeset bits _sum
	bits=${1:-512} 
	shift
	if builtin command -v sha${bits}sum > /dev/null
	then
		_sum=$(sha${bits}sum    "$@") 
		echo ${_sum% *}
		return 0
	elif builtin command -v sha${bits} > /dev/null
	then
		_sum=$(sha${bits}       "$@") 
		if [[ "${_sum%% *}" == "SHA${bits}" ]]
		then
			echo ${_sum##* }
		else
			echo ${_sum% *}
		fi
		return 0
	elif builtin command -v shasum > /dev/null
	then
		_sum=$(shasum -a${bits} "$@") 
		echo ${_sum% *}
		return 0
	elif builtin command -v /opt/csw/bin/shasum > /dev/null
	then
		_sum=$(/opt/csw/bin/shasum -a${bits} "$@") 
		echo ${_sum% *}
		return 0
	fi
	rvm_error "Neither sha512sum nor shasum found in the PATH"
	return 1
}
__rvm_stat () {
	\command \stat "$@" || return $?
}
__rvm_statf () {
	__rvm_stat -f "$2" "$3"
}
__rvm_string_includes () {
	\typeset __search __text="$1"
	shift
	for __search in "$@"
	do
		if [[ " ${__text} " == *" ${__search} "* ]]
		then
			return 0
		fi
	done
	return 1
}
__rvm_string_match () {
	\typeset _string _search
	_string="$1" 
	shift
	while (( $# ))
	do
		_search="$1" 
		_search="${_search// /[[:space:]]}" 
		_search="${_search//\#/\#}" 
		eval "      case \"\${_string}\" in        ($_search) return 0 ;;      esac      "
		shift
	done
	return 1
}
__rvm_strings () {
	\typeset strings ruby_strings
	ruby_strings=($(echo ${rvm_ruby_args:-$rvm_ruby_string})) 
	for rvm_ruby_string in "${ruby_strings[@]}"
	do
		strings="$strings $(__rvm_select ; echo $rvm_ruby_string)" 
	done
	echo $strings
	return 0
}
__rvm_strip () {
	__rvm_sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]\{1,\}/ /g'
	return $?
}
__rvm_sudo () {
	\command \sudo "$@"
}
__rvm_switch () {
	\typeset new_rvm_path new_rvm_bin_path
	(( $# )) && [[ -z "$1" ]] && shift || true
	(( $# )) && [[ -n "$1" ]] && [[ -d "$1" || -d "${1%/*}" ]] && [[ ! -f "$1" ]] || {
		rvm_error "No valid path given."
		return 1
	}
	[[ "${rvm_path}" != "${new_rvm_path}" ]] || {
		rvm_warn "Already there!"
		return 2
	}
	rvm_log "Switching ${rvm_path} => ${1}"
	new_rvm_path="${1%/}" 
	new_rvm_bin_path="${2:-$new_rvm_path/bin}" 
	new_rvm_bin_path="${new_rvm_bin_path%/}" 
	__rvm_use_system
	__rvm_remove_from_path "${rvm_path%/}/*"
	rvm_reload_flag=1 
	rvm_path="${new_rvm_path}" 
	rvm_bin_path="${new_rvm_bin_path}" 
	rvm_scripts_path="${rvm_path}/scripts" 
	rvm_environments_path="${rvm_path}/environments" 
	__rvm_remove_from_path "${rvm_path%/}/*"
	__rvm_add_to_path prepend "${rvm_bin_path}"
}
__rvm_system_path () {
	rvm_remote_server_path="$(__rvm_db "rvm_remote_server_path${2:-}")" 
	[[ -n "${rvm_remote_server_path}" ]] || rvm_remote_server_path="${_system_name_lowercase}/${_system_version}/${_system_arch}" 
	if [[ "${1:-}" == "-" ]]
	then
		printf "%b" "${rvm_remote_server_path}\n"
	fi
}
__rvm_table () {
	if [[ -n "${1:-}" ]]
	then
		__rvm_table_br
		echo "$1" | __rvm_table_wrap_text
	fi
	__rvm_table_br
	\command \cat "${2:--}" | __rvm_table_wrap_text
	__rvm_table_br
}
__rvm_table_br () {
	\typeset width=${COLUMNS:-78}
	width=$(( width > 116 ? 116 : width )) 
	printf "%-${width}s\n" " " | __rvm_sed 's/ /*/g'
}
__rvm_table_wrap_text () {
	\typeset width=${COLUMNS:-78}
	width=$(( width > 116 ? 116 : width )) 
	width=$(( width - 4 )) 
	__rvm_fold $width | __rvm_awk -v width=$width '{printf "* %-"width"s *\n", $0}'
}
__rvm_tail () {
	\tail "$@" || return $?
}
__rvm_take_n () {
	\typeset IFS __temp_counter
	\typeset -a __temp_arr1 __temp_arr2
	IFS=$3 
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		eval "__temp_arr1=( \${=$1} )"
	else
		eval "__temp_arr1=( \$$1 )"
	fi
	__temp_counter=0 
	__temp_arr2=() 
	while (( __temp_counter < $2 ))
	do
		__temp_arr2+=("${__temp_arr1[__array_start+__temp_counter++]}") 
	done
	eval "$1=\"\${__temp_arr2[*]}\""
}
__rvm_tar () {
	\tar "$@" || return $?
}
__rvm_teardown () {
	if builtin command -v __rvm_cleanup_tmp > /dev/null 2>&1
	then
		__rvm_cleanup_tmp
	fi
	export __rvm_env_loaded
	: __rvm_env_loaded:${__rvm_env_loaded:=${rvm_tmp_path:+1}}:
	: __rvm_env_loaded:${__rvm_env_loaded:=0}:
	: __rvm_env_loaded:$(( __rvm_env_loaded-=1 )):
	if [[ -z "${rvm_tmp_path:-}" ]] || (( __rvm_env_loaded > 0 ))
	then
		return 0
	fi
	if [[ -n "${BASH_VERSION:-}" ]]
	then
		trap - EXIT HUP INT QUIT TERM
		if [[ -n "${_rvm_old_traps:-}" ]]
		then
			eval "${_rvm_old_traps}"
		fi
		(( rvm_bash_nounset == 1 )) && set -o nounset
		unset rvm_bash_nounset
	fi
	if [[ -n "${ZSH_VERSION:-""}" ]]
	then
		(( rvm_zsh_clobber == 0 )) && setopt noclobber
		(( rvm_zsh_nomatch == 0 )) || setopt nomatch
		unset rvm_zsh_clobber rvm_zsh_nomatch
	fi
	if [[ -n "${rvm_stored_umask:-}" ]]
	then
		umask ${rvm_stored_umask}
		unset rvm_stored_umask
	fi
	if builtin command -v __rvm_cleanup_download > /dev/null 2>&1
	then
		__rvm_cleanup_download
	fi
	if [[ "${rvm_stored_errexit:-""}" == "1" ]]
	then
		set -e
	fi
	__variables_definition unset
	unset _system_arch _system_name _system_type _system_version
	return 0
}
__rvm_teardown_final () {
	__rvm_env_loaded=1 
	unset __rvm_project_rvmrc_lock
	__rvm_teardown
}
__rvm_teardown_if_broken () {
	if __function_on_stack __rvm_load_project_config || __function_on_stack __rvm_with
	then
		true
	elif (( ${__rvm_env_loaded:-0} > 0 ))
	then
		__rvm_teardown_final
	fi
}
__rvm_truffleruby_set_rvm_ruby_url () {
	case "${_system_type}" in
		(Linux) platform="linux"  ;;
		(Darwin) platform="macos"  ;;
		(*) rvm_error "TruffleRuby does not support ${_system_type} currently." ;;
	esac
	case "${_system_arch}" in
		(x86_64) arch=amd64  ;;
		(*) rvm_error "TruffleRuby does not support ${_system_arch} currently." ;;
	esac
	rvm_ruby_package_name="truffleruby-${truffleruby_version}" 
	if (( ${rvm_head_flag:=0} == 1 ))
	then
		case "$platform" in
			(linux) platform="ubuntu-18.04"  ;;
			(macos) platform="macos-latest"  ;;
		esac
		rvm_ruby_package_file="${rvm_ruby_package_name}-${platform}" 
		rvm_ruby_url="${rvm_ruby_repo_url:-https://github.com/ruby/truffleruby-dev-builder/releases/latest/download/${rvm_ruby_package_file}.tar.gz}" 
	else
		rvm_ruby_package_file="${rvm_ruby_package_name}-${platform}-${arch}" 
		rvm_ruby_url="${rvm_ruby_repo_url:-$(__rvm_db "truffleruby_url")/vm-${truffleruby_version}/${rvm_ruby_package_file}.tar.gz}" 
	fi
	true
}
__rvm_truffleruby_set_version () {
	if (( ${rvm_head_flag:=0} == 1 ))
	then
		rvm_ruby_version="head" 
		truffleruby_version="head" 
	else
		rvm_ruby_version="${rvm_ruby_version:-$(__rvm_db "truffleruby_version")}" 
		truffleruby_version="${rvm_ruby_version}${rvm_ruby_patch_level:+-}${rvm_ruby_patch_level:-}" 
	fi
	true
}
__rvm_trust_rvmrc () {
	[[ -f "$1" ]] || return 1
	__rvm_reset_rvmrc_trust "$1"
	__rvm_db_ "${rvm_user_path:-${rvm_path}/user}/rvmrcs" "$(__rvm_rvmrc_key "$1")" "1;$(__rvm_checksum_for_contents "$1")" > /dev/null 2>&1 || return $?
}
__rvm_try_sudo () {
	(
		\typeset -a command_to_run
		\typeset sudo_path sbin_path missing_paths
		command_to_run=("$@") 
		(( UID == 0 )) || case "$rvm_autolibs_flag_number" in
			(0) rvm_debug "Running '$*' would require sudo."
				return 0 ;;
			(1) rvm_warn "Running '$*' would require sudo."
				return 0 ;;
			(2) rvm_requiremnts_fail error "Running '$*' would require sudo."
				return 1 ;;
			(*) if is_a_function __rvm_sudo
				then
					missing_paths="" 
					for sbin_path in /sbin /usr/sbin /usr/local/sbin
					do
						if [[ -d "${sbin_path}" ]] && [[ ":$PATH:" != *":${sbin_path}:"* ]]
						then
							missing_paths+=":${sbin_path}" 
						fi
					done
					if [[ -n "${missing_paths}" ]]
					then
						command_to_run=(/usr/bin/env PATH="${PATH}${missing_paths}" "${command_to_run[@]}") 
					fi
					command_to_run=(__rvm_sudo -p "%p password required for '$*': " "${command_to_run[@]}") 
				else
					rvm_error "Running '$*' would require sudo, but 'sudo' is not found!"
					return 1
				fi ;;
		esac
		"${command_to_run[@]}" || return $?
	)
}
__rvm_unload () {
	\typeset _element
	\typeset -a _list
	__rvm_remove_rvm_from_path
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		__rvm_remove_from_array fpath "$rvm_path/scripts/extras/completion.zsh" "${fpath[@]}"
	fi
	__rvm_unload_action unalias <<< "$(
    if [[ -n "${ZSH_VERSION:-}" ]]
    then alias | __rvm_awk -F"=" '/rvm/ {print $1}'
    else alias | __rvm_awk -F"[= ]" '/rvm/ {print $2}'
    fi
  )"
	__rvm_unload_action unset <<< "$(
    set |
      __rvm_awk -F"=" 'BEGIN{v=0;} /^[a-zA-Z_][a-zA-Z0-9_]*=/{v=1;} v==1&&$2~/^['\''\$]/{v=2;}
        v==1&&$2~/^\(/{v=3;} v==2&&/'\''$/&&!/'\'\''$/{v=1;} v==3&&/\)$/{v=1;} v{print;} v==1{v=0;}' |
      __rvm_awk -F"=" '/^[^ ]*(RUBY|GEM|IRB|gem|rubies|rvm)[^ ]*=/ {print $1} /^[^ ]*=.*rvm/ {print $1}' |
      __rvm_grep -vE "^PROMPT|^prompt|^PS|^BASH_SOURCE|^PATH"
  )"
	__rvm_unload_action __function_unset <<< "$(
    \typeset -f | __rvm_awk '$2=="()" {fun=$1} /rvm/{print fun}' | sort -u | __rvm_grep -v __rvm_unload_action
  )"
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		unset -f __rvm_unload_action
		unset -f __function_unset
		if [[ -n "${_comp_dumpfile:-}" ]]
		then
			\command \rm -f "$_comp_dumpfile"
			compinit -d "$_comp_dumpfile"
		fi
	else
		unset __rvm_unload_action __function_unset
	fi
}
__rvm_unload_action () {
	\typeset _element IFS
	\typeset -a _list
	IFS=$'\n' 
	_list=($( \command \cat ${2:--} | sort -u )) 
	for _element in "${_list[@]}"
	do
		$1 "${_element}"
	done
}
__rvm_unset_exports () {
	\typeset wrap_name name value
	\typeset -a __variables_list
	__rvm_read_lines __variables_list <<< "$(
    printenv | __rvm_sed '/^rvm_old_.*=/ { s/=.*$//; p; }; d;'
  )"
	for wrap_name in "${__variables_list[@]}"
	do
		eval "value=\"\${${wrap_name}}\""
		name=${wrap_name#rvm_old_} 
		if [[ -n "${value:-}" ]]
		then
			export $name="${value}"
		else
			unset $name
		fi
		unset $wrap_name
	done
}
__rvm_unset_ruby_variables () {
	unset rvm_env_string rvm_ruby_string rvm_ruby_strings rvm_ruby_binary rvm_ruby_gem_home rvm_ruby_gem_path rvm_ruby_home rvm_ruby_interpreter rvm_ruby_irbrc rvm_ruby_log_path rvm_ruby_major_version rvm_ruby_minor_version rvm_ruby_package_name rvm_ruby_patch_level rvm_ruby_release_version rvm_ruby_repo_url rvm_ruby_repo_branch rvm_ruby_revision rvm_ruby_selected_flag rvm_ruby_tag rvm_ruby_version rvm_head_flag rvm_ruby_package_file rvm_ruby_configure rvm_ruby_name rvm_ruby_url rvm_ruby_global_gems_path rvm_ruby_args rvm_ruby_name rvm_llvm_flag rvm_ruby_repo_tag
	__rvm_load_rvmrc
}
__rvm_untrust_rvmrc () {
	[[ -f "$1" ]] || return 1
	__rvm_reset_rvmrc_trust "$1"
	__rvm_db_ "${rvm_user_path:-${rvm_path}/user}/rvmrcs" "$(__rvm_rvmrc_key "$1")" "0;$(__rvm_checksum_for_contents "$1")" > /dev/null 2>&1 || return $?
}
__rvm_use () {
	\typeset binary full_binary_path rvm_ruby_gem_home __path_prefix __path_suffix
	__rvm_select "$@" || return $?
	if [[ "system" == ${rvm_ruby_interpreter:="system"} ]]
	then
		__rvm_use_system
	else
		__rvm_use_ || return $?
	fi
	__rvm_use_common
}
__rvm_use_ () {
	rvm_ruby_home="${rvm_ruby_home%%@*}" 
	if [[ ! -d "$rvm_ruby_home" ]]
	then
		if [[ ${rvm_install_on_use_flag:-0} -eq 1 ]]
		then
			rvm_warn "Required $rvm_ruby_string is not installed - installing."
			__rvm_run_wrapper manage "install" "$rvm_ruby_string"
		else
			rvm_error "Required $rvm_ruby_string is not installed."
			rvm_log "To install do: 'rvm install \"$rvm_ruby_string\"'"
			export rvm_recommended_ruby="rvm install $rvm_ruby_string" 
			return 1
		fi
	fi
	__rvm_gemset_use_ensure || return $?
	export GEM_HOME GEM_PATH MY_RUBY_HOME RUBY_VERSION IRBRC
	GEM_HOME="$rvm_ruby_gem_home" 
	GEM_PATH="$rvm_ruby_gem_path" 
	MY_RUBY_HOME="$rvm_ruby_home" 
	RUBY_VERSION="$rvm_ruby_string" 
	IRBRC="$rvm_ruby_irbrc" 
	unset BUNDLE_PATH
	if [[ "maglev" == "$rvm_ruby_interpreter" ]]
	then
		GEM_PATH="$GEM_PATH:$MAGLEV_HOME/lib/maglev/gems/1.8/" 
	fi
	[[ -n "${IRBRC:-}" ]] || unset IRBRC
	if (( ${rvm_use_flag:-1} >= 2 && ${rvm_internal_use_flag:-0} == 0 )) || (( ${rvm_use_flag:-1} == 1 && ${rvm_verbose_flag:-0} == 1 ))
	then
		rvm_log "Using ${GEM_HOME/${rvm_gemset_separator:-'@'}/ with gemset }"
	fi
	if [[ "$GEM_HOME" != "$rvm_ruby_global_gems_path" ]]
	then
		__path_prefix="$GEM_HOME/bin:$rvm_ruby_global_gems_path/bin:${rvm_ruby_binary%/*}:${rvm_bin_path}" 
	else
		__path_prefix="$GEM_HOME/bin:${rvm_ruby_binary%/*}:${rvm_bin_path}" 
	fi
	__path_suffix="" 
}
__rvm_use_common () {
	[[ -z "${rvm_ruby_string:-}" ]] || export rvm_ruby_string
	[[ -z "${rvm_gemset_name:-}" ]] || export rvm_gemset_name
	\typeset __save_PATH
	__rvm_remove_rvm_from_path
	__save_PATH=$PATH 
	if [[ -n "${_OLD_VIRTUAL_PATH}" ]]
	then
		PATH="${_OLD_VIRTUAL_PATH}" 
		__rvm_remove_rvm_from_path
		_OLD_VIRTUAL_PATH="${__path_prefix:-}${__path_prefix:+:}${PATH}${__path_suffix:+:}${__path_suffix:-}" 
	fi
	PATH="${__path_prefix:-}${__path_prefix:+:}$__save_PATH${__path_suffix:+:}${__path_suffix:-}" 
	export PATH
	builtin hash -r
	if [[ "$rvm_ruby_string" != "system" ]]
	then
		case "${rvm_rvmrc_flag:-0}" in
			(rvmrc|versions_conf|ruby_version) __rvm_set_${rvm_rvmrc_flag} ;;
		esac
		\typeset environment_id
		environment_id="$(__rvm_env_string)" 
		if (( ${rvm_default_flag:=0} == 1 )) && [[ "default" != "${rvm_ruby_interpreter:-}" ]] && [[ "system" != "${rvm_ruby_interpreter:-}" ]]
		then
			"$rvm_scripts_path/alias" delete default &> /dev/null
			"$rvm_scripts_path/alias" create default "$environment_id" >&/dev/null
		fi
		rvm_default_flag=0 
		if [[ -n "${rvm_ruby_alias:-}" ]]
		then
			rvm_log "Attempting to alias $environment_id to $rvm_ruby_alias"
			"$rvm_scripts_path/alias" delete "$rvm_ruby_alias" > /dev/null 2>&1
			rvm_alias_expanded=1 "$rvm_scripts_path/alias" create "$rvm_ruby_alias" "$environment_id" > /dev/null 2>&1
			ruby_alias="" 
			rvm_ruby_alias="" 
		fi
	else
		if (( ${rvm_default_flag:=0} == 1 ))
		then
			builtin command -v __rvm_reset >> /dev/null 2>&1 || source "$rvm_scripts_path/functions/reset"
			__rvm_reset
		fi
	fi
	rvm_hook="after_use" 
	source "$rvm_scripts_path/hook"
	return 0
}
__rvm_use_ruby_warnings () {
	if [[ "${rvm_ruby_string}" == "system" || "${rvm_ruby_string}" == "" ]]
	then
		return 0
	fi
	\typeset __executable __gem_version
	for __executable in ruby gem irb
	do
		[[ -x "$MY_RUBY_HOME/bin/${__executable}" ]] || rvm_warn "Warning! Executable '${__executable}' missing, something went wrong with this ruby installation!"
	done
	if [[ "${rvm_ruby_interpreter}" == "ruby" ]] && {
			__rvm_version_compare "${rvm_ruby_version}" -ge 2.0.0 || [[ "${rvm_ruby_version}" == "head" ]]
		} && __rvm_which gem > /dev/null && __gem_version="$(RUBYGEMS_GEMDEPS= gem --version)"  && [[ -n "${__gem_version}" ]] && __rvm_version_compare "${__gem_version}" -lt "2.0.0"
	then
		rvm_warn "Warning! You have just used ruby 2.0.0 or newer, which is not fully compatible with rubygems 1.8.x or older,
         consider upgrading rubygems with: <code>rvm rubygems latest</code>"
	fi
}
__rvm_use_system () {
	unset GEM_HOME GEM_PATH MY_RUBY_HOME RUBY_VERSION IRBRC
	if [[ -s "$rvm_path/config/system" ]]
	then
		if __rvm_grep "MY_RUBY_HOME='$rvm_rubies_path" "$rvm_path/config/system" > /dev/null
		then
			if [[ -f "$rvm_path/config/system" ]]
			then
				\command \rm -f "$rvm_path/config/system"
			fi
		else
			source "$rvm_path/config/system"
		fi
	fi
	if (( ${rvm_default_flag:=0} == 1 ))
	then
		"$rvm_scripts_path/alias" delete default &> /dev/null
		__rvm_find "${rvm_bin_path}" -maxdepth 0 -name 'default_*' -exec rm '{}' \;
		\command \rm -f "$rvm_path/config/default"
		\command \rm -f "$rvm_environments_path/default"
		__rvm_rm_rf "$rvm_wrappers_path/default"
	fi
	rvm_verbose_log "Now using system ruby."
	__path_prefix="" 
	__path_suffix="${rvm_bin_path}" 
	export rvm_ruby_string="system" 
}
__rvm_using_gemset_globalcache () {
	__rvm_db_ "$rvm_user_path/db" "use_gemset_globalcache" | __rvm_grep '^true$' > /dev/null 2>&1
	return $?
}
__rvm_version () {
	echo "rvm $(__rvm_version_installed) by $(__rvm_version_authors) [$(__rvm_version_website)]"
}
__rvm_version_authors () {
	echo "Michal Papis, Piotr Kuczynski, Wayne E. Seguin"
}
__rvm_version_compare () {
	\typeset first
	first="$( \command \printf "%b" "$1\n$3\n" | __rvm_version_sort | \command \head -n1 )" 
	case "$2" in
		(-eq|==|=) [[ "$1" == "$3" ]] || return $? ;;
		(-ne|!=) [[ "$1" != "$3" ]] || return $? ;;
		(-gt|\>) if [[ "$first" == "head" ]]
			then
				[[ "$first" == "$1" && "$1" != "$3" ]] || return $?
			else
				[[ "$first" == "$3" && "$1" != "$3" ]] || return $?
			fi ;;
		(-ge|\>=) if [[ "$first" == "head" ]]
			then
				[[ "$first" == "$1" || "$1" == "$3" ]] || return $?
			else
				[[ "$first" == "$3" || "$1" == "$3" ]] || return $?
			fi ;;
		(-lt|\<) if [[ "$first" == "head" ]]
			then
				[[ "$first" == "$3" && "$1" != "$3" ]] || return $?
			else
				[[ "$first" == "$1" && "$1" != "$3" ]] || return $?
			fi ;;
		(-le|\<=) if [[ "$first" == "head" ]]
			then
				[[ "$first" == "$3" || "$1" == "$3" ]] || return $?
			else
				[[ "$first" == "$1" || "$1" == "$3" ]] || return $?
			fi ;;
		(*) rvm_error "Unsupported operator '$2'."
			return 1 ;;
	esac
	return 0
}
__rvm_version_copyright () {
	echo "(c) 2009-2020 $(__rvm_version_authors)"
}
__rvm_version_installed () {
	echo "$(\command \cat "$rvm_path/VERSION") ($(\command \cat "$rvm_path/RELEASE" 2>/dev/null))"
}
__rvm_version_remote () {
	__rvm_curl -s --max-time 10 https://github.com/rvm/rvm/raw/stable/VERSION || true
}
__rvm_version_sort () {
	\command \awk -F'[.-]' -v OFS=. '{                   # split on "." and "-", merge back with "."
    original=$0                                        # save original to preserve it before the line is changed
    for (n=1; n<10; n++) {                             # iterate through max 9 components of version
      $n=tolower($n)                                   # ignore case for sorting
      if ($n == "")                 $n="0"             # treat non existing parts as 0
      if ($n ~ /^p[0-9]/)           $n=substr($n, 2)   # old ruby -p notation
      if ($n ~ /^[0-9](rc|b)/)      $n=substr($n, 1, 1)". "substr($n, 2)   # old jruby 0RC1 notation
      if (n == 1 && $n ~ /^[0-9]/)  $n="zzz."$n        # first group must be a string
      if (n > 1 && $n ~ /^[a-z]/)   $n=" "$n           # names go before numbers thanks to space
    }
    print $0"\t"original                               # print the transformed version and original separated by \t
                                                       # so we can extract original after sorting
  }' | LC_ALL=C \sort -t. -k 1,1d -k 2,2n -k 3,3n -k 4,4n -k 5,5n -k 6,6n -k 7,7n -k 8,8n -k 9,9n | \awk -F'\t' '{print $2}'
}
__rvm_version_website () {
	echo "https://rvm.io"
}
__rvm_wait_anykey () {
	if [[ -n "${1:-}" ]]
	then
		echo "$1"
	fi
	\typeset _read_char_flag
	if [[ -n "${ZSH_VERSION:-}" ]]
	then
		_read_char_flag=k 
	else
		_read_char_flag=n 
	fi
	builtin read -${_read_char_flag} 1 -s -r anykey
}
__rvm_which () {
	\command \which "$@" || return $?
}
__rvm_with () {
	(
		unset rvm_rvmrc_flag
		export rvm_create_flag=1 
		export rvm_delete_flag=0 
		export rvm_internal_use_flag=1 
		export rvm_use_flag=0 
		__rvm_use "$1" || return $?
		shift
		"$@" || return $?
	)
}
__rvm_xargs () {
	\xargs "$@" || return $?
}
__rvmrc_full_path_to_file () {
	if [[ "$1" == "all.rvmrcs" || "$1" == "allGemfiles" ]]
	then
		__rvmrc_warning_file="$1" 
	elif [[ -d "$1" && -s "$1/.rvmrc" ]]
	then
		__rvmrc_warning_file="$( __rvm_cd "$1" >/dev/null 2>&1; pwd )/.rvmrc" 
	elif [[ -d "$1" && -s "$1/Gemfile" ]]
	then
		__rvmrc_warning_file="$( __rvm_cd "$1" >/dev/null 2>&1; pwd )/Gemfile" 
	elif [[ -f "$1" || "$1" == *".rvmrc" || "$1" == *"Gemfile" ]]
	then
		__rvmrc_warning_file="$( dirname "$1" )" 
		: __rvmrc_warning_file:${__rvmrc_warning_file:=$PWD}
		__rvmrc_warning_file="${__rvmrc_warning_file}/${1##*/}" 
	else
		rvm_warn "Do not know how to handle '$1', please report: https://github.com/rvm/rvm/issues ~ __rvmrc_full_path_to_file"
		return 1
	fi
}
__rvmrc_warning () {
	\typeset __rvmrc_warning_path __rvmrc_warning_file
	__rvmrc_warning_path="$rvm_user_path/rvmrc_ignored" 
	case "${1:-help}" in
		(list) __rvmrc_warning_$1 "${2:-}" || return $? ;;
		(check|check_quiet|ignore|reset) __rvmrc_full_path_to_file "${2:-}" && __rvmrc_warning_$1 "${__rvmrc_warning_file:-${2:-}}" || return $? ;;
		(help) rvm_help rvmrc warning ;;
		(*) rvm_error_help "Unknown subcommand '$1'" rvmrc warning
			return 1 ;;
	esac
}
__rvmrc_warning_check () {
	if __rvmrc_warning_check_quiet "$1"
	then
		rvm_log "path '$1' is ignored."
	else
		\typeset ret=$?
		rvm_log "path '$1' is not ignored."
		return $ret
	fi
}
__rvmrc_warning_check_quiet () {
	[[ -f "$__rvmrc_warning_path" ]] || return $?
	\typeset __rvmrc_type
	case "$1" in
		(all.rvmrcs|allGemfiles) true ;;
		(*) __rvmrc_type="^all${1##*/}s" 
			if __rvm_grep "${__rvmrc_type}$" "$__rvmrc_warning_path" > /dev/null
			then
				return 0
			fi ;;
	esac
	__rvm_grep "^$1$" "$__rvmrc_warning_path" > /dev/null || return $?
}
__rvmrc_warning_display_for_Gemfile () {
	\typeset __rvmrc_warning_path __rvmrc_warning_file
	__rvmrc_warning_path="$rvm_user_path/rvmrc_ignored" 
	if [[ -t 2 ]] && __rvmrc_full_path_to_file "${1:-}" && ! __rvmrc_warning_check_quiet "${__rvmrc_warning_file:-${2:-}}"
	then
		rvm_warn "RVM used your Gemfile for selecting Ruby, it is all fine - Heroku does that too,
you can ignore these warnings with 'rvm rvmrc warning ignore $1'.
To ignore the warning for all files run 'rvm rvmrc warning ignore allGemfiles'.
"
	fi
}
__rvmrc_warning_display_for_rvmrc () {
	\typeset __rvmrc_warning_path __rvmrc_warning_file
	__rvmrc_warning_path="$rvm_user_path/rvmrc_ignored" 
	if [[ -t 2 ]] && __rvmrc_full_path_to_file "${1:-}" && ! __rvmrc_warning_check_quiet "${__rvmrc_warning_file:-${2:-}}"
	then
		rvm_warn "You are using '.rvmrc', it requires trusting, it is slower and it is not compatible with other ruby managers,
you can switch to '.ruby-version' using 'rvm rvmrc to ruby-version'
or ignore this warning with 'rvm rvmrc warning ignore $1',
'.rvmrc' will continue to be the default project file in RVM 1 and RVM 2,
to ignore the warning for all files run 'rvm rvmrc warning ignore all.rvmrcs'.
"
	fi
}
__rvmrc_warning_ignore () {
	__rvmrc_warning_check_quiet "$1" || case "$1" in
		(all.rvmrcs|allGemfiles) echo "$1" >> "$__rvmrc_warning_path" ;;
		(*) echo "$1" >> "$__rvmrc_warning_path" ;;
	esac
}
__rvmrc_warning_list () {
	rvm_log "# List of project files that ignore warnings:"
	if [[ -s "$__rvmrc_warning_path" ]]
	then
		\command \cat "$__rvmrc_warning_path"
	fi
}
__rvmrc_warning_reset () {
	\typeset __rvmrc_type
	case "${1:-}" in
		(all.rvmrcs|allGemfiles) if __rvmrc_warning_check_quiet "$1"
			then
				__rvm_sed_i "$__rvmrc_warning_path" -e "\#^${1}\$# d" -e '/^$/ d'
				__rvmrc_type="${1#all}" 
				__rvmrc_type="${__rvmrc_type%s}" 
				__rvm_sed_i "$__rvmrc_warning_path" -e "\#/${__rvmrc_type}\$# d" -e '\#^$# d'
			else
				rvm_debug "Already removed warning ignore from '$1'."
			fi ;;
		(*) if __rvmrc_warning_check_quiet "$1"
			then
				__rvm_sed_i "$__rvmrc_warning_path" -e "\#^${1}\$# d" -e '\#^$# d'
			else
				rvm_debug "Already removed warning ignore from '$1'."
			fi ;;
	esac
}
__sdk_config () {
	local -r editor=(${EDITOR:=vi}) 
	if ! command -v "${editor[@]}" > /dev/null
	then
		__sdkman_echo_red "No default editor configured."
		__sdkman_echo_yellow "Please set the default editor with the EDITOR environment variable."
		return 1
	fi
	"${editor[@]}" "${SDKMAN_DIR}/etc/config"
}
__sdk_current () {
	local candidate="$1" 
	echo ""
	if [ -n "$candidate" ]
	then
		__sdkman_determine_current_version "$candidate"
		if [ -n "$CURRENT" ]
		then
			__sdkman_echo_no_colour "Using ${candidate} version ${CURRENT}"
		else
			__sdkman_echo_red "Not using any version of ${candidate}"
		fi
	else
		local installed_count=0 
		for ((i = 0; i <= ${#SDKMAN_CANDIDATES[*]}; i++)) do
			if [[ -n ${SDKMAN_CANDIDATES[${i}]} ]]
			then
				__sdkman_determine_current_version "${SDKMAN_CANDIDATES[${i}]}"
				if [ -n "$CURRENT" ]
				then
					if [ ${installed_count} -eq 0 ]
					then
						__sdkman_echo_no_colour 'Using:'
						echo ""
					fi
					__sdkman_echo_no_colour "${SDKMAN_CANDIDATES[${i}]}: ${CURRENT}"
					((installed_count += 1))
				fi
			fi
		done
		if [ ${installed_count} -eq 0 ]
		then
			__sdkman_echo_no_colour 'No candidates are in use'
		fi
	fi
}
__sdk_default () {
	__sdkman_deprecation_notice "default"
	local candidate version
	candidate="$1" 
	version="$2" 
	__sdkman_check_candidate_present "$candidate" || return 1
	__sdkman_determine_version "$candidate" "$version" || return 1
	if [ ! -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${VERSION}" ]
	then
		echo ""
		__sdkman_echo_red "Stop! Candidate version is not installed."
		echo ""
		__sdkman_echo_yellow "Tip: Run the following to install this version"
		echo ""
		__sdkman_echo_yellow "$ sdk install ${candidate} ${VERSION}"
		return 1
	fi
	__sdkman_link_candidate_version "$candidate" "$VERSION"
	echo ""
	__sdkman_echo_green "Default ${candidate} version set to ${VERSION}"
}
__sdk_env () {
	local -r sdkmanrc=".sdkmanrc" 
	local -r subcommand="$1" 
	case $subcommand in
		("") __sdkman_load_env "$sdkmanrc" ;;
		(init) __sdkman_create_env_file "$sdkmanrc" ;;
		(install) __sdkman_setup_env "$sdkmanrc" ;;
		(clear) __sdkman_clear_env "$sdkmanrc" ;;
	esac
}
__sdk_flush () {
	local qualifier="$1" 
	case "$qualifier" in
		(version) if [[ -f "${SDKMAN_DIR}/var/version" ]]
			then
				rm -f "${SDKMAN_DIR}/var/version"
				__sdkman_echo_green "Version file has been flushed."
			fi ;;
		(temp) __sdkman_cleanup_folder "tmp" ;;
		(tmp) __sdkman_cleanup_folder "tmp" ;;
		(metadata) __sdkman_cleanup_folder "var/metadata" ;;
		(*) __sdkman_cleanup_folder "tmp"
			__sdkman_cleanup_folder "var/metadata" ;;
	esac
}
__sdk_help () {
	__sdkman_deprecation_notice "help"
	__sdkman_echo_no_colour ""
	__sdkman_echo_no_colour "Usage: sdk <command> [candidate] [version]"
	__sdkman_echo_no_colour "       sdk offline <enable|disable>"
	__sdkman_echo_no_colour ""
	__sdkman_echo_no_colour "   commands:"
	__sdkman_echo_no_colour "       install   or i    <candidate> [version] [local-path]"
	__sdkman_echo_no_colour "       uninstall or rm   <candidate> <version>"
	__sdkman_echo_no_colour "       list      or ls   [candidate]"
	__sdkman_echo_no_colour "       use       or u    <candidate> <version>"
	__sdkman_echo_no_colour "       config"
	__sdkman_echo_no_colour "       default   or d    <candidate> [version]"
	__sdkman_echo_no_colour "       home      or h    <candidate> <version>"
	__sdkman_echo_no_colour "       env       or e    [init|install|clear]"
	__sdkman_echo_no_colour "       current   or c    [candidate]"
	__sdkman_echo_no_colour "       upgrade   or ug   [candidate]"
	__sdkman_echo_no_colour "       version   or v"
	__sdkman_echo_no_colour "       help"
	__sdkman_echo_no_colour "       offline           [enable|disable]"
	if [[ "$sdkman_selfupdate_feature" == "true" ]]
	then
		__sdkman_echo_no_colour "       selfupdate        [force]"
	fi
	__sdkman_echo_no_colour "       update"
	__sdkman_echo_no_colour "       flush             [tmp|metadata|version]"
	__sdkman_echo_no_colour ""
	__sdkman_echo_no_colour "   candidate  :  the SDK to install: groovy, scala, grails, gradle, kotlin, etc."
	__sdkman_echo_no_colour "                 use list command for comprehensive list of candidates"
	__sdkman_echo_no_colour "                 eg: \$ sdk list"
	__sdkman_echo_no_colour "   version    :  where optional, defaults to latest stable if not provided"
	__sdkman_echo_no_colour "                 eg: \$ sdk install groovy"
	__sdkman_echo_no_colour "   local-path :  optional path to an existing local installation"
	__sdkman_echo_no_colour "                 eg: \$ sdk install groovy 2.4.13-local /opt/groovy-2.4.13"
	__sdkman_echo_no_colour ""
}
__sdk_home () {
	__sdkman_deprecation_notice "home"
	local candidate version
	candidate="$1" 
	version="$2" 
	__sdkman_check_version_present "$version" || return 1
	__sdkman_check_candidate_present "$candidate" || return 1
	__sdkman_determine_version "$candidate" "$version" || return 1
	if [[ ! -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}" ]]
	then
		echo ""
		__sdkman_echo_red "Stop! Candidate version is not installed."
		echo ""
		__sdkman_echo_yellow "Tip: Run the following to install this version"
		echo ""
		__sdkman_echo_yellow "$ sdk install ${candidate} ${version}"
		return 1
	fi
	echo -n "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}"
}
__sdk_install () {
	local candidate version folder
	candidate="$1" 
	version="$2" 
	folder="$3" 
	__sdkman_check_candidate_present "$candidate" || return 1
	__sdkman_determine_version "$candidate" "$version" "$folder" || return 1
	if [[ -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${VERSION}" || -L "${SDKMAN_CANDIDATES_DIR}/${candidate}/${VERSION}" ]]
	then
		echo ""
		__sdkman_echo_yellow "${candidate} ${VERSION} is already installed."
		return 0
	fi
	if [[ ${VERSION_VALID} == 'valid' ]]
	then
		__sdkman_determine_current_version "$candidate"
		__sdkman_install_candidate_version "$candidate" "$VERSION" || return 1
		if [[ "$sdkman_auto_answer" != 'true' && "$auto_answer_upgrade" != 'true' && -n "$CURRENT" ]]
		then
			__sdkman_echo_confirm "Do you want ${candidate} ${VERSION} to be set as default? (Y/n): "
			read USE
		fi
		if [[ -z "$USE" || "$USE" == "y" || "$USE" == "Y" ]]
		then
			echo ""
			__sdkman_echo_green "Setting ${candidate} ${VERSION} as default."
			__sdkman_link_candidate_version "$candidate" "$VERSION"
			__sdkman_add_to_path "$candidate"
		fi
		return 0
	elif [[ "$VERSION_VALID" == 'invalid' && -n "$folder" ]]
	then
		__sdkman_install_local_version "$candidate" "$VERSION" "$folder" || return 1
	else
		echo ""
		__sdkman_echo_red "Stop! $1 is not a valid ${candidate} version."
		return 1
	fi
}
__sdk_list () {
	local candidate="$1" 
	if [[ -z "$candidate" ]]
	then
		__sdkman_list_candidates
	else
		__sdkman_list_versions "$candidate"
	fi
}
__sdk_offline () {
	local mode="$1" 
	if [[ -z "$mode" || "$mode" == "enable" ]]
	then
		SDKMAN_OFFLINE_MODE="true" 
		__sdkman_echo_green "Offline mode enabled."
	fi
	if [[ "$mode" == "disable" ]]
	then
		SDKMAN_OFFLINE_MODE="false" 
		__sdkman_echo_green "Online mode re-enabled!"
	fi
}
__sdk_selfupdate () {
	local force_selfupdate
	local sdkman_script_version_api
	local sdkman_native_version_api
	if [[ "$SDKMAN_AVAILABLE" == "false" ]]
	then
		echo "This command is not available while offline."
		return 1
	fi
	if [[ "$sdkman_beta_channel" == "true" ]]
	then
		sdkman_script_version_api="${SDKMAN_CANDIDATES_API}/broker/version/sdkman/script/beta" 
		sdkman_native_version_api="${SDKMAN_CANDIDATES_API}/broker/version/sdkman/native/beta" 
	else
		sdkman_script_version_api="${SDKMAN_CANDIDATES_API}/broker/version/sdkman/script/stable" 
		sdkman_native_version_api="${SDKMAN_CANDIDATES_API}/broker/version/sdkman/native/stable" 
	fi
	sdkman_remote_script_version=$(__sdkman_secure_curl "$sdkman_script_version_api") 
	sdkman_remote_native_version=$(__sdkman_secure_curl "$sdkman_native_version_api") 
	sdkman_local_script_version=$(< "$SDKMAN_DIR/var/version") 
	sdkman_local_native_version=$(< "$SDKMAN_DIR/var/version_native") 
	__sdkman_echo_debug "Script: local version: $sdkman_local_script_version; remote version: $sdkman_remote_script_version"
	__sdkman_echo_debug "Native: local version: $sdkman_local_native_version; remote version: $sdkman_remote_native_version"
	force_selfupdate="$1" 
	export sdkman_debug_mode
	if [[ "$sdkman_local_script_version" == "$sdkman_remote_script_version" && "$sdkman_local_native_version" == "$sdkman_remote_native_version" && "$force_selfupdate" != "force" ]]
	then
		echo "No update available at this time."
	elif [[ "$sdkman_beta_channel" == "true" ]]
	then
		__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/selfupdate/beta/${SDKMAN_PLATFORM}" | bash
	else
		__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/selfupdate/stable/${SDKMAN_PLATFORM}" | bash
	fi
}
__sdk_uninstall () {
	__sdkman_deprecation_notice "uninstall"
	local candidate version current
	candidate="$1" 
	version="$2" 
	__sdkman_check_candidate_present "$candidate" || return 1
	__sdkman_check_version_present "$version" || return 1
	current=$(readlink "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" | sed "s!${SDKMAN_CANDIDATES_DIR}/${candidate}/!!g") 
	if [[ -L "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" && "$version" == "$current" ]]
	then
		echo ""
		__sdkman_echo_green "Deselecting ${candidate} ${version}..."
		unlink "${SDKMAN_CANDIDATES_DIR}/${candidate}/current"
	fi
	echo ""
	if [ -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}" ]
	then
		__sdkman_echo_green "Uninstalling ${candidate} ${version}..."
		rm -rf "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}"
	else
		__sdkman_echo_red "${candidate} ${version} is not installed."
	fi
}
__sdk_update () {
	local candidates_uri="${SDKMAN_CANDIDATES_API}/candidates/all" 
	__sdkman_echo_debug "Using candidates endpoint: $candidates_uri"
	local fresh_candidates_csv=$(__sdkman_secure_curl_with_timeouts "$candidates_uri") 
	__sdkman_echo_debug "Local candidates: $SDKMAN_CANDIDATES_CSV"
	__sdkman_echo_debug "Fetched candidates: $fresh_candidates_csv"
	if [[ -n "${fresh_candidates_csv}" ]] && ! grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv} -iq 'html' <<< "${fresh_candidates_csv}"
	then
		__sdkman_echo_debug "Fresh and cached candidate lengths: ${#fresh_candidates_csv} ${#SDKMAN_CANDIDATES_CSV}"
		local fresh_candidates combined_candidates diff_candidates
		if [[ "${zsh_shell}" == 'true' ]]
		then
			fresh_candidates=(${(s:,:)fresh_candidates_csv}) 
		else
			IFS=',' read -a fresh_candidates <<< "${fresh_candidates_csv}"
		fi
		combined_candidates=("${fresh_candidates[@]}" "${SDKMAN_CANDIDATES[@]}") 
		diff_candidates=($(printf $'%s\n' "${combined_candidates[@]}" | sort | uniq -u)) 
		if ((${#diff_candidates[@]}))
		then
			local delta
			delta=("${fresh_candidates[@]}" "${diff_candidates[@]}") 
			delta=($(printf $'%s\n' "${delta[@]}" | sort | uniq -d)) 
			if ((${#delta[@]}))
			then
				__sdkman_echo_green "\nAdding new candidates(s): ${delta[*]}"
			fi
			delta=("${SDKMAN_CANDIDATES[@]}" "${diff_candidates[@]}") 
			delta=($(printf $'%s\n' "${delta[@]}" | sort | uniq -d)) 
			if ((${#delta[@]}))
			then
				__sdkman_echo_green "\nRemoving obsolete candidates(s): ${delta[*]}"
			fi
			echo "${fresh_candidates_csv}" >| "${SDKMAN_CANDIDATES_CACHE}"
			__sdkman_echo_yellow $'\nPlease open a new terminal now...'
		else
			touch "${SDKMAN_CANDIDATES_CACHE}"
			__sdkman_echo_green $'\nNo new candidates found at this time.'
		fi
	fi
}
__sdk_upgrade () {
	local all candidates candidate upgradable installed_count upgradable_count upgradable_candidates
	if [ -n "$1" ]
	then
		all=false 
		candidates=$1 
	else
		all=true 
		if [[ "$zsh_shell" == 'true' ]]
		then
			candidates=(${SDKMAN_CANDIDATES[@]}) 
		else
			candidates=${SDKMAN_CANDIDATES[@]} 
		fi
	fi
	installed_count=0 
	upgradable_count=0 
	echo ""
	for candidate in ${candidates}
	do
		upgradable="$(__sdkman_determine_upgradable_version "$candidate")" 
		case $? in
			(1) $all || __sdkman_echo_red "Not using any version of ${candidate}" ;;
			(2) echo ""
				__sdkman_echo_red "Stop! Could not get remote version of ${candidate}"
				return 1 ;;
			(*) if [ -n "$upgradable" ]
				then
					[ ${upgradable_count} -eq 0 ] && __sdkman_echo_no_colour "Available defaults:"
					__sdkman_echo_no_colour "$upgradable"
					((upgradable_count += 1))
					upgradable_candidates=(${upgradable_candidates[@]} $candidate) 
				fi
				((installed_count += 1)) ;;
		esac
	done
	if $all
	then
		if [ ${installed_count} -eq 0 ]
		then
			__sdkman_echo_no_colour 'No candidates are in use'
		elif [ ${upgradable_count} -eq 0 ]
		then
			__sdkman_echo_no_colour "All candidates are up-to-date"
		fi
	elif [ ${upgradable_count} -eq 0 ]
	then
		__sdkman_echo_no_colour "${candidate} is up-to-date"
	fi
	if [ ${upgradable_count} -gt 0 ]
	then
		echo ""
		if [[ "$sdkman_auto_answer" != 'true' ]]
		then
			__sdkman_echo_confirm "Use prescribed default version(s)? (Y/n): "
			read UPGRADE_ALL
		fi
		export auto_answer_upgrade='true' 
		if [[ -z "$UPGRADE_ALL" || "$UPGRADE_ALL" == "y" || "$UPGRADE_ALL" == "Y" ]]
		then
			for ((i = 0; i <= ${#upgradable_candidates[*]}; i++)) do
				upgradable_candidate="${upgradable_candidates[${i}]}" 
				if [[ -n "$upgradable_candidate" ]]
				then
					__sdk_install $upgradable_candidate
				fi
			done
		fi
		unset auto_answer_upgrade
	fi
}
__sdk_use () {
	local candidate version install
	candidate="$1" 
	version="$2" 
	__sdkman_check_version_present "$version" || return 1
	__sdkman_check_candidate_present "$candidate" || return 1
	if [[ ! -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}" ]]
	then
		echo ""
		__sdkman_echo_red "Stop! Candidate version is not installed."
		echo ""
		__sdkman_echo_yellow "Tip: Run the following to install this version"
		echo ""
		__sdkman_echo_yellow "$ sdk install ${candidate} ${version}"
		return 1
	fi
	__sdkman_set_candidate_home "$candidate" "$version"
	if [[ $PATH =~ ${SDKMAN_CANDIDATES_DIR}/${candidate}/([^/]+) ]]
	then
		local matched_version
		if [[ "$zsh_shell" == "true" ]]
		then
			matched_version=${match[1]} 
		else
			matched_version=${BASH_REMATCH[1]} 
		fi
		export PATH=${PATH//${SDKMAN_CANDIDATES_DIR}\/${candidate}\/${matched_version}/${SDKMAN_CANDIDATES_DIR}\/${candidate}\/${version}} 
	fi
	if [[ ! ( -L "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" || -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" ) ]]
	then
		__sdkman_echo_green "Setting ${candidate} version ${version} as default."
		__sdkman_link_candidate_version "$candidate" "$version"
	fi
	echo ""
	__sdkman_echo_green "Using ${candidate} version ${version} in this shell."
}
__sdk_version () {
	__sdkman_deprecation_notice "version"
	local version=$(cat $SDKMAN_DIR/var/version) 
	echo ""
	__sdkman_echo_yellow "SDKMAN $version"
}
__sdkman_add_to_path () {
	local candidate present
	candidate="$1" 
	present=$(__sdkman_path_contains "$candidate") 
	if [[ "$present" == 'false' ]]
	then
		PATH="$SDKMAN_CANDIDATES_DIR/$candidate/current/bin:$PATH" 
	fi
}
__sdkman_build_version_csv () {
	local candidate versions_csv
	candidate="$1" 
	versions_csv="" 
	if [[ -d "${SDKMAN_CANDIDATES_DIR}/${candidate}" ]]
	then
		for version in $(find "${SDKMAN_CANDIDATES_DIR}/${candidate}" -maxdepth 1 -mindepth 1 \( -type l -o -type d \) -exec basename '{}' \; | sort -r)
		do
			if [[ "$version" != 'current' ]]
			then
				versions_csv="${version},${versions_csv}" 
			fi
		done
		versions_csv=${versions_csv%?} 
	fi
	echo "$versions_csv"
}
__sdkman_check_and_use () {
	local -r candidate=$1 
	local -r version=$2 
	if [[ ! -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}" ]]
	then
		__sdkman_echo_red "Stop! $candidate $version is not installed."
		echo ""
		__sdkman_echo_yellow "Run 'sdk env install' to install it."
		return 1
	fi
	__sdk_use "$candidate" "$version"
}
__sdkman_check_candidate_present () {
	local candidate="$1" 
	if [ -z "$candidate" ]
	then
		echo ""
		__sdkman_echo_red "No candidate provided."
		__sdk_help
		return 1
	fi
}
__sdkman_check_version_present () {
	local version="$1" 
	if [ -z "$version" ]
	then
		echo ""
		__sdkman_echo_red "No candidate version provided."
		__sdk_help
		return 1
	fi
}
__sdkman_checksum_zip () {
	local -r zip_archive="$1" 
	local -r headers_file="$2" 
	local algorithm checksum cmd
	local shasum_avail=false 
	local md5sum_avail=false 
	if [ -z "${headers_file}" ]
	then
		echo ""
		__sdkman_echo_debug "Skipping checksum for cached artifact"
		return
	elif [ ! -f "${headers_file}" ]
	then
		echo ""
		__sdkman_echo_yellow "Metadata file not found at '${headers_file}', skipping checksum..."
		return
	fi
	if [[ "$sdkman_checksum_enable" != "true" ]]
	then
		echo ""
		__sdkman_echo_yellow "Checksums are disabled, skipping verification..."
		return
	fi
	if command -v shasum > /dev/null 2>&1
	then
		shasum_avail=true 
	fi
	if command -v md5sum > /dev/null 2>&1
	then
		md5sum_avail=true 
	fi
	while IFS= read -r line
	do
		algorithm=$(echo $line | sed -n 's/^X-Sdkman-Checksum-\(.*\):.*$/\1/p' | tr '[:lower:]' '[:upper:]') 
		checksum=$(echo $line | sed -n 's/^X-Sdkman-Checksum-.*:\(.*\)$/\1/p' | tr -cd '[:alnum:]') 
		if [[ -n ${algorithm} && -n ${checksum} ]]
		then
			if [[ "$algorithm" =~ 'SHA' && "$shasum_avail" == 'true' ]]
			then
				cmd="echo \"${checksum} *${zip_archive}\" | shasum --check --quiet" 
			elif [[ "$algorithm" =~ 'MD5' && "$md5sum_avail" == 'true' ]]
			then
				cmd="echo \"${checksum} ${zip_archive}\" | md5sum --check --quiet" 
			fi
			if [[ -n $cmd ]]
			then
				__sdkman_echo_no_colour "Verifying artifact: ${zip_archive} (${algorithm}:${checksum})"
				if ! eval "$cmd"
				then
					rm -f "$zip_archive"
					echo ""
					__sdkman_echo_red "Stop! An invalid checksum was detected and the archive removed! Please try re-installing."
					return 1
				fi
			else
				__sdkman_echo_no_colour "Not able to perform checksum verification at this time."
			fi
		fi
	done < "${headers_file}"
}
__sdkman_cleanup_folder () {
	local folder="$1" 
	local sdkman_cleanup_dir
	local sdkman_cleanup_disk_usage
	local sdkman_cleanup_count
	sdkman_cleanup_dir="${SDKMAN_DIR}/${folder}" 
	sdkman_cleanup_disk_usage=$(du -sh "$sdkman_cleanup_dir") 
	sdkman_cleanup_count=$(ls -1 "$sdkman_cleanup_dir" | wc -l) 
	rm -rf "$sdkman_cleanup_dir"
	mkdir "$sdkman_cleanup_dir"
	__sdkman_echo_green "${sdkman_cleanup_count} archive(s) flushed, freeing ${sdkman_cleanup_disk_usage}."
}
__sdkman_clear_env () {
	local sdkmanrc="$1" 
	if [[ -z $SDKMAN_ENV ]]
	then
		__sdkman_echo_red "No environment currently set!"
		return 1
	fi
	if [[ ! -f ${SDKMAN_ENV}/${sdkmanrc} ]]
	then
		__sdkman_echo_red "Could not find ${SDKMAN_ENV}/${sdkmanrc}."
		return 1
	fi
	__sdkman_env_each_candidate "${SDKMAN_ENV}/${sdkmanrc}" "__sdkman_env_restore_default_version"
	unset SDKMAN_ENV
}
__sdkman_complete_candidate_version () {
	local -r command=$1 
	local -r candidate=$2 
	local -r candidate_version=$3 
	local -a candidates
	case $command in
		(default | d | home | h | uninstall | rm | use | u) local -r version_paths=("${SDKMAN_CANDIDATES_DIR}/${candidate}"/*) 
			for version_path in "${version_paths[@]}"
			do
				[[ $version_path = *current ]] && continue
				candidates+=("${version_path##*/}") 
			done ;;
		(install | i) while IFS= read -r -d, version || [[ -n "$version" ]]
			do
				candidates+=("$version") 
			done <<< "$(curl --silent "${SDKMAN_CANDIDATES_API}/candidates/$candidate/${SDKMAN_PLATFORM}/versions/all")" ;;
	esac
	COMPREPLY=($(compgen -W "${candidates[*]}" -- "$candidate_version")) 
}
__sdkman_complete_command () {
	local -r command=$1 
	local -r current_word=$2 
	local -a candidates
	case $command in
		(sdk) candidates=("install" "uninstall" "list" "use" "config" "default" "home" "env" "current" "upgrade" "version" "help" "offline" "selfupdate" "update" "flush")  ;;
		(current | c | default | d | home | h | uninstall | rm | upgrade | ug | use | u) local -r candidate_paths=("${SDKMAN_CANDIDATES_DIR}"/*) 
			for candidate_path in "${candidate_paths[@]}"
			do
				candidates+=("${candidate_path##*/}") 
			done ;;
		(install | i | list | ls) candidates=${SDKMAN_CANDIDATES[@]}  ;;
		(env | e) candidates=("init" "install" "clear")  ;;
		(offline) candidates=("enable" "disable")  ;;
		(selfupdate) candidates=("force")  ;;
		(flush) candidates=("temp" "version")  ;;
	esac
	COMPREPLY=($(compgen -W "${candidates[*]}" -- "$current_word")) 
}
__sdkman_create_env_file () {
	local sdkmanrc="$1" 
	if [[ -f "$sdkmanrc" ]]
	then
		__sdkman_echo_red "$sdkmanrc already exists!"
		return 1
	fi
	__sdkman_determine_current_version "java"
	local version
	[[ -n "$CURRENT" ]] && version="$CURRENT"  || version="$(__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/candidates/default/java")" 
	cat <<eof >| "$sdkmanrc"
# Enable auto-env through the sdkman_auto_env config
# Add key=value pairs of SDKs to use below
java=$version
eof
	__sdkman_echo_green "$sdkmanrc created."
}
__sdkman_deprecation_notice () {
	local message="
[Deprecation Notice]:
This legacy '$1' command is replaced by a native implementation
and it will be removed in a future release.
Please follow the discussion here:
https://github.com/sdkman/sdkman-cli/discussions/1332" 
	if [[ "$sdkman_colour_enable" == 'false' ]]
	then
		__sdkman_echo_no_colour "$message"
	else
		__sdkman_echo_yellow "$message"
	fi
}
__sdkman_determine_candidate_bin_dir () {
	local candidate_dir="$1" 
	if [[ -d "${candidate_dir}/bin" ]]
	then
		echo "${candidate_dir}/bin"
	else
		echo "$candidate_dir"
	fi
}
__sdkman_determine_current_version () {
	local candidate present
	candidate="$1" 
	present=$(__sdkman_path_contains "${SDKMAN_CANDIDATES_DIR}/${candidate}") 
	if [[ "$present" == 'true' ]]
	then
		if [[ $PATH =~ ${SDKMAN_CANDIDATES_DIR}/${candidate}/([^/]+)/bin ]]
		then
			if [[ "$zsh_shell" == "true" ]]
			then
				CURRENT=${match[1]} 
			else
				CURRENT=${BASH_REMATCH[1]} 
			fi
		fi
		if [[ "$CURRENT" == "current" ]]
		then
			CURRENT=$(readlink "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" | sed "s!${SDKMAN_CANDIDATES_DIR}/${candidate}/!!g") 
		fi
	else
		CURRENT="" 
	fi
}
__sdkman_determine_healthcheck_status () {
	if [[ "$SDKMAN_OFFLINE_MODE" == "true" || ( "$COMMAND" == "offline" && "$QUALIFIER" == "enable" ) ]]
	then
		echo ""
	else
		echo $(__sdkman_secure_curl_with_timeouts "${SDKMAN_CANDIDATES_API}/healthcheck")
	fi
}
__sdkman_determine_upgradable_version () {
	local candidate local_versions remote_default_version
	candidate="$1" 
	local_versions="$(echo $(find "${SDKMAN_CANDIDATES_DIR}/${candidate}" -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; 2> /dev/null) | sed -e "s/ /, /g")" 
	if [ ${#local_versions} -eq 0 ]
	then
		return 1
	fi
	remote_default_version="$(__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/candidates/default/${candidate}")" 
	if [ -z "$remote_default_version" ]
	then
		return 2
	fi
	if [ ! -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${remote_default_version}" ]
	then
		__sdkman_echo_yellow "${candidate} (local: ${local_versions}; default: ${remote_default_version})"
	fi
}
__sdkman_determine_version () {
	local candidate version folder
	candidate="$1" 
	version="$2" 
	folder="$3" 
	if [[ "$SDKMAN_AVAILABLE" == "false" && -n "$version" && -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}" ]]
	then
		VERSION="$version" 
	elif [[ "$SDKMAN_AVAILABLE" == "false" && -z "$version" && -L "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" ]]
	then
		VERSION=$(readlink "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" | sed "s!${SDKMAN_CANDIDATES_DIR}/${candidate}/!!g") 
	elif [[ "$SDKMAN_AVAILABLE" == "false" && -n "$version" ]]
	then
		__sdkman_echo_red "Stop! ${candidate} ${version} is not available while offline."
		return 1
	elif [[ "$SDKMAN_AVAILABLE" == "false" && -z "$version" ]]
	then
		__sdkman_echo_red "This command is not available while offline."
		return 1
	else
		if [[ -z "$version" ]]
		then
			version=$(__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/candidates/default/${candidate}") 
		fi
		local validation_url="${SDKMAN_CANDIDATES_API}/candidates/validate/${candidate}/${version}/${SDKMAN_PLATFORM}" 
		VERSION_VALID=$(__sdkman_secure_curl "$validation_url") 
		__sdkman_echo_debug "Validate $candidate $version for $SDKMAN_PLATFORM: $VERSION_VALID"
		__sdkman_echo_debug "Validation URL: $validation_url"
		if [[ "$VERSION_VALID" == 'valid' || ( "$VERSION_VALID" == 'invalid' && -n "$folder" ) ]]
		then
			VERSION="$version" 
		elif [[ "$VERSION_VALID" == 'invalid' && -L "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}" ]]
		then
			VERSION="$version" 
		elif [[ "$VERSION_VALID" == 'invalid' && -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}" ]]
		then
			VERSION="$version" 
		else
			if [[ -z "$version" ]]
			then
				version="\b" 
			fi
			echo ""
			__sdkman_echo_red "Stop! $candidate $version is not available. Possible causes:"
			__sdkman_echo_red " * $version is an invalid version"
			__sdkman_echo_red " * $candidate binaries are incompatible with your platform"
			__sdkman_echo_red " * $candidate has not been released yet"
			echo ""
			__sdkman_echo_yellow "Tip: see all available versions for your platform:"
			echo ""
			__sdkman_echo_yellow "  $ sdk list $candidate"
			return 1
		fi
	fi
}
__sdkman_display_offline_warning () {
	local healthcheck_status="$1" 
	if [[ -z "$healthcheck_status" && "$COMMAND" != "offline" && "$SDKMAN_OFFLINE_MODE" != "true" ]]
	then
		__sdkman_echo_red "==== INTERNET NOT REACHABLE! ==================================================="
		__sdkman_echo_red ""
		__sdkman_echo_red " Some functionality is disabled or only partially available."
		__sdkman_echo_red " If this persists, please enable the offline mode:"
		__sdkman_echo_red ""
		__sdkman_echo_red "   $ sdk offline"
		__sdkman_echo_red ""
		__sdkman_echo_red "================================================================================"
		echo ""
	fi
}
__sdkman_display_proxy_warning () {
	__sdkman_echo_red "==== PROXY DETECTED! ==========================================================="
	__sdkman_echo_red "Please ensure you have open internet access to continue."
	__sdkman_echo_red "================================================================================"
	echo ""
}
__sdkman_download () {
	local candidate version
	candidate="$1" 
	version="$2" 
	metadata_folder="${SDKMAN_DIR}/var/metadata" 
	mkdir -p "${metadata_folder}"
	local platform_parameter="$SDKMAN_PLATFORM" 
	local download_url="${SDKMAN_CANDIDATES_API}/broker/download/${candidate}/${version}/${platform_parameter}" 
	local base_name="${candidate}-${version}" 
	local tmp_headers_file="${SDKMAN_DIR}/tmp/${base_name}.headers.tmp" 
	local headers_file="${metadata_folder}/${base_name}.headers" 
	export local binary_input="${SDKMAN_DIR}/tmp/${base_name}.bin" 
	export local zip_output="${SDKMAN_DIR}/tmp/${base_name}.zip" 
	echo ""
	__sdkman_echo_no_colour "Downloading: ${candidate} ${version}"
	echo ""
	__sdkman_echo_no_colour "In progress..."
	echo ""
	__sdkman_secure_curl_download "${download_url}" --output "${binary_input}" --dump-header "${tmp_headers_file}"
	grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv} '^X-Sdkman' "${tmp_headers_file}" > "${headers_file}"
	__sdkman_echo_debug "Downloaded binary to: ${binary_input} (HTTP headers written to: ${headers_file})"
	local post_installation_hook="${SDKMAN_DIR}/tmp/hook_post_${candidate}_${version}.sh" 
	__sdkman_echo_debug "Get post-installation hook: ${SDKMAN_CANDIDATES_API}/hooks/post/${candidate}/${version}/${platform_parameter}"
	__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/hooks/post/${candidate}/${version}/${platform_parameter}" >| "$post_installation_hook"
	__sdkman_echo_debug "Copy remote post-installation hook: ${post_installation_hook}"
	source "$post_installation_hook"
	__sdkman_post_installation_hook || return 1
	__sdkman_echo_debug "Processed binary as: $zip_output"
	__sdkman_echo_debug "Completed post-installation hook..."
	__sdkman_validate_zip "${zip_output}" || return 1
	__sdkman_checksum_zip "${zip_output}" "${headers_file}" || return 1
	echo ""
}
__sdkman_echo () {
	if [[ "$sdkman_colour_enable" == 'false' ]]
	then
		echo -e "$2"
	else
		echo -e "\033[1;$1$2\033[0m"
	fi
}
__sdkman_echo_confirm () {
	if [[ "$sdkman_colour_enable" == 'false' ]]
	then
		echo -n "$1"
	else
		echo -e -n "\033[1;33m$1\033[0m"
	fi
}
__sdkman_echo_cyan () {
	__sdkman_echo "36m" "$1"
}
__sdkman_echo_debug () {
	if [[ "$sdkman_debug_mode" == 'true' ]]
	then
		echo "$1"
	fi
}
__sdkman_echo_green () {
	__sdkman_echo "32m" "$1"
}
__sdkman_echo_no_colour () {
	echo "$1"
}
__sdkman_echo_paged () {
	if [[ -n "$PAGER" ]]
	then
		echo "$@" | eval "$PAGER"
	elif command -v less >&/dev/null
	then
		echo "$@" | less
	else
		echo "$@"
	fi
}
__sdkman_echo_red () {
	__sdkman_echo "31m" "$1"
}
__sdkman_echo_yellow () {
	__sdkman_echo "33m" "$1"
}
__sdkman_env_each_candidate () {
	local -r filepath=$1 
	local -r func=$2 
	local normalised_line
	while IFS= read -r line || [[ -n "$line" ]]
	do
		normalised_line="$(__sdkman_normalise "$line")" 
		__sdkman_is_blank_line "$normalised_line" && continue
		if ! __sdkman_matches_candidate_format "$normalised_line"
		then
			__sdkman_echo_red "Invalid candidate format!"
			echo ""
			__sdkman_echo_yellow "Expected 'candidate=version' but found '$normalised_line'"
			return 1
		fi
		$func "${normalised_line%=*}" "${normalised_line#*=}" || return
	done < "$filepath"
}
__sdkman_env_restore_default_version () {
	local -r candidate="$1" 
	local candidate_dir default_version
	candidate_dir="${SDKMAN_CANDIDATES_DIR}/${candidate}/current" 
	if __sdkman_is_symlink $candidate_dir
	then
		default_version=$(basename $(readlink ${candidate_dir})) 
		__sdk_use "$candidate" "$default_version" > /dev/null && __sdkman_echo_yellow "Restored $candidate version to $default_version (default)"
	else
		__sdkman_echo_yellow "No default version of $candidate was found"
	fi
}
__sdkman_export_candidate_home () {
	local candidate_name="$1" 
	local candidate_dir="$2" 
	local candidate_home_var="$(echo ${candidate_name} | tr '[:lower:]' '[:upper:]')_HOME" 
	export $(echo "$candidate_home_var")="$candidate_dir"
}
__sdkman_install_candidate_version () {
	local candidate version
	candidate="$1" 
	version="$2" 
	__sdkman_download "$candidate" "$version" || return 1
	__sdkman_echo_green "Installing: ${candidate} ${version}"
	mkdir -p "${SDKMAN_CANDIDATES_DIR}/${candidate}"
	rm -rf "${SDKMAN_DIR}/tmp/out"
	unzip -oq "${SDKMAN_DIR}/tmp/${candidate}-${version}.zip" -d "${SDKMAN_DIR}/tmp/out"
	mv -f "$SDKMAN_DIR"/tmp/out/* "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}"
	__sdkman_echo_green "Done installing!"
	echo ""
}
__sdkman_install_local_version () {
	local candidate version folder version_length version_length_max
	version_length_max=15 
	candidate="$1" 
	version="$2" 
	folder="$3" 
	version_length=${#version} 
	__sdkman_echo_debug "Validating that actual version length ($version_length) does not exceed max ($version_length_max)"
	if [[ $version_length -gt $version_length_max ]]
	then
		__sdkman_echo_red "Invalid version! ${version} with length ${version_length} exceeds max of ${version_length_max}!"
		return 1
	fi
	mkdir -p "${SDKMAN_CANDIDATES_DIR}/${candidate}"
	if [[ "$folder" != /* ]]
	then
		folder="$(pwd)/$folder" 
	fi
	if [[ -d "$folder" ]]
	then
		__sdkman_echo_green "Linking ${candidate} ${version} to ${folder}"
		ln -s "$folder" "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}"
		__sdkman_echo_green "Done installing!"
	else
		__sdkman_echo_red "Invalid path! Refusing to link ${candidate} ${version} to ${folder}."
		return 1
	fi
	echo ""
}
__sdkman_is_blank_line () {
	[[ -z "$1" ]]
}
__sdkman_is_symlink () {
	[[ -h "$1" ]]
}
__sdkman_link_candidate_version () {
	local candidate version
	candidate="$1" 
	version="$2" 
	if [[ -L "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" || -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" ]]
	then
		rm -rf "${SDKMAN_CANDIDATES_DIR}/${candidate}/current"
	fi
	ln -s "${version}" "${SDKMAN_CANDIDATES_DIR}/${candidate}/current"
}
__sdkman_list_candidates () {
	if [[ "$SDKMAN_AVAILABLE" == "false" ]]
	then
		__sdkman_echo_red "This command is not available while offline."
	else
		__sdkman_echo_paged "$(__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/candidates/list")"
	fi
}
__sdkman_list_versions () {
	local candidate versions_csv
	candidate="$1" 
	versions_csv="$(__sdkman_build_version_csv "$candidate")" 
	__sdkman_determine_current_version "$candidate"
	if [[ "$SDKMAN_AVAILABLE" == "false" ]]
	then
		__sdkman_offline_list "$candidate" "$versions_csv"
	else
		__sdkman_echo_paged "$(__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/candidates/${candidate}/${SDKMAN_PLATFORM}/versions/list?current=${CURRENT}&installed=${versions_csv}")"
	fi
}
__sdkman_load_env () {
	local sdkmanrc="$1" 
	if [[ ! -f "$sdkmanrc" ]]
	then
		__sdkman_echo_red "Could not find $sdkmanrc in the current directory."
		echo ""
		__sdkman_echo_yellow "Run 'sdk env init' to create it."
		return 1
	fi
	__sdkman_env_each_candidate "$sdkmanrc" "__sdkman_check_and_use" && SDKMAN_ENV=$PWD 
}
__sdkman_matches_candidate_format () {
	[[ "$1" =~ ^[[:lower:]]+\=.+$ ]]
}
__sdkman_normalise () {
	local -r line_without_comments="${1/\#*/}" 
	echo "${line_without_comments//[[:space:]]/}"
}
__sdkman_offline_list () {
	local candidate versions_csv
	candidate="$1" 
	versions_csv="$2" 
	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"
	__sdkman_echo_yellow "Offline: only showing installed ${candidate} versions"
	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"
	local versions=($(echo ${versions_csv//,/ })) 
	for ((i = ${#versions} - 1; i >= 0; i--)) do
		if [[ -n "${versions[${i}]}" ]]
		then
			if [[ "${versions[${i}]}" == "$CURRENT" ]]
			then
				__sdkman_echo_no_colour " > ${versions[${i}]}"
			else
				__sdkman_echo_no_colour " * ${versions[${i}]}"
			fi
		fi
	done
	if [[ -z "${versions[@]}" ]]
	then
		__sdkman_echo_yellow "   None installed!"
	fi
	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"
	__sdkman_echo_no_colour "* - installed                                                                   "
	__sdkman_echo_no_colour "> - currently in use                                                            "
	__sdkman_echo_no_colour "--------------------------------------------------------------------------------"
}
__sdkman_path_contains () {
	local candidate exists
	candidate="$1" 
	exists="$(echo "$PATH" | grep "$candidate")" 
	if [[ -n "$exists" ]]
	then
		echo 'true'
	else
		echo 'false'
	fi
}
__sdkman_prepend_candidate_to_path () {
	local candidate_dir candidate_bin_dir
	candidate_dir="$1" 
	candidate_bin_dir=$(__sdkman_determine_candidate_bin_dir "$candidate_dir") 
	echo "$PATH" | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv} -q "$candidate_dir" || PATH="${candidate_bin_dir}:${PATH}" 
	unset CANDIDATE_BIN_DIR
}
__sdkman_secure_curl () {
	if [[ "${sdkman_insecure_ssl}" == 'true' ]]
	then
		curl --insecure --silent --location "$1"
	else
		curl --silent --location "$1"
	fi
}
__sdkman_secure_curl_download () {
	local curl_params
	curl_params=('--progress-bar' '--location') 
	if [[ "${sdkman_debug_mode}" == 'true' ]]
	then
		curl_params+=('--verbose') 
	fi
	if [[ "${sdkman_curl_continue}" == 'true' ]]
	then
		curl_params+=('-C' '-') 
	fi
	if [[ -n "${sdkman_curl_retry_max_time}" ]]
	then
		curl_params+=('--retry-max-time' "${sdkman_curl_retry_max_time}") 
	fi
	if [[ -n "${sdkman_curl_retry}" ]]
	then
		curl_params+=('--retry' "${sdkman_curl_retry}") 
	fi
	if [[ "${sdkman_insecure_ssl}" == 'true' ]]
	then
		curl_params+=('--insecure') 
	fi
	curl "${curl_params[@]}" "${@}"
}
__sdkman_secure_curl_with_timeouts () {
	if [[ "${sdkman_insecure_ssl}" == 'true' ]]
	then
		curl --insecure --silent --location --connect-timeout ${sdkman_curl_connect_timeout} --max-time ${sdkman_curl_max_time} "$1"
	else
		curl --silent --location --connect-timeout ${sdkman_curl_connect_timeout} --max-time ${sdkman_curl_max_time} "$1"
	fi
}
__sdkman_set_availability () {
	local healthcheck_status="$1" 
	local detect_html="$(echo "$healthcheck_status" | tr '[:upper:]' '[:lower:]' | grep 'html')" 
	if [[ -z "$healthcheck_status" ]]
	then
		SDKMAN_AVAILABLE="false" 
		__sdkman_display_offline_warning "$healthcheck_status"
	elif [[ -n "$detect_html" ]]
	then
		SDKMAN_AVAILABLE="false" 
		__sdkman_display_proxy_warning
	else
		SDKMAN_AVAILABLE="true" 
	fi
}
__sdkman_set_candidate_home () {
	local candidate version upper_candidate
	candidate="$1" 
	version="$2" 
	upper_candidate=$(echo "$candidate" | tr '[:lower:]' '[:upper:]') 
	export "${upper_candidate}_HOME"="${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}"
}
__sdkman_setup_env () {
	local sdkmanrc="$1" 
	if [[ ! -f "$sdkmanrc" ]]
	then
		__sdkman_echo_red "Could not find $sdkmanrc in the current directory."
		echo ""
		__sdkman_echo_yellow "Run 'sdk env init' to create it."
		return 1
	fi
	sdkman_auto_answer="true" USE="n" __sdkman_env_each_candidate "$sdkmanrc" "__sdk_install"
	__sdkman_load_env "$sdkmanrc"
}
__sdkman_update_service_availability () {
	local healthcheck_status=$(__sdkman_determine_healthcheck_status) 
	__sdkman_set_availability "$healthcheck_status"
}
__sdkman_validate_zip () {
	local zip_archive zip_ok
	zip_archive="$1" 
	zip_ok=$(unzip -t "$zip_archive" | grep 'No errors detected in compressed data') 
	if [ -z "$zip_ok" ]
	then
		rm -f "$zip_archive"
		echo ""
		__sdkman_echo_red "Stop! The archive was corrupt and has been removed! Please try installing again."
		return 1
	fi
}
__setup_lang_fallback () {
	if [[ -z "${LANG:-}" ]]
	then
		LANG="$(
      {
        locale -a | __rvm_grep "^en_US.utf8" ||
        locale -a | __rvm_grep "^en_US" ||
        locale -a | __rvm_grep "^en" ||
        locale -a
      } 2>/dev/null | \command \head -n 1
    )" 
		: LANG=${LANG:=en_US.utf-8}
		export LANG
		rvm_warn "\$LANG was empty, setting up LANG=$LANG, if it fails again try setting LANG to something sane and try again."
	fi
}
__variables_definition () {
	\typeset -a __variables_list __array_list
	\typeset __method
	__method="$1" 
	__variables_list=(rvm_head_flag rvm_ruby_selected_flag rvm_user_install_flag rvm_path_flag rvm_cron_flag rvm_static_flag rvm_default_flag rvm_loaded_flag rvm_llvm_flag rvm_skip_autoreconf_flag rvm_dynamic_extensions_flag rvm_18_flag rvm_19_flag rvm_20_flag rvm_21_flag rvm_force_autoconf_flag rvm_dump_environment_flag rvm_curl_flags rvm_rubygems_version rvm_verbose_flag rvm_debug_flag rvm_trace_flag __array_start rvm_skip_pristine_flag rvm_create_flag rvm_remove_flag rvm_movable_flag rvm_archive_flag rvm_gemdir_flag rvm_reload_flag rvm_auto_reload_flag rvm_disable_binary_flag rvm_ignore_gemsets_flag rvm_skip_gemsets_flag rvm_install_on_use_flag rvm_remote_flag rvm_verify_downloads_flag rvm_skip_openssl_flag rvm_gems_cache_path rvm_gems_path rvm_man_path rvm_ruby_gem_path rvm_ruby_log_path rvm_gems_cache_path rvm_archives_path rvm_docs_path rvm_environments_path rvm_examples_path rvm_gems_path rvm_gemsets_path rvm_help_path rvm_hooks_path rvm_lib_path rvm_log_path rvm_patches_path rvm_repos_path rvm_rubies_path rvm_scripts_path rvm_src_path rvm_tmp_path rvm_user_path rvm_usr_path rvm_wrappers_path rvm_stored_errexit rvm_ruby_strings rvm_ruby_binary rvm_ruby_gem_home rvm_ruby_home rvm_ruby_interpreter rvm_ruby_irbrc rvm_ruby_major_version rvm_ruby_minor_version rvm_ruby_package_name rvm_ruby_patch_level rvm_ruby_release_version rvm_ruby_repo_url rvm_ruby_repo_branch rvm_ruby_revision rvm_ruby_tag rvm_ruby_sha rvm_ruby_repo_tag rvm_ruby_version rvm_ruby_package_file rvm_ruby_name rvm_ruby_name rvm_ruby_args rvm_ruby_user_tag rvm_ruby_patch detected_rvm_ruby_name __rvm_env_loaded next_token rvm_error_message rvm_gemset_name rvm_parse_break rvm_token rvm_action rvm_export_args rvm_gemset_separator rvm_expanding_aliases rvm_tar_command rvm_tar_options rvm_patch_original_pwd rvm_project_rvmrc rvm_archive_extension rvm_autoinstall_bundler_flag rvm_codesign_identity rvm_expected_gemset_name rvm_without_gems rvm_with_gems rvm_with_default_gems rvm_ignore_dotfiles_flag rvm_fuzzy_flag rvm_autolibs_flag rvm_autolibs_flag_number rvm_autolibs_flag_runner rvm_quiet_curl_flag rvm_max_time_flag rvm_error_clr rvm_warn_clr rvm_debug_clr rvm_notify_clr rvm_code_clr rvm_comment_clr rvm_reset_clr rvm_error_color rvm_warn_color rvm_debug_color rvm_notify_color rvm_code_color rvm_comment_color rvm_reset_color rvm_log_timestamp rvm_log_filesystem rvm_log_namelen rvm_show_log_lines_on_error) 
	__array_list=(rvm_patch_names rvm_ree_options rvm_autoconf_flags rvm_architectures) 
	case "${__method}" in
		(export) true ;;
		(unset) unset "${__array_list[@]}" || true ;;
		(*) rvm_error "Unknown action given to __variables_definition: ${__method}"
			return 1 ;;
	esac
	${__method} "${__variables_list[@]}" || true
	if [[ -n "${BASH_VERSION:-}" ]]
	then
		export -fn __rvm_select_version_variables __rvm_ruby_string_parse_ __rvm_rm_rf_verbose __rvm_parse_args __rvm_ruby_string_find __rvm_file_load_env __rvm_remove_without_gems 2> /dev/null || true
	fi
}
__zsh_like_cd () {
	\typeset __zsh_like_cd_hook
	if builtin "$@"
	then
		for __zsh_like_cd_hook in chpwd "${chpwd_functions[@]}"
		do
			if \typeset -f "$__zsh_like_cd_hook" > /dev/null 2>&1
			then
				"$__zsh_like_cd_hook" || break
			fi
		done
		true
	else
		return $?
	fi
}
_a2ps () {
	# undefined
	builtin autoload -XUz
}
_a2utils () {
	# undefined
	builtin autoload -XUz
}
_aap () {
	# undefined
	builtin autoload -XUz
}
_abcde () {
	# undefined
	builtin autoload -XUz
}
_absolute_command_paths () {
	# undefined
	builtin autoload -XUz
}
_ack () {
	# undefined
	builtin autoload -XUz
}
_acpi () {
	# undefined
	builtin autoload -XUz
}
_acpitool () {
	# undefined
	builtin autoload -XUz
}
_acroread () {
	# undefined
	builtin autoload -XUz
}
_adb () {
	# undefined
	builtin autoload -XUz
}
_add-zle-hook-widget () {
	# undefined
	builtin autoload -XUz
}
_add-zsh-hook () {
	# undefined
	builtin autoload -XUz
}
_alias () {
	# undefined
	builtin autoload -XUz
}
_aliases () {
	# undefined
	builtin autoload -XUz
}
_all_labels () {
	# undefined
	builtin autoload -XUz
}
_all_matches () {
	# undefined
	builtin autoload -XUz
}
_alsa-utils () {
	# undefined
	builtin autoload -XUz
}
_alternative () {
	# undefined
	builtin autoload -XUz
}
_analyseplugin () {
	# undefined
	builtin autoload -XUz
}
_ansible () {
	# undefined
	builtin autoload -XUz
}
_ant () {
	# undefined
	builtin autoload -XUz
}
_antiword () {
	# undefined
	builtin autoload -XUz
}
_apachectl () {
	# undefined
	builtin autoload -XUz
}
_apm () {
	# undefined
	builtin autoload -XUz
}
_approximate () {
	# undefined
	builtin autoload -XUz
}
_apt () {
	# undefined
	builtin autoload -XUz
}
_apt-file () {
	# undefined
	builtin autoload -XUz
}
_apt-move () {
	# undefined
	builtin autoload -XUz
}
_apt-show-versions () {
	# undefined
	builtin autoload -XUz
}
_aptitude () {
	# undefined
	builtin autoload -XUz
}
_arch_archives () {
	# undefined
	builtin autoload -XUz
}
_arch_namespace () {
	# undefined
	builtin autoload -XUz
}
_arg_compile () {
	# undefined
	builtin autoload -XUz
}
_arguments () {
	# undefined
	builtin autoload -XUz
}
_arp () {
	# undefined
	builtin autoload -XUz
}
_arping () {
	# undefined
	builtin autoload -XUz
}
_arrays () {
	# undefined
	builtin autoload -XUz
}
_asciidoctor () {
	# undefined
	builtin autoload -XUz
}
_asciinema () {
	# undefined
	builtin autoload -XUz
}
_assign () {
	# undefined
	builtin autoload -XUz
}
_at () {
	# undefined
	builtin autoload -XUz
}
_attr () {
	# undefined
	builtin autoload -XUz
}
_augeas () {
	# undefined
	builtin autoload -XUz
}
_auto-apt () {
	# undefined
	builtin autoload -XUz
}
_autocd () {
	# undefined
	builtin autoload -XUz
}
_avahi () {
	# undefined
	builtin autoload -XUz
}
_awk () {
	# undefined
	builtin autoload -XUz
}
_aws () {
	# undefined
	builtin autoload -XUz
}
_axi-cache () {
	# undefined
	builtin autoload -XUz
}
_base64 () {
	# undefined
	builtin autoload -XUz
}
_basename () {
	# undefined
	builtin autoload -XUz
}
_basenc () {
	# undefined
	builtin autoload -XUz
}
_bash () {
	# undefined
	builtin autoload -XUz
}
_bash_complete () {
	local ret=1 
	local -a suf matches
	local -x COMP_POINT COMP_CWORD
	local -a COMP_WORDS COMPREPLY BASH_VERSINFO
	local -x COMP_LINE="$words" 
	local -A savejobstates savejobtexts
	(( COMP_POINT = 1 + ${#${(j. .)words[1,CURRENT-1]}} + $#QIPREFIX + $#IPREFIX + $#PREFIX ))
	(( COMP_CWORD = CURRENT - 1))
	COMP_WORDS=("${words[@]}") 
	BASH_VERSINFO=(2 05b 0 1 release) 
	savejobstates=(${(kv)jobstates}) 
	savejobtexts=(${(kv)jobtexts}) 
	[[ ${argv[${argv[(I)nospace]:-0}-1]} = -o ]] && suf=(-S '') 
	matches=(${(f)"$(compgen $@ -- ${words[CURRENT]})"}) 
	if [[ -n $matches ]]
	then
		if [[ ${argv[${argv[(I)filenames]:-0}-1]} = -o ]]
		then
			compset -P '*/' && matches=(${matches##*/}) 
			compset -S '/*' && matches=(${matches%%/*}) 
			compadd -f "${suf[@]}" -a matches && ret=0 
		else
			compadd "${suf[@]}" - "${(@)${(Q@)matches}:#*\ }" && ret=0 
			compadd -S ' ' - ${${(M)${(Q)matches}:#*\ }% } && ret=0 
		fi
	fi
	if (( ret ))
	then
		if [[ ${argv[${argv[(I)default]:-0}-1]} = -o ]]
		then
			_default "${suf[@]}" && ret=0 
		elif [[ ${argv[${argv[(I)dirnames]:-0}-1]} = -o ]]
		then
			_directories "${suf[@]}" && ret=0 
		fi
	fi
	return ret
}
_bash_completions () {
	# undefined
	builtin autoload -XUz
}
_baudrates () {
	# undefined
	builtin autoload -XUz
}
_baz () {
	# undefined
	builtin autoload -XUz
}
_be_name () {
	# undefined
	builtin autoload -XUz
}
_beadm () {
	# undefined
	builtin autoload -XUz
}
_beep () {
	# undefined
	builtin autoload -XUz
}
_bibtex () {
	# undefined
	builtin autoload -XUz
}
_bind_addresses () {
	# undefined
	builtin autoload -XUz
}
_bindkey () {
	# undefined
	builtin autoload -XUz
}
_bison () {
	# undefined
	builtin autoload -XUz
}
_bittorrent () {
	# undefined
	builtin autoload -XUz
}
_bogofilter () {
	# undefined
	builtin autoload -XUz
}
_bpf_filters () {
	# undefined
	builtin autoload -XUz
}
_bpython () {
	# undefined
	builtin autoload -XUz
}
_brace_parameter () {
	# undefined
	builtin autoload -XUz
}
_brctl () {
	# undefined
	builtin autoload -XUz
}
_brew () {
	# undefined
	builtin autoload -XUz
}
_bsd_disks () {
	# undefined
	builtin autoload -XUz
}
_bsd_pkg () {
	# undefined
	builtin autoload -XUz
}
_bsdconfig () {
	# undefined
	builtin autoload -XUz
}
_bsdinstall () {
	# undefined
	builtin autoload -XUz
}
_btrfs () {
	# undefined
	builtin autoload -XUz
}
_bts () {
	# undefined
	builtin autoload -XUz
}
_bug () {
	# undefined
	builtin autoload -XUz
}
_builtin () {
	# undefined
	builtin autoload -XUz
}
_bun () {
	zstyle ':completion:*:*:bun:*' group-name ''
	zstyle ':completion:*:*:bun-grouped:*' group-name ''
	zstyle ':completion:*:*:bun::descriptions' format '%F{green}-- %d --%f'
	zstyle ':completion:*:*:bun-grouped:*' format '%F{green}-- %d --%f'
	local program=bun 
	typeset -A opt_args
	local curcontext="$curcontext" state line context 
	_arguments -s '1: :->cmd' '*: :->args' && ret=0 
	case $state in
		(cmd) local -a scripts_list
			IFS=$'\n' scripts_list=($(SHELL=zsh bun getcompletes i)) 
			scripts="scripts:scripts:((${scripts_list//:/\\\\:}))" 
			IFS=$'\n' files_list=($(SHELL=zsh bun getcompletes j)) 
			main_commands=('run\:"Run JavaScript with Bun, a package.json script, or a bin" ' 'test\:"Run unit tests with Bun" ' 'x\:"Install and execute a package bin (bunx)" ' 'repl\:"Start a REPL session with Bun" ' 'init\:"Start an empty Bun project from a blank template" ' 'create\:"Create a new project from a template (bun c)" ' 'install\:"Install dependencies for a package.json (bun i)" ' 'add\:"Add a dependency to package.json (bun a)" ' 'remove\:"Remove a dependency from package.json (bun rm)" ' 'update\:"Update outdated dependencies & save to package.json" ' 'outdated\:"Display the latest versions of outdated dependencies" ' 'link\:"Link an npm package globally" ' 'unlink\:"Globally unlink an npm package" ' 'pm\:"More commands for managing packages" ' 'build\:"Bundle TypeScript & JavaScript into a single file" ' 'upgrade\:"Get the latest version of bun" ' 'help\:"Show all supported flags and commands" ') 
			main_commands=($main_commands) 
			_alternative "$scripts" "args:command:(($main_commands))" "files:files:(($files_list))" ;;
		(args) case $line[1] in
				(add | a) _bun_add_completion ;;
				(unlink) _bun_unlink_completion ;;
				(link) _bun_link_completion ;;
				(bun) _bun_bun_completion ;;
				(init) _bun_init_completion ;;
				(create | c) _bun_create_completion ;;
				(x) _arguments -s -C '1: :->cmd' '2: :->cmd2' '*: :->args' && ret=0  ;;
				(pm) _bun_pm_completion ;;
				(install | i) _bun_install_completion ;;
				(remove | rm) _bun_remove_completion ;;
				(run) _bun_run_completion ;;
				(upgrade) _bun_upgrade_completion ;;
				(repl) _bun_repl_completion ;;
				(build) _bun_build_completion ;;
				(update) _bun_update_completion ;;
				(outdated) _bun_outdated_completion ;;
				('test') _bun_test_completion ;;
				(help) _arguments -s -C '1: :->cmd' '2: :->cmd2' '*: :->args' && ret=0 
					case $state in
						(cmd2) curcontext="${curcontext%:*:*}:bun-grouped" 
							_alternative "args:command:(($main_commands))" ;;
						(args) case $line[2] in
								(add) _bun_add_completion ;;
								(unlink) _bun_unlink_completion ;;
								(link) _bun_link_completion ;;
								(bun) _bun_bun_completion ;;
								(init) _bun_init_completion ;;
								(create) _bun_create_completion ;;
								(x) _arguments -s -C '1: :->cmd' '2: :->cmd2' '*: :->args' && ret=0  ;;
								(pm) _bun_pm_completion ;;
								(install) _bun_install_completion ;;
								(remove) _bun_remove_completion ;;
								(run) _bun_run_completion ;;
								(upgrade) _bun_upgrade_completion ;;
								(repl) _bun_repl_completion ;;
								(build) _bun_build_completion ;;
								(update) _bun_update_completion ;;
								(outdated) _bun_outdated_completion ;;
								('test') _bun_test_completion ;;
							esac ;;
					esac ;;
			esac ;;
	esac
}
_bun_add_completion () {
	_arguments -s -C '1: :->cmd1' '*: :->package' '--config[Load config(bunfig.toml)]: :->config' '-c[Load config(bunfig.toml)]: :->config' '--yarn[Write a yarn.lock file (yarn v1)]' '-y[Write a yarn.lock file (yarn v1)]' '--production[Don'"'"'t install devDependencies]' '-p[Don'"'"'t install devDependencies]' '--no-save[Don'"'"'t save a lockfile]' '--save[Save to package.json]' '--dry-run[Don'"'"'t install anything]' '--frozen-lockfile[Disallow changes to lockfile]' '--force[Always request the latest versions from the registry & reinstall all dependencies]' '-f[Always request the latest versions from the registry & reinstall all dependencies]' '--cache-dir[Store & load cached data from a specific directory path]:cache-dir' '--no-cache[Ignore manifest cache entirely]' '--silent[Don'"'"'t log anything]' '--verbose[Excessively verbose logging]' '--no-progress[Disable the progress bar]' '--no-summary[Don'"'"'t print a summary]' '--no-verify[Skip verifying integrity of newly downloaded packages]' '--ignore-scripts[Skip lifecycle scripts in the package.json (dependency scripts are never run)]' '--global[Add a package globally]' '-g[Add a package globally]' '--cwd[Set a specific cwd]:cwd' '--backend[Platform-specific optimizations for installing dependencies]:backend:("copyfile" "hardlink" "symlink")' '--link-native-bins[Link "bin" from a matching platform-specific dependency instead. Default: esbuild, turbo]:link-native-bins' '--help[Print this help menu]' '--dev[Add dependence to "devDependencies]' '-d[Add dependence to "devDependencies]' '-D[]' '--development[]' '--optional[Add dependency to "optionalDependencies]' '--peer[Add dependency to "peerDependencies]' '--exact[Add the exact version instead of the ^range]' && ret=0 
	case $state in
		(config) _bun_list_bunfig_toml ;;
		(package) _bun_add_param_package_completion ;;
	esac
}
_bun_add_param_package_completion () {
	IFS=$'\n' inexact=($(history -n bun | grep -E "^bun add " | cut -c 9- | uniq)) 
	IFS=$'\n' exact=($($inexact | grep -E "^$words[$CURRENT]")) 
	IFS=$'\n' packages=($(SHELL=zsh bun getcompletes a $words[$CURRENT])) 
	to_print=$inexact 
	if [ ! -z "$exact" -a "$exact" != " " ]
	then
		to_print=$exact 
	fi
	if [ ! -z "$to_print" -a "$to_print" != " " ]
	then
		if [ ! -z "$packages" -a "$packages" != " " ]
		then
			_describe -1 -t to_print 'History' to_print
			_describe -1 -t packages "Popular" packages
			return
		fi
		_describe -1 -t to_print 'History' to_print
		return
	fi
	if [ ! -z "$packages" -a "$packages" != " " ]
	then
		_describe -1 -t packages "Popular" packages
		return
	fi
}
_bun_build_completion () {
	_arguments -s -C '1: :->cmd' '*: :->file' '--outfile[Write the output to a specific file (default: stdout)]:outfile' '--outdir[Write the output to a directory (required for splitting)]:outdir' '--minify[Enable all minification flags]' '--minify-whitespace[Remove unneeded whitespace]' '--minify-syntax[Transform code to use less syntax]' '--minify-identifiers[Shorten variable names]' '--sourcemap[Generate sourcemaps]: :->sourcemap' '--target[The intended execution environment for the bundle. "browser", "bun" or "node"]: :->target' '--splitting[Whether to enable code splitting (requires --outdir)]' '--compile[generating a standalone binary from a TypeScript or JavaScript file]' '--format[Specifies the module format to be used in the generated bundles]: :->format' && ret=0 
	case $state in
		(file) _files ;;
		(target) _alternative 'args:cmd3:((browser bun node))' ;;
		(sourcemap) _alternative 'args:cmd3:((none external inline))' ;;
		(format) _alternative 'args:cmd3:((esm cjs iife))' ;;
	esac
}
_bun_bun_completion () {
	_arguments -s -C '1: :->cmd' '*: :->file' '--version[Show version and exit]' '-V[Show version and exit]' '--cwd[Change directory]:cwd' '--help[Show command help]' '-h[Show command help]' '--use[Use a framework, e.g. "next"]:use' && ret=0 
	case $state in
		(file) _files ;;
	esac
}
_bun_create_completion () {
	_arguments -s -C '1: :->cmd' '2: :->cmd2' '*: :->args' && ret=0 
	case $state in
		(cmd2) _alternative 'args:create:((next-app\:"Next.js app" react-app\:"React app"))' ;;
		(args) case $line[2] in
				(next) pmargs=('1: :->cmd' '2: :->cmd2' '3: :->file' '--force[Overwrite existing files]' '--no-install[Don'"'"'t install node_modules]' '--no-git[Don'"'"'t create a git repository]' '--verbose[verbose]' '--no-package-json[Disable package.json transforms]' '--open[On finish, start bun & open in-browser]') 
					_arguments -s -C $pmargs && ret=0 
					case $state in
						(file) _files ;;
					esac ;;
				(react) _arguments -s -C $pmargs && ret=0 
					case $state in
						(file) _files ;;
					esac ;;
				(*) _arguments -s -C $pmargs && ret=0 
					case $state in
						(file) _files ;;
					esac ;;
			esac ;;
	esac
}
_bun_init_completion () {
	_arguments -s -C '1: :->cmd' '-y[Answer yes to all prompts]:' '--yes[Answer yes to all prompts]:' && ret=0 
}
_bun_install_completion () {
	_arguments -s -C '1: :->cmd1' '--config[Load config(bunfig.toml)]: :->config' '-c[Load config(bunfig.toml)]: :->config' '--yarn[Write a yarn.lock file (yarn v1)]' '-y[Write a yarn.lock file (yarn v1)]' '--production[Don'"'"'t install devDependencies]' '-p[Don'"'"'t install devDependencies]' '--no-save[Don'"'"'t save a lockfile]' '--save[Save to package.json]' '--dry-run[Don'"'"'t install anything]' '--frozen-lockfile[Disallow changes to lockfile]' '--force[Always request the latest versions from the registry & reinstall all dependencies]' '-f[Always request the latest versions from the registry & reinstall all dependencies]' '--cache-dir[Store & load cached data from a specific directory path]:cache-dir' '--no-cache[Ignore manifest cache entirely]' '--silent[Don'"'"'t log anything]' '--verbose[Excessively verbose logging]' '--no-progress[Disable the progress bar]' '--no-summary[Don'"'"'t print a summary]' '--no-verify[Skip verifying integrity of newly downloaded packages]' '--ignore-scripts[Skip lifecycle scripts in the package.json (dependency scripts are never run)]' '--global[Add a package globally]' '-g[Add a package globally]' '--cwd[Set a specific cwd]:cwd' '--backend[Platform-specific optimizations for installing dependencies]:backend:("copyfile" "hardlink" "symlink")' '--link-native-bins[Link "bin" from a matching platform-specific dependency instead. Default: esbuild, turbo]:link-native-bins' '--help[Print this help menu]' '--dev[Add dependence to "devDependencies]' '-d[Add dependence to "devDependencies]' '--development[]' '-D[]' '--optional[Add dependency to "optionalDependencies]' '--peer[Add dependency to "peerDependencies]' '--exact[Add the exact version instead of the ^range]' && ret=0 
	case $state in
		(config) _bun_list_bunfig_toml ;;
	esac
}
_bun_link_completion () {
	_arguments -s -C '1: :->cmd1' '*: :->package' '--config[Load config(bunfig.toml)]: :->config' '-c[Load config(bunfig.toml)]: :->config' '--yarn[Write a yarn.lock file (yarn v1)]' '-y[Write a yarn.lock file (yarn v1)]' '--production[Don'"'"'t install devDependencies]' '-p[Don'"'"'t install devDependencies]' '--no-save[Don'"'"'t save a lockfile]' '--save[Save to package.json]' '--dry-run[Don'"'"'t install anything]' '--frozen-lockfile[Disallow changes to lockfile]' '--force[Always request the latest versions from the registry & reinstall all dependencies]' '-f[Always request the latest versions from the registry & reinstall all dependencies]' '--cache-dir[Store & load cached data from a specific directory path]:cache-dir' '--no-cache[Ignore manifest cache entirely]' '--silent[Don'"'"'t log anything]' '--verbose[Excessively verbose logging]' '--no-progress[Disable the progress bar]' '--no-summary[Don'"'"'t print a summary]' '--no-verify[Skip verifying integrity of newly downloaded packages]' '--ignore-scripts[Skip lifecycle scripts in the package.json (dependency scripts are never run)]' '--global[Add a package globally]' '-g[Add a package globally]' '--cwd[Set a specific cwd]:cwd' '--backend[Platform-specific optimizations for installing dependencies]:backend:("copyfile" "hardlink" "symlink")' '--link-native-bins[Link "bin" from a matching platform-specific dependency instead. Default: esbuild, turbo]:link-native-bins' '--help[Print this help menu]' && ret=0 
	case $state in
		(config) _bun_list_bunfig_toml ;;
		(package) _bun_link_param_package_completion ;;
	esac
}
_bun_link_param_package_completion () {
	install_env=$BUN_INSTALL 
	install_dir=${(P)install_env:-$HOME/.bun} 
	global_node_modules=$install_dir/install/global/node_modules 
	local -a packages_full_path=(${global_node_modules}/*(N)) 
	packages=$(echo $packages_full_path | tr ' ' '\n' | xargs  basename) 
	_alternative "dirs:directory:(($packages))"
}
_bun_list_bunfig_toml () {
	_files
}
_bun_outdated_completion () {
	_arguments -s -C '--cwd[Set a specific cwd]:cwd' '--verbose[Excessively verbose logging]' '--no-progress[Disable the progress bar]' '--help[Print this help menu]' && ret=0 
	case $state in
		(config) _bun_list_bunfig_toml ;;
	esac
}
_bun_pm_completion () {
	_arguments -s -C '1: :->cmd' '2: :->cmd2' '*: :->args' && ret=0 
	case $state in
		(cmd2) sub_commands=('bin\:"print the path to bin folder" ' 'ls\:"list the dependency tree according to the current lockfile" ' 'hash\:"generate & print the hash of the current lockfile" ' 'hash-string\:"print the string used to hash the lockfile" ' 'hash-print\:"print the hash stored in the current lockfile" ' 'cache\:"print the path to the cache folder" ' 'version\:"bump the version in package.json and create a git tag" ') 
			_alternative "args:cmd3:(($sub_commands))" ;;
		(args) case $line[2] in
				(cache) _arguments -s -C '1: :->cmd' '2: :->cmd2' ':::(rm)' && ret=0  ;;
				(bin) pmargs=("-g[print the global path to bin folder]") 
					_arguments -s -C '1: :->cmd' '2: :->cmd2' $pmargs && ret=0  ;;
				(ls) pmargs=("--all[list the entire dependency tree according to the current lockfile]") 
					_arguments -s -C '1: :->cmd' '2: :->cmd2' $pmargs && ret=0  ;;
				(version) version_args=("patch[increment patch version]" "minor[increment minor version]" "major[increment major version]" "prepatch[increment patch version and add pre-release]" "preminor[increment minor version and add pre-release]" "premajor[increment major version and add pre-release]" "prerelease[increment pre-release version]" "from-git[use version from latest git tag]") 
					pmargs=("--no-git-tag-version[don't create a git commit and tag]" "--allow-same-version[allow bumping to the same version]" "-m[use the given message for the commit]:message" "--message[use the given message for the commit]:message" "--preid[identifier to prefix pre-release versions]:preid") 
					_arguments -s -C '1: :->cmd' '2: :->cmd2' '3: :->increment' $pmargs && ret=0 
					case $state in
						(increment) _alternative "args:increment:(($version_args))" ;;
					esac ;;
			esac ;;
	esac
}
_bun_remove_completion () {
	_arguments -s -C '1: :->cmd1' '*: :->package' '--config[Load config(bunfig.toml)]: :->config' '-c[Load config(bunfig.toml)]: :->config' '--yarn[Write a yarn.lock file (yarn v1)]' '-y[Write a yarn.lock file (yarn v1)]' '--production[Don'"'"'t install devDependencies]' '-p[Don'"'"'t install devDependencies]' '--no-save[Don'"'"'t save a lockfile]' '--save[Save to package.json]' '--dry-run[Don'"'"'t install anything]' '--frozen-lockfile[Disallow changes to lockfile]' '--force[Always request the latest versions from the registry & reinstall all dependencies]' '-f[Always request the latest versions from the registry & reinstall all dependencies]' '--cache-dir[Store & load cached data from a specific directory path]:cache-dir' '--no-cache[Ignore manifest cache entirely]' '--silent[Don'"'"'t log anything]' '--verbose[Excessively verbose logging]' '--no-progress[Disable the progress bar]' '--no-summary[Don'"'"'t print a summary]' '--no-verify[Skip verifying integrity of newly downloaded packages]' '--ignore-scripts[Skip lifecycle scripts in the package.json (dependency scripts are never run)]' '--global[Add a package globally]' '-g[Add a package globally]' '--cwd[Set a specific cwd]:cwd' '--backend[Platform-specific optimizations for installing dependencies]:backend:("copyfile" "hardlink" "symlink")' '--link-native-bins[Link "bin" from a matching platform-specific dependency instead. Default: esbuild, turbo]:link-native-bins' '--help[Print this help menu]' && ret=0 
	case $state in
		(config) _bun_list_bunfig_toml ;;
		(package) _bun_remove_param_package_completion ;;
	esac
}
_bun_remove_param_package_completion () {
	if ! command -v jq &> /dev/null
	then
		return
	fi
	if [ -f "package.json" ]
	then
		local dependencies=$(jq -r '.dependencies | keys[]' package.json) 
		local dev_dependencies=$(jq -r '.devDependencies | keys[]' package.json) 
		_alternative "deps:dependency:(($dependencies))"
		_alternative "deps:dependency:(($dev_dependencies))"
	fi
}
_bun_repl_completion () {
	_arguments -s -C '1: :->cmd' '--help[Print this help menu]' '-h[Print this help menu]' '(-p --print)--eval[Evaluate argument as a script, then exit]:script' '(-p --print)-e[Evaluate argument as a script, then exit]:script' '(-e --eval)--print[Evaluate argument as a script, print the result, then exit]:script' '(-e --eval)-p[Evaluate argument as a script, print the result, then exit]:script' '--preload[Import a module before other modules are loaded]:preload' '-r[Import a module before other modules are loaded]:preload' '--smol[Use less memory, but run garbage collection more often]' '--config[Specify path to Bun config file]: :->config' '-c[Specify path to Bun config file]: :->config' '--cwd[Absolute path to resolve files & entry points from]:cwd' '--env-file[Load environment variables from the specified file(s)]:env-file' '--no-env-file[Disable automatic loading of .env files]' && ret=0 
	case $state in
		(config) _bun_list_bunfig_toml ;;
	esac
}
_bun_run_completion () {
	_arguments -s -C '1: :->cmd' '2: :->script' '*: :->other' '--help[Display this help and exit]' '-h[Display this help and exit]' '--bun[Force a script or package to use Bun'"'"'s runtime instead of Node.js (via symlinking node)]' '-b[Force a script or package to use Bun'"'"'s runtime instead of Node.js (via symlinking node)]' '--cwd[Absolute path to resolve files & entry points from. This just changes the process cwd]:cwd' '--config[Config file to load bun from (e.g. -c bunfig.toml]: :->config' '-c[Config file to load bun from (e.g. -c bunfig.toml]: :->config' '--env-file[Load environment variables from the specified file(s)]:env-file' '--extension-order[Defaults to: .tsx,.ts,.jsx,.js,.json]:extension-order' '--jsx-factory[Changes the function called when compiling JSX elements using the classic JSX runtime]:jsx-factory' '--jsx-fragment[Changes the function called when compiling JSX fragments]:jsx-fragment' '--jsx-import-source[Declares the module specifier to be used for importing the jsx and jsxs factory functions. Default: "react"]:jsx-import-source' '--jsx-runtime["automatic" (default) or "classic"]: :->jsx-runtime' '--preload[Import a module before other modules are loaded]:preload' '-r[Import a module before other modules are loaded]:preload' '--main-fields[Main fields to lookup in package.json. Defaults to --target dependent]:main-fields' '--no-summary[Don'"'"'t print a summary]' '--version[Print version and exit]' '-v[Print version and exit]' '--revision[Print version with revision and exit]' '--tsconfig-override[Load tsconfig from path instead of cwd/tsconfig.json]:tsconfig-override' '--define[Substitute K:V while parsing, e.g. --define process.env.NODE_ENV:"development". Values are parsed as JSON.]:define' '-d[Substitute K:V while parsing, e.g. --define process.env.NODE_ENV:"development". Values are parsed as JSON.]:define' '--external[Exclude module from transpilation (can use * wildcards). ex: -e react]:external' '-e[Exclude module from transpilation (can use * wildcards). ex: -e react]:external' '--loader[Parse files with .ext:loader, e.g. --loader .js:jsx. Valid loaders: js, jsx, ts, tsx, json, toml, text, file, wasm, napi]:loader' '--packages[Exclude dependencies from bundle, e.g. --packages external. Valid options: bundle, external]:packages' '-l[Parse files with .ext:loader, e.g. --loader .js:jsx. Valid loaders: js, jsx, ts, tsx, json, toml, text, file, wasm, napi]:loader' '--origin[Rewrite import URLs to start with --origin. Default: ""]:origin' '-u[Rewrite import URLs to start with --origin. Default: ""]:origin' '--port[Port to serve bun'"'"'s dev server on. Default: '"'"'3000'"'"']:port' '-p[Port to serve bun'"'"'s dev server on. Default: '"'"'3000'"'"']:port' '--smol[Use less memory, but run garbage collection more often]' '--minify[Minify (experimental)]' '--minify-syntax[Minify syntax and inline data (experimental)]' '--minify-whitespace[Minify Whitespace (experimental)]' '--minify-identifiers[Minify identifiers]' '--no-macros[Disable macros from being executed in the bundler, transpiler and runtime]' '--target[The intended execution environment for the bundle. "browser", "bun" or "node"]: :->target' '--inspect[Activate Bun'"'"'s Debugger]:inspect' '--inspect-wait[Activate Bun'"'"'s Debugger, wait for a connection before executing]:inspect-wait' '--inspect-brk[Activate Bun'"'"'s Debugger, set breakpoint on first line of code and wait]:inspect-brk' '--hot[Enable auto reload in bun'"'"'s JavaScript runtime]' '--watch[Automatically restart bun'"'"'s JavaScript runtime on file change]' '--no-install[Disable auto install in bun'"'"'s JavaScript runtime]' '--install[Install dependencies automatically when no node_modules are present, default: "auto". "force" to ignore node_modules, fallback to install any missing]: :->install_' '-i[Automatically install dependencies and use global cache in bun'"'"'s runtime, equivalent to --install=fallback'] '--prefer-offline[Skip staleness checks for packages in bun'"'"'s JavaScript runtime and resolve from disk]' '--prefer-latest[Use the latest matching versions of packages in bun'"'"'s JavaScript runtime, always checking npm]' '--silent[Don'"'"'t repeat the command for bun run]' '--dump-environment-variables[Dump environment variables from .env and process as JSON and quit. Useful for debugging]' '--dump-limits[Dump system limits. Userful for debugging]' && ret=0 
	case $state in
		(script) curcontext="${curcontext%:*:*}:bun-grouped" 
			_bun_run_param_script_completion ;;
		(jsx-runtime) _alternative 'args:cmd3:((classic automatic))' ;;
		(target) _alternative 'args:cmd3:((browser bun node))' ;;
		(install_) _alternative 'args:cmd3:((auto force fallback))' ;;
		(other) _files ;;
	esac
}
_bun_run_param_script_completion () {
	local -a scripts_list
	IFS=$'\n' scripts_list=($(SHELL=zsh bun getcompletes s)) 
	IFS=$'\n' bins=($(SHELL=zsh bun getcompletes b)) 
	_alternative "scripts:scripts:((${scripts_list//:/\\\\:}))"
	_alternative "bin:bin:((${bins//:/\\\\:}))"
	_alternative "files:file:_files -g '*.(js|ts|jsx|tsx|wasm)'"
}
_bun_test_completion () {
	_arguments -s -C '1: :->cmd1' '*: :->file' '-h[Display this help and exit]' '--help[Display this help and exit]' '-b[Force a script or package to use Bun.js instead of Node.js (via symlinking node)]' '--bun[Force a script or package to use Bun.js instead of Node.js (via symlinking node)]' '--cwd[Set a specific cwd]:cwd' '-c[Load config(bunfig.toml)]: :->config' '--config[Load config(bunfig.toml)]: :->config' '--env-file[Load environment variables from the specified file(s)]:env-file' '--extension-order[Defaults to: .tsx,.ts,.jsx,.js,.json]:extension-order' '--jsx-factory[Changes the function called when compiling JSX elements using the classic JSX runtime]:jsx-factory' '--jsx-fragment[Changes the function called when compiling JSX fragments]:jsx-fragment' '--jsx-import-source[Declares the module specifier to be used for importing the jsx and jsxs factory functions. Default: "react"]:jsx-import-source' '--jsx-runtime["automatic" (default) or "classic"]: :->jsx-runtime' '--preload[Import a module before other modules are loaded]:preload' '-r[Import a module before other modules are loaded]:preload' '--main-fields[Main fields to lookup in package.json. Defaults to --target dependent]:main-fields' '--no-summary[Don'"'"'t print a summary]' '--version[Print version and exit]' '-v[Print version and exit]' '--revision[Print version with revision and exit]' '--tsconfig-override[Load tsconfig from path instead of cwd/tsconfig.json]:tsconfig-override' '--define[Substitute K:V while parsing, e.g. --define process.env.NODE_ENV:"development". Values are parsed as JSON.]:define' '-d[Substitute K:V while parsing, e.g. --define process.env.NODE_ENV:"development". Values are parsed as JSON.]:define' '--external[Exclude module from transpilation (can use * wildcards). ex: -e react]:external' '-e[Exclude module from transpilation (can use * wildcards). ex: -e react]:external' '--loader[Parse files with .ext:loader, e.g. --loader .js:jsx. Valid loaders: js, jsx, ts, tsx, json, toml, text, file, wasm, napi]:loader' '-l[Parse files with .ext:loader, e.g. --loader .js:jsx. Valid loaders: js, jsx, ts, tsx, json, toml, text, file, wasm, napi]:loader' '--origin[Rewrite import URLs to start with --origin. Default: ""]:origin' '-u[Rewrite import URLs to start with --origin. Default: ""]:origin' '--port[Port to serve bun'"'"'s dev server on. Default: '"'"'3000'"'"']:port' '-p[Port to serve bun'"'"'s dev server on. Default: '"'"'3000'"'"']:port' '--smol[Use less memory, but run garbage collection more often]' '--minify[Minify (experimental)]' '--minify-syntax[Minify syntax and inline data (experimental)]' '--minify-identifiers[Minify identifiers]' '--no-macros[Disable macros from being executed in the bundler, transpiler and runtime]' '--target[The intended execution environment for the bundle. "browser", "bun" or "node"]: :->target' '--inspect[Activate Bun'"'"'s Debugger]:inspect' '--inspect-wait[Activate Bun'"'"'s Debugger, wait for a connection before executing]:inspect-wait' '--inspect-brk[Activate Bun'"'"'s Debugger, set breakpoint on first line of code and wait]:inspect-brk' '--watch[Automatically restart bun'"'"'s JavaScript runtime on file change]' '--timeout[Set the per-test timeout in milliseconds, default is 5000.]:timeout' '--update-snapshots[Update snapshot files]' '--rerun-each[Re-run each test file <NUMBER> times, helps catch certain bugs]:rerun' '--retry[Default retry count for all tests]:retry' '--todo[Include tests that are marked with "test.todo()"]' '--coverage[Generate a coverage profile]' '--bail[Exit the test suite after <NUMBER> failures. If you do not specify a number, it defaults to 1.]:bail' '--test-name-pattern[Run only tests with a name that matches the given regex]:pattern' '-t[Run only tests with a name that matches the given regex]:pattern' && ret=0 
	case $state in
		(file) _bun_test_param_script_completion ;;
		(config) _files ;;
	esac
}
_bun_test_param_script_completion () {
	local -a scripts_list
	_alternative "files:file:_files -g '*(_|.)(test|spec).(js|ts|jsx|tsx)'"
}
_bun_unlink_completion () {
	_arguments -s -C '1: :->cmd1' '*: :->package' '--config[Load config(bunfig.toml)]: :->config' '-c[Load config(bunfig.toml)]: :->config' '--yarn[Write a yarn.lock file (yarn v1)]' '-y[Write a yarn.lock file (yarn v1)]' '--production[Don'"'"'t install devDependencies]' '-p[Don'"'"'t install devDependencies]' '--no-save[Don'"'"'t save a lockfile]' '--save[Save to package.json]' '--dry-run[Don'"'"'t install anything]' '--frozen-lockfile[Disallow changes to lockfile]' '--force[Always request the latest versions from the registry & reinstall all dependencies]' '-f[Always request the latest versions from the registry & reinstall all dependencies]' '--cache-dir[Store & load cached data from a specific directory path]:cache-dir' '--no-cache[Ignore manifest cache entirely]' '--silent[Don'"'"'t log anything]' '--verbose[Excessively verbose logging]' '--no-progress[Disable the progress bar]' '--no-summary[Don'"'"'t print a summary]' '--no-verify[Skip verifying integrity of newly downloaded packages]' '--ignore-scripts[Skip lifecycle scripts in the package.json (dependency scripts are never run)]' '--global[Add a package globally]' '-g[Add a package globally]' '--cwd[Set a specific cwd]:cwd' '--backend[Platform-specific optimizations for installing dependencies]:backend:("copyfile" "hardlink" "symlink")' '--link-native-bins[Link "bin" from a matching platform-specific dependency instead. Default: esbuild, turbo]:link-native-bins' '--help[Print this help menu]' && ret=0 
	case $state in
		(config) _bun_list_bunfig_toml ;;
		(package)  ;;
	esac
}
_bun_update_completion () {
	_arguments -s -C '1: :->cmd1' '-c[Load config(bunfig.toml)]: :->config' '--config[Load config(bunfig.toml)]: :->config' '-y[Write a yarn.lock file (yarn v1)]' '--yarn[Write a yarn.lock file (yarn v1)]' '-p[Don'"'"'t install devDependencies]' '--production[Don'"'"'t install devDependencies]' '--no-save[Don'"'"'t save a lockfile]' '--save[Save to package.json]' '--dry-run[Don'"'"'t install anything]' '--frozen-lockfile[Disallow changes to lockfile]' '--latest[Updates dependencies to latest version, regardless of compatibility]' '-f[Always request the latest versions from the registry & reinstall all dependencies]' '--force[Always request the latest versions from the registry & reinstall all dependencies]' '--cache-dir[Store & load cached data from a specific directory path]:cache-dir' '--no-cache[Ignore manifest cache entirely]' '--silent[Don'"'"'t log anything]' '--verbose[Excessively verbose logging]' '--no-progress[Disable the progress bar]' '--no-summary[Don'"'"'t print a summary]' '--no-verify[Skip verifying integrity of newly downloaded packages]' '--ignore-scripts[Skip lifecycle scripts in the package.json (dependency scripts are never run)]' '-g[Add a package globally]' '--global[Add a package globally]' '--cwd[Set a specific cwd]:cwd' '--backend[Platform-specific optimizations for installing dependencies]:backend:("copyfile" "hardlink" "symlink")' '--link-native-bins[Link "bin" from a matching platform-specific dependency instead. Default: esbuild, turbo]:link-native-bins' '--help[Print this help menu]' && ret=0 
	case $state in
		(config) _bun_list_bunfig_toml ;;
	esac
}
_bun_upgrade_completion () {
	_arguments -s -C '1: :->cmd' '--canary[Upgrade to canary build]' && ret=0 
}
_bzip2 () {
	# undefined
	builtin autoload -XUz
}
_bzr () {
	# undefined
	builtin autoload -XUz
}
_cabal () {
	# undefined
	builtin autoload -XUz
}
_cache_invalid () {
	# undefined
	builtin autoload -XUz
}
_caffeinate () {
	# undefined
	builtin autoload -XUz
}
_cal () {
	# undefined
	builtin autoload -XUz
}
_calendar () {
	# undefined
	builtin autoload -XUz
}
_call_function () {
	# undefined
	builtin autoload -XUz
}
_call_program () {
	local -xi COLUMNS=999 
	local curcontext="${curcontext}" tmp err_fd=-1 clocale='_comp_locale;' 
	local -a prefix
	if [[ "$1" = -p ]]
	then
		shift
		if (( $#_comp_priv_prefix ))
		then
			curcontext="${curcontext%:*}/${${(@M)_comp_priv_prefix:#^*[^\\]=*}[1]}:" 
			zstyle -t ":completion:${curcontext}:${1}" gain-privileges && prefix=($_comp_priv_prefix) 
		fi
	elif [[ "$1" = -l ]]
	then
		shift
		clocale='' 
	fi
	if (( ${debug_fd:--1} > 2 )) || [[ ! -t 2 ]]
	then
		exec {err_fd}>&2
	else
		exec {err_fd}> /dev/null
	fi
	{
		if zstyle -s ":completion:${curcontext}:${1}" command tmp
		then
			if [[ "$tmp" = -* ]]
			then
				eval $clocale "$tmp[2,-1]" "$argv[2,-1]"
			else
				eval $clocale $prefix "$tmp"
			fi
		else
			eval $clocale $prefix "$argv[2,-1]"
		fi 2>&$err_fd
	} always {
		exec {err_fd}>&-
	}
}
_canonical_paths () {
	# undefined
	builtin autoload -XUz
}
_capabilities () {
	# undefined
	builtin autoload -XUz
}
_cat () {
	# undefined
	builtin autoload -XUz
}
_ccal () {
	# undefined
	builtin autoload -XUz
}
_cd () {
	# undefined
	builtin autoload -XUz
}
_cdbs-edit-patch () {
	# undefined
	builtin autoload -XUz
}
_cdcd () {
	# undefined
	builtin autoload -XUz
}
_cdr () {
	# undefined
	builtin autoload -XUz
}
_cdrdao () {
	# undefined
	builtin autoload -XUz
}
_cdrecord () {
	# undefined
	builtin autoload -XUz
}
_chattr () {
	# undefined
	builtin autoload -XUz
}
_chcon () {
	# undefined
	builtin autoload -XUz
}
_chflags () {
	# undefined
	builtin autoload -XUz
}
_chkconfig () {
	# undefined
	builtin autoload -XUz
}
_chmod () {
	# undefined
	builtin autoload -XUz
}
_choom () {
	# undefined
	builtin autoload -XUz
}
_chown () {
	# undefined
	builtin autoload -XUz
}
_chroot () {
	# undefined
	builtin autoload -XUz
}
_chrt () {
	# undefined
	builtin autoload -XUz
}
_chsh () {
	# undefined
	builtin autoload -XUz
}
_cksum () {
	# undefined
	builtin autoload -XUz
}
_clay () {
	# undefined
	builtin autoload -XUz
}
_cmdambivalent () {
	# undefined
	builtin autoload -XUz
}
_cmdstring () {
	# undefined
	builtin autoload -XUz
}
_cmp () {
	# undefined
	builtin autoload -XUz
}
_code () {
	# undefined
	builtin autoload -XUz
}
_column () {
	# undefined
	builtin autoload -XUz
}
_combination () {
	# undefined
	builtin autoload -XUz
}
_comm () {
	# undefined
	builtin autoload -XUz
}
_command () {
	# undefined
	builtin autoload -XUz
}
_command_names () {
	# undefined
	builtin autoload -XUz
}
_comp_locale () {
	# undefined
	builtin autoload -XUz
}
_compadd () {
	# undefined
	builtin autoload -XUz
}
_compdef () {
	# undefined
	builtin autoload -XUz
}
_complete () {
	# undefined
	builtin autoload -XUz
}
_complete_debug () {
	# undefined
	builtin autoload -XUz
}
_complete_help () {
	# undefined
	builtin autoload -XUz
}
_complete_help_generic () {
	# undefined
	builtin autoload -XUz
}
_complete_tag () {
	# undefined
	builtin autoload -XUz
}
_completers () {
	# undefined
	builtin autoload -XUz
}
_composer () {
	# undefined
	builtin autoload -XUz
}
_compress () {
	# undefined
	builtin autoload -XUz
}
_condition () {
	# undefined
	builtin autoload -XUz
}
_configure () {
	# undefined
	builtin autoload -XUz
}
_coreadm () {
	# undefined
	builtin autoload -XUz
}
_correct () {
	# undefined
	builtin autoload -XUz
}
_correct_filename () {
	# undefined
	builtin autoload -XUz
}
_correct_word () {
	# undefined
	builtin autoload -XUz
}
_cowsay () {
	# undefined
	builtin autoload -XUz
}
_cp () {
	# undefined
	builtin autoload -XUz
}
_cpio () {
	# undefined
	builtin autoload -XUz
}
_cplay () {
	# undefined
	builtin autoload -XUz
}
_cpupower () {
	# undefined
	builtin autoload -XUz
}
_crontab () {
	# undefined
	builtin autoload -XUz
}
_cryptsetup () {
	# undefined
	builtin autoload -XUz
}
_cscope () {
	# undefined
	builtin autoload -XUz
}
_csplit () {
	# undefined
	builtin autoload -XUz
}
_cssh () {
	# undefined
	builtin autoload -XUz
}
_csup () {
	# undefined
	builtin autoload -XUz
}
_ctags () {
	# undefined
	builtin autoload -XUz
}
_ctags_tags () {
	# undefined
	builtin autoload -XUz
}
_cu () {
	# undefined
	builtin autoload -XUz
}
_curl () {
	# undefined
	builtin autoload -XUz
}
_cut () {
	# undefined
	builtin autoload -XUz
}
_cvs () {
	# undefined
	builtin autoload -XUz
}
_cvsup () {
	# undefined
	builtin autoload -XUz
}
_cygcheck () {
	# undefined
	builtin autoload -XUz
}
_cygpath () {
	# undefined
	builtin autoload -XUz
}
_cygrunsrv () {
	# undefined
	builtin autoload -XUz
}
_cygserver () {
	# undefined
	builtin autoload -XUz
}
_cygstart () {
	# undefined
	builtin autoload -XUz
}
_dak () {
	# undefined
	builtin autoload -XUz
}
_darcs () {
	# undefined
	builtin autoload -XUz
}
_date () {
	# undefined
	builtin autoload -XUz
}
_date_formats () {
	# undefined
	builtin autoload -XUz
}
_dates () {
	# undefined
	builtin autoload -XUz
}
_dbus () {
	# undefined
	builtin autoload -XUz
}
_dchroot () {
	# undefined
	builtin autoload -XUz
}
_dchroot-dsa () {
	# undefined
	builtin autoload -XUz
}
_dconf () {
	# undefined
	builtin autoload -XUz
}
_dcop () {
	# undefined
	builtin autoload -XUz
}
_dcut () {
	# undefined
	builtin autoload -XUz
}
_dd () {
	# undefined
	builtin autoload -XUz
}
_deb_architectures () {
	# undefined
	builtin autoload -XUz
}
_deb_codenames () {
	# undefined
	builtin autoload -XUz
}
_deb_files () {
	# undefined
	builtin autoload -XUz
}
_deb_packages () {
	# undefined
	builtin autoload -XUz
}
_debbugs_bugnumber () {
	# undefined
	builtin autoload -XUz
}
_debchange () {
	# undefined
	builtin autoload -XUz
}
_debcheckout () {
	# undefined
	builtin autoload -XUz
}
_debdiff () {
	# undefined
	builtin autoload -XUz
}
_debfoster () {
	# undefined
	builtin autoload -XUz
}
_deborphan () {
	# undefined
	builtin autoload -XUz
}
_debsign () {
	# undefined
	builtin autoload -XUz
}
_debsnap () {
	# undefined
	builtin autoload -XUz
}
_debuild () {
	# undefined
	builtin autoload -XUz
}
_default () {
	# undefined
	builtin autoload -XUz
}
_defaults () {
	# undefined
	builtin autoload -XUz
}
_defer_async_git_register () {
	case "${PS1}:${PS2}:${PS3}:${PS4}:${RPROMPT}:${RPS1}:${RPS2}:${RPS3}:${RPS4}" in
		(*(\$\(git_prompt_info\)|\`git_prompt_info\`)*) _omz_register_handler _omz_git_prompt_info ;;
	esac
	case "${PS1}:${PS2}:${PS3}:${PS4}:${RPROMPT}:${RPS1}:${RPS2}:${RPS3}:${RPS4}" in
		(*(\$\(git_prompt_status\)|\`git_prompt_status\`)*) _omz_register_handler _omz_git_prompt_status ;;
	esac
	add-zsh-hook -d precmd _defer_async_git_register
	unset -f _defer_async_git_register
}
_delimiters () {
	# undefined
	builtin autoload -XUz
}
_describe () {
	# undefined
	builtin autoload -XUz
}
_description () {
	# undefined
	builtin autoload -XUz
}
_devtodo () {
	# undefined
	builtin autoload -XUz
}
_df () {
	# undefined
	builtin autoload -XUz
}
_dhclient () {
	# undefined
	builtin autoload -XUz
}
_dhcpinfo () {
	# undefined
	builtin autoload -XUz
}
_dict () {
	# undefined
	builtin autoload -XUz
}
_dict_words () {
	# undefined
	builtin autoload -XUz
}
_diff () {
	# undefined
	builtin autoload -XUz
}
_diff3 () {
	# undefined
	builtin autoload -XUz
}
_diff_options () {
	# undefined
	builtin autoload -XUz
}
_diffstat () {
	# undefined
	builtin autoload -XUz
}
_dig () {
	# undefined
	builtin autoload -XUz
}
_dir_list () {
	# undefined
	builtin autoload -XUz
}
_directories () {
	# undefined
	builtin autoload -XUz
}
_directory_stack () {
	# undefined
	builtin autoload -XUz
}
_dirs () {
	# undefined
	builtin autoload -XUz
}
_disable () {
	# undefined
	builtin autoload -XUz
}
_dispatch () {
	# undefined
	builtin autoload -XUz
}
_django () {
	# undefined
	builtin autoload -XUz
}
_dkms () {
	# undefined
	builtin autoload -XUz
}
_dladm () {
	# undefined
	builtin autoload -XUz
}
_dlocate () {
	# undefined
	builtin autoload -XUz
}
_dmesg () {
	# undefined
	builtin autoload -XUz
}
_dmidecode () {
	# undefined
	builtin autoload -XUz
}
_dnf () {
	# undefined
	builtin autoload -XUz
}
_dns_types () {
	# undefined
	builtin autoload -XUz
}
_doas () {
	# undefined
	builtin autoload -XUz
}
_domains () {
	# undefined
	builtin autoload -XUz
}
_dos2unix () {
	# undefined
	builtin autoload -XUz
}
_dpatch-edit-patch () {
	# undefined
	builtin autoload -XUz
}
_dpkg () {
	# undefined
	builtin autoload -XUz
}
_dpkg-buildpackage () {
	# undefined
	builtin autoload -XUz
}
_dpkg-cross () {
	# undefined
	builtin autoload -XUz
}
_dpkg-repack () {
	# undefined
	builtin autoload -XUz
}
_dpkg_source () {
	# undefined
	builtin autoload -XUz
}
_dput () {
	# undefined
	builtin autoload -XUz
}
_drill () {
	# undefined
	builtin autoload -XUz
}
_dropbox () {
	# undefined
	builtin autoload -XUz
}
_dscverify () {
	# undefined
	builtin autoload -XUz
}
_dsh () {
	# undefined
	builtin autoload -XUz
}
_dtrace () {
	# undefined
	builtin autoload -XUz
}
_dtruss () {
	# undefined
	builtin autoload -XUz
}
_du () {
	# undefined
	builtin autoload -XUz
}
_dumpadm () {
	# undefined
	builtin autoload -XUz
}
_dumper () {
	# undefined
	builtin autoload -XUz
}
_dupload () {
	# undefined
	builtin autoload -XUz
}
_dvi () {
	# undefined
	builtin autoload -XUz
}
_dynamic_directory_name () {
	# undefined
	builtin autoload -XUz
}
_e2label () {
	# undefined
	builtin autoload -XUz
}
_ecasound () {
	# undefined
	builtin autoload -XUz
}
_echotc () {
	# undefined
	builtin autoload -XUz
}
_echoti () {
	# undefined
	builtin autoload -XUz
}
_ed () {
	# undefined
	builtin autoload -XUz
}
_elfdump () {
	# undefined
	builtin autoload -XUz
}
_elinks () {
	# undefined
	builtin autoload -XUz
}
_email_addresses () {
	# undefined
	builtin autoload -XUz
}
_emulate () {
	# undefined
	builtin autoload -XUz
}
_enable () {
	# undefined
	builtin autoload -XUz
}
_enscript () {
	# undefined
	builtin autoload -XUz
}
_entr () {
	# undefined
	builtin autoload -XUz
}
_env () {
	# undefined
	builtin autoload -XUz
}
_eog () {
	# undefined
	builtin autoload -XUz
}
_equal () {
	# undefined
	builtin autoload -XUz
}
_espeak () {
	# undefined
	builtin autoload -XUz
}
_etags () {
	# undefined
	builtin autoload -XUz
}
_ethtool () {
	# undefined
	builtin autoload -XUz
}
_evince () {
	# undefined
	builtin autoload -XUz
}
_exec () {
	# undefined
	builtin autoload -XUz
}
_expand () {
	# undefined
	builtin autoload -XUz
}
_expand_alias () {
	# undefined
	builtin autoload -XUz
}
_expand_word () {
	# undefined
	builtin autoload -XUz
}
_extensions () {
	# undefined
	builtin autoload -XUz
}
_external_pwds () {
	# undefined
	builtin autoload -XUz
}
_fakeroot () {
	# undefined
	builtin autoload -XUz
}
_fbsd_architectures () {
	# undefined
	builtin autoload -XUz
}
_fbsd_device_types () {
	# undefined
	builtin autoload -XUz
}
_fc () {
	# undefined
	builtin autoload -XUz
}
_feh () {
	# undefined
	builtin autoload -XUz
}
_fetch () {
	# undefined
	builtin autoload -XUz
}
_fetchmail () {
	# undefined
	builtin autoload -XUz
}
_ffmpeg () {
	# undefined
	builtin autoload -XUz
}
_figlet () {
	# undefined
	builtin autoload -XUz
}
_file_descriptors () {
	# undefined
	builtin autoload -XUz
}
_file_flags () {
	# undefined
	builtin autoload -XUz
}
_file_modes () {
	# undefined
	builtin autoload -XUz
}
_file_systems () {
	# undefined
	builtin autoload -XUz
}
_files () {
	# undefined
	builtin autoload -XUz
}
_find () {
	# undefined
	builtin autoload -XUz
}
_find_net_interfaces () {
	# undefined
	builtin autoload -XUz
}
_findmnt () {
	# undefined
	builtin autoload -XUz
}
_finger () {
	# undefined
	builtin autoload -XUz
}
_fink () {
	# undefined
	builtin autoload -XUz
}
_first () {
	# undefined
	builtin autoload -XUz
}
_flac () {
	# undefined
	builtin autoload -XUz
}
_flex () {
	# undefined
	builtin autoload -XUz
}
_floppy () {
	# undefined
	builtin autoload -XUz
}
_flowadm () {
	# undefined
	builtin autoload -XUz
}
_fmadm () {
	# undefined
	builtin autoload -XUz
}
_fmt () {
	# undefined
	builtin autoload -XUz
}
_fold () {
	# undefined
	builtin autoload -XUz
}
_fortune () {
	# undefined
	builtin autoload -XUz
}
_free () {
	# undefined
	builtin autoload -XUz
}
_freebsd-update () {
	# undefined
	builtin autoload -XUz
}
_fs_usage () {
	# undefined
	builtin autoload -XUz
}
_fsh () {
	# undefined
	builtin autoload -XUz
}
_fstat () {
	# undefined
	builtin autoload -XUz
}
_functions () {
	# undefined
	builtin autoload -XUz
}
_fuse_arguments () {
	# undefined
	builtin autoload -XUz
}
_fuse_values () {
	# undefined
	builtin autoload -XUz
}
_fuser () {
	# undefined
	builtin autoload -XUz
}
_fusermount () {
	# undefined
	builtin autoload -XUz
}
_fw_update () {
	# undefined
	builtin autoload -XUz
}
_gcc () {
	# undefined
	builtin autoload -XUz
}
_gcore () {
	# undefined
	builtin autoload -XUz
}
_gdb () {
	# undefined
	builtin autoload -XUz
}
_geany () {
	# undefined
	builtin autoload -XUz
}
_gem () {
	# undefined
	builtin autoload -XUz
}
_generic () {
	# undefined
	builtin autoload -XUz
}
_genisoimage () {
	# undefined
	builtin autoload -XUz
}
_getclip () {
	# undefined
	builtin autoload -XUz
}
_getconf () {
	# undefined
	builtin autoload -XUz
}
_getent () {
	# undefined
	builtin autoload -XUz
}
_getfacl () {
	# undefined
	builtin autoload -XUz
}
_getmail () {
	# undefined
	builtin autoload -XUz
}
_getopt () {
	# undefined
	builtin autoload -XUz
}
_gh () {
	# undefined
	builtin autoload -XUz
}
_ghostscript () {
	# undefined
	builtin autoload -XUz
}
_git () {
	# undefined
	builtin autoload -XUz
}
_git-buildpackage () {
	# undefined
	builtin autoload -XUz
}
_git-lfs () {
	# undefined
	builtin autoload -XUz
}
_git_log_prettily () {
	if ! [ -z $1 ]
	then
		git log --pretty=$1
	fi
}
_global () {
	# undefined
	builtin autoload -XUz
}
_global_tags () {
	# undefined
	builtin autoload -XUz
}
_globflags () {
	# undefined
	builtin autoload -XUz
}
_globqual_delims () {
	# undefined
	builtin autoload -XUz
}
_globquals () {
	# undefined
	builtin autoload -XUz
}
_gnome-gv () {
	# undefined
	builtin autoload -XUz
}
_gnu_generic () {
	# undefined
	builtin autoload -XUz
}
_gnupod () {
	# undefined
	builtin autoload -XUz
}
_gnutls () {
	# undefined
	builtin autoload -XUz
}
_go () {
	# undefined
	builtin autoload -XUz
}
_gpasswd () {
	# undefined
	builtin autoload -XUz
}
_gpg () {
	# undefined
	builtin autoload -XUz
}
_gphoto2 () {
	# undefined
	builtin autoload -XUz
}
_gprof () {
	# undefined
	builtin autoload -XUz
}
_gqview () {
	# undefined
	builtin autoload -XUz
}
_gradle () {
	# undefined
	builtin autoload -XUz
}
_graphicsmagick () {
	# undefined
	builtin autoload -XUz
}
_grep () {
	# undefined
	builtin autoload -XUz
}
_grep-excuses () {
	# undefined
	builtin autoload -XUz
}
_groff () {
	# undefined
	builtin autoload -XUz
}
_groups () {
	# undefined
	builtin autoload -XUz
}
_growisofs () {
	# undefined
	builtin autoload -XUz
}
_gsettings () {
	# undefined
	builtin autoload -XUz
}
_gstat () {
	# undefined
	builtin autoload -XUz
}
_guard () {
	# undefined
	builtin autoload -XUz
}
_guilt () {
	# undefined
	builtin autoload -XUz
}
_gv () {
	# undefined
	builtin autoload -XUz
}
_gzip () {
	# undefined
	builtin autoload -XUz
}
_hash () {
	# undefined
	builtin autoload -XUz
}
_have_glob_qual () {
	# undefined
	builtin autoload -XUz
}
_hdiutil () {
	# undefined
	builtin autoload -XUz
}
_head () {
	# undefined
	builtin autoload -XUz
}
_hexdump () {
	# undefined
	builtin autoload -XUz
}
_history () {
	# undefined
	builtin autoload -XUz
}
_history_complete_word () {
	# undefined
	builtin autoload -XUz
}
_history_modifiers () {
	# undefined
	builtin autoload -XUz
}
_host () {
	# undefined
	builtin autoload -XUz
}
_hostname () {
	# undefined
	builtin autoload -XUz
}
_hosts () {
	# undefined
	builtin autoload -XUz
}
_htop () {
	# undefined
	builtin autoload -XUz
}
_hwinfo () {
	# undefined
	builtin autoload -XUz
}
_iconv () {
	# undefined
	builtin autoload -XUz
}
_iconvconfig () {
	# undefined
	builtin autoload -XUz
}
_id () {
	# undefined
	builtin autoload -XUz
}
_ifconfig () {
	# undefined
	builtin autoload -XUz
}
_iftop () {
	# undefined
	builtin autoload -XUz
}
_ignored () {
	# undefined
	builtin autoload -XUz
}
_imagemagick () {
	# undefined
	builtin autoload -XUz
}
_in_vared () {
	# undefined
	builtin autoload -XUz
}
_inetadm () {
	# undefined
	builtin autoload -XUz
}
_init_d () {
	# undefined
	builtin autoload -XUz
}
_initctl () {
	# undefined
	builtin autoload -XUz
}
_install () {
	# undefined
	builtin autoload -XUz
}
_invoke-rc.d () {
	# undefined
	builtin autoload -XUz
}
_ionice () {
	# undefined
	builtin autoload -XUz
}
_iostat () {
	# undefined
	builtin autoload -XUz
}
_ip () {
	# undefined
	builtin autoload -XUz
}
_ipadm () {
	# undefined
	builtin autoload -XUz
}
_ipfw () {
	# undefined
	builtin autoload -XUz
}
_ipsec () {
	# undefined
	builtin autoload -XUz
}
_ipset () {
	# undefined
	builtin autoload -XUz
}
_iptables () {
	# undefined
	builtin autoload -XUz
}
_irssi () {
	# undefined
	builtin autoload -XUz
}
_ispell () {
	# undefined
	builtin autoload -XUz
}
_iwconfig () {
	# undefined
	builtin autoload -XUz
}
_jail () {
	# undefined
	builtin autoload -XUz
}
_jails () {
	# undefined
	builtin autoload -XUz
}
_java () {
	# undefined
	builtin autoload -XUz
}
_java_class () {
	# undefined
	builtin autoload -XUz
}
_jexec () {
	# undefined
	builtin autoload -XUz
}
_jls () {
	# undefined
	builtin autoload -XUz
}
_jobs () {
	# undefined
	builtin autoload -XUz
}
_jobs_bg () {
	# undefined
	builtin autoload -XUz
}
_jobs_builtin () {
	# undefined
	builtin autoload -XUz
}
_jobs_fg () {
	# undefined
	builtin autoload -XUz
}
_joe () {
	# undefined
	builtin autoload -XUz
}
_join () {
	# undefined
	builtin autoload -XUz
}
_jot () {
	# undefined
	builtin autoload -XUz
}
_jq () {
	# undefined
	builtin autoload -XUz
}
_kdeconnect () {
	# undefined
	builtin autoload -XUz
}
_kdump () {
	# undefined
	builtin autoload -XUz
}
_kfmclient () {
	# undefined
	builtin autoload -XUz
}
_kill () {
	# undefined
	builtin autoload -XUz
}
_killall () {
	# undefined
	builtin autoload -XUz
}
_kind () {
	# undefined
	builtin autoload -XUz
}
_kld () {
	# undefined
	builtin autoload -XUz
}
_knock () {
	# undefined
	builtin autoload -XUz
}
_kpartx () {
	# undefined
	builtin autoload -XUz
}
_ktrace () {
	# undefined
	builtin autoload -XUz
}
_ktrace_points () {
	# undefined
	builtin autoload -XUz
}
_kvno () {
	# undefined
	builtin autoload -XUz
}
_last () {
	# undefined
	builtin autoload -XUz
}
_ld_debug () {
	# undefined
	builtin autoload -XUz
}
_ldap () {
	# undefined
	builtin autoload -XUz
}
_ldconfig () {
	# undefined
	builtin autoload -XUz
}
_ldd () {
	# undefined
	builtin autoload -XUz
}
_less () {
	# undefined
	builtin autoload -XUz
}
_lha () {
	# undefined
	builtin autoload -XUz
}
_libvirt () {
	# undefined
	builtin autoload -XUz
}
_lighttpd () {
	# undefined
	builtin autoload -XUz
}
_limit () {
	# undefined
	builtin autoload -XUz
}
_limits () {
	# undefined
	builtin autoload -XUz
}
_links () {
	# undefined
	builtin autoload -XUz
}
_lintian () {
	# undefined
	builtin autoload -XUz
}
_list () {
	# undefined
	builtin autoload -XUz
}
_list_files () {
	# undefined
	builtin autoload -XUz
}
_lldb () {
	# undefined
	builtin autoload -XUz
}
_ln () {
	# undefined
	builtin autoload -XUz
}
_loadkeys () {
	# undefined
	builtin autoload -XUz
}
_locale () {
	# undefined
	builtin autoload -XUz
}
_localedef () {
	# undefined
	builtin autoload -XUz
}
_locales () {
	# undefined
	builtin autoload -XUz
}
_locate () {
	# undefined
	builtin autoload -XUz
}
_logger () {
	# undefined
	builtin autoload -XUz
}
_logical_volumes () {
	# undefined
	builtin autoload -XUz
}
_login_classes () {
	# undefined
	builtin autoload -XUz
}
_look () {
	# undefined
	builtin autoload -XUz
}
_losetup () {
	# undefined
	builtin autoload -XUz
}
_lp () {
	# undefined
	builtin autoload -XUz
}
_ls () {
	# undefined
	builtin autoload -XUz
}
_lsattr () {
	# undefined
	builtin autoload -XUz
}
_lsblk () {
	# undefined
	builtin autoload -XUz
}
_lscfg () {
	# undefined
	builtin autoload -XUz
}
_lsdev () {
	# undefined
	builtin autoload -XUz
}
_lslv () {
	# undefined
	builtin autoload -XUz
}
_lsns () {
	# undefined
	builtin autoload -XUz
}
_lsof () {
	# undefined
	builtin autoload -XUz
}
_lspv () {
	# undefined
	builtin autoload -XUz
}
_lsusb () {
	# undefined
	builtin autoload -XUz
}
_lsvg () {
	# undefined
	builtin autoload -XUz
}
_ltrace () {
	# undefined
	builtin autoload -XUz
}
_lua () {
	# undefined
	builtin autoload -XUz
}
_luarocks () {
	# undefined
	builtin autoload -XUz
}
_lynx () {
	# undefined
	builtin autoload -XUz
}
_lz4 () {
	# undefined
	builtin autoload -XUz
}
_lzop () {
	# undefined
	builtin autoload -XUz
}
_mac_applications () {
	# undefined
	builtin autoload -XUz
}
_mac_files_for_application () {
	# undefined
	builtin autoload -XUz
}
_madison () {
	# undefined
	builtin autoload -XUz
}
_mail () {
	# undefined
	builtin autoload -XUz
}
_mailboxes () {
	# undefined
	builtin autoload -XUz
}
_main_complete () {
	# undefined
	builtin autoload -XUz
}
_make () {
	# undefined
	builtin autoload -XUz
}
_make-kpkg () {
	# undefined
	builtin autoload -XUz
}
_man () {
	# undefined
	builtin autoload -XUz
}
_mat () {
	# undefined
	builtin autoload -XUz
}
_mat2 () {
	# undefined
	builtin autoload -XUz
}
_match () {
	# undefined
	builtin autoload -XUz
}
_math () {
	# undefined
	builtin autoload -XUz
}
_math_params () {
	# undefined
	builtin autoload -XUz
}
_matlab () {
	# undefined
	builtin autoload -XUz
}
_md5sum () {
	# undefined
	builtin autoload -XUz
}
_mdadm () {
	# undefined
	builtin autoload -XUz
}
_mdfind () {
	# undefined
	builtin autoload -XUz
}
_mdls () {
	# undefined
	builtin autoload -XUz
}
_mdutil () {
	# undefined
	builtin autoload -XUz
}
_members () {
	# undefined
	builtin autoload -XUz
}
_mencal () {
	# undefined
	builtin autoload -XUz
}
_menu () {
	# undefined
	builtin autoload -XUz
}
_mere () {
	# undefined
	builtin autoload -XUz
}
_mergechanges () {
	# undefined
	builtin autoload -XUz
}
_message () {
	# undefined
	builtin autoload -XUz
}
_mh () {
	# undefined
	builtin autoload -XUz
}
_mii-tool () {
	# undefined
	builtin autoload -XUz
}
_mime_types () {
	# undefined
	builtin autoload -XUz
}
_mixerctl () {
	# undefined
	builtin autoload -XUz
}
_mkdir () {
	# undefined
	builtin autoload -XUz
}
_mkfifo () {
	# undefined
	builtin autoload -XUz
}
_mknod () {
	# undefined
	builtin autoload -XUz
}
_mkshortcut () {
	# undefined
	builtin autoload -XUz
}
_mktemp () {
	# undefined
	builtin autoload -XUz
}
_mkzsh () {
	# undefined
	builtin autoload -XUz
}
_module () {
	# undefined
	builtin autoload -XUz
}
_module-assistant () {
	# undefined
	builtin autoload -XUz
}
_module_math_func () {
	# undefined
	builtin autoload -XUz
}
_modutils () {
	# undefined
	builtin autoload -XUz
}
_mondo () {
	# undefined
	builtin autoload -XUz
}
_monotone () {
	# undefined
	builtin autoload -XUz
}
_moosic () {
	# undefined
	builtin autoload -XUz
}
_mosh () {
	# undefined
	builtin autoload -XUz
}
_most_recent_file () {
	# undefined
	builtin autoload -XUz
}
_mount () {
	# undefined
	builtin autoload -XUz
}
_mozilla () {
	# undefined
	builtin autoload -XUz
}
_mpc () {
	# undefined
	builtin autoload -XUz
}
_mplayer () {
	# undefined
	builtin autoload -XUz
}
_mt () {
	# undefined
	builtin autoload -XUz
}
_mtools () {
	# undefined
	builtin autoload -XUz
}
_mtr () {
	# undefined
	builtin autoload -XUz
}
_multi_parts () {
	# undefined
	builtin autoload -XUz
}
_mupdf () {
	# undefined
	builtin autoload -XUz
}
_mutt () {
	# undefined
	builtin autoload -XUz
}
_mv () {
	# undefined
	builtin autoload -XUz
}
_my_accounts () {
	# undefined
	builtin autoload -XUz
}
_myrepos () {
	# undefined
	builtin autoload -XUz
}
_mysql_utils () {
	# undefined
	builtin autoload -XUz
}
_mysqldiff () {
	# undefined
	builtin autoload -XUz
}
_nautilus () {
	# undefined
	builtin autoload -XUz
}
_nbsd_architectures () {
	# undefined
	builtin autoload -XUz
}
_ncftp () {
	# undefined
	builtin autoload -XUz
}
_nedit () {
	# undefined
	builtin autoload -XUz
}
_net_interfaces () {
	# undefined
	builtin autoload -XUz
}
_netcat () {
	# undefined
	builtin autoload -XUz
}
_netscape () {
	# undefined
	builtin autoload -XUz
}
_netstat () {
	# undefined
	builtin autoload -XUz
}
_networkmanager () {
	# undefined
	builtin autoload -XUz
}
_networksetup () {
	# undefined
	builtin autoload -XUz
}
_newsgroups () {
	# undefined
	builtin autoload -XUz
}
_next_label () {
	# undefined
	builtin autoload -XUz
}
_next_tags () {
	# undefined
	builtin autoload -XUz
}
_nginx () {
	# undefined
	builtin autoload -XUz
}
_ngrep () {
	# undefined
	builtin autoload -XUz
}
_nice () {
	# undefined
	builtin autoload -XUz
}
_nkf () {
	# undefined
	builtin autoload -XUz
}
_nl () {
	# undefined
	builtin autoload -XUz
}
_nm () {
	# undefined
	builtin autoload -XUz
}
_nmap () {
	# undefined
	builtin autoload -XUz
}
_normal () {
	# undefined
	builtin autoload -XUz
}
_nothing () {
	# undefined
	builtin autoload -XUz
}
_nsenter () {
	# undefined
	builtin autoload -XUz
}
_nslookup () {
	# undefined
	builtin autoload -XUz
}
_numbers () {
	# undefined
	builtin autoload -XUz
}
_numfmt () {
	# undefined
	builtin autoload -XUz
}
_nvram () {
	# undefined
	builtin autoload -XUz
}
_objdump () {
	# undefined
	builtin autoload -XUz
}
_object_classes () {
	# undefined
	builtin autoload -XUz
}
_object_files () {
	# undefined
	builtin autoload -XUz
}
_obsd_architectures () {
	# undefined
	builtin autoload -XUz
}
_od () {
	# undefined
	builtin autoload -XUz
}
_okular () {
	# undefined
	builtin autoload -XUz
}
_oldlist () {
	# undefined
	builtin autoload -XUz
}
_omz () {
	local -a cmds subcmds
	cmds=('changelog:Print the changelog' 'help:Usage information' 'plugin:Manage plugins' 'pr:Manage Oh My Zsh Pull Requests' 'reload:Reload the current zsh session' 'shop:Open the Oh My Zsh shop' 'theme:Manage themes' 'update:Update Oh My Zsh' 'version:Show the version') 
	if (( CURRENT == 2 ))
	then
		_describe 'command' cmds
	elif (( CURRENT == 3 ))
	then
		case "$words[2]" in
			(changelog) local -a refs
				refs=("${(@f)$(builtin cd -q "$ZSH"; command git for-each-ref --format="%(refname:short):%(subject)" refs/heads refs/tags)}") 
				_describe 'command' refs ;;
			(plugin) subcmds=('disable:Disable plugin(s)' 'enable:Enable plugin(s)' 'info:Get plugin information' 'list:List plugins' 'load:Load plugin(s)') 
				_describe 'command' subcmds ;;
			(pr) subcmds=('clean:Delete all Pull Request branches' 'test:Test a Pull Request') 
				_describe 'command' subcmds ;;
			(theme) subcmds=('list:List themes' 'set:Set a theme in your .zshrc file' 'use:Load a theme') 
				_describe 'command' subcmds ;;
		esac
	elif (( CURRENT == 4 ))
	then
		case "${words[2]}::${words[3]}" in
			(plugin::(disable|enable|load)) local -aU valid_plugins
				if [[ "${words[3]}" = disable ]]
				then
					valid_plugins=($plugins) 
				else
					valid_plugins=("$ZSH"/plugins/*/{_*,*.plugin.zsh}(-.N:h:t) "$ZSH_CUSTOM"/plugins/*/{_*,*.plugin.zsh}(-.N:h:t)) 
					[[ "${words[3]}" = enable ]] && valid_plugins=(${valid_plugins:|plugins}) 
				fi
				_describe 'plugin' valid_plugins ;;
			(plugin::info) local -aU plugins
				plugins=("$ZSH"/plugins/*/{_*,*.plugin.zsh}(-.N:h:t) "$ZSH_CUSTOM"/plugins/*/{_*,*.plugin.zsh}(-.N:h:t)) 
				_describe 'plugin' plugins ;;
			(plugin::list) local -a opts
				opts=('--enabled:List enabled plugins only') 
				_describe -o 'options' opts ;;
			(theme::(set|use)) local -aU themes
				themes=("$ZSH"/themes/*.zsh-theme(-.N:t:r) "$ZSH_CUSTOM"/**/*.zsh-theme(-.N:r:gs:"$ZSH_CUSTOM"/themes/:::gs:"$ZSH_CUSTOM"/:::)) 
				_describe 'theme' themes ;;
		esac
	elif (( CURRENT > 4 ))
	then
		case "${words[2]}::${words[3]}" in
			(plugin::(enable|disable|load)) local -aU valid_plugins
				if [[ "${words[3]}" = disable ]]
				then
					valid_plugins=($plugins) 
				else
					valid_plugins=("$ZSH"/plugins/*/{_*,*.plugin.zsh}(-.N:h:t) "$ZSH_CUSTOM"/plugins/*/{_*,*.plugin.zsh}(-.N:h:t)) 
					[[ "${words[3]}" = enable ]] && valid_plugins=(${valid_plugins:|plugins}) 
				fi
				local -a args
				args=(${words[4,$(( CURRENT - 1))]}) 
				valid_plugins=(${valid_plugins:|args}) 
				_describe 'plugin' valid_plugins ;;
		esac
	fi
	return 0
}
_omz::changelog () {
	local version=${1:-HEAD} format=${3:-"--text"} 
	if (
			builtin cd -q "$ZSH"
			! command git show-ref --verify refs/heads/$version && ! command git show-ref --verify refs/tags/$version && ! command git rev-parse --verify "${version}^{commit}"
		) &> /dev/null
	then
		cat >&2 <<EOF
Usage: ${(j: :)${(s.::.)0#_}} [version]

NOTE: <version> must be a valid branch, tag or commit.
EOF
		return 1
	fi
	ZSH="$ZSH" command zsh -f "$ZSH/tools/changelog.sh" "$version" "${2:-}" "$format"
}
_omz::confirm () {
	if [[ -n "$1" ]]
	then
		_omz::log prompt "$1" "${${functrace[1]#_}%:*}"
	fi
	read -r -k 1
	if [[ "$REPLY" != $'\n' ]]
	then
		echo
	fi
}
_omz::help () {
	cat >&2 <<EOF
Usage: omz <command> [options]

Available commands:

  help                Print this help message
  changelog           Print the changelog
  plugin <command>    Manage plugins
  pr     <command>    Manage Oh My Zsh Pull Requests
  reload              Reload the current zsh session
  shop                Open the Oh My Zsh shop
  theme  <command>    Manage themes
  update              Update Oh My Zsh
  version             Show the version

EOF
}
_omz::log () {
	setopt localoptions nopromptsubst
	local logtype=$1 
	local logname=${3:-${${functrace[1]#_}%:*}} 
	if [[ $logtype = debug && -z $_OMZ_DEBUG ]]
	then
		return
	fi
	case "$logtype" in
		(prompt) print -Pn "%S%F{blue}$logname%f%s: $2" ;;
		(debug) print -P "%F{white}$logname%f: $2" ;;
		(info) print -P "%F{green}$logname%f: $2" ;;
		(warn) print -P "%S%F{yellow}$logname%f%s: $2" ;;
		(error) print -P "%S%F{red}$logname%f%s: $2" ;;
	esac >&2
}
_omz::plugin () {
	(( $# > 0 && $+functions[$0::$1] )) || {
		cat >&2 <<EOF
Usage: ${(j: :)${(s.::.)0#_}} <command> [options]

Available commands:

  disable <plugin> Disable plugin(s)
  enable <plugin>  Enable plugin(s)
  info <plugin>    Get information of a plugin
  list [--enabled] List Oh My Zsh plugins
  load <plugin>    Load plugin(s)

EOF
		return 1
	}
	local command="$1" 
	shift
	$0::$command "$@"
}
_omz::plugin::disable () {
	if [[ -z "$1" ]]
	then
		echo "Usage: ${(j: :)${(s.::.)0#_}} <plugin> [...]" >&2
		return 1
	fi
	local -a dis_plugins
	for plugin in "$@"
	do
		if [[ ${plugins[(Ie)$plugin]} -eq 0 ]]
		then
			_omz::log warn "plugin '$plugin' is not enabled."
			continue
		fi
		dis_plugins+=("$plugin") 
	done
	if [[ ${#dis_plugins} -eq 0 ]]
	then
		return 1
	fi
	local awk_subst_plugins="  gsub(/[ \t]+(${(j:|:)dis_plugins})[ \t]+/, \" \") # with spaces before or after
  gsub(/[ \t]+(${(j:|:)dis_plugins})$/, \"\")       # with spaces before and EOL
  gsub(/^(${(j:|:)dis_plugins})[ \t]+/, \"\")       # with BOL and spaces after

  gsub(/\((${(j:|:)dis_plugins})[ \t]+/, \"(\")     # with parenthesis before and spaces after
  gsub(/[ \t]+(${(j:|:)dis_plugins})\)/, \")\")     # with spaces before or parenthesis after
  gsub(/\((${(j:|:)dis_plugins})\)/, \"()\")        # with only parentheses

  gsub(/^(${(j:|:)dis_plugins})\)/, \")\")          # with BOL and closing parenthesis
  gsub(/\((${(j:|:)dis_plugins})$/, \"(\")          # with opening parenthesis and EOL
" 
	local awk_script="
# if plugins=() is in oneline form, substitute disabled plugins and go to next line
/^[ \t]*plugins=\([^#]+\).*\$/ {
  $awk_subst_plugins
  print \$0
  next
}

# if plugins=() is in multiline form, enable multi flag and disable plugins if they're there
/^[ \t]*plugins=\(/ {
  multi=1
  $awk_subst_plugins
  print \$0
  next
}

# if multi flag is enabled and we find a valid closing parenthesis, remove plugins and disable multi flag
multi == 1 && /^[^#]*\)/ {
  multi=0
  $awk_subst_plugins
  print \$0
  next
}

multi == 1 && length(\$0) > 0 {
  $awk_subst_plugins
  if (length(\$0) > 0) print \$0
  next
}

{ print \$0 }
" 
	local zdot="${ZDOTDIR:-$HOME}" 
	local zshrc="${${:-"${zdot}/.zshrc"}:A}" 
	awk "$awk_script" "$zshrc" > "$zdot/.zshrc.new" && command cp -f "$zshrc" "$zdot/.zshrc.bck" && command mv -f "$zdot/.zshrc.new" "$zshrc"
	[[ $? -eq 0 ]] || {
		local ret=$? 
		_omz::log error "error disabling plugins."
		return $ret
	}
	if ! command zsh -n "$zdot/.zshrc"
	then
		_omz::log error "broken syntax in '"${zdot/#$HOME/\~}/.zshrc"'. Rolling back changes..."
		command mv -f "$zdot/.zshrc.bck" "$zshrc"
		return 1
	fi
	_omz::log info "plugins disabled: ${(j:, :)dis_plugins}."
	[[ ! -o interactive ]] || _omz::reload
}
_omz::plugin::enable () {
	if [[ -z "$1" ]]
	then
		echo "Usage: ${(j: :)${(s.::.)0#_}} <plugin> [...]" >&2
		return 1
	fi
	local -a add_plugins
	for plugin in "$@"
	do
		if [[ ${plugins[(Ie)$plugin]} -ne 0 ]]
		then
			_omz::log warn "plugin '$plugin' is already enabled."
			continue
		fi
		add_plugins+=("$plugin") 
	done
	if [[ ${#add_plugins} -eq 0 ]]
	then
		return 1
	fi
	local awk_script="
# if plugins=() is in oneline form, substitute ) with new plugins and go to the next line
/^[ \t]*plugins=\([^#]+\).*\$/ {
  sub(/\)/, \" $add_plugins&\")
  print \$0
  next
}

# if plugins=() is in multiline form, enable multi flag and indent by default with 2 spaces
/^[ \t]*plugins=\(/ {
  multi=1
  indent=\"  \"
  print \$0
  next
}

# if multi flag is enabled and we find a valid closing parenthesis,
# add new plugins with proper indent and disable multi flag
multi == 1 && /^[^#]*\)/ {
  multi=0
  split(\"$add_plugins\",p,\" \")
  for (i in p) {
    print indent p[i]
  }
  print \$0
  next
}

# if multi flag is enabled and we didnt find a closing parenthesis,
# get the indentation level to match when adding plugins
multi == 1 && /^[^#]*/ {
  indent=\"\"
  for (i = 1; i <= length(\$0); i++) {
    char=substr(\$0, i, 1)
    if (char == \" \" || char == \"\t\") {
      indent = indent char
    } else {
      break
    }
  }
}

{ print \$0 }
" 
	local zdot="${ZDOTDIR:-$HOME}" 
	local zshrc="${${:-"${zdot}/.zshrc"}:A}" 
	awk "$awk_script" "$zshrc" > "$zdot/.zshrc.new" && command cp -f "$zshrc" "$zdot/.zshrc.bck" && command mv -f "$zdot/.zshrc.new" "$zshrc"
	[[ $? -eq 0 ]] || {
		local ret=$? 
		_omz::log error "error enabling plugins."
		return $ret
	}
	if ! command zsh -n "$zdot/.zshrc"
	then
		_omz::log error "broken syntax in '"${zdot/#$HOME/\~}/.zshrc"'. Rolling back changes..."
		command mv -f "$zdot/.zshrc.bck" "$zshrc"
		return 1
	fi
	_omz::log info "plugins enabled: ${(j:, :)add_plugins}."
	[[ ! -o interactive ]] || _omz::reload
}
_omz::plugin::info () {
	if [[ -z "$1" ]]
	then
		echo "Usage: ${(j: :)${(s.::.)0#_}} <plugin>" >&2
		return 1
	fi
	local readme
	for readme in "$ZSH_CUSTOM/plugins/$1/README.md" "$ZSH/plugins/$1/README.md"
	do
		if [[ -f "$readme" ]]
		then
			if [[ ! -t 1 ]]
			then
				cat "$readme"
				return $?
			fi
			case 1 in
				(${+commands[glow]}) glow -p "$readme" ;;
				(${+commands[bat]}) bat -l md --style plain "$readme" ;;
				(${+commands[less]}) less "$readme" ;;
				(*) cat "$readme" ;;
			esac
			return $?
		fi
	done
	if [[ -d "$ZSH_CUSTOM/plugins/$1" || -d "$ZSH/plugins/$1" ]]
	then
		_omz::log error "the '$1' plugin doesn't have a README file"
	else
		_omz::log error "'$1' plugin not found"
	fi
	return 1
}
_omz::plugin::list () {
	local -a custom_plugins builtin_plugins
	if [[ "$1" == "--enabled" ]]
	then
		local plugin
		for plugin in "${plugins[@]}"
		do
			if [[ -d "${ZSH_CUSTOM}/plugins/${plugin}" ]]
			then
				custom_plugins+=("${plugin}") 
			elif [[ -d "${ZSH}/plugins/${plugin}" ]]
			then
				builtin_plugins+=("${plugin}") 
			fi
		done
	else
		custom_plugins=("$ZSH_CUSTOM"/plugins/*(-/N:t)) 
		builtin_plugins=("$ZSH"/plugins/*(-/N:t)) 
	fi
	if [[ ! -t 1 ]]
	then
		print -l ${(q-)custom_plugins} ${(q-)builtin_plugins}
		return
	fi
	if (( ${#custom_plugins} ))
	then
		print -P "%U%BCustom plugins%b%u:"
		print -lac ${(q-)custom_plugins}
	fi
	if (( ${#builtin_plugins} ))
	then
		(( ${#custom_plugins} )) && echo
		print -P "%U%BBuilt-in plugins%b%u:"
		print -lac ${(q-)builtin_plugins}
	fi
}
_omz::plugin::load () {
	if [[ -z "$1" ]]
	then
		echo "Usage: ${(j: :)${(s.::.)0#_}} <plugin> [...]" >&2
		return 1
	fi
	local plugin base has_completion=0 
	for plugin in "$@"
	do
		if [[ -d "$ZSH_CUSTOM/plugins/$plugin" ]]
		then
			base="$ZSH_CUSTOM/plugins/$plugin" 
		elif [[ -d "$ZSH/plugins/$plugin" ]]
		then
			base="$ZSH/plugins/$plugin" 
		else
			_omz::log warn "plugin '$plugin' not found"
			continue
		fi
		if [[ ! -f "$base/_$plugin" && ! -f "$base/$plugin.plugin.zsh" ]]
		then
			_omz::log warn "'$plugin' is not a valid plugin"
			continue
		elif (( ! ${fpath[(Ie)$base]} ))
		then
			fpath=("$base" $fpath) 
		fi
		local -a comp_files
		comp_files=($base/_*(N)) 
		has_completion=$(( $#comp_files > 0 )) 
		if [[ -f "$base/$plugin.plugin.zsh" ]]
		then
			source "$base/$plugin.plugin.zsh"
		fi
	done
	if (( has_completion ))
	then
		compinit -D -d "$_comp_dumpfile"
	fi
}
_omz::pr () {
	(( $# > 0 && $+functions[$0::$1] )) || {
		cat >&2 <<EOF
Usage: ${(j: :)${(s.::.)0#_}} <command> [options]

Available commands:

  clean                       Delete all PR branches (ohmyzsh/pull-*)
  test <PR_number_or_URL>     Fetch PR #NUMBER and rebase against master

EOF
		return 1
	}
	local command="$1" 
	shift
	$0::$command "$@"
}
_omz::pr::clean () {
	(
		set -e
		builtin cd -q "$ZSH"
		local fmt branches
		fmt="%(color:bold blue)%(align:18,right)%(refname:short)%(end)%(color:reset) %(color:dim bold red)%(objectname:short)%(color:reset) %(color:yellow)%(contents:subject)" 
		branches="$(command git for-each-ref --sort=-committerdate --color --format="$fmt" "refs/heads/ohmyzsh/pull-*")" 
		if [[ -z "$branches" ]]
		then
			_omz::log info "there are no Pull Request branches to remove."
			return
		fi
		echo "$branches\n"
		_omz::confirm "do you want remove these Pull Request branches? [Y/n] "
		[[ "$REPLY" != [yY$'\n'] ]] && return
		_omz::log info "removing all Oh My Zsh Pull Request branches..."
		command git branch --list 'ohmyzsh/pull-*' | while read branch
		do
			command git branch -D "$branch"
		done
	)
}
_omz::pr::test () {
	if [[ "$1" = https://* ]]
	then
		1="${1:t}" 
	fi
	if ! [[ -n "$1" && "$1" =~ ^[[:digit:]]+$ ]]
	then
		echo "Usage: ${(j: :)${(s.::.)0#_}} <PR_NUMBER_or_URL>" >&2
		return 1
	fi
	local branch
	branch=$(builtin cd -q "$ZSH"; git symbolic-ref --short HEAD)  || {
		_omz::log error "error when getting the current git branch. Aborting..."
		return 1
	}
	(
		set -e
		builtin cd -q "$ZSH"
		command git remote -v | while read remote url _
		do
			case "$url" in
				(https://github.com/ohmyzsh/ohmyzsh(|.git)) found=1 
					break ;;
				(git@github.com:ohmyzsh/ohmyzsh(|.git)) found=1 
					break ;;
			esac
		done
		(( $found )) || {
			_omz::log error "could not find the ohmyzsh git remote. Aborting..."
			return 1
		}
		_omz::log info "checking if PR #$1 has the 'testers needed' label..."
		local pr_json label label_id="MDU6TGFiZWw4NzY1NTkwNA==" 
		pr_json=$(
      curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/ohmyzsh/ohmyzsh/pulls/$1"
    ) 
		if [[ $? -gt 0 || -z "$pr_json" ]]
		then
			_omz::log error "error when trying to fetch PR #$1 from GitHub."
			return 1
		fi
		if (( $+commands[jq] ))
		then
			label="$(command jq ".labels.[] | select(.node_id == \"$label_id\")" <<< "$pr_json")" 
		else
			label="$(command grep "\"$label_id\"" <<< "$pr_json" 2>/dev/null)" 
		fi
		if [[ -z "$label" ]]
		then
			_omz::log warn "PR #$1 does not have the 'testers needed' label. This means that the PR"
			_omz::log warn "has not been reviewed by a maintainer and may contain malicious code."
			_omz::log prompt "Do you want to continue testing it? [yes/N] "
			builtin read -r
			if [[ "${REPLY:l}" != yes ]]
			then
				_omz::log error "PR test canceled. Please ask a maintainer to review and label the PR."
				return 1
			else
				_omz::log warn "Continuing to check out and test PR #$1. Be careful!"
			fi
		fi
		_omz::log info "fetching PR #$1 to ohmyzsh/pull-$1..."
		command git fetch -f "$remote" refs/pull/$1/head:ohmyzsh/pull-$1 || {
			_omz::log error "error when trying to fetch PR #$1."
			return 1
		}
		_omz::log info "rebasing PR #$1..."
		local ret gpgsign
		{
			gpgsign=$(command git config --local commit.gpgsign 2>/dev/null)  || ret=$? 
			[[ $ret -ne 129 ]] || gpgsign=$(command git config commit.gpgsign 2>/dev/null) 
			command git config commit.gpgsign false
			command git rebase master ohmyzsh/pull-$1 || {
				command git rebase --abort &> /dev/null
				_omz::log warn "could not rebase PR #$1 on top of master."
				_omz::log warn "you might not see the latest stable changes."
				_omz::log info "run \`zsh\` to test the changes."
				return 1
			}
		} always {
			case "$gpgsign" in
				("") command git config --unset commit.gpgsign ;;
				(*) command git config commit.gpgsign "$gpgsign" ;;
			esac
		}
		_omz::log info "fetch of PR #${1} successful."
	)
	[[ $? -eq 0 ]] || return 1
	_omz::log info "running \`zsh\` to test the changes. Run \`exit\` to go back."
	command zsh -l
	_omz::confirm "do you want to go back to the previous branch? [Y/n] "
	[[ "$REPLY" != [yY$'\n'] ]] && return
	(
		set -e
		builtin cd -q "$ZSH"
		command git checkout "$branch" -- || {
			_omz::log error "could not go back to the previous branch ('$branch')."
			return 1
		}
	)
}
_omz::reload () {
	command rm -f $_comp_dumpfile $ZSH_COMPDUMP
	local zsh="${ZSH_ARGZERO:-${functrace[-1]%:*}}" 
	[[ "$zsh" = -* || -o login ]] && exec -l "${zsh#-}" || exec "$zsh"
}
_omz::shop () {
	local shop_url="https://commitgoods.com/collections/oh-my-zsh" 
	_omz::log info "Opening Oh My Zsh shop in your browser..."
	_omz::log info "$shop_url"
	open_command "$shop_url"
}
_omz::theme () {
	(( $# > 0 && $+functions[$0::$1] )) || {
		cat >&2 <<EOF
Usage: ${(j: :)${(s.::.)0#_}} <command> [options]

Available commands:

  list            List all available Oh My Zsh themes
  set <theme>     Set a theme in your .zshrc file
  use <theme>     Load a theme

EOF
		return 1
	}
	local command="$1" 
	shift
	$0::$command "$@"
}
_omz::theme::list () {
	local -a custom_themes builtin_themes
	custom_themes=("$ZSH_CUSTOM"/**/*.zsh-theme(-.N:r:gs:"$ZSH_CUSTOM"/themes/:::gs:"$ZSH_CUSTOM"/:::)) 
	builtin_themes=("$ZSH"/themes/*.zsh-theme(-.N:t:r)) 
	if [[ ! -t 1 ]]
	then
		print -l ${(q-)custom_themes} ${(q-)builtin_themes}
		return
	fi
	if [[ -n "$ZSH_THEME" ]]
	then
		print -Pn "%U%BCurrent theme%b%u: "
		[[ $ZSH_THEME = random ]] && echo "$RANDOM_THEME (via random)" || echo "$ZSH_THEME"
		echo
	fi
	if (( ${#custom_themes} ))
	then
		print -P "%U%BCustom themes%b%u:"
		print -lac ${(q-)custom_themes}
		echo
	fi
	print -P "%U%BBuilt-in themes%b%u:"
	print -lac ${(q-)builtin_themes}
}
_omz::theme::set () {
	if [[ -z "$1" ]]
	then
		echo "Usage: ${(j: :)${(s.::.)0#_}} <theme>" >&2
		return 1
	fi
	if [[ ! -f "$ZSH_CUSTOM/$1.zsh-theme" ]] && [[ ! -f "$ZSH_CUSTOM/themes/$1.zsh-theme" ]] && [[ ! -f "$ZSH/themes/$1.zsh-theme" ]]
	then
		_omz::log error "%B$1%b theme not found"
		return 1
	fi
	local awk_script='
!set && /^[ \t]*ZSH_THEME=[^#]+.*$/ {
  set=1
  sub(/^[ \t]*ZSH_THEME=[^#]+.*$/, "ZSH_THEME=\"'$1'\" # set by `omz`")
  print $0
  next
}

{ print $0 }

END {
  # If no ZSH_THEME= line was found, return an error
  if (!set) exit 1
}
' 
	local zdot="${ZDOTDIR:-$HOME}" 
	local zshrc="${${:-"${zdot}/.zshrc"}:A}" 
	awk "$awk_script" "$zshrc" > "$zdot/.zshrc.new" || {
		cat <<EOF
ZSH_THEME="$1" # set by \`omz\`

EOF
		cat "$zdot/.zshrc"
	} > "$zdot/.zshrc.new" && command cp -f "$zshrc" "$zdot/.zshrc.bck" && command mv -f "$zdot/.zshrc.new" "$zshrc"
	[[ $? -eq 0 ]] || {
		local ret=$? 
		_omz::log error "error setting theme."
		return $ret
	}
	if ! command zsh -n "$zdot/.zshrc"
	then
		_omz::log error "broken syntax in '"${zdot/#$HOME/\~}/.zshrc"'. Rolling back changes..."
		command mv -f "$zdot/.zshrc.bck" "$zshrc"
		return 1
	fi
	_omz::log info "'$1' theme set correctly."
	[[ ! -o interactive ]] || _omz::reload
}
_omz::theme::use () {
	if [[ -z "$1" ]]
	then
		echo "Usage: ${(j: :)${(s.::.)0#_}} <theme>" >&2
		return 1
	fi
	if [[ -f "$ZSH_CUSTOM/$1.zsh-theme" ]]
	then
		source "$ZSH_CUSTOM/$1.zsh-theme"
	elif [[ -f "$ZSH_CUSTOM/themes/$1.zsh-theme" ]]
	then
		source "$ZSH_CUSTOM/themes/$1.zsh-theme"
	elif [[ -f "$ZSH/themes/$1.zsh-theme" ]]
	then
		source "$ZSH/themes/$1.zsh-theme"
	else
		_omz::log error "%B$1%b theme not found"
		return 1
	fi
	ZSH_THEME="$1" 
	[[ $1 = random ]] || unset RANDOM_THEME
}
_omz::update () {
	(( $+commands[git] )) || {
		_omz::log error "git is not installed. Aborting..."
		return 1
	}
	[[ "$1" != --unattended ]] || {
		_omz::log error "the \`\e[2m--unattended\e[0m\` flag is no longer supported, use the \`\e[2mupgrade.sh\e[0m\` script instead."
		_omz::log error "for more information see https://github.com/ohmyzsh/ohmyzsh/wiki/FAQ#how-do-i-update-oh-my-zsh"
		return 1
	}
	local last_commit=$(builtin cd -q "$ZSH"; git rev-parse HEAD 2>/dev/null) 
	[[ $? -eq 0 ]] || {
		_omz::log error "\`$ZSH\` is not a git directory. Aborting..."
		return 1
	}
	zstyle -s ':omz:update' verbose verbose_mode || verbose_mode=default 
	ZSH="$ZSH" command zsh -f "$ZSH/tools/upgrade.sh" -i -v $verbose_mode || return $?
	zmodload zsh/datetime
	echo "LAST_EPOCH=$(( EPOCHSECONDS / 60 / 60 / 24 ))" >| "${ZSH_CACHE_DIR}/.zsh-update"
	command rm -rf "$ZSH/log/update.lock"
	if [[ "$(builtin cd -q "$ZSH"; git rev-parse HEAD)" != "$last_commit" ]]
	then
		local zsh="${ZSH_ARGZERO:-${functrace[-1]%:*}}" 
		[[ "$zsh" = -* || -o login ]] && exec -l "${zsh#-}" || exec "$zsh"
	fi
}
_omz::version () {
	(
		builtin cd -q "$ZSH"
		local version
		version=$(command git describe --tags HEAD 2>/dev/null)  || version=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null)  || version=$(command git name-rev --no-undefined --name-only --exclude="remotes/*" HEAD 2>/dev/null)  || version="<detached>" 
		local commit=$(command git rev-parse --short HEAD 2>/dev/null) 
		printf "%s (%s)\n" "$version" "$commit"
	)
}
_omz_async_callback () {
	emulate -L zsh
	local fd=$1 
	local err=$2 
	if [[ -z "$err" || "$err" == "hup" ]]
	then
		local handler="${(k)_OMZ_ASYNC_FDS[(r)$fd]}" 
		local old_output="${_OMZ_ASYNC_OUTPUT[$handler]}" 
		IFS= read -r -u $fd -d '' "_OMZ_ASYNC_OUTPUT[$handler]"
		if [[ "$old_output" != "${_OMZ_ASYNC_OUTPUT[$handler]}" ]]
		then
			zle .reset-prompt
			zle -R
		fi
		exec {fd}<&-
	fi
	zle -F "$fd"
	_OMZ_ASYNC_FDS[$handler]=-1 
	_OMZ_ASYNC_PIDS[$handler]=-1 
}
_omz_async_request () {
	setopt localoptions noksharrays unset
	local -i ret=$? 
	typeset -gA _OMZ_ASYNC_FDS _OMZ_ASYNC_PIDS _OMZ_ASYNC_OUTPUT
	local handler
	for handler in ${_omz_async_functions}
	do
		(( ${+functions[$handler]} )) || continue
		local fd=${_OMZ_ASYNC_FDS[$handler]:--1} 
		local pid=${_OMZ_ASYNC_PIDS[$handler]:--1} 
		if (( fd != -1 && pid != -1 )) && {
				true <&$fd
			} 2> /dev/null
		then
			exec {fd}<&-
			zle -F $fd
			if [[ -o MONITOR ]]
			then
				kill -TERM -$pid 2> /dev/null
			else
				kill -TERM $pid 2> /dev/null
			fi
		fi
		_OMZ_ASYNC_FDS[$handler]=-1 
		_OMZ_ASYNC_PIDS[$handler]=-1 
		exec {fd}< <(
      # Tell parent process our PID
      builtin echo ${sysparams[pid]}
      # Set exit code for the handler if used
      () { return $ret }
      # Run the async function handler
      $handler
    )
		_OMZ_ASYNC_FDS[$handler]=$fd 
		is-at-least 5.8 || command true
		read -u $fd "_OMZ_ASYNC_PIDS[$handler]"
		zle -F "$fd" _omz_async_callback
	done
}
_omz_diag_dump_check_core_commands () {
	builtin echo "Core command check:"
	local redefined name builtins externals reserved_words
	redefined=() 
	reserved_words=(do done esac then elif else fi for case if while function repeat time until select coproc nocorrect foreach end '!' '[[' '{' '}') 
	builtins=(alias autoload bg bindkey break builtin bye cd chdir command comparguments compcall compctl compdescribe compfiles compgroups compquote comptags comptry compvalues continue dirs disable disown echo echotc echoti emulate enable eval exec exit false fc fg functions getln getopts hash jobs kill let limit log logout noglob popd print printf pushd pushln pwd r read rehash return sched set setopt shift source suspend test times trap true ttyctl type ulimit umask unalias unfunction unhash unlimit unset unsetopt vared wait whence where which zcompile zle zmodload zparseopts zregexparse zstyle) 
	if is-at-least 5.1
	then
		reserved_word+=(declare export integer float local readonly typeset) 
	else
		builtins+=(declare export integer float local readonly typeset) 
	fi
	builtins_fatal=(builtin command local) 
	externals=(zsh) 
	for name in $reserved_words
	do
		if [[ $(builtin whence -w $name) != "$name: reserved" ]]
		then
			builtin echo "reserved word '$name' has been redefined"
			builtin which $name
			redefined+=$name 
		fi
	done
	for name in $builtins
	do
		if [[ $(builtin whence -w $name) != "$name: builtin" ]]
		then
			builtin echo "builtin '$name' has been redefined"
			builtin which $name
			redefined+=$name 
		fi
	done
	for name in $externals
	do
		if [[ $(builtin whence -w $name) != "$name: command" ]]
		then
			builtin echo "command '$name' has been redefined"
			builtin which $name
			redefined+=$name 
		fi
	done
	if [[ -n "$redefined" ]]
	then
		builtin echo "SOME CORE COMMANDS HAVE BEEN REDEFINED: $redefined"
	else
		builtin echo "All core commands are defined normally"
	fi
}
_omz_diag_dump_echo_file_w_header () {
	local file=$1 
	if [[ -f $file || -h $file ]]
	then
		builtin echo "========== $file =========="
		if [[ -h $file ]]
		then
			builtin echo "==========    ( => ${file:A} )   =========="
		fi
		command cat $file
		builtin echo "========== end $file =========="
		builtin echo
	elif [[ -d $file ]]
	then
		builtin echo "File '$file' is a directory"
	elif [[ ! -e $file ]]
	then
		builtin echo "File '$file' does not exist"
	else
		command ls -lad "$file"
	fi
}
_omz_diag_dump_one_big_text () {
	local program programs progfile md5
	builtin echo oh-my-zsh diagnostic dump
	builtin echo
	builtin echo $outfile
	builtin echo
	command date
	command uname -a
	builtin echo OSTYPE=$OSTYPE
	builtin echo ZSH_VERSION=$ZSH_VERSION
	builtin echo User: $USERNAME
	builtin echo umask: $(umask)
	builtin echo
	_omz_diag_dump_os_specific_version
	builtin echo
	programs=(sh zsh ksh bash sed cat grep ls find git posh) 
	local progfile="" extra_str="" sha_str="" 
	for program in $programs
	do
		extra_str="" sha_str="" 
		progfile=$(builtin which $program) 
		if [[ $? == 0 ]]
		then
			if [[ -e $progfile ]]
			then
				if builtin whence shasum &> /dev/null
				then
					sha_str=($(command shasum $progfile)) 
					sha_str=$sha_str[1] 
					extra_str+=" SHA $sha_str" 
				fi
				if [[ -h "$progfile" ]]
				then
					extra_str+=" ( -> ${progfile:A} )" 
				fi
			fi
			builtin printf '%-9s %-20s %s\n' "$program is" "$progfile" "$extra_str"
		else
			builtin echo "$program: not found"
		fi
	done
	builtin echo
	builtin echo Command Versions:
	builtin echo "zsh: $(zsh --version)"
	builtin echo "this zsh session: $ZSH_VERSION"
	builtin echo "bash: $(bash --version | command grep bash)"
	builtin echo "git: $(git --version)"
	builtin echo "grep: $(grep --version)"
	builtin echo
	_omz_diag_dump_check_core_commands || return 1
	builtin echo
	builtin echo Process state:
	builtin echo pwd: $PWD
	if builtin whence pstree &> /dev/null
	then
		builtin echo Process tree for this shell:
		pstree -p $$
	else
		ps -fT
	fi
	builtin set | command grep -a '^\(ZSH\|plugins\|TERM\|LC_\|LANG\|precmd\|chpwd\|preexec\|FPATH\|TTY\|DISPLAY\|PATH\)\|OMZ'
	builtin echo
	builtin echo Exported:
	builtin echo $(builtin export | command sed 's/=.*//')
	builtin echo
	builtin echo Locale:
	command locale
	builtin echo
	builtin echo Zsh configuration:
	builtin echo setopt: $(builtin setopt)
	builtin echo
	builtin echo zstyle:
	builtin zstyle
	builtin echo
	builtin echo 'compaudit output:'
	compaudit
	builtin echo
	builtin echo '$fpath directories:'
	command ls -lad $fpath
	builtin echo
	builtin echo oh-my-zsh installation:
	command ls -ld ~/.z*
	command ls -ld ~/.oh*
	builtin echo
	builtin echo oh-my-zsh git state:
	(
		builtin cd $ZSH && builtin echo "HEAD: $(git rev-parse HEAD)" && git remote -v && git status | command grep "[^[:space:]]"
	)
	if [[ $verbose -ge 1 ]]
	then
		(
			builtin cd $ZSH && git reflog --date=default | command grep pull
		)
	fi
	builtin echo
	if [[ -e $ZSH_CUSTOM ]]
	then
		local custom_dir=$ZSH_CUSTOM 
		if [[ -h $custom_dir ]]
		then
			custom_dir=$(builtin cd $custom_dir && pwd -P) 
		fi
		builtin echo "oh-my-zsh custom dir:"
		builtin echo "   $ZSH_CUSTOM ($custom_dir)"
		(
			builtin cd ${custom_dir:h} && command find ${custom_dir:t} -name .git -prune -o -print
		)
		builtin echo
	fi
	if [[ $verbose -ge 1 ]]
	then
		builtin echo "bindkey:"
		builtin bindkey
		builtin echo
		builtin echo "infocmp:"
		command infocmp -L
		builtin echo
	fi
	local zdotdir=${ZDOTDIR:-$HOME} 
	builtin echo "Zsh configuration files:"
	local cfgfile cfgfiles
	cfgfiles=(/etc/zshenv /etc/zprofile /etc/zshrc /etc/zlogin /etc/zlogout $zdotdir/.zshenv $zdotdir/.zprofile $zdotdir/.zshrc $zdotdir/.zlogin $zdotdir/.zlogout ~/.zsh.pre-oh-my-zsh /etc/bashrc /etc/profile ~/.bashrc ~/.profile ~/.bash_profile ~/.bash_logout) 
	command ls -lad $cfgfiles 2>&1
	builtin echo
	if [[ $verbose -ge 1 ]]
	then
		for cfgfile in $cfgfiles
		do
			_omz_diag_dump_echo_file_w_header $cfgfile
		done
	fi
	builtin echo
	builtin echo "Zsh compdump files:"
	local dumpfile dumpfiles
	command ls -lad $zdotdir/.zcompdump*
	dumpfiles=($zdotdir/.zcompdump*(N)) 
	if [[ $verbose -ge 2 ]]
	then
		for dumpfile in $dumpfiles
		do
			_omz_diag_dump_echo_file_w_header $dumpfile
		done
	fi
}
_omz_diag_dump_os_specific_version () {
	local osname osver version_file version_files
	case "$OSTYPE" in
		(darwin*) osname=$(command sw_vers -productName) 
			osver=$(command sw_vers -productVersion) 
			builtin echo "OS Version: $osname $osver build $(sw_vers -buildVersion)" ;;
		(cygwin) command systeminfo | command head -n 4 | command tail -n 2 ;;
	esac
	if builtin which lsb_release > /dev/null
	then
		builtin echo "OS Release: $(command lsb_release -s -d)"
	fi
	version_files=(/etc/*-release(N) /etc/*-version(N) /etc/*_version(N)) 
	for version_file in $version_files
	do
		builtin echo "$version_file:"
		command cat "$version_file"
		builtin echo
	done
}
_omz_git_prompt_info () {
	if ! __git_prompt_git rev-parse --git-dir &> /dev/null || [[ "$(__git_prompt_git config --get oh-my-zsh.hide-info 2>/dev/null)" == 1 ]]
	then
		return 0
	fi
	local ref
	ref=$(__git_prompt_git symbolic-ref --short HEAD 2> /dev/null)  || ref=$(__git_prompt_git describe --tags --exact-match HEAD 2> /dev/null)  || ref=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null)  || return 0
	local upstream
	if (( ${+ZSH_THEME_GIT_SHOW_UPSTREAM} ))
	then
		upstream=$(__git_prompt_git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null)  && upstream=" -> ${upstream}" 
	fi
	echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref:gs/%/%%}${upstream:gs/%/%%}$(parse_git_dirty)${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}
_omz_git_prompt_status () {
	[[ "$(__git_prompt_git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]] && return
	local -A prefix_constant_map
	prefix_constant_map=('\?\? ' 'UNTRACKED' 'A  ' 'ADDED' 'M  ' 'MODIFIED' 'MM ' 'MODIFIED' ' M ' 'MODIFIED' 'AM ' 'MODIFIED' ' T ' 'MODIFIED' 'R  ' 'RENAMED' ' D ' 'DELETED' 'D  ' 'DELETED' 'UU ' 'UNMERGED' 'ahead' 'AHEAD' 'behind' 'BEHIND' 'diverged' 'DIVERGED' 'stashed' 'STASHED') 
	local -A constant_prompt_map
	constant_prompt_map=('UNTRACKED' "$ZSH_THEME_GIT_PROMPT_UNTRACKED" 'ADDED' "$ZSH_THEME_GIT_PROMPT_ADDED" 'MODIFIED' "$ZSH_THEME_GIT_PROMPT_MODIFIED" 'RENAMED' "$ZSH_THEME_GIT_PROMPT_RENAMED" 'DELETED' "$ZSH_THEME_GIT_PROMPT_DELETED" 'UNMERGED' "$ZSH_THEME_GIT_PROMPT_UNMERGED" 'AHEAD' "$ZSH_THEME_GIT_PROMPT_AHEAD" 'BEHIND' "$ZSH_THEME_GIT_PROMPT_BEHIND" 'DIVERGED' "$ZSH_THEME_GIT_PROMPT_DIVERGED" 'STASHED' "$ZSH_THEME_GIT_PROMPT_STASHED") 
	local status_constants
	status_constants=(UNTRACKED ADDED MODIFIED RENAMED DELETED STASHED UNMERGED AHEAD BEHIND DIVERGED) 
	local status_text
	status_text="$(__git_prompt_git status --porcelain -b 2> /dev/null)" 
	if [[ $? -eq 128 ]]
	then
		return 1
	fi
	local -A statuses_seen
	if __git_prompt_git rev-parse --verify refs/stash &> /dev/null
	then
		statuses_seen[STASHED]=1 
	fi
	local status_lines
	status_lines=("${(@f)${status_text}}") 
	if [[ "$status_lines[1]" =~ "^## [^ ]+ \[(.*)\]" ]]
	then
		local branch_statuses
		branch_statuses=("${(@s/,/)match}") 
		for branch_status in $branch_statuses
		do
			if [[ ! $branch_status =~ "(behind|diverged|ahead) ([0-9]+)?" ]]
			then
				continue
			fi
			local last_parsed_status=$prefix_constant_map[$match[1]] 
			statuses_seen[$last_parsed_status]=$match[2] 
		done
	fi
	for status_prefix in "${(@k)prefix_constant_map}"
	do
		local status_constant="${prefix_constant_map[$status_prefix]}" 
		local status_regex=$'(^|\n)'"$status_prefix" 
		if [[ "$status_text" =~ $status_regex ]]
		then
			statuses_seen[$status_constant]=1 
		fi
	done
	local status_prompt
	for status_constant in $status_constants
	do
		if (( ${+statuses_seen[$status_constant]} ))
		then
			local next_display=$constant_prompt_map[$status_constant] 
			status_prompt="$next_display$status_prompt" 
		fi
	done
	echo $status_prompt
}
_omz_register_handler () {
	setopt localoptions noksharrays unset
	typeset -ga _omz_async_functions
	if [[ -z "$1" ]] || (( ! ${+functions[$1]} )) || (( ${_omz_async_functions[(Ie)$1]} ))
	then
		return
	fi
	_omz_async_functions+=("$1") 
	if (( ! ${precmd_functions[(Ie)_omz_async_request]} )) && (( ${+functions[_omz_async_request]}))
	then
		autoload -Uz add-zsh-hook
		add-zsh-hook precmd _omz_async_request
	fi
}
_omz_source () {
	local context filepath="$1" 
	case "$filepath" in
		(lib/*) context="lib:${filepath:t:r}"  ;;
		(plugins/*) context="plugins:${filepath:h:t}"  ;;
	esac
	local disable_aliases=0 
	zstyle -T ":omz:${context}" aliases || disable_aliases=1 
	local -A aliases_pre galiases_pre
	if (( disable_aliases ))
	then
		aliases_pre=("${(@kv)aliases}") 
		galiases_pre=("${(@kv)galiases}") 
	fi
	if [[ -f "$ZSH_CUSTOM/$filepath" ]]
	then
		source "$ZSH_CUSTOM/$filepath"
	elif [[ -f "$ZSH/$filepath" ]]
	then
		source "$ZSH/$filepath"
	fi
	if (( disable_aliases ))
	then
		if (( #aliases_pre ))
		then
			aliases=("${(@kv)aliases_pre}") 
		else
			(( #aliases )) && unalias "${(@k)aliases}"
		fi
		if (( #galiases_pre ))
		then
			galiases=("${(@kv)galiases_pre}") 
		else
			(( #galiases )) && unalias "${(@k)galiases}"
		fi
	fi
}
_open () {
	# undefined
	builtin autoload -XUz
}
_openstack () {
	# undefined
	builtin autoload -XUz
}
_opkg () {
	# undefined
	builtin autoload -XUz
}
_options () {
	# undefined
	builtin autoload -XUz
}
_options_set () {
	# undefined
	builtin autoload -XUz
}
_options_unset () {
	# undefined
	builtin autoload -XUz
}
_opustools () {
	# undefined
	builtin autoload -XUz
}
_osascript () {
	# undefined
	builtin autoload -XUz
}
_osc () {
	# undefined
	builtin autoload -XUz
}
_other_accounts () {
	# undefined
	builtin autoload -XUz
}
_otool () {
	# undefined
	builtin autoload -XUz
}
_p11-kit () {
	# undefined
	builtin autoload -XUz
}
_pack () {
	# undefined
	builtin autoload -XUz
}
_pandoc () {
	# undefined
	builtin autoload -XUz
}
_parameter () {
	# undefined
	builtin autoload -XUz
}
_parameters () {
	# undefined
	builtin autoload -XUz
}
_paste () {
	# undefined
	builtin autoload -XUz
}
_patch () {
	# undefined
	builtin autoload -XUz
}
_patchutils () {
	# undefined
	builtin autoload -XUz
}
_path_commands () {
	# undefined
	builtin autoload -XUz
}
_path_files () {
	# undefined
	builtin autoload -XUz
}
_pax () {
	# undefined
	builtin autoload -XUz
}
_pbcopy () {
	# undefined
	builtin autoload -XUz
}
_pbm () {
	# undefined
	builtin autoload -XUz
}
_pbuilder () {
	# undefined
	builtin autoload -XUz
}
_pdf () {
	# undefined
	builtin autoload -XUz
}
_pdftk () {
	# undefined
	builtin autoload -XUz
}
_perf () {
	# undefined
	builtin autoload -XUz
}
_perforce () {
	# undefined
	builtin autoload -XUz
}
_perl () {
	# undefined
	builtin autoload -XUz
}
_perl_basepods () {
	# undefined
	builtin autoload -XUz
}
_perl_modules () {
	# undefined
	builtin autoload -XUz
}
_perldoc () {
	# undefined
	builtin autoload -XUz
}
_pfctl () {
	# undefined
	builtin autoload -XUz
}
_pfexec () {
	# undefined
	builtin autoload -XUz
}
_pgids () {
	# undefined
	builtin autoload -XUz
}
_pgrep () {
	# undefined
	builtin autoload -XUz
}
_php () {
	# undefined
	builtin autoload -XUz
}
_physical_volumes () {
	# undefined
	builtin autoload -XUz
}
_pick_variant () {
	# undefined
	builtin autoload -XUz
}
_picocom () {
	# undefined
	builtin autoload -XUz
}
_pidof () {
	# undefined
	builtin autoload -XUz
}
_pids () {
	# undefined
	builtin autoload -XUz
}
_pine () {
	# undefined
	builtin autoload -XUz
}
_ping () {
	# undefined
	builtin autoload -XUz
}
_pip () {
	# undefined
	builtin autoload -XUz
}
_pipx () {
	# undefined
	builtin autoload -XUz
}
_piuparts () {
	# undefined
	builtin autoload -XUz
}
_pkg-config () {
	# undefined
	builtin autoload -XUz
}
_pkg5 () {
	# undefined
	builtin autoload -XUz
}
_pkg_instance () {
	# undefined
	builtin autoload -XUz
}
_pkgadd () {
	# undefined
	builtin autoload -XUz
}
_pkgin () {
	# undefined
	builtin autoload -XUz
}
_pkginfo () {
	# undefined
	builtin autoload -XUz
}
_pkgrm () {
	# undefined
	builtin autoload -XUz
}
_pkgtool () {
	# undefined
	builtin autoload -XUz
}
_plutil () {
	# undefined
	builtin autoload -XUz
}
_pmap () {
	# undefined
	builtin autoload -XUz
}
_pon () {
	# undefined
	builtin autoload -XUz
}
_portaudit () {
	# undefined
	builtin autoload -XUz
}
_portlint () {
	# undefined
	builtin autoload -XUz
}
_portmaster () {
	# undefined
	builtin autoload -XUz
}
_ports () {
	# undefined
	builtin autoload -XUz
}
_portsnap () {
	# undefined
	builtin autoload -XUz
}
_postfix () {
	# undefined
	builtin autoload -XUz
}
_postgresql () {
	# undefined
	builtin autoload -XUz
}
_postscript () {
	# undefined
	builtin autoload -XUz
}
_powerd () {
	# undefined
	builtin autoload -XUz
}
_pr () {
	# undefined
	builtin autoload -XUz
}
_precommand () {
	# undefined
	builtin autoload -XUz
}
_prefix () {
	# undefined
	builtin autoload -XUz
}
_print () {
	# undefined
	builtin autoload -XUz
}
_printenv () {
	# undefined
	builtin autoload -XUz
}
_printers () {
	# undefined
	builtin autoload -XUz
}
_process_names () {
	# undefined
	builtin autoload -XUz
}
_procstat () {
	# undefined
	builtin autoload -XUz
}
_prompt () {
	# undefined
	builtin autoload -XUz
}
_prove () {
	# undefined
	builtin autoload -XUz
}
_prstat () {
	# undefined
	builtin autoload -XUz
}
_ps () {
	# undefined
	builtin autoload -XUz
}
_ps1234 () {
	# undefined
	builtin autoload -XUz
}
_pscp () {
	# undefined
	builtin autoload -XUz
}
_pspdf () {
	# undefined
	builtin autoload -XUz
}
_psutils () {
	# undefined
	builtin autoload -XUz
}
_ptree () {
	# undefined
	builtin autoload -XUz
}
_ptx () {
	# undefined
	builtin autoload -XUz
}
_pump () {
	# undefined
	builtin autoload -XUz
}
_putclip () {
	# undefined
	builtin autoload -XUz
}
_pv () {
	# undefined
	builtin autoload -XUz
}
_pwgen () {
	# undefined
	builtin autoload -XUz
}
_pydoc () {
	# undefined
	builtin autoload -XUz
}
_python () {
	# undefined
	builtin autoload -XUz
}
_python_modules () {
	# undefined
	builtin autoload -XUz
}
_qdbus () {
	# undefined
	builtin autoload -XUz
}
_qemu () {
	# undefined
	builtin autoload -XUz
}
_qiv () {
	# undefined
	builtin autoload -XUz
}
_qtplay () {
	# undefined
	builtin autoload -XUz
}
_quilt () {
	# undefined
	builtin autoload -XUz
}
_railway () {
	# undefined
	builtin autoload -XUz
}
_rake () {
	# undefined
	builtin autoload -XUz
}
_ranlib () {
	# undefined
	builtin autoload -XUz
}
_rar () {
	# undefined
	builtin autoload -XUz
}
_rcctl () {
	# undefined
	builtin autoload -XUz
}
_rclone () {
	# undefined
	builtin autoload -XUz
}
_rcs () {
	# undefined
	builtin autoload -XUz
}
_rdesktop () {
	# undefined
	builtin autoload -XUz
}
_read () {
	# undefined
	builtin autoload -XUz
}
_read_comp () {
	# undefined
	builtin autoload -XUz
}
_readelf () {
	# undefined
	builtin autoload -XUz
}
_readlink () {
	# undefined
	builtin autoload -XUz
}
_readshortcut () {
	# undefined
	builtin autoload -XUz
}
_rebootin () {
	# undefined
	builtin autoload -XUz
}
_redirect () {
	# undefined
	builtin autoload -XUz
}
_regex_arguments () {
	# undefined
	builtin autoload -XUz
}
_regex_words () {
	# undefined
	builtin autoload -XUz
}
_remote_files () {
	# undefined
	builtin autoload -XUz
}
_renice () {
	# undefined
	builtin autoload -XUz
}
_reprepro () {
	# undefined
	builtin autoload -XUz
}
_requested () {
	# undefined
	builtin autoload -XUz
}
_retrieve_cache () {
	# undefined
	builtin autoload -XUz
}
_retrieve_mac_apps () {
	# undefined
	builtin autoload -XUz
}
_ri () {
	# undefined
	builtin autoload -XUz
}
_rlogin () {
	# undefined
	builtin autoload -XUz
}
_rm () {
	# undefined
	builtin autoload -XUz
}
_rmdir () {
	# undefined
	builtin autoload -XUz
}
_route () {
	# undefined
	builtin autoload -XUz
}
_routing_domains () {
	# undefined
	builtin autoload -XUz
}
_routing_tables () {
	# undefined
	builtin autoload -XUz
}
_rpm () {
	# undefined
	builtin autoload -XUz
}
_rrdtool () {
	# undefined
	builtin autoload -XUz
}
_rsync () {
	# undefined
	builtin autoload -XUz
}
_rubber () {
	# undefined
	builtin autoload -XUz
}
_ruby () {
	# undefined
	builtin autoload -XUz
}
_run-help () {
	# undefined
	builtin autoload -XUz
}
_runit () {
	# undefined
	builtin autoload -XUz
}
_samba () {
	# undefined
	builtin autoload -XUz
}
_savecore () {
	# undefined
	builtin autoload -XUz
}
_say () {
	# undefined
	builtin autoload -XUz
}
_sbuild () {
	# undefined
	builtin autoload -XUz
}
_sc_usage () {
	# undefined
	builtin autoload -XUz
}
_sccs () {
	# undefined
	builtin autoload -XUz
}
_sched () {
	# undefined
	builtin autoload -XUz
}
_schedtool () {
	# undefined
	builtin autoload -XUz
}
_schroot () {
	# undefined
	builtin autoload -XUz
}
_scl () {
	# undefined
	builtin autoload -XUz
}
_scons () {
	# undefined
	builtin autoload -XUz
}
_screen () {
	# undefined
	builtin autoload -XUz
}
_script () {
	# undefined
	builtin autoload -XUz
}
_scselect () {
	# undefined
	builtin autoload -XUz
}
_scutil () {
	# undefined
	builtin autoload -XUz
}
_sdk () {
	local -r previous_word=${COMP_WORDS[COMP_CWORD - 1]} 
	local -r current_word=${COMP_WORDS[COMP_CWORD]} 
	if ((COMP_CWORD == 3))
	then
		local -r before_previous_word=${COMP_WORDS[COMP_CWORD - 2]} 
		__sdkman_complete_candidate_version "$before_previous_word" "$previous_word" "$current_word"
		return
	fi
	__sdkman_complete_command "$previous_word" "$current_word"
}
_seafile () {
	# undefined
	builtin autoload -XUz
}
_sed () {
	# undefined
	builtin autoload -XUz
}
_selinux_contexts () {
	# undefined
	builtin autoload -XUz
}
_selinux_roles () {
	# undefined
	builtin autoload -XUz
}
_selinux_types () {
	# undefined
	builtin autoload -XUz
}
_selinux_users () {
	# undefined
	builtin autoload -XUz
}
_sep_parts () {
	# undefined
	builtin autoload -XUz
}
_seq () {
	# undefined
	builtin autoload -XUz
}
_sequence () {
	# undefined
	builtin autoload -XUz
}
_service () {
	# undefined
	builtin autoload -XUz
}
_services () {
	# undefined
	builtin autoload -XUz
}
_set () {
	# undefined
	builtin autoload -XUz
}
_set_command () {
	# undefined
	builtin autoload -XUz
}
_set_remove () {
	comm -23 <(echo $1 | sort | tr " " "\n") <(echo $2 | sort | tr " " "\n") 2> /dev/null
}
_setfacl () {
	# undefined
	builtin autoload -XUz
}
_setopt () {
	# undefined
	builtin autoload -XUz
}
_setpriv () {
	# undefined
	builtin autoload -XUz
}
_setsid () {
	# undefined
	builtin autoload -XUz
}
_setup () {
	# undefined
	builtin autoload -XUz
}
_setxkbmap () {
	# undefined
	builtin autoload -XUz
}
_sh () {
	# undefined
	builtin autoload -XUz
}
_shasum () {
	# undefined
	builtin autoload -XUz
}
_showmount () {
	# undefined
	builtin autoload -XUz
}
_shred () {
	# undefined
	builtin autoload -XUz
}
_shuf () {
	# undefined
	builtin autoload -XUz
}
_shutdown () {
	# undefined
	builtin autoload -XUz
}
_signals () {
	# undefined
	builtin autoload -XUz
}
_signify () {
	# undefined
	builtin autoload -XUz
}
_sisu () {
	# undefined
	builtin autoload -XUz
}
_slabtop () {
	# undefined
	builtin autoload -XUz
}
_slrn () {
	# undefined
	builtin autoload -XUz
}
_smartmontools () {
	# undefined
	builtin autoload -XUz
}
_smit () {
	# undefined
	builtin autoload -XUz
}
_snoop () {
	# undefined
	builtin autoload -XUz
}
_socket () {
	# undefined
	builtin autoload -XUz
}
_sockstat () {
	# undefined
	builtin autoload -XUz
}
_softwareupdate () {
	# undefined
	builtin autoload -XUz
}
_sort () {
	# undefined
	builtin autoload -XUz
}
_source () {
	# undefined
	builtin autoload -XUz
}
_spamassassin () {
	# undefined
	builtin autoload -XUz
}
_split () {
	# undefined
	builtin autoload -XUz
}
_sqlite () {
	# undefined
	builtin autoload -XUz
}
_sqsh () {
	# undefined
	builtin autoload -XUz
}
_ss () {
	# undefined
	builtin autoload -XUz
}
_ssh () {
	# undefined
	builtin autoload -XUz
}
_ssh_hosts () {
	# undefined
	builtin autoload -XUz
}
_sshfs () {
	# undefined
	builtin autoload -XUz
}
_stat () {
	# undefined
	builtin autoload -XUz
}
_stdbuf () {
	# undefined
	builtin autoload -XUz
}
_stgit () {
	# undefined
	builtin autoload -XUz
}
_store_cache () {
	# undefined
	builtin autoload -XUz
}
_stow () {
	# undefined
	builtin autoload -XUz
}
_strace () {
	# undefined
	builtin autoload -XUz
}
_strftime () {
	# undefined
	builtin autoload -XUz
}
_strings () {
	# undefined
	builtin autoload -XUz
}
_strip () {
	# undefined
	builtin autoload -XUz
}
_stripe () {
	# undefined
	builtin autoload -XUz
}
_stty () {
	# undefined
	builtin autoload -XUz
}
_su () {
	# undefined
	builtin autoload -XUz
}
_sub_commands () {
	# undefined
	builtin autoload -XUz
}
_sublimetext () {
	# undefined
	builtin autoload -XUz
}
_subscript () {
	# undefined
	builtin autoload -XUz
}
_subversion () {
	# undefined
	builtin autoload -XUz
}
_sudo () {
	# undefined
	builtin autoload -XUz
}
_suffix_alias_files () {
	# undefined
	builtin autoload -XUz
}
_surfraw () {
	# undefined
	builtin autoload -XUz
}
_svcadm () {
	# undefined
	builtin autoload -XUz
}
_svccfg () {
	# undefined
	builtin autoload -XUz
}
_svcprop () {
	# undefined
	builtin autoload -XUz
}
_svcs () {
	# undefined
	builtin autoload -XUz
}
_svcs_fmri () {
	# undefined
	builtin autoload -XUz
}
_svn-buildpackage () {
	# undefined
	builtin autoload -XUz
}
_sw_vers () {
	# undefined
	builtin autoload -XUz
}
_swaks () {
	# undefined
	builtin autoload -XUz
}
_swanctl () {
	# undefined
	builtin autoload -XUz
}
_swift () {
	# undefined
	builtin autoload -XUz
}
_sys_calls () {
	# undefined
	builtin autoload -XUz
}
_sysclean () {
	# undefined
	builtin autoload -XUz
}
_sysctl () {
	# undefined
	builtin autoload -XUz
}
_sysmerge () {
	# undefined
	builtin autoload -XUz
}
_syspatch () {
	# undefined
	builtin autoload -XUz
}
_sysrc () {
	# undefined
	builtin autoload -XUz
}
_sysstat () {
	# undefined
	builtin autoload -XUz
}
_systat () {
	# undefined
	builtin autoload -XUz
}
_system_profiler () {
	# undefined
	builtin autoload -XUz
}
_sysupgrade () {
	# undefined
	builtin autoload -XUz
}
_tac () {
	# undefined
	builtin autoload -XUz
}
_tags () {
	# undefined
	builtin autoload -XUz
}
_tail () {
	# undefined
	builtin autoload -XUz
}
_tar () {
	# undefined
	builtin autoload -XUz
}
_tar_archive () {
	# undefined
	builtin autoload -XUz
}
_tardy () {
	# undefined
	builtin autoload -XUz
}
_tcpdump () {
	# undefined
	builtin autoload -XUz
}
_tcpsys () {
	# undefined
	builtin autoload -XUz
}
_tcptraceroute () {
	# undefined
	builtin autoload -XUz
}
_tee () {
	# undefined
	builtin autoload -XUz
}
_telnet () {
	# undefined
	builtin autoload -XUz
}
_terminals () {
	# undefined
	builtin autoload -XUz
}
_tex () {
	# undefined
	builtin autoload -XUz
}
_texi () {
	# undefined
	builtin autoload -XUz
}
_texinfo () {
	# undefined
	builtin autoload -XUz
}
_tidy () {
	# undefined
	builtin autoload -XUz
}
_tiff () {
	# undefined
	builtin autoload -XUz
}
_tilde () {
	# undefined
	builtin autoload -XUz
}
_tilde_files () {
	# undefined
	builtin autoload -XUz
}
_time_zone () {
	# undefined
	builtin autoload -XUz
}
_timeout () {
	# undefined
	builtin autoload -XUz
}
_tin () {
	# undefined
	builtin autoload -XUz
}
_tla () {
	# undefined
	builtin autoload -XUz
}
_tload () {
	# undefined
	builtin autoload -XUz
}
_tmux () {
	# undefined
	builtin autoload -XUz
}
_todo.sh () {
	# undefined
	builtin autoload -XUz
}
_toilet () {
	# undefined
	builtin autoload -XUz
}
_toolchain-source () {
	# undefined
	builtin autoload -XUz
}
_top () {
	# undefined
	builtin autoload -XUz
}
_topgit () {
	# undefined
	builtin autoload -XUz
}
_totd () {
	# undefined
	builtin autoload -XUz
}
_touch () {
	# undefined
	builtin autoload -XUz
}
_tpb () {
	# undefined
	builtin autoload -XUz
}
_tput () {
	# undefined
	builtin autoload -XUz
}
_tr () {
	# undefined
	builtin autoload -XUz
}
_tracepath () {
	# undefined
	builtin autoload -XUz
}
_transmission () {
	# undefined
	builtin autoload -XUz
}
_trap () {
	# undefined
	builtin autoload -XUz
}
_trash () {
	# undefined
	builtin autoload -XUz
}
_tree () {
	# undefined
	builtin autoload -XUz
}
_truncate () {
	# undefined
	builtin autoload -XUz
}
_truss () {
	# undefined
	builtin autoload -XUz
}
_trust () {
	# undefined
	builtin autoload -XUz
}
_tty () {
	# undefined
	builtin autoload -XUz
}
_ttyctl () {
	# undefined
	builtin autoload -XUz
}
_ttys () {
	# undefined
	builtin autoload -XUz
}
_tune2fs () {
	# undefined
	builtin autoload -XUz
}
_twidge () {
	# undefined
	builtin autoload -XUz
}
_twisted () {
	# undefined
	builtin autoload -XUz
}
_typeset () {
	# undefined
	builtin autoload -XUz
}
_ulimit () {
	# undefined
	builtin autoload -XUz
}
_uml () {
	# undefined
	builtin autoload -XUz
}
_umountable () {
	# undefined
	builtin autoload -XUz
}
_unace () {
	# undefined
	builtin autoload -XUz
}
_uname () {
	# undefined
	builtin autoload -XUz
}
_unexpand () {
	# undefined
	builtin autoload -XUz
}
_unhash () {
	# undefined
	builtin autoload -XUz
}
_uniq () {
	# undefined
	builtin autoload -XUz
}
_unison () {
	# undefined
	builtin autoload -XUz
}
_units () {
	# undefined
	builtin autoload -XUz
}
_unshare () {
	# undefined
	builtin autoload -XUz
}
_update-alternatives () {
	# undefined
	builtin autoload -XUz
}
_update-rc.d () {
	# undefined
	builtin autoload -XUz
}
_uptime () {
	# undefined
	builtin autoload -XUz
}
_urls () {
	# undefined
	builtin autoload -XUz
}
_urpmi () {
	# undefined
	builtin autoload -XUz
}
_urxvt () {
	# undefined
	builtin autoload -XUz
}
_usbconfig () {
	# undefined
	builtin autoload -XUz
}
_uscan () {
	# undefined
	builtin autoload -XUz
}
_user_admin () {
	# undefined
	builtin autoload -XUz
}
_user_at_host () {
	# undefined
	builtin autoload -XUz
}
_user_expand () {
	# undefined
	builtin autoload -XUz
}
_user_math_func () {
	# undefined
	builtin autoload -XUz
}
_users () {
	# undefined
	builtin autoload -XUz
}
_users_on () {
	# undefined
	builtin autoload -XUz
}
_valgrind () {
	# undefined
	builtin autoload -XUz
}
_value () {
	# undefined
	builtin autoload -XUz
}
_values () {
	# undefined
	builtin autoload -XUz
}
_vared () {
	# undefined
	builtin autoload -XUz
}
_vars () {
	# undefined
	builtin autoload -XUz
}
_vcs_info () {
	# undefined
	builtin autoload -XUz
}
_vcs_info_hooks () {
	# undefined
	builtin autoload -XUz
}
_vi () {
	# undefined
	builtin autoload -XUz
}
_vim () {
	# undefined
	builtin autoload -XUz
}
_vim-addons () {
	# undefined
	builtin autoload -XUz
}
_visudo () {
	# undefined
	builtin autoload -XUz
}
_vmctl () {
	# undefined
	builtin autoload -XUz
}
_vmstat () {
	# undefined
	builtin autoload -XUz
}
_vnc () {
	# undefined
	builtin autoload -XUz
}
_volume_groups () {
	# undefined
	builtin autoload -XUz
}
_vorbis () {
	# undefined
	builtin autoload -XUz
}
_vpnc () {
	# undefined
	builtin autoload -XUz
}
_vserver () {
	# undefined
	builtin autoload -XUz
}
_w () {
	# undefined
	builtin autoload -XUz
}
_w3m () {
	# undefined
	builtin autoload -XUz
}
_wait () {
	# undefined
	builtin autoload -XUz
}
_wajig () {
	# undefined
	builtin autoload -XUz
}
_wakeup_capable_devices () {
	# undefined
	builtin autoload -XUz
}
_wanna-build () {
	# undefined
	builtin autoload -XUz
}
_wanted () {
	# undefined
	builtin autoload -XUz
}
_watch () {
	# undefined
	builtin autoload -XUz
}
_watch-snoop () {
	# undefined
	builtin autoload -XUz
}
_wc () {
	# undefined
	builtin autoload -XUz
}
_webbrowser () {
	# undefined
	builtin autoload -XUz
}
_wget () {
	# undefined
	builtin autoload -XUz
}
_whereis () {
	# undefined
	builtin autoload -XUz
}
_which () {
	# undefined
	builtin autoload -XUz
}
_who () {
	# undefined
	builtin autoload -XUz
}
_whois () {
	# undefined
	builtin autoload -XUz
}
_widgets () {
	# undefined
	builtin autoload -XUz
}
_wiggle () {
	# undefined
	builtin autoload -XUz
}
_wipefs () {
	# undefined
	builtin autoload -XUz
}
_wpa_cli () {
	# undefined
	builtin autoload -XUz
}
_x_arguments () {
	# undefined
	builtin autoload -XUz
}
_x_borderwidth () {
	# undefined
	builtin autoload -XUz
}
_x_color () {
	# undefined
	builtin autoload -XUz
}
_x_colormapid () {
	# undefined
	builtin autoload -XUz
}
_x_cursor () {
	# undefined
	builtin autoload -XUz
}
_x_display () {
	# undefined
	builtin autoload -XUz
}
_x_extension () {
	# undefined
	builtin autoload -XUz
}
_x_font () {
	# undefined
	builtin autoload -XUz
}
_x_geometry () {
	# undefined
	builtin autoload -XUz
}
_x_keysym () {
	# undefined
	builtin autoload -XUz
}
_x_locale () {
	# undefined
	builtin autoload -XUz
}
_x_modifier () {
	# undefined
	builtin autoload -XUz
}
_x_name () {
	# undefined
	builtin autoload -XUz
}
_x_resource () {
	# undefined
	builtin autoload -XUz
}
_x_selection_timeout () {
	# undefined
	builtin autoload -XUz
}
_x_title () {
	# undefined
	builtin autoload -XUz
}
_x_utils () {
	# undefined
	builtin autoload -XUz
}
_x_visual () {
	# undefined
	builtin autoload -XUz
}
_x_window () {
	# undefined
	builtin autoload -XUz
}
_xargs () {
	# undefined
	builtin autoload -XUz
}
_xauth () {
	# undefined
	builtin autoload -XUz
}
_xautolock () {
	# undefined
	builtin autoload -XUz
}
_xclip () {
	# undefined
	builtin autoload -XUz
}
_xcode-select () {
	# undefined
	builtin autoload -XUz
}
_xdvi () {
	# undefined
	builtin autoload -XUz
}
_xfig () {
	# undefined
	builtin autoload -XUz
}
_xft_fonts () {
	# undefined
	builtin autoload -XUz
}
_xinput () {
	# undefined
	builtin autoload -XUz
}
_xloadimage () {
	# undefined
	builtin autoload -XUz
}
_xmlsoft () {
	# undefined
	builtin autoload -XUz
}
_xmlstarlet () {
	# undefined
	builtin autoload -XUz
}
_xmms2 () {
	# undefined
	builtin autoload -XUz
}
_xmodmap () {
	# undefined
	builtin autoload -XUz
}
_xournal () {
	# undefined
	builtin autoload -XUz
}
_xpdf () {
	# undefined
	builtin autoload -XUz
}
_xrandr () {
	# undefined
	builtin autoload -XUz
}
_xscreensaver () {
	# undefined
	builtin autoload -XUz
}
_xset () {
	# undefined
	builtin autoload -XUz
}
_xt_arguments () {
	# undefined
	builtin autoload -XUz
}
_xt_session_id () {
	# undefined
	builtin autoload -XUz
}
_xterm () {
	# undefined
	builtin autoload -XUz
}
_xv () {
	# undefined
	builtin autoload -XUz
}
_xwit () {
	# undefined
	builtin autoload -XUz
}
_xxd () {
	# undefined
	builtin autoload -XUz
}
_xz () {
	# undefined
	builtin autoload -XUz
}
_yafc () {
	# undefined
	builtin autoload -XUz
}
_yast () {
	# undefined
	builtin autoload -XUz
}
_yodl () {
	# undefined
	builtin autoload -XUz
}
_yp () {
	# undefined
	builtin autoload -XUz
}
_yum () {
	# undefined
	builtin autoload -XUz
}
_zargs () {
	# undefined
	builtin autoload -XUz
}
_zattr () {
	# undefined
	builtin autoload -XUz
}
_zcalc () {
	# undefined
	builtin autoload -XUz
}
_zcalc_line () {
	# undefined
	builtin autoload -XUz
}
_zcat () {
	# undefined
	builtin autoload -XUz
}
_zcompile () {
	# undefined
	builtin autoload -XUz
}
_zdump () {
	# undefined
	builtin autoload -XUz
}
_zeal () {
	# undefined
	builtin autoload -XUz
}
_zed () {
	# undefined
	builtin autoload -XUz
}
_zfs () {
	# undefined
	builtin autoload -XUz
}
_zfs_dataset () {
	# undefined
	builtin autoload -XUz
}
_zfs_pool () {
	# undefined
	builtin autoload -XUz
}
_zftp () {
	# undefined
	builtin autoload -XUz
}
_zip () {
	# undefined
	builtin autoload -XUz
}
_zle () {
	# undefined
	builtin autoload -XUz
}
_zlogin () {
	# undefined
	builtin autoload -XUz
}
_zmodload () {
	# undefined
	builtin autoload -XUz
}
_zmv () {
	# undefined
	builtin autoload -XUz
}
_zoneadm () {
	# undefined
	builtin autoload -XUz
}
_zones () {
	# undefined
	builtin autoload -XUz
}
_zparseopts () {
	# undefined
	builtin autoload -XUz
}
_zpty () {
	# undefined
	builtin autoload -XUz
}
_zsh () {
	# undefined
	builtin autoload -XUz
}
_zsh-mime-handler () {
	# undefined
	builtin autoload -XUz
}
_zsh_autosuggest_accept () {
	local -i retval max_cursor_pos=$#BUFFER 
	if [[ "$KEYMAP" = "vicmd" ]]
	then
		max_cursor_pos=$((max_cursor_pos - 1)) 
	fi
	if (( $CURSOR != $max_cursor_pos || !$#POSTDISPLAY ))
	then
		_zsh_autosuggest_invoke_original_widget $@
		return
	fi
	BUFFER="$BUFFER$POSTDISPLAY" 
	POSTDISPLAY= 
	_zsh_autosuggest_invoke_original_widget $@
	retval=$? 
	if [[ "$KEYMAP" = "vicmd" ]]
	then
		CURSOR=$(($#BUFFER - 1)) 
	else
		CURSOR=$#BUFFER 
	fi
	return $retval
}
_zsh_autosuggest_async_request () {
	zmodload zsh/system 2> /dev/null
	typeset -g _ZSH_AUTOSUGGEST_ASYNC_FD _ZSH_AUTOSUGGEST_CHILD_PID
	if [[ -n "$_ZSH_AUTOSUGGEST_ASYNC_FD" ]] && {
			true <&$_ZSH_AUTOSUGGEST_ASYNC_FD
		} 2> /dev/null
	then
		builtin exec {_ZSH_AUTOSUGGEST_ASYNC_FD}<&-
		zle -F $_ZSH_AUTOSUGGEST_ASYNC_FD
		if [[ -n "$_ZSH_AUTOSUGGEST_CHILD_PID" ]]
		then
			if [[ -o MONITOR ]]
			then
				kill -TERM -$_ZSH_AUTOSUGGEST_CHILD_PID 2> /dev/null
			else
				kill -TERM $_ZSH_AUTOSUGGEST_CHILD_PID 2> /dev/null
			fi
		fi
	fi
	builtin exec {_ZSH_AUTOSUGGEST_ASYNC_FD}< <(
		# Tell parent process our pid
		echo $sysparams[pid]

		# Fetch and print the suggestion
		local suggestion
		_zsh_autosuggest_fetch_suggestion "$1"
		echo -nE "$suggestion"
	)
	autoload -Uz is-at-least
	is-at-least 5.8 || command true
	read _ZSH_AUTOSUGGEST_CHILD_PID <&$_ZSH_AUTOSUGGEST_ASYNC_FD
	zle -F "$_ZSH_AUTOSUGGEST_ASYNC_FD" _zsh_autosuggest_async_response
}
_zsh_autosuggest_async_response () {
	emulate -L zsh
	local suggestion
	if [[ -z "$2" || "$2" == "hup" ]]
	then
		IFS='' read -rd '' -u $1 suggestion
		zle autosuggest-suggest -- "$suggestion"
		builtin exec {1}<&-
	fi
	zle -F "$1"
	_ZSH_AUTOSUGGEST_ASYNC_FD= 
}
_zsh_autosuggest_bind_widget () {
	typeset -gA _ZSH_AUTOSUGGEST_BIND_COUNTS
	local widget=$1 
	local autosuggest_action=$2 
	local prefix=$ZSH_AUTOSUGGEST_ORIGINAL_WIDGET_PREFIX 
	local -i bind_count
	case $widgets[$widget] in
		(user:_zsh_autosuggest_(bound|orig)_*) bind_count=$((_ZSH_AUTOSUGGEST_BIND_COUNTS[$widget]))  ;;
		(user:*) _zsh_autosuggest_incr_bind_count $widget
			zle -N $prefix$bind_count-$widget ${widgets[$widget]#*:} ;;
		(builtin) _zsh_autosuggest_incr_bind_count $widget
			eval "_zsh_autosuggest_orig_${(q)widget}() { zle .${(q)widget} }"
			zle -N $prefix$bind_count-$widget _zsh_autosuggest_orig_$widget ;;
		(completion:*) _zsh_autosuggest_incr_bind_count $widget
			eval "zle -C $prefix$bind_count-${(q)widget} ${${(s.:.)widgets[$widget]}[2,3]}" ;;
	esac
	eval "_zsh_autosuggest_bound_${bind_count}_${(q)widget}() {
		_zsh_autosuggest_widget_$autosuggest_action $prefix$bind_count-${(q)widget} \$@
	}"
	zle -N -- $widget _zsh_autosuggest_bound_${bind_count}_$widget
}
_zsh_autosuggest_bind_widgets () {
	emulate -L zsh
	local widget
	local ignore_widgets
	ignore_widgets=(.\* _\* ${_ZSH_AUTOSUGGEST_BUILTIN_ACTIONS/#/autosuggest-} $ZSH_AUTOSUGGEST_ORIGINAL_WIDGET_PREFIX\* $ZSH_AUTOSUGGEST_IGNORE_WIDGETS) 
	for widget in ${${(f)"$(builtin zle -la)"}:#${(j:|:)~ignore_widgets}}
	do
		if [[ -n ${ZSH_AUTOSUGGEST_CLEAR_WIDGETS[(r)$widget]} ]]
		then
			_zsh_autosuggest_bind_widget $widget clear
		elif [[ -n ${ZSH_AUTOSUGGEST_ACCEPT_WIDGETS[(r)$widget]} ]]
		then
			_zsh_autosuggest_bind_widget $widget accept
		elif [[ -n ${ZSH_AUTOSUGGEST_EXECUTE_WIDGETS[(r)$widget]} ]]
		then
			_zsh_autosuggest_bind_widget $widget execute
		elif [[ -n ${ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS[(r)$widget]} ]]
		then
			_zsh_autosuggest_bind_widget $widget partial_accept
		else
			_zsh_autosuggest_bind_widget $widget modify
		fi
	done
}
_zsh_autosuggest_capture_completion_async () {
	_zsh_autosuggest_capture_setup
	zmodload zsh/parameter 2> /dev/null || return
	autoload +X _complete
	functions[_original_complete]=$functions[_complete] 
	_complete () {
		unset 'compstate[vared]'
		_original_complete "$@"
	}
	vared 1
}
_zsh_autosuggest_capture_completion_sync () {
	_zsh_autosuggest_capture_setup
	zle autosuggest-capture-completion
}
_zsh_autosuggest_capture_completion_widget () {
	local -a +h comppostfuncs
	comppostfuncs=(_zsh_autosuggest_capture_postcompletion) 
	CURSOR=$#BUFFER 
	zle -- ${(k)widgets[(r)completion:.complete-word:_main_complete]}
	if is-at-least 5.0.3
	then
		stty -onlcr -ocrnl -F /dev/tty
	fi
	echo -nE - $'\0'$BUFFER$'\0'
}
_zsh_autosuggest_capture_postcompletion () {
	compstate[insert]=1 
	unset 'compstate[list]'
}
_zsh_autosuggest_capture_setup () {
	if ! is-at-least 5.4
	then
		zshexit () {
			kill -KILL $$ 2>&- || command kill -KILL $$
			sleep 1
		}
	fi
	zstyle ':completion:*' matcher-list ''
	zstyle ':completion:*' path-completion false
	zstyle ':completion:*' max-errors 0 not-numeric
	bindkey '^I' autosuggest-capture-completion
}
_zsh_autosuggest_clear () {
	POSTDISPLAY= 
	_zsh_autosuggest_invoke_original_widget $@
}
_zsh_autosuggest_disable () {
	typeset -g _ZSH_AUTOSUGGEST_DISABLED
	_zsh_autosuggest_clear
}
_zsh_autosuggest_enable () {
	unset _ZSH_AUTOSUGGEST_DISABLED
	if (( $#BUFFER ))
	then
		_zsh_autosuggest_fetch
	fi
}
_zsh_autosuggest_escape_command () {
	setopt localoptions EXTENDED_GLOB
	echo -E "${1//(#m)[\"\'\\()\[\]|*?~]/\\$MATCH}"
}
_zsh_autosuggest_execute () {
	BUFFER="$BUFFER$POSTDISPLAY" 
	POSTDISPLAY= 
	_zsh_autosuggest_invoke_original_widget "accept-line"
}
_zsh_autosuggest_fetch () {
	if (( ${+ZSH_AUTOSUGGEST_USE_ASYNC} ))
	then
		_zsh_autosuggest_async_request "$BUFFER"
	else
		local suggestion
		_zsh_autosuggest_fetch_suggestion "$BUFFER"
		_zsh_autosuggest_suggest "$suggestion"
	fi
}
_zsh_autosuggest_fetch_suggestion () {
	typeset -g suggestion
	local -a strategies
	local strategy
	strategies=(${=ZSH_AUTOSUGGEST_STRATEGY}) 
	for strategy in $strategies
	do
		_zsh_autosuggest_strategy_$strategy "$1"
		[[ "$suggestion" != "$1"* ]] && unset suggestion
		[[ -n "$suggestion" ]] && break
	done
}
_zsh_autosuggest_highlight_apply () {
	typeset -g _ZSH_AUTOSUGGEST_LAST_HIGHLIGHT
	if (( $#POSTDISPLAY ))
	then
		typeset -g _ZSH_AUTOSUGGEST_LAST_HIGHLIGHT="$#BUFFER $(($#BUFFER + $#POSTDISPLAY)) $ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" 
		region_highlight+=("$_ZSH_AUTOSUGGEST_LAST_HIGHLIGHT") 
	else
		unset _ZSH_AUTOSUGGEST_LAST_HIGHLIGHT
	fi
}
_zsh_autosuggest_highlight_reset () {
	typeset -g _ZSH_AUTOSUGGEST_LAST_HIGHLIGHT
	if [[ -n "$_ZSH_AUTOSUGGEST_LAST_HIGHLIGHT" ]]
	then
		region_highlight=("${(@)region_highlight:#$_ZSH_AUTOSUGGEST_LAST_HIGHLIGHT}") 
		unset _ZSH_AUTOSUGGEST_LAST_HIGHLIGHT
	fi
}
_zsh_autosuggest_incr_bind_count () {
	typeset -gi bind_count=$((_ZSH_AUTOSUGGEST_BIND_COUNTS[$1]+1)) 
	_ZSH_AUTOSUGGEST_BIND_COUNTS[$1]=$bind_count 
}
_zsh_autosuggest_invoke_original_widget () {
	(( $# )) || return 0
	local original_widget_name="$1" 
	shift
	if (( ${+widgets[$original_widget_name]} ))
	then
		zle $original_widget_name -- $@
	fi
}
_zsh_autosuggest_modify () {
	local -i retval
	local -i KEYS_QUEUED_COUNT
	local orig_buffer="$BUFFER" 
	local orig_postdisplay="$POSTDISPLAY" 
	POSTDISPLAY= 
	_zsh_autosuggest_invoke_original_widget $@
	retval=$? 
	emulate -L zsh
	if (( $PENDING > 0 || $KEYS_QUEUED_COUNT > 0 ))
	then
		POSTDISPLAY="$orig_postdisplay" 
		return $retval
	fi
	if [[ "$BUFFER" = "$orig_buffer"* && "$orig_postdisplay" = "${BUFFER:$#orig_buffer}"* ]]
	then
		POSTDISPLAY="${orig_postdisplay:$(($#BUFFER - $#orig_buffer))}" 
		return $retval
	fi
	if (( ${+_ZSH_AUTOSUGGEST_DISABLED} ))
	then
		return $?
	fi
	if (( $#BUFFER > 0 ))
	then
		if [[ -z "$ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE" ]] || (( $#BUFFER <= $ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE ))
		then
			_zsh_autosuggest_fetch
		fi
	fi
	return $retval
}
_zsh_autosuggest_partial_accept () {
	local -i retval cursor_loc
	local original_buffer="$BUFFER" 
	BUFFER="$BUFFER$POSTDISPLAY" 
	_zsh_autosuggest_invoke_original_widget $@
	retval=$? 
	cursor_loc=$CURSOR 
	if [[ "$KEYMAP" = "vicmd" ]]
	then
		cursor_loc=$((cursor_loc + 1)) 
	fi
	if (( $cursor_loc > $#original_buffer ))
	then
		POSTDISPLAY="${BUFFER[$(($cursor_loc + 1)),$#BUFFER]}" 
		BUFFER="${BUFFER[1,$cursor_loc]}" 
	else
		BUFFER="$original_buffer" 
	fi
	return $retval
}
_zsh_autosuggest_start () {
	if (( ${+ZSH_AUTOSUGGEST_MANUAL_REBIND} ))
	then
		add-zsh-hook -d precmd _zsh_autosuggest_start
	fi
	_zsh_autosuggest_bind_widgets
}
_zsh_autosuggest_strategy_completion () {
	emulate -L zsh
	setopt EXTENDED_GLOB
	typeset -g suggestion
	local line REPLY
	whence compdef > /dev/null || return
	zmodload zsh/zpty 2> /dev/null || return
	[[ -n "$ZSH_AUTOSUGGEST_COMPLETION_IGNORE" ]] && [[ "$1" == $~ZSH_AUTOSUGGEST_COMPLETION_IGNORE ]] && return
	if zle
	then
		zpty $ZSH_AUTOSUGGEST_COMPLETIONS_PTY_NAME _zsh_autosuggest_capture_completion_sync
	else
		zpty $ZSH_AUTOSUGGEST_COMPLETIONS_PTY_NAME _zsh_autosuggest_capture_completion_async "\$1"
		zpty -w $ZSH_AUTOSUGGEST_COMPLETIONS_PTY_NAME $'\t'
	fi
	{
		zpty -r $ZSH_AUTOSUGGEST_COMPLETIONS_PTY_NAME line '*'$'\0''*'$'\0'
		suggestion="${${(@0)line}[2]}" 
	} always {
		zpty -d $ZSH_AUTOSUGGEST_COMPLETIONS_PTY_NAME
	}
}
_zsh_autosuggest_strategy_history () {
	emulate -L zsh
	setopt EXTENDED_GLOB
	local prefix="${1//(#m)[\\*?[\]<>()|^~#]/\\$MATCH}" 
	local pattern="$prefix*" 
	if [[ -n $ZSH_AUTOSUGGEST_HISTORY_IGNORE ]]
	then
		pattern="($pattern)~($ZSH_AUTOSUGGEST_HISTORY_IGNORE)" 
	fi
	typeset -g suggestion="${history[(r)$pattern]}" 
}
_zsh_autosuggest_strategy_match_prev_cmd () {
	emulate -L zsh
	setopt EXTENDED_GLOB
	local prefix="${1//(#m)[\\*?[\]<>()|^~#]/\\$MATCH}" 
	local pattern="$prefix*" 
	if [[ -n $ZSH_AUTOSUGGEST_HISTORY_IGNORE ]]
	then
		pattern="($pattern)~($ZSH_AUTOSUGGEST_HISTORY_IGNORE)" 
	fi
	local history_match_keys
	history_match_keys=(${(k)history[(R)$~pattern]}) 
	local histkey="${history_match_keys[1]}" 
	local prev_cmd="$(_zsh_autosuggest_escape_command "${history[$((HISTCMD-1))]}")" 
	for key in "${(@)history_match_keys[1,200]}"
	do
		[[ $key -gt 1 ]] || break
		if [[ "${history[$((key - 1))]}" == "$prev_cmd" ]]
		then
			histkey="$key" 
			break
		fi
	done
	typeset -g suggestion="$history[$histkey]" 
}
_zsh_autosuggest_suggest () {
	emulate -L zsh
	local suggestion="$1" 
	if [[ -n "$suggestion" ]] && (( $#BUFFER ))
	then
		POSTDISPLAY="${suggestion#$BUFFER}" 
	else
		POSTDISPLAY= 
	fi
}
_zsh_autosuggest_toggle () {
	if (( ${+_ZSH_AUTOSUGGEST_DISABLED} ))
	then
		_zsh_autosuggest_enable
	else
		_zsh_autosuggest_disable
	fi
}
_zsh_autosuggest_widget_accept () {
	local -i retval
	_zsh_autosuggest_highlight_reset
	_zsh_autosuggest_accept $@
	retval=$? 
	_zsh_autosuggest_highlight_apply
	zle -R
	return $retval
}
_zsh_autosuggest_widget_clear () {
	local -i retval
	_zsh_autosuggest_highlight_reset
	_zsh_autosuggest_clear $@
	retval=$? 
	_zsh_autosuggest_highlight_apply
	zle -R
	return $retval
}
_zsh_autosuggest_widget_disable () {
	local -i retval
	_zsh_autosuggest_highlight_reset
	_zsh_autosuggest_disable $@
	retval=$? 
	_zsh_autosuggest_highlight_apply
	zle -R
	return $retval
}
_zsh_autosuggest_widget_enable () {
	local -i retval
	_zsh_autosuggest_highlight_reset
	_zsh_autosuggest_enable $@
	retval=$? 
	_zsh_autosuggest_highlight_apply
	zle -R
	return $retval
}
_zsh_autosuggest_widget_execute () {
	local -i retval
	_zsh_autosuggest_highlight_reset
	_zsh_autosuggest_execute $@
	retval=$? 
	_zsh_autosuggest_highlight_apply
	zle -R
	return $retval
}
_zsh_autosuggest_widget_fetch () {
	local -i retval
	_zsh_autosuggest_highlight_reset
	_zsh_autosuggest_fetch $@
	retval=$? 
	_zsh_autosuggest_highlight_apply
	zle -R
	return $retval
}
_zsh_autosuggest_widget_modify () {
	local -i retval
	_zsh_autosuggest_highlight_reset
	_zsh_autosuggest_modify $@
	retval=$? 
	_zsh_autosuggest_highlight_apply
	zle -R
	return $retval
}
_zsh_autosuggest_widget_partial_accept () {
	local -i retval
	_zsh_autosuggest_highlight_reset
	_zsh_autosuggest_partial_accept $@
	retval=$? 
	_zsh_autosuggest_highlight_apply
	zle -R
	return $retval
}
_zsh_autosuggest_widget_suggest () {
	local -i retval
	_zsh_autosuggest_highlight_reset
	_zsh_autosuggest_suggest $@
	retval=$? 
	_zsh_autosuggest_highlight_apply
	zle -R
	return $retval
}
_zsh_autosuggest_widget_toggle () {
	local -i retval
	_zsh_autosuggest_highlight_reset
	_zsh_autosuggest_toggle $@
	retval=$? 
	_zsh_autosuggest_highlight_apply
	zle -R
	return $retval
}
_zsh_highlight () {
	local ret=$? 
	typeset -r ret
	(( ${+region_highlight[@]} )) || {
		echo 'zsh-syntax-highlighting: error: $region_highlight is not defined' >&2
		echo 'zsh-syntax-highlighting: (Check whether zsh-syntax-highlighting was installed according to the instructions.)' >&2
		return $ret
	}
	(( ${+zsh_highlight__memo_feature} )) || {
		region_highlight+=(" 0 0 fg=red, memo=zsh-syntax-highlighting") 
		case ${region_highlight[-1]} in
			("0 0 fg=red") integer -gr zsh_highlight__memo_feature=0  ;;
			("0 0 fg=red memo=zsh-syntax-highlighting") integer -gr zsh_highlight__memo_feature=1  ;;
			(" 0 0 fg=red, memo=zsh-syntax-highlighting")  ;&
			(*) if is-at-least 5.9
				then
					integer -gr zsh_highlight__memo_feature=1 
				else
					integer -gr zsh_highlight__memo_feature=0 
				fi ;;
		esac
		region_highlight[-1]=() 
	}
	if (( zsh_highlight__memo_feature ))
	then
		region_highlight=("${(@)region_highlight:#*memo=zsh-syntax-highlighting*}") 
	else
		region_highlight=() 
	fi
	if [[ $WIDGET == zle-isearch-update ]] && {
			$zsh_highlight__pat_static_bug || ! (( $+ISEARCHMATCH_ACTIVE ))
		}
	then
		return $ret
	fi
	local -A zsyh_user_options
	if zmodload -e zsh/parameter
	then
		zsyh_user_options=("${(kv)options[@]}") 
	else
		local canonical_options onoff option raw_options
		raw_options=(${(f)"$(emulate -R zsh; set -o)"}) 
		canonical_options=(${${${(M)raw_options:#*off}%% *}#no} ${${(M)raw_options:#*on}%% *}) 
		for option in "${canonical_options[@]}"
		do
			[[ -o $option ]]
			case $? in
				(0) zsyh_user_options+=($option on)  ;;
				(1) zsyh_user_options+=($option off)  ;;
				(*) echo "zsh-syntax-highlighting: warning: '[[ -o $option ]]' returned $?" ;;
			esac
		done
	fi
	typeset -r zsyh_user_options
	emulate -L zsh
	setopt localoptions warncreateglobal nobashrematch
	local REPLY
	[[ -n ${ZSH_HIGHLIGHT_MAXLENGTH:-} ]] && [[ $#BUFFER -gt $ZSH_HIGHLIGHT_MAXLENGTH ]] && return $ret
	(( KEYS_QUEUED_COUNT > 0 )) && return $ret
	(( PENDING > 0 )) && return $ret
	{
		local cache_place
		local -a region_highlight_copy
		local highlighter
		for highlighter in $ZSH_HIGHLIGHT_HIGHLIGHTERS
		do
			cache_place="_zsh_highlight__highlighter_${highlighter}_cache" 
			typeset -ga ${cache_place}
			if ! type "_zsh_highlight_highlighter_${highlighter}_predicate" >&/dev/null
			then
				echo "zsh-syntax-highlighting: warning: disabling the ${(qq)highlighter} highlighter as it has not been loaded" >&2
				ZSH_HIGHLIGHT_HIGHLIGHTERS=(${ZSH_HIGHLIGHT_HIGHLIGHTERS:#${highlighter}}) 
			elif "_zsh_highlight_highlighter_${highlighter}_predicate"
			then
				region_highlight_copy=("${region_highlight[@]}") 
				region_highlight=() 
				{
					"_zsh_highlight_highlighter_${highlighter}_paint"
				} always {
					: ${(AP)cache_place::="${region_highlight[@]}"}
				}
				region_highlight=("${region_highlight_copy[@]}") 
			fi
			region_highlight+=("${(@P)cache_place}") 
		done
		() {
			(( REGION_ACTIVE )) || return
			integer min max
			if (( MARK > CURSOR ))
			then
				min=$CURSOR max=$MARK 
			else
				min=$MARK max=$CURSOR 
			fi
			if (( REGION_ACTIVE == 1 ))
			then
				[[ $KEYMAP = vicmd ]] && (( max++ ))
			elif (( REGION_ACTIVE == 2 ))
			then
				local needle=$'\n' 
				(( min = ${BUFFER[(Ib:min:)$needle]} ))
				(( max = ${BUFFER[(ib:max:)$needle]} - 1 ))
			fi
			_zsh_highlight_apply_zle_highlight region standout "$min" "$max"
		}
		(( $+YANK_ACTIVE )) && (( YANK_ACTIVE )) && _zsh_highlight_apply_zle_highlight paste standout "$YANK_START" "$YANK_END"
		(( $+ISEARCHMATCH_ACTIVE )) && (( ISEARCHMATCH_ACTIVE )) && _zsh_highlight_apply_zle_highlight isearch underline "$ISEARCHMATCH_START" "$ISEARCHMATCH_END"
		(( $+SUFFIX_ACTIVE )) && (( SUFFIX_ACTIVE )) && _zsh_highlight_apply_zle_highlight suffix bold "$SUFFIX_START" "$SUFFIX_END"
		return $ret
	} always {
		typeset -g _ZSH_HIGHLIGHT_PRIOR_BUFFER="$BUFFER" 
		typeset -gi _ZSH_HIGHLIGHT_PRIOR_CURSOR=$CURSOR 
	}
}
_zsh_highlight__function_callable_p () {
	if _zsh_highlight__is_function_p "$1" && ! _zsh_highlight__function_is_autoload_stub_p "$1"
	then
		return 0
	else
		(
			autoload -U +X -- "$1" 2> /dev/null
		)
		return $?
	fi
}
_zsh_highlight__function_is_autoload_stub_p () {
	if zmodload -e zsh/parameter
	then
		[[ "$functions[$1]" == *"builtin autoload -X"* ]]
	else
		[[ "${${(@f)"$(which -- "$1")"}[2]}" == $'\t'$histchars[3]' undefined' ]]
	fi
}
_zsh_highlight__is_function_p () {
	if zmodload -e zsh/parameter
	then
		(( ${+functions[$1]} ))
	else
		[[ $(type -wa -- "$1") == *'function'* ]]
	fi
}
_zsh_highlight__zle-line-finish () {
	() {
		local -h -r WIDGET=zle-line-finish 
		_zsh_highlight
	}
}
_zsh_highlight__zle-line-pre-redraw () {
	true && _zsh_highlight "$@"
}
_zsh_highlight_add_highlight () {
	local -i start end
	local highlight
	start=$1 
	end=$2 
	shift 2
	for highlight
	do
		if (( $+ZSH_HIGHLIGHT_STYLES[$highlight] ))
		then
			region_highlight+=("$start $end $ZSH_HIGHLIGHT_STYLES[$highlight], memo=zsh-syntax-highlighting") 
			break
		fi
	done
}
_zsh_highlight_apply_zle_highlight () {
	local entry="$1" default="$2" 
	integer first="$3" second="$4" 
	local region="${zle_highlight[(r)${entry}:*]-}" 
	if [[ -z "$region" ]]
	then
		region=$default 
	else
		region="${region#${entry}:}" 
		if [[ -z "$region" ]] || [[ "$region" == none ]]
		then
			return
		fi
	fi
	integer start end
	if (( first < second ))
	then
		start=$first end=$second 
	else
		start=$second end=$first 
	fi
	region_highlight+=("$start $end $region, memo=zsh-syntax-highlighting") 
}
_zsh_highlight_bind_widgets () {
	
}
_zsh_highlight_brackets_match () {
	case $BUFFER[$1] in
		(\() [[ $BUFFER[$2] == \) ]] ;;
		(\[) [[ $BUFFER[$2] == \] ]] ;;
		(\{) [[ $BUFFER[$2] == \} ]] ;;
		(*) false ;;
	esac
}
_zsh_highlight_buffer_modified () {
	[[ "${_ZSH_HIGHLIGHT_PRIOR_BUFFER:-}" != "$BUFFER" ]]
}
_zsh_highlight_call_widget () {
	builtin zle "$@" && _zsh_highlight
}
_zsh_highlight_cursor_moved () {
	[[ -n $CURSOR ]] && [[ -n ${_ZSH_HIGHLIGHT_PRIOR_CURSOR-} ]] && (($_ZSH_HIGHLIGHT_PRIOR_CURSOR != $CURSOR))
}
_zsh_highlight_highlighter_brackets_paint () {
	local char style
	local -i bracket_color_size=${#ZSH_HIGHLIGHT_STYLES[(I)bracket-level-*]} buflen=${#BUFFER} level=0 matchingpos pos 
	local -A levelpos lastoflevel matching
	pos=0 
	for char in ${(s..)BUFFER}
	do
		(( ++pos ))
		case $char in
			(["([{"]) levelpos[$pos]=$((++level)) 
				lastoflevel[$level]=$pos  ;;
			([")]}"]) if (( level > 0 ))
				then
					matchingpos=$lastoflevel[$level] 
					levelpos[$pos]=$((level--)) 
					if _zsh_highlight_brackets_match $matchingpos $pos
					then
						matching[$matchingpos]=$pos 
						matching[$pos]=$matchingpos 
					fi
				else
					levelpos[$pos]=-1 
				fi ;;
		esac
	done
	for pos in ${(k)levelpos}
	do
		if (( $+matching[$pos] ))
		then
			if (( bracket_color_size ))
			then
				_zsh_highlight_add_highlight $((pos - 1)) $pos bracket-level-$(( (levelpos[$pos] - 1) % bracket_color_size + 1 ))
			fi
		else
			_zsh_highlight_add_highlight $((pos - 1)) $pos bracket-error
		fi
	done
	if [[ $WIDGET != zle-line-finish ]]
	then
		pos=$((CURSOR + 1)) 
		if (( $+levelpos[$pos] )) && (( $+matching[$pos] ))
		then
			local -i otherpos=$matching[$pos] 
			_zsh_highlight_add_highlight $((otherpos - 1)) $otherpos cursor-matchingbracket
		fi
	fi
}
_zsh_highlight_highlighter_brackets_predicate () {
	[[ $WIDGET == zle-line-finish ]] || _zsh_highlight_cursor_moved || _zsh_highlight_buffer_modified
}
_zsh_highlight_highlighter_cursor_paint () {
	[[ $WIDGET == zle-line-finish ]] && return
	_zsh_highlight_add_highlight $CURSOR $(( $CURSOR + 1 )) cursor
}
_zsh_highlight_highlighter_cursor_predicate () {
	[[ $WIDGET == zle-line-finish ]] || _zsh_highlight_cursor_moved
}
_zsh_highlight_highlighter_line_paint () {
	_zsh_highlight_add_highlight 0 $#BUFFER line
}
_zsh_highlight_highlighter_line_predicate () {
	_zsh_highlight_buffer_modified
}
_zsh_highlight_highlighter_main_paint () {
	setopt localoptions extendedglob
	if [[ $CONTEXT == (select|vared) ]]
	then
		return
	fi
	typeset -a ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR
	typeset -a ZSH_HIGHLIGHT_TOKENS_CONTROL_FLOW
	local -a options_to_set reply
	local REPLY
	local flags_with_argument
	local flags_sans_argument
	local flags_solo
	local -A precommand_options
	precommand_options=('-' '' 'builtin' '' 'command' :pvV 'exec' a:cl 'noglob' '' 'doas' aCu:Lns 'nice' n: 'pkexec' '' 'sudo' Cgprtu:AEHPSbilns:eKkVv 'stdbuf' ioe: 'eatmydata' '' 'catchsegv' '' 'nohup' '' 'setsid' :wc 'env' u:i 'ionice' cn:t:pPu 'strace' IbeaosXPpEuOS:ACdfhikqrtTvVxyDc 'proxychains' f:q 'torsocks' idq:upaP 'torify' idq:upaP 'ssh-agent' aEPt:csDd:k 'tabbed' gnprtTuU:cdfhs:v 'chronic' :ev 'ifne' :n 'grc' :se 'cpulimit' elp:ivz 'ktrace' fgpt:aBCcdiT) 
	if [[ $zsyh_user_options[ignorebraces] == on || ${zsyh_user_options[ignoreclosebraces]:-off} == on ]]
	then
		local right_brace_is_recognised_everywhere=false 
	else
		local right_brace_is_recognised_everywhere=true 
	fi
	if [[ $zsyh_user_options[pathdirs] == on ]]
	then
		options_to_set+=(PATH_DIRS) 
	fi
	ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR=('|' '||' ';' '&' '&&' $'\n' '|&' '&!' '&|') 
	ZSH_HIGHLIGHT_TOKENS_CONTROL_FLOW=($'\x7b' $'\x28' '()' 'while' 'until' 'if' 'then' 'elif' 'else' 'do' 'time' 'coproc' '!') 
	if (( $+X_ZSH_HIGHLIGHT_DIRS_BLACKLIST ))
	then
		print 'zsh-syntax-highlighting: X_ZSH_HIGHLIGHT_DIRS_BLACKLIST is deprecated. Please use ZSH_HIGHLIGHT_DIRS_BLACKLIST.' >&2
		ZSH_HIGHLIGHT_DIRS_BLACKLIST=($X_ZSH_HIGHLIGHT_DIRS_BLACKLIST) 
		unset X_ZSH_HIGHLIGHT_DIRS_BLACKLIST
	fi
	_zsh_highlight_main_highlighter_highlight_list -$#PREBUFFER '' 1 "$PREBUFFER$BUFFER"
	local start end_ style
	for start end_ style in $reply
	do
		(( start >= end_ )) && {
			print -r -- "zsh-syntax-highlighting: BUG: _zsh_highlight_highlighter_main_paint: start($start) >= end($end_)" >&2
			return
		}
		(( end_ <= 0 )) && continue
		(( start < 0 )) && start=0 
		_zsh_highlight_main_calculate_fallback $style
		_zsh_highlight_add_highlight $start $end_ $reply
	done
}
_zsh_highlight_highlighter_main_predicate () {
	[[ $WIDGET == zle-line-finish ]] || _zsh_highlight_buffer_modified
}
_zsh_highlight_highlighter_pattern_paint () {
	setopt localoptions extendedglob
	local pattern
	for pattern in ${(k)ZSH_HIGHLIGHT_PATTERNS}
	do
		_zsh_highlight_pattern_highlighter_loop "$BUFFER" "$pattern"
	done
}
_zsh_highlight_highlighter_pattern_predicate () {
	_zsh_highlight_buffer_modified
}
_zsh_highlight_highlighter_regexp_paint () {
	setopt localoptions extendedglob
	local pattern
	for pattern in ${(k)ZSH_HIGHLIGHT_REGEXP}
	do
		_zsh_highlight_regexp_highlighter_loop "$BUFFER" "$pattern"
	done
}
_zsh_highlight_highlighter_regexp_predicate () {
	_zsh_highlight_buffer_modified
}
_zsh_highlight_highlighter_root_paint () {
	if (( EUID == 0 ))
	then
		_zsh_highlight_add_highlight 0 $#BUFFER root
	fi
}
_zsh_highlight_highlighter_root_predicate () {
	_zsh_highlight_buffer_modified
}
_zsh_highlight_load_highlighters () {
	setopt localoptions noksharrays bareglobqual
	[[ -d "$1" ]] || {
		print -r -- "zsh-syntax-highlighting: highlighters directory ${(qq)1} not found." >&2
		return 1
	}
	local highlighter highlighter_dir
	for highlighter_dir in $1/*/(/)
	do
		highlighter="${highlighter_dir:t}" 
		[[ -f "$highlighter_dir${highlighter}-highlighter.zsh" ]] && . "$highlighter_dir${highlighter}-highlighter.zsh"
		if type "_zsh_highlight_highlighter_${highlighter}_paint" &> /dev/null && type "_zsh_highlight_highlighter_${highlighter}_predicate" &> /dev/null
		then
			
		elif type "_zsh_highlight_${highlighter}_highlighter" &> /dev/null && type "_zsh_highlight_${highlighter}_highlighter_predicate" &> /dev/null
		then
			if false
			then
				print -r -- "zsh-syntax-highlighting: warning: ${(qq)highlighter} highlighter uses deprecated entry point names; please ask its maintainer to update it: https://github.com/zsh-users/zsh-syntax-highlighting/issues/329" >&2
			fi
			eval "_zsh_highlight_highlighter_${(q)highlighter}_paint() { _zsh_highlight_${(q)highlighter}_highlighter \"\$@\" }"
			eval "_zsh_highlight_highlighter_${(q)highlighter}_predicate() { _zsh_highlight_${(q)highlighter}_highlighter_predicate \"\$@\" }"
		else
			print -r -- "zsh-syntax-highlighting: ${(qq)highlighter} highlighter should define both required functions '_zsh_highlight_highlighter_${highlighter}_paint' and '_zsh_highlight_highlighter_${highlighter}_predicate' in ${(qq):-"$highlighter_dir${highlighter}-highlighter.zsh"}." >&2
		fi
	done
}
_zsh_highlight_main__is_global_alias () {
	if zmodload -e zsh/parameter
	then
		(( ${+galiases[$arg]} ))
	elif [[ $arg == '='* ]]
	then
		return 1
	else
		alias -L -g -- "$1" > /dev/null
	fi
}
_zsh_highlight_main__is_redirection () {
	[[ ${1#[0-9]} == (\<|\<\>|(\>|\>\>)(|\|)|\<\<(|-)|\<\<\<|\<\&|\&\<|(\>|\>\>)\&(|\|)|\&(\>|\>\>)(|\||\!)) ]]
}
_zsh_highlight_main__is_runnable () {
	if _zsh_highlight_main__type "$1"
	then
		[[ $REPLY != none ]]
	else
		return 2
	fi
}
_zsh_highlight_main__precmd_hook () {
	setopt localoptions
	if eval '[[ -o warnnestedvar ]]' 2> /dev/null
	then
		unsetopt warnnestedvar
	fi
	_zsh_highlight_main__command_type_cache=() 
}
_zsh_highlight_main__resolve_alias () {
	if zmodload -e zsh/parameter
	then
		REPLY=${aliases[$arg]} 
	else
		REPLY="${"$(alias -- $arg)"#*=}" 
	fi
}
_zsh_highlight_main__stack_pop () {
	if [[ $braces_stack[1] == $1 ]]
	then
		braces_stack=${braces_stack:1} 
		if (( $+2 ))
		then
			style=$2 
		fi
		return 0
	else
		style=unknown-token 
		return 1
	fi
}
_zsh_highlight_main__type () {
	integer -r aliases_allowed=${2-1} 
	integer may_cache=1 
	if (( $+_zsh_highlight_main__command_type_cache ))
	then
		REPLY=$_zsh_highlight_main__command_type_cache[(e)$1] 
		if [[ -n "$REPLY" ]]
		then
			return
		fi
	fi
	if (( $#options_to_set ))
	then
		setopt localoptions $options_to_set
	fi
	unset REPLY
	if zmodload -e zsh/parameter
	then
		if (( $+aliases[(e)$1] ))
		then
			may_cache=0 
		fi
		if (( ${+galiases[(e)$1]} )) && (( aliases_allowed ))
		then
			REPLY='global alias' 
		elif (( $+aliases[(e)$1] )) && (( aliases_allowed ))
		then
			REPLY=alias 
		elif [[ $1 == *.* && -n ${1%.*} ]] && (( $+saliases[(e)${1##*.}] ))
		then
			REPLY='suffix alias' 
		elif (( $reswords[(Ie)$1] ))
		then
			REPLY=reserved 
		elif (( $+functions[(e)$1] ))
		then
			REPLY=function 
		elif (( $+builtins[(e)$1] ))
		then
			REPLY=builtin 
		elif (( $+commands[(e)$1] ))
		then
			REPLY=command 
		elif {
				[[ $1 != */* ]] || is-at-least 5.3
			} && ! (
				builtin type -w -- "$1"
			) > /dev/null 2>&1
		then
			REPLY=none 
		fi
	fi
	if ! (( $+REPLY ))
	then
		REPLY="${$(:; (( aliases_allowed )) || unalias -- "$1" 2>/dev/null; LC_ALL=C builtin type -w -- "$1" 2>/dev/null)##*: }" 
		if [[ $REPLY == 'alias' ]]
		then
			may_cache=0 
		fi
	fi
	if (( may_cache )) && (( $+_zsh_highlight_main__command_type_cache ))
	then
		_zsh_highlight_main__command_type_cache[(e)$1]=$REPLY 
	fi
	[[ -n $REPLY ]]
	return $?
}
_zsh_highlight_main_add_many_region_highlights () {
	for 1 2 3
	do
		_zsh_highlight_main_add_region_highlight $1 $2 $3
	done
}
_zsh_highlight_main_add_region_highlight () {
	integer start=$1 end=$2 
	shift 2
	if (( $#in_alias ))
	then
		[[ $1 == unknown-token ]] && alias_style=unknown-token 
		return
	fi
	if (( in_param ))
	then
		if [[ $1 == unknown-token ]]
		then
			param_style=unknown-token 
		fi
		if [[ -n $param_style ]]
		then
			return
		fi
		param_style=$1 
		return
	fi
	(( start += buf_offset ))
	(( end += buf_offset ))
	list_highlights+=($start $end $1) 
}
_zsh_highlight_main_calculate_fallback () {
	local -A fallback_of
	fallback_of=(alias arg0 suffix-alias arg0 global-alias dollar-double-quoted-argument builtin arg0 function arg0 command arg0 precommand arg0 hashed-command arg0 autodirectory arg0 arg0_\* arg0 path_prefix path path_pathseparator path path_prefix_pathseparator path_prefix single-quoted-argument{-unclosed,} double-quoted-argument{-unclosed,} dollar-quoted-argument{-unclosed,} back-quoted-argument{-unclosed,} command-substitution{-quoted,,-unquoted,} command-substitution-delimiter{-quoted,,-unquoted,} command-substitution{-delimiter,} process-substitution{-delimiter,} back-quoted-argument{-delimiter,}) 
	local needle=$1 value 
	reply=($1) 
	while [[ -n ${value::=$fallback_of[(k)$needle]} ]]
	do
		unset "fallback_of[$needle]"
		reply+=($value) 
		needle=$value 
	done
}
_zsh_highlight_main_highlighter__try_expand_parameter () {
	local arg="$1" 
	unset reply
	{
		{
			local -a match mbegin mend
			local MATCH
			integer MBEGIN MEND
			local parameter_name
			local -a words
			if [[ $arg[1] != '$' ]]
			then
				return 1
			fi
			if [[ ${arg[2]} == '{' ]] && [[ ${arg[-1]} == '}' ]]
			then
				parameter_name=${${arg:2}%?} 
			else
				parameter_name=${arg:1} 
			fi
			if [[ $res == none ]] && [[ ${parameter_name} =~ ^${~parameter_name_pattern}$ ]] && [[ ${(tP)MATCH} != *special* ]]
			then
				case ${(tP)MATCH} in
					(*array*|*assoc*) words=(${(P)MATCH})  ;;
					("") words=()  ;;
					(*) if [[ $zsyh_user_options[shwordsplit] == on ]]
						then
							words=(${(P)=MATCH}) 
						else
							words=(${(P)MATCH}) 
						fi ;;
				esac
				reply=("${words[@]}") 
			else
				return 1
			fi
		}
	}
}
_zsh_highlight_main_highlighter_check_assign () {
	setopt localoptions extended_glob
	[[ $arg == [[:alpha:]_][[:alnum:]_]#(|\[*\])(|[+])=* ]] || [[ $arg == [0-9]##(|[+])=* ]]
}
_zsh_highlight_main_highlighter_check_path () {
	_zsh_highlight_main_highlighter_expand_path "$1"
	local expanded_path="$REPLY" tmp_path 
	integer in_command_position=$2 
	if [[ $zsyh_user_options[autocd] == on ]]
	then
		integer autocd=1 
	else
		integer autocd=0 
	fi
	if (( in_command_position ))
	then
		REPLY=arg0 
	else
		REPLY=path 
	fi
	if [[ ${1[1]} == '=' && $1 == ??* && ${1[2]} != $'\x28' && $zsyh_user_options[equals] == 'on' && $expanded_path[1] != '/' ]]
	then
		REPLY=unknown-token 
		return 0
	fi
	[[ -z $expanded_path ]] && return 1
	if [[ $expanded_path[1] == / ]]
	then
		tmp_path=$expanded_path 
	else
		tmp_path=$PWD/$expanded_path 
	fi
	tmp_path=$tmp_path:a 
	while [[ $tmp_path != / ]]
	do
		[[ -n ${(M)ZSH_HIGHLIGHT_DIRS_BLACKLIST:#$tmp_path} ]] && return 1
		tmp_path=$tmp_path:h 
	done
	if (( in_command_position ))
	then
		if [[ -x $expanded_path ]]
		then
			if (( autocd ))
			then
				if [[ -d $expanded_path ]]
				then
					REPLY=autodirectory 
				fi
				return 0
			elif [[ ! -d $expanded_path ]]
			then
				return 0
			fi
		fi
	else
		if [[ -L $expanded_path || -e $expanded_path ]]
		then
			return 0
		fi
	fi
	if [[ $expanded_path != /* ]] && (( autocd || ! in_command_position ))
	then
		local cdpath_dir
		for cdpath_dir in $cdpath
		do
			if [[ -d "$cdpath_dir/$expanded_path" && -x "$cdpath_dir/$expanded_path" ]]
			then
				if (( in_command_position && autocd ))
				then
					REPLY=autodirectory 
				fi
				return 0
			fi
		done
	fi
	[[ ! -d ${expanded_path:h} ]] && return 1
	if (( has_end && (len == end_pos) )) && (( ! $#in_alias )) && [[ $WIDGET != zle-line-finish ]]
	then
		local -a tmp
		if (( in_command_position ))
		then
			tmp=(${expanded_path}*(N-*,N-/)) 
		else
			tmp=(${expanded_path}*(N)) 
		fi
		(( ${+tmp[1]} )) && REPLY=path_prefix  && return 0
	fi
	return 1
}
_zsh_highlight_main_highlighter_expand_path () {
	(( $# == 1 )) || print -r -- "zsh-syntax-highlighting: BUG: _zsh_highlight_main_highlighter_expand_path: called without argument" >&2
	setopt localoptions nonomatch
	unset REPLY
	: ${REPLY:=${(Q)${~1}}}
}
_zsh_highlight_main_highlighter_highlight_argument () {
	local base_style=default i=$1 option_eligible=${2:-1} path_eligible=1 ret start style 
	local -a highlights
	local -a match mbegin mend
	local MATCH
	integer MBEGIN MEND
	case "$arg[i]" in
		('%') if [[ $arg[i+1] == '?' ]]
			then
				(( i += 2 ))
			fi ;;
		('-') if (( option_eligible ))
			then
				if [[ $arg[i+1] == - ]]
				then
					base_style=double-hyphen-option 
				else
					base_style=single-hyphen-option 
				fi
				path_eligible=0 
			fi ;;
		('=') if [[ $arg[i+1] == $'\x28' ]]
			then
				(( i += 2 ))
				_zsh_highlight_main_highlighter_highlight_list $(( start_pos + i - 1 )) S $has_end $arg[i,-1]
				ret=$? 
				(( i += REPLY ))
				highlights+=($(( start_pos + $1 - 1 )) $(( start_pos + i )) process-substitution $(( start_pos + $1 - 1 )) $(( start_pos + $1 + 1 )) process-substitution-delimiter $reply) 
				if (( ret == 0 ))
				then
					highlights+=($(( start_pos + i - 1 )) $(( start_pos + i )) process-substitution-delimiter) 
				fi
			fi ;;
	esac
	(( --i ))
	while (( ++i <= $#arg ))
	do
		i=${arg[(ib.i.)[\\\'\"\`\$\<\>\*\?]]} 
		case "$arg[$i]" in
			("") break ;;
			("\\") (( i += 1 ))
				continue ;;
			("'") _zsh_highlight_main_highlighter_highlight_single_quote $i
				(( i = REPLY ))
				highlights+=($reply)  ;;
			('"') _zsh_highlight_main_highlighter_highlight_double_quote $i
				(( i = REPLY ))
				highlights+=($reply)  ;;
			('`') _zsh_highlight_main_highlighter_highlight_backtick $i
				(( i = REPLY ))
				highlights+=($reply)  ;;
			('$') if [[ $arg[i+1] != "'" ]]
				then
					path_eligible=0 
				fi
				if [[ $arg[i+1] == "'" ]]
				then
					_zsh_highlight_main_highlighter_highlight_dollar_quote $i
					(( i = REPLY ))
					highlights+=($reply) 
					continue
				elif [[ $arg[i+1] == $'\x28' ]]
				then
					if [[ $arg[i+2] == $'\x28' ]] && _zsh_highlight_main_highlighter_highlight_arithmetic $i
					then
						(( i = REPLY ))
						highlights+=($reply) 
						continue
					fi
					start=$i 
					(( i += 2 ))
					_zsh_highlight_main_highlighter_highlight_list $(( start_pos + i - 1 )) S $has_end $arg[i,-1]
					ret=$? 
					(( i += REPLY ))
					highlights+=($(( start_pos + start - 1)) $(( start_pos + i )) command-substitution-unquoted $(( start_pos + start - 1)) $(( start_pos + start + 1)) command-substitution-delimiter-unquoted $reply) 
					if (( ret == 0 ))
					then
						highlights+=($(( start_pos + i - 1)) $(( start_pos + i )) command-substitution-delimiter-unquoted) 
					fi
					continue
				fi
				while [[ $arg[i+1] == [=~#+'^'] ]]
				do
					(( i += 1 ))
				done
				if [[ $arg[i+1] == [*@#?$!-] ]]
				then
					(( i += 1 ))
				fi ;;
			([\<\>]) if [[ $arg[i+1] == $'\x28' ]]
				then
					start=$i 
					(( i += 2 ))
					_zsh_highlight_main_highlighter_highlight_list $(( start_pos + i - 1 )) S $has_end $arg[i,-1]
					ret=$? 
					(( i += REPLY ))
					highlights+=($(( start_pos + start - 1)) $(( start_pos + i )) process-substitution $(( start_pos + start - 1)) $(( start_pos + start + 1 )) process-substitution-delimiter $reply) 
					if (( ret == 0 ))
					then
						highlights+=($(( start_pos + i - 1)) $(( start_pos + i )) process-substitution-delimiter) 
					fi
					continue
				fi ;|
			(*) if $highlight_glob && [[ $zsyh_user_options[multios] == on || $in_redirection -eq 0 ]] && [[ ${arg[$i]} =~ ^[*?] || ${arg:$i-1} =~ ^\<[0-9]*-[0-9]*\> ]]
				then
					highlights+=($(( start_pos + i - 1 )) $(( start_pos + i + $#MATCH - 1)) globbing) 
					(( i += $#MATCH - 1 ))
					path_eligible=0 
				else
					continue
				fi ;;
		esac
	done
	if (( path_eligible ))
	then
		if (( in_redirection )) && [[ $last_arg == *['<>']['&'] && $arg[$1,-1] == (<0->|p|-) ]]
		then
			if [[ $arg[$1,-1] == (p|-) ]]
			then
				base_style=redirection 
			else
				base_style=numeric-fd 
			fi
		elif _zsh_highlight_main_highlighter_check_path $arg[$1,-1] 0
		then
			base_style=$REPLY 
			_zsh_highlight_main_highlighter_highlight_path_separators $base_style
			highlights+=($reply) 
		fi
	fi
	highlights=($(( start_pos + $1 - 1 )) $end_pos $base_style $highlights) 
	_zsh_highlight_main_add_many_region_highlights $highlights
}
_zsh_highlight_main_highlighter_highlight_arithmetic () {
	local -a saved_reply
	local style
	integer i j k paren_depth ret
	reply=() 
	for ((i = $1 + 3 ; i <= end_pos - start_pos ; i += 1 )) do
		(( j = i + start_pos - 1 ))
		(( k = j + 1 ))
		case "$arg[$i]" in
			([\'\"\\@{}]) style=unknown-token  ;;
			('(') (( paren_depth++ ))
				continue ;;
			(')') if (( paren_depth ))
				then
					(( paren_depth-- ))
					continue
				fi
				[[ $arg[i+1] == ')' ]] && {
					(( i++ ))
					break
				}
				(( has_end && (len == k) )) && break
				return 1 ;;
			('`') saved_reply=($reply) 
				_zsh_highlight_main_highlighter_highlight_backtick $i
				(( i = REPLY ))
				reply=($saved_reply $reply) 
				continue ;;
			('$') if [[ $arg[i+1] == $'\x28' ]]
				then
					saved_reply=($reply) 
					if [[ $arg[i+2] == $'\x28' ]] && _zsh_highlight_main_highlighter_highlight_arithmetic $i
					then
						(( i = REPLY ))
						reply=($saved_reply $reply) 
						continue
					fi
					(( i += 2 ))
					_zsh_highlight_main_highlighter_highlight_list $(( start_pos + i - 1 )) S $has_end $arg[i,end_pos]
					ret=$? 
					(( i += REPLY ))
					reply=($saved_reply $j $(( start_pos + i )) command-substitution-quoted $j $(( j + 2 )) command-substitution-delimiter-quoted $reply) 
					if (( ret == 0 ))
					then
						reply+=($(( start_pos + i - 1 )) $(( start_pos + i )) command-substitution-delimiter) 
					fi
					continue
				else
					continue
				fi ;;
			($histchars[1]) if [[ $arg[i+1] != ('='|$'\x28'|$'\x7b'|[[:blank:]]) ]]
				then
					style=history-expansion 
				else
					continue
				fi ;;
			(*) continue ;;
		esac
		reply+=($j $k $style) 
	done
	if [[ $arg[i] != ')' ]]
	then
		(( i-- ))
	fi
	style=arithmetic-expansion 
	reply=($(( start_pos + $1 - 1)) $(( start_pos + i )) arithmetic-expansion $reply) 
	REPLY=$i 
}
_zsh_highlight_main_highlighter_highlight_backtick () {
	local buf highlight style=back-quoted-argument-unclosed style_end 
	local -i arg1=$1 end_ i=$1 last offset=0 start subshell_has_end=0 
	local -a highlight_zone highlights offsets
	reply=() 
	last=$(( arg1 + 1 )) 
	while i=$arg[(ib:i+1:)[\\\\\`]] 
	do
		if (( i > $#arg ))
		then
			buf=$buf$arg[last,i] 
			offsets[i-arg1-offset]='' 
			(( i-- ))
			subshell_has_end=$(( has_end && (start_pos + i == len) )) 
			break
		fi
		if [[ $arg[i] == '\' ]]
		then
			(( i++ ))
			if [[ $arg[i] == ('$'|'`'|'\') ]]
			then
				buf=$buf$arg[last,i-2] 
				(( offset++ ))
				offsets[i-arg1-offset]=$offset 
			else
				buf=$buf$arg[last,i-1] 
			fi
		else
			style=back-quoted-argument 
			style_end=back-quoted-argument-delimiter 
			buf=$buf$arg[last,i-1] 
			offsets[i-arg1-offset]='' 
			break
		fi
		last=$i 
	done
	_zsh_highlight_main_highlighter_highlight_list 0 '' $subshell_has_end $buf
	for start end_ highlight in $reply
	do
		start=$(( start_pos + arg1 + start + offsets[(Rb:start:)?*] )) 
		end_=$(( start_pos + arg1 + end_ + offsets[(Rb:end_:)?*] )) 
		highlights+=($start $end_ $highlight) 
		if [[ $highlight == back-quoted-argument-unclosed && $style == back-quoted-argument ]]
		then
			style_end=unknown-token 
		fi
	done
	reply=($(( start_pos + arg1 - 1 )) $(( start_pos + i )) $style $(( start_pos + arg1 - 1 )) $(( start_pos + arg1 )) back-quoted-argument-delimiter $highlights) 
	if (( $#style_end ))
	then
		reply+=($(( start_pos + i - 1)) $(( start_pos + i )) $style_end) 
	fi
	REPLY=$i 
}
_zsh_highlight_main_highlighter_highlight_dollar_quote () {
	local -a match mbegin mend
	local MATCH
	integer MBEGIN MEND
	local i j k style
	local AA
	integer c
	reply=() 
	for ((i = $1 + 2 ; i <= $#arg ; i += 1 )) do
		(( j = i + start_pos - 1 ))
		(( k = j + 1 ))
		case "$arg[$i]" in
			("'") break ;;
			("\\") style=back-dollar-quoted-argument 
				for ((c = i + 1 ; c <= $#arg ; c += 1 )) do
					[[ "$arg[$c]" != ([0-9xXuUa-fA-F]) ]] && break
				done
				AA=$arg[$i+1,$c-1] 
				if [[ "$AA" =~ "^(x|X)[0-9a-fA-F]{1,2}" || "$AA" =~ "^[0-7]{1,3}" || "$AA" =~ "^u[0-9a-fA-F]{1,4}" || "$AA" =~ "^U[0-9a-fA-F]{1,8}" ]]
				then
					(( k += $#MATCH ))
					(( i += $#MATCH ))
				else
					if (( $#arg > $i+1 )) && [[ $arg[$i+1] == [xXuU] ]]
					then
						style=unknown-token 
					fi
					(( k += 1 ))
					(( i += 1 ))
				fi ;;
			(*) continue ;;
		esac
		reply+=($j $k $style) 
	done
	if [[ $arg[i] == "'" ]]
	then
		style=dollar-quoted-argument 
	else
		(( i-- ))
		style=dollar-quoted-argument-unclosed 
	fi
	reply=($(( start_pos + $1 - 1 )) $(( start_pos + i )) $style $reply) 
	REPLY=$i 
}
_zsh_highlight_main_highlighter_highlight_double_quote () {
	local -a breaks match mbegin mend saved_reply
	local MATCH
	integer last_break=$(( start_pos + $1 - 1 )) MBEGIN MEND 
	local i j k ret style
	reply=() 
	for ((i = $1 + 1 ; i <= $#arg ; i += 1 )) do
		(( j = i + start_pos - 1 ))
		(( k = j + 1 ))
		case "$arg[$i]" in
			('"') break ;;
			('`') saved_reply=($reply) 
				_zsh_highlight_main_highlighter_highlight_backtick $i
				(( i = REPLY ))
				reply=($saved_reply $reply) 
				continue ;;
			('$') style=dollar-double-quoted-argument 
				if [[ ${arg:$i} =~ ^([A-Za-z_][A-Za-z0-9_]*|[0-9]+) ]]
				then
					(( k += $#MATCH ))
					(( i += $#MATCH ))
				elif [[ ${arg:$i} =~ ^[{]([A-Za-z_][A-Za-z0-9_]*|[0-9]+)[}] ]]
				then
					(( k += $#MATCH ))
					(( i += $#MATCH ))
				elif [[ $arg[i+1] == '$' ]]
				then
					(( k += 1 ))
					(( i += 1 ))
				elif [[ $arg[i+1] == [-#*@?] ]]
				then
					(( k += 1 ))
					(( i += 1 ))
				elif [[ $arg[i+1] == $'\x28' ]]
				then
					saved_reply=($reply) 
					if [[ $arg[i+2] == $'\x28' ]] && _zsh_highlight_main_highlighter_highlight_arithmetic $i
					then
						(( i = REPLY ))
						reply=($saved_reply $reply) 
						continue
					fi
					breaks+=($last_break $(( start_pos + i - 1 ))) 
					(( i += 2 ))
					_zsh_highlight_main_highlighter_highlight_list $(( start_pos + i - 1 )) S $has_end $arg[i,-1]
					ret=$? 
					(( i += REPLY ))
					last_break=$(( start_pos + i )) 
					reply=($saved_reply $j $(( start_pos + i )) command-substitution-quoted $j $(( j + 2 )) command-substitution-delimiter-quoted $reply) 
					if (( ret == 0 ))
					then
						reply+=($(( start_pos + i - 1 )) $(( start_pos + i )) command-substitution-delimiter-quoted) 
					fi
					continue
				else
					continue
				fi ;;
			("\\") style=back-double-quoted-argument 
				if [[ \\\`\"\$${histchars[1]} == *$arg[$i+1]* ]]
				then
					(( k += 1 ))
					(( i += 1 ))
				else
					continue
				fi ;;
			($histchars[1]) if [[ $arg[i+1] != ('='|$'\x28'|$'\x7b'|[[:blank:]]) ]]
				then
					style=history-expansion 
				else
					continue
				fi ;;
			(*) continue ;;
		esac
		reply+=($j $k $style) 
	done
	if [[ $arg[i] == '"' ]]
	then
		style=double-quoted-argument 
	else
		(( i-- ))
		style=double-quoted-argument-unclosed 
	fi
	(( last_break != start_pos + i )) && breaks+=($last_break $(( start_pos + i ))) 
	saved_reply=($reply) 
	reply=() 
	for 1 2 in $breaks
	do
		(( $1 != $2 )) && reply+=($1 $2 $style) 
	done
	reply+=($saved_reply) 
	REPLY=$i 
}
_zsh_highlight_main_highlighter_highlight_list () {
	integer start_pos end_pos=0 buf_offset=$1 has_end=$3 
	local alias_style param_style last_arg arg buf=$4 highlight_glob=true saw_assignment=false style 
	local in_array_assignment=false 
	integer in_param=0 len=$#buf 
	local -a in_alias match mbegin mend list_highlights
	local -A seen_alias
	readonly parameter_name_pattern='([A-Za-z_][A-Za-z0-9_]*|[0-9]+)' 
	list_highlights=() 
	local braces_stack=$2 
	local this_word next_word=':start::start_of_pipeline:' 
	integer in_redirection
	local proc_buf="$buf" 
	local -a args
	if [[ $zsyh_user_options[interactivecomments] == on ]]
	then
		args=(${(zZ+c+)buf}) 
	else
		args=(${(z)buf}) 
	fi
	if [[ $braces_stack == 'S' ]] && (( $+args[3] && ! $+args[4] )) && [[ $args[3] == $'\x29' ]] && [[ $args[1] == *'<'* ]] && _zsh_highlight_main__is_redirection $args[1]
	then
		highlight_glob=false 
	fi
	while (( $#args ))
	do
		last_arg=$arg 
		arg=$args[1] 
		shift args
		if (( $#in_alias ))
		then
			(( in_alias[1]-- ))
			in_alias=($in_alias[$in_alias[(i)<1->],-1]) 
			if (( $#in_alias == 0 ))
			then
				seen_alias=() 
				_zsh_highlight_main_add_region_highlight $start_pos $end_pos $alias_style
			else
				() {
					local alias_name
					for alias_name in ${(k)seen_alias[(R)<$#in_alias->]}
					do
						seen_alias=("${(@kv)seen_alias[(I)^$alias_name]}") 
					done
				}
			fi
		fi
		if (( in_param ))
		then
			(( in_param-- ))
			if (( in_param == 0 ))
			then
				_zsh_highlight_main_add_region_highlight $start_pos $end_pos $param_style
				param_style="" 
			fi
		fi
		if (( in_redirection == 0 ))
		then
			this_word=$next_word 
			next_word=':regular:' 
		elif (( !in_param ))
		then
			(( --in_redirection ))
		fi
		style=unknown-token 
		if [[ $this_word == *':start:'* ]]
		then
			in_array_assignment=false 
			if [[ $arg == 'noglob' ]]
			then
				highlight_glob=false 
			fi
		fi
		if (( $#in_alias == 0 && in_param == 0 ))
		then
			[[ "$proc_buf" = (#b)(#s)(''([ $'\t']|[\\]$'\n')#)(?|)* ]]
			integer offset="${#match[1]}" 
			(( start_pos = end_pos + offset ))
			(( end_pos = start_pos + $#arg ))
			[[ $arg == ';' && ${match[3]} == $'\n' ]] && arg=$'\n' 
			proc_buf="${proc_buf[offset + $#arg + 1,len]}" 
		fi
		if [[ $zsyh_user_options[interactivecomments] == on && $arg[1] == $histchars[3] ]]
		then
			if [[ $this_word == *(':regular:'|':start:')* ]]
			then
				style=comment 
			else
				style=unknown-token 
			fi
			_zsh_highlight_main_add_region_highlight $start_pos $end_pos $style
			in_redirection=1 
			continue
		fi
		if [[ $this_word == *':start:'* ]] && ! (( in_redirection ))
		then
			_zsh_highlight_main__type "$arg" "$(( ! ${+seen_alias[$arg]} ))"
			local res="$REPLY" 
			if [[ $res == "alias" ]]
			then
				if [[ $arg == ?*=* ]]
				then
					_zsh_highlight_main_add_region_highlight $start_pos $end_pos unknown-token
					continue
				fi
				seen_alias[$arg]=$#in_alias 
				_zsh_highlight_main__resolve_alias $arg
				local -a alias_args
				if [[ $zsyh_user_options[interactivecomments] == on ]]
				then
					alias_args=(${(zZ+c+)REPLY}) 
				else
					alias_args=(${(z)REPLY}) 
				fi
				args=($alias_args $args) 
				if (( $#in_alias == 0 ))
				then
					alias_style=alias 
				else
					(( in_alias[1]-- ))
				fi
				in_alias=($(($#alias_args + 1)) $in_alias) 
				(( in_redirection++ ))
				continue
			else
				_zsh_highlight_main_highlighter_expand_path $arg
				_zsh_highlight_main__type "$REPLY" 0
				res="$REPLY" 
			fi
		fi
		if _zsh_highlight_main__is_redirection $arg
		then
			if (( in_redirection == 1 ))
			then
				_zsh_highlight_main_add_region_highlight $start_pos $end_pos unknown-token
			else
				in_redirection=2 
				_zsh_highlight_main_add_region_highlight $start_pos $end_pos redirection
			fi
			continue
		elif [[ $arg == '{'${~parameter_name_pattern}'}' ]] && _zsh_highlight_main__is_redirection $args[1]
		then
			in_redirection=3 
			_zsh_highlight_main_add_region_highlight $start_pos $end_pos named-fd
			continue
		fi
		if (( ! in_param )) && _zsh_highlight_main_highlighter__try_expand_parameter "$arg"
		then
			() {
				local -a words
				words=("${reply[@]}") 
				if (( $#words == 0 )) && (( ! in_redirection ))
				then
					(( ++in_redirection ))
					_zsh_highlight_main_add_region_highlight $start_pos $end_pos comment
					continue
				else
					(( in_param = 1 + $#words ))
					args=($words $args) 
					arg=$args[1] 
					_zsh_highlight_main__type "$arg" 0
					res=$REPLY 
				fi
			}
		fi
		if (( ! in_redirection ))
		then
			if [[ $this_word == *':sudo_opt:'* ]]
			then
				if [[ -n $flags_with_argument ]] && {
						if [[ -n $flags_sans_argument ]]
						then
							[[ $arg == '-'[$flags_sans_argument]#[$flags_with_argument] ]]
						else
							[[ $arg == '-'[$flags_with_argument] ]]
						fi
					}
				then
					this_word=${this_word//:start:/} 
					next_word=':sudo_arg:' 
				elif [[ -n $flags_with_argument ]] && {
						if [[ -n $flags_sans_argument ]]
						then
							[[ $arg == '-'[$flags_sans_argument]#[$flags_with_argument]* ]]
						else
							[[ $arg == '-'[$flags_with_argument]* ]]
						fi
					}
				then
					this_word=${this_word//:start:/} 
					next_word+=':start:' 
					next_word+=':sudo_opt:' 
				elif [[ -n $flags_sans_argument ]] && [[ $arg == '-'[$flags_sans_argument]# ]]
				then
					this_word=':sudo_opt:' 
					next_word+=':start:' 
					next_word+=':sudo_opt:' 
				elif [[ -n $flags_solo ]] && {
						if [[ -n $flags_sans_argument ]]
						then
							[[ $arg == '-'[$flags_sans_argument]#[$flags_solo]* ]]
						else
							[[ $arg == '-'[$flags_solo]* ]]
						fi
					}
				then
					this_word=':sudo_opt:' 
					next_word=':regular:' 
				elif [[ $arg == '-'* ]]
				then
					this_word=':sudo_opt:' 
					next_word+=':start:' 
					next_word+=':sudo_opt:' 
				else
					this_word=${this_word//:sudo_opt:/} 
				fi
			elif [[ $this_word == *':sudo_arg:'* ]]
			then
				next_word+=':sudo_opt:' 
				next_word+=':start:' 
			fi
		fi
		if [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR:#"$arg"} ]] && [[ $braces_stack != *T* || $arg != ('||'|'&&') ]]
		then
			if _zsh_highlight_main__stack_pop T || _zsh_highlight_main__stack_pop Q
			then
				style=unknown-token 
			elif $in_array_assignment
			then
				case $arg in
					($'\n') style=commandseparator  ;;
					(';') style=unknown-token  ;;
					(*) style=unknown-token  ;;
				esac
			elif [[ $this_word == *':regular:'* ]]
			then
				style=commandseparator 
			elif [[ $this_word == *':start:'* ]] && [[ $arg == $'\n' ]]
			then
				style=commandseparator 
			elif [[ $this_word == *':start:'* ]] && [[ $arg == ';' ]] && (( $#in_alias ))
			then
				style=commandseparator 
			else
				style=unknown-token 
			fi
			if [[ $arg == $'\n' ]] && $in_array_assignment
			then
				next_word=':regular:' 
			elif [[ $arg == ';' ]] && $in_array_assignment
			then
				next_word=':regular:' 
			else
				next_word=':start:' 
				highlight_glob=true 
				saw_assignment=false 
				() {
					local alias_name
					for alias_name in ${(k)seen_alias[(R)<$#in_alias->]}
					do
						seen_alias=("${(@kv)seen_alias[(I)^$alias_name]}") 
					done
				}
				if [[ $arg != '|' && $arg != '|&' ]]
				then
					next_word+=':start_of_pipeline:' 
				fi
			fi
		elif ! (( in_redirection)) && [[ $this_word == *':always:'* && $arg == 'always' ]]
		then
			style=reserved-word 
			highlight_glob=true 
			saw_assignment=false 
			next_word=':start::start_of_pipeline:' 
		elif ! (( in_redirection)) && [[ $this_word == *':start:'* ]]
		then
			if (( ${+precommand_options[$arg]} )) && _zsh_highlight_main__is_runnable $arg
			then
				style=precommand 
				() {
					set -- "${(@s.:.)precommand_options[$arg]}"
					flags_with_argument=$1 
					flags_sans_argument=$2 
					flags_solo=$3 
				}
				next_word=${next_word//:regular:/} 
				next_word+=':sudo_opt:' 
				next_word+=':start:' 
				if [[ $arg == 'exec' || $arg == 'env' ]]
				then
					next_word+=':regular:' 
				fi
			else
				case $res in
					(reserved) style=reserved-word 
						case $arg in
							(time|nocorrect) next_word=${next_word//:regular:/} 
								next_word+=':start:'  ;;
							($'\x7b') braces_stack='Y'"$braces_stack"  ;;
							($'\x7d') _zsh_highlight_main__stack_pop 'Y' reserved-word
								if [[ $style == reserved-word ]]
								then
									next_word+=':always:' 
								fi ;;
							($'\x5b\x5b') braces_stack='T'"$braces_stack"  ;;
							('do') braces_stack='D'"$braces_stack"  ;;
							('done') _zsh_highlight_main__stack_pop 'D' reserved-word ;;
							('if') braces_stack=':?'"$braces_stack"  ;;
							('then') _zsh_highlight_main__stack_pop ':' reserved-word ;;
							('elif') if [[ ${braces_stack[1]} == '?' ]]
								then
									braces_stack=':'"$braces_stack" 
								else
									style=unknown-token 
								fi ;;
							('else') if [[ ${braces_stack[1]} == '?' ]]
								then
									:
								else
									style=unknown-token 
								fi ;;
							('fi') _zsh_highlight_main__stack_pop '?' ;;
							('foreach') braces_stack='$'"$braces_stack"  ;;
							('end') _zsh_highlight_main__stack_pop '$' reserved-word ;;
							('repeat') in_redirection=2 
								this_word=':start::regular:'  ;;
							('!') if [[ $this_word != *':start_of_pipeline:'* ]]
								then
									style=unknown-token 
								else
									
								fi ;;
						esac
						if $saw_assignment && [[ $style != unknown-token ]]
						then
							style=unknown-token 
						fi ;;
					('suffix alias') style=suffix-alias  ;;
					('global alias') style=global-alias  ;;
					(alias) : ;;
					(builtin) style=builtin 
						[[ $arg == $'\x5b' ]] && braces_stack='Q'"$braces_stack"  ;;
					(function) style=function  ;;
					(command) style=command  ;;
					(hashed) style=hashed-command  ;;
					(none) if (( ! in_param )) && _zsh_highlight_main_highlighter_check_assign
						then
							_zsh_highlight_main_add_region_highlight $start_pos $end_pos assign
							local i=$(( arg[(i)=] + 1 )) 
							saw_assignment=true 
							if [[ $arg[i] == '(' ]]
							then
								in_array_assignment=true 
								_zsh_highlight_main_add_region_highlight start_pos+i-1 start_pos+i reserved-word
							else
								next_word+=':start:' 
								if (( i <= $#arg ))
								then
									() {
										local highlight_glob=false 
										[[ $zsyh_user_options[globassign] == on ]] && highlight_glob=true 
										_zsh_highlight_main_highlighter_highlight_argument $i
									}
								fi
							fi
							continue
						elif (( ! in_param )) && [[ $arg[0,1] = $histchars[0,1] ]] && (( $#arg[0,2] == 2 ))
						then
							style=history-expansion 
						elif (( ! in_param )) && [[ $arg[0,1] == $histchars[2,2] ]]
						then
							style=history-expansion 
						elif (( ! in_param )) && ! $saw_assignment && [[ $arg[1,2] == '((' ]]
						then
							_zsh_highlight_main_add_region_highlight $start_pos $((start_pos + 2)) reserved-word
							if [[ $arg[-2,-1] == '))' ]]
							then
								_zsh_highlight_main_add_region_highlight $((end_pos - 2)) $end_pos reserved-word
							fi
							continue
						elif (( ! in_param )) && [[ $arg == '()' ]]
						then
							style=reserved-word 
						elif (( ! in_param )) && ! $saw_assignment && [[ $arg == $'\x28' ]]
						then
							style=reserved-word 
							braces_stack='R'"$braces_stack" 
						elif (( ! in_param )) && [[ $arg == $'\x29' ]]
						then
							if _zsh_highlight_main__stack_pop 'S'
							then
								REPLY=$start_pos 
								reply=($list_highlights) 
								return 0
							fi
							_zsh_highlight_main__stack_pop 'R' reserved-word
						else
							if _zsh_highlight_main_highlighter_check_path $arg 1
							then
								style=$REPLY 
							else
								style=unknown-token 
							fi
						fi ;;
					(*) _zsh_highlight_main_add_region_highlight $start_pos $end_pos arg0_$res
						continue ;;
				esac
			fi
			if [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_CONTROL_FLOW:#"$arg"} ]]
			then
				next_word=':start::start_of_pipeline:' 
			fi
		elif _zsh_highlight_main__is_global_alias "$arg"
		then
			style=global-alias 
		else
			case $arg in
				($'\x29') if $in_array_assignment
					then
						_zsh_highlight_main_add_region_highlight $start_pos $end_pos assign
						_zsh_highlight_main_add_region_highlight $start_pos $end_pos reserved-word
						in_array_assignment=false 
						next_word+=':start:' 
						continue
					elif (( in_redirection ))
					then
						style=unknown-token 
					else
						if _zsh_highlight_main__stack_pop 'S'
						then
							REPLY=$start_pos 
							reply=($list_highlights) 
							return 0
						fi
						_zsh_highlight_main__stack_pop 'R' reserved-word
					fi ;;
				($'\x28\x29') if (( in_redirection )) || $in_array_assignment
					then
						style=unknown-token 
					else
						if [[ $zsyh_user_options[multifuncdef] == on ]] || false
						then
							next_word+=':start::start_of_pipeline:' 
						fi
						style=reserved-word 
					fi ;;
				(*) if false
					then
						
					elif [[ $arg = $'\x7d' ]] && $right_brace_is_recognised_everywhere
					then
						if (( in_redirection )) || $in_array_assignment
						then
							style=unknown-token 
						else
							_zsh_highlight_main__stack_pop 'Y' reserved-word
							if [[ $style == reserved-word ]]
							then
								next_word+=':always:' 
							fi
						fi
					elif [[ $arg[0,1] = $histchars[0,1] ]] && (( $#arg[0,2] == 2 ))
					then
						style=history-expansion 
					elif [[ $arg == $'\x5d\x5d' ]] && _zsh_highlight_main__stack_pop 'T' reserved-word
					then
						:
					elif [[ $arg == $'\x5d' ]] && _zsh_highlight_main__stack_pop 'Q' builtin
					then
						:
					else
						_zsh_highlight_main_highlighter_highlight_argument 1 $(( 1 != in_redirection ))
						continue
					fi ;;
			esac
		fi
		_zsh_highlight_main_add_region_highlight $start_pos $end_pos $style
	done
	(( $#in_alias )) && in_alias=() _zsh_highlight_main_add_region_highlight $start_pos $end_pos $alias_style
	(( in_param == 1 )) && in_param=0 _zsh_highlight_main_add_region_highlight $start_pos $end_pos $param_style
	[[ "$proc_buf" = (#b)(#s)(([[:space:]]|\\$'\n')#) ]]
	REPLY=$(( end_pos + ${#match[1]} - 1 )) 
	reply=($list_highlights) 
	return $(( $#braces_stack > 0 ))
}
_zsh_highlight_main_highlighter_highlight_path_separators () {
	local pos style_pathsep
	style_pathsep=$1_pathseparator 
	reply=() 
	[[ -z "$ZSH_HIGHLIGHT_STYLES[$style_pathsep]" || "$ZSH_HIGHLIGHT_STYLES[$1]" == "$ZSH_HIGHLIGHT_STYLES[$style_pathsep]" ]] && return 0
	for ((pos = start_pos; $pos <= end_pos; pos++ )) do
		if [[ $BUFFER[pos] == / ]]
		then
			reply+=($((pos - 1)) $pos $style_pathsep) 
		fi
	done
}
_zsh_highlight_main_highlighter_highlight_single_quote () {
	local arg1=$1 i q=\' style 
	i=$arg[(ib:arg1+1:)$q] 
	reply=() 
	if [[ $zsyh_user_options[rcquotes] == on ]]
	then
		while [[ $arg[i+1] == "'" ]]
		do
			reply+=($(( start_pos + i - 1 )) $(( start_pos + i + 1 )) rc-quote) 
			(( i++ ))
			i=$arg[(ib:i+1:)$q] 
		done
	fi
	if [[ $arg[i] == "'" ]]
	then
		style=single-quoted-argument 
	else
		(( i-- ))
		style=single-quoted-argument-unclosed 
	fi
	reply=($(( start_pos + arg1 - 1 )) $(( start_pos + i )) $style $reply) 
	REPLY=$i 
}
_zsh_highlight_pattern_highlighter_loop () {
	local buf="$1" pat="$2" 
	local -a match mbegin mend
	local MATCH
	integer MBEGIN MEND
	if [[ "$buf" == (#b)(*)(${~pat})* ]]
	then
		region_highlight+=("$((mbegin[2] - 1)) $mend[2] $ZSH_HIGHLIGHT_PATTERNS[$pat], memo=zsh-syntax-highlighting") 
		"$0" "$match[1]" "$pat"
		return $?
	fi
}
_zsh_highlight_preexec_hook () {
	typeset -g _ZSH_HIGHLIGHT_PRIOR_BUFFER= 
	typeset -gi _ZSH_HIGHLIGHT_PRIOR_CURSOR= 
}
_zsh_highlight_regexp_highlighter_loop () {
	local buf="$1" pat="$2" 
	integer OFFSET=0 
	local MATCH
	integer MBEGIN MEND
	local -a match mbegin mend
	while true
	do
		[[ "$buf" =~ "$pat" ]] || return
		region_highlight+=("$((MBEGIN - 1 + OFFSET)) $((MEND + OFFSET)) $ZSH_HIGHLIGHT_REGEXP[$pat], memo=zsh-syntax-highlighting") 
		buf="$buf[$(($MEND+1)),-1]" 
		OFFSET=$((MEND+OFFSET)) 
	done
}
_zsocket () {
	# undefined
	builtin autoload -XUz
}
_zstyle () {
	# undefined
	builtin autoload -XUz
}
_ztodo () {
	# undefined
	builtin autoload -XUz
}
_zypper () {
	# undefined
	builtin autoload -XUz
}
add-zle-hook-widget () {
	# undefined
	builtin autoload -XU
}
add-zsh-hook () {
	emulate -L zsh
	local -a hooktypes
	hooktypes=(chpwd precmd preexec periodic zshaddhistory zshexit zsh_directory_name) 
	local usage="Usage: add-zsh-hook hook function\nValid hooks are:\n  $hooktypes" 
	local opt
	local -a autoopts
	integer del list help
	while getopts "dDhLUzk" opt
	do
		case $opt in
			(d) del=1  ;;
			(D) del=2  ;;
			(h) help=1  ;;
			(L) list=1  ;;
			([Uzk]) autoopts+=(-$opt)  ;;
			(*) return 1 ;;
		esac
	done
	shift $(( OPTIND - 1 ))
	if (( list ))
	then
		typeset -mp "(${1:-${(@j:|:)hooktypes}})_functions"
		return $?
	elif (( help || $# != 2 || ${hooktypes[(I)$1]} == 0 ))
	then
		print -u$(( 2 - help )) $usage
		return $(( 1 - help ))
	fi
	local hook="${1}_functions" 
	local fn="$2" 
	if (( del ))
	then
		if (( ${(P)+hook} ))
		then
			if (( del == 2 ))
			then
				set -A $hook ${(P)hook:#${~fn}}
			else
				set -A $hook ${(P)hook:#$fn}
			fi
			if (( ! ${(P)#hook} ))
			then
				unset $hook
			fi
		fi
	else
		if (( ${(P)+hook} ))
		then
			if (( ${${(P)hook}[(I)$fn]} == 0 ))
			then
				typeset -ga $hook
				set -A $hook ${(P)hook} $fn
			fi
		else
			typeset -ga $hook
			set -A $hook $fn
		fi
		autoload $autoopts -- $fn
	fi
}
alias_value () {
	(( $+aliases[$1] )) && echo $aliases[$1]
}
azure_prompt_info () {
	return 1
}
bashcompinit () {
	# undefined
	builtin autoload -XUz
}
bracketed-paste-magic () {
	# undefined
	builtin autoload -XUz
}
bzr_prompt_info () {
	local bzr_branch
	bzr_branch=$(bzr nick 2>/dev/null)  || return
	if [[ -n "$bzr_branch" ]]
	then
		local bzr_dirty="" 
		if [[ -n $(bzr status 2>/dev/null) ]]
		then
			bzr_dirty=" %{$fg[red]%}*%{$reset_color%}" 
		fi
		printf "%s%s%s%s" "$ZSH_THEME_SCM_PROMPT_PREFIX" "bzr::${bzr_branch##*:}" "$bzr_dirty" "$ZSH_THEME_GIT_PROMPT_SUFFIX"
	fi
}
chruby_prompt_info () {
	return 1
}
clipcopy () {
	unfunction clipcopy clippaste
	detect-clipboard || true
	"$0" "$@"
}
clippaste () {
	unfunction clipcopy clippaste
	detect-clipboard || true
	"$0" "$@"
}
colors () {
	emulate -L zsh
	typeset -Ag color colour
	color=(00 none 01 bold 02 faint 22 normal 03 italic 23 no-italic 04 underline 24 no-underline 05 blink 25 no-blink 07 reverse 27 no-reverse 08 conceal 28 no-conceal 30 black 40 bg-black 31 red 41 bg-red 32 green 42 bg-green 33 yellow 43 bg-yellow 34 blue 44 bg-blue 35 magenta 45 bg-magenta 36 cyan 46 bg-cyan 37 white 47 bg-white 39 default 49 bg-default) 
	local k
	for k in ${(k)color}
	do
		color[${color[$k]}]=$k 
	done
	for k in ${color[(I)3?]}
	do
		color[fg-${color[$k]}]=$k 
	done
	for k in grey gray
	do
		color[$k]=${color[black]} 
		color[fg-$k]=${color[$k]} 
		color[bg-$k]=${color[bg-black]} 
	done
	colour=(${(kv)color}) 
	local lc=$'\e[' rc=m 
	typeset -Hg reset_color bold_color
	reset_color="$lc${color[none]}$rc" 
	bold_color="$lc${color[bold]}$rc" 
	typeset -AHg fg fg_bold fg_no_bold
	for k in ${(k)color[(I)fg-*]}
	do
		fg[${k#fg-}]="$lc${color[$k]}$rc" 
		fg_bold[${k#fg-}]="$lc${color[bold]};${color[$k]}$rc" 
		fg_no_bold[${k#fg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done
	typeset -AHg bg bg_bold bg_no_bold
	for k in ${(k)color[(I)bg-*]}
	do
		bg[${k#bg-}]="$lc${color[$k]}$rc" 
		bg_bold[${k#bg-}]="$lc${color[bold]};${color[$k]}$rc" 
		bg_no_bold[${k#bg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done
}
compaudit () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compdef () {
	local opt autol type func delete eval new i ret=0 cmd svc 
	local -a match mbegin mend
	emulate -L zsh
	setopt extendedglob
	if (( ! $# ))
	then
		print -u2 "$0: I need arguments"
		return 1
	fi
	while getopts "anpPkKde" opt
	do
		case "$opt" in
			(a) autol=yes  ;;
			(n) new=yes  ;;
			([pPkK]) if [[ -n "$type" ]]
				then
					print -u2 "$0: type already set to $type"
					return 1
				fi
				if [[ "$opt" = p ]]
				then
					type=pattern 
				elif [[ "$opt" = P ]]
				then
					type=postpattern 
				elif [[ "$opt" = K ]]
				then
					type=widgetkey 
				else
					type=key 
				fi ;;
			(d) delete=yes  ;;
			(e) eval=yes  ;;
		esac
	done
	shift OPTIND-1
	if (( ! $# ))
	then
		print -u2 "$0: I need arguments"
		return 1
	fi
	if [[ -z "$delete" ]]
	then
		if [[ -z "$eval" ]] && [[ "$1" = *\=* ]]
		then
			while (( $# ))
			do
				if [[ "$1" = *\=* ]]
				then
					cmd="${1%%\=*}" 
					svc="${1#*\=}" 
					func="$_comps[${_services[(r)$svc]:-$svc}]" 
					[[ -n ${_services[$svc]} ]] && svc=${_services[$svc]} 
					[[ -z "$func" ]] && func="${${_patcomps[(K)$svc][1]}:-${_postpatcomps[(K)$svc][1]}}" 
					if [[ -n "$func" ]]
					then
						_comps[$cmd]="$func" 
						_services[$cmd]="$svc" 
					else
						print -u2 "$0: unknown command or service: $svc"
						ret=1 
					fi
				else
					print -u2 "$0: invalid argument: $1"
					ret=1 
				fi
				shift
			done
			return ret
		fi
		func="$1" 
		[[ -n "$autol" ]] && autoload -rUz "$func"
		shift
		case "$type" in
			(widgetkey) while [[ -n $1 ]]
				do
					if [[ $# -lt 3 ]]
					then
						print -u2 "$0: compdef -K requires <widget> <comp-widget> <key>"
						return 1
					fi
					[[ $1 = _* ]] || 1="_$1" 
					[[ $2 = .* ]] || 2=".$2" 
					[[ $2 = .menu-select ]] && zmodload -i zsh/complist
					zle -C "$1" "$2" "$func"
					if [[ -n $new ]]
					then
						bindkey "$3" | IFS=$' \t' read -A opt
						[[ $opt[-1] = undefined-key ]] && bindkey "$3" "$1"
					else
						bindkey "$3" "$1"
					fi
					shift 3
				done ;;
			(key) if [[ $# -lt 2 ]]
				then
					print -u2 "$0: missing keys"
					return 1
				fi
				if [[ $1 = .* ]]
				then
					[[ $1 = .menu-select ]] && zmodload -i zsh/complist
					zle -C "$func" "$1" "$func"
				else
					[[ $1 = menu-select ]] && zmodload -i zsh/complist
					zle -C "$func" ".$1" "$func"
				fi
				shift
				for i
				do
					if [[ -n $new ]]
					then
						bindkey "$i" | IFS=$' \t' read -A opt
						[[ $opt[-1] = undefined-key ]] || continue
					fi
					bindkey "$i" "$func"
				done ;;
			(*) while (( $# ))
				do
					if [[ "$1" = -N ]]
					then
						type=normal 
					elif [[ "$1" = -p ]]
					then
						type=pattern 
					elif [[ "$1" = -P ]]
					then
						type=postpattern 
					else
						case "$type" in
							(pattern) if [[ $1 = (#b)(*)=(*) ]]
								then
									_patcomps[$match[1]]="=$match[2]=$func" 
								else
									_patcomps[$1]="$func" 
								fi ;;
							(postpattern) if [[ $1 = (#b)(*)=(*) ]]
								then
									_postpatcomps[$match[1]]="=$match[2]=$func" 
								else
									_postpatcomps[$1]="$func" 
								fi ;;
							(*) if [[ "$1" = *\=* ]]
								then
									cmd="${1%%\=*}" 
									svc=yes 
								else
									cmd="$1" 
									svc= 
								fi
								if [[ -z "$new" || -z "${_comps[$1]}" ]]
								then
									_comps[$cmd]="$func" 
									[[ -n "$svc" ]] && _services[$cmd]="${1#*\=}" 
								fi ;;
						esac
					fi
					shift
				done ;;
		esac
	else
		case "$type" in
			(pattern) unset "_patcomps[$^@]" ;;
			(postpattern) unset "_postpatcomps[$^@]" ;;
			(key) print -u2 "$0: cannot restore key bindings"
				return 1 ;;
			(*) unset "_comps[$^@]" ;;
		esac
	fi
}
compdump () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compgen () {
	local opts prefix suffix job OPTARG OPTIND ret=1 
	local -a name res results jids
	local -A shortopts
	emulate -L sh
	setopt kshglob noshglob braceexpand nokshautoload
	shortopts=(a alias b builtin c command d directory e export f file g group j job k keyword u user v variable) 
	while getopts "o:A:G:C:F:P:S:W:X:abcdefgjkuv" name
	do
		case $name in
			([abcdefgjkuv]) OPTARG="${shortopts[$name]}"  ;&
			(A) case $OPTARG in
					(alias) results+=("${(k)aliases[@]}")  ;;
					(arrayvar) results+=("${(k@)parameters[(R)array*]}")  ;;
					(binding) results+=("${(k)widgets[@]}")  ;;
					(builtin) results+=("${(k)builtins[@]}" "${(k)dis_builtins[@]}")  ;;
					(command) results+=("${(k)commands[@]}" "${(k)aliases[@]}" "${(k)builtins[@]}" "${(k)functions[@]}" "${(k)reswords[@]}")  ;;
					(directory) setopt bareglobqual
						results+=(${IPREFIX}${PREFIX}*${SUFFIX}${ISUFFIX}(N-/)) 
						setopt nobareglobqual ;;
					(disabled) results+=("${(k)dis_builtins[@]}")  ;;
					(enabled) results+=("${(k)builtins[@]}")  ;;
					(export) results+=("${(k)parameters[(R)*export*]}")  ;;
					(file) setopt bareglobqual
						results+=(${IPREFIX}${PREFIX}*${SUFFIX}${ISUFFIX}(N)) 
						setopt nobareglobqual ;;
					(function) results+=("${(k)functions[@]}")  ;;
					(group) emulate zsh
						_groups -U -O res
						emulate sh
						setopt kshglob noshglob braceexpand
						results+=("${res[@]}")  ;;
					(hostname) emulate zsh
						_hosts -U -O res
						emulate sh
						setopt kshglob noshglob braceexpand
						results+=("${res[@]}")  ;;
					(job) results+=("${savejobtexts[@]%% *}")  ;;
					(keyword) results+=("${(k)reswords[@]}")  ;;
					(running) jids=("${(@k)savejobstates[(R)running*]}") 
						for job in "${jids[@]}"
						do
							results+=(${savejobtexts[$job]%% *}) 
						done ;;
					(stopped) jids=("${(@k)savejobstates[(R)suspended*]}") 
						for job in "${jids[@]}"
						do
							results+=(${savejobtexts[$job]%% *}) 
						done ;;
					(setopt | shopt) results+=("${(k)options[@]}")  ;;
					(signal) results+=("SIG${^signals[@]}")  ;;
					(user) results+=("${(k)userdirs[@]}")  ;;
					(variable) results+=("${(k)parameters[@]}")  ;;
					(helptopic)  ;;
				esac ;;
			(F) COMPREPLY=() 
				local -a args
				args=("${words[0]}" "${@[-1]}" "${words[CURRENT-2]}") 
				() {
					typeset -h words
					$OPTARG "${args[@]}"
				}
				results+=("${COMPREPLY[@]}")  ;;
			(G) setopt nullglob
				results+=(${~OPTARG}) 
				unsetopt nullglob ;;
			(W) results+=(${(Q)~=OPTARG})  ;;
			(C) results+=($(eval $OPTARG))  ;;
			(P) prefix="$OPTARG"  ;;
			(S) suffix="$OPTARG"  ;;
			(X) if [[ ${OPTARG[0]} = '!' ]]
				then
					results=("${(M)results[@]:#${OPTARG#?}}") 
				else
					results=("${results[@]:#$OPTARG}") 
				fi ;;
		esac
	done
	print -l -r -- "$prefix${^results[@]}$suffix"
}
compinit () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compinstall () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
complete () {
	emulate -L zsh
	local args void cmd print remove
	args=("$@") 
	zparseopts -D -a void o: A: G: W: C: F: P: S: X: a b c d e f g j k u v p=print r=remove
	if [[ -n $print ]]
	then
		printf 'complete %2$s %1$s\n' "${(@kv)_comps[(R)_bash*]#* }"
	elif [[ -n $remove ]]
	then
		for cmd
		do
			unset "_comps[$cmd]"
		done
	else
		compdef _bash_complete\ ${(j. .)${(q)args[1,-1-$#]}} "$@"
	fi
}
conda_prompt_info () {
	return 1
}
d () {
	if [[ -n $1 ]]
	then
		dirs "$@"
	else
		dirs -v | head -n 10
	fi
}
default () {
	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2" && return 3
}
detect-clipboard () {
	emulate -L zsh
	if [[ "${OSTYPE}" == darwin* ]] && (( ${+commands[pbcopy]} )) && (( ${+commands[pbpaste]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | pbcopy
		}
		clippaste () {
			pbpaste
		}
	elif [[ "${OSTYPE}" == (cygwin|msys)* ]]
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" > /dev/clipboard
		}
		clippaste () {
			cat /dev/clipboard
		}
	elif (( $+commands[clip.exe] )) && (( $+commands[powershell.exe] ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | clip.exe
		}
		clippaste () {
			powershell.exe -noprofile -command Get-Clipboard
		}
	elif [ -n "${WAYLAND_DISPLAY:-}" ] && (( ${+commands[wl-copy]} )) && (( ${+commands[wl-paste]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | wl-copy &> /dev/null &|
		}
		clippaste () {
			wl-paste --no-newline
		}
	elif [ -n "${DISPLAY:-}" ] && (( ${+commands[xsel]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | xsel --clipboard --input
		}
		clippaste () {
			xsel --clipboard --output
		}
	elif [ -n "${DISPLAY:-}" ] && (( ${+commands[xclip]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | xclip -selection clipboard -in &> /dev/null &|
		}
		clippaste () {
			xclip -out -selection clipboard
		}
	elif (( ${+commands[lemonade]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | lemonade copy
		}
		clippaste () {
			lemonade paste
		}
	elif (( ${+commands[doitclient]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | doitclient wclip
		}
		clippaste () {
			doitclient wclip -r
		}
	elif (( ${+commands[win32yank]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | win32yank -i
		}
		clippaste () {
			win32yank -o
		}
	elif [[ $OSTYPE == linux-android* ]] && (( $+commands[termux-clipboard-set] ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | termux-clipboard-set
		}
		clippaste () {
			termux-clipboard-get
		}
	elif [ -n "${TMUX:-}" ] && (( ${+commands[tmux]} ))
	then
		clipcopy () {
			tmux load-buffer -w "${1:--}"
		}
		clippaste () {
			tmux save-buffer -
		}
	else
		_retry_clipboard_detection_or_fail () {
			local clipcmd="${1}" 
			shift
			if detect-clipboard
			then
				"${clipcmd}" "$@"
			else
				print "${clipcmd}: Platform $OSTYPE not supported or xclip/xsel not installed" >&2
				return 1
			fi
		}
		clipcopy () {
			_retry_clipboard_detection_or_fail clipcopy "$@"
		}
		clippaste () {
			_retry_clipboard_detection_or_fail clippaste "$@"
		}
		return 1
	fi
}
diff () {
	command diff --color "$@"
}
down-line-or-beginning-search () {
	# undefined
	builtin autoload -XU
}
edit-command-line () {
	# undefined
	builtin autoload -XU
}
env_default () {
	[[ ${parameters[$1]} = *-export* ]] && return 0
	export "$1=$2" && return 3
}
file_exists_at_url () {
	(
		if [[ -n "${1:-}" ]]
		then
			unset curl
			file_exists_at_url_command "$1" --insecure || {
				\typeset __ret=$?
				case ${__ret} in
					(60) file_exists_at_url_command "$1" || return $?
						return 0 ;;
					(*) return ${__ret} ;;
				esac
			}
		else
			rvm_warn "Warning: URL was not passed to file_exists_at_url"
			return 1
		fi
	)
}
file_exists_at_url_command () {
	__rvm_curl --silent --insecure --location --list-only --max-time ${rvm_max_time_flag:-5} --head "$@" 2>&1 | __rvm_grep -E 'HTTP/[0-9\.]+ 200' > /dev/null 2>&1 || {
		\typeset __ret=$?
		case ${__ret} in
			(28) rvm_warn "RVM was not able to check existence of remote files with timeout of ${rvm_max_time_flag:-3} seconds
you can increase the timeout by setting it in ~/.rvmrc => rvm_max_time_flag=10" ;;
		esac
		return ${__ret}
	}
}
gbda () {
	git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2> /dev/null
}
gbds () {
	local default_branch=$(git_main_branch) 
	(( ! $? )) || default_branch=$(git_develop_branch) 
	git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch
	do
		local merge_base=$(git merge-base $default_branch $branch) 
		if [[ $(git cherry $default_branch $(git commit-tree $(git rev-parse $branch\^{tree}) -p $merge_base -m _)) = -* ]]
		then
			git branch -D $branch
		fi
	done
}
gccd () {
	setopt localoptions extendedglob
	local repo="${${@[(r)(ssh://*|git://*|ftp(s)#://*|http(s)#://*|*@*)(.git/#)#]}:-$_}" 
	command git clone --recurse-submodules "$@" || return
	[[ -d "$_" ]] && cd "$_" || cd "${${repo:t}%.git/#}"
}
gdnolock () {
	git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
}
gdv () {
	git diff -w "$@" | view -
}
gem () {
	\typeset result
	(
		\typeset rvmrc
		rvm_rvmrc_files=("/etc/rvmrc" "$HOME/.rvmrc") 
		if [[ -n "${rvm_prefix:-}" ]] && ! [[ "$HOME/.rvmrc" -ef "${rvm_prefix}/.rvmrc" ]]
		then
			rvm_rvmrc_files+=("${rvm_prefix}/.rvmrc") 
		fi
		for rvmrc in "${rvm_rvmrc_files[@]}"
		do
			[[ -s "${rvmrc}" ]] && source "${rvmrc}" || true
		done
		unset rvm_rvmrc_files
		command gem "$@"
	) || result=$? 
	hash -r
	return ${result:-0}
}
gem_install () {
	\typeset gem_name gem_version version_check
	gem_version="" 
	__rvm_parse_gems_args "$@"
	if [[ -z "${gem_version}" ]]
	then
		__rvm_db "gem_${gem_name}_version" "gem_version"
	fi
	if (( ${rvm_force_flag:-0} == 0 )) && is_gem_installed
	then
		rvm_log "gem ${gem_name} ${gem_version:-} is already installed"
		return 0
	else
		gem_install_force || return $?
	fi
	true
}
gem_install_force () {
	\typeset __available_gem
	\typeset -a install_params
	install_params=() 
	__available_gem="$( __rvm_ls -v1 "${rvm_path}/gem-cache"/${gem_name}-${version_check}.gem 2>/dev/null | tail -n 1 )" 
	if [[ -n "${__available_gem}" ]]
	then
		install_params+=(--local) 
	elif [[ -n "${gem_version}" ]]
	then
		install_params+=(-v "${gem_version}") 
	fi
	if __rvm_version_compare "$(\command \gem --version)" -ge 2.2
	then
		install_params+=(--no-document) 
	else
		install_params+=(--no-ri --no-rdoc) 
	fi
	for __gem_option in ${rvm_gem_options}
	do
		case "${__gem_option}" in
			(--no-ri|--no-rdoc|--no-document)  ;;
			(*) install_params+=("${__gem_option}")  ;;
		esac
	done
	__rvm_log_command "gem.install.${gem_name}${gem_version:+-}${gem_version:-}" "installing gem ${__available_gem:-${gem_name}} ${install_params[*]}" \command \gem install "${__available_gem:-${gem_name}}" "${install_params[@]}" || return $?
}
gem_wrappers_pristine () {
	if [ "$(printf '%s\n' "3.2.0" "$(gem -v)" | sort -V | head -n1)" == "3.2.0" ]
	then
		gem pristine gem-wrappers --only-plugins > /dev/null
	fi
}
gemset_create () {
	\typeset gem_home gemset gemsets prefix
	[[ -n "$rvm_ruby_string" ]] || __rvm_select
	prefix="${rvm_ruby_gem_home%%${rvm_gemset_separator:-"@"}*}" 
	for gemset in "$@"
	do
		if [[ -z "$rvm_ruby_string" || "$rvm_ruby_string" == "system" ]]
		then
			rvm_error "Can not create gemset when using system ruby.  Try 'rvm use <some ruby>' first."
			return 1
		elif [[ "$gemset" == *"${rvm_gemset_separator:-"@"}"* ]]
		then
			rvm_error "Can not create gemset '$gemset', it contains a \"${rvm_gemset_separator:-"@"}\"."
			return 2
		elif [[ "$gemset" == *"${rvm_gemset_separator:-"@"}" ]]
		then
			rvm_error "Can not create gemset '$gemset', Missing name. "
			return 3
		fi
		gem_home="${prefix}${gemset:+${rvm_gemset_separator:-"@"}}${gemset}" 
		__rvm_remove_broken_symlinks "$gem_home"
		[[ -d "$gem_home/bin" ]] || mkdir -p "$gem_home/bin"
		if [[ ! -d "$gem_home/bin" ]]
		then
			rvm_error "Can not create gemset '$gemset', permissions problem? "
			return 4
		fi
		: rvm_gems_cache_path:${rvm_gems_cache_path:=${rvm_gems_path:-"$rvm_path/gems"}/cache}
		if __rvm_using_gemset_globalcache
		then
			if [[ -d "$gem_home/cache" && ! -L "$gem_home/cache" ]]
			then
				\command \mv -n "$gem_home/cache"/*.gem "$rvm_gems_cache_path/" 2> /dev/null
			fi
			__rvm_rm_rf "$gem_home/cache"
			ln -fs "$rvm_gems_cache_path" "$gem_home/cache"
		else
			__rvm_remove_broken_symlinks "$gem_home/cache"
			mkdir -p "$gem_home/cache"
		fi
		rvm_log "$rvm_ruby_string - #gemset created $gem_home"
		if (( ${rvm_skip_gemsets_flag:-0} == 0 ))
		then
			__rvm_with "${rvm_ruby_string}${gemset:+@}${gemset}" gemset_initial ${gemset:-default}
		fi
	done
	if (( ${rvm_skip_gemsets_flag:-0} != 0 ))
	then
		rvm_log "Skipped importing default gemsets"
	fi
}
gemset_import () {
	\typeset __prefix rvm_file_name
	unset -f gem
	__rvm_select
	__prefix="$1" 
	if [[ -n "${2:-}" ]]
	then
		rvm_file_name="${2%.gems*}.gems" 
	else
		\typeset -a gem_file_names
		gem_file_names=("${rvm_gemset_name}.gems" "default.gems" "system.gems" ".gems") 
		__rvm_find_first_file rvm_file_name "${gem_file_names[@]}" || {
			rvm_error "No *.gems file found."
			return 1
		}
	fi
	[[ -d "$rvm_ruby_gem_home/specifications/" ]] || mkdir -p "$rvm_ruby_gem_home/specifications/"
	[[ -d "$rvm_gems_cache_path" ]] || mkdir -p "$rvm_gems_cache_path"
	\typeset -a lines
	lines=() 
	if [[ -s "$rvm_file_name" ]]
	then
		__rvm_read_lines lines "${rvm_file_name}"
		__rvm_lines_without_comments
	fi
	rvm_debug "lines from ${rvm_file_name}: ${lines[*]}"
	if [[ -n "${3:-}" ]]
	then
		__rvm_lines_without_gems
		__rvm_lines_with_gems "${3}"
		rvm_debug "recalculated lines($3): ${lines[*]}"
	fi
	if (( ${#lines[@]} ))
	then
		__rvm_log_command "gemsets.import${3:+.}${3:-}" "${__prefix} $rvm_file_name" gemset_import_list "${lines[@]}"
	else
		rvm_log "${__prefix}file $rvm_file_name evaluated to empty gem list"
	fi
}
gemset_import_list () {
	case "${rvm_ruby_string}" in
		(*jruby*) \command \gem install "$@" ;;
		(*) \typeset line
			for line
			do
				gem_install $line || rvm_error "there was an error installing gem $line"
			done ;;
	esac
}
gemset_initial () {
	\typeset gemsets gemset _iterator paths _jruby_opts
	_jruby_opts=$JRUBY_OPTS 
	export JRUBY_OPTS="${JRUBY_OPTS} --dev" 
	true ${rvm_gemsets_path:="$rvm_path/gemsets"}
	[[ -d "$rvm_gems_path/${rvm_ruby_string}/cache" ]] || mkdir -p "$rvm_gems_path/${rvm_ruby_string}/cache" 2> /dev/null
	__rvm_ensure_has_environment_files
	paths=($( __rvm_ruby_string_paths_under "$rvm_gemsets_path" | sort -r )) 
	for _iterator in "${paths[@]}"
	do
		if [[ -f "${_iterator}/$1.gems" ]]
		then
			gemset_import "$rvm_ruby_string - #importing gemset" "${_iterator}/$1.gems" "$1"
			break
		else
			rvm_debug "$rvm_ruby_string - #gemset definition does not exist ${_iterator}/$1.gems"
		fi
	done
	__rvm_log_command "gemset.wrappers.$1" "$rvm_ruby_string - #generating ${1} wrappers" run_gem_wrappers regenerate 2> /dev/null || true
	export JRUBY_OPTS=${_jruby_opts} 
}
gemset_pristine () {
	if (
			unset -f gem
			builtin command -v gem > /dev/null
		)
	then
		\typeset _gem _version _platforms
		\typeset -a _failed _pristine_command
		_failed=() 
		_pristine_command=(\command \gem pristine) 
		if __rvm_version_compare "$(\command \gem --version)" -ge 2.2.0
		then
			_pristine_command+=(--extensions) 
		fi
		rvm_log "Restoring gems to pristine condition..."
		while read _gem _version _platforms
		do
			printf "%b" "${_gem}-${_version} "
			"${_pristine_command[@]}" "${_gem}" --version "${_version}" > /dev/null || _failed+=("${_gem} --version ${_version}") 
		done <<< "$(
      GEM_PATH="$GEM_HOME" __rvm_list_gems \
        "${pristine_gems_filter:-"! gem.executables.empty? || ! gem.extensions.empty?"}"
    )"
		if (( ${#_failed[@]} > 0 ))
		then
			rvm_error "\n'${_pristine_command[*]} ${_failed[*]}' failed, you need to fix these gems manually."
			return 1
		else
			rvm_log "\nfinished."
		fi
	else
		rvm_error "'gem' command not found in PATH."
		return 1
	fi
}
gemset_reset_env () {
	(
		export rvm_internal_use_flag=1 
		export rvm_use_flag=0 
		__rvm_use "${1:-}"
		__rvm_ensure_has_environment_files && run_gem_wrappers regenerate || return $?
	)
}
getent () {
	if [[ $1 = hosts ]]
	then
		sed 's/#.*//' /etc/$1 | grep -w $2
	elif [[ $2 = <-> ]]
	then
		grep ":$2:[^:]*$" /etc/$1
	else
		grep "^$2:" /etc/$1
	fi
}
ggf () {
	local b
	[[ $# != 1 ]] && b="$(git_current_branch)" 
	git push --force origin "${b:-$1}"
}
ggfl () {
	local b
	[[ $# != 1 ]] && b="$(git_current_branch)" 
	git push --force-with-lease origin "${b:-$1}"
}
ggl () {
	if [[ $# != 0 ]] && [[ $# != 1 ]]
	then
		git pull origin "${*}"
	else
		local b
		[[ $# == 0 ]] && b="$(git_current_branch)" 
		git pull origin "${b:-$1}"
	fi
}
ggp () {
	if [[ $# != 0 ]] && [[ $# != 1 ]]
	then
		git push origin "${*}"
	else
		local b
		[[ $# == 0 ]] && b="$(git_current_branch)" 
		git push origin "${b:-$1}"
	fi
}
ggpnp () {
	if [[ $# == 0 ]]
	then
		ggl && ggp
	else
		ggl "${*}" && ggp "${*}"
	fi
}
ggu () {
	local b
	[[ $# != 1 ]] && b="$(git_current_branch)" 
	git pull --rebase origin "${b:-$1}"
}
git_commits_ahead () {
	if __git_prompt_git rev-parse --git-dir &> /dev/null
	then
		local commits="$(__git_prompt_git rev-list --count @{upstream}..HEAD 2>/dev/null)" 
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_AHEAD_PREFIX$commits$ZSH_THEME_GIT_COMMITS_AHEAD_SUFFIX"
		fi
	fi
}
git_commits_behind () {
	if __git_prompt_git rev-parse --git-dir &> /dev/null
	then
		local commits="$(__git_prompt_git rev-list --count HEAD..@{upstream} 2>/dev/null)" 
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_BEHIND_PREFIX$commits$ZSH_THEME_GIT_COMMITS_BEHIND_SUFFIX"
		fi
	fi
}
git_current_branch () {
	local ref
	ref=$(__git_prompt_git symbolic-ref --quiet HEAD 2> /dev/null) 
	local ret=$? 
	if [[ $ret != 0 ]]
	then
		[[ $ret == 128 ]] && return
		ref=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null)  || return
	fi
	echo ${ref#refs/heads/}
}
git_current_user_email () {
	__git_prompt_git config user.email 2> /dev/null
}
git_current_user_name () {
	__git_prompt_git config user.name 2> /dev/null
}
git_develop_branch () {
	command git rev-parse --git-dir &> /dev/null || return
	local branch
	for branch in dev devel develop development
	do
		if command git show-ref -q --verify refs/heads/$branch
		then
			echo $branch
			return 0
		fi
	done
	echo develop
	return 1
}
git_main_branch () {
	command git rev-parse --git-dir &> /dev/null || return
	local remote ref
	for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}
	do
		if command git show-ref -q --verify $ref
		then
			echo ${ref:t}
			return 0
		fi
	done
	for remote in origin upstream
	do
		ref=$(command git rev-parse --abbrev-ref $remote/HEAD 2>/dev/null) 
		if [[ $ref == $remote/* ]]
		then
			echo ${ref#"$remote/"}
			return 0
		fi
	done
	echo master
	return 1
}
git_previous_branch () {
	local ref
	ref=$(__git_prompt_git rev-parse --quiet --symbolic-full-name @{-1} 2> /dev/null) 
	local ret=$? 
	if [[ $ret != 0 ]] || [[ -z $ref ]]
	then
		return
	fi
	echo ${ref#refs/heads/}
}
git_prompt_ahead () {
	if [[ -n "$(__git_prompt_git rev-list origin/$(git_current_branch)..HEAD 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_AHEAD"
	fi
}
git_prompt_behind () {
	if [[ -n "$(__git_prompt_git rev-list HEAD..origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_BEHIND"
	fi
}
git_prompt_info () {
	if [[ -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_info]}" ]]
	then
		echo -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_info]}"
	fi
}
git_prompt_long_sha () {
	local SHA
	SHA=$(__git_prompt_git rev-parse HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}
git_prompt_remote () {
	if [[ -n "$(__git_prompt_git show-ref origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_EXISTS"
	else
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_MISSING"
	fi
}
git_prompt_short_sha () {
	local SHA
	SHA=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}
git_prompt_status () {
	if [[ -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_status]}" ]]
	then
		echo -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_status]}"
	fi
}
git_remote_status () {
	local remote ahead behind git_remote_status git_remote_status_detailed
	remote=${$(__git_prompt_git rev-parse --verify ${hook_com[branch]}@{upstream} --symbolic-full-name 2>/dev/null)/refs\/remotes\/} 
	if [[ -n ${remote} ]]
	then
		ahead=$(__git_prompt_git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l) 
		behind=$(__git_prompt_git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l) 
		if [[ $ahead -eq 0 ]] && [[ $behind -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_EQUAL_REMOTE" 
		elif [[ $ahead -gt 0 ]] && [[ $behind -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE$((ahead))%{$reset_color%}" 
		elif [[ $behind -gt 0 ]] && [[ $ahead -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE$((behind))%{$reset_color%}" 
		elif [[ $ahead -gt 0 ]] && [[ $behind -gt 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE$((ahead))%{$reset_color%}$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE$((behind))%{$reset_color%}" 
		fi
		if [[ -n $ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_DETAILED ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_PREFIX${remote:gs/%/%%}$git_remote_status_detailed$ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_SUFFIX" 
		fi
		echo $git_remote_status
	fi
}
git_repo_name () {
	local repo_path
	if repo_path="$(__git_prompt_git rev-parse --show-toplevel 2>/dev/null)"  && [[ -n "$repo_path" ]]
	then
		echo ${repo_path:t}
	fi
}
grename () {
	if [[ -z "$1" || -z "$2" ]]
	then
		echo "Usage: $0 old_branch new_branch"
		return 1
	fi
	git branch -m "$1" "$2"
	if git push origin :"$1"
	then
		git push --set-upstream origin "$2"
	fi
}
gunwipall () {
	local _commit=$(git log --grep='--wip--' --invert-grep --max-count=1 --format=format:%H) 
	if [[ "$_commit" != "$(git rev-parse HEAD)" ]]
	then
		git reset $_commit || return 1
	fi
}
handle_completion_insecurities () {
	local -aU insecure_dirs
	insecure_dirs=(${(f@):-"$(compaudit 2>/dev/null)"}) 
	[[ -z "${insecure_dirs}" ]] && return
	print "[oh-my-zsh] Insecure completion-dependent directories detected:"
	ls -ld "${(@)insecure_dirs}"
	cat <<EOD

[oh-my-zsh] For safety, we will not load completions from these directories until
[oh-my-zsh] you fix their permissions and ownership and restart zsh.
[oh-my-zsh] See the above list for directories with group or other writability.

[oh-my-zsh] To fix your permissions you can do so by disabling
[oh-my-zsh] the write permission of "group" and "others" and making sure that the
[oh-my-zsh] owner of these directories is either root or your current user.
[oh-my-zsh] The following command may help:
[oh-my-zsh]     compaudit | xargs chmod g-w,o-w

[oh-my-zsh] If the above didn't help or you want to skip the verification of
[oh-my-zsh] insecure directories you can set the variable ZSH_DISABLE_COMPFIX to
[oh-my-zsh] "true" before oh-my-zsh is sourced in your zshrc file.

EOD
}
hg_prompt_info () {
	return 1
}
is-at-least () {
	emulate -L zsh
	local IFS=".-" min_cnt=0 ver_cnt=0 part min_ver version order 
	min_ver=(${=1}) 
	version=(${=2:-$ZSH_VERSION} 0) 
	while (( $min_cnt <= ${#min_ver} ))
	do
		while [[ "$part" != <-> ]]
		do
			(( ++ver_cnt > ${#version} )) && return 0
			if [[ ${version[ver_cnt]} = *[0-9][^0-9]* ]]
			then
				order=(${version[ver_cnt]} ${min_ver[ver_cnt]}) 
				if [[ ${version[ver_cnt]} = <->* ]]
				then
					[[ $order != ${${(On)order}} ]] && return 1
				else
					[[ $order != ${${(O)order}} ]] && return 1
				fi
				[[ $order[1] != $order[2] ]] && return 0
			fi
			part=${version[ver_cnt]##*[^0-9]} 
		done
		while true
		do
			(( ++min_cnt > ${#min_ver} )) && return 0
			[[ ${min_ver[min_cnt]} = <-> ]] && break
		done
		(( part > min_ver[min_cnt] )) && return 0
		(( part < min_ver[min_cnt] )) && return 1
		part='' 
	done
}
is_a_function () {
	\typeset -f $1 > /dev/null 2>&1 || return $?
}
is_gem_installed () {
	\typeset gem_spec
	gem_spec="gem '$gem_name'" 
	if [[ -n "${gem_version}" ]]
	then
		gem_spec+=", '$gem_version'" 
		version_check="${gem_version#*=}" 
	else
		version_check="*([[:digit:]\.])" 
	fi
	__rvm_ls -ld "${rvm_ruby_gem_home:-$GEM_HOME}/gems"/${gem_name}-${version_check} > /dev/null 2>&1 || "${rvm_ruby_binary}" -rrubygems -e "$gem_spec" 2> /dev/null || return $?
}
is_parent_of () {
	\typeset name pid ppid pname
	name=$1 
	pid=$2 
	while [[ -n "$pid" && "$pid" != "0" ]]
	do
		case "`uname`" in
			(SunOS) read ppid pname <<< "$(\command \ps -p $pid -o ppid= -o comm=)" ;;
			(*) read ppid pname <<< "$(\command \ps -p $pid -o ppid= -o ucomm=)" ;;
		esac
		if [[ -n "$ppid" && -n "$pname" ]]
		then
			if [[ "$pname" == "$name" ]]
			then
				echo $pid
				return 0
			else
				pid=$ppid 
			fi
		else
			break
		fi
	done
	return 1
}
is_plugin () {
	local base_dir=$1 
	local name=$2 
	builtin test -f $base_dir/plugins/$name/$name.plugin.zsh || builtin test -f $base_dir/plugins/$name/_$name
}
is_theme () {
	local base_dir=$1 
	local name=$2 
	builtin test -f $base_dir/$name.zsh-theme
}
jenv_prompt_info () {
	return 1
}
load_rvm_scripts () {
	\typeset -a scripts
	scripts=(selector logging support utility init cleanup env rvmrc install environment gemset checksum list) 
	source "${rvm_scripts_path}/initialize"
	for entry in ${scripts[@]}
	do
		[[ " ${rvm_base_except:-} " == *" $entry "* ]] || source "${rvm_scripts_path}/functions/$entry" || return $?
	done
	unset rvm_base_except
}
mkcd () {
	mkdir -p $@ && cd ${@:$#}
}
nvm () {
	if [ "$#" -lt 1 ]
	then
		nvm --help
		return
	fi
	local DEFAULT_IFS
	DEFAULT_IFS=" $(nvm_echo t | command tr t \\t)
" 
	if [ "${-#*e}" != "$-" ]
	then
		set +e
		local EXIT_CODE
		IFS="${DEFAULT_IFS}" nvm "$@"
		EXIT_CODE="$?" 
		set -e
		return "$EXIT_CODE"
	elif [ "${-#*a}" != "$-" ]
	then
		set +a
		local EXIT_CODE
		IFS="${DEFAULT_IFS}" nvm "$@"
		EXIT_CODE="$?" 
		set -a
		return "$EXIT_CODE"
	elif [ -n "${BASH-}" ] && [ "${-#*E}" != "$-" ]
	then
		set +E
		local EXIT_CODE
		IFS="${DEFAULT_IFS}" nvm "$@"
		EXIT_CODE="$?" 
		set -E
		return "$EXIT_CODE"
	elif [ "${IFS}" != "${DEFAULT_IFS}" ]
	then
		IFS="${DEFAULT_IFS}" nvm "$@"
		return "$?"
	fi
	local i
	for i in "$@"
	do
		case $i in
			(--) break ;;
			('-h' | 'help' | '--help') NVM_NO_COLORS="" 
				for j in "$@"
				do
					if [ "${j}" = '--no-colors' ]
					then
						NVM_NO_COLORS="${j}" 
						break
					fi
				done
				local NVM_IOJS_PREFIX
				NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
				local NVM_NODE_PREFIX
				NVM_NODE_PREFIX="$(nvm_node_prefix)" 
				NVM_VERSION="$(nvm --version)" 
				nvm_echo
				nvm_echo "Node Version Manager (v${NVM_VERSION})"
				nvm_echo
				nvm_echo 'Note: <version> refers to any version-like string nvm understands. This includes:'
				nvm_echo '  - full or partial version numbers, starting with an optional "v" (0.10, v0.1.2, v1)'
				nvm_echo "  - default (built-in) aliases: ${NVM_NODE_PREFIX}, stable, unstable, ${NVM_IOJS_PREFIX}, system"
				nvm_echo '  - custom aliases you define with `nvm alias foo`'
				nvm_echo
				nvm_echo ' Any options that produce colorized output should respect the `--no-colors` option.'
				nvm_echo
				nvm_echo 'Usage:'
				nvm_echo '  nvm --help                                  Show this message'
				nvm_echo '    --no-colors                               Suppress colored output'
				nvm_echo '  nvm --version                               Print out the installed version of nvm'
				nvm_echo '  nvm install [<version>]                     Download and install a <version>. Uses .nvmrc if available and version is omitted.'
				nvm_echo '   The following optional arguments, if provided, must appear directly after `nvm install`:'
				nvm_echo '    -s                                        Skip binary download, install from source only.'
				nvm_echo '    -b                                        Skip source download, install from binary only.'
				nvm_echo '    --reinstall-packages-from=<version>       When installing, reinstall packages installed in <node|iojs|node version number>'
				nvm_echo '    --lts                                     When installing, only select from LTS (long-term support) versions'
				nvm_echo '    --lts=<LTS name>                          When installing, only select from versions for a specific LTS line'
				nvm_echo '    --skip-default-packages                   When installing, skip the default-packages file if it exists'
				nvm_echo '    --latest-npm                              After installing, attempt to upgrade to the latest working npm on the given node version'
				nvm_echo '    --no-progress                             Disable the progress bar on any downloads'
				nvm_echo '    --alias=<name>                            After installing, set the alias specified to the version specified. (same as: nvm alias <name> <version>)'
				nvm_echo '    --default                                 After installing, set default alias to the version specified. (same as: nvm alias default <version>)'
				nvm_echo '    --save                                    After installing, write the specified version to .nvmrc'
				nvm_echo '  nvm uninstall <version>                     Uninstall a version'
				nvm_echo '  nvm uninstall --lts                         Uninstall using automatic LTS (long-term support) alias `lts/*`, if available.'
				nvm_echo '  nvm uninstall --lts=<LTS name>              Uninstall using automatic alias for provided LTS line, if available.'
				nvm_echo '  nvm use [<version>]                         Modify PATH to use <version>. Uses .nvmrc if available and version is omitted.'
				nvm_echo '   The following optional arguments, if provided, must appear directly after `nvm use`:'
				nvm_echo '    --silent                                  Silences stdout/stderr output'
				nvm_echo '    --lts                                     Uses automatic LTS (long-term support) alias `lts/*`, if available.'
				nvm_echo '    --lts=<LTS name>                          Uses automatic alias for provided LTS line, if available.'
				nvm_echo '    --save                                    Writes the specified version to .nvmrc.'
				nvm_echo '  nvm exec [<version>] [<command>]            Run <command> on <version>. Uses .nvmrc if available and version is omitted.'
				nvm_echo '   The following optional arguments, if provided, must appear directly after `nvm exec`:'
				nvm_echo '    --silent                                  Silences stdout/stderr output'
				nvm_echo '    --lts                                     Uses automatic LTS (long-term support) alias `lts/*`, if available.'
				nvm_echo '    --lts=<LTS name>                          Uses automatic alias for provided LTS line, if available.'
				nvm_echo '  nvm run [<version>] [<args>]                Run `node` on <version> with <args> as arguments. Uses .nvmrc if available and version is omitted.'
				nvm_echo '   The following optional arguments, if provided, must appear directly after `nvm run`:'
				nvm_echo '    --silent                                  Silences stdout/stderr output'
				nvm_echo '    --lts                                     Uses automatic LTS (long-term support) alias `lts/*`, if available.'
				nvm_echo '    --lts=<LTS name>                          Uses automatic alias for provided LTS line, if available.'
				nvm_echo '  nvm current                                 Display currently activated version of Node'
				nvm_echo '  nvm ls [<version>]                          List installed versions, matching a given <version> if provided'
				nvm_echo '    --no-colors                               Suppress colored output'
				nvm_echo '    --no-alias                                Suppress `nvm alias` output'
				nvm_echo '  nvm ls-remote [<version>]                   List remote versions available for install, matching a given <version> if provided'
				nvm_echo '    --lts                                     When listing, only show LTS (long-term support) versions'
				nvm_echo '    --lts=<LTS name>                          When listing, only show versions for a specific LTS line'
				nvm_echo '    --no-colors                               Suppress colored output'
				nvm_echo '  nvm version <version>                       Resolve the given description to a single local version'
				nvm_echo '  nvm version-remote <version>                Resolve the given description to a single remote version'
				nvm_echo '    --lts                                     When listing, only select from LTS (long-term support) versions'
				nvm_echo '    --lts=<LTS name>                          When listing, only select from versions for a specific LTS line'
				nvm_echo '  nvm deactivate                              Undo effects of `nvm` on current shell'
				nvm_echo '    --silent                                  Silences stdout/stderr output'
				nvm_echo '  nvm alias [<pattern>]                       Show all aliases beginning with <pattern>'
				nvm_echo '    --no-colors                               Suppress colored output'
				nvm_echo '  nvm alias <name> <version>                  Set an alias named <name> pointing to <version>'
				nvm_echo '  nvm unalias <name>                          Deletes the alias named <name>'
				nvm_echo '  nvm install-latest-npm                      Attempt to upgrade to the latest working `npm` on the current node version'
				nvm_echo '  nvm reinstall-packages <version>            Reinstall global `npm` packages contained in <version> to current version'
				nvm_echo '  nvm unload                                  Unload `nvm` from shell'
				nvm_echo '  nvm which [current | <version>]             Display path to installed node version. Uses .nvmrc if available and version is omitted.'
				nvm_echo '    --silent                                  Silences stdout/stderr output when a version is omitted'
				nvm_echo '  nvm cache dir                               Display path to the cache directory for nvm'
				nvm_echo '  nvm cache clear                             Empty cache directory for nvm'
				nvm_echo '  nvm set-colors [<color codes>]              Set five text colors using format "yMeBg". Available when supported.'
				nvm_echo '                                               Initial colors are:'
				nvm_echo_with_colors "                                                  $(nvm_wrap_with_color_code 'b' 'b')$(nvm_wrap_with_color_code 'y' 'y')$(nvm_wrap_with_color_code 'g' 'g')$(nvm_wrap_with_color_code 'r' 'r')$(nvm_wrap_with_color_code 'e' 'e')"
				nvm_echo '                                               Color codes:'
				nvm_echo_with_colors "                                                $(nvm_wrap_with_color_code 'r' 'r')/$(nvm_wrap_with_color_code 'R' 'R') = $(nvm_wrap_with_color_code 'r' 'red') / $(nvm_wrap_with_color_code 'R' 'bold red')"
				nvm_echo_with_colors "                                                $(nvm_wrap_with_color_code 'g' 'g')/$(nvm_wrap_with_color_code 'G' 'G') = $(nvm_wrap_with_color_code 'g' 'green') / $(nvm_wrap_with_color_code 'G' 'bold green')"
				nvm_echo_with_colors "                                                $(nvm_wrap_with_color_code 'b' 'b')/$(nvm_wrap_with_color_code 'B' 'B') = $(nvm_wrap_with_color_code 'b' 'blue') / $(nvm_wrap_with_color_code 'B' 'bold blue')"
				nvm_echo_with_colors "                                                $(nvm_wrap_with_color_code 'c' 'c')/$(nvm_wrap_with_color_code 'C' 'C') = $(nvm_wrap_with_color_code 'c' 'cyan') / $(nvm_wrap_with_color_code 'C' 'bold cyan')"
				nvm_echo_with_colors "                                                $(nvm_wrap_with_color_code 'm' 'm')/$(nvm_wrap_with_color_code 'M' 'M') = $(nvm_wrap_with_color_code 'm' 'magenta') / $(nvm_wrap_with_color_code 'M' 'bold magenta')"
				nvm_echo_with_colors "                                                $(nvm_wrap_with_color_code 'y' 'y')/$(nvm_wrap_with_color_code 'Y' 'Y') = $(nvm_wrap_with_color_code 'y' 'yellow') / $(nvm_wrap_with_color_code 'Y' 'bold yellow')"
				nvm_echo_with_colors "                                                $(nvm_wrap_with_color_code 'k' 'k')/$(nvm_wrap_with_color_code 'K' 'K') = $(nvm_wrap_with_color_code 'k' 'black') / $(nvm_wrap_with_color_code 'K' 'bold black')"
				nvm_echo_with_colors "                                                $(nvm_wrap_with_color_code 'e' 'e')/$(nvm_wrap_with_color_code 'W' 'W') = $(nvm_wrap_with_color_code 'e' 'light grey') / $(nvm_wrap_with_color_code 'W' 'white')"
				nvm_echo 'Example:'
				nvm_echo '  nvm install 8.0.0                     Install a specific version number'
				nvm_echo '  nvm use 8.0                           Use the latest available 8.0.x release'
				nvm_echo '  nvm run 6.10.3 app.js                 Run app.js using node 6.10.3'
				nvm_echo '  nvm exec 4.8.3 node app.js            Run `node app.js` with the PATH pointing to node 4.8.3'
				nvm_echo '  nvm alias default 8.1.0               Set default node version on a shell'
				nvm_echo '  nvm alias default node                Always default to the latest available node version on a shell'
				nvm_echo
				nvm_echo '  nvm install node                      Install the latest available version'
				nvm_echo '  nvm use node                          Use the latest version'
				nvm_echo '  nvm install --lts                     Install the latest LTS version'
				nvm_echo '  nvm use --lts                         Use the latest LTS version'
				nvm_echo
				nvm_echo '  nvm set-colors cgYmW                  Set text colors to cyan, green, bold yellow, magenta, and white'
				nvm_echo
				nvm_echo 'Note:'
				nvm_echo '  to remove, delete, or uninstall nvm - just remove the `$NVM_DIR` folder (usually `~/.nvm`)'
				nvm_echo
				return 0 ;;
		esac
	done
	local COMMAND
	COMMAND="${1-}" 
	shift
	local VERSION
	local ADDITIONAL_PARAMETERS
	case $COMMAND in
		("cache") case "${1-}" in
				(dir) nvm_cache_dir ;;
				(clear) local DIR
					DIR="$(nvm_cache_dir)" 
					if command rm -rf "${DIR}" && command mkdir -p "${DIR}"
					then
						nvm_echo 'nvm cache cleared.'
					else
						nvm_err "Unable to clear nvm cache: ${DIR}"
						return 1
					fi ;;
				(*) nvm --help >&2
					return 127 ;;
			esac ;;
		("debug") local OS_VERSION
			nvm_is_zsh && setopt local_options shwordsplit
			nvm_err "nvm --version: v$(nvm --version)"
			if [ -n "${TERM_PROGRAM-}" ]
			then
				nvm_err "\$TERM_PROGRAM: ${TERM_PROGRAM}"
			fi
			nvm_err "\$SHELL: ${SHELL}"
			nvm_err "\$SHLVL: ${SHLVL-}"
			nvm_err "whoami: '$(whoami)'"
			nvm_err "\${HOME}: ${HOME}"
			nvm_err "\${NVM_DIR}: '$(nvm_sanitize_path "${NVM_DIR}")'"
			nvm_err "\${PATH}: $(nvm_sanitize_path "${PATH}")"
			nvm_err "\$PREFIX: '$(nvm_sanitize_path "${PREFIX}")'"
			nvm_err "\${NPM_CONFIG_PREFIX}: '$(nvm_sanitize_path "${NPM_CONFIG_PREFIX}")'"
			nvm_err "\$NVM_NODEJS_ORG_MIRROR: '${NVM_NODEJS_ORG_MIRROR}'"
			nvm_err "\$NVM_IOJS_ORG_MIRROR: '${NVM_IOJS_ORG_MIRROR}'"
			nvm_err "shell version: '$(${SHELL} --version | command head -n 1)'"
			nvm_err "uname -a: '$(command uname -a | command awk '{$2=""; print}' | command xargs)'"
			nvm_err "checksum binary: '$(nvm_get_checksum_binary 2>/dev/null)'"
			if [ "$(nvm_get_os)" = "darwin" ] && nvm_has sw_vers
			then
				OS_VERSION="$(sw_vers | command awk '{print $2}' | command xargs)" 
			elif [ -r "/etc/issue" ]
			then
				OS_VERSION="$(command head -n 1 /etc/issue | command sed 's/\\.//g')" 
				if [ -z "${OS_VERSION}" ] && [ -r "/etc/os-release" ]
				then
					OS_VERSION="$(. /etc/os-release && echo "${NAME}" "${VERSION}")" 
				fi
			fi
			if [ -n "${OS_VERSION}" ]
			then
				nvm_err "OS version: ${OS_VERSION}"
			fi
			if nvm_has "awk"
			then
				nvm_err "awk: $(nvm_command_info awk), $({ command awk --version 2>/dev/null || command awk -W version; } \
          | command head -n 1)"
			else
				nvm_err "awk: not found"
			fi
			if nvm_has "curl"
			then
				nvm_err "curl: $(nvm_command_info curl), $(command curl -V | command head -n 1)"
			else
				nvm_err "curl: not found"
			fi
			if nvm_has "wget"
			then
				nvm_err "wget: $(nvm_command_info wget), $(command wget -V | command head -n 1)"
			else
				nvm_err "wget: not found"
			fi
			local TEST_TOOLS ADD_TEST_TOOLS
			TEST_TOOLS="git grep" 
			ADD_TEST_TOOLS="sed cut basename rm mkdir xargs" 
			if [ "darwin" != "$(nvm_get_os)" ] && [ "freebsd" != "$(nvm_get_os)" ]
			then
				TEST_TOOLS="${TEST_TOOLS} ${ADD_TEST_TOOLS}" 
			else
				for tool in ${ADD_TEST_TOOLS}
				do
					if nvm_has "${tool}"
					then
						nvm_err "${tool}: $(nvm_command_info "${tool}")"
					else
						nvm_err "${tool}: not found"
					fi
				done
			fi
			for tool in ${TEST_TOOLS}
			do
				local NVM_TOOL_VERSION
				if nvm_has "${tool}"
				then
					if command ls -l "$(nvm_command_info "${tool}" | command awk '{print $1}')" | command grep -q busybox
					then
						NVM_TOOL_VERSION="$(command "${tool}" --help 2>&1 | command head -n 1)" 
					else
						NVM_TOOL_VERSION="$(command "${tool}" --version 2>&1 | command head -n 1)" 
					fi
					nvm_err "${tool}: $(nvm_command_info "${tool}"), ${NVM_TOOL_VERSION}"
				else
					nvm_err "${tool}: not found"
				fi
				unset NVM_TOOL_VERSION
			done
			unset TEST_TOOLS ADD_TEST_TOOLS
			local NVM_DEBUG_OUTPUT
			for NVM_DEBUG_COMMAND in 'nvm current' 'which node' 'which iojs' 'which npm' 'npm config get prefix' 'npm root -g'
			do
				NVM_DEBUG_OUTPUT="$(${NVM_DEBUG_COMMAND} 2>&1)" 
				nvm_err "${NVM_DEBUG_COMMAND}: $(nvm_sanitize_path "${NVM_DEBUG_OUTPUT}")"
			done
			return 42 ;;
		("install" | "i") local version_not_provided
			version_not_provided=0 
			local NVM_OS
			NVM_OS="$(nvm_get_os)" 
			if ! nvm_has "curl" && ! nvm_has "wget"
			then
				nvm_err 'nvm needs curl or wget to proceed.'
				return 1
			fi
			if [ $# -lt 1 ]
			then
				version_not_provided=1 
			fi
			local nobinary
			local nosource
			local noprogress
			nobinary=0 
			noprogress=0 
			nosource=0 
			local LTS
			local ALIAS
			local NVM_UPGRADE_NPM
			NVM_UPGRADE_NPM=0 
			local NVM_WRITE_TO_NVMRC
			NVM_WRITE_TO_NVMRC=0 
			local PROVIDED_REINSTALL_PACKAGES_FROM
			local REINSTALL_PACKAGES_FROM
			local SKIP_DEFAULT_PACKAGES
			while [ $# -ne 0 ]
			do
				case "$1" in
					(---*) nvm_err 'arguments with `---` are not supported - this is likely a typo'
						return 55 ;;
					(-s) shift
						nobinary=1 
						if [ $nosource -eq 1 ]
						then
							nvm err '-s and -b cannot be set together since they would skip install from both binary and source'
							return 6
						fi ;;
					(-b) shift
						nosource=1 
						if [ $nobinary -eq 1 ]
						then
							nvm err '-s and -b cannot be set together since they would skip install from both binary and source'
							return 6
						fi ;;
					(-j) shift
						nvm_get_make_jobs "$1"
						shift ;;
					(--no-progress) noprogress=1 
						shift ;;
					(--lts) LTS='*' 
						shift ;;
					(--lts=*) LTS="${1##--lts=}" 
						shift ;;
					(--latest-npm) NVM_UPGRADE_NPM=1 
						shift ;;
					(--default) if [ -n "${ALIAS-}" ]
						then
							nvm_err '--default and --alias are mutually exclusive, and may not be provided more than once'
							return 6
						fi
						ALIAS='default' 
						shift ;;
					(--alias=*) if [ -n "${ALIAS-}" ]
						then
							nvm_err '--default and --alias are mutually exclusive, and may not be provided more than once'
							return 6
						fi
						ALIAS="${1##--alias=}" 
						shift ;;
					(--reinstall-packages-from=*) if [ -n "${PROVIDED_REINSTALL_PACKAGES_FROM-}" ]
						then
							nvm_err '--reinstall-packages-from may not be provided more than once'
							return 6
						fi
						PROVIDED_REINSTALL_PACKAGES_FROM="$(nvm_echo "$1" | command cut -c 27-)" 
						if [ -z "${PROVIDED_REINSTALL_PACKAGES_FROM}" ]
						then
							nvm_err 'If --reinstall-packages-from is provided, it must point to an installed version of node.'
							return 6
						fi
						REINSTALL_PACKAGES_FROM="$(nvm_version "${PROVIDED_REINSTALL_PACKAGES_FROM}")"  || :
						shift ;;
					(--copy-packages-from=*) if [ -n "${PROVIDED_REINSTALL_PACKAGES_FROM-}" ]
						then
							nvm_err '--reinstall-packages-from may not be provided more than once, or combined with `--copy-packages-from`'
							return 6
						fi
						PROVIDED_REINSTALL_PACKAGES_FROM="$(nvm_echo "$1" | command cut -c 22-)" 
						if [ -z "${PROVIDED_REINSTALL_PACKAGES_FROM}" ]
						then
							nvm_err 'If --copy-packages-from is provided, it must point to an installed version of node.'
							return 6
						fi
						REINSTALL_PACKAGES_FROM="$(nvm_version "${PROVIDED_REINSTALL_PACKAGES_FROM}")"  || :
						shift ;;
					(--reinstall-packages-from | --copy-packages-from) nvm_err "If ${1} is provided, it must point to an installed version of node using \`=\`."
						return 6 ;;
					(--skip-default-packages) SKIP_DEFAULT_PACKAGES=true 
						shift ;;
					(--save | -w) if [ $NVM_WRITE_TO_NVMRC -eq 1 ]
						then
							nvm_err '--save and -w may only be provided once'
							return 6
						fi
						NVM_WRITE_TO_NVMRC=1 
						shift ;;
					(*) break ;;
				esac
			done
			local provided_version
			provided_version="${1-}" 
			if [ -z "${provided_version}" ]
			then
				if [ "_${LTS-}" = '_*' ]
				then
					nvm_echo 'Installing latest LTS version.'
					if [ $# -gt 0 ]
					then
						shift
					fi
				elif [ "_${LTS-}" != '_' ]
				then
					nvm_echo "Installing with latest version of LTS line: ${LTS}"
					if [ $# -gt 0 ]
					then
						shift
					fi
				else
					nvm_rc_version
					if [ $version_not_provided -eq 1 ] && [ -z "${NVM_RC_VERSION}" ]
					then
						unset NVM_RC_VERSION
						nvm --help >&2
						return 127
					fi
					provided_version="${NVM_RC_VERSION}" 
					unset NVM_RC_VERSION
				fi
			elif [ $# -gt 0 ]
			then
				shift
			fi
			case "${provided_version}" in
				('lts/*') LTS='*' 
					provided_version=''  ;;
				(lts/*) LTS="${provided_version##lts/}" 
					provided_version=''  ;;
			esac
			local EXIT_CODE
			VERSION="$(NVM_VERSION_ONLY=true NVM_LTS="${LTS-}" nvm_remote_version "${provided_version}")" 
			EXIT_CODE="$?" 
			if [ "${VERSION}" = 'N/A' ] || [ $EXIT_CODE -ne 0 ]
			then
				local LTS_MSG
				local REMOTE_CMD
				if [ "${LTS-}" = '*' ]
				then
					LTS_MSG='(with LTS filter) ' 
					REMOTE_CMD='nvm ls-remote --lts' 
				elif [ -n "${LTS-}" ]
				then
					LTS_MSG="(with LTS filter '${LTS}') " 
					REMOTE_CMD="nvm ls-remote --lts=${LTS}" 
					if [ -z "${provided_version}" ]
					then
						nvm_err "Version with LTS filter '${LTS}' not found - try \`${REMOTE_CMD}\` to browse available versions."
						return 3
					fi
				else
					REMOTE_CMD='nvm ls-remote' 
				fi
				nvm_err "Version '${provided_version}' ${LTS_MSG-}not found - try \`${REMOTE_CMD}\` to browse available versions."
				return 3
			fi
			ADDITIONAL_PARAMETERS='' 
			while [ $# -ne 0 ]
			do
				case "$1" in
					(--reinstall-packages-from=*) if [ -n "${PROVIDED_REINSTALL_PACKAGES_FROM-}" ]
						then
							nvm_err '--reinstall-packages-from may not be provided more than once'
							return 6
						fi
						PROVIDED_REINSTALL_PACKAGES_FROM="$(nvm_echo "$1" | command cut -c 27-)" 
						if [ -z "${PROVIDED_REINSTALL_PACKAGES_FROM}" ]
						then
							nvm_err 'If --reinstall-packages-from is provided, it must point to an installed version of node.'
							return 6
						fi
						REINSTALL_PACKAGES_FROM="$(nvm_version "${PROVIDED_REINSTALL_PACKAGES_FROM}")"  || : ;;
					(--copy-packages-from=*) if [ -n "${PROVIDED_REINSTALL_PACKAGES_FROM-}" ]
						then
							nvm_err '--reinstall-packages-from may not be provided more than once, or combined with `--copy-packages-from`'
							return 6
						fi
						PROVIDED_REINSTALL_PACKAGES_FROM="$(nvm_echo "$1" | command cut -c 22-)" 
						if [ -z "${PROVIDED_REINSTALL_PACKAGES_FROM}" ]
						then
							nvm_err 'If --copy-packages-from is provided, it must point to an installed version of node.'
							return 6
						fi
						REINSTALL_PACKAGES_FROM="$(nvm_version "${PROVIDED_REINSTALL_PACKAGES_FROM}")"  || : ;;
					(--reinstall-packages-from | --copy-packages-from) nvm_err "If ${1} is provided, it must point to an installed version of node using \`=\`."
						return 6 ;;
					(--skip-default-packages) SKIP_DEFAULT_PACKAGES=true  ;;
					(*) ADDITIONAL_PARAMETERS="${ADDITIONAL_PARAMETERS} $1"  ;;
				esac
				shift
			done
			if [ -n "${PROVIDED_REINSTALL_PACKAGES_FROM-}" ] && [ "$(nvm_ensure_version_prefix "${PROVIDED_REINSTALL_PACKAGES_FROM}")" = "${VERSION}" ]
			then
				nvm_err "You can't reinstall global packages from the same version of node you're installing."
				return 4
			elif [ "${REINSTALL_PACKAGES_FROM-}" = 'N/A' ]
			then
				nvm_err "If --reinstall-packages-from is provided, it must point to an installed version of node."
				return 5
			fi
			local FLAVOR
			if nvm_is_iojs_version "${VERSION}"
			then
				FLAVOR="$(nvm_iojs_prefix)" 
			else
				FLAVOR="$(nvm_node_prefix)" 
			fi
			EXIT_CODE=0 
			if nvm_is_version_installed "${VERSION}"
			then
				nvm_err "${VERSION} is already installed."
				nvm use "${VERSION}"
				EXIT_CODE=$? 
				if [ $EXIT_CODE -eq 0 ]
				then
					if [ "${NVM_UPGRADE_NPM}" = 1 ]
					then
						nvm install-latest-npm
						EXIT_CODE=$? 
					fi
					if [ $EXIT_CODE -ne 0 ] && [ -z "${SKIP_DEFAULT_PACKAGES-}" ]
					then
						nvm_install_default_packages
					fi
					if [ $EXIT_CODE -ne 0 ] && [ -n "${REINSTALL_PACKAGES_FROM-}" ] && [ "_${REINSTALL_PACKAGES_FROM}" != "_N/A" ]
					then
						nvm reinstall-packages "${REINSTALL_PACKAGES_FROM}"
						EXIT_CODE=$? 
					fi
				fi
				if [ -n "${LTS-}" ]
				then
					LTS="$(echo "${LTS}" | tr '[:upper:]' '[:lower:]')" 
					nvm_ensure_default_set "lts/${LTS}"
				else
					nvm_ensure_default_set "${provided_version}"
				fi
				if [ $NVM_WRITE_TO_NVMRC -eq 1 ]
				then
					nvm_write_nvmrc "${VERSION}"
					EXIT_CODE=$? 
				fi
				if [ $EXIT_CODE -ne 0 ] && [ -n "${ALIAS-}" ]
				then
					nvm alias "${ALIAS}" "${provided_version}"
					EXIT_CODE=$? 
				fi
				return $EXIT_CODE
			fi
			if [ -n "${NVM_INSTALL_THIRD_PARTY_HOOK-}" ]
			then
				nvm_err '** $NVM_INSTALL_THIRD_PARTY_HOOK env var set; dispatching to third-party installation method **'
				local NVM_METHOD_PREFERENCE
				NVM_METHOD_PREFERENCE='binary' 
				if [ $nobinary -eq 1 ]
				then
					NVM_METHOD_PREFERENCE='source' 
				fi
				local VERSION_PATH
				VERSION_PATH="$(nvm_version_path "${VERSION}")" 
				"${NVM_INSTALL_THIRD_PARTY_HOOK}" "${VERSION}" "${FLAVOR}" std "${NVM_METHOD_PREFERENCE}" "${VERSION_PATH}" || {
					EXIT_CODE=$? 
					nvm_err '*** Third-party $NVM_INSTALL_THIRD_PARTY_HOOK env var failed to install! ***'
					return $EXIT_CODE
				}
				if ! nvm_is_version_installed "${VERSION}"
				then
					nvm_err '*** Third-party $NVM_INSTALL_THIRD_PARTY_HOOK env var claimed to succeed, but failed to install! ***'
					return 33
				fi
				EXIT_CODE=0 
			else
				if [ "_${NVM_OS}" = "_freebsd" ]
				then
					nobinary=1 
					nvm_err "Currently, there is no binary for FreeBSD"
				elif [ "_$NVM_OS" = "_openbsd" ]
				then
					nobinary=1 
					nvm_err "Currently, there is no binary for OpenBSD"
				elif [ "_${NVM_OS}" = "_sunos" ]
				then
					if ! nvm_has_solaris_binary "${VERSION}"
					then
						nobinary=1 
						nvm_err "Currently, there is no binary of version ${VERSION} for SunOS"
					fi
				fi
				if [ $nobinary -ne 1 ] && nvm_binary_available "${VERSION}"
				then
					NVM_NO_PROGRESS="${NVM_NO_PROGRESS:-${noprogress}}" nvm_install_binary "${FLAVOR}" std "${VERSION}" "${nosource}"
					EXIT_CODE=$? 
				else
					EXIT_CODE=-1 
					if [ $nosource -eq 1 ]
					then
						nvm_err "Binary download is not available for ${VERSION}"
						EXIT_CODE=3 
					fi
				fi
				if [ $EXIT_CODE -ne 0 ] && [ $nosource -ne 1 ]
				then
					if [ -z "${NVM_MAKE_JOBS-}" ]
					then
						nvm_get_make_jobs
					fi
					if [ "_${NVM_OS}" = "_win" ]
					then
						nvm_err 'Installing from source on non-WSL Windows is not supported'
						EXIT_CODE=87 
					else
						NVM_NO_PROGRESS="${NVM_NO_PROGRESS:-${noprogress}}" nvm_install_source "${FLAVOR}" std "${VERSION}" "${NVM_MAKE_JOBS}" "${ADDITIONAL_PARAMETERS}"
						EXIT_CODE=$? 
					fi
				fi
			fi
			if [ $EXIT_CODE -eq 0 ]
			then
				if nvm_use_if_needed "${VERSION}" && nvm_install_npm_if_needed "${VERSION}"
				then
					if [ -n "${LTS-}" ]
					then
						nvm_ensure_default_set "lts/${LTS}"
					else
						nvm_ensure_default_set "${provided_version}"
					fi
					if [ "${NVM_UPGRADE_NPM}" = 1 ]
					then
						nvm install-latest-npm
						EXIT_CODE=$? 
					fi
					if [ $EXIT_CODE -eq 0 ] && [ -z "${SKIP_DEFAULT_PACKAGES-}" ]
					then
						nvm_install_default_packages
					fi
					if [ $EXIT_CODE -eq 0 ] && [ -n "${REINSTALL_PACKAGES_FROM-}" ] && [ "_${REINSTALL_PACKAGES_FROM}" != "_N/A" ]
					then
						nvm reinstall-packages "${REINSTALL_PACKAGES_FROM}"
						EXIT_CODE=$? 
					fi
				else
					EXIT_CODE=$? 
				fi
			fi
			return $EXIT_CODE ;;
		("uninstall") if [ $# -ne 1 ]
			then
				nvm --help >&2
				return 127
			fi
			local PATTERN
			PATTERN="${1-}" 
			case "${PATTERN-}" in
				(--)  ;;
				(--lts | 'lts/*') VERSION="$(nvm_match_version "lts/*")"  ;;
				(lts/*) VERSION="$(nvm_match_version "lts/${PATTERN##lts/}")"  ;;
				(--lts=*) VERSION="$(nvm_match_version "lts/${PATTERN##--lts=}")"  ;;
				(*) VERSION="$(nvm_version "${PATTERN}")"  ;;
			esac
			if [ "_${VERSION}" = "_$(nvm_ls_current)" ]
			then
				if nvm_is_iojs_version "${VERSION}"
				then
					nvm_err "nvm: Cannot uninstall currently-active io.js version, ${VERSION} (inferred from ${PATTERN})."
				else
					nvm_err "nvm: Cannot uninstall currently-active node version, ${VERSION} (inferred from ${PATTERN})."
				fi
				return 1
			fi
			if ! nvm_is_version_installed "${VERSION}"
			then
				nvm_err "${VERSION} version is not installed..."
				return
			fi
			local SLUG_BINARY
			local SLUG_SOURCE
			if nvm_is_iojs_version "${VERSION}"
			then
				SLUG_BINARY="$(nvm_get_download_slug iojs binary std "${VERSION}")" 
				SLUG_SOURCE="$(nvm_get_download_slug iojs source std "${VERSION}")" 
			else
				SLUG_BINARY="$(nvm_get_download_slug node binary std "${VERSION}")" 
				SLUG_SOURCE="$(nvm_get_download_slug node source std "${VERSION}")" 
			fi
			local NVM_SUCCESS_MSG
			if nvm_is_iojs_version "${VERSION}"
			then
				NVM_SUCCESS_MSG="Uninstalled io.js $(nvm_strip_iojs_prefix "${VERSION}")" 
			else
				NVM_SUCCESS_MSG="Uninstalled node ${VERSION}" 
			fi
			local VERSION_PATH
			VERSION_PATH="$(nvm_version_path "${VERSION}")" 
			if ! nvm_check_file_permissions "${VERSION_PATH}"
			then
				nvm_err 'Cannot uninstall, incorrect permissions on installation folder.'
				nvm_err 'This is usually caused by running `npm install -g` as root. Run the following commands as root to fix the permissions and then try again.'
				nvm_err
				nvm_err "  chown -R $(whoami) \"$(nvm_sanitize_path "${VERSION_PATH}")\""
				nvm_err "  chmod -R u+w \"$(nvm_sanitize_path "${VERSION_PATH}")\""
				return 1
			fi
			local CACHE_DIR
			CACHE_DIR="$(nvm_cache_dir)" 
			command rm -rf "${CACHE_DIR}/bin/${SLUG_BINARY}/files" "${CACHE_DIR}/src/${SLUG_SOURCE}/files" "${VERSION_PATH}" 2> /dev/null
			nvm_echo "${NVM_SUCCESS_MSG}"
			for ALIAS in $(nvm_grep -l "${VERSION}" "$(nvm_alias_path)/*" 2>/dev/null)
			do
				nvm unalias "$(command basename "${ALIAS}")"
			done ;;
		("deactivate") local NVM_SILENT
			while [ $# -ne 0 ]
			do
				case "${1}" in
					(--silent) NVM_SILENT=1  ;;
					(--)  ;;
				esac
				shift
			done
			local NEWPATH
			NEWPATH="$(nvm_strip_path "${PATH}" "/bin")" 
			if [ "_${PATH}" = "_${NEWPATH}" ]
			then
				if [ "${NVM_SILENT:-0}" -ne 1 ]
				then
					nvm_err "Could not find ${NVM_DIR}/*/bin in \${PATH}"
				fi
			else
				export PATH="${NEWPATH}" 
				\hash -r
				if [ "${NVM_SILENT:-0}" -ne 1 ]
				then
					nvm_echo "${NVM_DIR}/*/bin removed from \${PATH}"
				fi
			fi
			if [ -n "${MANPATH-}" ]
			then
				NEWPATH="$(nvm_strip_path "${MANPATH}" "/share/man")" 
				if [ "_${MANPATH}" = "_${NEWPATH}" ]
				then
					if [ "${NVM_SILENT:-0}" -ne 1 ]
					then
						nvm_err "Could not find ${NVM_DIR}/*/share/man in \${MANPATH}"
					fi
				else
					export MANPATH="${NEWPATH}" 
					if [ "${NVM_SILENT:-0}" -ne 1 ]
					then
						nvm_echo "${NVM_DIR}/*/share/man removed from \${MANPATH}"
					fi
				fi
			fi
			if [ -n "${NODE_PATH-}" ]
			then
				NEWPATH="$(nvm_strip_path "${NODE_PATH}" "/lib/node_modules")" 
				if [ "_${NODE_PATH}" != "_${NEWPATH}" ]
				then
					export NODE_PATH="${NEWPATH}" 
					if [ "${NVM_SILENT:-0}" -ne 1 ]
					then
						nvm_echo "${NVM_DIR}/*/lib/node_modules removed from \${NODE_PATH}"
					fi
				fi
			fi
			unset NVM_BIN
			unset NVM_INC ;;
		("use") local PROVIDED_VERSION
			local NVM_SILENT
			local NVM_SILENT_ARG
			local NVM_DELETE_PREFIX
			NVM_DELETE_PREFIX=0 
			local NVM_LTS
			local IS_VERSION_FROM_NVMRC
			IS_VERSION_FROM_NVMRC=0 
			local NVM_WRITE_TO_NVMRC
			NVM_WRITE_TO_NVMRC=0 
			while [ $# -ne 0 ]
			do
				case "$1" in
					(--silent) NVM_SILENT=1 
						NVM_SILENT_ARG='--silent'  ;;
					(--delete-prefix) NVM_DELETE_PREFIX=1  ;;
					(--)  ;;
					(--lts) NVM_LTS='*'  ;;
					(--lts=*) NVM_LTS="${1##--lts=}"  ;;
					(--save | -w) if [ $NVM_WRITE_TO_NVMRC -eq 1 ]
						then
							nvm_err '--save and -w may only be provided once'
							return 6
						fi
						NVM_WRITE_TO_NVMRC=1  ;;
					(--*)  ;;
					(*) if [ -n "${1-}" ]
						then
							PROVIDED_VERSION="$1" 
						fi ;;
				esac
				shift
			done
			if [ -n "${NVM_LTS-}" ]
			then
				VERSION="$(nvm_match_version "lts/${NVM_LTS:-*}")" 
			elif [ -z "${PROVIDED_VERSION-}" ]
			then
				NVM_SILENT="${NVM_SILENT:-0}" nvm_rc_version
				if [ -n "${NVM_RC_VERSION-}" ]
				then
					PROVIDED_VERSION="${NVM_RC_VERSION}" 
					IS_VERSION_FROM_NVMRC=1 
					VERSION="$(nvm_version "${PROVIDED_VERSION}")" 
				fi
				unset NVM_RC_VERSION
				if [ -z "${VERSION}" ]
				then
					nvm_err 'Please see `nvm --help` or https://github.com/nvm-sh/nvm#nvmrc for more information.'
					return 127
				fi
			else
				VERSION="$(nvm_match_version "${PROVIDED_VERSION}")" 
			fi
			if [ -z "${VERSION}" ]
			then
				nvm --help >&2
				return 127
			fi
			if [ $NVM_WRITE_TO_NVMRC -eq 1 ]
			then
				nvm_write_nvmrc "${VERSION}"
			fi
			if [ "_${VERSION}" = '_system' ]
			then
				if nvm_has_system_node && nvm deactivate "${NVM_SILENT_ARG-}" > /dev/null 2>&1
				then
					if [ "${NVM_SILENT:-0}" -ne 1 ]
					then
						nvm_echo "Now using system version of node: $(node -v 2>/dev/null)$(nvm_print_npm_version)"
					fi
					return
				elif nvm_has_system_iojs && nvm deactivate "${NVM_SILENT_ARG-}" > /dev/null 2>&1
				then
					if [ "${NVM_SILENT:-0}" -ne 1 ]
					then
						nvm_echo "Now using system version of io.js: $(iojs --version 2>/dev/null)$(nvm_print_npm_version)"
					fi
					return
				elif [ "${NVM_SILENT:-0}" -ne 1 ]
				then
					nvm_err 'System version of node not found.'
				fi
				return 127
			elif [ "_${VERSION}" = '_∞' ]
			then
				if [ "${NVM_SILENT:-0}" -ne 1 ]
				then
					nvm_err "The alias \"${PROVIDED_VERSION}\" leads to an infinite loop. Aborting."
				fi
				return 8
			fi
			if [ "${VERSION}" = 'N/A' ]
			then
				if [ "${NVM_SILENT:-0}" -ne 1 ]
				then
					nvm_ensure_version_installed "${PROVIDED_VERSION}" "${IS_VERSION_FROM_NVMRC}"
				fi
				return 3
			elif ! nvm_ensure_version_installed "${VERSION}" "${IS_VERSION_FROM_NVMRC}"
			then
				return $?
			fi
			local NVM_VERSION_DIR
			NVM_VERSION_DIR="$(nvm_version_path "${VERSION}")" 
			PATH="$(nvm_change_path "${PATH}" "/bin" "${NVM_VERSION_DIR}")" 
			if nvm_has manpath
			then
				if [ -z "${MANPATH-}" ]
				then
					local MANPATH
					MANPATH=$(manpath) 
				fi
				MANPATH="$(nvm_change_path "${MANPATH}" "/share/man" "${NVM_VERSION_DIR}")" 
				export MANPATH
			fi
			export PATH
			\hash -r
			export NVM_BIN="${NVM_VERSION_DIR}/bin" 
			export NVM_INC="${NVM_VERSION_DIR}/include/node" 
			if [ "${NVM_SYMLINK_CURRENT-}" = true ]
			then
				command rm -f "${NVM_DIR}/current" && ln -s "${NVM_VERSION_DIR}" "${NVM_DIR}/current"
			fi
			local NVM_USE_OUTPUT
			NVM_USE_OUTPUT='' 
			if [ "${NVM_SILENT:-0}" -ne 1 ]
			then
				if nvm_is_iojs_version "${VERSION}"
				then
					NVM_USE_OUTPUT="Now using io.js $(nvm_strip_iojs_prefix "${VERSION}")$(nvm_print_npm_version)" 
				else
					NVM_USE_OUTPUT="Now using node ${VERSION}$(nvm_print_npm_version)" 
				fi
			fi
			if [ "_${VERSION}" != "_system" ]
			then
				local NVM_USE_CMD
				NVM_USE_CMD="nvm use --delete-prefix" 
				if [ -n "${PROVIDED_VERSION}" ]
				then
					NVM_USE_CMD="${NVM_USE_CMD} ${VERSION}" 
				fi
				if [ "${NVM_SILENT:-0}" -eq 1 ]
				then
					NVM_USE_CMD="${NVM_USE_CMD} --silent" 
				fi
				if ! nvm_die_on_prefix "${NVM_DELETE_PREFIX}" "${NVM_USE_CMD}" "${NVM_VERSION_DIR}"
				then
					return 11
				fi
			fi
			if [ -n "${NVM_USE_OUTPUT-}" ] && [ "${NVM_SILENT:-0}" -ne 1 ]
			then
				nvm_echo "${NVM_USE_OUTPUT}"
			fi ;;
		("run") local provided_version
			local has_checked_nvmrc
			has_checked_nvmrc=0 
			local IS_VERSION_FROM_NVMRC
			IS_VERSION_FROM_NVMRC=0 
			local NVM_SILENT
			local NVM_SILENT_ARG
			local NVM_LTS
			while [ $# -gt 0 ]
			do
				case "$1" in
					(--silent) NVM_SILENT=1 
						NVM_SILENT_ARG='--silent' 
						shift ;;
					(--lts) NVM_LTS='*' 
						shift ;;
					(--lts=*) NVM_LTS="${1##--lts=}" 
						shift ;;
					(*) if [ -n "$1" ]
						then
							break
						else
							shift
						fi ;;
				esac
			done
			if [ $# -lt 1 ] && [ -z "${NVM_LTS-}" ]
			then
				NVM_SILENT="${NVM_SILENT:-0}" nvm_rc_version && has_checked_nvmrc=1 
				if [ -n "${NVM_RC_VERSION-}" ]
				then
					VERSION="$(nvm_version "${NVM_RC_VERSION-}")"  || :
				fi
				unset NVM_RC_VERSION
				if [ "${VERSION:-N/A}" = 'N/A' ]
				then
					nvm --help >&2
					return 127
				fi
			fi
			if [ -z "${NVM_LTS-}" ]
			then
				provided_version="$1" 
				if [ -n "${provided_version}" ]
				then
					VERSION="$(nvm_version "${provided_version}")"  || :
					if [ "_${VERSION:-N/A}" = '_N/A' ] && ! nvm_is_valid_version "${provided_version}"
					then
						provided_version='' 
						if [ $has_checked_nvmrc -ne 1 ]
						then
							NVM_SILENT="${NVM_SILENT:-0}" nvm_rc_version && has_checked_nvmrc=1 
						fi
						provided_version="${NVM_RC_VERSION}" 
						IS_VERSION_FROM_NVMRC=1 
						VERSION="$(nvm_version "${NVM_RC_VERSION}")"  || :
						unset NVM_RC_VERSION
					else
						shift
					fi
				fi
			fi
			local NVM_IOJS
			if nvm_is_iojs_version "${VERSION}"
			then
				NVM_IOJS=true 
			fi
			local EXIT_CODE
			nvm_is_zsh && setopt local_options shwordsplit
			local LTS_ARG
			if [ -n "${NVM_LTS-}" ]
			then
				LTS_ARG="--lts=${NVM_LTS-}" 
				VERSION='' 
			fi
			if [ "_${VERSION}" = "_N/A" ]
			then
				nvm_ensure_version_installed "${provided_version}" "${IS_VERSION_FROM_NVMRC}"
			elif [ "${NVM_IOJS}" = true ]
			then
				nvm exec "${NVM_SILENT_ARG-}" "${LTS_ARG-}" "${VERSION}" iojs "$@"
			else
				nvm exec "${NVM_SILENT_ARG-}" "${LTS_ARG-}" "${VERSION}" node "$@"
			fi
			EXIT_CODE="$?" 
			return $EXIT_CODE ;;
		("exec") local NVM_SILENT
			local NVM_LTS
			while [ $# -gt 0 ]
			do
				case "$1" in
					(--silent) NVM_SILENT=1 
						shift ;;
					(--lts) NVM_LTS='*' 
						shift ;;
					(--lts=*) NVM_LTS="${1##--lts=}" 
						shift ;;
					(--) break ;;
					(--*) nvm_err "Unsupported option \"$1\"."
						return 55 ;;
					(*) if [ -n "$1" ]
						then
							break
						else
							shift
						fi ;;
				esac
			done
			local provided_version
			provided_version="$1" 
			if [ "${NVM_LTS-}" != '' ]
			then
				provided_version="lts/${NVM_LTS:-*}" 
				VERSION="${provided_version}" 
			elif [ -n "${provided_version}" ]
			then
				VERSION="$(nvm_version "${provided_version}")"  || :
				if [ "_${VERSION}" = '_N/A' ] && ! nvm_is_valid_version "${provided_version}"
				then
					NVM_SILENT="${NVM_SILENT:-0}" nvm_rc_version && has_checked_nvmrc=1 
					provided_version="${NVM_RC_VERSION}" 
					unset NVM_RC_VERSION
					VERSION="$(nvm_version "${provided_version}")"  || :
				else
					shift
				fi
			fi
			nvm_ensure_version_installed "${provided_version}"
			EXIT_CODE=$? 
			if [ "${EXIT_CODE}" != "0" ]
			then
				return $EXIT_CODE
			fi
			if [ "${NVM_SILENT:-0}" -ne 1 ]
			then
				if [ "${NVM_LTS-}" = '*' ]
				then
					nvm_echo "Running node latest LTS -> $(nvm_version "${VERSION}")$(nvm use --silent "${VERSION}" && nvm_print_npm_version)"
				elif [ -n "${NVM_LTS-}" ]
				then
					nvm_echo "Running node LTS \"${NVM_LTS-}\" -> $(nvm_version "${VERSION}")$(nvm use --silent "${VERSION}" && nvm_print_npm_version)"
				elif nvm_is_iojs_version "${VERSION}"
				then
					nvm_echo "Running io.js $(nvm_strip_iojs_prefix "${VERSION}")$(nvm use --silent "${VERSION}" && nvm_print_npm_version)"
				else
					nvm_echo "Running node ${VERSION}$(nvm use --silent "${VERSION}" && nvm_print_npm_version)"
				fi
			fi
			NODE_VERSION="${VERSION}" "${NVM_DIR}/nvm-exec" "$@" ;;
		("ls" | "list") local PATTERN
			local NVM_NO_COLORS
			local NVM_NO_ALIAS
			while [ $# -gt 0 ]
			do
				case "${1}" in
					(--)  ;;
					(--no-colors) NVM_NO_COLORS="${1}"  ;;
					(--no-alias) NVM_NO_ALIAS="${1}"  ;;
					(--*) nvm_err "Unsupported option \"${1}\"."
						return 55 ;;
					(*) PATTERN="${PATTERN:-$1}"  ;;
				esac
				shift
			done
			if [ -n "${PATTERN-}" ] && [ -n "${NVM_NO_ALIAS-}" ]
			then
				nvm_err '`--no-alias` is not supported when a pattern is provided.'
				return 55
			fi
			local NVM_LS_OUTPUT
			local NVM_LS_EXIT_CODE
			NVM_LS_OUTPUT=$(nvm_ls "${PATTERN-}") 
			NVM_LS_EXIT_CODE=$? 
			NVM_NO_COLORS="${NVM_NO_COLORS-}" nvm_print_versions "${NVM_LS_OUTPUT}"
			if [ -z "${NVM_NO_ALIAS-}" ] && [ -z "${PATTERN-}" ]
			then
				if [ -n "${NVM_NO_COLORS-}" ]
				then
					nvm alias --no-colors
				else
					nvm alias
				fi
			fi
			return $NVM_LS_EXIT_CODE ;;
		("ls-remote" | "list-remote") local NVM_LTS
			local PATTERN
			local NVM_NO_COLORS
			while [ $# -gt 0 ]
			do
				case "${1-}" in
					(--)  ;;
					(--lts) NVM_LTS='*'  ;;
					(--lts=*) NVM_LTS="${1##--lts=}"  ;;
					(--no-colors) NVM_NO_COLORS="${1}"  ;;
					(--*) nvm_err "Unsupported option \"${1}\"."
						return 55 ;;
					(*) if [ -z "${PATTERN-}" ]
						then
							PATTERN="${1-}" 
							if [ -z "${NVM_LTS-}" ]
							then
								case "${PATTERN}" in
									('lts/*') NVM_LTS='*' 
										PATTERN=''  ;;
									(lts/*) NVM_LTS="${PATTERN##lts/}" 
										PATTERN=''  ;;
								esac
							fi
						fi ;;
				esac
				shift
			done
			local NVM_OUTPUT
			local EXIT_CODE
			NVM_OUTPUT="$(NVM_LTS="${NVM_LTS-}" nvm_remote_versions "${PATTERN}" &&:)" 
			EXIT_CODE=$? 
			if [ -n "${NVM_OUTPUT}" ]
			then
				NVM_NO_COLORS="${NVM_NO_COLORS-}" nvm_print_versions "${NVM_OUTPUT}"
				return $EXIT_CODE
			fi
			NVM_NO_COLORS="${NVM_NO_COLORS-}" nvm_print_versions "N/A"
			return 3 ;;
		("current") nvm_version current ;;
		("which") local NVM_SILENT
			local provided_version
			while [ $# -ne 0 ]
			do
				case "${1}" in
					(--silent) NVM_SILENT=1  ;;
					(--)  ;;
					(*) provided_version="${1-}"  ;;
				esac
				shift
			done
			if [ -z "${provided_version-}" ]
			then
				NVM_SILENT="${NVM_SILENT:-0}" nvm_rc_version
				if [ -n "${NVM_RC_VERSION}" ]
				then
					provided_version="${NVM_RC_VERSION}" 
					VERSION=$(nvm_version "${NVM_RC_VERSION}")  || :
				fi
				unset NVM_RC_VERSION
			elif [ "${provided_version}" != 'system' ]
			then
				VERSION="$(nvm_version "${provided_version}")"  || :
			else
				VERSION="${provided_version-}" 
			fi
			if [ -z "${VERSION}" ]
			then
				nvm --help >&2
				return 127
			fi
			if [ "_${VERSION}" = '_system' ]
			then
				if nvm_has_system_iojs > /dev/null 2>&1 || nvm_has_system_node > /dev/null 2>&1
				then
					local NVM_BIN
					NVM_BIN="$(nvm use system >/dev/null 2>&1 && command which node)" 
					if [ -n "${NVM_BIN}" ]
					then
						nvm_echo "${NVM_BIN}"
						return
					fi
					return 1
				fi
				nvm_err 'System version of node not found.'
				return 127
			elif [ "${VERSION}" = '∞' ]
			then
				nvm_err "The alias \"${2}\" leads to an infinite loop. Aborting."
				return 8
			fi
			nvm_ensure_version_installed "${provided_version}"
			EXIT_CODE=$? 
			if [ "${EXIT_CODE}" != "0" ]
			then
				return $EXIT_CODE
			fi
			local NVM_VERSION_DIR
			NVM_VERSION_DIR="$(nvm_version_path "${VERSION}")" 
			nvm_echo "${NVM_VERSION_DIR}/bin/node" ;;
		("alias") local NVM_ALIAS_DIR
			NVM_ALIAS_DIR="$(nvm_alias_path)" 
			local NVM_CURRENT
			NVM_CURRENT="$(nvm_ls_current)" 
			command mkdir -p "${NVM_ALIAS_DIR}/lts"
			local ALIAS
			local TARGET
			local NVM_NO_COLORS
			ALIAS='--' 
			TARGET='--' 
			while [ $# -gt 0 ]
			do
				case "${1-}" in
					(--)  ;;
					(--no-colors) NVM_NO_COLORS="${1}"  ;;
					(--*) nvm_err "Unsupported option \"${1}\"."
						return 55 ;;
					(*) if [ "${ALIAS}" = '--' ]
						then
							ALIAS="${1-}" 
						elif [ "${TARGET}" = '--' ]
						then
							TARGET="${1-}" 
						fi ;;
				esac
				shift
			done
			if [ -z "${TARGET}" ]
			then
				nvm unalias "${ALIAS}"
				return $?
			elif echo "${ALIAS}" | grep -q "#"
			then
				nvm_err 'Aliases with a comment delimiter (#) are not supported.'
				return 1
			elif [ "${TARGET}" != '--' ]
			then
				if [ "${ALIAS#*\/}" != "${ALIAS}" ]
				then
					nvm_err 'Aliases in subdirectories are not supported.'
					return 1
				fi
				VERSION="$(nvm_version "${TARGET}")"  || :
				if [ "${VERSION}" = 'N/A' ]
				then
					nvm_err "! WARNING: Version '${TARGET}' does not exist."
				fi
				nvm_make_alias "${ALIAS}" "${TARGET}"
				NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_CURRENT="${NVM_CURRENT-}" DEFAULT=false nvm_print_formatted_alias "${ALIAS}" "${TARGET}" "${VERSION}"
			else
				if [ "${ALIAS-}" = '--' ]
				then
					unset ALIAS
				fi
				nvm_list_aliases "${ALIAS-}"
			fi ;;
		("unalias") local NVM_ALIAS_DIR
			NVM_ALIAS_DIR="$(nvm_alias_path)" 
			command mkdir -p "${NVM_ALIAS_DIR}"
			if [ $# -ne 1 ]
			then
				nvm --help >&2
				return 127
			fi
			if [ "${1#*\/}" != "${1-}" ]
			then
				nvm_err 'Aliases in subdirectories are not supported.'
				return 1
			fi
			local NVM_IOJS_PREFIX
			local NVM_NODE_PREFIX
			NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
			NVM_NODE_PREFIX="$(nvm_node_prefix)" 
			local NVM_ALIAS_EXISTS
			NVM_ALIAS_EXISTS=0 
			if [ -f "${NVM_ALIAS_DIR}/${1-}" ]
			then
				NVM_ALIAS_EXISTS=1 
			fi
			if [ $NVM_ALIAS_EXISTS -eq 0 ]
			then
				case "$1" in
					("stable" | "unstable" | "${NVM_IOJS_PREFIX}" | "${NVM_NODE_PREFIX}" | "system") nvm_err "${1-} is a default (built-in) alias and cannot be deleted."
						return 1 ;;
				esac
				nvm_err "Alias ${1-} doesn't exist!"
				return
			fi
			local NVM_ALIAS_ORIGINAL
			NVM_ALIAS_ORIGINAL="$(nvm_alias "${1}")" 
			command rm -f "${NVM_ALIAS_DIR}/${1}"
			nvm_echo "Deleted alias ${1} - restore it with \`nvm alias \"${1}\" \"${NVM_ALIAS_ORIGINAL}\"\`" ;;
		("install-latest-npm") if [ $# -ne 0 ]
			then
				nvm --help >&2
				return 127
			fi
			nvm_install_latest_npm ;;
		("reinstall-packages" | "copy-packages") if [ $# -ne 1 ]
			then
				nvm --help >&2
				return 127
			fi
			local PROVIDED_VERSION
			PROVIDED_VERSION="${1-}" 
			if [ "${PROVIDED_VERSION}" = "$(nvm_ls_current)" ] || [ "$(nvm_version "${PROVIDED_VERSION}" ||:)" = "$(nvm_ls_current)" ]
			then
				nvm_err 'Can not reinstall packages from the current version of node.'
				return 2
			fi
			local VERSION
			if [ "_${PROVIDED_VERSION}" = "_system" ]
			then
				if ! nvm_has_system_node && ! nvm_has_system_iojs
				then
					nvm_err 'No system version of node or io.js detected.'
					return 3
				fi
				VERSION="system" 
			else
				VERSION="$(nvm_version "${PROVIDED_VERSION}")"  || :
			fi
			local NPMLIST
			NPMLIST="$(nvm_npm_global_modules "${VERSION}")" 
			local INSTALLS
			local LINKS
			INSTALLS="${NPMLIST%% //// *}" 
			LINKS="${NPMLIST##* //// }" 
			nvm_echo "Reinstalling global packages from ${VERSION}..."
			if [ -n "${INSTALLS}" ]
			then
				nvm_echo "${INSTALLS}" | command xargs npm install -g --quiet
			else
				nvm_echo "No installed global packages found..."
			fi
			nvm_echo "Linking global packages from ${VERSION}..."
			if [ -n "${LINKS}" ]
			then
				(
					set -f
					IFS='
' 
					for LINK in ${LINKS}
					do
						set +f
						unset IFS
						if [ -n "${LINK}" ]
						then
							case "${LINK}" in
								('/'*) (
										nvm_cd "${LINK}" && npm link
									) ;;
								(*) (
										nvm_cd "$(npm root -g)/../${LINK}" && npm link
									) ;;
							esac
						fi
					done
				)
			else
				nvm_echo "No linked global packages found..."
			fi ;;
		("clear-cache") command rm -f "${NVM_DIR}/v*" "$(nvm_version_dir)" 2> /dev/null
			nvm_echo 'nvm cache cleared.' ;;
		("version") nvm_version "${1}" ;;
		("version-remote") local NVM_LTS
			local PATTERN
			while [ $# -gt 0 ]
			do
				case "${1-}" in
					(--)  ;;
					(--lts) NVM_LTS='*'  ;;
					(--lts=*) NVM_LTS="${1##--lts=}"  ;;
					(--*) nvm_err "Unsupported option \"${1}\"."
						return 55 ;;
					(*) PATTERN="${PATTERN:-${1}}"  ;;
				esac
				shift
			done
			case "${PATTERN-}" in
				('lts/*') NVM_LTS='*' 
					unset PATTERN ;;
				(lts/*) NVM_LTS="${PATTERN##lts/}" 
					unset PATTERN ;;
			esac
			NVM_VERSION_ONLY=true NVM_LTS="${NVM_LTS-}" nvm_remote_version "${PATTERN:-node}" ;;
		("--version" | "-v") nvm_echo '0.40.3' ;;
		("unload") nvm deactivate > /dev/null 2>&1
			unset -f nvm nvm_iojs_prefix nvm_node_prefix nvm_add_iojs_prefix nvm_strip_iojs_prefix nvm_is_iojs_version nvm_is_alias nvm_has_non_aliased nvm_ls_remote nvm_ls_remote_iojs nvm_ls_remote_index_tab nvm_ls nvm_remote_version nvm_remote_versions nvm_install_binary nvm_install_source nvm_clang_version nvm_get_mirror nvm_get_download_slug nvm_download_artifact nvm_install_npm_if_needed nvm_use_if_needed nvm_check_file_permissions nvm_print_versions nvm_compute_checksum nvm_get_checksum_binary nvm_get_checksum_alg nvm_get_checksum nvm_compare_checksum nvm_version nvm_rc_version nvm_match_version nvm_ensure_default_set nvm_get_arch nvm_get_os nvm_print_implicit_alias nvm_validate_implicit_alias nvm_resolve_alias nvm_ls_current nvm_alias nvm_binary_available nvm_change_path nvm_strip_path nvm_num_version_groups nvm_format_version nvm_ensure_version_prefix nvm_normalize_version nvm_is_valid_version nvm_normalize_lts nvm_ensure_version_installed nvm_cache_dir nvm_version_path nvm_alias_path nvm_version_dir nvm_find_nvmrc nvm_find_up nvm_find_project_dir nvm_tree_contains_path nvm_version_greater nvm_version_greater_than_or_equal_to nvm_print_npm_version nvm_install_latest_npm nvm_npm_global_modules nvm_has_system_node nvm_has_system_iojs nvm_download nvm_get_latest nvm_has nvm_install_default_packages nvm_get_default_packages nvm_curl_use_compression nvm_curl_version nvm_auto nvm_supports_xz nvm_echo nvm_err nvm_grep nvm_cd nvm_die_on_prefix nvm_get_make_jobs nvm_get_minor_version nvm_has_solaris_binary nvm_is_merged_node_version nvm_is_natural_num nvm_is_version_installed nvm_list_aliases nvm_make_alias nvm_print_alias_path nvm_print_default_alias nvm_print_formatted_alias nvm_resolve_local_alias nvm_sanitize_path nvm_has_colors nvm_process_parameters nvm_node_version_has_solaris_binary nvm_iojs_version_has_solaris_binary nvm_curl_libz_support nvm_command_info nvm_is_zsh nvm_stdout_is_terminal nvm_npmrc_bad_news_bears nvm_sanitize_auth_header nvm_get_colors nvm_set_colors nvm_print_color_code nvm_wrap_with_color_code nvm_format_help_message_colors nvm_echo_with_colors nvm_err_with_colors nvm_get_artifact_compression nvm_install_binary_extract nvm_extract_tarball nvm_process_nvmrc nvm_nvmrc_invalid_msg nvm_write_nvmrc > /dev/null 2>&1
			unset NVM_RC_VERSION NVM_NODEJS_ORG_MIRROR NVM_IOJS_ORG_MIRROR NVM_DIR NVM_CD_FLAGS NVM_BIN NVM_INC NVM_MAKE_JOBS NVM_COLORS INSTALLED_COLOR SYSTEM_COLOR CURRENT_COLOR NOT_INSTALLED_COLOR DEFAULT_COLOR LTS_COLOR > /dev/null 2>&1 ;;
		("set-colors") local EXIT_CODE
			nvm_set_colors "${1-}"
			EXIT_CODE=$? 
			if [ "$EXIT_CODE" -eq 17 ]
			then
				nvm --help >&2
				nvm_echo
				nvm_err_with_colors "\033[1;37mPlease pass in five \033[1;31mvalid color codes\033[1;37m. Choose from: rRgGbBcCyYmMkKeW\033[0m"
			fi ;;
		(*) nvm --help >&2
			return 127 ;;
	esac
}
nvm_add_iojs_prefix () {
	nvm_echo "$(nvm_iojs_prefix)-$(nvm_ensure_version_prefix "$(nvm_strip_iojs_prefix "${1-}")")"
}
nvm_alias () {
	local ALIAS
	ALIAS="${1-}" 
	if [ -z "${ALIAS}" ]
	then
		nvm_err 'An alias is required.'
		return 1
	fi
	if ! ALIAS="$(nvm_normalize_lts "${ALIAS}")" 
	then
		return $?
	fi
	if [ -z "${ALIAS}" ]
	then
		return 2
	fi
	local NVM_ALIAS_PATH
	NVM_ALIAS_PATH="$(nvm_alias_path)/${ALIAS}" 
	if [ ! -f "${NVM_ALIAS_PATH}" ]
	then
		nvm_err 'Alias does not exist.'
		return 2
	fi
	command awk 'NF' "${NVM_ALIAS_PATH}"
}
nvm_alias_path () {
	nvm_echo "$(nvm_version_dir old)/alias"
}
nvm_auto () {
	local NVM_MODE
	NVM_MODE="${1-}" 
	case "${NVM_MODE}" in
		(none) return 0 ;;
		(use) local VERSION
			local NVM_CURRENT
			NVM_CURRENT="$(nvm_ls_current)" 
			if [ "_${NVM_CURRENT}" = '_none' ] || [ "_${NVM_CURRENT}" = '_system' ]
			then
				VERSION="$(nvm_resolve_local_alias default 2>/dev/null || nvm_echo)" 
				if [ -n "${VERSION}" ]
				then
					if [ "_${VERSION}" != '_N/A' ] && nvm_is_valid_version "${VERSION}"
					then
						nvm use --silent "${VERSION}" > /dev/null
					else
						return 0
					fi
				elif nvm_rc_version > /dev/null 2>&1
				then
					nvm use --silent > /dev/null
				fi
			else
				nvm use --silent "${NVM_CURRENT}" > /dev/null
			fi ;;
		(install) local VERSION
			VERSION="$(nvm_alias default 2>/dev/null || nvm_echo)" 
			if [ -n "${VERSION}" ] && [ "_${VERSION}" != '_N/A' ] && nvm_is_valid_version "${VERSION}"
			then
				nvm install "${VERSION}" > /dev/null
			elif nvm_rc_version > /dev/null 2>&1
			then
				nvm install > /dev/null
			else
				return 0
			fi ;;
		(*) nvm_err 'Invalid auto mode supplied.'
			return 1 ;;
	esac
}
nvm_binary_available () {
	nvm_version_greater_than_or_equal_to "$(nvm_strip_iojs_prefix "${1-}")" v0.8.6
}
nvm_cache_dir () {
	nvm_echo "${NVM_DIR}/.cache"
}
nvm_cd () {
	\cd "$@"
}
nvm_change_path () {
	if [ -z "${1-}" ]
	then
		nvm_echo "${3-}${2-}"
	elif ! nvm_echo "${1-}" | nvm_grep -q "${NVM_DIR}/[^/]*${2-}" && ! nvm_echo "${1-}" | nvm_grep -q "${NVM_DIR}/versions/[^/]*/[^/]*${2-}"
	then
		nvm_echo "${3-}${2-}:${1-}"
	elif nvm_echo "${1-}" | nvm_grep -Eq "(^|:)(/usr(/local)?)?${2-}:.*${NVM_DIR}/[^/]*${2-}" || nvm_echo "${1-}" | nvm_grep -Eq "(^|:)(/usr(/local)?)?${2-}:.*${NVM_DIR}/versions/[^/]*/[^/]*${2-}"
	then
		nvm_echo "${3-}${2-}:${1-}"
	else
		nvm_echo "${1-}" | command sed -e "s#${NVM_DIR}/[^/]*${2-}[^:]*#${3-}${2-}#" -e "s#${NVM_DIR}/versions/[^/]*/[^/]*${2-}[^:]*#${3-}${2-}#"
	fi
}
nvm_check_file_permissions () {
	nvm_is_zsh && setopt local_options nonomatch
	for FILE in "$1"/* "$1"/.[!.]* "$1"/..?*
	do
		if [ -d "$FILE" ]
		then
			if [ -n "${NVM_DEBUG-}" ]
			then
				nvm_err "${FILE}"
			fi
			if [ ! -L "${FILE}" ] && ! nvm_check_file_permissions "${FILE}"
			then
				return 2
			fi
		elif [ -e "$FILE" ] && [ ! -w "$FILE" ] && [ ! -O "$FILE" ]
		then
			nvm_err "file is not writable or self-owned: $(nvm_sanitize_path "$FILE")"
			return 1
		fi
	done
	return 0
}
nvm_clang_version () {
	clang --version | command awk '{ if ($2 == "version") print $3; else if ($3 == "version") print $4 }' | command sed 's/-.*$//g'
}
nvm_command_info () {
	local COMMAND
	local INFO
	COMMAND="${1}" 
	if type "${COMMAND}" | nvm_grep -q hashed
	then
		INFO="$(type "${COMMAND}" | command sed -E 's/\(|\)//g' | command awk '{print $4}')" 
	elif type "${COMMAND}" | nvm_grep -q aliased
	then
		INFO="$(which "${COMMAND}") ($(type "${COMMAND}" | command awk '{ $1=$2=$3=$4="" ;print }' | command sed -e 's/^\ *//g' -Ee "s/\`|'//g"))" 
	elif type "${COMMAND}" | nvm_grep -q "^${COMMAND} is an alias for"
	then
		INFO="$(which "${COMMAND}") ($(type "${COMMAND}" | command awk '{ $1=$2=$3=$4=$5="" ;print }' | command sed 's/^\ *//g'))" 
	elif type "${COMMAND}" | nvm_grep -q "^${COMMAND} is /"
	then
		INFO="$(type "${COMMAND}" | command awk '{print $3}')" 
	else
		INFO="$(type "${COMMAND}")" 
	fi
	nvm_echo "${INFO}"
}
nvm_compare_checksum () {
	local FILE
	FILE="${1-}" 
	if [ -z "${FILE}" ]
	then
		nvm_err 'Provided file to checksum is empty.'
		return 4
	elif ! [ -f "${FILE}" ]
	then
		nvm_err 'Provided file to checksum does not exist.'
		return 3
	fi
	local COMPUTED_SUM
	COMPUTED_SUM="$(nvm_compute_checksum "${FILE}")" 
	local CHECKSUM
	CHECKSUM="${2-}" 
	if [ -z "${CHECKSUM}" ]
	then
		nvm_err 'Provided checksum to compare to is empty.'
		return 2
	fi
	if [ -z "${COMPUTED_SUM}" ]
	then
		nvm_err "Computed checksum of '${FILE}' is empty."
		nvm_err 'WARNING: Continuing *without checksum verification*'
		return
	elif [ "${COMPUTED_SUM}" != "${CHECKSUM}" ] && [ "${COMPUTED_SUM}" != "\\${CHECKSUM}" ]
	then
		nvm_err "Checksums do not match: '${COMPUTED_SUM}' found, '${CHECKSUM}' expected."
		return 1
	fi
	nvm_err 'Checksums matched!'
}
nvm_compute_checksum () {
	local FILE
	FILE="${1-}" 
	if [ -z "${FILE}" ]
	then
		nvm_err 'Provided file to checksum is empty.'
		return 2
	elif ! [ -f "${FILE}" ]
	then
		nvm_err 'Provided file to checksum does not exist.'
		return 1
	fi
	if nvm_has_non_aliased "sha256sum"
	then
		nvm_err 'Computing checksum with sha256sum'
		command sha256sum "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "shasum"
	then
		nvm_err 'Computing checksum with shasum -a 256'
		command shasum -a 256 "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "sha256"
	then
		nvm_err 'Computing checksum with sha256 -q'
		command sha256 -q "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "gsha256sum"
	then
		nvm_err 'Computing checksum with gsha256sum'
		command gsha256sum "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "openssl"
	then
		nvm_err 'Computing checksum with openssl dgst -sha256'
		command openssl dgst -sha256 "${FILE}" | command awk '{print $NF}'
	elif nvm_has_non_aliased "bssl"
	then
		nvm_err 'Computing checksum with bssl sha256sum'
		command bssl sha256sum "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "sha1sum"
	then
		nvm_err 'Computing checksum with sha1sum'
		command sha1sum "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "sha1"
	then
		nvm_err 'Computing checksum with sha1 -q'
		command sha1 -q "${FILE}"
	fi
}
nvm_curl_libz_support () {
	curl -V 2> /dev/null | nvm_grep "^Features:" | nvm_grep -q "libz"
}
nvm_curl_use_compression () {
	nvm_curl_libz_support && nvm_version_greater_than_or_equal_to "$(nvm_curl_version)" 7.21.0
}
nvm_curl_version () {
	curl -V | command awk '{ if ($1 == "curl") print $2 }' | command sed 's/-.*$//g'
}
nvm_die_on_prefix () {
	local NVM_DELETE_PREFIX
	NVM_DELETE_PREFIX="${1-}" 
	case "${NVM_DELETE_PREFIX}" in
		(0 | 1)  ;;
		(*) nvm_err 'First argument "delete the prefix" must be zero or one'
			return 1 ;;
	esac
	local NVM_COMMAND
	NVM_COMMAND="${2-}" 
	local NVM_VERSION_DIR
	NVM_VERSION_DIR="${3-}" 
	if [ -z "${NVM_COMMAND}" ] || [ -z "${NVM_VERSION_DIR}" ]
	then
		nvm_err 'Second argument "nvm command", and third argument "nvm version dir", must both be nonempty'
		return 2
	fi
	if [ -n "${PREFIX-}" ] && [ "$(nvm_version_path "$(node -v)")" != "${PREFIX}" ]
	then
		nvm deactivate > /dev/null 2>&1
		nvm_err "nvm is not compatible with the \"PREFIX\" environment variable: currently set to \"${PREFIX}\""
		nvm_err 'Run `unset PREFIX` to unset it.'
		return 3
	fi
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	local NVM_NPM_CONFIG_x_PREFIX_ENV
	NVM_NPM_CONFIG_x_PREFIX_ENV="$(command awk 'BEGIN { for (name in ENVIRON) if (toupper(name) == "NPM_CONFIG_PREFIX") { print name; break } }')" 
	if [ -n "${NVM_NPM_CONFIG_x_PREFIX_ENV-}" ]
	then
		local NVM_CONFIG_VALUE
		eval "NVM_CONFIG_VALUE=\"\$${NVM_NPM_CONFIG_x_PREFIX_ENV}\""
		if [ -n "${NVM_CONFIG_VALUE-}" ] && [ "_${NVM_OS}" = "_win" ]
		then
			NVM_CONFIG_VALUE="$(cd "$NVM_CONFIG_VALUE" 2>/dev/null && pwd)" 
		fi
		if [ -n "${NVM_CONFIG_VALUE-}" ] && ! nvm_tree_contains_path "${NVM_DIR}" "${NVM_CONFIG_VALUE}"
		then
			nvm deactivate > /dev/null 2>&1
			nvm_err "nvm is not compatible with the \"${NVM_NPM_CONFIG_x_PREFIX_ENV}\" environment variable: currently set to \"${NVM_CONFIG_VALUE}\""
			nvm_err "Run \`unset ${NVM_NPM_CONFIG_x_PREFIX_ENV}\` to unset it."
			return 4
		fi
	fi
	local NVM_NPM_BUILTIN_NPMRC
	NVM_NPM_BUILTIN_NPMRC="${NVM_VERSION_DIR}/lib/node_modules/npm/npmrc" 
	if nvm_npmrc_bad_news_bears "${NVM_NPM_BUILTIN_NPMRC}"
	then
		if [ "_${NVM_DELETE_PREFIX}" = "_1" ]
		then
			npm config --loglevel=warn delete prefix --userconfig="${NVM_NPM_BUILTIN_NPMRC}"
			npm config --loglevel=warn delete globalconfig --userconfig="${NVM_NPM_BUILTIN_NPMRC}"
		else
			nvm_err "Your builtin npmrc file ($(nvm_sanitize_path "${NVM_NPM_BUILTIN_NPMRC}"))"
			nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
			nvm_err "Run \`${NVM_COMMAND}\` to unset it."
			return 10
		fi
	fi
	local NVM_NPM_GLOBAL_NPMRC
	NVM_NPM_GLOBAL_NPMRC="${NVM_VERSION_DIR}/etc/npmrc" 
	if nvm_npmrc_bad_news_bears "${NVM_NPM_GLOBAL_NPMRC}"
	then
		if [ "_${NVM_DELETE_PREFIX}" = "_1" ]
		then
			npm config --global --loglevel=warn delete prefix
			npm config --global --loglevel=warn delete globalconfig
		else
			nvm_err "Your global npmrc file ($(nvm_sanitize_path "${NVM_NPM_GLOBAL_NPMRC}"))"
			nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
			nvm_err "Run \`${NVM_COMMAND}\` to unset it."
			return 10
		fi
	fi
	local NVM_NPM_USER_NPMRC
	NVM_NPM_USER_NPMRC="${HOME}/.npmrc" 
	if nvm_npmrc_bad_news_bears "${NVM_NPM_USER_NPMRC}"
	then
		if [ "_${NVM_DELETE_PREFIX}" = "_1" ]
		then
			npm config --loglevel=warn delete prefix --userconfig="${NVM_NPM_USER_NPMRC}"
			npm config --loglevel=warn delete globalconfig --userconfig="${NVM_NPM_USER_NPMRC}"
		else
			nvm_err "Your user’s .npmrc file ($(nvm_sanitize_path "${NVM_NPM_USER_NPMRC}"))"
			nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
			nvm_err "Run \`${NVM_COMMAND}\` to unset it."
			return 10
		fi
	fi
	local NVM_NPM_PROJECT_NPMRC
	NVM_NPM_PROJECT_NPMRC="$(nvm_find_project_dir)/.npmrc" 
	if nvm_npmrc_bad_news_bears "${NVM_NPM_PROJECT_NPMRC}"
	then
		if [ "_${NVM_DELETE_PREFIX}" = "_1" ]
		then
			npm config --loglevel=warn delete prefix
			npm config --loglevel=warn delete globalconfig
		else
			nvm_err "Your project npmrc file ($(nvm_sanitize_path "${NVM_NPM_PROJECT_NPMRC}"))"
			nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
			nvm_err "Run \`${NVM_COMMAND}\` to unset it."
			return 10
		fi
	fi
}
nvm_download () {
	if nvm_has "curl"
	then
		local CURL_COMPRESSED_FLAG="" 
		local CURL_HEADER_FLAG="" 
		if [ -n "${NVM_AUTH_HEADER:-}" ]
		then
			sanitized_header=$(nvm_sanitize_auth_header "${NVM_AUTH_HEADER}") 
			CURL_HEADER_FLAG="--header \"Authorization: ${sanitized_header}\"" 
		fi
		if nvm_curl_use_compression
		then
			CURL_COMPRESSED_FLAG="--compressed" 
		fi
		local NVM_DOWNLOAD_ARGS
		NVM_DOWNLOAD_ARGS='' 
		for arg in "$@"
		do
			NVM_DOWNLOAD_ARGS="${NVM_DOWNLOAD_ARGS} \"$arg\"" 
		done
		eval "curl -q --fail ${CURL_COMPRESSED_FLAG:-} ${CURL_HEADER_FLAG:-} ${NVM_DOWNLOAD_ARGS}"
	elif nvm_has "wget"
	then
		ARGS=$(nvm_echo "$@" | command sed "
      s/--progress-bar /--progress=bar /
      s/--compressed //
      s/--fail //
      s/-L //
      s/-I /--server-response /
      s/-s /-q /
      s/-sS /-nv /
      s/-o /-O /
      s/-C - /-c /
    ") 
		if [ -n "${NVM_AUTH_HEADER:-}" ]
		then
			ARGS="${ARGS} --header \"${NVM_AUTH_HEADER}\"" 
		fi
		eval wget $ARGS
	fi
}
nvm_download_artifact () {
	local FLAVOR
	case "${1-}" in
		(node | iojs) FLAVOR="${1}"  ;;
		(*) nvm_err 'supported flavors: node, iojs'
			return 1 ;;
	esac
	local KIND
	case "${2-}" in
		(binary | source) KIND="${2}"  ;;
		(*) nvm_err 'supported kinds: binary, source'
			return 1 ;;
	esac
	local TYPE
	TYPE="${3-}" 
	local MIRROR
	MIRROR="$(nvm_get_mirror "${FLAVOR}" "${TYPE}")" 
	if [ -z "${MIRROR}" ]
	then
		return 2
	fi
	local VERSION
	VERSION="${4}" 
	if [ -z "${VERSION}" ]
	then
		nvm_err 'A version number is required.'
		return 3
	fi
	if [ "${KIND}" = 'binary' ] && ! nvm_binary_available "${VERSION}"
	then
		nvm_err "No precompiled binary available for ${VERSION}."
		return
	fi
	local SLUG
	SLUG="$(nvm_get_download_slug "${FLAVOR}" "${KIND}" "${VERSION}")" 
	local COMPRESSION
	COMPRESSION="$(nvm_get_artifact_compression "${VERSION}")" 
	local CHECKSUM
	CHECKSUM="$(nvm_get_checksum "${FLAVOR}" "${TYPE}" "${VERSION}" "${SLUG}" "${COMPRESSION}")" 
	local tmpdir
	if [ "${KIND}" = 'binary' ]
	then
		tmpdir="$(nvm_cache_dir)/bin/${SLUG}" 
	else
		tmpdir="$(nvm_cache_dir)/src/${SLUG}" 
	fi
	command mkdir -p "${tmpdir}/files" || (
		nvm_err "creating directory ${tmpdir}/files failed"
		return 3
	)
	local TARBALL
	TARBALL="${tmpdir}/${SLUG}.${COMPRESSION}" 
	local TARBALL_URL
	if nvm_version_greater_than_or_equal_to "${VERSION}" 0.1.14
	then
		TARBALL_URL="${MIRROR}/${VERSION}/${SLUG}.${COMPRESSION}" 
	else
		TARBALL_URL="${MIRROR}/${SLUG}.${COMPRESSION}" 
	fi
	if [ -r "${TARBALL}" ]
	then
		nvm_err "Local cache found: $(nvm_sanitize_path "${TARBALL}")"
		if nvm_compare_checksum "${TARBALL}" "${CHECKSUM}" > /dev/null 2>&1
		then
			nvm_err "Checksums match! Using existing downloaded archive $(nvm_sanitize_path "${TARBALL}")"
			nvm_echo "${TARBALL}"
			return 0
		fi
		nvm_compare_checksum "${TARBALL}" "${CHECKSUM}"
		nvm_err "Checksum check failed!"
		nvm_err "Removing the broken local cache..."
		command rm -rf "${TARBALL}"
	fi
	nvm_err "Downloading ${TARBALL_URL}..."
	nvm_download -L -C - "${PROGRESS_BAR}" "${TARBALL_URL}" -o "${TARBALL}" || (
		command rm -rf "${TARBALL}" "${tmpdir}"
		nvm_err "download from ${TARBALL_URL} failed"
		return 4
	)
	if nvm_grep '404 Not Found' "${TARBALL}" > /dev/null
	then
		command rm -rf "${TARBALL}" "${tmpdir}"
		nvm_err "HTTP 404 at URL ${TARBALL_URL}"
		return 5
	fi
	nvm_compare_checksum "${TARBALL}" "${CHECKSUM}" || (
		command rm -rf "${tmpdir}/files"
		return 6
	)
	nvm_echo "${TARBALL}"
}
nvm_echo () {
	command printf %s\\n "$*" 2> /dev/null
}
nvm_echo_with_colors () {
	command printf %b\\n "$*" 2> /dev/null
}
nvm_ensure_default_set () {
	local VERSION
	VERSION="$1" 
	if [ -z "${VERSION}" ]
	then
		nvm_err 'nvm_ensure_default_set: a version is required'
		return 1
	elif nvm_alias default > /dev/null 2>&1
	then
		return 0
	fi
	local OUTPUT
	OUTPUT="$(nvm alias default "${VERSION}")" 
	local EXIT_CODE
	EXIT_CODE="$?" 
	nvm_echo "Creating default alias: ${OUTPUT}"
	return $EXIT_CODE
}
nvm_ensure_version_installed () {
	local PROVIDED_VERSION
	PROVIDED_VERSION="${1-}" 
	local IS_VERSION_FROM_NVMRC
	IS_VERSION_FROM_NVMRC="${2-}" 
	if [ "${PROVIDED_VERSION}" = 'system' ]
	then
		if nvm_has_system_iojs || nvm_has_system_node
		then
			return 0
		fi
		nvm_err "N/A: no system version of node/io.js is installed."
		return 1
	fi
	local LOCAL_VERSION
	local EXIT_CODE
	LOCAL_VERSION="$(nvm_version "${PROVIDED_VERSION}")" 
	EXIT_CODE="$?" 
	local NVM_VERSION_DIR
	if [ "${EXIT_CODE}" != "0" ] || ! nvm_is_version_installed "${LOCAL_VERSION}"
	then
		if VERSION="$(nvm_resolve_alias "${PROVIDED_VERSION}")" 
		then
			nvm_err "N/A: version \"${PROVIDED_VERSION} -> ${VERSION}\" is not yet installed."
		else
			local PREFIXED_VERSION
			PREFIXED_VERSION="$(nvm_ensure_version_prefix "${PROVIDED_VERSION}")" 
			nvm_err "N/A: version \"${PREFIXED_VERSION:-$PROVIDED_VERSION}\" is not yet installed."
		fi
		nvm_err ""
		if [ "${PROVIDED_VERSION}" = 'lts' ]
		then
			nvm_err '`lts` is not an alias - you may need to run `nvm install --lts` to install and `nvm use --lts` to use it.'
		elif [ "${IS_VERSION_FROM_NVMRC}" != '1' ]
		then
			nvm_err "You need to run \`nvm install ${PROVIDED_VERSION}\` to install and use it."
		else
			nvm_err 'You need to run `nvm install` to install and use the node version specified in `.nvmrc`.'
		fi
		return 1
	fi
}
nvm_ensure_version_prefix () {
	local NVM_VERSION
	NVM_VERSION="$(nvm_strip_iojs_prefix "${1-}" | command sed -e 's/^\([0-9]\)/v\1/g')" 
	if nvm_is_iojs_version "${1-}"
	then
		nvm_add_iojs_prefix "${NVM_VERSION}"
	else
		nvm_echo "${NVM_VERSION}"
	fi
}
nvm_err () {
	nvm_echo "$@" >&2
}
nvm_err_with_colors () {
	nvm_echo_with_colors "$@" >&2
}
nvm_extract_tarball () {
	if [ "$#" -ne 4 ]
	then
		nvm_err 'nvm_extract_tarball requires exactly 4 arguments'
		return 5
	fi
	local NVM_OS
	NVM_OS="${1-}" 
	local VERSION
	VERSION="${2-}" 
	local TARBALL
	TARBALL="${3-}" 
	local TMPDIR
	TMPDIR="${4-}" 
	local tar_compression_flag
	tar_compression_flag='z' 
	if nvm_supports_xz "${VERSION}"
	then
		tar_compression_flag='J' 
	fi
	local tar
	tar='tar' 
	if [ "${NVM_OS}" = 'aix' ]
	then
		tar='gtar' 
	fi
	if [ "${NVM_OS}" = 'openbsd' ]
	then
		if [ "${tar_compression_flag}" = 'J' ]
		then
			command xzcat "${TARBALL}" | "${tar}" -xf - -C "${TMPDIR}" -s '/[^\/]*\///' || return 1
		else
			command "${tar}" -x${tar_compression_flag}f "${TARBALL}" -C "${TMPDIR}" -s '/[^\/]*\///' || return 1
		fi
	else
		command "${tar}" -x${tar_compression_flag}f "${TARBALL}" -C "${TMPDIR}" --strip-components 1 || return 1
	fi
}
nvm_find_nvmrc () {
	local dir
	dir="$(nvm_find_up '.nvmrc')" 
	if [ -e "${dir}/.nvmrc" ]
	then
		nvm_echo "${dir}/.nvmrc"
	fi
}
nvm_find_project_dir () {
	local path_
	path_="${PWD}" 
	while [ "${path_}" != "" ] && [ "${path_}" != '.' ] && [ ! -f "${path_}/package.json" ] && [ ! -d "${path_}/node_modules" ]
	do
		path_=${path_%/*} 
	done
	nvm_echo "${path_}"
}
nvm_find_up () {
	local path_
	path_="${PWD}" 
	while [ "${path_}" != "" ] && [ "${path_}" != '.' ] && [ ! -f "${path_}/${1-}" ]
	do
		path_=${path_%/*} 
	done
	nvm_echo "${path_}"
}
nvm_format_version () {
	local VERSION
	VERSION="$(nvm_ensure_version_prefix "${1-}")" 
	local NUM_GROUPS
	NUM_GROUPS="$(nvm_num_version_groups "${VERSION}")" 
	if [ "${NUM_GROUPS}" -lt 3 ]
	then
		nvm_format_version "${VERSION%.}.0"
	else
		nvm_echo "${VERSION}" | command cut -f1-3 -d.
	fi
}
nvm_get_arch () {
	local HOST_ARCH
	local NVM_OS
	local EXIT_CODE
	local LONG_BIT
	NVM_OS="$(nvm_get_os)" 
	if [ "_${NVM_OS}" = "_sunos" ]
	then
		if HOST_ARCH=$(pkg_info -Q MACHINE_ARCH pkg_install) 
		then
			HOST_ARCH=$(nvm_echo "${HOST_ARCH}" | command tail -1) 
		else
			HOST_ARCH=$(isainfo -n) 
		fi
	elif [ "_${NVM_OS}" = "_aix" ]
	then
		HOST_ARCH=ppc64 
	else
		HOST_ARCH="$(command uname -m)" 
		LONG_BIT="$(getconf LONG_BIT 2>/dev/null)" 
	fi
	local NVM_ARCH
	case "${HOST_ARCH}" in
		(x86_64 | amd64) NVM_ARCH="x64"  ;;
		(i*86) NVM_ARCH="x86"  ;;
		(aarch64 | armv8l) NVM_ARCH="arm64"  ;;
		(*) NVM_ARCH="${HOST_ARCH}"  ;;
	esac
	if [ "_${LONG_BIT}" = "_32" ] && [ "${NVM_ARCH}" = "x64" ]
	then
		NVM_ARCH="x86" 
	fi
	if [ "$(uname)" = "Linux" ] && [ "${NVM_ARCH}" = arm64 ] && [ "$(command od -An -t x1 -j 4 -N 1 "/sbin/init" 2>/dev/null)" = ' 01' ]
	then
		NVM_ARCH=armv7l 
		HOST_ARCH=armv7l 
	fi
	if [ -f "/etc/alpine-release" ]
	then
		NVM_ARCH=x64-musl 
	fi
	nvm_echo "${NVM_ARCH}"
}
nvm_get_artifact_compression () {
	local VERSION
	VERSION="${1-}" 
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	local COMPRESSION
	COMPRESSION='tar.gz' 
	if [ "_${NVM_OS}" = '_win' ]
	then
		COMPRESSION='zip' 
	elif nvm_supports_xz "${VERSION}"
	then
		COMPRESSION='tar.xz' 
	fi
	nvm_echo "${COMPRESSION}"
}
nvm_get_checksum () {
	local FLAVOR
	case "${1-}" in
		(node | iojs) FLAVOR="${1}"  ;;
		(*) nvm_err 'supported flavors: node, iojs'
			return 2 ;;
	esac
	local MIRROR
	MIRROR="$(nvm_get_mirror "${FLAVOR}" "${2-}")" 
	if [ -z "${MIRROR}" ]
	then
		return 1
	fi
	local SHASUMS_URL
	if [ "$(nvm_get_checksum_alg)" = 'sha-256' ]
	then
		SHASUMS_URL="${MIRROR}/${3}/SHASUMS256.txt" 
	else
		SHASUMS_URL="${MIRROR}/${3}/SHASUMS.txt" 
	fi
	nvm_download -L -s "${SHASUMS_URL}" -o - | command awk "{ if (\"${4}.${5}\" == \$2) print \$1}"
}
nvm_get_checksum_alg () {
	local NVM_CHECKSUM_BIN
	NVM_CHECKSUM_BIN="$(nvm_get_checksum_binary 2>/dev/null)" 
	case "${NVM_CHECKSUM_BIN-}" in
		(sha256sum | shasum | sha256 | gsha256sum | openssl | bssl) nvm_echo 'sha-256' ;;
		(sha1sum | sha1) nvm_echo 'sha-1' ;;
		(*) nvm_get_checksum_binary
			return $? ;;
	esac
}
nvm_get_checksum_binary () {
	if nvm_has_non_aliased 'sha256sum'
	then
		nvm_echo 'sha256sum'
	elif nvm_has_non_aliased 'shasum'
	then
		nvm_echo 'shasum'
	elif nvm_has_non_aliased 'sha256'
	then
		nvm_echo 'sha256'
	elif nvm_has_non_aliased 'gsha256sum'
	then
		nvm_echo 'gsha256sum'
	elif nvm_has_non_aliased 'openssl'
	then
		nvm_echo 'openssl'
	elif nvm_has_non_aliased 'bssl'
	then
		nvm_echo 'bssl'
	elif nvm_has_non_aliased 'sha1sum'
	then
		nvm_echo 'sha1sum'
	elif nvm_has_non_aliased 'sha1'
	then
		nvm_echo 'sha1'
	else
		nvm_err 'Unaliased sha256sum, shasum, sha256, gsha256sum, openssl, or bssl not found.'
		nvm_err 'Unaliased sha1sum or sha1 not found.'
		return 1
	fi
}
nvm_get_colors () {
	local COLOR
	local SYS_COLOR
	local COLORS
	COLORS="${NVM_COLORS:-bygre}" 
	case $1 in
		(1) COLOR=$(nvm_print_color_code "$(echo "$COLORS" | awk '{ print substr($0, 1, 1); }')")  ;;
		(2) COLOR=$(nvm_print_color_code "$(echo "$COLORS" | awk '{ print substr($0, 2, 1); }')")  ;;
		(3) COLOR=$(nvm_print_color_code "$(echo "$COLORS" | awk '{ print substr($0, 3, 1); }')")  ;;
		(4) COLOR=$(nvm_print_color_code "$(echo "$COLORS" | awk '{ print substr($0, 4, 1); }')")  ;;
		(5) COLOR=$(nvm_print_color_code "$(echo "$COLORS" | awk '{ print substr($0, 5, 1); }')")  ;;
		(6) SYS_COLOR=$(nvm_print_color_code "$(echo "$COLORS" | awk '{ print substr($0, 2, 1); }')") 
			COLOR=$(nvm_echo "$SYS_COLOR" | command tr '0;' '1;')  ;;
		(*) nvm_err "Invalid color index, ${1-}"
			return 1 ;;
	esac
	nvm_echo "$COLOR"
}
nvm_get_default_packages () {
	local NVM_DEFAULT_PACKAGE_FILE
	NVM_DEFAULT_PACKAGE_FILE="${NVM_DIR}/default-packages" 
	if [ -f "${NVM_DEFAULT_PACKAGE_FILE}" ]
	then
		command awk -v filename="${NVM_DEFAULT_PACKAGE_FILE}" '
      /^[[:space:]]*#/ { next }                     # Skip lines that begin with #
      /^[[:space:]]*$/ { next }                     # Skip empty lines
      /[[:space:]]/ && !/^[[:space:]]*#/ {
        print "Only one package per line is allowed in `" filename "`. Please remove any lines with multiple space-separated values." > "/dev/stderr"
        err = 1
        exit 1
      }
      {
        if (NR > 1 && !prev_space) printf " "
        printf "%s", $0
        prev_space = 0
      }
    ' "${NVM_DEFAULT_PACKAGE_FILE}"
	fi
}
nvm_get_download_slug () {
	local FLAVOR
	case "${1-}" in
		(node | iojs) FLAVOR="${1}"  ;;
		(*) nvm_err 'supported flavors: node, iojs'
			return 1 ;;
	esac
	local KIND
	case "${2-}" in
		(binary | source) KIND="${2}"  ;;
		(*) nvm_err 'supported kinds: binary, source'
			return 2 ;;
	esac
	local VERSION
	VERSION="${3-}" 
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	local NVM_ARCH
	NVM_ARCH="$(nvm_get_arch)" 
	if ! nvm_is_merged_node_version "${VERSION}"
	then
		if [ "${NVM_ARCH}" = 'armv6l' ] || [ "${NVM_ARCH}" = 'armv7l' ]
		then
			NVM_ARCH="arm-pi" 
		fi
	fi
	if nvm_version_greater '14.17.0' "${VERSION}" || (
			nvm_version_greater_than_or_equal_to "${VERSION}" '15.0.0' && nvm_version_greater '16.0.0' "${VERSION}"
		)
	then
		if [ "_${NVM_OS}" = '_darwin' ] && [ "${NVM_ARCH}" = 'arm64' ]
		then
			NVM_ARCH=x64 
		fi
	fi
	if [ "${KIND}" = 'binary' ]
	then
		nvm_echo "${FLAVOR}-${VERSION}-${NVM_OS}-${NVM_ARCH}"
	elif [ "${KIND}" = 'source' ]
	then
		nvm_echo "${FLAVOR}-${VERSION}"
	fi
}
nvm_get_latest () {
	local NVM_LATEST_URL
	local CURL_COMPRESSED_FLAG
	if nvm_has "curl"
	then
		if nvm_curl_use_compression
		then
			CURL_COMPRESSED_FLAG="--compressed" 
		fi
		NVM_LATEST_URL="$(curl ${CURL_COMPRESSED_FLAG:-} -q -w "%{url_effective}\\n" -L -s -S https://latest.nvm.sh -o /dev/null)" 
	elif nvm_has "wget"
	then
		NVM_LATEST_URL="$(wget -q https://latest.nvm.sh --server-response -O /dev/null 2>&1 | command awk '/^  Location: /{DEST=$2} END{ print DEST }')" 
	else
		nvm_err 'nvm needs curl or wget to proceed.'
		return 1
	fi
	if [ -z "${NVM_LATEST_URL}" ]
	then
		nvm_err "https://latest.nvm.sh did not redirect to the latest release on GitHub"
		return 2
	fi
	nvm_echo "${NVM_LATEST_URL##*/}"
}
nvm_get_make_jobs () {
	if nvm_is_natural_num "${1-}"
	then
		NVM_MAKE_JOBS="$1" 
		nvm_echo "number of \`make\` jobs: ${NVM_MAKE_JOBS}"
		return
	elif [ -n "${1-}" ]
	then
		unset NVM_MAKE_JOBS
		nvm_err "$1 is invalid for number of \`make\` jobs, must be a natural number"
	fi
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	local NVM_CPU_CORES
	case "_${NVM_OS}" in
		("_linux") NVM_CPU_CORES="$(nvm_grep -c -E '^processor.+: [0-9]+' /proc/cpuinfo)"  ;;
		("_freebsd" | "_darwin" | "_openbsd") NVM_CPU_CORES="$(sysctl -n hw.ncpu)"  ;;
		("_sunos") NVM_CPU_CORES="$(psrinfo | wc -l)"  ;;
		("_aix") NVM_CPU_CORES="$(pmcycles -m | wc -l)"  ;;
	esac
	if ! nvm_is_natural_num "${NVM_CPU_CORES}"
	then
		nvm_err 'Can not determine how many core(s) are available, running in single-threaded mode.'
		nvm_err 'Please report an issue on GitHub to help us make nvm run faster on your computer!'
		NVM_MAKE_JOBS=1 
	else
		nvm_echo "Detected that you have ${NVM_CPU_CORES} CPU core(s)"
		if [ "${NVM_CPU_CORES}" -gt 2 ]
		then
			NVM_MAKE_JOBS=$((NVM_CPU_CORES - 1)) 
			nvm_echo "Running with ${NVM_MAKE_JOBS} threads to speed up the build"
		else
			NVM_MAKE_JOBS=1 
			nvm_echo 'Number of CPU core(s) less than or equal to 2, running in single-threaded mode'
		fi
	fi
}
nvm_get_minor_version () {
	local VERSION
	VERSION="$1" 
	if [ -z "${VERSION}" ]
	then
		nvm_err 'a version is required'
		return 1
	fi
	case "${VERSION}" in
		(v | .* | *..* | v*[!.0123456789]* | [!v]*[!.0123456789]* | [!v0123456789]* | v[!0123456789]*) nvm_err 'invalid version number'
			return 2 ;;
	esac
	local PREFIXED_VERSION
	PREFIXED_VERSION="$(nvm_format_version "${VERSION}")" 
	local MINOR
	MINOR="$(nvm_echo "${PREFIXED_VERSION}" | nvm_grep -e '^v' | command cut -c2- | command cut -d . -f 1,2)" 
	if [ -z "${MINOR}" ]
	then
		nvm_err 'invalid version number! (please report this)'
		return 3
	fi
	nvm_echo "${MINOR}"
}
nvm_get_mirror () {
	local NVM_MIRROR
	NVM_MIRROR='' 
	case "${1}-${2}" in
		(node-std) NVM_MIRROR="${NVM_NODEJS_ORG_MIRROR:-https://nodejs.org/dist}"  ;;
		(iojs-std) NVM_MIRROR="${NVM_IOJS_ORG_MIRROR:-https://iojs.org/dist}"  ;;
		(*) nvm_err 'unknown type of node.js or io.js release'
			return 1 ;;
	esac
	case "${NVM_MIRROR}" in
		(*\`* | *\\* | *\'* | *\(* | *' '*) nvm_err '$NVM_NODEJS_ORG_MIRROR and $NVM_IOJS_ORG_MIRROR may only contain a URL'
			return 2 ;;
	esac
	if ! nvm_echo "${NVM_MIRROR}" | command awk '{ $0 ~ "^https?://[a-zA-Z0-9./_-]+$" }'
	then
		nvm_err '$NVM_NODEJS_ORG_MIRROR and $NVM_IOJS_ORG_MIRROR may only contain a URL'
		return 2
	fi
	nvm_echo "${NVM_MIRROR}"
}
nvm_get_os () {
	local NVM_UNAME
	NVM_UNAME="$(command uname -a)" 
	local NVM_OS
	case "${NVM_UNAME}" in
		(Linux\ *) NVM_OS=linux  ;;
		(Darwin\ *) NVM_OS=darwin  ;;
		(SunOS\ *) NVM_OS=sunos  ;;
		(FreeBSD\ *) NVM_OS=freebsd  ;;
		(OpenBSD\ *) NVM_OS=openbsd  ;;
		(AIX\ *) NVM_OS=aix  ;;
		(CYGWIN* | MSYS* | MINGW*) NVM_OS=win  ;;
	esac
	nvm_echo "${NVM_OS-}"
}
nvm_grep () {
	GREP_OPTIONS='' command grep "$@"
}
nvm_has () {
	type "${1-}" > /dev/null 2>&1
}
nvm_has_colors () {
	local NVM_NUM_COLORS
	if nvm_has tput
	then
		NVM_NUM_COLORS="$(command tput -T "${TERM:-vt100}" colors)" 
	fi
	[ "${NVM_NUM_COLORS:--1}" -ge 8 ] && [ "${NVM_NO_COLORS-}" != '--no-colors' ]
}
nvm_has_non_aliased () {
	nvm_has "${1-}" && ! nvm_is_alias "${1-}"
}
nvm_has_solaris_binary () {
	local VERSION="${1-}" 
	if nvm_is_merged_node_version "${VERSION}"
	then
		return 0
	elif nvm_is_iojs_version "${VERSION}"
	then
		nvm_iojs_version_has_solaris_binary "${VERSION}"
	else
		nvm_node_version_has_solaris_binary "${VERSION}"
	fi
}
nvm_has_system_iojs () {
	[ "$(nvm deactivate >/dev/null 2>&1 && command -v iojs)" != '' ]
}
nvm_has_system_node () {
	[ "$(nvm deactivate >/dev/null 2>&1 && command -v node)" != '' ]
}
nvm_install_binary () {
	local FLAVOR
	case "${1-}" in
		(node | iojs) FLAVOR="${1}"  ;;
		(*) nvm_err 'supported flavors: node, iojs'
			return 4 ;;
	esac
	local TYPE
	TYPE="${2-}" 
	local PREFIXED_VERSION
	PREFIXED_VERSION="${3-}" 
	if [ -z "${PREFIXED_VERSION}" ]
	then
		nvm_err 'A version number is required.'
		return 3
	fi
	local nosource
	nosource="${4-}" 
	local VERSION
	VERSION="$(nvm_strip_iojs_prefix "${PREFIXED_VERSION}")" 
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	if [ -z "${NVM_OS}" ]
	then
		return 2
	fi
	local TARBALL
	local TMPDIR
	local PROGRESS_BAR
	local NODE_OR_IOJS
	if [ "${FLAVOR}" = 'node' ]
	then
		NODE_OR_IOJS="${FLAVOR}" 
	elif [ "${FLAVOR}" = 'iojs' ]
	then
		NODE_OR_IOJS="io.js" 
	fi
	if [ "${NVM_NO_PROGRESS-}" = "1" ]
	then
		PROGRESS_BAR="-sS" 
	else
		PROGRESS_BAR="--progress-bar" 
	fi
	nvm_echo "Downloading and installing ${NODE_OR_IOJS-} ${VERSION}..."
	TARBALL="$(PROGRESS_BAR="${PROGRESS_BAR}" nvm_download_artifact "${FLAVOR}" binary "${TYPE-}" "${VERSION}" | command tail -1)" 
	if [ -f "${TARBALL}" ]
	then
		TMPDIR="$(dirname "${TARBALL}")/files" 
	fi
	if nvm_install_binary_extract "${NVM_OS}" "${PREFIXED_VERSION}" "${VERSION}" "${TARBALL}" "${TMPDIR}"
	then
		if [ -n "${ALIAS-}" ]
		then
			nvm alias "${ALIAS}" "${provided_version}"
		fi
		return 0
	fi
	if [ "${nosource-}" = '1' ]
	then
		nvm_err 'Binary download failed. Download from source aborted.'
		return 0
	fi
	nvm_err 'Binary download failed, trying source.'
	if [ -n "${TMPDIR-}" ]
	then
		command rm -rf "${TMPDIR}"
	fi
	return 1
}
nvm_install_binary_extract () {
	if [ "$#" -ne 5 ]
	then
		nvm_err 'nvm_install_binary_extract needs 5 parameters'
		return 1
	fi
	local NVM_OS
	local PREFIXED_VERSION
	local VERSION
	local TARBALL
	local TMPDIR
	NVM_OS="${1}" 
	PREFIXED_VERSION="${2}" 
	VERSION="${3}" 
	TARBALL="${4}" 
	TMPDIR="${5}" 
	local VERSION_PATH
	[ -n "${TMPDIR-}" ] && command mkdir -p "${TMPDIR}" && VERSION_PATH="$(nvm_version_path "${PREFIXED_VERSION}")"  || return 1
	if [ "${NVM_OS}" = 'win' ]
	then
		VERSION_PATH="${VERSION_PATH}/bin" 
		command unzip -q "${TARBALL}" -d "${TMPDIR}" || return 1
	else
		nvm_extract_tarball "${NVM_OS}" "${VERSION}" "${TARBALL}" "${TMPDIR}"
	fi
	command mkdir -p "${VERSION_PATH}" || return 1
	if [ "${NVM_OS}" = 'win' ]
	then
		command mv "${TMPDIR}/"*/* "${VERSION_PATH}/" || return 1
		command chmod +x "${VERSION_PATH}"/node.exe || return 1
		command chmod +x "${VERSION_PATH}"/npm || return 1
		command chmod +x "${VERSION_PATH}"/npx 2> /dev/null
	else
		command mv "${TMPDIR}/"* "${VERSION_PATH}" || return 1
	fi
	command rm -rf "${TMPDIR}"
	return 0
}
nvm_install_default_packages () {
	local DEFAULT_PACKAGES
	DEFAULT_PACKAGES="$(nvm_get_default_packages)" 
	EXIT_CODE=$? 
	if [ $EXIT_CODE -ne 0 ] || [ -z "${DEFAULT_PACKAGES}" ]
	then
		return $EXIT_CODE
	fi
	nvm_echo "Installing default global packages from ${NVM_DIR}/default-packages..."
	nvm_echo "npm install -g --quiet ${DEFAULT_PACKAGES}"
	if ! nvm_echo "${DEFAULT_PACKAGES}" | command xargs npm install -g --quiet
	then
		nvm_err "Failed installing default packages. Please check if your default-packages file or a package in it has problems!"
		return 1
	fi
}
nvm_install_latest_npm () {
	nvm_echo 'Attempting to upgrade to the latest working version of npm...'
	local NODE_VERSION
	NODE_VERSION="$(nvm_strip_iojs_prefix "$(nvm_ls_current)")" 
	local NPM_VERSION
	NPM_VERSION="$(npm --version 2>/dev/null)" 
	if [ "${NODE_VERSION}" = 'system' ]
	then
		NODE_VERSION="$(node --version)" 
	elif [ "${NODE_VERSION}" = 'none' ]
	then
		nvm_echo "Detected node version ${NODE_VERSION}, npm version v${NPM_VERSION}"
		NODE_VERSION='' 
	fi
	if [ -z "${NODE_VERSION}" ]
	then
		nvm_err 'Unable to obtain node version.'
		return 1
	fi
	if [ -z "${NPM_VERSION}" ]
	then
		nvm_err 'Unable to obtain npm version.'
		return 2
	fi
	local NVM_NPM_CMD
	NVM_NPM_CMD='npm' 
	if [ "${NVM_DEBUG-}" = 1 ]
	then
		nvm_echo "Detected node version ${NODE_VERSION}, npm version v${NPM_VERSION}"
		NVM_NPM_CMD='nvm_echo npm' 
	fi
	local NVM_IS_0_6
	NVM_IS_0_6=0 
	if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 0.6.0 && nvm_version_greater 0.7.0 "${NODE_VERSION}"
	then
		NVM_IS_0_6=1 
	fi
	local NVM_IS_0_9
	NVM_IS_0_9=0 
	if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 0.9.0 && nvm_version_greater 0.10.0 "${NODE_VERSION}"
	then
		NVM_IS_0_9=1 
	fi
	if [ $NVM_IS_0_6 -eq 1 ]
	then
		nvm_echo '* `node` v0.6.x can only upgrade to `npm` v1.3.x'
		$NVM_NPM_CMD install -g npm@1.3
	elif [ $NVM_IS_0_9 -eq 0 ]
	then
		if nvm_version_greater_than_or_equal_to "${NPM_VERSION}" 1.0.0 && nvm_version_greater 2.0.0 "${NPM_VERSION}"
		then
			nvm_echo '* `npm` v1.x needs to first jump to `npm` v1.4.28 to be able to upgrade further'
			$NVM_NPM_CMD install -g npm@1.4.28
		elif nvm_version_greater_than_or_equal_to "${NPM_VERSION}" 2.0.0 && nvm_version_greater 3.0.0 "${NPM_VERSION}"
		then
			nvm_echo '* `npm` v2.x needs to first jump to the latest v2 to be able to upgrade further'
			$NVM_NPM_CMD install -g npm@2
		fi
	fi
	if [ $NVM_IS_0_9 -eq 1 ] || [ $NVM_IS_0_6 -eq 1 ]
	then
		nvm_echo '* node v0.6 and v0.9 are unable to upgrade further'
	elif nvm_version_greater 1.1.0 "${NODE_VERSION}"
	then
		nvm_echo '* `npm` v4.5.x is the last version that works on `node` versions < v1.1.0'
		$NVM_NPM_CMD install -g npm@4.5
	elif nvm_version_greater 4.0.0 "${NODE_VERSION}"
	then
		nvm_echo '* `npm` v5 and higher do not work on `node` versions below v4.0.0'
		$NVM_NPM_CMD install -g npm@4
	elif [ $NVM_IS_0_9 -eq 0 ] && [ $NVM_IS_0_6 -eq 0 ]
	then
		local NVM_IS_4_4_OR_BELOW
		NVM_IS_4_4_OR_BELOW=0 
		if nvm_version_greater 4.5.0 "${NODE_VERSION}"
		then
			NVM_IS_4_4_OR_BELOW=1 
		fi
		local NVM_IS_5_OR_ABOVE
		NVM_IS_5_OR_ABOVE=0 
		if [ $NVM_IS_4_4_OR_BELOW -eq 0 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 5.0.0
		then
			NVM_IS_5_OR_ABOVE=1 
		fi
		local NVM_IS_6_OR_ABOVE
		NVM_IS_6_OR_ABOVE=0 
		local NVM_IS_6_2_OR_ABOVE
		NVM_IS_6_2_OR_ABOVE=0 
		if [ $NVM_IS_5_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 6.0.0
		then
			NVM_IS_6_OR_ABOVE=1 
			if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 6.2.0
			then
				NVM_IS_6_2_OR_ABOVE=1 
			fi
		fi
		local NVM_IS_9_OR_ABOVE
		NVM_IS_9_OR_ABOVE=0 
		local NVM_IS_9_3_OR_ABOVE
		NVM_IS_9_3_OR_ABOVE=0 
		if [ $NVM_IS_6_2_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 9.0.0
		then
			NVM_IS_9_OR_ABOVE=1 
			if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 9.3.0
			then
				NVM_IS_9_3_OR_ABOVE=1 
			fi
		fi
		local NVM_IS_10_OR_ABOVE
		NVM_IS_10_OR_ABOVE=0 
		if [ $NVM_IS_9_3_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 10.0.0
		then
			NVM_IS_10_OR_ABOVE=1 
		fi
		local NVM_IS_12_LTS_OR_ABOVE
		NVM_IS_12_LTS_OR_ABOVE=0 
		if [ $NVM_IS_10_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 12.13.0
		then
			NVM_IS_12_LTS_OR_ABOVE=1 
		fi
		local NVM_IS_13_OR_ABOVE
		NVM_IS_13_OR_ABOVE=0 
		if [ $NVM_IS_12_LTS_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 13.0.0
		then
			NVM_IS_13_OR_ABOVE=1 
		fi
		local NVM_IS_14_LTS_OR_ABOVE
		NVM_IS_14_LTS_OR_ABOVE=0 
		if [ $NVM_IS_13_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 14.15.0
		then
			NVM_IS_14_LTS_OR_ABOVE=1 
		fi
		local NVM_IS_14_17_OR_ABOVE
		NVM_IS_14_17_OR_ABOVE=0 
		if [ $NVM_IS_14_LTS_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 14.17.0
		then
			NVM_IS_14_17_OR_ABOVE=1 
		fi
		local NVM_IS_15_OR_ABOVE
		NVM_IS_15_OR_ABOVE=0 
		if [ $NVM_IS_14_LTS_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 15.0.0
		then
			NVM_IS_15_OR_ABOVE=1 
		fi
		local NVM_IS_16_OR_ABOVE
		NVM_IS_16_OR_ABOVE=0 
		if [ $NVM_IS_15_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 16.0.0
		then
			NVM_IS_16_OR_ABOVE=1 
		fi
		local NVM_IS_16_LTS_OR_ABOVE
		NVM_IS_16_LTS_OR_ABOVE=0 
		if [ $NVM_IS_16_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 16.13.0
		then
			NVM_IS_16_LTS_OR_ABOVE=1 
		fi
		local NVM_IS_17_OR_ABOVE
		NVM_IS_17_OR_ABOVE=0 
		if [ $NVM_IS_16_LTS_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 17.0.0
		then
			NVM_IS_17_OR_ABOVE=1 
		fi
		local NVM_IS_18_OR_ABOVE
		NVM_IS_18_OR_ABOVE=0 
		if [ $NVM_IS_17_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 18.0.0
		then
			NVM_IS_18_OR_ABOVE=1 
		fi
		local NVM_IS_18_17_OR_ABOVE
		NVM_IS_18_17_OR_ABOVE=0 
		if [ $NVM_IS_18_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 18.17.0
		then
			NVM_IS_18_17_OR_ABOVE=1 
		fi
		local NVM_IS_19_OR_ABOVE
		NVM_IS_19_OR_ABOVE=0 
		if [ $NVM_IS_18_17_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 19.0.0
		then
			NVM_IS_19_OR_ABOVE=1 
		fi
		local NVM_IS_20_5_OR_ABOVE
		NVM_IS_20_5_OR_ABOVE=0 
		if [ $NVM_IS_19_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 20.5.0
		then
			NVM_IS_20_5_OR_ABOVE=1 
		fi
		local NVM_IS_20_17_OR_ABOVE
		NVM_IS_20_17_OR_ABOVE=0 
		if [ $NVM_IS_20_5_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 20.17.0
		then
			NVM_IS_20_17_OR_ABOVE=1 
		fi
		local NVM_IS_21_OR_ABOVE
		NVM_IS_21_OR_ABOVE=0 
		if [ $NVM_IS_20_17_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 21.0.0
		then
			NVM_IS_21_OR_ABOVE=1 
		fi
		local NVM_IS_22_9_OR_ABOVE
		NVM_IS_22_9_OR_ABOVE=0 
		if [ $NVM_IS_21_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 22.9.0
		then
			NVM_IS_22_9_OR_ABOVE=1 
		fi
		if [ $NVM_IS_4_4_OR_BELOW -eq 1 ] || {
				[ $NVM_IS_5_OR_ABOVE -eq 1 ] && nvm_version_greater 5.10.0 "${NODE_VERSION}"
			}
		then
			nvm_echo '* `npm` `v5.3.x` is the last version that works on `node` 4.x versions below v4.4, or 5.x versions below v5.10, due to `Buffer.alloc`'
			$NVM_NPM_CMD install -g npm@5.3
		elif [ $NVM_IS_4_4_OR_BELOW -eq 0 ] && nvm_version_greater 4.7.0 "${NODE_VERSION}"
		then
			nvm_echo '* `npm` `v5.4.1` is the last version that works on `node` `v4.5` and `v4.6`'
			$NVM_NPM_CMD install -g npm@5.4.1
		elif [ $NVM_IS_6_OR_ABOVE -eq 0 ]
		then
			nvm_echo '* `npm` `v5.x` is the last version that works on `node` below `v6.0.0`'
			$NVM_NPM_CMD install -g npm@5
		elif {
				[ $NVM_IS_6_OR_ABOVE -eq 1 ] && [ $NVM_IS_6_2_OR_ABOVE -eq 0 ]
			} || {
				[ $NVM_IS_9_OR_ABOVE -eq 1 ] && [ $NVM_IS_9_3_OR_ABOVE -eq 0 ]
			}
		then
			nvm_echo '* `npm` `v6.9` is the last version that works on `node` `v6.0.x`, `v6.1.x`, `v9.0.x`, `v9.1.x`, or `v9.2.x`'
			$NVM_NPM_CMD install -g npm@6.9
		elif [ $NVM_IS_10_OR_ABOVE -eq 0 ]
		then
			if nvm_version_greater 4.4.4 "${NPM_VERSION}"
			then
				nvm_echo '* `npm` `v4.4.4` or later is required to install npm v6.14.18'
				$NVM_NPM_CMD install -g npm@4
			fi
			nvm_echo '* `npm` `v6.x` is the last version that works on `node` below `v10.0.0`'
			$NVM_NPM_CMD install -g npm@6
		elif [ $NVM_IS_12_LTS_OR_ABOVE -eq 0 ] || {
				[ $NVM_IS_13_OR_ABOVE -eq 1 ] && [ $NVM_IS_14_LTS_OR_ABOVE -eq 0 ]
			} || {
				[ $NVM_IS_15_OR_ABOVE -eq 1 ] && [ $NVM_IS_16_OR_ABOVE -eq 0 ]
			}
		then
			nvm_echo '* `npm` `v7.x` is the last version that works on `node` `v13`, `v15`, below `v12.13`, or `v14.0` - `v14.15`'
			$NVM_NPM_CMD install -g npm@7
		elif {
				[ $NVM_IS_12_LTS_OR_ABOVE -eq 1 ] && [ $NVM_IS_13_OR_ABOVE -eq 0 ]
			} || {
				[ $NVM_IS_14_LTS_OR_ABOVE -eq 1 ] && [ $NVM_IS_14_17_OR_ABOVE -eq 0 ]
			} || {
				[ $NVM_IS_16_OR_ABOVE -eq 1 ] && [ $NVM_IS_16_LTS_OR_ABOVE -eq 0 ]
			} || {
				[ $NVM_IS_17_OR_ABOVE -eq 1 ] && [ $NVM_IS_18_OR_ABOVE -eq 0 ]
			}
		then
			nvm_echo '* `npm` `v8.6` is the last version that works on `node` `v12`, `v14.13` - `v14.16`, or `v16.0` - `v16.12`'
			$NVM_NPM_CMD install -g npm@8.6
		elif [ $NVM_IS_18_17_OR_ABOVE -eq 0 ] || {
				[ $NVM_IS_19_OR_ABOVE -eq 1 ] && [ $NVM_IS_20_5_OR_ABOVE -eq 0 ]
			}
		then
			nvm_echo '* `npm` `v9.x` is the last version that works on `node` `< v18.17`, `v19`, or `v20.0` - `v20.4`'
			$NVM_NPM_CMD install -g npm@9
		elif [ $NVM_IS_20_17_OR_ABOVE -eq 0 ] || {
				[ $NVM_IS_21_OR_ABOVE -eq 1 ] && [ $NVM_IS_22_9_OR_ABOVE -eq 0 ]
			}
		then
			nvm_echo '* `npm` `v10.x` is the last version that works on `node` `< v20.17`, `v21`, or `v22.0` - `v22.8`'
			$NVM_NPM_CMD install -g npm@10
		else
			nvm_echo '* Installing latest `npm`; if this does not work on your node version, please report a bug!'
			$NVM_NPM_CMD install -g npm
		fi
	fi
	nvm_echo "* npm upgraded to: v$(npm --version 2>/dev/null)"
}
nvm_install_npm_if_needed () {
	local VERSION
	VERSION="$(nvm_ls_current)" 
	if ! nvm_has "npm"
	then
		nvm_echo 'Installing npm...'
		if nvm_version_greater 0.2.0 "${VERSION}"
		then
			nvm_err 'npm requires node v0.2.3 or higher'
		elif nvm_version_greater_than_or_equal_to "${VERSION}" 0.2.0
		then
			if nvm_version_greater 0.2.3 "${VERSION}"
			then
				nvm_err 'npm requires node v0.2.3 or higher'
			else
				nvm_download -L https://npmjs.org/install.sh -o - | clean=yes npm_install=0.2.19 sh
			fi
		else
			nvm_download -L https://npmjs.org/install.sh -o - | clean=yes sh
		fi
	fi
	return $?
}
nvm_install_source () {
	local FLAVOR
	case "${1-}" in
		(node | iojs) FLAVOR="${1}"  ;;
		(*) nvm_err 'supported flavors: node, iojs'
			return 4 ;;
	esac
	local TYPE
	TYPE="${2-}" 
	local PREFIXED_VERSION
	PREFIXED_VERSION="${3-}" 
	if [ -z "${PREFIXED_VERSION}" ]
	then
		nvm_err 'A version number is required.'
		return 3
	fi
	local VERSION
	VERSION="$(nvm_strip_iojs_prefix "${PREFIXED_VERSION}")" 
	local NVM_MAKE_JOBS
	NVM_MAKE_JOBS="${4-}" 
	local ADDITIONAL_PARAMETERS
	ADDITIONAL_PARAMETERS="${5-}" 
	local NVM_ARCH
	NVM_ARCH="$(nvm_get_arch)" 
	if [ "${NVM_ARCH}" = 'armv6l' ] || [ "${NVM_ARCH}" = 'armv7l' ]
	then
		if [ -n "${ADDITIONAL_PARAMETERS}" ]
		then
			ADDITIONAL_PARAMETERS="--without-snapshot ${ADDITIONAL_PARAMETERS}" 
		else
			ADDITIONAL_PARAMETERS='--without-snapshot' 
		fi
	fi
	if [ -n "${ADDITIONAL_PARAMETERS}" ]
	then
		nvm_echo "Additional options while compiling: ${ADDITIONAL_PARAMETERS}"
	fi
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	local make
	make='make' 
	local MAKE_CXX
	case "${NVM_OS}" in
		('freebsd' | 'openbsd') make='gmake' 
			MAKE_CXX="CC=${CC:-cc} CXX=${CXX:-c++}"  ;;
		('darwin') MAKE_CXX="CC=${CC:-cc} CXX=${CXX:-c++}"  ;;
		('aix') make='gmake'  ;;
	esac
	if nvm_has "clang++" && nvm_has "clang" && nvm_version_greater_than_or_equal_to "$(nvm_clang_version)" 3.5
	then
		if [ -z "${CC-}" ] || [ -z "${CXX-}" ]
		then
			nvm_echo "Clang v3.5+ detected! CC or CXX not specified, will use Clang as C/C++ compiler!"
			MAKE_CXX="CC=${CC:-cc} CXX=${CXX:-c++}" 
		fi
	fi
	local TARBALL
	local TMPDIR
	local VERSION_PATH
	if [ "${NVM_NO_PROGRESS-}" = "1" ]
	then
		PROGRESS_BAR="-sS" 
	else
		PROGRESS_BAR="--progress-bar" 
	fi
	nvm_is_zsh && setopt local_options shwordsplit
	TARBALL="$(PROGRESS_BAR="${PROGRESS_BAR}" nvm_download_artifact "${FLAVOR}" source "${TYPE}" "${VERSION}" | command tail -1)"  && [ -f "${TARBALL}" ] && TMPDIR="$(dirname "${TARBALL}")/files"  && if ! (
			command mkdir -p "${TMPDIR}" && nvm_extract_tarball "${NVM_OS}" "${VERSION}" "${TARBALL}" "${TMPDIR}" && VERSION_PATH="$(nvm_version_path "${PREFIXED_VERSION}")"  && nvm_cd "${TMPDIR}" && nvm_echo '$>'./configure --prefix="${VERSION_PATH}" $ADDITIONAL_PARAMETERS'<' && ./configure --prefix="${VERSION_PATH}" $ADDITIONAL_PARAMETERS && $make -j "${NVM_MAKE_JOBS}" ${MAKE_CXX-} && command rm -f "${VERSION_PATH}" 2> /dev/null && $make -j "${NVM_MAKE_JOBS}" ${MAKE_CXX-} install
		)
	then
		nvm_err "nvm: install ${VERSION} failed!"
		command rm -rf "${TMPDIR-}"
		return 1
	fi
}
nvm_iojs_prefix () {
	nvm_echo 'iojs'
}
nvm_iojs_version_has_solaris_binary () {
	local IOJS_VERSION
	IOJS_VERSION="$1" 
	local STRIPPED_IOJS_VERSION
	STRIPPED_IOJS_VERSION="$(nvm_strip_iojs_prefix "${IOJS_VERSION}")" 
	if [ "_${STRIPPED_IOJS_VERSION}" = "${IOJS_VERSION}" ]
	then
		return 1
	fi
	nvm_version_greater_than_or_equal_to "${STRIPPED_IOJS_VERSION}" v3.3.1
}
nvm_is_alias () {
	\alias "${1-}" > /dev/null 2>&1
}
nvm_is_iojs_version () {
	case "${1-}" in
		(iojs-*) return 0 ;;
	esac
	return 1
}
nvm_is_merged_node_version () {
	nvm_version_greater_than_or_equal_to "$1" v4.0.0
}
nvm_is_natural_num () {
	if [ -z "$1" ]
	then
		return 4
	fi
	case "$1" in
		(0) return 1 ;;
		(-*) return 3 ;;
		(*) [ "$1" -eq "$1" ] 2> /dev/null ;;
	esac
}
nvm_is_valid_version () {
	if nvm_validate_implicit_alias "${1-}" 2> /dev/null
	then
		return 0
	fi
	case "${1-}" in
		("$(nvm_iojs_prefix)" | "$(nvm_node_prefix)") return 0 ;;
		(*) local VERSION
			VERSION="$(nvm_strip_iojs_prefix "${1-}")" 
			nvm_version_greater_than_or_equal_to "${VERSION}" 0 ;;
	esac
}
nvm_is_version_installed () {
	if [ -z "${1-}" ]
	then
		return 1
	fi
	local NVM_NODE_BINARY
	NVM_NODE_BINARY='node' 
	if [ "_$(nvm_get_os)" = '_win' ]
	then
		NVM_NODE_BINARY='node.exe' 
	fi
	if [ -x "$(nvm_version_path "$1" 2>/dev/null)/bin/${NVM_NODE_BINARY}" ]
	then
		return 0
	fi
	return 1
}
nvm_is_zsh () {
	[ -n "${ZSH_VERSION-}" ]
}
nvm_list_aliases () {
	local ALIAS
	ALIAS="${1-}" 
	local NVM_CURRENT
	NVM_CURRENT="$(nvm_ls_current)" 
	local NVM_ALIAS_DIR
	NVM_ALIAS_DIR="$(nvm_alias_path)" 
	command mkdir -p "${NVM_ALIAS_DIR}/lts"
	if [ "${ALIAS}" != "${ALIAS#lts/}" ]
	then
		nvm_alias "${ALIAS}"
		return $?
	fi
	nvm_is_zsh && unsetopt local_options nomatch
	(
		local ALIAS_PATH
		for ALIAS_PATH in "${NVM_ALIAS_DIR}/${ALIAS}"*
		do
			NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_CURRENT="${NVM_CURRENT}" nvm_print_alias_path "${NVM_ALIAS_DIR}" "${ALIAS_PATH}" &
		done
		wait
	) | command sort
	(
		local ALIAS_NAME
		for ALIAS_NAME in "$(nvm_node_prefix)" "stable" "unstable" "$(nvm_iojs_prefix)"
		do
			{
				if [ ! -f "${NVM_ALIAS_DIR}/${ALIAS_NAME}" ] && {
						[ -z "${ALIAS}" ] || [ "${ALIAS_NAME}" = "${ALIAS}" ]
					}
				then
					NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_CURRENT="${NVM_CURRENT}" nvm_print_default_alias "${ALIAS_NAME}"
				fi
			} &
		done
		wait
	) | command sort
	(
		local LTS_ALIAS
		for ALIAS_PATH in "${NVM_ALIAS_DIR}/lts/${ALIAS}"*
		do
			{
				LTS_ALIAS="$(NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_LTS=true nvm_print_alias_path "${NVM_ALIAS_DIR}" "${ALIAS_PATH}")" 
				if [ -n "${LTS_ALIAS}" ]
				then
					nvm_echo "${LTS_ALIAS}"
				fi
			} &
		done
		wait
	) | command sort
	return
}
nvm_ls () {
	local PATTERN
	PATTERN="${1-}" 
	local VERSIONS
	VERSIONS='' 
	if [ "${PATTERN}" = 'current' ]
	then
		nvm_ls_current
		return
	fi
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	local NVM_NODE_PREFIX
	NVM_NODE_PREFIX="$(nvm_node_prefix)" 
	local NVM_VERSION_DIR_IOJS
	NVM_VERSION_DIR_IOJS="$(nvm_version_dir "${NVM_IOJS_PREFIX}")" 
	local NVM_VERSION_DIR_NEW
	NVM_VERSION_DIR_NEW="$(nvm_version_dir new)" 
	local NVM_VERSION_DIR_OLD
	NVM_VERSION_DIR_OLD="$(nvm_version_dir old)" 
	case "${PATTERN}" in
		("${NVM_IOJS_PREFIX}" | "${NVM_NODE_PREFIX}") PATTERN="${PATTERN}-"  ;;
		(*) if nvm_resolve_local_alias "${PATTERN}"
			then
				return
			fi
			PATTERN="$(nvm_ensure_version_prefix "${PATTERN}")"  ;;
	esac
	if [ "${PATTERN}" = 'N/A' ]
	then
		return
	fi
	local NVM_PATTERN_STARTS_WITH_V
	case $PATTERN in
		(v*) NVM_PATTERN_STARTS_WITH_V=true  ;;
		(*) NVM_PATTERN_STARTS_WITH_V=false  ;;
	esac
	if [ $NVM_PATTERN_STARTS_WITH_V = true ] && [ "_$(nvm_num_version_groups "${PATTERN}")" = "_3" ]
	then
		if nvm_is_version_installed "${PATTERN}"
		then
			VERSIONS="${PATTERN}" 
		elif nvm_is_version_installed "$(nvm_add_iojs_prefix "${PATTERN}")"
		then
			VERSIONS="$(nvm_add_iojs_prefix "${PATTERN}")" 
		fi
	else
		case "${PATTERN}" in
			("${NVM_IOJS_PREFIX}-" | "${NVM_NODE_PREFIX}-" | "system")  ;;
			(*) local NUM_VERSION_GROUPS
				NUM_VERSION_GROUPS="$(nvm_num_version_groups "${PATTERN}")" 
				if [ "${NUM_VERSION_GROUPS}" = "2" ] || [ "${NUM_VERSION_GROUPS}" = "1" ]
				then
					PATTERN="${PATTERN%.}." 
				fi ;;
		esac
		nvm_is_zsh && setopt local_options shwordsplit
		nvm_is_zsh && unsetopt local_options markdirs
		local NVM_DIRS_TO_SEARCH1
		NVM_DIRS_TO_SEARCH1='' 
		local NVM_DIRS_TO_SEARCH2
		NVM_DIRS_TO_SEARCH2='' 
		local NVM_DIRS_TO_SEARCH3
		NVM_DIRS_TO_SEARCH3='' 
		local NVM_ADD_SYSTEM
		NVM_ADD_SYSTEM=false 
		if nvm_is_iojs_version "${PATTERN}"
		then
			NVM_DIRS_TO_SEARCH1="${NVM_VERSION_DIR_IOJS}" 
			PATTERN="$(nvm_strip_iojs_prefix "${PATTERN}")" 
			if nvm_has_system_iojs
			then
				NVM_ADD_SYSTEM=true 
			fi
		elif [ "${PATTERN}" = "${NVM_NODE_PREFIX}-" ]
		then
			NVM_DIRS_TO_SEARCH1="${NVM_VERSION_DIR_OLD}" 
			NVM_DIRS_TO_SEARCH2="${NVM_VERSION_DIR_NEW}" 
			PATTERN='' 
			if nvm_has_system_node
			then
				NVM_ADD_SYSTEM=true 
			fi
		else
			NVM_DIRS_TO_SEARCH1="${NVM_VERSION_DIR_OLD}" 
			NVM_DIRS_TO_SEARCH2="${NVM_VERSION_DIR_NEW}" 
			NVM_DIRS_TO_SEARCH3="${NVM_VERSION_DIR_IOJS}" 
			if nvm_has_system_iojs || nvm_has_system_node
			then
				NVM_ADD_SYSTEM=true 
			fi
		fi
		if ! [ -d "${NVM_DIRS_TO_SEARCH1}" ] || ! (
				command ls -1qA "${NVM_DIRS_TO_SEARCH1}" | nvm_grep -q .
			)
		then
			NVM_DIRS_TO_SEARCH1='' 
		fi
		if ! [ -d "${NVM_DIRS_TO_SEARCH2}" ] || ! (
				command ls -1qA "${NVM_DIRS_TO_SEARCH2}" | nvm_grep -q .
			)
		then
			NVM_DIRS_TO_SEARCH2="${NVM_DIRS_TO_SEARCH1}" 
		fi
		if ! [ -d "${NVM_DIRS_TO_SEARCH3}" ] || ! (
				command ls -1qA "${NVM_DIRS_TO_SEARCH3}" | nvm_grep -q .
			)
		then
			NVM_DIRS_TO_SEARCH3="${NVM_DIRS_TO_SEARCH2}" 
		fi
		local SEARCH_PATTERN
		if [ -z "${PATTERN}" ]
		then
			PATTERN='v' 
			SEARCH_PATTERN='.*' 
		else
			SEARCH_PATTERN="$(nvm_echo "${PATTERN}" | command sed 's#\.#\\\.#g;')" 
		fi
		if [ -n "${NVM_DIRS_TO_SEARCH1}${NVM_DIRS_TO_SEARCH2}${NVM_DIRS_TO_SEARCH3}" ]
		then
			VERSIONS="$(command find "${NVM_DIRS_TO_SEARCH1}"/* "${NVM_DIRS_TO_SEARCH2}"/* "${NVM_DIRS_TO_SEARCH3}"/* -name . -o -type d -prune -o -path "${PATTERN}*" \
        | command sed -e "
            s#${NVM_VERSION_DIR_IOJS}/#versions/${NVM_IOJS_PREFIX}/#;
            s#^${NVM_DIR}/##;
            \\#^[^v]# d;
            \\#^versions\$# d;
            s#^versions/##;
            s#^v#${NVM_NODE_PREFIX}/v#;
            \\#${SEARCH_PATTERN}# !d;
          " \
          -e 's#^\([^/]\{1,\}\)/\(.*\)$#\2.\1#;' \
        | command sort -t. -u -k 1.2,1n -k 2,2n -k 3,3n \
        | command sed -e 's#\(.*\)\.\([^\.]\{1,\}\)$#\2-\1#;' \
                      -e "s#^${NVM_NODE_PREFIX}-##;" \
      )" 
		fi
	fi
	if [ "${NVM_ADD_SYSTEM-}" = true ]
	then
		case "${PATTERN}" in
			('' | v) VERSIONS="${VERSIONS}
system"  ;;
			(system) VERSIONS="system"  ;;
		esac
	fi
	if [ -z "${VERSIONS}" ]
	then
		nvm_echo 'N/A'
		return 3
	fi
	nvm_echo "${VERSIONS}"
}
nvm_ls_current () {
	local NVM_LS_CURRENT_NODE_PATH
	if ! NVM_LS_CURRENT_NODE_PATH="$(command which node 2>/dev/null)" 
	then
		nvm_echo 'none'
	elif nvm_tree_contains_path "$(nvm_version_dir iojs)" "${NVM_LS_CURRENT_NODE_PATH}"
	then
		nvm_add_iojs_prefix "$(iojs --version 2>/dev/null)"
	elif nvm_tree_contains_path "${NVM_DIR}" "${NVM_LS_CURRENT_NODE_PATH}"
	then
		local VERSION
		VERSION="$(node --version 2>/dev/null)" 
		if [ "${VERSION}" = "v0.6.21-pre" ]
		then
			nvm_echo 'v0.6.21'
		else
			nvm_echo "${VERSION:-none}"
		fi
	else
		nvm_echo 'system'
	fi
}
nvm_ls_remote () {
	local PATTERN
	PATTERN="${1-}" 
	if nvm_validate_implicit_alias "${PATTERN}" 2> /dev/null
	then
		local IMPLICIT
		IMPLICIT="$(nvm_print_implicit_alias remote "${PATTERN}")" 
		if [ -z "${IMPLICIT-}" ] || [ "${IMPLICIT}" = 'N/A' ]
		then
			nvm_echo "N/A"
			return 3
		fi
		PATTERN="$(NVM_LTS="${NVM_LTS-}" nvm_ls_remote "${IMPLICIT}" | command tail -1 | command awk '{ print $1 }')" 
	elif [ -n "${PATTERN}" ]
	then
		PATTERN="$(nvm_ensure_version_prefix "${PATTERN}")" 
	else
		PATTERN=".*" 
	fi
	NVM_LTS="${NVM_LTS-}" nvm_ls_remote_index_tab node std "${PATTERN}"
}
nvm_ls_remote_index_tab () {
	local LTS
	LTS="${NVM_LTS-}" 
	if [ "$#" -lt 3 ]
	then
		nvm_err 'not enough arguments'
		return 5
	fi
	local FLAVOR
	FLAVOR="${1-}" 
	local TYPE
	TYPE="${2-}" 
	local MIRROR
	MIRROR="$(nvm_get_mirror "${FLAVOR}" "${TYPE}")" 
	if [ -z "${MIRROR}" ]
	then
		return 3
	fi
	local PREFIX
	PREFIX='' 
	case "${FLAVOR}-${TYPE}" in
		(iojs-std) PREFIX="$(nvm_iojs_prefix)-"  ;;
		(node-std) PREFIX=''  ;;
		(iojs-*) nvm_err 'unknown type of io.js release'
			return 4 ;;
		(*) nvm_err 'unknown type of node.js release'
			return 4 ;;
	esac
	local SORT_COMMAND
	SORT_COMMAND='command sort' 
	case "${FLAVOR}" in
		(node) SORT_COMMAND='command sort -t. -u -k 1.2,1n -k 2,2n -k 3,3n'  ;;
	esac
	local PATTERN
	PATTERN="${3-}" 
	if [ "${PATTERN#"${PATTERN%?}"}" = '.' ]
	then
		PATTERN="${PATTERN%.}" 
	fi
	local VERSIONS
	if [ -n "${PATTERN}" ] && [ "${PATTERN}" != '*' ]
	then
		if [ "${FLAVOR}" = 'iojs' ]
		then
			PATTERN="$(nvm_ensure_version_prefix "$(nvm_strip_iojs_prefix "${PATTERN}")")" 
		else
			PATTERN="$(nvm_ensure_version_prefix "${PATTERN}")" 
		fi
	else
		unset PATTERN
	fi
	nvm_is_zsh && setopt local_options shwordsplit
	local VERSION_LIST
	VERSION_LIST="$(nvm_download -L -s "${MIRROR}/index.tab" -o - \
    | command sed "
        1d;
        s/^/${PREFIX}/;
      " \
  )" 
	local LTS_ALIAS
	local LTS_VERSION
	command mkdir -p "$(nvm_alias_path)/lts"
	{
		command awk '{
        if ($10 ~ /^\-?$/) { next }
        if ($10 && !a[tolower($10)]++) {
          if (alias) { print alias, version }
          alias_name = "lts/" tolower($10)
          if (!alias) { print "lts/*", alias_name }
          alias = alias_name
          version = $1
        }
      }
      END {
        if (alias) {
          print alias, version
        }
      }' | while read -r LTS_ALIAS_LINE
		do
			LTS_ALIAS="${LTS_ALIAS_LINE%% *}" 
			LTS_VERSION="${LTS_ALIAS_LINE#* }" 
			nvm_make_alias "${LTS_ALIAS}" "${LTS_VERSION}" > /dev/null 2>&1
		done
	} <<EOF
$VERSION_LIST
EOF
	if [ -n "${LTS-}" ]
	then
		if ! LTS="$(nvm_normalize_lts "lts/${LTS}")" 
		then
			return $?
		fi
		LTS="${LTS#lts/}" 
	fi
	VERSIONS="$( { command awk -v lts="${LTS-}" '{
        if (!$1) { next }
        if (lts && $10 ~ /^\-?$/) { next }
        if (lts && lts != "*" && tolower($10) !~ tolower(lts)) { next }
        if ($10 !~ /^\-?$/) {
          if ($10 && $10 != prev) {
            print $1, $10, "*"
          } else {
            print $1, $10
          }
        } else {
          print $1
        }
        prev=$10;
      }' \
    | nvm_grep -w "${PATTERN:-.*}" \
    | $SORT_COMMAND; } << EOF
$VERSION_LIST
EOF
)" 
	if [ -z "${VERSIONS}" ]
	then
		nvm_echo 'N/A'
		return 3
	fi
	nvm_echo "${VERSIONS}"
}
nvm_ls_remote_iojs () {
	NVM_LTS="${NVM_LTS-}" nvm_ls_remote_index_tab iojs std "${1-}"
}
nvm_make_alias () {
	local ALIAS
	ALIAS="${1-}" 
	if [ -z "${ALIAS}" ]
	then
		nvm_err "an alias name is required"
		return 1
	fi
	local VERSION
	VERSION="${2-}" 
	if [ -z "${VERSION}" ]
	then
		nvm_err "an alias target version is required"
		return 2
	fi
	nvm_echo "${VERSION}" | tee "$(nvm_alias_path)/${ALIAS}" > /dev/null
}
nvm_match_version () {
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	local PROVIDED_VERSION
	PROVIDED_VERSION="$1" 
	case "_${PROVIDED_VERSION}" in
		("_${NVM_IOJS_PREFIX}" | '_io.js') nvm_version "${NVM_IOJS_PREFIX}" ;;
		('_system') nvm_echo 'system' ;;
		(*) nvm_version "${PROVIDED_VERSION}" ;;
	esac
}
nvm_node_prefix () {
	nvm_echo 'node'
}
nvm_node_version_has_solaris_binary () {
	local NODE_VERSION
	NODE_VERSION="$1" 
	local STRIPPED_IOJS_VERSION
	STRIPPED_IOJS_VERSION="$(nvm_strip_iojs_prefix "${NODE_VERSION}")" 
	if [ "_${STRIPPED_IOJS_VERSION}" != "_${NODE_VERSION}" ]
	then
		return 1
	fi
	nvm_version_greater_than_or_equal_to "${NODE_VERSION}" v0.8.6 && ! nvm_version_greater_than_or_equal_to "${NODE_VERSION}" v1.0.0
}
nvm_normalize_lts () {
	local LTS
	LTS="${1-}" 
	case "${LTS}" in
		(lts/-[123456789] | lts/-[123456789][0123456789]*) local N
			N="$(echo "${LTS}" | cut -d '-' -f 2)" 
			N=$((N+1)) 
			if [ $? -ne 0 ]
			then
				nvm_echo "${LTS}"
				return 0
			fi
			local NVM_ALIAS_DIR
			NVM_ALIAS_DIR="$(nvm_alias_path)" 
			local RESULT
			RESULT="$(command ls "${NVM_ALIAS_DIR}/lts" | command tail -n "${N}" | command head -n 1)" 
			if [ "${RESULT}" != '*' ]
			then
				nvm_echo "lts/${RESULT}"
			else
				nvm_err 'That many LTS releases do not exist yet.'
				return 2
			fi ;;
		(*) if [ "${LTS}" != "$(echo "${LTS}" | command tr '[:upper:]' '[:lower:]')" ]
			then
				nvm_err 'LTS names must be lowercase'
				return 3
			fi
			nvm_echo "${LTS}" ;;
	esac
}
nvm_normalize_version () {
	command awk 'BEGIN {
    split(ARGV[1], a, /\./);
    printf "%d%06d%06d\n", a[1], a[2], a[3];
    exit;
  }' "${1#v}"
}
nvm_npm_global_modules () {
	local NPMLIST
	local VERSION
	VERSION="$1" 
	NPMLIST=$(nvm use "${VERSION}" >/dev/null && npm list -g --depth=0 2>/dev/null | command sed -e '1d' -e '/UNMET PEER DEPENDENCY/d') 
	local INSTALLS
	INSTALLS=$(nvm_echo "${NPMLIST}" | command sed -e '/ -> / d' -e '/\(empty\)/ d' -e 's/^.* \(.*@[^ ]*\).*/\1/' -e '/^npm@[^ ]*.*$/ d' -e '/^corepack@[^ ]*.*$/ d' | command xargs) 
	local LINKS
	LINKS="$(nvm_echo "${NPMLIST}" | command sed -n 's/.* -> \(.*\)/\1/ p')" 
	nvm_echo "${INSTALLS} //// ${LINKS}"
}
nvm_npmrc_bad_news_bears () {
	local NVM_NPMRC
	NVM_NPMRC="${1-}" 
	if [ -n "${NVM_NPMRC}" ] && [ -f "${NVM_NPMRC}" ] && nvm_grep -Ee '^(prefix|globalconfig) *=' < "${NVM_NPMRC}" > /dev/null
	then
		return 0
	fi
	return 1
}
nvm_num_version_groups () {
	local VERSION
	VERSION="${1-}" 
	VERSION="${VERSION#v}" 
	VERSION="${VERSION%.}" 
	if [ -z "${VERSION}" ]
	then
		nvm_echo "0"
		return
	fi
	local NVM_NUM_DOTS
	NVM_NUM_DOTS=$(nvm_echo "${VERSION}" | command sed -e 's/[^\.]//g') 
	local NVM_NUM_GROUPS
	NVM_NUM_GROUPS=".${NVM_NUM_DOTS}" 
	nvm_echo "${#NVM_NUM_GROUPS}"
}
nvm_nvmrc_invalid_msg () {
	local error_text
	error_text="invalid .nvmrc!
all non-commented content (anything after # is a comment) must be either:
  - a single bare nvm-recognized version-ish
  - or, multiple distinct key-value pairs, each key/value separated by a single equals sign (=)

additionally, a single bare nvm-recognized version-ish must be present (after stripping comments)." 
	local warn_text
	warn_text="non-commented content parsed:
${1}" 
	nvm_err "$(nvm_wrap_with_color_code 'r' "${error_text}")

$(nvm_wrap_with_color_code 'y' "${warn_text}")"
}
nvm_print_alias_path () {
	local NVM_ALIAS_DIR
	NVM_ALIAS_DIR="${1-}" 
	if [ -z "${NVM_ALIAS_DIR}" ]
	then
		nvm_err 'An alias dir is required.'
		return 1
	fi
	local ALIAS_PATH
	ALIAS_PATH="${2-}" 
	if [ -z "${ALIAS_PATH}" ]
	then
		nvm_err 'An alias path is required.'
		return 2
	fi
	local ALIAS
	ALIAS="${ALIAS_PATH##"${NVM_ALIAS_DIR}"\/}" 
	local DEST
	DEST="$(nvm_alias "${ALIAS}" 2>/dev/null)"  || :
	if [ -n "${DEST}" ]
	then
		NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_LTS="${NVM_LTS-}" DEFAULT=false nvm_print_formatted_alias "${ALIAS}" "${DEST}"
	fi
}
nvm_print_color_code () {
	case "${1-}" in
		('0') return 0 ;;
		('r') nvm_echo '0;31m' ;;
		('R') nvm_echo '1;31m' ;;
		('g') nvm_echo '0;32m' ;;
		('G') nvm_echo '1;32m' ;;
		('b') nvm_echo '0;34m' ;;
		('B') nvm_echo '1;34m' ;;
		('c') nvm_echo '0;36m' ;;
		('C') nvm_echo '1;36m' ;;
		('m') nvm_echo '0;35m' ;;
		('M') nvm_echo '1;35m' ;;
		('y') nvm_echo '0;33m' ;;
		('Y') nvm_echo '1;33m' ;;
		('k') nvm_echo '0;30m' ;;
		('K') nvm_echo '1;30m' ;;
		('e') nvm_echo '0;37m' ;;
		('W') nvm_echo '1;37m' ;;
		(*) nvm_err "Invalid color code: ${1-}"
			return 1 ;;
	esac
}
nvm_print_default_alias () {
	local ALIAS
	ALIAS="${1-}" 
	if [ -z "${ALIAS}" ]
	then
		nvm_err 'A default alias is required.'
		return 1
	fi
	local DEST
	DEST="$(nvm_print_implicit_alias local "${ALIAS}")" 
	if [ -n "${DEST}" ]
	then
		NVM_NO_COLORS="${NVM_NO_COLORS-}" DEFAULT=true nvm_print_formatted_alias "${ALIAS}" "${DEST}"
	fi
}
nvm_print_formatted_alias () {
	local ALIAS
	ALIAS="${1-}" 
	local DEST
	DEST="${2-}" 
	local VERSION
	VERSION="${3-}" 
	if [ -z "${VERSION}" ]
	then
		VERSION="$(nvm_version "${DEST}")"  || :
	fi
	local VERSION_FORMAT
	local ALIAS_FORMAT
	local DEST_FORMAT
	local INSTALLED_COLOR
	local SYSTEM_COLOR
	local CURRENT_COLOR
	local NOT_INSTALLED_COLOR
	local DEFAULT_COLOR
	local LTS_COLOR
	INSTALLED_COLOR=$(nvm_get_colors 1) 
	SYSTEM_COLOR=$(nvm_get_colors 2) 
	CURRENT_COLOR=$(nvm_get_colors 3) 
	NOT_INSTALLED_COLOR=$(nvm_get_colors 4) 
	DEFAULT_COLOR=$(nvm_get_colors 5) 
	LTS_COLOR=$(nvm_get_colors 6) 
	ALIAS_FORMAT='%s' 
	DEST_FORMAT='%s' 
	VERSION_FORMAT='%s' 
	local NEWLINE
	NEWLINE='\n' 
	if [ "_${DEFAULT}" = '_true' ]
	then
		NEWLINE=' (default)\n' 
	fi
	local ARROW
	ARROW='->' 
	if nvm_has_colors
	then
		ARROW='\033[0;90m->\033[0m' 
		if [ "_${DEFAULT}" = '_true' ]
		then
			NEWLINE=" \033[${DEFAULT_COLOR}(default)\033[0m\n" 
		fi
		if [ "_${VERSION}" = "_${NVM_CURRENT-}" ]
		then
			ALIAS_FORMAT="\033[${CURRENT_COLOR}%s\033[0m" 
			DEST_FORMAT="\033[${CURRENT_COLOR}%s\033[0m" 
			VERSION_FORMAT="\033[${CURRENT_COLOR}%s\033[0m" 
		elif nvm_is_version_installed "${VERSION}"
		then
			ALIAS_FORMAT="\033[${INSTALLED_COLOR}%s\033[0m" 
			DEST_FORMAT="\033[${INSTALLED_COLOR}%s\033[0m" 
			VERSION_FORMAT="\033[${INSTALLED_COLOR}%s\033[0m" 
		elif [ "${VERSION}" = '∞' ] || [ "${VERSION}" = 'N/A' ]
		then
			ALIAS_FORMAT="\033[${NOT_INSTALLED_COLOR}%s\033[0m" 
			DEST_FORMAT="\033[${NOT_INSTALLED_COLOR}%s\033[0m" 
			VERSION_FORMAT="\033[${NOT_INSTALLED_COLOR}%s\033[0m" 
		fi
		if [ "_${NVM_LTS-}" = '_true' ]
		then
			ALIAS_FORMAT="\033[${LTS_COLOR}%s\033[0m" 
		fi
		if [ "_${DEST%/*}" = "_lts" ]
		then
			DEST_FORMAT="\033[${LTS_COLOR}%s\033[0m" 
		fi
	elif [ "_${VERSION}" != '_∞' ] && [ "_${VERSION}" != '_N/A' ]
	then
		VERSION_FORMAT='%s *' 
	fi
	if [ "${DEST}" = "${VERSION}" ]
	then
		command printf -- "${ALIAS_FORMAT} ${ARROW} ${VERSION_FORMAT}${NEWLINE}" "${ALIAS}" "${DEST}"
	else
		command printf -- "${ALIAS_FORMAT} ${ARROW} ${DEST_FORMAT} (${ARROW} ${VERSION_FORMAT})${NEWLINE}" "${ALIAS}" "${DEST}" "${VERSION}"
	fi
}
nvm_print_implicit_alias () {
	if [ "_$1" != "_local" ] && [ "_$1" != "_remote" ]
	then
		nvm_err "nvm_print_implicit_alias must be specified with local or remote as the first argument."
		return 1
	fi
	local NVM_IMPLICIT
	NVM_IMPLICIT="$2" 
	if ! nvm_validate_implicit_alias "${NVM_IMPLICIT}"
	then
		return 2
	fi
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	local NVM_NODE_PREFIX
	NVM_NODE_PREFIX="$(nvm_node_prefix)" 
	local NVM_COMMAND
	local NVM_ADD_PREFIX_COMMAND
	local LAST_TWO
	case "${NVM_IMPLICIT}" in
		("${NVM_IOJS_PREFIX}") NVM_COMMAND="nvm_ls_remote_iojs" 
			NVM_ADD_PREFIX_COMMAND="nvm_add_iojs_prefix" 
			if [ "_$1" = "_local" ]
			then
				NVM_COMMAND="nvm_ls ${NVM_IMPLICIT}" 
			fi
			nvm_is_zsh && setopt local_options shwordsplit
			local NVM_IOJS_VERSION
			local EXIT_CODE
			NVM_IOJS_VERSION="$(${NVM_COMMAND})"  && :
			EXIT_CODE="$?" 
			if [ "_${EXIT_CODE}" = "_0" ]
			then
				NVM_IOJS_VERSION="$(nvm_echo "${NVM_IOJS_VERSION}" | command sed "s/^${NVM_IMPLICIT}-//" | nvm_grep -e '^v' | command cut -c2- | command cut -d . -f 1,2 | uniq | command tail -1)" 
			fi
			if [ "_$NVM_IOJS_VERSION" = "_N/A" ]
			then
				nvm_echo 'N/A'
			else
				${NVM_ADD_PREFIX_COMMAND} "${NVM_IOJS_VERSION}"
			fi
			return $EXIT_CODE ;;
		("${NVM_NODE_PREFIX}") nvm_echo 'stable'
			return ;;
		(*) NVM_COMMAND="nvm_ls_remote" 
			if [ "_$1" = "_local" ]
			then
				NVM_COMMAND="nvm_ls node" 
			fi
			nvm_is_zsh && setopt local_options shwordsplit
			LAST_TWO=$($NVM_COMMAND | nvm_grep -e '^v' | command cut -c2- | command cut -d . -f 1,2 | uniq)  ;;
	esac
	local MINOR
	local STABLE
	local UNSTABLE
	local MOD
	local NORMALIZED_VERSION
	nvm_is_zsh && setopt local_options shwordsplit
	for MINOR in $LAST_TWO
	do
		NORMALIZED_VERSION="$(nvm_normalize_version "$MINOR")" 
		if [ "_0${NORMALIZED_VERSION#?}" != "_$NORMALIZED_VERSION" ]
		then
			STABLE="$MINOR" 
		else
			MOD="$(awk 'BEGIN { print int(ARGV[1] / 1000000) % 2 ; exit(0) }' "${NORMALIZED_VERSION}")" 
			if [ "${MOD}" -eq 0 ]
			then
				STABLE="${MINOR}" 
			elif [ "${MOD}" -eq 1 ]
			then
				UNSTABLE="${MINOR}" 
			fi
		fi
	done
	if [ "_$2" = '_stable' ]
	then
		nvm_echo "${STABLE}"
	elif [ "_$2" = '_unstable' ]
	then
		nvm_echo "${UNSTABLE:-"N/A"}"
	fi
}
nvm_print_npm_version () {
	if nvm_has "npm"
	then
		local NPM_VERSION
		NPM_VERSION="$(npm --version 2>/dev/null)" 
		if [ -n "${NPM_VERSION}" ]
		then
			command printf " (npm v${NPM_VERSION})"
		fi
	fi
}
nvm_print_versions () {
	local NVM_CURRENT
	NVM_CURRENT=$(nvm_ls_current) 
	local INSTALLED_COLOR
	local SYSTEM_COLOR
	local CURRENT_COLOR
	local NOT_INSTALLED_COLOR
	local DEFAULT_COLOR
	local LTS_COLOR
	local NVM_HAS_COLORS
	NVM_HAS_COLORS=0 
	INSTALLED_COLOR=$(nvm_get_colors 1) 
	SYSTEM_COLOR=$(nvm_get_colors 2) 
	CURRENT_COLOR=$(nvm_get_colors 3) 
	NOT_INSTALLED_COLOR=$(nvm_get_colors 4) 
	DEFAULT_COLOR=$(nvm_get_colors 5) 
	LTS_COLOR=$(nvm_get_colors 6) 
	if nvm_has_colors
	then
		NVM_HAS_COLORS=1 
	fi
	command awk -v remote_versions="$(printf '%s' "${1-}" | tr '\n' '|')" -v installed_versions="$(nvm_ls | tr '\n' '|')" -v current="$NVM_CURRENT" -v installed_color="$INSTALLED_COLOR" -v system_color="$SYSTEM_COLOR" -v current_color="$CURRENT_COLOR" -v default_color="$DEFAULT_COLOR" -v old_lts_color="$DEFAULT_COLOR" -v has_colors="$NVM_HAS_COLORS" '
function alen(arr, i, len) { len=0; for(i in arr) len++; return len; }
BEGIN {
  fmt_installed = has_colors ? (installed_color ? "\033[" installed_color "%15s\033[0m" : "%15s") : "%15s *";
  fmt_system = has_colors ? (system_color ? "\033[" system_color "%15s\033[0m" : "%15s") : "%15s *";
  fmt_current = has_colors ? (current_color ? "\033[" current_color "->%13s\033[0m" : "%15s") : "->%13s *";

  latest_lts_color = current_color;
  sub(/0;/, "1;", latest_lts_color);

  fmt_latest_lts = has_colors && latest_lts_color ? ("\033[" latest_lts_color " (Latest LTS: %s)\033[0m") : " (Latest LTS: %s)";
  fmt_old_lts = has_colors && old_lts_color ? ("\033[" old_lts_color " (LTS: %s)\033[0m") : " (LTS: %s)";

  split(remote_versions, lines, "|");
  split(installed_versions, installed, "|");
  rows = alen(lines);

  for (n = 1; n <= rows; n++) {
    split(lines[n], fields, "[[:blank:]]+");
    cols = alen(fields);
    version = fields[1];
    is_installed = 0;

    for (i in installed) {
      if (version == installed[i]) {
        is_installed = 1;
        break;
      }
    }

    fmt_version = "%15s";
    if (version == current) {
      fmt_version = fmt_current;
    } else if (version == "system") {
      fmt_version = fmt_system;
    } else if (is_installed) {
      fmt_version = fmt_installed;
    }

    padding = (!has_colors && is_installed) ? "" : "  ";

    if (cols == 1) {
      formatted = sprintf(fmt_version, version);
    } else if (cols == 2) {
      formatted = sprintf((fmt_version padding fmt_old_lts), version, fields[2]);
    } else if (cols == 3 && fields[3] == "*") {
      formatted = sprintf((fmt_version padding fmt_latest_lts), version, fields[2]);
    }

    output[n] = formatted;
  }

  for (n = 1; n <= rows; n++) {
    print output[n]
  }

  exit
}'
}
nvm_process_nvmrc () {
	local NVMRC_PATH
	NVMRC_PATH="$1" 
	local lines
	lines=$(command sed 's/#.*//' "$NVMRC_PATH" | command sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | nvm_grep -v '^$') 
	if [ -z "$lines" ]
	then
		nvm_nvmrc_invalid_msg "${lines}"
		return 1
	fi
	local keys
	keys='' 
	local values
	values='' 
	local unpaired_line
	unpaired_line='' 
	while IFS= read -r line
	do
		if [ -z "${line}" ]
		then
			continue
		elif [ -z "${line%%=*}" ]
		then
			if [ -n "${unpaired_line}" ]
			then
				nvm_nvmrc_invalid_msg "${lines}"
				return 1
			fi
			unpaired_line="${line}" 
		elif case "$line" in
				(*'='*) true ;;
				(*) false ;;
			esac
		then
			key="${line%%=*}" 
			value="${line#*=}" 
			key=$(nvm_echo "${key}" | command sed 's/^[[:space:]]*//;s/[[:space:]]*$//') 
			value=$(nvm_echo "${value}" | command sed 's/^[[:space:]]*//;s/[[:space:]]*$//') 
			if [ "${key}" = 'node' ]
			then
				nvm_nvmrc_invalid_msg "${lines}"
				return 1
			fi
			if nvm_echo "${keys}" | nvm_grep -q -E "(^| )${key}( |$)"
			then
				nvm_nvmrc_invalid_msg "${lines}"
				return 1
			fi
			keys="${keys} ${key}" 
			values="${values} ${value}" 
		else
			if [ -n "${unpaired_line}" ]
			then
				nvm_nvmrc_invalid_msg "${lines}"
				return 1
			fi
			unpaired_line="${line}" 
		fi
	done <<EOF
$lines
EOF
	if [ -z "${unpaired_line}" ]
	then
		nvm_nvmrc_invalid_msg "${lines}"
		return 1
	fi
	nvm_echo "${unpaired_line}"
}
nvm_process_parameters () {
	local NVM_AUTO_MODE
	NVM_AUTO_MODE='use' 
	while [ "$#" -ne 0 ]
	do
		case "$1" in
			(--install) NVM_AUTO_MODE='install'  ;;
			(--no-use) NVM_AUTO_MODE='none'  ;;
		esac
		shift
	done
	nvm_auto "${NVM_AUTO_MODE}"
}
nvm_prompt_info () {
	which nvm &> /dev/null || return
	local nvm_prompt=${$(nvm current)#v} 
	echo "${ZSH_THEME_NVM_PROMPT_PREFIX}${nvm_prompt:gs/%/%%}${ZSH_THEME_NVM_PROMPT_SUFFIX}"
}
nvm_rc_version () {
	export NVM_RC_VERSION='' 
	local NVMRC_PATH
	NVMRC_PATH="$(nvm_find_nvmrc)" 
	if [ ! -e "${NVMRC_PATH}" ]
	then
		if [ "${NVM_SILENT:-0}" -ne 1 ]
		then
			nvm_err "No .nvmrc file found"
		fi
		return 1
	fi
	if ! NVM_RC_VERSION="$(nvm_process_nvmrc "${NVMRC_PATH}")" 
	then
		return 1
	fi
	if [ -z "${NVM_RC_VERSION}" ]
	then
		if [ "${NVM_SILENT:-0}" -ne 1 ]
		then
			nvm_err "Warning: empty .nvmrc file found at \"${NVMRC_PATH}\""
		fi
		return 2
	fi
	if [ "${NVM_SILENT:-0}" -ne 1 ]
	then
		nvm_echo "Found '${NVMRC_PATH}' with version <${NVM_RC_VERSION}>"
	fi
}
nvm_remote_version () {
	local PATTERN
	PATTERN="${1-}" 
	local VERSION
	if nvm_validate_implicit_alias "${PATTERN}" 2> /dev/null
	then
		case "${PATTERN}" in
			("$(nvm_iojs_prefix)") VERSION="$(NVM_LTS="${NVM_LTS-}" nvm_ls_remote_iojs | command tail -1)"  && : ;;
			(*) VERSION="$(NVM_LTS="${NVM_LTS-}" nvm_ls_remote "${PATTERN}")"  && : ;;
		esac
	else
		VERSION="$(NVM_LTS="${NVM_LTS-}" nvm_remote_versions "${PATTERN}" | command tail -1)" 
	fi
	if [ -n "${NVM_VERSION_ONLY-}" ]
	then
		command awk 'BEGIN {
      n = split(ARGV[1], a);
      print a[1]
    }' "${VERSION}"
	else
		nvm_echo "${VERSION}"
	fi
	if [ "${VERSION}" = 'N/A' ]
	then
		return 3
	fi
}
nvm_remote_versions () {
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	local NVM_NODE_PREFIX
	NVM_NODE_PREFIX="$(nvm_node_prefix)" 
	local PATTERN
	PATTERN="${1-}" 
	local NVM_FLAVOR
	if [ -n "${NVM_LTS-}" ]
	then
		NVM_FLAVOR="${NVM_NODE_PREFIX}" 
	fi
	case "${PATTERN}" in
		("${NVM_IOJS_PREFIX}" | "io.js") NVM_FLAVOR="${NVM_IOJS_PREFIX}" 
			unset PATTERN ;;
		("${NVM_NODE_PREFIX}") NVM_FLAVOR="${NVM_NODE_PREFIX}" 
			unset PATTERN ;;
	esac
	if nvm_validate_implicit_alias "${PATTERN-}" 2> /dev/null
	then
		nvm_err 'Implicit aliases are not supported in nvm_remote_versions.'
		return 1
	fi
	local NVM_LS_REMOTE_EXIT_CODE
	NVM_LS_REMOTE_EXIT_CODE=0 
	local NVM_LS_REMOTE_PRE_MERGED_OUTPUT
	NVM_LS_REMOTE_PRE_MERGED_OUTPUT='' 
	local NVM_LS_REMOTE_POST_MERGED_OUTPUT
	NVM_LS_REMOTE_POST_MERGED_OUTPUT='' 
	if [ -z "${NVM_FLAVOR-}" ] || [ "${NVM_FLAVOR-}" = "${NVM_NODE_PREFIX}" ]
	then
		local NVM_LS_REMOTE_OUTPUT
		NVM_LS_REMOTE_OUTPUT="$(NVM_LTS="${NVM_LTS-}" nvm_ls_remote "${PATTERN-}") "  && :
		NVM_LS_REMOTE_EXIT_CODE=$? 
		NVM_LS_REMOTE_PRE_MERGED_OUTPUT="${NVM_LS_REMOTE_OUTPUT%%v4\.0\.0*}" 
		NVM_LS_REMOTE_POST_MERGED_OUTPUT="${NVM_LS_REMOTE_OUTPUT#"$NVM_LS_REMOTE_PRE_MERGED_OUTPUT"}" 
	fi
	local NVM_LS_REMOTE_IOJS_EXIT_CODE
	NVM_LS_REMOTE_IOJS_EXIT_CODE=0 
	local NVM_LS_REMOTE_IOJS_OUTPUT
	NVM_LS_REMOTE_IOJS_OUTPUT='' 
	if [ -z "${NVM_LTS-}" ] && {
			[ -z "${NVM_FLAVOR-}" ] || [ "${NVM_FLAVOR-}" = "${NVM_IOJS_PREFIX}" ]
		}
	then
		NVM_LS_REMOTE_IOJS_OUTPUT=$(nvm_ls_remote_iojs "${PATTERN-}")  && :
		NVM_LS_REMOTE_IOJS_EXIT_CODE=$? 
	fi
	VERSIONS="$(nvm_echo "${NVM_LS_REMOTE_PRE_MERGED_OUTPUT}
${NVM_LS_REMOTE_IOJS_OUTPUT}
${NVM_LS_REMOTE_POST_MERGED_OUTPUT}" | nvm_grep -v "N/A" | command sed '/^ *$/d')" 
	if [ -z "${VERSIONS}" ]
	then
		nvm_echo 'N/A'
		return 3
	fi
	nvm_echo "${VERSIONS}" | command sed 's/ *$//g'
	return $NVM_LS_REMOTE_EXIT_CODE || $NVM_LS_REMOTE_IOJS_EXIT_CODE
}
nvm_resolve_alias () {
	if [ -z "${1-}" ]
	then
		return 1
	fi
	local PATTERN
	PATTERN="${1-}" 
	local ALIAS
	ALIAS="${PATTERN}" 
	local ALIAS_TEMP
	local SEEN_ALIASES
	SEEN_ALIASES="${ALIAS}" 
	local NVM_ALIAS_INDEX
	NVM_ALIAS_INDEX=1 
	while true
	do
		ALIAS_TEMP="$( (nvm_alias "${ALIAS}" 2>/dev/null | command head -n "${NVM_ALIAS_INDEX}" | command tail -n 1) || nvm_echo)" 
		if [ -z "${ALIAS_TEMP}" ]
		then
			break
		fi
		if command printf "${SEEN_ALIASES}" | nvm_grep -q -e "^${ALIAS_TEMP}$"
		then
			ALIAS="∞" 
			break
		fi
		SEEN_ALIASES="${SEEN_ALIASES}\\n${ALIAS_TEMP}" 
		ALIAS="${ALIAS_TEMP}" 
	done
	if [ -n "${ALIAS}" ] && [ "_${ALIAS}" != "_${PATTERN}" ]
	then
		local NVM_IOJS_PREFIX
		NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
		local NVM_NODE_PREFIX
		NVM_NODE_PREFIX="$(nvm_node_prefix)" 
		case "${ALIAS}" in
			('∞' | "${NVM_IOJS_PREFIX}" | "${NVM_IOJS_PREFIX}-" | "${NVM_NODE_PREFIX}") nvm_echo "${ALIAS}" ;;
			(*) nvm_ensure_version_prefix "${ALIAS}" ;;
		esac
		return 0
	fi
	if nvm_validate_implicit_alias "${PATTERN}" 2> /dev/null
	then
		local IMPLICIT
		IMPLICIT="$(nvm_print_implicit_alias local "${PATTERN}" 2>/dev/null)" 
		if [ -n "${IMPLICIT}" ]
		then
			nvm_ensure_version_prefix "${IMPLICIT}"
		fi
	fi
	return 2
}
nvm_resolve_local_alias () {
	if [ -z "${1-}" ]
	then
		return 1
	fi
	local VERSION
	local EXIT_CODE
	VERSION="$(nvm_resolve_alias "${1-}")" 
	EXIT_CODE=$? 
	if [ -z "${VERSION}" ]
	then
		return $EXIT_CODE
	fi
	if [ "_${VERSION}" != '_∞' ]
	then
		nvm_version "${VERSION}"
	else
		nvm_echo "${VERSION}"
	fi
}
nvm_sanitize_auth_header () {
	nvm_echo "$1" | command sed 's/[^a-zA-Z0-9:;_. -]//g'
}
nvm_sanitize_path () {
	local SANITIZED_PATH
	SANITIZED_PATH="${1-}" 
	if [ "_${SANITIZED_PATH}" != "_${NVM_DIR}" ]
	then
		SANITIZED_PATH="$(nvm_echo "${SANITIZED_PATH}" | command sed -e "s#${NVM_DIR}#\${NVM_DIR}#g")" 
	fi
	if [ "_${SANITIZED_PATH}" != "_${HOME}" ]
	then
		SANITIZED_PATH="$(nvm_echo "${SANITIZED_PATH}" | command sed -e "s#${HOME}#\${HOME}#g")" 
	fi
	nvm_echo "${SANITIZED_PATH}"
}
nvm_set_colors () {
	if [ "${#1}" -eq 5 ] && nvm_echo "$1" | nvm_grep -E "^[rRgGbBcCyYmMkKeW]{1,}$" > /dev/null
	then
		local INSTALLED_COLOR
		local LTS_AND_SYSTEM_COLOR
		local CURRENT_COLOR
		local NOT_INSTALLED_COLOR
		local DEFAULT_COLOR
		INSTALLED_COLOR="$(echo "$1" | awk '{ print substr($0, 1, 1); }')" 
		LTS_AND_SYSTEM_COLOR="$(echo "$1" | awk '{ print substr($0, 2, 1); }')" 
		CURRENT_COLOR="$(echo "$1" | awk '{ print substr($0, 3, 1); }')" 
		NOT_INSTALLED_COLOR="$(echo "$1" | awk '{ print substr($0, 4, 1); }')" 
		DEFAULT_COLOR="$(echo "$1" | awk '{ print substr($0, 5, 1); }')" 
		if ! nvm_has_colors
		then
			nvm_echo "Setting colors to: ${INSTALLED_COLOR} ${LTS_AND_SYSTEM_COLOR} ${CURRENT_COLOR} ${NOT_INSTALLED_COLOR} ${DEFAULT_COLOR}"
			nvm_echo "WARNING: Colors may not display because they are not supported in this shell."
		else
			nvm_echo_with_colors "Setting colors to: $(nvm_wrap_with_color_code "${INSTALLED_COLOR}" "${INSTALLED_COLOR}")$(nvm_wrap_with_color_code "${LTS_AND_SYSTEM_COLOR}" "${LTS_AND_SYSTEM_COLOR}")$(nvm_wrap_with_color_code "${CURRENT_COLOR}" "${CURRENT_COLOR}")$(nvm_wrap_with_color_code "${NOT_INSTALLED_COLOR}" "${NOT_INSTALLED_COLOR}")$(nvm_wrap_with_color_code "${DEFAULT_COLOR}" "${DEFAULT_COLOR}")"
		fi
		export NVM_COLORS="$1" 
	else
		return 17
	fi
}
nvm_stdout_is_terminal () {
	[ -t 1 ]
}
nvm_strip_iojs_prefix () {
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	case "${1-}" in
		("${NVM_IOJS_PREFIX}") nvm_echo ;;
		(*) nvm_echo "${1#"${NVM_IOJS_PREFIX}"-}" ;;
	esac
}
nvm_strip_path () {
	if [ -z "${NVM_DIR-}" ]
	then
		nvm_err '${NVM_DIR} not set!'
		return 1
	fi
	command printf %s "${1-}" | command awk -v NVM_DIR="${NVM_DIR}" -v RS=: '
  index($0, NVM_DIR) == 1 {
    path = substr($0, length(NVM_DIR) + 1)
    if (path ~ "^(/versions/[^/]*)?/[^/]*'"${2-}"'.*$") { next }
  }
  # The final RT will contain a colon if the input has a trailing colon, or a null string otherwise
  { printf "%s%s", sep, $0; sep=RS } END { printf "%s", RT }'
}
nvm_supports_xz () {
	if [ -z "${1-}" ]
	then
		return 1
	fi
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	if [ "_${NVM_OS}" = '_darwin' ]
	then
		local MACOS_VERSION
		MACOS_VERSION="$(sw_vers -productVersion)" 
		if nvm_version_greater "10.9.0" "${MACOS_VERSION}"
		then
			return 1
		fi
	elif [ "_${NVM_OS}" = '_freebsd' ]
	then
		if ! [ -e '/usr/lib/liblzma.so' ]
		then
			return 1
		fi
	else
		if ! command which xz > /dev/null 2>&1
		then
			return 1
		fi
	fi
	if nvm_is_merged_node_version "${1}"
	then
		return 0
	fi
	if nvm_version_greater_than_or_equal_to "${1}" "0.12.10" && nvm_version_greater "0.13.0" "${1}"
	then
		return 0
	fi
	if nvm_version_greater_than_or_equal_to "${1}" "0.10.42" && nvm_version_greater "0.11.0" "${1}"
	then
		return 0
	fi
	case "${NVM_OS}" in
		(darwin) nvm_version_greater_than_or_equal_to "${1}" "2.3.2" ;;
		(*) nvm_version_greater_than_or_equal_to "${1}" "1.0.0" ;;
	esac
	return $?
}
nvm_tree_contains_path () {
	local tree
	tree="${1-}" 
	local node_path
	node_path="${2-}" 
	if [ "@${tree}@" = "@@" ] || [ "@${node_path}@" = "@@" ]
	then
		nvm_err "both the tree and the node path are required"
		return 2
	fi
	local previous_pathdir
	previous_pathdir="${node_path}" 
	local pathdir
	pathdir=$(dirname "${previous_pathdir}") 
	while [ "${pathdir}" != '' ] && [ "${pathdir}" != '.' ] && [ "${pathdir}" != '/' ] && [ "${pathdir}" != "${tree}" ] && [ "${pathdir}" != "${previous_pathdir}" ]
	do
		previous_pathdir="${pathdir}" 
		pathdir=$(dirname "${previous_pathdir}") 
	done
	[ "${pathdir}" = "${tree}" ]
}
nvm_use_if_needed () {
	if [ "_${1-}" = "_$(nvm_ls_current)" ]
	then
		return
	fi
	nvm use "$@"
}
nvm_validate_implicit_alias () {
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	local NVM_NODE_PREFIX
	NVM_NODE_PREFIX="$(nvm_node_prefix)" 
	case "$1" in
		("stable" | "unstable" | "${NVM_IOJS_PREFIX}" | "${NVM_NODE_PREFIX}") return ;;
		(*) nvm_err "Only implicit aliases 'stable', 'unstable', '${NVM_IOJS_PREFIX}', and '${NVM_NODE_PREFIX}' are supported."
			return 1 ;;
	esac
}
nvm_version () {
	local PATTERN
	PATTERN="${1-}" 
	local VERSION
	if [ -z "${PATTERN}" ]
	then
		PATTERN='current' 
	fi
	if [ "${PATTERN}" = "current" ]
	then
		nvm_ls_current
		return $?
	fi
	local NVM_NODE_PREFIX
	NVM_NODE_PREFIX="$(nvm_node_prefix)" 
	case "_${PATTERN}" in
		("_${NVM_NODE_PREFIX}" | "_${NVM_NODE_PREFIX}-") PATTERN="stable"  ;;
	esac
	VERSION="$(nvm_ls "${PATTERN}" | command tail -1)" 
	if [ -z "${VERSION}" ] || [ "_${VERSION}" = "_N/A" ]
	then
		nvm_echo "N/A"
		return 3
	fi
	nvm_echo "${VERSION}"
}
nvm_version_dir () {
	local NVM_WHICH_DIR
	NVM_WHICH_DIR="${1-}" 
	if [ -z "${NVM_WHICH_DIR}" ] || [ "${NVM_WHICH_DIR}" = "new" ]
	then
		nvm_echo "${NVM_DIR}/versions/node"
	elif [ "_${NVM_WHICH_DIR}" = "_iojs" ]
	then
		nvm_echo "${NVM_DIR}/versions/io.js"
	elif [ "_${NVM_WHICH_DIR}" = "_old" ]
	then
		nvm_echo "${NVM_DIR}"
	else
		nvm_err 'unknown version dir'
		return 3
	fi
}
nvm_version_greater () {
	command awk 'BEGIN {
    if (ARGV[1] == "" || ARGV[2] == "") exit(1)
    split(ARGV[1], a, /\./);
    split(ARGV[2], b, /\./);
    for (i=1; i<=3; i++) {
      if (a[i] && a[i] !~ /^[0-9]+$/) exit(2);
      if (b[i] && b[i] !~ /^[0-9]+$/) { exit(0); }
      if (a[i] < b[i]) exit(3);
      else if (a[i] > b[i]) exit(0);
    }
    exit(4)
  }' "${1#v}" "${2#v}"
}
nvm_version_greater_than_or_equal_to () {
	command awk 'BEGIN {
    if (ARGV[1] == "" || ARGV[2] == "") exit(1)
    split(ARGV[1], a, /\./);
    split(ARGV[2], b, /\./);
    for (i=1; i<=3; i++) {
      if (a[i] && a[i] !~ /^[0-9]+$/) exit(2);
      if (a[i] < b[i]) exit(3);
      else if (a[i] > b[i]) exit(0);
    }
    exit(0)
  }' "${1#v}" "${2#v}"
}
nvm_version_path () {
	local VERSION
	VERSION="${1-}" 
	if [ -z "${VERSION}" ]
	then
		nvm_err 'version is required'
		return 3
	elif nvm_is_iojs_version "${VERSION}"
	then
		nvm_echo "$(nvm_version_dir iojs)/$(nvm_strip_iojs_prefix "${VERSION}")"
	elif nvm_version_greater 0.12.0 "${VERSION}"
	then
		nvm_echo "$(nvm_version_dir old)/${VERSION}"
	else
		nvm_echo "$(nvm_version_dir new)/${VERSION}"
	fi
}
nvm_wrap_with_color_code () {
	local CODE
	CODE="$(nvm_print_color_code "${1}" 2>/dev/null ||:)" 
	local TEXT
	TEXT="${2-}" 
	if nvm_has_colors && [ -n "${CODE}" ]
	then
		nvm_echo_with_colors "\033[${CODE}${TEXT}\033[0m"
	else
		nvm_echo "${TEXT}"
	fi
}
nvm_write_nvmrc () {
	local VERSION_STRING
	VERSION_STRING=$(nvm_version "${1-}") 
	if [ "${VERSION_STRING}" = '∞' ] || [ "${VERSION_STRING}" = 'N/A' ]
	then
		return 1
	fi
	echo "${VERSION_STRING}" | tee "$PWD"/.nvmrc > /dev/null || {
		if [ "${NVM_SILENT:-0}" -ne 1 ]
		then
			nvm_err "Warning: Unable to write version number ($VERSION_STRING) to .nvmrc"
		fi
		return 3
	}
	if [ "${NVM_SILENT:-0}" -ne 1 ]
	then
		nvm_echo "Wrote version number ($VERSION_STRING) to .nvmrc"
	fi
}
omz () {
	setopt localoptions noksharrays
	[[ $# -gt 0 ]] || {
		_omz::help
		return 1
	}
	local command="$1" 
	shift
	(( ${+functions[_omz::$command]} )) || {
		_omz::help
		return 1
	}
	_omz::$command "$@"
}
omz_diagnostic_dump () {
	emulate -L zsh
	builtin echo "Generating diagnostic dump; please be patient..."
	local thisfcn=omz_diagnostic_dump 
	local -A opts
	local opt_verbose opt_noverbose opt_outfile
	local timestamp=$(date +%Y%m%d-%H%M%S) 
	local outfile=omz_diagdump_$timestamp.txt 
	builtin zparseopts -A opts -D -- "v+=opt_verbose" "V+=opt_noverbose"
	local verbose n_verbose=${#opt_verbose} n_noverbose=${#opt_noverbose} 
	(( verbose = 1 + n_verbose - n_noverbose ))
	if [[ ${#*} > 0 ]]
	then
		opt_outfile=$1 
	fi
	if [[ ${#*} > 1 ]]
	then
		builtin echo "$thisfcn: error: too many arguments" >&2
		return 1
	fi
	if [[ -n "$opt_outfile" ]]
	then
		outfile="$opt_outfile" 
	fi
	_omz_diag_dump_one_big_text &> "$outfile"
	if [[ $? != 0 ]]
	then
		builtin echo "$thisfcn: error while creating diagnostic dump; see $outfile for details"
	fi
	builtin echo
	builtin echo Diagnostic dump file created at: "$outfile"
	builtin echo
	builtin echo To share this with OMZ developers, post it as a gist on GitHub
	builtin echo at "https://gist.github.com" and share the link to the gist.
	builtin echo
	builtin echo "WARNING: This dump file contains all your zsh and omz configuration files,"
	builtin echo "so don't share it publicly if there's sensitive information in them."
	builtin echo
}
omz_history () {
	local clear list stamp REPLY
	zparseopts -E -D c=clear l=list f=stamp E=stamp i=stamp t:=stamp
	if [[ -n "$clear" ]]
	then
		print -nu2 "This action will irreversibly delete your command history. Are you sure? [y/N] "
		builtin read -E
		[[ "$REPLY" = [yY] ]] || return 0
		print -nu2 >| "$HISTFILE"
		fc -p "$HISTFILE"
		print -u2 History file deleted.
	elif [[ $# -eq 0 ]]
	then
		builtin fc "${stamp[@]}" -l 1
	else
		builtin fc "${stamp[@]}" -l "$@"
	fi
}
omz_termsupport_cwd () {
	setopt localoptions unset
	local URL_HOST URL_PATH
	URL_HOST="$(omz_urlencode -P $HOST)"  || return 1
	URL_PATH="$(omz_urlencode -P $PWD)"  || return 1
	[[ -z "$KONSOLE_PROFILE_NAME" && -z "$KONSOLE_DBUS_SESSION" ]] || URL_HOST="" 
	printf "\e]7;file://%s%s\e\\" "${URL_HOST}" "${URL_PATH}"
}
omz_termsupport_precmd () {
	[[ "${DISABLE_AUTO_TITLE:-}" != true ]] || return 0
	title "$ZSH_THEME_TERM_TAB_TITLE_IDLE" "$ZSH_THEME_TERM_TITLE_IDLE"
}
omz_termsupport_preexec () {
	[[ "${DISABLE_AUTO_TITLE:-}" != true ]] || return 0
	emulate -L zsh
	setopt extended_glob
	local -a cmdargs
	cmdargs=("${(z)2}") 
	if [[ "${cmdargs[1]}" = fg ]]
	then
		local job_id jobspec="${cmdargs[2]#%}" 
		case "$jobspec" in
			(<->) job_id=${jobspec}  ;;
			("" | % | +) job_id=${(k)jobstates[(r)*:+:*]}  ;;
			(-) job_id=${(k)jobstates[(r)*:-:*]}  ;;
			([?]*) job_id=${(k)jobtexts[(r)*${(Q)jobspec}*]}  ;;
			(*) job_id=${(k)jobtexts[(r)${(Q)jobspec}*]}  ;;
		esac
		if [[ -n "${jobtexts[$job_id]}" ]]
		then
			1="${jobtexts[$job_id]}" 
			2="${jobtexts[$job_id]}" 
		fi
	fi
	local CMD="${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}" 
	local LINE="${2:gs/%/%%}" 
	title "$CMD" "%100>...>${LINE}%<<"
}
omz_urldecode () {
	emulate -L zsh
	local encoded_url=$1 
	local caller_encoding=$langinfo[CODESET] 
	local LC_ALL=C 
	export LC_ALL
	local tmp=${encoded_url:gs/+/ /} 
	tmp=${tmp:gs/\\/\\\\/} 
	tmp=${tmp:gs/%/\\x/} 
	local decoded="$(printf -- "$tmp")" 
	local -a safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII) 
	if [[ -z ${safe_encodings[(r)$caller_encoding]} ]]
	then
		decoded=$(echo -E "$decoded" | iconv -f UTF-8 -t $caller_encoding) 
		if [[ $? != 0 ]]
		then
			echo "Error converting string from UTF-8 to $caller_encoding" >&2
			return 1
		fi
	fi
	echo -E "$decoded"
}
omz_urlencode () {
	emulate -L zsh
	setopt norematchpcre
	local -a opts
	zparseopts -D -E -a opts r m P
	local in_str="$@" 
	local url_str="" 
	local spaces_as_plus
	if [[ -z $opts[(r)-P] ]]
	then
		spaces_as_plus=1 
	fi
	local str="$in_str" 
	local encoding=$langinfo[CODESET] 
	local safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII) 
	if [[ -z ${safe_encodings[(r)$encoding]} ]]
	then
		str=$(echo -E "$str" | iconv -f $encoding -t UTF-8) 
		if [[ $? != 0 ]]
		then
			echo "Error converting string from $encoding to UTF-8" >&2
			return 1
		fi
	fi
	local i byte ord LC_ALL=C 
	export LC_ALL
	local reserved=';/?:@&=+$,' 
	local mark='_.!~*''()-' 
	local dont_escape="[A-Za-z0-9" 
	if [[ -z $opts[(r)-r] ]]
	then
		dont_escape+=$reserved 
	fi
	if [[ -z $opts[(r)-m] ]]
	then
		dont_escape+=$mark 
	fi
	dont_escape+="]" 
	local url_str="" 
	for ((i = 1; i <= ${#str}; ++i )) do
		byte="$str[i]" 
		if [[ "$byte" =~ "$dont_escape" ]]
		then
			url_str+="$byte" 
		else
			if [[ "$byte" == " " && -n $spaces_as_plus ]]
			then
				url_str+="+" 
			elif [[ "$PREFIX" = *com.termux* ]]
			then
				url_str+="$byte" 
			else
				ord=$(( [##16] #byte )) 
				url_str+="%$ord" 
			fi
		fi
	done
	echo -E "$url_str"
}
open_command () {
	local open_cmd
	case "$OSTYPE" in
		(darwin*) open_cmd='open'  ;;
		(cygwin*) open_cmd='cygstart'  ;;
		(linux*) [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='nohup xdg-open'  || {
				open_cmd='cmd.exe /c start ""' 
				[[ -e "$1" ]] && {
					1="$(wslpath -w "${1:a}")"  || return 1
				}
				[[ "$1" = (http|https)://* ]] && {
					1="$(echo "$1" | sed -E 's/([&|()<>^])/^\1/g')"  || return 1
				}
			} ;;
		(msys*) open_cmd='start ""'  ;;
		(*) echo "Platform $OSTYPE not supported"
			return 1 ;;
	esac
	if [[ -n "$BROWSER" && "$1" = (http|https)://* ]]
	then
		"$BROWSER" "$@"
		return
	fi
	${=open_cmd} "$@" &> /dev/null
}
parse_git_dirty () {
	local STATUS
	local -a FLAGS
	FLAGS=('--porcelain') 
	if [[ "$(__git_prompt_git config --get oh-my-zsh.hide-dirty)" != "1" ]]
	then
		if [[ "${DISABLE_UNTRACKED_FILES_DIRTY:-}" == "true" ]]
		then
			FLAGS+='--untracked-files=no' 
		fi
		case "${GIT_STATUS_IGNORE_SUBMODULES:-}" in
			(git)  ;;
			(*) FLAGS+="--ignore-submodules=${GIT_STATUS_IGNORE_SUBMODULES:-dirty}"  ;;
		esac
		STATUS=$(__git_prompt_git status ${FLAGS} 2> /dev/null | tail -n 1) 
	fi
	if [[ -n $STATUS ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_DIRTY"
	else
		echo "$ZSH_THEME_GIT_PROMPT_CLEAN"
	fi
}
pyenv_prompt_info () {
	return 1
}
rbenv_prompt_info () {
	return 1
}
regexp-replace () {
	argv=("$1" "$2" "$3") 
	4=0 
	[[ -o re_match_pcre ]] && 4=1 
	emulate -L zsh
	local MATCH MBEGIN MEND
	local -a match mbegin mend
	if (( $4 ))
	then
		zmodload zsh/pcre || return 2
		pcre_compile -- "$2" && pcre_study || return 2
		4=0 6= 
		local ZPCRE_OP
		while pcre_match -b -n $4 -- "${(P)1}"
		do
			5=${(e)3} 
			argv+=(${(s: :)ZPCRE_OP} "$5") 
			4=$((argv[-2] + (argv[-3] == argv[-2]))) 
		done
		(($# > 6)) || return
		set +o multibyte
		5= 6=1 
		for 2 3 4 in "$@[7,-1]"
		do
			5+=${(P)1[$6,$2]}$4 
			6=$(($3 + 1)) 
		done
		5+=${(P)1[$6,-1]} 
	else
		4=${(P)1} 
		while [[ -n $4 ]]
		do
			if [[ $4 =~ $2 ]]
			then
				5+=${4[1,MBEGIN-1]}${(e)3} 
				if ((MEND < MBEGIN))
				then
					((MEND++))
					5+=${4[1]} 
				fi
				4=${4[MEND+1,-1]} 
				6=1 
			else
				break
			fi
		done
		[[ -n $6 ]] || return
		5+=$4 
	fi
	eval $1=\$5
}
ruby_prompt_info () {
	echo "$(rvm_prompt_info || rbenv_prompt_info || chruby_prompt_info)"
}
rubygems_detect_ruby_lib_gem_path () {
	\typeset ruby_path
	ruby_path="$( __rvm_which "${1:-ruby}" )"  || {
		rvm_error "Missing 'ruby' in 'rubygems_detect_ruby_lib_gem_path'."
		return 1
	}
	ruby_lib_gem_path="$(
    unset GEM_HOME GEM_PATH
    "$ruby_path" -rrubygems -e 'puts Gem.default_dir' 2>/dev/null
  )"  || ruby_lib_gem_path="" 
	[[ -n "$ruby_lib_gem_path" ]] || rubygems_detect_ruby_lib_gem_path_fallback || return $?
}
rubygems_detect_ruby_lib_gem_path_fallback () {
	rubygems_detect_ruby_lib_gem_path_from "rubylib" || rubygems_detect_ruby_lib_gem_path_from "lib" || return $?
	ruby_lib_gem_path+="/gems" 
	\typeset ruby_version
	ruby_version="$( __rvm_ruby_config_get ruby_version "$ruby_path")"  || ruby_version="" 
	if [[ -n "${ruby_version:-}" && -d "${ruby_lib_gem_path}/${ruby_version:-}" ]]
	then
		ruby_lib_gem_path+="$ruby_version" 
	elif [[ -d "${ruby_lib_gem_path}/shared" ]]
	then
		ruby_lib_gem_path+="shared" 
	else
		return 3
	fi
}
rubygems_detect_ruby_lib_gem_path_from () {
	ruby_lib_gem_path="$( __rvm_ruby_config_get ${1}prefix "$ruby_path" )"  || ruby_lib_gem_path="" 
	[[ -z "${ruby_lib_gem_path:-}" ]] || {
		ruby_lib_gem_path="$( __rvm_ruby_config_get ${1}dir  "$ruby_path" )"  || ruby_lib_gem_path="" 
		ruby_lib_gem_path="${ruby_lib_gem_path%/*}" 
	}
	[[ -n "${ruby_lib_gem_path:-}" ]] || return 1
	[[ -d "${ruby_lib_gem_path}/gems" ]] || return 2
}
run_gem_wrappers () {
	gem_install gem-wrappers > /dev/null && gem_wrappers_pristine && gem wrappers "$@" || return $?
}
rvm () {
	\typeset result current_result
	rvm_ruby_args=() 
	__rvm_teardown_if_broken
	__rvm_cli_posix_check || return $?
	__rvm_cli_load_rvmrc || return $?
	__rvm_cli_version_check "$@" || return $?
	__rvm_initialize
	__rvm_path_match_gem_home_check
	__rvm_setup
	__rvm_cli_autoupdate "$@" || return $?
	next_token="$1" 
	(( $# == 0 )) || shift
	__rvm_parse_args "$@"
	result=$? 
	: rvm_ruby_args:${#rvm_ruby_args[@]}:${rvm_ruby_args[*]}:
	(( ${rvm_trace_flag:-0} == 0 )) || set -o xtrace
	(( result )) || case "${rvm_action:=help}" in
		(use) if rvm_is_a_shell_function
			then
				__rvm_use && __rvm_use_ruby_warnings
			fi ;;
		(switch) if rvm_is_a_shell_function
			then
				__rvm_switch "${rvm_ruby_args[@]}"
			fi ;;
		(inspect | strings | version | remote_version) __rvm_${rvm_action} ;;
		(ls | list) "$rvm_scripts_path/list" "${rvm_ruby_args[@]}" ;;
		(debug) rvm_is_not_a_shell_function="${rvm_is_not_a_shell_function}" "$rvm_scripts_path/info" '' debug ;;
		(info) rvm_is_not_a_shell_function="${rvm_is_not_a_shell_function}" "$rvm_scripts_path/${rvm_action}" "${rvm_ruby_args[@]}" ;;
		(reset) source "$rvm_scripts_path/functions/${rvm_action}"
			__rvm_${rvm_action} ;;
		(update) printf "%b" "ERROR: rvm update has been removed. Try 'rvm get head' or see the 'rvm get' and rvm 'rubygems' CLI API instead\n" ;;
		(implode | seppuku) source "$rvm_scripts_path/functions/implode"
			__rvm_implode ;;
		(get) next_token="${1:-}" 
			(( $# == 0 )) || shift
			[[ "$next_token" == "${rvm_action}" ]] && shift
			__rvm_cli_rvm_get "${rvm_ruby_args[@]}" ;;
		(current) __rvm_env_string ;;
		(help | rtfm | env | list | monitor | notes | pkg | requirements) next_token="${1:-}" 
			(( $# == 0 )) || shift
			if (( $# )) && [[ "$next_token" == "${rvm_action}" ]]
			then
				shift
			fi
			"$rvm_scripts_path/${rvm_action}" "${rvm_ruby_args[@]}" ;;
		(cleanup | tools | snapshot | disk-usage | repair | alias | docs | rubygems | migrate | cron | group | wrapper) "$rvm_scripts_path/${rvm_action}" "${rvm_ruby_args[@]}" ;;
		(upgrade) __rvm_fix_selected_ruby __rvm_run_wrapper "$rvm_action" "$rvm_action" "${rvm_ruby_args[@]}" ;;
		(autolibs | osx-ssl-certs | fix-permissions) __rvm_run_wrapper "$rvm_action" "$rvm_action" "${rvm_ruby_args[@]}" ;;
		(do) old_rvm_ruby_string=${rvm_ruby_string:-} 
			unset rvm_ruby_string
			export rvm_ruby_strings rvm_in_flag
			result=0 
			if rvm_is_a_shell_function no_warning
			then
				"$rvm_scripts_path/set" "$rvm_action" "${rvm_ruby_args[@]}" || result=$? 
			else
				exec "$rvm_scripts_path/set" "$rvm_action" "${rvm_ruby_args[@]}" || result=$? 
			fi
			[[ -n "$old_rvm_ruby_string" ]] && rvm_ruby_string=$old_rvm_ruby_string 
			unset old_rvm_ruby_string ;;
		(rvmrc) __rvm_rvmrc_tools "${rvm_ruby_args[@]}" ;;
		(config-get) \typeset __ruby __var
			__ruby=$( __rvm_which ruby ) 
			for __var in "${rvm_ruby_args[@]}"
			do
				__rvm_ruby_config_get "${__var}" "${__ruby}"
			done ;;
		(gemset_use) if rvm_is_a_shell_function
			then
				__rvm_gemset_use
			fi ;;
		(gemset) export rvm_ruby_strings
			"$rvm_scripts_path/gemsets" "${rvm_ruby_args[@]}"
			result=$? 
			rvm_ruby_strings="" 
			if rvm_is_a_shell_function no_warning
			then
				if [[ ${rvm_delete_flag:-0} -eq 1 ]]
				then
					if [[ "${GEM_HOME:-""}" == "${GEM_HOME%%${rvm_gemset_separator:-@}*}${rvm_gemset_separator:-@}${rvm_gemset_name}" ]]
					then
						rvm_delete_flag=0 
						__rvm_use "@default"
					fi
					unset gem_prefix
				elif [[ "${rvm_ruby_args[*]}" == rename* ]] || [[ "${rvm_ruby_args[*]}" == move* ]]
				then
					\typeset _command _from _to
					read _command _from _to <<< "${rvm_ruby_args[*]}"
					if [[ "${GEM_HOME:-""}" == "${GEM_HOME%%${rvm_gemset_separator:-@}*}${rvm_gemset_separator:-@}${_from}" ]]
					then
						__rvm_use "@${_to}"
					fi
				fi
			fi ;;
		(reload) rvm_reload_flag=1  ;;
		(tests | specs) rvm_action="rake" 
			__rvm_do ;;
		(delete | remove) export rvm_path
			if [[ -n "${rvm_ruby_strings}" ]]
			then
				__rvm_run_wrapper manage "$rvm_action" "${rvm_ruby_strings//*-- }"
			else
				__rvm_run_wrapper manage "$rvm_action"
			fi
			__rvm_use default ;;
		(fetch | uninstall | reinstall) export rvm_path
			if [[ -n "${rvm_ruby_strings}" ]]
			then
				__rvm_run_wrapper manage "$rvm_action" "${rvm_ruby_strings//*-- }"
			else
				__rvm_run_wrapper manage "$rvm_action"
			fi ;;
		(try_install | install) export rvm_path
			__rvm_cli_install_ruby "${rvm_ruby_strings}" ;;
		(automount) if [[ -n "$rvm_ruby_string" ]]
			then
				rvm_ruby_args=("$rvm_ruby_string" "${rvm_ruby_args[@]}") 
			fi
			"${rvm_scripts_path}/mount" "$rvm_action" "${rvm_ruby_args[@]}" ;;
		(mount | prepare) if [[ -n "$rvm_ruby_string" ]]
			then
				rvm_ruby_args=("$rvm_ruby_string" "${rvm_ruby_args[@]}") 
			fi
			"${rvm_scripts_path}/$rvm_action" "$rvm_action" "${rvm_ruby_args[@]}" ;;
		(export) __rvm_export "$rvm_export_args" ;;
		(unexport) __rvm_unset_exports ;;
		(error) false ;;
		(which) __rvm_which "${rvm_ruby_args[@]}" ;;
		(*) rvm_error "unknown action '$rvm_action'"
			false ;;
	esac
	current_result=$? 
	(( result )) || result=${current_result} 
	(( result )) || case "$rvm_action" in
		(reinstall | try_install | install) if [[ -n "${rvm_ruby_string}" ]]
				rvm_is_a_shell_function no_warning
			then
				if [[ -e "${rvm_environments_path}/default" ]]
				then
					rvm_verbose_flag=0 __rvm_use
				else
					rvm_verbose_flag=0 rvm_default_flag=1 __rvm_use
				fi
			fi ;;
	esac
	current_result=$? 
	(( result )) || result=${current_result} 
	\typeset __local_rvm_trace_flag
	__local_rvm_trace_flag=${rvm_trace_flag:-0} 
	__rvm_cli_autoreload
	if (( __local_rvm_trace_flag > 0 ))
	then
		set +o verbose
		set +o xtrace
		[[ -n "${ZSH_VERSION:-""}" ]] || set +o errtrace
	fi
	return ${result:-0}
}
rvm_debug () {
	(( ${rvm_debug_flag:-0} )) || return 0
	if rvm_pretty_print stderr
	then
		__rvm_replace_colors "<debug>$*</debug>\n" >&6
	else
		printf "%b" "$*\n" >&6
	fi
}
rvm_debug_stream () {
	if (( ${rvm_debug_flag:-0} == 0 && ${rvm_trace_flag:-0} == 0 ))
	then
		cat - > /dev/null
	elif rvm_pretty_print stdout
	then
		\command \cat - | __rvm_awk '{print "'"${rvm_debug_clr:-}"'"$0"'"${rvm_reset_clr:-}"'"}' >&6
	else
		\command \cat - >&6
	fi
}
rvm_error () {
	if rvm_pretty_print stderr
	then
		__rvm_replace_colors "<error>$*</error>\n" >&6
	else
		printf "%b" "$*\n" >&6
	fi
}
rvm_error_help () {
	rvm_error "$1"
	shift
	rvm_help "$@"
}
rvm_fail () {
	rvm_error "$1"
	exit "${2:-1}"
}
rvm_help () {
	"${rvm_scripts_path}/help" "$@"
}
rvm_install_gpg_setup () {
	{
		rvm_gpg_command="$( \which gpg2 2>/dev/null )"  && [[ ${rvm_gpg_command} != "/cygdrive/"* ]]
	} || {
		rvm_gpg_command="$( \which gpg 2>/dev/null )"  && [[ ${rvm_gpg_command} != "/cygdrive/"* ]]
	} || rvm_gpg_command="" 
	rvm_debug "Detected GPG program: '$rvm_gpg_command'"
	[[ -n "$rvm_gpg_command" ]] || return $?
}
rvm_is_a_shell_function () {
	\typeset _message
	if (( ${rvm_is_not_a_shell_function:-0} )) && [[ "${1:-}" != "no_warning" ]]
	then
		if rvm_pretty_print stderr
		then
			rvm_log ""
		fi
		if rvm_pretty_print stderr
		then
			rvm_error "${rvm_notify_clr:-}RVM is not a function, selecting rubies with '${rvm_error_clr:-}rvm use ...${rvm_notify_clr:-}' will not work."
		else
			rvm_error "RVM is not a function, selecting rubies with 'rvm use ...' will not work."
		fi
		if [[ -n "${SUDO_USER:-}" ]]
		then
			rvm_warn '
Please avoid using "sudo" in front of "rvm".
RVM knows when to use "sudo" and will use it only when it is necessary.
'
		else
			rvm_warn '
You need to change your terminal emulator preferences to allow login shell.
Sometimes it is required to use `/bin/bash --login` as the command.
Please visit https://rvm.io/integration/gnome-terminal/ for an example.
'
		fi
	fi
	return ${rvm_is_not_a_shell_function:-0}
}
rvm_log () {
	[[ ${rvm_quiet_flag} == 1 ]] && return
	printf "%b" "$*\n"
}
rvm_notify () {
	if rvm_pretty_print stdout
	then
		__rvm_replace_colors "<notify>$*</notify>\n"
	else
		printf "%b" "$*\n"
	fi
}
rvm_out () {
	printf "$*\n"
}
rvm_pretty_print () {
	case "${rvm_pretty_print_flag:=auto}" in
		(0|no) return 1 ;;
		(1|auto) case "${TERM:-dumb}" in
				(dumb|unknown) return 1 ;;
			esac
			case "$1" in
				(stdout) [[ -t 1 ]] || return 1 ;;
				(stderr) [[ -t 2 ]] || return 1 ;;
				([0-9]) [[ -t $1 ]] || return 1 ;;
				(any) [[ -t 1 || -t 2 ]] || return 1 ;;
				(*) [[ -t 1 && -t 2 ]] || return 1 ;;
			esac
			return 0 ;;
		(2|force) return 0 ;;
	esac
}
rvm_printf_to_stderr () {
	printf "$@" >&6
}
rvm_prompt_info () {
	[ -f $HOME/.rvm/bin/rvm-prompt ] || return 1
	local rvm_prompt
	rvm_prompt=$($HOME/.rvm/bin/rvm-prompt ${=ZSH_THEME_RVM_PROMPT_OPTIONS} 2>/dev/null) 
	[[ -z "${rvm_prompt}" ]] && return 1
	echo "${ZSH_THEME_RUBY_PROMPT_PREFIX}${rvm_prompt:gs/%/%%}${ZSH_THEME_RUBY_PROMPT_SUFFIX}"
}
rvm_verbose_log () {
	if (( ${rvm_verbose_flag:=0} == 1 ))
	then
		rvm_log "$@"
	fi
}
rvm_warn () {
	if rvm_pretty_print stderr
	then
		__rvm_replace_colors "<warn>$*</warn>\n" >&6
	else
		printf "%b" "$*\n" >&6
	fi
}
sdk () {
	COMMAND="$1" 
	QUALIFIER="$2" 
	case "$COMMAND" in
		(l) COMMAND="list"  ;;
		(ls) COMMAND="list"  ;;
		(v) COMMAND="version"  ;;
		(u) COMMAND="use"  ;;
		(i) COMMAND="install"  ;;
		(rm) COMMAND="uninstall"  ;;
		(c) COMMAND="current"  ;;
		(ug) COMMAND="upgrade"  ;;
		(d) COMMAND="default"  ;;
		(h) COMMAND="home"  ;;
		(e) COMMAND="env"  ;;
	esac
	if [[ "$COMMAND" != "update" ]]
	then
		___sdkman_check_candidates_cache "$SDKMAN_CANDIDATES_CACHE" || return 1
	fi
	SDKMAN_AVAILABLE="true" 
	if [ -z "$SDKMAN_OFFLINE_MODE" ]
	then
		SDKMAN_OFFLINE_MODE="false" 
	fi
	__sdkman_update_service_availability
	if [ -f "${SDKMAN_DIR}/etc/config" ]
	then
		source "${SDKMAN_DIR}/etc/config"
	fi
	if [[ -z "$COMMAND" ]]
	then
		___sdkman_help
		return 1
	fi
	CMD_FOUND="" 
	if [[ "$COMMAND" != "selfupdate" || "$sdkman_selfupdate_feature" == "true" ]]
	then
		CMD_TARGET="${SDKMAN_DIR}/src/sdkman-${COMMAND}.sh" 
		if [[ -f "$CMD_TARGET" ]]
		then
			CMD_FOUND="$CMD_TARGET" 
		fi
	fi
	CMD_TARGET="${SDKMAN_DIR}/ext/sdkman-${COMMAND}.sh" 
	if [[ -f "$CMD_TARGET" ]]
	then
		CMD_FOUND="$CMD_TARGET" 
	fi
	if [[ -z "$CMD_FOUND" ]]
	then
		echo ""
		__sdkman_echo_red "Invalid command: $COMMAND"
		echo ""
		___sdkman_help
	fi
	if [[ "$COMMAND" == "offline" && -n "$QUALIFIER" && -z $(echo "enable disable" | grep -w "$QUALIFIER") ]]
	then
		echo ""
		__sdkman_echo_red "Stop! $QUALIFIER is not a valid offline mode."
	fi
	local final_rc=0 
	local native_command="${SDKMAN_DIR}/libexec/${COMMAND}" 
	if [[ "$sdkman_native_enable" == 'true' && -f "$native_command" ]]
	then
		"$native_command" "${@:2}"
	elif [ -n "$CMD_FOUND" ]
	then
		if [[ -n "$QUALIFIER" && "$COMMAND" != "help" && "$COMMAND" != "offline" && "$COMMAND" != "flush" && "$COMMAND" != "selfupdate" && "$COMMAND" != "env" && "$COMMAND" != "completion" && "$COMMAND" != "edit" && "$COMMAND" != "home" && -z $(echo ${SDKMAN_CANDIDATES[@]} | grep -w "$QUALIFIER") ]]
		then
			echo ""
			__sdkman_echo_red "Stop! $QUALIFIER is not a valid candidate."
			return 1
		fi
		local converted_command_name=$(echo "$COMMAND" | tr '-' '_') 
		__sdk_"$converted_command_name" "${@:2}"
	fi
	final_rc=$? 
	return $final_rc
}
spectrum_bls () {
	setopt localoptions nopromptsubst
	local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris} 
	for code in {000..255}
	do
		print -P -- "$code: ${BG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
	done
}
spectrum_ls () {
	setopt localoptions nopromptsubst
	local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris} 
	for code in {000..255}
	do
		print -P -- "$code: ${FG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
	done
}
svn_prompt_info () {
	return 1
}
take () {
	if [[ $1 =~ ^(https?|ftp).*\.(tar\.(gz|bz2|xz)|tgz)$ ]]
	then
		takeurl "$1"
	elif [[ $1 =~ ^(https?|ftp).*\.(zip)$ ]]
	then
		takezip "$1"
	elif [[ $1 =~ ^([A-Za-z0-9]\+@|https?|git|ssh|ftps?|rsync).*\.git/?$ ]]
	then
		takegit "$1"
	else
		takedir "$@"
	fi
}
takedir () {
	mkdir -p $@ && cd ${@:$#}
}
takegit () {
	git clone "$1"
	cd "$(basename ${1%%.git})"
}
takeurl () {
	local data thedir
	data="$(mktemp)" 
	curl -L "$1" > "$data"
	tar xf "$data"
	thedir="$(tar tf "$data" | head -n 1)" 
	rm "$data"
	cd "$thedir"
}
takezip () {
	local data thedir
	data="$(mktemp)" 
	curl -L "$1" > "$data"
	unzip "$data" -d "./"
	thedir="$(unzip -l "$data" | awk 'NR==4 {print $4}' | sed 's/\/.*//')" 
	rm "$data"
	cd "$thedir"
}
tf_prompt_info () {
	return 1
}
title () {
	setopt localoptions nopromptsubst
	[[ -n "${INSIDE_EMACS:-}" && "$INSIDE_EMACS" != vterm ]] && return
	: ${2=$1}
	case "$TERM" in
		(cygwin | xterm* | putty* | rxvt* | konsole* | ansi | mlterm* | alacritty* | st* | foot* | contour* | wezterm*) print -Pn "\e]2;${2:q}\a"
			print -Pn "\e]1;${1:q}\a" ;;
		(screen* | tmux*) print -Pn "\ek${1:q}\e\\" ;;
		(*) if [[ "$TERM_PROGRAM" == "iTerm.app" ]]
			then
				print -Pn "\e]2;${2:q}\a"
				print -Pn "\e]1;${1:q}\a"
			else
				if (( ${+terminfo[fsl]} && ${+terminfo[tsl]} ))
				then
					print -Pn "${terminfo[tsl]}$1${terminfo[fsl]}"
				fi
			fi ;;
	esac
}
try_alias_value () {
	alias_value "$1" || echo "$1"
}
uninstall_oh_my_zsh () {
	command env ZSH="$ZSH" sh "$ZSH/tools/uninstall.sh"
}
up-line-or-beginning-search () {
	# undefined
	builtin autoload -XU
}
upgrade_oh_my_zsh () {
	echo "${fg[yellow]}Note: \`$0\` is deprecated. Use \`omz update\` instead.$reset_color" >&2
	omz update
}
url-quote-magic () {
	# undefined
	builtin autoload -XUz
}
verify_package_pgp () {
	if "${rvm_gpg_command}" --verify "$2" "$1"
	then
		rvm_notify "GPG verified '$1'"
	else
		\typeset _return=$?
		rvm_error "GPG signature verification failed for '$1' - '$3'! Try to install GPG v2 and then fetch the public key:

    ${SUDO_USER:+sudo }${rvm_gpg_command##*/} --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

or if it fails:

    command curl -sSL https://rvm.io/mpapis.asc | ${SUDO_USER:+sudo }${rvm_gpg_command##*/} --import -
    command curl -sSL https://rvm.io/pkuczynski.asc | ${SUDO_USER:+sudo }${rvm_gpg_command##*/} --import -

In case of further problems with validation please refer to https://rvm.io/rvm/security
"
		return ${_return}
	fi
}
vi_mode_prompt_info () {
	return 1
}
virtualenv_prompt_info () {
	return 1
}
work_in_progress () {
	command git -c log.showSignature=false log -n 1 2> /dev/null | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv} -q -- "--wip--" && echo "WIP!!"
}
zle-line-finish () {
	echoti rmkx
}
zle-line-init () {
	echoti smkx
}
zrecompile () {
	setopt localoptions extendedglob noshwordsplit noksharrays
	local opt check quiet zwc files re file pre ret map tmp mesg pats
	tmp=() 
	while getopts ":tqp" opt
	do
		case $opt in
			(t) check=yes  ;;
			(q) quiet=yes  ;;
			(p) pats=yes  ;;
			(*) if [[ -n $pats ]]
				then
					tmp=($tmp $OPTARG) 
				else
					print -u2 zrecompile: bad option: -$OPTARG
					return 1
				fi ;;
		esac
	done
	shift OPTIND-${#tmp}-1
	if [[ -n $check ]]
	then
		ret=1 
	else
		ret=0 
	fi
	if [[ -n $pats ]]
	then
		local end num
		while (( $# ))
		do
			end=$argv[(i)--] 
			if [[ end -le $# ]]
			then
				files=($argv[1,end-1]) 
				shift end
			else
				files=($argv) 
				argv=() 
			fi
			tmp=() 
			map=() 
			OPTIND=1 
			while getopts :MR opt $files
			do
				case $opt in
					([MR]) map=(-$opt)  ;;
					(*) tmp=($tmp $files[OPTIND])  ;;
				esac
			done
			shift OPTIND-1 files
			(( $#files )) || continue
			files=($files[1] ${files[2,-1]:#*(.zwc|~)}) 
			(( $#files )) || continue
			zwc=${files[1]%.zwc}.zwc 
			shift 1 files
			(( $#files )) || files=(${zwc%.zwc}) 
			if [[ -f $zwc ]]
			then
				num=$(zcompile -t $zwc | wc -l) 
				if [[ num-1 -ne $#files ]]
				then
					re=yes 
				else
					re= 
					for file in $files
					do
						if [[ $file -nt $zwc ]]
						then
							re=yes 
							break
						fi
					done
				fi
			else
				re=yes 
			fi
			if [[ -n $re ]]
			then
				if [[ -n $check ]]
				then
					[[ -z $quiet ]] && print $zwc needs re-compilation
					ret=0 
				else
					[[ -z $quiet ]] && print -n "re-compiling ${zwc}: "
					if [[ -z "$quiet" ]] && {
							[[ ! -f $zwc ]] || mv -f $zwc ${zwc}.old
						} && zcompile $map $tmp $zwc $files
					then
						print succeeded
					elif ! {
							{
								[[ ! -f $zwc ]] || mv -f $zwc ${zwc}.old
							} && zcompile $map $tmp $zwc $files 2> /dev/null
						}
					then
						[[ -z $quiet ]] && print "re-compiling ${zwc}: failed"
						ret=1 
					fi
				fi
			fi
		done
		return ret
	fi
	if (( $# ))
	then
		argv=(${^argv}/*.zwc(ND) ${^argv}.zwc(ND) ${(M)argv:#*.zwc}) 
	else
		argv=(${^fpath}/*.zwc(ND) ${^fpath}.zwc(ND) ${(M)fpath:#*.zwc}) 
	fi
	argv=(${^argv%.zwc}.zwc) 
	for zwc
	do
		files=(${(f)"$(zcompile -t $zwc)"}) 
		if [[ $files[1] = *\(mapped\)* ]]
		then
			map=-M 
			mesg='succeeded (old saved)' 
		else
			map=-R 
			mesg=succeeded 
		fi
		if [[ $zwc = */* ]]
		then
			pre=${zwc%/*}/ 
		else
			pre= 
		fi
		if [[ $files[1] != *$ZSH_VERSION ]]
		then
			re=yes 
		else
			re= 
		fi
		files=(${pre}${^files[2,-1]:#/*} ${(M)files[2,-1]:#/*}) 
		[[ -z $re ]] && for file in $files
		do
			if [[ $file -nt $zwc ]]
			then
				re=yes 
				break
			fi
		done
		if [[ -n $re ]]
		then
			if [[ -n $check ]]
			then
				[[ -z $quiet ]] && print $zwc needs re-compilation
				ret=0 
			else
				[[ -z $quiet ]] && print -n "re-compiling ${zwc}: "
				tmp=(${^files}(N)) 
				if [[ $#tmp -ne $#files ]]
				then
					[[ -z $quiet ]] && print 'failed (missing files)'
					ret=1 
				else
					if [[ -z "$quiet" ]] && mv -f $zwc ${zwc}.old && zcompile $map $zwc $files
					then
						print $mesg
					elif ! {
							mv -f $zwc ${zwc}.old && zcompile $map $zwc $files 2> /dev/null
						}
					then
						[[ -z $quiet ]] && print "re-compiling ${zwc}: failed"
						ret=1 
					fi
				fi
			fi
		fi
	done
	return ret
}
zsh_stats () {
	fc -l 1 | awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' | grep -v "./" | sort -nr | head -n 20 | column -c3 -s " " -t | nl
}

# setopts 20
setopt alwaystoend
setopt autocd
setopt autopushd
setopt completeinword
setopt extendedglob
setopt extendedhistory
setopt noflowcontrol
setopt nohashdirs
setopt histexpiredupsfirst
setopt histignoredups
setopt histignorespace
setopt histverify
setopt interactivecomments
setopt kshglob
setopt login
setopt longlistjobs
setopt promptsubst
setopt pushdignoredups
setopt pushdminus
setopt sharehistory

# aliases 232
alias -- -='cd -'
alias -g ...=../..
alias -g ....=../../..
alias -g .....=../../../..
alias -g ......=../../../../..
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
alias _='sudo '
alias current_branch=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}current_branch%F{yellow}\' is deprecated, using \'%F{green}git_current_branch%F{yellow}\' instead.%f"\n    git_current_branch'
alias egrep='grep -E'
alias fgrep='grep -F'
alias g=git
alias ga='git add'
alias gaa='git add --all'
alias gam='git am'
alias gama='git am --abort'
alias gamc='git am --continue'
alias gams='git am --skip'
alias gamscp='git am --show-current-patch'
alias gap='git apply'
alias gapa='git add --patch'
alias gapt='git apply --3way'
alias gau='git add --update'
alias gav='git add --verbose'
alias gb='git branch'
alias gbD='git branch --delete --force'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbg='LANG=C git branch -vv | grep ": gone\]"'
alias gbgD='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -D'
alias gbgd='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -d'
alias gbl='git blame -w'
alias gbm='git branch --move'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsn='git bisect new'
alias gbso='git bisect old'
alias gbsr='git bisect reset'
alias gbss='git bisect start'
alias gc='git commit --verbose'
alias gc!='git commit --verbose --amend'
alias gcB='git checkout -B'
alias gca='git commit --verbose --all'
alias gca!='git commit --verbose --all --amend'
alias gcam='git commit --all --message'
alias gcan!='git commit --verbose --all --no-edit --amend'
alias gcann!='git commit --verbose --all --date=now --no-edit --amend'
alias gcans!='git commit --verbose --all --signoff --no-edit --amend'
alias gcas='git commit --all --signoff'
alias gcasm='git commit --all --signoff --message'
alias gcb='git checkout -b'
alias gcd='git checkout $(git_develop_branch)'
alias gcf='git config --list'
alias gcfu='git commit --fixup'
alias gcl='git clone --recurse-submodules'
alias gclean='git clean --interactive -d'
alias gclf='git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules'
alias gcm='git checkout $(git_main_branch)'
alias gcmsg='git commit --message'
alias gcn='git commit --verbose --no-edit'
alias gcn!='git commit --verbose --no-edit --amend'
alias gco='git checkout'
alias gcor='git checkout --recurse-submodules'
alias gcount='git shortlog --summary --numbered'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gcs='git commit --gpg-sign'
alias gcsm='git commit --signoff --message'
alias gcss='git commit --gpg-sign --signoff'
alias gcssm='git commit --gpg-sign --signoff --message'
alias gd='git diff'
alias gdca='git diff --cached'
alias gdct='git describe --tags $(git rev-list --tags --max-count=1)'
alias gdcw='git diff --cached --word-diff'
alias gds='git diff --staged'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gdup='git diff @{upstream}'
alias gdw='git diff --word-diff'
alias gf='git fetch'
alias gfa='git fetch --all --tags --prune --jobs=10'
alias gfg='git ls-files | grep'
alias gfo='git fetch origin'
alias gg='git gui citool'
alias gga='git gui citool --amend'
alias ggpull='git pull origin "$(git_current_branch)"'
alias ggpur=ggu
alias ggpush='git push origin "$(git_current_branch)"'
alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias ghh='git help'
alias gignore='git update-index --assume-unchanged'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias git-svn-dcommit-push='git svn dcommit && git push github $(git_main_branch):svntrunk'
alias gk='\gitk --all --branches &!'
alias gke='\gitk --all $(git log --walk-reflogs --pretty=%h) &!'
alias gl='git pull'
alias glg='git log --stat'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glgp='git log --stat --patch'
alias glo='git log --oneline --decorate'
alias glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias glp=_git_log_prettily
alias gluc='git pull upstream $(git_current_branch)'
alias glum='git pull upstream $(git_main_branch)'
alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gmff='git merge --ff-only'
alias gmom='git merge origin/$(git_main_branch)'
alias gms='git merge --squash'
alias gmtl='git mergetool --no-prompt'
alias gmtlvim='git mergetool --no-prompt --tool=vimdiff'
alias gmum='git merge upstream/$(git_main_branch)'
alias gp='git push'
alias gpd='git push --dry-run'
alias gpf='git push --force-with-lease --force-if-includes'
alias gpf!='git push --force'
alias gpoat='git push origin --all && git push origin --tags'
alias gpod='git push origin --delete'
alias gpr='git pull --rebase'
alias gpra='git pull --rebase --autostash'
alias gprav='git pull --rebase --autostash -v'
alias gpristine='git reset --hard && git clean --force -dfx'
alias gprom='git pull --rebase origin $(git_main_branch)'
alias gpromi='git pull --rebase=interactive origin $(git_main_branch)'
alias gprum='git pull --rebase upstream $(git_main_branch)'
alias gprumi='git pull --rebase=interactive upstream $(git_main_branch)'
alias gprv='git pull --rebase -v'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes'
alias gpu='git push upstream'
alias gpv='git push --verbose'
alias gr='git remote'
alias gra='git remote add'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbd='git rebase $(git_develop_branch)'
alias grbi='git rebase --interactive'
alias grbm='git rebase $(git_main_branch)'
alias grbo='git rebase --onto'
alias grbom='git rebase origin/$(git_main_branch)'
alias grbs='git rebase --skip'
alias grbum='git rebase upstream/$(git_main_branch)'
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'
alias grev='git revert'
alias greva='git revert --abort'
alias grevc='git revert --continue'
alias grf='git reflog'
alias grh='git reset'
alias grhh='git reset --hard'
alias grhk='git reset --keep'
alias grhs='git reset --soft'
alias grm='git rm'
alias grmc='git rm --cached'
alias grmv='git remote rename'
alias groh='git reset origin/$(git_current_branch) --hard'
alias grrm='git remote remove'
alias grs='git restore'
alias grset='git remote set-url'
alias grss='git restore --source'
alias grst='git restore --staged'
alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'
alias gru='git reset --'
alias grup='git remote update'
alias grv='git remote --verbose'
alias gsb='git status --short --branch'
alias gsd='git svn dcommit'
alias gsh='git show'
alias gsi='git submodule init'
alias gsps='git show --pretty=short --show-signature'
alias gsr='git svn rebase'
alias gss='git status --short'
alias gst='git status'
alias gsta='git stash push'
alias gstaa='git stash apply'
alias gstall='git stash --all'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --patch'
alias gstu='gsta --include-untracked'
alias gsu='git submodule update'
alias gsw='git switch'
alias gswc='git switch --create'
alias gswd='git switch $(git_develop_branch)'
alias gswm='git switch $(git_main_branch)'
alias gta='git tag --annotate'
alias gtl='gtl(){ git tag --sort=-v:refname -n --list "${1}*" }; noglob gtl'
alias gts='git tag --sign'
alias gtv='git tag | sort -V'
alias gunignore='git update-index --no-assume-unchanged'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
alias gwch='git log --patch --abbrev-commit --pretty=medium --raw'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gwipe='git reset --hard && git clean --force -df'
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'
alias history=omz_history
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'
alias ls='ls -G'
alias lsa='ls -lah'
alias md='mkdir -p'
alias pip='python3 -m pip'
alias rd=rmdir
alias run-help=man
alias rvm-restart='rvm_reload_flag=1 source '\''/Users/ivanma/.rvm/scripts/rvm'\'
alias which-command=whence

# exports 86
export BUN_INSTALL=/Users/ivanma/.bun
export CODEX_HOME=/Users/ivanma/Desktop/gauntlet/ShipShape/ship/.codex
export CODEX_MANAGED_BY_NPM=1
export COLORFGBG='0;15'
export COLORTERM=truecolor
export COMMAND_MODE=unix2003
export GEM_HOME=/Users/ivanma/.rvm/gems/ruby-3.1.0
export GEM_PATH=/Users/ivanma/.rvm/gems/ruby-3.1.0:/Users/ivanma/.rvm/gems/ruby-3.1.0@global
export HOME=/Users/ivanma
export HOMEBREW_CELLAR=/opt/homebrew/Cellar
export HOMEBREW_PREFIX=/opt/homebrew
export HOMEBREW_REPOSITORY=/opt/homebrew
export INFOPATH=/opt/homebrew/share/info:/opt/homebrew/share/info:
export IRBRC=/Users/ivanma/.rvm/rubies/ruby-3.1.0/.irbrc
export ITERM_PROFILE=Default
export ITERM_SESSION_ID=w0t0p0:593833B0-F262-47E1-B3AC-9BFF64C96733
export JAVA_HOME=/Users/ivanma/.sdkman/candidates/java/current
export LANG=en_US.UTF-8
export LC_TERMINAL=iTerm2
export LC_TERMINAL_VERSION=3.6.8
export LESS=-R
export LOGNAME=ivanma
export LSCOLORS=Gxfxcxdxbxegedabagacad
export LS_COLORS='di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
export MAVEN_HOME=/Users/ivanma/.sdkman/candidates/maven/current
export MY_RUBY_HOME=/Users/ivanma/.rvm/rubies/ruby-3.1.0
export NVM_BIN=/Users/ivanma/.nvm/versions/node/v24.14.0/bin
export NVM_CD_FLAGS=-q
export NVM_DIR=/Users/ivanma/.nvm
export NVM_INC=/Users/ivanma/.nvm/versions/node/v24.14.0/include/node
export PAGER=less
export RUBY_VERSION=ruby-3.1.0
export SDKMAN_CANDIDATES_API=https://api.sdkman.io/2
export SDKMAN_CANDIDATES_DIR=/Users/ivanma/.sdkman/candidates
export SDKMAN_DIR=/Users/ivanma/.sdkman
export SDKMAN_PLATFORM=darwinarm64
export SHELL=/bin/zsh
export SSH_AUTH_SOCK=/private/tmp/com.apple.launchd.qCEMmzko8Z/Listeners
export TERM=xterm-256color
export TERMINFO_DIRS=/Applications/iTerm.app/Contents/Resources/terminfo:/usr/share/terminfo
export TERM_FEATURES=T3LrMSc7UUw9Ts3BFGsSyHNoSxFP
export TERM_PROGRAM=iTerm.app
export TERM_PROGRAM_VERSION=3.6.8
export TERM_SESSION_ID=w0t0p0:593833B0-F262-47E1-B3AC-9BFF64C96733
export TMPDIR=/var/folders/y_/q67msw0108sb79wxqs0lf98c0000gn/T/
export USER=ivanma
export XPC_FLAGS=0x0
export XPC_SERVICE_NAME=0
export ZSH=/Users/ivanma/.oh-my-zsh
export __CFBundleIdentifier=com.googlecode.iterm2
export __CF_USER_TEXT_ENCODING=0x1F5:0x0:0x0
export rvm_alias_expanded=''
export rvm_bin_flag=''
export rvm_bin_path=/Users/ivanma/.rvm/bin
export rvm_delete_flag=''
export rvm_docs_type=''
export rvm_file_name=''
export rvm_gemstone_package_file=''
export rvm_gemstone_url=''
export rvm_hook=''
export rvm_niceness=''
export rvm_nightly_flag=''
export rvm_only_path_flag=''
export rvm_path=/Users/ivanma/.rvm
export rvm_prefix=/Users/ivanma
export rvm_pretty_print_flag=''
export rvm_proxy=''
export rvm_quiet_flag=''
export rvm_ruby_alias=''
export rvm_ruby_bits=''
export rvm_ruby_configure=''
export rvm_ruby_file=''
export rvm_ruby_global_gems_path=''
export rvm_ruby_make=''
export rvm_ruby_make_install=''
export rvm_ruby_mode=''
export rvm_ruby_string=''
export rvm_ruby_url=''
export rvm_script_name=''
export rvm_sdk=''
export rvm_silent_flag=''
export rvm_sticky_flag=''
export rvm_system_flag=''
export rvm_use_flag=''
export rvm_user_flag=''
export rvm_version='1.29.12 (latest)'
