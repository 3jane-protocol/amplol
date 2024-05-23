// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IAmplol} from "../interface/IAmplol.sol";
import {IVault} from "../interface/IVault.sol";

// Amplol store
abstract contract AmplolStore is IAmplol {
    // Previous Rebase
    uint256 public pRebase;
    // TVL
    uint256 public tvl;
    // Can transfer
    bool public canTransfer;
    // 3Jane vault
    IVault public vault;
    // Gap is left to avoid storage collisions.
    uint256[30] private ____gap;
}
