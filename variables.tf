variable "location" {
    type = string
    description = "Azure location"
    // one of ( as for Dec 8 2020 : 
    /*
     'eastus, eastus2, westus, centralus, northcentralus, southcentralus, northeurope, westeurope,
     eastasia, southeastasia, japaneast, japanwest, australiaeast, australiasoutheast, australiacentral,
     brazilsouth, southindia, centralindia, westindia, canadacentral, canadaeast, westus2, 
     westcentralus, uksouth, ukwest, koreacentral, koreasouth, francecentral, southafricanorth, 
     uaenorth, switzerlandnorth, germanywestcentral, norwayeast'. 
    */
}


variable "admin_username" {
    type = string
    description = "Administrator user name for virtual machine"
}

variable "admin_password" {
    type = string
    description = "Password must meet Azure complexity requirements"
}

