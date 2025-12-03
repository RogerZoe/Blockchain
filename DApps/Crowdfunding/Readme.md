# 🚀 Crowdfunding DApp

A modern, decentralized crowdfunding platform built with **Thirdweb** and **Next.js** that empowers creators to launch campaigns and receive support directly on the blockchain.

## ✨ Features

### 🎯 Campaign Management
- **Create Campaigns** - Launch new crowdfunding projects with custom goals and deadlines
- **Tiered Funding** - Multiple contribution levels with different rewards
- **Real-time Tracking** - Monitor campaign progress and funding status
- **Edit Campaigns** - Update campaign details and funding tiers

### 💫 User Experience
- **Dashboard** - Overview of all your campaigns and their status
- **Beautiful UI** - Modern, responsive design with Tailwind CSS
- **Blockchain Integration** - Secure, transparent transactions on the blockchain
- **Campaign Discovery** - Browse and support innovative projects

## 🛠️ Tech Stack

- **Frontend**: Next.js 14, React, TypeScript, Tailwind CSS
- **Blockchain**: Thirdweb SDK, Smart Contracts
- **Styling**: Modern UI components with responsive design
- **Development**: ESLint, Prettier, PostCSS

## 📦 Project Structure

```
crowdfunding/
├── contracts/          # Smart contracts
├── src/               # Application source code
├── public/            # Static assets
├── DEMO/              # Demo files and examples
├── .env.local         # Environment variables
├── package.json       # Dependencies
├── tsconfig.json     # TypeScript configuration
└── tailwind.config.ts # Tailwind CSS configuration
```

## 🚀 Getting Started

### Prerequisites
- Node.js 18+ 
- npm or yarn
- Thirdweb account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/RogerZoe/DApps.git
   cd DApps/Crowdfunding
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.local.example .env.local
   ```
   Add your Thirdweb configuration:
   ```env
   THIRDWEB_CLIENT_ID=your_client_id
   THIRDWEB_SECRET_KEY=your_secret_key
   ```

4. **Run the development server**
   ```bash
   npm run dev
   ```

5. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## 💡 How It Works

### For Campaign Creators
1. **Create** - Launch a new campaign with description, goal, and deadline
2. **Customize** - Set up funding tiers with different reward levels
3. **Manage** - Track contributions and update campaign details
4. **Withdraw** - Access funds when goals are met

### For Supporters
1. **Discover** - Browse active campaigns on the dashboard
2. **Contribute** - Choose funding tier and make secure blockchain payments
3. **Track** - Monitor campaign progress and see your impact
4. **Engage** - Follow project updates and milestone achievements

## 🎨 UI Components

### Dashboard
- Campaign overview cards
- Funding progress indicators
- Quick action buttons
- Responsive grid layout

### Campaign Pages
- Hero section with campaign details
- Tier selection interface
- Real-time funding statistics
- Contributor lists

### Management Interface
- Campaign creation wizard
- Tier management system
- Status toggles and controls
- Analytics dashboard

## 🔧 Smart Contract Features

- **Secure Funding** - Funds held in escrow until campaign success
- **Transparent Tracking** - All transactions visible on blockchain
- **Flexible Tiers** - Multiple contribution levels
- **Automatic Distribution** - Smart contract handles fund release
- **Refund Mechanism** - Failed campaigns automatically refund supporters

## 🌟 Thirdweb Integration

This project leverages Thirdweb for:
- **Smart Contract Deployment** - Easy contract management
- **Wallet Connection** - Seamless Web3 authentication
- **Blockchain Interactions** - Simplified contract calls
- **Gas Optimization** - Efficient transaction handling

## 📱 Responsive Design

- **Mobile-first** approach
- **Tablet-optimized** layouts
- **Desktop-enhanced** experiences
- **Cross-browser** compatibility

## 🚧 Development

### Available Scripts
```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
```


## 🔗 Links

- **Live Demo**: [Coming Soon]
- **GitHub Repository**: [https://github.com/RogerZoe/DApps](https://github.com/RogerZoe/DApps)
- **Thirdweb Documentation**: [https://portal.thirdweb.com](https://portal.thirdweb.com)

---

Built with ❤️ using **Thirdweb** and **Next.js** for the decentralized future of crowdfunding!
