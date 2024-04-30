function fish_prompt
    #Save the return status of the previous command
    set -l last_pipestatus $pipestatus

    switch "$USER"
        case root toor
            printf '%s@%s %s%s%s# ' $USER (prompt_hostname) (set -q fish_color_cwd_root
                                                             and set_color $fish_color_cwd_root
                                                             or set_color $fish_color_cwd) \
                (prompt_pwd) (set_color normal)
        case '*'
            set -l pipestatus_string (__fish_print_pipestatus "[" "] " "|" (set_color $fish_color_status) \
                                      (set_color --bold $fish_color_status) $last_pipestatus)

            set -l userhost_color brblue
            if test -n "$TOOLBOX_ENV"
                set userhost_color yellow
            end

            printf '[%s] %s%s@%s %s%s %s%s%s \f\r> ' (date "+%H:%M:%S") (set_color $userhost_color) \
                $USER (prompt_hostname) (set_color $fish_color_cwd) $PWD $pipestatus_string \
                (set_color normal)
    end
end
