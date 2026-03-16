#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="${ROOT_DIR}/tests/e2e"
CLUSTER_CREATED=false
CT_CONTAINER_STARTED=false
CLUSTER_NAME="${CLUSTER_NAME:-$(mktemp -u "nuc-native-gateway-e2e-XXXXXXXXXX" | tr "[:upper:]" "[:lower:]")}"
CT_CONTAINER_NAME="ct-${CLUSTER_NAME}"
CT_VERSION="${CT_VERSION:-v3.14.0}"
K8S_VERSION="${K8S_VERSION:-v1.35.0}"
GATEWAY_API_VERSION="${GATEWAY_API_VERSION:-v1.5.0}"
GATEWAY_API_CRD_URL="https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/experimental-install.yaml"
E2E_NAMESPACE="nuc-native-gateway-e2e"
RELEASE_NAME="nuc-native-gateway-e2e"
VALUES_FILE="tests/e2e/values/install.values.yaml"

RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

log_error() { echo -e "${RED}Error:${RESET} $1" >&2; }
log_info() { echo -e "$1"; }
log_warn() { echo -e "${YELLOW}Warning:${RESET} $1" >&2; }

docker_exec() {
  docker exec --interactive "${CT_CONTAINER_NAME}" "$@"
}

show_help() {
  echo "Usage: $(basename "$0") [ct install options]"
  echo ""
  echo "Create a kind cluster, install Gateway API experimental CRDs, and run chart-testing against the root chart."
  echo "Unknown arguments are passed through to 'ct install'."
  echo ""
  echo "Environment overrides:"
  echo "  CLUSTER_NAME          Kind cluster name"
  echo "  CT_VERSION            chart-testing image tag"
  echo "  K8S_VERSION           kindest/node tag"
  echo "  GATEWAY_API_VERSION   Gateway API release used for CRD bootstrap"
  echo ""
}

verify_prerequisites() {
  for bin in docker kind kubectl; do
    if ! command -v "${bin}" >/dev/null 2>&1; then
      log_error "${bin} is not installed"
      exit 1
    fi
  done
}

cleanup() {
  local exit_code=$?

  if [ "${exit_code}" -ne 0 ] && [ "${CLUSTER_CREATED}" = true ]; then
    dump_cluster_state || true
  fi

  log_info "Cleaning up resources"

  if [ "${CT_CONTAINER_STARTED}" = true ]; then
    log_info "Removing ct container ${CT_CONTAINER_NAME}"
    if docker ps --filter="name=${CT_CONTAINER_NAME}" --filter="status=running" | grep -q "${CT_CONTAINER_NAME}"; then
      docker kill "${CT_CONTAINER_NAME}" >/dev/null 2>&1
    else
      log_warn "ct container ${CT_CONTAINER_NAME} not running"
    fi
  fi

  if [ "${CLUSTER_CREATED}" = true ]; then
    log_info "Removing kind cluster ${CLUSTER_NAME}"
    if kind get clusters | grep -q "${CLUSTER_NAME}"; then
      kind delete cluster --name="${CLUSTER_NAME}"
    else
      log_warn "kind cluster ${CLUSTER_NAME} not found"
    fi
  fi

  exit "${exit_code}"
}

dump_cluster_state() {
  log_warn "Dumping Gateway API resources from ${CLUSTER_NAME}"
  kubectl get gatewayclasses.gateway.networking.k8s.io || true
  kubectl get \
    backendtlspolicies.gateway.networking.k8s.io,gateways.gateway.networking.k8s.io,grpcroutes.gateway.networking.k8s.io,httproutes.gateway.networking.k8s.io,referencegrants.gateway.networking.k8s.io,tlsroutes.gateway.networking.k8s.io \
    -A || true
}

run_ct_container() {
  log_info "Running ct container ${CT_CONTAINER_NAME}"

  docker run --rm --interactive --detach --network host \
    --name "${CT_CONTAINER_NAME}" \
    --volume "${ROOT_DIR}:/workdir" \
    --workdir /workdir \
    "quay.io/helmpack/chart-testing:${CT_VERSION}" \
    cat

  CT_CONTAINER_STARTED=true
  echo
}

create_kind_cluster() {
  log_info "Creating kind cluster ${CLUSTER_NAME}"

  if kind get clusters | grep -q "${CLUSTER_NAME}"; then
    log_error "kind cluster ${CLUSTER_NAME} already exists"
    exit 1
  fi

  kind create cluster \
    --name="${CLUSTER_NAME}" \
    --config="${SCRIPT_DIR}/kind.yaml" \
    --image="kindest/node:${K8S_VERSION}" \
    --wait=60s

  CLUSTER_CREATED=true
  echo
}

install_gateway_api_crds() {
  log_info "Installing Gateway API experimental CRDs from ${GATEWAY_API_VERSION}"
  kubectl apply -f "${GATEWAY_API_CRD_URL}"

  for crd in \
    backendtlspolicies.gateway.networking.k8s.io \
    gatewayclasses.gateway.networking.k8s.io \
    gateways.gateway.networking.k8s.io \
    grpcroutes.gateway.networking.k8s.io \
    httproutes.gateway.networking.k8s.io \
    referencegrants.gateway.networking.k8s.io \
    tlsroutes.gateway.networking.k8s.io; do
    kubectl wait --for=condition=Established --timeout=120s "crd/${crd}"
  done

  echo
}

copy_kubeconfig_to_ct_container() {
  log_info "Copying kubeconfig to ct container"
  docker_exec mkdir -p /root/.kube
  docker cp "${HOME}/.kube/config" "${CT_CONTAINER_NAME}:/root/.kube/config"
  echo
}

install_chart() {
  local ct_args=(
    install
    --chart-dirs .
    --charts .
    --namespace "${E2E_NAMESPACE}"
    --release-name "${RELEASE_NAME}"
    --skip-clean-up
    --helm-extra-args "--create-namespace -f ${VALUES_FILE} --wait --timeout 300s"
  )

  if [ "$#" -gt 0 ]; then
    ct_args+=("$@")
  fi

  log_info "Installing chart with chart-testing"
  docker_exec ct "${ct_args[@]}"
  echo
}

verify_release_resources() {
  log_info "Verifying installed Gateway API resources"
  kubectl get gatewayclass e2e-gateway-class
  kubectl -n "${E2E_NAMESPACE}" get gateway e2e-gateway
  kubectl -n "${E2E_NAMESPACE}" get httproute e2e-http
  kubectl -n "${E2E_NAMESPACE}" get grpcroute e2e-grpc
  kubectl -n "${E2E_NAMESPACE}" get tlsroute e2e-tls
  kubectl -n "${E2E_NAMESPACE}" get backendtlspolicy e2e-backend-tls
  kubectl -n "${E2E_NAMESPACE}" get referencegrant e2e-referencegrant
  echo
}

parse_args() {
  for arg in "$@"; do
    case "${arg}" in
      -h|--help)
        show_help
        exit 0
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  verify_prerequisites

  trap cleanup EXIT

  run_ct_container
  create_kind_cluster
  install_gateway_api_crds
  copy_kubeconfig_to_ct_container
  install_chart "$@"
  verify_release_resources

  log_info "End-to-end checks completed successfully"
}

main "$@"
