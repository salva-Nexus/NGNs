// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library AccessManager {
    error AccessManager__Wallet_Already_Assigned();
    error AccessManager__Wallet_Blacklisted();
    error AccessManager__Not_Authorized();
    error AccessManager__Activity_Paused();

    function _alreadyAssigned(address _registeredAddress, uint128 _registeredNumber) internal pure {
        if (_registeredAddress != address(0) || _registeredNumber != 0) {
            revert AccessManager__Wallet_Already_Assigned();
        }
    }

    function _isBlacklisted(bool _blacklisted) internal pure {
        if (_blacklisted) revert AccessManager__Wallet_Blacklisted();
    }

    function _whenNotOperational(bool _isOperational, bool _hasRole) internal pure {
        if (!_isOperational && !_hasRole) revert AccessManager__Activity_Paused();
    }
}
