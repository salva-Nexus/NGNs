# Load environment variables from .env
include .env

# --- WALLET MANAGEMENT ---
ADD-KEY:
	cast wallet import salva_admin --interactive 

# --- DEPLOYMENT ---

DEPLOY-TO-ETH_MAINNET:
	forge script script/DeployNGNs.s.sol:DeployNGNs --rpc-url ${ETH_MAINNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

DEPLOY-TO-ETH_TESTNET:
	forge script script/DeployNGNs.s.sol:DeployNGNs --rpc-url ${ETH_SEPOLIA_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}


DEPLOY-TO-BASE_MAINNET:
	forge script script/DeployNGNs.s.sol:DeployNGNs --rpc-url ${BASE_MAINNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

DEPLOY-TO-BASE_TESTNET:
	forge script script/DeployNGNs.s.sol:DeployNGNs --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

# --- ACCESS CONTROL (ROLES) ---
# Fixed length mismatch by ensuring keccak result is captured correctly
GRANT-ROLE:
	cast send 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C "grantRole(bytes32,address)" $$(cast keccak "TREASURY_ROLE") ${BACKEND_MANAGER_ADDRESS} --rpc-url ${BASE_MAINNET_RPC_URL} --account mainKey

REVOKE-ROLE:
	cast send 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C "revokeRole(bytes32,address)" $$(cast keccak "TREASURY_ROLE") 0x9Da6C69815A2b9FFe7eE08A0be00EF181881Ad71 --rpc-url ${BASE_MAINNET_RPC_URL} --account mainKey

# --- OPERATIONAL STATUS ---
PAUSE-CONTRACT:
	cast send ${NGN_TOKEN_ADDRESS} "setOperationalStatus(bool)" false --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

RESUME-CONTRACT:
	cast send ${NGN_TOKEN_ADDRESS} "setOperationalStatus(bool)" true --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

BURN-MAINNET:
	cast send 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C "burn(address,uint256)" 0x2250bf1c33977251a9c7b981a6f12f5d9203722d 17050e6 --rpc-url https://base-mainnet.g.alchemy.com/v2/Xw8PCp_3hHh_MOBnHUy6J --private-key $(BACKEND_PRIVATE_KEY)

MINT-TESTNET:
	cast send 0xae7597fa3414Bc94254fA7777663882355ED6Cb7 "mint(address,uint256)" 0xfD5A9828bac27495FAb7F6174b3de386E0554187 1000000e6 --rpc-url https://base-sepolia.g.alchemy.com/v2/6BNajqzojJOGGBKndC6FR --private-key 

MINT-MAINNET:
	cast send 0x78E9917e6A7D7DD2fd3fc031723741F4f755641C "mint(address,uint256)" 0x854c565648cea8e8fd160a2c784257f9f9698156 17050e6 --rpc-url https://base-mainnet.g.alchemy.com/v2/6BNajqzojJOGGBKndC6FR --private-key $(BACKEND_PRIVATE_KEY)

FREEZE:
	cast send ${NGN_TOKEN_ADDRESS} "freezeAccountViaAlias(uint128)" 3175982357 --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

UNFREEZE:
	cast send ${NGN_TOKEN_ADDRESS} "unfreezeAccountViaAlias(uint128)" 3175982357 --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey