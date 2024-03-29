#' Plot Diagnostics for a coxr Object
#'
#' Graphical tool which in a series of 5 graphs let us compare how well data are
#' explained by the estimated proportional hazards model with non-robust
#' (black color) and robust method (green color).  The first graph gives
#' standardized difference of two estimated survival functions; one via the Cox
#' model and the other via Kaplan Meier estimator.  The following four graphs
#' show the same differences for four strata, defined by the quartiles of the
#' estimated linear predictor.  Comparison of estimation results along with
#' analysis of the graphs leads frequently to a very detailed information about
#' the model fit (see examples).
#'
#' @param x \code{coxr} object, typically result of \code{\link{coxr}}.
#' @param caption captions to appear above the plots.
#' @param xlab title for the x axis.
#' @param ylab title for the y axis.
#' @param main overall title for the plot.
#' @param \dots other parameters to be passed through to plotting functions.
#' @param color if \code{FALSE} grayscale mode is used.
#'
#' @return Data frame containing the following variables:
#' \itemize{
#' \item{time}{vector of survival times.}
#' \item{status}{vector of censoring status.}
#' \item{X1, X2, ...}{explanatory variables (their number is determined by the
#' dimension of vector of regression coefficients).}
#' }
#'
#' @export

plot.coxr <- function(x,
                      caption = c("Full data set",
                                  "First quartile",
                                  "Second quartile",
                                  "Third quartile",
                                  "Fourth quartile"),
                      main = NULL,
                      xlab = "log time",
                      ylab = "standardized survival differences",
                      ...,
    color = TRUE) {

    if ( !inherits(x, "coxr") ) {
        stop("use only with \"coxr\" objects")
    }

    sorted <- order(x$y[,1])

    logtime <- log(x$y[sorted,1])
    status  <- x$y[sorted,2]

    if ( length(x$skip) > 0 ) {
        notskip = !1:ncol(x$x) %in% x$skip
        z <- as.matrix(x$x[sorted,notskip])
        beta <- x$coef[notskip]
        beta.ple <- x$ple.coefficients[notskip]
    } else {
        z <- as.matrix(x$x[sorted,])
        beta <- x$coef
        beta.ple <- x$ple.coefficients
    }

    zbeta <- z %*% beta

    expzbeta <- exp(zbeta)
    expzbeta.ple <- exp(z %*% beta.ple)

    q <- quantile(zbeta, probs = c(0, 0.25, 0.5, 0.75, 1), names = FALSE)

    xlabs   <- c("", "", xlab, xlab)
    ylabs   <- c(ylab, "", ylab, "")
    margs   <- rbind( c(-2,0,0,-1), c(-2,0,0,0), c(0,0,-2,-1), c(0,0,-2,0))

    par.def <- par(no.readonly = TRUE)
    on.exit(par(par.def))

    coxr.draw(expzbeta, expzbeta.ple, logtime, status, x$lambda.ple, x$lambda,
              color)

    mtext(caption[1], 3, 0.25)
    if ( !is.null(main) ) {
        title(main = main)
    }
    title(xlab = xlab, ylab = ylab)

    par(ask = TRUE)

    split.screen(c(2,2))
    par(cex.lab=0.75)

    for ( i in 1:4 ) {

        ind <- which( zbeta >= q[i] & zbeta < q[i+1] )

        par(mar=c(par.def$mar + margs[i,]))
        screen(i)
        coxr.draw(expzbeta[ind], expzbeta.ple[ind], logtime[ind], status[ind],
                  x$lambda.ple[ind], x$lambda[ind], color)
        title(xlab=xlabs[i], ylab=ylabs[i])
        mtext(caption[i+1], 3, 0.25)
        close.screen(i)

    }

    close.screen(all.screens = TRUE)
    if ( !is.null(main) ) {
        title(main = main)
    }

    invisible()

}

coxr.draw <- function(expzbeta, expzbeta.ple, logtime, status, lam, lamr,
                      color) {

    n <- length(logtime)

    km    <- cumprod(((n:1)-status)/(n:1))
    norm  <- sqrt(km*(1-km))
    gkm   <- km * sqrt( cumsum(status/(n:1)/((n:1)-status)) )
    upper <- 2*gkm/norm

    curvr  <- (t(rep(1/n,n))%*%t(exp(-lamr%*%t(expzbeta)))-km)/norm
    curvpl <- (t(rep(1/n,n))%*%t(exp(-lam %*%t(expzbeta.ple)))-km)/norm

    plot(logtime, upper, ylim = c(-0.6,0.6), type = "l", xlab = "", ylab = "")
    lines(logtime, -upper)
    lines(logtime, curvpl)

    if (color) {

        points(logtime, rep(0,n), pch=20, col="red")
        lines(logtime, curvr, type="l", col="green")

    } else {

        points(logtime, rep(0,n), pch=20)
        lines(logtime, curvr, type="l", col="gray75")

    }

}
