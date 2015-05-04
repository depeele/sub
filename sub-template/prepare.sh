#!/usr/bin/env bash
#
# Prepare a new root-sub or sub-sub for use.
#
# A root-sub is indicated by a single parameter that is the name of the new
# root-sub.
#
# A sub-sub is indicated by multiple parameters that represent the sub-based
# command line, beginning with the root-sub and proceeding through any
# intermediate sub-subs to the final, new leaf sub-sub being prepared.
#
# Usage: prepare.sh root-sub [sub-sub ...]
#
# Examples:
#   # A new root-sub named "abc"
#   prepare.sh abc
#
#   # A new sub-sub of "abc" named "def"
#   prepare.sh abc def
#
set -e

##
# Reliably resolve the incoming symbolic link.
# @method resolve_link
# @param  path    The path to the target symlink {String};
#
# @return The location of the incoming symlink {String}
#
resolve_link() {
  $(type -p greadlink readlink | head -1) "$1"
}

##
# Reliably retrieve the absolute path of the directory containing this script
# taking care to resolve any intervening symlinks to their physical locations.
# @method get_script_dir
#
# @return The absolute path to the directory containing this script {String};
#
get_script_dir() {
  local src="${BASH_SOURCE[0]}"
  local dir

  # While $src is a symlink, resolve it
  while [ -h "$src" ]; do
    dir="$( cd -P "$( dirname "$src" )" && pwd )"
    src="$(resolve_link "$src")"

    # If $src was a relative symlink, ther will be no '/' prefix...
    [[ $src != /* ]] && src="$dir/$src"
  done

  dir="$( cd -P "$( dirname "$src" )" && pwd )"
  echo "$dir"
}

# Determine the type of sed avaialble
if [ -z $SED_TYPE ]; then
  if `sed --version >/dev/null 2>&1` ; then
    SED_TYPE="gnu"

  else
    SED_TYPE="bsd"
  fi
fi

##
# Handle differences between BSD-sed and GNU-sed with respect to the '-i' flag.
# @method ised
# @param  pat   The substitution pattern {String};
# @param  file  The source/destination file {String};
#
ised() {
  pat=$1
  file=$2

  case $SED_TYPE in
    gnu) sed -i "$pat" "$file" ;;
    bsd) sed -i "" "$pat" "$file" ;;
  esac
}

##############################################################################
if [ $# -lt 1 ]; then
  echo "usage: prepare.sh root-sub [sub-sub ...]" >&2
  exit 1
fi

NAME="${@:$#}"

SUB_BASENAME="$(echo $NAME | tr '[:upper:]' '[:lower:]')"
SUB_FULLNAME="$(echo $*    | tr '[:upper:]' '[:lower:]')"

# isSub indicates whether this is a root-sub (== 0) or sub-sub (> 0)
isSub=$(( $# - 1 ))

[ ${isSub} -eq 0 ] && echo "Preparing your '$SUB_BASENAME' sub!"

if [ "$NAME" != "sub" ]; then
  #
  # If this is a root-sub, 'libexec/sub' should be a soft-link.
  # If this is the case, expand it to a full, non-linked copy.
  #
  if [ -h "libexec/sub" ]; then
    mv libexec/sub libexec/sub-link
    cp -RL libexec/sub-link libexec/sub

    rm -f libexec/sub-link
  fi

  #
  # Process all files, replacing:
  #   '%sub%'     with SUB_BASENAME
  #   '%fullSub%' with SUB_FULLNAME
  #
  for file in {bin,completions,libexec}/* libexec/sub/**/*; do
    [ ! -f "$file" ] && continue

    ised "s/%sub%/$SUB_BASENAME/g;
          s/%fullSub%/$SUB_FULLNAME/g;" "$file"
  done

  # Rename 'bin/sub'
  mv bin/sub "bin/$SUB_BASENAME"
fi

[ -f README.md  ] && rm README.md
[ -f prepare.sh ] && rm prepare.sh

if [ ${isSub} -eq 0 ]; then
  echo "Done! Enjoy your new sub! If you're happy with your sub, run:"
  echo
  echo "    rm -rf .git"
  echo "    git init"
  echo "    git add ."
  echo "    git commit -m 'Starting off $SUB_BASENAME'"
  echo "    ./bin/$SUB_BASENAME init"
  echo
  echo "Made a mistake? Want to make a different sub? Run:"
  echo
  echo "    git add ."
  echo "    git checkout -f"
  echo
  echo "Thanks for making a sub!"
fi
