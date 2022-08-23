// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EnergyPacks {

    uint[] public packsDefinitionCost = [0.01 ether, 0.1 ether, 0.5 ether];
    uint[] public packsDefinitionTokens = [10, 100, 1000];
    uint[] public packsDefinitionNFTs = [0, 0, 1];

    mapping(address => uint256) public EBBalnces;

    constructor() { }

    function buyPack(address to) public payable {
        uint[] memory _packsDefinitionCost = packsDefinitionCost;
        uint _purchasedTokens = 0;
        uint _purchasedNTFs = 0;

        for (uint i =0; i < _packsDefinitionCost.length; i = i++){
            if (_packsDefinitionCost[i] == msg.value) {
                _purchasedTokens = packsDefinitionTokens[i];
                _purchasedNTFs = packsDefinitionNFTs[i];
                break;
            }
        }

        require(_purchasedTokens > 0, "Value sent is not correct");

        EBBalnces[to] = EBBalnces[to] + _purchasedTokens;
        // TODO: mint NFTs based on _purchasedNTFs
    }

}