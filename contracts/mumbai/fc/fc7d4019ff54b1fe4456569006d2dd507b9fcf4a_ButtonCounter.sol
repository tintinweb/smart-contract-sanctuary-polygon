/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFuntikToken {
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract ButtonCounter {
    uint256 private _clickCount;
    address private _owner;
    uint256 private _tokenPrice = 1;
    IFuntikToken private _funtikToken;

    event RequestSent(address indexed sender, string request);
    event DescriptionChanged(string newDescription);

    constructor(IFuntikToken funtikToken) {
        _clickCount = 0;
        _owner = msg.sender;
        _funtikToken = funtikToken;
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
        address tokenAddress = address(_funtikToken);
        require(_funtikToken.balanceOf(sender) >= tokenAmount, "Insufficient balance");
        require(_funtikToken.allowance(sender, address(this)) >= tokenAmount, "Token not approved");
        require(_funtikToken.transferFrom(sender, tokenAddress, tokenAmount), "Token transfer failed");
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