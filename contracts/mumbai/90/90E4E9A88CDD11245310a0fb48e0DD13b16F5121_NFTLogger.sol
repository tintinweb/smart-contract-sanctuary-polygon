// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./NFTSecondLogger.sol";

contract NFTLogger {
    event MethodExecuted(address indexed dest, bytes params);

    address LoggerInterfaceAddress = 0xE7BF8d1eFe23332f109eda689f357ef65d4198a1;
    NFTSecondLogger logger = NFTSecondLogger(LoggerInterfaceAddress);

    function log(address dest, bytes calldata func) external {
        emit MethodExecuted(dest, func);
    }

    function see () external pure returns (bool) {
        return true;
    }

    function logAndSee(address dest, bytes calldata func) external {
        emit MethodExecuted(dest, func);
        logger.see();
    }

    function logAndLog(address dest, bytes calldata func) external {
        emit MethodExecuted(dest, func);
        logger.log(dest, func);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

contract NFTSecondLogger {
    event MethodExecuted(address indexed dest, bytes params);

    function log(address dest, bytes calldata func) external {
        emit MethodExecuted(dest, func);
    }

    function see () external pure returns (bool) {
        return true;
    }
}