library(tidyverse)

## Import data
rawTbl = tibble()
csvs = list.files(pattern='\\.csv$')
drop.cols <- c('type', 'attrname', 'attrvalue')
for (csv in csvs) {
  rsuCount = as.numeric(str_split(csv, "_")[[1]][1])
  beaconFreq = 1/as.numeric(str_split(csv, "_")[[1]][2])
  print(str_c('Importing file ', csv))
  fileTbl = read_csv(csv, col_types='ccccccn') %>%
    mutate(rc=rsuCount, bf=beaconFreq) %>%
    filter(!is.na(value)) %>% # Throw out rows containing only metadata
    select(-one_of(drop.cols)) %>% # Throw out redundant columns
    spread(name, value)
  rawTbl = bind_rows(rawTbl, fileTbl)
}

## totalBusyTime ecdf
p = ggplot(rawTbl, aes(x=totalBusyTime, color=run))
p = p + stat_ecdf()
p = p + facet_grid(rows=vars(bf), cols=vars(rc))

## TotalLostPackets ecdf
p = ggplot(rawTbl, aes(x=TotalLostPackets, color=run))
p = p + stat_ecdf()
p = p + facet_grid(bf ~ rc, labeller=label_both)

## Transform busyTbl
plotTbl = rawTbl %>%
  group_by(rc, bf) %>%
  summarise(meanBusy=mean(totalBusyTime),
            meanLost=mean(TotalLostPackets),
            # 95% confidence level for student t distribution
            errorBusy=abs(qt(.05/2, df=n()-1))*sd(totalBusyTime)/sqrt(n()),
            errorLost=abs(qt(.05/2, df=n()-1))*sd(TotalLostPackets)/sqrt(n()))

## totalBusyTime mean plot
p = ggplot(plotTbl, aes(x=bf, y=meanBusy, color=as.factor(rc)))
p = p + geom_point()
p = p + geom_line()
p = p + geom_errorbar(aes(ymin=meanBusy-errorBusy, ymax=meanBusy+errorBusy))
p = p + theme_bw()
p = p + labs(x = "Beacon frequency in Hz")
p = p + labs(y = "Mean totalBusyTime in seconds")
p = p + labs(color = "Number of RSUs")
p = p + labs(title = "Includes 95% confidence intervals for the mean value over all RSUs and runs")
ggsave("busyTime_mean.pdf")

## TotalLostPackets mean plot
p = ggplot(plotTbl, aes(x=bf, y=meanLost, color=as.factor(rc)))
p = p + geom_point()
p = p + geom_line()
p = p + geom_errorbar(aes(ymin=meanLost-errorLost, ymax=meanLost+errorLost))
p = p + theme_bw()
p = p + labs(x = "Beacon frequency in Hz")
p = p + labs(y = "Mean TotalLostPackets")
p = p + labs(color = "Number of RSUs")
p = p + labs(title = "Includes 95% confidence intervals for the mean value over all RSUs and runs")
ggsave("lostPackets_mean.pdf")
