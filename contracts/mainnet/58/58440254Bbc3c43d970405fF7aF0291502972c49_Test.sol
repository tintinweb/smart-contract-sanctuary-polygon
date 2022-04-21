// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.11;

contract Test {

    uint256 public numAdditions;

    constructor(uint256 numInit) {
        numAdditions = numInit;
    }

    function addFunds() payable public {
        numAdditions++;
    }

    function balance() public view returns(uint256) {
        return address(this).balance;
    }
}