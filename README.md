# SNMP Monitoring

A collection of scripts intended to extend Net-SNMP to non-SNMP aware applications.  

### Prerequisites

These scripts are intended to be run against a Linux host of some kind.  They may work on a mac, with some cleanup due to the way Mac looks at directory structures.  Windows will likely turn into a pumpkin. :)

net-snmp installed on the local machine and running properly.  You do NOT need to install MIB files unless you are doing something that specifically requires them.  These scripts will leverage the raw OID, so no additional dependencys are created in that respect.

Normal linux tools: bash, awk, grep, sed, etc.

I try very hard to create basic help systems within my scripts. -h should give a high level overview, and -x should enable a debug mode for testing and validation.

### Installing

Install net-snmp

Configure net-snmp

Clone the repository to its new home.  In general I prefer /opt

sudo chmod 775 /opt/snmp-monitoring/bin/*

edit your /etc/snmp/snmpd.conf file to have the string pass 1.3.6.1.4.1.30911 /opt/snmp-monitoring/bin/snmp_drop_oid.sh

restart snmpd

## Running the tests

test against the default test OID

/opt/snmp-monitoring/bin/snmp_drop_oid.sh -g 1.3.6.1.4.1.30911.666.0

snmpget -v 2c -c public localhost 1.3.6.1.4.1.30911.666.0
* It is STRONGLY recommended to never use public for your community string.

test from a remote machine

snmpget -v 2c -c public 'remote IP' 1.3.6.1.4.1.30911.666.0

Begin creating new files either with your application, or using the drop_oid script

snmp_drop_oid.sh -x -s "1.3.6.1.4.1.30911.666.0 string Default Test"

It is important to note that an snmpwalk is a modified snmpgetnext command.  It behaves badly with this script.  It is suggested that snmpget to be the most common way of retreiving data.

## Versioning

I use whatever comes to mind for my versioning.  In general master will be the "blessed" version..

## Authors

* **Christopher Hubbard** - *Initial work* - [Guyverix](https://github.com/Guyverix)

See also the list of [contributors](https://github.com/Guyverix/snmp-monitoring/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


