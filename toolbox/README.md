### Immutable development environment

Dependencies:

* Rootless podman with CGroupsV2 set up.
* `tusk` task runner (https://github.com/rliebz/tusk)
* `podman-compose`

Build the toolbox:

`$ tusk build`

Create and run a workspace:

`$ mkdir workspaces/project1`

`$ tusk bash workspaces/project1`

#### Visual Studio Code Remote - Containers
Install `podman-docker` to simulate the docker API.

Attach to a running toolbox container and open `/workspace`.
