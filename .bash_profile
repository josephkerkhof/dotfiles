#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# force bash to source the generic profile directory
if [ -f ~/.profile ]; then
  source ~/.profile
fi
