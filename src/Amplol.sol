// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20Upgradeable, ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import {AmplolStore} from "./storage/AmplolStorage.sol";
import {IVault} from "./interface/IVault.sol";

contract Amplol is
    ERC20Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    AmplolStore
 {

    constructor() {
      _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, address _vault, uint256 _scalar, uint256 _timer, address _minter, address _owner) {
          if (_vault == address(0)) revert Bad3Jane();
          if (_scalar == 0) revert BadScalar();
          if (_minter == address(0)) revert BadMinter();
          if (_owner == address(0)) revert BadOwner();

          vault = IVault(_vault);
          scalar = _scalar;
          minter = _minter;
          timer = _timer;

          pTVL = 1 * 10 ** 18;

          _transferOwnership(_owner);
          __ReentrancyGuard_init_unchained();
          __ERC20_init_unchained(_name, _symbol);
    }

    function setScalar(uint256 _scalar) external onlyOwner {
      if (_scalar == 0) revert BadScalar();
      scalar = _scalar;
      emit NewScalar(_scalar);
    }

    function setTimer(uint256 _timer) external onlyOwner {
      timer = _timer;
      emit NewTimer(_timer);
    }

    function setMinter(address _minter) external onlyOwner {
      if (_minter == address(0)) revert BadMinter();
      minter = _minter;
      emit NewMinter(_minter);
    }

    function rebase() public {
        // Too early
        if (block.timestamp < pRebase + timer) revert BadRebase();
        uint256 cTVL = vault.totalBalance() / scalar;
        if (cTVL != pTVL) {
            uint256 rebaseRatio = cTVL * 1e18 / pTVL; // Calculate the rebase ratio with precision
            uint256 newSupply = totalSupply() * rebaseRatio / 1e18; // Adjust total supply based on the rebase ratio
            _rebase(newSupply); // Apply the new total supply
            pTVL = cTVL; // Update the last recorded TVL
            pRebase = block.timestamp; // Update last rebase time
        }
    }

    function _rebase(uint256 _newSupply) internal {
        uint256 currentSupply = totalSupply();
        if (_newSupply > currentSupply) {
            _mint(address(this), _newSupply - currentSupply); // Mint the difference if the new supply is greater
        } else if (_newSupply < totalSupply()) {
            _burn(address(this), currentSupply - _newSupply); // Burn the difference if the new supply is lesser
        }
    }

    function mint(address _recipient, uint256 _amount) external {
      if (_minter != address(0)) revert BadMinter();
      _mint(_recipient, _amount);
    }

    function nRebase() external view returns (uint256) {
      return pRebase + timer;
    }

    /// @dev Authorizes an upgrade, ensuring that the owner is performing the upgrade
    /// @param newImplementation The new contract implementation to upgrade to
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
