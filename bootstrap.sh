#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

MYSHELL=`echo $SHELL | rev | awk -F/ '{print $1}' | rev`
echo $MYSHELL

git pull origin master;

function doIt() {
	rsync --exclude "*.git/" \
		--exclude ".DS_Store" \
		--exclude ".macos" \
		--exclude "bootstrap.sh" \
		--exclude "brew.sh" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		--exclude ".idea/" \
		-avh --no-perms . ~;
    cd fasd; PREFIX=$HOME make install; cd -
	# Subprocess can't refresh the parent shell; zshrc also refuses bash.
	if [ "$MYSHELL" = "bash" ]; then
		source ~/.bashrc;
	else
		echo "Done. Reload with: source ~/.zshrc";
	fi;
}

if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;
