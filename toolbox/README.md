### Immutable development environment

Dependencies:

- Rootless podman with CGroupsV2 set up.
- `direnv`
- `yq`
- `tusk` task runner (https://github.com/rliebz/tusk)
- `podman-compose-git` docker-compose may also work with some tweaking.

Build the toolbox:

`$ tusk build-all`

Create and run a workspace:

`$ mkdir workspaces/project1`

`$ tusk shell workspaces/project1`
