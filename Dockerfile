# get shiny server plus tidyverse packages image
FROM rocker/shiny-verse:latest

# system libraries of general use
RUN apt-get update && apt-get install -y \
    curl \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev\
    libssl3 \
    libgdal-dev \
    libproj-dev \
    libgeos-dev \
    libudunits2-dev \
    netcdf-bin \
    libharfbuzz-dev \ 
    libfribidi-dev \
    ## clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# install R packages required 
# (change it depending on the packages you need)
RUN R -e "install.packages('shiny')"
RUN R -e "install.packages('shinythemes')"
RUN R -e "install.packages('tidyverse')"
RUN R -e "install.packages('sf', dependencies = TRUE)"
RUN R -e "install.packages('leaflet', dependencies = TRUE)"
RUN R -e "install.packages('units', dependencies = TRUE)"

# clean up
RUN rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Copy configuration files into the Docker image
COPY shiny-server.conf  /etc/shiny-server/shiny-server.conf

# Copy shiny app into the Docker image
COPY app /srv/shiny-server/

RUN rm /srv/shiny-server/index.html

# Make the ShinyApp available at port 3838
EXPOSE 3838

# Copy shiny app execution file into the Docker image
COPY shiny-server.sh /usr/bin/shiny-server.sh

RUN ["chmod", "+x", "/usr/bin/shiny-server.sh"]

USER shiny

CMD ["/usr/bin/shiny-server"]