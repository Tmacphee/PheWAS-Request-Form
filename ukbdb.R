
library(rJava)
library(RJDBC)

# Download driver file (if needed) to current directory 

URL <-  'https://s3.amazonaws.com/athena-downloads/drivers/JDBC/SimbaAthenaJDBC_2.0.2/AthenaJDBC41_2.0.2.jar'
fil <- basename(URL)
if (!file.exists(fil)) download.file(URL, fil, mode = 'wb')

athena_driver = JDBC(driverClass = "com.simba.athena.jdbc.Driver",
                     'AthenaJDBC41_2.0.2.jar',
                     identifier.quote = "'")

get_athena_conn = function(schema = 'ukbiobank-phewas') {
  
  cat("connecting")
  con <- dbConnect(
    athena_driver,
    'jdbc:awsathena://athena.us-east-1.amazonaws.com:443/',
    s3_staging_dir = "s3://aws-athena-query-results-765426722673-us-east-1",
    user = creds$athena_user,
    password = creds$athena_password,
    schema = creds$schema
  )
  cat("connected")
  return(con)
}

get_targets_proc = function() {
  conn <- get_athena_conn()
  target_query <-
    paste(
      'SELECT DISTINCT target_name FROM linreg_results ',
      'UNION ',
      'SELECT DISTINCT target_name FROM logreg_results ',
      'ORDER BY target_name'
    )
  res <- dbGetQuery(conn, target_query)
  dbDisconnect(conn)
  return(res)
}

addlimit = function(query) {
  limit <- 10000
  query <- paste(query, 'limit', limit, sep = ' ')
  query
}

#Function to retrive logictic regression
get_logreg_results = function(target_name = '',
                              minNegLogP = 3.0) {
  q = paste(
    'SELECT "locus.contig" AS chr, "locus.position" AS pos, alleles, rsid, ',
    'code AS pheno_id, name AS phenotype,categoryid AS "Category ID",categoryname AS "Category Description",n, beta, ',
    '-log10(p_value) AS "-log10p" ',
    'FROM logreg_results, phenotype_names ',
    'WHERE (((logreg_results.code = phenotype_names.fid) ',
    'AND (-log10(p_value) > ',
    minNegLogP,
    ' )) ',
    'AND (target_name = \'',
    target_name,
    '\')) ORDER BY "p_value" ASC',
    sep = ''
  )
  q <- addlimit(q)
  print(q)
  
  conn <- get_athena_conn()
  res <- dbGetQuery(conn, q)
  
  print(paste("Retrieved results for target ", target_name))
  
  return(res)
  
}

get_linreg_results = function(target_name = '',
                              minNegLogP = 3.0) {
  q = paste(
    'SELECT "locus.contig" AS chr, "locus.position" AS pos, alleles, rsid, ',
    'code AS pheno_id, name AS phenotype,categoryid AS "Category ID",categoryname AS "Category Description", n, beta, ',
    '-log10(p_value) AS "-log10p" ',
    'FROM linreg_results, phenotype_names ',
    'WHERE (((linreg_results.code = phenotype_names.fid) ',
    'AND (-log10(p_value) > ',
    minNegLogP,
    ' )) ',
    'AND (target_name = \'',
    target_name,
    '\')) ORDER BY "p_value" ASC',
    sep = ''
  )
  q <- addlimit(q)
  print(q)
  
  conn <- get_athena_conn()
  res <- dbGetQuery(conn, q)
  
  print(paste("Retrieved results for target ", target_name))
  
  return(res)
  
}
