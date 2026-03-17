# NUC KServe

Helm chart for rendering KServe custom resources from declarative values.

The chart does not install KServe CRDs or controllers. It renders these KServe resource kinds:

- `ClusterServingRuntime`
- `ClusterStorageContainer`
- `InferenceGraph`
- `InferenceService`
- `LocalModelCache`
- `LocalModelNodeGroup`
- `LocalModelNode`
- `ServingRuntime`
- `TrainedModel`

## Quick Start

Render the example configuration:

```bash
helm template nuc-kserve . -f values.yaml.example
```

Install the chart:

```bash
helm install nuc-kserve . \
  --namespace kserve \
  --create-namespace \
  -f values.yaml.example
```
