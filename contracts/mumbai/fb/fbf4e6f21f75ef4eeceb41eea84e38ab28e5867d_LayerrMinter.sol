// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {AddressValue} from "../lib/StorageTypes.sol";
import {IOwnable} from "../interfaces/IOwnable.sol";
import {LAYERROWNABLE_OWNER_SLOT, LAYERROWNABLE_NEW_OWNER_SLOT} from "./LayerrStorage.sol";

/**
 * @title LayerrOwnable
 * @author 0xth0mas (Layerr)
 * @notice ERC173 compliant ownership interface with two-step transfer/acceptance.
 * @dev LayerrOwnable uses two custom storage slots for current contract owner and new owner as defined in LayerrStorage.
 */
contract LayerrOwnable is IOwnable {
    modifier onlyOwner() {
        if (msg.sender != _getOwner()) {
            revert NotContractOwner();
        }
        _;
    }

    modifier onlyNewOwner() {
        if (msg.sender != _getNewOwner()) {
            revert NotContractOwner();
        }
        _;
    }

    /**
     * @notice Returns the current contract owner
     */
    function owner() external view returns(address _owner) {
        _owner = _getOwner();
    }

    /**
     * @notice Begins first step of ownership transfer. _newOwner will need to call acceptTransfer() to complete.
     * @param _newOwner address to transfer ownership of contract to
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        _setNewOwner(_newOwner);
    }

    /**
     * @notice Second step of ownership transfer called by the new contract owner.
     */
    function acceptTransfer() external onlyNewOwner {
        address _previousOwner = _getOwner();

        //set contract owner to new owner, clear out the newOwner value
        _setOwner(_getNewOwner());
        _setNewOwner(address(0));

        emit OwnershipTransferred(_previousOwner, _getOwner());
    }

    /**
     * @notice Cancels ownership transfer to newOwner before the transfer is accepted.
     */
    function cancelTransfer() external onlyOwner {
        _setNewOwner(address(0));
    }

    /**
     * @notice EIP165 supportsInterface for introspection
     */
    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool) {
        return interfaceID == 0x7f5828d0;
    }

    /** INTERNAL FUNCTIONS */

    /**
     * @dev Internal helper function to load custom storage slot address value
     */
    function _getOwner() internal view returns(address _owner) {
        AddressValue storage ownerValue;
        /// @solidity memory-safe-assembly
        assembly {
            ownerValue.slot := LAYERROWNABLE_OWNER_SLOT
        }
        _owner = ownerValue.value;
    }

    /**
     * @dev Internal helper function to set owner address in custom storage slot
     */
    function _setOwner(address _owner) internal {
        AddressValue storage ownerValue;
        /// @solidity memory-safe-assembly
        assembly {
            ownerValue.slot := LAYERROWNABLE_OWNER_SLOT
        }
        ownerValue.value = _owner;
    }

    /**
     * @dev Internal helper function to load custom storage slot address value
     */
    function _getNewOwner() internal view returns(address _newOwner) {
        AddressValue storage newOwnerValue;
        /// @solidity memory-safe-assembly
        assembly {
            newOwnerValue.slot := LAYERROWNABLE_NEW_OWNER_SLOT
        }
        _newOwner = newOwnerValue.value;
    }

    /**
     * @dev Internal helper function to set new owner address in custom storage slot
     */
    function _setNewOwner(address _newOwner) internal {
        AddressValue storage newOwnerValue;
        /// @solidity memory-safe-assembly
        assembly {
            newOwnerValue.slot := LAYERROWNABLE_NEW_OWNER_SLOT
        }
        newOwnerValue.value = _newOwner;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Storage slot for current owner calculated from keccak256('Layerr.LayerrOwnable.owner')
bytes32 constant LAYERROWNABLE_OWNER_SLOT = 0xedc628ad38a73ae7d50600532f1bf21da1bfb1390b4f8174f361aca54d4c6b66;

/// @dev Storage slot for pending ownership transfer calculated from keccak256('Layerr.LayerrOwnable.newOwner')
bytes32 constant LAYERROWNABLE_NEW_OWNER_SLOT = 0x15c115ab76de082272ae65126522082d4aad634b6478097549f84086af3b84bc;

/// @dev Storage slot for token name calculated from keccak256('Layerr.LayerrToken.name')
bytes32 constant LAYERRTOKEN_NAME_SLOT = 0x7f84c61ed30727f282b62cab23f49ac7f4d263f04a4948416b7b9ba7f34a20dc;

/// @dev Storage slot for token symbol calculated from keccak256('Layerr.LayerrToken.symbol')
bytes32 constant LAYERRTOKEN_SYMBOL_SLOT = 0xdc0f2363b26c589c72caecd2357dae5fee235863060295a057e8d69d61a96d8a;

/// @dev Storage slot for URI renderer calculated from keccak256('Layerr.LayerrToken.renderer')
bytes32 constant LAYERRTOKEN_RENDERER_SLOT = 0x395b7021d979c3dbed0f5d530785632316942232113ba3dbe325dc167550e320;

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. 
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC4906 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerr1155
 * @author 0xth0mas (Layerr)
 * @notice ILayerr1155 interface defines functions required in an ERC1155 token contract to callable by the LayerrMinter contract.
 */
interface ILayerr1155 {

    /**
     * @notice Mints tokens to the recipients, each recipient gets the corresponding tokenId in the `tokenIds` array
     * @dev This function should be protected by a role so that it is not callable by any address
     * @dev `recipients`, `tokenIds` and `amounts` arrays must be equal length, each recipient will receive the corresponding 
     *      tokenId and amount from the `tokenIds` and `amounts` arrays
     * @param recipients addresses to airdrop tokens to
     * @param tokenIds ids of tokens to be airdropped to recipients
     * @param amounts amounts of tokens to be airdropped to recipients
     */
    function airdrop(address[] calldata recipients, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @notice Mints `amount` of `tokenId` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param tokenId id of the token to mint
     * @param amount amount of token to mint
     */
    function mintTokenId(address minter, address to, uint256 tokenId, uint256 amount) external;

    /**
     * @notice Mints `amount` of `tokenId` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param tokenIds array of ids to mint
     * @param amounts array of amounts to mint
     */
    function mintBatchTokenIds(
        address minter,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Burns `tokenId` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenId from
     * @param tokenId id of token to be burned
     * @param amount amount of `tokenId` to burn from `from`
     */
    function burnTokenId(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external;

    /**
     * @notice Burns `tokenId` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenId from
     * @param tokenIds array of token ids to be burned
     * @param amounts array of amounts to burn from `from`
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Emits URI event for tokens provided
     * @param tokenIds array of token ids to emit MetadataUpdate event for
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external;

    /**
     * @notice Returns the total supply of ERC1155 tokens in circulation for given `id`.
     * @param id the token id to check total supply of
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice Returns the total number of tokens minted for the contract and the number of tokens minted by the `minter`
     * @param minter address to check for number of tokens minted
     * @param id the token id to check number of tokens minted for
     * @return totalMinted total number of ERC1155 tokens for given `id` minted since token launch
     * @return minterMinted total number of ERC1155 tokens for given `id` minted by the `minter`
     */
    function totalMintedCollectionAndMinter(address minter, uint256 id) external view returns(uint256 totalMinted, uint256 minterMinted);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerr20
 * @author 0xth0mas (Layerr)
 * @notice ILayerr20 interface defines functions required in an ERC20 token contract to callable by the LayerrMinter contract.
 */
interface ILayerr20 {
    /// @dev Thrown when two or more sets of arrays are supplied that require equal lengths but differ in length.
    error ArrayLengthMismatch();

    /**
     * @notice Mints tokens to the recipients in amounts specified
     * @dev This function should be protected by a role so that it is not callable by any address
     * @param recipients addresses to airdrop tokens to
     * @param amounts amount of tokens to airdrop to recipients
     */
    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external;

    /**
     * @notice Mints `amount` of ERC20 tokens to the `to` address
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the minted amount will be credited to
     * @param to address that will receive the tokens being minted
     * @param amount amount of tokens being minted
     */
    function mint(address minter, address to, uint256 amount) external;

    /**
     * @notice Burns `amount` of ERC20 tokens from the `from` address
     * @dev This function should check that the caller has a sufficient spend allowance to burn these tokens
     * @param from address that the tokens will be burned from
     * @param amount amount of tokens to be burned
     */
    function burn(address from, uint256 amount) external;

    /**
     * @notice Returns the total supply of ERC20 tokens in circulation.
     */
    function totalSupply() external view returns(uint256);

    /**
     * @notice Returns the total number of tokens minted for the contract and the number of tokens minted by the `minter`
     * @param minter address to check for number of tokens minted
     * @return totalMinted total number of ERC20 tokens minted since token launch
     * @return minterMinted total number of ERC20 tokens minted by the `minter`
     */
    function totalMintedTokenAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerr721
 * @author 0xth0mas (Layerr)
 * @notice ILayerr721 interface defines functions required in an ERC721 token contract to callable by the LayerrMinter contract.
 * @dev ILayerr721 should be used for non-sequential token minting.
 */
interface ILayerr721 {
    /// @dev Thrown when two or more sets of arrays are supplied that require equal lengths but differ in length.
    error ArrayLengthMismatch();

    /**
     * @notice Mints tokens to the recipients, each recipient gets the corresponding tokenId in the `tokenIds` array
     * @dev This function should be protected by a role so that it is not callable by any address
     * @param recipients addresses to airdrop tokens to
     * @param tokenIds ids of tokens to be airdropped to recipients
     */
    function airdrop(address[] calldata recipients, uint256[] calldata tokenIds) external;

    /**
     * @notice Mints `tokenId` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the token
     * @param tokenId the id of the token to mint
     */
    function mintTokenId(address minter, address to, uint256 tokenId) external;

    /**
     * @notice Mints `tokenIds` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param tokenIds the ids of tokens to mint
     */
    function mintBatchTokenIds(
        address minter,
        address to,
        uint256[] calldata tokenIds
    ) external;

    /**
     * @notice Burns `tokenId` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenId from
     * @param tokenId id of token to be burned
     */
    function burnTokenId(address from, uint256 tokenId) external;

    /**
     * @notice Burns `tokenIds` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenIds from
     * @param tokenIds ids of tokens to be burned
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds
    ) external;

    /**
     * @notice Emits ERC-4906 BatchMetadataUpdate event for all tokens
     */
    function updateMetadataAllTokens() external;

    /**
     * @notice Emits ERC-4906 MetadataUpdate event for tokens provided
     * @param tokenIds array of token ids to emit MetadataUpdate event for
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external;

    /**
     * @notice Returns the total supply of ERC721 tokens in circulation.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the total number of tokens minted for the contract and the number of tokens minted by the `minter`
     * @param minter address to check for number of tokens minted
     * @return totalMinted total number of ERC721 tokens minted since token launch
     * @return minterMinted total number of ERC721 tokens minted by the `minter`
     */
    function totalMintedCollectionAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerr721A
 * @author 0xth0mas (Layerr)
 * @notice ILayerr721A interface defines functions required in an ERC721A token contract to callable by the LayerrMinter contract.
 * @dev ILayerr721A should be used for sequential token minting.
 */
interface ILayerr721A {
    /// @dev Thrown when two or more sets of arrays are supplied that require equal lengths but differ in length.
    error ArrayLengthMismatch();


    /**
     * @notice Mints tokens to the recipients, each recipient receives the corresponding amount of tokens in the `amounts` array
     * @dev This function should be protected by a role so that it is not callable by any address
     * @param recipients addresses to airdrop tokens to
     * @param amounts amount of tokens that should be airdropped to each recipient
     */
    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external;


    /**
     * @notice Sequentially mints `quantity` of tokens to `to`
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param quantity the number of tokens to sequentially mint to `to`
     */
    function mintSequential(address minter, address to, uint256 quantity) external;

    /**
     * @notice Burns `tokenId` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenId from
     * @param tokenId id of token to be burned
     */
    function burnTokenId(address from, uint256 tokenId) external;

    /**
     * @notice Burns `tokenIds` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenIds from
     * @param tokenIds ids of tokens to be burned
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds
    ) external;

    /**
     * @notice Emits ERC-4906 BatchMetadataUpdate event for all tokens
     */
    function updateMetadataAllTokens() external;

    /**
     * @notice Emits ERC-4906 MetadataUpdate event for tokens provided
     * @param tokenIds array of token ids to emit MetadataUpdate event for
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external;

    /**
     * @notice Returns the total supply of ERC721 tokens in circulation.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the total number of tokens minted for the contract and the number of tokens minted by the `minter`
     * @param minter address to check for number of tokens minted
     * @return totalMinted total number of ERC721 tokens minted since token launch
     * @return minterMinted total number of ERC721 tokens minted by the `minter`
     */
    function totalMintedCollectionAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MintOrder, MintParameters, MintToken, BurnToken, PaymentToken} from "../lib/MinterStructs.sol";

/**
 * @title ILayerrMinter
 * @author 0xth0mas (Layerr)
 * @notice ILayerrMinter interface defines functions required in the LayerrMinter to be callable by token contracts
 */
interface ILayerrMinter {

    /// @dev Event emitted when a mint order is fulfilled
    event MintOrderFulfilled(
        bytes indexed mintParametersSignature,
        address indexed minter,
        uint256 indexed quantity
    );

    /// @dev Event emitted when a token contract updates an allowed signer for EIP712 signatures
    event ContractAllowedSignerUpdate(
        address indexed _contract,
        address indexed _signer,
        bool indexed _allowed
    );

    /// @dev Event emitted when a token contract updates an allowed oracle signer for offchain authorization of a wallet to use a signature
    event ContractOracleUpdated(
        address indexed _contract,
        address indexed _oracle,
        bool indexed _allowed
    );

    /// @dev Event emitted when a signer updates their nonce with LayerrMinter. Updating a nonce invalidates all previously signed EIP712 signatures.
    event SignerNonceIncremented(
        address indexed _signer,
        uint256 indexed _nonce
    );

    /// @dev Event emitted when a specific signature's validity is updated with the LayerrMinter contract.
    event SignatureValidityUpdated(
        address indexed _contract,
        bool indexed invalid,
        bytes32 signatureDigest
    );

    /// @dev Thrown when the amount of native tokens supplied in msg.value is insufficient for the mint order
    error InsufficientPayment();

    /// @dev Thrown when a payment fails to be forwarded to the intended recipient
    error PaymentFailed();

    /// @dev Thrown when a MintParameters payment token uses a token type value other than native or ERC20
    error InvalidPaymentTokenType();

    /// @dev Thrown when a MintParameters burn token uses a token type value other than ERC20, ERC721 or ERC1155
    error InvalidBurnTokenType();

    /// @dev Thrown when a MintParameters mint token uses a token type value other than ERC20, ERC721 or ERC1155
    error InvalidMintTokenType();

    /// @dev Thrown when a MintParameters burn token uses a burn type value other than contract burn or send to dead
    error InvalidBurnType();

    /// @dev Thrown when a MintParameters burn token requires a specific burn token id and the tokenId supplied does not match
    error InvalidBurnTokenId();

    /// @dev Thrown when a MintParameters burn token requires a specific ERC721 token and the burn amount is greater than 1
    error CannotBurnMultipleERC721WithSameId();

    /// @dev Thrown when attempting to mint with MintParameters that have a start time greater than the current block time
    error MintHasNotStarted();

    /// @dev Thrown when attempting to mint with MintParameters that have an end time less than the current block time
    error MintHasEnded();

    /// @dev Thrown when a MintParameters has a merkleroot set but the supplied merkle proof is invalid
    error InvalidMerkleProof();

    /// @dev Thrown when a MintOrder will cause a token's minted supply to exceed the defined maximum supply in MintParameters
    error MintExceedsMaxSupply();

    /// @dev Thrown when a MintOrder will cause a minter's minted amount to exceed the defined max per wallet in MintParameters
    error MintExceedsMaxPerWallet();

    /// @dev Thrown when a MintParameters mint token has a specific ERC721 token and the mint amount is greater than 1
    error CannotMintMultipleERC721WithSameId();

    /// @dev Thrown when the recovered signer for the MintParameters is not an allowed signer for the mint token
    error NotAllowedSigner();

    /// @dev Thrown when the recovered signer's nonce does not match the current nonce in LayerrMinter
    error SignerNonceInvalid();

    /// @dev Thrown when a signature has been marked as invalid for a mint token contract
    error SignatureInvalid();

    /// @dev Thrown when MintParameters requires an oracle signature and the recovered signer is not an allowed oracle for the contract
    error InvalidOracleSignature();

    /// @dev Thrown when MintParameters has a max signature use set and the MintOrder will exceed the maximum uses
    error ExceedsMaxSignatureUsage();

    /// @dev Thrown when attempting to increment nonce on behalf of another account and the signature is invalid
    error InvalidSignatureToIncrementNonce();

    /**
     * @notice This function is called by token contracts to update allowed signers for minting
     * @param _signer address of the EIP712 signer
     * @param _allowed if the `_signer` is allowed to sign for minting
     */
    function setContractAllowedSigner(address _signer, bool _allowed) external;

    /**
     * @notice This function is called by token contracts to update allowed oracles for offchain authorizations
     * @param _oracle address of the oracle
     * @param _allowed if the `_oracle` is allowed to sign offchain authorizations
     */
    function setContractAllowedOracle(address _oracle, bool _allowed) external;

    /**
     * @notice This function is called by token contracts to update validity of signatures for the LayerrMinter contract
     * @dev `invalid` should be true to invalidate signatures, the default state of `invalid` being false means 
     *      a signature is valid for a contract assuming all other conditions are met
     * @param signatureDigests an array of message digests for MintParameters to update validity of
     * @param invalid if the supplied digests will be marked as valid or invalid
     */
    function setSignatureValidity(
        bytes32[] calldata signatureDigests,
        bool invalid
    ) external;

    /**
     * @notice Increments the nonce for a signer to invalidate all previous signed MintParameters
     */
    function incrementSignerNonce() external;

    /**
     * @notice Increments the nonce on behalf of another account by validating a signature from that account
     * @dev The signature is an eth personal sign message of the current signer nonce plus the chain id
     *      ex. current nonce 0 on chain 5 would be a signature of \x19Ethereum Signed Message:\n15
     *          current nonce 50 on chain 1 would be a signature of \x19Ethereum Signed Message:\n251
     * @param signer account to increment nonce for
     * @param signature signature proof that the request is coming from the account
     */
    function incrementNonceFor(address signer, bytes calldata signature) external;

    /**
     * @notice Validates and processes a single MintOrder, tokens are minted to msg.sender
     * @param mintOrder struct containing the details of the mint order
     */
    function mint(
        MintOrder calldata mintOrder
    ) external payable;

    /**
     * @notice Validates and processes an array of MintOrders, tokens are minted to msg.sender
     * @param mintOrders array of structs containing the details of the mint orders
     */
    function mintBatch(
        MintOrder[] calldata mintOrders
    ) external payable;

    /**
     * @notice Validates and processes a single MintOrder, tokens are minted to `mintToWallet`
     * @param mintToWallet the address tokens will be minted to
     * @param mintOrder struct containing the details of the mint order
     */
    function mintTo(
        address mintToWallet,
        MintOrder calldata mintOrder
    ) external payable;

    /**
     * @notice Validates and processes an array of MintOrders, tokens are minted to `mintToWallet`
     * @param mintToWallet the address tokens will be minted to
     * @param mintOrders array of structs containing the details of the mint orders
     */
    function mintBatchTo(
        address mintToWallet,
        MintOrder[] calldata mintOrders
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165} from "./IERC165.sol";

/**
 * @title ILayerrRenderer
 * @author 0xth0mas (Layerr)
 * @notice ILayerrRenderer interface defines functions required in LayerrRenderer to be callable by token contracts
 */
interface ILayerrRenderer is ERC165 {

    enum RenderType {
        LAYERR_HOSTED,
        PREREVEAL,
        BASE_PLUS_TOKEN
    }

    /// @dev Thrown when a payment fails for Layerr-hosted IPFS
    error PaymentFailed();

    /// @dev Thrown when a call is made for an owner-function by a non-contract owner
    error NotContractOwner();

    /// @dev Thrown when a signature is not made by the authorized account
    error InvalidSignature();

    /**
     * @notice Generates a tokenURI for the `contractAddress` and `tokenId`
     * @param contractAddress token contract address to render a token URI for
     * @param tokenId token id to render
     * @return uri for the token metadata
     */
    function tokenURI(
        address contractAddress,
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * @notice Generates a contractURI for the `contractAddress`
     * @param contractAddress contract address to render a contract URI for
     * @return uri for the contract metadata
     */
    function contractURI(
        address contractAddress
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerrToken
 * @author 0xth0mas (Layerr)
 * @notice ILayerrToken interface defines functions required to be supported by the Layerr platform
 */
interface ILayerrToken {

    /// @dev Emitted when the contract is deployed so that it can be indexed and assigned to its owner
    event LayerrContractDeployed();

    /// @dev Emitted when a mint extension is updated to allowed or disallowed
    event MintExtensionUpdated(address mintExtension, bool allowed);

    /// @dev Emitted when the contract's renderer is updated
    event RendererUpdated(address renderer);

    /// @dev Thrown when a caller that is not a mint extension attempts to execute a mint function
    error NotValidMintingExtension();

    /// @dev Thrown when a non-owner attempts to execute an only owner function
    error NotAuthorized();

    /// @dev Thrown when attempting to withdraw funds from the contract and the call fails
    error WithdrawFailed();

    /**
     * @return name the name of the token
     */
    function name() external view returns(string memory);

    /**
     * @return symbol the token symbol
     */
    function symbol() external view returns(string memory);

    /**
     * @return renderer the address that will render token/contract URIs
     */
    function renderer() external view returns(address);
    
    /**
     * @notice Sets the renderer for token/contract URIs
     * @dev This function should be restricted to contract owners
     * @param _renderer address to set as the token/contract URI renderer
     */
    function setRenderer(address _renderer) external;

    /**
     * @notice Sets whether or not an address is allowed to call minting functions
     * @dev This function should be restricted to contract owners
     * @param _extension address of the mint extension to update
     * @param _allowed if the mint extension is allowed to mint tokens
     */
    function setMintExtension(
        address _extension,
        bool _allowed
    ) external;

    /**
     * @notice This function calls the mint extension to update `_signer`'s allowance
     * @dev This function should be restricted to contract owners
     * @param _extension address of the mint extension to update
     * @param _signer address of the signer to update
     * @param _allowed if `_signer` is allowed to sign for `_extension`
     */
    function setContractAllowedSigner(
        address _extension,
        address _signer,
        bool _allowed
    ) external;

    /**
     * @notice This function calls the mint extension to update `_oracle`'s allowance
     * @dev This function should be restricted to contract owners
     * @param _extension address of the mint extension to update
     * @param _oracle address of the oracle to update
     * @param _allowed if `_oracle` is allowed to sign for `_extension`
     */
    function setContractAllowedOracle(
        address _extension,
        address _oracle,
        bool _allowed
    ) external;

    /**
     * @notice This function calls the mint extension to update signature validity
     * @dev This function should be restricted to contract owners
     * @param _extension address of the mint extension to update
     * @param signatureDigests hash digests of signatures parameters to update
     * @param invalid true if the signature digests should be marked as invalid
     */
    function setSignatureValidity(
        address _extension,
        bytes32[] calldata signatureDigests,
        bool invalid
    ) external;

    /**
     * @notice This function updates the ERC2981 royalty percentages
     * @dev This function should be restricted to contract owners
     * @param pct royalty percentage in BPS
     * @param royaltyReciever address to receive royalties
     */
    function setRoyalty(
        uint96 pct,
        address royaltyReciever
    ) external;

    /**
     * @notice This function updates the token contract's name and symbol
     * @dev This function should be restricted to contract owners
     * @param _name new name for the token contract
     * @param _symbol new symbol for the token contract
     */
    function editContract(
        string calldata _name,
        string calldata _symbol
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165} from './IERC165.sol';

interface IOwnable is ERC165 {

    /// @dev Thrown when a non-owner is attempting to perform an owner function
    error NotContractOwner();

    /// @dev Emitted when contract ownership is transferred to a new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner    
    /// @return The address of the owner.
    function owner() view external returns(address);
	
    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract    
    function transferOwnership(address _newOwner) external;	
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {TOKEN_TYPE_NATIVE, TOKEN_TYPE_ERC20, TOKEN_TYPE_ERC721, TOKEN_TYPE_ERC1155} from "./lib/TokenType.sol";
import {BURN_TYPE_CONTRACT_BURN, BURN_TYPE_SEND_TO_DEAD} from "./lib/BurnType.sol";
import {MintOrder, MintParameters, MintToken, BurnToken, PaymentToken} from "./lib/MinterStructs.sol";
import {ReentrancyGuard} from "./lib/ReentrancyGuard.sol";
import {ILayerrMinter} from "./interfaces/ILayerrMinter.sol";
import {ILayerr20} from "./interfaces/ILayerr20.sol";
import {ILayerr721} from "./interfaces/ILayerr721.sol";
import {ILayerr721A} from "./interfaces/ILayerr721A.sol";
import {ILayerr1155} from "./interfaces/ILayerr1155.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC1155} from "./interfaces/IERC1155.sol";
import {IDelegationRegistry} from "./interfaces/IDelegationRegistry.sol";
import {MerkleProof} from "./lib/MerkleProof.sol";
import {SignatureVerification} from "./lib/SignatureVerification.sol";

/**
 * @title LayerrMinter
 * @author 0xth0mas (Layerr)
 * @notice LayerrMinter is an unowned immutable primative for ERC20, ERC721 and ERC1155
 *         token minting on EVM-based blockchains. Token contract owners build and sign
 *         MintParameters which are used by minters to create MintOrders to mint tokens.
 *         MintParameters define what to mint and conditions for minting.
 *         Conditions for minting include requiring tokens be burned, payment amounts,
 *         start time, end time, additional oracle signature, maximum supply, max per 
 *         wallet and max signature use.
 *         Mint tokens can be ERC20, ERC721 or ERC1155
 *         Burn tokens can be ERC20, ERC721 or ERC1155
 *         Payment tokens can be the chain native token or ERC20
 *         Payment tokens can specify a referral BPS to pay a referral fee at time of mint
 *         LayerrMinter has native support for delegate.cash delegation on allowlist mints
 */
contract LayerrMinter is ILayerrMinter, ReentrancyGuard, SignatureVerification {

    /// @dev mapping of signature digests that have been marked as invalid for a token contract
    mapping(address => mapping(bytes32 => bool)) public signatureInvalid;

    /// @dev counter for number of times a signature has been used, only incremented if signatureMaxUses > 0
    mapping(bytes32 => uint256) public signatureUseCount;

    /// @dev mapping of addresses that are allowed signers for token contracts
    mapping(address => mapping(address => bool)) public contractAllowedSigner;

    /// @dev mapping of addresses that are allowed oracle signers for token contracts
    mapping(address => mapping(address => bool)) public contractAllowedOracle;

    /// @dev mapping of nonces for signers, used to invalidate all previously signed MintParameters
    mapping(address => uint256) public signerNonce;

    /// @dev address to send tokens when burn type is SEND_TO_DEAD
    address private constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// @dev delegate.cash registry for users that want to use a hot wallet for minting an allowlist mint
    IDelegationRegistry delegateCash = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    /**
     * @inheritdoc ILayerrMinter
     */
    function setContractAllowedSigner(address _signer, bool _allowed) external {
        contractAllowedSigner[msg.sender][_signer] = _allowed;

        emit ContractAllowedSignerUpdate(msg.sender, _signer, _allowed);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function setContractAllowedOracle(address _oracle, bool _allowed) external {
        contractAllowedOracle[msg.sender][_oracle] = _allowed;

        emit ContractOracleUpdated(msg.sender, _oracle, _allowed);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function incrementSignerNonce() external {
        unchecked {
            signerNonce[msg.sender] += uint256(
                keccak256(abi.encodePacked(block.timestamp))
            );
        }

        emit SignerNonceIncremented(msg.sender, signerNonce[msg.sender]);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function incrementNonceFor(address signer, bytes calldata signature) external {
        if(!_validateIncrementNonceSigner(signer, signerNonce[signer], signature)) revert InvalidSignatureToIncrementNonce();
        unchecked {
            signerNonce[signer] += uint256(
                keccak256(abi.encodePacked(block.timestamp))
            );
        }

        emit SignerNonceIncremented(signer, signerNonce[signer]);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function setSignatureValidity(
        bytes32[] calldata signatureDigests,
        bool invalid
    ) external {
        for (uint256 i; i < signatureDigests.length; ) {
            signatureInvalid[msg.sender][signatureDigests[i]] = invalid;
            emit SignatureValidityUpdated(msg.sender, invalid, signatureDigests[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mint(
        MintOrder calldata mintOrder
    ) external payable NonReentrant {
        _processMintOrder(msg.sender, mintOrder, 0);

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mintBatch(
        MintOrder[] calldata mintOrders
    ) external payable NonReentrant {
        uint256 suppliedBurnTokenIdIndex = 0;

        for (uint256 orderIndex; orderIndex < mintOrders.length; ) {
            MintOrder calldata mintOrder = mintOrders[orderIndex];

            suppliedBurnTokenIdIndex = _processMintOrder(msg.sender, mintOrder, suppliedBurnTokenIdIndex);

            unchecked {
                ++orderIndex;
            }
        }

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mintTo(
        address mintToWallet,
        MintOrder calldata mintOrder
    ) external payable NonReentrant {
        _processMintOrder(mintToWallet, mintOrder, 0);

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mintBatchTo(
        address mintToWallet,
        MintOrder[] calldata mintOrders
    ) external payable NonReentrant {
        uint256 suppliedBurnTokenIdIndex = 0;

        for (uint256 orderIndex; orderIndex < mintOrders.length; ) {
            MintOrder calldata mintOrder = mintOrders[orderIndex];

            suppliedBurnTokenIdIndex = _processMintOrder(mintToWallet, mintOrder, suppliedBurnTokenIdIndex);

            unchecked {
                ++orderIndex;
            }
        }

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @notice Validates mint parameters, processes payments and burns, mint tokens
     * @param mintToWallet address that tokens will be minted to
     * @param mintOrder struct containing the mint order details
     * @param suppliedBurnTokenIdIndex the current burn token index before processing the mint order
     * @return suppliedBurnTokenIdIndex the current burn token index after processing the mint order
     */
    function _processMintOrder(
        address mintToWallet, 
        MintOrder calldata mintOrder, 
        uint256 suppliedBurnTokenIdIndex
    ) internal returns (uint256) {
        MintParameters calldata mintParameters = mintOrder.mintParameters;
        bytes calldata mintParametersSignature = mintOrder.mintParametersSignature;
        uint256 quantity = mintOrder.quantity;

        (address mintParametersSigner, bytes32 signatureDigest) = _recoverMintParametersSigner(
            mintParameters,
            mintParametersSignature
        );

        (bool useDelegate, address oracleSigner) = _validateMintParameters(mintToWallet, mintOrder, mintParametersSignature, mintParametersSigner, signatureDigest);

        _processPayments(
            quantity,
            mintParameters.paymentTokens,
            mintOrder.referrer
        );
        if(mintParameters.burnTokens.length > 0) {
            suppliedBurnTokenIdIndex = _processBurns(
                quantity,
                suppliedBurnTokenIdIndex,
                mintParameters.burnTokens,
                mintOrder.suppliedBurnTokenIds
            );
        }

        address mintCountWallet;
        if(useDelegate) {
            mintCountWallet = mintOrder.vaultWallet;
        } else {
            mintCountWallet = mintToWallet;
        }
        
        _processMints(
            mintParameters.mintTokens,
            mintParametersSigner,
            signatureDigest,
            oracleSigner,
            quantity,
            mintCountWallet,
            mintToWallet
        );

        emit MintOrderFulfilled(mintParametersSignature, mintToWallet, quantity);

        return suppliedBurnTokenIdIndex;
    }

    /**
     * @notice Checks the MintParameters for start/end time compliance, signer nonce, allowlist, signature max uses and oracle signature
     * @param mintToWallet address tokens will be minted to
     * @param mintOrder struct containing the mint order details 
     * @param mintParametersSignature EIP712 signature of the MintParameters
     * @param mintParametersSigner recovered signer of the mintParametersSignature
     * @param signatureDigest hash digest of the MintParameters
     * @return useDelegate true for allowlist mint that mintToWallet 
     * @return oracleSigner recovered address of the oracle signer if oracle signature is required or address(0) if oracle signature is not required
     */
    function _validateMintParameters(
        address mintToWallet, 
        MintOrder calldata mintOrder, 
        bytes calldata mintParametersSignature, 
        address mintParametersSigner, 
        bytes32 signatureDigest
    ) internal returns(bool useDelegate, address oracleSigner) {
        MintParameters calldata mintParameters = mintOrder.mintParameters;
        if (mintParameters.startTime > block.timestamp) {
            revert MintHasNotStarted();
        }
        if (mintParameters.endTime < block.timestamp) {
            revert MintHasEnded();
        }
        if (signerNonce[mintParametersSigner] != mintParameters.nonce) {
            revert SignerNonceInvalid();
        }
        if (mintParameters.merkleRoot != bytes32(0)) {
            if (
                !MerkleProof.verifyCalldata(
                    mintOrder.merkleProof,
                    mintParameters.merkleRoot,
                    keccak256(abi.encodePacked(mintToWallet))
                )
            ) {
                address vaultWallet = mintOrder.vaultWallet;
                if(vaultWallet == address(0)) {
                    revert InvalidMerkleProof();
                } else {
                    // check delegate for all first as it's more likely than delegate for contract, saves 3200 gas
                    if(!delegateCash.checkDelegateForAll(mintToWallet, vaultWallet)) {
                        if(!delegateCash.checkDelegateForContract(mintToWallet, vaultWallet, address(this))) {
                            revert InvalidMerkleProof();
                        }
                    }
                    if (
                        MerkleProof.verifyCalldata(
                            mintOrder.merkleProof,
                            mintParameters.merkleRoot,
                            keccak256(abi.encodePacked(vaultWallet))
                        )
                    ) {
                        useDelegate = true;
                    } else {
                        revert InvalidMerkleProof();
                    }
                }
            }
        }
        
        if (mintParameters.signatureMaxUses != 0) {
            signatureUseCount[signatureDigest] += mintOrder.quantity;
            if (signatureUseCount[signatureDigest] > mintParameters.signatureMaxUses) {
                revert ExceedsMaxSignatureUsage();
            }
        }

        if(mintParameters.oracleSignatureRequired) {
            oracleSigner = _recoverOracleSigner(mintToWallet, mintParametersSignature, mintOrder.oracleSignature);
            if(oracleSigner == address(0)) {
                revert InvalidOracleSignature();
            }
        }
    }

    /**
     * @notice Iterates over payment tokens and sends payment amounts to recipients. 
     *         If there is a referrer and a payment token has a referralBPS the referral amount is split and sent to the referrer
     *         Payment token types can be native token or ERC20.
     * @param mintOrderQuantity multipier for each payment token
     * @param paymentTokens array of payment tokens for a mint order
     * @param referrer wallet address of user that made the referral for this sale
     */
    function _processPayments(
        uint256 mintOrderQuantity,
        PaymentToken[] calldata paymentTokens,
        address referrer
    ) internal {
        for (uint256 paymentTokenIndex = 0; paymentTokenIndex < paymentTokens.length; ) {
            PaymentToken calldata paymentToken = paymentTokens[paymentTokenIndex];
            uint256 paymentAmount = paymentToken.paymentAmount * mintOrderQuantity;
            uint256 tokenType = paymentToken.tokenType;

            if (tokenType == TOKEN_TYPE_NATIVE) {
                if(referrer == address(0) || paymentToken.referralBPS == 0) {
                    _transferNative(paymentToken.payTo, paymentAmount);
                } else {
                    uint256 referrerPayment = paymentAmount * paymentToken.referralBPS / 10000;
                    _transferNative(referrer, referrerPayment);
                    paymentAmount -= referrerPayment;
                    _transferNative(paymentToken.payTo, paymentAmount);
                }
            } else if (tokenType == TOKEN_TYPE_ERC20) {
                if(referrer == address(0) || paymentToken.referralBPS == 0) {
                    _transferERC20(
                        paymentToken.contractAddress,
                        msg.sender,
                        paymentToken.payTo,
                        paymentAmount
                    );
                } else {
                    uint256 referrerPayment = paymentAmount * paymentToken.referralBPS / 10000;
                    _transferERC20(
                        paymentToken.contractAddress,
                        msg.sender,
                        referrer,
                        referrerPayment
                    );
                    paymentAmount -= referrerPayment;
                    _transferERC20(
                        paymentToken.contractAddress,
                        msg.sender,
                        paymentToken.payTo,
                        paymentAmount
                    );
                }
            } else {
                revert InvalidPaymentTokenType();
            }
            unchecked {
                ++paymentTokenIndex;
            }
        }
    }

    /**
     * @notice Processes burns for a mint order. Burn tokens can be ERC20, ERC721, or ERC1155. Burn types can be
     *         contract burns or send to dead address.
     * @param mintOrderQuantity multiplier for each burn token
     * @param suppliedBurnTokenIdIndex current index for the supplied burn token ids before processing burns
     * @param burnTokens array of burn tokens for a mint order
     * @param suppliedBurnTokenIds array of burn token ids supplied by minter
     * @return suppliedBurnTokenIdIndex current index for the supplied burn token ids after processing burns
     */
    function _processBurns(
        uint256 mintOrderQuantity,
        uint256 suppliedBurnTokenIdIndex,
        BurnToken[] calldata burnTokens,
        uint256[] calldata suppliedBurnTokenIds
    ) internal returns (uint256) {
        for (uint256 burnTokenIndex = 0; burnTokenIndex < burnTokens.length; ) {
            BurnToken calldata burnToken = burnTokens[burnTokenIndex];

            address contractAddress = burnToken.contractAddress;
            uint256 tokenId = burnToken.tokenId;
            bool specificTokenId = burnToken.specificTokenId;
            uint256 burnType = burnToken.burnType;
            uint256 tokenType = burnToken.tokenType;
            uint256 burnAmount = burnToken.burnAmount * mintOrderQuantity;

            if (tokenType == TOKEN_TYPE_ERC1155) {
                uint256 burnTokenEnd = burnTokenIndex;
                for (; burnTokenEnd < burnTokens.length; ) {
                    if (burnTokens[burnTokenEnd].contractAddress != contractAddress) {
                        break;
                    }
                    unchecked {
                        ++burnTokenEnd;
                    }
                }
                unchecked { --burnTokenEnd; }
                if (burnTokenEnd == burnTokenIndex) {
                    if (specificTokenId) {
                        if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                            revert InvalidBurnTokenId();
                        }
                    }
                    if (burnType == BURN_TYPE_CONTRACT_BURN) {
                        ILayerr1155(contractAddress).burnTokenId(
                            msg.sender,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex],
                            burnAmount
                        );
                    } else if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                        IERC1155(contractAddress).safeTransferFrom(
                            msg.sender,
                            DEAD_ADDRESS,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex],
                            burnAmount,
                            ""
                        );
                    } else {
                        revert InvalidBurnType();
                    }
                    unchecked {
                        ++suppliedBurnTokenIdIndex;
                    }
                } else {
                    unchecked {
                        ++burnTokenEnd;
                    }
                    uint256[] memory burnTokenIds = new uint256[]((burnTokenEnd - burnTokenIndex));
                    uint256[] memory burnTokenAmounts = new uint256[]((burnTokenEnd - burnTokenIndex));
                    for (uint256 arrayIndex = 0; burnTokenIndex < burnTokenEnd; ) {
                        burnToken = burnTokens[burnTokenIndex];
                        specificTokenId = burnToken.specificTokenId;
                        tokenId = burnToken.tokenId;
                        burnAmount = burnToken.burnAmount * mintOrderQuantity;

                        if (specificTokenId) {
                            if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                                revert InvalidBurnTokenId();
                            }
                        }

                        burnTokenIds[arrayIndex] = suppliedBurnTokenIds[suppliedBurnTokenIdIndex];
                        burnTokenAmounts[arrayIndex] = burnAmount;
                        unchecked {
                            ++burnTokenIndex;
                            ++arrayIndex;
                            ++suppliedBurnTokenIdIndex;
                        }
                    }
                    unchecked {
                        --burnTokenIndex;
                    }
                    if (burnType == BURN_TYPE_CONTRACT_BURN) {
                        ILayerr1155(contractAddress).burnBatchTokenIds(
                            msg.sender,
                            burnTokenIds,
                            burnTokenAmounts
                        );
                    } else if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                        IERC1155(contractAddress).safeBatchTransferFrom(
                            msg.sender,
                            DEAD_ADDRESS,
                            burnTokenIds,
                            burnTokenAmounts,
                            ""
                        );
                    } else {
                        revert InvalidBurnType();
                    }
                }
            } else if (tokenType == TOKEN_TYPE_ERC721) {
                if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                    if (burnAmount > 1) {
                        if (specificTokenId) {
                            revert CannotBurnMultipleERC721WithSameId();
                        }
                        for (uint256 burnCounter = 0; burnCounter < burnAmount; ) {
                            IERC721(contractAddress).transferFrom(
                                msg.sender,
                                DEAD_ADDRESS,
                                suppliedBurnTokenIds[suppliedBurnTokenIdIndex]
                            );
                            unchecked {
                                ++burnCounter;
                                ++suppliedBurnTokenIdIndex;
                            }
                        }
                    } else {
                        if (specificTokenId) {
                            if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                                revert InvalidBurnTokenId();
                            }
                        }
                        IERC721(contractAddress).transferFrom(
                            msg.sender,
                            DEAD_ADDRESS,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex]
                        );
                        unchecked {
                            ++suppliedBurnTokenIdIndex;
                        }
                    }
                } else if (burnType == BURN_TYPE_CONTRACT_BURN) {
                    if (burnAmount > 1) {
                        if (specificTokenId) {
                            revert CannotBurnMultipleERC721WithSameId();
                        }
                        uint256[] memory burnTokenIds = new uint256[](burnAmount);
                        for (uint256 arrayIndex = 0; arrayIndex < burnAmount;) {
                            burnTokenIds[arrayIndex] = suppliedBurnTokenIds[suppliedBurnTokenIdIndex];
                            unchecked {
                                ++arrayIndex;
                                ++suppliedBurnTokenIdIndex;
                            }
                        }
                        ILayerr721(contractAddress).burnBatchTokenIds(msg.sender, burnTokenIds);
                    } else {
                        if (specificTokenId) {
                            if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                                revert InvalidBurnTokenId();
                            }
                        }
                        ILayerr721(contractAddress).burnTokenId(
                            msg.sender,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex]
                        );
                        unchecked {
                            ++suppliedBurnTokenIdIndex;
                        }
                    }
                } else {
                    revert InvalidBurnType();
                }
            } else if (tokenType == TOKEN_TYPE_ERC20) {
                if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                    _transferERC20(
                        contractAddress,
                        msg.sender,
                        DEAD_ADDRESS,
                        burnAmount
                    );
                } else if (burnType == BURN_TYPE_CONTRACT_BURN) {
                    ILayerr20(contractAddress).burn(msg.sender, burnAmount);
                } else {
                    revert InvalidBurnType();
                }
            } else {
                revert InvalidBurnTokenType();
            }
            unchecked {
                ++burnTokenIndex;
            }
        }

        return suppliedBurnTokenIdIndex;
    }

    /**
     * @notice Processes mints for a mint order. Token types can be ERC20, ERC721, or ERC1155. 
     * @param mintTokens array of mint tokens from the mint order
     * @param mintParametersSigner recovered address from the mint parameters signature
     * @param mintParametersDigest hash digest of the supplied mint parameters
     * @param oracleSigner recovered address of the oracle signer if oracle signature required was true, address(0) otherwise
     * @param mintOrderQuantity multiplier for each mint token
     * @param mintCountWallet wallet address that will be used for checking max per wallet mint conditions
     * @param mintToWallet wallet address that tokens will be minted to
     */
    function _processMints(
        MintToken[] calldata mintTokens,
        address mintParametersSigner,
        bytes32 mintParametersDigest,
        address oracleSigner,
        uint256 mintOrderQuantity,
        address mintCountWallet,
        address mintToWallet
    ) internal {
        uint256 mintTokenIndex;
        uint256 mintTokensLength = mintTokens.length;
        for ( ; mintTokenIndex < mintTokensLength; ) {
            MintToken calldata mintToken = mintTokens[mintTokenIndex];

            address contractAddress = mintToken.contractAddress;
            _checkContractSigners(contractAddress, mintParametersSigner, mintParametersDigest, oracleSigner);

            uint256 tokenId = mintToken.tokenId;
            uint256 maxSupply = mintToken.maxSupply;
            uint256 maxMintPerWallet = mintToken.maxMintPerWallet;
            bool specificTokenId = mintToken.specificTokenId;
            uint256 mintAmount = mintToken.mintAmount * mintOrderQuantity;
            uint256 tokenType = mintToken.tokenType;

            if (tokenType == TOKEN_TYPE_ERC1155) {
                uint256 mintTokenEnd = mintTokenIndex;
                for (; mintTokenEnd < mintTokensLength; ) {
                    if (mintTokens[mintTokenEnd].contractAddress != contractAddress) {
                        break;
                    }
                    unchecked {
                        ++mintTokenEnd;
                    }
                }
                unchecked { --mintTokenEnd; }
                if (mintTokenEnd == mintTokenIndex) {
                    _checkERC1155MintQuantities(contractAddress, tokenId, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);

                    ILayerr1155(contractAddress).mintTokenId(
                        mintCountWallet,
                        mintToWallet,
                        tokenId,
                        mintAmount
                    );
                } else {
                    unchecked {
                        ++mintTokenEnd;
                    }
                    uint256[] memory mintTokenIds = new uint256[]((mintTokenEnd - mintTokenIndex));
                    uint256[] memory mintTokenAmounts = new uint256[]((mintTokenEnd - mintTokenIndex));
                    for (uint256 arrayIndex = 0; mintTokenIndex < mintTokenEnd; ) {
                        mintToken = mintTokens[mintTokenIndex];
                        maxSupply = mintToken.maxSupply;
                        maxMintPerWallet = mintToken.maxMintPerWallet;
                        tokenId = mintToken.tokenId;
                        mintAmount = mintToken.mintAmount * mintOrderQuantity;

                        _checkERC1155MintQuantities(contractAddress, tokenId, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);

                        mintTokenIds[arrayIndex] = tokenId;
                        mintTokenAmounts[arrayIndex] = mintAmount;
                        unchecked {
                            ++mintTokenIndex;
                            ++arrayIndex;
                        }
                    }
                    unchecked {
                        --mintTokenIndex;
                    }
                    ILayerr1155(contractAddress)
                        .mintBatchTokenIds(
                            mintCountWallet,
                            mintToWallet,
                            mintTokenIds,
                            mintTokenAmounts
                        );
                }
            } else if (tokenType == TOKEN_TYPE_ERC721) {
                _checkERC721MintQuantities(contractAddress, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);

                if (!specificTokenId || mintAmount > 1) {
                    if (specificTokenId) {
                        revert CannotMintMultipleERC721WithSameId();
                    }
                    ILayerr721A(contractAddress).mintSequential(mintCountWallet, mintToWallet, mintAmount);
                } else {
                    ILayerr721(contractAddress).mintTokenId(mintCountWallet, mintToWallet, tokenId);
                }
            } else if (tokenType == TOKEN_TYPE_ERC20) {
                _checkERC20MintQuantities(contractAddress, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);
                ILayerr20(contractAddress).mint(mintCountWallet, mintToWallet, mintAmount);
            } else {
                revert InvalidMintTokenType();
            }
            unchecked {
                ++mintTokenIndex;
            }
        }
    }

    /**
     * @notice Checks the mint parameters and oracle signers to ensure they are authorized for the token contract.
     *         Checks that the mint parameters signature digest has not been marked as invalid.
     * @param contractAddress token contract to check signers for
     * @param mintParametersSigner recovered signer for the mint parameters
     * @param mintParametersDigest hash digest of the supplied mint parameters 
     * @param oracleSigner recovered oracle signer if oracle signature is required by mint parameters
     */
    function _checkContractSigners(address contractAddress, address mintParametersSigner, bytes32 mintParametersDigest, address oracleSigner) internal view {
        if (!contractAllowedSigner[contractAddress][mintParametersSigner]) {
            revert NotAllowedSigner();
        }
        if (signatureInvalid[contractAddress][mintParametersDigest]) {
            revert SignatureInvalid();
        }
        if(oracleSigner != address(0)) {
            if(!contractAllowedOracle[contractAddress][oracleSigner]) {
                revert InvalidOracleSignature();
            }
        }
    }

    /**
     * @notice Calls the token contract to get total minted and minted by wallet, checks against mint parameters max supply and max per wallet
     * @param contractAddress token contract to check mint counts for
     * @param tokenId id of the token to check
     * @param maxSupply maximum supply for a token defined in mint parameters
     * @param maxMintPerWallet maximum per wallet for a token defined in mint parameters
     * @param mintCountWallet wallet to check for minted amount
     * @param mintAmount the amount that will be minted
     */
    function _checkERC1155MintQuantities(address contractAddress, uint256 tokenId, uint256 maxSupply, uint256 maxMintPerWallet, address mintCountWallet, uint256 mintAmount) internal view {
        if(maxSupply != 0 || maxMintPerWallet != 0) {
            (uint256 totalMinted, uint256 minterMinted) = ILayerr1155(contractAddress).totalMintedCollectionAndMinter(mintCountWallet, tokenId);
            if (maxSupply != 0) {
                if (totalMinted + mintAmount > maxSupply) {
                    revert MintExceedsMaxSupply();
                }
            }
            if (maxMintPerWallet != 0) {
                if (minterMinted + mintAmount > maxMintPerWallet) {
                    revert MintExceedsMaxPerWallet();
                }
            }
        }
    }


    /**
     * @notice Calls the token contract to get total minted and minted by wallet, checks against mint parameters max supply and max per wallet
     * @param contractAddress token contract to check mint counts for
     * @param maxSupply maximum supply for a token defined in mint parameters
     * @param maxMintPerWallet maximum per wallet for a token defined in mint parameters
     * @param mintCountWallet wallet to check for minted amount
     * @param mintAmount the amount that will be minted
     */
    function _checkERC721MintQuantities(address contractAddress, uint256 maxSupply, uint256 maxMintPerWallet, address mintCountWallet, uint256 mintAmount) internal view {
        if(maxSupply != 0 || maxMintPerWallet != 0) {
            (uint256 totalMinted, uint256 minterMinted) = ILayerr721(contractAddress).totalMintedCollectionAndMinter(mintCountWallet);
            if (maxSupply != 0) {
                if (totalMinted + mintAmount > maxSupply) {
                    revert MintExceedsMaxSupply();
                }
            }
            if (maxMintPerWallet != 0) {
                if (minterMinted + mintAmount > maxMintPerWallet) {
                    revert MintExceedsMaxPerWallet();
                }
            }
        }
    }


    /**
     * @notice Calls the token contract to get total minted and minted by wallet, checks against mint parameters max supply and max per wallet
     * @param contractAddress token contract to check mint counts for
     * @param maxSupply maximum supply for a token defined in mint parameters
     * @param maxMintPerWallet maximum per wallet for a token defined in mint parameters
     * @param mintCountWallet wallet to check for minted amount
     * @param mintAmount the amount that will be minted
     */
    function _checkERC20MintQuantities(address contractAddress, uint256 maxSupply, uint256 maxMintPerWallet, address mintCountWallet, uint256 mintAmount) internal view {
        if(maxSupply != 0 || maxMintPerWallet != 0) {
            (uint256 totalMinted, uint256 minterMinted) = ILayerr20(contractAddress).totalMintedTokenAndMinter(mintCountWallet);
            if (maxSupply != 0) {
                if (totalMinted + mintAmount > maxSupply) {
                    revert MintExceedsMaxSupply();
                }
            }
            if (maxMintPerWallet != 0) {
                if (minterMinted + mintAmount > maxMintPerWallet) {
                    revert MintExceedsMaxPerWallet();
                }
            }
        }
    }

    /**
     * @notice Transfers `amount` of native token to `to` address. Reverts if the transfer fails.
     * @param to address to send native token to
     * @param amount amount of native token to send
     */
    function _transferNative(address to, uint256 amount) internal {
        (bool sent, ) = payable(to).call{value: amount}("");
        if (!sent) {
            if(address(this).balance < amount) {
                revert InsufficientPayment();
            } else {
                revert PaymentFailed();
            }
        }
    }

    /**
     * @notice Transfers `amount` of ERC20 token from `from` address to `to` address.
     * @param contractAddress ERC20 token address
     * @param from address to transfer ERC20 tokens from
     * @param to address to send ERC20 tokens to
     * @param amount amount of ERC20 tokens to send
     */
    function _transferERC20(
        address contractAddress,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20(contractAddress).transferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {StringValue} from "./lib/StorageTypes.sol";
import {AddressValue} from "./lib/StorageTypes.sol";
import {ILayerrMinter} from "./interfaces/ILayerrMinter.sol";
import {LAYERROWNABLE_OWNER_SLOT, LAYERRTOKEN_NAME_SLOT, LAYERRTOKEN_SYMBOL_SLOT, LAYERRTOKEN_RENDERER_SLOT} from "./common/LayerrStorage.sol";

/**
 * @title LayerrProxy
 * @author 0xth0mas (Layerr)
 * @notice A proxy contract that serves as an interface for interacting with 
 *         Layerr tokens. At deployment it sets token properties and contract 
 *         ownership, initializes signers and mint extensions, and configures 
 *         royalties.
 */
contract LayerrProxy {

    /// @dev the implementation address for the proxy contract
    address immutable proxy;

    /// @dev Thrown when a required initialization call fails
    error DeploymentFailed();

    /**
     * @notice Initializes the proxy contract
     * @param _proxy implementation address for the proxy contract
     * @param _name token contract name
     * @param _symbol token contract symbol
     * @param royaltyPct default royalty percentage in BPS
     * @param royaltyReceiver default royalty receiver
     * @param operatorFilterRegistry address of the operator filter registry to subscribe to
     * @param _extension minting extension to use with the token contract
     * @param _renderer renderer to use with the token contract
     * @param _signers array of allowed signers for the mint extension
     */
    constructor(
        address _proxy, 
        string memory _name, 
        string memory _symbol, 
        uint96 royaltyPct, 
        address royaltyReceiver, 
        address operatorFilterRegistry, 
        address _extension, 
        address _renderer, 
        address[] memory _signers
    ) {
        proxy = _proxy; 

        StringValue storage name;
        StringValue storage symbol;
        AddressValue storage renderer;
        AddressValue storage owner;
        /// @solidity memory-safe-assembly
        assembly {
            name.slot := LAYERRTOKEN_NAME_SLOT
            symbol.slot := LAYERRTOKEN_SYMBOL_SLOT
            renderer.slot := LAYERRTOKEN_RENDERER_SLOT
            owner.slot := LAYERROWNABLE_OWNER_SLOT
        } 
        name.value = _name;
        symbol.value = _symbol;
        renderer.value = _renderer;
        owner.value = tx.origin;

        uint256 signersLength = _signers.length;
        for(uint256 signerIndex;signerIndex < signersLength;) {
            ILayerrMinter(_extension).setContractAllowedSigner(_signers[signerIndex], true);
            unchecked {
                ++signerIndex;
            }
        }

        (bool success, ) = _proxy.delegatecall(abi.encodeWithSignature("setRoyalty(uint96,address)", royaltyPct, royaltyReceiver));
        if(!success) revert DeploymentFailed();

        (success, ) = _proxy.delegatecall(abi.encodeWithSignature("setOperatorFilter(address)", operatorFilterRegistry));
        //this item may fail if deploying a contract that does not use an operator filter

        (success, ) = _proxy.delegatecall(abi.encodeWithSignature("setMintExtension(address,bool)", _extension, true));
        if(!success) revert DeploymentFailed();

        (success, ) = _proxy.delegatecall(abi.encodeWithSignature("initialize()"));
        if(!success) revert DeploymentFailed();
    }

    fallback() external payable {
        address _proxy = proxy;
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), _proxy, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {ILayerrRenderer} from "./interfaces/ILayerrRenderer.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";

/**
 * @title LayerrRenderer
 * @author 0xth0mas (Layerr)
 * @notice LayerrRenderer handles contractURI and tokenURI generation for contracts
 *         deployed on the Layerr platform. Contract owners have complete control of 
 *         their tokens with the ability to set their own renderer, host their tokens
 *         with Layerr, set all tokens to a prereveal image, or set a base URI that
 *         token ids will be appended to.
 *         Tokens hosted with Layerr will automatically generate a tokenURI with the
 *         `layerrBaseTokenUri`{chainId}/{contractAddress}/{tokenId} to allow new tokens
 *         to be minted without updating a base uri.
 *         For long term storage, Layerr-hosted tokens can be swept onto Layerr's IPFS
 *         solution.
 */
contract LayerrRenderer is ILayerrRenderer {

    /// @dev Layerr-owned EOA that is allowed to update the base token and base contract URIs for Layerr-hosted non-IPFS tokens
    address public owner;

    /// @dev Layerr's signature account for checking parameters of tokens swept to Layerr IPFS
    address public layerrSigner;

    /// @dev The base token URI that chainId, contractAddress and tokenId are added to for rendering
    string public layerrBaseTokenUri = 'https://metadata.layerr.art/';

    /// @dev The base contract URI that chainId and contractAddress are added to for rendering
    string public layerrBaseContractUri = 'https://contract-metadata.layerr.art/';

    /// @dev The rendering type for a token contract, defaults to LAYERR_HOSTED
    mapping(address => RenderType) public contractRenderType;

    /// @dev Base token URI set by the token contract owner for BASE_PLUS_TOKEN render type and LAYERR_HOSTED tokens on IPFS
    mapping(address => string) public contractBaseTokenUri;

    /// @dev Token contract URI set by the token contract owner
    mapping(address => string) public contractContractUri;

    /// @dev mapping of token contract addresses that flag a token contract as having all of its tokens hosted on Layerr IPFS
    mapping(address => bool) public layerrHostedAllTokensOnIPFS;

    /// @dev bitmap of token ids for a token contract that have been moved to Layerr hosted IPFS
    mapping(address => mapping(uint256 => uint256)) public layerrHostedTokensOnIPFS;

    /// @dev mapping of token contract addresses with the UTC timestamp of when the IPFS hosting is paid through
    mapping(address => uint256) public layerrHostedIPFSExpiration;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotContractOwner();
        }
        _;
    }

    constructor() {
        owner = tx.origin; //TODO: Need a Layerr ownership account, ideally multisig that could be deployed on all EVM chains at same address
    }

    /**
     * @inheritdoc ILayerrRenderer
     */
    function tokenURI(
        address contractAddress,
        uint256 tokenId
    ) external view returns (string memory _tokenURI) {
        RenderType renderType = contractRenderType[contractAddress];
        if (renderType == RenderType.LAYERR_HOSTED) {
            if(_isLayerrHostedIPFS(contractAddress, tokenId)) {
                _tokenURI = string(
                    abi.encodePacked(contractBaseTokenUri[contractAddress], _toString(tokenId))
                );
            } else {
                _tokenURI = string(
                    abi.encodePacked(
                        layerrBaseTokenUri,
                        "/",
                        _toString(block.chainid),
                        "/",
                        _toString(contractAddress),
                        "/",
                        _toString(tokenId)
                    )
                );
            }
        } else if (renderType == RenderType.PREREVEAL) {
            _tokenURI = contractBaseTokenUri[contractAddress];
        } else if (renderType == RenderType.BASE_PLUS_TOKEN) {
            _tokenURI = string(
                abi.encodePacked(contractBaseTokenUri[contractAddress], _toString(tokenId))
            );
        }
    }

    /**
     * @inheritdoc ILayerrRenderer
     */
    function contractURI(
        address contractAddress
    ) external view returns (string memory _contractURI) {
        _contractURI = contractContractUri[contractAddress];
        if (bytes(_contractURI).length == 0) {
            _contractURI = string(
                abi.encodePacked(
                    layerrBaseContractUri,
                    "/",
                    _toString(block.chainid),
                    "/",
                    _toString(contractAddress)
                )
            );
        }
    }

    /**
     * @notice Updates rendering settings for a contract. Must be the ERC173 owner for the token contract to call.
     * @param contractAddress address of the contract to set the base token URI for
     * @param baseTokenUri base token URI to set for `contractAddress`
     * @param renderType sets the current render type for the contract
     */
    function setContractBaseTokenUri(
        address contractAddress,
        string calldata baseTokenUri,
        RenderType renderType
    ) external {
        if (IOwnable(contractAddress).owner() != msg.sender) {
            revert NotContractOwner();
        }
        contractBaseTokenUri[contractAddress] = baseTokenUri;
        contractRenderType[contractAddress] = renderType;
    }

    /**
     * @notice Updates rendering settings for a contract. Must be the ERC173 owner for the token contract to call.
     * @param contractAddress address of the contract to set the base token URI for
     * @param contractUri contract URI to set for `contractAddress`
     */
    function setContractUri(
        address contractAddress,
        string calldata contractUri
    ) external {
        if (IOwnable(contractAddress).owner() != msg.sender) {
            revert NotContractOwner();
        }
        contractContractUri[contractAddress] = contractUri;
    }

    /**
     * @notice Updates the base token URI to sweep tokens to IPFS for Layerr hosted tokens
     *         This allows new tokens to continue to be minted on the contract with the default
     *         rendering address while existing tokens are moved onto IPFS for long term storage.
     * @param contractAddress address of the token contract
     * @param baseTokenUri base token URI to set for the contract's tokens
     * @param allTokens set to true for larger collections that are done minting
     *                  avoids setting each token id in the bitmap for gas savings but new tokens
     *                  will not render with the default rendering address
     * @param tokenIds array of token ids that are being swept to Layerr hosted IPFS
     * @param ipfsExpiration UTC timestamp that the IPFS hosting is paid through
     * @param signature signature by Layerr account to confirm the parameters supplied
     */
    function setContractBaseTokenUriForLayerrHostedIPFS(
        address contractAddress,
        string calldata baseTokenUri,
        bool allTokens,
        uint256[] calldata tokenIds,
        uint256 ipfsExpiration,
        bytes calldata signature
    ) external payable {
        if (IOwnable(contractAddress).owner() != msg.sender) {
            revert NotContractOwner();
        }

        bytes32 hash = keccak256(abi.encodePacked(contractAddress, baseTokenUri, ipfsExpiration, msg.value));
        address signer = _recover(hash, signature);
        if(signer != layerrSigner) revert InvalidSignature();

        (bool sent, ) = payable(owner).call{value: msg.value}("");
        if (!sent) {
            revert PaymentFailed();
        }

        layerrHostedIPFSExpiration[contractAddress] = ipfsExpiration;
        layerrHostedAllTokensOnIPFS[contractAddress] = allTokens;
        contractBaseTokenUri[contractAddress] = baseTokenUri;
        contractRenderType[contractAddress] = RenderType.LAYERR_HOSTED;

        for(uint256 i = 0;i < tokenIds.length;) {
            _setLayerrHostedIPFS(contractAddress, tokenIds[i]);
            unchecked { ++i; }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ILayerrRenderer).interfaceId;
    }

    /* OWNER FUNCTIONS */
    
    /**
     * @notice Owner function to set the Layerr signature account
     * @param _layerrSigner address that will be used to check signatures
     */
    function setLayerrSigner(
        address _layerrSigner
    ) external onlyOwner {
        layerrSigner = _layerrSigner;
    }

    /**
     * @notice Owner function to set the default token rendering URI
     * @param _layerrBaseTokenUri base token uri to be used for default token rendering
     */
    function setLayerrBaseTokenUri(
        string calldata _layerrBaseTokenUri
    ) external onlyOwner {
        layerrBaseTokenUri = _layerrBaseTokenUri;
    }

    /**
     * @notice Owner function to set the default contract rendering URI
     * @param _layerrBaseContractUri base contract uri to be used for default rendering
     */

    function setLayerrBaseContractUri(
        string calldata _layerrBaseContractUri
    ) external onlyOwner {
        layerrBaseContractUri = _layerrBaseContractUri;
    }

    /* INTERNAL FUNCTIONS */

    /**
     * @notice Checks to see if a token has been flagged as being hosted on Layerr IPFS
     * @param contractAddress token contract address to check
     * @param tokenId id of the token to check
     * @return isIPFS if token has been flagged as being hosted on Layerr IPFS
     */
    function _isLayerrHostedIPFS(address contractAddress, uint256 tokenId) internal view returns(bool isIPFS) {
        isIPFS = layerrHostedAllTokensOnIPFS[contractAddress] || layerrHostedTokensOnIPFS[contractAddress][tokenId >> 8] & (1 << (tokenId & 0xFF)) != 0;
    }

    /**
     * @notice Flags a token as being hosted on Layerr IPFS in a bitmap
     * @param contractAddress token contract address
     * @param tokenId id of the token
     */
    function _setLayerrHostedIPFS(address contractAddress, uint256 tokenId) internal {
        layerrHostedTokensOnIPFS[contractAddress][tokenId >> 8] |= (1 << (tokenId & 0xFF));
    }

    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            str := sub(m, 0x20)
            mstore(str, 0)
            let end := str

            for { let temp := value } 1 {} {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }

    function _toString(address value) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; ) {
            bytes1 b = bytes1(uint8(uint(uint160(value)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);
            unchecked { ++i; }
        }
        return string(s);
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function _recover(
        bytes32 hash,
        bytes calldata sig
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        /// @solidity memory-safe-assembly
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Burn type that specifies the token will be burned with a contract call that reduces supply
uint256 constant BURN_TYPE_CONTRACT_BURN = 0;
/// @dev Burn type that specifies the token will be transferred to the 0x000...dead address without reducing supply
uint256 constant BURN_TYPE_SEND_TO_DEAD = 1;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple ERC2981 NFT Royalty Standard implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC2981.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/common/ERC2981.sol)
abstract contract ERC2981 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The royalty fee numerator exceeds the fee denominator.
    error RoyaltyOverflow();

    /// @dev The royalty receiver cannot be the zero address.
    error RoyaltyReceiverIsZeroAddress();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The default royalty info is given by:
    /// ```
    ///     let packed := sload(_ERC2981_MASTER_SLOT_SEED)
    ///     let receiver := shr(96, packed)
    ///     let royaltyFraction := xor(packed, shl(96, receiver))
    /// ```
    ///
    /// The per token royalty info is given by.
    /// ```
    ///     mstore(0x00, tokenId)
    ///     mstore(0x20, _ERC2981_MASTER_SLOT_SEED)
    ///     let packed := sload(keccak256(0x00, 0x40))
    ///     let receiver := shr(96, packed)
    ///     let royaltyFraction := xor(packed, shl(96, receiver))
    /// ```
    uint256 private constant _ERC2981_MASTER_SLOT_SEED = 0xaa4ec00224afccfdb7;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERC2981                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Checks that `_feeDenominator` is non-zero.
    constructor() {
        require(_feeDenominator() != 0, "Fee denominator cannot be zero.");
    }

    /// @dev Returns the denominator for the royalty amount.
    /// Defaults to 10000, which represents fees in basis points.
    /// Override this function to return a custom amount if needed.
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`.
    /// See: https://eips.ethereum.org/EIPS/eip-165
    /// This function call must use less than 30000 gas.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC2981: 0x2a55205a.
            result := or(eq(s, 0x01ffc9a7), eq(s, 0x2a55205a))
        }
    }

    /// @dev Returns the `receiver` and `royaltyAmount` for `tokenId` sold at `salePrice`.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 feeDenominator = _feeDenominator();
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, _ERC2981_MASTER_SLOT_SEED)
            let packed := sload(keccak256(0x00, 0x40))
            receiver := shr(96, packed)
            if iszero(receiver) {
                packed := sload(mload(0x20))
                receiver := shr(96, packed)
            }
            let x := salePrice
            let y := xor(packed, shl(96, receiver)) // `feeNumerator`.
            // Overflow check, equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            // Out-of-gas revert. Should not be triggered in practice, but included for safety.
            returndatacopy(returndatasize(), returndatasize(), mul(y, gt(x, div(not(0), y))))
            royaltyAmount := div(mul(x, y), feeDenominator)
        }
    }

    /// @dev Sets the default royalty `receiver` and `feeNumerator`.
    ///
    /// Requirements:
    /// - `receiver` must not be the zero address.
    /// - `feeNumerator` must not be greater than the fee denominator.
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        uint256 feeDenominator = _feeDenominator();
        /// @solidity memory-safe-assembly
        assembly {
            feeNumerator := shr(160, shl(160, feeNumerator))
            if gt(feeNumerator, feeDenominator) {
                mstore(0x00, 0x350a88b3) // `RoyaltyOverflow()`.
                revert(0x1c, 0x04)
            }
            let packed := shl(96, receiver)
            if iszero(packed) {
                mstore(0x00, 0xb4457eaa) // `RoyaltyReceiverIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
            sstore(_ERC2981_MASTER_SLOT_SEED, or(packed, feeNumerator))
        }
    }

    /// @dev Sets the default royalty `receiver` and `feeNumerator` to zero.
    function _deleteDefaultRoyalty() internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(_ERC2981_MASTER_SLOT_SEED, 0)
        }
    }

    /// @dev Sets the royalty `receiver` and `feeNumerator` for `tokenId`.
    ///
    /// Requirements:
    /// - `receiver` must not be the zero address.
    /// - `feeNumerator` must not be greater than the fee denominator.
    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator)
        internal
        virtual
    {
        uint256 feeDenominator = _feeDenominator();
        /// @solidity memory-safe-assembly
        assembly {
            feeNumerator := shr(160, shl(160, feeNumerator))
            if gt(feeNumerator, feeDenominator) {
                mstore(0x00, 0x350a88b3) // `RoyaltyOverflow()`.
                revert(0x1c, 0x04)
            }
            let packed := shl(96, receiver)
            if iszero(packed) {
                mstore(0x00, 0xb4457eaa) // `RoyaltyReceiverIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, tokenId)
            mstore(0x20, _ERC2981_MASTER_SLOT_SEED)
            sstore(keccak256(0x00, 0x40), or(packed, feeNumerator))
        }
    }

    /// @dev Sets the royalty `receiver` and `feeNumerator` for `tokenId` to zero.
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, _ERC2981_MASTER_SLOT_SEED)
            sstore(keccak256(0x00, 0x40), 0)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProof {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            MERKLE PROOF VERIFICATION OPERATIONS            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf)
        internal
        pure
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(proof) {
                // Initialize `offset` to the offset of `proof` elements in memory.
                let offset := add(proof, 0x20)
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(offset, shl(5, mload(proof)))
                // Iterate over proof elements to compute root hash.
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, mload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), mload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf)
        internal
        pure
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(proof.offset, shl(5, proof.length))
                // Initialize `offset` to the offset of `proof` in the calldata.
                let offset := proof.offset
                // Iterate over proof elements to compute root hash.
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, calldataload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), calldataload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether all `leaves` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    function verifyMultiProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32[] memory leaves,
        bool[] memory flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leaves` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the lengths of the arrays.
            let leavesLength := mload(leaves)
            let proofLength := mload(proof)
            let flagsLength := mload(flags)

            // Advance the pointers of the arrays to point to the data.
            leaves := add(0x20, leaves)
            proof := add(0x20, proof)
            flags := add(0x20, flags)

            // If the number of flags is correct.
            for {} eq(add(leavesLength, proofLength), add(flagsLength, 1)) {} {
                // For the case where `proof.length + leaves.length == 1`.
                if iszero(flagsLength) {
                    // `isValid = (proof.length == 1 ? proof[0] : leaves[0]) == root`.
                    isValid := eq(mload(xor(leaves, mul(xor(proof, leaves), proofLength))), root)
                    break
                }

                // The required final proof offset if `flagsLength` is not zero, otherwise zero.
                let proofEnd := mul(iszero(iszero(flagsLength)), add(proof, shl(5, proofLength)))
                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leaves into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                leavesLength := shl(5, leavesLength)
                for { let i := 0 } iszero(eq(i, leavesLength)) { i := add(i, 0x20) } {
                    mstore(add(hashesFront, i), mload(add(leaves, i)))
                }
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, leavesLength)
                // This is the end of the memory for the queue.
                // We recycle `flagsLength` to save on stack variables (sometimes save gas).
                flagsLength := add(hashesBack, shl(5, flagsLength))

                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(mload(flags)) {
                        // Loads the next proof.
                        b := mload(proof)
                        proof := add(proof, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }

                    // Advance to the next flag.
                    flags := add(flags, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    if iszero(lt(hashesBack, flagsLength)) { break }
                }
                isValid :=
                    and(
                        // Checks if the last value in the queue is same as the root.
                        eq(mload(sub(hashesBack, 0x20)), root),
                        // And whether all the proofs are used, if required (i.e. `proofEnd != 0`).
                        or(iszero(proofEnd), eq(proofEnd, proof))
                    )
                break
            }
        }
    }

    /// @dev Returns whether all `leaves` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    function verifyMultiProofCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leaves,
        bool[] calldata flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leaves` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        /// @solidity memory-safe-assembly
        assembly {
            // If the number of flags is correct.
            for {} eq(add(leaves.length, proof.length), add(flags.length, 1)) {} {
                // For the case where `proof.length + leaves.length == 1`.
                if iszero(flags.length) {
                    // `isValid = (proof.length == 1 ? proof[0] : leaves[0]) == root`.
                    // forgefmt: disable-next-item
                    isValid := eq(
                        calldataload(
                            xor(leaves.offset, mul(xor(proof.offset, leaves.offset), proof.length))
                        ),
                        root
                    )
                    break
                }

                // The required final proof offset if `flagsLength` is not zero, otherwise zero.
                let proofEnd :=
                    mul(iszero(iszero(flags.length)), add(proof.offset, shl(5, proof.length)))
                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leaves into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                calldatacopy(hashesFront, leaves.offset, shl(5, leaves.length))
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, shl(5, leaves.length))
                // This is the end of the memory for the queue.
                // We recycle `flagsLength` to save on stack variables (sometimes save gas).
                flags.length := add(hashesBack, shl(5, flags.length))

                // We don't need to make a copy of `proof.offset` or `flags.offset`,
                // as they are pass-by-value (this trick may not always save gas).

                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(calldataload(flags.offset)) {
                        // Loads the next proof.
                        b := calldataload(proof.offset)
                        proof.offset := add(proof.offset, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }

                    // Advance to the next flag offset.
                    flags.offset := add(flags.offset, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    if iszero(lt(hashesBack, flags.length)) { break }
                }
                isValid :=
                    and(
                        // Checks if the last value in the queue is same as the root.
                        eq(mload(sub(hashesBack, 0x20)), root),
                        // And whether all the proofs are used, if required (i.e. `proofEnd != 0`).
                        or(iszero(proofEnd), eq(proofEnd, proof.offset))
                    )
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes32 array.
    function emptyProof() internal pure returns (bytes32[] calldata proof) {
        /// @solidity memory-safe-assembly
        assembly {
            proof.length := 0
        }
    }

    /// @dev Returns an empty calldata bytes32 array.
    function emptyLeaves() internal pure returns (bytes32[] calldata leaves) {
        /// @solidity memory-safe-assembly
        assembly {
            leaves.length := 0
        }
    }

    /// @dev Returns an empty calldata bool array.
    function emptyFlags() internal pure returns (bool[] calldata flags) {
        /// @solidity memory-safe-assembly
        assembly {
            flags.length := 0
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/**
 * @dev EIP712 Domain for signature verification
 */
struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

/**
 * @dev MintOrders contain MintParameters as defined by a token creator
 *      along with proofs required to validate the MintParameters and 
 *      parameters specific to the mint being performed.
 * 
 *      `mintParameters` are the parameters signed by the token creator
 *      `quantity` is a multiplier for mintTokens, burnTokens and paymentTokens
 *          defined in mintParameters
 *      `mintParametersSignature` is the signature from the token creator
 *      `oracleSignature` is a signature of the hash of the mintParameters digest 
 *          and msg.sender. The recovered signer must be an allowed oracle for 
 *          the token contract if oracleSignatureRequired is true for mintParameters.
 *      `merkleProof` is the proof that is checked if merkleRoot is not bytes(0) in
 *          mintParameters
 *      `suppliedBurnTokenIds` is an array of tokenIds to be used when processing
 *          burnTokens. There must be one item in the array for each ERC1155 burnToken
 *          regardless of `quantity` and `quantity` items in the array for each ERC721
 *          burnToken.
 *      `referrer` is the address that will receive a portion of a paymentToken if
 *          not address(0) and paymentToken's referralBPS is greater than 0
 *      `vaultWallet` is used for allowlist mints if the msg.sender address it not on
 *          the allowlist but their delegate.cash vault wallet is.
 *      
 */
struct MintOrder {
    MintParameters mintParameters;
    uint256 quantity;
    bytes mintParametersSignature;
    bytes oracleSignature;
    bytes32[] merkleProof;
    uint256[] suppliedBurnTokenIds;
    address referrer;
    address vaultWallet;
}

/**
 * @dev MintParameters define the tokens to be minted and conditions that must be met
 *      for the mint to be successfully processed.
 * 
 *      `mintTokens` is an array of tokens that will be minted
 *      `burnTokens` is an array of tokens required to be burned
 *      `paymentTokens` is an array of tokens required as payment
 *      `startTime` is the UTC timestamp of when the mint will start
 *      `endTime` is the UTC timestamp of when the mint will end
 *      `signatureMaxUses` limits the number of mints that can be performed with the
 *          specific mintParameters/signature
 *      `merkleRoot` is the root of the merkletree for allowlist minting
 *      `nonce` is the signer nonce that can be incremented on the LayerrMinter 
 *          contract to invalidate all previous signatures
 *      `oracleSignatureRequired` if true requires a secondary signature to process the mint
 */
struct MintParameters {
    MintToken[] mintTokens;
    BurnToken[] burnTokens;
    PaymentToken[] paymentTokens;
    uint256 startTime;
    uint256 endTime;
    uint256 signatureMaxUses;
    bytes32 merkleRoot;
    uint256 nonce;
    bool oracleSignatureRequired;
}

/**
 * @dev Defines the token that will be minted
 *      
 *      `contractAddress` address of contract to mint tokens from
 *      `specificTokenId` used for ERC721 - 
 *          if true, mint is non-sequential ERC721
 *          if false, mint is sequential ERC721A
 *      `tokenType` is the type of token being minted defined in TokenTypes.sol
 *      `tokenId` the tokenId to mint if specificTokenId is true
 *      `mintAmount` is the quantity to be minted
 *      `maxSupply` is checked against the total minted amount at time of mint
 *          minting reverts if `mintAmount` * `quantity` will cause total minted to 
 *          exceed `maxSupply`
 *      `maxMintPerWallet` is checked against the number minted for the wallet
 *          minting reverts if `mintAmount` * `quantity` will cause wallet minted to 
 *          exceed `maxMintPerWallet`
 */
struct MintToken {
    address contractAddress;
    bool specificTokenId;
    uint256 tokenType;
    uint256 tokenId;
    uint256 mintAmount;
    uint256 maxSupply;
    uint256 maxMintPerWallet;
}

/**
 * @dev Defines the token that will be burned
 *      
 *      `contractAddress` address of contract to burn tokens from
 *      `specificTokenId` specifies if the user has the option of choosing any token
 *          from the contract or if they must burn a specific token
 *      `tokenType` is the type of token being burned, defined in TokenTypes.sol
 *      `burnType` is the type of burn to perform, burn function call or transfer to 
 *          dead address, defined in BurnType.sol
 *      `tokenId` the tokenId to burn if specificTokenId is true
 *      `burnAmount` is the quantity to be burned
 */
struct BurnToken {
    address contractAddress;
    bool specificTokenId;
    uint256 tokenType;
    uint256 burnType;
    uint256 tokenId;
    uint256 burnAmount;
}

/**
 * @dev Defines the token that will be used for payment
 *      
 *      `contractAddress` address of contract to for payment if ERC20
 *          if tokenType is native token then this should be set to 0x000...000
 *          to save calldata gas units
 *      `tokenType` is the type of token being used for payment, defined in TokenTypes.sol
 *      `payTo` the address that will receive the payment
 *      `paymentAmount` the amount for the payment in base units for the token
 *          ex. a native payment on Ethereum for 1 ETH would be specified in wei
 *          which would be 1**18 wei
 *      `referralBPS` is the percentage of the payment in BPS that will be sent to the 
 *          `referrer` on the MintOrder if `referralBPS` is greater than 0 and `referrer`
 *          is not address(0)
 */
struct PaymentToken {
    address contractAddress;
    uint256 tokenType;
    address payTo;
    uint256 paymentAmount;
    uint256 referralBPS;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReentrancyGuard
 * @author 0xth0mas (Layerr)
 * @notice Simple reentrancy guard to prevent callers from re-entering the LayerrMinter mint functions
 */
contract ReentrancyGuard {
    uint256 private _reentrancyGuard = 1;
    error ReentrancyProhibited();

    modifier NonReentrant() {
        if (_reentrancyGuard > 1) {
            revert ReentrancyProhibited();
        }
        _reentrancyGuard = 2;
        _;
        _reentrancyGuard = 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {EIP712Domain, MintOrder, MintParameters, MintToken, BurnToken, PaymentToken} from "./MinterStructs.sol";
import {EIP712_DOMAIN_TYPEHASH, MINTPARAMETERS_TYPEHASH, MINTTOKEN_TYPEHASH, BURNTOKEN_TYPEHASH, PAYMENTTOKEN_TYPEHASH} from "./TypeHashes.sol";

/**
 * @title SignatureVerification
 * @author 0xth0mas (Layerr)
 * @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP712.sol)
 * @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/EIP712.sol)
 * @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol)
 * @notice Recovers the EIP712 signer for MintParameters and oracle signers
 *         for the LayerrMinter contract.
 */
contract SignatureVerification {
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    string private constant _name = "LayerrMinter";
    string private constant _version = "1.0";

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    constructor() {
        _hashedName = keccak256(bytes(_name));
        _hashedVersion = keccak256(bytes(_version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }
    
    /**
     * @notice Recovers the signer address for the supplied mint parameters and signature
     * @param _input MintParameters to recover the signer for
     * @param signature Signature for the MintParameters `_input` to recover signer
     * @return signer recovered signer of `signature` and `_input`
     * @return digest hash digest of `_input`
     */
    function _recoverMintParametersSigner(
        MintParameters calldata _input,
        bytes calldata signature
    ) internal view returns (address signer, bytes32 digest) {
        bytes32 hash = _getMintParametersHash(_input);
        digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), hash)
        );
        signer = _recover(digest, signature);
    }

    /**
     * @notice Recovers the signer address for the supplied oracle signature
     * @param minter address of wallet performing the mint
     * @param mintParametersSignature signature of MintParameters to check oracle signature of
     * @param oracleSignature supplied oracle signature
     * @return signer recovered oracle signer address
     */
    function _recoverOracleSigner(
        address minter, 
        bytes calldata mintParametersSignature, 
        bytes calldata oracleSignature
    ) internal pure returns(address signer) {
        bytes32 digest = keccak256(abi.encodePacked(minter, mintParametersSignature));
        signer = _recover(digest, oracleSignature);
    }

    /**
     * @notice Recovers the signer address for the increment nonce transaction
     * @param signer address of the account to increment nonce
     * @param currentNonce current nonce for the signer account
     * @param signature signature of message to validate
     * @return valid if the signature came from the signer
     */
    function _validateIncrementNonceSigner(
        address signer, 
        uint256 currentNonce,
        bytes calldata signature
    ) internal view returns(bool valid) {
        unchecked {
            // add chain id to current nonce to guard against replay on other chains
            currentNonce += block.chainid;
        }
        bytes memory nonceString = bytes(_toString(currentNonce));
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", _toString(nonceString.length), nonceString));
        valid = signer == _recover(digest, signature) && signer != address(0);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparator() private view returns (bytes32 separator) {
        separator = _cachedDomainSeparator;
        if (_cachedDomainSeparatorInvalidated()) {
            separator = _buildDomainSeparator();
        }
    }

    /**
     *  @dev Returns if the cached domain separator has been invalidated.
     */ 
    function _cachedDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        address cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    _hashedName,
                    _hashedVersion,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function _recover(
        bytes32 hash,
        bytes calldata sig
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        /// @solidity memory-safe-assembly
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            str := sub(m, 0x20)
            mstore(str, 0)
            let end := str

            for { let temp := value } 1 {} {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }

    function _getMintTokenArrayHash(
        MintToken[] calldata _input
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded;
        for (uint i = 0; i < _input.length; ) {
            encoded = abi.encodePacked(encoded, _getMintTokenHash(_input[i]));
            unchecked {
                ++i;
            }
        }
        hash = keccak256(encoded);
    }

    function _getBurnTokenArrayHash(
        BurnToken[] calldata _input
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded;
        for (uint i = 0; i < _input.length; ) {
            encoded = abi.encodePacked(encoded, _getBurnTokenHash(_input[i]));
            unchecked {
                ++i;
            }
        }
        hash = keccak256(encoded);
    }

    function _getPaymentTokenArrayHash(
        PaymentToken[] calldata _input
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded;
        for (uint i = 0; i < _input.length; ) {
            encoded = abi.encodePacked(encoded, _getPaymentTokenHash(_input[i]));
            unchecked {
                ++i;
            }
        }
        hash = keccak256(encoded);
    }

    function _getMintTokenHash(
        MintToken calldata _input
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                MINTTOKEN_TYPEHASH,
                _input.contractAddress,
                _input.specificTokenId,
                _input.tokenType,
                _input.tokenId,
                _input.mintAmount,
                _input.maxSupply,
                _input.maxMintPerWallet
            )
        );
    }

    function _getBurnTokenHash(
        BurnToken calldata _input
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                BURNTOKEN_TYPEHASH,
                _input.contractAddress,
                _input.specificTokenId,
                _input.tokenType,
                _input.burnType,
                _input.tokenId,
                _input.burnAmount
            )
        );
    }

    function _getPaymentTokenHash(
        PaymentToken calldata _input
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                PAYMENTTOKEN_TYPEHASH,
                _input.contractAddress,
                _input.tokenType,
                _input.payTo,
                _input.paymentAmount,
                _input.referralBPS
            )
        );
    }

    function _getMintParametersHash(
        MintParameters calldata _input
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded = abi.encode(
            MINTPARAMETERS_TYPEHASH,
            _getMintTokenArrayHash(_input.mintTokens),
            _getBurnTokenArrayHash(_input.burnTokens),
            _getPaymentTokenArrayHash(_input.paymentTokens),
            _input.startTime,
            _input.endTime,
            _input.signatureMaxUses,
            _input.merkleRoot,
            _input.nonce,
            _input.oracleSignatureRequired
        );
        hash = keccak256(encoded);
    }

    function getMintParametersSignatureDigest(
        MintParameters calldata _input
    ) external view returns (bytes32 digest) {
        bytes32 hash = _getMintParametersHash(_input);
        digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), hash)
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Simple struct to store a string value in a custom storage slot
struct StringValue {
    string value;
}

/// @dev Simple struct to store an address value in a custom storage slot
struct AddressValue {
    address value;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Token type used for payment tokens to specify payment is in the blockchain native token
uint256 constant TOKEN_TYPE_NATIVE  = 0;
/// @dev Token type used for payments, mints and burns to specify the token is an ERC20
uint256 constant TOKEN_TYPE_ERC20 = 1;
/// @dev Token type used for mints and burns to specify the token is an ERC721
uint256 constant TOKEN_TYPE_ERC721 = 2;
/// @dev Token type used for mints and burns to specify the token is an ERC1155
uint256 constant TOKEN_TYPE_ERC1155 = 3;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

bytes32 constant MINTPARAMETERS_TYPEHASH = keccak256(
    "MintParameters(MintToken[] mintTokens,"
    "BurnToken[] burnTokens,"
    "PaymentToken[] paymentTokens,"
    "uint256 startTime,"
    "uint256 endTime,"
    "uint256 signatureMaxUses,"
    "bytes32 merkleRoot,"
    "uint256 nonce,"
    "bool oracleSignatureRequired)"
    "BurnToken(address contractAddress,"
    "bool specificTokenId,"
    "uint8 tokenType,"
    "uint8 burnType,"
    "uint256 tokenId,"
    "uint256 burnAmount)"
    "MintToken(address contractAddress,"
    "bool specificTokenId,"
    "uint8 tokenType,"
    "uint256 tokenId,"
    "uint256 mintAmount,"
    "uint256 maxSupply,"
    "uint256 maxMintPerWallet)"
    "PaymentToken(address contractAddress,"
    "uint8 tokenType,"
    "address payTo,"
    "uint256 paymentAmount,"
    "uint256 referralBPS)"
);

bytes32 constant MINTTOKEN_TYPEHASH = keccak256(
    "MintToken(address contractAddress,bool specificTokenId,uint8 tokenType,uint256 tokenId,uint256 mintAmount,uint256 maxSupply,uint256 maxMintPerWallet)"
);

bytes32 constant BURNTOKEN_TYPEHASH = keccak256(
    "BurnToken(address contractAddress,bool specificTokenId,uint8 tokenType,uint8 burnType,uint256 tokenId,uint256 burnAmount)"
);

bytes32 constant PAYMENTTOKEN_TYPEHASH = keccak256(
    "PaymentToken(address contractAddress,uint8 tokenType,address payTo,uint256 paymentAmount,uint256 referralBPS)"
);

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;


import {ILayerr20} from "../interfaces/ILayerr20.sol";
import {ILayerr721} from "../interfaces/ILayerr721.sol";
import {ILayerr721A} from "../interfaces/ILayerr721A.sol";
import {ILayerr1155} from "../interfaces/ILayerr1155.sol";
import {ILayerrToken} from "../interfaces/ILayerrToken.sol";
import {ILayerrRenderer} from "../interfaces/ILayerrRenderer.sol";

contract LayerrInterfaceInspect {

    function getLayerr20InterfaceId() external pure returns (bytes4) {
        return type(ILayerr20).interfaceId; 
    }

    function getLayerr721InterfaceId() external pure returns (bytes4) {
        return type(ILayerr721).interfaceId; 
    }

    function getLayerr721AInterfaceId() external pure returns (bytes4) {
        return type(ILayerr721A).interfaceId; 
    }

    function getLayerr1155InterfaceId() external pure returns (bytes4) {
        return type(ILayerr1155).interfaceId; 
    }

    function getLayerrTokenInterfaceId() external pure returns (bytes4) {
        return type(ILayerrToken).interfaceId; 
    }

    function getLayerrRendererInterfaceId() external pure returns (bytes4) {
        return type(ILayerrRenderer).interfaceId; 
    }

}

// SPDX-License-Identifier: MIT
// ERC1155P Contracts v1.1
// Creator: 0xjustadev/0xth0mas

pragma solidity ^0.8.20;

import "./IERC1155P.sol";

/**
 * @dev Interface of ERC1155 token receiver.
 */
interface ERC1155P__IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Interface for IERC1155MetadataURI.
 */

interface ERC1155P__IERC1155MetadataURI {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

 /**
 * @title ERC1155P
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155 including the Metadata extension.
 * Optimized for lower gas for users collecting multiple tokens.
 *
 * Assumptions:
 * - An owner cannot have more than 2**16 - 1 of a single token
 * - The maximum token ID cannot exceed 2**100 - 1
 */
abstract contract ERC1155P is IERC1155P, ERC1155P__IERC1155MetadataURI {

    /**
     * @dev MAX_ACCOUNT_TOKEN_BALANCE is 2^16-1 because token balances are
     *      are being packed into 16 bits within each bucket.
     */
    uint256 private constant MAX_ACCOUNT_TOKEN_BALANCE = 0xFFFF;

    uint256 private constant BALANCE_STORAGE_OFFSET =
        0xE000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant APPROVAL_STORAGE_OFFSET =
        0xD000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @dev MAX_TOKEN_ID is derived from custom storage pointer location for 
     *      account/token balance data. Wallet address is shifted 92 bits left
     *      and leaves 92 bits for bucket #'s. Each bucket holds 8 token balances
     *      2^92*8-1 = MAX_TOKEN_ID
     */
    uint256 private constant MAX_TOKEN_ID = 0x07FFFFFFFFFFFFFFFFFFFFFFF;

    // The `TransferSingle` event signature is given by:
    // `keccak256(bytes("TransferSingle(address,address,address,uint256,uint256)"))`.
    bytes32 private constant _TRANSFER_SINGLE_EVENT_SIGNATURE =
        0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62;
    // The `TransferBatch` event signature is given by:
    // `keccak256(bytes("TransferBatch(address,address,address,uint256[],uint256[])"))`.
    bytes32 private constant _TRANSFER_BATCH_EVENT_SIGNATURE =
        0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb;
    // The `ApprovalForAll` event signature is given by:
    // `keccak256(bytes("ApprovalForAll(address,address,bool)"))`.
    bytes32 private constant _APPROVAL_FOR_ALL_EVENT_SIGNATURE =
        0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0xd9b67a26 || // ERC165 interface ID for ERC1155.
            interfaceId == 0x0e89341c; // ERC165 interface ID for ERC1155MetadataURI.
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        if(account == address(0)) { _revert(BalanceQueryForZeroAddress.selector); }
        return getBalance(account, id);
    }

    /**
     * @dev Gets the amount of tokens minted by an account for a given token id
     */
    function _numberMinted(address account, uint256 id) internal view returns (uint256) {
        if(account == address(0)) { _revert(BalanceQueryForZeroAddress.selector); }
        return getMinted(account, id);
    }

    /**
     * @dev Gets the balance of an account's token id from packed token data
     *
     */
    function getBalance(address account, uint256 id) private view returns (uint256 _balance) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            _balance := shr(shl(5, and(id, 0x07)), and(sload(keccak256(0x00, 0x20)), shl(shl(5, and(id, 0x07)), 0x0000FFFF)))
        }
    }

    /**
     * @dev Sets the balance of an account's token id in packed token data
     *
     */
    function setBalance(address account, uint256 id, uint256 amount) private {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            mstore(0x00, keccak256(0x00, 0x20))
            mstore(0x20, sload(mload(0x00)))
            mstore(0x20, or(and(not(shl(shl(5, and(id, 0x07)), 0x0000FFFF)), mload(0x20)), shl(shl(5, and(id, 0x07)), amount)))
            sstore(mload(0x00), mload(0x20))
        }
    }

    /**
     * @dev Gets the number minted of an account's token id from packed token data
     *
     */
    function getMinted(address account, uint256 id) private view returns (uint256 _minted) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            _minted := shr(16, shr(shl(5, and(id, 0x07)), and(sload(keccak256(0x00, 0x20)), shl(shl(5, and(id, 0x07)), 0xFFFF0000))))
        }
    }

    /**
     * @dev Sets the number minted of an account's token id in packed token data
     *
     */
    function setMinted(address account, uint256 id, uint256 amount) private {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            mstore(0x00, keccak256(0x00, 0x20))
            mstore(0x20, sload(mload(0x00)))
            mstore(0x20, or(and(not(shl(shl(5, and(id, 0x07)), 0xFFFF0000)), mload(0x20)), shl(shl(5, and(id, 0x07)), shl(16, amount))))
            sstore(mload(0x00), mload(0x20))
        }
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) public view virtual override returns (uint256[] memory) {
        if(accounts.length != ids.length) { _revert(ArrayLengthMismatch.selector); }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for(uint256 i = 0; i < accounts.length;) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
            unchecked {
                ++i;
            }
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool _approved) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, shr(96, shl(96, account)))
            mstore(0x20, or(APPROVAL_STORAGE_OFFSET, shr(96, shl(96, operator))))
            mstore(0x00, keccak256(0x00, 0x40))
            _approved := sload(mload(0x00))
        }
        return _approved; 
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public virtual override {
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
        if(to == address(0)) { _revert(TransferToZeroAddress.selector); }
        
        if(from != _msgSenderERC1155P())
            if (!isApprovedForAll(from, _msgSenderERC1155P())) _revert(TransferCallerNotOwnerNorApproved.selector);

        address operator = _msgSenderERC1155P();

        _beforeTokenTransfer(operator, from, to, id, amount, data);

        if(from != to) {
            uint256 fromBalance = getBalance(from, id);
            if(amount > fromBalance) { _revert(TransferExceedsBalance.selector); }
            uint256 toBalance = getBalance(to, id);
            unchecked {
                fromBalance -= amount;
                toBalance += amount;
            }
            if(toBalance > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
            setBalance(from, id, fromBalance);
            setBalance(to, id, toBalance);   
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Emit the `TransferSingle` event.
            let memOffset := mload(0x40)
            mstore(memOffset, id)
            mstore(add(memOffset, 0x20), amount)
            log4(
                memOffset, // Start of data .
                0x40, // Length of data.
                _TRANSFER_SINGLE_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                to // `to`.
            )
        }

        _afterTokenTransfer(operator, from, to, id, amount, data);

        if(to.code.length != 0)
            if(!_checkContractOnERC1155Received(from, to, id, amount, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {
        if(to == address(0)) { _revert(TransferToZeroAddress.selector); }
        if(ids.length != amounts.length) { _revert(ArrayLengthMismatch.selector); }

        if(from != _msgSenderERC1155P())
            if (!isApprovedForAll(from, _msgSenderERC1155P())) _revert(TransferCallerNotOwnerNorApproved.selector);

        address operator = _msgSenderERC1155P();

        _beforeBatchTokenTransfer(operator, from, to, ids, amounts, data);

        if(from != to) {
            for (uint256 i = 0; i < ids.length;) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }

                uint256 fromBalance = getBalance(from, id);
                if(amount > fromBalance) { _revert(TransferExceedsBalance.selector); }
                uint256 toBalance = getBalance(to, id);
                unchecked {
                    fromBalance -= amount;
                    toBalance += amount;
                }
                if(toBalance > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
                setBalance(from, id, fromBalance);
                setBalance(to, id, toBalance);
                unchecked {
                    ++i;
                }
            }
        }

        /// @solidity memory-safe-assembly
        assembly {
            let memOffset := mload(0x40)
            mstore(memOffset, 0x40)
            mstore(add(memOffset,0x20), add(0x60, mul(0x20,ids.length)))
            mstore(add(memOffset,0x40), ids.length)
            calldatacopy(add(memOffset,0x60), ids.offset, mul(0x20,ids.length))
            mstore(add(add(memOffset,0x60),mul(0x20,ids.length)), amounts.length)
            calldatacopy(add(add(memOffset,0x80),mul(0x20,ids.length)), amounts.offset, mul(0x20,amounts.length))
            log4(
                memOffset, 
                add(0x80,mul(0x40,amounts.length)),
                _TRANSFER_BATCH_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                to // `to`.
            )
        }

        _afterBatchTokenTransfer(operator, from, to, ids, amounts, data);


        if(to.code.length != 0)
            if(!_checkContractOnERC1155BatchReceived(from, to, ids, amounts, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address minter, address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
        if(to == address(0)) { _revert(MintToZeroAddress.selector); }
        if(amount == 0) { _revert(MintZeroQuantity.selector); }

        address operator = _msgSenderERC1155P();

        _beforeTokenTransfer(operator, address(0), to, id, amount, data);

        uint256 toBalance = getBalance(to, id);
        uint256 toMinted = getMinted(minter, id);
        unchecked {
            toBalance += amount;
            toMinted += amount;
        }
        if(toBalance > MAX_ACCOUNT_TOKEN_BALANCE || toMinted > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
        setBalance(to, id, toBalance);
        setMinted(minter, id, toMinted);

        /// @solidity memory-safe-assembly
        assembly {
            // Emit the `TransferSingle` event.
            let memOffset := mload(0x40)
            mstore(memOffset, id)
            mstore(add(memOffset, 0x20), amount)
            log4(
                memOffset, // Start of data .
                0x40, // Length of data.
                _TRANSFER_SINGLE_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                0, // `from`.
                to // `to`.
            )
        }

        _afterTokenTransfer(operator, address(0), to, id, amount, data);

        if(to.code.length != 0)
            if(!_checkContractOnERC1155Received(address(0), to, id, amount, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address minter,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {
        if(to == address(0)) { _revert(MintToZeroAddress.selector); }
        if(ids.length != amounts.length) { _revert(ArrayLengthMismatch.selector); }

        address operator = _msgSenderERC1155P();

        _beforeBatchTokenTransfer(operator, address(0), to, ids, amounts, data);

        uint256 id;
        uint256 amount;
        for (uint256 i = 0; i < ids.length;) {
            id = ids[i];
            amount = amounts[i];
            if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
            if(amount == 0) { _revert(MintZeroQuantity.selector); }

            uint256 toBalance = getBalance(to, id);
            uint256 toMinted = getMinted(minter, id);
            unchecked {
                toBalance += amount;
                toMinted += amount;
            }
            if(toBalance > MAX_ACCOUNT_TOKEN_BALANCE || toMinted > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
            setBalance(to, id, toBalance);
            setMinted(minter, id, toMinted);
            unchecked {
                ++i;
            }
        }

        /// @solidity memory-safe-assembly
        assembly {
            let memOffset := mload(0x40)
            mstore(memOffset, 0x40)
            mstore(add(memOffset,0x20), add(0x60, mul(0x20,ids.length)))
            mstore(add(memOffset,0x40), ids.length)
            calldatacopy(add(memOffset,0x60), ids.offset, mul(0x20,ids.length))
            mstore(add(add(memOffset,0x60),mul(0x20,ids.length)), amounts.length)
            calldatacopy(add(add(memOffset,0x80),mul(0x20,ids.length)), amounts.offset, mul(0x20,amounts.length))
            log4(
                memOffset, 
                add(0x80,mul(0x40,amounts.length)),
                _TRANSFER_BATCH_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                0, // `from`.
                to // `to`.
            )
        }

        _afterBatchTokenTransfer(operator, address(0), to, ids, amounts, data);

        if(to.code.length != 0)
            if(!_checkContractOnERC1155BatchReceived(address(0), to, ids, amounts, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
        if(from == address(0)) { _revert(BurnFromZeroAddress.selector); }

        address operator = _msgSenderERC1155P();

        _beforeTokenTransfer(operator, from, address(0), id, amount, "");

        uint256 fromBalance = getBalance(from, id);
        if(amount > fromBalance) { _revert(BurnExceedsBalance.selector); }
        unchecked {
            fromBalance -= amount;
        }
        setBalance(from, id, fromBalance);

        /// @solidity memory-safe-assembly
        assembly {
            // Emit the `TransferSingle` event.
            let memOffset := mload(0x40)
            mstore(memOffset, id)
            mstore(add(memOffset, 0x20), amount)
            log4(
                memOffset, // Start of data.
                0x40, // Length of data.
                _TRANSFER_SINGLE_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                0 // `to`.
            )
        }

        _afterTokenTransfer(operator, from, address(0), id, amount, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] calldata ids, uint256[] calldata amounts) internal virtual {
        if(from == address(0)) { _revert(BurnFromZeroAddress.selector); }
        if(ids.length != amounts.length) { _revert(ArrayLengthMismatch.selector); }

        address operator = _msgSenderERC1155P();

        _beforeBatchTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length;) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }

            uint256 fromBalance = getBalance(from, id);
            if(amount > fromBalance) { _revert(BurnExceedsBalance.selector); }
            unchecked {
                fromBalance -= amount;
            }
            setBalance(from, id, fromBalance);
            unchecked {
                ++i;
            }
        }

        /// @solidity memory-safe-assembly
        assembly {
            let memOffset := mload(0x40)
            mstore(memOffset, 0x40)
            mstore(add(memOffset,0x20), add(0x60, mul(0x20,ids.length)))
            mstore(add(memOffset,0x40), ids.length)
            calldatacopy(add(memOffset,0x60), ids.offset, mul(0x20,ids.length))
            mstore(add(add(memOffset,0x60),mul(0x20,ids.length)), amounts.length)
            calldatacopy(add(add(memOffset,0x80),mul(0x20,ids.length)), amounts.offset, mul(0x20,amounts.length))
            log4(
                memOffset, 
                add(0x80,mul(0x40,amounts.length)),
                _TRANSFER_BATCH_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                0 // `to`.
            )
        }

        _afterBatchTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, caller())
            mstore(0x20, or(APPROVAL_STORAGE_OFFSET, shr(96, shl(96, operator))))
            mstore(0x00, keccak256(0x00, 0x40))
            mstore(0x20, approved)
            sstore(mload(0x00), mload(0x20))
            log3(
                0x20,
                0x20,
                _APPROVAL_FOR_ALL_EVENT_SIGNATURE,
                caller(),
                shr(96, shl(96, operator))
            )
        }
    }

    /**
     * @dev Hook that is called before any single token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    

    /**
     * @dev Hook that is called before any batch token transfer. This includes minting
     * and burning.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    
    function _beforeBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any single token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any batch token transfer. This includes minting
     * and burning.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    
    function _afterBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC1155Receiver-onERC155Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `id` - Token ID to be transferred.
     * `amount` - Balance of token to be transferred
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC1155Received(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory _data
    ) private returns (bool) {
        try ERC1155P__IERC1155Receiver(to).onERC1155Received(_msgSenderERC1155P(), from, id, amount, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC1155P__IERC1155Receiver(to).onERC1155Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
            /// @solidity memory-safe-assembly
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    /**
     * @dev Private function to invoke {IERC1155Receiver-onERC155Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `id` - Token ID to be transferred.
     * `amount` - Balance of token to be transferred
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC1155BatchReceived(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory _data
    ) private returns (bool) {
        try ERC1155P__IERC1155Receiver(to).onERC1155BatchReceived(_msgSenderERC1155P(), from, ids, amounts, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC1155P__IERC1155Receiver(to).onERC1155BatchReceived.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
            /// @solidity memory-safe-assembly
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }
    
    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC1155P() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155P.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155PSupply is ERC1155P {
    /**
     * @dev Custom storage pointer for total token supply. Total supply is
     *      split into buckets of 4 tokens per bucket allowing for 64 bits
     *      per token. 
     *      32 bits are used to store total supply for a max value of 0xFFFFFFFF 
     *      (~4.3B) of a single token. 
     *      32 bits are used to store the mint count for a token
     * 
     *      The standard ERC1155P implementation allows a maximum token id
     *      of 0x0FFFFFFFFFFFFFFFFFFFFFFFF which requires a max bucket id of
     *      0x1FFFFFFFFFFFFFFFFFFFFFFF. Storage slots for buckets start at
     *      0xF000000000000000000000000000000000000000000000000000000000000000
     *      and continue through
     *      0xF0000000000000000000000000000000000000001FFFFFFFFFFFFFFFFFFFFFFF
     * 
     *      Storage pointers for ERC1155P account balances start at
     *      0xE000000000000000000000000000000000000000000000000000000000000000
     *      and continue through
     *      0xEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
     * 
     *      All custom pointers get hashed to avoid potential conflicts or 
     *      incorrect returns on view functions.
     */
    uint256 private constant TOTAL_SUPPLY_STORAGE_OFFSET =
        0xF000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MAX_TOTAL_SUPPLY = 0xFFFFFFFF;

    /**
     * Total supply exceeds maximum.
     */
    error ExceedsMaximumTotalSupply();

    /**
     * @dev Total amount of tokens with a given id.
     */
    function totalSupply(
        uint256 id
    ) public view virtual returns (uint256 _totalSupply) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(TOTAL_SUPPLY_STORAGE_OFFSET, shr(2, id)))
            _totalSupply := shr(shl(6, and(id, 0x03)), and(sload(keccak256(0x00, 0x20)), shl(shl(6, and(id, 0x03)), 0x00000000FFFFFFFF)))
        }
    }

    /**
     * @dev Sets total supply in custom storage slot location
     */
    function setTotalSupply(uint256 id, uint256 amount) private {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(TOTAL_SUPPLY_STORAGE_OFFSET, shr(2, id)))
            mstore(0x00, keccak256(0x00, 0x20))
            mstore(0x20, sload(mload(0x00)))
            mstore(0x20, or(and(not(shl(shl(6, and(id, 0x03)), 0x00000000FFFFFFFF)), mload(0x20)), shl(shl(6, and(id, 0x03)), amount)))
            sstore(mload(0x00), mload(0x20))
        }
    }

    /**
     * @dev Total amount of tokens minted with a given id.
     */
    function totalMinted(
        uint256 id
    ) public view virtual returns (uint256 _totalMinted) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(TOTAL_SUPPLY_STORAGE_OFFSET, shr(2, id)))
            _totalMinted := shr(32, shr(shl(6, and(id, 0x03)), and(sload(keccak256(0x00, 0x20)), shl(shl(6, and(id, 0x03)), 0xFFFFFFFF00000000))))
        }
    }

    /**
     * @dev Sets total minted in custom storage slot location
     */
    function setTotalMinted(uint256 id, uint256 amount) private {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(TOTAL_SUPPLY_STORAGE_OFFSET, shr(2, id)))
            mstore(0x00, keccak256(0x00, 0x20))
            mstore(0x20, sload(mload(0x00)))
            mstore(0x20, or(and(not(shl(shl(6, and(id, 0x03)), 0xFFFFFFFF00000000)), mload(0x20)), shl(shl(6, and(id, 0x03)), shl(32, amount))))
            sstore(mload(0x00), mload(0x20))
        }
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return this.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory
    ) internal virtual override {
        if (from == address(0)) {
            uint256 supply = this.totalSupply(id);
            uint256 minted = this.totalMinted(id);
            unchecked {
                supply += amount;
                minted += amount;
            }
            if (supply > MAX_TOTAL_SUPPLY || minted > MAX_TOTAL_SUPPLY) {
                ERC1155P._revert(ExceedsMaximumTotalSupply.selector);
            }
            setTotalSupply(id, supply);
            setTotalMinted(id, minted);
        }

        if (to == address(0)) {
            uint256 supply = this.totalSupply(id);
            unchecked {
                supply -= amount;
            }
            setTotalSupply(id, supply);
        }
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeBatchTokenTransfer(
        address,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory
    ) internal virtual override {
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ) {
                uint256 id = ids[i];
                uint256 supply = this.totalSupply(id);
                uint256 minted = this.totalMinted(id);
                unchecked {
                    supply += amounts[i];
                    minted += amounts[i];
                    ++i;
                }
                if (supply > MAX_TOTAL_SUPPLY || minted > MAX_TOTAL_SUPPLY) {
                    ERC1155P._revert(ExceedsMaximumTotalSupply.selector);
                }
                setTotalSupply(id, supply);
                setTotalMinted(id, minted);
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ) {
                uint256 id = ids[i];
                uint256 supply = this.totalSupply(id);
                unchecked {
                    supply -= amounts[i];
                    ++i;
                }
                setTotalSupply(id, supply);
            }
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// ERC1155P Contracts v1.1

pragma solidity ^0.8.20;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155P {

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Arrays cannot be different lengths.
     */
    error ArrayLengthMismatch();

    /**
     * Cannot burn from the zero address.
     */
    error BurnFromZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The quantity of tokens being burned is greater than account balance.
     */
    error BurnExceedsBalance();

    /**
     * The quantity of tokens being transferred is greater than account balance.
     */
    error TransferExceedsBalance();

    /**
     * The resulting token balance exceeds the maximum storable by ERC1155P
     */
    error ExceedsMaximumBalance();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC1155Receiver interface.
     */
    error TransferToNonERC1155ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * Exceeds max token ID
     */
    error ExceedsMaximumTokenId();
    
    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {ERC1155PSupply} from "./extensions/ERC1155PSupply.sol";
import {ILayerr1155} from "../../interfaces/ILayerr1155.sol";
import {ILayerrRenderer} from "../../interfaces/ILayerrRenderer.sol";
import {LayerrToken} from "../LayerrToken.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * @title Layerr1155
 * @author 0xth0mas (Layerr)
 * @notice Layerr1155 is an ERC1155 contract built for the Layerr platform using
 *         the ERC1155P implementation for gas efficient mints, burns, purchases,  
 *         and transfers of multiple tokens.
 */
contract Layerr1155 is
    DefaultOperatorFilterer,
    ERC1155PSupply,
    ILayerr1155,
    LayerrToken
{

    /** METADATA FUNCTIONS */

    /**
     * @notice Returns the URI for a given `tokenId`
     * @param id id of token to return URI of
     * @return tokenURI location of the token metadata
     */
    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        return ILayerrRenderer(_getRenderer()).tokenURI(address(this), id);
    }

    /**
     * @notice Returns the URI for the contract metadata
     * @return contractURI location of the contract metadata
     */
    function contractURI() public view returns (string memory) {
        return ILayerrRenderer(_getRenderer()).contractURI(address(this));
    }

    /** MINT FUNCTIONS */

    /**
     * @inheritdoc ILayerr1155
     */
    function mintTokenId(
        address minter,
        address to,
        uint256 id,
        uint256 amount
    ) external onlyMinter {
        _mint(minter, to, id, amount, "");
    }

    /**
     * @inheritdoc ILayerr1155
     */
    function mintBatchTokenIds(
        address minter,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyMinter {
        _mintBatch(minter, to, ids, amounts, "");
    }

    /**
     * @inheritdoc ILayerr1155
     */
    function burnTokenId(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external onlyMinter {
        if (!isApprovedForAll(from, msg.sender)) {
            revert NotAuthorized();
        }
        _burn(from, tokenId, amount);
    }

    /**
     * @inheritdoc ILayerr1155
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyMinter {
        if (!isApprovedForAll(from,msg.sender)) {
            revert NotAuthorized();
        }
        _burnBatch(from, tokenIds, amounts);
    }

    /**
     * @inheritdoc ILayerr1155
     */
    function totalSupply(uint256 id) public view override(ERC1155PSupply, ILayerr1155) returns (uint256) {
        return ERC1155PSupply.totalSupply(id);
    }
    
    /**
     * @inheritdoc ILayerr1155
     */
    function totalMintedCollectionAndMinter(address minter, uint256 id) external view returns(uint256 totalMinted, uint256 minterMinted) {
        totalMinted = totalSupply(id);
        minterMinted = _numberMinted(minter, id);
    }
    
    /** OWNER FUNCTIONS */

    /**
     * @inheritdoc ILayerr1155
     */
    function airdrop(address[] calldata recipients, uint256[] calldata tokenIds, uint256[] calldata amounts) external onlyOwner {
        if(recipients.length != tokenIds.length || tokenIds.length != amounts.length) { revert ArrayLengthMismatch(); }

        for(uint256 index = 0;index < recipients.length;) {
            _mint(msg.sender, recipients[index], tokenIds[index], amounts[index], "");

            unchecked { ++index; }
        }
    }

    /**
     * @notice Subscribes to an operator filter registry
     * @param operatorFilterRegistry operator filter address to subscribe to
     */
    function setOperatorFilter(address operatorFilterRegistry) external onlyOwner {
        if (operatorFilterRegistry != address(0)) {
            OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
                address(this),
                operatorFilterRegistry
            );
        }
    }

    /**
     * @notice Unsubscribes from the operator filter registry
     */
    function removeOperatorFilter() external onlyOwner {
        OPERATOR_FILTER_REGISTRY.unregister(
            address(this)
        );
    }

    /**
     * @inheritdoc ILayerr1155
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external onlyOwner {
        ILayerrRenderer renderer = ILayerrRenderer(_getRenderer());
        for(uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            emit URI(renderer.tokenURI(address(this), tokenId), tokenId);
            
            unchecked { ++i; }
        }
    }

    /** OPERATOR FILTER OVERRIDES */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /** ERC165 */

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(LayerrToken, ERC1155PSupply) returns (bool) {
        return
            interfaceId == type(ILayerr1155).interfaceId ||
            LayerrToken.supportsInterface(interfaceId) ||
            ERC1155PSupply.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple ERC20 + EIP-2612 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)
/// @dev Note:
/// The ERC20 standard allows minting and transferring to and from the zero address,
/// minting and transferring zero tokens, as well as self-approvals.
/// For performance, this implementation WILL NOT revert for such actions.
/// Please add any checks with overrides if desired.
abstract contract ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The total supply has overflowed.
    error TotalSupplyOverflow();

    /// @dev The allowance has overflowed.
    error AllowanceOverflow();

    /// @dev The allowance has underflowed.
    error AllowanceUnderflow();

    /// @dev The balance has overflowed
    error BalanceOverflow();

    /// @dev Insufficient balance.
    error InsufficientBalance();

    /// @dev Insufficient allowance.
    error InsufficientAllowance();

    /// @dev The permit is invalid.
    error InvalidPermit();

    /// @dev The permit has expired.
    error PermitExpired();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `amount` tokens is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Emitted when `amount` tokens is approved by `owner` to be used by `spender`.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot for the total minted.
    uint256 private constant _TOTAL_MINTED_SLOT = 0x05345cdf77eb68f44c;

    /// @dev The storage slot for the total burned.
    uint256 private constant _TOTAL_BURNED_SLOT = 0xc44f86be77fdc54350;

    uint256 private constant _BALANCE_MASK = 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @dev The balance slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _BALANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let balanceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _BALANCE_SLOT_SEED = 0x87a211a2;

    /// @dev The allowance slot of (`owner`, `spender`) is given by:
    /// ```
    ///     mstore(0x20, spender)
    ///     mstore(0x0c, _ALLOWANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let allowanceSlot := keccak256(0x0c, 0x34)
    /// ```
    uint256 private constant _ALLOWANCE_SLOT_SEED = 0x7f5e9f20;

    /// @dev The nonce slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _NONCES_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let nonceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _NONCES_SLOT_SEED = 0x38377508;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the name of the token.
    function name() public view virtual returns (string memory);

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual returns (string memory);

    /// @dev Returns the decimals places of the token.
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC20                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the amount of tokens in existence.
    function totalSupply() public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sub(sload(_TOTAL_MINTED_SLOT), sload(_TOTAL_BURNED_SLOT))
        }
    }

    /// @dev Returns the amount of tokens minted.
    function _totalMinted() internal view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_TOTAL_MINTED_SLOT)
        }
    }

    /// @dev Returns the amount of tokens burned.
    function _totalBurned() internal view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_TOTAL_BURNED_SLOT)
        }
    }

    /// @dev Returns the amount of tokens owned by `owner`.
    function balanceOf(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := and(sload(keccak256(0x0c, 0x20)), _BALANCE_MASK)
        }
    }

    /// @dev Returns the amount of tokens minted by `wallet`.
    function _numberMinted(address wallet) internal view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, wallet)
            result := shr(128, sload(keccak256(0x0c, 0x20)))
        }
    }

    /// @dev Returns the amount of tokens that `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x34))
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// Emits a {Approval} event.
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// Emits a {Approval} event.
    function increaseAllowance(address spender, uint256 difference) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowanceBefore := sload(allowanceSlot)
            // Add to the allowance.
            let allowanceAfter := add(allowanceBefore, difference)
            // Revert upon overflow.
            if lt(allowanceAfter, allowanceBefore) {
                mstore(0x00, 0xf9067066) // `AllowanceOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated allowance.
            sstore(allowanceSlot, allowanceAfter)
            // Emit the {Approval} event.
            mstore(0x00, allowanceAfter)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// Emits a {Approval} event.
    function decreaseAllowance(address spender, uint256 difference) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowanceBefore := sload(allowanceSlot)
            // Revert if will underflow.
            if lt(allowanceBefore, difference) {
                mstore(0x00, 0x8301ab38) // `AllowanceUnderflow()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated allowance.
            let allowanceAfter := sub(allowanceBefore, difference)
            sstore(allowanceSlot, allowanceAfter)
            // Emit the {Approval} event.
            mstore(0x00, allowanceAfter)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Transfer `amount` tokens from the caller to `to`.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    ///
    /// Emits a {Transfer} event.
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, caller())
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalanceSlotValue := sload(fromBalanceSlot)
            let fromBalance := and(fromBalanceSlotValue, _BALANCE_MASK)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, or(and(fromBalanceSlotValue, not(_BALANCE_MASK)), sub(fromBalance, amount)))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            let toBalanceSlotValue := sload(toBalanceSlot)
            let toBalanceBefore := and(toBalanceSlotValue, _BALANCE_MASK)
            let toBalanceAfter := add(toBalanceBefore, amount)
            if gt(toBalanceAfter, _BALANCE_MASK) {
                mstore(0x00, 0x89560ca1)
                revert(0x1c, 0x04)
            }
            // Add and store the updated balance.
            sstore(toBalanceSlot, or(and(toBalanceSlotValue, not(_BALANCE_MASK)), toBalanceAfter))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, caller(), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Transfers `amount` tokens from `from` to `to`.
    ///
    /// Note: does not update the allowance if it is the maximum uint256 value.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    /// - The caller must have at least `amount` of allowance to transfer the tokens of `from`.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the allowance slot and load its value.
            mstore(0x20, caller())
            mstore(0x0c, or(from_, _ALLOWANCE_SLOT_SEED))
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if iszero(eq(allowance_, not(0))) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalanceSlotValue := sload(fromBalanceSlot)
            let fromBalance := and(fromBalanceSlotValue, _BALANCE_MASK)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, or(and(fromBalanceSlotValue, not(_BALANCE_MASK)), sub(fromBalance, amount)))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            let toBalanceSlotValue := sload(toBalanceSlot)
            let toBalanceBefore := and(toBalanceSlotValue, _BALANCE_MASK)
            let toBalanceAfter := add(toBalanceBefore, amount)
            if gt(toBalanceAfter, _BALANCE_MASK) {
                mstore(0x00, 0x89560ca1)
                revert(0x1c, 0x04)
            }
            // Add and store the updated balance.
            sstore(toBalanceSlot, or(and(toBalanceSlotValue, not(_BALANCE_MASK)), toBalanceAfter))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EIP-2612                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the current nonce for `owner`.
    /// This value is used to compute the signature for EIP-2612 permit.
    function nonces(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the nonce slot and load its value.
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Sets `value` as the allowance of `spender` over the tokens of `owner`,
    /// authorized by a signed approval by `owner`.
    ///
    /// Emits a {Approval} event.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        bytes32 domainSeparator = DOMAIN_SEPARATOR();
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the free memory pointer.
            let m := mload(0x40)
            // Revert if the block timestamp greater than `deadline`.
            if gt(timestamp(), deadline) {
                mstore(0x00, 0x1a15a3cc) // `PermitExpired()`.
                revert(0x1c, 0x04)
            }
            // Clean the upper 96 bits.
            owner := shr(96, shl(96, owner))
            spender := shr(96, shl(96, spender))
            // Compute the nonce slot and load its value.
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            let nonceSlot := keccak256(0x0c, 0x20)
            let nonceValue := sload(nonceSlot)
            // Increment and store the updated nonce.
            sstore(nonceSlot, add(nonceValue, 1))
            // Prepare the inner hash.
            // `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
            // forgefmt: disable-next-item
            mstore(m, 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9)
            mstore(add(m, 0x20), owner)
            mstore(add(m, 0x40), spender)
            mstore(add(m, 0x60), value)
            mstore(add(m, 0x80), nonceValue)
            mstore(add(m, 0xa0), deadline)
            // Prepare the outer hash.
            mstore(0, 0x1901)
            mstore(0x20, domainSeparator)
            mstore(0x40, keccak256(m, 0xc0))
            // Prepare the ecrecover calldata.
            mstore(0, keccak256(0x1e, 0x42))
            mstore(0x20, and(0xff, v))
            mstore(0x40, r)
            mstore(0x60, s)
            pop(staticcall(gas(), 1, 0, 0x80, 0x20, 0x20))
            // If the ecrecover fails, the returndatasize will be 0x00,
            // `owner` will be be checked if it equals the hash at 0x00,
            // which evaluates to false (i.e. 0), and we will revert.
            // If the ecrecover succeeds, the returndatasize will be 0x20,
            // `owner` will be compared against the returned address at 0x20.
            if iszero(eq(mload(returndatasize()), owner)) {
                mstore(0x00, 0xddafbaef) // `InvalidPermit()`.
                revert(0x1c, 0x04)
            }
            // Compute the allowance slot and store the value.
            // The `owner` is already at slot 0x20.
            mstore(0x40, or(shl(160, _ALLOWANCE_SLOT_SEED), spender))
            sstore(keccak256(0x2c, 0x34), value)
            // Emit the {Approval} event.
            log3(add(m, 0x60), 0x20, _APPROVAL_EVENT_SIGNATURE, owner, spender)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Returns the EIP-2612 domains separator.
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40) // Grab the free memory pointer.
        }
        //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
        bytes32 nameHash = keccak256(bytes(name()));
        /// @solidity memory-safe-assembly
        assembly {
            let m := result
            // `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
            // forgefmt: disable-next-item
            mstore(m, 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f)
            mstore(add(m, 0x20), nameHash)
            // `keccak256("1")`.
            // forgefmt: disable-next-item
            mstore(add(m, 0x40), 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            result := keccak256(m, 0xa0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL MINT FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `amount` tokens to `to`, increasing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let totalMintedBefore := sload(_TOTAL_MINTED_SLOT)
            let totalMintedAfter := add(totalMintedBefore, amount)
            // Revert if the total minted overflows.
            if lt(totalMintedAfter, totalMintedBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated total minted.
            sstore(_TOTAL_MINTED_SLOT, totalMintedAfter)
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            let toBalanceSlotValue := sload(toBalanceSlot)
            let toBalanceBefore := and(toBalanceSlotValue, _BALANCE_MASK)
            let toMintedBefore := shr(128, toBalanceSlotValue)
            let toBalanceAfter := add(toBalanceBefore, amount)
            let toMintedAfter := add(toMintedBefore, amount)
            if gt(toBalanceAfter, _BALANCE_MASK) {
                mstore(0x00, 0x89560ca1)
                revert(0x1c, 0x04)
            }
            if gt(toMintedAfter, _BALANCE_MASK) {
                mstore(0x00, 0x89560ca1)
                revert(0x1c, 0x04)
            }
            // Add and store the updated balance.
            sstore(toBalanceSlot, add(shl(128, toMintedAfter), toBalanceAfter))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(address(0), to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL BURN FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Burns `amount` tokens from `from`, reducing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, from)
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalanceSlotValue := sload(fromBalanceSlot)
            let fromBalance := and(fromBalanceSlotValue, _BALANCE_MASK)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, or(and(fromBalanceSlotValue, not(_BALANCE_MASK)), sub(fromBalance, amount)))
            // Update burned
            let totalBurnedBefore := sload(_TOTAL_BURNED_SLOT)
            let totalBurnedAfter := add(totalBurnedBefore, amount)
            // Revert if the total minted overflows.
            if lt(totalBurnedAfter, totalBurnedBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated total burned.
            sstore(_TOTAL_BURNED_SLOT, totalBurnedAfter)
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), 0)
        }
        _afterTokenTransfer(from, address(0), amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL TRANSFER FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Moves `amount` of tokens from `from` to `to`.
    function _transfer(address from, address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalanceSlotValue := sload(fromBalanceSlot)
            let fromBalance := and(fromBalanceSlotValue, _BALANCE_MASK)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, or(and(fromBalanceSlotValue, not(_BALANCE_MASK)), sub(fromBalance, amount)))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            let toBalanceSlotValue := sload(toBalanceSlot)
            let toBalanceBefore := and(toBalanceSlotValue, _BALANCE_MASK)
            let toBalanceAfter := add(toBalanceBefore, amount)
            if gt(toBalanceAfter, _BALANCE_MASK) {
                mstore(0x00, 0x89560ca1)
                revert(0x1c, 0x04)
            }
            // Add and store the updated balance.
            sstore(toBalanceSlot, or(and(toBalanceSlotValue, not(_BALANCE_MASK)), toBalanceAfter))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL ALLOWANCE FUNCTIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Updates the allowance of `owner` for `spender` based on spent `amount`.
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if iszero(eq(allowance_, not(0))) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the tokens of `owner`.
    ///
    /// Emits a {Approval} event.
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let owner_ := shl(96, owner)
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, or(owner_, _ALLOWANCE_SLOT_SEED))
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, shr(96, owner_), shr(96, mload(0x2c)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import "./ERC20.sol";
import {ILayerr20} from "../../interfaces/ILayerr20.sol";
import {ILayerrRenderer} from "../../interfaces/ILayerrRenderer.sol";
import {LayerrToken} from "../LayerrToken.sol";

/**
 * @title Layerr20
 * @author 0xth0mas (Layerr)
 * @notice Layerr20 is an ERC20 contract built for the Layerr platform using
 *         the Solady ERC20 implementation.
 */
contract Layerr20 is ERC20, ILayerr20, LayerrToken {

    /** METADATA FUNCTIONS */

    /**
     * @notice Returns the URI for the contract metadata
     * @return contractURI location of the contract metadata
     */
    function contractURI() public view returns (string memory) {
        return ILayerrRenderer(_getRenderer()).contractURI(address(this));
    }

    /**
     * @inheritdoc LayerrToken
     */
    function name() public view virtual override(LayerrToken, ERC20) returns (string memory) {
        return LayerrToken.name();
    }

    /**
     * @inheritdoc LayerrToken
     */
    function symbol() public view virtual override(LayerrToken, ERC20) returns (string memory) {
        return LayerrToken.symbol();
    }

    /** MINT FUNCTIONS */

    /**
     * @inheritdoc ILayerr20
     */
    function mint(address, address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    /**
     * @inheritdoc ILayerr20
     */
    function burn(address from, uint256 amount) external onlyMinter {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }

    /**
     * @inheritdoc ILayerr20
     */
    function totalSupply() public view override(ERC20, ILayerr20) returns (uint256) {
        return ERC20.totalSupply();
    }

    /**
     * @inheritdoc ILayerr20
     */
    function totalMintedTokenAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted) {
        totalMinted = _totalMinted();
        minterMinted = _numberMinted(minter);
    }

    /** OWNER FUNCTIONS */

    /**
     * @inheritdoc ILayerr20
     */
    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        if(recipients.length != amounts.length) { revert ArrayLengthMismatch(); }

        for(uint256 index = 0;index < recipients.length;) {
            uint256 amount = amounts[index];
            _mint(recipients[index], amount);
            unchecked { ++index; }
        }
    }

    /** ERC165 */

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(LayerrToken) returns (bool) {
        return
            interfaceId == type(ILayerr20).interfaceId ||
            LayerrToken.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../ERC721A/IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721 is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The number of tokens that have been minted.
    uint256 private _mintCounter;

    // The number of tokens that have been burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _mintCounter - _burnCounter;
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        return _mintCounter;
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) _revert(BalanceQueryForZeroAddress.selector);
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        /// @solidity memory-safe-assembly
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Returns whether the ownership slot at `index` is initialized.
     * An uninitialized slot does not necessarily mean that the slot has no owner.
     */
    function _ownershipIsInitialized(uint256 index) internal view virtual returns (bool) {
        return _packedOwnerships[index] != 0;
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256 packed) {
        packed = _packedOwnerships[tokenId];
        // If the data at the starting slot does not exist, start the scan.
        if (packed > 0 && packed & _BITMASK_BURNED == 0) {
            return packed;
        }
        _revert(OwnerQueryForNonexistentToken.selector);
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        /// @solidity memory-safe-assembly
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        _approve(to, tokenId, true);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) _revert(ApprovalQueryForNonexistentToken.selector);

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool result) {
        uint256 packed = _packedOwnerships[tokenId];
        result = (packed > 0 && packed & _BITMASK_BURNED == 0);
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        /// @solidity memory-safe-assembly
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
        from = address(uint160(uint256(uint160(from)) & _BITMASK_ADDRESS));

        if (address(uint160(prevOwnershipPacked)) != from) _revert(TransferFromIncorrectOwner.selector);

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        /// @solidity memory-safe-assembly
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );
        }

        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
        uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the `Transfer` event.
            log4(
                0, // Start of data (0, since no data).
                0, // End of data (0, since no data).
                _TRANSFER_EVENT_SIGNATURE, // Signature.
                from, // `from`.
                toMasked, // `to`.
                tokenId // `tokenId`.
            )
        }
        if (toMasked == 0) _revert(TransferToZeroAddress.selector);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
            /// @solidity memory-safe-assembly
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address minter, address to, uint256 tokenId) internal virtual {
        if(_packedOwnerships[tokenId] > 0) _revert(TokenAlreadyExists.selector);

        _beforeTokenTransfers(address(0), to, tokenId, 1);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(1) | _nextExtraData(address(0), to, 0)
            );

            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            if(minter == to) {
                _packedAddressData[to] += ((1 << _BITPOS_NUMBER_MINTED) | 1);
            } else {
                _packedAddressData[to] += 1;
                _packedAddressData[minter] += (1 << _BITPOS_NUMBER_MINTED);
            }

            ++_mintCounter;

            // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
            uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;

            if (toMasked == 0) _revert(MintToZeroAddress.selector);
        
            /// @solidity memory-safe-assembly
            assembly {
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    tokenId // `tokenId`.
                )
            }

        }
        _afterTokenTransfers(address(0), to, tokenId, 1);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address minter, 
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(minter, to, tokenId);

        unchecked {
            if (to.code.length != 0) {
                if (!_checkContractOnERC721Received(address(0), to, tokenId, _data)) {
                    _revert(TransferToNonERC721ReceiverImplementer.selector);
                }
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(minter, to, quantity, '')`.
     */
    function _safeMint(address minter, address to, uint256 quantity) internal virtual {
        _safeMint(minter, to, quantity, '');
    }

    // =============================================================
    //                       APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_approve(to, tokenId, false)`.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _approve(to, tokenId, false);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        bool approvalCheck
    ) internal virtual {
        address owner = ownerOf(tokenId);

        if (approvalCheck && _msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                _revert(ApprovalCallerNotOwnerNorApproved.selector);
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        /// @solidity memory-safe-assembly
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            ++_burnCounter;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) _revert(OwnershipNotInitializedForExtraData.selector);
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        /// @solidity memory-safe-assembly
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import {IERC4906} from "../../interfaces/IERC4906.sol";
import {ILayerr721} from "../../interfaces/ILayerr721.sol";
import {ILayerrRenderer} from "../../interfaces/ILayerrRenderer.sol";
import {LayerrToken} from "../LayerrToken.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * @title Layerr721A
 * @author 0xth0mas (Layerr)
 * @notice Layerr721A is an ERC721 contract built for the Layerr platform using
 *         a modified Chiru Labs ERC721A implementation for non-sequential 
 *         minting.
 */
contract Layerr721 is DefaultOperatorFilterer, ERC721, ILayerr721, LayerrToken, IERC4906 {

    /** METADATA FUNCTIONS */
    
    /**
     * @notice Returns the URI for a given `tokenId`
     * @param tokenId id of token to return URI of
     * @return tokenURI location of the token metadata
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return ILayerrRenderer(_getRenderer()).tokenURI(address(this), tokenId);
    }

    /**
     * @notice Returns the URI for the contract metadata
     * @return contractURI location of the contract metadata
     */
    function contractURI() public view returns (string memory) {
        return ILayerrRenderer(_getRenderer()).contractURI(address(this));
    }

    /**
     * @inheritdoc LayerrToken
     */
    function name() public view virtual override(LayerrToken, ERC721) returns (string memory) {
        return LayerrToken.name();
    }

    /**
     * @inheritdoc LayerrToken
     */
    function symbol() public view virtual override(LayerrToken, ERC721) returns (string memory) {
        return LayerrToken.symbol();
    }

    /** MINT FUNCTIONS */

    /**
     * @inheritdoc ILayerr721
     */
    function mintTokenId(address minter, address to, uint256 tokenId) external onlyMinter {
        _mint(minter, to, tokenId);
    }

    /**
     * @inheritdoc ILayerr721
     */
    function mintBatchTokenIds(
        address minter,
        address to,
        uint256[] calldata tokenIds
    ) external onlyMinter {
        for(uint256 i = 0;i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            _mint(minter, to, tokenId);
            
            unchecked { ++i; }
        }
    }

    /**
     * @inheritdoc ILayerr721
     */
    function burnTokenId(address from, uint256 tokenId) external onlyMinter {
        if(ownerOf(tokenId) != from) { revert NotAuthorized(); }
        _burn(tokenId);
    }

    /**
     * @inheritdoc ILayerr721
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds
    ) external onlyMinter {
        for(uint256 i = 0;i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            if(ownerOf(tokenId) != from) { revert NotAuthorized(); }
            _burn(tokenId);

            unchecked { ++i; }
        }
    }

    /**
     * @inheritdoc ILayerr721
     */
    function totalSupply() public view override(ERC721, ILayerr721) returns (uint256) {
        return ERC721.totalSupply();
    }

    /**
     * @inheritdoc ILayerr721
     */
    function totalMintedCollectionAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted) {
        totalMinted = _totalMinted();
        minterMinted = _numberMinted(minter);
    }

    /** OWNER FUNCTIONS */

    /**
     * @inheritdoc ILayerr721
     */
    function airdrop(address[] calldata recipients, uint256[] calldata tokenIds) external onlyOwner {
        if(recipients.length != tokenIds.length) { revert ArrayLengthMismatch(); }

        for(uint256 index = 0;index < recipients.length;) {
            _mint(msg.sender, recipients[index], tokenIds[index]);

            unchecked { ++index; }
        }
    }

    /**
     * @notice Subscribes to an operator filter registry
     * @param operatorFilterRegistry operator filter address to subscribe to
     */
    function setOperatorFilter(address operatorFilterRegistry) external onlyOwner {
        if (operatorFilterRegistry != address(0)) {
            OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
                address(this),
                operatorFilterRegistry
            );
        }
    }

    /**
     * @notice Unsubscribes from the operator filter registry
     */
    function removeOperatorFilter() external onlyOwner {
        OPERATOR_FILTER_REGISTRY.unregister(
            address(this)
        );
    }

    /**
     * @inheritdoc ILayerr721
     */
    function updateMetadataAllTokens() external onlyOwner {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    /**
     * @inheritdoc ILayerr721
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external onlyOwner {
        for(uint256 i; i < tokenIds.length; ) {
            emit MetadataUpdate(tokenIds[i]);
            
            unchecked { ++i; }
        }
    }

    /** OPERATOR FILTER OVERRIDES */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /** ERC165 */

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(LayerrToken, ERC721) returns (bool) {
        return
            interfaceId == type(ILayerr721).interfaceId ||
            LayerrToken.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) _revert(BalanceQueryForZeroAddress.selector);
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        /// @solidity memory-safe-assembly
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Returns whether the ownership slot at `index` is initialized.
     * An uninitialized slot does not necessarily mean that the slot has no owner.
     */
    function _ownershipIsInitialized(uint256 index) internal view virtual returns (bool) {
        return _packedOwnerships[index] != 0;
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256 packed) {
        if (_startTokenId() <= tokenId) {
            packed = _packedOwnerships[tokenId];
            // If the data at the starting slot does not exist, start the scan.
            if (packed == 0) {
                if (tokenId >= _currentIndex) _revert(OwnerQueryForNonexistentToken.selector);
                // Invariant:
                // There will always be an initialized ownership slot
                // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                // before an unintialized ownership slot
                // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                // Hence, `tokenId` will not underflow.
                //
                // We can directly compare the packed value.
                // If the address is zero, packed will be zero.
                for (;;) {
                    unchecked {
                        packed = _packedOwnerships[--tokenId];
                    }
                    if (packed == 0) continue;
                    if (packed & _BITMASK_BURNED == 0) return packed;
                    // Otherwise, the token is burned, and we must revert.
                    // This handles the case of batch burned tokens, where only the burned bit
                    // of the starting slot is set, and remaining slots are left uninitialized.
                    _revert(OwnerQueryForNonexistentToken.selector);
                }
            }
            // Otherwise, the data exists and we can skip the scan.
            // This is possible because we have already achieved the target condition.
            // This saves 2143 gas on transfers of initialized tokens.
            // If the token is not burned, return `packed`. Otherwise, revert.
            if (packed & _BITMASK_BURNED == 0) return packed;
        }
        _revert(OwnerQueryForNonexistentToken.selector);
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        /// @solidity memory-safe-assembly
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        _approve(to, tokenId, true);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) _revert(ApprovalQueryForNonexistentToken.selector);

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool result) {
        if (_startTokenId() <= tokenId) {
            if (tokenId < _currentIndex) {
                uint256 packed;
                while ((packed = _packedOwnerships[tokenId]) == 0) --tokenId;
                result = packed & _BITMASK_BURNED == 0;
            }
        }
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        /// @solidity memory-safe-assembly
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
        from = address(uint160(uint256(uint160(from)) & _BITMASK_ADDRESS));

        if (address(uint160(prevOwnershipPacked)) != from) _revert(TransferFromIncorrectOwner.selector);

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        /// @solidity memory-safe-assembly
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
        uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the `Transfer` event.
            log4(
                0, // Start of data (0, since no data).
                0, // End of data (0, since no data).
                _TRANSFER_EVENT_SIGNATURE, // Signature.
                from, // `from`.
                toMasked, // `to`.
                tokenId // `tokenId`.
            )
        }
        if (toMasked == 0) _revert(TransferToZeroAddress.selector);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
            /// @solidity memory-safe-assembly
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address minter, address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) _revert(MintZeroQuantity.selector);

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            if(minter == to) {
                _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);
            } else {
                _packedAddressData[minter] += quantity * (1 << _BITPOS_NUMBER_MINTED);
                _packedAddressData[to] += quantity;
            }

            // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
            uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;

            if (toMasked == 0) _revert(MintToZeroAddress.selector);

            uint256 end = startTokenId + quantity;
            uint256 tokenId = startTokenId;

            do {
                /// @solidity memory-safe-assembly
                assembly {
                    // Emit the `Transfer` event.
                    log4(
                        0, // Start of data (0, since no data).
                        0, // End of data (0, since no data).
                        _TRANSFER_EVENT_SIGNATURE, // Signature.
                        0, // `address(0)`.
                        toMasked, // `to`.
                        tokenId // `tokenId`.
                    )
                }
                // The `!=` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
            } while (++tokenId != end);

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) _revert(MintToZeroAddress.selector);
        if (quantity == 0) _revert(MintZeroQuantity.selector);
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) _revert(MintERC2309QuantityExceedsLimit.selector);

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address minter,
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(minter, to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        _revert(TransferToNonERC721ReceiverImplementer.selector);
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) _revert(bytes4(0));
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address minter, address to, uint256 quantity) internal virtual {
        _safeMint(minter, to, quantity, '');
    }

    // =============================================================
    //                       APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_approve(to, tokenId, false)`.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _approve(to, tokenId, false);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        bool approvalCheck
    ) internal virtual {
        address owner = ownerOf(tokenId);

        if (approvalCheck && _msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                _revert(ApprovalCallerNotOwnerNorApproved.selector);
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        /// @solidity memory-safe-assembly
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) _revert(OwnershipNotInitializedForExtraData.selector);
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        /// @solidity memory-safe-assembly
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    /**
     * Cannot mint a token that already exists.
     */
    error TokenAlreadyExists();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import {IERC4906} from "../../interfaces/IERC4906.sol";
import {ILayerr721A} from "../../interfaces/ILayerr721A.sol";
import {ILayerrRenderer} from "../../interfaces/ILayerrRenderer.sol";
import {LayerrToken} from "../LayerrToken.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * @title Layerr721A
 * @author 0xth0mas (Layerr)
 * @notice Layerr721A is an ERC721 contract built for the Layerr platform using
 *         the Chiru Labs ERC721A implementation for gas efficient sequential 
 *         minting.
 */
contract Layerr721A is DefaultOperatorFilterer, ERC721A, ILayerr721A, LayerrToken, IERC4906 {

    /** METADATA FUNCTIONS */

    /**
     * @notice Returns the URI for a given `tokenId`
     * @param tokenId id of token to return URI of
     * @return tokenURI location of the token metadata
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return ILayerrRenderer(_getRenderer()).tokenURI(address(this), tokenId);
    }

    /**
     * @notice Returns the URI for the contract metadata
     * @return contractURI location of the contract metadata
     */
    function contractURI() public view returns (string memory) {
        return ILayerrRenderer(_getRenderer()).contractURI(address(this));
    }

    /**
     * @inheritdoc LayerrToken
     */
    function name() public view virtual override(LayerrToken, ERC721A) returns (string memory) {
        return LayerrToken.name();
    }

    /**
     * @inheritdoc LayerrToken
     */
    function symbol() public view virtual override(LayerrToken, ERC721A) returns (string memory) {
        return LayerrToken.symbol();
    }

    /** MINT FUNCTIONS */

    /**
     * @inheritdoc ILayerr721A
     */
    function mintSequential(address minter, address to, uint256 quantity) external onlyMinter {
        _mint(minter, to, quantity);
    }

    /**
     * @inheritdoc ILayerr721A
     */
    function burnTokenId(address from, uint256 tokenId) external onlyMinter {
        if(ownerOf(tokenId) != from) { revert NotAuthorized(); }
        _burn(tokenId, true);
    }

    /**
     * @inheritdoc ILayerr721A
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds
    ) external onlyMinter {
        for(uint256 i = 0;i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            if(ownerOf(tokenId) != from) { revert NotAuthorized(); }
            _burn(tokenId, true);

            unchecked { ++i; }
        }
    }

    /**
     * @inheritdoc ILayerr721A
     */
    function totalSupply() public view override(ERC721A, ILayerr721A) returns (uint256) {
        return ERC721A.totalSupply();
    }

    /**
     * @inheritdoc ILayerr721A
     */
    function totalMintedCollectionAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted) {
        totalMinted = _totalMinted();
        minterMinted = _numberMinted(minter);
    }

    /** OWNER FUNCTIONS */

    /**
     * @inheritdoc ILayerr721A
     */
    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        if(recipients.length != amounts.length) { revert ArrayLengthMismatch(); }

        for(uint256 index = 0;index < recipients.length;) {
            _mint(msg.sender, recipients[index], amounts[index]);

            unchecked { ++index; }
        }
    }

    /**
     * @notice Subscribes to an operator filter registry
     * @param operatorFilterRegistry operator filter address to subscribe to
     */
    function setOperatorFilter(address operatorFilterRegistry) external onlyOwner {
        if (operatorFilterRegistry != address(0)) {
            OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
                address(this),
                operatorFilterRegistry
            );
        }
    }

    /**
     * @notice Unsubscribes from the operator filter registry
     */
    function removeOperatorFilter() external onlyOwner {
        OPERATOR_FILTER_REGISTRY.unregister(
            address(this)
        );
    }

    /**
     * @inheritdoc ILayerr721A
     */
    function updateMetadataAllTokens() external onlyOwner {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    /**
     * @inheritdoc ILayerr721A
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external onlyOwner {
        for(uint256 i; i < tokenIds.length; ) {
            emit MetadataUpdate(tokenIds[i]);

            unchecked { ++i; }
        }
    }

    /** OPERATOR FILTER OVERRIDES */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /** ERC165 */

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(LayerrToken, ERC721A) returns (bool) {
        return
            interfaceId == type(ILayerr721A).interfaceId ||
            LayerrToken.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {AddressValue, StringValue} from "../lib/StorageTypes.sol";
import {LAYERRTOKEN_NAME_SLOT, LAYERRTOKEN_SYMBOL_SLOT, LAYERRTOKEN_RENDERER_SLOT} from "../common/LayerrStorage.sol";
import {LayerrOwnable} from "../common/LayerrOwnable.sol";
import {ILayerrToken} from "../interfaces/ILayerrToken.sol";
import {ILayerrMinter} from "../interfaces/ILayerrMinter.sol";
import {ERC2981} from "../lib/ERC2981.sol";

/**
 * @title LayerrToken
 * @author 0xth0mas (Layerr)
 * @notice LayerrToken contains the general purpose token contract functions for interacting
 *         with the Layerr platform.
 */
contract LayerrToken is ILayerrToken, LayerrOwnable, ERC2981 {

    /// @dev mapping of allowed mint extensions
    mapping(address => bool) public mintingExtensions;

    modifier onlyMinter() {
        if (!mintingExtensions[msg.sender]) {
            revert NotValidMintingExtension();
        }
        _;
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function name() public virtual view returns(string memory _name) {
        StringValue storage nameValue;
        /// @solidity memory-safe-assembly
        assembly {
            nameValue.slot := LAYERRTOKEN_NAME_SLOT
        }
        _name = nameValue.value;
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function symbol() public virtual view returns(string memory _symbol) {
        StringValue storage symbolValue;
        /// @solidity memory-safe-assembly
        assembly {
            symbolValue.slot := LAYERRTOKEN_SYMBOL_SLOT
        }
        _symbol = symbolValue.value;
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function renderer() external view returns(address _renderer) {
        _renderer = _getRenderer();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(LayerrOwnable, ERC2981) returns (bool) {
        return interfaceId == type(ILayerrToken).interfaceId ||
            ERC2981.supportsInterface(interfaceId) ||
            LayerrOwnable.supportsInterface(interfaceId);
    }

    /* OWNER FUNCTIONS */

    /**
     * @inheritdoc ILayerrToken
     */
    function setRenderer(address _renderer) external onlyOwner {
        _setRenderer(_renderer);

        emit RendererUpdated(_renderer);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function setMintExtension(
        address _extension,
        bool _allowed
    ) external onlyOwner {
        mintingExtensions[_extension] = _allowed;

        emit MintExtensionUpdated(_extension, _allowed);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function setContractAllowedSigner(
        address _extension,
        address _signer,
        bool _allowed
    ) external onlyOwner {
        ILayerrMinter(_extension).setContractAllowedSigner(_signer, _allowed);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function setContractAllowedOracle(
        address _extension,
        address _oracle,
        bool _allowed
    ) external onlyOwner {
        ILayerrMinter(_extension).setContractAllowedOracle(_oracle, _allowed);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function setSignatureValidity(
        address _extension,
        bytes32[] calldata signatureDigests,
        bool invalid
    ) external onlyOwner {
        ILayerrMinter(_extension).setSignatureValidity(signatureDigests, invalid);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function setRoyalty(
        uint96 pct,
        address royaltyReciever
    ) external onlyOwner {
        _setDefaultRoyalty(royaltyReciever, pct);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function editContract(
        string calldata _name,
        string calldata _symbol
    ) external onlyOwner {
        _setName(_name);
        _setSymbol(_symbol);
    }

    /**
     * @notice Called during a proxy deployment to emit the LayerrContractDeployed event
     */
    function initialize() external onlyOwner {
        emit LayerrContractDeployed();
    }

    /**
     * @notice Called to withdraw any funds that may be sent to the contract
     */
    function withdraw() external onlyOwner {
        (bool sent, ) = payable(_getOwner()).call{value: address(this).balance}("");
        if (!sent) {
            revert WithdrawFailed();
        }
    }

    /**
     *  INTERNAL FUNCTIONS
     */

    /**
     * @notice Internal function to set the renderer address in a custom storage slot location
     * @param _renderer address of the renderer to set
     */
    function _setRenderer(address _renderer) internal {
        AddressValue storage rendererValue;
        /// @solidity memory-safe-assembly
        assembly {
            rendererValue.slot := LAYERRTOKEN_RENDERER_SLOT
        }
        rendererValue.value = _renderer;
    }

    /**
     * @notice Internal function to get the renderer address from a custom storage slot location
     * @return _renderer address of the renderer
     */
    function _getRenderer() internal view returns(address _renderer) {
        AddressValue storage rendererValue;
        /// @solidity memory-safe-assembly
        assembly {
            rendererValue.slot := LAYERRTOKEN_RENDERER_SLOT
        }
        _renderer = rendererValue.value;
    }

    /**
     * @notice Internal function to set the token contract name in a custom storage slot location
     * @param _name name for the token contract
     */
    function _setName(string calldata _name) internal {
        StringValue storage nameValue;
        /// @solidity memory-safe-assembly
        assembly {
            nameValue.slot := LAYERRTOKEN_NAME_SLOT
        }
        nameValue.value = _name;
    }

    /**
     * @notice Internal function to set the token contract symbol in a custom storage slot location
     * @param _symbol symbol for the token contract
     */
    function _setSymbol(string calldata _symbol) internal {
        StringValue storage symbolValue;
        /// @solidity memory-safe-assembly
        assembly {
            symbolValue.slot := LAYERRTOKEN_SYMBOL_SLOT
        }
        symbolValue.value = _symbol;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";
/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";
/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}