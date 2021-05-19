library(tidyverse)

## Import data
vecTbl = read_tsv("out.tsv", col_types='ddccciiiiidddd') %>%
  group_by(measurement) %>%
  mutate(rsuCount=parse_number(str_split(measurement, ", ")[[1]][1]),
         interArrival=parse_number(str_split(measurement, ", ")[[1]][2])) %>%
  ungroup()

scalarTbl = tibble()
tsvs = list.files(pattern='sca\\.tsv$')
for (tsv in tsvs) {
  fileTbl = read_tsv(tsv) %>%
    mutate(rsuCount=parse_number(str_split(str_split(tsv, '-')[[1]][2], ",")[[1]][1]),
           interArrival=parse_number(str_split(str_split(tsv, '-')[[1]][2], ",")[[1]][2]),
           run=parse_number(str_split(tsv, '-')[[1]][3]))
  scalarTbl = bind_rows(scalarTbl, fileTbl)
}

## Compress data
delays = c("delayVO:vector", "delayVI:vector", "delayBE:vector", "delayBK:vector")
counts = c("countVO:vector", "countVI:vector", "countBE:vector", "countBK:vector")
vars = c(delays, counts)
tmpTbl = vecTbl %>%
  group_by(rsuCount, interArrival) %>%
  summarise_at(vars, list(mean = ~mean(., na.rm=T),
                          count = ~sum(!is.na(.)),
                          # 95% confidence level for student t distribution
                          err = ~abs(qt(.05/2,df=sum(!is.na(.))-1))*sd(., na.rm=T)/sqrt(sum(!is.na(.)))))

meanDelayTbl = tmpTbl %>%
  select(rsuCount, interArrival, matches("^delay.*mean$")) %>%
  gather(str_c(delays, '_mean'), key="metric", value="meanDelay") %>%
  group_by(rsuCount, interArrival, metric) %>%
  mutate(ac=str_c(str_extract_all(metric, "\\p{Uppercase}")[[1]], collapse='')) %>%
  ungroup() %>%
  select(-one_of("metric"))
errDelayTbl = tmpTbl %>%
  select(rsuCount, interArrival, matches("^delay.*err$")) %>%
  gather(str_c(delays, '_err'), key="metric", value="errDelay") %>%
  group_by(rsuCount, interArrival, metric) %>%
  mutate(ac=str_c(str_extract_all(metric, "\\p{Uppercase}")[[1]], collapse='')) %>%
  ungroup() %>%
  select(-one_of("metric"))
meanCountTbl = tmpTbl %>%
  select(rsuCount, interArrival, matches("^count.*mean$")) %>%
  gather(str_c(counts, '_mean'), key="metric", value="meanCount") %>%
  group_by(rsuCount, interArrival, metric) %>%
  mutate(ac=str_c(str_extract_all(metric, "\\p{Uppercase}")[[1]], collapse='')) %>%
  ungroup() %>%
  select(-one_of("metric"))
errCountTbl = tmpTbl %>%
  select(rsuCount, interArrival, matches("^count.*err$")) %>%
  gather(str_c(counts, '_err'), key="metric", value="errCount") %>%
  group_by(rsuCount, interArrival, metric) %>%
  mutate(ac=str_c(str_extract_all(metric, "\\p{Uppercase}")[[1]], collapse='')) %>%
  ungroup() %>%
  select(-one_of("metric"))
countDelayTbl = tmpTbl %>%
  select(rsuCount, interArrival, matches("^delay.*count$")) %>%
  gather(str_c(delays, '_count'), key="metric", value="countDelay") %>%
  group_by(rsuCount, interArrival, metric) %>%
  mutate(ac=str_c(str_extract_all(metric, "\\p{Uppercase}")[[1]], collapse='')) %>%
  ungroup() %>%
  select(-one_of("metric"))
countCountTbl = tmpTbl %>%
  select(rsuCount, interArrival, matches("^count.*count$")) %>%
  gather(str_c(counts, '_count'), key="metric", value="countCount") %>%
  group_by(rsuCount, interArrival, metric) %>%
  mutate(ac=str_c(str_extract_all(metric, "\\p{Uppercase}")[[1]], collapse='')) %>%
  ungroup() %>%
  select(-one_of("metric"))

pltTbl = meanDelayTbl %>%
  full_join(errDelayTbl, by=c("rsuCount", "interArrival", "ac")) %>%
  full_join(meanCountTbl, by=c("rsuCount", "interArrival", "ac")) %>%
  full_join(errCountTbl, by=c("rsuCount", "interArrival", "ac")) %>%
  full_join(countDelayTbl, by=c("rsuCount", "interArrival", "ac")) %>%
  full_join(countCountTbl, by=c("rsuCount", "interArrival", "ac")) %>%
  filter(countDelay > 10) %>%
  mutate(delay_ms=meanDelay*1000,
         err_ms=errDelay*1000,
         #good_kb=meanCount*4000/(8*1000),
         #err_kb=errCount*4000/(8*1000)) %>%
         good_kb=meanCount*4000,
         err_kb=errCount*4000) %>%
  na.omit(meanDelay) %>%
  mutate(rsuCount=as.factor(rsuCount),
         interArrival=as.factor(interArrival),
         ac=as.factor(ac)) %>%
  complete(rsuCount, interArrival, ac, fill=list(delay_ms=1, good_kb=1))

