//SPDX-License-Identifier: GPL-3.0+

pragma solidity ^0.8.12;

import "ReentrancyGuard.sol";

contract DaiToken
{
    function approve(address, uint256) external returns (bool) {}
    function transferFrom(address, address, uint256) external returns (bool) {}    
}

contract RyuNFT
{
    function mintNFT() external returns (uint256) {}
    function safeTransferFrom(address, address, uint256) public {}
}

contract Minter is ReentrancyGuard
{
    //Constants
    address private constant DAI_TOKEN_ADDRESS = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;    
    address private constant RYU_NFT_ADDRESS = 0x15D43742b98a9FAeb56d8C6baAcaa586F8223617;
    
    uint256 private constant MINT_PRICE = 100000000000000000; //0.1 DAI    

    DaiToken private constant DAI_TOKEN = DaiToken(DAI_TOKEN_ADDRESS);     
    RyuNFT   private constant RYU_NFT = RyuNFT(RYU_NFT_ADDRESS);    
    
    constructor() {}
    
    function mintRyuNFT(uint256 amount) external        
	{
        require(amount > 0, "NFT MINT: amount must be greater than 0");

        DAI_TOKEN.transferFrom(msg.sender, address(this), amount * MINT_PRICE);        

        for (uint256 i = 0; i < amount; i++) 
        {
            uint256 id = RYU_NFT.mintNFT();

			RYU_NFT.safeTransferFrom(address(this), msg.sender, id);			
        }
	}    
}