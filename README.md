# 🚨 Disaster Relief Fund Allocation System

A blockchain-based smart contract system that democratically allocates emergency relief funds based on community voting and authorized disaster reporting.

## 🌟 Features

- 💰 **Community Funding**: Anyone can contribute STX to the relief fund
- 🔐 **Authorized Reporting**: Only verified reporters can submit disaster reports
- 🗳️ **Democratic Voting**: Community members vote on funding allocation
- ⚡ **Automatic Processing**: Funds are automatically allocated based on voting results
- 📊 **Transparent Tracking**: All transactions and votes are publicly visible

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- STX wallet for testing

### Installation

```bash
git clone <repository-url>
cd disaster-relief-fund
clarinet console
```

## 📖 Usage Guide

### 1. 💵 Contributing to the Fund

```clarity
(contract-call? .disaster-relief-fund contribute-to-fund u1000000)
```

### 2. 👥 Authorizing Reporters (Owner Only)

```clarity
(contract-call? .disaster-relief-fund authorize-reporter 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### 3. 📢 Reporting a Disaster

```clarity
(contract-call? .disaster-relief-fund report-disaster "Haiti Earthquake" u8 u5000000)
```

### 4. 🗳️ Voting on Disasters

```clarity
;; Vote FOR funding
(contract-call? .disaster-relief-fund vote-on-disaster u1 true)

;; Vote AGAINST funding  
(contract-call? .disaster-relief-fund vote-on-disaster u1 false)
```

### 5. ⚙️ Processing Fund Allocation

```clarity
(contract-call? .disaster-relief-fund process-disaster-funding u1)
```

### 6. 💸 Withdrawing Allocated Funds

```clarity
(contract-call? .disaster-relief-fund withdraw-allocated-funds u1)
```

## 🔍 Read-Only Functions

### Check Fund Balance
```clarity
(contract-call? .disaster-relief-fund get-total-fund-balance)
```

### Get Disaster Information
```clarity
(contract-call? .disaster-relief-fund get-disaster-info u1)
```

### Check Voting Status
```clarity
(contract-call? .disaster-relief-fund get-user-vote u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Verify Reporter Authorization
```clarity
(contract-call? .disaster-relief-fund is-authorized-reporter 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## 🎯 How It Works

1. **💰 Fund Collection**: Community members contribute STX to build the relief fund
2. **📋 Disaster Reporting**: Authorized reporters submit disaster information with funding requests
3. **🗳️ Community Voting**: Users vote on whether disasters should receive funding
4. **⚖️ Automatic Allocation**: System processes votes (60% approval threshold required)
5. **💵 Fund Disbursement**: Approved reporters can withdraw allocated funds

## 🔧 Configuration

- **Minimum Votes Required**: Default 3 votes (adjustable by owner)
- **Approval Threshold**: 60% of votes must be "yes"
- **Maximum Allocation**: 80% of available funds per disaster
- **Severity Scale**: 1-10 (10 being most severe)

## 🛡️ Security Features

- ✅ Only authorized reporters can submit disasters
- ✅ One vote per user per disaster
- ✅ Funds locked until community approval
- ✅ Transparent voting and allocation process
- ✅ Owner-controlled reporter authorization

## 📊 Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner only operation |
| u101 | Disaster not found |
| u102 | Already exists |
| u103 | Insufficient funds |
| u104 | Invalid amount |
| u105 | Not authorized |
| u106 | Already voted |
| u107 | Voting closed |
| u108 | Minimum votes not met |

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

---

Built with ❤️ for disaster relief and community empowerment 🌍
```

**Git Commit Message:**
```
feat: implement disaster relief fund allocation system with community voting
```

**GitHub Pull Request Title:**
```
🚨 Add Disaster Relief Fund Allocation System with Democratic Voting
```

**GitHub Pull Request Description:**
```
## 🚨 Disaster Relief Fund Allocation System

This PR introduces a comprehensive blockchain-based disaster relief fund allocation system that enables democratic distribution of emergency funds.

### ✨ What's Added

- **Smart Contract Implementation**: Complete Clarity contract with fund management, voting, and allocation logic
- **Community Funding**: STX contribution system for building relief funds  
- **Authorized Reporting**: Controlle
