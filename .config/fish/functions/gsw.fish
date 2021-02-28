function gsw
    git switch (git branch --all | fzf | tr -d '[:space:]')
end
