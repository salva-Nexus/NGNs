# Load environment variables from .env
include .env

# --- WALLET MANAGEMENT ---
ADD-KEY:
	cast wallet import salva_admin --interactive 

# --- DEPLOYMENT ---

DEPLOY-TO-BNB_MAINNET:
	forge script script/DeployNGNs.s.sol:DeployNGNs --rpc-url ${BNB_MAINNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

DEPLOY-TO-BNB_TESTNET:
	forge script script/DeployNGNs.s.sol:DeployNGNs --rpc-url ${BNB_TESTNET_RPC_URL} --private-key 15eede1b5e4e834b6cc83913ebfc9aeb37238d0dd8c3556178910a4052edb1f1 --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}


DEPLOY-TO-BASE_MAINNET:
	forge script script/DeployNGNs.s.sol:DeployNGNs --rpc-url ${BASE_MAINNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

DEPLOY-TO-BASE_TESTNET:
	forge script script/DeployNGNs.s.sol:DeployNGNs --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

# --- ACCESS CONTROL (ROLES) ---
# Fixed length mismatch by ensuring keccak result is captured correctly
GRANT-ROLE-BASE-TESTNET:
	cast send 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C "grantRole(bytes32,address)" $$(cast keccak "TREASURY_ROLE") ${BACKEND_MANAGER_ADDRESS} --rpc-url ${BASE_MAINNET_RPC_URL} --account mainKey

REVOKE-ROLE-BASE-TESTNET:
	cast send 0xae7597fa3414Bc94254fA7777663882355ED6Cb7 "revokeRole(bytes32,address)" $$(cast keccak "TREASURY_ROLE") 0x9Da6C69815A2b9FFe7eE08A0be00EF181881Ad71 --rpc-url ${BASE_MAINNET_RPC_URL} --account mainKey

GRANT-ROLE-BNB-MAINNET:
	cast send 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C "grantRole(bytes32,address)" $$(cast keccak "TREASURY_ROLE") 0x9Da6C69815A2b9FFe7eE08A0be00EF181881Ad71 --rpc-url ${BNB_MAINNET_RPC_URL} --account mainKey

GRANT-ROLE-BNB-TESTNET:
	cast send 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C "grantRole(bytes32,address)" $$(cast keccak "TREASURY_ROLE") ${BACKEND_MANAGER_ADDRESS} --rpc-url ${BNB_TESTNET_RPC_URL} --account mainKey

# --- OPERATIONAL STATUS ---
PAUSE-CONTRACT:
	cast send ${NGN_TOKEN_ADDRESS} "setOperationalStatus(bool)" false --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

RESUME-CONTRACT:
	cast send ${NGN_TOKEN_ADDRESS} "setOperationalStatus(bool)" true --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

BURN-MAINNET:
	cast send 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C "burn(address,uint256)" 0xcdb14a87f21be2efbde9cc857c056d23a37bce8f 17050e6 --rpc-url https://bnb-mainnet.g.alchemy.com/v2/ --account mainKey

MINT-TESTNET:
	cast send 0x210E93c6A658569bC4655820B9BcdD163e25fb2D "mint(address,uint256)" 0x29b71e1AC6c11B2455Bf5A4BFC30c6714EC6A2fD 20000e18 --rpc-url ${BNB_TESTNET_RPC_URL} --private-key 15eede1b5e4e834b6cc83913ebfc9aeb37238d0dd8c3556178910a4052edb1f1

MINT-MAINNET:
	cast send 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C "mint(address,uint256)" 0xcdb14a87f21be2efbde9cc857c056d23a37bce8f 17050e6 --rpc-url https://bnb-mainnet.g.alchemy.com/v2/ --account mainKey

FREEZE:
	cast send ${NGN_TOKEN_ADDRESS} "freezeAccountViaAlias(uint128)" 3175982357 --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

UNFREEZE:
	cast send ${NGN_TOKEN_ADDRESS} "unfreezeAccountViaAlias(uint128)" 3175982357 --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey