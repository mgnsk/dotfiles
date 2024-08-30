function fish_prompt
    #Save the return status of the previous command
    set -l last_pipestatus $pipestatus

    set -l pipestatus_string (__fish_print_pipestatus "[" "] " "|" (set_color $fish_color_status) \
                                                                   (set_color --bold $fish_color_status) $last_pipestatus)

    if test -n "$TOOLBOX_ENV"
        set userhost_color yellow
    else
        set userhost_color brblue
    end

    printf '[%s] %s%s@%s %s%s %s%s%s \f\r> ' (date "+%H:%M:%S") \
        (set_color $userhost_color) $USER (prompt_hostname) \
        (set_color $fish_color_cwd) $PWD $pipestatus_string \
        (set_color normal)
end
