copy_empty_project <- function(proj_name,
                               lib_strategy = c("project-user","project","user","global"),
                               overwrite_rprofile=FALSE){
  lib_strategy <- match.arg(lib_strategy)
  .Rprofile_name <- normalizePath(file.path(proj_name, ".Rprofile"),winslash = "/",mustWork = FALSE)
  Rprofile.R_name <- normalizePath(file.path(proj_name, "Rprofile.R"),winslash = "/",mustWork = FALSE)

  file.copy2(file.path(system.file("extdata/EmptyProject", package = "tidyproject"),
                       "."), proj_name, recursive = TRUE, overwrite = FALSE)
  #if(!file.exists(.Rprofile_name)){
  unlink(.Rprofile_name, force = TRUE)
  result <- file.rename(Rprofile.R_name,.Rprofile_name)
  if(!result) stop("unable to create project config file")
  rproj_paths <- dir(proj_name, pattern = "\\.Rproj$", full.names = TRUE)
  if(length(rproj_paths) > 1){
    unlink(file.path(proj_name, "OpenProject.Rproj"), force = TRUE)
  }
  # } else {
  #   existing_lines <- readLines(.Rprofile_name)
  #   if(any(grepl("ProjectLibrary",existing_lines))){
  #     if(!overwrite_rprofile){
  #       stop("Existing ProjectLibrary setup lines found in ",
  #            .Rprofile_name,
  #            "\n  Remove and then try again ",
  #            "\n  Or run again with overwrite_rprofile=TRUE", call. = FALSE)
  #     } else {
  #       unlink(.Rprofile_name,force = TRUE)
  #     }
  #   }
  #   new_lines <- readLines(Rprofile.R_name)
  #   cat(paste0("\n",new_lines),file = .Rprofile_name,append = TRUE)
  # }
  config_lines <- readLines(.Rprofile_name)

  regex_lib_strategy <- '(lib\\s*<-\\s*)"project-user"'
  if(length(regex_lib_strategy) != 1) stop("can't set lib strategy - write .Rprofile manually")
  config_lines <- gsub(regex_lib_strategy, paste0('\\1"',lib_strategy,'"'), config_lines)

  #config_lines <- gsub("^(\\.remove_user_lib <- )\\S*(.*)$",
  #                     paste0("\\1",remove_user_lib,"\\2"),
  #                     config_lines)

  write(config_lines,file=.Rprofile_name)
}

## like file.copy, but only for non binaries
file.copy2 <- function(from, to, overwrite = FALSE, recursive = FALSE){
  dest <- file.path(to, basename(from))
  for(i in seq_along(from)){
    if(file.info(from[i])$isdir){
      if(overwrite | !file.exists(dest[i])) dir.create(dest[i], showWarnings = FALSE)
      next_list_files <- list.files(from[i], full.names = TRUE)
      if(length(next_list_files) > 0 & recursive)
        file.copy2(from = next_list_files, to = dest[i], recursive = TRUE)
    } else {
      if(overwrite | !file.exists(dest[i])) {
        file.create(dest[i])
        write(readLines(from[i]), file = dest[i])
      }
    }
  }
}

#' Load local package
#'
#' Equivalent to  devtools::document() followed by devtools::load_all().  This
#' function operate on a localpackage/R directory if it exists, otherwise it
#' will assume the base directory is the package directory
#'
#' @param ... arguments to be passed to devtools::load_all
#'
#' @details if analysis directory is a package this will default to
#'   devtools::document() followed by devtools::load_all()
#' @export

load_localpackage <- function(...){
  if(!requireNamespace("devtools",quietly = TRUE)) stop("devtools package required", call. = FALSE)

  if(is_package_type()){
    suppressWarnings(suppressMessages({
      devtools::document()
    }))
    devtools::load_all(...)
  } else {
    suppressWarnings(suppressMessages({
      devtools::document("localpackage")
    }))
    devtools::load_all("localpackage", ...)
  }

  return(invisible(TRUE))
}


