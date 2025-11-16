# 🏗️ Architecture Documentation

## System Overview

The Secudity Multi-Signature Wallet is a decentralized smart contract system that enables multiple parties to collectively control a single Ethereum wallet.

---

## Core Components

### 1. State Variables
```solidity
address[] public owners;                          // List of wallet owners
mapping(address => bool) public isOwner;         // Quick owner lookup
uint256 public numConfirmationsRequired;         // Required confirmations
Transaction[] public transactions;                // All transactions
mapping(uint256 => mapping(address => bool)) public isConfirmed; // Confirmation tracking
```

### 2. Data Structures

#### Transaction Struct
```solidity
struct Transaction {
    address to;              // Destination address
    uint256 value;          // ETH amount to send
    bytes data;             // Contract call data
    bool executed;          // Execution status
    uint256 numConfirmations; // Confirmation count
}
```

---

## Transaction Lifecycle
```
┌─────────────────┐
│  1. SUBMIT      │  Owner submits transaction
│  Transaction    │  → Creates new transaction
└────────┬────────┘  → Assigns transaction index
         │
         ▼
┌─────────────────┐
│  2. CONFIRM     │  Owners confirm transaction
│  Transaction    │  → Each owner confirms once
└────────┬────────┘  → Confirmation count increases
         │
         ▼
┌─────────────────┐
│  3. EXECUTE     │  Execute when threshold met
│  Transaction    │  → Checks confirmation count
└────────┬────────┘  → Marks as executed
         │            → Sends ETH/calls contract
         ▼
┌─────────────────┐
│  4. COMPLETE    │  Transaction finalized
└─────────────────┘
```

### Optional: Revoke Confirmation
```
Before Execution:
┌─────────────────┐
│  REVOKE         │  Owner revokes confirmation
│  Confirmation   │  → Decreases confirmation count
└─────────────────┘  → Can confirm again later
```

---

## Function Flow Diagrams

### Submit Transaction
```
submitTransaction(to, value, data)
    │
    ├─> Check: msg.sender is owner
    │
    ├─> Create new Transaction
    │   ├─> to = _to
    │   ├─> value = _value
    │   ├─> data = _data
    │   ├─> executed = false
    │   └─> numConfirmations = 0
    │
    ├─> Add to transactions[]
    │
    ├─> Emit SubmitTransaction event
    │
    └─> Return transaction index
```

### Confirm Transaction
```
confirmTransaction(txIndex)
    │
    ├─> Check: msg.sender is owner
    ├─> Check: transaction exists
    ├─> Check: not executed
    ├─> Check: not already confirmed by msg.sender
    │
    ├─> Increment numConfirmations
    ├─> Mark isConfirmed[txIndex][msg.sender] = true
    │
    └─> Emit ConfirmTransaction event
```

### Execute Transaction
```
executeTransaction(txIndex)
    │
    ├─> Check: msg.sender is owner
    ├─> Check: transaction exists
    ├─> Check: not executed
    ├─> Check: numConfirmations >= required
    │
    ├─> Mark executed = true (BEFORE call)
    │
    ├─> Execute external call
    │   └─> to.call{value}(data)
    │
    ├─> Check: call succeeded
    │
    └─> Emit ExecuteTransaction event
```

---

## Security Architecture

### Defense Layers
```
Layer 1: Access Control
    └─> onlyOwner modifier
    
Layer 2: State Validation
    └─> txExists, notExecuted, notConfirmed modifiers
    
Layer 3: Business Logic
    └─> Confirmation threshold checks
    
Layer 4: Reentrancy Protection
    └─> Checks-Effects-Interactions pattern
    
Layer 5: Error Handling
    └─> Custom errors with revert
```

### Checks-Effects-Interactions Pattern
```solidity
function executeTransaction(uint256 _txIndex) public {
    // 1. CHECKS
    onlyOwner modifier
    txExists modifier
    notExecuted modifier
    require(numConfirmations >= required)
    
    // 2. EFFECTS
    transaction.executed = true; // Update state FIRST
    
    // 3. INTERACTIONS
    (bool success, ) = to.call{value}(data); // External call LAST
    if (!success) revert TxFailed();
}
```

---

## Gas Optimization Strategies

