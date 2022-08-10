// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SplitPayment {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function send(address payable[] memory _to, uint256[] memory _amount)
        public
        payable
        onlyOwner
    {
        require(
            _to.length == _amount.length,
            "_to and _amount arrays must have the same length"
        );
        for (uint256 ii = 0; ii < _to.length; ii++) {
            _to[ii].transfer(_amount[ii]);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can send transfers");
        _;
    }
}