provider "aws" {
    alias = "awsmain"
    region = "us-east-1"
    profile = "account1"
}

provider "aws" {
    alias = "awsaccount2"
    region = "us-east-1"
    profile = "account2"
}

provider "aws" {
    alias = "awsaccount3"
    region = "us-east-1"
    profile = "account3"
}

###### Adding provider until account3