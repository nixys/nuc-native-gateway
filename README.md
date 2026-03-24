# NUC Native Gateway

Helm chart for rendering Kubernetes Gateway API resources from declarative values.

The chart does not install Gateway API CRDs or any controller. It only renders Gateway API objects that are already supported by the target cluster and controller.

## Quick Start

Render the example configuration:

```bash
helm template nuc-native-gateway . -f values.yaml.example
```

Install the chart:

```bash
helm install nuc-native-gateway . \
  --namespace gateway-system \
  --create-namespace \
  -f values.yaml.example
```

Install the local README generator hook:

```bash
pre-commit install
pre-commit install-hooks
```

## Supported Resources

The chart can render these Gateway API kinds:

- `BackendTLSPolicy`
- `GatewayClass`
- `Gateway`
- `GRPCRoute`
- `HTTPRoute`
- `ListenerSet`
- `ReferenceGrant`
- `TLSRoute`

Support for individual kinds and fields still depends on the Gateway API bundle and controller installed in the cluster.

## Values Model

Each top-level map in [values.yaml](values.yaml) maps resource names to one resource kind:

- `backendTLSPolicies`
- `gatewayClasses`
- `gateways`
- `grpcRoutes`
- `httpRoutes`
- `listenerSets`
- `referenceGrants`
- `tlsRoutes`

Every map entry uses the same generic contract:

| Field | Required | Description |
|-------|----------|-------------|
| map key | yes | Resource name used for `metadata.name`. |
| `namespace` | no | Namespace for namespaced resources. Defaults to the Helm release namespace. Ignored for cluster-scoped resources. |
| `labels` | no | Labels merged on top of built-in chart labels and `commonLabels`. |
| `annotations` | no | Annotations merged on top of `commonAnnotations`. |
| `apiVersion` | no | Per-resource API version override. |
| `spec` | no | Raw resource spec rendered as-is. |
| `status` | no | Optional raw status block. Usually not managed through Helm in production. |

In a higher-precedence values file, set a map entry to `null` to suppress a default resource from a lower-precedence values file.

Global controls:

- `enabled`
- `global` (accepted for umbrella-chart compatibility and ignored by this chart)
- `nameOverride`
- `commonLabels`
- `commonAnnotations`
- `apiVersions.*`

The value contract is validated by [values.schema.json](values.schema.json).

## Helm Values

