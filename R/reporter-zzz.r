#' @include reporter-stop.r
NULL

#' Get/set reporter; execute code in specified reporter.
#'
#' Changes global reporter to that specified, runs code and the returns
#' global reporter back to previous value.
#'
#' The \code{with_reporter} function returns the reporter that has been used
#' for running the code.
#'
#' @keywords internal
#' @param reporter test reporter to use
#' @param code code block to execute
#' @name reporter-accessors
NULL

testthat_env <- new.env()

# Default has to be the stop reporter, since it is this that will be run by
# default from the command line and in R CMD test.
testthat_env$reporter <- StopReporter$new()

#' @rdname reporter-accessors
#' @export
set_reporter <- function(reporter) {
  old <- testthat_env$reporter
  testthat_env$reporter <- reporter
  invisible(old)
}

#' @rdname reporter-accessors
#' @export
get_reporter <- function() {
  testthat_env$reporter
}

#' @rdname reporter-accessors
#' @param start_end_reporter whether to start and end the reporter
#' @export
with_reporter <- function(reporter, code, start_end_reporter = TRUE) {
  reporter <- find_reporter(reporter)

  old <- set_reporter(reporter)
  on.exit(set_reporter(old))

  if (start_end_reporter) {
    reporter$start_reporter()
  }

  force(code)

  if (start_end_reporter) {
    reporter$end_reporter()
  }

  invisible(reporter)
}

#' Find reporter object given name or object.
#'
#' If not found, will return informative error message.
#' Pass a character vector to create a \code{\link{MultiReporter}} composed
#' of individual reporters.
#' Will return null if given NULL.
#'
#' @param reporter name of reporter(s), or reporter object(s)
#' @keywords internal
find_reporter <- function(reporter) {
  if (is.null(reporter)) return(NULL)

  if (length(reporter) <= 1L) {
    find_reporter_one(reporter)
  } else {
    MultiReporter$new(reporters = lapply(reporter, find_reporter_one))
  }
}

find_reporter_one <- function(reporter) {
  if (inherits(reporter, "Reporter")) return(reporter)

  name <- reporter
  substr(name, 1, 1) <- toupper(substr(name, 1, 1))
  name <- paste0(name, "Reporter")

  if (!exists(name)) {
    stop("Can not find test reporter ", reporter, call. = FALSE)
  }

  get(name)$new()
}
