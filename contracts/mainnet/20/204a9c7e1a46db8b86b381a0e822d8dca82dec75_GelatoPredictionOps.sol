pragma solidity ^0.8.13;

import "./IResolver.sol";

import "./IPredictionOpsManager.sol";

contract GelatoPredictionOps is IResolver {
    IPredictionOpsManager public predictionOpsManager;
    address public owner;
    uint256 public delay;

    constructor(IPredictionOpsManager _predictionOpsManager) {
        predictionOpsManager = _predictionOpsManager;
        delay = 60;
        owner = msg.sender;
    }

    function checker() external view override returns (bool canExec, bytes memory execPayload) {
        // solhint-disable not-rely-on-time
        canExec = predictionOpsManager.canPerformTask(delay);

        execPayload = abi.encodeWithSignature("execute()", predictionOpsManager);
    }
     function setDelay(uint256 _delay) external {
        require(msg.sender == owner, "invalid caller");
        delay = _delay;
    }
}

pragma solidity ^0.8.13;

interface IPredictionOpsManager {
    function execute() external;

    function canPerformTask(uint256 _delay) external view returns (bool);
}

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

interface IResolver {
    function checker() external view returns (bool canExec, bytes memory execPayload);
}