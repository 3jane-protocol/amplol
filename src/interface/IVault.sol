// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// 3Jane vault interface
interface IVault {
  function totalBalance() external view returns (uint256);
}
