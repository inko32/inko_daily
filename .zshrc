if [[ -n "${ZSH_VERSION:-}" && $- == *i* ]]; then
  export ZSH_CUSTOM_PLUGIN_DIR="${HOME}/.local/share/${USER}_zsh/plugins"
  # fastfetch -l none -s os:kernel:memory:uptime:battery:locale

  sysinfo() {
    local os_kernel="$(uname -s) $(uname -r) $(uname -m)"
    local mem_info=$(free -m | awk 'NR==2{printf "%.1fG/%.0fG (%d%%%)", $3/1024, $2/1024, ($3/$2)*100}')
    local up_time=$(uptime -p | sed 's/up //; s/ hours\?/h/g; s/ minutes\?/m/g; s/ days\?/d/g; s/,//g')
    local zsh_ver="zsh ${ZSH_VERSION}"

    local bat_dir=""
    for d in /sys/class/power_supply/BAT*; do
      [[ -d "$d" ]] && bat_dir="$d" && break
    done

    local bat_str="N/A"
    if [[ -n "$bat_dir" ]]; then
      local cap=$(< "$bat_dir/capacity")
      local p_status="$(< "$bat_dir/status")"
      local s="${p_status:l}"
      p_status=$([[ "$s" == *discharging* ]] && echo "Discharging" || echo "AC Connected")
      bat_str="${cap}%%[$p_status]"
    fi
    # print -P "%F{blue}${os_kernel}%f | Memory: %F{green}${mem_info}%f | Uptime: %F{yellow}${up_time}%f"
    # print -P "%F{magenta}${zsh_ver}%f | Locale: %F{white}${LANG:-en_US.UTF-8}%f | Battery: %F{cyan}${bat_str}%f"
    print -P "${os_kernel} | Memory: ${mem_info} | Uptime: ${up_time}"
    print -P "${zsh_ver} | Locale: ${LANG:-en_US.UTF-8} | Battery: ${bat_str}"
  }

  __minilolcat() { # default amplitude is 127(full), brightness = 128
    { (( $# > 0 )) && echo "$@" || cat } | awk '
    BEGIN { pi = 3.14; freq = 0.12; amplitude = 60; base_brightness = 190} {
        for (i = 1; i <= length($0); i++) {
            r = int(sin(freq * (NR + i) + 0) * amplitude + base_brightness);
            g = int(sin(freq * (NR + i) + 2 * pi / 3) * amplitude + base_brightness);
            b = int(sin(freq * (NR + i) + 4 * pi / 3) * amplitude + base_brightness);
            printf "\033[38;2;%d;%d;%dm%s\033[0m", r, g, b, substr($0, i, 1);
        }
        printf "\n";
    }'
  }

  init_interactive_zsh() {
    bindkey "\e[1;5C" forward-word      # Ctrl + Right
    bindkey "\e[1;5D" backward-word     # Ctrl + Left
    bindkey '^H' backward-kill-word
    # bindkey '^W' backward-kill-word # builtin, not useful
    # bindkey '^U' backward-kill-line # builtin
    # bindkey '^K' kill-line # builtin
    # bindkey '^A' beginning-of-line # builtin
    # bindkey '^E' end-of-line # builtin

    # bindkey '^[[A' history-search-backward
    # bindkey '^[OA' history-search-backward

    alias sudo='sudo '

    if command -v eza &>/dev/null; then
      alias ls='eza -al --color=always --group-directories-first --icons=always' # preferred listing
      alias la='eza -a --color=always --group-directories-first --icons=always'  # all files and dirs
      alias ll='eza -l --color=always --group-directories-first --icons=always'  # long format
      alias lt='eza -aT --color=always --group-directories-first --icons=always' # tree listing
      alias l.="eza -a | grep -e '^\.'"                                     # show only dotfiles
    else
      alias ls='ls -l --color=auto'
      alias ll='ls -alFh'
    fi

    alias ip='ip -color=auto -human-readable -pretty'
    alias df='df --human-readable --print-type'
    alias du='du --total --human-readable --summarize'
    alias grep='grep --color=auto'

    alias svba='source .venv/bin/activate'
    alias make="make -j`nproc`"
    alias ninja="ninja -j`nproc`"
    alias n="ninja"

    [[ -z "${aliases[tb]}" ]] && alias tb="nc termbin.com 9999" # cat << 'EOF' | tb
    alias c="clear"

    # cachyos fish useful
    alias tarnow='tar -acf '
    alias untar='tar -zxvf '
    alias wget='wget -c '
    alias psmem='ps auxf | sort -nr -k 4'
    alias psmem10='ps auxf | sort -nr -k 4 | head -10'
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
    alias .....='cd ../../../..'
    alias ......='cd ../../../../..'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias hw='hwinfo --short'                                   # Hardware Info
    alias big="expac -H M '%m\t%n' | sort -h | nl"              # Sort installed packages according to size in MB
    alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'          # List amount of -git packages


    # ArchLinux Exclusive

    alias rmpkg="sudo pacman -Rsn"
    alias cleanch="sudo pacman -Scc"
    alias fixpacman="sudo rm /var/lib/pacman/db.lck"
    alias update="sudo pacman -Syu"
    alias cleanup="sudo pacman -Rns \$(pacman -Qtdq)" # Cleanup orphaned packages
    alias jctl="journalctl -p 3 -xb" # Get the error messages from journalctl
    # Recent installed packages
    alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

    if ! command -v pacman &>/dev/null; then
      print -P "%F{red}[WARN] pacman is unavailable，arch-exclusive aliases like update, rmpkg will not work！%f"
    fi

    # man page
    export MANROFFOPT="-c"
    MANPAGER="sh -c 'col -bx | bat -l man -p'"

    # sudo pacman -S starship zoxide atuin
    (( $+commands[atuin] )) && source <(atuin init zsh --disable-up-arrow)
    (( $+commands[starship] )) && source <(starship init zsh)
    (( $+commands[zoxide] )) && source <(zoxide init zsh)


    autoload -U compinit && compinit -d "${ZSH_CUSTOM_PLUGIN_DIR}/.zcompdump"
    atuin config set inline_height_shell_up_key_binding 6

    autoload -U select-word-style
    select-word-style bash

  }

  init_inputrc() {
    set colored-completion-prefix on
    set colored-stats on
    set show-all-if-ambiguous on
    set reverrt-all-at-newline on
  }

  check_deps() {
    local missing_deps=()
    local has_pacman=false

    ref_missing=()
    ref_has_pacman=false

    command -v pacman &>/dev/null && ref_has_pacman=true

    typeset -A deps
    deps=(
      git       "git"
      atuin     "atuin"
      starship  "starship"
      zoxide    "zoxide"
      bat       "bat"
      nc        "openbsd-netcat"
      eza       "eza"
    )

    for cmd in ${(k)deps}; do
        if ! command -v "$cmd" &>/dev/null; then
            ref_missing+=("${deps[$cmd]}")
        fi
    done

    if [[ ${#ref_missing[@]} -gt 0 ]]; then
      print -P "%F{yellow}[WARN] Missing terminal efficiency tools detected: ${ref_missing[*]}%f"

      if [[ $ref_has_pacman == true ]]; then
        local missing_list="${ref_missing[*]}"
        print -P "%F{cyan}Run fix_zshrc_deps to automatically install them.%f"
        alias fix_zshrc_deps="
          print 'Installing missing components via pacman...';
          sudo pacman -S --needed $missing_list;\
          print 'Done. Please reopen your terminal or run source ~/.zshrc' ;
        "
      else
        print "Please install the dependencies manually."
      fi
    fi
  }

  load_zsh_plugins() {
    typeset -r autosuggest_file="${ZSH_CUSTOM_PLUGIN_DIR}/zsh-autosuggestions/zsh-autosuggestions.zsh"
    typeset -r syntax_highlight_file="${ZSH_CUSTOM_PLUGIN_DIR}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

    typeset -i failed=0
    [[ -f "$autosuggest_file" ]] && source "$autosuggest_file" || failed=1
    [[ -f "$syntax_highlight_file" ]] && source "$syntax_highlight_file" || failed=1

    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'  # Dark Gray

    if [[ $failed -eq 1 ]]; then
      print -P "%F{yellow}[WARN] zsh plugins missing, run: %F{cyan}fix_zsh_plugin%f%f"

      alias fix_zsh_plugin="
        print 'fixing zsh plugins...';
        mkdir -p '${ZSH_CUSTOM_PLUGIN_DIR}';

        [[ ! -d '${ZSH_CUSTOM_PLUGIN_DIR}/zsh-autosuggestions' ]] && \
          git clone https://github.com/zsh-users/zsh-autosuggestions.git '${ZSH_CUSTOM_PLUGIN_DIR}/zsh-autosuggestions';

        [[ ! -d '${ZSH_CUSTOM_PLUGIN_DIR}/zsh-syntax-highlighting' ]] && \
          git clone https://github.com/zsh-users/zsh-syntax-highlighting.git '${ZSH_CUSTOM_PLUGIN_DIR}/zsh-syntax-highlighting';

        print 'fix complete.';
        source ~/.zshrc
      "
    fi
  }
  sysinfo | __minilolcat
  check_deps
  load_zsh_plugins
  init_inputrc
  init_interactive_zsh

  # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
  # Initialization code that may require console input (password prompts, [y/n]
  # confirmations, etc.) must go above this block; everything else may go below.
  # if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  #   source "${XDG_CACHE_HOME:-$HOME/.cache}/p1z0k-instant-prompt-${(%):-%n}.zsh"
  # fi
  # below here should no output to stdout
  # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
  # [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

  # not using p10k, use starship instead.

fi

# the cachyos default config is not needed
# source /usr/share/cachyos-zsh-config/cachyos-config.zsh


zramfs() {
  local mount_point="/tmp/zramfs"
  case "$1" in
    mount)
      local size="24G"
      local zram_dev
      zram_dev=$(sudo zramctl --find --size "${size}") && \
      sudo mkfs.ext4 -O ^has_journal "${zram_dev}" && \
      sudo mkdir -p "${mount_point}" && \
      sudo mount -o noatime,discard "${zram_dev}" "${mount_point}" && \
      sudo chown -R $USER:$USER "${mount_point}" && \
      echo "mounted ${zram_dev} (${size}) to ${mount_point}"
      ;;
    unmount)
      local zram_dev
      zram_dev=$(findmnt -n -o SOURCE "${mount_point}") && \
      sudo umount "${mount_point}" && \
      sudo zramctl --reset "${zram_dev}" && \
      echo "reset done: ${zram_dev}"
      ;;
    *)
      echo "Usage: zramfs {mount|unmount}"
      ;;
  esac
  # Note: mount a zramfs
  # SIZE="24G"; MOUNT_POINT="/tmp/zramfs"; ZRAM_DEV=$(sudo zramctl --find --size "${SIZE}") && sudo mkfs.ext4 -O ^has_journal "${ZRAM_DEV}" && sudo mkdir -p "${MOUNT_POINT}" && sudo mount -o noatime,discard "${ZRAM_DEV}" "${MOUNT_POINT}" && sudo chown -R $USER:$USER "${MOUNT_POINT}" && echo "mounted ${ZRAM_DEV} (${SIZE}) to ${MOUNT_POINT}"
  # unmount
  # MOUNT_POINT="/tmp/zramfs"; ZRAM_DEV=$(findmnt -n -o SOURCE "${MOUNT_POINT}") && sudo umount "${MOUNT_POINT}" && sudo zramctl --reset "${ZRAM_DEV}" && echo "reset done: ${ZRAM_DEV}"
}
