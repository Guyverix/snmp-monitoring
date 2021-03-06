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
#   DESCRIPTION:  Get all matches of an OID (snmpgetnext value)
#    PARAMETERS:  OID number
#       RETURNS:  OID / TYPE / DATA
#===============================================================================
next() {
# Only gives one result in a walk or a getnext!

# What are we starting with?
local OID=${1}

# Next in the file system (may NOT be a concurrent number)

# Old version:
#local nextOid=$(ls ${O_PATH} | grep -A1 ${OID} | head -2 | tail -1 | sed 's/oid//')
# found and fixed by amoruck!
if [[ -e ${O_PATH}/${PREFIX}${OID} ]];then
    # Next in the file system (may NOT be a concurrent number)
    local nextOid=$(ls ${O_PATH} | grep -A1 ${OID} | head -2 | tail -1 | sed 's/oid//')
else
    local nextOid=$(ls ${O_PATH} | grep ${OID} | head -1 | sed 's/oid//')
fi


# Do we even have another OID to return?
if [ -z ${nextOid} ];then
  return

# the oids match, we did not increment.  Nothing new
# exit out with no results
elif [[ "${nextOid}" == "${OID}" ]] ;then
  return
# We have somthing different than the origional OID value.
# Return the data now

else
  # Only actually return something if we really do have a file
  if [[ -e ${O_PATH}/${PREFIX}${nextOid} ]];then
    cat "${O_PATH}/${PREFIX}${nextOid}"
  fi
fi
# Catchall return nothing
return
}

#===  GETOPTS  =================================================================
#          NAME:  getopts
#   DESCRIPTION:  Not a function.  Get the options from the command args
#    PARAMETERS:  as defined
#       RETURNS:  nothing by default.  Global variable declarations
#===============================================================================
TYPE='get'
O_PATH='/opt/snmp-monitoring/data'
PREFIX='oid'
DEF_OID='.1.3.6.1.4.1.30911'

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
       VAL=$(echo "${OPTARG}")
       CVAL=$(echo ${VAL} | awk '{print $1(NF>1? FS $2 : "")}')
       VAL=$(echo ${VAL} | sed "s|${CVAL} ||")
       TYPE='sset'                   ;;
    p) O_PATH="${OPTARG}"            ;;
    g) TYPE='get';  OID="${OPTARG}"  ;;
    n) TYPE='next'; OID="${OPTARG}"  ;;
    *) echo -e "${DEF_OID}\nstring\nIncorrect arguments passed to script"; exit 0 ;;
  esac
done

# Make sure we are not pulling grud out of the filesystem
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

