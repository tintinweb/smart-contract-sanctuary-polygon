/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

// SPDX-License-Identifier: MIT
// This contract for CorianderDAO.eth WL Packet Giveaway

// Join CorianderDAO.eth >> https://discord.gg/D3VTz4ppF9 

pragma solidity ^0.8.11;

contract SendMaticGiveaway {
    address public contractOwner;

    address public nftContractAddr;
    address[36] public maticGiveawayAddr;

    constructor() {
        contractOwner = msg.sender;

        nftContractAddr = 0x9cC1339a6A3Cf2F71a478434D5325EFd06E4Cf24;
        CorianderWL_NFT cNFT = CorianderWL_NFT(nftContractAddr);
        
        for (uint i = 1; i <= 36; i++) {
            maticGiveawayAddr[i-1] = cNFT.ownerOf(i);
        }
    }

    function sendGiveaway() public payable {
        uint256 winnerTokenId = random(36);
        transferEther(payable(maticGiveawayAddr[winnerTokenId]), 88*10**16);

        for (uint i = 0; i < 36; i++) {
            if (i != winnerTokenId) {
                transferEther(payable(maticGiveawayAddr[i]), 1*10**16);
            }
        }
    }

    receive() external payable {}

    function transferEther(address payable _to, uint _amount) public payable {
        require(contractOwner == msg.sender);
        _to.transfer(_amount);
    }

    function random(uint256 _len) private view returns (uint256) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%_len);
    }
}

contract CorianderWL_NFT {
    function ownerOf(uint256 todenId) public view returns(address) {}
}