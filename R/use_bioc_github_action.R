## By Marcel Ramos in https://github.com/lcolladotor/biocthis/pull/11
.normalizeVersion <- function() {
    if (BiocManager:::isDevel()) {
        "devel"
    } else {
        paste0("RELEASE_", gsub("\\.", "_", BiocManager::version()))
    }
}

.GHARversion <- function(biocdocker) {
    ## For R CMD check
    BiocStatus <- Bioc <- NULL

    info <- BiocManager:::.version_map_get_online(
        "https://bioconductor.org/config.yaml"
    )
    info <- subset(info, BiocStatus != "future")

    if (biocdocker == "devel") {
        res <- subset(info, BiocStatus == "devel")

        ## Check the latest "release" version. If the R version is older than
        ## the R version for Bioc-devel, this means that we are working with R-devel
        ## and need to use that version for r-lib/actions/setup-r to recognize it
        ## https://github.com/r-lib/actions/tree/master/setup-r
        last_rel <- as.character(subset(info, BiocStatus == "release")[, "R"])
        res[, "R"] <- ifelse(last_rel == res[, "R"], last_rel, "devel")
    } else {
        biocdocker <- gsub("^RELEASE_", "", toupper(biocdocker))
        biocdocker <- gsub("_", ".", biocdocker)
        res <- subset(info, Bioc == biocdocker)
    }

    c("R" = as.character(res[, "R"]), "Bioc" = as.character(res[, "Bioc"]))
}

