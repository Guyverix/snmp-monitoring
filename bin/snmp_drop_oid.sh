#!/bin/bash - 
#===============================================================================
#
#          FILE:  snmp_drop_oid.sh
# 
#         USAGE:  ./snmp_drop_oid.sh 
# 
#   DESCRIPTION:  Parse and return snmp values from drop oid files. 
#  REQUIREMENTS:  net-snmp configured to call this script
#          BUGS:  None Known.
#         NOTES:  ---
#        AUTHOR: Christopher Hubbard (CSH), chubbard@iwillfearnoevil.com
#       COMPANY: Home
#       CREATED: 08-03-14 08:25:49 AM PDT
#      REVISION: Mary
#       VERSION: 1.0.6
#===============================================================================

# set -o nounset      # Treat unset variables as an error
# set -x              # DEBUG MODE

canonicalpath=`readlink -f $0`
canonicaldirname=`dirname ${canonicalpath}`/..
samedirname=`dirname ${canonicalpath}`

#==============================================================================
# Define a base useage case for a -h option
#==============================================================================
usage(){
cat << EOF
Usage: $0 options

This script is intended to be called from net-snmp as a "pass" option.  The script 
will parse snmp drop oid files for applications.  It makes some assumptions as to the
location of the files.  However additional abilities have been added to the script 
to take alternate paths as well.  It is critical that the rules for parsing be 
followed to the letter.  The Net-SNMP pass system is somewhat clunky and not 
very forgiving.

OID values can only be the following: (64 bit not supported)
integer, gauge, counter, timeticks, ipaddress, objectid, or string

Options:
-h  show this help screen
-x  enable debug mode
-g  * snmp get request returns ONLY exact match on the oid  (default)
-n  * snmp get next request returns entire oid tree from match  
-p  path to alternate drop-oids
-f  file prefix (if not oid)
-s  SET an snmp value in the drop oid directory *Args: OID type value
* net-snmp can only use these two options with 'pass'

Example:
$0 -g .1.3.6.1.4.1.30911.2.1.1.1.1.1
.1.3.6.1.4.1.30911.2.1.1.1.1.1
string
u1

EOF
}

#===  FUNCTION  ================================================================
#          NAME:  sset (set is a bash keyword, dont use as a function)
#   DESCRIPTION:  Set an snmp oid value
#    PARAMETERS:  OID / TYPE / DATA
#       RETURNS:  none
#===============================================================================
sset() {
local OID=$1
local D_TYPE=$2
local VAL=$3

echo "${OID}"     > ${O_PATH}/${PREFIX}${OID}
echo "${D_TYPE}" >> ${O_PATH}/${PREFIX}${OID}
echo "${VAL}"    >> ${O_PATH}/${PREFIX}${OID}

}

#===  FUNCTION  ================================================================
#          NAME:  get
#   DESCRIPTION:  Get a single snmp OID value
#    PARAMETERS:  OID number
#       RETURNS:  OID / TYPE / DATA
#===============================================================================
get() {
local match=`ls ${O_PATH}/${PREFIX}${OID} 2>/dev/null`
if [[ -z ${match} ]];then
  JUNK=0
else 
#  echo "${OID}"
  cat ${match}
fi
}

#===  FUNCTION  ================================================================
#          NAME:  next
#   DESCRIPTION:  Get all matches of an OID (snmpwalk)
#    PARAMETERS:  OID number
#       RETURNS:  OID / TYPE / DATA
#===============================================================================
next() {
# Only gives one result in a walk
# local match=`ls ${O_PATH}/${PREFIX}${OID}.* 2>/dev/null | head -1`

local match=`ls ${O_PATH}/${PREFIX}${OID}.* 2>/dev/null`
local files=$(find -type f ${O_PATH} -name "${PREFIX}${OID}")

if [ -e ${O_PATH}/${PREFIX}${OID} ];then
  # It is implied that we have a valid file of somekind


if [[ -z ${match} ]];then
  JUNK=0
else 
  IFS=$'\n'
  for x in `echo -e "${match}"` ;do
    local L_OID=`echo "${x}" | sed "s|.*.${PREFIX}||"`
    echo "${L_OID}"
    cat ${x}
  done
fi
}

#===  GETOPTS  =================================================================
#          NAME:  getopts
#   DESCRIPTION:  Not a function.  Get the options from the command args
#    PARAMETERS:  as defined
#       RETURNS:  nothing by default.  Variable declaration
#===============================================================================
TYPE='get'
O_PATH='/opt/snmp-monitoring/data'
PREFIX='oid'

while getopts "xhg:s:n:p:f:" OPTION
do
  case ${OPTION} in
    h) usage; exit 0                 ;;
    x) export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; set -v ; set -x ;;
    f) PREFIX="${OPTARG}"            ;;
    s) if [ "${OPTARG}" == "0" ]; then 
         exit 0 
       fi
       OID=$(echo "${OPTARG}" | awk '{print $1}');
       D_TYPE=$(echo "${OPTARG}" | awk '{print $2}')
       VAL=$(echo "${OPTARG}" | sed "s|.*.${D_TYPE}\ ||")
       TYPE='sset'                   ;;
    p) O_PATH="${OPTARG}"            ;;
    g) TYPE='get';  OID="${OPTARG}"  ;;
    n) TYPE='next'; OID="${OPTARG}"  ;;
    *) echo -e ".1.3.6.1.4.1.30911\nstring\nIncorrect arguments passed to script"; exit 0 ;;
  esac
done

if [[ ! "${OID}" =~ "^\..*" ]];then
  OID=".${OID}"
  OID=$(echo "${OID}" | sed 's|\.\.|\.|')
fi

# Could have been called in the origional case statement, but 
# would not have been as clear in the code.


case ${TYPE} in
  sset) sset "${OID}" "${D_TYPE}" "${VAL}" ;;
  get)  get  "${OID}" ;;
  next) next "${OID}" ;; 
esac
# We are not going to exit in error ever, as this must be a very rigid framework 
# due to the limitations of what net-snmp expects.
exit 0

