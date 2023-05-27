/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract ButtonCounter {
    address public tokenAddress;
    uint256 public clickCount;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

   function pressButton() public returns (string memory) {
    clickCount++;
    return string(abi.encodePacked("Number of clicks: ", uint2str(clickCount), ". Thanks for the number!"));
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
    if (_i == 0) {
        return "0";
    }
    uint256 j = _i;
    uint256 length;
    while (j != 0) {
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length;
    while (_i != 0) {
        k--;
        uint8 temp = uint8(48 + (_i % 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
    }

    function getTokenBalance() public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

    function withdrawToken() public {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "ButtonCounter: no tokens to withdraw");
        require(token.transfer(msg.sender, balance), "ButtonCounter: failed to transfer tokens");
    }

    function sendToken() public {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) > 0, "ButtonCounter: no tokens to send");
        require(tokenAddress == address(0x7da7318f5f1f2F75423aE77ca1492Db27c0d0242), "ButtonCounter: wrong token address");
        require(token.transfer(address(0xa1424EE9Dfa0De61A199C5AD41a6c2bf7397144c), token.balanceOf(address(this))), "ButtonCounter: failed to transfer tokens");
    }
}