% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/makers.r
\name{Pmaker}
\alias{Pmaker}
\title{Pairs matrix}
\usage{
Pmaker(m)
}
\arguments{
\item{m}{the number of objects}
}
\value{
...
}
\description{
Compute the pairs matrix for a full ranking of m objects
}
\details{
This is the transpose of the pairs matrix presented in Marden (1995).
}
\examples{

data(city); city

Pmaker(3)
Pmaker(3) \%*\% city
# 1 = city, 2 = suburb, 3 = country

# looking just among city folk, generate the pairs matrix
city[,"city",drop=FALSE] # the data
m <- sum(city[,"city"])
k <- (Pmaker(3) \%*\% city)[,1]
Khat <- upper(k) + lower(m-k)
colnames(Khat) <- row.names(Khat) <- colnames(city)
Khat
round(Khat / m, 2) # \% times row is rated over column


# worked out: city is voted over suburb in 123 , 132, and 231, equaling
210 + 23 + 8   # = Khat[1,2]
# whereas suburb is rated over city in 213, 312, 321, equaling
111 + 204 + 81 # = Khat[2,1]


# is there a condorcet choice?

p <- ncol(Khat)
Khat[which(diag(p) == 1)] <- NA
K2 <- t(apply(Khat, 1, function(v) v[!is.na(v)])) # remove diag elts
boole <- apply(K2/m, 1, function(x) all(x > .5))
if(any(boole)) names(boole)[which(boole)]
# suburb is a condorcet choice

}
\references{
Marden, J. I. (1995). \emph{Analyzing and Modeling Rank Data},
London: Chapman & Hall. p.42.
}
\seealso{
\code{\link[=Tmaker]{Tmaker()}}, \code{\link[=Amaker]{Amaker()}}, \code{\link[=Emaker]{Emaker()}}, \code{\link[=Mmaker]{Mmaker()}}, \code{\link[=Smaker]{Smaker()}}
}
