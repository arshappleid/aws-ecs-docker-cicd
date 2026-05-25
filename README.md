# Github Actions Pipeline to Automate Deployment and Testing
This pipeline automates building of source code, Unit Testing, Deployment of Code to ECS Clusters, and API Testing with Bruno. 

## Explanation of Each Step

### Build 
Build The source Code, errors detected here will be compilation errors. 

### Unit Testing
Run unit test using python's pytest library to test routers, service functions with aws infrastructure, using python's [moto](https://docs.getmoto.org/en/latest/docs/getting_started.html#decorator) library. 

### Deployment
Deploy new code changes to production environment, using blue green deployment with aws.

### API Testing
Perform End to End Testing (to verify user experience), experienced on your application. 


