{{/*
Validate that required values are not empty
*/}}
{{- define "bootstrap.validateRequiredValues" -}}
{{- $requiredValues := list
  (dict "path" "environmentConfig.bootstrap.resourcePrefix" "value" .Values.environmentConfig.bootstrap.resourcePrefix)
  (dict "path" "environmentConfig.bootstrap.awsAccountId" "value" .Values.environmentConfig.bootstrap.awsAccountId)
  (dict "path" "environmentConfig.bootstrap.awsPartition" "value" .Values.environmentConfig.bootstrap.awsPartition)
  (dict "path" "environmentConfig.bootstrap.awsRegion" "value" .Values.environmentConfig.bootstrap.awsRegion)
  (dict "path" "environmentConfig.bootstrap.clusterName" "value" .Values.environmentConfig.bootstrap.clusterName)
  (dict "path" "environmentConfig.bootstrap.clusterFqdn" "value" .Values.environmentConfig.bootstrap.clusterFqdn)
  (dict "path" "environmentConfig.bootstrap.clusterHost" "value" .Values.environmentConfig.bootstrap.clusterHost)
  (dict "path" "environmentConfig.bootstrap.clusterEndpoint" "value" .Values.environmentConfig.bootstrap.clusterEndpoint)
  (dict "path" "environmentConfig.bootstrap.oidcProvider" "value" .Values.environmentConfig.bootstrap.oidcProvider)
  (dict "path" "environmentConfig.bootstrap.oidcProviderArn" "value" .Values.environmentConfig.bootstrap.oidcProviderArn)
  (dict "path" "environmentConfig.bootstrap.awsVpcId" "value" .Values.environmentConfig.bootstrap.awsVpcId)
  (dict "path" "environmentConfig.bootstrap.awsLbcRoleArn" "value" .Values.environmentConfig.bootstrap.awsLbcRoleArn)
  (dict "path" "environmentConfig.bootstrap.awsEbsCsiDriverRoleArn" "value" .Values.environmentConfig.bootstrap.awsEbsCsiDriverRoleArn)
  (dict "path" "environmentConfig.bootstrap.awsExternalDnsRoleArn" "value" .Values.environmentConfig.bootstrap.awsExternalDnsRoleArn)
  (dict "path" "environmentConfig.bootstrap.certManagerRoleArn" "value" .Values.environmentConfig.bootstrap.certManagerRoleArn)
  (dict "path" "environmentConfig.bootstrap.karpenterRoleArn" "value" .Values.environmentConfig.bootstrap.karpenterRoleArn)
  (dict "path" "environmentConfig.bootstrap.crossplaneProviderAwsIamRoleArn" "value" .Values.environmentConfig.bootstrap.crossplaneProviderAwsIamRoleArn)
  (dict "path" "environmentConfig.bootstrap.karpenterInstanceProfile" "value" .Values.environmentConfig.bootstrap.karpenterInstanceProfile)
-}}
{{- range $requiredValues -}}
  {{- if not .value -}}
    {{- fail (printf "Value '%s' is required but not set in values.yaml" .path) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate HSP AWS Platform required values when enabled
*/}}
{{- define "bootstrap.validateHspAwsPlatformValues" -}}
{{- if .Values.features.hspAwsPlatform.enabled -}}
{{- $requiredValues := list
  (dict "path" "environmentConfig.sharedServicesAccountId" "value" .Values.environmentConfig.sharedServicesAccountId)
  (dict "path" "environmentConfig.bootstrap.awsPrivateSubnetIds" "value" .Values.environmentConfig.bootstrap.awsPrivateSubnetIds)
  (dict "path" "environmentConfig.bootstrap.awsRdsSubnetGroup" "value" .Values.environmentConfig.bootstrap.awsRdsSubnetGroup)
  (dict "path" "environmentConfig.bootstrap.awsRedshiftSubnetGroup" "value" .Values.environmentConfig.bootstrap.awsRedshiftSubnetGroup)
  (dict "path" "environmentConfig.bootstrap.awsElasticacheSubnetGroup" "value" .Values.environmentConfig.bootstrap.awsElasticacheSubnetGroup)
  (dict "path" "environmentConfig.bootstrap.awsRdsSecurityGroups" "value" .Values.environmentConfig.bootstrap.awsRdsSecurityGroups)
  (dict "path" "environmentConfig.bootstrap.awsRedshiftSecurityGroups" "value" .Values.environmentConfig.bootstrap.awsRedshiftSecurityGroups)
  (dict "path" "environmentConfig.bootstrap.awsElasticacheSecurityGroups" "value" .Values.environmentConfig.bootstrap.awsElasticacheSecurityGroups)
  (dict "path" "environmentConfig.bootstrap.awsActivemqSecurityGroups" "value" .Values.environmentConfig.bootstrap.awsActivemqSecurityGroups)
-}}
{{- range $requiredValues -}}
  {{- if not .value -}}
    {{- fail (printf "Value '%s' is required when features.hspAwsPlatform.enabled is true" .path) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate K3S values for Karpenter EC2NodeClass
*/}}
{{- define "bootstrap.validateK3sValues" -}}
{{- $requiredValues := list
  (dict "path" "environmentConfig.bootstrap.k3sTokenParameterName" "value" .Values.environmentConfig.bootstrap.k3sTokenParameterName)
  (dict "path" "environmentConfig.bootstrap.k3sVersionParameterName" "value" .Values.environmentConfig.bootstrap.k3sVersionParameterName)
-}}
{{- range $requiredValues -}}
  {{- if not .value -}}
    {{- fail (printf "Value '%s' is required for K3S node provisioning" .path) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
