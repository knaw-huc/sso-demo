FROM centos:centos6

MAINTAINER jgasper@unicon.net

#ENV JRE_HOME /opt/jre1.7.0_71
#NV JAVA_HOME /opt/jre1.7.0_71
ENV JETTY_HOME /opt/jetty
ENV JETTY_BASE /opt/iam-jetty-base
ENV PATH $PATH:$JRE_HOME/bin:/opt/container-scripts

RUN yum install -y http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm \
	&& yum install -y --enablerepo=centosplus 389-ds \
	&& yum -y install wget tar unzip \
	&& yum clean all

ADD ldap/ /ldap-data/

# The 389-ds setup will fail because the hostname can't reliable be determined, so we'll bypass it and then install.
RUN sed -i 's/checkHostname {/checkHostname {\nreturn();/g' /usr/lib64/dirsrv/perl/DSUtil.pm \
	&& setup-ds-admin.pl --silent --file /ldap-data/ds-setup.inf \
	&& ldapadd -H ldap:/// -f /ldap-data/ppolicy.ldif -x -D "cn=Directory Manager" -w password \
	&& ldapadd -H ldap:/// -f /ldap-data/users.ldif -x -D "cn=Directory Manager" -w password \
	&& rm -fr /ldap-data/

# jdk
ADD java/jdk-8u172-linux-x64.rpm /tmp/jdk-8u172-linux-x64.rpm
RUN cd /tmp &&\
    yum -y localinstall jdk-8u172-linux-x64.rpm
ENV JAVA_HOME "/usr/java/default"
ENV PATH $JAVA_HOME/bin:$PATH

# maven
RUN wget https://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo &&\
    sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo &&\
    yum install -y apache-maven &&\
    mvn --version

# Download Jetty, verify the hash, and install, initialize a new base
RUN set -x; \
    jetty_version=9.2.10.v20150310; \
    wget -O jetty.tar.gz "https://eclipse.org/downloads/download.php?file=/jetty/$jetty_version/dist/jetty-distribution-$jetty_version.tar.gz&r=1" \
    && cd /opt \
    && tar xf /jetty.tar.gz \
    && mv /opt/jetty-distribution-$jetty_version /opt/jetty \
    && rm /jetty.tar.gz \
    && cp /opt/jetty/bin/jetty.sh /etc/init.d/jetty \
    && mkdir -p /opt/iam-jetty-base/modules \
    && mkdir -p /opt/iam-jetty-base/lib/ext \
    && cd /opt/iam-jetty-base \
    && touch start.ini \
    && $JAVA_HOME/bin/java -jar ../jetty/start.jar --add-to-startd=http,https,deploy,ext,annotations,jstl

# Download Shibboleth IdP, verify the hash, and install
RUN set -x; \
    shibidp_version=2.4.3; \
    wget https://shibboleth.net/downloads/identity-provider/2.4.3/shibboleth-identityprovider-$shibidp_version-bin.zip \
    && echo "9f2787c64f56c6f6020ac5d01e62bf0f8851755c  shibboleth-identityprovider-$shibidp_version-bin.zip" | sha1sum -c - \
    && unzip shibboleth-identityprovider-$shibidp_version-bin.zip -d /opt \
    && rm shibboleth-identityprovider-2.4.3-bin.zip \
    && cd /opt/shibboleth-identityprovider-$shibidp_version \
    && sed -i 's/keystorePassword="\${idp.keystore.pass}"/keystorePassword="CHANGEME"/g' /opt/shibboleth-identityprovider-$shibidp_version/src/installer/resources/build.xml

ADD iam-jetty-base/ /opt/iam-jetty-base/

RUN shibidp_version=2.4.3; \
    cd /opt/shibboleth-identityprovider-$shibidp_version \
    && ./install.sh

ADD shibboleth-idp/ /opt/shibboleth-idp/

# Install CAS
ADD cas /tmp/cas
RUN cd /tmp/cas &&\
    mvn package &&\
    cp target/cas.war /opt/iam-jetty-base/webapps/

#Container Execution
ADD container-scripts/ /opt/container-scripts/
RUN chmod -R +x /opt/container-scripts/

EXPOSE 389 5005 8080 8443

CMD run-sso.sh