This section is generated from [values.yaml](values.yaml) by `helm-docs`. Edit [values.yaml](values.yaml) comments or [docs/README.md.gotmpl](docs/README.md.gotmpl), then run `pre-commit run helm-docs --all-files` or `make docs` if you need to refresh it outside a commit.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| apiVersions.backendTLSPolicy | string | `"gateway.networking.k8s.io/v1"` | Default apiVersion for BackendTLSPolicy resources. |
| apiVersions.gateway | string | `"gateway.networking.k8s.io/v1"` | Default apiVersion for Gateway resources. |
| apiVersions.gatewayClass | string | `"gateway.networking.k8s.io/v1"` | Default apiVersion for GatewayClass resources. |
| apiVersions.grpcRoute | string | `"gateway.networking.k8s.io/v1"` | Default apiVersion for GRPCRoute resources. |
| apiVersions.httpRoute | string | `"gateway.networking.k8s.io/v1"` | Default apiVersion for HTTPRoute resources. |
| apiVersions.listenerSet | string | `"gateway.networking.k8s.io/v1"` | Default apiVersion for ListenerSet resources. |
| apiVersions.referenceGrant | string | `"gateway.networking.k8s.io/v1"` | Default apiVersion for ReferenceGrant resources. |
| apiVersions.tlsRoute | string | `"gateway.networking.k8s.io/v1"` | Default apiVersion for TLSRoute resources. |
| backendTLSPolicies | object | {} | BackendTLSPolicy resources keyed by resource name. |
| backendTLSPolicies.__helm_docs_example__.annotations | object | `{}` | Resource-specific annotations. |
| backendTLSPolicies.__helm_docs_example__.apiVersion | string | chart default for this kind | Per-resource apiVersion override. |
| backendTLSPolicies.__helm_docs_example__.labels | object | `{}` | Resource-specific labels. |
| backendTLSPolicies.__helm_docs_example__.namespace | string | release namespace | Namespace for namespaced resources. Defaults to the Helm release namespace. Ignored for cluster-scoped kinds. |
| backendTLSPolicies.__helm_docs_example__.spec | object | `{}` | Resource spec rendered as-is. |
| backendTLSPolicies.__helm_docs_example__.status | object | `{}` | Optional resource status rendered as-is. |
| commonAnnotations | object | `{}` | Extra annotations applied to every rendered resource. |
| commonLabels | object | `{}` | Extra labels applied to every rendered resource. |
| enabled | bool | `true` | Enable nuc-native-gateway chart rendering. |
| gatewayClasses | object | {} | GatewayClass resources keyed by resource name. |
| gatewayClasses.__helm_docs_example__.annotations | object | `{}` | Resource-specific annotations. |
| gatewayClasses.__helm_docs_example__.apiVersion | string | chart default for this kind | Per-resource apiVersion override. |
| gatewayClasses.__helm_docs_example__.labels | object | `{}` | Resource-specific labels. |
| gatewayClasses.__helm_docs_example__.namespace | string | "" | Namespace for namespaced resources. Defaults to the Helm release namespace. Ignored for cluster-scoped kinds. |
| gatewayClasses.__helm_docs_example__.spec | object | `{}` | Resource spec rendered as-is. |
| gatewayClasses.__helm_docs_example__.status | object | `{}` | Optional resource status rendered as-is. |
| gateways | object | {} | Gateway resources keyed by resource name. |
| gateways.__helm_docs_example__.annotations | object | `{}` | Resource-specific annotations. |
| gateways.__helm_docs_example__.apiVersion | string | chart default for this kind | Per-resource apiVersion override. |
| gateways.__helm_docs_example__.labels | object | `{}` | Resource-specific labels. |
| gateways.__helm_docs_example__.namespace | string | release namespace | Namespace for namespaced resources. Defaults to the Helm release namespace. Ignored for cluster-scoped kinds. |
| gateways.__helm_docs_example__.spec | object | `{}` | Resource spec rendered as-is. |
| gateways.__helm_docs_example__.status | object | `{}` | Optional resource status rendered as-is. |
| global | object | `{}` | Compatibility values inherited from umbrella charts. Accepted but ignored by this chart. |
| grpcRoutes | object | {} | GRPCRoute resources keyed by resource name. |
| grpcRoutes.__helm_docs_example__.annotations | object | `{}` | Resource-specific annotations. |
| grpcRoutes.__helm_docs_example__.apiVersion | string | chart default for this kind | Per-resource apiVersion override. |
| grpcRoutes.__helm_docs_example__.labels | object | `{}` | Resource-specific labels. |
| grpcRoutes.__helm_docs_example__.namespace | string | release namespace | Namespace for namespaced resources. Defaults to the Helm release namespace. Ignored for cluster-scoped kinds. |
| grpcRoutes.__helm_docs_example__.spec | object | `{}` | Resource spec rendered as-is. |
| grpcRoutes.__helm_docs_example__.status | object | `{}` | Optional resource status rendered as-is. |
| httpRoutes | object | {} | HTTPRoute resources keyed by resource name. |
| httpRoutes.__helm_docs_example__.annotations | object | `{}` | Resource-specific annotations. |
| httpRoutes.__helm_docs_example__.apiVersion | string | chart default for this kind | Per-resource apiVersion override. |
| httpRoutes.__helm_docs_example__.labels | object | `{}` | Resource-specific labels. |
| httpRoutes.__helm_docs_example__.namespace | string | release namespace | Namespace for namespaced resources. Defaults to the Helm release namespace. Ignored for cluster-scoped kinds. |
| httpRoutes.__helm_docs_example__.spec | object | `{}` | Resource spec rendered as-is. |
| httpRoutes.__helm_docs_example__.status | object | `{}` | Optional resource status rendered as-is. |
| listenerSets | object | {} | ListenerSet resources keyed by resource name. |
| listenerSets.__helm_docs_example__.annotations | object | `{}` | Resource-specific annotations. |
| listenerSets.__helm_docs_example__.apiVersion | string | chart default for this kind | Per-resource apiVersion override. |
| listenerSets.__helm_docs_example__.labels | object | `{}` | Resource-specific labels. |
| listenerSets.__helm_docs_example__.namespace | string | release namespace | Namespace for namespaced resources. Defaults to the Helm release namespace. Ignored for cluster-scoped kinds. |
| listenerSets.__helm_docs_example__.spec | object | `{}` | Resource spec rendered as-is. |
| listenerSets.__helm_docs_example__.status | object | `{}` | Optional resource status rendered as-is. |
| nameOverride | string | `""` | Override the default chart label name if needed. |
| referenceGrants | object | {} | ReferenceGrant resources keyed by resource name. |
| referenceGrants.__helm_docs_example__.annotations | object | `{}` | Resource-specific annotations. |
| referenceGrants.__helm_docs_example__.apiVersion | string | chart default for this kind | Per-resource apiVersion override. |
| referenceGrants.__helm_docs_example__.labels | object | `{}` | Resource-specific labels. |
| referenceGrants.__helm_docs_example__.namespace | string | release namespace | Namespace for namespaced resources. Defaults to the Helm release namespace. Ignored for cluster-scoped kinds. |
| referenceGrants.__helm_docs_example__.spec | object | `{}` | Resource spec rendered as-is. |
| referenceGrants.__helm_docs_example__.status | object | `{}` | Optional resource status rendered as-is. |
| tlsRoutes | object | {} | TLSRoute resources keyed by resource name. |
| tlsRoutes.__helm_docs_example__.annotations | object | `{}` | Resource-specific annotations. |
| tlsRoutes.__helm_docs_example__.apiVersion | string | chart default for this kind | Per-resource apiVersion override. |
| tlsRoutes.__helm_docs_example__.labels | object | `{}` | Resource-specific labels. |
| tlsRoutes.__helm_docs_example__.namespace | string | release namespace | Namespace for namespaced resources. Defaults to the Helm release namespace. Ignored for cluster-scoped kinds. |
| tlsRoutes.__helm_docs_example__.spec | object | `{}` | Resource spec rendered as-is. |
| tlsRoutes.__helm_docs_example__.status | object | `{}` | Optional resource status rendered as-is. |

