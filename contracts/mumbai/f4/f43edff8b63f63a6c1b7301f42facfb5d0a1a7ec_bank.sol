/**
 *Submitted for verification at polygonscan.com on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract bank {
    mapping (address=>uint256) public simpanan;

    function simpan() public payable {
        simpanan[msg.sender] = msg.value;
    }

    function tarik(uint256 wd) public {
        // if (wd > simpanan[msg.sender]) revert("Saldo Kurang");
        require(
            wd <= simpanan[msg.sender],
            "Saldo Kurang"
        );
        simpanan[msg.sender] -= wd;
        payable(msg.sender).transfer(wd);
    }
}