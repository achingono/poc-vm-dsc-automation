while getopts n:l:c:u:p:v: flag
do
    case "${flag}" in
        n) NAME=${OPTARG};;
        l) LOCATION=${OPTARG};;
        c) CODE=${OPTARG};;
        u) USERNAME=${OPTARG};;
        p) PASSWORD=${OPTARG};;
        v) VERSION=${OPTARG};;
    esac
done

if [ "$NAME" == "" ] || [ "$LOCATION" == "" ] || [ "$CODE" == "" ] || [ "$USERNAME" == "" ] || [ "$PASSWORD" == "" ]; then
 echo "Syntax: $0 -n <name> -l <location> -c <unique code> -u <admin username> -p <admin password>"
 exit 1;
elif [[ $CODE =~ [^a-zA-Z0-9] ]]; then
 echo "Unique code must contain ONLY letters and numbers. No special characters."
 echo "Syntax: $0 -n <name> -l <location> -c <unique code> -u <admin username> -p <admin password>"
 exit 1;
fi

SECONDS=0
echo "Start time: $(date)"

RESOURCE_GROUP=rg-$NAME-$CODE-$LOCATION
STORAGE_ACCOUNT=$(echo "stg$NAME$CODE"  | tr -d -c 'a-z0-9')
CONFIG_CONTAINER=configurations
DEPLOY_CONTAINER=deployments
VIRTUAL_MACHINE=vm-$NAME-$CODE

# create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# create storage account
az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS

# Create blob containers if they do not exist
az storage container create \
    --account-name $STORAGE_ACCOUNT \
    --name $CONFIG_CONTAINER \
    --public-access off

az storage container create \
    --account-name $STORAGE_ACCOUNT \
    --name $DEPLOY_CONTAINER \
    --public-access off        

# upload server configuration package to storage account
az storage blob upload \
    --account-name $STORAGE_ACCOUNT \
    --container-name $CONFIG_CONTAINER \
    --name ServerConfiguration-v$VERSION.zip \
    --file ./artifacts/ServerConfiguration.zip \
    --overwrite

# upload web deploy package to storage account
az storage blob upload \
    --account-name $STORAGE_ACCOUNT \
    --container-name $DEPLOY_CONTAINER \
    --name WebDeploy-v$VERSION.zip \
    --file ./artifacts/WebDeploy.zip \
    --overwrite

# remove invalid characters from storage account
az vm extension delete --resource-group $RESOURCE_GROUP --vm-name $VIRTUAL_MACHINE --name Microsoft.Powershell.DSC

# provision infrastructure
az deployment sub create \
    --name $NAME \
    --location $LOCATION \
    --template-file ./iac/main.bicep \
    --parameters name=$NAME \
                location=$LOCATION \
                uniqueSuffix=$CODE \
                adminUsername=$USERNAME \
                adminPassword=$PASSWORD \
                version=$VERSION

duration=$SECONDS
echo "End time: $(date)"
echo "$(($duration / 3600)) hours, $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."