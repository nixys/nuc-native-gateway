# NUC Native Gateway

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: v1](https://img.shields.io/badge/AppVersion-v1-informational?style=flat-square)

Helm chart for rendering Kubernetes Gateway API resources from declarative values.

This chart does not install Gateway API CRDs or a controller. It renders Gateway API objects that are already supported by your cluster and controller installation.

## TL;DR

```bash
helm install nuc-native-gateway . \
  --namespace gateway-system \
  --create-namespace \
  -f values.yaml.example
```

## Introduction

`nuc-native-gateway` is a generic Helm chart for publishing Gateway API resources from values.

The chart supports these resource kinds:

- `BackendTLSPolicy`
- `GatewayClass`
- `Gateway`
- `GRPCRoute`
- `HTTPRoute`
- `ListenerSet`
- `ReferenceGrant`
- `TLSRoute`

The chart keeps template logic intentionally small:

- each top-level list in `values.yaml` maps to one resource kind
- common labels and annotations are merged into every rendered resource
- namespaced resources default to the Helm release namespace when `namespace` is omitted
- `GatewayClass` is rendered as cluster-scoped
- `apiVersion` can be overridden globally per kind or per resource item
- `status` can be rendered when explicitly provided in values

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| N/A | Helm | 3.x or newer |
| N/A | Kubernetes | cluster with Gateway API CRDs for the resources you render |
| N/A | Controller | any Gateway API implementation that supports your chosen resource set |

Notes:

- the chart does not ship CRDs
- not every controller supports every Gateway API kind or field
- `ListenerSet` support is controller-dependent and may rely on experimental APIs in some environments

## Installing the Chart

To install the chart with the release name `nuc-native-gateway`:

```bash
helm install nuc-native-gateway . \
  --namespace gateway-system \
  --create-namespace \
  -f values.yaml.example
```

To render manifests without installing:

```bash
helm template nuc-native-gateway . -f values.yaml.example
```

To render only your own values:

```bash
helm template nuc-native-gateway . -f my-values.yaml
```

## Uninstalling the Chart

To uninstall/delete the `nuc-native-gateway` deployment:

```bash
helm uninstall nuc-native-gateway --namespace gateway-system
```

This removes only the resources managed by the release. It does not remove Gateway API CRDs from the cluster.

## Upgrading the Chart

To upgrade an existing release:

```bash
helm upgrade nuc-native-gateway . \
  --namespace gateway-system \
  -f my-values.yaml
```

Before upgrading:

- review the rendered output with `helm template`
- check whether your controller supports newly added fields
- keep previous values files if you need rollback or compatibility checks

## Values Files

The chart ships with two useful values files:

- [values.yaml](/home/ruk/nixys/nuc-native-gateway/values.yaml): minimal defaults, renders no resources by default
- [values.yaml.example](/home/ruk/nixys/nuc-native-gateway/values.yaml.example): full example covering all supported resource kinds

Use `values.yaml.example` as a starting point when bootstrapping a new deployment.

## Resource Model

Each supported top-level list follows the same item contract:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Resource name. |
| `namespace` | string | no | Namespace for namespaced resources. Defaults to Helm release namespace. Ignored for cluster-scoped resources. |
| `labels` | map | no | Labels merged on top of built-in chart labels and `commonLabels`. |
| `annotations` | map | no | Annotations merged on top of `commonAnnotations`. |
| `apiVersion` | string | no | Per-resource API version override. |
| `spec` | map | no | Raw resource specification rendered as-is. |
| `status` | map | no | Optional status block rendered as-is. Useful for fixture rendering, but usually not managed through Helm in production. |

Built-in labels added to every rendered resource:

- `app.kubernetes.io/name`
- `app.kubernetes.io/instance`
- `app.kubernetes.io/managed-by`
- `helm.sh/chart`

## Supported Top-Level Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `nameOverride` | string | `""` | Override the chart name used in generated labels. |
| `commonLabels` | map | `{}` | Extra labels merged into every rendered resource. |
| `commonAnnotations` | map | `{}` | Extra annotations merged into every rendered resource. |
| `apiVersions.backendTLSPolicy` | string | `gateway.networking.k8s.io/v1` | Default API version for `BackendTLSPolicy`. |
| `apiVersions.gatewayClass` | string | `gateway.networking.k8s.io/v1` | Default API version for `GatewayClass`. |
| `apiVersions.gateway` | string | `gateway.networking.k8s.io/v1` | Default API version for `Gateway`. |
| `apiVersions.grpcRoute` | string | `gateway.networking.k8s.io/v1` | Default API version for `GRPCRoute`. |
| `apiVersions.httpRoute` | string | `gateway.networking.k8s.io/v1` | Default API version for `HTTPRoute`. |
| `apiVersions.listenerSet` | string | `gateway.networking.k8s.io/v1` | Default API version for `ListenerSet`. |
| `apiVersions.referenceGrant` | string | `gateway.networking.k8s.io/v1` | Default API version for `ReferenceGrant`. |
| `apiVersions.tlsRoute` | string | `gateway.networking.k8s.io/v1` | Default API version for `TLSRoute`. |
| `backendTLSPolicies` | list | `[]` | List of `BackendTLSPolicy` resources. |
| `gatewayClasses` | list | `[]` | List of `GatewayClass` resources. |
| `gateways` | list | `[]` | List of `Gateway` resources. |
| `grpcRoutes` | list | `[]` | List of `GRPCRoute` resources. |
| `httpRoutes` | list | `[]` | List of `HTTPRoute` resources. |
| `listenerSets` | list | `[]` | List of `ListenerSet` resources. |
| `referenceGrants` | list | `[]` | List of `ReferenceGrant` resources. |
| `tlsRoutes` | list | `[]` | List of `TLSRoute` resources. |

## Example

Minimal `GatewayClass` and `Gateway` configuration:

```yaml
commonLabels:
  platform: gateway-api

gatewayClasses:
  - name: public-gateway-class
    spec:
      controllerName: example.net/gateway-controller

gateways:
  - name: edge-gateway
    namespace: edge
    spec:
      gatewayClassName: public-gateway-class
      listeners:
        - name: https
          port: 443
          protocol: HTTPS
```

Render it:

```bash
helm template nuc-native-gateway . -f my-values.yaml
```

## Testing

The repository uses several complementary checks:

- `helm lint`
- `helm unittest` for suites in `tests/units/`
- backward compatibility rendering checks against previous chart tags
- full manifest rendering from `values.yaml.example`
- `kubeconform` validation for supported schemas

Representative local commands:

```bash
helm lint . -f values.yaml.example
helm template nuc-native-gateway . -f values.yaml.example
helm unittest -f 'tests/units/*_test.yaml' .
sh tests/units/backward_compatibility_test.sh
```

## Tips

- Start with [values.yaml.example](/home/ruk/nixys/nuc-native-gateway/values.yaml.example) and delete the resource sections you do not need.
- Keep CRD versions aligned with the Gateway API bundle installed in your cluster.
- Prefer managing `spec` through Helm and let your controller own `status`.
- Use `helm template` in CI or review workflows to inspect exact rendered output before applying changes.

## Source Layout

| Path | Purpose |
|------|---------|
| [Chart.yaml](/home/ruk/nixys/nuc-native-gateway/Chart.yaml) | Chart metadata. |
| [values.yaml](/home/ruk/nixys/nuc-native-gateway/values.yaml) | Minimal defaults. |
| [values.yaml.example](/home/ruk/nixys/nuc-native-gateway/values.yaml.example) | Complete example configuration. |
| [templates/_helpers.tpl](/home/ruk/nixys/nuc-native-gateway/templates/_helpers.tpl) | Shared helper for labels, annotations, namespace handling, and raw spec/status rendering. |
| [templates/](/home/ruk/nixys/nuc-native-gateway/templates) | One template per supported Gateway API kind. |
| [tests/units/](/home/ruk/nixys/nuc-native-gateway/tests/units) | Compact Helm unit suites, fixture values, and backward compatibility script. |
| [tests/smokes/](/home/ruk/nixys/nuc-native-gateway/tests/smokes) | Altinity-style smoke tests for render and schema flows. |
