if [ -v TMUX ]; then
  FZF="fzf-tmux"
  FZF_OPTION="-u 70%"
else
  FZF="fzf"
  FZF_OPTION=""
fi

function fzf--insert-commandline() {
  local filepath="$1"
  [ -z "$filepath" ] && return
  if [ -n "$LBUFFER" ]; then
    BUFFER="${LBUFFER}${filepath}"
  else
    if [ -d "$filepath" ]; then
      BUFFER="cd $filepath"
    elif [ -f "$filepath" ]; then
      BUFFER="$EDITOR $filepath"
    fi
  fi
  CURSOR=$#BUFFER
}

function fzf-find() {
  local filepath="$(find . | grep -v '/\.' | $FZF $FZF_OPTION --prompt 'PATH>')"
  fzf--insert-commandline $filepath
}

function fzf-find_dep2() {
  local filepath="$(find . -maxdepth 2 | grep -v '/\.' | $FZF $FZF_OPTION --prompt 'PATH>')"
  fzf--insert-commandline $filepath
}

function fzf-ls() {
  function custom-ls() {
    case $(uname) in
    Darwin*)
      /bin/ls
      /bin/ls -A | grep "^\."
      ;;
    Linux*)
      /bin/ls --color='never'
      /bin/ls --color='never' -A | grep "^\."
      ;;
    *)
      /bin/ls
      ;;
    esac
  }
  local filepath="./$(custom-ls | $FZF $FZF_OPTION --prompt 'PATH>')"
  fzf--insert-commandline $filepath
  return
}

zle -N fzf-find
bindkey -r '^S'
bindkey '^S' fzf-find

zle -N fzf-find_dep2
bindkey -r '^D'
bindkey '^D' fzf-find_dep2

zle -N fzf-ls
bindkey -r '^F'
bindkey '^F' fzf-ls

function agvim() {
  local data="$(ag $@ | fzf)"
  local filepath="$(echo $data | awk -F : '{print $1}')"
  local lineno="$(echo $data | awk -F : '{print $2}')"
  [ -z "$filepath" ] && return
  if [ -f "$filepath" ]; then
    vim -c $lineno "$filepath"
  fi
}

