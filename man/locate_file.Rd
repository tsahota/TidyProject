% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/new_script.R
\name{locate_file}
\alias{locate_file}
\title{Locate file from search path}
\usage{
locate_file(x, search_path = c("."), recursive = FALSE)
}
\arguments{
\item{x}{string for file name}

\item{search_path}{vector of strings giving search path}

\item{recursive}{logical. Default TRUE. whether to do recusive search or not}
}
\value{
Path of located file.  Returns error if file not found.
}
\description{
Finds first file in search_path that exists
}
\examples{
\dontrun{
locate_file('script.R',c('.','Scripts')) ## looks in current working directory, then Scripts folder
}
}
