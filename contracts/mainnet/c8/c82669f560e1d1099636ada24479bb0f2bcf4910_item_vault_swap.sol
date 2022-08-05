/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

// File: contracts/item_vault_swap.sol

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFireBotItems {
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory amounts);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

interface IFbx {
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

contract item_vault_swap {

    address public items_contract = 0x2e14520C30370d114612552616964a3bCeD6176E;
    address public fbx_contract = 0xD125443F38A69d776177c2B9c041f462936F8218;
    address public vault_address = 0xBd684239567341ed500224FfE21F5540930359A9;

    function show_vault_items() external view returns (uint256[] memory amounts) {
        address[] memory accounts;
        uint256[] memory ids;
        for (uint256 i = 0; i < 5; i++) {
            accounts[i] = vault_address;
            ids[i] = i + 5;
        }
        return IFireBotItems(items_contract).balanceOfBatch(accounts, ids);
    }

    function exchange_item(uint256 give_id, uint256 take_id) external {
        // 1. send 5 fbx to the vault
        IFbx(fbx_contract).transferFrom(tx.origin, vault_address, 5 * 1e18);

        // 2. send your item to the vault
        IFireBotItems(items_contract).safeTransferFrom(tx.origin, vault_address, give_id, 1, "0x0");

        // 3. the vault sends you back the other item
        IFireBotItems(items_contract).safeTransferFrom(vault_address, tx.origin, take_id, 1, "0x0");
    } 
}