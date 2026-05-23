### ==========================================================================
### Telepito script a jaspBreuschPagan JASP-modulhoz
### ==========================================================================
###
### HASZNALAT:
###   1. Nyisd meg a jaspBreuschPagan.Rproj fajlt RStudio-ban (dupla kattintas).
###   2. Az RStudio Console-ban futtasd:  source("install.R")
###   3. A script a vegen kiirja a "Project library" utvonalat.
###   4. JASP -> Preferences -> Advanced -> Development module:
###         Project library : <a kiirt utvonal>
###         Module name     : jaspBreuschPagan
###      majd a Modules listaban a refresh/frissites gomb.
### ==========================================================================

message("\n=== jaspBreuschPagan telepito script ===\n")

if (!file.exists("DESCRIPTION") || !dir.exists("inst"))
  stop("Ezt a scriptet a modul fo mappajabol futtasd (ahol a DESCRIPTION es az ",
       "inst mappa van). Nyisd meg a jaspBreuschPagan.Rproj-ot eloszor.")

if (!requireNamespace("renv", quietly = TRUE)) {
  message("Az 'renv' csomag nincs telepitve. Telepitem...")
  install.packages("renv", repos = "https://cloud.r-project.org")
}

renv::consent(provided = TRUE)

if (is.null(renv::project())) {
  if (file.exists("renv.lock")) {
    message("Van renv.lock, aktivalom a projektet.")
    renv::activate()
  } else {
    message("Nincs meg renv.lock, inicializalom a projektet (renv::init).")
    renv::init(bare = TRUE, restart = FALSE)
  }
} else {
  message("Mar aktiv renv projekt.")
}

if (file.exists("renv.lock")) {
  message("Lockfile szinkronizalasa (renv::restore)...")
  try(renv::restore(clean = FALSE, prompt = FALSE), silent = TRUE)
}

message("\nA modul es fuggosegeinek telepitese (renv::install)...\n")
renv::install(".", prompt = FALSE)

message("\nLockfile frissitese (renv::snapshot)...")
try(renv::snapshot(prompt = FALSE), silent = TRUE)

libPath <- .libPaths()[1]
message("\n==========================================================")
message(" KESZ! Ezt add meg a JASP-ban:")
message("----------------------------------------------------------")
message(" Project library : ", libPath)
message(" Module name     : jaspBreuschPagan")
message("==========================================================\n")
message("JASP -> Preferences -> Advanced -> Development module mezok,")
message("majd a Modules listaban a frissites (refresh) gomb.\n")

## --- (Megjegyzes) GitHub token, ha kell ------------------------------------
## Ha a jaspBase/jaspGraphs letoltesenel 401/403 hibat kapsz:
##   usethis::edit_r_environ()
##   # a megnyilo fajlba ird be (uj tokennel):  GITHUB_PAT=ghp_...
##   # mentsd, majd Session -> Restart R, es futtasd ujra ezt a scriptet.
## Ellenorzes:  gh::gh_whoami()
