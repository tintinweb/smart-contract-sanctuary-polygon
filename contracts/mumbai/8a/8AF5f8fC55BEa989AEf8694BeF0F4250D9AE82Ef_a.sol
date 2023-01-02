// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {StroageLib} from "./storage.sol";

contract a {
    using StroageLib for StroageLib.Layout;
    event Annoucement(string msg);

    function sayHi() public {
        StroageLib.layout().message = "Hi";
        emit Annoucement("Hi");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library StroageLib {
    struct Layout {
        string message;
    }
    bytes32 internal constant STORAGE_SLOT =
        keccak256("covest.contracts.insurance.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 position = STORAGE_SLOT;
        assembly {
            l.slot := position
        }
    }
}