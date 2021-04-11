# tidyproject

[![Travis-CI Build Status](https://travis-ci.org/tsahota/tidyproject.svg?branch=master)](https://travis-ci.org/tsahota/tidyproject)
[![Coverage Status](https://coveralls.io/repos/github/tsahota/tidyproject/badge.svg?branch=master)](https://coveralls.io/github/tsahota/tidyproject?branch=master)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/tsahota/tidyproject?branch=master&svg=true)](https://ci.appveyor.com/project/tsahota/tidyproject)

## Build Institutional Memory and Learning:
 
#### Memory:
* Consistent and tidy directory structure for all your projects
* Long term reproducibility:
  * Project library for each project: stores packages alongside project code (like packrat but lighter): 
  * Version control (git) compatibility: roll back your projects when needed.

#### Learning:
* Code library: Store and share scripts, functions, templates in an ever improving repository of code
* Search code library for keywords or raw text

## Installation

The alpha version is `v0.3.2`.  The beta version is `v0.5.2`.  Install the version you want with

```R
install.packages("devtools")
devtools::install_github("tsahota/tidyproject@v0.5.2")
library(tidyproject)
```

Get the most recent stable release with:

```R
devtools::install_github("tsahota/tidyproject")
```

## Quick Tutorial

### Make a project

Make a tidyproject by selecting `File` -> `New Project` -> `New Directory` -> `New tidyproject`

You should see a new directory structure.  Opening the Rstudio project reconfigures default libraries to use the project library, e.g. try installing a package now:

```R
devtools::install_github("tsahota/tidyproject")
library(tidyproject)
```

This package is now in your "ProjectLibrary" subdirectory. Loading packages from this tidyproject (e.g. with `library`), will cause packages in this specific project library load. If you want to switch projects, use Rstudio's "open project".  Using setwd() is strongly discouraged.

Create a new script:

```R
new_script("scriptname.R")
```
This will pre-fill some comment fields and store the script in your "Scripts" subdirectory.

### Use code library

View code library with:

```R
code_library()
```

Preview code with:

```R
preview("nameofscript.R")
```

To get the full file path of code library files use `ls_code_library`.  E.g. 

```R
ls_code_library("nameofscript.R")
```

will return a list of files matching `nameofscript.R`.  Bring code into your project by staging and then importing:

```R
ls_code_library("nameofscript.R") %>%
  stage() %>%
  import()
```

This will bring the code into a top directory `staging` which has the same substructure as the main analysis directory.  Importing bring your code from the staged area to the main analysis directory.  This two step process is done for reproducibility since as even if `nameofscript.R` changes in the code library in a way that breaks your code, the version of it that's been staged will remain static. Ensuring that your code will not break due to this.

If you want to replace your staged script (or the imported script) using the argument `overwrite = TRUE`.  Be careful though. 


### Search for code

To list all R scripts in the `./Scripts` subdirectory:

```R
ls_scripts("./Scripts")
```

More refined searching is most easily accomplished with the pipe symbol, `%>%`, e.g. to find all scripts in `./Scripts` that contain the text `text_to_match`:

```R
ls_scripts("./Scripts") %>% search_raw("text_to_match")
```

To find all scripts in the **Code Library** that contain the text `text_to_match`:

```R
ls_code_library() %>% search_raw("text_to_match")
```

### Monitor your compliance

Check your tidyproject is set up correctly by typing the following:

```R
check_session()
```

It complains about Renvironment_info.txt not being present. Take an snapshot of your R environment:

```R
environment_info()
```

This will search your scripts in your "Scripts" directory for package dependencies and output version and environment information into Renvironment_info.txt of the main directory.  If you run `check_session()` again it should pass now.  If tidyproject ever gives you errors, `check_session()` is a good first port of call.


# FAQ

### + How do I disable the ProjectLibrary

The ProjectLibrary is configured inside `.Rprofile`.  Deleting this or deleting its contents will disable the ProjectLibrary.


