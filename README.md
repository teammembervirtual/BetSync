BetSync is a decentralized synchronized betting pools platform built on the Stacks blockchain using Clarity smart contracts.
BetSync enables users to create and participate in binary outcome betting pools with transparent, automated payouts and real-time odds calculation. Perfect for prediction markets, sports betting, and community-driven wagering.
🚀 Features
Core Functionality

Pool Creation: Create binary outcome betting pools with custom titles, descriptions, and deadlines
Dynamic Betting: Place bets on either outcome with real-time pool updates
Automated Resolution: Pool creators can resolve outcomes after deadlines
Fair Payouts: Proportional reward distribution based on winning pool contributions
Platform Fees: Built-in 3% platform fee structure for sustainability

Advanced Features

Real-time Odds: Dynamic odds calculation based on current pool distributions
User Statistics: Track individual betting performance and participation history
Pool Management: Creators can close pools early if needed
Contribution Tracking: Detailed records of all user contributions per pool
Input Validation: Comprehensive validation for all user inputs and edge cases

📋 Prerequisites

Stacks CLI installed
Clarinet for testing and deployment
Basic understanding of Clarity smart contracts
STX tokens for transactions

🛠️ Installation

Clone the repository
bashgit clone https://github.com/yourusername/BetSync.git
cd BetSync

Initialize Clarinet project
bashclarinet new betsync-project
cd betsync-project

Add the contract
bash# Copy the contract file to contracts/
cp ../betsync.clar contracts/

Update Clarinet.toml
toml[contracts.betsync]
path = "contracts/betsync.clar"


🎯 Usage
Creating a Betting Pool
clarity;; Create a new betting pool
(contract-call? .betsync create-pool 
  "Election 2024" 
  "Who will win the presidential election?" 
  "Candidate A" 
  "Candidate B" 
  u1000) ;; Duration in blocks
Joining a Pool
clarity;; Place a bet on outcome 1 (Candidate A) with 1000 microSTX
(contract-call? .betsync join-pool u1 u1 u1000000)

;; Place a bet on outcome 2 (Candidate B) with 500 microSTX
(contract-call? .betsync join-pool u1 u2 u500000)
Resolving a Pool
clarity;; Pool creator resolves the outcome (only after deadline)
(contract-call? .betsync resolve-pool u1 u1) ;; Outcome 1 wins
Claiming Winnings
clarity;; Winners claim their proportional share
(contract-call? .betsync claim-winnings u1)
📊 Contract Functions
Public Functions
FunctionDescriptionParameterscreate-poolCreate a new betting pooltitle, description, outcome-a, outcome-b, durationjoin-poolPlace a bet on a specific outcomepool-id, outcome (1 or 2), amountresolve-poolResolve pool outcome (creator only)pool-id, winning-outcomeclaim-winningsClaim rewards from resolved poolspool-idclose-poolClose an active pool early (creator only)pool-id
Read-Only Functions
FunctionDescriptionReturnsget-pool-infoGet complete pool informationPool data structureget-contribution-infoGet user's contribution detailsContribution dataget-user-statsGet user's betting statisticsStats summarycalculate-pool-oddsGet current odds for both outcomesOdds structureget-potential-payoutCalculate potential winningsPayout projectionsis-pool-activeCheck if pool is currently activeBoolean
💰 Economics
Fee Structure

Platform Fee: 3% of gross winnings
Gas Fees: Standard Stacks transaction fees apply

Payout Calculation
Gross Payout = User Contribution + (User Contribution × Losing Pool / Winning Pool)
Net Payout = Gross Payout - Platform Fee (3%)
Example

Pool A: 1000 STX, Pool B: 2000 STX
Your bet: 100 STX on Pool A (wins)
Gross payout: 100 + (100 × 2000 / 1000) = 300 STX
Platform fee: 300 × 0.03 = 9 STX
Net payout: 291 STX

🔒 Security Features

Input Validation: All user inputs are thoroughly validated
Access Control: Only pool creators can resolve outcomes
Deadline Enforcement: Bets only accepted before deadlines
Double-spending Prevention: Claims can only be made once
State Consistency: Atomic operations ensure data integrity

🧪 Testing
bash# Run all tests
clarinet test

# Run specific test file
clarinet test tests/betsync_test.ts

# Check contract syntax
clarinet check
Test Coverage

Pool creation and validation
Betting mechanics and edge cases
Resolution and payout calculations
Access control and permissions
Error handling and edge cases

🚀 Deployment
Testnet Deployment
bash# Deploy to testnet
clarinet deploy --testnet

# Verify deployment
clarinet contract-call --testnet .betsync get-current-pool-id
Mainnet Deployment
bash# Deploy to mainnet (requires mainnet configuration)
clarinet deploy --mainnet
🤝 Contributing
We welcome contributions! Please follow these steps:

Fork the repository
Create a feature branch
bashgit checkout -b feature/amazing-feature

Make your changes

Follow Clarity coding standards
Add comprehensive tests
Update documentation


Commit your changes
bashgit commit -m "Add amazing feature"

Push to your branch
bashgit push origin feature/amazing-feature

Open a Pull Request

Development Guidelines

Code Style: Follow established Clarity conventions
Testing: Maintain 100% test coverage for new features
Documentation: Update README and inline comments
Security: Consider all edge cases and potential exploits

📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
MIT License

Copyright (c) 2025 BetSync

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
🔗 Related Projects

Stacks - The blockchain powering BetSync
Clarity - The smart contract language
Hiro - Development tools and infrastructure
Clarinet - Local development environment

📞 Support

Documentation: Stacks Documentation
Community: Stacks Discord
Issues: GitHub Issues
Discussions: GitHub Discussions

🏆 Acknowledgments

Built with ❤️ on the Stacks blockchain
Inspired by the need for transparent, decentralized betting
Thanks to the Stacks and Clarity community for their support


⚠️ Disclaimer: This software is provided for educational and research purposes. Users should comply with all applicable laws and regulations regarding betting and gambling in their jurisdiction. The developers are not responsible for any misuse of this software.