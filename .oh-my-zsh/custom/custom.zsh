#!/usr/bin/env zsh

prepend_path PATH $HOME/bin
prepend_path PATH $HOME/.local/bin
prepend_path PATH /usr/local/bin

# Create a new directory and enter it
function mkd() {
	mkdir -p "$@" && cd "$_";
}

# Change working directory to the top-most Finder window location
function cdf() { # short for `cdfinder`
	cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')";
}

# Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression
function targz() {
	local tmpFile="${@%/}.tar";
	tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1;

	size=$(
		stat -f"%z" "${tmpFile}" 2> /dev/null; # macOS `stat`
		stat -c"%s" "${tmpFile}" 2> /dev/null;  # GNU `stat`
	);

	local cmd="";
	if (( size < 52428800 )) && hash zopfli 2> /dev/null; then
		# the .tar file is smaller than 50 MB and Zopfli is available; use it
		cmd="zopfli";
	else
		if hash pigz 2> /dev/null; then
			cmd="pigz";
		else
			cmd="gzip";
		fi;
	fi;

	echo "Compressing .tar ($((size / 1000)) kB) using \`${cmd}\`…";
	"${cmd}" -v "${tmpFile}" || return 1;
	[ -f "${tmpFile}" ] && rm "${tmpFile}";

	zippedSize=$(
		stat -f"%z" "${tmpFile}.gz" 2> /dev/null; # macOS `stat`
		stat -c"%s" "${tmpFile}.gz" 2> /dev/null; # GNU `stat`
	);

	echo "${tmpFile}.gz ($((zippedSize / 1000)) kB) created successfully.";
}

