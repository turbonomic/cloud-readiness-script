# cloud-readiness-script

This script will check access to various AWS and/or Azure URLs to validate access to the cloud from the source machine.  It 
will not only check access to the URL, but also checks who issued the certificate.  Failed URLs will output to the screen 
and all URLs will be written to csv files for review.


#### Usage: ./cloud_readiness_script.sh -a | -z [--proxy <IP or Hostname:port>] [--proxy-user <username>:<password>] [--awsfile <filename>] [--azurefile <filename>]
```
-a, --aws                     Check AWS URLs

-z, --azure                   Check Azure URLs

-p, --proxy                   Specify proxy server with port

-U, --proxy-user              Specify proxy server user and password

--awsfile <filename>          Specify different csv output file for AWS (default aws_checked_urls.csv)
  
--azurefile <filename>        Specify different csv output file for AWS (default aws_checked_urls.csv)
  ```
**Note:** Some AWS URLs will fail by design as not every service exists in every AWS region
