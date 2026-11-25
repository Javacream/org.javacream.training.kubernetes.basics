#!/bin/sh
set -eu

# Die Informationen erst beim Containerstart ermitteln.
. /etc/os-release
escape_html() {
    printf '%s' "$1" | sed 's/\&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

host=$(escape_html "$(hostname)")
os=$(escape_html "$(uname -s)")
kernel=$(escape_html "$(uname -r)")
distribution=$(escape_html "${PRETTY_NAME:-unknown}")
architecture=$(escape_html "$(uname -m)")

cat > /usr/share/nginx/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Host Information</title>
</head>
<body>
    <h1>Host Information</h1>
    <dl>
        <dt>Hostname</dt><dd>$host</dd>
        <dt>Operating system</dt><dd>$os</dd>
        <dt>Linux distribution</dt><dd>$distribution</dd>
        <dt>Kernel version</dt><dd>$kernel</dd>
        <dt>Architecture</dt><dd>$architecture</dd>
    </dl>
</body>
</html>
EOF
