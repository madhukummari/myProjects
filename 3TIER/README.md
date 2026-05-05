# 3-Tier AWS Infrastructure with Terraform

This Terraform project creates a highly available, scalable 3-tier architecture on AWS. It implements infrastructure best practices with modular design, security controls, and multi-AZ deployment.

## Architecture Overview

The infrastructure consists of three tiers deployed across multiple availability zones:

```
┌─────────────────────────────────────────────────────┐
│           Internet Users                             │
└──────────────────┬──────────────────────────────────┘
                   │
        ┌──────────▼──────────┐
        │  Internet Gateway   │
        └──────────┬──────────┘
                   │
    ┌──────────────┴──────────────┐
    │                             │
┌───▼────────────────────────────▼───┐
│    Web Tier (Public Subnets)       │
│  ┌─────────────┐ ┌─────────────┐  │
│  │   Web-A     │ │   Web-B     │  │
│  │  (us-east   │ │  (us-east   │  │
│  │    1a)      │ │    1b)      │  │
│  └─────────────┘ └─────────────┘  │
└───┬────────────────────────────────┘
    │
    └───────────────────────────────────────────┐
                                               │
                ┌──────────────────────────────▼────────┐
                │  App Tier (Private Subnets)          │
                │ ┌──────────────┐ ┌──────────────┐   │
                │ │   App-A      │ │   App-B      │   │
                │ │  (us-east    │ │  (us-east    │   │
                │ │   1a)        │ │   1b)        │   │
                │ └──────────────┘ └──────────────┘   │
                └──────────────────────────────────────┘
                                   │
                ┌──────────────────▼────────────────────┐
                │  DB Tier (DB Private Subnets)        │
                │         RDS MySQL Instance           │
                │  Multi-AZ Subnet Group               │
                └────────────────────────────────────────┘
```

## Modules

### 1. VPC Module (`modules/vpc/`)
**Purpose:** Creates the network infrastructure foundation

**Resources Created:**
- **VPC**: Main Virtual Private Cloud with DNS support enabled
- **Internet Gateway**: Entry point for internet traffic
- **Public Subnets**: 2 subnets across availability zones for web tier
  - Subnet A: 10.0.1.0/24 (us-east-1a)
  - Subnet B: 10.0.2.0/24 (us-east-1b)
- **Private Subnets (App Tier)**: 2 subnets for application servers
  - Subnet A: 10.0.11.0/24 (us-east-1a)
  - Subnet B: 10.0.12.0/24 (us-east-1b)
- **Private Subnets (DB Tier)**: 2 subnets for database
  - Subnet A: 10.0.21.0/24 (us-east-1a)
  - Subnet B: 10.0.22.0/24 (us-east-1b)
- **Route Tables**: Public and private route tables for traffic routing

**Key Features:**
- Multi-AZ deployment for high availability
- Automatic availability zone discovery
- Proper CIDR planning for scalability

---

### 2. Security Module (`modules/security/`)
**Purpose:** Manages all security controls, access, and authentication

**Resources Created:**

#### Network Access Layer
- **Network ACLs (NACLs)**: Stateless firewall rules
  - SSH (Port 22): Open to all (0.0.0.0/0)
  - HTTP (Port 80): Open to all (0.0.0.0/0)
  - HTTPS (Port 443): Open to all (0.0.0.0/0)
  - Outbound: All traffic allowed

#### Identity & Access Management
- **SSM IAM Role**: Allows EC2 instances to use AWS Systems Manager
  - Policy: `AmazonSSMManagedInstanceCore`
  - Enables Session Manager access without SSH keys
  - Supports parameter store access for secrets

#### Security Groups (Layer-Based)
Security groups implement a layered security model:

| Layer | Ports | Source | Purpose |
|-------|-------|--------|---------|
| ALB | 80, 443 | 0.0.0.0/0 | Load balancer internet access |
| Web | 80 | ALB SG | Web servers receive from ALB only |
| App | 8080, 8081 | Web SG | App servers receive from web tier only |
| DB | 3306 | App SG | MySQL database from app tier only |

---

### 3. Web Module (`modules/web/`)
**Purpose:** Creates and manages the web tier servers

**Resources Created:**
- **2 EC2 Instances** (Web-A, Web-B)
  - Instance Type: Configurable (default: t2.micro or similar)
  - AMI: Amazon Linux 2 (latest)
  - Placement: Public subnets across 2 AZs
  - Availability Zones: us-east-1a, us-east-1b

**Features:**
- **IAM Instance Profile**: Enables SSM Session Manager access
- **Security Group**: Web tier security group
- **High Availability**: 2 instances across different AZs
- **Auto-Discovery**: Automatically selects latest Amazon Linux 2 AMI

**Typical Use Cases:**
- Nginx/Apache web servers
- Reverse proxies
- Static content serving

