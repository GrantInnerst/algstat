#' Fit a hierarchical log-linear model with algebraic methods
#'
#' \code{loglinear} fits a hierarchical log-linear model to a dataset (typically
#' a contingency table) and performs an exact conditional test on the fitted
#' model using various distance metrics.  The exact test, which is a
#' goodness-of-fit test, is performed via Monte-Carlo sampling from the
#' conditional distribution of the table given the sufficient statistics of the
#' model.  In short, inference is drawn by comparing the statistic of the
#' observed table (be it an unnormalized log-likelihood, a Pearson chi-squared
#' value, or another metric) to those of the samples.  The proportion of sampled
#' tables with equal to or more extreme values than the observed table is the
#' resulting p-value.
#'
#' In many ways, \code{loglinear} is like \code{\link{loglin}} or
#' \code{\link{loglm}}; however, there are a few key differences.
#'
#' The first difference is methodological.  The tests conducted with
#' \code{loglinear} are exact conditional tests based on the conditional
#' distribution of the data given the sufficient statistics for the model.  In
#' other words, they are analogues of Fisher's exact test for generic log-linear
#' models.  These tests are made possible by advances in algebraic statistics;
#' see references 1--3 below.
#'
#' The second difference between \code{loglinear} and \code{\link{loglin}} or
#' \code{\link{loglm}} is that inference is made through Monte Carlo simulation.
#' In particular, \code{loglinear} leverages Markov moves to sample from the
#' conditional distribution of the data given its sufficent statistics.  If the
#' software 4ti2 is installed on your machine, you can use \code{\link{markov}}
#' (or let \code{loglinear} use \code{\link{markov}}) to generate a Markov basis
#' to use for the Markov moves. This basis is guaranteed to produce a MCMC
#' routine that converges to the conditional distribution of interest. Since
#' \code{loglinear} uses Monte Carlo simulation to conduct inference, and since
#' it uses MCMC to do so, concerns typical to MCMC should be addressed.  In
#' particular, issues such as burn in and mixing (autocorrelation of samples)
#' should be addressed.  The examples illustrate some of these topics.  The
#' result is a p-value that is generated by Monte Carlo simulation.  Its
#' standard error is provided (computed as in the standard CLT confidence
#' interval) to give a sense of the Monte Carlo error.
#'
#' A third way that \code{loglinear} differs from \code{stats::loglin} or
#' \code{MASS::loglm} is in generalizing the kinds of tests performed.  While
#' those allow for asymptotic unconditional testing using Pearson's X^2 test and
#' the likelihood ratio test, \code{loglinear} gives several test statistics:
#' Pearson's X^2, the likelihood ratio G^2, Freeman-Tukey, Cressie-Read (lambda
#' = 2/3), and Neyman's modified X^2., see the last reference.  In other words,
#' to compute the exact p-value, iter = 1e4 samples are sampled from the
#' conditional distribution of the table given the sufficient statistics, and
#' then the proportion of tables that have X^2, G^2, etc. values greater than or
#' equal to that of the observed table is the p value for the (conditional)
#' exact test. A similar, and perhaps preferable approach, simply adds up the
#' probabilities of the tables that have probabilities less than or equal to
#' that of the observed table; this is the first line output in hierarchical and
#' does not use a test statistic.
#'
#' Some authors (see the third reference) suggest that for discrete problems, a
#' "mid p value" is preferable to the traditional p value, and when presented
#' should be interepreted in the same way. If the p value is defined to be
#' P(samps >= obs), the mid p value is defined to be P(samps > obs) + P(samps ==
#' obs)/2.  The mid p value is computed for each test.
#'
#' @param model hierarchical log-linear model specification
#' @param data data, typically as a table but can be in different formats.  see
#'   \code{\link{teshape}}
#' @param init the initialization of the chain. by default, this is the observed
#'   table
#' @param iter number of chain iterations
#' @param burn burn-in
#' @param thin thinning
#' @param engine C++ or R? (C++ yields roughly a 20-25x speedup)
#' @param method should the expected value (exp) be fit using iterative
#'   proportional fitting (via loglin) or the MCMC as the average of the steps?
#' @param moves the markov moves for the mcmc (as columns of a matrix).
#' @param ... ...
#' @return a list containing named elements
#'
#'   \itemize{
#'
#'   \item \code{steps}: an integer matrix whose columns represent individual
#'   samples from the mcmc.
#'
#'   \item \code{moves}: the moves used for the proposal distribution in the
#'   mcmc, computed with 4ti2 (note that only the positive moves are given).
#'
#'   \item \code{accept_prob}: the average acceptance probability of the moves,
#'   including the thinned moves.
#'
#'   \item \code{param}: the fitted parameters of the log linear model.
#'
#'   \item \code{df}: parameters per term in the model
#'
#'   \item \code{quality}: model selection statistics AIC, AICc, and BIC. \item
#'   \code{residuals}: the (unstandardized) pearson residuals (O - E) / sqrt(E)
#'
#'   \item \code{call}: the call.
#'
#'   \item \code{obs}: the contingency table given.
#'
#'   \item \code{exp}: the fit contingency table as an integer array.
#'
#'   \item \code{A}: the sufficient statistics computing matrix (from Tmaker).
#'
#'   \item \code{p.value}: the exact p-values of individual tests, accurate to
#'   Monte-Carlo error.  these are computed as the proportion of samples with
#'   statistics equal to or larger than the oberved statistic.
#'
#'   \item \code{mid.p.value}: the mid p.values, see Agresti pp.20--21.
#'
#'   \item \code{statistic}: the pearson's chi-squared (X2), likelihood ratio
#'   (G2), Freeman-Tukey (FT), Cressie-Read (CR), and Neyman modified
#'   chi-squared (NM) statistics computed for the table given.
#'
#'   \item \code{sampsStats}: the statistics computed for each mcmc sample.
#'
#'   \item \code{cells}: the number of cells in the table.
#'
#'   \item \code{method}: the method used to estimate the table.
#'
#'   }
#' @export loglinear
#' @aliases hierarchical
#' @author David Kahle
#' @seealso \code{\link{loglin}}, \code{\link{loglm}}, \code{\link{metropolis}}
#' @references Diaconis, P. and B. Sturmfels (1998). Algebraic Algorithms for
#'   Sampling from Conditional Distributions. \emph{The Annals of Statistics}
#'   26(1), pp.363-397.
#' @references Drton, M., B. Sturmfels, and S. Sullivant (2009). \emph{Lectures
#'   on Algebraic Statistics}, Basel: Birkhauser Verlag AG.
#' @references Aoki, S., H. Hara, and A. Takemura (2012). \emph{Markov Bases in
#'   Algebraic Statistics}, Springer.
#' @references Agresti, A. (2002). \emph{Categorical Data Analysis}, Basel: John
#'   Wiley & Sons, 2ed.
#' @references Agresti, A. (1992). A Survey of Exact Inference for Contingency
#'   Tables \emph{Statistical Science} 7(1), pp.131-153.
#' @references Read, T. and Cressie, N. (1998). \emph{Goodness-of-Fit Statistics
#'   for Discrete Multivariate Data}, Springer-Verlag.
#' @examples
#'
#' \dontrun{ requires LattE and 4ti2
#'
#'
#' ## handedness introductory example
#' ############################################################
#'
#' data(handy); handy
#'
#' (out <- loglinear(~ Gender + Handedness, data = handy))
#'
#' # you can also specify the same model using variable indices...
#' (out <- loglinear(~ 1 + 2, data = handy))
#'
#' # ... or as a list of facets given by indices
#' (out <- loglinear(list(1, 2), data = handy))
#'
#' # ... or as a list of facets given by name
#' (out <- loglinear(list("Gender", "Handedness"), data = handy))
#'
#' # ... and even via a pre-computed configuration matrix
#' # this method does come with somewhat reduced output
#' A <- hmat(c(2, 2), 1:2)
#' (out <- loglinear(A, data = handy))
#'
#'
#'
#' # loglinear performs the same tasks as loglin and loglm,
#' # but loglinear gives the exact test p values and more goodness-of-fit statistics
#' stats::loglin(handy, list(1, 2))
#' MASS::loglm(~ Gender + Handedness, data = handy)
#' # loglm is just a wrapper of loglin
#'
#' # we can check loglinear's output with
#' fisher.test(handy)$p.value
#' out$p.value
#'
#'
#'
#'
#'
#'
#'
#'
#'
#' # comparisons between loglinear, stats::loglin, and MASS::loglm
#' ############################################################
#'
#' (loglinearFit <- loglinear(~ Gender + Handedness, data = handy))
#' (loglinFit    <- stats::loglin(handy, list(1, 2), fit = TRUE, param = TRUE))
#' (loglmFit     <- MASS::loglm(~ Gender + Handedness, data = handy))
#'
#'
#'
#' # the expected table given the sufficient statistics can be computed
#' # via two methods, iterative proportional fitting, and the mcmc itself:
#' loglinearFit$exp # ipf
#' loglinear(~ Gender + Handedness, data = handy, method = "mcmc")$exp
#' loglinFit$fit # the equivalent in loglin; this is used by default in loglinear
#'
#'
#'
#'
#' # the parameter values of the loglinear model can be accessed
#' loglinearFit$param
#' loglinFit$param
#'
#'
#'
#'
#' # the p-value for the goodness-of-fit of the overall model is available as well :
#' # loglinear gives the exact conditional p-value
#' # (conditional on the sufficient statistics)
#' # the five numbers correspond the probability of observering a table that is
#' # "more weird" than the observed table, where "more weird" is determined
#' # by having a larger X2 value (or G2, FT, CR, or NM)
#' loglinearFit$p.value
#'
#' # in this case (a 2x2 table with the independence model), we can check that
#' # the above p-values are coorect up to Monte Carlo error
#' fisher.test(handy)$p.value
#'
#'
#' # loglin gives the p-values using the unconditional asymptotic distribution:
#' # note that the two are quite different in this case, although the conclusion
#' # is the same
#' c(
#'   "X2" = pchisq(loglinFit$pearson, df = loglinFit$df, lower.tail = FALSE),
#'   "G2" = pchisq(loglinFit$lrt,     df = loglinFit$df, lower.tail = FALSE)
#' )
#'
#' # mid p-values are available as well:
#' loglinearFit$mid.p.value # the mid (exact conditional) p-value is also available
#'
#'
#'
#'
#' # the test statistics based on the observed table and the expected
#' # table under the model are available
#' loglinearFit$statistic
#' c(X2 = loglinFit$pearson, G2 = loglinFit$lrt) # loglin only gives X2 and G2
#' # note that PR is un-normalized log-probability
#'
#'
#'
#' # the markov moves used for the proposal distribution of the metropolis-hastings
#' # algorithm are returned. the proposal distribution is uniform on +/-
#' # the moves added to the current table
#' loglinearFit$moves
#' # they are easier understood as tables
#' vec2tab(loglinearFit$moves, dim(handy))
#' # notice that the marginals stay fixed:
#' handy + vec2tab(loglinearFit$moves, dim(handy))
#'
#'
#'
#'
#' # these were computed as the markov basis of the integer matrix
#' # (for different models, different schemes may be employed)
#' loglinearFit$A
#' markov(loglinearFit$A)
#' loglinearFit$moves
#'
#'
#'
#'
#' # the moves are also sometimes written in tableau form (LAS p.13)
#' tableau(loglinearFit$moves, dim(handy))
#' # that's +1 the the table in elements [1,1] and [2,2]
#' # and -1 in the table in elements [1,2] and [2,1]
#'
#'
#'
#'
#' # the acceptance probability of the MCMC is retained
#' loglinearFit$accept_prob
#'
#'
#'
#'
#' # various model assessment measures are also available
#' loglinearFit$quality
#'
#'
#'
#'
#' # the number of independent parameters per term are in df
#' loglinearFit$df
#'
#'
#'
#'
#' # as an added help, you may find the visuals in vcd useful:
#' library(vcd)
#' mosaic(~ Gender + Handedness, data = handy, shade = TRUE, legend = TRUE)
#' # note mosaic's use of the asymptotic X^2 test
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#' ## politics example - with computing the exact p value by hand
#' ############################################################
#'
#' data(politics); politics
#'
#' (out <- loglinear(~ Personality + Party, data = politics))
#' loglinFit <- stats::loglin(politics, as.list(1:2), fit = TRUE, param = TRUE)
#'
#' out$p.value
#' # exact without monte-carlo error
#' sum(dhyper(c(0:3,6:9), 10, 10, 9))
#' fisher.test(politics)$p.value
#' round(dhyper(0:9, 10, 10, 9), 4)
#'
#' # we can sample from the hypergeometric distribution on the fiber using
#' # rhyper
#' rhyper(100, 10, 10, 9)
#'
#'
#' # comparisons :
#' out$exp
#' loglinFit$fit
#'
#' out$param
#' loglinFit$param
#'
#' out$p.value # exact
#' c(
#'   X2 = pchisq(loglinFit$pearson, df = loglinFit$df, lower.tail = FALSE),
#'   G2 = pchisq(loglinFit$lrt,     df = loglinFit$df, lower.tail = FALSE)
#' ) # asymptotic approximation
#' fisher.test(politics)$p.value # the exact conditional p-value
#'
#' out$statistic # accurate to monte carlo error
#' c(X2 = loglinFit$pearson, G2 = loglinFit$lrt)
#'
#' vcd::mosaic(~ Personality + Party, data = politics, shade = TRUE, legend = TRUE)
#'
#'
#'
#' # alternative model specifications :
#' loglinear(~ Personality + Party, data = politics)
#' loglinear(~ 1 + 2, data = politics)
#' loglinear(list(1, 2), data = politics)
#' loglinear(list("Personality", "Party"), data = politics)
#'
#'
#'
#'
#'
#'
#'
#'
#'
#' ## eyeHairColor from the Diaconis and Sturmfels reference
#' ############################################################
#'
#' data(HairEyeColor)
#' eyeHairColor <- margin.table(HairEyeColor, 2:1)
#'
#' out <- loglinear(~ Eye + Hair, data = eyeHairColor)
#'
#' # the default fisher.test doesn't work even with workspace = 2E9
#' # (with over 4.5Gb in memory) because it is trying to enumerate the fiber.
#' #fisher.test(eyeHairColor, workspace = 2E9)
#' # it can, however, compute Monte Carlo p-values for RxC tables, like loglinear
#' fisher.test(eyeHairColor, simulate.p.value = TRUE, B = 1e6)
#' out$p.value
#'
#' # you can see the markov moves used in the mcmc in tableau notation
#' tableau(out$moves, dim(eyeHairColor))
#'
#' # library(vcd)
#' # mosaic(~ Eye + Hair, data = HairEyeColor, shade = TRUE, legend = TRUE)
#'
#'
#'
#'
#'
#'
#' ## abortion preference example from the
#' ## Diaconis and Sturmfels reference pp. 379--381
#' ## a no 3-way interaction model
#' ############################################################
#'
#' data(abortion); abortion
#'
#' (loglinearFit <- loglinear(subsets(1:3, 2), data = abortion,
#'   iter = 10000, burn = 50000, thin = 50
#' ))
#' loglinFit <- loglin(abortion, subsets(1:3, 2), fit = TRUE, param = TRUE)
#'
#' vec2tab(rowMeans(loglinearFit$steps), dim(abortion)) # cf. p. 380
#' loglinFit$fit
#'
#' all.equal(loglinearFit$param, loglinFit$param)
#'
#'
#'
#' qqplot(rchisq(1055, df = 8), out$sampsStats$X2s)
#' curve(1*x, from = 0, to = 30, add = TRUE, col = "red")
#'
#' ( nMoves <- 2*ncol(out$moves) ) # DS uses 110
#' # (the markov basis is larger than it needs to be)
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#' ## loglin no three-way interaction model example
#' ############################################################
#'
#' # the help for fits the no three-way interaction model on HairEyeColor,
#' # finds a .66196 p-value using the asymptotic distribution, and concludes
#' # a good fit:
#' data(HairEyeColor)
#'
#' loglinearFit <- loglinear(subsets(1:3, 2), data = HairEyeColor)
#' loglinFit    <- loglin(HairEyeColor, subsets(1:3, 2), fit = TRUE, param = TRUE)
#'
#'
#'
#'
#' # p values
#' loglinearFit$p.value
#' pchisq(loglinFit$lrt, loglinFit$df, lower.tail = FALSE) # see ?loglin
#'
#' # test statistics
#' loglinearFit$statistic
#' c(X2 = loglinFit$pearson, G2 = loglinFit$lrt)
#'
#' # fits (estimated tables)
#' loglinearFit$obs
#' round(loglinearFit$exp, 1)
#' round(loglinFit$fit, 1)
#'
#'
#' # checking the autocorrelation of mcmc
#' acf(loglinearFit$sampsStats$PRs)
#'
#' # poor mixing is a known limitation of markov bases strategies
#' # one strategy is to try to thin the mcmc
#' loglinearFit <- loglinear(subsets(1:3, 2), data = HairEyeColor, thin = 100)
#' acf(loglinearFit$sampsStats$PRs) # got it! (overkill, actually)
#'
#'
#' # the slight differences in loglinFit$fit and loglinearFit$exp (both done with ipf from loglin)
#' # are due to differences in variable order:
#' loglin(HairEyeColor, subsets(1:3, 2), fit = TRUE)$fit
#' loglin(HairEyeColor, subsets(1:3, 2)[c(1,3,2)], fit = TRUE)$fit
#'
#' # let's look at a few model moves
#' vec2tab(loglinearFit$moves[,1], dim(HairEyeColor))
#' vec2tab(loglinearFit$moves[,50], dim(HairEyeColor))
#' -vec2tab(loglinearFit$moves[,50], dim(HairEyeColor))
#'
#' # they contribute 0 to the marginals of the table
#' # (the sufficient statistics of the model)
#' exampleMove <- loglinearFit$moves[,50]
#' vec2tab(exampleMove, dim(HairEyeColor))
#' loglinearFit$A %*% exampleMove
#'
#' # two tables with same sufficient statistics
#' HairEyeColor
#' HairEyeColor + vec2tab(exampleMove, dim(HairEyeColor))
#'
#' # here are the sufficient statistics:
#' loglinearFit$A %*% tab2vec(HairEyeColor)
#' loglinearFit$A %*% tab2vec(HairEyeColor + vec2tab(exampleMove, dim(HairEyeColor)))
#'
#'
#'
#'
#'
#'
#'
#'
#'
#' ## a table with positive marginals but no MLE for
#' ## the no-three way interaction model
#' ############################################################
#'
#'
#' data(haberman); haberman
#'
#' mod <- loglinear(subsets(1:3, 2), data = haberman)
#'
#' loglinFit <- loglin(haberman, subsets(1:3, 2), param = TRUE, fit = TRUE)
#' loglinFit$fit
#' loglinFit$param
#' c(X2 = loglinFit$pearson, G2 = loglinFit$lrt)
#'
#' loglinearFit <- loglinear(subsets(1:3, 2), data = haberman, method = "mcmc")
#' loglinearFit$exp
#' loglinearFit$param
#' loglinearFit$statistic
#'
#' A <- hmat(rep(2, 3), subsets(1:3, 2))
#' count_tables(haberman, A) # there's only one table in the fiber!
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#' ## an example from agresti, p.322
#' ############################################################
#'
#' data(drugs); drugs
#' ftable(aperm(drugs, c(3, 1, 2))) # = table 8.3
#'
#' out <- loglinear(~ Alcohol + Cigarette + Marijuana, data = drugs)
#' matrix(round(aperm(out$exp, c(2,1,3)), 1), byrow = FALSE)
#'
#' loglin(drugs, as.list(1:3), fit = TRUE)$fit
#' loglin(drugs, as.list(1:3), param = TRUE)$param
#'
#' # # the saturated model issues a warning from markov, but works :
#' # out <- loglinear(~ Alcohol * Cigarette * Marijuana, data = drugs)
#' # matrix(round(aperm(out$exp, c(2,1,3)), 1), byrow = FALSE) # = the data
#'
#'
#' ftable(aperm(out$exp, c(3,1,2)))
#'
#' stats <- loglin(drugs, as.list(1:3), fit = TRUE, param = TRUE)
#'
#'
#' ## considered via glm
#'
#' df <- as.data.frame(drugs)
#' mod <- glm(Freq ~ Alcohol + Cigarette + Marijuana, data = df, family = poisson)
#' summary(mod)
#' mod$fitted.values
#'
#'
#' # the same can be done with glm :
#'
#' mod <- glm(
#'   Freq ~ Alcohol + Cigarette + Marijuana,
#'   data = as.data.frame(drugs), family = poisson
#' )
#' summary(mod)
#' matrix(round(mod$fitted.values[c(1,3,2,4,5,7,6,8)],1))
#'
#'
#'
#' mod <- glm(
#'   Freq ~ Alcohol * Cigarette + Marijuana,
#'   data = as.data.frame(drugs), family = poisson
#' )
#' summary(mod)
#' matrix(round(mod$fitted.values[c(1,3,2,4,5,7,6,8)],1))
#'
#'
#' mod <- glm(
#'   Freq ~ Alcohol * Cigarette * Marijuana,
#'   data = as.data.frame(drugs), family = poisson
#' )
#' summary(mod)
#' matrix(round(mod$fitted.values[c(1,3,2,4,5,7,6,8)],1))
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#'
#' }
#'
#' 
loglinear <- function(model, data, 
                      init = tab2vec(data), 
                      iter = 1e4, burn = 1000, 
                      thin = 10, engine = c("Cpp","R"), 
                      method = c("ipf", "mcmc"), moves, 
                      ...)
{

  ## set/check args
  ##################################################
  
  engine  <- match.arg(engine)
  method  <- match.arg(method)  
  argList <- as.list(match.call(expand.dots = TRUE))[-1]
  
  if("formula" %in% names(argList)){
    .Deprecated(msg = 
      'the formula argument is deprecated, please use "model" instead.'
    )
  }

  
  ## reshape data
  ##################################################
  
  data   <- suppressMessages(teshape(data, "tab"))
  p      <- length(dim(data))
  nCells <- length(data)
  
  ## if a pure array is given, give names for later
  if(is.array(data) && is.null(dimnames(data))) data <- array2tab(data)
  
  ## other basic objects
  varsNlevels <- dimnames(data)  
  vars        <- names(varsNlevels)
  
  
  
  
  ## check for sampling zeros
  ##################################################
  if(any(data == 0L)) message(
    "Care ought be taken with tables with sampling zeros to ensure the MLE exists."
  )


  ## parse model specification (formula for vector of r_k's)
  ##################################################
  
  modelGivenByMatrix <- ifelse(is.matrix(model), TRUE, FALSE)

  if(modelGivenByMatrix){
    A <- model
  } else {
    # if it's a formula ~ Gender + Handedness or ~ 1 + 2, convert to list
    if(is.formula(model)){ 
    
      ## parse formula
      fString <- as.character(model)
      predString <- fString[2]
    
      ## make list of facets
      model <- strsplit(predString, " \\+ ")[[1]]
      model <- strsplit(model, " \\* ")
        
    } 

    # make facets (list of index vecs); if model specified with variable
    # names, convert them to indices
    if(all(unlist(model) %in% vars)){ # variable names      
      varname2index <- 1:p
      names(varname2index) <- vars      
      facets <- lapply(model, function(varsInFacet) varname2index[varsInFacet])
    } else if(all(unlist(model) %in% 1:length(vars))){ # by indices
      facets <- lapply(model, as.integer) # to fix the ~ 1 + 2 case, parsed as chars
    } else {
      stop("Invalid model specification, see ?loglinear")
    }
    
    # make configuration (model) matrix
    A <- hmat(dim(data), facets)
  }

  ## construct A matrix and compute moves
  ##################################################  
  
  if(missing(moves) && !is.null(getOption("4ti2_path"))){
   
    message("Computing Markov moves (4ti2)... ", appendLF = FALSE)  	
    moves <- markov(A)
    message("done.", appendLF = TRUE)      
    
  } else if(missing(moves) && is.null(getOption("4ti2_path"))){
    
    warning(
      "No moves were provided and 4ti2 is not found.\n",
      "  The resulting chain is likely not connected and strongly autocorrelated.\n",
      "  See ?loglinear.  Consider using rmove to generate SIS moves in advance.",
      immediate. = TRUE
    )
    message("Computing 1000 SIS moves... ", appendLF = FALSE)    
    moves <- rmove(n = 1000, A = A, b = A %*% tab2vec(data), ...)
    message("done.", appendLF = TRUE)      
    
  } else if(is.character(moves)){
    
    movesMat <- NULL
    stopifnot(all(moves %in% c("lattice", "markov", "groebner", "grobner", "graver", "sis")))
    if("lattice"  %in% moves)  movesMat <- cbind(movesMat,   zbasis(A))
    if("markov"   %in% moves)  movesMat <- cbind(movesMat,   markov(A))
    if("groebner" %in% moves)  movesMat <- cbind(movesMat, groebner(A))
    if("grobner"  %in% moves)  movesMat <- cbind(movesMat, groebner(A))
    if("graver"   %in% moves)  stop("graver not yet implemented.")
    moves <- movesMat
    
  }
  
  stopifnot(is.array(moves))
  


  ## run metropolis-hastings
  ##################################################  
  init <- unname(init) # init
  out <- metropolis(init, moves, iter = iter, burn = burn, thin = thin, engine = engine)  



  ## compute data chi square
  ##################################################  
  if(modelGivenByMatrix && method == "ipf"){
    message(
      "Iterative proportional fitting is not yet implemented\n", 
      "  for models specified by configuration matrices.\n",
      "  Changing to method = \"mcmc\"..."
    )
    method <- "mcmc"
  }
  if(method == "ipf"){
    exp <- loglin(data, facets, fit = TRUE, print = FALSE)$fit
  } else if(method == "mcmc"){
    exp <- vec2tab(rowMeans(out$steps), dim(data))
    dimnames(exp) <- dimnames(data)
  }
  e <- unname(tab2vec(exp))
  u <- t(t(unname(tab2vec(data))))
  PR <- computeUProbsCpp(matrix(u))  # unnormd prob; numers LAS 1.1.10
  X2 <- computeX2sCpp(u, e)  
  G2 <- computeG2sCpp(u, e)    
  FT <- computeCRsCpp(u, e, -.5)      
  CR <- computeCRsCpp(u, e, 2/3)
  NM <- computeNMsCpp(u, e)  

  
  ## compute MCMC chi squares
  ##################################################  
  PRs <- computeUProbsCpp(out$steps) # unnormd probs; numers LAS 1.1.10
  X2s <- computeX2sCpp(out$steps, e)  
  G2s <- computeG2sCpp(out$steps, e) 
  FTs <- computeCRsCpp(out$steps, e, -.5)
  CRs <- computeCRsCpp(out$steps, e, 2/3)  
  NMs <- computeNMsCpp(out$steps, e)   


  ## compute parameters
  ##################################################      
  if(!modelGivenByMatrix){
  # in principle, there should be one parameter for every cell.
  # there are prod(dim(data)) cells.
  # a good reference is BFH, p. 35 (and to a lesser extent 43)
  # the prod(dim(data)[terms[[j]]] - 1) line below is like
  # (I - 1) (J - 1) (K - 1)
  # CDA p.79 also helpful
  dimSatModel <- nCells - 1
  degFreedom <- rep.int(0, 2^p) # there are 2^p possible subsets of vars, and
                                # therefore there are 2^p possible terms
                                
  # possibleTerms are more "types of terms" as opposed to individual terms
  # for example, an entry c(1,3) would refer to all combinations of levels
  # of variables 1 and 3; ie (# var 1 levels - 1) * (# var 3 levels - 1)
  # individual terms (parameters)
  possibleTerms <- subsets(p, include_null = TRUE)
  names(possibleTerms) <- sapply(possibleTerms, paste, collapse = " ")
  names(possibleTerms)[which(names(possibleTerms) == "")] <- "(Intercept)"    
  nVarLvls <- dim(data)
  # paramsPerTerm <- lapply(possibleTerms, function(x){
  #   if(length(x) == 0) return(1L)
  #   prod(nVarLvls[x] - 1)
  # })
  
  
  # similarly, there are the terms in the model
  termsInModel <- unique(unlist(lapply(
    lapply(facets, as.character), # to avoid subsets(2)
    subsets, include_null = TRUE), 
    recursive = FALSE
  ))
  termsInModel <- lapply(termsInModel, as.integer)
  names(termsInModel) <- sapply(termsInModel, paste, collapse = " ")  
  names(termsInModel)[which(names(termsInModel) == "")] <- "(Intercept)"
  paramsPerTermInModel <- lapply(termsInModel, function(x){
    if(length(x) == 0) return(1L) 
    prod(nVarLvls[x] - 1)
  })
  names(paramsPerTermInModel) <- unname(sapply(termsInModel, function(x){
    if(length(x) == 0) return("(Intercept)")
    paste(names(dimnames(data))[x], collapse = ".")
  }))
  nParamsInModel <- sum(unlist(paramsPerTermInModel))
  dimModel <- nParamsInModel - 1 # the - 1 accounts for the overall mean
  overallAsymptoticDegFreedom <- (dimSatModel - dimModel)
  

  # compute the parameters  
  log_fit <- exp
  log_fit[exp > 0] <- log(exp[exp > 0])  
  param <- as.list(rep(NA, length(termsInModel)))
  names(param) <- names(paramsPerTermInModel) 
  for(k in seq_along(param)){
    if(length(termsInModel[[k]]) == 0){
      param[[k]] <- mean(log_fit)
      log_fit <- log_fit - param[[k]]
    } else {
      param[[k]] <- apply(log_fit, termsInModel[[k]], mean)
      log_fit <- sweep(log_fit, termsInModel[[k]], param[[k]])
    }
  }
  # for every step, fit mle
  # then decompose mle
  # problem : they all have the same marginals, so the same
  # mles!
  # idea 1 : sample from the multinomial with the same sample
  # size (so different marginals), estimate, then decompose
  # idea 2 : bootstrap sample from the table, estimate, decompose
  # i think i like idea 2 better.
  

  # reorder the param estimates in the order of subsets
  # so you have the intercept, then all first order terms, and so on
  goodOrder <- sapply(
    c("(Intercept)", subsets(names(dimnames(data)))),
    paste, collapse = "."
  )
  param <- param[goodOrder[goodOrder %in% names(param)]]
  out$param <- param
  
  }
  
  ## compute residuals and model selection, agresti p.81, 216, 324
  ##################################################  
  out$residuals <- exp
  out$residuals[exp > 0] <- 
    (data[exp > 0] - exp[exp > 0]) / sqrt(exp[exp > 0])
  
  if(!modelGivenByMatrix){
    k <- nParamsInModel  # = number of params 
    n <- sum(data)       # = sample size
    L <- dmultinom(u, sum(u), e, TRUE) # maximized log-likelihood
    BIC  <- log(n)*k - 2*L
    AIC  <-      2*k - 2*L
    AICc <- AIC + 2*k*(k+1)/(n-k-1)
    out$df <- paramsPerTermInModel
    out$quality <- c(AIC = AIC, AICc = AICc, BIC = BIC)
  }

  ## add A matrix, p.value and return
  ##################################################  
  out$call <- match.call()   
  out$obs <- data  
  out$exp <- exp
  out$A <- A
  
  out$p.value <- c(
    PR = mean(PRs <= PR),   
    X2 = mean(X2s >= X2), 
    G2 = mean(G2s >= G2),   
    FT = mean(FTs >= FT),
    CR = mean(CRs >= CR),
    NM = mean(NMs >= NM)
  )
  
  out$p.value.std.err <- c(
    PR = sqrt(mean(PRs <= PR)*(1-mean(PRs <= PR))/iter), 
    X2 = sqrt(mean(X2s >= X2)*(1-mean(X2s >= X2))/iter), 
    G2 = sqrt(mean(G2s >= G2)*(1-mean(G2s >= G2))/iter),   
    FT = sqrt(mean(FTs >= FT)*(1-mean(FTs >= FT))/iter),
    CR = sqrt(mean(CRs >= CR)*(1-mean(CRs >= CR))/iter), 
    NM = sqrt(mean(NMs >= NM)*(1-mean(NMs >= NM))/iter)     
  )  
  
  out$mid.p.value <- c(
    PR = mean(PRs < PR) + mean(PRs == PR)/2,
    X2 = mean(X2s > X2) + mean(X2s == X2)/2, 
    G2 = mean(G2s > G2) + mean(G2s == G2)/2,
    FT = mean(FTs > FT) + mean(FTs == FT)/2,
    CR = mean(CRs > CR) + mean(CRs == CR)/2,
    NM = mean(NMs > NM) + mean(NMs == NM)/2    
  )  
  
  out$iter       <- iter
  out$burn       <- burn
  out$thin       <- thin
  out$statistic  <- c(PR = PR, X2 = X2, G2 = G2, FT = FT, CR = CR, NM = NM)
  out$sampsStats <- list(PRs = PRs, X2s = X2s, G2s = G2s, FTs = FTs, CRs = CRs, NMs = NMs)
  out$cells      <- nCells
  out$method     <- method

  class(out) <- "loglinear"
  out
}



















#' @export
hierarchical <- function(...){
  .Deprecated(msg = "hierarchical is deprecated, use loglinear instead.")
  loglinear(...)
}












