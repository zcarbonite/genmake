#!/bin/bash

### Generates makefiles for C/C++ sourcefiles

#VARIABLES
SRC=""
TARGET=""
LIBS=""
TARGET="main"
CFLAGS=""
INCPATH=""
LIBPATH=""
TEMP="tempMakefile"
OUTFILE="Makefile"v
MAIN_CLASS="Main"
EXCLUDE=""
SPECIFIC=""
MAIN_SRC=""

VERSION="0.4.2"
SRC_EXT="cpp"
DIR="./"
OVERWRITE=0
AUTO=0
LANG=0
############### STATIC MAKEFILE GENERATION ###############
#
#

#create rule for a given source file
makeRule(){
	local deps=`g++ -MM $1`
	deps=$(echo $deps|sed 's/\\//')
	local rule=$deps
	
	[ "$deps" = "" ] && rm -f $TEMP && 
		echo "Makefile generation failed." && exit 2
	rule+='\n\t$(CXX) $(CFLAGS) $(INCPATH) -c $<\n'
	echo -e "\t$deps\n"
	echo -e $rule >> $TEMP	
}

#create standard makefile rules
endMakefile(){
	local rule='clean:\n\trm -f $(OBJ) $(TARGET)\n'
	rule+='run:\n\tmake --quiet\n\t./$(TARGET)\n'
	rule+='tar:\n\tmake clean; tar -cvf TARBALL.tar.gz *\n'
	echo -e $rule >> $TEMP
}

#checks to see if sourcefile has a main function defined
hasMain(){
	[ "`cat $1 | grep 'int main'`" != "" ] && return 1 || return 0
}

#find all elgible source files in a directory
setSources(){

	local count=0
	local location="*.$SRC_EXT"
	local match=0
	cd $DIR
	
	
	for srcFile in $location ; do 
		[ "$srcFile" = "$location" ] && break
		
		#if $srcFile is not in $SPECIFIC skip process
		if [ "$SPECIFIC" != "" ]; then
			match=0
			for spec in $SPECIFIC ; do
				if [ "$spec" = "$srcFile" ]; then
					match=1;
					break;
				fi
			done
			
			[ $match -eq 0 ] && continue;
		fi

		#if $srcFile is in $EXCLUDE then skip process
		if [ "$EXCLUDE" != "" ]; then
			match=0
			for exc in $EXCLUDE ; do
				if [ "$exc" = "$srcFile" ]; then
					match=1;
					break;
				fi
			done
			
			[ $match -eq 1 ] && continue;
		fi

		count=`expr $count + 1`
		echo -e "\t$srcFile"
		SRC+="$srcFile "
	done
	echo -e "$count source file(s) found.\n"
	[ $count -lt 1 ] && rm -f $TEMP && exit 1
}

#write the first part of the makefile
initMakefile(){
	
	local var="CXX = g++\n"
	var+="CFLAGS = $CFLAGS\n"
	var+="INCPATH = $INCL\n"
	var+="LIBS = $LIBS\n"
	var+="LIBPATH = $LIBPATH\n";
	var+="SRC = $SRC\n"
	var+='OBJ = $(SRC:.'
	var+="$SRC_EXT=.o)\n"
	var+="TARGET = $TARGET\n\n"

	local rule='$(TARGET): $(OBJ)\n\t$(CXX) $(LIBPATH) $(LIBS) $(OBJ) -o $@\n\n'

	echo -e $var > $TEMP
	echo -e $rule >> $TEMP
}

#call all necessary functions to build a functional makefile
createMakefile(){
	
	cd $DIR
	pwd
	if [ -e "$OUTFILE" ] && [ $OVERWRITE -eq 0 ]  ; then
		printf "Override current 'Makefile'? [y/n] "
		read reply
		[ "${reply:0:1}" != "y" ] && [ "${reply:0:1}" != "Y" ] && exit 3
	
	fi
	if [ $LANG -eq 1 ]; then
		createJavaMakefile
	else
		if [ $AUTO -eq 1 ]; then
			#writeGenericMakefile
			exit
		else 
			echo -e "\nFinding source files..."
			setSources
			echo -e "Generating makefile...\n"
			initMakefile
		
			for srcFile in $SRC ; do
				makeRule $srcFile;
			done
		
			endMakefile
		fi
	fi
	cat $TEMP > $OUTFILE 
	rm $TEMP
	echo "Makefile generated."
}

