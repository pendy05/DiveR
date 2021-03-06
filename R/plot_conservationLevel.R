plotting7<-function(proteindata,line_dot_size, wordsize,host,proteinOrder){
  p<-ggplot(proteindata,
            environment = environment()) +
    geom_boxplot(aes(x=level,y=index.incidence),outlier.shape=NA,width=0.5)+ 
    geom_jitter(aes(x=level,y=index.incidence,col=ConservationLevel),position = position_jitter(width = .15, height=-0.7),
                size=line_dot_size)+
    labs(x=NULL,y="Index Incidence (%)\n",fill="Conservation level")+ #, title = unique(data$host)
    scale_y_continuous(breaks = c(0,25,50,75,100),labels=c("0","25","50","75","100"),limits = c(0,110))+
    theme_classic(base_size = wordsize)+
    theme(
      legend.key = element_rect(fill = "transparent", colour = "transparent"),
      legend.position="bottom"
    )+
    scale_colour_manual('Conservation Level',breaks=c("Completely conserved (CC)","Highly conserved (HC)","Mixed variable (MV)","Highly diverse (HD)","Extremely diverse (ED)"),
                        values = c("Completely conserved (CC)"="black","Highly conserved (HC)"="#0057d1","Mixed variable (MV)"="#02d57f","Highly diverse (HD)"="#8722ff", "Extremely diverse (ED)"="#ff617d")) +  
    guides(color = guide_legend(override.aes = list(size = 2),nrow=2))+
    theme(plot.margin = unit(c(5, 1, 1, 1), "lines"),axis.text.x = element_text(angle = 55, vjust = 0.5, hjust=0.5)) +
    coord_cartesian(clip = "off") + #allow ggtext outside of the plot
      ggtitle(toTitleCase(paste(data$host,"Host",sep=" ")))
  ggplotly(p)
}


