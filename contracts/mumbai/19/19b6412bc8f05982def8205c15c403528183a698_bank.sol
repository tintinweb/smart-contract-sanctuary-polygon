/**
 *Submitted for verification at polygonscan.com on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract bank {
    mapping (address => uint256) public simpanan;

    function simpan() public payable {
        simpanan[msg.sender] = msg.value;
    }

    function tarik(uint wd) public {
        require(
            wd <= simpanan[msg.sender],
            "saldo tidak cukup"
        );

        simpanan[msg.sender] -= wd;
        payable(msg.sender).transfer(wd);
    }
}