############### END OF STATIC MAKEFILE ##################


############### DYNAMIC MAKEFILE GENERATION ###############
#
#BUGGED
#
#writeGenericMakefile(){
#	echo "CC=g++" >> $TEMP
#	echo "TARGET=$TARGET" >> $TEMP
#	echo "LIBS=$LIBS" >> $TEMP
#	echo "CFLAGS=$CFLAGS" >> $TEMP
#	echo 'OBJECTS=$(addsuffix .o, $(basename $(shell ls *.'"$SRC_EXT )))" >> $TEMP
#	echo 'HEADERS=$(addsuffix .h, $(basename $(shell ls *.h )))' >> $TEMP
#	echo 'CLEAN_TARGETS=$(addsuffix .o, $(basename $(shell ls *.'"$SRC_EXT)))"'${TARGET} ${TEST_TARGET} *.rpo *.gch makefile.dep' >> $TEMP
	
#	echo -e '\nall: ${OBJECTS}\n\t${CC} ${LIBS} $^ -o ${TARGET}\n' >> $TEMP
#	echo -e '%.o:\n\t${CC} ${CFLAGS} -c ${LDFLAGS} $< -o $@\n' >> $TEMP
#	echo -e 'clean:\n\trm -f ${CLEAN_TARGETS}\n}' >> $TEMP
#	echo -e 'tar:\n\tmake clean; tar -cvf TARBALL.tar.gz *\n' >> $TEMP	
#	echo "makefile.dep:*.$SRC_EXT *.h" >> $TEMP
#	echo -e '\tfor i in *.'"$SRC_EXT"'; do gcc -MM "$${i}"; done > $@' >> $TEMP
#	echo -e 'include makefile.dep\n' >> $TEMP
#}

#	
############### END OF DYNAMIC MAKEFILE ###############


############### JAVA MAKEFILE GENERATION ################
# make executable jar package
## java -cfe $TARGET.jar $TARGET *.jar

createJavaMakefile(){
	echo "CC=javac" >> $TEMP
	echo "TARGET=$TARGET" >> $TEMP
	echo "MAIN_CLASS=$MAIN_CLASS" >> $TEMP
	echo "SRC=*.java" >> $TEMP
	echo -e 'OBJ = $(SRC:.java=.class)\n' >> $TEMP
	echo -e 'all: $(SRC)\n\tjavac $^\n' >> $TEMP
	echo -e '.java:\n\tjavac $@\n' >> $TEMP
	echo -e 'clean:\n\trm -f $(OBJ) $(TARGET).jar\n' >> $TEMP
	echo -e 'jar:\n\tmake --quiet' >> $TEMP
	echo -e '\n\tjar -cfe $(TARGET).jar $(MAIN_CLASS) *.class\n' >> $TEMP
}
#
############### END OF JAVA MAKEFILE ################

displayHelp(){
	echo "Usage: gmake [options]"
	echo "Options:"

#	echo -e "--auto\t\t\tCreate a dynamic makefile that will change with your"
#	echo -e "\t\t\tsource code, recommended as 'test' makefile, but not final.\n"

	echo -e "--dir\t\t\tChange directory before doing anything"
	echo -e "\t--dir DIRECTORY\n"

	echo -e "--exc\t\t\tSpecify source files to exclude from makefile"
	echo -e "\t--exc FILE1 FILE2...\n"

	echo -e "--out\t\t\tSpecify target executable, otherwise 'main' used"
	echo -e "\t--exe TARGET\n"

	echo -e "--ext\t\t\tSpecify source file extension, otherwise 'cpp' used"
	echo -e "\t--ext EXTENSION\n"

	echo -e "--flg\t\t\tAdd compilation flags to makefile"
	echo -e "\t--flg FLAG1 FLAG2...\n"

	echo -e "--force\t\t\tDo not warn about overwriting found makefile\n"
	echo -e "--help\t\t\tDisplay this help message and exit\n"

	echo -e "--inc\t\t\tAdd include paths to makefile"
	echo -e "\t--inc PATH1 PATH2...\n"

	echo -e "--lib\t\t\tAdd build libraries to makefile"
	echo -e "\t--lib LIBRARY1 LIBRARY2...\n"

	echo -e "--libpath\t\t\tAdd library paths to makefile"
	echo -e "\t--libpath PATH1 PATH2...\n"

	echo -e "--only\t\t\tOnly use specified source files in makefile"
	echo -e "\t--only FILE1 FILE2...\n"
	

	echo -e "--java\t\t\tCreate makefile for java source\n"

	echo -e "--mc\t\t\tUsed in conjunction with '--java' to specify main class"
	echo -e "\t--mc MAIN\n"

	echo -e "--pkg\t\t\tAdd libraries and flags using pkg-config"
	echo -e "\t--pkg PKGNAME\n"

	echo -e "--version\t\t\t Display gmake version.\n"
		
	echo -e "\nThis program was created to generate makefiles based on given source files.\n"	
}

