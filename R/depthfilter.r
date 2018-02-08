#' @aliases depthfilter
#' @title Filter locations by water depth
#' @description Function to remove fixes located at a given height from the high tide line.
#' @param sdata A data frame containing columns with the following headers: "id", "DateTime", "lat", "lon", "qi". 
#' This filter is independently applied to a subset of data grouped by the unique "id". 
#' "DateTime" is date & time in class POSIXct. "lat" and "lon" are the recorded latitude and longitude in decimal degrees. 
#' "qi" is the numerical quality index associated with each fix where the greater number represents better quality 
#' (e.g. number of GPS satellites used for estimation).
#' @param bathymetry object of class "RasterLayer" containing bathymetric data in meters. Geographic coordinate system is WGS84.
#' @param extract Method to extract cell values from raster layer inherited from extract function of raster package. 
#' Default is "bilinear". See the raster package for details.
#' @param tide A data frame containing columns with the following headers: "tideDT", "reading", "standard.port". 
#' "tideDT" is date & time in class POSIXct for each observed tidal height. "reading" is the observed tidal height in meters. 
#' "standard.port" is the identifier of each tidal station.
#' @param qi An integer specifying threshold quality index. 
#' Fixes associated to a quality index higher than the threshold are excluded from the depthfilter. Default is 4
#' @param depth An integer denoting vertical difference from a high tide line in meters. 
#' A positive value indicates above the high tide and a negative value indicates below the high tide. 
#' The function removes fixes above the given threshold. Default is 0 m (i.e. high tide line).
#' @param tidal.plane A data frame containing columns with the following headers: 
#' "standard.port", "secondary.port", "lat", "lon", "timeDiff", "datumDiff". 
#' "standard.port" is the identifier for a tidal observation station. 
#' "secondary.port" is the identifier for a station at which tide is only predicted using tidal records observed at the related standard port. 
#' "lat" and "lon" are the latitude and longitude of each secondary port in decimal degrees. 
#' "timeDiff" is the time difference between standard port and its associated secondary port. 
#' "datumDiff" is the baseline difference in meters between bathymetry and tidal observations/predictions 
#' if each data uses different datum (e.g. LAT and MSL). 
#' @param filter Default is TRUE. If FALSE, the function does not filter locations but the depth estimates are returned.
#' @import sp raster
#' @importFrom data.table data.table
#' @export
#' @details This function removes fixes located at a given height from estimated high tide line when the "filter" option is enabled. 
#' The function chooses the closest match between each fix and tidal observations or predictions in temporal and spatial scales 
#' in order to estimate height of high tide at the time and location of each fix. 
#' It does not filter data when the "filter" option is disabled but it returns the estimated water depth of each location with 
#' the tide effect accounted for (bathymetry + tide height). The estimated water depths are returned in the "depth.exp" column. 
#' @return Input data is returned with two columns added; "depth.exp", "depth.HT". 
#' "depth.exp" is the estimated water depth at the time of location fixing. 
#' "depth.HT" is the estimated water depth at the high tide nearest to the time and location of each fix. 
#' When the "filter" option is enabled, the fixes identified by this filter are removed from the input data. 
#' @author Takahiro Shimada
#' @note Input data must not contain temporal or spatial duplicates.
#' @references Shimada T, Limpus C, Jones R, Hazel J, Groom R, Hamann M (2016) 
#' Sea turtles return home after intentional displacement from coastal foraging areas. 
#' Marine Biology 163:1-14 doi:10.1007/s00227-015-2771-0
#' @references Beaman, R.J. (2010) Project 3DGBR: A high-resolution depth model for the Great Barrier Reef and Coral Sea. 
#' Marine and Tropical Sciences Research Facility (MTSRF) Project 2.5i.1a Final Report, MTSRF, Cairns, Australia, pp. 13 plus Appendix 1.
#' @seealso dupfilter, ddfilter
#' @examples
#' 
#' ### Load data sets
#' # Fastloc GPS data obtained from a green turtle
#' data(turtle)
#' 
#' # Bathymetry model developed by Beaman (2010)
#' data(bathymodel)
#' 
#' # A tidal plane for the example site
#' data(tidalplane)
#' 
#' # Tidal observations and predictions for the example site
#' data(tidedata)
#' 
#' # Map for the example site
#' data(basemap)
#' 
#' 
#' ### Remove temporal and/or spatial duplicates
#' turtle.dup <- dupfilter(turtle)
#' 
#' 
#' ### Remove biologically unrealistic fixes 
#' ## Estimate vmax
#' vmax <- est.vmax(turtle.dup)
#' 
#' ## Estimate maxvlp
#' maxvlp <- est.maxvlp(turtle.dup)
#' 
#' ## Apply ddfilter
#' turtle.dd <- ddfilter(turtle.dup, vmax=vmax, maxvlp=maxvlp)
#'
#'
#' ### Apply depthfilter
#' turtle.dep <- depthfilter(sdata=turtle.dd, 
#'                           bathymetry=bathymodel, 
#'                           tide=tidedata, 
#'                           tidal.plane=tidalplane)
#' 
#' 
#' ### Plot data on a map before and after depthfilter is applied
#' par(mfrow=c(1,2))
#' par(mar=c(4,5,2,1))
#' plot(basemap, col="grey", xlim=c(152.8, 153.1), ylim=c(-25.75, -25.24))
#' axis(1, at=seq(from=152, to=154, by=0.2))
#' axis(2, at=seq(from=-26, to=-25, by=0.2), las=2)
#' mtext("Longitude", side=1, line=2.5)
#' mtext("Latitude", side=2, line=3.5)
#' box()
#' title("Not applied")
#' LatLong <- data.frame(Y=turtle.dup$lat, X=turtle.dup$lon)
#' coordinates(LatLong) <- ~X+Y
#' proj4string(LatLong) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84")
#' plot(LatLong, pch=21, bg="yellow", add=TRUE)
#' 
#' par(mar=c(4,4,2,2))
#' plot(basemap, col="grey", xlim=c(152.8, 153.1), ylim=c(-25.75, -25.24))
#' axis(1, at=seq(from=152, to=154, by=0.2))
#' axis(2, at=seq(from=-26, to=-25, by=0.2), las=2)
#' mtext("Longitude", side=1, line=2.5)
#' box()
#' title("Applied")
#' LatLong <- data.frame(Y=turtle.dep$lat, X=turtle.dep$lon)
#' coordinates(LatLong) <- ~X+Y
#' proj4string(LatLong) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84")
#' plot(LatLong, pch=21, bg="yellow", add=TRUE)



