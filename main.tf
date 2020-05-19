provider "azurerm" {
    version = "~>2.0.0"
    features {
    }
}

provider "random" {
    version = "~> 2.1"
}

terraform {
    backend "azurerm" {
        key = "ifa.terraform.tfstate"
    }
}
