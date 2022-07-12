/**
 *Submitted for verification at polygonscan.com on 2022-07-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Running {

    receive() external payable {

    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function widthdraw(address user, uint256 amount) public {
        address payable payableUser = payable(user);
        payableUser.transfer(amount);
    }
}