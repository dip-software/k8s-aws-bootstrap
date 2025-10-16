const helmRegex = {
  customType: "regex",
  datasourceTemplate: "helm",
  matchStringsStrategy: "combination",
};

module.exports = {
  username: "renovate[bot]",
  gitAuthor: "Renovate Bot <bot@renovateapp.com>",
  onboarding: false,
  platform: "github",
  forkProcessing: "disabled",
  dryRun: null,
  repositories: ["dip-software/k8s-aws-bootstrap"],
  enabledManagers: ["custom.regex"],
  customManagers: [
    {
      customType: "regex",
      matchStringsStrategy: "any",
      managerFilePatterns: [
        "/.github/workflows/.*.(yaml|yml)/",
        "/.github/actions/.*.(yaml|yml)/",
        "/base/.*.(yaml|yml)/",
        "/base/helm-charts/.*.(yaml|yml)/",
        "/overlays/nginx/.*.(yaml|yml)/",
        "/overlays/hsp-aws-platform/.*.(yaml|yml)/"
      ],
      matchStrings: [
        '# renovate:\\s+?datasource=(?<datasource>\\S+?)\\s+?depName=(?<depName>\\S+?)\\s+?(default|(?i:.*version))\\s?(:|=|:=|\\?=)\\s+"?(?<currentValue>\\S+?)"\\s',
        '# renovate:\\s+?datasource=(?<datasource>\\S+?)\\s+?depName=(?<depName>\\S+?)\\s*\\n\\s*targetRevision:\\s*(?<currentValue>\\S+)',
        '# renovate:\\s+?datasource=(?<datasource>\\S+?)\\s+?registryUrl=(?<registryUrl>\\S+?)\\s+?depName=(?<depName>\\S+?)\\s*\\n\\s*targetRevision:\\s*(?<currentValue>\\S+)',
        '# renovate:\\s+?datasource=(?<datasource>\\S+?)\\s+?depName=(?<depName>\\S+?)\\s*\\n\\s*image:\\s*(?<depName>\\S+?):(?<currentValue>\\S+)',
      ],
    },
  ],
  packageRules: [
    {
      matchDatasources: ["helm", "docker", "github-releases"],
    },
  ],
};
