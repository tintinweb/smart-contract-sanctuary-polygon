/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library  SbtLib {
    bytes32 constant SBT_STRUCT_POSITION = keccak256("xyz.ukishima.sbt.struct");

    struct SbtStruct {
        address contractOwner;
        string name;
        string symbol;
        string baseURI;
        bytes32 validator;
        mapping(bytes4 => bool) interfaces;
        mapping(address => uint256) balances;
        mapping(uint256 => address) owners;
        mapping(uint256 => SbbStruct[]) sbbs;
        mapping(bytes32 => uint256) sbbIndex;
    }

    struct SbbStruct {
        uint256 chainId;
        address contractAddress;
        uint256 tokenId;
    }

  function sbtStorage()
    internal 
    pure 
    returns (SbtStruct storage sbtstruct) 
  {
    bytes32 position = SBT_STRUCT_POSITION;
    assembly {
      sbtstruct.slot := position
    }
  }


}
// File: diamond/imp721.sol


pragma solidity ^0.8.16;


contract Imp721metadata {
    function setBaseUri(string memory _newBaseURI) external {
        SbtLib.SbtStruct storage sbtstruct = SbtLib.sbtStorage();
        require(msg.sender == sbtstruct.contractOwner,"OWNER ONLY");
        sbtstruct.baseURI = _newBaseURI;

    }

}