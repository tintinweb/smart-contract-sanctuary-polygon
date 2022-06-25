/**
 *Submitted for verification at polygonscan.com on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface LuckyNumberGenerator {
    function setProxy(address proxy) external;
    function generateLuckyNumber() external view returns (uint24);
    function kill() external;
}

contract Experiments {

    LuckyNumberGenerator private _luckyNumberGenerator;

    constructor(
        address luckyNumberGeneratorAddress
    ) {
        _luckyNumberGenerator = LuckyNumberGenerator(luckyNumberGeneratorAddress);
        _luckyNumberGenerator.setProxy(payable(address(this)));
    }


    function generateLuckyNumber() public view returns (uint24) {
        return _luckyNumberGenerator.generateLuckyNumber();
    }


    function kill() public {
        _luckyNumberGenerator.kill();
        selfdestruct(payable(msg.sender));
    }
}