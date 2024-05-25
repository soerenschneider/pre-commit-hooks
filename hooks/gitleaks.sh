#!/usr/bin/env bash

set -e

gitleaks protect --verbose --redact --staged
