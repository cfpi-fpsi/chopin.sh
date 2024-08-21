#!/usr/bin/env sh

name="Application"
EXCLUDE_FILES="webxdc.js *.sh *.xdc *~"

function usage () {
    echo "Usage: ${0} [-hgp]"
    echo "  -h                  Display this message"
    echo "  -g                  Add pre-commit hook which formats and lints code"
    echo "  -p                  Optimize all files and pack the project as a WebXDC"
    exit -1
}

function add_pre_commit_hook () {
    :
}

# $1 - filename
function extract_toml () {
    while IFS='= ' read -r lhs rhs; do
	if [[ ! $lhs =~ ^\ *# && -n $lhs ]]; then
            rhs="${rhs%%\#*}"
            rhs="${rhs%%*( )}"
            rhs="${rhs%\"*}"
            rhs="${rhs#\"*}"
            declare -g $lhs="$rhs"
	fi
    done < $1
}

function webxdc_create () {
    [[ ! -f ./index.html ]] && echo "Webxdc requires it's apps to have AT LEAST an index.html. Aborting." && exit -1

    # This doesn't work if source code is in a seperate directory. The
    # culprit is cp. Should use find or something and preserve
    # directories. In essence, this should find all source files and
    # preserve their parent directories in the temp/ directory.
    if [[ -x "$(command -v minify)" ]]; then
	echo "Minifying all source files."
	mkdir temp
	cp -r *.html *.css *.js temp/
	minify -r *.html *.js *.css -o ./
    else
	echo "minify command not found. Proceeding without minifying."
    fi
    
    echo "Removing all existing xdc packages."
    rm -f *.xdc

    if [[ -f ./manifest.toml ]]; then
	echo "Extracting name from manifest.toml."
	extract_toml manifest.toml
    else
	echo "No manifest.toml found. Using default application name."
    fi

    if [[ -x "$(command -v zip)" ]]; then
	echo "Packing project into an xdc package."
	zip -9 --recurse-paths "${name}.xdc" --exclude $EXCLUDE_FILES -- * > /dev/null
	echo "Output: ${name}.xdc."
	mv temp/* .
	rmdir temp
    else
	echo "The program zip could not be found. It is required to pack Webxdc applications. Aborting."
	exit -1
	mv temp/* .
	rmdir temp
    fi
}

[[ "$#" -eq 0 ]] && usage
while getopts ":hgp" option; do
    case ${option} in
	h)
	    usage
	    ;;
	g)
	    add_pre_commit_hook
	    ;;
	p)
	    webxdc_create
	    ;;
	\?)
	    echo "Invalid option -${OPTARG}"
	    usage
	    ;;
    esac
done
