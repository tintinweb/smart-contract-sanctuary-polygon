/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract BlockPurse {

    mapping(address => uint256) public balanceOf;

    receive() external payable {}

    function depistion() external payable returns(bool) {

        require(msg.value > 1000000000000000000);
        balanceOf[msg.sender] += msg.value;

        return true;
    }

    function withdraw() external returns (bool) {

        require(balanceOf[msg.sender] >= 1000000000000000000);

        (bool success,) = address(msg.sender).call{value: 1000000000000000000}(new bytes(0));
        require(success);

        balanceOf[msg.sender] -= 1000000000000000000;

        return true;
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }

}