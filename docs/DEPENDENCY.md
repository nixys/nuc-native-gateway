# Dependency Guide

Install these tools before running the local workflows:

- `git`
- `helm`
- `kubectl`
- `kind`
- `docker`
- `python3`
- `pre-commit`
- `kubeconform`
- Helm plugin `helm-unittest`

## Suggested Verification

```bash
git --version
helm version
kubectl version --client
kind version
docker version
python3 --version
pre-commit --version
kubeconform -v
helm plugin list
```

## Repository Checks

```bash
make lint
make test-unit
make test-smoke-fast
make test-compat
make test-e2e
```
