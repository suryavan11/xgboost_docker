FROM rocker/r-ver:3.6.1

## MRAN repo is already set by r-ver dockerfile to last update date of  r-ver:x.x.x

# Install R packages
RUN install2.r --error \
    mlapi \
    R6 \
    tokenizers \
    text2vec \
    caret \
    tidyverse \
&& cd / \
&& rm -rf /tmp/* \
&& apt-get remove --purge -y $BUILDDEPS \
&& apt-get autoremove -y \
&& apt-get autoclean -y \
&& rm -rf /var/lib/apt/lists/*

RUN mkdir /home/analysis

RUN R -e "install.packages('methods',dependencies=TRUE, repos='http://cran.rstudio.com/')"


# Install R packages
RUN install2.r --error \
    mlapi \
    R6 \
    tokenizers \
    text2vec \
    caret \
    tidyverse

COPY myscript.R /home/analysis/myscript.R

CMD R -e "source('/home/analysis/myscript.R')"