#' Create a biocthis-style GitHub Actions workflow
#'
#' This function is very similar to `usethis::use_github_action()` except
#' that it uses a template from `biocthis`. It creates a Bioconductor-friendly
#' GitHub action workflow for your package. You can also use this GitHub
#' Actions workflow by executing `usethis::use_github_action()`.
#'
#' For the full history on how this GitHub Actions workflow came to be, check
#' the "biocthis developer notes" vignette
#' <https://lcolladotor.github.io/biocthis/articles/biocthis_dev_notes.html>.
#'
#' @param biocdocker A `character(1)` specifying the Bioconductor docker
#' version you want to use. Valid names are `"devel"` or in the
#' `"RELEASE_X_Y"` format such as `"RELEASE_3_11"`. Check
#' <http://bioconductor.org/help/docker/> for more information on the
#' Bioconductor docker images. If you don't specify this, it will be
#' determined automatically using your current Bioconductor version. The
#' R version will be set to match the Bioconductor version.
#' @param pkgdown A `logical(1)` specifying whether to run `pkgdown`. Check
#' <https://cran.r-project.org/web/packages/pkgdown/index.html> for more
#' information on `pkgdown` which is useful for creating documentation
#' websites. If `TRUE`, then `pkgdown` will only run on the Linux
#' (Bioconductor docker) test.
#' @param testthat A `logical(1)` specifying whether to run `testthat`. Check
#' <https://cran.r-project.org/web/packages/testthat/index.html> for more
#' information about `testthat` which is useful for unit tests. The
#' testing chapter at <https://r-pkgs.org/tests.html> is also very useful.
#' @param covr A `logical(1)` specifying whether to run `covr`. Check
#' <https://cran.r-project.org/web/packages/covr/index.html> for more
#' information about `covr`, which is useful for displaying for assessing
#' your test coverage. If `TRUE`, then `covr` will only run on the Linux
#' (Bioconductor docker) test.
#' @param covr_coverage_type A `character(1)` specifying the code used to
#' calculate the `covr` coverage. Option are package `"tests"`, `"vignettes"`,
#' `"examples"`, `"all"`, or `"none"`. The default is `"all"`.
#' @param RUnit A `logical(1)` specifying whether to run `RUnit` unit tests.
#' Check <http://bioconductor.org/developers/how-to/unitTesting-guidelines/>
#' for more information about `RUnit`.
#' @param pkgdown_covr_branch A `character(1)` specifying the name of the GitHub
#' branch that will be used creating the `pkgdown` website and running `covr`.
#' Since biocthis version 1.9.3 this changed from "master" to "devel" by default
#' to match <https://twitter.com/Bioconductor/status/1631234299423850497>.
#' @param docker A `logical(1)` specifying whether to build a docker image
#' with the resulting package. This will also create a `Dockerfile`. You can
#' alternatively try using this excellent template:
#' <https://github.com/seandavi/BuildABiocWorkshop>.
#'
#' @return This function adds and/or replaces the
#' `.github/workflows/check-bioc.yml` file in your R package.
#'
#' @export
#'
#' @import usethis
#'
#' @examples
#' \dontrun{
#' ## Run this function in your package
#' biocthis::use_bioc_github_action()
#' }
#'
#' ## I have the following options on my ~/.Rprofile set
#' ## Check
#' ## <https://github.com/lcolladotor/biocthis/issues/9#issuecomment-702401032>
#' ## for more information.
#' options("biocthis.pkgdown" = TRUE)
#' options("biocthis.testthat" = TRUE)
use_bioc_github_action <- function(biocdocker,
    pkgdown = getOption("biocthis.pkgdown", FALSE),
    testthat = getOption("biocthis.testthat", FALSE),
    covr = testthat,
    covr_coverage_type = getOption("biocthis.covr_coverage_type", "all"),
    RUnit = getOption("biocthis.RUnit", FALSE),
    pkgdown_covr_branch = getOption("biocthis.pkgdown_covr_branch", "devel"),
    docker = getOption("biocthis.docker", FALSE)) {
    if (!missing(biocdocker)) {
        if (!grepl("^devel$|^RELEASE_", biocdocker[[1]])) {
            stop(
                "'biocdocker' should be 'devel' or in the 'RELEASE_X_Y' format, such as 'RELEASE_3_11'",
                call. = FALSE
            )
        }
    } else {
        biocdocker <- .normalizeVersion()
    }

    otps_overage_type <- c("tests", "vignettes", "examples", "all", "none")
    if (!covr_coverage_type %in% otps_overage_type) {
        stop(
            "'covr_coverage_type' should be 'tests', 'vignettes', 'examples', 'all', or 'none'.",
            call. = FALSE
        )
    }

    ## Set the variables to be used in the template GHA workflow
    repo_spec <- get_github_spec()
    datalist <- list(
        dockerversion = biocdocker,
        rvernum = .GHARversion(biocdocker)["R"],
        biocvernum = .GHARversion(biocdocker)["Bioc"],
        has_testthat = ifelse(testthat, "true", "false"),
        run_covr = ifelse(covr, "true", "false"),
        covr_coverage_type = covr_coverage_type,
        run_pkgdown = ifelse(pkgdown, "true", "false"),
        has_RUnit = ifelse(RUnit, "true", "false"),
        pkgdown_covr_branch = pkgdown_covr_branch,
        pkgdown_install = ifelse(
            biocdocker == "devel",
            'remotes::install_github("r-lib/pkgdown")',
            'remotes::install_cran("pkgdown")'
        ),
        run_docker = ifelse(docker, "true", "false")
    )

    ## Ask users to update the permissions for runners on GitHub
    if (!is.null(repo_spec)) {
        if (pkgdown) {
            message(
                "In order for the automatic pkgdown updates to work, you will need to go to https://github.com/",
                tolower(repo_spec),
                "/settings/actions and enable: Workflow permissions > Read and write permissions. Then click save."
            )
        }
        if (pkgdown && interactive()) {
            browseURL(paste0(
                "https://github.com/",
                tolower(repo_spec),
                "/settings/actions"
            ))
        }
    }


    ## Create Dockerfile if needed as well
    if (docker) {
        new_docker <-
            use_template(
                "Dockerfile",
                "Dockerfile",
                data = datalist,
                open = TRUE,
                package = "biocthis",
                ignore = usethis:::is_package()
            )
    }

    ## Locate the template GHA workflow
    template <- system.file(
        package = "biocthis", "templates",
        "check-bioc.yml", mustWork = TRUE
    )
    contents <- readLines(template)

    ## The code below is similar in results to whisker::whisker.render()
    idx <- grep("[^$]\\{\\{", contents)
    parts <- grep("[^$]\\{\\{", contents, value = TRUE)
    pco <- vector("character", length(parts))
    for (i in seq_along(parts)) {
        pco[[i]] <- mapply(
            function(x, y) {
                parts[[i]] <<- gsub(x, y, parts[[i]], fixed = TRUE)
            },
            x = paste0("{{", names(datalist), "}}"), y = datalist
        )[[length(datalist)]]
    }
    contents[idx] <- pco

    ## code taken from usethis
    usethis:::use_dot_github(ignore = TRUE)
    save_as <- fs::path(".github", "workflows", "check-bioc.yml")
    usethis:::create_directory(dirname(usethis::proj_path(save_as)))
    new <- usethis::write_over(usethis::proj_path(save_as), contents)
    invisible(new)
}
