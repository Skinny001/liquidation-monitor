// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {LiquidationMonitor} from "../src/LiquidationMonitor.sol";

contract Simulate is Script {
    // Deployed contract address
    address constant MONITOR_ADDRESS = 0x9a129Ef786fff0F9Ce334A10D6ae1691399755cc;

    // Real mainnet wallets that had Aave positions during volatile periods
    address[] public walletsToMonitor = [
        0x176F3DAb24a159341c0509bB36B833E7fdd0a132,
        0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9,
        0xBcca60bB61934080951369a648Fb03DF4F96263C,
        0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B,
        0x398eC7346DcD622eDc5ae82352F02bE94C62d119
    ];

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        LiquidationMonitor monitor = LiquidationMonitor(MONITOR_ADDRESS);

        // Step 1 — Register all wallets
        console.log("=== Registering wallets ===");
        for (uint256 i = 0; i < walletsToMonitor.length; i++) {
            monitor.addWallet(walletsToMonitor[i]);
            console.log("Added wallet:", walletsToMonitor[i]);
        }

        // Step 2 — Run health check once
        console.log("=== Running health check ===");
        monitor.checkAllWallets();
        console.log("Health check completed");

        console.log("=== Simulation complete ===");
        console.log("Total wallets monitored:", monitor.getWalletCount());

        vm.stopBroadcast();
    }
}
