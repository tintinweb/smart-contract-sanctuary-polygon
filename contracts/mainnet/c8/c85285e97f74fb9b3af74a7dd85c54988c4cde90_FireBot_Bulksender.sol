/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

// File: contracts/FireBot_BulkSender.sol


pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
}

contract FireBot_Bulksender{
    function bulksendToken(IERC20 token, address[] memory to, uint256[] memory values) public {
        require(to.length == values.length);
        for (uint256 i = 0; i < to.length; i++) {
            token.transferFrom(msg.sender, to[i], values[i]);
        }
    }
}