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
library(reshape2)
library(tokenizers)
library(text2vec)
library(caret)
library(tidyverse)


cust_agent = readRDS( file.path(modelfilepath, 'cust_agent_R6_model_v1_20191224.rds') )
cust_agent.model = cust_agent$new()

df = read_delim( file.path(modelfilepath, 'cust_agent_R6_model_v1_20191224.rds'),
                 n_max = 1000,
                 delim = '|')
colnames(df) = tolower(str_remove_all(colnames(df),'^.*\\.'))


######### prediction for every turn #########
pred1 = cbind(df,cust_agent.model$predict(df$phrase) )

###########prediction on subset to generate the switch flag #####################

temp =  cust_agent.model$predict.on.subset(df, sourcemediaid, phrase, party)

temp1 = temp%>%select(-new.party)%>%
  melt(id = c('sourcemediaid', 'party'))%>%
  filter(party != 'Unknown')%>%
  mutate(variable = ifelse(variable == 'agent', 'Agent', 'Customer'))%>%
  arrange(sourcemediaid)%>%
  group_by(sourcemediaid)%>%
  top_n(1,value)%>%
  slice(1)%>%
  ungroup()%>%
  mutate(switch = ifelse(party == variable, FALSE, TRUE))


df = df%>%
  left_join(temp1%>%select(sourcemediaid, switch), by = 'sourcemediaid')%>%
  mutate(
    predicted.party = case_when(
      party == 'Agent' & switch == TRUE ~ 'Customer',
      party == 'Agent' & switch == FALSE ~ 'Agent',
      party == 'Customer' & switch == TRUE ~ 'Agent',
      party == 'Customer' & switch == FALSE ~ 'Customer',
      TRUE ~ 'Unknown'
    )
  )
