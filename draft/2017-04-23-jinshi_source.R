library(rgdal)
library(maps)
library(maptools)
library(broom)
library(ggplot2)
cn.mapdata <- readOGR("下载/Regime_Bou/CHN_adm1.shp")
tw.mapdata <- readOGR("下载/Regime_Bou/TWN_adm0.shp")
p.chn <- ggplot() + geom_polygon(
    aes(long, lat, group=group), data=cn.mapdata, 
    fill='gray97', color='gray', linetype=2, size=0.2) + 
    geom_polygon(
        aes(long, lat, group=group), data=tw.mapdata, 
        fill='gray97', color='gray', linetype=2, size=0.2) +
    theme_minimal() + coord_map() 

get_xml_list <- function(xml){
    library(XML)
    xmlToList(xmlParse(xml))
}
get_coord_df <- function(lst, split="[ ,]", id=1){
    staging <- strsplit(lst, split)
    out <- data.frame(matrix(
        as.numeric(unlist(staging)), byrow=TRUE, ncol=2))
    names(out) <- c("long", "lat")
    out$id <- id
    return(out)
}

nsong.xml <- get_xml_list("~/下载/northSong.kml")
nsong.bou <- c(
    nsong.xml[[1]][[3]][[3]]$Polygon$outerBoundaryIs$LinearRing$coordinates,
    nsong.xml[[1]][[3]][[4]]$Polygon$outerBoundaryIs$LinearRing$coordinates)
nsong.bou <- mapply(get_coord_df, nsong.bou, id=1:2, SIMPLIFY=FALSE)
names(nsong.bou) <- 1:2
nsong.bou <- do.call('rbind', nsong.bou)

ming.xml <- get_xml_list("~/下载/ming.kml")
ming.bou <- c(
    ming.xml[[1]][[3]][[3]]$outerBoundaryIs$LinearRing$coordinates,
    ming.xml[[1]][[4]][[3]]$outerBoundaryIs$LinearRing$coordinates,
    ming.xml[[1]][[5]][[3]]$outerBoundaryIs$LinearRing$coordinates)
ming.bou <- mapply(get_coord_df, ming.bou, id=1:3, SIMPLIFY=FALSE)
names(ming.bou) <- 1:3
ming.bou <- do.call('rbind', ming.bou)

qing.xml <- get_xml_list("~/下载/qing.kml")
qing.bou <- c(
    qing.xml[[1]][[3]][[3]]$outerBoundaryIs$LinearRing$coordinates,
    qing.xml[[1]][[4]][[3]]$outerBoundaryIs$LinearRing$coordinates,
    qing.xml[[1]][[5]][[3]]$outerBoundaryIs$LinearRing$coordinates,
    qing.xml[[1]][[6]][[3]]$outerBoundaryIs$LinearRing$coordinates)
qing.bou <- mapply(get_coord_df, qing.bou, id=1:4, SIMPLIFY=FALSE)
names(qing.bou) <- 1:4
qing.bou <- do.call('rbind', qing.bou)

p.song <- p.chn + geom_polygon(aes(long, lat, group=id), data=nsong.bou, fill="red", alpha=0.1) +
    ggtitle("北宋疆域")
p.ming <- p.chn + geom_polygon(aes(long, lat, group=id), data=ming.bou, fill="red", alpha=0.1) +
    ggtitle("明朝疆域")
p.qing <- p.chn + geom_polygon(aes(long, lat, group=id), data=qing.bou, fill="black", alpha=0.1)+
    ggtitle("清朝疆域")

library(readr)
nsong.js <- read_csv("下载/CBDB_exams_NSong_WGS84_kto.csv")
p.song + geom_point(aes(x_coord, y_coord), data=nsong.js, color="blue", alpha=0.2, size=0.5) +
    ggtitle("北宋进士来源地")
p.song + stat_density_2d(aes(x_coord, y_coord, fill=..level..), 
                         data=nsong.js, geom="polygon", alpha=0.5) +
    scale_fill_gradient(low="cyan", high="darkblue")+
    ggtitle("北宋进士来源地")

ming.js <- read_csv("下载/CBDB_exams_Ming_WGS84_MbJ.csv")
p.ming + geom_point(aes(x_coord, y_coord), data=ming.js, color="blue", alpha=0.2, size=0.5)+
    ggtitle("明朝进士来源地")
p.ming + stat_density_2d(aes(x_coord, y_coord, fill=..level..), data=ming.js, geom="polygon", alpha=0.5) +
    scale_fill_gradient(low="cyan", high="darkblue")+
    ggtitle("明朝进士来源地")

qing.js <- read_csv("下载/CBDB_exams_Qing_WGS84_GWU.csv")
p.qing + geom_point(aes(x_coord, y_coord), data=qing.js, color="blue", alpha=0.2, size=0.5)+
    ggtitle("清朝进士来源地")
