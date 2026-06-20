// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC7943Fungible } from "./Interfaces/IERC7943.sol";
import {
    AccessControlUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Salva NGNs Stablecoin
 * @author Salva
 * @notice ERC-20 stablecoin pegged to the Nigerian Naira, compliant with the
 *         ERC-7943 Universal RWA interface. Supports account-level compliance
 *         controls, a global circuit breaker, and privileged forced transfers.
 *
 * @dev Upgradeable via UUPS proxy pattern. Role-based access control is used
 *      for all privileged operations:
 *
 *      DEFAULT_ADMIN_ROLE → freeze/unfreeze accounts, pause/unpause, upgrade
 *      TREASURY_ROLE      → mint, burn, forcedTransfer
 *
 *      ERC-7943 compliance note:
 *      NGNs implements a subset of IERC7943Fungible. The frozen-token mechanics
 *      (setFrozenTokens / getFrozenTokens) are intentionally omitted — NGNs
 *      uses a binary blacklist instead of partial freezing, which is sufficient
 *      for Naira stablecoin compliance requirements. canTransfer is also omitted
 *      as canSend + canReceive cover all transfer eligibility checks needed.
 */
contract NGNs is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC20Upgradeable,
    IERC7943Fungible
{
    // ─── ROLES
    // ────────────────────────────────────────────────────────────────

    /// @notice Role granted to the treasury — can mint, burn, and force transfer.
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    // ─── STATE
    // ────────────────────────────────────────────────────────────────

    /// @dev Global circuit breaker. When false, all token operations are halted
    ///      except for DEFAULT_ADMIN_ROLE holders.
    bool private _isOperational;

    /// @dev Blacklist mapping. Blacklisted accounts cannot send or receive tokens.
    mapping(address => bool) private _isBlacklisted;

    /// @dev Storage gap for future upgrades — preserves storage layout across versions.
    uint256[50] private __gap;

    // ─── EVENTS
    // ───────────────────────────────────────────────────────────────

    /// @notice Emitted when the operational status of the contract changes.
    /// @param status True if operational, false if paused.
    event OperationalStatusChanged(bool status);

    /// @notice Emitted when an account is blacklisted.
    /// @param wallet The address that was frozen.
    event AccountFrozen(address indexed wallet);

    /// @notice Emitted when an account is removed from the blacklist.
    /// @param wallet The address that was unfrozen.
    event AccountUnfrozen(address indexed wallet);

    // ─── ERRORS
    // ───────────────────────────────────────────────────────────────

    /// @notice Thrown when an operation is attempted while the contract is paused.
    error NotOperational();

    /// @notice Thrown when a blacklisted account attempts a token operation,
    ///         or when a transfer is attempted to/from a blacklisted account.
    error AccountIsFrozen(address wallet);

    // ─── MODIFIERS
    // ────────────────────────────────────────────────────────────

    /**
     * @dev Reverts if the contract is paused, unless the caller holds DEFAULT_ADMIN_ROLE.
     *      Admins retain access during pause for emergency operations.
     */
    modifier onlyIfOperational() {
        if (!_isOperational && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotOperational();
        }
        _;
    }

    // ─── CONSTRUCTOR
    // ──────────────────────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ─── INITIALIZER
    // ──────────────────────────────────────────────────────────

    /**
     * @notice Initializes the NGNs contract.
     * @dev Called once on proxy deployment. Grants DEFAULT_ADMIN_ROLE and
     *      TREASURY_ROLE to the deployer and sets the contract as operational.
     */
    function initialize() public initializer {
        __AccessControl_init();
        __ERC20_init("Salva NGNs", "NGNs");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TREASURY_ROLE, msg.sender);
        _isOperational = true;
    }

    // ─── ERC-7943 COMPLIANCE
    // ──────────────────────────────────────────────────

    /**
     * @notice Returns whether an account is eligible to send tokens.
     * @dev ERC-7943 account-level eligibility check. An account can send
     *      if and only if it is not blacklisted. Operational status is not
     *      checked here — that is enforced at the transfer level.
     * @param account The address to check.
     * @return allowed True if the account is not blacklisted.
     */
    function canSend(address account) public view returns (bool allowed) {
        return !_isBlacklisted[account];
    }

    /**
     * @notice Returns whether an account is eligible to receive tokens.
     * @dev ERC-7943 account-level eligibility check. An account can receive
     *      if and only if it is not blacklisted.
     * @param account The address to check.
     * @return allowed True if the account is not blacklisted.
     */
    function canReceive(address account) public view returns (bool allowed) {
        return !_isBlacklisted[account];
    }

    // ─── ERC-20 OVERRIDES
    // ─────────────────────────────────────────────────────

    /**
     * @notice Transfers tokens to a recipient.
     * @dev Enforces operational status and ERC-7943 canSend/canReceive checks.
     * @param to The recipient address.
     * @param value The amount to transfer.
     * @return True if the transfer succeeded.
     */
    function transfer(address to, uint256 value) public override onlyIfOperational returns (bool) {
        if (!canSend(msg.sender) || !canReceive(to)) {
            revert ERC7943CannotSend_Or_Receive();
        }
        return super.transfer(to, value);
    }

    /**
     * @notice Transfers tokens on behalf of another account.
     * @dev Enforces operational status and ERC-7943 canSend/canReceive checks.
     * @param from The account to transfer from.
     * @param to The recipient address.
     * @param value The amount to transfer.
     * @return True if the transfer succeeded.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        override
        onlyIfOperational
        returns (bool)
    {
        if (!canSend(from) || !canReceive(to)) {
            revert ERC7943CannotSend_Or_Receive();
        }
        return super.transferFrom(from, to, value);
    }

    /**
     * @notice Approves a spender to transfer tokens on behalf of the caller.
     * @dev Enforces operational status and checks both caller and spender eligibility.
     * @param spender The address authorized to spend.
     * @param value The allowance amount.
     * @return True if the approval succeeded.
     */
    function approve(address spender, uint256 value) public override onlyIfOperational returns (bool) {
        if (!canSend(msg.sender) || !canReceive(spender)) {
            revert ERC7943CannotSend_Or_Receive();
        }
        return super.approve(spender, value);
    }

    // ─── ERC-7943 FORCED TRANSFER
    // ─────────────────────────────────────────────

    /**
     * @notice Forcibly transfers tokens from one address to another.
     * @dev Restricted to TREASURY_ROLE. Bypasses canSend check on `from` to
     *      allow recovery from blacklisted accounts. Still enforces canReceive
     *      on `to` to prevent sending to blacklisted recipients.
     *      Emits {ForcedTransfer}.
     * @param from The address to take tokens from.
     * @param to The address to send tokens to.
     * @param amount The amount to transfer.
     * @return True if the forced transfer succeeded.
     */
    function forcedTransfer(address from, address to, uint256 amount)
        external
        onlyRole(TREASURY_ROLE)
        onlyIfOperational
        returns (bool)
    {
        if (!canReceive(to)) revert ERC7943CannotReceive();
        super._update(from, to, amount);
        emit ForcedTransfer(from, to, amount);
        return true;
    }

    // ─── TREASURY FUNCTIONS
    // ───────────────────────────────────────────────────

    /**
     * @notice Mints new NGNs tokens to a recipient.
     * @dev Restricted to TREASURY_ROLE. Contract must be operational and
     *      recipient must not be blacklisted.
     * @param to The address to mint tokens to.
     * @param amount The amount to mint (6 decimals).
     */
    function mint(address to, uint256 amount) public onlyRole(TREASURY_ROLE) onlyIfOperational {
        if (!canReceive(to)) revert ERC7943CannotReceive();
        _mint(to, amount);
    }

    /**
     * @notice Burns NGNs tokens from an account.
     * @dev Restricted to TREASURY_ROLE. Contract must be operational.
     *      Used for redemptions and supply management.
     * @param account The address to burn tokens from.
     * @param amount The amount to burn (6 decimals).
     */
    function burn(address account, uint256 amount) public onlyRole(TREASURY_ROLE) onlyIfOperational {
        _burn(account, amount);
    }

    // ─── ADMIN FUNCTIONS
    // ──────────────────────────────────────────────────────

    /**
     * @notice Sets the operational status of the contract.
     * @dev When set to false, all token operations are paused except for
     *      DEFAULT_ADMIN_ROLE holders. Acts as a global circuit breaker.
     *      Emits {OperationalStatusChanged}.
     * @param operational True to resume operations, false to pause.
     */
    function setOperationalStatus(bool operational) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _isOperational = operational;
        emit OperationalStatusChanged(operational);
    }

    /**
     * @notice Blacklists an account, preventing it from sending or receiving tokens.
     * @dev Restricted to DEFAULT_ADMIN_ROLE. Blacklisted accounts also cannot
     *      be recipients of mints. Emits {AccountFrozen}.
     * @param wallet The address to blacklist.
     */
    function freezeAccount(address wallet) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isBlacklisted[wallet] = true;
        emit AccountFrozen(wallet);
    }

    /**
     * @notice Removes an account from the blacklist.
     * @dev Restricted to DEFAULT_ADMIN_ROLE. Emits {AccountUnfrozen}.
     * @param wallet The address to remove from the blacklist.
     */
    function unfreezeAccount(address wallet) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isBlacklisted[wallet] = false;
        emit AccountUnfrozen(wallet);
    }

    // ─── VIEWS
    // ────────────────────────────────────────────────────────────────

    /**
     * @notice Returns whether an account is blacklisted.
     * @param wallet The address to check.
     * @return True if the account is blacklisted.
     */
    function isAccountFrozen(address wallet) public view returns (bool) {
        return _isBlacklisted[wallet];
    }

    /**
     * @notice Returns whether the contract is currently operational.
     * @return True if operational, false if paused.
     */
    function isOperational() public view returns (bool) {
        return _isOperational;
    }

    /**
     * @notice Returns the number of decimals used by NGNs.
     * @dev Overridden to 6 decimals for stablecoin precision,
     * @return 6
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /**
     * @notice Returns true if this contract implements the given interface.
     * @dev Supports IERC7943Fungible, IERC20, IERC165, and AccessControl interfaces.
     * @param interfaceId The interface identifier to check.
     * @return True if the interface is supported
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC7943Fungible).interfaceId || interfaceId == type(IERC20).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // ─── INTERNAL
    // ─────────────────────────────────────────────────────────────

    /**
     * @dev Authorizes a contract upgrade. Restricted to DEFAULT_ADMIN_ROLE.
     *      Required by UUPSUpgradeable.
     * @param newImplementation The address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) { }
}