tmpTbl = scalarTbl %>%
  group_by(rsuCount, interArrival) %>%
  summarize(VO=sum(SentPacketsVO),
            VI=sum(SentPacketsVI),
            BE=sum(SentPacketsBE),
            BK=sum(SentPacketsBK)) %>%
  gather(`VO`, `VI`, `BE`, `BK`, key="ac", value = "sentPackets") %>%
  arrange(rsuCount, interArrival) %>%
  ungroup() %>%
  mutate(rsuCount=as.factor(rsuCount),
         interArrival=as.factor(interArrival),
         ac=as.factor(ac)) %>%
  filter(sentPackets > 10) %>%
  complete(rsuCount, interArrival, ac)

# AIFS values as read from Mac1609_4.cc
aifs = c(VO=2, VI=3, BE=6, BK=9)
pltSlotTbl = scalarTbl %>%
  group_by(rsuCount, interArrival) %>%
  summarize(# Average no. of waiting slots for a single packet per access category
    VO=sum(SlotsBackoffVO)/sum(SentPacketsVO) + aifs["VO"][[1]],
    VI=sum(SlotsBackoffVI)/sum(SentPacketsVI) + aifs["VI"][[1]],
    BE=sum(SlotsBackoffBE)/sum(SentPacketsBE) + aifs["BE"][[1]],
    BK=sum(SlotsBackoffBK)/sum(SentPacketsBK) + aifs["BK"][[1]]) %>%
  gather(`VO`, `VI`, `BE`, `BK`, key="ac", value = "slotsPerPacket") %>%
  arrange(rsuCount, interArrival) %>%
  filter(!is.infinite(slotsPerPacket)) %>%
  ungroup() %>%
  mutate(rsuCount=as.factor(rsuCount),
         interArrival=as.factor(interArrival),
         ac=as.factor(ac)) %>%
  complete(rsuCount, interArrival, ac) %>%
  full_join(tmpTbl, by=c("rsuCount", "interArrival", "ac")) %>%
  drop_na(sentPackets) %>%
  complete(rsuCount, interArrival, ac, fill=list(slotsPerPacket=0, SentPackets=0))

## Plot data
pltTbl$ac <- factor(pltTbl$ac, levels=c("VO", "VI", "BE", "BK"))
p = ggplot(pltTbl, aes(x=as.factor(rsuCount), y=delay_ms, fill=ac))
p = p + geom_bar(stat="identity", position=position_dodge())
p = p + geom_errorbar(aes(ymin=delay_ms-err_ms,
                          ymax=delay_ms+err_ms),
                      width=.2,
                      position=position_dodge(.9))
p = p + facet_grid(rows=vars(interArrival),
                   labeller = labeller(interArrival = c(`5` = "Inter arrival time = 5ms",
                                                        `10` = "Inter arrival time = 10ms")))
p = p + scale_y_log10(breaks = scales::trans_breaks("log10", function(x) 10^x),
                      labels = scales::trans_format("log10", scales::math_format(10^.x)))
p = p + annotation_logticks(sides = "l")
p = p + theme_bw()
p = p + labs(x = "Number of RSUs")
p = p + labs(y = "Mean end-to-end delay in ms")
p = p + labs(fill = "Access category")
p = p + labs(subtitle = "Includes 95% confidence intervals for the mean value over all runs and RSUs",
             title = "Bars are drawn only if they represent more than 10 received packets")
show(p)
ggsave("delay_bars.pdf", width=297, height=210, units="mm")

p = ggplot(pltTbl, aes(x=as.factor(rsuCount), y=good_kb, fill=ac))
p = p + geom_bar(stat="identity", position=position_dodge())
p = p + geom_errorbar(aes(ymin=good_kb-err_kb,
                          ymax=good_kb+err_kb),
                      width=.2,
                      position=position_dodge(.9))
p = p + facet_grid(rows=vars(interArrival),
                   labeller = labeller(interArrival = c(`5` = "Inter arrival time = 5ms",
                                                        `10` = "Inter arrival time = 10ms")))
p = p + scale_y_log10(breaks = scales::trans_breaks("log10", function(x) 10^x),
                      labels = scales::trans_format("log10", scales::math_format(10^.x)))
p = p + annotation_logticks(sides = "l")
p = p + theme_bw()
p = p + labs(x = "Number of RSUs")
p = p + labs(y = "Mean goodput in Bit/s")
p = p + labs(fill = "Access category")
p = p + labs(subtitle = "Includes 95% confidence intervals for the mean value over all runs and RSUs",
             title = "Bars are drawn only if they represent more than 10 received packets")
show(p)
ggsave("goodput_bars.pdf", width=297, height=210, units="mm")

pltSlotTbl$ac <- factor(pltSlotTbl$ac, levels=c("VO", "VI", "BE", "BK"))
p = ggplot(pltSlotTbl, aes(x=rsuCount, y=slotsPerPacket, fill=ac))
p = p + geom_bar(stat="identity", position=position_dodge())
p = p + facet_grid(rows=vars(interArrival),
                   labeller = labeller(interArrival = c(`5` = "Inter arrival time = 5ms",
                                                        `10` = "Inter arrival time = 10ms")))
# p = p + scale_y_log10(breaks = scales::trans_breaks("log10", function(x) 10^x),
#                       labels = scales::trans_format("log10", scales::math_format(10^.x)))
# p = p + annotation_logticks(sides = "l")
p = p + theme_bw()
p = p + labs(x = "Number of RSUs")
p = p + labs(y = "Mean number of waiting slots per packet (AIFS + backoff)")
p = p + labs(title = "Bars are drawn only if they represent more than 10 sent packets")
p = p + labs(fill = "Access category")
show(p)
ggsave("slots_bars.pdf", width=297, height=210, units="mm")
