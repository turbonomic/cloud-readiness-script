#!/bin/bash
#version 1.1.0

#Set initial variables
aws_output_file="aws_checked_urls.csv"
azure_output_file="azure_checked_urls.csv"
usage="Usage: $0 -a | -z [--proxy <IP or Hostname:port>] [--proxy-user <username>:<password>] [--awsfile <filename>] [--azurefile <filename>]"
check_urls=0
curl_cmd="curl -svi"

#List of Amazon Regions
declare -a AWS_regions_list=("us-east-2" "us-east-1" "us-west-1" "us-west-2" "af-south-1" "ap-east-1" "ap-south-1" "ap-northeast-3" "ap-northeast-2" #
"ap-southeast-1" "ap-southeast-2" "ap-northeast-1" "ca-central-1" "cn-north-1" "cn-northwest-1" "eu-central-1" "eu-west-1" "eu-west-2" #
"eu-south-1" "eu-west-3" "eu-north-1" "me-south-1" "sa-east-1" "us-gov-east-1" "us-gov-west-1")

#List of Amazon URLs the should exist per region
declare -a AWS_url_list=("s3.replace.amazonaws.com" "monitoring.replace.amazonaws.com" "events.replace.amazonaws.com" #
"logs.replace.amazonaws.com" "ec2.replace.amazonaws.com" "elasticloadbalancing.replace.amazonaws.com" #
"organizations.replace.amazonaws.com" "rds.replace.amazonaws.com" "resource-groups.replace.amazonaws.com" #
"servicecatalog.replace.amazonaws.com" "storagegateway.replace.amazonaws.com" "autoscaling.replace.amazonaws.com")

#List of One off Amazon web sites
declare -a single__AWS_urls=("api.pricing.us-east-1.amazonaws.com" "iam.amazonaws.com")

#List of One off Azure web sites
declare -a single__azure_urls=("ratecard.azure-api.net" "management.core.windows.net" "management.azure.com" "login.microsoftonline.com")

ValidIpAddressRegex="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]):[0-9]{1,5}$";
ValidHostnameRegex="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]):[0-9]{1,5}$";

#Function to cycle through AWS required URLs and Regions
run_aws () {
    for region in "${AWS_regions_list[@]}"
    do 
        for site in "${AWS_url_list[@]}"
        do
            result=`${curl_cmd} "https://${site/replace/$region}" 2>&1 |sed -e '/resolve/b' -e '/issuer/b' -e '/Failed/b' -e d |sed -e 's/^[* ]*//'`
            if [[ $result != *"issuer"* ]]; then 
              echo "${site/replace/$region}, $result"
            fi
        echo "${site/replace/$region}, $result" >> "$aws_output_file"
        done
    done
}

#Cycle through all one-off AWS URLs
run_aws_one_off () {
    for site in "${single__AWS_urls[@]}"
    do 
        result=`${curl_cmd} "https://${site}" 2>&1 |sed -e '/resolve/b' -e '/issuer/b' -e '/Failed/b' -e d |sed -e 's/^[* ]*//'`
        if [[ $result != *"issuer"* ]]; then 
          echo "${site/replace/$region}, $result"
        fi
        echo "${site/replace/$region}, $result" >> "$aws_output_file"
    done
}

#Cycle through all one-off Azure URLs
run_azure_one_off () {
    for site in "${single__azure_urls[@]}"
    do 
        result=`${curl_cmd} "https://${site}" 2>&1 |sed -e '/resolve/b' -e '/issuer/b' -e '/Failed/b' -e d |sed -e 's/^[* ]*//'`
        if [[ $result != *"issuer"* ]]; then 
          echo "${site/replace/$region}, $result"
        fi
        echo "${site/replace/$region}, $result" >> "$azure_output_file"
    done
}

#Check that parameters were specified
if [ $# == 0 ]; then
    echo "$0: require Parameters Missing"
    echo "$usage"
    exit 1
fi

#Loop through parameters
while [ "$1" != "" ]; do
    case "$1" in
        -a | --aws )            check_urls=$(( $check_urls + 1 ))
                                ;;
        -z | --azure )          check_urls=$(( $check_urls + 2 ))
                                ;;
        --awsfile )        if [[ ! -z "$2" ]] && [[ "$2" =~ ^[a-zA-Z0-9_+]{3,10}\.[a-zA-Z]{3}$ ]]; 
                                then 
                                    aws_output_file="$2" 
                                else 
                                    echo 'Unsupported filename: Name must be contain three characters plus a valid extension'
                                    echo "$usage"
                                    exit 1
                                fi
                                echo "Saving AWS results to ${aws_output_file}"
                                shift
                                ;;
        --azurefile )      if [[ ! -z "$2" ]] && [[ "$2" =~ ^[a-zA-Z0-9_+]{3,10}\.[a-zA-Z]{3}$ ]]; 
                                then 
                                    azure_output_file="$2" 
                                else 
                                    echo 'Unsupported filename: Name must be contain three characters plus a valid extension'
                                    echo "$usage"
                                    exit 1
                                fi
                                echo "Saving Azure results to ${azure_output_file}"
                                shift
                                ;;
        -p | --proxy )      if [[ ! -z "$2" ]] && [[ "$2" =~ $ValidIpAddressRegex || "$2" =~ $ValidHostnameRegex ]]; 
                                then
                                    curl_cmd+=" -x $2"
                                else 
                                    echo 'Proxy Server not valid: Enter an IP or Hostname with the port separated by a colon'
                                    echo "$usage"
                                    exit 1
                                fi
                                shift
                                ;;
        -U | --proxy-user )      if [[ ! -z "$2" ]] && [[ "$2" =~ ^.{3,}:.{3,}$ ]]; 
                                then
                                    curl_cmd+=" -U $2"
                                else 
                                    echo 'Format of proxy username and password not valid: user <username:password>'
                                    echo "$usage"
                                    exit 1
                                fi
                                shift
                                ;;                                    
        -h | --help )           echo "$usage"
                                echo 'Options: '
                                echo ' -a, --aws            Test AWS URLs'
                                echo ' -z, --azure          Test Azurl URLs'
                                echo ' -p, --proxy          Specify proxy server with port'
                                echo ' -U, --proxy-user     Specify proxy server user and password'
                                echo ' --awsfile            Specify AWS output file'
                                echo ' --azurefile          Specify Azure output file'
                                exit
                                ;;
        * )                     echo "$0: illegal option -- $1"
                                echo "$usage"
                                exit 1
    esac
    shift
done

curl_cmd+=" -X GET"
echo $curl_cmd
#exit

#Main Execution of script
if [ "$check_urls" -eq 1 ]
then
    echo -e 'Validating AWS URLs\n'
    echo 'URL Checked, Result' > "$aws_output_file"
    run_aws 
    run_aws_one_off 
elif [ "$check_urls" -eq 2 ]
then
    echo -e 'Validating Azure URLs\n'
    echo 'URL Checked, Result' > "$azure_output_file"
    run_azure_one_off 
elif [ "$check_urls" -eq 3 ]
then
    echo 'Validating Cloud Providers'
    echo -e '\nValidating AWS URLs\n'
    echo 'URL Checked, Result' > "$aws_output_file"
    run_aws
    run_aws_one_off 
    echo -e '\nValidating Azure URLs\n'
    echo 'URL Checked, Result' > "$azure_output_file"
    run_azure_one_off
elif [ "$check_urls" -eq 0 ]
then
    echo 'Please specify at least one cloud provider to check'
    echo "$usage"
    exit
fi

echo 'Cloud Readiness Script Completed!'