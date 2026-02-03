---
name: rbac_enforcement_skill
description: Enforces Role-Based Access Control to separate Agency vs Client views.
---

# RBAC Enforcement Skill

## Purpose
To ensure users only see data and options relevant to their role (Super Admin, Agency User, Client Viewer).

## Application Rules
**Apply this skill when:**
- Retrieving sensitive data (financials, strategy).
- Offering actions (Edit, Delete, Approve).

## Core Guidelines

### 1. Role Identification
- Check context: `UserRole` (Admin | Editor | Viewer).
- **Client Viewers**: READ-ONLY access. Cannot see internal agency notes or costs.
- **Agency Editors**: Full access.

### 2. Data Filtering
- **Internal Notes**: If role == Client, hide fields marked `internal_only`.
- **Costs**: Mask agency margins if applicable.

### 3. Action Gating
- If user attempts a restricted action (e.g., "Delete Campaign" as Client), refuse politely: "Insufficient permissions. Please contact your Account Manager."

## Verification Steps
1. **Role Check**: Did the agent verify the role?
2. **Filter Check**: Was sensitive data hidden for lower roles?
