# infrastructure

RIDI Pay infrastructure as code.

## Workspaces Guide

We use [Workspaces](https://www.terraform.io/docs/state/workspaces.html) to manage different environments (production, dev, etc.) in a single configuration.

- List Workspaces

```
$ terraform workspace list
* default
  staging
```

- Select a Workspace

```
$ terraform workspace select staging
```

- Create a new Workspace

```
$ terraform workspace new test
Created and switched to workspace "test"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
```

# Diagram
- Backend
![](https://pay-infra.s3.ap-northeast-2.amazonaws.com/backend-infra.svg)
