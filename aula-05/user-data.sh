#!/bin/bash
set -euo pipefail
dnf install -y postgresql15
psql --version
