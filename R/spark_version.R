spark_version_clean <- function(version) {
  gsub("\\.$","", gsub("([0-9]+\\.?)[^0-9\\.](.*)","\\1", version))
}

#' Get the Spark Version Associated with a Spark Connection
#'
#' Retrieve the version of Spark associated with a Spark connection.
#'
#' Suffixes for e.g. preview versions, or snapshotted versions,
#' are trimmed -- if you require the full Spark version, you can
#' retrieve it with \code{invoke(spark_context(sc), "version")}.
#'
#' @param sc A \code{spark_connection}.
#'
#' @return The Spark version as a \code{\link{numeric_version}}.
#'
#' @export
spark_version <- function(sc) {
  UseMethod("spark_version")
}

#' @export
spark_version.default <- function(sc) {

  # use cached value if available
  if (!is.null(sc$state$spark_version))
    return(sc$state$spark_version)

  # if `SPARK_HOME` is specified, infer version from it
  if (!is.null(sc$spark_home))
    return(spark_version_from_home(sc$spark_home))

  # get the version
  version <- invoke(spark_context(sc), "version")

  # Get rid of -preview and other suffix variations
  version <- spark_version_clean(version)

  # cache as numeric version
  sc$state$spark_version <- numeric_version(version)

  # return to caller
  sc$state$spark_version
}

spark_version_from_home_version <- function() {
  version <- Sys.getenv("SPARK_HOME_VERSION")
  if (nzchar(version)) version else NULL
}

#' Get the Spark Version Associated with a Spark Installation
#'
#' Retrieve the version of Spark associated with a Spark installation.
#'
#' @param spark_home The path to a Spark installation.
#' @param default The default version to be inferred, in case
#'   version lookup failed, e.g. no Spark installation was found
#'   at \code{spark_home}.
#'
#' @export
spark_version_from_home <- function(spark_home, default = NULL) {
  versionAttempts <- list(
    useDefault = function() {
      default
    },
    useEnvironmentVariable = function() {
      spark_version_from_home_version()
    },
    useReleaseFile = function() {
      versionedFile <- file.path(spark_home, "RELEASE")
      if (file.exists(versionedFile)) {
        releaseContents <- readLines(versionedFile)

        if (!is.null(releaseContents) && length(releaseContents) > 0) {
          gsub("Spark | built.*", "", releaseContents[[1]])
        }
      }
    },
    useAssemblies = function() {
      candidateVersions <- list(
        list(path = "lib", pattern = "spark-assembly-([0-9\\.]*)-hadoop.[0-9\\.]*\\.jar"),
        list(path = "yarn", pattern = "spark-([0-9\\.]*)-preview-yarn-shuffle\\.jar"),
        list(path = "yarn", pattern = "spark-([0-9\\.]*)-yarn-shuffle\\.jar"),
        list(path = "lib", pattern = "spark-([0-9\\.]*)-preview-yarn-shuffle\\.jar"),
        list(path = "lib", pattern = "spark-([0-9\\.]*)-yarn-shuffle\\.jar")
      )

      candidateFiles <- lapply(candidateVersions, function(e) {
        c(e,
          list(
            files = list.files(
              file.path(spark_home, e$path),
              pattern = e$pattern,
              recursive = TRUE
            )
          )
        )
      })

      filteredCandidates <- Filter(function(f) length(f$files) > 0, candidateFiles)
      if (length(filteredCandidates) > 0) {
        valid <- filteredCandidates[[1]]
        e <- regexec(valid$pattern, valid$files[[1]])
        match <- regmatches(valid$files[[1]], e)
        if (length(match) > 0 && length(match[[1]]) > 1) {
          return(match[[1]][[2]])
        }
      }
    }
  )

  for (versionAttempt in versionAttempts) {
    result <- versionAttempt()
    if (length(result) > 0)
      return(spark_version_clean(result))
  }

  stop(
    "Failed to detect version from SPARK_HOME or SPARK_HOME_VERSION. ",
    "Try passing the spark version explicitly.")
}
