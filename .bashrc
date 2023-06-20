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
stty lnext ^l
stty start ^p
stty intr ^q

# ALIASES: ---------------------------------------------------------------------

# General convenience.
alias ll='ls -l'
alias cl='clear'
alias rlrc='echo "Reloading bashrc"; source ~/.bashrc'
alias update='sudo apt update && sudo apt upgrade'
alias fetch='neofetch'
alias space='du -sh ~/* | sed "s/\/home\/$USER\///"'
alias python3='python3.10'
alias edit='nano'

# Maintenance.
alias kernels="sudo dpkg --list | egrep 'linux-image|linux-headers|linux-modules'"

# Edit configs.
alias edrc='code ~/.bashrc'
alias edvs='code ~/.vscode/vscode.css'
alias edte='code ~/.config/terminator/config'
alias ednf='code ~/.config/neofetch/config.conf'
alias edoo='code ~/.config/onlyoffice/DesktopEditors.conf'
alias edff='code ~/.mozilla/firefox/tskxltgb.default-release/chrome/userChrome.css'
alias edob='code /opt/nova/theme/Nova-galactic/obsidian/.obsidian/snippets/custom.css'
alias edsc='code /home/nv/.local/share/nemo/scripts'

# Launchers
alias retroarch='/opt/retroarch.AppImage'

# FUNCTIONS: -------------------------------------------------------------------

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
    rm -rf "~/.mozilla/firefox/Crash Reports/pending"
    rm -rf ~/.mozilla/firefox/*.default-release/bookmarkbackups
    rm -rf ~/.mozilla/firefox/*.default-release/datareporting/archived
    rm -rf ~/.mozilla/firefox/tskxltgb.default-release/weave/logs
    >~/.xsession-errors
    rm -f ~/.xsession-errors.old

    echo "Deleting coredumps"
    systemd-tmpfiles --clean
    sudo rm -rf /var/lib/systemd/coredump/*

    echo "Resetting command history"
    history -c
    cat /dev/null > ~/.bash_history
    cat /dev/null > ~/.python_history

    echo "Clearing caches"
    rm -rf ~/.cache/* # Clear home folder cache.
    rm -rf ~/.config/Code/Cache/Cache_Data/* # Clear VSCode cache.
    rm -rf ~/.config/Code/CachedData/*
    rm -rf ~/.config/obsidian/Cache_Data/* # Clear Obsidian cache.

    echo "Emptying trash folders"
    trash-empty # Empties trash folders on all drives.

    echo "Finished"
}

# Reset Rhythmbox library paths.
rhythmbox_path_reset() {
    gsettings set org.gnome.rhythmbox.rhythmdb locations "['file:///dev/null']"
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

# Activate Python virtual environments.
activate() {
    if [ $# -eq 0 ]; then
        echo "No environemt name provided."
    else
        source ~/.venv/$1/bin/activate
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

# Toggle monitor on or off.
toggle_monitor() {
    TOGGLE=$HOME/.monitor

    if [ ! -e $TOGGLE ]; then
        touch $TOGGLE
        xrandr --output DP-0 --mode 1920x1080 --rate 144.00
    else
        rm $TOGGLE
        xrandr --output DP-0 --off
    fi
}

# Toggle between PC and PC+TV. The TV is given sound.
toggle_tv() {
    TOGGLE=$HOME/.tv

    if [ ! -e $TOGGLE ]; then
        touch $TOGGLE
        echo "Turning on TV. Redirecting sound."

        # Move all running audio outputs to TV.
        OUTPUT="alsa_output.pci-0000_01_00.1.hdmi-stereo"
        pactl list short sink-inputs|while read stream; do
            id=$(echo $stream|cut '-d ' -f1)
            pactl move-sink-input "$id" "$OUTPUT"
        done

        pactl set-default-sink "$OUTPUT" # Set default audio output to TV.

        # Video.
        xrandr --output HDMI-0 --right-of DP-0 --mode 1920x1080 --rate 60.00
    else
        rm $TOGGLE
        echo "Turning off TV."

        # Move all running audio outputs to headphone jack.
        OUTPUT="alsa_output.pci-0000_00_1b.0.analog-stereo"
        pactl list short sink-inputs|while read stream; do
            id=$(echo $stream|cut '-d ' -f1)
            pactl move-sink-input "$id" "$OUTPUT"
        done

        pactl set-default-sink "$OUTPUT" # Set default audio output headphones.

        xrandr --output HDMI-0 --off # Video.
    fi
}

# Download track, playlist, album, etc. from a spotify url.
spotdl() {
    cd /media/nv/Storage/Music || cd ~/Downloads
    sudo docker run --rm -v $(pwd):/music spotdl/spotify-downloader download $1
    cd '/media/nv/Storage/'
    sudo chown -R nv:nv Music
    cd
}

sync_configs() {
    sudo cp ~/.bashrc /opt/nova/configs/.bashrc
    sudo cp /etc/nanorc /opt/nova/configs/.nanorc
    sudo cp ~/.config/neofetch/config.conf /opt/nova/configs/neofetch/config.conf
    sudo cp ~/.config/neofetch/nova.txt /opt/nova/configs/neofetch/nova.txt
    sudo cp ~/.config/gtk-3.0/gtk.css /opt/nova/configs/gtk.css
}

# Matlab Docker container operations.
# matlab() {
#    if [ $# -eq 0 ]; then
#        echo "No arguments provided"
#    elif [ $1 = "run" ]; then
#        docker run -it --rm\
#        -e DISPLAY=$DISPLAY \
#        -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
#        -v /home/nv/Projects:/home/matlab/Documents/MATLAB/Projects \
#        -v /home/nv/Studies:/home/matlab/Documents/MATLAB/Studies \
#        --shm-size=1024M mathworks/matlab:r2022b;
#    elif [ $1 = "save" ]; then
#        sudo docker commit $(sudo docker ps -lq) mathworks/matlab:r2022b
#    elif [ $1 = "install" ]; then
#        sudo docker pull mathworks/matlab:r2022b
#    else
#        echo "Invalid argument."
#    fi
# }
