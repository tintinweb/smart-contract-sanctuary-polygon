/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Resume {

    address admin;

    struct Owner { 
      address pubkey;
      string blockExplorer;
   }
   string[] nfts;
   string[] metadata;
   Owner owner;
    constructor() {
        admin = msg.sender;
        }

    modifier onlyOwner() {
        require(admin == msg.sender, "You are not the owner");
        _;
    }

    function getOwnerOfThisContract() public view returns(Owner memory){
        return owner;
    }
    function modifyOwner(address pubkey, string memory blockExplorer) public onlyOwner returns(bool){
        owner.pubkey = pubkey;
        owner.blockExplorer = blockExplorer;
        return true;
    }
    function getNFTUrls() public view returns(string[] memory){
        return nfts;
    }
       function getNFTMetadataUrls() public view returns(string[] memory){
        return metadata;
    }

    function resetNFTUrls() public onlyOwner{
        nfts = new string[](0);
        metadata = new string[](0);
    }
     function addNFTUrls(string memory url, string memory metadataUri)public onlyOwner returns(bool){  
        nfts.push(url);
        metadata.push(metadataUri);
        return true;
    }

}