#' Create new_project
#'
#' Creates directory structure.  User install tidyproject again in
#'
#' @param proj_name character string of full path to new_project
#' @param lib_strategy character either missing, "project","project-user","user",or "global"
#' @param overwrite_rprofile logical. should project .Rprofile be overwritten (default=FALSE)
#'
#' @export
make_project <- function(proj_name = ".", lib_strategy = c("project-user","project","user","global"),
                         overwrite_rprofile = FALSE) {
  ## must be full path.  User function: create new_project
  new_proj <- !file.exists(proj_name)
  if (new_proj) {
    tryCatch({
      message("Directory doesn't exist. Creating...")
      dir.create(proj_name)
      copy_empty_project(proj_name = proj_name,
                         lib_strategy = lib_strategy,
                         overwrite_rprofile = overwrite_rprofile)
      if (!TRUE %in% file.info(proj_name)$isdir)
        stop(paste(proj_name, "not created"))
    }, error = function(e) {
      message("Aborting. Reversing changes...")
      unlink(proj_name, recursive = TRUE, force = TRUE)
      stop(e)
    })
  } else {
    message("Directory exists. Merging...")
    ## find common files that wont be overwritten.
    all_templates <- dir(system.file("extdata/EmptyProject", package = "tidyproject"),
                         include.dirs = TRUE, all.files = TRUE, recursive = TRUE)
    all_existing <- dir(proj_name, include.dirs = TRUE, all.files = TRUE, recursive = TRUE)

    merge_conf <- intersect(all_templates, all_existing)
    message("\n---Merge conflict on files/folders (will not replace)---:\n")
    message(paste(merge_conf, collapse = "\n"))
    message("")
    copy_empty_project(proj_name=proj_name,lib_strategy = lib_strategy,
                       overwrite_rprofile = overwrite_rprofile)
  }
  if (getOption("git.exists")) {
    currentwd <- getwd()
    on.exit(setwd(currentwd))
    setwd(proj_name)
    bare_proj_name <- gsub(basename(proj_name), paste0(basename(proj_name), ".git"),
                           proj_name)
    tryCatch({
      r <- git2r::init(".")
      if (!file.exists(".gitignore")) {
        s <- unique(c(".Rproj.user", ".Rhistory", ".RData", getOption("git.ignore.files")))
        write(s, ".gitignore")
      }
      paths <- unlist(git2r::status(r))
      if (length(git2r::reflog(r)) == 0) {
        git2r::add(r, paths)
        git2r::config(r, user.name = Sys.info()["user"], user.email = getOption("user.email"))
        git2r::commit(r, "initialise_repository")
      }
    }, error = function(e) {
      setwd(currentwd)
      if (new_proj) {
        message("Aborting. Reversing changes...")
        unlink(proj_name, recursive = TRUE, force = TRUE)
        unlink(bare_proj_name, recursive = TRUE, force = TRUE)
      }
      stop(e)
    })
  }
  message(paste("tidyproject directory ready:", proj_name))
  message("----------------------------------------------------")
  message("")
  message("INSTRUCTIONS:")
  message(paste("1. Open Rstudio project to start working: ", proj_name))
  message(paste("2. (optional) Install tidyproject package in project library"))

  invisible(proj_name)

}

#' create local bare repository
#' @param proj_name character vector indicating path to tidyproject
#' @export
make_local_bare <- function(proj_name = getwd()) {
  currentwd <- getwd()
  on.exit(setwd(currentwd))
  setwd(proj_name)
  status <- git2r::status()
  if (length(status$untracked) > 0)
    stop("untracked files detected. Create bare repositories manually.")
  if (length(status$unstaged) > 0)
    stop("commit changes before continuing")
  proj_name_full <- getwd()
  bare_proj_name_full <- paste0(proj_name_full, ".git")
  git2r::clone(proj_name_full, bare_proj_name_full, bare = TRUE)
  setwd("../")
  res <- unlink(proj_name_full, recursive = TRUE, force = TRUE)
  git2r::clone(bare_proj_name_full, proj_name_full)
}

