# Setup Guide

This document records the deployment and validation of a containerized
Minecraft Paper server hosted on Microsoft Azure.

The project is designed as a DevOps portfolio project demonstrating Azure,
Linux administration, Docker, GitHub Actions, automation, security, backups,
and monitoring.

## Current Progress

- [x] GitHub repository created
- [x] Initial repository structure created
- [x] Azure resource group created
- [x] Ubuntu virtual machine deployed
- [x] SSH public-key authentication configured
- [x] Ubuntu packages updated
- [x] Docker Engine installed
- [x] Docker Compose installed
- [x] Docker container execution validated
- [ ] Minecraft Paper container deployed
- [ ] Minecraft client connection validated
- [ ] Automated backups configured
- [ ] Restore procedure tested
- [ ] GitHub Actions deployment configured
- [ ] Security hardening completed
- [ ] Monitoring configured
- [ ] Terraform implementation completed

## Deployment Environment

| Component | Configuration |
| Cloud platform | Microsoft Azure |
| Subscription | Azure for Students |
| Resource group | `minecraft-lab` |
| Region | East Asia |
| Virtual machine | `mc-paper-vm-01` |
| Operating system | Ubuntu Server 24.04 LTS |
| VM size | `Standard_B2s_v2` |
| CPU | 2 vCPUs |
| Memory | 8 GiB |
| Authentication | Ed25519 SSH public key |
| Container platform | Docker Engine and Docker Compose |

Real public IP addresses, SSH keys, passwords, and other credentials are not
stored in this repository.

## Container Runtime

Docker Engine was installed from Docker's official Ubuntu repository.

| Component | Installed version |
| Docker Engine | `29.6.1` |
| Docker Compose | `v5.3.1` |
| Docker Buildx | `v0.35.0` |
| containerd | `v2.2.6` |

The installation was validated using:

```bash
sudo systemctl status docker --no-pager
sudo systemctl is-enabled docker
docker version
docker compose version
docker buildx version
containerd --version
docker run --rm hello-world