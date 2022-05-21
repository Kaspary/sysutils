declare directory='./'
declare app=''
declare key=''
declare options=$(getopt -l "directory:,app:,key:,help" -o "d:a:k:yh" -a -- "$@");


function __showHelp() {
    echo "Script to deploy Heroku project";
    echo "";
    echo "Params:";
    echo "-h, --help           Display this help message";
    echo "-d, --directory      Directory with files to deploy, default is \"./\"";
    echo "-a, --app            Heroku app name";
    echo "-k, --key            Key to Heroku deploy";
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
            -a|--app)
                shift
                app=$1;
            ;;
            -k|--key)
                shift
                key=$1;
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


function __getAppName() {
    if [ -z "$app" ]; then
        __readAppName;
    fi;
}


function __readAppName() {
    read -p "App name to deploy: " app;
}


function __getKey() {
    if [ -z "$key" ]; then
        __readKey;
    fi;
}


function __readKey() {
    read -p "Key to deploy: " key;
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
    echo "Selected app \"${app}\" to deploy";
    read -p "Please, confirm this action (Y/n): " confirm;
    if [ $confirm == 'y' ] || [ $confirm == 'Y' ]; then
        return 1;
    else
        return 0;
    fi
}


function __deployFunction() {
    echo "Start deploy to app \"${app}\"...";
    git push https://heroku:${key}@git.heroku.com/${app}.git HEAD;
}


function __exitDeploy() {
    echo "Deploy canceled!";
    exit 0;
}

__readParams;
__getAppName;
__getKey;
__getConfirmation;