#' get project library location
#'
#' @param base_dir optional character path
#' @export
proj_lib <- function(base_dir = "."){
  R_version <- paste0(R.version$major, ".", tools::file_path_sans_ext(R.version$minor))
  base_proj_lib <- file.path(base_dir, "ProjectLibrary")#, R_version)
  base_contents <- dir(base_proj_lib, full.names = TRUE)
  base_dirs <- base_contents[file.info(base_contents)$isdir]
  base_dirs <- basename(base_dirs)
  ## no version dirs
  base_dirs <- base_dirs[!grepl("^[0-9\\.]+$", base_dirs)]

  proj_lib_v <- file.path("ProjectLibrary", R_version)
  proj_lib_v_full <- file.path(base_dir, proj_lib_v)

  if(file.exists(proj_lib_v_full)) {
    proj_lib <- proj_lib_v
  } else {
    if(length(base_dirs) == 0)
      proj_lib <- proj_lib_v else
        proj_lib <- "ProjectLibrary"
  }
  proj_lib
}

#' toggle library settings
#' @param lib character either missing, "project","project-user","user",or "global"
#' @export

toggle_libs <- function(lib = c("project","project-user","user","global")){
  current_lib_paths <- normalizePath(.libPaths(), winslash = "/")
  new_lib_paths <- current_lib_paths

  current_wd <- normalizePath(getwd(), winslash = "/")

  ## identify project/user/global libs
  match_project_libs <- grepl(current_wd, current_lib_paths)
  project_lib_pos <- which(match_project_libs)
  project_libs <- current_lib_paths[match_project_libs]
  project_lib_present <- length(project_libs) > 0
  default_project_lib <- proj_lib() #normalizePath(list.files(pattern = "ProjectLibrary", full.names = TRUE))
  default_user_lib <- normalizePath(Sys.getenv("R_LIBS_USER"), mustWork = FALSE, winslash = "/")
  match_user_lib <- grepl(default_user_lib, current_lib_paths)
  user_lib_pos <- which(match_user_lib)
  user_lib_present <- any(grepl(default_user_lib, current_lib_paths))
  default_user_lib_present <- file.exists(default_user_lib)

  move_to_front <- function(vec, indices) vec[c(indices, setdiff(seq_along(vec), indices))]
  move_to_back <- function(vec, indices) vec[c(setdiff(seq_along(vec), indices), indices)]

  global_lib_pos <- setdiff(seq_along(new_lib_paths), c(project_lib_pos,user_lib_pos))
  global_lib_present <- length(global_lib_pos) > 0

  if(missing(lib)){
    if(1 %in% project_lib_pos){
      if(2 %in% user_lib_pos) {
        message("library setting: project-user (reproducibility level: medium)")
        message("packages installed now will be specific to this project and R version")
        return(invisible("project-user")) }
      else {
        message("library setting: project (reproducibility level: high)")
        message("packages installed now will be specific to this project and R version")
        return(invisible("project"))
      }
    }
    if(1 %in% user_lib_pos) {
      message("library setting: user (reproducibility level: low)")
      message("packages installed now will be specific to you as a user and any project with a project-user config")
      return(invisible("user"))
    }
    if(1 %in% global_lib_pos) {
      message("library setting: global (reproducibility level: very low)")
      message("packages installed now will apply to all users and projects")
      return(invisible("global"))
    }
    ## else
    stop("cannot determine library structure")
  }

  lib <- match.arg(lib)

  user_front_if_exists <- function(){
    match_user_lib <- grepl(default_user_lib, new_lib_paths)
    user_lib_pos <- which(match_user_lib)
    if(user_lib_present){
      new_lib_paths <- move_to_front(new_lib_paths, user_lib_pos)
    }
    new_lib_paths
  }

  user_back_if_exists <- function(){
    match_user_lib <- grepl(default_user_lib, new_lib_paths)
    user_lib_pos <- which(match_user_lib)
    if(user_lib_present){
      new_lib_paths <- move_to_back(new_lib_paths, user_lib_pos)
    }
    new_lib_paths
  }

  user_front <- function(){
    match_user_lib <- grepl(default_user_lib, new_lib_paths)
    user_lib_pos <- which(match_user_lib)
    if(user_lib_present){
      new_lib_paths <- move_to_front(new_lib_paths, user_lib_pos)
    } else if(default_user_lib_present){
      new_lib_paths <- c(default_user_lib, new_lib_paths)
    } else stop("can't find user library")
    new_lib_paths
  }

  project_front <- function(){
    match_project_libs <- grepl(current_wd, new_lib_paths)
    project_lib_pos <- which(match_project_libs)
    if(project_lib_present){
      new_lib_paths <- move_to_front(new_lib_paths, project_lib_pos)
    } else if(file.exists(default_project_lib)) {
      new_lib_paths <- c(default_project_lib, new_lib_paths)
    } else stop("can't find a project library")
    new_lib_paths
  }

  project_back_if_exists <- function(){
    match_project_libs <- grepl(current_wd, new_lib_paths)
    project_lib_pos <- which(match_project_libs)
    if(project_lib_present){
      new_lib_paths <- move_to_back(new_lib_paths, project_lib_pos)
    }
    new_lib_paths
  }

  if(lib %in% "project"){
    new_lib_paths <- user_back_if_exists()
    new_lib_paths <- project_front()
  }


  if(lib %in% "project-user"){
    new_lib_paths <- user_front_if_exists()
    new_lib_paths <- project_front()
  }

  if(lib %in% "user"){
    new_lib_paths <- project_back_if_exists()
    new_lib_paths <- user_front()
  }

  if(lib %in% "global"){
    if(length(project_lib_pos) + length(user_lib_pos) == length(new_lib_paths))
      stop("can't find global libraries")
    new_lib_paths <- project_back_if_exists()
    new_lib_paths <- user_back_if_exists()
  }

  .libPaths(new_lib_paths)
  toggle_libs()

}

