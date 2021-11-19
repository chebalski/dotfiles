#!/usr/bin/env zsh

cd "$(dirname "${BASH_SOURCE}")";

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
	source ~/.zshrc;
}

if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
	doIt;
else
	read -q "REPLY?This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;
