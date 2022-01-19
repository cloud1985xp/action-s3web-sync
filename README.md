# GitHub Action; Simple Sync Repo to AWS S3 Bucket as Static Web

This github action just simple sync the files of your repo to AWS s3 bucket. Supposed you had this bucket configured as static website already

When sync the repo files, it excludes:

- .git directory
- Any .* files or .*/ directories

And if you are using  cloudfront as CDN and use
this action will create invalidation to for the uploaded files

Therefore you have to prepare your AWS credential in your workflow with following IAM permission at least:

- s3:GetObject
- s3:PutObject
- s3:ListBucket
- cloudfront:CreateInvalidation
- cloudfront:ListDistributions

## Inputs

### `bucket-name`

Give the s3 bucket name you want to hosted as static web

## Example

use following actions to setup

- actions/checkout
- aws-actions/configure-aws-credentials

With `aws-actions/configure-aws-credentials` you can use access key or any way it provided to configure the AWS credentials.


```
jobs:
  Example:
    name: Setup and Upload
    runs-on: ubuntu-latest
    steps:
    - name: Git clone the repository
      uses: actions/checkout@v2
    - name: configure aws credentials
      uses: aws-actions/configure-aws-credentials@master
    - name: Run Deployment
      uses: cloud1985xp/action-s3web-sync@v1
      with:
        bucket-name: my-s3-bucket-name
```