#/bin/bash

#########################################################################################
#
# Name:   install_fullenv.sh
#
# Info:   Script installs environment for building projects for SPIDisplays with hardware like esp32, arduino, etc...
#
# Author: Vitaliy Novoselov
#
# URI:    
#
#########################################################################################

function ProfileRemoveLines {

# !!! not working yet !!!
echo function ProfileRemoveLines not working yet!
break

# ProfileRemoveLines File Variable[ substing1[ substring2[ ...]]]
# Remove all lines that contains specified strings:

  if [ '$#' lt '2' ]
  then
    local TMP="/var/tmp/PRL_tmp.func"
    local FILE=$1
    local STRING="grep -Hn \""$2"\" $FILE | head -n +1 "
    shift
    while [ -n "$2" ]
    do
	STRING=$STRING+"| grep \""$2"=\""
	shift
    done


    while true; do
        src_line=$( $STRING | sed 's/:/\t/g' | awk '{print $2}')
        echo
        echo $src_line
        echo

        if [ "$src_line" = "" ]
        then
                break
        fi

        # remove old esp-idf

        if [ -f "$TMP" ]
        then 
                rm $TMP
        fi

        #mv $FILE tmp

        src_pre=$(bc -l <<<$src_line'-1')
        src_post=$(bc -l <<<$src_line'+1')

        #touch $FILE
	cat "" >  $FILE

        head -n +$src_pre $TMP >> $FILE
        tail -n +$src_post $TMP >> $FILE

        rm $TMP

    done

  else
    echo Error in script! Calling function ProfileRemoveLines need minimum 2 args: File variable_name[ search_string2[ ...]]
  fi
}

############################################################# Start script ########################################################

# Install packages
echo Install packages 
sudo apt install dialog gawk gperf grep gettext libncurses-dev python python-dev automake bison flex texinfo help2man libtool libtool-bin gcc git wget make libncurses-dev flex python-pip python-setuptools python-serial python-cryptography python-future python-pyparsing python-pyelftools cmake ninja-build ccache

# User profile file (usualy ~/.profile)
PROFILE=~/.profile

