#
# Copyright (C) 2013-2024 University of Amsterdam
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#

# Breusch-Pagan test for heteroskedasticity in linear regression.
#
# The test is computed by hand (not via a packaged routine) so that every
# intermediate quantity can be shown to the user. The pipeline is:
#   1. Fit the main OLS regression  y = b0 + b1 x1 + ... + bk xk + u
#   2. Take the squared residuals  u_hat^2
#   3. Fit the auxiliary regression of the (scaled) squared residuals on the
#      same predictors and read off its R^2
#   4. The LM statistic is n * R^2_aux  ~  Chi^2(k)  under homoskedasticity
#
# Two flavours are offered:
#   - Koenker (studentized): regress u_hat^2 directly on the predictors.
#     This is the robust default and is what JASP / lmtest::bptest report.
#   - Original Breusch-Pagan (1979): regress u_hat^2 / (RSS/n) on the
#     predictors and use SS_explained / 2 as the statistic. This assumes
#     normal errors and is sensitive to that assumption.

breuschPagan <- function(jaspResults, dataset, options) {

  # 1. Read & check the data ----------------------------------------------
  ready <- options[["dependent"]] != "" && length(options[["covariates"]]) > 0

  if (is.null(dataset))
    dataset <- .bpReadData(options, ready)

  if (ready)
    .bpCheckErrors(dataset, options)

  # 2. Compute the test (cached as a state object) ------------------------
  bpResults <- .bpComputeResults(jaspResults, dataset, options, ready)

  # 3. Build the output tables / plots ------------------------------------
  .bpMainTable(jaspResults, bpResults, options, ready)

  if (options[["auxiliaryRegression"]])
    .bpAuxiliaryTable(jaspResults, bpResults, options, ready)

  if (options[["residualPlot"]])
    .bpResidualPlot(jaspResults, bpResults, options, ready)

  return()
}


# ---------------------------------------------------------------------------
# Data reading
# ---------------------------------------------------------------------------
.bpReadData <- function(options, ready) {
  if (!ready)
    return(data.frame())

  variables <- c(options[["dependent"]], unlist(options[["covariates"]]))
  return(.readDataSetToEnd(columns.as.numeric = variables))
}


# ---------------------------------------------------------------------------
# Error checks
# ---------------------------------------------------------------------------
.bpCheckErrors <- function(dataset, options) {
  .hasErrors(
    dataset              = dataset,
    type                 = c("infinity", "observations", "variance"),
    observations.amount  = paste("<", length(options[["covariates"]]) + 2),
    exitAnalysisIfErrors = TRUE
  )
}


# ---------------------------------------------------------------------------
# Core computation
# ---------------------------------------------------------------------------
.bpComputeResults <- function(jaspResults, dataset, options, ready) {

  # Re-use a previously computed result if nothing relevant changed
  if (!is.null(jaspResults[["bpState"]]))
    return(jaspResults[["bpState"]]$object)

  if (!ready)
    return(NULL)

  results <- try(.bpDoTest(dataset, options))

  if (isTryError(results)) {
    errorMessage <- .extractErrorMessage(results)
    jaspResults[["bpState"]] <- createJaspState(NULL)
    return(list(error = errorMessage))
  }

  state <- createJaspState(results)
  state$dependOn(c("dependent", "covariates", "testType"))
  jaspResults[["bpState"]] <- state

  return(results)
}

.bpDoTest <- function(dataset, options) {

  dependent  <- options[["dependent"]]
  covariates <- unlist(options[["covariates"]])

  # --- 1. main regression ------------------------------------------------
  # dataset already holds decoded (human-readable) column names, so we build
  # the formula directly from them, quoting with backticks to be safe.
  df <- dataset
  mainFormula <- as.formula(paste0(
    "`", dependent, "` ~ ",
    paste0("`", covariates, "`", collapse = " + ")
  ))
  mainFit <- stats::lm(mainFormula, data = df)

  u      <- stats::residuals(mainFit)
  n      <- length(u)
  k      <- length(covariates)            # df of the test
  uSq    <- u^2
  rss    <- sum(uSq)
  sigma2 <- rss / n                        # ML variance estimate

  # --- 2. auxiliary regression ------------------------------------------
  auxData <- df
  testType <- options[["testType"]]

  if (testType == "koenker") {
    # studentized BP: regress raw squared residuals on predictors
    auxData[["..uSq.."]] <- uSq
  } else {
    # original BP (1979): regress scaled squared residuals
    auxData[["..uSq.."]] <- uSq / sigma2
  }

  auxFormula <- as.formula(paste0(
    "`..uSq..` ~ ",
    paste0("`", covariates, "`", collapse = " + ")
  ))
  auxFit  <- stats::lm(auxFormula, data = auxData)
  auxSumm <- summary(auxFit)
  r2Aux   <- auxSumm$r.squared

  # --- 3. statistic & p-value -------------------------------------------
  if (testType == "koenker") {
    statistic <- n * r2Aux
  } else {
    # original BP: half the explained sum of squares of the scaled aux reg
    fittedAux <- stats::fitted(auxFit)
    ssExplained <- sum((fittedAux - mean(auxData[["..uSq.."]]))^2)
    statistic <- ssExplained / 2
  }

  pValue <- stats::pchisq(statistic, df = k, lower.tail = FALSE)

  return(list(
    statistic   = statistic,
    df          = k,
    pValue      = pValue,
    n           = n,
    r2Aux       = r2Aux,
    sigma2      = sigma2,
    auxCoefs    = stats::coef(auxFit),
    auxSE       = auxSumm$coefficients[, "Std. Error"],
    auxT        = auxSumm$coefficients[, "t value"],
    auxP        = auxSumm$coefficients[, "Pr(>|t|)"],
    coefNames   = c("(Intercept)", covariates),
    residuals   = u,
    fittedMain  = stats::fitted(mainFit),
    testType    = testType
  ))
}


