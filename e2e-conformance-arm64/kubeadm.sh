#!/bin/bash +e

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tarname=image.tar
tarfile="${WORK_DIR}/tests/${tarname}"

export KUBE_VERSION=${KUBE_VERSION:-"v1.11.2"}
export LOGFILE="/mnt/e2e.log"

usage(){
    echo "usage:" >&2
    echo "  $0 e2e " >&2
    echo "  $0 clean" >&2
}

#install k8s master node
install_master(){

    sudo kubeadm init --kubernetes-version=v1.11.2 --pod-network-cidr=10.244.0.0/16  --ignore-preflight-errors=cri --token-ttl 0

    sudo cp /etc/kubernetes/admin.conf $HOME/
    sudo chown $(id -u):$(id -g) $HOME/admin.conf
    export KUBECONFIG=$HOME/admin.conf

    kubectl taint nodes --all node-role.kubernetes.io/master-
    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

    sleep 5

    sed -i 's/insecure-port=0/insecure-port=8080/g' /etc/kubernetes/manifests/kube-apiserver.yaml
    systemctl restart kubelet
    sleep 25

    echo "wait for K8s master node to be Ready"
    INC=0
    while [[ $INC -lt 20 ]]; do
        kube_ready=$(kubectl get node -o jsonpath='{.items['$count'].status.conditions[?(@.reason == "KubeletReady")].status}')
        if [ "${kube_ready}" == "True" ]; then
            break
        fi
        echo "."
        sleep 10
        ((++INC))
    done

    if [ "${kube_ready}" != "True" ]; then
        echo "k8s master node never went to Ready status"
        exit 1
    fi

    cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    echo "k8s master node in Ready status"
}

#install k8s node
install_node(){
    echo "inside install node function"

    # for k8s 1.8, use a non default value for volume plugins
    if [[ $KUBE_VERSION == v1.8* ]] ; then
        cat << EOF | sudo tee -a /etc/systemd/system/kubelet.service.d/11-volume_plugin_dir.conf
[Service]
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true --volume-plugin-dir=/var/lib/kubelet/volumeplugins"
EOF
        sudo systemctl daemon-reload
    fi

    echo "kubeadm join ${1} ${2} ${3} ${4} ${5} --skip-preflight-checks"
    sudo kubeadm join ${1} ${2} ${3} ${4} ${5} --skip-preflight-checks || true
}

#wait for all nodes in the cluster to be ready status
wait_for_ready(){
    #expect 3 node cluster by default
    local numberOfNode=${1:-3}
    local count=0
    sudo cp /etc/kubernetes/admin.conf $HOME/
    sudo chown $(id -u):$(id -g) $HOME/admin.conf
    export KUBECONFIG=$HOME/admin.conf

    until [[ $count -eq $numberOfNode ]]; do
        echo "wait for K8s node $count to be Ready."
        INC=0
        while [[ $INC -lt 90 ]]; do
            kube_ready=$(kubectl get node -o jsonpath='{.items['$count'].status.conditions[?(@.reason == "KubeletReady")].status}')
            if [ "${kube_ready}" != "True" ]; then
                break
            fi
            echo  -n "."
            sleep 10
            ((++INC))
        done
        echo
        if [ "${kube_ready}" != "True" ]; then
            echo "k8s node ${count} never went to Ready status"
            exit 1
        fi

        echo "k8s node ${count} in Ready status"
        ((++count))

    done

    echo "All k8s node in Ready status"

}

kubeadm_reset() {
    kubectl delete -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
    sudo kubeadm reset -f 
    sudo apt remove -y kubelet kubectl kubeadm --purge
    sudo rm /usr/local/bin/kube* -f
#	sudo rm /usr/local/bin/kubectl -f
    rm $HOME/admin.conf
    rm -rf $HOME/.kube
    sudo swapon -a
}

kubeadm_install_local_pv() {
#    mkdir -p /mnt/www/disk0
#    mkdir -p /mnt/www/disk1
#    mkdir -p /mnt/www/disk2

#    kubectl create -f stateful-local-all-pv.yaml 
     mkdir -p /tmp/home1
     mkdir -p /tmp/home2
     mkdir -p /tmp/home3
#     mkdir -p /tmp/home4
     kubectl create -f pv1.yaml
     kubectl create -f pv2.yaml
     kubectl create -f pv3.yaml
#     kubectl create -f pv4.yaml
}

kubeadm_e2e_test () {
    export KUBECONFIG=/etc/kubernetes/admin.conf
    export KUBE_MASTER_IP="127.0.0.1:8080"
    export KUBE_MASTER=local
    export KUBERNETES_CONFORMANCE_TEST=y
#    export GINKGO_PARALLEL=y

    cd $GOPATH/src/k8s.io/kubernetes
#    go run hack/e2e.go -- --provider=local --test --test_args="--ginkgo.skip=Networking-IPv6" > /mnt/k8s-e2e-full-20180827.log & 
#    go run hack/e2e.go -- --provider=local --test --test_args="--ginkgo.focus=\[Conformance\]" > /mnt/k8s-e2e-full-20180825.log &
    go run hack/e2e.go -- --provider=local --test --test_args="--ginkgo.focus=\[Conformance\]" 
}

case "${1:-}" in
    e2e)
		echo "kubeadm reset..."
		#kubeadm_reset
		sleep 1 
		echo "compile k8s..."
		# ./kubeadm-install.sh ${KUBE_VERSION}
		sleep 1 
		echo "install k8s..."
		# install_master
		sleep 1
	        echo "install local pv..."
		# kubeadm_install_local_pv
		echo "k8s e2e test..."
		kubeadm_e2e_test
		echo "k8s monitor pv..."

        ;;
    clean)
        kubeadm_reset
        ;;
    *)
        usage
        exit 1
esac
