

setwd('SET_YOUR_WORKING_DIRECTORY_HERE')

library(survival)
library(ranger)
library(ggplot2)
library(dplyr)
library(ggfortify)
library(lubridate)
library(plm)
library(fpp3)
library(survminer)


data = read.csv('LOAN_surv.csv')
temp = read.csv('UNRATE.csv')
# Convert the DATE so that it has the same key I can use when merging. 
temp <- 
  temp %>% mutate(DATE = as.Date(DATE)) %>% mutate(YearMonth = format(DATE, "%Y%m"))
# Merge data and temp on the specified keys
data <- merge(data, temp, by.x = "MONTHLY_REPORTING_PERIOD", by.y = "YearMonth", all = FALSE)

temp1 = read.csv('pp_df_rate.csv')
temp2 = read.csv('UNRATE.csv')
temp2 <- 
  temp2 %>% mutate(DATE = as.Date(DATE)) %>% mutate(YearMonth = format(DATE, "%Y%m"))
timeseries_rate <- merge(temp1, temp2, by.x = "MONTHLY_REPORTING_PERIOD", by.y = "YearMonth", all = FALSE)
timeseries_rate = timeseries_rate %>% mutate(Date = as.Date(DATE)) %>% as_tsibble(index = Date)



ggplot(timeseries_rate, aes(x = Date)) +
  geom_line(aes(y = Prepay_rate*10, color = "Prepay_rate")) +
  geom_line(aes(y = Pos_frac*2-80, color = "Pos_frac")) +  # Rescale the pos_frac for comparison
  scale_y_continuous(
    name = "Prepay_rate",
    sec.axis = sec_axis(~./10, name = "Pos_frac")  # Adjusting the scale back to original for secondary axis
  ) +
  labs(title = "Prepay_rate and Pos_frac over Time",
       x = "Date") +
  scale_color_manual(values = c("Prepay_rate" = "blue", "Pos_frac" = "red")) +
  theme_minimal()+
  theme(
    axis.text.y = element_blank()
  )


KapM <- survfit(Surv(Start_time, Stop_time, Prepayment_status) ~ 1, data)
ggsurvplot(KapM, 
           data = data,             
           conf.int = TRUE,        
           risk.table = FALSE,
           censor = FALSE)


KapM1 <- survfit(Surv(Start_time, Stop_time, Prepayment_status) ~ TERM, data)
ggsurvplot(KapM1,
           data = data,             # Provide the data here
           conf.int = TRUE,        # Do not show confidence interval
           risk.table = FALSE,      # Do not show risk table
           censor = FALSE)


filtered_data <- data %>% filter(SCORE != "")

KapM2 <- survfit(Surv(Start_time, Stop_time, Prepayment_status) ~ SCORE, filtered_data)

ggsurvplot(KapM2, 
           data = filtered_data,            
           conf.int = TRUE,       
           risk.table = FALSE,     
           censor = FALSE)



filtered_data <- data %>% filter(SIZE != "")
KapM3 <- survfit(Surv(Start_time, Stop_time, Prepayment_status) ~ SIZE, filtered_data)
ggsurvplot(KapM3, 
           data = filtered_data,            
           conf.int = TRUE,       
           risk.table = FALSE,     
           censor = FALSE)


cox1 <- 
  coxph(Surv(Start_time, Stop_time, Prepayment_status) ~ CREDIT_SCORE +
          Rate_gap + UNRATE + ORIGINAL_LOAN.TO.VALUE + ORIGINAL_UPB + ORIGINAL_DEBT.TO.INCOME +
          ORIGINAL_LOAN_TERM, data)
summary(cox1)


newdata1 <- data.frame(
  CREDIT_SCORE = rep(700,2), Rate_gap = c(0, 1),
  UNRATE = rep(0,2), ORIGINAL_LOAN.TO.VALUE = rep(50,2),
  ORIGINAL_UPB = rep(mean(data$ORIGINAL_UPB),2), 
  ORIGINAL_DEBT.TO.INCOME = rep(mean(data$ORIGINAL_DEBT.TO.INCOME),2),
  ORIGINAL_LOAN_TERM = rep(360,2)
)

survplots <- survfit(cox1, newdata1)

plot(survplots, xlab = "Months",
     ylab = "Survival Probablity (Prepayment Risk)", col = 2:5)

legend("bottomleft", c('Zero Gap','Unit Gap'), col = 2:5, lty = 1)


newdata1 <- data.frame(
  CREDIT_SCORE = rep(700,2), Rate_gap = c(0, 1),
  UNRATE = rep(14,2), ORIGINAL_LOAN.TO.VALUE = rep(50,2),
  ORIGINAL_UPB = rep(mean(data$ORIGINAL_UPB),2), 
  ORIGINAL_DEBT.TO.INCOME = rep(mean(data$ORIGINAL_DEBT.TO.INCOME),2),
  ORIGINAL_LOAN_TERM = rep(360,2)
)

survplots <- survfit(cox1, newdata1)

plot(survplots, xlab = "Months",
     ylab = "Survival Probablity (Prepayment Risk)", col = 2:5)

legend("topright", c('Zero Gap','Unit Gap'), col = 2:5, lty = 1)


cox2 <- 
  coxph(Surv(Start_time, Stop_time, Prepayment_status) ~ CREDIT_SCORE +
          Rate_gap + UNRATE + UNRATE*Rate_gap + ORIGINAL_LOAN.TO.VALUE +
          ORIGINAL_UPB + ORIGINAL_DEBT.TO.INCOME +
          ORIGINAL_LOAN_TERM, data)
summary(cox2)

probit1 <- glm(Prepayment_status ~ CREDIT_SCORE + Rate_gap + UNRATE + 
                 ORIGINAL_LOAN.TO.VALUE + ORIGINAL_UPB + 
                 ORIGINAL_DEBT.TO.INCOME + 
                 ORIGINAL_LOAN_TERM + PROPERTY_STATE + LOAN_AGE, 
               family =binomial(link = "probit"), data = data)

summary(probit1)


lpm <- lm(Prepayment_status ~ CREDIT_SCORE + Rate_gap + UNRATE + ORIGINAL_LOAN.TO.VALUE + ORIGINAL_UPB + ORIGINAL_DEBT.TO.INCOME + ORIGINAL_LOAN_TERM + PROPERTY_STATE + LOAN_AGE, data)

summary(lpm)


pdata <- pdata.frame(data, index = c("LOAN_SEQUENCE_NUMBER", "DATE"))

lpm_fx <- plm(Prepayment_status ~ LOAN_AGE*CREDIT_SCORE + Rate_gap + UNRATE + LOAN_AGE, data=pdata, model = "within")

summary(lpm_fx)

