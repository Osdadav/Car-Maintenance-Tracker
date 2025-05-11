# Car Maintenance Tracker

A decentralized application built on the Stacks blockchain for tracking and verifying vehicle maintenance records.

## Overview

This project provides a transparent and immutable record of vehicle maintenance history using blockchain technology. It allows vehicle owners to track maintenance, service providers to log their work, and creates a verifiable service history that can increase vehicle value and trust.

## Features

- Register vehicles with VIN, make, model, year, and mileage
- Register as a service provider
- Add maintenance records with detailed service information
- Verify maintenance records by vehicle owners
- Track vehicle mileage over time
- View complete maintenance history for any registered vehicle

## Smart Contract Functions

### Vehicle Owner Functions
- `register-vehicle`: Register a new vehicle on the blockchain
- `verify-maintenance-record`: Verify a maintenance record as the vehicle owner

### Service Provider Functions
- `register-service-provider`: Register as a service provider
- `add-maintenance-record`: Add a new maintenance record for a vehicle

### Read-Only Functions
- `get-vehicle-info`: Get detailed information about a vehicle
- `get-maintenance-record`: Get details of a specific maintenance record
- `get-service-provider`: Get information about a service provider
- `get-record-count`: Get the total number of maintenance records for a vehicle

## Development

This project is built using Clarity, the smart contract language for the Stacks blockchain.

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet)
- [Stacks CLI](https://github.com/blockstack/stacks.js)