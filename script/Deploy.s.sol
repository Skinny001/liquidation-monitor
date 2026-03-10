// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {LiquidationMonitor} from "../src/LiquidationMonitor.sol";

contract Deploy is Script {
    // Aave V3 Pool address on Ethereum Mainnet
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        LiquidationMonitor monitor = new LiquidationMonitor(AAVE_POOL);

        console.log("LiquidationMonitor deployed at:", address(monitor));
        console.log("Aave Pool:", AAVE_POOL);
        console.log("Owner:", monitor.owner());

        vm.stopBroadcast();
    }
}