# Determine size of a file or total size of a directory
function fs() {
	if du -b /dev/null > /dev/null 2>&1; then
		local arg=-sbh;
	else
		local arg=-sh;
	fi
	if [[ -n "$@" ]]; then
		du $arg -- "$@";
	else
		du $arg .[^.]* ./*;
	fi;
}

# Use Git’s colored diff when available
hash git &>/dev/null;
if [ $? -eq 0 ]; then
	function diff() {
		git diff --no-index --color-words "$@";
	}
fi;

# Compare original and gzipped file size
function gz() {
	local origsize=$(wc -c < "$1");
	local gzipsize=$(gzip -c "$1" | wc -c);
	local ratio=$(echo "$gzipsize * 100 / $origsize" | bc -l);
	printf "orig: %d bytes\n" "$origsize";
	printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio";
}

# Syntax-highlight JSON strings or files
# Usage: `json '{"foo":42}'` or `echo '{"foo":42}' | json`
function json() {
	if [ -t 0 ]; then # argument
		python -mjson.tool <<< "$*" | pygmentize -l javascript;
	else # pipe
		python -mjson.tool | pygmentize -l javascript;
	fi;
}

# Run `dig` and display the most useful info
function digga() {
	dig +nocmd "$1" any +multiline +noall +answer;
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
function getcertnames() {
	if [ -z "${1}" ]; then
		echo "ERROR: No domain specified.";
		return 1;
	fi;

	local domain="${1}";
	echo "Testing ${domain}…";
	echo ""; # newline

	local tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
		| openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1);

	if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
		local certText=$(echo "${tmp}" \
			| openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
			no_serial, no_sigdump, no_signame, no_validity, no_version");
		echo "Common Name:";
		echo ""; # newline
		echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//";
		echo ""; # newline
		echo "Subject Alternative Name(s):";
		echo ""; # newline
		echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
			| sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2;
		return 0;
	else
		echo "ERROR: Certificate not found.";
		return 1;
	fi;
}

# `v` with no arguments opens the current directory in Vim, otherwise opens the
# given location
function v() {
	if [ $# -eq 0 ]; then
		vim .;
	else
	    f -e vim "$@";
	fi;
}

# `o` with no arguments opens the current directory, otherwise opens the given
# location
function o() {
	if [ $# -eq 0 ]; then
		open .;
	else
	    a -e open "$@";
	fi;
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function tre() {
	tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX;
}

# Added
#---------------------------------------------------------------------

drmi() {
  local regex="$1"
  docker images | grep $regex | awk '{print $1 ":" $2}' | xargs docker rmi
  dprune
}

ecs_login() {
    read -p "AWS region [us-east-1]: " REGION
    read -p "AWS docker repo [$ECS_REPO]: " USER_REPO
    REGION=${REGION:-us-east-1}
    ECS_REPO=${USER_REPO:-$ECS_REPO}
    export ECS_REPO
    aws ecr get-login --no-include-email --region $REGION | awk '{printf $6}' | docker login -u AWS $ECS_REPO --password-stdin
}

# fasd & fzf change directory - jump using `fasd` if given argument, filter output of `fasd` using `fzf` else
function z() {
    [ $# -gt 0 ] && fasd_cd -d "$*" && return
    local dir
    dir="$(fasd -Rdl "$1" | fzf -1 -0 --no-sort +m)" && cd "${dir}" || return 1
}

function init_brew_utils() {
    # use brew coreutils, tar, getopt, grep, findutils
    if which brew &> /dev/null; then
        local dir
        dir=$(brew --prefix coreutils)
        if [ -d dir ]; then
            prepend_path PATH "$dir/libexec/gnubin"
            prepend_path MANPATH "$dir/libexec/gnuman"
        fi
        dir=$(brew --prefix gnu-tar)
        if [ -d $dir ]; then
            prepend_path PATH "$dir/libexec/gnubin"
            prepend_path MANPATH "$dir/libexec/gnuman"
        fi
        dir=$(brew --prefix gnu-getopt)
        if [ -d dir ]; then
            prepend_path PATH "$dir/bin"
        fi
				dir=$(brew --prefix grep)
				if [ -d $dir ]; then
						prepend_path PATH "$dir/libexec/gnubin"
						prepend_path MANPATH "$dir/libexec/gnuman"
				fi
				dir=$(brew --prefix findutils)
        if [ -d $dir ]; then
            prepend_path PATH "$dir/libexec/gnubin"
            prepend_path MANPATH "$dir/libexec/gnuman"
        fi
    fi
}

# k8s
# get most recent log grepping job name
function kcl() {
	pod="$(kubectl get pods -o name | grep "$1" | tail -n1)"
	kubectl logs $pod
}

# AWS autocomplete
if [ -f /usr/local/bin/aws_completer ]; then
    complete -C '/usr/local/bin/aws_completer' aws;
fi

# init fasd
eval "$(fasd --init auto)";
unalias z

# init commacd
source ~/.commacd.sh;

# init fzf\
source <(fzf --zsh)
[ -f .fzf/install ] && .fzf/install --key-bindings --completion --no-update-rc &> /dev/null;
[ -f ~/.fzf.bash ] && source ~/.fzf.bash;

# vim
mkdir -p ~/.vim/autoload ~/.vim/bundle && \
    curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim;

# use brew coreutils, tar, getopt
init_brew_utils

# pyenv
if which pyenv &> /dev/null; then
	eval "$(pyenv init -)";
	export PYENV_ROOT="$HOME/.pyenv";
	prepend_path PATH "$PYENV_ROOT/shims";
fi

# poetry
prepend_path PATH "$HOME/.local/bin"

# prioritize brew installs
if which brew &> /dev/null; then
	dir=$(brew --prefix)
	prepend_path PATH "$dir/bin"
fi

# k8s
source <(kubectl completion zsh)
complete -F __start_kubectl k

# direnv
eval "$(direnv hook zsh)"

# java home
export JAVA_HOME=$(/usr/libexec/java_home -v 18)

# 1pass cli
eval "$(op completion zsh)"; compdef _op op

# turn off history exapnsion
set +o histexpand

# s5cmd
autoload -Uz compinit
compinit

_s5cmd_cli_zsh_autocomplete() {
	local -a opts
	local cur
	cur=${words[-1]}
	opts=("${(@f)$(${words[@]:0:#words[@]-1} "${cur}" --generate-bash-completion)}")

	if [[ "${opts[1]}" != "" ]]; then
	  _describe 'values' opts
	else
	  _files
	fi
}

compdef _s5cmd_cli_zsh_autocomplete s5cmd

#  duckdb
prepend_path PATH '/Users/ascott/.duckdb/cli/latest'

# docker
append_path PATH '/Applications/Docker.app/Contents/Resources/bin/'

# Function to find and activate Python virtual environment
uvsh() {
  local dir="$PWD"
  
  # Keep going up the directory tree until we find a .venv, uv.lock, or reach the root
  while [[ "$dir" != "/" ]]; do
    # Check for uv.lock first - if found, stop looking further
    if [[ -f "$dir/uv.lock" ]]; then
      if [[ -d "$dir/.venv" && -f "$dir/.venv/bin/activate" ]]; then
        echo "Found virtual environment at $dir/.venv"
        source "$dir/.venv/bin/activate"
        return 0
      else
        echo "Found uv.lock at $dir but no virtual environment"
        return 1
      fi
    fi
    
    # Check for .venv
    if [[ -d "$dir/.venv" && -f "$dir/.venv/bin/activate" ]]; then
      echo "Found virtual environment at $dir/.venv"
      source "$dir/.venv/bin/activate"
      return 0
    fi
    
    dir="$(dirname "$dir")"
  done
  
  echo "No virtual environment (.venv) found in parent directories"
  return 1
}

