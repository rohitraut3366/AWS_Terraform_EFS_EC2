# AWS_Terraform_EFS_EC2
Blog link :https://medium.com/@rohitraut3366/launching-an-application-on-aws-cloud-using-ec2-efs-s3-and-cloudfront-1526c7dfe6ec
# Here the step by step process which is easy to understand.
```
Step 1 : Creating KeyPair and Security group allowing port 22(SSH), 80 and 2049(NFS).
```
```
Step 2: Create an S3 bucket and uploading image in S3.
```
```
Step 3: Creating Cloud Front using S3 Created in step3.
```
```
Step 4: Writing Bucket Policy so cloud front can access the objects in s3.
```
```
Step 5: Creating EFS(Elastic File System) and Mouting it to all three subnets.
```
```
Step 6: Launching two EC2 instances one for webserver and one for testing.
```
```
Step 7: Mounting EFS to /var/www/html.
```
