// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IOracle.sol";

contract TestOracle is IOracle {
    function hasCompleted(address from) external view override returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of a compliant oracle contract.
 */
interface IOracle {
    /**
     * @dev Returns if `from` has completed the task `guildId`
     */
    function hasCompleted(address from) external view returns (bool);
}