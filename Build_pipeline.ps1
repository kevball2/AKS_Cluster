    ## Get your subscription ID
    $sub = az account show | ConvertFrom-Json

    #set the name of the Azure Keyvault you created in the previous step to retrieve the AKS secrets
    $AzureKeyVault = "nobs1"

    ## Ensure the DevOps extension is available
    az extension add --name azure-devops

    ## Set this value to the URL of your Azure Devops site Example: https://dev.azure.com/NoBSDevOps
    $organization = "https://technicalpanda.visualstudio.com"

    ## Ensure the service endpoint command creates the service connection in the right project
    az devops configure --defaults project=NoBS_AKS_Cluster organization=$organization

    ## Create the project
    az devops project create --name "NoBS_AKS_Cluster"


    
        ## Test if the $sp object from creating the service principal in the previous steps still exists
        if ($null -ne $sp)
        {
            ## Run $sp.password and copy it to the clipboard
            $sp.clientSecret
            ## create the service endpoint. Paste the value of $sp.Password here returned earlier.
            ## use this command if the earlier $sp object used to create the Service Principal still exists
            $armEndpoint = az devops service-endpoint azurerm create --azure-rm-service-principal-id $sp.clientId --azure-rm-subscription-id $sub.id --azure-rm-subscription-name $sub.name --azure-rm-tenant-id $sub.tenantId --name 'ARM' | ConvertFrom-Json

        }
        if($null -eq $sp)
        {
             
             ## If you needed to gather the secrets again use these commands
             $clientId = az keyvault secret show --vault-name $AzureKeyVault --name 'AKSClientId' | ConvertFrom-Json | Select-Object value
             $clientSecret = az keyvault secret show --vault-name $AzureKeyVault --name 'AKSClientSecret' | ConvertFrom-Json | Select-Object value
             $clientSecret.value
 
             ## create the service endpoint. Paste the value of $clientSecret.value here returned earlier when the password is requested.
             $armEndpoint = az devops service-endpoint azurerm create --azure-rm-service-principal-id $($clientId.value) --azure-rm-subscription-id $sub.id --azure-rm-subscription-name $sub.name --azure-rm-tenant-id $sub.tenantId --name 'ARM' | ConvertFrom-Json
 
        } 
    
    az devops service-endpoint update --id $armEndpoint.id --enable-for-all
    ## Alow the pipeline to access the key vault
    az keyvault set-policy --name $AzureKeyVault --spn http://nobsapp --secret-permissions get list

    ## Define the URL to your forked repo
    $repoUrl = 'https://github.com/kevball2/AKS_Cluster'
    # $repoUrl = 'https://github.com/NoBSDevOps/AKS_Cluster'

    ## Create a GitHub service endpoint for the pipeline to connect to the GitHub repo
    $gitHubServiceEndpoint = az devops service-endpoint github create --github-url $repoUrl --name 'GitHub' | ConvertFrom-Json
    ## paste in the GitHub token when prompted 

    ## Create the pipeline linked to your forked repo of the book's example repo
    az pipelines create --name "AKS_Cluster" --repository $repoUrl --branch main --service-connection $gitHubServiceEndpoint.id --skip-run

    ## When prompted, choose 1 and 1 for using the existing pipeline
