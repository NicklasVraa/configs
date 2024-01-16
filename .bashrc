# Desc: ~/.bashrc: executed by bash(1) for non-login shells.
# Auth: Nicklas Vraa

# SETUP: -----------------------------------------------------------------------
case $- in
    *i*) ;;
      *) return;;
esac

# Bash command-history configs.
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize
shopt -s extglob

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	    color_prompt=yes
    else
	    color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls -AF --color=auto --group-directories-first'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Source .bash_private if it exists.
if [ -f "$HOME/.bash_clipboard" ]; then
    . "$HOME/.bash_clipboard"
fi

# KEYBINDS: --------------------------------------------------------------------

# Remappings to allow for ctrl-c copying, ctrl-v pasting, and ctrl-q interrupt.
# To see current mappings, run: stty -a
stty lnext ^l; stty start ^p; stty intr ^q

# ALIASES: ---------------------------------------------------------------------

# General convenience.
alias ll='ls -l'
alias cl='clear'
alias edrc='code ~/.bashrc'
alias rlrc='echo "Reloading bashrc"; source ~/.bashrc'
alias update='sudo apt update && sudo apt upgrade'
alias fetch='neofetch'
alias space='du -sh ~/* | sed "s/\/home\/$USER\///"'
alias python='python3'

# Maintenance.
alias kernels="sudo dpkg --list | egrep 'linux-image|linux-headers|linux-modules'"
alias brokelinks="find . -xtype l"

# Launchers
alias retroarch='/opt/retroarch.AppImage'

# FUNCTIONS: -------------------------------------------------------------------

# Convert number of characters to words and pages.
char2page() {
    local page_count=$(($1 / 1700))
    echo "Estimated pages: $page_count"
}

# Activate virtual environments.
activate() {
    if [ $# -eq 0 ]; then
        echo "No environemt name provided."
    else
        source ~/.venv/$1/bin/activate
    fi
}

# Remove clutter.
clean() {
    sudo apt clean # Empty package manager cache.

    echo "Deleting excess logs"
    sudo rm -rf /var/log/journal/*
    sudo rm -rf /var/log/timeshift/*
    sudo rm -rf /var/log/cups/*
    sudo rm -f /var/log/*.log.*gz
    sudo rm -f /var/log/dmesg.*.gz
    sudo rm -f /var/log/syslog.*.gz
    sudo rm -f /var/log/vbox-setup.log.*
    sudo rm -f /var/log/Xorg.*.log.old
    sudo rm -f /var/log/lightdm/*.log.*.gz

    echo "Purging firefox clutter"
    rm -rf ~/.mozilla/firefox/Crash\ Reports/*
    rm -rf ~/.mozilla/firefox/*.default-release/bookmarkbackups
    rm -rf ~/.mozilla/firefox/*.default-release/datareporting/archived
    rm -rf ~/.mozilla/firefox/tskxltgb.default-release/weave/logs
    rm -rf ~/.mozilla/firefox/tskxltgb.default-release/storage/default/http* # Offline data cache.

    echo "Resetting xsession logs"
    >~/.xsession-errors
    rm -f ~/.xsession-errors.old

    echo "Deleting coredumps"
    sudo systemd-tmpfiles --clean
    sudo rm -rf /var/lib/systemd/coredump/*

    echo "Resetting command history"
    history -c
    cat /dev/null > ~/.bash_history
    cat /dev/null > ~/.python_history

    echo "Clearing caches"
    rm -rf ~/.cache/mozilla # Clear home folder cache.
    rm -rf ~/.config/Code/Cache/Cache_Data/* # Clear VSCode cache.
    rm -rf ~/.config/Code/CachedData/*
    rm -rf ~/.config/obsidian/Cache_Data/* # Clear Obsidian cache.

    echo "Emptying trash folders"
    trash-empty # Empties trash folders on all drives.

    echo "Finished"
}

# Cut or convert video.
video() {
    if [ $# -eq 0 ]; then
        echo "No arguments provided."
    elif [ $1 = "cut" ]; then
        ffmpeg -ss $3 -to $4 -i $2 -c copy cut_$2
    elif [ $1 = "convert" ]; then
        file=$2
        name=$(echo "${file%.*}")
        echo $name
        ffmpeg -i $file -codec copy $name.$3
    elif [ $1 = "mute" ]; then
        ffmpeg -an -i $2 -c copy muted_$2
    else
        echo "Invalid parameter. Try these:"
        echo "  video cut file.ext 00:01:00 00:02:00"
        echo "  video convert file.ext mp4"
    fi
}

# Tex Live Package Manager shortcuts.
lpm() {
    if [ $# -eq 0 ]; then
        echo "No arguments provided."
    elif [ $1 = "run" ]; then
        sudo tlmgr --gui
    elif [ $1 = "clean" ]; then
        sudo tlmgr backup --all --clean=0
    else
        echo "Invalid argument."
    fi
}

# Download track, playlist, album, etc. from a spotify url.
dl() {
    if [ $# -eq 0 ]; then
        echo "No link provided."
    else
        echo "Attempting to download music..."
        cd /media/nv/Storage/Music/
        activate spotdl
        spotdl $1
        deactivate
        cd
    fi
}

# Copy config files to a version-controlled directory.
configs-sync() {
    sudo cp ~/.bashrc /opt/nova/configs/.bashrc
    sudo cp /etc/nanorc /opt/nova/configs/.nanorc
    sudo cp ~/.config/neofetch/config.conf /opt/nova/configs/neofetch/config.conf
    sudo cp ~/.config/neofetch/nova.txt /opt/nova/configs/neofetch/nova.txt
    sudo cp ~/.config/gtk-3.0/gtk.css /opt/nova/configs/gtk.css
}

# Reset Rhythmbox library paths.
rhythmbox-reset() {
    gsettings set org.gnome.rhythmbox.rhythmdb locations "['file:///dev/null']"
}

# Purge unwanted fonts.
purge-fonts() {
    echo "Purging highly specialized fonts..."
    sudo apt purge fonts-beng fonts-beng-extra fonts-deva fonts-deva-extra fonts-gargi fonts-gubbi fonts-gujr fonts-gujr-extra fonts-guru fonts-guru-extra fonts-indic fonts-kalapi fonts-khmeros-core fonts-knda fonts-lao fonts-lklug-sinhala fonts-lohit-* fonts-mlym fonts-nakula fonts-navilu fonts-orya fonts-orya-extra fonts-pagul fonts-sahadeva fonts-samyak-* fonts-sarai fonts-sil-* fonts-smc fonts-smc-* fonts-taml fonts-telu fonts-telu-extra fonts-thai-tlwg fonts-tibetan-machine fonts-tlwg-* fonts-wqy-microhei fonts-noto-cjk fonts-takao-pgothic fonts-tibetan-machine  ttf-ancient-fonts-symbola

    echo "Removing corresponding folders..."
    cd /usr/share/fonts/truetype
    sudo rm -rf abyssinica crosextra fonts-beng-extra fonts-deva-extra fonts-gujr-extra fonts-guru-extra fonts-kalapi fonts-orya-extra fonts-telu-extra Gargi Gubbi kacst kacst-one lao lohit-* malayalam Nakula Navilu padauk pagul Sahadeva samyak samyak-fonts Sarai sinhala tibetan-machine tlwg ttf-khmeros-core

    cd
    echo Recreating the font cache...
    sudo fc-cache -r
    sudo fc-cache -fv
}
