#!/bin/bash

cat > "config.js" << EOF
/* commercetools platform credentials */
exports.config = {
  client_id: "${COMMERCETOOLS_CLIENT_ID}",
  client_secret: "${COMMERCETOOLS_CLIENT_SECRET}",
  project_key: "${COMMERCETOOLS_PROJECT_KEY}"
}
EOF
