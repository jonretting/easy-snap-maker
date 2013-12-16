#!/usr/bin/env bash
# NAME: AWS Easy Snapshot Maker
# DESC: Automates the snapshot creation process, aslo list snapshots and volumes
# GIT:
# URL: 
# 
# Copyright (c) 2013 Jon Retting
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
VERSION="0.03"

usage() {
	echo "AWS Easy Snapshot Maker v${VERSION}
Usage:   create-snap [-L | -V] | <tag-name> [-r region] [-a N] [-idpqvh] 
Example: create-snap my-snap-tag -z us-west-1 -a 2
-r     --region       AWS Region (required if \$EC2_URL env var is not set)
-L     --list         List snapshots (stdout= snap-id, <tag-name>, date created)
-V     --volumes      List volumes (stdout= vol-id, tag:Name=VALUE, mount-state/instance-id)
-i     --instance     Looks for <tag-name> against Instances selects root vol (default is Volume <tag-name>)
-a=N   --archive=N    Keep N snapshots removes >N old (default=0, old volumes must have same <tag-name>)
-d     --dryrun       Do a test run without making changes
-p     --prompt       Prompts to continue/cancel after each execution process
-q     --quiet        Dont output anything to stdout
-E     --email        Email job start and completion or failure information
-F     --fail         Exit script with error on all warning (default is to continue)
-v     --verbose      Output more information
-h     --help         Display this cruft
       --version      Show version info
<tag-name> is the value of the \"Name\" tag given to your volume or instance (without <>)
<tag-name> required else if --list or --volumes is envoked
If tag-name is \" - \" asumes stdin piped for <tag-name>
Requires: \$AWS_ACCESS_KEY, \$AWS_SECRET_KEY, and \$JAVA_HOME environmental variables
Dependencies: AWS CLI Tools"
}
output() {
	local switch="$1"; local msg="$2"
	case "$switch" in
		message)	echo -ne "$msg"		;;
		 result)	echo "$msg"			;;
		   info)	logger -s -p local0.info -t 'Info: esm.sh' "'${msg}'"			;;
		   warn)	logger -is -p local0.warn -t 'Warning: esm.sh' "'${msg}'"		;;
	     optmis)	echo "Missing option value :: $msg"; exit 1			;;
		 badopt)	echo "Unknown option given :: $msg"; exit 1			;;
		  error)	logger -is -p local0.err -t 'Error: esm.sh' "'${msg}'"; exit 1	;;
	esac
}
is-number() {
	[[ -z "$1" ]] && output error "-a | --archive cannot be null"
	[[ "$1" =~ ^[0-9]+$ ]] || output error "-a | --archive is not a number :: $1"
}
long-opt() {
	[[ "$2" == "var" ]] && [[ -z "$1" ]] && output optmis "--$2"
	OPTIND=$(($OPTIND + 1))
}
get-options() {
	local opts=":r:LVidpqFvha:-:"
	while getopts "$opts" OPTIONS; do
		case "${OPTIONS}" in
			-)	case "${OPTARG}" in
				  region)	REGION="${!OPTIND}"; long-opt "${!OPTIND}" var	;;
			   	    list)	LIST_SNAPS=true; LIST_VOLS=false; long-opt		;;
				 volumes)	LIST_VOLS=true; LIST_SNAPS=false; long-opt		;;
				instance)	INSTANCE=true; long-opt		;;
				 archive)	is-number "${!OPTIND}" && ARCHIVE="${!OPTIND}"; long-opt "${!OPTIND}" var	;;
				  dryrun)	DRYRUN=true; long-opt		;;
				  prompt)	PROMPT=true; long-opt		;;
				   quiet)	QUIET=true; PROMPT=false; long-opt	;;
					fail)	WARN_FAIL=true; long-opt	;;
				 verbose)	VERBOSE=true; QUIET=false; long-opt	;;
					help)	usage; exit 0	;;
				 version)	usage | head -n 1; exit 0	;;
				       *)	output badopt "--${OPTARG}"	;;
				esac
			;;
			r)	REGION="$OPTARG"	;;
			L)	LIST_SNAPS=true; LIST_VOLS=false	;;
			V)	LIST_VOLS=true; LIST_SNAPS=false	;;
			i)	INSTANCE=true	;;
			a)	is-number "$OPTARG" && ARCHIVE="$OPTARG"	;;
			d)	DRYRUN=true		;;
			p)	PROMPT=true		;;
			q)	QUIET=true; PROMPT=false; VERBOSE=false	;;
			F)	WARN_FAIL=true;	;;
			v)	VERBOSE=true; QUIET=false	;;
			h)	usage; exit 0	;;
			:)	output optmis "-$OPTARG"	;;
			*)	output badopt "-$OPTARG"	;;
		esac
	done
}
get-name() {
	local args="$@"
	NAME=$(echo "$args" | sed 's/\-.*\ *//')
}


get-options "$@" && shift $((OPTIND-1))


#echo "$ARGS"

#echo $ALONG
exit 0