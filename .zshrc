# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="mlee"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export CC=gcc

if [ -f ~/prod/bin/set_local_pathing.ksh ]; then
  . ~/prod/bin/set_local_pathing.ksh
else
  . ~/localPackage/prod/bin/set_local_pathing.ksh
fi

if [ -f ~/.aliases ]; then
  . ~/.aliases
else
  echo "MISSING .aliases"
fi

if [ -f ~/prod/bin/functions.ksh ]; then
  . ~/prod/bin/functions.ksh
else
  echo "MISSING functions.ksh"
fi

if [[ -f "/etc/rtsrtdrc" ]]; then
  . /etc/rtsrtdrc
fi

PATH=$PATH:/opt/hpremote/rgreceiver

export CVS_RSH=ssh
export EDITOR=vim
ulimit -c unlimited
alias ssh='ssh -Y $*'
alias rmc='rm -rf core.*'
alias rml='rm -rf log/*'
alias rmlc='rml;rmc'
alias rmcl='rml;rmc'
alias ctags='find . -name *.cpp -o -name *.h -o -name *.hpp | xargs ctags -R --language-force=c++ --extra=+q --fields=+i'

export LANG=C
export USE_LOG_AGGREGATOR=0
unset WH_BUFFERED_LOGGING_SIZE
