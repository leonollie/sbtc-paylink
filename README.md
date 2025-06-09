# sBTC PayLink Protocol

A decentralized Bitcoin payment request system built on the Stacks blockchain, enabling seamless peer-to-peer transactions with built-in escrow, expiration handling, and comprehensive payment tracking.

## Overview

sBTC PayLink revolutionizes Bitcoin payments by providing a trustless, time-bound payment request system. Users can create shareable payment links with specific amounts, expiration dates, and optional memos. Recipients can fulfill these requests by transferring sBTC, with automatic state management and complete audit trails.

## Key Features

- **Decentralized Payment Requests**: Create and manage payment requests without intermediaries
- **Time-Bound Transactions**: Automatic expiration handling with customizable timeframes (up to 30 days)
- **Comprehensive State Management**: Track payment status (pending/paid/expired/canceled)
- **Multi-Index System**: Efficient querying by creator, recipient, and fulfiller
- **Batch Operations**: Enhanced UX with support for multiple operations
- **Audit Trail**: Complete transaction history with event emission
- **Security First**: Input validation, overflow protection, and state validation
- **Memo System**: Optional payment descriptions for context

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    sBTC PayLink Protocol                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Creator   │    │  Fulfiller  │    │  Recipient  │     │
│  │             │    │             │    │             │     │
│  │ Creates     │    │ Pays        │    │ Receives    │     │
│  │ Payment     │────┤ Payment     │────┤ sBTC        │     │
│  │ Link        │    │ Request     │    │ Transfer    │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                     Smart Contract Layer                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Data Storage  │  │ Business Logic  │  │   Indices   │ │
│  │                 │  │                 │  │             │ │
│  │ • payment-links │  │ • create-link   │  │ • by-creator│ │
│  │ • statistics    │  │ • fulfill-link  │  │ • by-recipient│
│  │ • counters      │  │ • cancel-link   │  │ • by-fulfiller│
│  │                 │  │ • mark-expired  │  │             │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                      sBTC Token Layer                       │
└─────────────────────────────────────────────────────────────┘
```

## Contract Architecture

### Core Components

#### 1. Data Storage Maps

- **`payment-links`**: Main storage for payment request metadata
- **`links-by-creator`**: Index for creator's payment links
- **`links-by-recipient`**: Index for recipient's assigned links  
- **`links-by-fulfiller`**: Index for fulfilled payments tracker

#### 2. State Management

- **Auto-incrementing ID system**: Unique identifiers for each payment link
- **Protocol statistics**: Total links created, fulfilled, and volume tracking
- **State transitions**: Pending → Paid/Expired/Canceled

#### 3. Security Framework

- **Input validation**: Amount, expiration, memo, and recipient checks
- **Overflow protection**: Safe arithmetic operations
- **Access control**: Creator-only cancellation, state validation
- **Anti-patterns**: Self-payment prevention, expired link handling

## Data Flow

### 1. Payment Link Creation

```
Creator → create-payment-link() → Validation → Storage → Index Updates → Event Emission
```

1. **Input Validation**: Amount ≥ 1 satoshi, expiration ≤ 30 days, valid recipient
2. **ID Generation**: Auto-increment counter for unique identification
3. **Storage**: Save payment link with metadata and pending state
4. **Index Updates**: Add to creator and recipient indices
5. **Event Emission**: Broadcast creation event for off-chain tracking

### 2. Payment Fulfillment

```
Fulfiller → fulfill-payment-link() → Validation → sBTC Transfer → State Update → Event Emission
```

1. **State Validation**: Link exists, pending status, not expired
2. **Authorization**: Prevent self-payment, validate fulfiller
3. **sBTC Transfer**: Execute token transfer to recipient
4. **State Update**: Mark as paid, record fulfiller
5. **Statistics Update**: Increment counters, update volume
6. **Index Update**: Add to fulfiller's index

### 3. Link Management

```
Creator → cancel-payment-link() → Authorization → State Update → Event Emission
Anyone → mark-expired() → Validation → State Update → Event Emission
```

## API Reference

### Public Functions

#### `create-payment-link`

Creates a new payment request link.

```clarity
(create-payment-link (recipient principal) (amount uint) (expires-in uint) (memo (optional (string-ascii 256))))
```

**Parameters:**

- `recipient`: Target principal to receive payment
- `amount`: Payment amount in sBTC units (minimum 1)
- `expires-in`: Expiration time in blocks (maximum 4,320 ≈ 30 days)
- `memo`: Optional payment description (max 256 characters)

**Returns:** `(response uint uint)` - Payment link ID on success

#### `fulfill-payment-link`

Fulfills a pending payment request by transferring sBTC.

```clarity
(fulfill-payment-link (id uint))
```

**Parameters:**

- `id`: Payment link identifier

**Returns:** `(response uint uint)` - Link ID on successful payment

#### `cancel-payment-link`

Cancels a pending payment link (creator only).

```clarity
(cancel-payment-link (id uint))
```

#### `mark-expired`

Marks an expired pending link as expired (public utility function).

```clarity
(mark-expired (id uint))
```

### Read-Only Functions

#### `get-payment-link`

Retrieves complete payment link details.

```clarity
(get-payment-link (id uint))
```

#### `get-link-status`

Gets enhanced status information including expiration status.

```clarity
(get-link-status (id uint))
```

#### `get-creator-links`

Returns all payment link IDs created by a principal.

```clarity
(get-creator-links (creator principal))
```

#### `get-recipient-links`

Returns all payment link IDs where principal is recipient.

```clarity
(get-recipient-links (recipient principal))
```

#### `get-protocol-stats`

Returns protocol usage statistics.

```clarity
(get-protocol-stats)
```

## Configuration

### Protocol Constants

- **Maximum Expiration**: 4,320 blocks (~30 days)
- **Minimum Payment**: 1 sBTC unit
- **Maximum Batch Size**: 20 operations
- **Index List Limit**: 50 entries per principal

### Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR-TAG-EXISTS` | Tag already exists |
| 101 | `ERR-NOT-PENDING` | Link not in pending state |
| 102 | `ERR-INSUFFICIENT-FUNDS` | Insufficient sBTC balance |
| 103 | `ERR-NOT-FOUND` | Payment link not found |
| 104 | `ERR-UNAUTHORIZED` | Unauthorized operation |
| 105 | `ERR-EXPIRED` | Payment link expired |
| 106 | `ERR-INVALID-AMOUNT` | Invalid payment amount |
| 107 | `ERR-EMPTY-MEMO` | Empty or invalid memo |
| 108 | `ERR-MAX-EXPIRATION-EXCEEDED` | Expiration exceeds maximum |
| 109 | `ERR-SELF-PAYMENT` | Cannot pay to self |
| 110 | `ERR-INVALID-RECIPIENT` | Invalid recipient address |

