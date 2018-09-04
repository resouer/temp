#!/bin/bash +e
KUBE_VERSION=${1:-"v1.11.2"}
KUBE_INSTALL_VERSION="${KUBE_VERSION/v/$null_str}"-00

sudo swapoff -a

# go get -d k8s.io/kubernetes
cp 0001-enable-e2e-on-arm.patch /tmp/
cd $GOPATH/src/k8s.io/kubernetes
git clean -df
git stash
git pull
git checkout ${KUBE_VERSION}
cp /tmp/0001-enable-e2e-on-arm.patch ./
patch -fp1 < 0001-enable-e2e-on-arm.patch
make
#make WHAT=test/e2e/e2e.test && make WHAT=ginkgo 
#&& make WHAT=cmd/kubectl
#cp _output/local/go/bin/kubectl /usr/local/bin/ -f

#cp /tmp/0001-enable-e2e-test-on-Arm64.patch ./
#patch -fp1 < 0001-enable-e2e-test-on-Arm64.patch

sudo apt-get install -y kubelet="${KUBE_INSTALL_VERSION}" kubeadm="${KUBE_INSTALL_VERSION}" kubectl="${KUBE_INSTALL_VERSION}"

#apt remove kubelet kubectl kubeadm -y

#cp ./_output/local/bin/linux/arm64/kubeadm /usr/local/bin -f
#cp ./_output/local/bin/linux/arm64/kubelet /usr/local/bin -f
#cp ./_output/local/bin/linux/arm64/kubectl /usr/local/bin -f
#get matching kubectl
#wget "https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl"
#chmod +x kubectl
#sudo cp kubectl /usr/local/bin
