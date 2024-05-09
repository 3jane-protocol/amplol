// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IVault} from "../interface/IVault.sol";

// Amplol interface
interface IAmplol {
    error Bad3Jane();
    error BadOwner();
    error BadMinter();
    error BadBurner();
    error EarlyRebase();
    error BadRebase();
    error BadTransfer();

    event NewTimer(uint256 timer);
    event ToggleTransfer(bool canTransfer);
    event Rebase(uint256 base, uint256 pTVL, uint256 pRebase);

    function setTimer(uint256) external;
    function toggleTransfer() external;
    function rebase() external;

    function vault() external view returns (IVault);
    function timer() external view returns (uint256);
    function canTransfer() external view returns (bool);
    function nRebase() external view returns (uint256);
}
