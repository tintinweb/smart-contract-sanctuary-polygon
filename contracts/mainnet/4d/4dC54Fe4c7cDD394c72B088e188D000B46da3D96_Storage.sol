/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * Random number generator (with seed of course)
 * Not perfect but cheap & quick
 * Made by bobochdbrew.eth
 */
contract ERC721{
    function balanceOf(address owner) public returns(uint256){}
}

contract Storage {
    mapping(string => bool) public usedSeeds;
    mapping(address => mapping(string => uint256[])) public history;
    uint256 price = 0.5 ether;
    address payable public Owner;
    event Generated(address sender,string seed, uint256[] result);
    ERC721 NFTContract = ERC721(0xcE5bA05153369EebE886B2EFdf766a8E146044d7);

    constructor(){
        Owner = payable(msg.sender);
    }

    function Generate(string memory seed, uint256 maxValue, uint256 amount) payable public{
        require(msg.value > price ||  NFTContract.balanceOf(msg.sender)> 0,"Need to pay small fees mate or own the NFT");
        require(usedSeeds[seed] == false, "Seed already used");
        require(amount > 0,"Trying to trick me or what ?");
        usedSeeds[seed] = true;
        uint256[] memory _num = new uint256[](amount);
        for(uint256 i = 0; i < amount;i++){
            _num[i] = uint256(keccak256(abi.encodePacked(seed,block.timestamp,block.difficulty,i))) % maxValue;
        }
        history[msg.sender][seed] = _num;
        emit Generated(msg.sender,seed,_num);
    }

    function changeOwner(address payable newMe) public{
        require(msg.sender == Owner,"You think you're me ?");
        Owner = newMe;       
    }

    function changeNFTContract(address newContract) public{
        require(msg.sender == Owner,"You think you're me ?");
        NFTContract = ERC721(newContract);       
    }

    function withdraw(address payable to, uint amount) public{ 
        require(msg.sender == Owner,"You think you're me ?");
        to.transfer(amount);
    }
}