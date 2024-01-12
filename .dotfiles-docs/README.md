# Dot Files

Tutorial taken from here: https://www.atlassian.com/git/tutorials/dotfiles

Instructions copied below in case the article ever goes away.

# Installing the dot files on a new system

If you already store your configuration/dotfiles in a Git repository, on a new system you can migrate to this setup with the following steps:

Clone your dotfiles into a bare repository in a "dot" folder of your $HOME:

`git clone --bare <git-repo-url> $HOME/.dotfiles`

Define the alias in the current shell scope:

`alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'`

Checkout the actual content from the bare repository to your $HOME:

`config checkout`

The step above might fail with a message like:
```
error: The following untracked working tree files would be overwritten by checkout:
    .bashrc
    .gitignore
Please move or remove them before you can switch branches.
Aborting
 ```
This is because your $HOME folder might already have some stock configuration files which would be overwritten by Git. The solution is simple: back up the files if you care about them, remove them if you don't care.

Re-run the check out if you had problems:

`config checkout`

Set the flag showUntrackedFiles to no on this specific (local) repository:

`config config --local status.showUntrackedFiles no`

You're done, from now on you can now type config commands to add and update your dotfiles:

```
config status
config add .vimrc
config commit -m "Add vimrc"
config add .bashrc
config commit -m "Add bashrc"
config push
```
