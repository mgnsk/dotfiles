alias ls='ls --color=auto'
alias l='ls -la'
alias ltr='ls -latr'
alias ..='cd ..'
alias ...='cd ../..'
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
config config status.showUntrackedFiles no

# Should be run on master branch with a clean status.
gitprune() {
	git fetch --prune
	for branch in `git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'`; do git branch -D $branch; done
}

# squash N last commits and edit the new commit message.
squashn() {
    git reset --soft "HEAD~$1"
    git commit --edit -m "$(git log --format=%B --reverse HEAD..HEAD@{1})"
}

# squash N last commits using merge and edit the new commit message.
mergesquashn() {
    # Reset the current branch to the commit just before the last 12:
    git reset --hard "HEAD~$1"

    # HEAD@{1} is where the branch was just before the previous command.
    # This command sets the state of the index to be as it would just
    # after a merge from that commit:
    git merge --squash HEAD@{1}

    # Commit those squashed changes.  The commit message will be helpfully
    # prepopulated with the commit messages of all the squashed commits:
    git commit --edit
}

pick() {
	grim -g "$(slurp -p)" -t ppm - | convert - -format '%[pixel:p{0,0}]' txt:-
}