### 1. Storage Optimization
```solidity
// Efficient: Pack boolean with other data
struct Transaction {
    address to;              // 20 bytes
    uint96 value;           // 12 bytes (packed with address)
    bool executed;          // 1 byte (packed)
    // ...
}
```

### 2. Custom Errors
```solidity
// Gas Efficient
error NotOwner();

// Less Efficient
require(isOwner[msg.sender], "Not an owner");
```

### 3. Short-Circuit Evaluation
```solidity
// Cheaper checks first
if (!isOwner[msg.sender]) revert NotOwner();
if (transaction.executed) revert TxAlreadyExecuted();
```

---

## Event Architecture

### Event Purpose

1. **Transaction Tracking** - Monitor all wallet activity
2. **Off-chain Indexing** - Build transaction history
3. **UI Updates** - Real-time wallet status
4. **Audit Trail** - Complete transparency

### Event Emission
```solidity
event SubmitTransaction(
    address indexed owner,    // Who submitted
    uint256 indexed txIndex,  // Transaction ID
    address indexed to,       // Destination
    uint256 value,           // Amount
    bytes data               // Call data
);
```

---

## Upgrade Path

### Current Version (v1.0)
- Immutable owners
- Fixed confirmation threshold
- No upgradability

### Future Considerations

**Option 1: Proxy Pattern**
```
User → Proxy Contract → Implementation Contract
```

**Option 2: Migration**
```
Old Wallet → Transfer funds → New Wallet
```

**Recommendation:** Migration approach
- Simpler
- More secure
- Clear ownership transfer

---

## Integration Patterns

### Frontend Integration
```javascript
// Submit transaction
const tx = await wallet.submitTransaction(
    recipientAddress,
    ethers.utils.parseEther("1.0"),
    "0x" // empty data
);

// Listen for events
wallet.on("SubmitTransaction", (owner, txIndex, to, value, data) => {
    console.log(`New transaction #${txIndex} submitted`);
});
```

### Backend Integration
```python
# Python example with web3.py
from web3 import Web3

w3 = Web3(Web3.HTTPProvider('https://mainnet.infura.io/v3/YOUR-KEY'))
wallet = w3.eth.contract(address=wallet_address, abi=wallet_abi)

# Get pending transactions
tx_count = wallet.functions.getTransactionCount().call()
for i in range(tx_count):
    tx = wallet.functions.getTransaction(i).call()
    if not tx[3]:  # not executed
        print(f"Pending transaction: {tx}")
```

---

## Testing Architecture

### Test Pyramid
```
         /\
        /  \  Invariant Tests (Property-based)
       /____\
      /      \  Fuzz Tests (Random inputs)
     /________\
    /          \  Unit Tests (Specific cases)
   /____________\
```

### Test Coverage Goals

- **Statements:** > 95%
- **Branches:** > 90%
- **Functions:** 100%
- **Lines:** > 95%

---

## Deployment Architecture

### Deployment Process
```
1. Compile contracts
   └─> forge build

2. Run tests
   └─> forge test

3. Deploy to testnet
   └─> forge script Deploy --rpc-url sepolia --broadcast

4. Verify on Etherscan
   └─> forge verify-contract

5. Test on testnet
   └─> Manual testing

6. Deploy to mainnet
   └─> forge script Deploy --rpc-url mainnet --broadcast
```

---

## Monitoring & Maintenance

### Key Metrics

1. **Transaction Volume** - Total transactions submitted
2. **Execution Rate** - % of transactions executed
3. **Average Confirmations** - Time to reach threshold
4. **Gas Costs** - Average gas per operation

### Monitoring Tools

- **Etherscan** - Transaction history
- **Tenderly** - Real-time monitoring
- **The Graph** - Event indexing
- **Dune Analytics** - Custom dashboards

---

## Conclusion

The Secudity Multi-Signature Wallet architecture prioritizes:

✅ **Security** - Multiple layers of protection  
✅ **Simplicity** - Clear, auditable code  
✅ **Gas Efficiency** - Optimized operations  
✅ **Transparency** - Complete event logging

---

**Version:** 1.0.0  
**Last Updated:** November 2025  
**Maintainer:** Secudity Team