## Included Values Files

- [values.yaml](values.yaml): minimal defaults that render no resources.
- [values.yaml.example](values.yaml.example): complete example covering every supported resource type.

Use [values.yaml.example](values.yaml.example) as a starting point and remove the resource-name keys you do not need.

## Testing

The repository uses three test layers:

- `tests/units/` for `helm-unittest` suites and backward compatibility checks
- `tests/e2e/` for local kind-based Helm install checks against real Gateway API CRDs
- `tests/smokes/` for render and schema smoke scenarios

Representative local commands:

```bash
helm lint . -f values.yaml.example
helm template nuc-native-gateway . -f values.yaml.example
helm unittest -f 'tests/units/*_test.yaml' .
sh tests/units/backward_compatibility_test.sh
python3 tests/smokes/run/smoke.py --scenario example-render
make test-e2e
```

Detailed test documentation is available in [docs/TESTS.MD](docs/TESTS.MD).

Local setup instructions for the development and test toolchain are available in [docs/DEPENDENCY.md](docs/DEPENDENCY.md).

The `e2e` layer is intentionally kept out of GitLab CI and is expected to be run locally through [Makefile](Makefile) or directly via `tests/e2e/test-e2e.sh`.

## Notes

- Keep the chart API versions aligned with the Gateway API CRDs installed in the cluster.
- `ListenerSet` support is controller-dependent and may rely on experimental APIs.
- Prefer managing `spec` through Helm and let the controller own `status`.

## Repository Layout

| Path | Purpose |
|------|---------|
| [Chart.yaml](Chart.yaml) | Chart metadata. |
| [values.yaml](values.yaml) | Minimal default values and `helm-docs` source comments. |
| [docs/README.md.gotmpl](docs/README.md.gotmpl) | Template used by `helm-docs` to build `README.md`. |
| [.pre-commit-config.yaml](.pre-commit-config.yaml) | Local hooks, including automatic `helm-docs` generation on commit. |
| [values.yaml.example](values.yaml.example) | Full example configuration. |
| [values.schema.json](values.schema.json) | JSON schema for chart values. |
| [templates/](templates) | One template per supported Gateway API kind plus shared helpers. |
| [tests/units/](tests/units) | Compact Helm unit suites and backward compatibility checks. |
| [tests/e2e/](tests/e2e) | kind-based end-to-end installation checks. |
| [tests/smokes/](tests/smokes) | Smoke scenarios for render and schema validation. |
| [docs/DEPENDENCY.md](docs/DEPENDENCY.md) | Local dependency installation guide for development and tests. |
| [docs/TESTS.MD](docs/TESTS.MD) | Detailed testing documentation. |
