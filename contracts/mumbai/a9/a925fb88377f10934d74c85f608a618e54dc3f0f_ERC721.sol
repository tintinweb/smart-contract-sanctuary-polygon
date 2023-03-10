/**
 *Submitted for verification at polygonscan.com on 2023-03-10
*/

/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract ERC721{
   string Name_ = "MYPanda";
    string symbol_ = "MYP";
    string url = "https://gateway.pinata.cloud/ipfs/QmdNSegzCHk1NviGm1S9A91hTSx6SjKJYyU63fWsu5bgbK";

  function name() public view returns (string memory) {
        return Name_;
    }

    function symbol() public view  returns (string memory) {
        return symbol_;
    }

function URLCreate() public view  returns (string memory) {
        //URI = url;
        return url;
    }


}