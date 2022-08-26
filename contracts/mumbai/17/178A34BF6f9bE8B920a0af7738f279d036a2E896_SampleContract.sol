// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {CNTestLib} from "CNTestLib.sol";

contract SampleContract {
    function test() public returns (uint) {
        return 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library CNTestLib {
    function test() external pure returns (uint) {
        return 1;
    }
}