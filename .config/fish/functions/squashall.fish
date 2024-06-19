function squashall
    # Squash all commits into a single commit.

    read -P "Enter commit message: " message

    git reset $(git commit-tree HEAD^{tree} -m "$message")
end
