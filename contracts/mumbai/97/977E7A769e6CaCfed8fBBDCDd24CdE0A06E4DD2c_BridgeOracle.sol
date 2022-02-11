//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/IBridgeOracle.sol";

contract BridgeOracle is
IBridgeOracle
{
    mapping(bytes32 => uint256) chainFees;

    constructor(

    ) {

    }

    function getFee(
        bytes32 toChain
    ) external view returns (uint256) {
        return chainFees[toChain];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBridgeOracle {
    function getFee(bytes32 toChain) external view returns (uint256);
}