FROM rocker/r-ver:3.6.1

## MRAN repo is already set by r-ver dockerfile to update date of  r-ver:x.x.x

## install dependencies for caret
RUN apt-get update && apt-get install libz-dev \
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

COPY predict_CA.R, predict_driver.R, predict_sentiment.R /opt/

RUN chmod +x /opt/model_SAD_diarize_transcribe.sh

WORKDIR /opt

# CMD R -e "source('/home/analysis/myscript.R')"
