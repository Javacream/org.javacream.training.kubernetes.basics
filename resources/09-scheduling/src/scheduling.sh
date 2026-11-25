#!/bin/sh
kubectl get nodes --show-labels
kubectl -n training get pods -o wide
kubectl -n training describe deployment web
