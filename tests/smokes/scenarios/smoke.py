from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from tests.smokes.steps import chart, helm, kubeconform, render, system


@dataclass
class SmokeContext:
    repo_root: Path
    workdir: Path
    chart_dir: Path
    render_dir: Path
    release_name: str
    namespace: str
    kube_version: str
    kubeconform_bin: str
    schema_location: str
    skip_kinds: str

    @property
    def example_values(self) -> Path:
        return self.repo_root / "values.yaml.example"

    @property
    def rendering_contract_values(self) -> Path:
        return self.repo_root / "tests" / "smokes" / "fixtures" / "rendering-contract.values.yaml"

    @property
    def invalid_missing_name_values(self) -> Path:
        return self.repo_root / "tests" / "smokes" / "fixtures" / "invalid-missing-name.values.yaml"


def check_default_empty(context: SmokeContext) -> None:
    helm.lint(context.chart_dir, workdir=context.workdir)
    output_path = context.render_dir / "default-empty.yaml"
    helm.template(
        context.chart_dir,
        release_name=context.release_name,
        namespace=context.namespace,
        output_path=output_path,
        workdir=context.workdir,
    )
    documents = render.load_documents(output_path)
    render.assert_doc_count(documents, 0)


def check_schema_invalid_missing_name(context: SmokeContext) -> None:
    result = helm.lint(
        context.chart_dir,
        values_file=context.invalid_missing_name_values,
        workdir=context.workdir,
        check=False,
    )
    if result.returncode == 0:
        raise system.TestFailure(
            "helm lint unexpectedly succeeded for invalid values without resource name"
        )

    combined_output = f"{result.stdout}\n{result.stderr}"
    if "missing property 'name'" not in combined_output:
        raise system.TestFailure(
            "helm lint failed for invalid values, but the error does not mention the missing name field"
        )


def check_rendering_contract(context: SmokeContext) -> None:
    helm.lint(
        context.chart_dir,
        values_file=context.rendering_contract_values,
        workdir=context.workdir,
    )
    output_path = context.render_dir / "rendering-contract.yaml"
    helm.template(
        context.chart_dir,
        release_name=context.release_name,
        namespace=context.namespace,
        values_file=context.rendering_contract_values,
        output_path=output_path,
        workdir=context.workdir,
    )

    documents = render.load_documents(output_path)
    render.assert_doc_count(documents, 2)

    inference_service = render.select_document(
        documents, kind="InferenceService", name="merged-inferenceservice"
    )
    render.assert_path(inference_service, "apiVersion", "serving.kserve.io/v1beta1")
    render.assert_path(inference_service, "metadata.namespace", context.namespace)
    render.assert_path(
        inference_service,
        "metadata.labels[app.kubernetes.io/name]",
        "kserve-platform",
    )
    render.assert_path(inference_service, "metadata.labels.platform", "kserve")
    render.assert_path(inference_service, "metadata.labels.component", "inference-service")
    render.assert_path(inference_service, "metadata.labels.tier", "online")
    render.assert_path(inference_service, "metadata.annotations.team", "platform")
    render.assert_path(inference_service, "metadata.annotations.note", "canary")
    render.assert_path(
        inference_service, "spec.predictor.sklearn.storageUri", "s3://models/sklearn"
    )

    cluster_runtime = render.select_document(
        documents, kind="ClusterServingRuntime", name="cluster-runtime"
    )
    render.assert_path(cluster_runtime, "apiVersion", "example.net/v1alpha1")
    render.assert_path_missing(cluster_runtime, "metadata.namespace")
    render.assert_path(
        cluster_runtime,
        "metadata.labels[app.kubernetes.io/name]",
        "kserve-platform",
    )
    render.assert_path(cluster_runtime, "metadata.labels.component", "runtime")
    render.assert_path(cluster_runtime, "metadata.annotations.team", "platform")
    render.assert_path(cluster_runtime, "metadata.annotations.note", "autosync")
    render.assert_path(cluster_runtime, "spec.supportedModelFormats[0].name", "sklearn")


