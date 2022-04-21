pragma solidity ^0.8.13;

import ".././Interface/IResolver.sol";

import ".././Interface/IPredictionOpsManager.sol";

contract GelatoPredictionOps is IResolver {
    IPredictionOpsManager public predictionOpsManager;

    constructor(IPredictionOpsManager _predictionOpsManager) {
        predictionOpsManager = _predictionOpsManager;
    }

    function checker() external view override returns (bool canExec, bytes memory execPayload) {
        // solhint-disable not-rely-on-time
        canExec = predictionOpsManager.canPerformTask();

        execPayload = abi.encodeWithSelector(predictionOpsManager.execute.selector);
    }
}

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

interface IResolver {
    function checker() external view returns (bool canExec, bytes memory execPayload);
}

pragma solidity ^0.8.13;

interface IPredictionOpsManager {
    function execute() external;

    function canPerformTask() external view returns (bool);
}