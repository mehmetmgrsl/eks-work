## 1. Why EKS?

- When you want to deploy and manage containerized applications using Kubernetes without dealing with the complexity of maintaining the control plane then you can use EKS (Elastic Kubernetes Service -> AWS managed service).

- It's beneficial when you need efficient scaling, high availability, seamless integration with AWS services, and enhanced security.



## 2. Installation

### 2.1. Precondition

- kubectl
- eksctl
- aws cli

### 2.2. Create a cluster

```eksctl create cluster --name eks-cluster --region eu-north-1 --fargate```

### 2.3. Create a Fargate profile

```
eksctl create fargateprofile \
    --cluster eks-cluster \
    --region eu-north-1 \
    --name alb-sample-app \
    --namespace game-2048
```

### 2.4. Deploy the application and service and Ingress

```kubectl apply -f 2048_full.yaml```


### 2.5. Configure IAM OIDC provider

- ```export cluster_name=eks-cluster```

- ```oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)``` 

- Check if there is an IAM OIDC provider configured already
  -  ```aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4```

  If not, run the below command
  - ```eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve```

### 2.6. Setup alb

- Create IAM Policy

```
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
```

- Create IAM Role

```
eksctl create iamserviceaccount \
  --cluster=eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::<your-aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

- Add the helm repo for eks-charts

```helm repo add eks https://aws.github.io/eks-charts```

- Install AWS Load Balancer Controller

```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName=eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=eu-north-1 \
  --set vpcId=<vpc-id>
```

### 2.7. Access the app

 ```kubectl get ingress -n game-2048``` # get the \<ADDRESS\>

Open a browser and try to access -> http://ADDRESS


### 2.8. Uninstalling the Chart

```eksctl delete iamserviceaccount --cluster eks-cluster --namespace kube-system --name aws-load-balancer-controller```


### 2.9. Delete the cluster

``eksctl delete cluster --name eks-cluster --region eu-north-1``





### Resources

- [Amazon Elastic Kubernetes Service](https://aws.amazon.com/eks/)
- [Ultimate AWS DevOps Project on EKS - Abhishek Veeramalla](https://www.youtube.com/watch?v=RRCrY12VY_s)
- [How do I set up the AWS Load Balancer Controller on an Amazon EKS cluster for Fargate and deploy the 2048 game](https://repost.aws/knowledge-center/eks-alb-ingress-controller-fargate)
- [AWS Load Balancer Controller](https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller)