// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {IAmplol} from "../src/interface/IAmplol.sol";
import {Amplol} from "../src/Amplol.sol";
import {MockVault} from "../src/mocks/MockVault.sol";

contract AmplolTest is Test {
    uint256 public constant account = 1;
    uint256 public constant account2 = 2;

    Amplol public amplol;
    MockVault public vault;

    uint256 private constant FUN = 888;
    uint256 private constant BASE = 300 * 1e18;
    string public name = "AMPLOL";
    string public symbol = "AMPLOL";
    uint256 private start;
    uint256 public startTotalBalance = 100 * 1e18;

    address public amplolImplementation;

    event NewVault(address vault, uint256 tvl);
    event ToggleTransfer(bool canTransfer);
    event Rebase(uint256 pTVL, uint256 tvl, uint256 pRebase);
    event Mint(address indexed recipient, uint256 amount, uint256 tvl);
    event Burn(address indexed recipient, uint256 amount, uint256 tvl);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        vault = new MockVault();

        amplolImplementation = address(new Amplol());

        amplol = Amplol(
            address(
                new ERC1967Proxy(
                    amplolImplementation,
                    abi.encodeWithSelector(Amplol.initialize.selector, name, symbol, address(this))
                )
            )
        );

        start = block.timestamp;
        amplol.setVault(address(vault), startTotalBalance);
        vault.setTotalBalance(startTotalBalance);
    }

    function testConstructor() public {
        assertEq(address(amplol.vault()), address(vault));
        assertEq(amplol.owner(), address(this));
        assertEq(amplol.name(), name);
        assertEq(amplol.symbol(), symbol);
        assertEq(amplol.canTransfer(), false);
        assertEq(amplol.tvlBase(), BASE);
    }

    function testSetVaultAlreadySet() public {
        vm.expectRevert(IAmplol.Bad3Jane.selector);
        amplol.setVault(address(1), 1);
    }

    function testSetVaultUnauthorized() public {
        vm.prank(vm.addr(account));

        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, vm.addr(account))
        );

        amplol.setVault(address(1), 1);
    }

    function testToggleTransfer() public {
        assertEq(amplol.canTransfer(), false);
        vm.expectEmit(true, true, true, true, address(amplol));
        emit ToggleTransfer(true);
        amplol.toggleTransfer();

        assertEq(amplol.canTransfer(), true);
    }

    function testToggleTransferUnauthorized() public {
        vm.prank(vm.addr(account));

        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, vm.addr(account))
        );

        amplol.toggleTransfer();
    }

    function testMint() public {
        vm.prank(address(vault));

        uint256 amount = 1e18;

        vm.expectEmit(true, true, true, true, address(amplol));
        emit Transfer(address(0), vm.addr(account), amount * FUN * 1e18 / BASE);
        emit Mint(vm.addr(account), amount * FUN * 1e18 / BASE, BASE);
        amplol.mint(vm.addr(account), amount);

        assertEq(amplol.balanceOf(vm.addr(account)), (amount * FUN * 1e18 / BASE) * BASE / 1e18);
        assertEq(amplol.totalSupply(), (amount * FUN * 1e18 / BASE) * BASE / 1e18);
    }

    function testMintUnauthorized() public {
        vm.prank(vm.addr(account2));

        vm.expectRevert(IAmplol.BadMinter.selector);

        amplol.mint(address(this), 100);
    }

    function testBurner() public {
        vm.prank(address(vault));

        uint256 amount = 1e18;

        amplol.mint(vm.addr(account), amount);

        vm.expectEmit(true, true, true, true, address(amplol));
        emit Transfer(vm.addr(account), address(0), amount * FUN * 1e18 / BASE);
        emit Burn(vm.addr(account), amount * FUN * 1e18 / BASE, BASE);
        vm.prank(address(vault));
        amplol.burn(vm.addr(account), amount);

        assertEq(amplol.balanceOf(vm.addr(account)), 0);
        assertEq(amplol.totalSupply(), 0);
    }

    function testBurnUnauthorized() public {
        vm.prank(vm.addr(account2));

        vm.expectRevert(IAmplol.BadBurner.selector);

        amplol.burn(address(this), 100);
    }

    function testRebase() public {
        // Alice deposits 10 eETH when latest rebase totalBalance = 100 eETH, base = 2.
        vault.setTotalBalance(startTotalBalance * 2 + BASE);

        uint256 amount = 10 * 1e18;
        address alice = vm.addr(account);
        vm.prank(address(vault));
        amplol.mint(alice, amount);
        uint256 tvl = amplol.tvlBase();

        assertEq(tvl, startTotalBalance * 2 + BASE);
        // She gets minted back 5000 (10 eETH / 2 * 1000) AMPLOL’s.
        // Her balanceOf is still 10000 though

        assertEq(amplol.balanceOf(alice), amount * FUN);

        assertEq(amplol.totalSupply(), amount * FUN);

        // At the next rebase, the totalBalance = 200 eETH and so the base = 4 (2 * 200 / 100).
        vault.setTotalBalance(startTotalBalance * 4 + BASE);

        vm.prank(address(vault));
        amplol.mint(alice, 0);

        tvl = amplol.tvlBase();

        assertEq(tvl, startTotalBalance * 4 + BASE);
        // Her minted AMPLOL balance remains the same, but her balanceOf will indicate
        // that her balance is 20,000 AMPLOL’s (5000 * 4).
        // Her AMPLOL balance has increased because of the rebase mechanism since
        // the TVL went up 2x.

        assertEq(
            amplol.balanceOf(alice), amount * (startTotalBalance * 4 + BASE) / (startTotalBalance * 2 + BASE) * FUN
        );

        assertEq(amplol.totalSupply(), amount * (startTotalBalance * 4 + BASE) / (startTotalBalance * 2 + BASE) * FUN);
        // She later decides to withdraw 50% of her eETH, so 1250 (10 eETH / 4 * 1000) AMPLOL’s get burned.
        vm.prank(address(vault));
        amplol.burn(alice, amount / 2);

        assertEq(amplol.balanceOf(alice), 0);
        assertEq(amplol.totalSupply(), 0);
    }
}
