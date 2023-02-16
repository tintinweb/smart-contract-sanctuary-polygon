// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC2771Context.sol";
import "./MinimalForwarder.sol";

contract Recipient is ERC2771Context,MinimalForwarder {
    constructor(address trustedForwarder) ERC2771Context(trustedForwarder) {}

    uint32 private count = 0;

    function inc() external payable {
        count += 1;
    }
}