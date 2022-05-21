declare directory='./'
declare profile='default'
declare function=''
declare extension='*.py'
declare skip=''
declare options=$(getopt -l "directory:,profile:,function:,extension:,help" -o "d:p:f:e:yh" -a -- "$@");

function __showHelp() {
    echo "Script to deploy files to AWS Lambda Function";
    echo "";
    echo "Params:";
    echo "-h, --help           Display this help message";
    echo "-d, --directory      Directory with files to deploy, default is \"./\"";
    echo "-p, --profile        AWS profile, if none get \"default\"";
    echo "-f, --function       AWS function name";
    echo "-e, --extension      Extension from files to deploy, default is \"*.py\"";
    echo "-y                   Skip confirmation message";
    exit 0;
}


function __readParams() {
    eval set -- "$options";
    
    while true; do
        case $1 in
            -d|--directory)
                shift
                directory=$1;
            ;;
            -p|--profile)
                shift
                profile=$1;
            ;;
            -f|--function)
                shift
                function=$1;
            ;;
            -e|--extension)
                shift
                extension=$1;
            ;;
            -h|--help)
                __showHelp;
            ;;
            -y)
                skip=1
            ;;
            --)
                shift
            break;;
        esac
        shift
    done;
}


function __getFunctionName() {
    if [ -z "$function" ]; then
        __readFunctionName;
    fi;
}


function __readFunctionName() {
    read -p "Function to deploy: " function;
}


function __getConfirmation() {
    if [ -z "$skip" ]; then
        __readConfirmation
        local confirm=$?
        if [ "$confirm" = 1 ]; then
            __deployFunction;
        else
            __exitDeploy;
        fi;
    fi;
}


function __readConfirmation() {
    echo "Selected function \"${function}\" to deploy in AWS profile \"${profile}\"";
    read -p "Please, confirm this action (Y/n): " confirm;
    if [ $confirm == 'y' ] || [ $confirm == 'Y' ]; then
        return 1;
    else
        return 0;
    fi
}


function __deployFunction() {
    echo "Start deploy to function \"${function}\" in AWS profile \"${profile}\"...";
    __zipFiles;
    __uploadFilesToAWS;
    __deleteDeployFiles;
}


function __zipFiles() {
    echo "Add ${extension} files to zip";
    zip ${function}.zip ${extension};
}


function __uploadFilesToAWS() {
    echo "Upload files to AWS Lambda \"${function}\"";
    aws lambda update-function-code --function-name ${function} --zip-file fileb://${function}.zip --profile ${profile};
}


function __deleteDeployFiles() {
    echo "Remove deploy files";
    rm ${function}.zip;
}

function __exitDeploy() {
    echo "Deploy canceled!";
    exit 0;
}

__readParams;
__getFunctionName;
__getConfirmation;