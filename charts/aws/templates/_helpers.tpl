{{/*
Validate that required values are not empty
*/}}
{{- define "aws.validateRequiredValues" -}}
{{- $requiredValues := list
  (dict "path" "environmentConfig.resourcePrefix" "value" .Values.environmentConfig.resourcePrefix)
  (dict "path" "environmentConfig.accountId" "value" .Values.environmentConfig.accountId)
  (dict "path" "environmentConfig.partition" "value" .Values.environmentConfig.partition)
  (dict "path" "environmentConfig.clusterName" "value" .Values.environmentConfig.clusterName)
  (dict "path" "environmentConfig.clusterFqdn" "value" .Values.environmentConfig.clusterFqdn)
  (dict "path" "environmentConfig.region" "value" .Values.environmentConfig.region)
  (dict "path" "environmentConfig.bootstrap.awsVpcId" "value" .Values.environmentConfig.bootstrap.awsVpcId)
  (dict "path" "environmentConfig.bootstrap.awsExternalDnsRoleArn" "value" .Values.environmentConfig.bootstrap.awsExternalDnsRoleArn)
  (dict "path" "environmentConfig.bootstrap.awsEbsCsiDriverRoleArn" "value" .Values.environmentConfig.bootstrap.awsEbsCsiDriverRoleArn)
  (dict "path" "environmentConfig.bootstrap.awsLbcRoleArn" "value" .Values.environmentConfig.bootstrap.awsLbcRoleArn)
-}}
{{- range $requiredValues -}}
  {{- if not .value -}}
    {{- fail (printf "Value '%s' is required but not set in values.yaml" .path) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
