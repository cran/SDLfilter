#' @aliases ddfilter
#' @title Filter locations using a data driven filter
#' @description Function to remove locations by a data driven filter as described in Shimada et al. (2012)
#' @param sdata A data frame containing columns with the following headers: "id", "DateTime", "lat", "lon", "qi". 
#' This filter is independently applied to a subset of data grouped by the unique "id". 
#' "DateTime" is date & time in class POSIXct. "lat" and "lon" are the recorded latitude and longitude in decimal degrees. 
#' "qi" is the numerical quality index associated with each fix where the greater number represents better quality 
#' (e.g. number of GPS satellites used for estimation).
#' @param vmax A numeric vector specifying threshold speed both from a previous and to a subsequent fix. 
#' Default is 8.9km/h. If this value is unknown, the function "est.vmax" can be used to estimate the value based on the supplied data.
#' @param maxvlp A numeric vector specifying threshold speed during a loop trip. Default is 1.8 km/h. 
#' If this value is unknown, the function "est.maxvlp" can be used to estimate the value based on the supplied data.
#' @param qi An integer specifying threshold quality index during a loop trip. Default is 4.
#' @param ia An integer specifying threshold inner angle during a loop trip. Default is 90 degrees.
#' @param method An integer specifying how locations are filtered by speed. 
#' 1 = a location is removed if the speed EITHER from a previous and to a subsequent location exceeds a given threshold speed. 
#' 2 = a location is removed if the speed BOTH from a previous and to a subsequent location exceeds a given threshold speed. Default is 2.
#' @import sp raster trip
#' @export
#' @details Locations are removed if the speed both from a previous and to a subsequent location exceeds a given "vmax", 
#' or if all of the following criteria apply: the associated quality index is less than or equal to a given "qi", 
#' the inner angle is less than or equal to a given "ia" and the speed either from a previous 
#' or to a subsequent location exceeds a given "maxvlp". If "vmax" and "maxvlp" are unknown, they can be estimated 
#' using the functions "est.vmax" and "est.maxvlp", respectively.
#' @return A data frame is returned with locations identified by this filter removed. 
#' The following columns are added: "pTime", "sTime", "pDist", "sDist", "pSpeed", "sSpeed", "inAng". 
#' "pTime" and "sTime" are hours from a previous and to a subsequent fix respectively. 
#' "pDist" and "sDist" are straight distances in kilometres from a previous and to a subsequent fix respectively. 
#' "pSpeed" and "sSpeed" are linear speed from a previous and to a subsequent fix respectively. 
#' "inAng" is the angle between the bearings of lines joining successive location points.
#' @author Takahiro Shimada
#' @references Shimada T, Jones R, Limpus C, Hamann M (2012) 
#' Improving data retention and home range estimates by data-driven screening. 
#' Marine Ecology Progress Series 457:171-180 doi:10.3354/meps09747
#' @seealso ddfilter.speed, ddfilter.loop, "est.vmax", "est.maxvlp"
#' @examples
#' ### Load data sets
#' # Fastloc GPS data obtained from a green turtle
#' data(turtle)
#' 
#' # A Map for the example site
#' data(basemap)
#' 
#' 
#' ### Filter temporal and/or spatial duplicates
#' turtle.dup <- dupfilter(turtle, step.time=5/60, step.dist=0.001)
#'  
#' 
#' ### ddfilter
#' ## Estimate vmax
#' vmax <- est.vmax(turtle.dup)
#' 
#' ## Estimate maxvlp
#' maxvlp <- est.maxvlp(turtle.dup)
#' 
#' ## Apply ddfilter
#' turtle.dd <- ddfilter(turtle.dup, vmax=vmax, maxvlp=maxvlp)
#' # turtle.dd <- ddfilter(turtle.dup, vmax=9.9, qi=4, ia=90, maxvlp=2.0)
#' 
#' 
#' ### Plot data on a map before and after ddfilter is applied
#' par(mfrow=c(1,2))
#' 
#' # Entire area
#' par(mar=c(4,5,2,1))
#' LatLong <- data.frame(Y=turtle.dup$lat, X=turtle.dup$lon)
#' coordinates(LatLong) <- ~X+Y
#' proj4string(LatLong) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84")
#' plot(LatLong, pch=21, bg="yellow", xlim=c(147.8, 156.2))
#' axis(1)
#' axis(2, las=2)
#' box()
#' mtext("Longitude", side=1, line=2.5)
#' mtext("Latitude", side=2, line=3.5)
#' title("Unfiltered")
#' 
#' par(mar=c(4,4,2,2))
#' LatLong <- data.frame(Y=turtle.dd$lat, X=turtle.dd$lon)
#' coordinates(LatLong) <- ~X+Y
#' proj4string(LatLong) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84")
#' plot(LatLong, pch=21, bg="yellow", xlim=c(147.8, 156.2))
#' axis(1)
#' axis(2, las=2)
#' box()
#' mtext("Longitude", side=1, line=2.5)
#' title("Filtered")
#' 
#' # Zoomed in
#' par(mar=c(4,5,2,1))
#' plot(basemap, col="grey", xlim=c(152.8, 153.1), ylim=c(-25.75, -25.24))
#' axis(1, at=seq(from=152, to=154, by=0.2))
#' axis(2, at=seq(from=-26, to=-25, by=0.2), las=2)
#' mtext("Longitude", side=1, line=2.5)
#' mtext("Latitude", side=2, line=3.5)
#' box()
#' title("Unfiltered")
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
#' title("Filtered")
#' LatLong <- data.frame(Y=turtle.dd$lat, X=turtle.dd$lon)
#' coordinates(LatLong) <- ~X+Y
#' proj4string(LatLong) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84")
#' plot(LatLong, pch=21, bg="yellow", add=TRUE) 


ddfilter<-function(sdata, vmax=8.9, maxvlp=1.8, qi=4, ia=90, method=2) {
  
  #### Sample size of the input data
  OriginalSS<-nrow(sdata)
 
  #### Run ddfilters
  cat("\n")
  sdata<-ddfilter.speed(sdata, vmax, method)
  sdata<-ddfilter.loop(sdata, qi, ia, maxvlp)
  
  
  #### Report the summary of filtering
  FilteredSS<-nrow(sdata)
  RemovedSamplesN<-OriginalSS-FilteredSS
  RemovedSamplesP<-round((1-(FilteredSS/OriginalSS))*100,2)
  
  cat("\n")
  #maxchar<-sum(nchar(c("A total of ", RemovedSamplesN, " locations (", RemovedSamplesP, "%) were removed by ddfilter")))
  #cat(rep("#", maxchar), sep="")
  #cat("\n")
  cat("Input data:", OriginalSS, "locations")
  cat("\n")
  cat("Filtered data:", FilteredSS, "locations")
  cat("\n")
  cat("ddfilter removed ", RemovedSamplesN, " locations (", RemovedSamplesP, "% of original data)", sep="")
  #cat("\n")
  #cat(rep("#", maxchar), sep="")
  cat("\n\n")
  
  #### Return the filtered data set
  return(sdata)
}