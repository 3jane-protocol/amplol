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
    }

    function testConstructor() public {
        assertEq(address(amplol.vault()), address(vault));
        assertEq(amplol.timer(), timer);
        assertEq(amplol.owner(), address(this));
        assertEq(amplol.name(), name);
        assertEq(amplol.symbol(), symbol);
        assertEq(amplol.canTransfer(), false);
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
      
    }


    function testnRebase() public {
        assertEq(amplol.nRebase(), start + timer);
    }
}
