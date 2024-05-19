// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IAmplol} from "../interface/IAmplol.sol";
import {IVault} from "../interface/IVault.sol";

// Amplol store
abstract contract AmplolStore is IAmplol {
    // Previous Rebase
    uint256 internal pRebase;
    // TVL
    uint256 public tvl;
    // Can transfer
    bool public canTransfer;
    // Timer between rebases
    uint256 public timer;
    // 3Jane vault
    IVault public vault;
}
