source ~/.bash_aliases
fish_vi_key_bindings

# set -x PATH "$PATH:/opt/nvim"
set -x PATH "$PATH:/opt/nvim-linux-x86_64/bin"
set -x SYSTEMD_EDITOR nvim



# ~/.config/fish/config.fish
if test -f ~/.gitlab_token
    # Read the file, strip the trailing newline, and export it
    set -gx GITLAB_TOKEN (string trim < ~/.gitlab_token)
end

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

if status is-interactive
    # Commands to run in interactive sessions can go here

    # Autostart zellij
    eval "$(zellij setup --generate-auto-start fish)"
end
