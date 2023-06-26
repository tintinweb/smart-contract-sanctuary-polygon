// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "./LotteryInterface.sol";

error Automation__PerformUpkeepFailed();
error Automation__InvalidData();

contract Automation is AutomationCompatibleInterface {
    LotteryInterface public lottery;

    event UpkeepPerformed(bytes performData);

    constructor(address _lottery) {
        lottery = LotteryInterface(_lottery);
    }

    function checkUpkeep(
        bytes calldata checkData
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        if (keccak256(checkData) == keccak256(bytes(abi.encode("request")))) {
            bool isInterval = (block.timestamp - lottery.getLatestCheckpoint() >=
                lottery.getInterval() * 10);
            bool isParticipated = (lottery.getPlayerCounter() > 1);
            bool isOpen = lottery.getState();
            upkeepNeeded = (isInterval && isParticipated && isOpen);
            performData = checkData;
        }
        if (keccak256(checkData) == keccak256(bytes(abi.encode("pick")))) {
            bool isInterval = (block.timestamp - lottery.getLatestCheckpoint() >=
                lottery.getInterval());
            bool isRandom = (lottery.getRandomNumber() != 0);
            bool isClosed = !lottery.getState();
            upkeepNeeded = (isInterval && isRandom && isClosed);
            performData = checkData;
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        if (keccak256(performData) == keccak256(bytes(abi.encode("request")))) {
            if (
                (block.timestamp - lottery.getLatestCheckpoint() >= lottery.getInterval() * 10) &&
                (lottery.getPlayerCounter() > 1) &&
                (lottery.getState())
            ) {
                lottery.requestRandomWinner();
            } else {
                revert Automation__PerformUpkeepFailed();
            }
        } else if (keccak256(performData) == keccak256(bytes(abi.encode("pick")))) {
            if (
                (block.timestamp - lottery.getLatestCheckpoint() >= lottery.getInterval()) &&
                (lottery.getRandomNumber() != 0) &&
                (!lottery.getState())
            ) {
                lottery.pickRandomWinner();
            } else {
                revert Automation__PerformUpkeepFailed();
            }
        } else {
            revert Automation__InvalidData();
        }
        emit UpkeepPerformed(performData);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface LotteryInterface {
    function getState() external view returns (bool);

    function getPlayerCounter() external view returns (uint256);

    function getLatestCheckpoint() external view returns (uint256);

    function getInterval() external view returns (uint256);

    function getRandomNumber() external view returns (uint256);

    function requestRandomWinner() external;

    function pickRandomWinner() external;
}