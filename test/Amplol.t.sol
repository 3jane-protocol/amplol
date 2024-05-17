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

    Amplol public amplol;
    MockVault public vault;

    uint256 private constant FUN = 1000;
    string public name = "AMPLOL";
    string public symbol = "AMPLOL";
    uint256 public timer = 3600;
    uint256 public pTVL = 100;
    uint256 private start;
    uint256 public startTotalBalance = 100;

    address public amplolImplementation;

    event NewTimer(uint256 timer);
    event ToggleTransfer(bool canTransfer);
    event Rebase(uint256 base, uint256 pTVL, uint256 pRebase);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        vault = new MockVault();

        amplolImplementation = address(new Amplol());

        amplol = Amplol(
            address(
                new ERC1967Proxy(
                    amplolImplementation,
                    abi.encodeWithSelector(
                        Amplol.initialize.selector, name, symbol, address(vault), timer, pTVL, address(this)
                    )
                )
            )
        );

        start = block.timestamp;
        vault.setTotalBalance(startTotalBalance);
    }

    function testConstructor() public {
        assertEq(address(amplol.vault()), address(vault));
        assertEq(amplol.timer(), timer);
        assertEq(amplol.owner(), address(this));
        assertEq(amplol.name(), name);
        assertEq(amplol.symbol(), symbol);
        assertEq(amplol.canTransfer(), false);
        assertEq(amplol.base(), 1e18);
    }

    function testSetTimer() public {
        vm.expectEmit(true, true, true, true, address(amplol));
        emit NewTimer(200);
        amplol.setTimer(200);

        assertEq(amplol.timer(), 200);
    }

    function testSetTimerUnauthorized() public {
        vm.prank(vm.addr(account));

        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, vm.addr(account))
        );

        amplol.setTimer(100);
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

        uint256 amount = 100;

        vm.expectEmit(true, true, true, true, address(amplol));
        emit Transfer(address(0), vm.addr(account), amount * FUN);
        amplol.mint(vm.addr(account), amount);

        assertEq(amplol.balanceOf(vm.addr(account)), amount * FUN);
    }

    function testMintUnauthorized() public {
        vm.expectRevert(IAmplol.BadMinter.selector);

        amplol.mint(address(this), 100);
    }

    function testBurner() public {
        vm.prank(address(vault));

        uint256 amount = 100;

        amplol.mint(vm.addr(account), amount);

        vm.expectEmit(true, true, true, true, address(amplol));
        emit Transfer(vm.addr(account), address(0), amount * FUN);
        vm.prank(address(vault));
        amplol.burn(vm.addr(account), amount);

        assertEq(amplol.balanceOf(vm.addr(account)), 0);
    }

    function testBurnUnauthorized() public {
        vm.expectRevert(IAmplol.BadBurner.selector);

        amplol.burn(address(this), 100);
    }

    function testRebaseEarlyRebase() public {
        vm.expectRevert(IAmplol.EarlyRebase.selector);
        amplol.rebase();
    }

    function testRebase() public {
        // Alice deposits 10 eETH when latest rebase totalBalance = 100 eETH, base = 2.
        vault.setTotalBalance(startTotalBalance * 2);
        vm.warp(amplol.nRebase());
        amplol.rebase();

        uint256 amount = 10 * 1e18;
        address alice = vm.addr(account);
        uint256 base = amplol.base();
        vm.prank(address(vault));
        amplol.mint(alice, amount);

        assertEq(base, 2 * 1e18);
        // She gets minted back 5000 (10 eETH / 2 * 1000) AMPLOL’s.
        // Her balanceOf is still 10000 though
        assertEq(amplol.balanceOf(alice), amount * FUN);

        // At the next rebase, the totalBalance = 200 eETH and so the base = 4 (2 * 200 / 100).
        vault.setTotalBalance(startTotalBalance * 4);
        vm.warp(amplol.nRebase());
        amplol.rebase();

        base = amplol.base();
        assertEq(base, 4 * 1e18);
        // Her minted AMPLOL balance remains the same, but her balanceOf will indicate
        // that her balance is 20,000 AMPLOL’s (5000 * 4).
        // Her AMPLOL balance has increased because of the rebase mechanism since
        // the TVL went up 2x.
        assertEq(amplol.balanceOf(alice), amount * 2 * FUN);
        // She later decides to withdraw 50% of her eETH, so 1250 (10 eETH / 4 * 1000) AMPLOL’s get burned.
        vm.prank(address(vault));
        amplol.burn(alice, amount / 2);
        assertEq(amplol.balanceOf(alice), amount * 2 * FUN - amount / 2 * FUN);
    }

    function testnRebase() public {
        assertEq(amplol.nRebase(), start + timer);
    }
}
