function gsw
    git switch (git for-each-ref --sort='-committerdate' --format='%(refname:short)' refs/heads | fzf --no-sort --height 20%)
end
