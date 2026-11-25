#!/bin/sh
podman run --rm -d --name training-web -p 8080:80 docker.io/library/nginx:stable
podman ps
# podman stop training-web