#latest version for ggplot2
plot_conservationLevel<- function(data,line_dot_size,wordsize,host,proteinOrder,conservationLabel){
  #add word 'protein' in front of each protein name
  data$proteinName<-paste("Protein",data$proteinName)
  #create data for proteome bar "All" from existing data
  data1<-data
  data1$proteinName <- "All"
  data1$level <- "All"
  #set up the order of proteins in plot from left to right
  if (proteinOrder ==""){ #follow the default order in csv file
    level<-c("All",unique(data$proteinName))
  }else{ #order the proteins based on user input
    proteins<-paste("Protein",unlist(lapply(strsplit(proteinOrder,','),trimws)))
    level<-c("All",proteins)
  }
  #determine the protein order
  data$level = factor(data$proteinName, levels=level)
  #combine proteome bar with protein bars
  data<-rbind(data1,data)
  #determine the protein order
  data$level = factor(data$proteinName, levels=level)
  #calculation for total and percentage of conservation levels for each protein
  #sum up the total positions for each conservation level of proteins
  plot7_data<-ddply(data,.(proteinName,ConservationLevel),nrow)
  names(plot7_data)[3]<-"Total"
  
  C_level<- c("Completely conserved (CC)","Highly conserved (HC)","Mixed variable (MV)","Highly diverse (HD)","Extremely diverse (ED)")
  if (conservationLabel == 1){ #full label
    #check the presence of conservation level: insert value 0 if it is absent
    for ( conservation in C_level){ #conservation level
      for (name in level){ #proteinName
        if (!(conservation %in% plot7_data[plot7_data$proteinName==name,]$ConservationLevel)){
          plot7_data<-rbind(plot7_data,c(name,conservation,0))
        }}}
  }
  #sort the dataframe
  plot7_data[order(plot7_data$proteinName),]
  plot7_data$Total<- as.integer(plot7_data$Total)
  #get the percentage of each conservation level for each protein
  plot7_data<-ddply(plot7_data,.(proteinName),transform, percent=Total/sum(Total)*100)
  
  #gather the protein label in multicolor
  plot7_data<-plot7_data%>%mutate(Label = case_when(
    plot7_data$ConservationLevel == "Completely conserved (CC)" ~ paste0(sprintf("<span style =
    'color:#000000;'>CC: %.0f (%.1f %%) </span>",plot7_data$Total, round(plot7_data$percent,1))),
    plot7_data$ConservationLevel == "Highly conserved (HC)" ~ paste0(sprintf("<span style =
    'color:#0057d1;'>HC: %.0f (%.1f %%) </span>",plot7_data$Total, round(plot7_data$percent,1))),
    plot7_data$ConservationLevel == "Mixed variable (MV)" ~ paste0(sprintf("<span style =
    'color:#02d57f;'>MV: %.0f (%.1f %%) </span>",plot7_data$Total, round(plot7_data$percent,1))),
    plot7_data$ConservationLevel == "Highly diverse (HD)" ~ paste0(sprintf("<span style =
    'color:#A022FF;'>HD: %.0f (%.1f %%) </span>",plot7_data$Total, round(plot7_data$percent,1))),
    plot7_data$ConservationLevel == "Extremely diverse (ED)" ~ paste0(sprintf("<span style =
    'color:#ff617d;'>ED: %.0f (%.1f %%) </span>",plot7_data$Total, round(plot7_data$percent,1))),
    
  ))
  #set conservation level in specific order (CC,HC,MV,HD,ED)
  plot7_data<-plot7_data[order(factor(plot7_data$ConservationLevel, levels=c("Completely conserved (CC)","Highly conserved (HC)","Mixed variable (MV)","Highly diverse (HD)","Extremely diverse (ED)"))),]
  proteinTotal<-length(unique(plot7_data[['proteinName']]))
  #combine all conservation level labels into one for each protein
  Proteinlabel<- aggregate(Label~proteinName, plot7_data, paste, collapse="<br>")
  #rearrange protein order
  plot7_data<-plot7_data[order(factor(plot7_data$proteinName,levels=level)),]
  #get number of protein for labelling
  nProtein<-nrow(Proteinlabel)

    #plotting
    plot7<- ggplot(data, aes(x=level,y=index.incidence))+
    # gghalves
    geom_half_boxplot(outlier.shape = NA) +
    geom_half_point(aes(col = ConservationLevel), side = "r", 
                    position = position_jitter(width = 0, height=-0.7), size=line_dot_size, alpha=0.6) +
    ylim(0,105) +
    labs(x=NULL, y="Index incidence (%)\n", fill="Conservation level")+
      theme_classic(base_size = wordsize)+
      theme(
        legend.key = element_rect(fill = "transparent", colour = "transparent"),
        legend.position = 'bottom',
      plot.margin = unit(c(5, 1, 1, 1), "lines"),
      axis.ticks.x = element_blank(),
      axis.text.x = element_text(angle = 55, vjust = 0.5, hjust=0.5)
    )+
      scale_colour_manual('Conservation Level',
                        breaks = c("Completely conserved (CC)",
                                   "Highly conserved (HC)",
                                   "Mixed variable (MV)",
                                   "Highly diverse (HD)",
                                   "Extremely diverse (ED)"),
                        values = c("Completely conserved (CC)"="black",
                                   "Highly conserved (HC)"="#0057d1",
                                   "Mixed variable (MV)"="#02d57f",
                                   "Highly diverse (HD)"="#8722ff", 
                                   "Extremely diverse (ED)"="#ff617d")) +  
    geom_richtext(data = Proteinlabel, 
                  aes(x=proteinName,label = Label, y=c(rep(105,nProtein)),
                      label.size=0, label.color="transparent"),
                  position = position_dodge(width=0.1), 
                  size=((wordsize/2)-2), color="black", hjust=0, angle=90) + 
    guides(color = guide_legend(override.aes = list(size = 2), nrow=2))+
    coord_cartesian(clip = "off")+
    ggtitle(unique(data$host))
    plot7
}

