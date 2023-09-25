# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment and paths
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export WIREPLUMBER_CONFIG_DIR="$HOME/.config/wireplumber"
export WIREPLUMBER_DATA_DIR="$HOME/.config/wireplumber/scripts"
export HISTSIZE=5000
export HISTFILESIZE=5000
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Source API key variables
if [ -f ~/.api_keys ]; then
    . ~/.api_keys
fi

# User specific aliases and functions
alias chat='python $HOME/programs/python/openai/terminal-chat.py'
alias obsidian='flatpak run md.obsidian.Obsidian'
alias firefox='flatpak run org.mozilla.firefox' 
alias nvim='flatpak run io.neovim.nvim -u $HOME/.config/nvim/init.lua'
alias matrix='flatpak run im.riot.Riot --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland'
alias reco='flatpak run com.github.ryonakano.reco'
alias boxes='flatpak run org.gnome.Boxes'
alias obs='flatpak run com.obsproject.Studio'
alias color='flatpak run nl.hjdskes.gcolor3'
alias db='flatpak run org.sqlitebrowser.sqlitebrowser'
alias code='flatpak run com.visualstudio.code'

# Source additional configurations
if [ -d $HOME/.bashrc.d ]; then
    for rc in $HOME/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
    unset rc
fi

# Custom prompt
set_prompt() {
    local part
    if [[ "$PWD" == $HOME || "$PWD" == $HOME/ ]]; then
        PS1='\H:~\$ '
    elif [[ "$PWD" == $HOME/* ]]; then
        part="${PWD#$HOME/}"
        PS1="\H:~/$part\$ "
    else
        PS1='\H:\w\$ '
    fi
}
PROMPT_COMMAND=set_prompt

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

