// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/***
 * @title Salva NGNs Stablecoin
 * @author Salva
 * @notice Standard ERC20 implementation of the Nigerian Naira Stablecoin.
 */
contract NGNs is Initializable, AccessControlUpgradeable, UUPSUpgradeable, ERC20Upgradeable {
    // --- Access Control Roles ---
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    // --- State Variables ---
    bool private _isOperational;
    mapping(address => bool) private _isBlacklisted;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[50] private __gap;

    // --- Events ---
    event OperationalStatusChanged(bool status);
    event AccountFrozen(address indexed wallet);
    event AccountUnfrozen(address indexed wallet);

    // --- Custom Errors ---
    error NotOperational();
    error AccountIsFrozen(address wallet);

    // --- Modifiers ---
    modifier onlyIfOperational() {
        if (!_isOperational && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotOperational();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the NGNs contract.
     */
    function initialize() public initializer {
        __AccessControl_init();
        __ERC20_init("Salva NGNs", "NGNs");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TREASURY_ROLE, msg.sender);
        _isOperational = true;
    }

    // --- Administrative Functions ---

    function setOperationalStatus(bool operational) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _isOperational = operational;
        emit OperationalStatusChanged(operational);
    }

    function freezeAccount(address wallet) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isBlacklisted[wallet] = true;
        emit AccountFrozen(wallet);
    }

    function unfreezeAccount(address wallet) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isBlacklisted[wallet] = false;
        emit AccountUnfrozen(wallet);
    }

    // --- Token Core Functions ---
    function approve(address spender, uint256 value) public override onlyIfOperational returns (bool) {
        return super.approve(spender, value);
    }

    function mint(address account, uint256 amount) public onlyRole(TREASURY_ROLE) onlyIfOperational {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyRole(TREASURY_ROLE) onlyIfOperational {
        _burn(account, amount);
    }

    /**
     * @notice Overridden decimals to 6 for stablecoin precision.
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    // --- Internal Overrides ---

    /**
     * @dev Internal hook for all transfers (mint, burn, transfer).
     * Includes checks for operational status and blacklisted addresses.
     */
    function _update(address from, address to, uint256 amount) internal override {
        // Global circuit breaker check
        if (!_isOperational && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotOperational();
        }

        // Sanction/Blacklist checks
        if (_isBlacklisted[from] || _isBlacklisted[to]) {
            revert AccountIsFrozen(_isBlacklisted[from] ? from : to);
        }

        super._update(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // --- Views ---

    function isAccountFrozen(address wallet) public view returns (bool) {
        return _isBlacklisted[wallet];
    }

    function isOperational() public view returns (bool) {
        return _isOperational;
    }
}
