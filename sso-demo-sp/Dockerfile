FROM		ubuntu:16.04
MAINTAINER  Menzo Windhouwer <menzo.windhouwer@di.huc.knaw.nl>

RUN apt-get update &&\
    apt-get -y dist-upgrade &&\
    apt-get -y install supervisor wget openssl apache2 libapache2-mod-php libapache2-mod-shib2

# apache
ADD apache/envvars /etc/apache2/envvars
ADD apache/apache2.conf /etc/apache2/apache2.conf
RUN a2enmod ssl &&\
    a2enmod headers &&\
    a2ensite default-ssl

EXPOSE 443

# initialize shib
RUN /etc/init.d/shibd start &&\
	sleep 30 &&\
	/etc/init.d/shibd stop

ADD supervisor/start-*.sh /
RUN	chmod u+x /start-*.sh
ADD supervisor/*.conf /etc/supervisor/conf.d/
ADD supervisor/start.sh /start.sh
RUN	chmod u+x /start.sh

ENTRYPOINT /start.sh

# configure for interaction with the sso-demo IdP

ADD sso-demo/shibboleth2.xml /etc/shibboleth/shibboleth2.xml
ADD sso-demo/attribute-map.xml /etc/shibboleth/attribute-map.xml
ADD sso-demo/sso-demo-metadata.xml /etc/shibboleth/sso-demo-metadata.xml
RUN echo "# put / behind shibboleth" >> /etc/apache2/apache2.conf &&\
	echo "<Location />" >> /etc/apache2/apache2.conf &&\
    echo " AuthType            shibboleth" >> /etc/apache2/apache2.conf &&\
    echo " ShibRequireSession  Off" >> /etc/apache2/apache2.conf &&\
    echo " ShibUseHeaders      On" >> /etc/apache2/apache2.conf &&\
    echo " Satisfy             All" >> /etc/apache2/apache2.conf &&\
    echo " Require             shibboleth" >> /etc/apache2/apache2.conf &&\
	echo "</Location>" >> /etc/apache2/apache2.conf

# add sample page

RUN cd /var/www/html &&\
	wget -O index.php http://www.ncl.ac.uk/itservice/login-gateway/code/shibenv-php.txt
ADD apache/index.html /var/www/html/index.html

# Clean up APT when done.
RUN apt-get clean &&\
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
