// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IAavePool} from "./interfaces/IAavePool.sol";
import {AutomationCompatibleInterface} from "./interfaces/AutomationCompatibleInterface.sol";

/// @title LiquidationMonitorAutomated
/// @notice Automated liquidation monitoring for Aave V3 positions with Chainlink Automation
/// @dev Implements AutomationCompatibleInterface for Chainlink Automation integration
contract LiquidationMonitorAutomated is AutomationCompatibleInterface {
    // ─── State Variables ───────────────────────────────────────
    address public owner;
    IAavePool public aavePool;

    address[] public monitoredWallets;
    mapping(address => bool) public isMonitored;
    mapping(address => uint256) public lastHealthFactor;

    // 1.1 scaled by 1e18
    uint256 public dangerThreshold = 1.1e18;
    // 1.05 scaled by 1e18
    uint256 public criticalThreshold = 1.05e18;

    // Automation settings
    uint256 public checkInterval = 5 minutes;
    uint256 public lastCheckTimestamp;

    // ─── Events ────────────────────────────────────────────────
    event WalletAdded(address indexed wallet);
    event WalletRemoved(address indexed wallet);
    event HealthChecked(
        address indexed wallet,
        uint256 healthFactor,
        uint8 status
    );
    event WarningAlert(
        address indexed wallet,
        uint256 healthFactor,
        uint256 blockNumber
    );
    event CriticalAlert(
        address indexed wallet,
        uint256 healthFactor,
        uint256 blockNumber
    );
    event PositionSafe(address indexed wallet, uint256 healthFactor);
    event AutomationPerformed(uint256 timestamp, uint256 walletsChecked);

    // ─── Modifiers ─────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // ─── Constructor ───────────────────────────────────────────
    constructor(address _aavePool) {
        owner = msg.sender;
        aavePool = IAavePool(_aavePool);
        lastCheckTimestamp = block.timestamp;
    }

    // ─── Wallet Management ─────────────────────────────────────

    function addWallet(address wallet) external onlyOwner {
        require(!isMonitored[wallet], "Already monitored");
        isMonitored[wallet] = true;
        monitoredWallets.push(wallet);
        emit WalletAdded(wallet);
    }

    function removeWallet(address wallet) external onlyOwner {
        require(isMonitored[wallet], "Not monitored");
        isMonitored[wallet] = false;

        for (uint256 i = 0; i < monitoredWallets.length; i++) {
            if (monitoredWallets[i] == wallet) {
                monitoredWallets[i] = monitoredWallets[
                    monitoredWallets.length - 1
                ];
                monitoredWallets.pop();
                break;
            }
        }
        emit WalletRemoved(wallet);
    }

    // ─── Health Checking ───────────────────────────────────────

    function checkHealth(address wallet)
        public
        returns (uint256 healthFactor, uint8 status)
    {
        (, , , , , healthFactor) = aavePool.getUserAccountData(wallet);

        uint256 previousHealth = lastHealthFactor[wallet];
        lastHealthFactor[wallet] = healthFactor;

        // Determine status
        if (healthFactor < criticalThreshold) {
            status = 3; // Critical
            emit CriticalAlert(wallet, healthFactor, block.number);
        } else if (healthFactor < dangerThreshold) {
            status = 2; // Danger
            emit WarningAlert(wallet, healthFactor, block.number);
        } else if (
            previousHealth != 0 &&
            previousHealth < dangerThreshold &&
            healthFactor >= dangerThreshold
        ) {
            status = 0; // Recovered
            emit PositionSafe(wallet, healthFactor);
        } else {
            status = 1; // Safe
        }

        emit HealthChecked(wallet, healthFactor, status);
    }

    function checkAllWallets() public {
        for (uint256 i = 0; i < monitoredWallets.length; i++) {
            checkHealth(monitoredWallets[i]);
        }
    }

    // ─── Chainlink Automation Interface ────────────────────────

    /**
     * @notice Checks if upkeep is needed (called by Chainlink Automation)
     * @dev Returns true if enough time has passed since last check
     * @return upkeepNeeded Whether upkeep should be performed
     * @return performData Data to pass to performUpkeep (empty in this case)
     */
    function checkUpkeep(bytes calldata /* checkData */)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded =
            (block.timestamp - lastCheckTimestamp) >= checkInterval &&
            monitoredWallets.length > 0;
        performData = "";
    }

    /**
     * @notice Performs the upkeep (called by Chainlink Automation when checkUpkeep returns true)
     * @dev Checks all monitored wallets and updates their health status
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        // Revalidate the upkeep condition
        require(
            (block.timestamp - lastCheckTimestamp) >= checkInterval,
            "Interval not met"
        );
        require(monitoredWallets.length > 0, "No wallets to monitor");

        lastCheckTimestamp = block.timestamp;
        uint256 walletsChecked = monitoredWallets.length;

        checkAllWallets();

        emit AutomationPerformed(block.timestamp, walletsChecked);
    }

    // ─── Configuration ─────────────────────────────────────────

    function setDangerThreshold(uint256 newThreshold) external onlyOwner {
        dangerThreshold = newThreshold;
    }

    function setCriticalThreshold(uint256 newThreshold) external onlyOwner {
        criticalThreshold = newThreshold;
    }

    function setCheckInterval(uint256 newInterval) external onlyOwner {
        require(newInterval >= 1 minutes, "Interval too short");
        checkInterval = newInterval;
    }

    // ─── View Functions ────────────────────────────────────────

    function getMonitoredWallets() external view returns (address[] memory) {
        return monitoredWallets;
    }

    function getWalletCount() external view returns (uint256) {
        return monitoredWallets.length;
    }

    function getHealthFactor(address wallet)
        external
        view
        returns (uint256 healthFactor, uint8 status)
    {
        (, , , , , healthFactor) = aavePool.getUserAccountData(wallet);

        uint256 previousHealth = lastHealthFactor[wallet];

        // Determine status (read-only)
        if (healthFactor < criticalThreshold) {
            status = 3; // Critical
        } else if (healthFactor < dangerThreshold) {
            status = 2; // Danger
        } else if (
            previousHealth != 0 &&
            previousHealth < dangerThreshold &&
            healthFactor >= dangerThreshold
        ) {
            status = 0; // Recovered
        } else {
            status = 1; // Safe
        }
    }

    function getNextCheckTime() external view returns (uint256) {
        return lastCheckTimestamp + checkInterval;
    }
}
