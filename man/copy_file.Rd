% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TidyProject.R
\name{copy_file}
\alias{copy_file}
\title{Copy file to project directory}
\usage{
copy_file(from, dest_dir, overwrite = FALSE, alt_paths)
}
\arguments{
\item{from}{character. file name or path of file to copy}

\item{dest_dir}{character. file name file to create}

\item{overwrite}{logical. Overwrite "to" file if exists?}

\item{alt_paths}{character vector. paths to other candidate files to search}
}
\description{
Will copy any file from an external location (e.g. code library) into project
No modification of that file will take place
}
