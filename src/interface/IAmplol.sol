// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IVault} from "../interface/IVault.sol";

// Amplol interface
interface IAmplol {
    error Bad3Jane();
    error BadOwner();
    error BadMinter();
    error BadBurner();
    error BadTransfer();

    event NewVault(address vault, uint256 tvl);
    event ToggleTransfer(bool canTransfer);
    event Rebase(uint256 pTVL, uint256 tvl, uint256 pRebase);

    function setVault(address, uint256) external;
    function toggleTransfer() external;
    function tvl() external view returns (uint256);
    function vault() external view returns (IVault);
    function canTransfer() external view returns (bool);
    function pRebase() external view returns (uint256);
}
