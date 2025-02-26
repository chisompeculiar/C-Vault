# C-Vault: Decentralized Time-Locked Asset Management

C-Vault is a secure, decentralized smart contract for time-locked STX token management on the Stacks blockchain. It enables users to lock their assets for a specified period while providing emergency access options through beneficiary designation.

## Overview

C-Vault allows users to:
- Create time-locked vaults for their STX tokens
- Specify unlock times based on block heights
- Designate beneficiaries for emergency access
- Securely manage and access their funds once time-locks expire

## Features

### Secure Vault Creation
Lock your STX tokens for a predetermined period, making them inaccessible until the specified block height is reached.

### Flexible Deposits
Add funds to your existing vault at any time. When adding funds, the unlock time will be set to the maximum of the current unlock time and the new specified unlock time.

### Beneficiary Designation
Designate a trusted individual as a beneficiary who can access your funds after the unlock time, providing an emergency backup access mechanism.

### Full Control
Once the unlock height is reached, withdraw partial or full amounts from your vault at your convenience.

## Technical Details

### Contract Functions

#### Read-Only Functions

- `get-vault`: Retrieves vault details for a specific owner
- `vault-exists`: Checks if a vault exists for a given principal
- `is-vault-unlocked`: Determines if a vault's time-lock has expired
- `get-contract-balance`: Returns the contract's STX balance (for testing)

#### Public Functions

- `deposit`: Create a new vault or add to an existing one with a specified unlock height
- `withdraw`: Withdraw funds from an unlocked vault
- `set-beneficiary`: Designate a beneficiary for emergency access
- `beneficiary-withdraw`: Allow a designated beneficiary to withdraw funds from an unlocked vault

### Error Codes

- `ERR_UNAUTHORIZED` (100): Caller is not authorized for the operation
- `ERR_NO_VAULT` (101): Specified vault does not exist
- `ERR_VAULT_LOCKED` (102): Vault is still time-locked
- `ERR_INVALID_UNLOCK_TIME` (103): Specified unlock time is invalid
- `ERR_ZERO_DEPOSIT` (104): Attempted to deposit zero tokens
- `ERR_INSUFFICIENT_FUNDS` (105): Insufficient funds for withdrawal
- `ERR_BENEFICIARY_ALREADY_SET` (106): Beneficiary is already set and cannot be changed
- `ERR_INVALID_BENEFICIARY` (107): Invalid beneficiary specified (e.g., self-designation)

## Usage Examples

### Creating a Vault

```clarity
;; Lock 1000 STX for 1000 blocks
(contract-call? .c-vault deposit u1000 (+ block-height u1000))
```

### Setting a Beneficiary

```clarity
;; Set a trusted individual as beneficiary
(contract-call? .c-vault set-beneficiary 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Withdrawing Funds

```clarity
;; Withdraw 500 STX after unlock height is reached
(contract-call? .c-vault withdraw u500)
```

### Beneficiary Withdrawal

```clarity
;; Beneficiary can withdraw funds after unlock height
(contract-call? .c-vault beneficiary-withdraw 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Security Considerations

- **Time-locks**: Funds cannot be withdrawn before the specified unlock height
- **Beneficiary validation**: Beneficiaries cannot be the vault owner and cannot be changed once set
- **Input validation**: All user inputs are carefully validated to prevent exploits
- **Secure transfers**: Uses secure STX transfer mechanisms for all token movements

## Development

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing
- Basic understanding of Clarity smart contracts and the Stacks blockchain

### Testing

Run comprehensive tests using Clarinet:

```bash
clarinet test
```

### Deployment

Deploy to testnet or mainnet using Clarinet:

```bash
clarinet publish --testnet
# or
clarinet publish --mainnet
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
