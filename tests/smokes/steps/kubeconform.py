from __future__ import annotations

import json
from pathlib import Path
import shutil

from tests.smokes.steps import system

REQUIRED_SKIP_KINDS = {
    "ListenerSet",
    "ReferenceGrant",
    "TLSRoute",
}


def _merge_skip_kinds(skip_kinds: str) -> str:
    items: list[str] = []
    seen: set[str] = set()

    def add(value: str) -> None:
        cleaned = value.strip()
        if not cleaned or cleaned in seen:
            return
        seen.add(cleaned)
        items.append(cleaned)

    for raw in skip_kinds.split(","):
        add(raw)

    for required in sorted(REQUIRED_SKIP_KINDS):
        add(required)

    return ",".join(items)


def validate(
    *,
    manifest_path: Path,
    kube_version: str,
    kubeconform_bin: str,
    schema_location: str,
    skip_kinds: str,
) -> dict:
    resolved = kubeconform_bin
    if not Path(kubeconform_bin).is_absolute():
        found = shutil.which(kubeconform_bin)
        if not found:
            raise system.TestFailure(
                f"failed to find kubeconform binary '{kubeconform_bin}' in PATH"
            )
        resolved = found

    command = [
        resolved,
        "-summary",
        "-strict",
        "-output",
        "json",
        "-kubernetes-version",
        kube_version,
        "-schema-location",
        "default",
        "-schema-location",
        schema_location,
    ]
    merged_skip = _merge_skip_kinds(skip_kinds)
    if merged_skip:
        command.extend(["-skip", merged_skip])
    command.append(str(manifest_path))

    result = system.run(command, check=True)
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise system.TestFailure(
            "kubeconform output is not valid JSON"
        ) from exc

    summary = payload.get("summary", {})
    if summary.get("invalid", 0) or summary.get("errors", 0):
        messages = []
        for resource in payload.get("resources", []):
            status = resource.get("status")
            if status in {"statusInvalid", "statusError"}:
                messages.append(
                    f"{resource.get('kind')}/{resource.get('name')}: {resource.get('msg')}"
                )
        raise system.TestFailure(
            "kubeconform validation failed:\n" + "\n".join(messages)
        )

    return payload
