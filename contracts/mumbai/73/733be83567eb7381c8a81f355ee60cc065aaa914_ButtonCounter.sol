/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.0;
 
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
 
contract ButtonCounter {
    uint256 private _clickCount;
    address private _owner;
    address private _tokenAddress = 0x7da7318f5f1f2F75423aE77ca1492Db27c0d0242;
    uint256 private _tokenPrice = 1;
 
    event RequestSent(address indexed sender, string request);
    event DescriptionChanged(string newDescription);
 
    constructor() {
        _clickCount = 0;
        _owner = msg.sender;
    }
 
    function getDescription() public pure returns (string memory) {
        return "This is a button counter contract. Thanks for the poke!";
    }
 
    function sendRequest(string memory request) public {
        emit RequestSent(msg.sender, request);
    }
 
    function changeDescription(string memory newDescription) public {
        uint256 tokenAmount = _tokenPrice * 1 ether;
        address sender = msg.sender;
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(sender) >= tokenAmount, "Insufficient balance");
        require(token.transferFrom(sender, address(this), tokenAmount), "Token transfer failed");
        emit DescriptionChanged(newDescription);
    }
 
    function withdraw() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }
 
    function click() public {
        _clickCount++;
    }
 
    function getClickCount() public view returns (uint256) {
        return _clickCount;
    }
 
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }
}