# managed-cluster-config repository

This repo contains static configuration specific to a "managed" OpenShift Dedicated (OSD) cluster.

## How to use this repo

To add a new SelectorSyncSet, add your yaml manifest to the `deploy` dir, then run the `make` command.

Alternatively you can enable GitHub Actions on your fork and `make` will be ran automatically. Additionally,
the action will create a new commit with the generated files.


# Building

## Dependencies

- oyaml: `pip install oyaml`

# Configuration

All resources in `deploy/` are bundled into a template that is used by config management to apply to target "hive" clusters.  The configuration for this supports two options for deployment.  They can be deployed in the template so they are:

1. deployed directly to the "hive" cluster
2. deployed to the "hive" cluster inside a SelectorSyncSet

Direct deployment (#1) supports resources that are not synced down to OSD clusters.  SelectorSyncSet deployment (#2) supports resoures that _are_ synced down to OSD clusters.  Each are explained in detail here.  The general configuration is managed in a `config.yaml` file in each deploy directory.  Key things of note:

* This file is **optional**!  If not present it's assumed `deploymentMode` is `"SelectorSyncSet"` with no additional configuration.
* Configuration is _not_ inherited by sub-directories!  Every (EVERY) directory in the `deploy/` hierarchy must define a `config.yaml` file.

You must specify a `deploymentMode` property in `config.yaml`.

* `deploymentMode` (optional, default = `"SelectorSyncSet"`) - either "Direct" or "SelectorSyncSet".

## Direct Deployment

You must specify the `environments` where the resource is deployed.  There is no default set of environments.  It is a child of the top level `direct` property.

* `environments` (required, no default) - manages what environments the resources are deployed into.  Valid values are any of `"integration"`, `"stage"`, and `"production"`.

Example to deploy only to all environments:
```yaml
deploymentMode: "Direct"
direct:
    environments: ["integration", "stage", "production"]
```

Example to deploy only to integration and stage:
```yaml
deploymentMode: "Direct"
direct:
    environments: ["integration", "stage"]
```

## SelectorSyncSet Deployment

In the `config.yaml` file you define a top level property `selectorSyncSet`.  Within this configuration is supported for `matchLaels`, `matchExpressions`, `matchLabelsApplyMode`, `resourceApplyMode`, and `applyBehavior`.

* `matchLabels` (optional, default: `{}`) - adds additional `matchLabels` conditions to the SelectorSyncSet's `clusterDeploymentSelector`
* `matchExpressions` (optional, default: `[]`) - adds `matchExpressions` conditions to the SelectoSyncSet's `clusterDeploymentSelector`
* `resourceApplyMode` (optional, default: `"Sync"`) - sets the SelectorSyncSet's `resourceApplyMode`
* `matchLabelsApplyMode` (optional, default: `"AND"`) - When set as `"OR"` generates a separate SSS per `matchLabels` conditions. Default behavior creates a single SSS with all `matchLabels` conditions.  This is to tackle a situation where we want to apply configuration for one of many label conditions.
* `applyBehavior` (optional, default: None, [see hive default](https://github.com/openshift/hive/blob/master/config/crds/hive.openshift.io_selectorsyncsets.yaml)) - sets the SelectorSyncSet's `applyBehavior`

Example to apply a directory for any of a set of label conditions using Upsert:
```yaml
deploymentMode: "SelectorSyncSet"
selectorSyncSet:
    matchLabels:
        myAwesomeLabel: "some value"
        someOtherLabel: "something else"
    resourceApplyMode: "Upsert"
    matchLabelsApplyMode: "OR"
```

# Selector Sync Sets included in this repo

## Prometheus

A set of rules and alerts that SRE requires to ensure a cluster is functioning.  There are two categories of rules and alerts found here:

1. SRE specific, will never be part of OCP
2. Temporary addition until made part of OCP

## Prometheus and Alertmanager persistent storage

Persistent storage is configured using the configmap `cluster-monitoring-config`, which is read by the cluster-monitoring-operator to generate PersistentVolumeClaims and attach them to the Prometheus and Alertmanager pods.

## SRE Authorization

Instead of SRE having the `cluster-admin` role, a new ClusterRole, `osd-sre-admin`, is created with some permissions removed.  The ClusterRole can be regenerated in the `generate/sre-authorization` directory.  The role is granted to SRE via `osd-sre-admins` group.

To elevate privileges, SRE can add themselves to the group `osd-sre-cluster-admins`, which is bound to the ClusterRole `cluster-admin`.  When this group is created and managed by Hive, all users are wiped because the SelectorSyncSet will always have `users: null`.  Therefore, SRE will get elevated privileges for a limited time.

## Curated Operators

Initially OSD will support a subset of operators only.  These are managed by patching the OCP shipped OperatorSource CRs.  See `deploy/osd-curated-operators`.

NOTE that ClusterVersion is being patched to add overrides.  If other overrides are needed we'll have to tune how we do this patching.  It must be done along with the OperatorSource patching to ensure CVO doesn't revert the OperatorSource patching.

## Console Branding

In OSD, managed-cluster-config sets a [key named `branding` to `dedicated`](https://github.com/openshift/managed-cluster-config/blob/master/deploy/osd-console-branding/osd-branding.console.yaml) in the [Console operator](https://github.com/openshift/api/blob/master/operator/v1/types_console.go#L81-L128). This value is in turn read by code that applies the [logo](https://github.com/openshift/console/blob/1572a985cc0753d7e2630984c5163170765e9487/frontend/public/components/masthead.jsx) and [other branding elements](https://github.com/openshift/console/search?p=2&q=dedicated) predefined for that value.

## OAuth Templates

Docs TBA.

## Resource Quotas

Refer to [deploy/resource/quotas/README.md](deploy/resource/quotas/README.md).

## Image Pruning

Docs TBA.

## Logging

Prepares the cluster for `elasticsearch` and `logging` operator installation and pre-configures curator to retain 2 days of indexes (1 day for operations).

To opt-in to logging, the customer must:
1. install the `logging` operator
2. install the `elasticsearch` operator
3. create `ClusterLogging` CR in `openshift-logging`

# Dependencies

pyyaml


# Additional Scripts

There are additional scripts in this repo as a holding place for a better place or a better solution / process.
