library(httr)
apiKey <- "ncTchuT82S2QnuquJXn7WQm7vyQEwlGN"
result <- GET("http://10.245.43.138:3939/__api__/v1/users?prefix=rov6269",
              add_headers(Authorization = paste("Key", apiKey)))
print(content(result, as = "parsed"))
