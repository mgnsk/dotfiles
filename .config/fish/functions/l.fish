function l --wraps='ls -la'
    LC_COLLATE=C ls -la --group-directories-first $argv
end
