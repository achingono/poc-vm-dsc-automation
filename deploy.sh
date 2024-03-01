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

# check if storage account key has already been created
STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query [0].value --output tsv)

if [ "$STORAGE_ACCOUNT_KEY" == "" ]; then
    # create storage account
    az storage account create \
        --name $STORAGE_ACCOUNT \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --sku Standard_LRS

    # get storage account key
    STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query [0].value --output tsv)
fi

DEPLOY_CONTAINER_EXISTS=$(az storage container exists --account-name $STORAGE_ACCOUNT --name $DEPLOY_CONTAINER --account-key $STORAGE_ACCOUNT_KEY --output tsv)

if [ "$DEPLOY_CONTAINER_EXISTS" == "False" ]; then
    # Create blob container if it does not exist
    az storage container create \
        --account-name $STORAGE_ACCOUNT \
        --account-key $STORAGE_ACCOUNT_KEY \
        --name $DEPLOY_CONTAINER \
        --public-access off
fi

# check if file has already been uploaded
DEPLOY_FILE_EXISTS=$(az storage blob exists --account-name $STORAGE_ACCOUNT --container-name $DEPLOY_CONTAINER --name WebDeploy-v$VERSION.zip --output tsv)

if [ "$DEPLOY_FILE_EXISTS" == "False" ]; then
    # upload web deploy package to storage account
    az storage blob upload \
        --account-name $STORAGE_ACCOUNT \
        --container-name $DEPLOY_CONTAINER \
        --account-key $STORAGE_ACCOUNT_KEY \
        --name WebDeploy-v$VERSION.zip \
        --file ./artifacts/WebDeploy.zip \
        --overwrite
fi

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
                version=$VERSION \
                decryptionKey=C070562966C21059E353D2821CAB8642380E77F56CAC2EC9B963C32BEC9EBE83 \
                validationKey=966BC38D1918A269803D9E2C4A13F40BEF4B024E

duration=$SECONDS
echo "End time: $(date)"
echo "$(($duration / 3600)) hours, $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."