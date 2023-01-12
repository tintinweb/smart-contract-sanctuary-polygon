// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IOracle {

    /**
     * @notice Return amount of tokens that are required to receive that much eth.
     * @param ethOutput eth value want to receive.
     * @return tokenInput token value required.
     */
    function getTokenValueOfEth(uint256 ethOutput) external view returns (uint256 tokenInput);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../paymaster/IOracle.sol";

contract TestOracle is IOracle {
    uint256 public rate = 860000;

    function getTokenValueOfEth(uint256 ethOutput) external view returns (uint256 tokenInput) {
        return (ethOutput * rate) / (10 * 10**18);
    }

    function updateRate(uint256 newRate) external {
        rate = newRate;
    }
}