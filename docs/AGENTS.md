# Agent Guide

This repository is a single Helm chart that renders KServe custom resources from a generic values contract.

Keep these invariants when changing the chart:

- `values.yaml` stays minimal and renders nothing by default
- `values.yaml.example` exercises every supported KServe kind
- shared rendering behavior lives in `templates/_helpers.tpl`
- docs, schema, unit tests, smoke tests, and e2e stay aligned in the same change
- `tests/e2e/crds/` remains the source for offline CRD bootstrap in local end-to-end runs
