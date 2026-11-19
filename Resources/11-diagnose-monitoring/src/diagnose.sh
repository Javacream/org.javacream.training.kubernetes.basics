#!/bin/sh
kubectl -n training get events --sort-by=.metadata.creationTimestamp
kubectl -n training get pods -o wide
kubectl -n training describe deployment web
kubectl -n training logs deployment/web --tail=50
