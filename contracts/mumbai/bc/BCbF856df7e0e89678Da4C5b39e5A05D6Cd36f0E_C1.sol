// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import {C2} from "./C2.sol";

contract C1 {
    C2 public c2;
    uint256 public v1;

    constructor(address c2_) {
        c2 = C2(c2_);
    }

    function printTxOrginal() external returns (address) {
        v1 = 1;
        return c2.printTxOrginal();
    }

    function printMsgSender() external view returns (address) {
        return c2.printMsgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract C2 {
    uint256 public v2;

    function printTxOrginal() external returns (address) {
        v2 = 2;
        return tx.origin;
    }

    function printMsgSender() external view returns (address) {
        return msg.sender;
    }
}