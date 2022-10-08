export EDITOR=/usr/bin/nvim
export QT_QPA_PLATFORMTHEME="qt5ct"
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
export AWS_VAULT_BACKEND=pass

# path modifications

## home directory bin folder
if [ -d $HOME/bin ]; then
    PATH=$PATH:~/bin
fi

## set path so it includes user's private bin if it exists
if [ -d ~/.local/bin ]; then
    PATH=$PATH:~/.local/bin
fi

## rust-lang
if [ -d ~/.cargo/bin ]; then
    PATH=$PATH:~/.cargo/bin
fi

## go-lang
if [ -d /usr/local/go/bin ]; then
    PATH=$PATH:/usr/local/go/bin
fi

## composer
if [ -d ~/.config/composer/vendor/bin ]; then
    PATH=$PATH:~/.config/composer/vendor/bin
fi

## yarn
if [ -d ~/.yarn/bin ]; then
  PATH=$PATH:~/.yarn/bin
fi
