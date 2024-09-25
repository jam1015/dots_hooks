

# some are options with a specific  value, some should be empty string to be set as false
export DOTSREBASE="true"

# ours vs theirs in rebase/merge is counterintuitive; this uses the intiutive names; so everything is treated like a merge
# https://stackoverflow.com/questions/25576415/what-is-the-precise-meaning-of-ours-and-theirs-in-git
export DOTSREBASESTRATEGY="theirs"
export DOTSMERGESTRATEGY="theirs"
export DOTSPULL=""   # variable to control pull actions
export DOTSPUSH=""   # variable to control push actions
export REAPPLYCHERRYPICKS=""
export RUN="true"
export STOW=""
export BREADTHFIRST=""
