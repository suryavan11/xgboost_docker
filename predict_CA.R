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


cust_agent = readRDS( file.path(modelfilepath, 'cust_agent_R6_model_v1_20191224.rds') )
cust_agent.model = cust_agent$new()

filenm = list.files(inputfilepath, full.names = F)

for (i in seq_along(filenm)) {
df = read_delim( file.path(inputfilepath, filenm[[i]]),
                 # n_max = 1000,
                 delim = '|')
colnames(df) = tolower(str_remove_all(colnames(df),'^.*\\.'))

## assign party 1 = Agent, 2 = Customer (just to keep continuity with some old code. this portion can be revamped later
df = df%>%
mutate(party = ifelse(party ==1, 'Agent', 'Customer' ))

######### prediction for every turn #########
# pred1 = cbind(df,cust_agent.model$predict(df$phrase) )

###########prediction on subset to generate the switch flag #####################

temp =  cust_agent.model$predict.on.subset(df, sourcemediaid, phrase, party)

temp = temp%>%select(-new.party)%>%
  melt(id = c('sourcemediaid', 'party'))%>%
  # filter(party != 'Unknown')%>%
  mutate(variable = ifelse(variable == 'agent', 'Agent', 'Customer'))%>%
  arrange(sourcemediaid)%>%
  group_by(sourcemediaid)%>%
  top_n(1,value)%>%
  slice(1)%>%
  ungroup()%>%
  mutate(switch = ifelse(party == variable, FALSE, TRUE))


df = df%>%
  left_join(temp%>%select(sourcemediaid, switch), by = 'sourcemediaid')%>%
  mutate(
    party = case_when(
      party == 'Agent' & switch == TRUE ~ 'Customer',
      party == 'Agent' & switch == FALSE ~ 'Agent',
      party == 'Customer' & switch == TRUE ~ 'Agent',
      party == 'Customer' & switch == FALSE ~ 'Customer',
      TRUE ~ 'Unknown'
    )
  )%>%
  select(-switch)

write_delim(df, file.path(outputfilepath, filenm[[i]]), delim='|')
  
  rm(df)
  rm(temp)
  
  }
