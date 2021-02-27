function mergesquashn --description 'alias config=/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
  # Reset the current branch to the commit just before the last 12:
  git reset --hard "HEAD~$argv"

  # HEAD@{1} is where the branch was just before the previous command.
  # This command sets the state of the index to be as it would just
  # after a merge from that commit:
  git merge --squash HEAD@{1}

  # Commit those squashed changes.  The commit message will be helpfully
  # prepopulated with the commit messages of all the squashed commits:
  git commit --edit
end
