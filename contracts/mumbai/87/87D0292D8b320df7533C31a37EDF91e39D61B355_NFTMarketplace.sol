// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract NFTMarketplace {

mapping(uint256 => address) public tokens;
 uint256 nftPrice = 0.1 ether;
  modifier isavailable(uint tokenId){
    require(tokens[tokenId] == address(0), "Token doesn't exists");
        
   _;
  }

 function purchase (uint256 _tokenId)  external payable {
        require(msg.value==0.1 ether,'send 0.1 ether');
        
        tokens[_tokenId] = msg.sender;
 }
 function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    function available (uint256 _tokenId) external view returns(bool){
         if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;

    }


}