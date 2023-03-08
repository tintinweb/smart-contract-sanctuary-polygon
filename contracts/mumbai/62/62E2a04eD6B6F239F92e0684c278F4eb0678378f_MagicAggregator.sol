// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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


    /// @notice Gets the number of tokens the specified wallet is able to purchase currently.
    ///
    /// @param wallet            The address (wallet or contract) to mint into
    /// @param contracts       A list of ERC721 smart contracts that have the address allowed to mint
    /// @param function_names  A list of the names of the mint function for each contract
    /// @param amounts         A list of the quantity/amounts of each token to mint
    /// @param token_ids       A list of token_ids to mint
    function batchMint1155(
        address wallet,
        address payable[] calldata contracts,
        string[] memory function_names,
        uint256[] calldata amounts,
        uint256[] calldata token_ids
    ) external payable;

    /// @notice Bulk-transfers tokens from one wallet into multiple
    ///
    /// @param from            The address (wallet or contract) to mint into
    /// @param contracts       A list of ERC721 smart contracts that have the address allowed to mint
    /// @param amounts         A list of the quantity/amounts of each token to mint
    /// @param token_ids       A list of the Token IDs to transfer
    /// @param to_addresses    A list of the destination addresses (wallets) to send to
    function batchTranfser1155(
        address from,
        address payable[] calldata contracts,
        uint256[] calldata amounts,
        uint256[] calldata token_ids,
        address[] calldata to_addresses
    ) external;
}

// contracts/MagicAggregator.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IMagicAggregator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface TransferInterface721{
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface TransferInterface1155{
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract MagicAggregator is IMagicAggregator, Ownable {
    event batchMint721Response(bool success, bytes data, address contract_address, string function_name, uint256 amount);
    event batchTransfer721Response(bool success, bytes data, address contract_address, address to_address, uint256 token_id);
    event batchMint1155Response(bool success, bytes data, address contract_address, string function_name, uint256 amount, uint256 token_id);
    event batchTransfer1155Response(bool success, bytes data, address contract_address, address to_address, uint256 amount, uint256 token_id);
    event Transfer(address from, address to, uint256 tokenId);

    constructor() {}

    function batchMint721(
        address wallet,
        address payable[] calldata contracts,
        string[] memory function_names,
        uint256[] calldata amounts
    ) external payable onlyOwner {
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
            emit batchMint721Response(success, data, contracts[i], function_names[i], amounts[i]);
        }
    }

    function batchTranfser721(
        address from,
        address payable[] calldata contracts,
        uint256[] calldata token_ids,
        address[] calldata to_addresses
    ) external onlyOwner {
        // All arrays must be equal
        require(
            contracts.length == token_ids.length &&
            contracts.length == to_addresses.length,
            "all arrays must be equal length"
        );

        // Loop thru the contracts and transfer
        for (uint i=0; i<contracts.length; i++) {
            TransferInterface721 underlying_contract = TransferInterface721(contracts[i]);
            // underlying_contract.safeTransferFrom(from, to_addresses[i], token_ids[i], "");
            try underlying_contract.safeTransferFrom(from, to_addresses[i], token_ids[i], "") {
                emit batchTransfer721Response(true, "", contracts[i], to_addresses[i], token_ids[i]);
            } catch Error(string memory /*reason*/) {
                // This is executed in case
                // revert was called inside getData
                // and a reason string was provided.
                emit batchTransfer721Response(false, "", contracts[i], to_addresses[i], token_ids[i]);
            } catch (bytes memory /*lowLevelData*/) {
                // This is executed in case revert() was used
                // or there was a failing assertion, division
                // by zero, etc. inside getData.
                emit batchTransfer721Response(false, "", contracts[i], to_addresses[i], token_ids[i]);
            }
        }
    }

    function batchMint1155(
        address wallet,
        address payable[] calldata contracts,
        string[] memory function_names,
        uint256[] calldata amounts,
        uint256[] calldata token_ids
    ) external payable onlyOwner {
        // All arrays must be equal
        require(
            contracts.length == amounts.length &&
            contracts.length == function_names.length &&
            contracts.length == token_ids.length,
            "all arrays must be equal length"
        );
        // (to,token_id,amount)
        string memory abi_params = "(address,uint256,uint256)";

        // Loop through the contracts and mint
        for (uint i=0; i<contracts.length; i++) {
            string memory abi_str = string.concat(function_names[i], abi_params);
            (bool success, bytes memory data) = contracts[i].call(abi.encodeWithSignature(abi_str, wallet, amounts[i], token_ids[i]));
            emit batchMint1155Response(success, data, contracts[i], function_names[i], amounts[i], token_ids[i]);
        }
    }

    function batchTranfser1155(
        address from,
        address payable[] calldata contracts,
        uint256[] calldata amounts,
        uint256[] calldata token_ids,
        address[] calldata to_addresses
    ) external onlyOwner {
        // All arrays must be equal
        require(
            contracts.length == token_ids.length &&
            contracts.length == to_addresses.length &&
            contracts.length == amounts.length,
            "all arrays must be equal length"
        );

        // Loop thru the contracts and transfer
        for (uint i=0; i<contracts.length; i++) {
            TransferInterface1155 underlying_contract = TransferInterface1155(contracts[i]);
            // underlying_contract.safeTransferFrom(from, to_addresses[i], token_ids[i], "");
            try underlying_contract.safeTransferFrom(from, to_addresses[i], token_ids[i], amounts[i], "") {
                emit batchTransfer1155Response(true, "", contracts[i], to_addresses[i], token_ids[i], amounts[i]);
            } catch Error(string memory /*reason*/) {
                // This is executed in case
                // revert was called inside getData
                // and a reason string was provided.
                emit batchTransfer1155Response(false, "", contracts[i], to_addresses[i], token_ids[i], amounts[i]);
            } catch (bytes memory /*lowLevelData*/) {
                // This is executed in case revert() was used
                // or there was a failing assertion, division
                // by zero, etc. inside getData.
                emit batchTransfer1155Response(false, "", contracts[i], to_addresses[i], token_ids[i], amounts[i]);
            }
        }
    }
}