# Terraform ECS Example

## Terraform Overview

Terraform is branded as a cloud-agnostic infrastructure-as-code management service. It encourages declarative, collaborative, repeatable infrstructure definitions.

Terraform provides a way to write infrastructure-as-code in a declarative manner. This allows it to be committed to a software version control system, collaborated upon, and evolve with the project it ultimately hosts.

## What Terraform Is Not

The cloud-agnostic protion of Terraform's description hints at an abstraction layer above a cloud providers infrastructure. Before exploring what Terraform offers, it hinted to me that migration from provider A to provider be would require minimal changes to the Terraform infrastructure definitions.

This, however, is not the case. A deep understanding of the cloud providers ecosystem is required to define infrastructure. In this example, an AWS ECS Fargate application was deployed. While not extremely complicated, a deep understanding of AWS's EC2, ALB, IGW, and ECS services is required.

Further, Terraform does not address the need for a deployment pipeline. This is beyond the scope of Terraform. While the groundwork for a pipeline can be laid in the Terraform domain-specific language, it is up to the writer to devise and maintain.

## Application

This repository deploys a [simple Express server image](https://hub.docker.com/repository/docker/ashtonmeuser/dockerized-express/builds). It is used merely as a simple example or placeholder application.

## Architecture

Defined in the Terraform files is the application architecture.

### VPC

The VPC defined in this repository is contained, by default, in the Canadian region, `ca-central-1`. Within this region, the VPC spans two availability zones, or AZs.

```
TODO: A lot
```

## Getting Started

### Prerequisites

Before you begin, you must have the [AWS CLI](https://aws.amazon.com/cli/) installed and configured with at least a `default` profile. This configuration is beyond the scope of this example.

By default, the `default` AWS CLI profile is used. If you would like to overwrite this, or any other variable, create a `terraform.tfvars` file with the following format.

```
aws_profile = "my_custom_profile"
```

### Deploying

Navigate to the `/terraform` directory. All Terraform plugins (specific to provider) are installed by running `terraform init`.

To view what resources will be created, run `terraform plan`. If things look good, run `terraform apply`, review the changes, and enter `yes` when prompted.

This should generate an "output" that displays the DNS name for the load balancer. To display the outputs again, run `terraform output`. Navigating to this address should display the example application.

## Gotchas

The most popular VS Code extension for Terraform DSL, `mauve.terraform`, does not yet support Terraform 0.12 syntax. Ignore VS Code warnings/errors. See [GH issue](https://github.com/hashicorp/vscode-terraform/issues/157).
