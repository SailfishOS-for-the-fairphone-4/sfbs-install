module_name=sync

sfb_local_repo_state() {
	local dir="${1:-$PWD}" branch origin common_base local_ref remote_ref
	if [ "$(git -C "$dir" status -s 2>/dev/null)" ]; then
		echo "dirty"; return
	fi
	branch="${2:-$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null)}"
	origin="${3:-origin}/$branch"
	common_base=$(git -C "$dir" merge-base $branch $origin 2>/dev/null)
	local_ref=$(git -C "$dir" rev-parse $branch 2>/dev/null)
	remote_ref=$(git -C "$dir" rev-parse $origin 2>/dev/null)
	if [[ -z "$common_base" || -z "$local_ref" || -z "$remote_ref" ]]; then
		echo "unknown"; return
	fi
	if [ "$local_ref" = "$remote_ref" ]; then
		echo "up-to-date"
	elif [ "$local_ref" = "$common_base" ]; then
		echo "behind"
	elif [ "$remote_ref" = "$common_base" ]; then
		echo "ahead"
	else
		echo "diverged"
	fi
}

sfb_git_clone_or_pull() {
	local arg url dir origin branch shallow=0 dir_local cmd=(git) mode state commits
	for arg in "$@"; do
		case "$1" in
			-u) url="$2"; shift ;;
			-d) dir="$2"; shift ;;
			-o) origin=$2; shift ;;
			-b) branch=$2; shift ;;
			-s) shallow=$2; shift ;;
		esac
		shift
	done
	if [ -z "$dir" ]; then
		sfb_error "A specified directory is required to clone or update a local repo!"
	fi
	dir_local="${dir#"$ANDROID_ROOT/"}"
	[[ "$dir_local" = "$HOME"* ]] && dir_local="~${dir_local#"$HOME"}"

	if [ -d "$dir" ]; then
		cmd+=(-C "$dir")
		sfb_dbg "updating $url clone @ $dir_local (shallow: $shallow)..."
		if [ $shallow -eq 0 ]; then
			"${cmd[@]}" pull --recurse-submodules && return || sfb_warn "Failed to pull updates for $dir_local, trying shallow method..."
		else
			"${cmd[@]}" fetch --recurse-submodules --depth 1 || sfb_error "Failed to fetch updates for $dir_local!"
		fi

		state="$(sfb_local_repo_state "$dir" "$branch" "$origin")"
		case "$state" in
			up-to-date) return ;; # no need to update
			behind) : ;; # update out-of-date repo
			diverged)
				commits=$("${cmd[@]}" rev-list --count HEAD) # 1 on shallow clones
				if [ $commits -gt 1 ]; then
					sfb_error "Refusing to update diverged local repo with >1 commit!"
				fi
				;;
			*) sfb_error "Refusing to update '$dir_local' in a state of '$state'!" ;;
		esac
		cmd+=(reset --hard $origin --recurse-submodules)
		mode="update"
	else
		if [ -z "$url" ]; then
			sfb_error "Cannot create a local repo clone without a URL!"
		fi
		cmd+=(clone --recurse-submodules)
		if [ "$branch" ]; then
			cmd+=(-b $branch)
		fi
		if [ $shallow -eq 1 ]; then
			cmd+=(--depth 1)
		fi
		cmd+=("$url" "$dir")
		mode="create"
	fi
	"${cmd[@]}" || sfb_error "Failed to $mode local clone of $url!"
}

sfb_sync_hybris_repos() {
	local ans extra_init_args="" branch="hybris-$HYBRIS_VER" local_manifests_url xml name
	if sfb_array_contains "^\-(y|\-yes)$" "$@"; then
		ans="y"
	fi
	if sfb_array_contains "^\-(s|\-shallow)$" "$@"; then
		extra_init_args+=" --depth 1"
	fi
	if [ ! -d "$ANDROID_ROOT/.repo/manifests" ]; then
		sfb_log "Initializing new $branch source tree..."
		sfb_chroot habuild "repo init -u $REPO_INIT_URL -b $branch --platform=linux$extra_init_args" || return 1
	fi
	
	if [[  -f $ANDROID_ROOT/.repo/manifests/FP4.xml ]]; then
		if [ ! -d "$SFB_LOCAL_MANIFESTS" ]; then
			sfb_log "Initializing $SFB_LOCAL_MANIFESTS..."
			mkdir -p $SFB_LOCAL_MANIFESTS && cp $ANDROID_ROOT/.repo/manifests/FP4.xml $SFB_LOCAL_MANIFESTS/FP4.xml || return
		fi	
	fi
			
	if sfb_manual_hybris_patches_applied; then
		sfb_prompt "Applied hybris patches detected; run 'repo sync -l' & discard ALL local changes (y/N)?" ans "$SFB_YESNO_REGEX" "$ans"
		[[ "${ans^^}" != "Y"* ]] && return
		sfb_chroot habuild "repo sync -l" || return 1
	fi
	

	sfb_log "Syncing $branch source tree with $SFB_JOBS jobs..."
	if [ $(echo $ANDROID_ROOT/*/ | wc -w) -lt $(echo $ANDROID_ROOT/.repo/projects/*/ | wc -w) ]; then
		if [ ! -f "$ANDROID_ROOT/.repo/project.list" ]; then
			sfb_log "Syncing $branch source tree with --fetch-submodules"
			sfb_chroot habuild "repo sync -c -j$SFB_JOBS --fail-fast --fetch-submodules --no-clone-bundle --no-tags"
		fi	
	elif [ -d "$ANDROID_ROOT/.repo/manifests" ]; then
		sfb_log "Syncing $branch source tree with --force-sync"
		sfb_chroot habuild "repo sync -j$SFB_JOBS --force-sync" || return 1
	fi

	sfb_log "Cloning Libhybris into external"
	sfb_chroot habuild "$SUDO rm -rd external/libhybris"
	sfb_git_clone_or_pull -b "android11" -u ""$GIT_CLONE_PREFIX"mer-hybris/libhybris.git" -d "$ANDROID_ROOT/external/libhybris"
}

sfb_sync() {
	if [ "$PORT_TYPE" = "hybris" ]; then
		sfb_sync_hybris_repos "$@" || return 1
	fi
}

sfb_sync_setup_usage() {
	sfb_usage_main+=(sync "Synchronize repos for device")
	sfb_usage_main_sync_args=(
		"-y|--yes" "Answer yes to 'repo sync -l' question automatically on hybris ports"
		"-s|--shallow" "Initialize manifest repos as shallow clones on hybris ports"
		"-c|--clone-only" "Don't attempt to update pre-existing extra repos"
	)
}
