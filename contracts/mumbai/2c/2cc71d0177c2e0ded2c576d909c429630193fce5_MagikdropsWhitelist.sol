/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * 
 * @title MagikdropsWhitelist
 * @dev Just adds you to a special list ;)
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract MagikdropsWhitelist {

    mapping(address => bool) private whitelist;
    mapping(address => address) private nft;
    mapping(address => uint ) private nft_id;
    
    address owner; // variable that will contain the address of the contract deployer
    constructor() {
        owner = msg.sender; // setting the owner the contract deployer
    }
    
    function addMe() public {
        whitelist[ msg.sender ] = true;
    }

    function addMeWithNFT( address contract_addr, uint tokenId) public {
        //May require validation later
        whitelist[ msg.sender ] = true;
        nft[ msg.sender ] = contract_addr;
        nft_id[ msg.sender ] = tokenId;
    }
    

    function isIn( address _whitelistedAddress) public view returns (bool added,address contract_addr, uint tokenId ) {
        bool found_added;
        uint found_tokenId;
        address found_contract;
        found_added = whitelist[_whitelistedAddress];
        found_contract = nft[_whitelistedAddress];
        found_tokenId = nft_id[_whitelistedAddress];
        return (found_added, found_contract,found_tokenId);   
    }
}