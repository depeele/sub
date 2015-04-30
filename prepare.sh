#!/usr/bin/env bash
set -e

NAME="$1"
if [ -z "$NAME" ]; then
  echo "usage: prepare.sh NAME_OF_YOUR_SUB" >&2
  exit 1
fi

SUBNAME=$(echo $NAME | tr '[A-Z]' '[a-z]')
FUNNAME="$(echo $NAME | tr '[A-Z-]' '[a-z_]')"
ENVNAME="$(echo $NAME | tr '[a-z-]' '[A-Z_]')_ROOT"

echo "Preparing your '$SUBNAME' sub!"

if [ "$NAME" != "sub" ]; then
  rm bin/sub

  for file in **/*; do
    newFile="$(echo $file | sed "s/sub/$SUBNAME/")"

    sed -i "s/_sub/_$FUNNAME/g;s/sub/$SUBNAME/g;s/SUB_ROOT/$ENVNAME/g;s/%Sub%/sub/g" "$file"
    [[ "$file" != "$newFile" ]] && mv "$file" "$newFile"
  done

  for file in libexec/*; do
    chmod a+x $file
  done

  ln -s ../libexec/$SUBNAME bin/$SUBNAME
fi

rm README.md
rm prepare.sh

echo "Done! Enjoy your new sub! If you're happy with your sub, run:"
echo
echo "    rm -rf .git"
echo "    git init"
echo "    git add ."
echo "    git commit -m 'Starting off $SUBNAME'"
echo "    ./bin/$SUBNAME init"
echo
echo "Made a mistake? Want to make a different sub? Run:"
echo
echo "    git add ."
echo "    git checkout -f"
echo
echo "Thanks for making a sub!"
