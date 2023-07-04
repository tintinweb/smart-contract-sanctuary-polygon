/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;


interface All {
function checkNftPurchasedorNot(address nft)external view returns(bool);
}
contract logic{
    address owner;
    address nftcollection1;
    address acceptedToken;
  
    constructor(){
        owner=msg.sender;
        acceptedToken=0xCA7189b7fc453F5edce1De07584442Af0Ba4C419;
       
    }
    address [] public Collections;
    event addCollection(address collectionAddress);
    //add adressses 
    function addAddress(address collection) external {
        require(msg.sender==owner,"you are not owner");
        Collections.push(collection);
        emit addCollection(collection);
    }
   
    function Referalfee(address nft)external view returns(string memory){
         string memory warning ="Refferal has not buyed any nft";
        for(uint i=0;i<=Collections.length;)
        {
            bool check = All(Collections[i]).checkNftPurchasedorNot(nft);
            if(check==true){
                return "referal buyed that nft";
            }
            i+=i; 
        }
        return warning;   
        
        
    }

    function checkNftPurchasedorNot(address nft , uint ArrayIndex)external view returns(bool){
       bool check = All(Collections[ArrayIndex]).checkNftPurchasedorNot(nft);
        return check;
    }
}