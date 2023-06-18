/**
 *Submitted for verification at polygonscan.com on 2023-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract bank{
    mapping (address => uint256) public simpanan;

    function simpan() public payable{
        simpanan[msg.sender] = msg.value;
    }

    function tarik(uint256 wd) public {


        require(
            wd <= simpanan[msg.sender],
            "Saldo tidak cukup"
        );

        simpanan[msg.sender] -= wd;
        payable (msg.sender).transfer(wd);
    }
}