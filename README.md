# DecentralCare

A decentralized healthcare insurance marketplace built on the Stacks blockchain with Clarity smart contracts.

## Overview

DecentralCare is a fully decentralized platform that connects healthcare providers with patients seeking insurance coverage. It leverages blockchain technology to create a transparent, efficient, and trustless healthcare insurance ecosystem.

## Key Features

- **Healthcare Provider Registration**: Qualified healthcare providers can register on the platform to offer insurance plans.
- **Health Plan Creation**: Providers can create customized health insurance plans with different coverage options, premium rates, and terms.
- **Insurance Purchase**: Patients can browse available plans and purchase coverage directly through the platform.
- **Claims Processing**: Streamlined claims submission and approval/rejection process.
- **Refund Mechanism**: Fair refund calculations for plan cancellations based on unused coverage time.
- **Administrative Controls**: Emergency shutdown capabilities and system pause/unpause functionality.

## Technical Components

### Maps
- `healthcare-providers`: Stores information about registered healthcare providers
- `members`: Tracks insured members and their active coverage details
- `health-plans`: Contains all available insurance plans and their specifications
- `medical-claims`: Manages all submitted insurance claims and their status

### Key Functions

#### For Healthcare Providers
- `register-healthcare-provider`: Register as a healthcare provider on the platform
- `create-health-plan`: Create a new health insurance plan with specific terms
- `process-health-claim`: Review and approve/deny medical claims

#### For Patients/Members
- `purchase-health-plan`: Purchase an insurance plan from a provider
- `submit-health-claim`: Submit a medical claim for processing
- `cancel-health-plan`: Cancel existing coverage and receive a prorated refund

#### Administrative Functions
- `set-system-status`: Pause or unpause the platform operations
- `emergency-shutdown`: Trigger an emergency shutdown of the platform

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- Basic understanding of the Stacks blockchain and Clarity language

### Installation

1. Clone this repository
   ```
   git clone https://github.com/yourusername/decentralcare.git
   cd decentralcare
   ```

2. Install dependencies
   ```
   npm install
   ```

3. Test the smart contract
   ```
   clarinet test
   ```

## Usage

### Deploy the Contract
```bash
clarinet deploy
```

### Monitor Events
```bash
clarinet events watch
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- The Stacks Foundation
- Clarity language contributors
- Blockchain healthcare innovators