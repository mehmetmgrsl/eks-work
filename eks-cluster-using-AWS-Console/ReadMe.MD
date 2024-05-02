# WIP

### The needed IAM Roles
- EKS worker nodegroup role needs to have the three policies below:
  - AmazonEC2ContainerRegistryReadOnly
  - AmazonEKS_CNI_Policy
  - AmazonEKSWorkerNodePolicy


aws eks --region eu-central-1 update-kubeconfig --name eks-test