def check_example_render(context: SmokeContext) -> None:
    helm.lint(
        context.chart_dir,
        values_file=context.example_values,
        workdir=context.workdir,
    )
    output_path = context.render_dir / "example-render.yaml"
    helm.template(
        context.chart_dir,
        release_name=context.release_name,
        namespace=context.namespace,
        values_file=context.example_values,
        output_path=output_path,
        workdir=context.workdir,
    )

    documents = render.load_documents(output_path)
    render.assert_doc_count(documents, 9)
    render.assert_kinds(
        documents,
        {
            "ClusterServingRuntime",
            "ClusterStorageContainer",
            "InferenceGraph",
            "InferenceService",
            "LocalModelCache",
            "LocalModelNodeGroup",
            "LocalModelNode",
            "ServingRuntime",
            "TrainedModel",
        },
    )

    inference_service = render.select_document(
        documents, kind="InferenceService", name="sklearn-iris"
    )
    render.assert_path(inference_service, "metadata.namespace", "ml-platform")
    render.assert_path(
        inference_service,
        "spec.predictor.sklearn.storageUri",
        "gs://kfserving-examples/models/sklearn/1.0/model",
    )

    cluster_storage = render.select_document(
        documents, kind="ClusterStorageContainer", name="default-storage"
    )
    render.assert_path(cluster_storage, "spec.workloadType", "initContainer")

    localmodel_group = render.select_document(
        documents, kind="LocalModelNodeGroup", name="ssd-cache-group"
    )
    render.assert_path(localmodel_group, "spec.storageLimit", "100Gi")


def check_example_kubeconform(context: SmokeContext) -> None:
    output_path = context.render_dir / "example-kubeconform.yaml"
    helm.template(
        context.chart_dir,
        release_name=context.release_name,
        namespace=context.namespace,
        values_file=context.example_values,
        output_path=output_path,
        workdir=context.workdir,
    )
    kubeconform.validate(
        manifest_path=output_path,
        kube_version=context.kube_version,
        kubeconform_bin=context.kubeconform_bin,
        schema_location=context.schema_location,
        skip_kinds=context.skip_kinds,
    )


SCENARIOS: list[tuple[str, Callable[[SmokeContext], None]]] = [
    ("default-empty", check_default_empty),
    ("schema-invalid-missing-name", check_schema_invalid_missing_name),
    ("rendering-contract", check_rendering_contract),
    ("example-render", check_example_render),
    ("example-kubeconform", check_example_kubeconform),
]


def run_smoke_suite(args) -> int:
    scenario_map = dict(SCENARIOS)
    requested = args.scenario or ["all"]
    if "all" in requested:
        selected = [name for name, _ in SCENARIOS]
    else:
        selected = requested

    repo_root = Path(args.chart_dir).resolve()
    workdir, chart_dir = chart.stage_chart(repo_root, args.workdir)
    context = SmokeContext(
        repo_root=repo_root,
        workdir=workdir,
        chart_dir=chart_dir,
        render_dir=workdir / "rendered",
        release_name=args.release_name,
        namespace=args.namespace,
        kube_version=args.kube_version,
        kubeconform_bin=args.kubeconform_bin,
        schema_location=args.schema_location,
        skip_kinds=args.skip_kinds,
    )
    context.render_dir.mkdir(parents=True, exist_ok=True)

    failures: list[tuple[str, str]] = []
    try:
        for name in selected:
            system.log(f"=== scenario: {name} ===")
            try:
                scenario_map[name](context)
            except Exception as exc:
                failures.append((name, str(exc)))
                system.log(f"FAILED: {name}: {exc}")
            else:
                system.log(f"PASSED: {name}")
    finally:
        if args.keep_workdir:
            system.log(f"workdir kept at {workdir}")
        else:
            chart.cleanup(workdir)

    if failures:
        system.log("=== summary: failures ===")
        for name, message in failures:
            system.log(f"- {name}: {message}")
        return 1

    system.log("=== summary: all smoke scenarios passed ===")
    return 0
