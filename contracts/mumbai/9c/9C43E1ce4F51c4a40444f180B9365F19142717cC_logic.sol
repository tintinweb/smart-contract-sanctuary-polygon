/**
 *Submitted for verification at polygonscan.com on 2023-05-29
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
interface All {
// mapping(address => bool) public checkNftPurchasedorNot;
function checkNftPurchasedorNot(address nft)external view returns(bool);
}
contract logic{
    address nftcollection1;
    // address immutable nftcollection2;
    constructor(address werable1){
        nftcollection1=werable1;
        // nftcollection2=werable2;
    }

   
    function checkNftPurchasedorNot(address nft)external view returns(bool){
       bool check = All(nftcollection1).checkNftPurchasedorNot(nft);
        return check;
    }
}