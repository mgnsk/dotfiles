### Immutable development environment

Dependencies:

* Rootless podman with CGroupsV2 set up.
* `tusk` task runner (https://github.com/rliebz/tusk)
* `podman-compose-git`
* `fuse-overlayfs-git`

Build the toolbox:

`$ tusk build`

Create and run a workspace:

`$ mkdir workspaces/project1`

`$ tusk bash workspaces/project1`
