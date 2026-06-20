// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC7943Fungible is IERC165 {
    // ─── EVENTS
    // ───────────────────────────────────────────────────────────────
    event ForcedTransfer(address indexed from, address indexed to, uint256 amount);

    // ─── ERRORS
    // ───────────────────────────────────────────────────────────────
    error ERC7943CannotReceive();
    error ERC7943CannotSend_Or_Receive();

    // ─── FUNCTIONS
    // ────────────────────────────────────────────────────────────
    function forcedTransfer(address from, address to, uint256 amount) external returns (bool);
    function canSend(address account) external view returns (bool);
    function canReceive(address account) external view returns (bool);
}