# ---------------------------------------------------------------------------
# Main results table
# ---------------------------------------------------------------------------
.bpMainTable <- function(jaspResults, bpResults, options, ready) {

  if (!is.null(jaspResults[["bpTable"]]))
    return()

  testLabel <- if (options[["testType"]] == "koenker")
    gettext("Breusch-Pagan test (studentized, Koenker)")
  else
    gettext("Breusch-Pagan test (original, 1979)")

  bpTable <- createJaspTable(title = testLabel)
  bpTable$dependOn(c("dependent", "covariates", "testType"))
  bpTable$position <- 1

  bpTable$addColumnInfo(name = "statistic", title = gettext("&#967;&#178;"), type = "number")
  bpTable$addColumnInfo(name = "df",        title = gettext("df"),           type = "integer")
  bpTable$addColumnInfo(name = "p",         title = gettext("p"),            type = "pvalue")

  bpTable$addFootnote(gettext(
    "H\u2080: the error variance is constant (homoskedasticity). A significant result (small p) indicates heteroskedasticity."
  ))

  jaspResults[["bpTable"]] <- bpTable

  if (!ready)
    return()

  if (!is.null(bpResults[["error"]])) {
    bpTable$setError(bpResults[["error"]])
    return()
  }

  bpTable$addRows(list(
    statistic = bpResults[["statistic"]],
    df        = bpResults[["df"]],
    p         = bpResults[["pValue"]]
  ))

  bpTable$addFootnote(gettextf(
    "Statistic computed by hand as n \u00d7 R\u00b2 of the auxiliary regression: %1$i \u00d7 %2$s = %3$s.",
    bpResults[["n"]],
    format(round(bpResults[["r2Aux"]], 4), nsmall = 4),
    format(round(bpResults[["statistic"]], 4), nsmall = 4)
  ))
}


# ---------------------------------------------------------------------------
# Auxiliary regression table (optional)
# ---------------------------------------------------------------------------
.bpAuxiliaryTable <- function(jaspResults, bpResults, options, ready) {

  if (!is.null(jaspResults[["bpAuxTable"]]))
    return()

  auxTable <- createJaspTable(title = gettext("Auxiliary regression (squared residuals on predictors)"))
  auxTable$dependOn(c("dependent", "covariates", "testType", "auxiliaryRegression"))
  auxTable$position <- 2

  auxTable$addColumnInfo(name = "term", title = gettext("Term"),           type = "string")
  auxTable$addColumnInfo(name = "coef", title = gettext("Coefficient"),    type = "number")
  auxTable$addColumnInfo(name = "se",   title = gettext("Standard Error"), type = "number")
  auxTable$addColumnInfo(name = "t",    title = gettext("t"),              type = "number")
  auxTable$addColumnInfo(name = "p",    title = gettext("p"),              type = "pvalue")

  jaspResults[["bpAuxTable"]] <- auxTable

  if (!ready || !is.null(bpResults[["error"]]))
    return()

  for (i in seq_along(bpResults[["coefNames"]])) {
    auxTable$addRows(list(
      term = bpResults[["coefNames"]][i],
      coef = bpResults[["auxCoefs"]][i],
      se   = bpResults[["auxSE"]][i],
      t    = bpResults[["auxT"]][i],
      p    = bpResults[["auxP"]][i]
    ))
  }

  auxTable$addFootnote(gettextf(
    "R\u00b2 of the auxiliary regression = %s.",
    format(round(bpResults[["r2Aux"]], 4), nsmall = 4)
  ))
}


# ---------------------------------------------------------------------------
# Residual scatter plot (optional)
# ---------------------------------------------------------------------------
.bpResidualPlot <- function(jaspResults, bpResults, options, ready) {

  if (!is.null(jaspResults[["bpPlot"]]))
    return()

  plot <- createJaspPlot(
    title  = gettext("Residuals vs. fitted values"),
    width  = 480,
    height = 320
  )
  plot$dependOn(c("dependent", "covariates", "testType", "residualPlot"))
  plot$position <- 3

  jaspResults[["bpPlot"]] <- plot

  if (!ready || !is.null(bpResults[["error"]]))
    return()

  plotData <- data.frame(
    fitted    = bpResults[["fittedMain"]],
    residuals = bpResults[["residuals"]]
  )

  xBreaks <- jaspGraphs::getPrettyAxisBreaks(plotData$fitted)
  yBreaks <- jaspGraphs::getPrettyAxisBreaks(plotData$residuals)

  p <- ggplot2::ggplot(plotData, ggplot2::aes(x = fitted, y = residuals)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "darkred") +
    jaspGraphs::geom_point() +
    ggplot2::scale_x_continuous(name = gettext("Fitted values"),  breaks = xBreaks, limits = range(xBreaks)) +
    ggplot2::scale_y_continuous(name = gettext("Residuals"),      breaks = yBreaks, limits = range(yBreaks))

  p <- jaspGraphs::themeJasp(p)

  plot$plotObject <- p
}
