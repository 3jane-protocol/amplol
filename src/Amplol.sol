// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {AmplolStore} from "./storage/AmplolStorage.sol";
import {IVault} from "./interface/IVault.sol";

contract Amplol is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, AmplolStore {
    uint256 private constant FUN = 1e6;

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, address _owner) external initializer {
        if (_owner == address(0)) revert BadOwner();
        _transferOwnership(_owner);
        __ERC20_init_unchained(_name, _symbol);
    }

    function setVault(address _vault, uint256 _tvl) external onlyOwner {
        if (_vault == address(0) || address(vault) != address(0)) revert Bad3Jane();
        vault = IVault(_vault);
        tvl = _tvl;
        emit NewVault(_vault, tvl);
    }

    function toggleTransfer() external onlyOwner {
        canTransfer = !canTransfer;
        emit ToggleTransfer(canTransfer);
    }

    function mint(address _recipient, uint256 _amount) external {
        if (msg.sender != address(vault)) revert BadMinter();
        _rebase();
        _mint(_recipient, _amount * FUN * 1e18 / tvl);
    }

    function burn(address _recipient, uint256 _amount) external {
        if (msg.sender != address(vault)) revert BadBurner();
        _burn(_recipient, Math.min(super.balanceOf(_recipient), _amount * FUN * 1e18 / tvl));
        _rebase();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) * tvl / 1e18;
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() * tvl / 1e18;
    }

    function _rebase() internal {
        uint256 newTVL = vault.totalBalance();
        emit Rebase(tvl, newTVL, pRebase);
        tvl = newTVL; // Update the last recorded TVL
        pRebase = block.timestamp; // Update last rebase time
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (from != address(0) && to != address(0) && !canTransfer) revert BadTransfer();
        super._update(from, to, amount);
    }

    /// @dev Authorizes an upgrade, ensuring that the owner is performing the upgrade
    /// @param newImplementation The new contract implementation to upgrade to
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
