/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;


interface All {
function checkNftPurchasedorNot(address nft)external view returns(bool);
function UserHasPurchasedOrNot(address User) external view returns(bool);
}
contract logic{
    address owner;
    address nftcollection1;
    address acceptedToken;
  
    constructor(){
        owner=msg.sender;
    }
    address [] public Collections;
    
    event addCollection(address collectionAddress);
    //add adressses of collections
    function addAddress(address collection) external {
        require(msg.sender==owner,"you are not owner");
        require(collection != address(0),"null address is not acceptable");
        require(!isAddedOrNot(collection) ,"address is already added");
        Collections.push(collection);
        emit addCollection(collection);
    }
   
    function CheckForReferalFee(address nft, address User) external view returns (string memory) {
    string memory warning = "Referral has not purchased any NFT";
    
    for (uint i = 0; i <Collections.length; i++) {
        bool check = All(Collections[i]).checkNftPurchasedorNot(nft);
        bool check1 = All(Collections[i]).UserHasPurchasedOrNot(User);
        
        if (check == true && check1 == true) {
            return "Referral has purchased that NFT";
        }
    }
    
    return warning;
}
    function checkNftPurchasedorNot(address nft , uint ArrayIndex)external view returns(bool){
        require(msg.sender==owner,"you are not owner");
       bool check = All(Collections[ArrayIndex]).checkNftPurchasedorNot(nft);
        return check;
    }
    function isAddedOrNot(address _nftAddress) internal view returns(bool) {
        for(uint i=0;i<Collections.length;i++) {
            if(Collections[i] == _nftAddress){
                return true;
            }
        }
        return false;

    }
}