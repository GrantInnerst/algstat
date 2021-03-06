% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/segre.R
\name{segre}
\alias{segre}
\title{Segre Product}
\usage{
segre(...)
}
\arguments{
\item{...}{A listing of matrices}
}
\value{
A matrix that is the Segre product of the specified matrices.
}
\description{
Compute the Segre product of an arbitrary number of matrices
}
\examples{

A <- B <- C <- matrix(c(1,1,1,2,1,3,1,4,1,5), nrow = 2, ncol = 5)

# two matrices
segre(A, B)

# more 
segre(A, B, C)
}
