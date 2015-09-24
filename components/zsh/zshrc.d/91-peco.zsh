function peco--insert-commandline() {
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

function peco-find() {
  local filepath="$(find . | grep -v '/\.' | peco --prompt 'PATH>')"
  peco--insert-commandline $filepath
}

function peco-find_dep2() {
  local filepath="$(find . -maxdepth 2 | grep -v '/\.' | peco --prompt 'PATH>')"
  peco--insert-commandline $filepath
}

function peco-ls() {
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
  local filepath="./$(custom-ls | peco --prompt 'PATH>')"
  peco--insert-commandline $filepath
  return
}

zle -N peco-find
bindkey -r '^D'
bindkey '^D' peco-find

zle -N peco-find_dep2
bindkey -r '^F'
bindkey '^F' peco-find_dep2

zle -N peco-ls
bindkey -r '^L'
bindkey '^L' peco-ls

function agvim() {
  local data="$(ag $@ | peco)"
  local filepath="$(echo $data | awk -F : '{print $1}')"
  local lineno="$(echo $data | awk -F : '{print $2}')"
  [ -z "$filepath" ] && return
  if [ -f "$filepath" ]; then
    vim -c $lineno "$filepath"
  fi
}

