{ pkgs, ... }:
{
  xdg.enable = true;

  # Replaces the manual `xdg-user-dirs-update` call from
  # postinstall/3_config.sh, which used to run before dotfiles/
  # home-manager even existed on a fresh install. This runs as
  # part of `home-manager switch` activation instead.
  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
  xdg.userDirs.setSessionVariables = false;

  # User-level makepkg.conf override (XDG_CONFIG_HOME/pacman/makepkg.conf).
  # Arch/pacman-specific; no home-manager module and its
  # shell-array syntax doesn't fit a pkgs.formats.* generator.
  xdg.configFile."pacman/makepkg.conf".text = # bash
    ''
      MAKEFLAGS="--jobs=$(nproc)"
      BUILDDIR=/tmp/makepkg
      OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto)
      PACMAN_AUTH=sudo
    '';

  home.file.".config/containers/storage.conf".source =
    (pkgs.formats.toml { }).generate "containers-storage.conf"
      {
        storage.driver = "overlay";
      };

  # This is a *template* unit (%i = remote name), instantiated
  # per-remote at runtime by postinstall/6_rclone_mount.sh via
  # `systemctl --user enable --now rclone@$remote`. It's kept as
  # raw text rather than systemd.user.services."rclone@" because
  # that module always turns Install.WantedBy into an eager
  # ~/.config/systemd/user/default.target.wants/rclone@.service
  # symlink pointing at the bare, uninstantiated template - which
  # systemd can't start and fails at every login. Writing the file
  # directly avoids that footgun while still needing the
  # [Install] section for `systemctl enable` to work per-instance.
  # https://github.com/rclone/rclone/wiki/Systemd-rclone-mount#systemd
  xdg.configFile."systemd/user/rclone@.service".text = ''
    [Unit]
    Description=RClone mount of users remote %i using filesystem permissions
    Documentation=http://rclone.org/docs/
    After=network-online.target


    [Service]
    Type=notify
    #Set up environment
    Environment=REMOTE_NAME="%i"
    Environment=REMOTE_PATH="/"
    Environment=MOUNT_DIR="/mnt/%u/%i"
    Environment=POST_MOUNT_SCRIPT=""
    Environment=RCLONE_CONF="%h/.config/rclone/rclone.conf"
    Environment=RCLONE_TEMP_DIR="%h/.cache/rclone/%u/%i"
    Environment=RCLONE_RC_ON="false"

    #Default arguments for rclone mount. Can be overridden in the environment file
    Environment=RCLONE_MOUNT_ATTR_TIMEOUT="1s"
    #TODO: figure out default for the following parameter
    Environment=RCLONE_MOUNT_DAEMON_TIMEOUT="UNKNOWN_DEFAULT"
    Environment=RCLONE_MOUNT_DIR_CACHE_TIME="1m"
    Environment=RCLONE_MOUNT_DIR_PERMS="0777"
    Environment=RCLONE_MOUNT_FILE_PERMS="0666"
    Environment=RCLONE_MOUNT_GID="%G"
    Environment=RCLONE_MOUNT_MAX_READ_AHEAD="128k"
    Environment=RCLONE_MOUNT_POLL_INTERVAL="1m0s"
    Environment=RCLONE_MOUNT_UID="%U"
    Environment=RCLONE_MOUNT_UMASK="022"
    Environment=RCLONE_MOUNT_VFS_CACHE_MAX_AGE="1h0m0s"
    Environment=RCLONE_MOUNT_VFS_CACHE_MAX_SIZE="off"
    Environment=RCLONE_MOUNT_VFS_CACHE_MODE="writes"
    Environment=RCLONE_MOUNT_VFS_CACHE_POLL_INTERVAL="1m0s"
    Environment=RCLONE_MOUNT_VFS_READ_CHUNK_SIZE="128M"
    Environment=RCLONE_MOUNT_VFS_READ_CHUNK_SIZE_LIMIT="off"
    #TODO: figure out default for the following parameter
    Environment=RCLONE_MOUNT_VOLNAME="UNKNOWN_DEFAULT"

    #Overwrite default environment settings with settings from the file if present
    EnvironmentFile=-%h/.config/rclone/%i.env

    #Check that rclone is installed
    ExecStartPre=${pkgs.coreutils}/bin/test -x ${pkgs.rclone}/bin/rclone

    #Check the mount directory
    ExecStartPre=${pkgs.coreutils}/bin/test -d "''${MOUNT_DIR}"
    ExecStartPre=${pkgs.coreutils}/bin/test -w "''${MOUNT_DIR}"
    #TODO: Add test for MOUNT_DIR being empty -> ExecStartPre=${pkgs.coreutils}/bin/test -z "$(ls -A "''${MOUNT_DIR}")"

    #Check the rclone configuration file
    ExecStartPre=${pkgs.coreutils}/bin/test -f "''${RCLONE_CONF}"
    ExecStartPre=${pkgs.coreutils}/bin/test -r "''${RCLONE_CONF}"
    #TODO: add test that the remote is configured for the rclone configuration

    #Mount rclone fs
    ExecStart=${pkgs.rclone}/bin/rclone mount \
                --config="''${RCLONE_CONF}" \
    #See additional items for access control below for information about the following 2 flags
    #            --allow-other \
    #            --default-permissions \
                --rc="''${RCLONE_RC_ON}" \
                --cache-tmp-upload-path="''${RCLONE_TEMP_DIR}/upload" \
                --cache-chunk-path="''${RCLONE_TEMP_DIR}/chunks" \
                --cache-workers=8 \
                --cache-writes \
                --cache-dir="''${RCLONE_TEMP_DIR}/vfs" \
                --cache-db-path="''${RCLONE_TEMP_DIR}/db" \
                --no-modtime \
                --drive-use-trash \
                --stats=0 \
                --checkers=16 \
                --bwlimit=40M \
                --cache-info-age=60m \
                --attr-timeout="''${RCLONE_MOUNT_ATTR_TIMEOUT}" \
    #TODO: Include this once a proper default value is determined
    #           --daemon-timeout="''${RCLONE_MOUNT_DAEMON_TIMEOUT}" \
                --dir-cache-time="''${RCLONE_MOUNT_DIR_CACHE_TIME}" \
                --dir-perms="''${RCLONE_MOUNT_DIR_PERMS}" \
                --file-perms="''${RCLONE_MOUNT_FILE_PERMS}" \
                --gid="''${RCLONE_MOUNT_GID}" \
                --max-read-ahead="''${RCLONE_MOUNT_MAX_READ_AHEAD}" \
                --poll-interval="''${RCLONE_MOUNT_POLL_INTERVAL}" \
                --uid="''${RCLONE_MOUNT_UID}" \
                --umask="''${RCLONE_MOUNT_UMASK}" \
                --vfs-cache-max-age="''${RCLONE_MOUNT_VFS_CACHE_MAX_AGE}" \
                --vfs-cache-max-size="''${RCLONE_MOUNT_VFS_CACHE_MAX_SIZE}" \
                --vfs-cache-mode="''${RCLONE_MOUNT_VFS_CACHE_MODE}" \
                --vfs-cache-poll-interval="''${RCLONE_MOUNT_VFS_CACHE_POLL_INTERVAL}" \
                --vfs-read-chunk-size="''${RCLONE_MOUNT_VFS_READ_CHUNK_SIZE}" \
                --vfs-read-chunk-size-limit="''${RCLONE_MOUNT_VFS_READ_CHUNK_SIZE_LIMIT}" \
    #TODO: Include this once a proper default value is determined
    #            --volname="''${RCLONE_MOUNT_VOLNAME}"
                "''${REMOTE_NAME}:''${REMOTE_PATH}" "''${MOUNT_DIR}"

    #Execute Post Mount Script if specified
    ExecStartPost=${pkgs.bash}/bin/sh -c "''${POST_MOUNT_SCRIPT}"

    #Unmount rclone fs
    ExecStop=${pkgs.fuse}/bin/fusermount -u "''${MOUNT_DIR}"

    #Restart info
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=default.target
  '';
}
