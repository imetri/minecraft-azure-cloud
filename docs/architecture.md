# Architecture

## Overview

This project deploys a containerized Minecraft Paper server on Microsoft Azure.

## Initial Architecture

```text
Minecraft Client
       |
       | TCP 25565
       v
Azure Public IP
       |
       v
Azure Network Security Group
       |
       v
Ubuntu Virtual Machine
       |
       v
Docker Engine
       |
       v
Minecraft Paper Container