// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IVault} from "../interface/IVault.sol";

// Amplol interface
interface IAmplol {
    error Bad3Jane();
    error BadMinter();
    error BadOwner();
    error EarlyRebase();
    error BadRebase();
    error BadTransfer();

    event NewTimer(uint256 timer);
    event NewMinter(address indexed minter);
    event ToggleTransfer(bool canTransfer);
    event Rebase(uint256 base, uint256 pTVL, uint256 pRebase);

    function setMinter(address _minter) external;
    function rebase() external;

    function minter() external view returns (address);
    function vault() external view returns (IVault);
    function canTransfer() external view returns (bool);
    function nRebase() external view returns (uint256);
}
