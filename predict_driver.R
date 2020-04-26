########## prediction pipeline ############
# myarg <- commandArgs()
# inputfilepath = myarg[1]
# outputfilepath = myarg[2]
# modelfilepath = myarg[3]

inputfilepath='/opt/aspire/transcript1'
outputfilepath='/opt/aspire/transcript2'
modelfilepath='/opt/aspire/model'


library(mlapi)
library(R6)
library(reshape2)
library(tokenizers)
library(text2vec)
library(caret)
library(readr)
library(stringr)
library(dplyr)

quality = readRDS( file.path(modelfilepath, 'quality_R6_model_v5_20191229.rds') )
quality.model = quality$new()

filenm = list.files(inputfilepath, full.names = F)

for (i in seq_along(filenm)) {
  
df = read_delim( file.path(inputfilepath, filenm[[i]]),
                 # n_max = 1000,
                 delim = '|')
colnames(df) = tolower(str_remove_all(colnames(df),'^.*\\.'))



df = df%>%
  mutate(sourcemediaid = as.character(sourcemediaid))%>%
  ## mutate(startoffset = as.numeric(lubridate::hms(startoffset))  )%>% ## if needed, convert timestamp
  mutate(phrase = quality.model$preprocess.text.fn(phrase))%>%
  group_by(sourcemediaid)%>%
  # arrange(startoffset, .by_group = TRUE)%>% ##if needed, arrange by timestamp
  summarize(phrase = paste0(phrase, collapse = ' '), src_file_date = first(src_file_date))%>%
  ungroup()

src_file_dates = df$src_file_date

df = quality.model$predict(df,sourcemediaid, phrase, txt.length, language.col)

df$src_file_date = src_file_dates

output_detail = df%>%
    select(-ypred,-phrase,-txt.length,-language.col, -src_file_date)%>%
    melt()%>%
    mutate(value = round(value,4))%>%
    rename(L2Intent = variable, L2Prob = value )%>%
    arrange(sourcemediaid)

  output_summary = df%>%
    rename(L2Intent = ypred, text_length = txt.length, text_language = language.col )%>%
    mutate(prediction_date = lubridate::today())%>%
    select(sourcemediaid, L2Intent,text_language, text_length,
           src_file_date, prediction_date )



write_delim(output_summary,
            file.path(outputfilepath, str_replace_all(filenm[[i]], 'transcript', 'transcriptsummary') ), delim='|')

write_delim(output_detail,
            file.path(outputfilepath, str_replace_all(filenm[[i]], 'transcript', 'transcriptdetail') ), delim='|')

rm(df)
rm(output_detail)
rm(output_summary)
  
  }
