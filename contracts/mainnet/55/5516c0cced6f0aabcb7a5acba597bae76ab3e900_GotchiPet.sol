// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface AavegotchiGameFacet {
    function interact(uint256[] calldata _tokenIds) external;
}

contract GotchiPet {
    AavegotchiGameFacet private aavegotchiGameFacet;
    uint256 public lastExecuted;
    mapping(address => mapping(address => bool)) private registeredAccountsByManager;
    mapping(address => address[]) private accountsByManager;

    constructor(address gotchiDiamond) {
        aavegotchiGameFacet = AavegotchiGameFacet(gotchiDiamond);
    }

    function petGotchis(uint256[] calldata gotchiIds) public {
        require(gotchiIds.length > 0, "No Gotchis to pet");
        aavegotchiGameFacet.interact(gotchiIds);
        lastExecuted = block.timestamp;
    }

    function registerAccount(address account) public {
        require(!registeredAccountsByManager[msg.sender][account], "Already registered");
        registeredAccountsByManager[msg.sender][account] = true;
        accountsByManager[msg.sender].push(account);
    }

    function unregisterAccount(address account) public {
        require(registeredAccountsByManager[msg.sender][account], "Not registered");
        registeredAccountsByManager[msg.sender][account] = false;
        for (uint256 i = 0; i < accountsByManager[msg.sender].length; i++) {
            if (accountsByManager[msg.sender][i] == account) {
                accountsByManager[msg.sender][i] = accountsByManager[msg.sender][accountsByManager[msg.sender].length - 1];
                accountsByManager[msg.sender].pop();
                break;
            }
        }
    }

    function getRegisteredAccounts() public view returns (address[] memory) {
        return accountsByManager[msg.sender];
    }
}