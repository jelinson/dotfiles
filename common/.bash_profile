export EDITOR=emacs

export rc=~/.bash_profile
export em=~/.emacs
export asses=~/.bash_aliases

ep() { subl "$rc"; }
ass() { subl "$asses"; }
rsc() { source "$rc"; }

[ -f ~/.bash_aliases ] && source ~/.bash_aliases

export PS1="\[\e[1;35m\]\u@\h \W\$ \[\e[m\] "

[ -d "/Applications/Sublime Text.app" ] \
  && export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv bash)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv bash)"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

command -v rbenv &>/dev/null && eval "$(rbenv init - bash)"

[ -f ~/.bash_profile.local ] && source ~/.bash_profile.local
