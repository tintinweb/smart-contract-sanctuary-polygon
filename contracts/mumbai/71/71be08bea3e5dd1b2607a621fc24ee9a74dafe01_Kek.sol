/**
 *Submitted for verification at polygonscan.com on 2023-01-02
*/

pragma solidity 0.8.17;

contract Kek {

    uint256 public a = lol();

    constructor() {
        a = 1;
    }

    function lol() internal returns (uint256) {
        a = 2;
        return 3;
    }

    function topkek() external {
        a = 256;
    }

    function callExternalFunc(function() external func) external {
        func();
    }


}