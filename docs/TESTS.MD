# Smoke Tests

This chart includes Altinity-style smoke tests under `tests/smokes/`.

The structure follows the same layered idea as [Altinity helm-charts tests](https://github.com/Altinity/helm-charts/tree/main/tests):

- `run/` contains the entry point
- `scenarios/` orchestrates complete smoke flows
- `steps/` contains reusable operations
- `fixtures/` contains dedicated smoke-test values files

## Directory Layout

```text
tests/smokes/
├── helpers/
│   └── argparser.py
├── fixtures/
│   ├── invalid-missing-name.values.yaml
│   └── rendering-contract.values.yaml
├── run/
│   └── smoke.py
├── scenarios/
│   └── smoke.py
├── steps/
│   ├── chart.py
│   ├── helm.py
│   ├── kubeconform.py
│   ├── render.py
│   └── system.py
└── requirements.txt
```

## Covered Scenarios

The smoke suite currently covers:

1. `default-empty`
   Verifies that the chart renders no manifests with default values.

2. `schema-invalid-missing-name`
   Verifies that `values.schema.json` is active and rejects a resource item without `name`.

3. `rendering-contract`
   Verifies chart-owned behavior rather than CRD payload content:
   - `nameOverride`
   - merged labels and annotations
   - namespace fallback for namespaced resources
   - cluster-scoped `GatewayClass`
   - global and per-resource `apiVersion` override behavior

4. `example-render`
   Renders `values.yaml.example` and verifies that all supported resource kinds are produced from the example configuration.

5. `example-kubeconform`
   Renders `values.yaml.example` and validates the result with `kubeconform` using the same Gateway API CRD schema location as CI.

## Prerequisites

- `python3`
- `helm`
- `kubeconform` for the `example-kubeconform` scenario
- `PyYAML`

Install Python dependency:

```bash
pip3 install -r tests/smokes/requirements.txt
```

## How the Suite Works

The smoke runner does not execute Helm directly in the repository root.

Instead it stages a temporary clean copy of the chart that includes only:

- `Chart.yaml`
- `values.yaml`
- `values.yaml.example`
- `values.schema.json`
- `templates/`

This keeps smoke tests isolated from unrelated files in the repository root and makes Helm execution deterministic.

## Running All Smoke Tests

From the repository root:

```bash
python3 tests/smokes/run/smoke.py
```

## Running Individual Scenarios

Run only one scenario:

```bash
python3 tests/smokes/run/smoke.py --scenario rendering-contract
```

Run multiple scenarios:

```bash
python3 tests/smokes/run/smoke.py \
  --scenario default-empty \
  --scenario example-render
```

## Useful Options

```bash
python3 tests/smokes/run/smoke.py --help
```

Key options:

- `--chart-dir`
  Override the chart repository root.

- `--release-name`
  Release name used for rendered output.

- `--namespace`
  Namespace used for namespaced rendered resources.

- `--kube-version`
  Kubernetes version passed to `kubeconform`.

- `--kubeconform-bin`
  Path or command name for `kubeconform`.

- `--schema-location`
  Additional CRD schema registry used by `kubeconform`.

- `--skip-kinds`
  Comma-separated list of resource kinds skipped in `kubeconform`.

- `--workdir`
  Reuse a specific working directory for staged chart files and rendered manifests.

- `--keep-workdir`
  Keep the staged work directory after the run for debugging.

## Examples

Run smoke tests with explicit kubeconform binary:

```bash
python3 tests/smokes/run/smoke.py \
  --kubeconform-bin /usr/local/bin/kubeconform
```

Keep rendered artifacts for debugging:

```bash
python3 tests/smokes/run/smoke.py --keep-workdir
```

Use a custom schema location:

```bash
python3 tests/smokes/run/smoke.py \
  --schema-location "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"
```

## Adding New Smoke Tests

When adding a new smoke test:

1. Add or reuse a fixture in `tests/smokes/fixtures/` if the scenario needs dedicated values.
2. Add reusable command or assertion logic in `tests/smokes/steps/`.
3. Add an orchestration function in `tests/smokes/scenarios/smoke.py`.
4. Register the scenario in the `SCENARIOS` list.
5. Document any new prerequisites or command-line flags here.

## Troubleshooting

If `helm` fails in the repository root but smoke tests still work, that is expected if the root contains unrelated files that Helm tries to read. The smoke suite stages a clean chart copy on purpose.

If `example-kubeconform` fails:

- verify that `kubeconform` is installed
- verify outbound network access to the configured schema location
- verify that the skip list matches the currently available Gateway API schemas

If Python cannot import `yaml`, install the requirements:

```bash
pip3 install -r tests/smokes/requirements.txt
```
