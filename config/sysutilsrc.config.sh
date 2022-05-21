declare bashrc=$HOME/.bashrc
declare sysutils=$HOME/.sysutils;
declare rcline="source ${HOME}/.sysutils/sysutilsrc"

# Create folder sysutils if not exist, and sysutilsrc
mkdir -p $sysutils;
touch $sysutils/sysutilsrc

# Add .sysutilsrc in .bashrc if not exists
grep -qxF "$rcline" $bashrc || printf "\n$rcline\n" >> $bashrc;

source $bashrc;