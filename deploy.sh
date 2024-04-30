#!/bin/bash -ex

# cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit

target_bucket=$BUCKET_NAME
distribution_id=$(aws cloudfront list-distributions --query "DistributionList.Items[*].{id:Id,origin:Origins.Items[0].Id}[?origin=='${target_bucket}'].id" --output text)

aws s3 sync --dryrun --exclude '.git/*' --exclude '.*' --exclude '*.sh' --exclude '.*/*' --exclude '**/.*' ./ s3://$target_bucket | awk '{ print "\"/"$3"\"" }' > .changes
changes_count=$(cat .changes | wc -l)
changes=$(cat .changes | sed 's/\/.\//\//g') # replace path /./ by /

if [ -z "$changes" ]; then
  echo "There is no change to deploy."
  exit
fi

items=$(echo $changes | tr '\n' ',' | tr ' ', ',' | sed 's/,$//g')
timestamp=$(date +"%s")

rm -f .inv-batch.json
touch .inv-batch.json

echo '{
    "Paths": {
        "Quantity": '${changes_count}',
        "Items": [' ${items} ']
    },
    "CallerReference": "s3-websync-'${timestamp}'"
}' > .inv-batch.json

echo "Going to upload following change files:"
echo $changes
echo ""

echo "Start uploading to ${target_bucket}"
echo "Start uploading"
aws s3 sync --exclude '.git/*' --exclude '.*' --exclude '*.sh' --exclude '.*/*' --exclude '**/.*' ./ s3://$target_bucket

if [ ! -z ${distribution_id} ]; then
  echo "Create invalidation to CloudFront.. ID=${distribution_id}"
  echo $(cat .inv-batch.json)
  aws cloudfront create-invalidation --distribution-id $distribution_id --invalidation-batch file://.inv-batch.json ||
    aws cloudfront create-invalidation --distribution-id $distribution_id --paths "/*"
fi

echo "Deploy finished"
