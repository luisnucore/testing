#!/usr/bin/env python3
import os

print('Haciendo deploy de cluster de k8')
os.system('terraform apply  -auto-approve -var "do_token=$do_token"   -var "pub_key=$pub_key"   -var "pvt_key=$pvt_key"   -var "fingerprint=$fingerprint"')
print('Lanzando servicio de nginx')
os.system('kubectl --kubeconfig ~/kbcnf/admin.conf apply -f custom-deploy.yaml')
os.system('kubectl --kubeconfig ~/kbcnf/admin.conf apply -f bitso-cpu-issue.yml')
