// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract T {
    constructor() payable {}

    function transferTest(address payable _to) external payable {
        _to.transfer(1);
    }

    function sendTest(address payable _to) external payable {
        bool res = _to.send(777);
        require(res, 'FAiled send');
    }

    function callTest(address payable _to) external payable {
        (bool success, ) = _to.call{ value: 999 }("");
        require(success, 'Failed call');
    }
}