## Usage Examples

### Creating a Payment Link

```javascript
// Create a payment request for 1000 sBTC units, expires in 1 day
const result = await contractCall({
  contractAddress: "ST...",
  contractName: "sbtc-paylink",
  functionName: "create-payment-link",
  functionArgs: [
    principalCV("ST1RECIPIENT..."), // recipient
    uintCV(1000),                   // amount
    uintCV(144),                    // expires in ~1 day (144 blocks)
    someCV(stringAsciiCV("Invoice #123")) // memo
  ]
});
```

### Fulfilling a Payment

```javascript
// Pay payment link ID 42
const result = await contractCall({
  contractAddress: "ST...",
  contractName: "sbtc-paylink", 
  functionName: "fulfill-payment-link",
  functionArgs: [uintCV(42)]
});
```

### Querying Payment Status

```javascript
// Get detailed status of payment link
const status = await contractCall({
  contractAddress: "ST...",
  contractName: "sbtc-paylink",
  functionName: "get-link-status", 
  functionArgs: [uintCV(42)]
});
```

## Security Considerations

### Input Validation

- All user inputs are validated for type, range, and format
- Overflow protection for arithmetic operations
- State consistency checks before modifications

### Access Control

- Creator-only cancellation permissions
- Prevention of self-payment scenarios
- Expiration enforcement for all operations

### Best Practices

- Always check link status before attempting fulfillment
- Monitor expiration times to avoid failed transactions
- Use batch operations for UI optimization
- Implement proper error handling for all edge cases

## Integration Guide

### Frontend Integration

1. **State Management**: Track payment link states in your application
2. **Event Listening**: Monitor contract events for real-time updates
3. **Batch Operations**: Use batch functions for improved UX
4. **Error Handling**: Implement comprehensive error handling

### Backend Integration

1. **Indexing**: Build additional indices for complex queries
2. **Monitoring**: Track protocol statistics and usage patterns
3. **Cleanup**: Implement expired link cleanup routines
4. **Analytics**: Leverage event emissions for business intelligence

## Contributing

Contributions are welcome! Please ensure all code changes include:

- Comprehensive tests
- Security considerations
- Documentation updates
- Gas optimization analysis
