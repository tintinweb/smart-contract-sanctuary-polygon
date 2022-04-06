// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import {C2} from "./C2.sol";

contract C1 {
    C2 public c2;
    address public origin;

    constructor(address c2_) {
        c2 = C2(c2_);
    }

    function printTxOrginal() external {
        origin = c2.printTxOrginal();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract C2 {
    function printTxOrginal() external view returns (address) {
        return tx.origin;
    }
}