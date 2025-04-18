
MASTER_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

kubectl create secret generic gitlab-repo-https -n argocd \
    --from-literal=username=root \
    --from-literal=password="glpat-xhzonFh6aE_Ujk24atzW" \
    --from-literal=url=http://$MASTER_IP:31827/root/yassine.git 

kubectl rollout restart deployment/argocd-applicationset-controller -n argocd