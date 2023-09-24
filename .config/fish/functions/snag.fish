function snag -d "Pick desired files from a chosen branch"
    # use fzf to choose source branch to snag files FROM
    # TODO sort branches by changes in this specific directory
    set branch (git for-each-ref --sort='-committerdate' --format='%(refname:short)' refs/heads | fzf --no-sort --height 20%)
    # avoid doing work if branch isn't set
    if test -n "$branch"
        # use fzf to choose files that differ from current branch
        set files (git diff --relative --name-only $branch | fzf --no-sort --height 20% --layout=reverse --border --multi)
    end
    # avoid checking out branch if files aren't specified
    if test -n "$files"
        git checkout -p $branch $files
    end
end
