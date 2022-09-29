// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import NFT's Contract Interfaces;
import {INFT} from "./INFT.sol";

interface Oracle {
    function requestRandomWords() external returns (uint256 requestId);
}

contract GachaOracle {
    address owner;
    address nftAddress;
    address oracleAddress;
    uint gachaLimit;
    //Connecting address with gacha limit
    mapping(address => user) public userInfo;

    struct user {
        uint mintAmount;
        mapping(uint => string) rarity;
    }
    
    constructor(address _nftAddress){
        //set contract owner's address
        owner = msg.sender;

        //set NFT contract's address
        nftAddress = _nftAddress;

        //set gacha limit per user
        gachaLimit = 2;

        //set oracleAddress;
        oracleAddress = 0x1F150FF7157f4321d94a3bEd08bcEad4571D7604;
    }
    

    function gacha() public{
        //Checking function caller gacha limit
        uint userMintAmount = userInfo[msg.sender].mintAmount; 
        require(userMintAmount < gachaLimit, "You have reached mint limit");

        //Protecting function from reentrancy attack manually (Without using OpenZeppelin's reetrancy guard);
        userInfo[msg.sender].mintAmount += 1; 

        //get simple random number (good for local testing)
        // uint random = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 100;
        uint random = Oracle(oracleAddress).requestRandomWords() % 100;
        

        //set random number 0-14 to get a Good rarity
        uint good = INFT(nftAddress).getRarityRate("Good");

        //set random number 15-44 to get a Bad rarity
        uint bad = good + INFT(nftAddress).getRarityRate("Bad");

        //set random number 45-99 to get a Normal rarity
        uint normal = bad + INFT(nftAddress).getRarityRate("Normal");

        if(random < good){
            userInfo[msg.sender].rarity[userMintAmount] = "Good";
        }else if(random < bad){
            userInfo[msg.sender].rarity[userMintAmount] = "Bad";
        }else if(random < normal){
            userInfo[msg.sender].rarity[userMintAmount] = "Normal";
        }

        //If user haven't mint 2 nft then mint NFT and send to function caller's address
        INFT(nftAddress).safeMint(msg.sender);
    }

    //Funtion to update gacha limit
    function updateGachaLimit(uint _newLimit) public {
        //Checking function caller manually (not using OpenZeppelin's onlyOwner)
        require(msg.sender == owner, "Only owner can call this function");

        gachaLimit = _newLimit;
    }

    //function to get User's minted Rarity
    function getRarity(address _address) public view returns (string[] memory){
        string[] memory arrayOfRarity = new string[](userInfo[_address].mintAmount);

        for(uint256 i=0; i<userInfo[_address].mintAmount; i++){
            arrayOfRarity[i] = userInfo[_address].rarity[i];
        }

        return arrayOfRarity;
    }


    //Example JSON CID:  QmfABNPUC67P2pW3WMPS9L7pEhzsJCv9vZvEY7Jg2Da7NC
    //function to update NFT's CID
    //This function can't be run after the NFT Minted this is caused by the NFT Smart Contract that only Allowed NFT Owner to Update the URI.
    // function updateURI(uint _tokenId, string memory _CID) public{
    //     INFT(nftAddress).setTokenUri(_tokenId, _CID);
    // }




}