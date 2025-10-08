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
        "/overlays/nginx/.*.(yaml|yml)/"
      ],
      matchStrings: [
        '# renovate:\\s+?datasource=(?<datasource>\\S+?)\\s+?depName=(?<depName>\\S+?)\\s+?(default|(?i:.*version))\\s?(:|=|:=|\\?=)\\s?"?(?<currentValue>\\S+?)"\\s',
      ],
    },
  ],
  packageRules: [
    {
      matchDatasources: ["helm", "docker", "github-releases"],
    },
  ],
};
