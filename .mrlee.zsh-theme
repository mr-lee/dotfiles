# mlee.zsh-theme
#
# Author: Matt Lee
# Derived from Andy Fleming's af-magic - all credit to him
#
# Created on:		April 02, 2013
# Last modified on:	April 02, 2013



if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="green"; fi
local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"

# color vars
eval my_gray='$FG[237]'
eval my_orange='$FG[214]'
eval my_blue='$FG[032]'
eval my_green='$FG[108]'
eval my_red='$FG[202]'
eval my_yellow='$FG[226]'

# primary prompt
PROMPT='$my_gray------------------------------------------------------------%{$reset_color%} 
%{$my_blue%}%~\
$(git_prompt_info) \
%{$my_yellow%}%(!.#.$)%{$reset_color%} '
PROMPT2='%{$fg[red]%}\ %{$reset_color%}'
RPS1='${return_code}'

# right prompt
RPROMPT='$my_orange%n@%m $my_green%T%{$reset_color%}'

# git settings
ZSH_THEME_GIT_PROMPT_PREFIX="$my_green(branch:"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="$my_red*%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$my_green)%{$reset_color%}"
