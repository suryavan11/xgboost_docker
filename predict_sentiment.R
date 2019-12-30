
########## prediction pipeline ############
# myarg <- commandArgs()
# inputfilepath = myarg[1]
# outputfilepath = myarg[2]
# modelfilepath = myarg[3]

inputfilepath='/opt/aspire/transcripts'
outputfilepath='/opt/aspire/transcripts1'
modelfilepath='/opt/aspire/models'


library(mlapi)
library(R6)
library(tokenizers)
library(text2vec)
library(caret)
library(readr)
library(stringr)
library(dplyr)

upscore = readRDS( file.path(modelfilepath, 'upscore_R6_model_v1_20191223.rds') )
upscore.model = upscore$new()

filenm = list.files(inputfilepath, full.names = F)

df = read_delim( file.path(inputfilepath, filenm[[1]]),
                 # n_max = 1000,
                 delim = '|')
colnames(df) = tolower(str_remove_all(colnames(df),'^.*\\.'))


df = df%>%
  mutate(sourcemediaid = as.character(sourcemediaid))%>%
  ## mutate(startoffset = as.numeric(lubridate::hms(startoffset))  )%>% ## if needed, convert timestamp
  mutate(phrase = upscore.model$preprocess.text.fn(phrase))%>%
  group_by(sourcemediaid)%>%
  # arrange(startoffset, .by_group = TRUE)%>% ##if needed, arrange by timestamp
  summarize(phrase = paste0(phrase, collapse = ' '), src_file_date = first(src_file_date))%>%
  ungroup()

df = upscore.model$predict(df,sourcemediaid, phrase, calibrate = T)


write_delim(df%>%rename(sentiment=high)%>%mutate(sentiment=round(sentiment,3))%>%select(sourcemediaid, sentiment, src_file_date),
            file.path(outputfilepath, str_replace_all(filenm[[1]], 'transcript', 'transcriptmetadata') ), delim='|')
