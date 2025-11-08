import json, os, boto3, logging
from botocore.exceptions import ClientError

log = logging.getLogger()
log.setLevel(logging.INFO)
REQUIRED = os.environ.get("REQUIRED_TAGS","Owner,App,Env").split(",")

tag = boto3.client("resourcegroupstaggingapi")
s3  = boto3.client("s3")
ec2 = boto3.client("ec2")

def ensure_tags_on_s3(bucket, missing):
    try:
        current = s3.get_bucket_tagging(Bucket=bucket).get("TagSet", [])
    except ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchTagSet":
            current = []
        else:
            raise
    keys = {t["Key"] for t in current}
    for k in missing:
        if k not in keys:
            current.append({"Key": k, "Value": f"auto-{k.lower()}"})
    s3.put_bucket_tagging(Bucket=bucket, Tagging={"TagSet": current})
    return True

def evaluate_and_fix(resource_arn):
    # Minimal demo: handle S3 buckets and EC2 volumes/instances
    if resource_arn.startswith("arn:aws:s3:::"):
        bucket = resource_arn.split(":::")[-1]
        # Fetch tags via Tagging API
        resp = tag.get_resources(ResourceARNList=[resource_arn])
        current = {t["Key"] for r in resp["ResourceTagMappingList"] for t in r.get("Tags",[])}
        missing = [k for k in REQUIRED if k not in current]
        if missing:
            ensure_tags_on_s3(bucket, missing)
            return {"resource": resource_arn, "fixed": True, "missing": missing}
        return {"resource": resource_arn, "fixed": False, "missing": []}
    return {"resource": resource_arn, "fixed": False, "missing": []}

def lambda_handler(event, context):
    log.info("Event: %s", json.dumps(event))
    # If invoked by Config custom rule, extract resource ARN if present; otherwise demo with list-tags query
    res_arn = None
    if isinstance(event, dict):
        res_arn = (event.get("invokingEvent") or event).get("configurationItem",{}).get("arn") if event.get("invokingEvent") else event.get("resource_arn")
    if not res_arn:
        # As a demo path, scan a small page for S3 buckets
        resp = tag.get_resources(ResourceTypeFilters=["s3"], ResourcesPerPage=1)
        for m in resp.get("ResourceTagMappingList", []):
            res_arn = m["ResourceARN"]; break
    if not res_arn:
        return {"status": "no-resource"}

    result = evaluate_and_fix(res_arn)
    log.info("Result: %s", result)
    return {"status": "ok", **result}
