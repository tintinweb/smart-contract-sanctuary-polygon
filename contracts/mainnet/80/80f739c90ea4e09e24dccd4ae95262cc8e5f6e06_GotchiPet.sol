// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface AavegotchiGameFacet {
    function interact(uint256[] calldata _tokenIds) external;
}

contract GotchiPet {
    AavegotchiGameFacet private aavegotchiGameFacet;
    uint256 public lastExecuted;
    mapping(address => bool) private registeredAccounts;
    address[] public accounts;

    constructor(address gotchiDiamond) {
        aavegotchiGameFacet = AavegotchiGameFacet(gotchiDiamond);
    }

    function petGotchis(uint256[] calldata gotchiIds) public {
        require(gotchiIds.length > 0, "No Gotchis to pet");
        aavegotchiGameFacet.interact(gotchiIds);
        lastExecuted = block.timestamp;
    }

    function registerMe() public {
        require(!registeredAccounts[msg.sender], "Already registered");
        registeredAccounts[msg.sender] = true;
    }

    function unregisterMe() public {
        require(registeredAccounts[msg.sender], "Not registered");
        registeredAccounts[msg.sender] = false;
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == msg.sender) {
                accounts[i] = accounts[accounts.length - 1];
                accounts.pop();
                break;
            }
        }
    }
}