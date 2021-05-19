library(tidyverse)

## Import data
scalarTbl = tibble()
tsvs = list.files(pattern='sca\\.tsv$')
for (tsv in tsvs) {
  fileTbl = read_tsv(tsv) %>%
    filter(nod_name == "Scenario.rsu[0].nic.mac1609_4") %>%
    mutate(experiment=str_split(tsv, '-')[[1]][1],
           run=str_remove(str_split(str_split(tsv, '-')[[1]][2], "\\.")[[1]][1], "#"))
  scalarTbl = bind_rows(scalarTbl, fileTbl)
}

delayTbl = tibble()
tsvs = list.files(pattern='delay..\\.tsv$')
for (tsv in tsvs) {
  #assign(str_c(str_remove(tsv, '\\.tsv$'), "tbl"), tibble())
  fileTbl = read_tsv(tsv) %>%
    filter(node == "Scenario.rsu[1].appl") %>%
    gather(6, key="ac", value="value") %>%
    mutate(ac=str_remove(str_remove(ac, '\\:vector$'), '^delay'),
           delay_ms=value*1000)
  delayTbl = bind_rows(delayTbl, fileTbl)
}

countTbl = tibble()
tsvs = list.files(pattern='count..\\.tsv$')
for (tsv in tsvs) {
  #assign(str_c(str_remove(tsv, '\\.tsv$'), "tbl"), tibble())
  fileTbl = read_tsv(tsv) %>%
    filter(node == "Scenario.rsu[1].appl") %>%
    gather(6, key="ac", value="value") %>%
    mutate(ac=str_remove(str_remove(ac, '\\:vector$'), '^count'),
           goodput_kb=value*4000/(8*1000))
  countTbl = bind_rows(countTbl, fileTbl)
}

## Sanity check data
# end-to-end delay ecdf
p = ggplot(sample_frac(delayTbl, .1), aes(x=delay_ms, color=as.factor(repetition)))
p = p + stat_ecdf()
p = p + facet_grid(ac ~ experiment, labeller=label_both)
ggsave("delay_ecdf.pdf", width=297, height=210, units="mm")

# goodput ecdf
p = ggplot(countTbl, aes(x=goodput_kb, color=as.factor(repetition)))
p = p + stat_ecdf()
p = p + facet_grid(ac ~ experiment, labeller=label_both)
ggsave("goodput_ecdf.pdf", width=297, height=210, units="mm")

## Compress data
pltDelayTbl = delayTbl %>%
  group_by(experiment, ac) %>%
  summarise(mean=mean(delay_ms),
            # 95% confidence level for student t distribution
            error=abs(qt(.05/2, df=n()-1))*sd(delay_ms)/sqrt(n()))

pltGoodTbl = countTbl %>%
  filter(value > 0) %>%
  group_by(experiment, ac) %>%
  summarise(mean=mean(goodput_kb),
            # 95% confidence level for student t distribution
            error=abs(qt(.05/2, df=n()-1))*sd(goodput_kb)/sqrt(n()))

# AIFS values as read from Mac1609_4.cc
aifs = c(VO=2, VI=3, BE=6, BK=9)
pltSlotTbl = scalarTbl %>%
  group_by(experiment) %>%
  summarize(# Average no. of waiting slots for a single packet per access category
            VO=sum(SlotsBackoffVO)/sum(SentPacketsVO) + aifs["VO"][[1]],
            VI=sum(SlotsBackoffVI)/sum(SentPacketsVI) + aifs["VI"][[1]],
            BE=sum(SlotsBackoffBE)/sum(SentPacketsBE) + aifs["BE"][[1]],
            BK=sum(SlotsBackoffBK)/sum(SentPacketsBK) + aifs["BK"][[1]]) %>%
  gather(`VO`, `VI`, `BE`, `BK`, key="ac", value = "slotsPerPacket") %>%
  arrange(experiment) %>%
  drop_na(slotsPerPacket)
  

## Plot data
pltDelayTbl$ac <- factor(pltDelayTbl$ac, levels=c("VO", "VI", "BE", "BK"))
p = ggplot(pltDelayTbl, aes(x=ac, y=mean, fill=experiment))
p = p + geom_bar(stat="identity", position=position_dodge())
p = p + geom_errorbar(aes(ymin=mean-error,
                          ymax=mean+error),
                      width=.2,
                      position=position_dodge(.9))
p = p + scale_y_log10(breaks = scales::trans_breaks("log10", function(x) 10^x),
                      labels = scales::trans_format("log10", scales::math_format(10^.x)))
p = p + annotation_logticks(sides = "l")
p = p + theme_bw()
p = p + labs(x = "Access category")
p = p + labs(y = "Mean end-to-end delay in ms")
p = p + labs(fill = "Scenario")
p = p + labs(title = "Includes 95% confidence intervals for the mean value over all runs")
ggsave("delay_bars.pdf", width=297, height=210, units="mm")

pltGoodTbl$ac <- factor(pltGoodTbl$ac, levels=c("VO", "VI", "BE", "BK"))
p = ggplot(pltGoodTbl, aes(x=ac, y=mean, fill=experiment))
p = p + geom_bar(stat="identity", position=position_dodge())
p = p + geom_errorbar(aes(ymin=mean-error,
                          ymax=mean+error),
                      width=.2,
                      position=position_dodge(.9))
p = p + scale_y_log10(breaks = scales::trans_breaks("log10", function(x) 10^x),
                      labels = scales::trans_format("log10", scales::math_format(10^.x)))
p = p + annotation_logticks(sides = "l")
p = p + theme_bw()
p = p + labs(x = "Access category")
p = p + labs(y = "Mean goodput in KB/s")
p = p + labs(fill = "Scenario")
p = p + labs(title = "Includes 95% confidence intervals for the mean value over all runs")
ggsave("goodput_bars.pdf", width=297, height=210, units="mm")

pltSlotTbl$ac <- factor(pltSlotTbl$ac, levels=c("VO", "VI", "BE", "BK"))
p = ggplot(pltSlotTbl, aes(x=ac, y=slotsPerPacket, fill=experiment))
p = p + geom_bar(stat="identity", position=position_dodge())
p = p + theme_bw()
p = p + labs(x = "Access category")
p = p + labs(y = "Mean number of waiting slots per packet (AIFS + backoff)")
p = p + labs(fill = "Scenario")
ggsave("slots_bars.pdf", width=297, height=210, units="mm")