#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="${ROOT_DIR}/tests/e2e"
CLUSTER_CREATED=false
CLUSTER_NAME="${CLUSTER_NAME:-$(mktemp -u "nuc-kserve-e2e-XXXXXXXXXX" | tr "[:upper:]" "[:lower:]")}"
K8S_VERSION="${K8S_VERSION:-v1.35.0}"
E2E_NAMESPACE="nuc-kserve-e2e"
WORKLOAD_NAMESPACE="ml-platform"
RELEASE_NAME="nuc-kserve-e2e"
VALUES_FILE="values.yaml.example"

RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

log_error() { echo -e "${RED}Error:${RESET} $1" >&2; }
log_info() { echo -e "$1"; }
log_warn() { echo -e "${YELLOW}Warning:${RESET} $1" >&2; }

show_help() {
  echo "Usage: $(basename "$0") [helm upgrade/install options]"
  echo ""
  echo "Create a kind cluster, install vendored KServe CRDs, and run Helm install/upgrade against the root chart."
  echo "Unknown arguments are passed through to 'helm upgrade --install'."
  echo ""
  echo "Environment overrides:"
  echo "  CLUSTER_NAME   Kind cluster name"
  echo "  K8S_VERSION    kindest/node tag"
  echo ""
}

verify_prerequisites() {
  for bin in docker kind kubectl helm; do
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
  log_warn "Dumping KServe resources from ${CLUSTER_NAME}"
  kubectl get crd | grep 'serving.kserve.io' || true
  kubectl get inferenceservices,inferencegraphs,servingruntimes,trainedmodels -A || true
  kubectl get clusterservingruntimes,clusterstoragecontainers,localmodelcaches,localmodelnodegroups,localmodelnodes || true
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

install_kserve_crds() {
  log_info "Installing vendored KServe CRDs"
  kubectl apply --server-side -f "${SCRIPT_DIR}/crds"

  for crd in \
    clusterservingruntimes.serving.kserve.io \
    clusterstoragecontainers.serving.kserve.io \
    inferencegraphs.serving.kserve.io \
    inferenceservices.serving.kserve.io \
    localmodelcaches.serving.kserve.io \
    localmodelnodegroups.serving.kserve.io \
    localmodelnodes.serving.kserve.io \
    servingruntimes.serving.kserve.io \
    trainedmodels.serving.kserve.io; do
    kubectl wait --for=condition=Established --timeout=120s "crd/${crd}"
  done

  echo
}

ensure_namespaces() {
  for ns in "${E2E_NAMESPACE}" "${WORKLOAD_NAMESPACE}"; do
    log_info "Ensuring namespace ${ns} exists"
    kubectl get namespace "${ns}" >/dev/null 2>&1 || kubectl create namespace "${ns}"
  done
  echo
}

install_chart() {
  local helm_args=(
    upgrade
    --install
    "${RELEASE_NAME}"
    "${ROOT_DIR}"
    --namespace "${E2E_NAMESPACE}"
    -f "${ROOT_DIR}/${VALUES_FILE}"
    --wait
    --timeout 300s
  )

  if [ "$#" -gt 0 ]; then
    helm_args+=("$@")
  fi

  log_info "Building chart dependencies"
  helm dependency build "${ROOT_DIR}"
  echo

  log_info "Installing chart with Helm"
  helm "${helm_args[@]}"
  echo
}

verify_release_resources() {
  log_info "Verifying installed KServe resources"
  kubectl get clusterservingruntime sklearn-cluster-runtime
  kubectl get clusterstoragecontainer default-storage
  kubectl -n "${WORKLOAD_NAMESPACE}" get inferencegraph model-chain
  kubectl -n "${WORKLOAD_NAMESPACE}" get inferenceservice sklearn-iris
  kubectl get localmodelcache bert-cache
  kubectl get localmodelnodegroup ssd-cache-group
  kubectl get localmodelnode worker-cache-01
  kubectl -n "${WORKLOAD_NAMESPACE}" get servingruntime sklearn-runtime
  kubectl -n "${WORKLOAD_NAMESPACE}" get trainedmodel sklearn-iris-v1
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

  create_kind_cluster
  install_kserve_crds
  ensure_namespaces
  install_chart "$@"
  verify_release_resources

  log_info "End-to-end checks completed successfully"
}

main "$@"
