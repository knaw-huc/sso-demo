#!/bin/sh
set -x

export JAVA_HOME=/usr/java/default
export JETTY_HOME=/opt/jetty/
export JETTY_BASE=/opt/iam-jetty-base/
export PATH=$PATH:$JAVA_HOME/bin

echo "Fetch sp.example.org Shibboleth metadata."
wget --no-check-certificate -O /opt/shibboleth-idp/metadata/sp.xml https://sp.example.org/Shibboleth.sso/Metadata

echo "Updating the Shibboleth webapp artifacts."
cp /jar-location/ucla-shibboleth.jar /opt/shibboleth-identityprovider-2.4.3/lib/

echo "Rebuilding the idp.war file"
cd /opt/shibboleth-identityprovider-2.4.3
./install.sh -Didp.home.input=/opt/shibboleth-idp -Dinstall.config=no

touch /opt/shibboleth-idp/logs/idp-process.log
tail -f /opt/shibboleth-idp/logs/idp-process.log &

touch /opt/iam-jetty-base/cas.log
tail -f /opt/iam-jetty-base/cas.log &

/usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir 
tail -f /var/log/dirsrv/slapd-dir/access &

export JAVA_OPTIONS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"

cd /opt/iam-jetty-base
$JAVA_HOME/bin/java -jar ../jetty/start.jar
