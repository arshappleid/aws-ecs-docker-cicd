#!/bin/bash

#   Usage
#  ./create_github_action_iam_role.sh GITHUB_REPO_URL BRANCH=*
#
#   Creates the IAM role required for the CICD Pipeline, to automatically
#   create the role with access to Create ECR repo (if does not exist), Create a 
#   new Image within the registry, Create new Task Definition, Update the ECS Service
#   with a new task deployment. 
# 
#   Note : This creates an IAM role with overly provisioned access to all the actions in 
#   in the above AWS Service. This allows to use the same role for multiple Services or 
#   Clusters, although access for different github repos will need to be configured. 
#   This does not fall in-line with the least privelege access requirements and therefore 
#   should be revised in production environments. 
#  
#
#   
#