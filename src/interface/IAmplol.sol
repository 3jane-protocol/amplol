// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IVault} from "../interface/IVault.sol";

// Amplol interface
interface IAmplol {
    error Bad3Jane();
    error BadScalar();
    error BadMinter();
    error BadOwner();
    error EarlyRebase();
    error BadRebase();

    event NewScalar(uint256 scalar);
    event NewTimer(uint256 timer);
    event NewMinter(address indexed minter);
    event Rebase(uint256 base, uint256 pTVL, uint256 pRebase);

    function setScalar(uint256 _scalar) external;
    function setMinter(address _minter) external;
    function rebase() external;

    function scalar() external view returns (uint256);
    function vault() external view returns (IVault);
    function nRebase() external view returns (uint256);
}
