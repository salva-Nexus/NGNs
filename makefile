# Load environment variables from .env
include .env

# --- TESTING ---
FORGE_TEST_SEPOLIA: 
	forge test --fork-url ${SEPOLIA_RPC_URL} -vvvv

FORGE_TEST_MAINNET: 
	forge test --fork-url ${ETH_MAINNET_RPC_URL} -vvvv

# --- WALLET MANAGEMENT ---
ADD-KEY:
	cast wallet import salva_admin --interactive 

# --- DEPLOYMENT ---
DEPLOY-TO-BASE_MAINNET:
	forge script script/DeployNGNs.s.sol:DeployNGNs --rpc-url ${BASE_MAINNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

DEPLOY-TO-BASE_TESTNET:
	forge script script/DeployNGNs.s.sol:DeployNGNs --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

# --- ACCESS CONTROL (ROLES) ---
# Fixed length mismatch by ensuring keccak result is captured correctly
GRANT-ROLE:
	cast send ${REGISTRY_CONTRACT_ADDRESS} "grantRole(bytes32,address)" $$(cast keccak "REGISTRAR_ROLE") ${BACKEND_MANAGER_ADDRESS} --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

REVOKE-ROLE:
	cast send ${NGN_TOKEN_ADDRESS} "revokeRole(bytes32,address)" $$(cast keccak "TREASURY_ROLE") ${BACKEND_MANAGER_ADDRESS} --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

# --- OPERATIONAL STATUS ---
PAUSE-CONTRACT:
	cast send ${NGN_TOKEN_ADDRESS} "setOperationalStatus(bool)" false --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

RESUME-CONTRACT:
	cast send ${NGN_TOKEN_ADDRESS} "setOperationalStatus(bool)" true --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

BURN:
	cast send ${NGN_TOKEN_ADDRESS} "burnViaAccountAlias(uint128,uint256)" 5265733930 144000e6 --rpc-url ${BASE_SEPOLIA_RPC_URL} --private-key $(BACKEND_PRIVATE_KEY)

MINT:
	cast send ${NGN_TOKEN_ADDRESS} "mintViaAccountAlias(uint128,uint256)" 5265733930 144000e6 --rpc-url ${BASE_SEPOLIA_RPC_URL} --private-key $(BACKEND_PRIVATE_KEY)

FREEZE:
	cast send ${NGN_TOKEN_ADDRESS} "freezeAccountViaAlias(uint128)" 3175982357 --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey

UNFREEZE:
	cast send ${NGN_TOKEN_ADDRESS} "unfreezeAccountViaAlias(uint128)" 3175982357 --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey