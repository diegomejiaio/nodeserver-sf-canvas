#!/bin/bash

set -e  # Detener el script si ocurre un error

# Variables de configuración
RG="fs-canvas-webapp-01"
APP_NAME="sfcanvaswebapp002"
PLAN_NAME="sf-canvas-linux-plan"
ACR_NAME="sfcanvaswebappcr"
IMAGE_TAG="2.3"
IMAGE_NAME="$ACR_NAME.azurecr.io/sf-canvas-webapp:$IMAGE_TAG"
REGION="eastus2"

# Validate if ARC exists
if ! az acr show --name "$ACR_NAME" --resource-group "$RG" &>/dev/null; then
    echo "❌ Error: El Azure Container Registry '$ACR_NAME' no existe en el grupo de recursos '$RG', crealo manualmente."   # if doesnt exist create it
else
    echo "✅ Azure Container Registry '$ACR_NAME' ya existe."
fi

# Give admin permissions to the ACR
echo "1.1) 🔑 Asignando permisos de administrador al ACR..."
az acr update \
    --name "$ACR_NAME" \
    --admin-enabled true

# Iniciar sesión en Azure Container Registry
echo "2) 🔐 Iniciando sesión en Azure Container Registry... (si acabas de crear el recurso puede fallar)"
az acr login --name "$ACR_NAME"

# Configurar Docker Buildx
echo "3) 🐳 Configurando Docker Buildx..."
docker buildx create --use --name sfcanvas_builder || docker buildx use sfcanvas_builder

# Construir y subir la imagen Docker al ACR
echo "4) 📦 Construyendo y subiendo la imagen Docker..."
docker buildx build --platform linux/amd64 -t "$IMAGE_NAME" . --push

# Verificar que la imagen se ha subido correctamente
echo "5) 🔍 Verificando la imagen en ACR..."
az acr repository show --name "$ACR_NAME" --image "sf-canvas-webapp:$IMAGE_TAG" || {
    echo "❌ Error: La imagen no se ha subido correctamente al ACR."
    exit 1
}

# Crear el App Service Plan si no existe
echo "6) 🛠️ Verificando el App Service Plan..."
az appservice plan show --name "$PLAN_NAME" --resource-group "$RG" &>/dev/null || {
    echo "📄 Creando el App Service Plan..."
    az appservice plan create \
        --name "$PLAN_NAME" \
        --resource-group "$RG" \
        --sku B1 \
        --is-linux
}

# Crear la Web App si no existe
echo "7) 🌐 Verificando la Web App..."
az webapp show --name "$APP_NAME" --resource-group "$RG" &>/dev/null || {
    echo "7.1) 🚀 Creando la Web App..."
    az webapp create \
        --resource-group "$RG" \
        --plan "$PLAN_NAME" \
        --name "$APP_NAME" \
        --runtime "NODE|20-lts"
}

# Habilitar la identidad administrada del sistema
echo "8) 🔐 Habilitando la identidad administrada del sistema..."
PRINCIPAL_ID=$(az webapp identity assign \
    --name "$APP_NAME" \
    --resource-group "$RG" \
    --query principalId \
    --output tsv)

# Asignar el rol AcrPull a la identidad administrada
echo "9) 🔑 Asignando el rol AcrPull a la identidad administrada..."
ACR_ID=$(az acr show --name "$ACR_NAME" --resource-group "$RG" --query id --output tsv)
az role assignment create \
    --assignee "$PRINCIPAL_ID" \
    --scope "$ACR_ID" \
    --role AcrPull \
    --output none

# Esperar a que la asignación de rol se propague
echo "10) ⏳ Esperando la propagación de la asignación de rol..."
sleep 5

# Configurar la Web App para usar la imagen del contenedor
echo "11) 🔄 Configurando la Web App para usar la imagen del contenedor..."
az webapp config container set \
    --name "$APP_NAME" \
    --resource-group "$RG" \
    --container-image-name "$IMAGE_NAME" \
    --container-registry-url "https://$ACR_NAME.azurecr.io"

az webapp config show \
  --name "$APP_NAME" \
  --resource-group "$RG" \
  --query acrUseManagedIdentityCreds

# Configurar la Web App para usar la identidad administrada con ACR
echo "12) 🔐 Configurando la Web App para usar la identidad administrada con ACR..."
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
az resource update \
    --ids "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG/providers/Microsoft.Web/sites/$APP_NAME/config/web" \
    --set properties.acrUseManagedIdentityCreds=true

# Configurar las variables de entorno de la aplicación
echo "13) ⚙️ Configurando las variables de entorno de la aplicación..."
az webapp config appsettings set \
    --resource-group "$RG" \
    --name "$APP_NAME" \
    --settings \
        WEBSITES_PORT=80 \
        WEBSITES_CONTAINER_START_TIME_LIMIT=1800 \
        WEBSITES_ENABLE_APP_SERVICE_STORAGE=false

# Reiniciar la Web App
echo "14) 🔄 Reiniciando la Web App..."
az webapp restart \
    --name "$APP_NAME" \
    --resource-group "$RG"

echo "✅ Despliegue completado. Accede a tu aplicación en: https://$APP_NAME.azurewebsites.net"
echo "El despliegue tarda 40s aproximadamente en estar listo."
sleep 40
echo "Puedes ver los logs de la aplicación con el siguiente comando:"
echo "az webapp log tail --name $APP_NAME --resource-group $RG"

