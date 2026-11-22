#!/bin/sh
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A
