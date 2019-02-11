#!/usr/bin/env bash

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Append to the Bash history file, rather than overwriting it
shopt -s histappend;

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Add Homebrew `/usr/local/bin` and User `~/bin` to the `$PATH`
path_prepend PATH "/usr/local/bin";
path_prepend PATH "$HOME/bin";

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# Add tab completion for many Bash commands
if which brew &> /dev/null && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
	source "$(brew --prefix)/etc/bash_completion" &> /dev/null;
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
fi;

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &> /dev/null && [ -f /usr/local/etc/bash_completion.d/git-completion.bash ]; then
	complete -o default -o nospace -F _git g;
fi;

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;


# Added
#---------------------------------------------------------------------

# AWS autocomplete
if [ -f /usr/local/bin/aws_completer ]; then
    complete -C '/usr/local/bin/aws_completer' aws;
fi

# init fasd
eval "$(fasd --init auto)";
unalias z

# init commacd
source ~/.commacd.bash;

# init fzf
[ -f .fzf/install ] && .fzf/install --key-bindings --completion --no-update-rc &> /dev/null;
[ -f ~/.fzf.bash ] && source ~/.fzf.bash;

# vim
mkdir -p ~/.vim/autoload ~/.vim/bundle && \
    curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim;

# pyenv
if which pyenv &> /dev/null; then eval "$(pyenv init -)"; fi


# use brew coreutils, tar, getopt
init_brew_utils
