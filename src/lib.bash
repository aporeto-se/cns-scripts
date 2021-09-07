# See https://docs.aporeto.com/saas/microseg-console-api/about for detail.

set -e

function _binCheck()
{
builtin type -P "$1" &> /dev/null || { err "$1 jq not found in path"; return 2; }
return 0
}

function getToken()
{
getTokenWithAWSMagic
}

function getTokenWithAWSMagic()
{
local raw
raw=$(curl -s "$API/issue" -X POST -H 'Content-Type: application/json' -d "$(_getTokenWithAWSMagic)")
[[ "$raw" ]] || { err "Failed to get token"; return 3; }
echo "$raw" | jq -r '.token'
}

function _getTokenWithAWSMagic()
{

local token0 role json accessKeyId secretAccessKey token

token0=$(curl -s -f -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
role=$(curl -s -f http://169.254.169.254/latest/meta-data/iam/security-credentials/)
json=$(curl -s -f -H "X-aws-ec2-metadata-token: $token0" http://169.254.169.254/latest/meta-data/iam/security-credentials/"$role")
accessKeyId=$(echo "$json" | jq -r '.AccessKeyId')
secretAccessKey=$(echo "$json" | jq -r '.SecretAccessKey')
token=$(echo "$json" | jq -r '.Token')
[[ "$token" ]] || { err "Failed to get token"; return 2; }

cat <<EOF
{
  "realm": "AWSSecurityToken",
  "validity": "24h",
  "quota": 0,
  "metadata": {
    "accessKeyID": "$accessKeyId",
    "secretAccessKey": "$secretAccessKey",
    "token": "$token"
  }
}
EOF
return 0
}

function runningInAWS()
{
curl -s --fail --connect-timeout 2 --retry 0 169.254.169.254/latest/meta-data/ami-id > /dev/null 2>&1 && return 0
return 1
}

function listNamespaces()
{
local ns
ns="/"
[[ "$1" ]] && { ns="$1"; }

local raw
raw=$(curl -s --fail --connect-timeout 10 "$API/namespaces" \
  -X GET \
  -H "Content-Type: application/json" \
  -H "X-Namespace: $ns" \
  -H "X-Fields: name" \
  -H "cookie: x-aporeto-token=$(getToken)")
}

function err() { echo "$@" 1>&2; }

_binCheck "jq"
_binCheck "curl"
[[ "$API" ]] || { err "Missing required var API"; return 3; }