depthfilter<-function(sdata, bathymetry, extract="bilinear", tide, qi=4, depth=0, tidal.plane, filter=TRUE) {
  
  OriginalSS<-nrow(sdata)
  
  ### Sort data in alphabetical and chronological order
  # Animal data
  sdata<-with(sdata, sdata[order(id, DateTime),])
  row.names(sdata)<-1:nrow(sdata)
  
  # tidal data
  tide<-with(tide, tide[order(standard.port, tideDT),])
  row.names(tide)<-1:nrow(tide)
  
  # tidal plane
  tidal.plane<-with(tidal.plane, tidal.plane[order(standard.port, secondary.port),])
  row.names(tidal.plane)<-1:nrow(tidal.plane) 
  
  
  ### Set lat and lon as "SpatialPoints"
  # Animal data
  LatLong<-data.frame(Y=sdata$lat, X=sdata$lon)
  coordinates(LatLong)<-~X+Y
  proj4string(LatLong)<-CRS("+proj=longlat +ellps=WGS84 +datum=WGS84")
  
  # tidal data
  LatLong.tide<-data.frame(Y=tidal.plane$lat, X=tidal.plane$lon)
  coordinates(LatLong.tide)<-~X+Y
  proj4string(LatLong.tide)<-CRS("+proj=longlat +ellps=WGS84 +datum=WGS84")
  
  
  ### extract bathymetry at each animal location
  sdata$bathy<-extract(bathymetry, LatLong, method=extract)
  
  
  ### Find the nearest tidal station for each animal location  
  # Get nearest tidal ports
  distance.to.ports<-pointDistance(LatLong, LatLong.tide, lonlat=T)
  if(nrow(tidal.plane)==1){
    np.index<-1 
  } else {
    np.index<-apply(distance.to.ports, 1, which.min)    
  }
  
  sdata$nearest.port<-tidal.plane[np.index, "secondary.port"]
  np.list<-levels(factor(sdata$nearest.port))
  
  
  # Get the names of standard ports associated to the nearest ports
  s.index<-match(sdata$nearest.port, tidal.plane$secondary.port)
  sdata$standard.port<-tidal.plane[s.index, "standard.port"]
  
  
  ### Subset tidal data according to the range of animal data
  sp.list<-levels(factor(sdata$standard.port))
  tide<-tide[tide$standard.port %in% sp.list,]
    
  trimTide<-function(j){
      MaxInterval<-max(diff(tide[tide$standard.port %in% j, "tideDT"]))
      units(MaxInterval)<-"mins"
      minDateTime<-min(sdata[sdata$standard.port %in% j, "DateTime"])-MaxInterval
      maxDateTime<-max(sdata[sdata$standard.port %in% j, "DateTime"])+MaxInterval
      with(tide, tide[tideDT>=minDateTime & tideDT<=maxDateTime & standard.port %in% j,])
  }
  
  tide.list<-lapply(sp.list, trimTide)
  tide<-do.call(rbind, lapply(tide.list, data.frame, stringsAsFactors=FALSE))
  
  
  ### Organize tidal data
  # Calculate difference in tide to a subsequent record
  tide$range<-unlist(tapply(tide$reading, tide$standard.port, function(x) c(diff(x),NA)))   
  
  
  # Calculate tidal height increment per minute
  Interval<-unlist(tapply(tide$tideDT, tide$standard.port, function(x) c(as.numeric(diff(x)),NA)))
  tide$increment<-tide$range/Interval
  
  
  
  ## Estimate tide at secondary ports
  GetTideSP<-function(j){
      pri.port<-with(tidal.plane, tidal.plane[secondary.port %in% j, "standard.port"])
      sec.port<-with(tidal.plane, tidal.plane[secondary.port %in% j, "secondary.port"])
      tide.sub<-tide[tide$standard.port %in% pri.port,]
      
      timeDiff <- with(tidal.plane[tidal.plane$secondary.port %in% sec.port,], timeDiff)
      tide.sub$tideDT <- tide.sub$tideDT+timeDiff*60
      tide.sub$secondary.port<-sec.port
      tide.sub
  }
      
  tideS.list<-lapply(np.list, GetTideSP)
  tide.s<-do.call(rbind, lapply(tideS.list, data.frame, stringsAsFactors=FALSE))
  
  
  
  #### Estimate water depth with the tide accounted for
  ### Actual water depth
  # Estimate tidal height at each location 
  tide.s$tideDT1<-tide.s$tideDT
  sdata$DateTime1<-sdata$DateTime
  
  DateTime<-NULL; increment<-NULL; reading<-NULL; rm2<-NULL; rm3<-NULL; tideDT<-NULL
  
  tidalHeight<-function(j){
      ## Make data tables
      tide.dt<-data.table(tide.s[tide.s$secondary.port %in% j,], key="tideDT1")
      sdata.dt<-data.table(sdata[sdata$nearest.port %in% j,], key="DateTime1")
      
      ## Get the differences in time between each location and tidal reading at secondary ports
      estTide<-tide.dt[sdata.dt, list(DateTime, tideDT, reading, increment), roll="nearest"]
      estTide$gap.time<-with(estTide, as.numeric(difftime(tideDT, DateTime, units = "mins")))
      
      ## Estimate tidal adjustment for each location
      sdata.dt$adj.reading<-with(estTide, reading+increment*gap.time)
      
      as.data.frame(sdata.dt)
  }
  
      
  sdataDT.list<-lapply(np.list, tidalHeight)
  sdata<-do.call(rbind, lapply(sdataDT.list, data.frame, stringsAsFactors=FALSE))
  
  
  # Estimate actual depth of each location with tide effect
  d.index<-match(sdata$nearest.port, tidal.plane$secondary.port)
  adj.datum<-tidal.plane[d.index, "datumDiff"]
  sdata$depth.exp<-with(sdata, bathy+adj.datum-adj.reading)
  
  
  if(filter %in% TRUE){
      ### Water depth at closest high tide
      ## Organize tidal data
      #Estimate high tide at each port: (0=High, 1=others)
      peakTide<-function(j){
          tide.temp<-tide.s[tide.s$secondary.port %in% j,]
          Interval<-as.numeric(with(tide.temp, difftime(tide.temp[2, "tideDT"], tide.temp[1, "tideDT"], units="mins")))
          ncell.lookup<-120/Interval
          
          find.peakHL<-function(i) {
              if(tide.temp$reading[i]>=max(tide.temp$reading[(i+1):(i+ncell.lookup)]) & tide.temp$reading[i]>=max(tide.temp$reading[(i-1):(i-ncell.lookup)])){
                  0
              } else {
                  1
              }
          }
          
          peak<-unlist(lapply(ncell.lookup:(nrow(tide.temp)-ncell.lookup-1), find.peakHL))
          tide.temp$peak<-c(rep(NA, ncell.lookup-1), peak, rep(NA, ncell.lookup+1))
          tide.temp[tide.temp$peak == 0,]
      }
      
      tide.s<-with(tide.s, tide.s[order(secondary.port, tideDT),])
      row.names(tide.s)<-1:nrow(tide.s)
      
      peakTide.list<-lapply(np.list, peakTide)
      Htide<-do.call(rbind, lapply(peakTide.list, data.frame, stringsAsFactors=FALSE))
      Htide<-Htide[!(is.na(Htide$reading)),]
      
      
      ## Estimate height of high tide at each turtle location
      HtideHeight<-function(j){
          Htide.dt<-data.table(Htide[Htide$secondary.port %in% j,], key="tideDT1")
          sdata.dt<-data.table(sdata[sdata$nearest.port %in% j,], key="DateTime1")
          estHtide<-Htide.dt[sdata.dt, list(DateTime, tideDT, reading, increment), roll="nearest"]
          estHtide$adj.reading<-with(estHtide, reading)  
          sdata.dt$adj.reading.HT<-estHtide$adj.reading
          
          as.data.frame(sdata.dt)
      }
      
      sdataHTH.list<-lapply(np.list, HtideHeight)
      sdata<-do.call(rbind, lapply(sdataHTH.list, data.frame, stringsAsFactors=FALSE))
      
      
      ## Estimate actual depth of a location at the nearest high tide
      d.index<-match(sdata$nearest.port, tidal.plane$secondary.port)
      adj.datum<-tidal.plane[d.index, "datumDiff"]
      sdata$depth.HT<-with(sdata, bathy+adj.datum-adj.reading.HT)
      
      
      ### Remove locations according to water depth at high tide: (0 = remove, 1 = keep)
      sdata<-with(sdata, sdata[!(qi<=qi & depth.HT>depth),])
      
      
      #### Re-order data
      sdata<-with(sdata, sdata[complete.cases(lat),])
      sdata<-with(sdata, sdata[order(id, DateTime),])
      row.names(sdata)<-1:nrow(sdata)
      
      
      #### Report the summary of filtering
      FilteredSS<-nrow(sdata)
      RemovedSamplesN<-OriginalSS-FilteredSS
      RemovedSamplesP<-round((1-(FilteredSS/OriginalSS))*100,2)
      DepthEst<-nrow(sdata[!(is.na(sdata$depth.exp)),])
      
      cat("\n")
      cat("Input data:", OriginalSS, "locations")
      cat("\n")
      cat("Filtered data:", FilteredSS, "locations")
      cat("\n")
      cat("depthfilter removed ", RemovedSamplesN, " locations (", RemovedSamplesP, "% of original data)", sep="")
      cat("\n")
      cat("Actual water depth (bathymetry + tide height) was estiamted for", DepthEst, "of", OriginalSS, "locations")
      cat("\n\n")
      
      
      #### Delete working columns and return the output
      drops<-c("nearest.port", "bathy", "standard.port", "adj.reading", "adj.reading.HT", "DateTime1")
      sdata<-sdata[,!(names(sdata) %in% drops)] 
      return(sdata)
      
  } else {
      
      #### Re-order data
      sdata<-with(sdata, sdata[order(id, DateTime),])
      row.names(sdata)<-1:nrow(sdata)
      
      
      #### Report the summary of filtering
      DepthEst<-nrow(sdata[!(is.na(sdata$depth.exp)),])

      cat("\n")
      cat("No location was removed by depthfilter (i.e. filter option was desabled)")
      cat("\n")
      cat("Actual water depth (bathymetry + tide height) was estiamted for", DepthEst, "of", OriginalSS, "locations")
      cat("\n\n")
      
      
      #### Delete working columns and return the output
      drops<-c("nearest.port", "bathy", "standard.port", "adj.reading", "DateTime1")
      sdata<-sdata[,!(names(sdata) %in% drops)] 
      return(sdata)
         
  }
}
