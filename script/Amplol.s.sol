// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Amplol} from "src/Amplol.sol";

contract AmplolScript is Script {
    function run() public {
        vm.startBroadcast();

        address owner = 0xeAc05c331167B02540Aa52f2a2745Ce0278f7070;
        address amplolImplementation = address(new Amplol());
        address amplol = address(
            new ERC1967Proxy(
                amplolImplementation, abi.encodeWithSelector(Amplol.initialize.selector, "Amplol", "AMPLOL", owner)
            )
        );

        vm.stopBroadcast();

        console.log("Implementation");
        console.log(amplolImplementation);
        console.log("Proxy");
        console.log(amplol);
    }
}
