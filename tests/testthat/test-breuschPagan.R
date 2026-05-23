context("Breusch-Pagan test")

test_that("Studentized (Koenker) Breusch-Pagan matches lmtest::bptest", {
  set.seed(1)
  n <- 200
  x <- rnorm(n)
  # induce heteroskedasticity so the test has something to detect
  y <- 1 + 0.5 * x + rnorm(n, sd = exp(0.4 * x))
  testData <- data.frame(y = y, x = x)

  options <- jaspTools::analysisOptions("breuschPagan")
  options[["dependent"]]          <- "y"
  options[["covariates"]]         <- "x"
  options[["testType"]]           <- "koenker"
  options[["auxiliaryRegression"]] <- TRUE
  options[["residualPlot"]]       <- FALSE

  results <- jaspTools::runAnalysis("breuschPagan", testData, options)

  table <- results[["results"]][["bpTable"]][["data"]][[1]]

  # reference value from lmtest::bptest(lm(y ~ x))
  ref <- lmtest::bptest(lm(y ~ x, data = testData))

  expect_equal(table[["statistic"]], unname(ref$statistic), tolerance = 1e-4)
  expect_equal(table[["p"]],         unname(ref$p.value),   tolerance = 1e-4)
  expect_equal(table[["df"]],        1)
})

test_that("Analysis runs with multiple predictors", {
  set.seed(2)
  n <- 150
  x1 <- rnorm(n); x2 <- rnorm(n)
  y  <- x1 - x2 + rnorm(n)
  testData <- data.frame(y = y, x1 = x1, x2 = x2)

  options <- jaspTools::analysisOptions("breuschPagan")
  options[["dependent"]]   <- "y"
  options[["covariates"]]  <- c("x1", "x2")
  options[["testType"]]    <- "koenker"

  results <- jaspTools::runAnalysis("breuschPagan", testData, options)
  table   <- results[["results"]][["bpTable"]][["data"]][[1]]

  expect_equal(table[["df"]], 2)  # df equals number of predictors
})
