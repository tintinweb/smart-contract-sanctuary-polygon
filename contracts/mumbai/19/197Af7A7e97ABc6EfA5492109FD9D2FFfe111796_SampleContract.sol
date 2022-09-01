// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {CNTestLib} from "CNTestLib.sol";

contract SampleContract {
    function get () public {
        CNTestLib.doStuff();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library CNTestLib {
    function doStuff() public {
    }
}