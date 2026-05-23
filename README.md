# jaspBreuschPagan

A JASP module that performs the **Breusch–Pagan test** for heteroskedasticity in
linear regression. You select a dependent variable and one or more predictors,
and the module fits the regression, takes the squared residuals, runs the
auxiliary regression and reports the test statistic and p-value — exactly the
manual procedure, done for you automatically.

## What it computes

For a regression `y = b0 + b1*x1 + ... + bk*xk + u`:

1. Fits the main OLS regression and extracts the residuals `u`.
2. Squares them: `u^2`.
3. Runs the **auxiliary regression** of the squared residuals on the same
   predictors and reads off its `R²`.
4. Reports the statistic `LM = n × R²` with `k` degrees of freedom, and the
   χ² p-value `P(χ²(k) > LM)`.

Null hypothesis: the error variance is constant (homoskedasticity). A small
p-value indicates heteroskedasticity.

### Two variants

- **Studentized (Koenker)** — the robust default. Regresses the raw squared
  residuals on the predictors; `LM = n × R²`. Matches `lmtest::bptest()` and
  does not assume normally distributed errors.
- **Original Breusch–Pagan (1979)** — the classic version assuming normal
  errors; uses half the explained sum of squares of the scaled auxiliary
  regression.

## Output

- **Main table**: χ², df, and p, with a footnote spelling out the `n × R²`
  arithmetic.
- **Auxiliary regression table** (optional): the coefficients of the auxiliary
  regression and its R².
- **Residuals vs. fitted plot** (optional): a funnel/fan shape is a visual cue
  for heteroskedasticity.

## Installation (as a development module)

1. Fork or download this repository.
2. Open JASP.
3. Go to the **+** menu (top-right) → **Developer mode** must be enabled in
   *Preferences → Advanced*.
4. Click **Install Developer Module** and point it at this folder.
5. The **Breusch-Pagan Test** analysis appears in the module's ribbon.

## Usage

1. Open your dataset in JASP.
2. Click the module's icon → **Breusch-Pagan Test**.
3. Assign your outcome to **Dependent variable** and your predictor(s) to
   **Predictors** (use the same predictors as in your original regression).
4. Pick a test variant and read off χ², df and p.

## Verification

The studentized variant has been checked against `lmtest::bptest()`. As a
worked example, on a regression of `BC_diff` on `2_age` (n = 201) the module
returns χ² = 1.4497, df = 1, p = 0.2286 — identical to the value obtained by
hand from the auxiliary regression's R² (0.007213 × 201).

## License

GPL (>= 2).
