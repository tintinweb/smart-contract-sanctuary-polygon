// contracts/IMagicAggregator.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMagicAggregator {
    /// @notice Gets the number of tokens the specified wallet is able to purchase currently.
    ///
    /// @param addr            The address (wallet or contract) to mint into
    /// @param contracts       A list of ERC721 smart contracts that have the address allowed to mint
    /// @param function_names  A list of the names of the mint function for each contract
    /// @param amounts         A list of the quantity/amounts of each token to mint
    function batchMint721(
        address addr,
        address payable[] calldata contracts,
        string[] memory function_names,
        uint256[] calldata amounts
    ) external payable;

    /// @notice Bulk-transfers tokens from one wallet into multiple
    ///
    /// @param from            The address (wallet or contract) to mint into
    /// @param contracts       A list of ERC721 smart contracts that have the address allowed to mint
    /// @param token_ids       A list of the Token IDs to transfer
    /// @param to_addresses    A list of the destination addresses (wallets) to send to
    function batchTranfser721(
        address from,
        address payable[] calldata contracts,
        uint256[] calldata token_ids,
        address[] calldata to_addresses
    ) external;
}

// contracts/MagicAggregator.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IMagicAggregator.sol";

interface TransferInterface{
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract MagicAggregator is IMagicAggregator {
    event Response(bool success, bytes data, address contract_address, string function_name, uint256 amount);
    event Transfer(address from, address to, uint256 tokenId);

    constructor() {}

    function batchMint721(
        address wallet,
        address payable[] calldata contracts,
        string[] memory function_names,
        uint256[] calldata amounts
    ) external payable {
        // All arrays must be equal
        require(
            contracts.length == amounts.length &&
            contracts.length == function_names.length,
            "all arrays must be equal length"
        );
        string memory abi_params = "(address,uint256)";

        // Loop through the contracts and mint
        for (uint i=0; i<contracts.length; i++) {
            // MintInterface underlying_contract = MintInterface(contracts[i]);
            string memory abi_str = string.concat(function_names[i], abi_params);
            (bool success, bytes memory data) = contracts[i].call(abi.encodeWithSignature(abi_str, wallet, amounts[i]));
            emit Response(success, data, contracts[i], function_names[i], amounts[i]);
        }
    }

    function batchTranfser721(
        address from,
        address payable[] calldata contracts,
        uint256[] calldata token_ids,
        address[] calldata to_addresses
    ) external {
        // All arrays must be equal
        require(
            contracts.length == token_ids.length &&
            contracts.length == to_addresses.length,
            "all arrays must be equal length"
        );

        // Loop thru the contracts and transfer
        for (uint i=0; i<contracts.length; i++) {
            TransferInterface underlying_contract = TransferInterface(contracts[i]);
            underlying_contract.safeTransferFrom(from, to_addresses[i], token_ids[i], "");
        }
    }
}