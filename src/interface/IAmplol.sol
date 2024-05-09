// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Amplol interface
interface IAmplol {
  error Bad3Jane();
  error BadScalar();
  error BadMinter();
  error BadRebase();

  event NewScalar(uint256 scalar);
  event Newtimer(uint256 timer);
  event NewMinter(address indexed minter);

  function setScalar(uint256 _scalar) external;
  function setMinter(address _minter) external;
  function rebase() external;

  function scalar() external view returns (uint256);
  function vault() external view returns (address);
  function nRebase() external view returns (uint256);
}
