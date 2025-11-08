#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pushd "$ROOT_DIR/lambdas/auto_remediate_required_tags" >/dev/null
pip install -r requirements.txt -t package >/dev/null
cp -r *.py package/
cd package && zip -r ../auto_remediate_required_tags.zip . >/dev/null
popd >/dev/null

pushd "$ROOT_DIR/lambdas/nat_cost_reporter" >/dev/null
npm install >/dev/null
npm run build || ./node_modules/.bin/tsc
zip -r nat_cost_reporter.zip dist >/dev/null
popd >/dev/null

echo "Artifacts packaged:
 - lambdas/auto_remediate_required_tags/auto_remediate_required_tags.zip
 - lambdas/nat_cost_reporter/nat_cost_reporter.zip"
