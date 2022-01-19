#!/bin/bash -e

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit

target_bucket=$BUCKET_NAME
distribution_id=$(aws cloudfront list-distributions --query "DistributionList.Items[*].{id:Id,origin:Origins.Items[0].Id}[?origin=='${target_bucket}'].id" --output text)

changes=$(aws s3 sync --dryrun --exclude '.git/*' --exclude '*.sh' --exclude '.*/*' --exclude '**/.*' ./ s3://$target_bucket | awk '{ print "/"$3 }')

if [ -z "$changes" ]; then
  echo "There is no change to deploy."
  exit
fi

echo "Going to upload following change files:"
changes=$(echo $changes | sed 's/\/.\//\//g') # replace path /./ by /
echo $changes
echo ""

echo "Start uploading to ${target_bucket}"
echo "Start uploading"
aws s3 sync --exclude '.git/*' --exclude '*.sh' --exclude '.*/*' --exclude '**/.*' ./ s3://$target_bucket

if [ ! -z ${distribution_id} ]; then
  echo "Create invalidation to CloudFront.. ID=${distribution_id}"
  aws cloudfront create-invalidation --distribution-id $distribution_id --paths $changes
fi

echo "Deploy finished"
