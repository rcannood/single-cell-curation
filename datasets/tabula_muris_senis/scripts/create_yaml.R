# Create cellxgene schema yaml file


library("yaml")

main <- function(cmdArgs=commandArgs(T)) {
    
    lookup_table_files <- cmdArgs[-length(cmdArgs)]
    out_file <- cmdArgs[length(cmdArgs)]
    
    #cell_type_file <- '../data/misc/ontology_lookup_cell_type.tsv'
    
    # Create backbone of the yml with manual values
    yaml_final <- make_yaml_list()
    
    # Read suggested term tables
    lookup_tables <- lapply(lookup_table_files, read.table, sep='\t', stringsAsFactors=F, header=T)
    
    # Verify there's only on ontology term per item and convert to list
    lookup_tables <- lapply(lookup_tables, lookup_table_to_list)
    
    # Appending to yaml
    for (i in lookup_tables) 
        yaml_final$obs <- c(yaml_final$obs, i)
                        
    yaml_final <- as.yaml(yaml_final)
    
    # Eliminate single quotes in numbers
    #yaml_final <- gsub("\\'(\\d+)\\'", "\\1", yaml_final)
    
    writeLines(yaml_final, out_file)
    
}


#' Creates backbone of yaml
make_yaml_list <- function() {
    
    x <- list(
         #fixup_gene_symbols = list(X = "log1p", raw.X = "raw"),
         obs = list(assay_ontology_term_id = "EFO:0009899",
                    ethnicity_ontology_term_id = "na",
                    #sex = list(sex = list(M='male', F='female')),
                    disease_ontology_term_id =  'PATO:0000461'
                    ),
         
         uns = list(version = list(corpora_schema_version="1.1.0", corpora_encoding_version="0.1.0"),
                    organism = "Mus musculus", 
                    organism_ontology_term_id = "NCBITaxon:10090",
                    layer_descriptions = list(X = "log(counts_per_thousand+1)", raw.X = "raw"), 
                    publication_doi = "https://doi.org/10.1038/s41586-020-2496-1", 
                    title = paste("A single-cell transcriptomic atlas characterizes ageing tissues in the mouse")
                    )
         )
    
    x
}
    


#' Takes the look up table and keeps the selected terms, throws an error if there's more than selected ontology terms per item
lookup_table_to_list <- function(x) {
    
    #if(! all(x[, 5, drop = T] %in% c('True', 'False')))
    #    stop('Column five from look up tables can only be "True" or "False"')
    
    x$final <- ifelse(x$final == 'True', T, F)
    
    validate_lookup_table(x)
    
    x <- x[x$final, ]
    type <- x$type[1]
    orignal_column <- colnames(x)[1]
    
    results  <- setNames(x[, 3, drop = T], x[, 1, drop = T])
    results <- list(list(as.list(results)))
    #browser()
    names(results) <- paste0(type, '_ontology_term_id')
    names(results[[1]]) <- orignal_column
    
    return(results)
    
}

validate_lookup_table <- function(x) {
    
    tallies <- tapply(x$final, x[,1,drop = T], sum)
    
    if(any(tallies!=1)){
        incorrect <- names(tallies[tallies!=1])
        stop("Lookup table error: The following categories don't have exactly one ontology selected", paste(incorrect, collapse = ", "))
    }
    
    if(length(unique(x$type)) > 1) {
        stop("Lookup table error: only one type per table is allowed, I found these multiple types: ", paste(unique(x$type), collapse=", "))
    }
}

main()