p.qing + stat_density_2d(aes(x_coord, y_coord, fill=..level..), data=qing.js, geom="polygon", alpha=0.5) +
    scale_fill_gradient(low="cyan", high="darkblue")+
    ggtitle("清朝进士来源地")

#cbdb
library(RSQLite)
con <- dbConnect(SQLite(), "下载/cbdb_sqlite.db")
addr <- dbReadTable(con, "ADDRESSES")
dbDisconnect(con)

# 北宋
addr.song <- addr[addr$belongs3_Name=="宋朝" | addr$belongs4_Name=="宋朝" |
                      addr$belongs5_Name=="宋朝",]
addr.song <- addr.song[!is.na(addr.song$c_name_chn),]
addr.song$Prov <- addr.song$belongs2_Name
i=which(addr.song$belongs4_Name=="宋朝")
addr.song$Prov[i] <- addr.song$belongs3_Name[i]
addr.song <- addr.song[!duplicated(addr.song$c_name_chn),]

nsong.js <- merge(nsong.js, addr.song[,c("c_name_chn", "Prov")], 
                  by.x="AddrChn", by.y="c_name_chn", all.x=TRUE)
nsong.js$Decade <- cut(as.numeric(nsong.js$EntryYear), seq(960, 1130, 10))
nsong.js$Decade <- factor(nsong.js$Decade, 
                          labels=seq(960, 1130, 10)[1:nlevels(nsong.js$Decade)])
library(data.table)
nsong.stat1 <- dcast(nsong.js, Prov~., length)
nsong.stat1 <- nsong.stat1[order(nsong.stat1$., decreasing=TRUE),]

nsong.stat <- dcast(nsong.js, Decade~Prov, length)
nsong.stat <- melt(nsong.stat, id="Decade", stringsAsFactors=FALSE)
nsong.stat$Decade <- as.integer(as.character(nsong.stat$Decade))
nsong.stat$variable <- factor(nsong.stat$variable, levels=nsong.stat1$Prov)
nsong.stat <- nsong.stat[!is.na(nsong.stat$variable) & nsong.stat$variable != 'NA',]

library(ggthemes)
cols <- c(hc_pal()(10), tableau_color_pal()(10), wsj_pal()(6), canva_pal()(4),
          economist_pal()(10))
cols <- cols[(1:nlevels(nsong.stat$variable))]
names(cols) <- levels(nsong.stat$variable)
ggplot(nsong.stat, aes(Decade, value, fill=variable))+
    geom_area(stat="identity", position="fill", alpha=0.75) + 
    scale_fill_manual(values=cols) + theme_minimal() +
    scale_y_continuous(labels=scales::percent)+
    xlab("年份") + ylab("比重") + ggtitle("北宋进士来源地比重变迁")+
    theme(legend.position="bottom")

# 明朝 
addr.ming <- addr[addr$belongs3_Name=="明朝" | addr$belongs4_Name=="明朝" |
                      addr$belongs5_Name=="明朝",]
addr.ming <- addr.ming[!is.na(addr.ming$c_name_chn),]
addr.ming$Prov <- addr.ming$belongs2_Name
i=which(addr.ming$belongs4_Name=="明朝")
addr.ming$Prov[i] <- addr.ming$belongs3_Name[i]
i=which(addr.ming$belongs5_Name=="明朝")
addr.ming$Prov[i] <- addr.ming$belongs4_Name[i]
addr.ming <- addr.ming[!duplicated(addr.ming$c_name_chn),]

ming.js <- merge(ming.js, addr.ming[,c("c_name_chn", "Prov")], 
                  by.x="AddrChn", by.y="c_name_chn", all.x=TRUE)
ming.js$Decade <- cut(as.numeric(ming.js$EntryYear), seq(1360, 1650, 10))
ming.js$Decade <- factor(ming.js$Decade, 
                          labels=seq(1360, 1650, 10)[1:nlevels(ming.js$Decade)])

ming.js$Prov <- gsub("(^.+)(布政司|巡撫|總督|留守司)$", "\\1", ming.js$Prov)
ming.stat1 <- dcast(ming.js, Prov~., length)
ming.stat1 <- ming.stat1[order(ming.stat1$., decreasing=TRUE),]

ming.stat <- dcast(ming.js, Decade~Prov, length)
ming.stat <- melt(ming.stat, id="Decade", stringsAsFactors=FALSE)
ming.stat$Decade <- as.integer(as.character(ming.stat$Decade))
ming.stat$variable <- factor(ming.stat$variable, levels=ming.stat1$Prov)
ming.stat <- ming.stat[!is.na(ming.stat$variable) & ming.stat$variable != 'NA',]

library(ggthemes)
cols <- c(hc_pal()(10), tableau_color_pal()(10), wsj_pal()(6), canva_pal()(4),
          economist_pal()(10))
