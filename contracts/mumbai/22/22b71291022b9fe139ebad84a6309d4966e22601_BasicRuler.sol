// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IRuler} from "./IRuler.sol";

contract BasicRuler is IRuler {
    event Ruled(uint256 caseId, uint256 result);

    function rule(uint256 caseId, uint256 result) external {
        emit Ruled(caseId, result);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRuler {
    function rule(uint256 caseId, uint256 result) external;
}