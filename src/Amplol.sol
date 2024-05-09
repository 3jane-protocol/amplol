// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import {AmplolStore} from "./storage/AmplolStorage.sol";
import {IVault} from "./interface/IVault.sol";

contract Amplol is ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, AmplolStore {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _vault,
        uint256 _timer,
        uint256 _pTVL,
        address _owner
    ) external initializer {
        if (_vault == address(0)) revert Bad3Jane();
        if (_owner == address(0)) revert BadOwner();

        vault = IVault(_vault);
        timer = _timer;
        pTVL = _pTVL;

        _transferOwnership(_owner);
        __ReentrancyGuard_init_unchained();
        __ERC20_init_unchained(_name, _symbol);
    }

    function setTimer(uint256 _timer) external onlyOwner {
        timer = _timer;
        emit NewTimer(_timer);
    }

    function toggleTransfer() external onlyOwner {
        canTransfer = !canTransfer;
        emit ToggleTransfer(canTransfer);
    }

    function rebase() public {
        // Too early
        if (block.timestamp < pRebase + timer) revert EarlyRebase();
        uint256 cTVL = vault.totalBalance();
        // numba up-only LOL
        if (cTVL < pTVL) revert BadRebase();
        base *= cTVL / pTVL;
        pTVL = cTVL; // Update the last recorded TVL
        pRebase = block.timestamp; // Update last rebase time
        emit Rebase(base, pTVL, pRebase);
    }

    function mint(address _recipient, uint256 _amount) external {
        if (msg.sender != address(vault)) revert BadMinter();
        _mint(_recipient, _amount * 1e18 / base);
    }

    function burn(address _recipient, uint256 _amount) external {
        if (msg.sender != address(vault)) revert BadBurner();
        _burn(_recipient, _amount * base / 1e18);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) * base / 1e18;
    }

    function nRebase() external view returns (uint256) {
        return pRebase + timer;
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (from != address(0) && to != address(0) && !canTransfer) revert BadTransfer();
        super._update(from, to, amount);
    }

    /// @dev Authorizes an upgrade, ensuring that the owner is performing the upgrade
    /// @param newImplementation The new contract implementation to upgrade to
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
