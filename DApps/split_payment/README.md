# 💰 Split Payment DApp

A beautiful and modern decentralized application for splitting expenses with friends on the Ethereum blockchain. Built with React, Web3.js, and smart contracts to make shared payments seamless and transparent.

![Split Payment DApp](https://img.shields.io/badge/React-18.2.0-blue) ![Web3](https://img.shields.io/badge/Web3.js-1.9.0-orange) ![Solidity](https://img.shields.io/badge/Solidity-^0.8.19-purple) ![License](https://img.shields.io/badge/License-MIT-green) ![Live Demo](https://img.shields.io/badge/Live_Demo-Available-success)

## 🌐 Live Demo

**🚀 Try it now:** [https://splitpayment-one.vercel.app/](https://splitpayment-one.vercel.app/)

### Quick Test Instructions:
1. **Connect MetaMask** to the Sepolia testnet
2. **Get test ETH** from [Sepolia Faucet](https://sepoliafaucet.com/)
3. **Create an expense** and share the ID with friends
4. **Test payments** with multiple wallets

## ✨ Features

- 🎨 **Stunning Glassmorphism UI** - Modern design with beautiful gradients and animations
- 🔗 **Seamless MetaMask Integration** - Easy wallet connection and transaction signing
- 💸 **Create Shared Expenses** - Split bills equally among multiple participants
- 👥 **Real-time Payment Tracking** - See who has paid and who hasn't
- 🔐 **Blockchain Security** - All transactions secured on Ethereum
- 📱 **Fully Responsive** - Works perfectly on desktop and mobile
- ⚡ **Fast & Gas Efficient** - Optimized smart contract for low gas costs
- 🌍 **Live Deployment** - Ready to use at [splitpayment-one.vercel.app](https://splitpayment-one.vercel.app/)

## 🚀 Quick Start

### Prerequisites

- Node.js (v16 or higher)
- MetaMask browser extension
- Ethereum wallet with test ETH (Sepolia recommended)

### Live Demo Access

1. **Visit**: [https://splitpayment-one.vercel.app/](https://splitpayment-one.vercel.app/)
2. **Connect MetaMask** (ensure you're on Sepolia testnet)
3. **Get test ETH** from [Sepolia Faucet](https://sepoliafaucet.com/)
4. **Start splitting expenses** with friends!

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/split-payment-dapp.git
   cd split-payment-dapp
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Deploy Smart Contract**
   ```bash
   # Using Remix IDE or Hardhat
   # Deploy the SimpleSplitPayment.sol contract
   # Update CONTRACT_ADDRESS in App.js
   ```

4. **Run the application**
   ```bash
   npm start
   ```

5. **Open your browser**
   ```
   http://localhost:3000
   ```

## 🏗️ Project Structure

```
split-payment-dapp/
├── src/
│   ├── components/
│   │   ├── Header.jsx
│   │   ├── WalletConnection.jsx
│   │   ├── CreateExpense.jsx
│   │   ├── PayShare.jsx
│   │   └── StatusMessage.jsx
│   ├── App.js
│   ├── App.css
│   └── abi/
│       └── SplitPaymentABI.json
├── contracts/
│   └── SimpleSplitPayment.sol
└── public/
    └── index.html
```

## 📋 How to Use

### 1. Connect Your Wallet
- Click "Connect Wallet" to link your MetaMask
- Ensure you're on the correct network (Sepolia testnet recommended)

### 2. Create a New Expense
- **Description**: What the expense is for (e.g., "Dinner", "Hotel")
- **Amount**: Total amount in ETH to split
- **Split With**: Comma-separated wallet addresses of participants

### 3. Pay Your Share
- Enter the Expense ID received after creation
- Click "Check Details" to view expense information
- Pay your calculated share with one click

### 4. Track Payments
- View real-time payment status of all participants
- See who has paid and who hasn't
- Get notifications for completed payments

## 🎯 Live Demo Features

The deployed version includes:

- ✅ **Fully functional smart contract** on Sepolia testnet
- ✅ **Real transaction processing** with test ETH
- ✅ **Beautiful responsive design** that works on all devices
- ✅ **Error handling** for common user mistakes
- ✅ **Transaction status tracking** with clear feedback
- ✅ **Multi-wallet testing** capability


## 🎨 UI Components

### Header
- Beautiful gradient title with floating animation
- Professional branding

### WalletConnection
- Real-time connection status
- Formatted wallet address display
- Smooth connect/disconnect flows

### CreateExpense
- Intuitive form with validation
- Real-time input feedback
- Success confirmation with Expense ID

### PayShare
- Expense details display
- Payment status tracking
- One-click payment processing

### StatusMessage
- Toast notifications for all actions
- Success, error, and info states
- Auto-dismiss functionality


## 🛠️ Technical Stack

- **Frontend**: React 18, Web3.js
- **Styling**: Pure CSS with modern features
- **Blockchain**: Ethereum, Solidity
- **Wallet**: MetaMask integration
- **Build Tool**: Create React App
- **Deployment**: Vercel
- **Network**: Sepolia Testnet


## 🧪 Testing the Live Demo

To test the live deployment:

1. **Switch to Sepolia Testnet** in MetaMask
2. **Get test ETH** from:
   - [Sepolia Faucet](https://sepoliafaucet.com/)
   - [Alchemy Faucet](https://sepoliafaucet.com/)
   - [Infura Faucet](https://www.infura.io/faucet)

3. **Test Flow**:
   ```
   Create Expense → Share ID → Check Details → Make Payment → Verify Status
   ```

## 🌐 Deployment

### Live Deployment
- **URL**: [https://splitpayment-one.vercel.app/](https://splitpayment-one.vercel.app/)
- **Platform**: Vercel
- **Network**: Sepolia Testnet
- **Status**: ✅ Live and Functional

### Smart Contract Deployment
1. Compile with Solidity 0.8.19+
2. Deploy to Ethereum network (Sepolia for demo)
3. Verify on Etherscan

### Frontend Deployment
```bash
# Build for production
npm run build

# Deploy to Vercel
vercel --prod
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---
