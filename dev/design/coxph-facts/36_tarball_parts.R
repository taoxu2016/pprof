# CoxPH C6 plan, §2.1: where the package tarball's bytes go, and what could make room for the C6
# documentation under the 5,000,000 bytes at which `R CMD check --as-cran` notes the tarball's size.
# For each tarball given: its size, each file's size and gzip-compressed size (memCompress, which
# approximates the file's share of the .tar.gz, one gzip stream) summed by directory, the largest
# files, and the built vignettes with the PNG images embedded in them. Then the bundled data files'
# compression and their sizes resaved with gzip, bzip2, and xz (tools::resaveRdaFiles() on copies;
# data/ is not touched), and one plot of the getting-started vignette at 96 and 72 dpi.
# Run from the repository root:
#   Rscript dev/design/coxph-facts/36_tarball_parts.R <output file> <tarball> [<tarball> ...]
# The tarballs, each in a directory of its own, whose name heads its section: `R CMD build <repository>` in
# build/, and `R CMD build --resave-data=best <repository>` in build-best/. The plot uses an installed pprof
# from the library PPROF_FACTS_LIB when it is set, and devtools::load_all() otherwise.
args <- commandArgs(trailingOnly = TRUE)
out_file <- args[[1]]
tarballs <- args[-1]
out <- character()
say <- function(...) {
  out <<- c(out, paste0(...))
  writeLines(out, out_file)
}
gz_size <- function(path) length(memCompress(readBin(path, "raw", file.size(path)), type = "gzip"))

for (tarball in tarballs) {
  dir <- file.path(tempdir(), basename(dirname(normalizePath(tarball))))
  unlink(dir, recursive = TRUE)
  dir.create(dir)
  utils::untar(tarball, exdir = dir)
  files <- list.files(dir, recursive = TRUE, all.files = TRUE)
  info <- data.frame(file = files, size = file.size(file.path(dir, files)), stringsAsFactors = FALSE)
  info$gz <- vapply(file.path(dir, files), gz_size, numeric(1))
  info$group <- vapply(strsplit(info$file, "/", fixed = TRUE), function(p) {
    if (length(p) <= 2) return("(top level)")
    if (p[[2]] == "tests" && length(p) >= 5) return(paste(p[2:min(5, length(p) - 1)], collapse = "/"))
    paste(p[2:min(3, length(p) - 1)], collapse = "/")
  }, "")
  groups <- aggregate(cbind(size, gz) ~ group, info, sum)
  groups <- groups[order(-groups$gz), ]
  say("## ", basename(dirname(normalizePath(tarball))), "/", basename(tarball))
  say("")
  say(sprintf("%d bytes, %d under 5,000,000; %d files, %d bytes unpacked, %d bytes gzip-compressed file by file",
              file.size(tarball), 5e6 - file.size(tarball), nrow(info), sum(info$size), sum(info$gz)))
  say("")
  say(sprintf("%-40s %10s %10s", "directory", "bytes", "gzip"))
  for (k in seq_len(nrow(groups))) say(sprintf("%-40s %10d %10d", groups$group[k], groups$size[k], groups$gz[k]))
  say("")
  say("Largest files (gzip bytes):")
  top <- info[order(-info$gz), ][1:12, ]
  for (k in seq_len(nrow(top))) say(sprintf("  %-70s %9d %9d", top$file[k], top$size[k], top$gz[k]))
  say("")
  say("Built vignettes: embedded PNG images and the rest of the page (bytes, and gzip-compressed):")
  for (f in list.files(file.path(dir, "pprof", "inst", "doc"), pattern = "html$", full.names = TRUE)) {
    x <- paste(readLines(f, warn = FALSE), collapse = "\n")
    m <- gregexpr("data:image/png;base64,[A-Za-z0-9+/=]+", x)[[1]]
    images <- if (m[1] > 0) regmatches(x, list(m))[[1]] else character()
    rest <- x
    for (image in images) rest <- sub(image, "", rest, fixed = TRUE)
    say(sprintf("  %-26s %d images, %6d (%6d); rest %6d (%6d)", basename(f), length(images), sum(nchar(images)),
                if (length(images)) length(memCompress(charToRaw(paste(images, collapse = "")), "gzip")) else 0L,
                nchar(rest, "bytes"), length(memCompress(charToRaw(rest), "gzip"))))
  }
  say("")
}

say("## The bundled data")
say("")
check <- tools::checkRdaFiles("data")
for (k in seq_len(nrow(check))) say(sprintf("%-28s %7d bytes, %s", rownames(check)[k], check$size[k], check$compress[k]))
copies <- file.path(tempdir(), "rda")
for (type in c("gzip", "bzip2", "xz")) {
  unlink(copies, recursive = TRUE)
  dir.create(copies)
  file.copy(list.files("data", full.names = TRUE), copies)
  tools::resaveRdaFiles(copies, compress = type, compression_level = 9)
  sizes <- file.size(list.files(copies, full.names = TRUE))
  say(sprintf("resaved with %-5s: %s; %d in all", type,
              paste(sprintf("%s %d", basename(list.files(copies)), sizes), collapse = ", "), sum(sizes)))
  objects <- vapply(list.files(copies, full.names = TRUE), function(f) {
    resaved <- new.env()
    original <- new.env()
    load(f, resaved)
    load(file.path("data", basename(f)), original)
    identical(as.list(resaved), as.list(original))
  }, logical(1))
  say(sprintf("  the resaved objects are identical() to the bundled ones: %s", all(objects)))
}
say("")

say("## One plot at two resolutions")
say("")
if (nzchar(Sys.getenv("PPROF_FACTS_LIB"))) {
  .libPaths(c(Sys.getenv("PPROF_FACTS_LIB"), .libPaths()))
  suppressPackageStartupMessages(library(pprof))
} else {
  suppressMessages(devtools::load_all(quiet = TRUE))
}
data(ExampleDataBinary)
example <- data.frame(y = ExampleDataBinary$Y, hospital = ExampleDataBinary$ProvID, ExampleDataBinary$Z)
plot <- plot_funnel(funnel_limits(fit_logistic_fe(y ~ z1 + z2 + z3 + z4 + z5, example, "hospital")))
for (dpi in c(96, 72)) {
  png_file <- tempfile(fileext = ".png")
  grDevices::png(png_file, width = 6, height = 4, units = "in", res = dpi)
  print(plot)
  grDevices::dev.off()
  say(sprintf("The getting-started vignette's funnel plot, 6 by 4 inches at %d dpi: %d bytes", dpi, file.size(png_file)))
}