---

### 4. App Module (`modules/app/`)
**Purpose:** Creates and manages the application tier servers

**Resources Created:**
- **2 EC2 Instances** (App-A, App-B)
  - Instance Type: Configurable
  - AMI: Amazon Linux 2 (latest)
  - Placement: Private subnets across 2 AZs
  - Availability Zones: us-east-1a, us-east-1b

**Features:**
- **IAM Instance Profile**: SSM Session Manager access
- **Security Group**: App tier security group
- **Private Subnets**: No direct internet access
- **High Availability**: 2 instances for redundancy

**Typical Use Cases:**
- Node.js/Express applications
- Python Django/Flask applications
- Java Spring Boot applications
- Microservices

---

### 5. DB Module (`modules/db/`)
**Purpose:** Creates and manages the database tier

**Resources Created:**
- **RDS Instance**: Managed relational database
  - Engine: MySQL (configurable version)
  - Multi-AZ Deployment: DB subnet group for automatic failover
  - Credentials: Retrieved from AWS Systems Manager Parameter Store
    - Parameter `/db/username`: Database username
    - Parameter `/db/password`: Database password
  - Security Group: DB tier security group (port 3306)

**Features:**
- **DB Subnet Group**: Spans 2 availability zones for high availability
- **Automatic Backups**: Configured via variables
- **Encrypted State**: Stored in S3 backend
- **Secrets Management**: Uses SSM Parameter Store for credentials

**Database Details:**
- Accessible only from app tier (port 3306)
- Multi-AZ for automatic failover
- Regular snapshots and backups

---

## Project Structure

```
3TIER/
├── README.md                           # This file
├── main.tf                            # Root module - calls all submodules
├── provider.tf                        # AWS provider and backend configuration
├── variable.tf                        # Input variables
├── output.tf                          # Output values
├── dev.tfvar                          # Development environment variables
└── modules/
    ├── ReadME.md
    ├── vpc/
    │   ├── main.tf                   # VPC resources
    │   ├── variable.tf               # VPC input variables
    │   ├── output.tf                 # VPC outputs (VPC ID, subnet IDs, etc.)
    │   └── provider.tf               # VPC provider config
    ├── security/
    │   ├── main.tf                   # Security resources (SGs, NACLs, IAM)
    │   ├── variable.tf               # Security input variables
    │   ├── output.tf                 # Security outputs
    │   └── provider.tf               # Security provider config
    ├── web/
    │   ├── main.tf                   # Web tier EC2 instances
    │   ├── variable.tf               # Web tier variables
    │   ├── output.tf                 # Web tier outputs
    │   └── provider.tf               # Web tier provider config
    ├── app/
    │   ├── main.tf                   # App tier EC2 instances
    │   ├── variable.tf               # App tier variables
    │   ├── output.tf                 # App tier outputs
    │   └── provider.tf               # App tier provider config
    └── db/
        ├── main.tf                   # Database resources
        ├── variable.tf               # Database variables
        ├── output.tf                 # Database outputs
        └── provider.tf               # Database provider config
```

---

## Configuration & Deployment

### Prerequisites

1. **AWS Account**: Active AWS account with appropriate credentials
2. **Terraform**: Version ~> 5.0 of Terraform installed
3. **S3 Backend**: S3 bucket for state storage (terraform-state-bucket-3692)
4. **DynamoDB Table**: For state locking (terraform-locks)
5. **SSM Parameters**: Database credentials stored in Parameter Store:
   - `/db/username`
   - `/db/password`

### Development Environment Variables (dev.tfvar)

```hcl
region                = "us-east-1"
project_name          = "stationary-app"
vpc_cidr              = "10.0.0.0/16"

# Public Subnets
public_subnet_a_cidr  = "10.0.1.0/24"
public_subnet_b_cidr  = "10.0.2.0/24"

# App Subnets (Private)
app_subnet_a_cidr     = "10.0.11.0/24"
app_subnet_b_cidr     = "10.0.12.0/24"

# DB Subnets (Private)
db_subnet_a_cidr      = "10.0.21.0/24"
db_subnet_b_cidr      = "10.0.22.0/24"

# Availability Zones
az_a                  = "us-east-1a"
az_b                  = "us-east-1b"

# Route Tables
public_rt             = "app-public-rt"
private_rt            = "app-private-rt"
```

### Core Variables (variable.tf)

- `region`: AWS region for deployment
- `project_name`: Project identifier for resource naming
- `vpc_cidr`: CIDR block for VPC
- `instance_type`: EC2 instance type (web and app tier)
- `db_identifier`: Database instance identifier
- `db_allocated_storage`: Storage size in GB
- `db_engine`: Database engine (e.g., mysql)
- `db_engine_version`: Database version
- `db_instance_class`: Database instance type
- `db_name`: Initial database name
- `skip_final_snapshot`: Skip final snapshot on deletion

