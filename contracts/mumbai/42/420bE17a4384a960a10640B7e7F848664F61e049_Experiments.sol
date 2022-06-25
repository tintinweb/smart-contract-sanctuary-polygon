// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./LuckyNumberGenerator.sol";

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

    function test() public view returns (address) {
        return address(_luckyNumberGenerator);
    }


    function kill() public {
        _luckyNumberGenerator.kill();
        selfdestruct(payable(msg.sender));
    }
}