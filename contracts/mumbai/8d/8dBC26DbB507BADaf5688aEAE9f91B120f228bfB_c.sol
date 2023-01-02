// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {StroageLib} from "./storage.sol";

contract c {
    using StroageLib for StroageLib.Layout;

    function getMessage() public view returns (string memory) {
        return StroageLib.layout().message;
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