#' compute path relative to reference
#'
#' @param path character
#' @param relative_path character
#'
#' @export

relative_path <- function (path, relative_path){

  file.exists_path <- file.exists(path)
  file.exists_relative_path <- file.exists(relative_path)

  if(!file.exists_path) path <- file.path(getwd(), path)  ## if doesn't exist assume relative path
  if(!file.exists_relative_path) relative_path <- file.path(getwd(), relative_path)

  mainPieces <- strsplit(normalizePath(path, mustWork = FALSE, winslash = "/"), .Platform$file.sep, fixed=TRUE)[[1]]
  refPieces <- strsplit(normalizePath(relative_path, mustWork = FALSE, winslash = "/"), .Platform$file.sep, fixed=TRUE)[[1]]

  #if(!file.exists_path) unlink(path)
  #if(!file.exists_relative_path) unlink(relative_path)

  shorterLength <- min(length(mainPieces), length(refPieces))

  last_common_piece <- max(which(mainPieces[1:shorterLength] == refPieces[1:shorterLength]),1)

  dots <- setdiff(refPieces,refPieces[1:last_common_piece])
  dots <- rep("..", length(dots))

  mainPieces <- setdiff(mainPieces,mainPieces[1:last_common_piece])

  relativePieces <- c(dots, mainPieces)
  do.call(file.path, as.list(relativePieces))
}

relative_path <- Vectorize(relative_path, USE.NAMES = FALSE)

is_package_type <- function(){
  top_level_files <- dir()
  !"localpackage" %in% top_level_files & "R" %in% top_level_files
}

