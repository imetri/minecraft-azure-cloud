# Setup Guide

This document records the complete deployment process for the Minecraft Paper
server infrastructure.

## Current Progress

- [x] GitHub repository created
- [x] Initial repository structure created
- [x] Azure resource group created
- [x] Ubuntu virtual machine deployed
- [x] SSH access configured
- [x] Docker installed
- [ ] Minecraft Paper container deployed
- [ ] GitHub Actions configured
- [ ] Automated backups configured
- [ ] Monitoring configured
- [ ] Terraform implementation completed

## Container Runtime

- Docker Engine: `Docker version 29.6.1, build 8900f1d`
- Docker Compose: `Docker Compose version v5.3.1`
- Docker Buildx: `github.com/docker/buildx v0.35.0 a319e5b15052cf6557ceb666eb8ff6e32380b782`
- containerd: `containerd containerd v2.2.6 11ce9d5f3c68c941867e82890e93e815c1304f1b

## Persistent Data Storage

Minecraft runtime data is stored outside the Docker container using persistent host directories (volumes):

- `/srv/minecraft/data` is mounted to `/data` inside the container. This directory stores the Minecraft world, server configuration, plugins, and log files.
- `/srv/minecraft/backups` stores local backup archives of the server data.

By keeping server data outside the container, the Minecraft server can be stopped, updated, or recreated without losing player progress or configuration files. This separation makes the server easier to maintain and recover if something goes wrong.