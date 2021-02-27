function pick
    grim -g (slurp) -t ppm - | convert - -format '%[pixel:p{0,0}]' txt:-
end
