#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias l='ls -Alhv --group-directories-first'
alias ltr='ls -latr'
alias ..='cd ..'
alias grep='grep --color=auto'
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias qr='qrencode -t ANSI'

gsw() {
	git switch "$(git for-each-ref --sort='-committerdate' --format='%(refname:short)' refs/heads | fzf --no-sort --height 20%)"
}

mergesquashn() {
	# Reset the current branch to the commit just before the last N:
	git reset --hard "HEAD~$1"

	# HEAD@{1} is where the branch was just before the previous command.
	# This command sets the state of the index to be as it would just
	# after a merge from that commit:
	git merge --squash 'HEAD@{1}'

	# Commit those squashed changes.  The commit message will be helpfully
	# prepopulated with the commit messages of all the squashed commits:
	git commit --edit
}

pick() {
	grim -g "$(slurp -p)" -t ppm - | convert - -format '%[pixel:p{0,0}]' txt:-
}

# Pick desired files from a chosen branch.
snag() {
	# use fzf to choose source branch to snag files FROM
	# TODO sort branches by changes in this specific directory
	local branch="$(git for-each-ref --sort='-committerdate' --format='%(refname:short)' refs/heads | fzf --no-sort --height 20%)"
	# avoid doing work if branch isn't set
	if test -n "$branch"; then
		# use fzf to choose files that differ from current branch
		local files="$(git diff --relative --name-only "$branch" | fzf --no-sort --height 20% --layout=reverse --border --multi)"
	fi
	# avoid checking out branch if files aren't specified
	if test -n "$files"; then
		git checkout -p "$branch" "$files"
	fi
}

# Squash all commits into a single commit.
squashall() {
	read -rP "Enter commit message: " message

	git reset "$(git commit-tree 'HEAD^{tree}' -m "$message")"
}

if test -f /usr/share/LS_COLORS/dircolors.sh; then
	. /usr/share/LS_COLORS/dircolors.sh
fi

if test -d /usr/share/fzf; then
	source /usr/share/fzf/key-bindings.bash
fi

# TODO
# if type -p direnv; then
# 	eval "$(direnv hook bash)"
# fi

PROMPT_COMMAND=__prompt_command # Function to generate PS1 after CMDs

shopt -s histappend
PROMPT_COMMAND="history -a;history -c;history -r;$PROMPT_COMMAND"

__prompt_command() {
	local EXIT="$?" # This needs to be first
	PS1=""

	local RCol='\[\e[0m\]'
	local Red='\[\e[0;31m\]'
	local Gre='\[\e[0;32m\]'
	local BrBlu='\[\e[0;36m\]'

	PS1+="${RCol}[\t] ${BrBlu}\u@\h ${Gre}\w"

	if [ $EXIT != 0 ]; then
		PS1+=" ${Red}[${EXIT}]"
	fi

	PS1+=" ${RCol}\n> "
}
