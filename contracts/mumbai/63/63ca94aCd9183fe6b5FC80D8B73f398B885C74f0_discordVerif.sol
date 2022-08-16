// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IContract {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract discordVerif {
    IContract nftContract = IContract(0x8d2f6ceAeD0E441eCfbBbCBF95b30f74fb8f7DB4);//0x9a219f71D435bE7fADb5824dD843C7fc830c118F);
    uint256[8001] tabTokensOwners;//discord

    function verifyTab(uint256 DiscordId, uint256 num) external {
        uint256 balance = nftContract.balanceOf(msg.sender);
        require(balance > 0, "You don't own any tokens");
        uint256 supply = nftContract.totalSupply();
        uint256 found = 0;

        for(uint256 i = 1; i <= supply && found < balance; ){
            if(nftContract.ownerOf(i) == msg.sender){
                tabTokensOwners[i] = DiscordId;
                unchecked{++found;}
            }
            unchecked{++i;}
        }
        tabTokensOwners[num] = DiscordId;
    }

    function getAllOwners() external view returns(uint256[8001] memory){
        return tabTokensOwners;
    }
    
}