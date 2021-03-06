covariance <- function(fitted, nugget, sill, range, smooth, smooth2 = NULL,
                       dist, col = 1, ...){

  if (!missing(fitted)){
    cov.mod <- fitted$cov.mod
    smooth <- fitted$param["smooth"]
    range <- fitted$param["range"]
    nugget <- fitted$param["nugget"]
    sill <- 1 - fitted$param["nugget"]

  }

  if ((smooth <= 0) || (range <= 0) || (smooth > 150) || (sill <= 0) || (nugget < 0))
    stop("invalid parameter for the whittle-matern covariance function")

  cov.fun <- function(dist) {
    idx <- dist == 0
    ans <- rep(nugget + sill, length(dist))
    ans[!idx] <- sill * 2^(1-smooth) / gamma(smooth) * (dist[!idx] / range)^smooth *
      besselK(dist[!idx] / range, smooth)
    dim(ans) <- dim(dist)
    return(ans)
  }

  if (!missing(dist)){
    cov.val <- cov.fun(dist)
    return(list(cov.fun = cov.fun, cov.val = cov.val))
  } else invisible(cov.fun)
}

#' Kriging
#'
#' This function interpolates a zero mean Gaussian random field using the simple
#' kriging predictor.
#'
#' @param data A numeric vector or matrix. If data is a matrix then the simple
#' kriging predictor is given for each realisation, i.e., each row of data.
#' @param data.coord A numeric vector or matrix specifying the coordinates of
#' the observed data. If data.coord is a matrix, each row must corresponds to
#' one location.
#' @param krig.coord A numeric vector or matrix specifying the coordinates where
#'  the kriging predictor has to be computed. If krig.coord is a matrix, each
#'  row must correspond to one location.
#' @param cov.mod A character string specifying the covariance function family.
#' Must be one of "whitmat", "powexp", "cauchy", "bessel" or "caugen" for the
#' Whittle-Matern, the powered exponential, the Cauchy, the Bessel or the
#' generalized Cauchy covariance families.
#' @param sill,range,smooth,smooth2 Numerics specifiying the sill, range, smooth
#' and, if any, the second smooth parameters of the covariance function.
#' @param grid logical. Does krig.coord specifies a grid?
#' @param only.weights Logical. Should only the kriging weights be computed? If
#' FALSE, the kriging predictor isn't computed.
#'
#' @return A list with components
#' \itemize{
#'   \item coord	The coordinates where the kriging predictor has been computed;
#'   \item krig.est	The kriging predictor estimates;
#'   \item grid	Does coord define a grid?;
#'   \item weights A matrix giving the kriging weights: each column corresponds
#'   to one prediction location.
#' }
#' @export
#'
kriging <- function(data, data.coord, krig.coord, cov.mod = "whitmat",
                    sill, range, smooth, smooth2 = NULL, grid = FALSE,
                    only.weights = FALSE){

  if (is.null(dim(data.coord))){
    dist.dim <- 1
    n.site <- length(data.coord)
  }

  else {
    dist.dim <- ncol(data.coord)
    n.site <- nrow(data.coord)
  }

  if (is.null(dim(krig.coord)))
    dist.dim.krig <- 1

  else
    dist.dim.krig <- ncol(krig.coord)

  if (dist.dim != dist.dim.krig)
    stop(paste("The conditioning locations live in R^", dist.dim,
               " but you want predictions in R^", dist.dim.krig, "!", sep=""))

  if (grid){
    if (is.null(dim(krig.coord)) || (ncol(krig.coord) != 2))
      stop("''grid'' can be 'TRUE' only with 2 dimensional locations")

    new.krig.coord <- NULL
    for (i in 1:nrow(krig.coord))
      new.krig.coord <- rbind(new.krig.coord, cbind(krig.coord[,1],
                                                    krig.coord[i,2]))
  }

  else
    new.krig.coord <- krig.coord

  if (dist.dim == 1)
    n.krig <- length(new.krig.coord)

  else
    n.krig <- nrow(new.krig.coord)

  if (!is.vector(data)){
    n.obs <- nrow(data)

    if (ncol(data) != n.site)
      stop("''data'' and ''data.coord'' don't match")
  }

  else {
    n.obs <- 1

    if (length(data) != n.site)
      stop("''data'' and ''data.coord'' don't match")
  }

  distMat <- as.matrix(stats::dist(data.coord, diag = TRUE, upper = TRUE))

  icovMat <- covariance(nugget = 0, sill = sill, range = range, smooth = smooth,
                        smooth2 = smooth2, cov.mod = cov.mod, plot = FALSE,
                        dist = distMat)$cov.val

  icovMat <- solve(icovMat)
  icovMat[lower.tri(icovMat)] <- 0

  if (cov.mod == "whitmat")
    cov.mod.num <- 1
  if (cov.mod == "cauchy")
    cov.mod.num <- 2
  if (cov.mod == "powexp")
    cov.mod.num <- 3
  if (cov.mod == "bessel")
    cov.mod.num <- 4
  if (cov.mod == "caugen")
    cov.mod.num <- 5

  if (cov.mod != "caugen")
    smooth2 <- 0

  weights <- .C("skriging", as.integer(n.site), as.integer(n.krig),
                as.integer(cov.mod.num), as.integer(dist.dim), as.double(icovMat),
                as.double(data.coord), as.double(new.krig.coord), as.double(data),
                as.double(sill), as.double(range), as.double(smooth),
                as.double(smooth2), weights = double(n.krig * n.site))$weights

  weights <- matrix(weights, n.site, n.krig)

  if (!only.weights){
    if (grid && (n.obs > 1)){
      krig <- array(NA, c(nrow(krig.coord), nrow(krig.coord), n.obs))

      for (i in 1:n.obs)
        krig[,,i] <- matrix(data[i,] %*% weights, nrow(krig.coord))
    }

    else {
      krig <- data %*% weights

      if (grid)
        krig <- matrix(krig, nrow(krig.coord))

    }
  }

  else
    krig <- NULL

  return(list(coord = krig.coord, krig.est = krig, grid = grid,
              weights = weights))
}