{{- define "nuc-native-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "nuc-native-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "nuc-native-gateway.labels" -}}
app.kubernetes.io/name: {{ include "nuc-native-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "nuc-native-gateway.chart" . }}
{{- end -}}

{{- define "nuc-native-gateway.renderResource" -}}
{{- $root := .root -}}
{{- $item := .item -}}
{{- $resourceName := .resourceName -}}
{{- $defaultLabels := include "nuc-native-gateway.labels" $root | fromYaml -}}
{{- $labels := mustMergeOverwrite (dict) $defaultLabels ($root.Values.commonLabels | default dict) ($item.labels | default dict) -}}
{{- $annotations := mustMergeOverwrite (dict) ($root.Values.commonAnnotations | default dict) ($item.annotations | default dict) -}}
{{- if ne $resourceName "__helm_docs_example__" }}
apiVersion: {{ default .defaultApiVersion $item.apiVersion }}
kind: {{ .kind }}
metadata:
  name: {{ $resourceName }}
  {{- if .namespaced }}
  namespace: {{ default $root.Release.Namespace $item.namespace }}
  {{- end }}
  labels:
{{ toYaml $labels | nindent 4 }}
  {{- if $annotations }}
  annotations:
{{ toYaml $annotations | nindent 4 }}
  {{- end }}
{{- with $item.spec }}
spec:
{{ toYaml . | nindent 2 }}
{{- end }}
{{- with $item.status }}
status:
{{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- end -}}
{{- define "nuc-native-gateway.renderResources" -}}
{{- $collection := .collection | default dict -}}
{{- range $resourceName := keys $collection | sortAlpha }}
{{- $item := get $collection $resourceName -}}
---
{{ include "nuc-native-gateway.renderResource" (dict
  "root" $.root
  "item" $item
  "resourceName" $resourceName
  "kind" $.kind
  "defaultApiVersion" $.defaultApiVersion
  "namespaced" $.namespaced
) }}
{{ end }}
{{- end -}}
