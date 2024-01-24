#!/bin/bash

# Get the private IP address of the instance
aws_metadata_token=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
ec2_ip_address=$(curl -H "X-aws-ec2-metadata-token: $aws_metadata_token" http://169.254.169.254/latest/meta-data/local-ipv4)
# Create an HTML file with the private IP address
cat <<EOF > index.html
<html>
<head><title>Private IP Address</title></head>
<body>
<h1>Private IP Address: $ec2_ip_address</h1>
</body>
</html>
EOF

# Install Apache web server
yum -y update
yum -y install httpd
systemctl start httpd
systemctl enable httpd

# Serve the HTML file from the Apache web server
mv index.html /var/www/html/index.html