dispVersion(){
	echo "gmake $VERSION"
	echo "This is free software. There is NO warranty; not even for"
	echo -e "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n"
}

handleArgs(){
	
	local flag=0
	
	for arg in $* ; do
		
		if [ "$arg" = "--help" ] ; then
			displayHelp
			exit
		elif [ "$arg" = "--dir" ] ; then
			flag=1
			continue
			
		elif  [ "$arg" = "--ext" ] ; then
			flag=2
			continue
			
		elif [ "$arg" = "--inc" ] ; then
			flag=3
			continue
			
		elif [ "$arg" = "--out" ] ; then
			flag=4
			continue
			
		elif [ "$arg" = "--lib" ] ; then
			flag=5
			continue
			
		elif [ "$arg" = "--flg" ] ; then
			flag=6
			continue
		elif [ "$arg" = "--exc" ] ; then
			flag=7
			continue
		
		elif [ "$arg" = "--only" ]; then
			flag=8
			continue

		elif [ "$arg" = "--libpath" ]; then
			flag=9
			continue

		elif [ "$arg" = "--force" ]; then
			flag=10
			OVERWRITE=1
			continue
#		elif [ "$arg" = "--auto" ]; then
#			flag=11
#			AUTO=1
#			continue
		elif [ "$arg" = "--java" ]; then
			flag=12
			LANG=1
			continue
		elif [ "$arg" = "--mc" ]; then
			flag=13
			continue
		elif [ "$arg" = "--version" ]; then
			flag=14
			dispVersion
			exit
			continue
		elif [ "$arg" = "--pkg" ]; then
			flag=15
			continue			
		fi
				
		case $flag in
			( 1 ) 	DIR=$arg;
				echo "DIR: $DIR"; 
				flag=0; 
				continue ;;

			( 2 ) 	SRC_EXT=$arg;
				echo "SRC_EXT: $SRC_EXT"; 
				flag=0; continue ;;

			( 3 ) 	INCPATH+="$arg ";
				echo "INCPATHUDE PATHS: $INCL"; 
				#flag=0; 
				continue ;;

			( 4 ) 	TARGET=$arg;
				echo "TARGET: $TARGET"; 
				flag=0; continue ;;

			( 5 ) 	LIBS+="$arg "; 
				#echo "LIBS: $LIBS";
				#flag=0; 
				continue ;;

			( 6 ) 	CFLAGS+="$arg "; 
				echo "CFLAGS: $CFLAGS";
				#flag=0 ; 
				continue;;
		
			( 7 ) 	EXCLUDE+="$arg "; 
				continue;;
				
			( 8 ) 	SPECIFIC+="$arg ";
				echo "SPECIFIC FILES: $SPECIFIC";
				continue;;

			( 9 )   LIBPATH+="$arg ";
				echo "LIBPATH: $LIBPATH";
				continue;;
			( 13 ) MAIN_CLASS="$arg";
			       echo "MainClass: $MAIN_CLASS";
			       flag=0; continue;;
			( 15 ) 
			       LIBS+=`pkg-config --libs $arg`; 
			       CFLAGS+=`pkg-config --cflags $arg`; 
			       continue;;
			( * ) flag=0 ;;
		esac
	done
	
	[ "$CFLAGS" != "" ] && echo "CFLAGS: $CFLAGS;";		
	[ "$LIBS" != "" ] && echo "LIBS: $LIBS";
	[ "$EXCLUDE" != "" ] && echo "EXCLUDE FILES: $EXCLUDE";		
	
	[ $# -gt 0 ] && [ $flag -eq 0 ] && echo "Invalid argument, run with '--help' for usage." && exit 2
}

handleArgs $*
createMakefile
