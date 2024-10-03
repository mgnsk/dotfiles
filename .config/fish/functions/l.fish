function l --wraps='ls'
    ls -Alhv --group-directories-first $argv
end
