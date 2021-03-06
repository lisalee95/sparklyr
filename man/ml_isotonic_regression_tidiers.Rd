% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tidiers_ml_isotonic_regression.R
\name{ml_isotonic_regression_tidiers}
\alias{ml_isotonic_regression_tidiers}
\alias{tidy.ml_model_isotonic_regression}
\alias{augment.ml_model_isotonic_regression}
\alias{glance.ml_model_isotonic_regression}
\title{Tidying methods for Spark ML Isotonic Regression}
\usage{
\method{tidy}{ml_model_isotonic_regression}(x, ...)

\method{augment}{ml_model_isotonic_regression}(x, newdata = NULL, ...)

\method{glance}{ml_model_isotonic_regression}(x, ...)
}
\arguments{
\item{x}{a Spark ML model.}

\item{...}{extra arguments (not used.)}

\item{newdata}{a tbl_spark of new data to use for prediction.}
}
\description{
These methods summarize the results of Spark ML models into tidy forms.
}