cols <- cols[(1:nlevels(ming.stat$variable))]
names(cols) <- levels(ming.stat$variable)
ggplot(ming.stat, aes(Decade, value, fill=variable))+
    geom_area(stat="identity", position="fill", alpha=0.75) + 
    scale_fill_manual(values=cols) + theme_minimal() +
    scale_y_continuous(labels=scales::percent)+
    xlab("年份") + ylab("比重") + ggtitle("明朝进士来源地比重变迁")+
    theme(legend.position="bottom")


# 清朝 
addr.qing <- addr[addr$belongs3_Name=="清朝" | addr$belongs4_Name=="清朝" |
                      addr$belongs5_Name=="清朝",]
addr.qing <- addr.qing[!is.na(addr.qing$c_name_chn),]
addr.qing$Prov <- addr.qing$belongs2_Name
i=which(addr.qing$belongs4_Name=="清朝")
addr.qing$Prov[i] <- addr.qing$belongs3_Name[i]
i=which(addr.qing$belongs5_Name=="清朝")
addr.qing$Prov[i] <- addr.qing$belongs4_Name[i]
addr.qing <- addr.qing[!duplicated(addr.qing$c_name_chn),]

qing.js <- merge(qing.js, addr.qing[,c("c_name_chn", "Prov")], 
                 by.x="AddrChn", by.y="c_name_chn", all.x=TRUE)
qing.js$Decade <- cut(as.numeric(qing.js$EntryYear), seq(1640, 1910, 10))
qing.js$Decade <- factor(qing.js$Decade, 
                         labels=seq(1640, 1910, 10)[1:nlevels(qing.js$Decade)])

qing.stat1 <- dcast(qing.js, Prov~., length)
qing.stat1 <- qing.stat1[order(qing.stat1$., decreasing=TRUE),]

qing.stat <- dcast(qing.js, Decade~Prov, length)
qing.stat <- melt(qing.stat, id="Decade", stringsAsFactors=FALSE)
qing.stat$Decade <- as.integer(as.character(qing.stat$Decade))
qing.stat$variable <- factor(qing.stat$variable, levels=qing.stat1$Prov)
qing.stat <- qing.stat[!is.na(qing.stat$variable) & qing.stat$variable != 'NA',]

library(ggthemes)
cols <- c(hc_pal()(10), tableau_color_pal()(10), wsj_pal()(6), canva_pal()(4),
          economist_pal()(10))
cols <- cols[(1:nlevels(qing.stat$variable))]
names(cols) <- levels(qing.stat$variable)
ggplot(qing.stat, aes(Decade, value, fill=variable))+
    geom_area(stat="identity", position="fill", alpha=0.75) + 
    scale_fill_manual(values=cols) + theme_minimal() +
    scale_y_continuous(labels=scales::percent)+
    xlab("年份") + ylab("比重") + ggtitle("清朝进士来源地比重变迁")+
    theme(legend.position="bottom")

# all
ming.js$ExamRank <- as.character(ming.js$ExamRank)
qing.js$ExamRank <- as.character(qing.js$ExamRank)
library(dplyr)
jinshi <- do.call('bind_rows',list(nsong.js, ming.js,qing.js))
p.chn + geom_point(aes(x_coord, y_coord), data=jinshi, color="blue", alpha=0.2, size=0.5)+
    ggtitle("北宋、明、清进士来源地")
p.chn + stat_density_2d(aes(x_coord, y_coord, fill=..level..), data=jinshi, geom="polygon", alpha=0.5) +
    scale_fill_gradient(low="cyan", high="darkblue")+
    ggtitle("北宋、明、清进士来源地")
jinshi.stat <- dcast(jinshi, AddrChn~., length)
jinshi.stat <- jinshi.stat[order(jinshi.stat$., decreasing=TRUE),]

# family name
library(stringr)
fam.name <- str_sub(jinshi$NameChn, 1,1)
sort(table(fam.name), decreasing=TRUE)

jinshi$FamilyName <- fam.name
for (famName in c("王", "李", "瀳", "隇", "劉", "吳", "楊", "黃", "林", "周")){
    pp <- p.chn + geom_point(aes(x_coord, y_coord), data=jinshi[jinshi$FamilyName==famName,], 
                       color="blue", alpha=0.2, size=0.5)+
        stat_density_2d(aes(x_coord, y_coord, fill=..level..), 
                        data=jinshi[jinshi$FamilyName==famName,], geom="polygon", alpha=0.5) +
        scale_fill_gradient(low="cyan", high="darkblue")+
        ggtitle(paste0("北宋、明、清", fam.name, "姓进士来源地"))
    print(pp)
}

jinshi.putian <- jinshi[jinshi$AddrChn=='莆田',]
jinshi.putian <- dcast(jinshi.putian, EntryYear~., length)
jinshi.putian$EntryYear <- as.integer(jinshi.putian$EntryYear)
ggplot() + geom_bar(aes(EntryYear, .), stat='identity', data=jinshi.putian) + 
    theme_hc() + ggtitle("莆田进士数变迁") + xlab("年份") + ylab("人数")
