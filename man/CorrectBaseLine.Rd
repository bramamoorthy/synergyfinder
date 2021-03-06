% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Reshape_data.R
\name{CorrectBaseLine}
\alias{CorrectBaseLine}
\title{Base line correction}
\usage{
CorrectBaseLine(response.mat, method = c("non", "part", "all"))
}
\arguments{
\item{response.mat}{A drug cobination dose-response matrix. It's column name
and row name are representing the concerntrations of drug added to column 
and row, respectively. The values in matrix indicate the inhibition rate to
cell growth.}

\item{method}{A character value to indicate using which method to do
baseline correction. Available values ate:
\itemize{
  \item \strong{non} means no baseline corection.
  \item \strong{part} means only adjust the negative values in the matrix.
  \item \strong{all} means adjust all values in the matrix.
}}
}
\value{
A matrix which base line have been adjusted.
}
\description{
\code{CorrectBaseLine} adjusts the base line of drug combination
dose-response matrix to make it closer to 0.
}
\examples{
data("mathews_screening_data")
data <- ReshapeData(mathews_screening_data)
response.mat <- data$dose.response.mats[[1]]
adjusted.mat <- CorrectBaseLine(response.mat, method = "part")
}
\author{
\itemize{
   \item{Liye He \email{liye.he@helsinki.fi}}
   \item{Shuyu Zheng \email{shuyu.zheng@helsinki.fi}}
}
}
