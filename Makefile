IMAGE_REPO ?= rg.fr-par.scw.cloud/funcscwriseriscvrunnerappqdvknz9s/riscv-runner
GOARCH     ?= riscv64

.PHONY: build
build: build-device-plugin build-node-labeller

.PHONY: build-device-plugin
build-device-plugin:
	CGO_ENABLED=0 GOOS=linux GOARCH=$(GOARCH) go build -o bin/k8s-device-plugin ./cmd/k8s-device-plugin

.PHONY: build-node-labeller
build-node-labeller:
	CGO_ENABLED=0 GOOS=linux GOARCH=$(GOARCH) go build -o bin/k8s-node-labeller ./cmd/k8s-node-labeller

.PHONY: container-build
container-build: container-build-device-plugin container-build-node-labeller

.PHONY: container-build-device-plugin
container-build-device-plugin:
	docker build --platform linux/riscv64 -f Dockerfile -t $(IMAGE_REPO):device-plugin-latest .

.PHONY: container-build-node-labeller
container-build-node-labeller:
	docker build --platform linux/riscv64 -f labeller.Dockerfile -t $(IMAGE_REPO):node-labeller-latest .

.PHONY: container-push
container-push: container-push-device-plugin container-push-node-labeller

.PHONY: container-push-device-plugin
container-push-device-plugin:
	docker build --platform linux/riscv64 -f Dockerfile -t $(IMAGE_REPO):device-plugin-latest .
	docker push $(IMAGE_REPO):device-plugin-latest

.PHONY: container-push-node-labeller
container-push-node-labeller:
	docker build --platform linux/riscv64 -f labeller.Dockerfile -t $(IMAGE_REPO):node-labeller-latest .
	docker push $(IMAGE_REPO):node-labeller-latest

.PHONY: kubectl-apply
kubectl-apply: kubectl-apply-device-plugin kubectl-apply-node-labeller

.PHONY: kubectl-apply-device-plugin
kubectl-apply-device-plugin:
	kubectl apply -f k8s-ds-device-plugin.yaml
	kubectl rollout restart daemonset/rise-riscv-runner-device-plugin -n kube-system

.PHONY: kubectl-apply-and-wait-device-plugin
kubectl-apply-and-wait-device-plugin: kubectl-apply-device-plugin
	kubectl rollout status daemonset/rise-riscv-runner-device-plugin -n kube-system --watch

.PHONY: kubectl-apply-node-labeller
kubectl-apply-node-labeller:
	kubectl apply -f k8s-ds-node-labeller.yaml
	kubectl rollout restart daemonset/rise-riscv-runner-node-labeller -n kube-system

.PHONY: clean
clean:
	rm -rf bin/
