FROM ubuntu:trusty

MAINTAINER Kristian Peters <kpeters@ipb-halle.de>

LABEL Description="Install RStudio Server + relevant R & Bioconductor packages in Docker."



# Environment variables
ENV PACK_R="tools devtools rsm RUnit rCharts cba matrixStats Matrix plotrix squash FactoMineR vegan eigenfaces Hmisc"
ENV PACK_BIOC="xcms mzR pcaMethods mtbls2 CAMERA multtest faahKO msdata"
ENV PACK_GITHUB="glibiseller/IPO sneumann/geoRge"



# Add cran R backport
RUN apt-get -y install apt-transport-https
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
RUN echo "deb https://cran.uni-muenster.de/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list

# Update & upgrade sources
RUN apt-get -y update
RUN apt-get -y dist-upgrade

# Install R and RStudio-related packages
RUN apt-get -y install wget r-base gdebi-core psmisc libapparmor1

# Install development files needed for compilation
RUN apt-get -y install git python xorg-dev libglu1-mesa-dev freeglut3-dev libgomp1 libxml2-dev gcc g++ libgfortran-4.8-dev libcurl4-gnutls-dev cmake wget ed libssl-dev

# Install libraries needed by Bioconductor
RUN apt-get -y install netcdf-bin libnetcdf-dev libdigest-sha-perl

# Install RStudio from their repository
RUN wget -O /tmp/rstudio-server-download.html https://www.rstudio.com/products/rstudio/download-server/
RUN wget -O /tmp/rstudio.deb "$(cat /tmp/rstudio-server-download.html | grep amd64\.deb | grep wget | sed -e "s/.*https/https/" | sed -e "s/deb.*/deb/")"
RUN dpkg -i /tmp/rstudio.deb

# Clean up
RUN apt-get -y clean && apt-get -y autoremove && rm -rf /var/lib/{cache,log}/ /tmp/* /var/tmp/*



# Install R packages
RUN for PACK in $PACK_R; do R -e "install.packages(\"$PACK\", repos='https://cran.rstudio.com/')"; done

# Install R packages from Bioconductor
RUN for PACK in $PACK_BIOC; do R -e "source('https://bioconductor.org/biocLite.R'); biocLite(\"$PACK\", dep=T, ask=F)"; done

# Install other R packages
RUN for PACK in $PACK_GITHUB; do R -e "library('devtools'); install_github(\"$PACK\")"; done

# Update R packages
RUN R -e "update.packages(repos='https://cran.rstudio.com/', ask=F)"



# Configure RStudio server
ADD rserver.conf /etc/rstudio/rserver.conf
ADD rsession.conf /etc/rstudio/rsession.conf
RUN echo "#!/bin/sh" > /usr/sbin/rstudio-server.sh
RUN echo "/usr/lib/rstudio-server/bin/rserver --server-daemonize=0" >> /usr/sbin/rstudio-server.sh
RUN chmod +x /usr/sbin/rstudio-server.sh



# HACK: Infrastructure specific
#RUN apt-get -y install ldap-utils libpam-ldapd libnss-ldapd libldap2-dev nslcd
#WORKDIR /
#ADD etc/ldap.conf /etc/ldap.conf
#ADD etc/ldap /etc/ldap
#ADD etc/pam.d /etc/pam.d
#ADD etc/nsswitch.conf /etc/nsswitch.conf
#ADD etc/nslcd.conf /etc/nslcd.conf
#RUN chmod 660 /etc/nslcd.conf
#ADD etc/ssl/certs/IPB* /etc/ssl/certs/
#RUN update-rc.d nslcd enable

#RUN echo "#!/bin/sh" > /usr/sbin/rstudio-server.sh
#RUN echo "service nslcd start" >> /usr/sbin/rstudio-server.sh
#RUN echo "sleep 10" >> /usr/sbin/rstudio-server.sh
#RUN echo "/usr/lib/rstudio-server/bin/rserver --server-daemonize=0" >> /usr/sbin/rstudio-server.sh
#RUN chmod +x /usr/sbin/rstudio-server.sh



# expose port
EXPOSE 8080

# Define Entry point script
WORKDIR /
ENTRYPOINT ["/bin/sh","/usr/sbin/rstudio-server.sh"]

