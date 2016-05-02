FROM ubuntu:trusty

MAINTAINER Kristian Peters <kpeters@ipb-halle.de>

LABEL Description="RStudio Server + important R & Bioconductor packages."



# Environment variables
ENV DISPLAY=":1"
ENV PATH="/usr/local/bin/:/usr/local/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin:/bin:/sbin"
ENV PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig"
ENV LD_LIBRARY_PATH="/usr/lib64:/usr/lib:/usr/local/lib64:/usr/local/lib"

ENV PACK_R="abind BH cba curl dendextend devtools doSNOW eigenfaces extrafont FactoMineR geometry ggplot2 Hmisc httr klaR kohonen magic Matrix matrixStats mda memoise plotly plotrix R6 rCharts Rcpp rmarkdown rsm rstudioapi RUnit squash tools vegan xslx"
ENV PACK_BIOC="mtbls2 Risa"
ENV PACK_GITHUB="dragua/xlsx glibiseller/IPO jcapelladesto/geoRge rstudio/rmarkdown"



# Add cran R backport
RUN apt-get -y install apt-transport-https
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
RUN echo "deb https://cran.uni-muenster.de/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list

# Update & upgrade sources
RUN apt-get -y update
RUN apt-get -y dist-upgrade

# Install RStudio-related packages
RUN apt-get -y install wget r-base gdebi-core psmisc libapparmor1

# Install development files needed for general compilation
RUN apt-get -y install cmake ed freeglut3-dev g++ gcc git libcurl4-gnutls-dev libgfortran-4.8-dev libglu1-mesa-dev libgomp1 libssl-dev libxml2-dev python xorg-dev

# Install libraries needed by Bioconductor
RUN apt-get -y install gdb libbz2-dev libdigest-sha-perl libexpat1-dev libgl1-mesa-dev libglu1-mesa-dev libgmp3-dev libgsl0-dev libgsl0ldbl liblzma-dev libnetcdf-dev libopenbabel-dev libpcre3-dev libpng12-dev libxml2-dev netcdf-bin openjdk-7-jdk python-dev python-pip

# Install Xorg environment (needed for compiling some Bioc packages)
RUN apt-get -y install xauth xinit xterm xvfb

# Install libsbml (needed by Bioconductor rsbml)
RUN wget -O /tmp/libsbml.deb 'http://downloads.sourceforge.net/project/sbml/libsbml/5.12.0/stable/Linux/64-bit/libSBML-5.12.0-Linux-x64.deb?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fsbml%2Ffiles%2Flibsbml%2F5.12.0%2Fstable%2FLinux%2F64-bit%2F&ts=1455626187&use_mirror=heanet'
RUN dpkg -i /tmp/libsbml.deb
RUN rm /tmp/libsbml.deb
RUN pip install python-libsbml

# Install RStudio from their repository
RUN wget -O /tmp/rstudio-server-download.html https://www.rstudio.com/products/rstudio/download-server/
RUN wget -O /tmp/rstudio.deb "$(cat /tmp/rstudio-server-download.html | grep amd64\.deb | grep wget | sed -e "s/.*https/https/" | sed -e "s/deb.*/deb/")"
RUN dpkg -i /tmp/rstudio.deb
RUN rm /tmp/rstudio-server-download.html
RUN rm /tmp/rstudio.deb

# Clean up
RUN apt-get -y clean && apt-get -y autoremove && rm -rf /var/lib/{cache,log}/ /tmp/* /var/tmp/*



# Update java in R
RUN R CMD javareconf

# Install R packages
RUN for PACK in $PACK_R; do R -e "install.packages(\"$PACK\", repos='https://cran.rstudio.com/')"; done

# Install metabolomics R packages from Bioconductor
RUN R -e "source('https://bioconductor.org/biocLite.R'); biocLite(\"BiocInstaller\", dep=TRUE, ask=FALSE)"
ADD installFromBiocViews.R /tmp/installFromBiocViews.R
ADD xinitrc /root/.xinitrc
RUN chmod +x /root/.xinitrc
RUN echo -n > /root/.Xauthority
RUN dd if=/dev/urandom count=1 | sha256sum | sed -e "s/^/add $DISPLAY . /" | sed -e "s/ \-.*//" | /usr/bin/xauth -f /root/.Xauthority -q
RUN xinit -- /usr/bin/Xvfb $DISPLAY -screen 0 800x600x16 -dpi 75 -nolisten tcp -audit 4 -ac -auth /root/.Xauthority 1>&2 2>/dev/null
# will be RUN in .xinitrc: xterm -display $DISPLAY -e R -f /tmp/installFromBiocViews.R

# Install other Bioconductor packages
RUN for PACK in $PACK_BIOC; do R -e "library(BiocInstaller); biocLite(\"$PACK\", ask=FALSE)"; done

# Install other R packages from source
RUN for PACK in $PACK_GITHUB; do R -e "library('devtools'); install_github(\"$PACK\")"; done

# Install BATMAN
RUN R -e "library('devtools'); install.packages("batman", repos="http://R-Forge.R-project.org")"

# Update R packages
RUN R -e "update.packages(repos='https://cran.rstudio.com/', ask=F)"



# Configure RStudio server
ADD rserver.conf /etc/rstudio/rserver.conf
ADD rsession.conf /etc/rstudio/rsession.conf
RUN echo "#!/bin/sh" > /usr/sbin/rstudio-server.sh
RUN echo "/usr/lib/rstudio-server/bin/rserver --server-daemonize=0" >> /usr/sbin/rstudio-server.sh
RUN chmod +x /usr/sbin/rstudio-server.sh



# Infrastructure specific
RUN groupadd -g 9999 -f rstudio
RUN useradd -d /home/rstudio -m -g rstudio -u 9999 -s /bin/bash rstudio
RUN echo 'rstudio:docker' | chpasswd



# expose port
EXPOSE 8080

# Define Entry point script
WORKDIR /
ENTRYPOINT ["/bin/sh","/usr/sbin/rstudio-server.sh"]

