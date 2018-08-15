# SNMP Monitoring

A collection of scripts intended to extend Net-SNMP to non-SNMP aware applications.  

### Prerequisites

These scripts are intended to be run against a Linux host of some kind.  They may work on a mac, with some cleanup due to the way Mac looks at directory structures.  Windows will likely turn into a pumpkin. :)

net-snmp installed on the local machine and running properly.  You do NOT need to install MIB files unless you are doing something that specifically requires them.  These scripts will leverage the raw OID, so no additional dependencys are created in that respect.

Normal linux tools: bash, awk, grep, sed, etc.

I try very hard to create basic help systems within my scripts. -h should give a high level overview, and -x should enable a good debug mode for testing and validation.

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

snmp_drop_oid.sh -x -s "1.3.6.1.4.1.30911.666.# string Default Test"

It is important to note that an snmpwalk is a modified snmpgetnext command.  Because of this, if you have sparse array values the script SHOULD work as expected, but minimal testing has been done.

To test SNMPWALK / SNMPGETNEXT

Create your sub-oid values as shown above and then walk it
```
snmpwalk -v2c -c COMMUNITY IP_ADDRESS 1.3.6.1.4.1.30911.666
iso.3.6.1.4.1.30911.666.1 = Gauge32: 12
iso.3.6.1.4.1.30911.666.2 = INTEGER: 2345
iso.3.6.1.4.1.30911.666.3 = STRING: "test string 03"
iso.3.6.1.4.1.30911.666.4 = Counter32: 123434556
iso.3.6.1.4.1.30911.666.5 = IpAddress: 192.168.15.204
iso.3.6.1.4.1.30911.666.7 = STRING: "testing getnext with gaps in the file structure"
```
## Versioning

I use whatever comes to mind for my versioning.  I have kinda been a bit sloppy in how I do my version work.  If you look at the bash scripts themselves, they have a version and a revision name.  Revision starts with womens names beginning with the letter A, and goes up to the letter M.  At M, then the Version number will likely increment depending on how many changes have been done to the script.  (feel free to hate, Mary is my wifes name. so M is the final point in figuring out if I need a version increase :P)

In general master will be the "blessed" version..

## Authors

* **Christopher Hubbard** - *Initial work* - [Guyverix](https://github.com/Guyverix)

See also the list of [contributors](https://github.com/Guyverix/snmp-monitoring/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


