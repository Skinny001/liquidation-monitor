// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface AutomationCompatibleInterface {
    /**
     * @notice Checks if the contract requires work to be done.
     * @param checkData Data passed to the function when checking for upkeep.
     * @return upkeepNeeded Boolean indicating whether upkeep is needed.
     * @return performData Data to be passed to performUpkeep if upkeep is needed.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice Performs the work on the contract.
     * @param performData Data passed to the function when performing upkeep.
     */
    function performUpkeep(bytes calldata performData) external;
}
