#!/bin/bash
# This script deploy all of the plugin vim used on Ubuntu based OS

# Global used variables
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP_PATH=$SCRIPT_PATH/tmp-$RANDOM
VIM_BASE=~/.vim
VIM_BUNDLE=~/.vim/bundle
VIM_COLORS=~/.vim/colors

PRT_NO_ACT="[-]:"
PRT_NEW="[+]:"
PRT_UPDATE="[U]:"

PLUGINS_LIST=$SCRIPT_PATH/plugins.txt
COLORS_LIST=$SCRIPT_PATH/colors.txt
PACKAGE_LIST=$SCRIPT_PATH/packages.txt

# Global used functions
stage_print () {
	echo "*******************************************************"
	echo $1
	echo "*******************************************************"
}

check_folder () {
	echo "- Checking $1"
	if [ -d $1 ]; then
		echo "$PRT_NO_ACT $1 existed"
	else
		echo "$PRT_NEW $1 does not exist, creating ..."
		mkdir -p $1
	fi
	echo ""
}

# Creating, checking and updating VIM plugins
# Parameters:
# 1: URL for getting this plugin with git
check_plugin () {
	BASENAME=$(basename $1)
	BASENAME=${BASENAME%.*}
	echo "- Checking plugin $BASENAME"
	if [ -d $VIM_BUNDLE/$BASENAME ]; then
		echo "$PRT_UPDATE $BASENAME existed, updating"
		cd $VIM_BUNDLE/$BASENAME && git pull 
	else
		echo "$PRT_NEW $BASENAME does not exist, creating ..."
		cd $VIM_BUNDLE && git clone $1
	fi
	echo ""
}

# Get colors for VIM
# Parameters:
# 1: URL for getting this color with git
check_color () {
	FILENAME=$(basename $1)
	BASENAME=${FILENAME%.*}
	echo "- Checking color $BASENAME"
	if [ -f $VIM_COLORS/$FILENAME ]; then
		echo "$PRT_NO_ACT $BASENAME existed"
	else
		echo "$PRT_NEW $BASENAME does not exist, creating ..."
		cd $VIM_COLORS && wget $1
	fi
	echo ""
}

# Check packages installed
# Parameters:
# 1: Name of the package
check_package () {
echo "- Checking $1"
if ! dpkg -s $1 > /dev/null; then
	echo "$PRT_NEW $1 not installed, try to install"
	sudo apt-get -y install $1
else
	echo "$PRT_NO_ACT $1 installed"
fi
}

install_ctags () {
echo "- Checking ctags"
if ! CTAGS_PATH="$(type -p "ctags")" || [ -z "$CTAGS_PATH" ]; then
	echo "$PRT_NEW ctags does not exist, try to get it..."
	rm -rf $TMP_PATH
	mkdir $TMP_PATH
	cd $TMP_PATH && wget http://prdownloads.sourceforge.net/ctags/ctags-5.8.tar.gz
	tar -xf ctags-5.8.tar.gz
	cd $TMP_PATH/ctags-5.8 && ./configure && make && sudo make install
	rm -rf $TMP_PATH
else
	echo "$PRT_NO_ACT ctags existed $CTAGS_PATH"
fi
}

# 0. Environment checking
stage_print "Checking environment"
sudo apt-get -y install build-essential
sudo apt-get -y install cmake
sudo apt-get -y install vim
sudo apt-get -y install wmctrl
sudo apt-get -y install ack-grep
sudo apt-get -y install python2.7
sudo apt-get -y install python-dev

# 1. Check tools
stage_print "Checking tools"
# Get Ctags
install_ctags

# 2. Create necessary folders
stage_print "Checking the folder for the plugins of VIM"
check_folder $VIM_BASE
check_folder $VIM_BUNDLE 
check_folder $VIM_COLORS 

# 3. Deploy colors
stage_print "Deploying colors..."
while read COLOR_ITEM
do
	check_color $COLOR_ITEM
done < $COLORS_LIST

# 4. Deploy plugins
stage_print "Deploying plugins..."
while read PLUGIN_ITEM
do
	check_plugin $PLUGIN_ITEM
done < $PLUGINS_LIST

# Copy vim configuration file to user's home
cp $SCRIPT_PATH/../.vimrc ~/

# Additional steps for YouCompleteMe
if [ -d $VIM_BUNDLE/YouCompleteMe ]; then
	echo "- Update submodule of YouCompleteMe"
	cd $VIM_BUNDLE/YouCompleteMe
	git submodule update --init --recursive
	echo "- Get Clang 64bit"
	#Clang
	if [ "$(uname -m | grep '64')" ]; then
		if [ "$(uname -a | grep '14.04')" ]; then
			cd ~/Downloads
			rm -rf $TMP_PATH
			mkdir $TMP_PATH
			cd $TMP_PATH
			wget http://llvm.org/releases/3.7.0/clang+llvm-3.7.0-x86_64-linux-gnu-ubuntu-14.04.tar.xz
			tar -xf clang+llvm-3.7.0-x86_64-linux-gnu-ubuntu-14.04.tar.xz
			mkdir ycm_build
			cd ycm_build
			cmake -G "Unix Makefiles" -DPATH_TO_LLVM_ROOT=../clang+llvm-3.7.0-x86_64-linux-gnu-ubuntu-14.04 . ~/.vim/bundle/YouCompleteMe/third_party/ycmd/cpp
			make ycm_support_libs
		else
			echo "Warning: Not Ubuntu 14.04, please get Clang manually from http://llvm.org/releases/download.html"
			echo "Then depress to, for example ~/Downloads/clang"
			echo "cd ~/Downloads; mkdir ycm_build; cd ycm_build"
			echo "cmake -G "Unix Makefiles" -DPATH_TO_LLVM_ROOT=~/Downloads/clang/ . ~/.vim/bundle/YouCompleteMe/third_party/ycmd/cpp"
			echo "make ycm_support_libs"
		fi
	else
		echo "Error: Clang need x86_64 of Ubuntu, skip..."
	fi
fi
