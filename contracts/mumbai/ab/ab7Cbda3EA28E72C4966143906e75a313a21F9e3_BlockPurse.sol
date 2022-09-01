/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract BlockPurse {

    mapping(address => uint256) public balanceOf;

    receive() external payable {}

    function depistion() external payable returns(bool) {

        require(msg.value > 0);
        balanceOf[msg.sender] += msg.value;

        return true;
    }

    function withdraw(uint256 amount) external returns (bool) {

        require(balanceOf[msg.sender] >= amount);

        safeTransferETH(msg.sender, amount);

        balanceOf[msg.sender] -= amount;

        require(balanceOf[msg.sender] >= 0);

        return true;
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }

}