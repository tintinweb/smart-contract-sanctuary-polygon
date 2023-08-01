// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IOracle {

    /**
     * return amount of tokens that are required to receive that much eth.
     */
    function getTokenValueOfEth(uint256 ethOutput) external view returns (uint256 tokenInput);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../samples/IOracle.sol";

contract TestOracle is IOracle {
    function getTokenValueOfEth(uint256 ethOutput) external pure override returns (uint256 tokenInput) {
        return ethOutput * 2;
    }
}