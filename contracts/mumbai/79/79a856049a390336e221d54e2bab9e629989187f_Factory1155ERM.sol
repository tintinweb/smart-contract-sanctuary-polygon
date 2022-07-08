/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.0;

interface IVault1155ERM {
    function initialize(
        string memory name,
        string memory symbol,
        uint256 parityDepositAmount,
        uint256 parityWithdrawalAmount,
        address[] calldata contractAddresses,
        address owner,
        bool restrictDeposits,
        bool restrictWithdrawals
    ) external;
}

/** Factory for a heterogeneous, restricted, managed (heterogeneous) vault that targets ERC-1155 conforming contracts. */
contract Factory1155ERM {
    /** Fired when a vault is created. */
    event VaultCreated(address vaultAddress);

    // Address of the master Vault contract.
    address public _vaultAddress;

    // Who can change the master Vault contract address.
    address public _owner = msg.sender;

    bool _reentrancyGuard;

    /**
     * Deploy a new vault.
     *
     * Features:
     *     - Heterogeneous: Multiple types of ERC-1155 token can be stored.
     *     - Restricted: Role-restricted withdrawers / depositers.
     *     - Managed: Tokens can be added / modified / removed after deployment.
     *
     * @param name The name of the wrapped token.
     * @param symbol The symbol of the wrapped token.
     * @param parityDepositAmount The amount of parity tokens received when depositing each NFT. Use '0' for the default of 10^18.
     * @param parityWithdrawalAmount The amount of parity tokens spent when withdrawing each NFT. Use '0' for the default of 10^18.
     * @param contractAddresses The addresses of the ERC-1155 contracts whose tokens will be stored in this vault.
     * @param restrictDeposits Restricts deposits to those wallets that have been previously authorized (enables whitelist).
     * @param restrictWithdrawals Restricts withdrawals to those wallets that have been previously authorized (enables whitelist).
     *
     * @return The address of the newly created vault.
     */
    function deploy(
        string memory name,
        string memory symbol,
        uint256 parityDepositAmount,
        uint256 parityWithdrawalAmount,
        address[] calldata contractAddresses,
        bool restrictDeposits,
        bool restrictWithdrawals
    ) external returns (address) {
        require(!_reentrancyGuard, "reentrant");
        _reentrancyGuard = true;

        // We don't validate the addresses to see if they are ERC721 contracts, because A) we want to be able to interact with
        // partially/non-conforming contracts (e.g., USDT), and B) because any interactions with non-compatible / non-contract
        // addresses will revert.

        // Create the vault
        address vault = _clone();
        IVault1155ERM(vault).initialize(
            name,
            symbol,
            parityDepositAmount,
            parityWithdrawalAmount,
            contractAddresses,
            msg.sender,
            restrictDeposits,
            restrictWithdrawals
        );


        // Hello world!
        emit VaultCreated(vault);

        _reentrancyGuard = false;

        return vault;
    }

    // Change the owner
    function setOwner(address newOwner) external {
        require(
               msg.sender == _owner
            && newOwner != address(0)
            && newOwner != address(this)
            && newOwner != _vaultAddress
            && newOwner != msg.sender // owner
            && !_reentrancyGuard,
            "Invalid address"
        );

        _owner = newOwner;
    }

    // Update the master Vault contract address.
    function setVaultAddress(address newAddress) external {
        require(
               msg.sender == _owner
            && newAddress != address(0)
            && newAddress != address(this)
            && newAddress != _vaultAddress
            && newAddress != msg.sender // owner
            && !_reentrancyGuard, 
            "Invalid address"
        );

        _vaultAddress = newAddress;
    }

    // Create a simple EIP-1167 clone of the Vault contract. This has no upgradability.
    // https://github.com/optionality/clone-factory
    function _clone() internal returns (address result) {
        bytes20 targetBytes = bytes20(_vaultAddress);
        require(targetBytes != bytes20(0x0), "Vault address not set");
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}