#!/bin/sh
kubectl -n training rollout status deployment/web
kubectl -n training scale deployment/web --replicas=3
kubectl -n training rollout history deployment/web
# kubectl -n training rollout undo deployment/web
