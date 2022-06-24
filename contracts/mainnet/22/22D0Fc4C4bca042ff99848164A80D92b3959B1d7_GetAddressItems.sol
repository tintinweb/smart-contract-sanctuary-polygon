// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./utils/IItemVault.sol";

/**
* @dev Read item user of players' items.
 */

contract GetAddressItems {

    /**
     * @dev use interface to set vault
     * IItemVault - set intetface for vaultItem
     * Set up a role for contract deployer to be VAULT_ADMIN.
     */
    

    IItemVault public vaultItem;


     /**
     * @dev Initialize this contract.
     * it can only be set once during construction.
     * @param _itemVaultAddress - Contract address of ItemVault smart contract.
     */

    constructor(address _itemVaultAddress) {
        vaultItem = IItemVault(_itemVaultAddress);
    }

    /**
    * @dev Get all item of player.
    * @param _address - Address of user has item.
    * @param _lengthId - amount ID in Vault Item.
     */
   function getAllitem(address _address,uint256 _lengthId) external view returns (uint256[] memory)
    {
        uint256[] memory items = new uint[](_lengthId + 1);
        for (uint256 id = 1; id <= _lengthId; id++) {
            items[id] = vaultItem.getItemAmountbyId(_address, id);
        }
        return items;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IItemVault{
    function increaseItem(address _userAddress, uint256 _itemId, uint256 _itemAmount) external;

    function decreaseItem(address _userAddress, uint256 _itemId, uint256 _itemAmount) external;

    function getItemAmountbyId(address _userAddress, uint256 _itemId) external view returns (uint256);
}