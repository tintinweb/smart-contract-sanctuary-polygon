/**
 *Submitted for verification at polygonscan.com on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract self {
    uint256 deposit;

    function dep() external payable {
        deposit += msg.value;
    }
    
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    function destroy() external {
        selfdestruct(payable(msg.sender));
    }

    receive() external payable {}
}