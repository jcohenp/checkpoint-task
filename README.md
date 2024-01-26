# Checkpoint challenge 

This repository contains 2 Docker microservices in Python built on EKS, S3 bucket, ELB and SQS

## Prerequisites

- **Git**: Cloning the repository and managing the source code.
- **terraform**: Create all your infrastrucure 
- **kubectl**: Communicating with your eks cluster from your local machine 

## Folder Structure:

- **.github/workflows**: all your workflows to build and deploy your microservices 
- **apps/**: Contains microservices to process requests, push it to a queue and write the data on s3 bucket
  - **message_broker**: used for writing post data to a S3 bucket when the SQS queue get a message
    - **Dockerfile**: Instructions to build the docker image
    - **message_broker.py**: python script to listen on the SQS queue and write data to s3 bucket
    - **requirements.txt**: set all necessary dependencies for our message_broker app
  - **processing_requests**: script to install ansible on ubuntu system
    - **Dockerfile**: Instructions to build the docker image
    - **processing_requests.py**: Flask app to process requests and send data to queue
    - **requirements.txt**: set all necessary dependencies for our processing_requests app
- **terraform**: used to set up all infrastructures
    - **main.tf**: used as general main for the terraform, used to run modules 
    - **variables.tf**: used to set up var used in the main.tf file
    - **eks-cluster.tf**: used eks module from hashicorp to set up the module and set permissions to nodes and clusters
    - **kubernetes.tf**: All resources that are necessary (processing_requests and messages_broker)
    - **outputs.tf**: all outputs for the terraform
    - **s3.tf**: Creation of the finla bucket where the message_broker ms will send the data
    - **sqs.tf**: Queue where the processing_requests will send the data
    - **ssm.tf**: Used for storing important variables like s3bucket name, token, sqs endpoint ...
    - **terraform.tf**: Initialized all necessaries providers
    - **vpc.tf**: VPC where our infrastrucre will be deployed


### Configuration:

1. **Clone this repository:**

    ```
    git clone https://github.com/jcohenp/checkpoint-assignment.git
    ```
    
2. **move to the terraform repository**:
    ```
    cd terraform
    ``` 
3. **Initialized the terraform repos:**

    ```
    terraform init
    ```

4. **create a plan:**

    ```
    terraform plan
    ```
    
5. **apply your change:**
    ```
    terraform apply --auto-approve
    ```

6. **Check if your eks environment is set properly**
    
    **kubectl get all -A**
    ```
    NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
    default       pod/messagesbroker-64fc8df4b8-f49zd       1/1     Running   0          22m
    default       pod/processingrequests-6b59464c67-jgcvt   1/1     Running   0          22m
    kube-system   pod/aws-node-74sbd                        2/2     Running   0          24m
    kube-system   pod/aws-node-m2qsh                        2/2     Running   0          23m
    kube-system   pod/aws-node-rkrvz                        2/2     Running   0          24m
    kube-system   pod/coredns-86969bccb4-9pxpp              1/1     Running   0          22m
    kube-system   pod/coredns-86969bccb4-sc9z4              1/1     Running   0          21m
    kube-system   pod/kube-proxy-648zx                      1/1     Running   0          24m
    kube-system   pod/kube-proxy-6r8mn                      1/1     Running   0          24m
    kube-system   pod/kube-proxy-dm865                      1/1     Running   0          23m
    
    NAMESPACE     NAME                            TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)          AGE
    default       service/kubernetes              ClusterIP      172.20.0.1      <none>                                                                   443/TCP          54m
    default       service/processingrequestssvc   LoadBalancer   172.20.252.89   a23b88c01410c45a2ae9551d4c382a1a-595729304.us-east-1.elb.amazonaws.com   5001:32391/TCP   25m
    kube-system   service/kube-dns                ClusterIP      172.20.0.10     <none>                                                                   53/UDP,53/TCP    51m
    
    NAMESPACE     NAME                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
    kube-system   daemonset.apps/aws-node     3         3         3       3            3           <none>          51m
    kube-system   daemonset.apps/kube-proxy   3         3         3       3            3           <none>          51m
    
    NAMESPACE     NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
    default       deployment.apps/messagesbroker       1/1     1            1           25m
    default       deployment.apps/processingrequests   1/1     1            1           25m
    kube-system   deployment.apps/coredns              2/2     2            2           51m
    
    NAMESPACE     NAME                                            DESIRED   CURRENT   READY   AGE
    default       replicaset.apps/messagesbroker-64fc8df4b8       1         1         1       25m
    default       replicaset.apps/processingrequests-6b59464c67   1         1         1       25m
    kube-system   replicaset.apps/coredns-86969bccb4              2         2         2       51m
    ```
    
7. **get deployment and services associated with our microservices**
    
    **kubectl get deploy -o wide**
    ```
    NAME                 READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS           IMAGES                                   SELECTOR
    messagesbroker       1/1     1            1           33m   messagesbroker       jcohenp/checkpoint-messages_broker       app=messagesbroker
    processingrequests   1/1     1            1           33m   processingrequests   jcohenp/checkpoint-processing_requests   app=processingrequests
    ```
    **kubectl get svc -o wide**
    ```
    AME                    TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)          AGE   SELECTOR
    kubernetes              ClusterIP      172.20.0.1      <none>                                                                   443/TCP          63m   <none>
    processingrequestssvc   LoadBalancer   172.20.252.89   a23b88c01410c45a2ae9551d4c382a1a-595729304.us-east-1.elb.amazonaws.com   5001:32391/TCP   34m   app=processingrequests
    ```
    Each deployment is created with 1 replicas and the service is LoadBalancer type. That will generate an url that is attached with a loadBalancer on AWS.

8. **Validate that the S3 bucket has been created correctly**
    
    ```
    aws s3 ls
    ```

    ```
    2024-01-25 11:23:25 devops--checkpoint-assignment
    2023-11-29 13:31:08 devops-directive-tf-state-jul-student
    2024-01-26 17:30:54 messages-bucket-checkpoint-assignment
    ```
9. **Validate that the SQS queue exist**:
    
    ```
    aws sqs list-queues
    ```
    
    ```
   {
        "QueueUrls": [
            "https://sqs.us-east-1.amazonaws.com/766537570218/my_sqs"
        ]
    }
    ```

    ```
    aws sqs get-queue-attributes --queue-url https://sqs.us-east-1.amazonaws.com/766537570218/my_sqs --attribute-names All
    ```
    
    ```
    {
        "Attributes": {
            "QueueArn": "arn:aws:sqs:us-east-1:766537570218:my_sqs",
            "ApproximateNumberOfMessages": "0",
            "ApproximateNumberOfMessagesNotVisible": "0",
            "ApproximateNumberOfMessagesDelayed": "0",
            "CreatedTimestamp": "1706283053",
            "LastModifiedTimestamp": "1706283053",
            "VisibilityTimeout": "30",
            "MaximumMessageSize": "262144",
            "MessageRetentionPeriod": "345600",
            "DelaySeconds": "0",
            "ReceiveMessageWaitTimeSeconds": "0",
            "SqsManagedSseEnabled": "true"
        }
    }
    ```
    

10. **Validate that the processing_requests microservice is reachable:**
    ```
    curl -X POST -H "Content-Type: application/json"  -d '{"data": {"email_subject": "Your Subject", "email_sender": "Your Sender", "email_timestream": "1706213694", "email_content": "Your Content"}, "token": "foobar"}' http://a23b88c01410c45a2ae9551d4c382a1a-595729304.us-east-1.elb.amazonaws.com:5001/process_request
    ```

    ```
    {
    "message": "Request processed successfully"
    }
    ```
11. **Let's dive into the logs:**
    ```
    ...
    'amz-sdk-invocation-id': b'3ddafec1-188d-4e16-b6c3-c5035fd9efe8', 'amz-sdk-request': b'attempt=1', 'Content-Length': '306'}>
    DEBUG:botocore.httpsession:Certificate path: /usr/local/lib/python3.8/site-packages/botocore/cacert.pem
    DEBUG:urllib3.connectionpool:Resetting dropped connection: sqs.us-east-1.amazonaws.com
    DEBUG:urllib3.connectionpool:https://sqs.us-east-1.amazonaws.com:443 "POST / HTTP/1.1" 200 378
    DEBUG:botocore.parsers:Response headers: {'x-amzn-RequestId': '965b6e0e-80c0-5781-b2fc-302363584d3c', 'Date': 'Fri, 26 Jan 2024 16:44:08 GMT', 'Content-Type': 'text/xml', 'Content-Length': '378', 'connection': 'keep-alive'}
    DEBUG:botocore.parsers:Response body:
    b'<?xml version="1.0"?><SendMessageResponse xmlns="http://queue.amazonaws.com/doc/2012-11-05/"><SendMessageResult><MessageId>0c8b1b3e-1350-4836-a516-2a81af644bbc</MessageId><MD5OfMessageBody>f5d1decf8a4781adddcfdb8e3b29cbd5</MD5OfMessageBody></SendMessageResult><ResponseMetadata><RequestId>965b6e0e-80c0-5781-b2fc-302363584d3c</RequestId></ResponseMetadata></SendMessageResponse>'
    DEBUG:botocore.hooks:Event needs-retry.sqs.SendMessage: calling handler <botocore.retryhandler.RetryHandler object at 0x7fe3b2044be0>
    DEBUG:botocore.retryhandler:No retry needed.
    INFO:__main__:Request processed successfully
    INFO:werkzeug:10.0.1.38 - - [26/Jan/2024 16:44:08] "POST /process_request HTTP/1.1" 200 -
    ```
    I have created a logger inside the flask app to get more information about the requests.

12. **Checking the correctness of the token:(for the exercise I have defnied the token value to 'foobar'**
    
    Lets check when the token is not correct
    ```
    curl -X POST -H "Content-Type: application/json"  -d '{"data": {"email_subject": "Your Subject", "email_sender": "Your Sender", "email_timestream": "1706213694", "email_content": "Your Content"}, "token": "notgood"}' http://a23b88c01410c45a2ae9551d4c382a1a-595729304.us-east-1.elb.amazonaws.com:5001/process_request
    ```
    ```
    {
        "error": "Invalid token"
    }
    ```
13. **Checking the correctness of the timestamp:**

    ```
    curl -X POST -H "Content-Type: application/json"  -d '{"data": {"email_subject": "Your Subject", "email_sender": "Your Sender", "email_timestream": "170621369400", "email_content": "Your Content"}, "token": "foobar"}' http://a23b88c01410c45a2ae9551d4c382a1a-595729304.us-east-1.elb.amazonaws.com:5001/process_request
    ```
    ```
    {
        "error": "Invalid date format or fields"
    }
    ```
14. **Check that message_broker microservice has correctly created a s3 object from the queue:**
    
    ```
    aws s3 ls messages-bucket-checkpoint-assignment
    ```

    ```
    2024-01-26 18:44:17        131 sqs_message_1706213694.json
    ```
    Get the content of the file
    
    ```
    {"email_subject": "Your Subject", "email_sender": "Your Sender", "email_timestream": "1706213694", "email_content": "Your Content"}
    ```
    
## CI/CD pipelines

I have created a build and deploy process for each microservices

- Build process consist of building a new image and send it to the docker registry
- Deploy process will used kubectl to connect to the eks cluster to deploy the new image that the user has defined.

All the pipelines are done on github action

I have defined all secrets like docker credentials or variables like microservice version inside githubaction configuration.

1. **Build process**:

The build will perform the following actions:
- Create a version policy: \<IMAGE\>:\<version_from_var\>.build_number
- docker build
- docker tag
- docker push on my docker registry repository

Once the build succeed the new image is available:
- https://hub.docker.com/repository/docker/jcohenp/checkpoint-processing_requests/general
- https://hub.docker.com/repository/docker/jcohenp/checkpoint-messages_broker/general


2. **Deploy process**

To make it works, it is necessary to update secrets variables from githubaction to match with credentials from your environment:
- AWS_ACCESS_KEY_ID
- AWS_REGION
- AWS_SECRET_ACCESS_KEY

the deploy will perform the following actions:
- Create an input parameter to specify the docker tag that you want to deploy
- Configure AWS credentials
- Update kubeconfig to let githubaction to interact with the eks cluster
- Set the new image using kubectl