#' stage files in project staging area ready for import
#'
#' @param files character vector. path of files to stage
#' @param destination default empty.  Optional destination directory
#'  by default will be equivalent location in staging/
#' @param additional_sub_dirs character vector. additional subdirectories
#'  not in standard tidyproject structure
#' @param overwrite logical (default = FALSE).
#' @param silent logical (default = FALSE)
#' @export
stage <- function(files, destination, additional_sub_dirs = c(),
                  overwrite = FALSE, silent = FALSE){

  ## send unmodified files into staging area for importation

  files <- normalizePath(files, winslash = "/")

  ##########################
  sub_dirs <- c("SourceData",
                "DerivedData",
                "localpackage",
                "Scripts",
                "Models",
                tidyproject::models_dir(),
                "Results",
                additional_sub_dirs)

  sub_dirs <- basename(sub_dirs)

  sub_dirs <- unique(sub_dirs)

  key_dirs <- sub_dirs

  regex_key_dirs <- paste0("\\b", key_dirs, "\\b")

  files_sep <- strsplit(files, .Platform$file.sep)

  if(!missing(destination)){
    if(!grepl("staging", destination))
      stop("destination should be in staging area", call. = FALSE)
    destination <- file.path(destination, basename(files))
    destination <- relative_path(destination, "staging")
  } else {
    destination <- sapply(files_sep, function(file_sep){
      file_sep <- rev(file_sep)
      matches <- match(key_dirs, file_sep)
      if(all(is.na(matches))) return(NA_character_)
      matched_dir <- key_dirs[which.min(matches)]
      file_sep <- file_sep[seq_len(match(matched_dir, file_sep))]
      do.call(file.path, as.list(rev(file_sep)))
    })
  }

  ## analysis package code
  if(is_package_type()){
    destination <- gsub("localpackage/R", "R",destination)
    ## remove other files in localpackage
    subset_files <- !grepl("localpackage", destination)
    files <- files[subset_files]
    destination <- destination[subset_files]
  }

  d <- tibble::tibble(from = files, destination)
  d$staging <- file.path("staging", d$destination)

  d <- d[!is.na(d$destination), ]
  dir_names <- unique(dirname(d$staging))
  for(dir_name in dir_names) dir.create(dir_name, recursive = TRUE, showWarnings = FALSE)

  existing_files <- d$staging[file.exists(d$staging)]
  do_copy <- rep(TRUE, nrow(d))  ## default = copy
  if(!overwrite & length(existing_files)){
    #stop("File(s) already exist:\n",paste(paste0(" ",existing_files),collapse="\n"), "\nRename existing staged files or use overwrite=TRUE", call. = FALSE)
    if(!silent) message("File(s) not to be overwritten:\n",paste(paste0(" ",existing_files),collapse="\n"), "\nRename existing staged files or use overwrite=TRUE")
    #d <- d[!d$staging %in% existing_files, ]
    do_copy[file.exists(d$staging)] <- FALSE
  }

  file.copy(d$from[do_copy],
            d$staging[do_copy],
            overwrite = overwrite)

  if(!silent) message("File(s) staged in project:\n",paste(paste0(" ",d$staging[do_copy]),collapse="\n"), "\nTo import use import()")

  invisible(d)

}

#' Import staged files into project
#'
#' @param copy_table data frame or character.
#'   if data.frame should be output from \code{stage()}
#'   if character path, result will be \code{stage()}d first
#' @param overwrite logical (default = FALSE)
#' @param silent logical (default = FALSE)
#' @param skip character (default = "\\.mod$"). pattern to skip
#' @export
import <- function(copy_table, overwrite = FALSE, silent = FALSE,
                   skip = "\\.mod$"){

  ## import the files_to_copy

  ## R scripts in Scripts to be copied with the stamp at the top
  ## Code in Models/. not to be copied - this will be handled by nm() %>% ctl("staging/...")
  ## everything else copied as is

  if(is.character(copy_table)){
    copy_table <- stage(copy_table, overwrite = overwrite, silent = silent)
  }

  copy_table <- copy_table[!is.na(copy_table$destination), ]
  ## skip everything in Models
  copy_table <- copy_table[!grepl(skip, copy_table$destination), ]

  copy_table$extn <- tools::file_ext(copy_table$destination)

  d_R <- copy_table[copy_table$extn %in% c("r", "R"), ]
  d_other <- copy_table[!copy_table$extn %in% c("r", "R"), ]

  existing_files <- c(
    d_R$destination[file.exists(d_R$destination)],
    d_other$destination[file.exists(d_other$destination)]
  )
  if(!overwrite & length(existing_files) > 0){
    #stop("File(s) already exist:\n",paste(paste0(" ",existing_files),collapse="\n"), "\nRename existing staged files or use overwrite=TRUE", call. = FALSE)
    if(!silent) message("File(s) not to be overwritten:\n",paste(paste0(" ",existing_files),collapse="\n"), "\nRename existing project files or use overwrite=TRUE")
    copy_table <- copy_table[!copy_table$destination %in% existing_files, ]
  }

  dirs <- dirname(c(d_R$destination, d_other$destination))
  dirs <- unique(dirs)
  for(path in dirs) dir.create(path, recursive = TRUE, showWarnings = FALSE)

  copy_script2(d_R$staging, d_R$destination, overwrite = overwrite)
  file.copy(d_other$staging, d_other$destination, overwrite = overwrite)  ## use copy_file instead?

  message("Files imported:\n ",
          paste(copy_table$destination, collapse = "\n "))

  invisible()

}
