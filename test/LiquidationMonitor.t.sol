// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {LiquidationMonitor} from "../src/LiquidationMonitor.sol";
import {IAavePool} from "../src/interfaces/IAavePool.sol";

// Mock Aave Pool for testing
contract MockAavePool is IAavePool {
    uint256 public mockHealthFactor = 2e18; // Default: safe (2.0)

    function setHealthFactor(uint256 hf) external {
        mockHealthFactor = hf;
    }

    function getUserAccountData(address)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256 healthFactor)
    {
        return (0, 0, 0, 0, 0, mockHealthFactor);
    }
}

contract LiquidationMonitorTest is Test {
    LiquidationMonitor public monitor;
    MockAavePool public mockPool;

    address public owner = address(this);
    address public wallet1 = address(0x1111);
    address public wallet2 = address(0x2222);

    // Events to test
    event WalletAdded(address indexed wallet);
    event WalletRemoved(address indexed wallet);
    event HealthChecked(address indexed wallet, uint256 healthFactor, uint8 status);
    event WarningAlert(address indexed wallet, uint256 healthFactor, uint256 blockNumber);
    event CriticalAlert(address indexed wallet, uint256 healthFactor, uint256 blockNumber);
    event PositionSafe(address indexed wallet, uint256 healthFactor);

    function setUp() public {
        mockPool = new MockAavePool();
        monitor = new LiquidationMonitor(address(mockPool));
    }

    // ─── Wallet Management Tests ───────────────────────────────

    function test_AddWallet() public {
        monitor.addWallet(wallet1);
        assertTrue(monitor.isMonitored(wallet1));
        assertEq(monitor.getWalletCount(), 1);
    }

    function test_AddWalletEmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit WalletAdded(wallet1);
        monitor.addWallet(wallet1);
    }

    function test_CannotAddDuplicateWallet() public {
        monitor.addWallet(wallet1);
        vm.expectRevert("Already monitored");
        monitor.addWallet(wallet1);
    }

    function test_RemoveWallet() public {
        monitor.addWallet(wallet1);
        monitor.removeWallet(wallet1);
        assertFalse(monitor.isMonitored(wallet1));
        assertEq(monitor.getWalletCount(), 0);
    }

    function test_OnlyOwnerCanAddWallet() public {
        vm.prank(address(0x9999));
        vm.expectRevert("Not owner");
        monitor.addWallet(wallet1);
    }

    // ─── Health Check Tests ────────────────────────────────────

    function test_SafeHealthFactor() public {
        monitor.addWallet(wallet1);
        mockPool.setHealthFactor(2e18); // 2.0 = safe

        (uint256 hf, uint8 status) = monitor.checkHealth(wallet1);
        assertEq(hf, 2e18);
        assertEq(status, 1); // Safe
    }

    function test_WarningAlert() public {
        monitor.addWallet(wallet1);
        mockPool.setHealthFactor(1.08e18); // 1.08 = below danger threshold

        vm.expectEmit(true, false, false, false);
        emit WarningAlert(wallet1, 1.08e18, block.number);

        (, uint8 status) = monitor.checkHealth(wallet1);
        assertEq(status, 2); // Danger
    }

    function test_CriticalAlert() public {
        monitor.addWallet(wallet1);
        mockPool.setHealthFactor(1.02e18); // 1.02 = critical

        vm.expectEmit(true, false, false, false);
        emit CriticalAlert(wallet1, 1.02e18, block.number);

        (, uint8 status) = monitor.checkHealth(wallet1);
        assertEq(status, 3); // Critical
    }

    function test_PositionRecovery() public {
        monitor.addWallet(wallet1);

        // First: put in warning
        mockPool.setHealthFactor(1.08e18);
        monitor.checkHealth(wallet1);

        // Then: recover
        mockPool.setHealthFactor(1.5e18);

        vm.expectEmit(true, false, false, false);
        emit PositionSafe(wallet1, 1.5e18);

        (, uint8 status) = monitor.checkHealth(wallet1);
        assertEq(status, 0); // Recovered
    }

    function test_CheckAllWallets() public {
        monitor.addWallet(wallet1);
        monitor.addWallet(wallet2);
        mockPool.setHealthFactor(1.5e18);

        monitor.checkAllWallets(); // Should not revert

        assertEq(monitor.lastHealthFactor(wallet1), 1.5e18);
        assertEq(monitor.lastHealthFactor(wallet2), 1.5e18);
    }

    function test_UpdateThreshold() public {
        monitor.setDangerThreshold(1.2e18);
        assertEq(monitor.dangerThreshold(), 1.2e18);
    }
}
