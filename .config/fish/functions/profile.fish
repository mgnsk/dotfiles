function profile
    fish --profile /dev/stdout -ic 'fish_prompt; exit' | sort -nk 1
end
