# Test Guide

The repository uses three test layers:

- `tests/units/`: `helm-unittest` coverage for helper behavior, defaulting, namespace handling, API version overrides, and example rendering.
- `tests/smokes/`: render-path checks without a live cluster.
- `tests/e2e/`: local `kind` install that bootstraps vendored KServe CRDs and verifies the rendered custom resources can be created by the API server.

## Fast Checks

```bash
make lint
make test-unit
make test-smoke-fast
```

## Full Local Checks

```bash
make test-compat
make test-smoke
make test-e2e
```

## E2E Flow

`tests/e2e/test-e2e.sh` does the following:

1. creates a disposable `kind` cluster
2. installs vendored CRDs from `tests/e2e/crds/`
3. creates the namespaces used by `values.yaml.example`
4. runs `helm upgrade --install`
5. checks that all nine KServe resources from the example values exist

The script deletes the cluster on exit and dumps cluster state on failure.