### State Management

**Backend Configuration (provider.tf):**
```hcl
backend "s3" {
    bucket         = "terraform-state-bucket-3692"
    key            = "state/terraform-modules.tfstate"
    region         = "ap-south-2"
    encrypt        = true
    dynamodb_table = "terraform-locks"
}
```

- **Encrypted State**: All state files are encrypted in S3
- **State Locking**: DynamoDB prevents concurrent modifications
- **Remote Backend**: Team collaboration and CI/CD integration

---

## Deployment Instructions

### Step 1: Initialize Terraform

```bash
terraform init -var-file="dev.tfvar"
```

This command:
- Downloads provider plugins
- Configures S3 backend
- Creates necessary DynamoDB locks

### Step 2: Validate Configuration

```bash
terraform validate
```

Checks syntax and configuration for errors.

### Step 3: Plan Deployment

```bash
terraform plan -var-file="dev.tfvar" -out=tfplan
```

Shows all resources that will be created.

### Step 4: Apply Configuration

```bash
terraform apply tfplan
```

Deploys the infrastructure to AWS.

### Step 5: Verify Deployment

After deployment, verify resources in AWS Console:
- VPC with subnets created
- EC2 instances running in web and app tiers
- RDS database instance created
- Security groups properly configured

---

## Data Flow

1. **Internet → Web Tier**: Traffic enters via Internet Gateway to public subnets
2. **Web Tier → App Tier**: Web servers communicate with app servers via private subnets
3. **App Tier → DB Tier**: Application servers connect to RDS database
4. **Return Path**: Responses flow back through NAT Gateway or similar

---

## Security Features

✅ **Network Security**
- Security groups implement least privilege access
- NACLs provide stateless firewall rules
- Private subnets isolate app and database tiers

✅ **Access Management**
- SSM IAM roles enable passwordless access
- Session Manager for secure SSH alternative
- No hardcoded credentials in infrastructure

✅ **Data Protection**
- Encrypted Terraform state in S3
- Database credentials stored in Parameter Store
- Optional encryption for EBS volumes

✅ **High Availability**
- Multi-AZ deployment across 2 availability zones
- Database subnet group for RDS failover
- Multiple instances in each tier for redundancy

---

## Connectivity & Access

### Web Tier Access
- **Inbound**: HTTP/HTTPS from internet (0.0.0.0/0)
- **Outbound**: To app tier (port 8080, 8081)
- **Access**: SSH via SSM Session Manager

### App Tier Access
- **Inbound**: HTTP/HTTPS from web tier only
- **Outbound**: To database tier (port 3306)
- **Access**: SSH via SSM Session Manager (no direct internet)

### Database Tier Access
- **Inbound**: MySQL port 3306 from app tier only
- **Credentials**: Retrieved from SSM Parameter Store
- **Backups**: Automated by RDS

---

## Customization

### Adding More Instances
Modify instance counts in web/app modules by adjusting the `for_each` loops.

### Changing Instance Types
Update `instance_type` variable to t3.small, t3.medium, etc.

### Adding Additional Security Rules
Extend `locals.layers` in security module for new ports/tiers.

### Scaling Database
Modify `db_allocated_storage` and `db_instance_class` variables.

---

## Cleanup

To destroy all infrastructure:

```bash
terraform destroy -var-file="dev.tfvar"
```

⚠️ **Warning**: This will delete all resources including the RDS database. Ensure you have backups if needed.

---

## Best Practices Implemented

✓ Modular architecture for reusability
✓ Multi-AZ deployment for high availability
✓ Security group-based access control
✓ Remote state management with encryption
✓ IAM roles with minimal permissions
✓ Systems Manager integration for secure access
✓ Automated backup and recovery mechanisms
✓ Clear resource naming conventions
✓ Infrastructure as Code version control

---

## Troubleshooting

### Deployment Fails
- Verify AWS credentials are configured
- Check S3 backend bucket exists
- Ensure DynamoDB table exists for locks

### Instances Not Starting
- Check security group rules
- Verify subnet has available IPs
- Check CloudWatch logs for errors

### Database Connection Issues
- Verify app tier security group has port 3306 access
- Check database credentials in SSM Parameter Store
- Verify database subnet group configuration

### State Lock Issues
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

---

## Team Collaboration

This infrastructure is managed via remote state, enabling team collaboration:

1. All developers use the same S3 backend
2. DynamoDB locks prevent concurrent modifications
3. Terraform plans show all proposed changes
4. Code reviews before applying changes
5. Automated deployments via CI/CD pipelines

---

## Support & Documentation

- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices.html)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)

---

**Last Updated**: May 2026  
**Version**: 1.0  
**Maintainers**: Infrastructure Team
