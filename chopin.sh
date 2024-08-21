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
    echo "Creating WebXDC package."
    echo "Removing all existing XDC packages."
    rm -f *.xdc

    echo "Extracting name from manifest.toml."
    [[ -f ./manifest.toml ]] && extract_toml manifest.toml
    
    echo "Packing project into an XDC package."
    zip -9 --recurse-paths "${name}.xdc" --exclude $EXCLUDE_FILES -- * > /dev/null
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