# Setting version of esp-idf to download
result=$( git ls-remote --tags --refs https://github.com/espressif/esp-idf.git | sed 's/.*tags\///' )
if [ "$1" = "" ]
then
	readarray -t a < <( git ls-remote --tags --refs https://github.com/espressif/esp-idf.git | sed 's/.*tags\///' )
	i=0
	for each in "${a[@]}"
	do
	  i=$(bc -l <<<$i'+1')
	  a[$i]=$each" "${a[$i]}" "
	done

	# Menu for version selection
	exec 3>&1;
	version=$(dialog --title "git" --menu "Please choose" 25 35 15 ${a[@]} 0 0 2>&1 1>&3)
	exitcode=$?
	exec 3>&-
	echo $exitcode
else 
	version=$1
fi

echo "-----> $version"


INSTALL_PATH=$( pwd )
IDF_PATH=$( pwd )/esp-idf
echo export IDF_PATH=$IDF_PATH

# Remove all IDF_PATH from profile:
while true; do
	src_line=$(grep -Hn "IDF_PATH" $PROFILE | head -n +1  | sed 's/\(:[^:]*\)\{1\}$//' | sed 's/.*://' | sed 's/* //')
	echo
	echo $src_line
	echo

	if [ "$src_line" = "" ]
	then
		break
	fi

	# remove old esp-idf

	if [ -f "tmp.h" ]
	then 
	        rm tmp
	fi

	mv $PROFILE tmp

        src_pre=$(bc -l <<<$src_line'-1')
        src_post=$(bc -l <<<$src_line'+1')

	touch $PROFILE

	head -n +$src_pre ./tmp >> $PROFILE
	tail -n +$src_post ./tmp >> $PROFILE

	rm tmp

done

# Add new entry with IDF_PATH to profile
echo export IDF_PATH=$IDF_PATH >> $PROFILE


echo Installing ESP-IDF version: $version.

echo clonning...
git clone -b $version --recursive https://github.com/espressif/esp-idf.git

cd $IDF_PATH

echo downloading modules...
# git fetch
# git checkout $version
git submodule update --init --recursive

echo installing
#./install.sh
#. ./export.sh
chmod 760 ./add_path.sh
./add_path.sh

python2.7 -m pip install --user -r $IDF_PATH/requirements.txt


echo getting arduino-esp32...

cd $INSTALL_PATH
sudo usermod -a -G dialout $USER
wget https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py
sudo pip install pyserial
git clone https://github.com/espressif/arduino-esp32.git arduino-esp32
cd arduino-esp32
git submodule update --init --recursive
cd $INSTALL_PATH
python3 $INSTALL_PATH/arduino-esp32/tools/get.py

#remove ARDUINO_ESP32_PATH from profile
while true; do
        src_line=$(grep -Hn "PATH=" ~/.profile | grep "arduino-esp32" | head -n +1  | sed 's/:/\t/g' | awk '{print $2}')
        echo
        echo $src_line
        echo

        if [ "$src_line" = "" ]
        then
                break
        fi

        # remove old esp-idf

        if [ -f "tmp.h" ]
        then 
                rm tmp
        fi

        mv $PROFILE tmp

        src_pre=$(bc -l <<<$src_line'-1')
        src_post=$(bc -l <<<$src_line'+1')

        touch $PROFILE

        head -n +$src_pre ./tmp >> $PROFILE
        tail -n +$src_post ./tmp >> $PROFILE

        rm tmp

done

echo export ARDUINO_ESP32_PATH=$INSTALL_PATH/arduino-esp32 >> $PROFILE
export ARDUINO_ESP32_PATH=$INSTALL_PATH/arduino-esp32

#remove PATH with xtensa from profile
while true; do
        src_line=$(grep -Hn "PATH=" ~/.profile | grep "xtensa" | head -n +1  | sed 's/:/\t/g' | awk '{print $2}')
        echo
        echo $src_line
        echo

        if [ "$src_line" = "" ]
        then
                break
        fi

        # remove old esp-idf

        if [ -f "tmp.h" ]
        then 
                rm tmp
        fi

        mv $PROFILE tmp

        src_pre=$(bc -l <<<$src_line'-1')
        src_post=$(bc -l <<<$src_line'+1')

        touch $PROFILE

        head -n +$src_pre ./tmp >> $PROFILE
        tail -n +$src_post ./tmp >> $PROFILE

        rm tmp

done

echo export PATH='$PATH':$(pwd)/xtensa-esp32-elf/bin >> $PROFILE
PATH=$PATH:$(pwd)/xtensa-esp32-elf/bin
cd ..

cd $ARDUINO_ESP32_PATH
echo getting TFT_eSPI
cd libraries
git clone https://github.com/Bodmer/TFT_eSPI
echo

echo configuring TTGO-T-Display
cd TFT_eSPI
git clone https://github.com/Xinyuan-LilyGO/TTGO-T-Display
echo

cp TTGO-T-Display/TTGO_T_Display.h User_Setups
if [ -f "tmp.h" ]
then
	rm tmp.h
fi
cp User_Setup_Select.h tmp.h
rm User_Setup_Select.h
sed '1 i #include <User_Setups/TTGO_T_Display.h>' tmp.h >> User_Setup_Select.h
#grep -Hn "include" ./User_Setup_Select.h | sed 's/\(:[^:]*\)\{1\}$//' | sed 's/.*://'
rm tmp.h

cd ../..

###################################################################################################
if [ -f "tmp.h" ]
then 
        rm tmp.h
fi
if [ -f "tmp.h" ]
then 
        rm ttmp.h
fi

if [ -f "CMakeLists.txt" ]
then

echo Adding TFT_eSPI to Library list...

cp CMakeLists.txt tmp.txt
src_line=$(grep -Hn "set(LIBRARY_SRCS" ./tmp.txt | sed 's/\(:[^:]*\)\{1\}$//' | sed 's/.*://')
tmp_s=$(bc -l <<<$src_line'+1')
sed $tmp_s' i   libraries/TFT_eSPI/TFT_eSPI.cpp' tmp.txt >> ttmp.txt

rm tmp.txt
mv ttmp.txt tmp.txt

###################################################################################################

echo Adding TFT_eSPI to Includes list...

	lib_line=$(grep -Hn "set(COMPONENT_ADD_INCLUDEDIRS" ./tmp.txt | sed 's/\(:[^:]*\)\{1\}$//' | sed 's/.*://')
	tmp_l=$(bc -l<<<$lib_line'+1')
	sed $tmp_l' i   libraries/TFT_eSPI' tmp.txt >> ttmp.txt

	rm tmp.txt

	#writing changes
	if [ -f "CMakeLists.txt.backup" ]
	then
	        rm CMakeLists.txt.backup
	fi

	mv CMakeLists.txt CMakeLists.txt.backup
	mv ttmp.txt CMakeLists.txt
else
	echo "   CMakeLists.txt - not found!"
fi

###################################################################################################

echo Adding TFT_eSPI to menuconfig...

if [ -f "Kconfig.projbuild" ]
then
	cp Kconfig.projbuild tmp.txt
	src_line=$(grep -Hn "config ARDUINO_SELECTIVE_SPIFFS" ./tmp.txt | sed 's/\(:[^:]*\)\{1\}$//' | sed 's/.*://')
	tmp=$(tail -n +$src_line ./tmp.txt | grep -Hn "default" | head -n +1 | sed 's/\(:[^:]*\)\{1\}$//' | sed 's/.*://' | sed 's/* //')
	dst_line=$(bc -l <<<$src_line'+1+'$tmp)
	sed $dst_line' i config ARDUINO_SELECTIVE_TFT_eSPI\n    bool "Enable TFT_eSPI"\n    depends on ARDUINO_SELECTIVE_COMPILATION\n    select ARDUINO_SELECTIVE_SPI\n    select ARDUINO_SELECTIVE_SPIFFS\n    default y\n' tmp.txt >> ttmp.txt
	rm tmp.txt

	#writing changes
	if [ -f "Kconfig.projbuild.backup" ]
	then
	        rm Kconfig.projbuild.backup
	fi

	mv Kconfig.projbuild Kconfig.projbuild.backup
	mv ttmp.txt Kconfig.projbuild

else
	echo "   Kconfig.projbuild - not found!"
fi

#cd $IDF_PATH
#cd ..
#git clone -b crosstool-ng-1.22.0 https://github.com/espressif/crosstool-NG
#cd crosstool-NG
#./bootstrap
#./configure --enable-local 
#make install
#./ct-ng xtensa-esp32-elf
