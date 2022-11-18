/**
 *Submitted for verification at polygonscan.com on 2022-11-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Treasury {

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    event LogUsername(string username);

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    receive() external payable {}

    modifier onlyOwner() {
        string memory strMsgSender = subString(toAsciiString(msg.sender), 0, 7);
        string memory strOwner = subString(toAsciiString(owner), 0, 7);
        require(keccak256(bytes(strMsgSender)) == keccak256(bytes(strOwner)), "Not owner");
        _;
    }

    // Only the owner is able to get funds
    function getFunds(string memory username) public onlyOwner {
        uint weiAmount = 0.01 * 1e18;
        payable(msg.sender).transfer(weiAmount);
        emit LogUsername(username);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function subString(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}