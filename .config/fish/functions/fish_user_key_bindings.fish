function fish_user_key_bindings
  fish_vi_key_bindings
  fzf_key_bindings
  bind -M insert \ce fzf_complete
  bind -M insert \cx accept-autosuggestion
end
