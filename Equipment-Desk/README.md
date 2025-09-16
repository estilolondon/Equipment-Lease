# Equipment Lease Marketplace Smart Contract

## Overview

The Equipment Lease Marketplace is a comprehensive decentralized platform built on the Stacks blockchain that enables secure equipment leasing through smart contracts. The platform tokenizes equipment leases as NFTs, automates payment processing, tracks maintenance records, and facilitates transferable lease rights.

## Features

### Core Functionality
- **Equipment Registration**: Register and manage equipment assets with detailed metadata
- **Lease Agreement Creation**: Establish comprehensive lease agreements between lessors and lessees
- **NFT-Based Lease Rights**: Each lease is represented as a transferable NFT
- **Automated Payment Processing**: Process monthly payments, security deposits, and penalty fees
- **Maintenance Tracking**: Document and track equipment maintenance history
- **Lease Transfer**: Transfer lease rights to other parties via NFT transfers

### Equipment Categories
The platform supports five equipment categories:
- Construction Equipment
- Medical Equipment
- Industrial Equipment
- Technology Equipment
- Automotive Equipment

### Equipment Conditions
Equipment can be registered in four condition states:
- New
- Excellent
- Good
- Fair

## Contract Architecture

### Data Structures

#### Equipment Asset Registry
Each equipment asset contains:
- Equipment name and detailed description
- Asset owner and estimated value
- Equipment category and current condition
- Availability status
- Next maintenance due date
- Registration timestamp

#### Lease Agreement Registry
Each lease agreement includes:
- Associated equipment ID
- Lessor and lessee principals
- Lease start and end blocks
- Monthly rental amount and security deposit
- Payment tracking and status
- Agreement timestamps

#### Payment Transaction History
Tracks all payment transactions with:
- Payment amount and timestamp
- Payment category (monthly, deposit, penalty, maintenance)
- Paying party information

#### Equipment Maintenance Log
Maintains service records with:
- Maintenance category and cost
- Service provider and timestamp
- Detailed service description

## Public Functions

### Equipment Management

#### `register-equipment-asset`
Register new equipment on the platform.
```
(register-equipment-asset 
  (asset-name (string-ascii 256))
  (asset-description (string-ascii 512))
  (asset-value uint)
  (asset-category (string-ascii 64))
  (asset-condition (string-ascii 32)))
```

#### `modify-equipment-availability`
Update equipment availability status (owner only).
```
(modify-equipment-availability 
  (equipment-id uint)
  (new-availability-status bool))
```

### Lease Management

#### `establish-lease-agreement`
Create a new lease agreement and mint corresponding NFT.
```
(establish-lease-agreement 
  (target-equipment-id uint)
  (prospective-lessee principal)
  (lease-duration-blocks uint)
  (monthly-rental-fee uint)
  (required-deposit uint))
```

#### `terminate-lease-agreement`
End an active lease agreement (lessor or lessee only).
```
(terminate-lease-agreement (target-lease-id uint))
```

### Payment Processing

#### `process-lease-payment`
Process various types of lease payments.
```
(process-lease-payment 
  (target-lease-id uint)
  (transaction-type (string-ascii 32)))
```

Payment types supported:
- `monthly`: Monthly rental payment
- `deposit`: Security deposit payment
- `penalty`: Penalty fee payment
- `maintenance`: Maintenance cost payment

### Maintenance Tracking

#### `document-maintenance-service`
Record maintenance services performed on equipment.
```
(document-maintenance-service 
  (target-equipment-id uint)
  (service-type (string-ascii 64))
  (service-cost uint)
  (service-description (string-ascii 256)))
```

### Lease Rights Transfer

#### `transfer-lease-rights`
Transfer lease rights NFT to a new lessee.
```
(transfer-lease-rights 
  (target-lease-id uint)
  (new-lessee principal))
```

## Read-Only Functions

### Data Retrieval
- `get-equipment-details`: Retrieve equipment information
- `get-lease-agreement-details`: Get lease agreement data
- `get-payment-transaction-details`: Access payment history
- `get-maintenance-service-record`: View maintenance records
- `get-lease-rights-token-holder`: Check NFT ownership
- `get-total-equipment-count`: Get total registered equipment
- `get-total-lease-count`: Get total lease agreements

### Status Checks
- `check-lease-payment-overdue`: Verify if payments are overdue
- `check-equipment-maintenance-due`: Check maintenance schedule

## Administrative Functions

### Platform Management
- `update-marketplace-administrator`: Change contract administrator
- `modify-platform-service-fee`: Adjust platform fee (max 10%)
- `toggle-marketplace-emergency-pause`: Emergency pause functionality
- `execute-emergency-fund-withdrawal`: Emergency fund recovery

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Unauthorized access |
| u101 | Resource not found |
| u102 | Resource already exists |
| u103 | Invalid amount value |
| u104 | Insufficient balance |
| u105 | Lease period expired |
| u106 | Lease inactive state |
| u107 | Invalid duration period |
| u108 | Equipment unavailable |
| u109 | Payment processing failed |
| u110 | Invalid principal address |
| u111 | Maintenance required |
| u112 | Invalid input data |

## Economic Model

### Platform Fees
- Default platform service fee: 2.5% (250 basis points)
- Fee is deducted from each payment transaction
- Fees are transferred to the marketplace administrator
- Maximum fee cap: 10%

### Payment Schedule
- Monthly payments are due every 4320 blocks (~30 days)
- Maintenance schedule: every 8640 blocks (~60 days)
- Overdue payments are tracked automatically

## Security Features

### Access Control
- Owner-only functions for equipment and lease management
- Validation of all input parameters
- Emergency pause functionality
- Principal address validation

### Data Validation
- String length validation
- Category and condition validation
- Amount and duration validation
- Equipment and lease ID validation

## Usage Examples

### Registering Equipment
```clarity
(register-equipment-asset 
  "Excavator CAT 320" 
  "Heavy-duty excavator suitable for construction projects"
  u500000
  "construction"
  "excellent")
```

### Creating a Lease
```clarity
(establish-lease-agreement 
  u1               ;; equipment ID
  'SP123...ABC     ;; lessee address
  u129600          ;; 90 days in blocks
  u5000            ;; monthly fee (50 STX)
  u10000)          ;; security deposit (100 STX)
```

### Processing Payment
```clarity
(process-lease-payment u1 "monthly")
```

## Development and Deployment

### Prerequisites
- Stacks blockchain development environment
- Clarity language support
- Sufficient STX for contract deployment