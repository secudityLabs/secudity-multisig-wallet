# 🔐 Secudity Multi-Signature Wallet

![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue)
![Foundry](https://img.shields.io/badge/Built%20with-Foundry-red)
![License](https://img.shields.io/badge/License-MIT-green)

**A secure, gas-optimized multi-signature wallet built with Foundry**

Created by [Secudity](https://instagram.com/secudity)

---

## 📋 Overview

A production-ready multi-signature wallet that requires multiple owner confirmations before executing transactions. Built with security best practices and comprehensive testing.

### ✨ Features

- ✅ **Multi-signature authorization** - Require N-of-M confirmations
- ✅ **Secure by design** - Custom errors, checks-effects-interactions pattern
- ✅ **Gas optimized** - Efficient storage and operations
- ✅ **Fully tested** - Unit, fuzz, and invariant tests
- ✅ **Event logging** - Complete transaction transparency
- ✅ **Revocable confirmations** - Change your mind before execution

---

## 🏗️ Architecture

### Contract Structure
```
src/
├── MultiSigWallet.sol           # Main wallet contract
└── interfaces/
    └── IMultiSigWallet.sol      # Interface definition

test/
├── MultiSigWallet.t.sol         # Unit tests
├── MultiSigWallet.fuzz.t.sol    # Fuzz tests
└── MultiSigWallet.invariant.t.sol # Invariant tests

script/
└── Deploy.s.sol                 # Deployment script
```

### Key Components

- **Owners**: Addresses authorized to submit and confirm transactions
- **Required Confirmations**: Minimum number of confirmations needed
- **Transactions**: Proposed actions awaiting confirmation
- **Confirmations**: Owner approvals for transactions

---

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/secudity-multisig-wallet.git
cd secudity-multisig-wallet

# Install dependencies
forge install

# Build the project
forge build
```

### Running Tests
```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test file
forge test --match-contract MultiSigWalletTest

# Run with gas report
forge test --gas-report

# Run fuzz tests with more runs
forge test --match-contract Fuzz -vv

# Run invariant tests
forge test --match-contract Invariant -vv

# Generate coverage report
forge coverage
```

---

## 📖 Usage

### Deployment

1. **Configure your environment**
```bash
cp .env.example .env
# Edit .env and add your private key and RPC URLs
```

2. **Update owner addresses** in `script/Deploy.s.sol`

3. **Deploy to network**
```bash
# Deploy to Sepolia testnet
forge script script/Deploy.s.sol:DeployMultiSigWallet --rpc-url sepolia --broadcast --verify

# Deploy to mainnet (be careful!)
forge script script/Deploy.s.sol:DeployMultiSigWallet --rpc-url mainnet --broadcast --verify
```

### Interacting with the Contract

#### Submit a Transaction
```solidity
// Submit a transaction to send 1 ETH to recipient
uint256 txIndex = wallet.submitTransaction(
    recipientAddress,
    1 ether,
    "" // empty data for simple ETH transfer
);
```

#### Confirm a Transaction
```solidity
// Owner confirms the transaction
wallet.confirmTransaction(txIndex);
```

#### Execute a Transaction
```solidity
// Execute after required confirmations
wallet.executeTransaction(txIndex);
```

#### Revoke Confirmation
```solidity
// Change your mind before execution
wallet.revokeConfirmation(txIndex);
```

### Example Workflow
```solidity
// 1. Owner 1 submits a transaction
wallet.submitTransaction(0x123..., 5 ether, "");

// 2. Owner 2 confirms
wallet.confirmTransaction(0);

// 3. Owner 3 confirms (if 3 confirmations required)
wallet.confirmTransaction(0);

// 4. Any owner can execute
wallet.executeTransaction(0);
```

---

## 🔒 Security Features

### Design Patterns

- ✅ **Checks-Effects-Interactions** - Prevents reentrancy attacks
- ✅ **Custom Errors** - Gas-efficient error handling
- ✅ **Access Control** - Owner-only functions
- ✅ **Event Emissions** - Full transaction transparency

### Security Considerations

1. **Owner Management**
   - Owners cannot be zero address
   - Owners must be unique
   - No duplicate owners allowed

2. **Transaction Validation**
   - Transactions cannot be executed without required confirmations
   - Executed transactions cannot be re-executed
   - Confirmations can be revoked before execution

3. **Failure Handling**
   - Failed transactions revert with clear error messages
   - Transaction state updated before external calls

---

## 🧪 Testing

### Test Coverage

- **Unit Tests**: 25+ test cases covering all functions
- **Fuzz Tests**: Property-based testing with random inputs
- **Invariant Tests**: Continuous property verification

### Key Invariants

1. Balance equals deposits minus withdrawals
2. Only owners can submit transactions
3. Transaction count never decreases
4. Executed transactions stay executed

---

## 📊 Gas Optimization

| Function | Gas Cost (avg) |
|----------|----------------|
| submitTransaction | ~85,000 |
| confirmTransaction | ~45,000 |
| executeTransaction | ~60,000 |
| revokeConfirmation | ~30,000 |

---

## 🛠️ Development

### Project Structure
```
.
├── src/                    # Smart contracts
├── test/                   # Test files
├── script/                 # Deployment scripts
├── docs/                   # Documentation
├── audit/                  # Audit reports
├── foundry.toml           # Foundry configuration
└── README.md              # This file
```

### Best Practices

- Write tests before implementation
- Use custom errors instead of require strings
- Follow Checks-Effects-Interactions pattern
- Emit events for all state changes
- Document all public functions

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📞 Contact

**Secudity** - Security + Solidity

- Instagram: [@secudity](https://instagram.com/secudity)
- GitHub: [@yourusername](https://github.com/yourusername)

---

## 🙏 Acknowledgments

- Built with [Foundry](https://github.com/foundry-rs/foundry)
- Inspired by Gnosis Safe
- Security best practices from [OpenZeppelin](https://www.openzeppelin.com/)

---

⭐ **If you find this project useful, please consider giving it a star!**
