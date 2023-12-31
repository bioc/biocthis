% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/use_bioc_badges.R
\name{bioc_badges}
\alias{bioc_badges}
\alias{use_bioc_badges}
\alias{use_bioc_build_badge}
\alias{use_bioc_support_badge}
\alias{use_bioc_rank_badge}
\alias{use_bioc_history_badge}
\alias{use_bioc_last_commit_badge}
\alias{use_bioc_dependencies_badge}
\title{Add Bioconductor README badges}
\usage{
use_bioc_badges()

use_bioc_build_badge(which = c("release", "devel"))

use_bioc_support_badge()

use_bioc_rank_badge()

use_bioc_history_badge()

use_bioc_last_commit_badge()

use_bioc_dependencies_badge()
}
\arguments{
\item{which}{Which branch to report the build status for. Possible values:
\code{"release"} (default) or \code{"devel"}.}
}
\description{
These functions add markdown text to the \code{README} to include all or
individual badges from the Bioconductor landing page.
}
\details{
\itemize{
\item \code{use_bioc_badges()}: adds all badges listed below, mimicking the
\href{https://bioconductor.org/packages/release/bioc/html/biocthis.html}{Bioconductor landing page}
\item \code{use_bioc_build_badge()}: badge indicating \href{https://bioconductor.org/developers/}{Bioconductor build status} for either the \code{devel} or
\code{release} branch
\item \code{use_bioc_support_badge()}: Bioc support site activity in the last 6 months
(answered posts / total posts)
\item \code{use_bioc_rank_badge()}: ranking by number of downloads
\item \code{use_bioc_history_badge()}: how long since the package was first in a
released Bioconductor version (or if it is in devel only)
\item \code{use_bioc_last_commit_badge()}: time since last commit
\item \code{use_bioc_dependencies_badge()}: number of recursive dependencies needed to
install the package
}
}
\examples{
\dontrun{
## Add all Bioc badges at once
use_bioc_badges()

## Add just the Bioc build status badge for devel
use_bioc_build_badge("devel")
}
}
\seealso{
\code{\link[usethis:badges]{usethis::use_badge()}}
}
