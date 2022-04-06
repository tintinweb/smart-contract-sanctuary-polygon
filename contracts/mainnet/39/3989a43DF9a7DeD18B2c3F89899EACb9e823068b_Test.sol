// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.11;

contract Test {

    bool internal isDummy;

    constructor(bool initDummy) {
        isDummy = initDummy;
    }

    function getIsDummy() public view returns(bool) {
        return isDummy;
    }
}