/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract SC04B {

    uint internal _nextToken;
    
    IERC721 tokenContract;

    address public deployer = 0x1be7c2Fc8e12553742b3B9D02AC4c7581770a5c7;

    constructor(address token_) {
        _nextToken = 0;
        tokenContract = IERC721(token_);
    }

    function buyNFT(address to, uint amount) public payable {
        require(amount <= 10, 'Amount exceeds limit');
        require(msg.value >= amount * 0.01 ether, 'Invalid msg.value');
        
        //llamar a los metodos de ERC721
        for (uint i = 0 ; i < amount; i++){
            tokenContract.transferFrom(deployer, to, _nextToken);
            _nextToken++;
        }
    }

    function withdraw() public payable {
        require(msg.sender == deployer, 'Not permitted');
        payable(msg.sender).call{value: address(this).balance};
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

}