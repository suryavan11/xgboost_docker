FROM rocker/r-ver:3.6.1

## MRAN repo is already set by r-ver dockerfile to update date of  r-ver:x.x.x

## install dependencies for caret
RUN sudo apt-get install libz-dev \
&& install2.r --error \
    mlapi \
    R6 \
    tokenizers \
    text2vec \
    caret \
    readr \
    stringr \
    dplyr \
&& cd / \
&& rm -rf /tmp/* \
&& apt-get remove --purge -y $BUILDDEPS \
&& apt-get autoremove -y \
&& apt-get autoclean -y \
&& rm -rf /var/lib/apt/lists/*

RUN mkdir /home/analysis

COPY myscript.R /home/analysis/myscript.R

CMD R -e "source('/home/analysis/myscript.R')"
