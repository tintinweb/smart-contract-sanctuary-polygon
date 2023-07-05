/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

pragma solidity ^0.8.18;

interface CG_Contract {
    function withdraw(address where) external payable;
}

contract WithdrawFunds {
    CG_Contract private cgContract;

    constructor() {
        cgContract = CG_Contract(address(0x000D9ACa2eb24f3ff999bFC6800AB27081EA0000));
    }

    function withdrawFunds() external {
        cgContract.withdraw(msg.sender);
    }
}