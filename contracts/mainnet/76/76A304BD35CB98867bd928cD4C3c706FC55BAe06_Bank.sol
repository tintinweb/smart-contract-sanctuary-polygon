/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



interface Inft {
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint);
    
}

contract Bank {
    address nftAddr;
    mapping(address => uint256) public balanceOf;
    function setNftAddr(address _nftAddress) public payable {
       nftAddr = _nftAddress;
    }

    function addTax(uint moneyToAdd) public payable {
        require(moneyToAdd <= msg.value, "Ether value sent is not correct");
        uint256 totalTokens = Inft(nftAddr).totalSupply();
        address currentTokenOwner;
        uint256 moneyToAddEach = moneyToAdd / totalTokens;
        for (uint256 j = 0; j < totalTokens; j += 1) {  //for loop example
            currentTokenOwner = Inft(nftAddr).ownerOf(j);
            balanceOf[currentTokenOwner] += moneyToAddEach;     
      }
        
    }

    function withdraw() public payable {
        require(balanceOf[msg.sender]!=0,"you have no money to draw");
        payable(msg.sender).transfer(balanceOf[msg.sender]);
        balanceOf[msg.sender] = 0;
        
    }
}