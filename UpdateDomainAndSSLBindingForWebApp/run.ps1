using namespace System.Net



# Input bindings are passed in via param block.

param($Request, $TriggerMetadata)

$status =$Null

$body =$Null

$Errorr= $Null #named Errorr due to Error is reserved by the system


# Interact with query parameters or the body of the request.

$webAppName = $Request.Body.webAppName

$customDomain = $Request.Body.customDomain

$slot = $Request.Body.env

$resourceGroupName = $Request.Body.resourceGroupName

$sslThumbprint = $Request.Body.sslThumbprint



Import-Module Az.Accounts

import-Module Az.Websites



#Login into portal
Connect-AzAccount -Identity  
 

# Write to the Azure Functions log stream.

Write-Host "PowerShell HTTP trigger function processed a request."

#Since this errorr variable is $Null, this will retrieve an exception

#$errorr.Clear() 



#---start: Automatize by Dorian Vallecillo Calderon (v-dovall@microsoft.com) ----------

$webapp= Get-AzWebApp -Name $webAppName

$domains = $webapp.EnabledHostNames | Out-String

$domains = $domains + $customDomain

$domains = -split $domains

$customdomains=@()



foreach ($domain in $domains){

  if(!($domain.Contains("scm.azurewebsites.net"))){

    $customdomains=$customdomains + $domain

   }

}



$customdomains = -split $customdomains

#---end: MS code recommended ----------



if ($ResourceGroupName -and $webAppName -and $customDomain){

  if($slot){

    set-AzContext -Subscription "subscriptionID" #edit this line
    Write-Host "PowerShell: slot"

    Set-AzWebAppslot -Slot $slot -Name $webAppName -ResourceGroupName $resourceGroupName -HostNames $customdomains

    New-AzWebAppSSLBinding -Slot $slot  -ResourceGroupName $resourceGroupName -WebAppName $webAppName -Thumbprint $sslThumbprint -Name $customDomain

    Write-Host "PowerShell: slot"

  }

  else{
      set-AzContext -Subscription "subscriptionID" #edit this line
     Write-Host "PowerShell: production"

     Set-AzWebApp -Name $webAppName -ResourceGroupName $resourceGroupName -HostNames $customdomains

     New-AzWebAppSSLBinding -ResourceGroupName $resourceGroupName -WebAppName $webAppName -Thumbprint $sslThumbprint -Name $customDomain

     Write-Host "PowerShell: production"

  }

  If($Null -ne $Errorr){

     $status = [HttpStatusCode]::InternalServerError

     $body = "An error occurred | $ResourceGroupName | $webAppName |  $customDomain | $slot | $Errorr " 

   }

  else{

     $status = [HttpStatusCode]::ok

     $body = "Created | $ResourceGroupName | $webAppName |  $customDomain | $slot "

   }

}

else {

    $status = [HttpStatusCode]::BadRequest

    $body = "Bad Request | invalid input"

}



# Associate values to output bindings by calling 'Push-OutputBinding'.

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{

    StatusCode = $status

    Body = $body

})
