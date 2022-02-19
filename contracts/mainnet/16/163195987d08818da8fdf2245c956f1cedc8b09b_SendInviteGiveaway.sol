/**
 *Submitted for verification at polygonscan.com on 2022-02-19
*/

// SPDX-License-Identifier: MIT
// This contract for CorianderDAO.eth WL Packet Giveaway

// Join CorianderDAO.eth >> https://discord.gg/D3VTz4ppF9 

pragma solidity ^0.8.11;

interface ERC20_Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract SendInviteGiveaway {
    ERC20_Token public usdcToken;
    address public contractOwner;

    // address public nftContractAddr;
    address[] public inviteGiveawayAddr;
    address[] public top10GiveawayAddr;

    constructor() {
        contractOwner = msg.sender;
        usdcToken = ERC20_Token(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    }

    function addGiveawayAddress(address participantAddr, uint256 numberOfChance) public {
        require(contractOwner==msg.sender, "Permission Denied");
        for (uint i = 0; i < numberOfChance; i++) {
            inviteGiveawayAddr.push(participantAddr);
        }
    }

    function addTop10Address(address participantAddr) public {
        require(contractOwner==msg.sender, "Permission Denied");
        top10GiveawayAddr.push(participantAddr);
    }

    function removeTop10Address(uint256 index) public {
        require(contractOwner==msg.sender, "Permission Denied");
        delete top10GiveawayAddr[index];
    }

    function sendRandomGiveaway(uint256 _amount) public payable {
        require(contractOwner==msg.sender, "Permission Denied");
        require(_amount > 0, "ERR. AMT.");
        uint256 winnerTokenId = random(inviteGiveawayAddr.length);
        usdcToken.transferFrom(msg.sender, inviteGiveawayAddr[winnerTokenId], _amount);
    }

    function sendTop10Giveaway(uint256 _amount) public payable {
        require(contractOwner==msg.sender, "Permission Denied");
        require(_amount > 0, "ERR. AMT.");
        
        for (uint i = 0; i < top10GiveawayAddr.length; i++) {
            usdcToken.transferFrom(msg.sender, top10GiveawayAddr[i], _amount);
        }
    }

    function random(uint256 _len) private view returns (uint256) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%_len);
    }
}