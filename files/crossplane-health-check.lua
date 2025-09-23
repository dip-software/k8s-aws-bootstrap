-- Source: https://docs.crossplane.io/latest/guides/crossplane-with-argo-cd/
-- Default health status for resources being provisioned
local DEFAULT_HEALTH_STATUS = {
  status = "Progressing",
  message = "Provisioning…"
}

-- Health status constants
local HEALTH_STATUS = {
  HEALTHY = "Healthy",
  DEGRADED = "Degraded",
  PROGRESSING = "Progressing"
}

-- Resource kinds that don't have status conditions but are considered healthy by default
local RESOURCES_WITHOUT_STATUS = {
  "Composition",
  "CompositionRevision", 
  "ControllerConfig",
  "DeploymentRuntimeConfig",
  "EnvironmentConfig",
  "ProviderConfig",
  "ProviderConfigUsage"
}

-- Condition types that indicate a healthy resource
local HEALTHY_CONDITION_TYPES = {
  "Ready",
  "Healthy", 
  "Offered",
  "Established"
}

-- Critical condition types that affect resource health
local CRITICAL_CONDITION_TYPES = {
  "LastAsyncOperation",
  "Synced"
}

-- Utility function to check if a value exists in a table
local function contains(table, val)
  if not table or not val then
    return false
  end
  
  for _, v in ipairs(table) do
    if v == val then
      return true
    end
  end
  return false
end

-- Create a health status response
local function create_health_status(status, message)
  return {
    status = status,
    message = message or ""
  }
end

-- Handle resources that don't have status by design
local function handle_resources_without_status()
  if not obj or not obj.kind then
    return nil
  end
  
  if obj.status == nil and contains(RESOURCES_WITHOUT_STATUS, obj.kind) then
    return create_health_status(HEALTH_STATUS.HEALTHY, "Resource is up-to-date.")
  end
  
  return nil
end

-- Handle ProviderConfig resources specially
local function handle_provider_config()
  if not obj or obj.kind ~= "ProviderConfig" then
    return nil
  end
  
  if obj.status == nil or obj.status.conditions == nil then
    local message = "Resource is configured."
    if obj.status and obj.status.users ~= nil then
      message = "Resource is in use."
    end
    return create_health_status(HEALTH_STATUS.HEALTHY, message)
  end
  
  return nil
end

-- Check critical conditions that indicate degraded health
local function check_critical_conditions(conditions)
  for _, condition in ipairs(conditions) do
    if contains(CRITICAL_CONDITION_TYPES, condition.type) then
      if condition.status == "False" then
        local message = condition.message or ("Condition " .. condition.type .. " is False")
        return create_health_status(HEALTH_STATUS.DEGRADED, message)
      end
    end
  end
  return nil
end

-- Check for healthy conditions
local function check_healthy_conditions(conditions)
  for _, condition in ipairs(conditions) do
    if contains(HEALTHY_CONDITION_TYPES, condition.type) then
      if condition.status == "True" then
        return create_health_status(HEALTH_STATUS.HEALTHY, "Resource is up-to-date.")
      end
    end
  end
  return nil
end

-- Main health check logic
local function determine_health_status()
  -- Input validation
  if not obj then
    return create_health_status(HEALTH_STATUS.DEGRADED, "Resource object is nil")
  end
  
  -- Handle resources without status
  local result = handle_resources_without_status()
  if result then
    return result
  end
  
  -- Handle ProviderConfig specially
  result = handle_provider_config()
  if result then
    return result
  end
  
  -- If no status or conditions, default to progressing
  if not obj.status or not obj.status.conditions then
    return DEFAULT_HEALTH_STATUS
  end
  
  -- Check critical conditions first (they take precedence)
  result = check_critical_conditions(obj.status.conditions)
  if result then
    return result
  end
  
  -- Check for healthy conditions
  result = check_healthy_conditions(obj.status.conditions)
  if result then
    return result
  end
  
  -- Default case: still progressing
  return DEFAULT_HEALTH_STATUS
end

-- Execute the health check and return the result
return determine_health_status()
