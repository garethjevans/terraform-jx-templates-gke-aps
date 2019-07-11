#!/bin/bash
set -euo pipefail

KEY=`find .. -name '*.key.json'`
echo $KEY

export GOOGLE_CREDENTIALS=`pwd`/${KEY}
terraform output $1
