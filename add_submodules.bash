#/bin/bash
# Initialize the .config/emacs submodule
git submodule add git@github.com:plexus/chemacs2 .config/emacs

# Initialize the .oh-my-zsh submodule
git submodule add git@github.com:ohmyzsh/ohmyzsh.git .oh-my-zsh

# Initialize the .spacemacs submodule with the 'develop' branch
git submodule add -b develop git@github.com:syl20bnr/spacemacs .spacemacs

# Initialize the .doomemacs submodule
git submodule add git@github.com:doomemacs/doomemacs .doomemacs

# Initialize minpac submodule
git submodule add .vim/pack/minpac/opt/minpac
