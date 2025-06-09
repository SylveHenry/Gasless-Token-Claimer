# Gasless Token Approval System

This project implements a gasless token approval system that allows:

1. Users to sign a gasless transaction to grant spend permission to a smart contract
2. The smart contract to subsequently spend the user's tokens without further user intervention

The system supports multiple ERC-20 tokens (including USDC and USDT) across various EVM chains (Ethereum, Optimism, Base, Arbitrum, Binance Smart Chain).

## Architecture

The system consists of:

- **GaslessApprover Contract**: Allows users to approve token spending without paying gas using EIP-2771 meta transactions
- **TokenSpender Contract**: Authorized to spend pre-approved tokens on behalf of users
- **Frontend Components**: For users to sign approvals with their wallet
- **Backend Scripts**: For automated token spending based on pre-approved allowances

## How It Works

1. **Gasless Token Approval**:
   - User signs a message (not a transaction) using their wallet
   - The signature authorizes the GaslessApprover to approve token spending
   - Biconomy relayers submit the actual transaction to the blockchain, paying the gas fees

2. **Token Spending**:
   - Once approved, the TokenSpender contract can move tokens from the user's wallet to any recipient
   - This can be triggered by authorized operators (e.g., your backend services)
   - No further signature or action is required from the user

## Getting Started

### Prerequisites

- Node.js and npm
- Hardhat
- MetaMask or another Ethereum wallet
- A Biconomy API key

### Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   cd gasless-token-approval
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Create a `.env` file with the following variables:
   ```
   PRIVATE_KEY=your_private_key
   BICONOMY_API_KEY=your_biconomy_api_key
   ETHEREUM_RPC_URL=your_ethereum_rpc_url
   OPTIMISM_RPC_URL=your_optimism_rpc_url
   BASE_RPC_URL=your_base_rpc_url
   ARBITRUM_RPC_URL=your_arbitrum_rpc_url
   BSC_RPC_URL=your_binance_rpc_url
   ```

### Deployment

1. Deploy the contracts:
   ```
   npx hardhat run scripts/deploy.js --network <network>
   ```

2. Add the deployed contract addresses to your `.env` file, as provided in the deployment output.

3. Register the GaslessApprover contract on the Biconomy dashboard:
   - Go to https://dashboard.biconomy.io/
   - Create a new app
   - Add the GaslessApprover contract address
   - Configure the methods to be forwarded (approveWithSignature)

## Usage

### Frontend Integration

1. Import the GaslessApproval utility:
   ```javascript
   import GaslessApproval from './GaslessApproval';
   ```

2. Initialize with your provider and contract addresses:
   ```javascript
   const gaslessApproval = new GaslessApproval(
     provider,
     gaslessApproverAddress,
     biconomyApiKey
   );
   ```

3. Create a gasless approval:
   ```javascript
   const approval = await gaslessApproval.approveTokenSpending(
     userAddress,
     tokenAddress,
     amount
   );
   ```

### Backend Token Spending

Use the script to spend pre-approved tokens:

```
node scripts/spend-tokens.js --network ethereum --token USDC --user 0x... --amount 100 --recipient 0x...
```

## Security Considerations

- The TokenSpender contract has significant permissions over users' tokens after approval
- Use the `operators` system to carefully control who can trigger token spending
- Consider implementing additional security measures like spending limits and timeouts
- The approvals include expiration timestamps to prevent replay attacks

## License

MIT

## Support

For assistance, please reach out to [your contact information]. 