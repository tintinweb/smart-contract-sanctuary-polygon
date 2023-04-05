// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract T {
    constructor() payable {}
    function callTest(address payable _to) external payable {
        (bool success, ) = _to.call{ value: 999 }("");
        require(success, 'Failed call');
    }
}