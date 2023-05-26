/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract MyToken {

    uint public price ;
uint public liveprice;
string key = "technoloader";
     function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
}

function checkEquality(string memory stringA , uint _price , uint _liveprice ) public  returns (bool) {
    require(compareStrings(stringA, key), "Strings are not equal");
    liveprice = _liveprice;
    price = _price;
    return true;
}


}