if [[ -n "${ZSH_VERSION:-}" && $- == *i* ]]; then
  export ZSH_CUSTOM_PLUGIN_DIR="${HOME}/.local/share/${USER}_zsh/plugins"
  # interactive terminal configuration
  fastfetch -l none -s os:kernel:memory:uptime:battery:locale

  init_interactive_zsh() {
    bindkey "\e[1;5C" forward-word      # Ctrl + R
    bindkey "\e[1;5D" backward-word     # Ctrl + L
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

    alias tb="nc termbin.com 9999" # cat << 'EOF' | tb
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
    alias cleanup="sudo pacman -Rsn $(pacman -Qtdq)" # Cleanup orphaned packages
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
    command -v atuin &>/dev/null || ref_missing+=("atuin")
    command -v starship &>/dev/null || ref_missing+=("starship")
    command -v zoxide &>/dev/null || ref_missing+=("zoxide")
    command -v bat &>/dev/null || ref_missing+=("bat")

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
  check_deps
  init_interactive_zsh
  init_inputrc

  load_zsh_plugins() {
    typeset -r autosuggest_file="${ZSH_CUSTOM_PLUGIN_DIR}/zsh-autosuggestions/zsh-autosuggestions.zsh"
    typeset -r syntax_highlight_file="${ZSH_CUSTOM_PLUGIN_DIR}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

    typeset -i failed=0
    [[ -f "$autosuggest_file" ]] && source "$autosuggest_file" || failed=1
    [[ -f "$syntax_highlight_file" ]] && source "$syntax_highlight_file" || failed=1

    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'  # text colour of suggestion - dark grey

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
  load_zsh_plugins

  # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
  # Initialization code that may require console input (password prompts, [y/n]
  # confirmations, etc.) must go above this block; everything else may go below.
  # if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  #   source "${XDG_CACHE_HOME:-$HOME/.cache}/p1z0k-instant-prompt-${(%):-%n}.zsh"
  # fi
  # below here should no output to stdout
  # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
  # [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

fi



