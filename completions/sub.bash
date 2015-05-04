##
# Perform sub-based autocompletion under the assumption that the top-level sub
# is resolvable via `which` and any nested subs always exist as a sub-directory
# of the current sub's 'libexec'
#
# Example:
#   sub-root                  Top-level sub, named "sub-root"
#     bin / sub-root          Resolvable via `which`
#                               (i.e. "sub-root/bin" is in $PATH)
#
#     libexec
#       commands
#       help
#       init
#
#       sub-1                 Nexted sub, named "sub-1" and executable via
#                               `sub-root sub-1`
#         bin / sub-1
#         libexec
#           commands
#           help
#
_autocompleteSub() {
  # The initial completion target -- may be changed before we're done
  local target=( "${COMP_WORDS[COMP_CWORD]}" )

  # Locate the path of the top-level sub
  local rootSub="$( which "${COMP_WORDS[0]}" )"
  local inSub=1                     # Set when we're currently in a new sub and
                                    # need to determine it's root (one
                                    # directory up).
  local gatherMode=0                # Set when we reach the lowest leaf sub to
                                    # signal the need to add all other words to
                                    # `target`.
  local path="$rootSub"             # The absolute path to the current sub
                                    # executable.
  local cmd=( "${COMP_WORDS[0]}" )  # An array representing the current sub
                                    # command.

  # Iterate over COMP_WORDS 1..n
  for (( index=1; index < ${#COMP_WORDS[@]}; index++ )); do
    local word="${COMP_WORDS[$index]}"

    # If we're in gather mode, push all remaining words into `target`
    [ $gatherMode -ne 0 ] && target+=( "$word" ) && continue

    ######################################################################
    # Not yet done, remember the current path/inSub state
    local lpath="$path"
    local lflag="$inSub"

    if [ $inSub ]; then
      # `path` is currently in the 'bin' subdirectory of a sub.
      # Back up and into the sub's 'libexec'
      path="$(dirname "$(dirname "$path")")/libexec"
      inSub=0
    fi

    # Does `path/word` appear to be a child sub?
    if [ -d "$path/$word" ]; then
      # This appears to be a child sub
      path="$path/$word/bin/$word"
      inSub=1
    else
      # NOT a child sub, treat it as a normal sub command
      path="$path/$word"
    fi

    # Check if `path` is an executable file...
    if [ -x "$path" ]; then
      # `path` is executable and so a valid sub.
      # Update `cmd` and continue.
      cmd+=( "$word" )

    else
      ####################################################################
      # `path` is NOT executable and thus neither a child sub nor sub
      # command.
      #
      # Revert to the previous path/inSub state and set 'gatherMode' to collect
      # all remaining words into `target`
      #
      target+=( "$word" )
      inSub=$lflag
      path="$lpath"
      gatherMode=1
    fi

  done

  # Use the assembled $cmd to generate completions
  if [ "${#target[@]}" -gt 1 ]; then
    completions="$(${cmd[@]} --complete "${target[@]}")"
  else
    completions="$(${cmd[@]} commands")"
  fi

  COMPREPLY=( $(compgen -W "$completions" -- "${target[@]}") )
}

complete -F _autocompleteSub sub
