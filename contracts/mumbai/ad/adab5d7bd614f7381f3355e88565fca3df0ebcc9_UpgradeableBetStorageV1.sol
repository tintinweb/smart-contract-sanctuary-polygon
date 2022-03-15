// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./UpgradeabilityStorage.sol";
import "./BetStorageContract.sol";

contract UpgradeableBetStorageV1 is UpgradeabilityStorage, BetStorageContract {

      function setPlayerSettings(address playerAddress,uint expirity) external
    {
            playerSettings[playerAddress].expirity = expirity; 
            playerSettings[playerAddress].gameLapse = 1; 
            emit playerSettingsUpdated(playerAddress,"SETTINGS UPDATED");
    }

    function getPlayerSettings(address playerAddress) public view returns (uint) {
           return (playerSettings[playerAddress].expirity) ;
    }

    function deletePlayerSettings(address playerAddress) external{
            playerSettings[playerAddress].expirity = 0; 
            
        
    }    

}