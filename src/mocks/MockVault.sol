// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// MockVault
contract MockVault {
    uint256 public totalBalance;

    function setTotalBalance(uint256 _totalBalance) external {
        totalBalance = _totalBalance;
    }
}
