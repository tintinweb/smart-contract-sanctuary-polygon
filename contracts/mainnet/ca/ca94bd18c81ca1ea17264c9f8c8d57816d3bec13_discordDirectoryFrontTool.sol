/**
 *Submitted for verification at polygonscan.com on 2022-05-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ADD-ON MADE BY @Gaspacho.eth 
// FOR THE DISCORD-ETH CONTRACT MADE BY 0xInuarashi

interface onChainDiscordDirectory {
    function setDiscordIdentity(string calldata discordTag_) external;
    function addressToDiscord(address) view external returns(string memory);
}

contract discordDirectoryFrontTool {
    function getAddressesToDiscords(address contractAddress_, address[] memory addresses_) public view returns(string[] memory) {
        uint256 len = addresses_.length;

        string[] memory IDs = new string[](len);
        uint256 i = 0;
        while (i < len) {
            IDs[i] = onChainDiscordDirectory(contractAddress_).addressToDiscord(addresses_[i]);
            i++;
        }

        return IDs;

    }
}