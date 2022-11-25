/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
    Note: Simple contract to use as base for const vals
*/
contract CommonConstants {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    /* is ERC165 */
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

/**
    @title ERC-1155 Mixed Fungible Token Standard
 */
interface IERC1155MixedFungible {
    /**
        @notice Returns true for non-fungible token id.
        @dev    Returns true for non-fungible token id.
        @param _id  Id of the token
        @return     If a token is non-fungible
     */
    function isNonFungible(uint256 _id) external pure returns (bool);

    /**
        @notice Returns true for fungible token id.
        @dev    Returns true for fungible token id.
        @param _id  Id of the token
        @return     If a token is fungible
     */
    function isFungible(uint256 _id) external pure returns (bool);

    /**
        @notice Returns the mint# of a token type.
        @dev    Returns the mint# of a token type.
        @param _id  Id of the token
        @return     The mint# of a token type.
     */
    function getNonFungibleIndex(uint256 _id) external pure returns (uint256);

    /**
        @notice Returns the base type of a token id.
        @dev    Returns the base type of a token id.
        @param _id  Id of the token
        @return     The base type of a token id.
     */
    function getNonFungibleBaseType(uint256 _id)
        external
        pure
        returns (uint256);

    /**
        @notice Returns true if the base type of the token id is a non-fungible base type.
        @dev    Returns true if the base type of the token id is a non-fungible base type.
        @param _id  Id of the token
        @return     The non-fungible base type info as bool
     */
    function isNonFungibleBaseType(uint256 _id) external pure returns (bool);

    /**
        @notice Returns true if the base type of the token id is a fungible base type.
        @dev    Returns true if the base type of the token id is a fungible base type.
        @param _id  Id of the token
        @return     The fungible base type info as bool
     */
    function isNonFungibleItem(uint256 _id) external pure returns (bool);

    /**
        @notice Returns the owner of a token.
        @dev    Returns the owner of a token.
        @param _id  Id of the token
        @return     The owner address
     */
    function ownerOf(uint256 _id) external view returns (address);
}

/**
    @author The Calystral Team
    @title The ERC1155CalystralMixedFungibleMintable' Interface
*/
interface IERC1155CalystralMixedFungibleMintable {
    /**
        @dev MUST emit when a release timestamp is set or updated.
        The `typeId` argument MUST be the id of a type.
        The `timestamp` argument MUST be the timestamp of the release in seconds.
    */
    event OnReleaseTimestamp(uint256 indexed typeId, uint256 timestamp);

    /**
        @notice Updates the metadata base URI.
        @dev Updates the `_metadataBaseURI`.
        @param uri The metadata base URI
    */
    function updateMetadataBaseURI(string calldata uri) external;

    /**
        @notice Creates a non-fungible type.
        @dev Creates a non-fungible type. This function only creates the type and is not used for minting.
        The type also has a maxSupply since there can be multiple tokens of the same type, e.g. 100x 'Pikachu'.
        Reverts if the `maxSupply` is 0 or exceeds the `MAX_TYPE_SUPPLY`.
        @param maxSupply        The maximum amount that can be created of this type, unlimited SHOULD be 2**128 (uint128) as the max. MUST NOT be set to 0
        @param releaseTimestamp The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
        @return                 The `typeId`
    */
    function createNonFungibleType(uint256 maxSupply, uint256 releaseTimestamp)
        external
        returns (uint256);

    /**
        @notice Creates a fungible type.
        @dev Creates a fungible type. This function only creates the type and is not used for minting.
        Reverts if the `maxSupply` is 0 or exceeds the `MAX_TYPE_SUPPLY`.
        @param maxSupply        The maximum amount that can be created of this type, unlimited SHOULD be 2**128 (uint128) as the max. MUST NOT be set to 0
        @param releaseTimestamp The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
        @return                 The `typeId`
    */
    function createFungibleType(uint256 maxSupply, uint256 releaseTimestamp)
        external
        returns (uint256);

    /**
        @notice Mints a non-fungible type.
        @dev Mints a non-fungible type.
        Reverts if type id is not existing.
        Reverts if out of stock.
        Emits the `TransferSingle` event.
        @param typeId   The type which should be minted
        @param toArr    An array of receivers
    */
    function mintNonFungible(uint256 typeId, address[] calldata toArr) external;

    /**
        @notice Mints a fungible type.
        @dev Mints a fungible type.
        Reverts if array lengths are unequal.
        Reverts if type id is not existing.
        Reverts if out of stock.
        Emits the `TransferSingle` event.
        @param typeId   The type which should be minted
        @param toArr    An array of receivers
    */
    function mintFungible(
        uint256 typeId,
        address[] calldata toArr,
        uint256[] calldata quantitiesArr
    ) external;

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        Uses Meta Transactions - transactions are signed by the owner or operator of the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner or approved operator of the owner.
        Reverts if `_to` is the zero address.
        Reverts if balance of holder for token `_id` is lower than the `_value` sent.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param signature    The signature of the signing account as proof for execution allowance
        @param signer       The signing account. This SHOULD be the owner of the asset or an approved operator of the owner.
        @param _to          Target address
        @param _id          ID of the token type
        @param _value       Transfer amount
        @param _data        Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaSafeTransferFrom(
        bytes memory signature,
        address signer,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        Uses Meta Transactions - transactions are signed by the owner or operator of the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner or approved operator of the owner.
        Reverts if `_to` is the zero address.
        Reverts if length of `_ids` is not the same as length of `_values`.
        Reverts if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param signature    The signature of the signing account as proof for execution allowance
        @param signer       The signing account. This SHOULD be the owner of the asset or an approved operator of the owner.
        @param _to          Target address
        @param _ids         IDs of each token type (order and length must match _values array)
        @param _values      Transfer amounts per token type (order and length must match _ids array)
        @param _data        Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaSafeBatchTransferFrom(
        bytes memory signature,
        address signer,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Burns fungible and/or non-fungible tokens.
        @dev Sends FTs and/or NFTs to 0x0 address.
        Uses Meta Transactions - transactions are signed by the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner.
        Emits the `TransferBatch` event where the `to` argument is the 0x0 address.
        @param signature    The signature of the signing account as proof for execution allowance
        @param signer The signing account. This SHOULD be the owner of the asset
        @param ids An array of token Ids which should be burned
        @param values An array of amounts which should be burned. The order matches the order in the ids array
        @param nonce Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaBatchBurn(
        bytes memory signature,
        address signer,
        uint256[] calldata ids,
        uint256[] calldata values,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        Uses Meta Transactions - transactions are signed by the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner.
        @param signature    The signature of the signing account as proof for execution allowance
        @param signer       The signing account. This SHOULD be the owner of the asset
        @param _operator    Address to add to the set of authorized operators
        @param _approved    True if the operator is approved, false to revoke approval
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaSetApprovalForAll(
        bytes memory signature,
        address signer,
        address _operator,
        bool _approved,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Sets a release timestamp.
        @dev Sets a release timestamp.
        Reverts if `timestamp` == 0.
        Reverts if the `typeId` is released already.
        @param typeId       The type which should be set or updated
        @param timestamp    The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
    */
    function setReleaseTimestamp(uint256 typeId, uint256 timestamp) external;

    /**
        @notice Get the release timestamp of a type.
        @dev Get the release timestamp of a type.
        @return The release timestamp of a type.
    */
    function getReleaseTimestamp(uint256 typeId)
        external
        view
        returns (uint256);

    /**
        @notice Get all existing type Ids.
        @dev Get all existing type Ids.
        @return An array of all existing type Ids.
    */
    function getTypeIds() external view returns (uint256[] memory);

    /**
        @notice Get a specific type Id.
        @dev Get a specific type Id.
        Reverts if `typeNonce` is 0 or if it does not exist.
        @param  typeNonce The type nonce for which the id is requested
        @return A specific type Id.
    */
    function getTypeId(uint256 typeNonce) external view returns (uint256);

    /**
        @notice Get all non-fungible assets for a specific user.
        @dev Get all non-fungible assets for a specific user.
        @param  owner The address of the requested user
        @return An array of Ids that are owned by the user
    */
    function getNonFungibleAssets(address owner)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Get all fungible assets for a specific user.
        @dev Get all fungible assets for a specific user.
        @param  owner The address of the requested user
        @return An array of Ids that are owned by the user
                An array for the amount owned of each Id
    */
    function getFungibleAssets(address owner)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    /**
        @notice Get the type nonce.
        @dev Get the type nonce.
        @return The type nonce.
    */
    function getTypeNonce() external view returns (uint256);

    /**
        @notice The amount of tokens that have been minted of a specific type.
        @dev    The amount of tokens that have been minted of a specific type.
                Reverts if the given typeId does not exist.
        @param  typeId The requested type
        @return The minted amount
    */
    function getMintedSupply(uint256 typeId) external view returns (uint256);

    /**
        @notice The amount of tokens that can be minted of a specific type.
        @dev    The amount of tokens that can be minted of a specific type.
                Reverts if the given typeId does not exist.
        @param  typeId The requested type
        @return The maximum mintable amount
    */
    function getMaxSupply(uint256 typeId) external view returns (uint256);

    /**
        @notice Get the burn nonce of a specific user.
        @dev    Get the burn nonce of a specific user / signer.
        @param  signer The requested signer
        @return The burn nonce of a specific user
    */
    function getMetaNonce(address signer) external view returns (uint256);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
    @author The Calystral Team
    @title The RegistrableContractState's Interface
*/
interface IRegistrableContractState is IERC165 {
    /*==============================
    =           EVENTS             =
    ==============================*/
    /// @dev MUST emit when the contract is set to an active state.
    event Activated();
    /// @dev MUST emit when the contract is set to an inactive state.
    event Inactivated();

    /*==============================
    =          FUNCTIONS           =
    ==============================*/
    /**
        @notice Sets the contract state to active.
        @dev Sets the contract state to active.
    */
    function setActive() external;

    /**
        @notice Sets the contract state to inactive.
        @dev Sets the contract state to inactive.
    */
    function setInactive() external;

    /**
        @dev Sets the registry contract object.
        Reverts if the registryAddress doesn't implement the IRegistry interface.
        @param registryAddress The registry address
    */
    function setRegistry(address registryAddress) external;

    /**
        @notice Returns the current contract state.
        @dev Returns the current contract state.
        @return The current contract state (true == active; false == inactive)
    */
    function getIsActive() external view returns (bool);

    /**
        @notice Returns the Registry address.
        @dev Returns the Registry address.
        @return The Registry address
    */
    function getRegistryAddress() external view returns (address);

    /**
        @notice Returns the current address associated with `key` identifier.
        @dev Look-up in the Registry.
        Returns the current address associated with `key` identifier.
        @return The key identifier
    */
    function getContractAddress(uint256 key) external view returns (address);
}

/**
    @author The Calystral Team
    @title The Assets' Interface
*/
interface IAssets is
    IERC1155,
    IERC1155MixedFungible,
    IERC1155CalystralMixedFungibleMintable,
    IRegistrableContractState
{
    /**
        @dev MUST emit when any property type is created.
        The `propertyId` argument MUST be the id of a property.
        The `name` argument MUST be the name of this specific id.
        The `propertyType` argument MUST be the property type.
    */
    event OnCreateProperty(
        uint256 propertyId,
        string name,
        PropertyType indexed propertyType
    );
    /**
        @dev MUST emit when an int type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateIntProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        int256 value
    );
    /**
        @dev MUST emit when an string type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateStringProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        string value
    );
    /**
        @dev MUST emit when an address type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateAddressProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        address value
    );
    /**
        @dev MUST emit when an byte type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateByteProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        bytes32 value
    );
    /**
        @dev MUST emit when an int array type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateIntArrayProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        int256[] value
    );
    /**
        @dev MUST emit when an address array type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateAddressArrayProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        address[] value
    );

    /// @dev Enum representing all existing property types that can be used.
    enum PropertyType {
        INT,
        STRING,
        ADDRESS,
        BYTE,
        INTARRAY,
        ADDRESSARRAY
    }

    /**
        @notice Creates a property of type int.
        @dev Creates a property of type int.
        @param name The name for this property
        @return     The property id
    */
    function createIntProperty(string calldata name) external returns (uint256);

    /**
        @notice Creates a property of type string.
        @dev Creates a property of type string.
        @param name The name for this property
        @return     The property id
    */
    function createStringProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type address.
        @dev Creates a property of type address.
        @param name The name for this property
        @return     The property id
    */
    function createAddressProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type byte.
        @dev Creates a property of type byte.
        @param name The name for this property
        @return     The property id
    */
    function createByteProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type int array.
        @dev Creates a property of type int array.
        @param name The name for this property
        @return     The property id
    */
    function createIntArrayProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type address array.
        @dev Creates a property of type address array.
        @param name The name for this property
        @return     The property id
    */
    function createAddressArrayProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Updates an existing int property for the passed value.
        @dev Updates an existing int property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateIntProperty(
        uint256 tokenId,
        uint256 propertyId,
        int256 value
    ) external;

    /**
        @notice Updates an existing string property for the passed value.
        @dev Updates an existing string property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateStringProperty(
        uint256 tokenId,
        uint256 propertyId,
        string calldata value
    ) external;

    /**
        @notice Updates an existing address property for the passed value.
        @dev Updates an existing address property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateAddressProperty(
        uint256 tokenId,
        uint256 propertyId,
        address value
    ) external;

    /**
        @notice Updates an existing byte property for the passed value.
        @dev Updates an existing byte property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateByteProperty(
        uint256 tokenId,
        uint256 propertyId,
        bytes32 value
    ) external;

    /**
        @notice Updates an existing int array property for the passed value.
        @dev Updates an existing int array property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateIntArrayProperty(
        uint256 tokenId,
        uint256 propertyId,
        int256[] calldata value
    ) external;

    /**
        @notice Updates an existing address array property for the passed value.
        @dev Updates an existing address array property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateAddressArrayProperty(
        uint256 tokenId,
        uint256 propertyId,
        address[] calldata value
    ) external;

    /**
        @notice Get the property type of a property.
        @dev Get the property type of a property.
        @return The property type
    */
    function getPropertyType(uint256 propertyId)
        external
        view
        returns (PropertyType);

    /**
        @notice Get the count of available properties.
        @dev Get the count of available properties.
        @return The property count
    */
    function getPropertyCounter() external view returns (uint256);
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
    @author The Calystral Team
    @title The Registry's Interface
*/
interface IRegistry is IRegistrableContractState {
    /*==============================
    =           EVENTS             =
    ==============================*/
    /**
        @dev MUST emit when an entry in the Registry is set or updated.
        The `key` argument MUST be the key of the entry which is set or updated.
        The `value` argument MUST be the address of the entry which is set or updated.
    */
    event EntrySet(uint256 indexed key, address value);
    /**
        @dev MUST emit when an entry in the Registry is removed.
        The `key` argument MUST be the key of the entry which is removed.
        The `value` argument MUST be the address of the entry which is removed.
    */
    event EntryRemoved(uint256 indexed key, address value);

    /*==============================
    =          FUNCTIONS           =
    ==============================*/
    /**
        @notice Sets the MultiSigAdmin contract as Registry entry 1.
        @dev Sets the MultiSigAdmin contract as Registry entry 1.
        @param msaAddress The contract address of the MultiSigAdmin
    */
    function initializeMultiSigAdmin(address msaAddress) external;

    /**
        @notice Checks if the registry Map contains the key.
        @dev Returns true if the key is in the registry map. O(1).
        @param key  The key to search for
        @return     The boolean result
    */
    function contains(uint256 key) external view returns (bool);

    /**
        @notice Returns the registry map length.
        @dev Returns the number of key-value pairs in the registry map. O(1).
        @return     The registry map length
    */
    function length() external view returns (uint256);

    /**
        @notice Returns the key-value pair stored at position `index` in the registry map.
        @dev Returns the key-value pair stored at position `index` in the registry map. O(1).
        Note that there are no guarantees on the ordering of entries inside the
        array, and it may change when more entries are added or removed.
        Requirements:
        - `index` must be strictly less than {length}.
        @param index    The position in the registry map
        @return         The key-value pair as a tuple
    */
    function at(uint256 index) external view returns (uint256, address);

    /**
        @notice Tries to return the value associated with `key`.
        @dev Tries to return the value associated with `key`.  O(1).
        Does not revert if `key` is not in the registry map.
        @param key    The key to search for
        @return       The key-value pair as a tuple
    */
    function tryGet(uint256 key) external view returns (bool, address);

    /**
        @notice Returns the value associated with `key`.
        @dev Returns the value associated with `key`.  O(1).
        Requirements:
        - `key` must be in the registry map.
        @param key    The key to search for
        @return       The contract address
    */
    function get(uint256 key) external view returns (address);

    /**
        @notice Returns all indices, keys, addresses.
        @dev Returns all indices, keys, addresses as three seperate arrays.
        @return Indices, keys, addresses
    */
    function getAll()
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            address[] memory
        );

    /**
        @notice Adds a key-value pair to a map, or updates the value for an existing
        key.
        @dev Adds a key-value pair to the registry map, or updates the value for an existing
        key. O(1).
        Returns true if the key was added to the registry map, that is if it was not
        already present.
        @param key    The key as an identifier
        @param value  The address of the contract
        @return       Success as a bool
    */
    function set(uint256 key, address value) external returns (bool);

    /**
        @notice Removes a value from the registry map.
        @dev Removes a value from the registry map. O(1).
        Returns true if the key was removed from the registry map, that is if it was present.
        @param key    The key as an identifier
        @return       Success as a bool
    */
    function remove(uint256 key) external returns (bool);

    /**
        @notice Sets a contract state to active.
        @dev Sets a contract state to active.
        @param key    The key as an identifier
    */
    function setContractActiveByKey(uint256 key) external;

    /**
        @notice Sets a contract state to active.
        @dev Sets a contract state to active.
        @param contractAddress The contract's address
    */
    function setContractActiveByAddress(address contractAddress) external;

    /**
        @notice Sets all contracts within the registry to state active.
        @dev Sets all contracts within the registry to state active.
        Does NOT revert if any contract doesn't implement the RegistrableContractState interface.
        Does NOT revert if it is an externally owned user account.
    */
    function setAllContractsActive() external;

    /**
        @notice Sets a contract state to inactive.
        @dev Sets a contract state to inactive.
        @param key    The key as an identifier
    */
    function setContractInactiveByKey(uint256 key) external;

    /**
        @notice Sets a contract state to inactive.
        @dev Sets a contract state to inactive.
        @param contractAddress The contract's address
    */
    function setContractInactiveByAddress(address contractAddress) external;

    /**
        @notice Sets all contracts within the registry to state inactive.
        @dev Sets all contracts within the registry to state inactive.
        Does NOT revert if any contract doesn't implement the RegistrableContractState interface.
        Does NOT revert if it is an externally owned user account.
    */
    function setAllContractsInactive() external;
}

/**
    @author The Calystral Team
    @title A helper parent contract: Pausable & Registry
*/
contract RegistrableContractState is IRegistrableContractState, ERC165 {
    /*==============================
    =          CONSTANTS           =
    ==============================*/

    /*==============================
    =            STORAGE           =
    ==============================*/
    /// @dev Current contract state
    bool private _isActive;
    /// @dev Current registry pointer
    address private _registryAddress;

    /*==============================
    =          MODIFIERS           =
    ==============================*/
    modifier isActive() {
        _isActiveCheck();
        _;
    }

    modifier isAuthorizedAdmin() {
        _isAuthorizedAdmin();
        _;
    }

    modifier isAuthorizedAdminOrRegistry() {
        _isAuthorizedAdminOrRegistry();
        _;
    }

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /**
        @notice Creates and initializes the contract.
        @dev Creates and initializes the contract.
        Registers all implemented interfaces.
        Inheriting contracts are INACTIVE by default.
    */
    constructor(address registryAddress) {
        _registryAddress = registryAddress;

        _registerInterface(type(IRegistrableContractState).interfaceId);
    }

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/

    /*==============================
    =          RESTRICTED          =
    ==============================*/
    function setActive() external override isAuthorizedAdminOrRegistry {
        _isActive = true;

        emit Activated();
    }

    function setInactive() external override isAuthorizedAdminOrRegistry {
        _isActive = false;

        emit Inactivated();
    }

    function setRegistry(address registryAddress)
        external
        override
        isAuthorizedAdmin
    {
        _registryAddress = registryAddress;

        try
            _registryContract().supportsInterface(type(IRegistry).interfaceId)
        returns (bool supportsInterface) {
            require(
                supportsInterface,
                "The provided contract does not implement the Registry interface"
            );
        } catch {
            revert(
                "The provided contract does not implement the Registry interface"
            );
        }
    }

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    function getIsActive() public view override returns (bool) {
        return _isActive;
    }

    function getRegistryAddress() public view override returns (address) {
        return _registryAddress;
    }

    function getContractAddress(uint256 key)
        public
        view
        override
        returns (address)
    {
        return _registryContract().get(key);
    }

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
    /**
        @dev Returns the target Registry object.
        @return The target Registry object
    */
    function _registryContract() internal view returns (IRegistry) {
        return IRegistry(_registryAddress);
    }

    /**
        @dev Checks if the contract is in an active state.
        Reverts if the contract is INACTIVE.
    */
    function _isActiveCheck() internal view {
        require(_isActive == true, "The contract is not active");
    }

    /**
        @dev Checks if the msg.sender is the Admin.
        Reverts if msg.sender is not the Admin.
    */
    function _isAuthorizedAdmin() internal view {
        require(msg.sender == getContractAddress(1), "Unauthorized call");
    }

    /**
        @dev Checks if the msg.sender is the Admin or the Registry.
        Reverts if msg.sender is not the Admin or the Registry.
    */
    function _isAuthorizedAdminOrRegistry() internal view {
        require(
            msg.sender == _registryAddress ||
                msg.sender == getContractAddress(1),
            "Unauthorized call"
        );
    }
}

/**
    @author The Calystral Team
    @title A contract vault that keeps anomalies secured
*/
contract AnomalyVault is
    RegistrableContractState,
    IERC1155TokenReceiver,
    CommonConstants
{
    using Address for address;

    /*==============================
    =            EVENTS            =
    ==============================*/

    /*==============================
    =          CONSTANTS           =
    ==============================*/
    /// @dev The token type id of the Halloween Crate.
    uint256 public constant HALLOWEEN21_CRATE_BASETYPEID =
        57896044618658097711785492504343953927996121800504035873582290433683637665792;
    /// @dev The token type id of Marbolg in silver quality.
    uint256 public constant MARBOLG_SILVER_BASETYPEID =
        57896044618658097711785492504343954068873021705772559747419377910435677208576;
    /// @dev The token type id of Marbolg in gold quality.
    uint256 public constant MARBOLG_GOLD_BASETYPEID =
        57896044618658097711785492504343954069213304072693498210882752517867445420032;

    /*==============================
    =            STORAGE           =
    ==============================*/
    /// @dev Counter for discovered silver anomalies.
    uint256 private _discoveredSilverAnomaliesCount;
    /// @dev Counter for burned regular halloween crates. Does not include the mint#0.
    uint256 private _regularHalloweenCratesBurnedCount;

    /*==============================
    =          MODIFIERS           =
    ==============================*/
    modifier isAuthorizedAssets() {
        require(getContractAddress(2) == msg.sender, "Unauthorized call");
        _;
    }

    modifier isAuthorizedAssetManager() {
        require(getContractAddress(3) == msg.sender, "Unauthorized call");
        _;
    }

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /** 
        @notice Creates and initializes the contract.
        @dev Creates and initializes the contract.
        Contract is INACTIVE by default.
        @param registryAddress      Address of the Registry
    */
    constructor(address registryAddress)
        RegistrableContractState(registryAddress)
    {
        _registerInterface(type(IERC1155TokenReceiver).interfaceId);
    }

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/
    //@override
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    )
        public
        virtual
        override(IERC1155TokenReceiver)
        isActive
        isAuthorizedAssets
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    //@override
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    )
        public
        virtual
        override(IERC1155TokenReceiver)
        isActive
        isAuthorizedAssets
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    /*==============================
    =          RESTRICTED          =
    ==============================*/
    /**
        @notice Frees an anomaly based on chance or guaranteed if mint#0 Helloween crate.
        @dev Frees an anomaly based on chance or guaranteed if mint#0 Helloween crate.
        @param recipient    The original owner of the crate
        @param typeId       Type Id of the crate used to check for mint#0 crate
    */
    function free_an_anomaly(
        address recipient,
        uint256 typeId,
        bytes memory seed
    ) external isActive isAuthorizedAssetManager {
        if (typeId == HALLOWEEN21_CRATE_BASETYPEID | 1) {
            _assetsContract().safeTransferFrom(
                address(this),
                recipient,
                MARBOLG_GOLD_BASETYPEID | 1,
                1,
                "0x0"
            );
        } else {
            _transferAnomalyIfLucky(recipient, seed);
        }
    }

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    /**
        @dev Returns the count of discovered anomalies.
        @return Count of anomalies discovered
    */
    function getDiscoveredSilverAnomaliesCount() public view returns (uint256) {
        return _discoveredSilverAnomaliesCount;
    }

    /**
        @dev Returns the count of regular burned Halloween Crates.
        @return Count of regular burned Halloween Crates
    */
    function getRegularHalloweenCratesBurnedCount()
        public
        view
        returns (uint256)
    {
        return _regularHalloweenCratesBurnedCount;
    }

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
    /**
        @dev Transfer a silver anomaly if the 12 / 100 chance was hit.
        @param  recipient   The owner of the new anomaly
        @param  seed        The seed which the randomness is based on
    */
    function _transferAnomalyIfLucky(address recipient, bytes memory seed)
        private
    {
        if (
            (12 - _discoveredSilverAnomaliesCount) ==
            (100 - _regularHalloweenCratesBurnedCount) ||
            _getRandomNumber(100, seed) < 12
        ) {
            _discoveredSilverAnomaliesCount++;
            _assetsContract().safeTransferFrom(
                address(this),
                recipient,
                MARBOLG_SILVER_BASETYPEID | _discoveredSilverAnomaliesCount,
                1,
                "0x0"
            );
        }
        _regularHalloweenCratesBurnedCount++;
        require(
            _discoveredSilverAnomaliesCount <= 12,
            "All anomalies have been minted already."
        );
    }

    /**
        @dev Returns a semi random number between 0 and `maxExcluded` (exluded).
        The randomness is based on the provided seed and gasleft().
        @param  maxExcluded The maximum value (excluded)
        @param  seed        The seed which the randomness is based on
        @return             Semi-Random uint256
    */
    function _getRandomNumber(uint256 maxExcluded, bytes memory seed)
        private
        view
        returns (uint256)
    {
        return
            uint256(keccak256(abi.encodePacked(seed, gasleft()))) % maxExcluded;
    }

    /**
        @dev Returns the target Assets Contract object.
        @return The target Assets Contract object
    */
    function _assetsContract() internal view returns (IAssets) {
        IAssets assetsContract = IAssets(getContractAddress(2));
        return assetsContract;
    }
}