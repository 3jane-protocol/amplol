// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IAmplol} from "../interface/IAmplol.sol";
import {IVault} from "../interface/IVault.sol";

// Amplol store
abstract contract AmplolStore is IAmplol {
    // This will act as the scaling factor for balance calculations
    uint256 internal base;
    // Previous TVL
    uint256 internal pTVL;
    // Previous Rebase
    uint256 internal pRebase;
    // Can transfer
    bool public canTransfer;
    // Timer between rebases
    uint256 public timer;
    // 3Jane vault
    IVault public vault;
}
