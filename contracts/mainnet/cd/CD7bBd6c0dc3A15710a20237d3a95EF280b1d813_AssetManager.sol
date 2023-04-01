/**
 *Submitted for verification at polygonscan.com on 2023-03-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
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
        returns (uint256[] memory, uint256[] memory, address[] memory);

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

    function setRegistry(
        address registryAddress
    ) external override isAuthorizedAdmin {
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

    function getContractAddress(
        uint256 key
    ) public view override returns (address) {
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
    function balanceOf(
        address _owner,
        uint256 _id
    ) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _ids
    ) external view returns (uint256[] memory);

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
    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool);
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
    function getNonFungibleBaseType(
        uint256 _id
    ) external pure returns (uint256);

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
    function createNonFungibleType(
        uint256 maxSupply,
        uint256 releaseTimestamp
    ) external returns (uint256);

    /**
        @notice Creates a fungible type.
        @dev Creates a fungible type. This function only creates the type and is not used for minting.
        Reverts if the `maxSupply` is 0 or exceeds the `MAX_TYPE_SUPPLY`.
        @param maxSupply        The maximum amount that can be created of this type, unlimited SHOULD be 2**128 (uint128) as the max. MUST NOT be set to 0
        @param releaseTimestamp The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
        @return                 The `typeId`
    */
    function createFungibleType(
        uint256 maxSupply,
        uint256 releaseTimestamp
    ) external returns (uint256);

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
    function getReleaseTimestamp(
        uint256 typeId
    ) external view returns (uint256);

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
    function getNonFungibleAssets(
        address owner
    ) external view returns (uint256[] memory);

    /**
        @notice Get all fungible assets for a specific user.
        @dev Get all fungible assets for a specific user.
        @param  owner The address of the requested user
        @return An array of Ids that are owned by the user
                An array for the amount owned of each Id
    */
    function getFungibleAssets(
        address owner
    ) external view returns (uint256[] memory, uint256[] memory);

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
    function createStringProperty(
        string calldata name
    ) external returns (uint256);

    /**
        @notice Creates a property of type address.
        @dev Creates a property of type address.
        @param name The name for this property
        @return     The property id
    */
    function createAddressProperty(
        string calldata name
    ) external returns (uint256);

    /**
        @notice Creates a property of type byte.
        @dev Creates a property of type byte.
        @param name The name for this property
        @return     The property id
    */
    function createByteProperty(
        string calldata name
    ) external returns (uint256);

    /**
        @notice Creates a property of type int array.
        @dev Creates a property of type int array.
        @param name The name for this property
        @return     The property id
    */
    function createIntArrayProperty(
        string calldata name
    ) external returns (uint256);

    /**
        @notice Creates a property of type address array.
        @dev Creates a property of type address array.
        @param name The name for this property
        @return     The property id
    */
    function createAddressArrayProperty(
        string calldata name
    ) external returns (uint256);

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
    function getPropertyType(
        uint256 propertyId
    ) external view returns (PropertyType);

    /**
        @notice Get the count of available properties.
        @dev Get the count of available properties.
        @return The property count
    */
    function getPropertyCounter() external view returns (uint256);
}

/**
    @author The Calystral Team
    @title A contract vault that keeps anomalies secured
*/
interface IAnomalyVault is IRegistrableContractState {
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
    ) external;

    /**
        @dev Returns the count of discovered anomalies.
        @return Count of anomalies discovered
    */
    function getDiscoveredSilverAnomaliesCount() external returns (uint256);

    /**
        @dev Returns the count of regular burned Halloween Crates.
        @return Count of regular burned Halloween Crates
    */
    function getRegularHalloweenCratesBurnedCount() external returns (uint256);
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

/**
    @author The Calystral Team
    @title A contract for managing the SynergyOfSerraAssets contract
*/
contract AssetManager is RegistrableContractState {
    /*==============================
    =          CONSTANTS           =
    ==============================*/
    /// @dev 1^18 decimals for fungible assets.
    uint256 public constant DECIMALS = 1e18;
    /// @dev The total amount of cards within one crate.
    uint256 public constant CARDS_PER_CRATE = 6;
    /// @dev The token type id of the Base Set I Crate.
    uint256 public constant BASE_SET_CRATE_TYPEID =
        340282366920938463463374607431768211456;
    /// @dev The token type id of the Transcendent Set Crate.
    uint256 public constant TRANSCENDENT_SET_CRATE_TYPEID =
        680564733841876926926749214863536422912;
    /// @dev The token type id of the Virtuals Set Crate.
    uint256 public constant VIRTUALS_SET_CRATE_TYPEID =
        142918594106794154654617335121342648811520;
    /// @dev The token type id of the Ticket to Serra.
    uint256 public constant TICKET_TO_SERRA_BASETYPEID =
        57896044618658097711785492504343953927655839433583097410118915826251869454336;
    /// @dev The token type id of the Halloween Crate.
    uint256 public constant HALLOWEEN21_CRATE_BASETYPEID =
        57896044618658097711785492504343953927996121800504035873582290433683637665792;
    /// @dev The token type id of the Golden Card Back.
    uint256 public constant GOLDEN_CARD_BACK_BASETYPEID =
        57896044618658097711785492504343954068532739338851621283956003303003908997120;
    /// @dev The token type id of Marbolg in silver quality.
    uint256 public constant MARBOLG_SILVER_BASETYPEID =
        57896044618658097711785492504343954068873021705772559747419377910435677208576;
    /// @dev The token type id of Marbolg in gold quality.
    uint256 public constant MARBOLG_GOLD_BASETYPEID =
        57896044618658097711785492504343954069213304072693498210882752517867445420032;

    /// @dev 1k value.
    uint256 public constant THOUSAND = 1000;
    /// @dev Maximum value for chances.
    uint256 public constant MAX_CHANCE = 100 * THOUSAND;
    /// @dev Chance for cards of type COMMON.
    uint256 public constant COMMON_CHANCE = 70 * THOUSAND;
    /// @dev Chance for cards of type RARE.
    uint256 public constant RARE_CHANCE = 94 * THOUSAND;
    /// @dev Chance for cards of type EPIC.
    uint256 public constant EPIC_CHANCE = 99 * THOUSAND;
    /// @dev Chance for cards of type LEGENDARY.
    uint256 public constant LEGENDARY_CHANCE = 100 * THOUSAND;
    /// @dev Chance for cards of type ARTIFACT.
    uint256 public constant ARTIFACT_CHANCE = 1;
    /// @dev Chance for quality of type METAL.
    uint256 public constant METAL_CHANCE = 84 * THOUSAND;
    /// @dev Chance for quality of type BRONZE.
    uint256 public constant BRONZE_CHANCE = 94 * THOUSAND;
    /// @dev Chance for quality of type SILVER.
    uint256 public constant SILVER_CHANCE = 99 * THOUSAND;
    /// @dev Chance for quality of type GOLD.
    uint256 public constant GOLD_CHANCE = 100 * THOUSAND;

    /*==============================
    =            STORAGE           =
    ==============================*/
    /// @dev Array of common card ids.
    uint256[] private _common_card_ids;
    /// @dev Array of rare card ids.
    uint256[] private _rare_card_ids;
    /// @dev Array of epic card ids.
    uint256[] private _epic_card_ids;
    /// @dev Array of legendary card ids.
    uint256[] private _legendary_card_ids;
    /// @dev Array of artifact card ids.
    uint256[] private _artifact_card_ids;

    /// @dev crate token id => crate amounts array.
    mapping(uint256 => uint256[10]) private _crate_amounts;
    /// @dev crate token id => crate pricing array.
    mapping(uint256 => uint256[10]) private _crate_pricing;

    /*==============================
    =          MODIFIERS           =
    ==============================*/
    modifier isAuthorizedBOSS() {
        require(msg.sender == getContractAddress(1000), "Unauthorized call");
        _;
    }

    modifier isAuthorizedCrateOpener() {
        require(msg.sender == getContractAddress(1005), "Unauthorized call");
        _;
    }

    modifier isAuthorizedHalloweenCrateOpener() {
        require(getContractAddress(1006) == msg.sender, "Unauthorized call");
        _;
    }

    modifier isReleased(uint256 tokenId) {
        require(
            _assetsContract().getReleaseTimestamp(tokenId) <= block.timestamp,
            "This token is not released yet."
        );
        _;
    }

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /** 
        @notice Creates and initializes the contract.
        @dev Creates and initializes the contract including the address of the BOSS.
        Creates the first initial two booster types.
        Contract is INACTIVE by default.
        @param registryAddress      Address of the Registry
    */
    constructor(
        address registryAddress
    ) RegistrableContractState(registryAddress) {
        //init crate amounts
        _crate_amounts[BASE_SET_CRATE_TYPEID] = [
            20 * THOUSAND * DECIMALS,
            50 * THOUSAND * DECIMALS,
            90 * THOUSAND * DECIMALS,
            140 * THOUSAND * DECIMALS,
            200 * THOUSAND * DECIMALS,
            260 * THOUSAND * DECIMALS,
            310 * THOUSAND * DECIMALS,
            350 * THOUSAND * DECIMALS,
            380 * THOUSAND * DECIMALS,
            400 * THOUSAND * DECIMALS
        ];
        _crate_amounts[TRANSCENDENT_SET_CRATE_TYPEID] = [
            20 * THOUSAND * DECIMALS,
            50 * THOUSAND * DECIMALS,
            90 * THOUSAND * DECIMALS,
            140 * THOUSAND * DECIMALS,
            200 * THOUSAND * DECIMALS,
            260 * THOUSAND * DECIMALS,
            310 * THOUSAND * DECIMALS,
            350 * THOUSAND * DECIMALS,
            380 * THOUSAND * DECIMALS,
            400 * THOUSAND * DECIMALS
        ];
        _crate_amounts[VIRTUALS_SET_CRATE_TYPEID] = [
            100 * THOUSAND * DECIMALS,
            250 * THOUSAND * DECIMALS,
            450 * THOUSAND * DECIMALS,
            700 * THOUSAND * DECIMALS,
            1000 * THOUSAND * DECIMALS,
            1300 * THOUSAND * DECIMALS,
            1550 * THOUSAND * DECIMALS,
            1750 * THOUSAND * DECIMALS,
            1900 * THOUSAND * DECIMALS,
            2000 * THOUSAND * DECIMALS
        ];

        //init crate pricing
        _crate_pricing[BASE_SET_CRATE_TYPEID] = [
            100,
            150,
            200,
            250,
            300,
            350,
            400,
            450,
            500,
            550
        ];
        _crate_pricing[TRANSCENDENT_SET_CRATE_TYPEID] = [
            200,
            300,
            400,
            500,
            600,
            700,
            800,
            900,
            1000,
            1100
        ];
        _crate_pricing[VIRTUALS_SET_CRATE_TYPEID] = [
            300,
            400,
            500,
            600,
            700,
            800,
            900,
            1000,
            1100,
            1200
        ];
    }

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/

    /*==============================
    =          RESTRICTED          =
    ==============================*/
    /**
        @notice Mints the Golden Ticket to Serra.
        @dev Mints the Golden Ticket to Serra.
        @param userAccounts Reward winners!
    */
    function mintTicketToSerra(
        address[] memory userAccounts
    ) external isAuthorizedAdmin {
        _assetsContract().mintNonFungible(
            TICKET_TO_SERRA_BASETYPEID,
            userAccounts
        );
    }

    /**
        @notice Mints the Halloween Crate.
        @dev Mints the Halloween Crate.
        @param userAccounts Reward winners!
    */
    function mintHalloweenCrate(
        address[] memory userAccounts
    ) external isAuthorizedAdmin {
        _assetsContract().mintNonFungible(
            HALLOWEEN21_CRATE_BASETYPEID,
            userAccounts
        );
    }

    /**
        @notice Mints the Golden Card Back.
        @dev Mints the Golden Card Back.
        @param userAccounts Serrans interacted with crates before sold out (block number 18717272)
    */
    function mintCardGoldBack(
        address[] memory userAccounts
    ) external isAuthorizedAdmin {
        _assetsContract().mintNonFungible(
            GOLDEN_CARD_BACK_BASETYPEID,
            userAccounts
        );
    }

    /**
        @notice Mints all the silver and golden version of the Marbolg cards and sends them to the Anomaly Vault.
        @dev Mints all the silver and golden version of the Marbolg cards and sends them to the Anomaly Vault.
    */
    function mintAllMarbolgCards() external isAuthorizedAdmin {
        address anomalyVaultAddress = getContractAddress(9);

        for (uint256 i = 0; i < 12; i++) {
            _mintNonFungible(MARBOLG_SILVER_BASETYPEID, anomalyVaultAddress);
        }
        _mintNonFungible(MARBOLG_GOLD_BASETYPEID, anomalyVaultAddress);
    }

    /**
        @notice Updates the metadata base URI.
        @dev Updates the `_metadataBaseURI`.
        @param uri The metadata base URI
    */
    function updateMetadataBaseURI(
        string calldata uri
    ) external isAuthorizedAdmin {
        _assetsContract().updateMetadataBaseURI(uri);
    }

    /**
        @notice Buys booster as a batch for a single user.
        @dev Buys booster as a batch for a single user.
        Reverts if array lengths are unequal.
        Reverts if type id is not existing.
        Reverts if out of stock.
        Emits the `TransferSingle` event.
        @param boosterTypes  Array of booster types that are bought
        @param amounts      Array of amounts for each booster type
        @param to           The receiver
    */
    function buyBoosters(
        uint256[] calldata boosterTypes,
        uint256[] calldata amounts,
        address to
    ) external isAuthorizedBOSS {
        require(
            boosterTypes.length == amounts.length,
            "Array length must match."
        );

        for (uint256 i = 0; i < boosterTypes.length; ++i) {
            _buyBooster(boosterTypes[i], amounts[i], to);
        }
    }

    /**
        @notice Opens transcendent set crates.
        @dev Opens transcendent set crates through meta tx. Burns the crates.
        Reverts if asset is not the transcendent set crate id.
        Reverts if crates with decimals are sent.
        Reverts if there is more than 1 element in types or amounts.
        Emits the `TransferSingle` event for burn and card / artifact creation.
        On-chain randomness:
        A Serran sends the sig (MBBsignature, unique) of his input data. (The increasing nonce makes the sig always unique)
        The CrateOpenerAccount (dev) sends the sig (seedSignature, unique) of the Serran's input data incl. its sig.
        The seedSignature is based on the user input, thus can't be tempered with on the dev side.
        The seedSignature is transparent and can be verified by anyone through signaturePublicKey, thus is used as a unique randomness seed.
        Additionally, the randomness function combines seedSignature with gasleft() so that the opening of multiple crates within one tx is still random.
        @param MBBsignature     Signature for burning the crates (batch)
        @param signer           The signing account (CrateUnlockingAccount)
        @param recipient        The original owner of the crate
        @param typeIds          Array of crate ids
        @param amounts          Array of crate amounts
        @param nonce            Nonce for meta transaction
        @param maxTimestamp     Max duration until the signature is valid
        @param seedSignature    Seed for randomness created through CrateOpenerAccount signature
    */
    function openCrates(
        bytes memory MBBsignature,
        address signer,
        address recipient,
        uint256[] calldata typeIds,
        uint256[] calldata amounts,
        uint256 nonce,
        uint256 maxTimestamp,
        bytes memory seedSignature
    ) external isAuthorizedCrateOpener {
        bytes32 dataHash = _getSeedHash(
            MBBsignature,
            signer,
            recipient,
            typeIds,
            amounts,
            nonce,
            maxTimestamp
        );
        address signaturePublicKey = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(dataHash),
            seedSignature
        );
        require(
            signaturePublicKey == getContractAddress(1005),
            "Invalid randomness seed. Unauthorized signer."
        );
        _assetsContract().metaBatchBurn(
            MBBsignature,
            signer,
            typeIds,
            amounts,
            nonce,
            maxTimestamp
        );
        require(
            typeIds.length == 1 && typeIds[0] == TRANSCENDENT_SET_CRATE_TYPEID,
            "The sent assets are invalid"
        );
        require(amounts[0] % DECIMALS == 0, "Keine halben Sachen");

        uint256 crateAmount = amounts[0] / DECIMALS;
        for (uint256 i = 0; i < crateAmount; i++) {
            uint256[] memory cardsToMint = new uint256[](CARDS_PER_CRATE);
            for (uint256 j = 0; j < CARDS_PER_CRATE - 1; j++) {
                cardsToMint[j] = _getRandomRarityCard(seedSignature);
            }
            cardsToMint[CARDS_PER_CRATE - 1] = _getRandomCard(
                _rare_card_ids,
                seedSignature
            );
            _mintArtifactIfLucky(recipient, seedSignature);
            _mintCards(cardsToMint, recipient);
        }
    }

    /**
        @notice Opens halloween21 crate.
        @dev Opens halloween21 crates through meta tx. Burns the crate.
        Reverts if asset is not the halloween21 crate id.
        Reverts if multiple crates are sent.
        Reverts if there is more than 1 element in types or amounts.
        Emits the `TransferSingle` event for burn and card creation.
        On-chain randomness:
        A Serran sends the sig (MBBsignature, unique) of his input data. (The increasing nonce makes the sig always unique)
        The CrateOpenerAccount (dev) sends the sig (seedSignature, unique) of the Serran's input data incl. its sig.
        The seedSignature is based on the user input, thus can't be tempered with on the dev side.
        The seedSignature is transparent and can be verified by anyone through signaturePublicKey, thus is used as a unique randomness seed.
        Additionally, the randomness function combines seedSignature with gasleft() so that the opening of multiple crates within one tx is still random.
        @param MBBsignature     Signature for burning the crates (batch)
        @param signer           The signing account (equals recipient)
        @param recipient        The original owner of the crate
        @param typeIds          Array of crate ids
        @param amounts          Array of crate amounts
        @param nonce            Nonce for meta transaction
        @param maxTimestamp     Max duration until the signature is valid
        @param seedSignature    Seed for randomness created through HalloweenCrateOpenerAccount signature
    */
    function openHalloweenCrate(
        bytes memory MBBsignature,
        address signer,
        address recipient,
        uint256[] calldata typeIds,
        uint256[] calldata amounts,
        uint256 nonce,
        uint256 maxTimestamp,
        bytes memory seedSignature
    ) external isAuthorizedHalloweenCrateOpener {
        bytes32 dataHash = _getSeedHash(
            MBBsignature,
            signer,
            recipient,
            typeIds,
            amounts,
            nonce,
            maxTimestamp
        );
        address signaturePublicKey = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(dataHash),
            seedSignature
        );
        require(
            signaturePublicKey == getContractAddress(1006),
            "Invalid randomness seed. Unauthorized signer."
        );
        _assetsContract().metaBatchBurn(
            MBBsignature,
            signer,
            typeIds,
            amounts,
            nonce,
            maxTimestamp
        );
        require(
            typeIds.length == 1 &&
                _assetsContract().getNonFungibleBaseType(typeIds[0]) ==
                HALLOWEEN21_CRATE_BASETYPEID,
            "The sent assets are invalid"
        );
        require(amounts[0] == 1, "Keine halben Sachen");

        if (typeIds[0] != HALLOWEEN21_CRATE_BASETYPEID | 1) {
            require(
                IAnomalyVault(getContractAddress(9))
                    .getDiscoveredSilverAnomaliesCount() <= 11,
                "All anomalies have been minted already."
            );
        }

        IAnomalyVault(getContractAddress(9)).free_an_anomaly(
            recipient,
            typeIds[0],
            seedSignature
        );
    }

    /**
        @dev Creates fungible and non-fungible types as a batch. This function only creates the type and is not used for minting.
        NFT types also has a maxSupply since there can be multiple tokens of the same type, e.g. 100x 'Pikachu'.
        Reverts if the `maxSupply` is 0 or exceeds the `MAX_TYPE_SUPPLY`.
        @param isNF                 Flag array if the creation should be a non-fungible, false for fungible tokens
        @param maxSupply            The maximum amounts that can be created of this type, unlimited SHOULD be 2**128 (uint128) as the max. MUST NOT be set to 0
        @param releaseTimestamps    Array of release timestamps
        @return                     The `typeId`
    */
    function createNewTokenTypes(
        bool[] calldata isNF,
        uint256[] calldata maxSupply,
        uint256[] calldata releaseTimestamps
    ) external isAuthorizedAdmin returns (uint256[] memory) {
        uint256 len = isNF.length;
        require(
            len == maxSupply.length && len == releaseTimestamps.length,
            "Array length must match."
        );

        uint256[] memory results = new uint256[](len);
        for (uint256 i = 0; i < len; ++i) {
            results[i] = _createNewTokenType(
                isNF[i],
                maxSupply[i],
                releaseTimestamps[i]
            );
        }
        return results;
    }

    /**
        @notice Sets a release timestamp for a token type.
        @dev Sets a release timestamp for a token type.
        Reverts if `timestamp` == 0.
        Reverts if the `tokenType` is released already.
        @param tokenType        The type which should be set or updated
        @param releaseTimestamp The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
    */
    function setReleaseTimestamp(
        uint256 tokenType,
        uint256 releaseTimestamp
    ) external isAuthorizedAdmin {
        _assetsContract().setReleaseTimestamp(tokenType, releaseTimestamp);
    }

    /**
        @notice Initializes the token ids of all common cards.
        @dev Initializes the token ids of all common cards.
        Reverts if array is initialized already.
    */
    function init_COMMON_CARDS() external isAuthorizedAdmin {
        require(_common_card_ids.length == 0, "Array is initialized already");
        _common_card_ids = [
            57896044618658097711785492504343953940586569376578759021727150908659061489664,
            57896044618658097711785492504343953941947698844262512875580649338386134335488,
            57896044618658097711785492504343953943308828311946266729434147768113207181312,
            57896044618658097711785492504343953950114475650365035998701639916748571410432,
            57896044618658097711785492504343953955558993521100051414115633635656862793728,
            57896044618658097711785492504343953956920122988783805267969132065383935639552,
            57896044618658097711785492504343953958281252456467559121822630495111008485376,
            57896044618658097711785492504343953963725770327202574537236624214019299868672,
            57896044618658097711785492504343953965086899794886328391090122643746372714496,
            57896044618658097711785492504343953967809158730253836098797119503200518406144,
            57896044618658097711785492504343953971892547133305097660357614792381736943616
        ];
    }

    /**
        @notice Initializes the token ids of all rare cards.
        @dev Initializes the token ids of all rare cards.
        Reverts if array is initialized already.
    */
    function init_RARE_CARDS() external isAuthorizedAdmin {
        require(_rare_card_ids.length == 0, "Array is initialized already");
        _rare_card_ids = [
            57896044618658097711785492504343953931058663102792482044752661900569551568896,
            57896044618658097711785492504343953933780922038159989752459658760023697260544,
            57896044618658097711785492504343953937864310441211251314020154049204915798016,
            57896044618658097711785492504343953944669957779630020583287646197840280027136,
            57896044618658097711785492504343953946031087247313774437141144627567352872960,
            57896044618658097711785492504343953954197864053416297560262135205929789947904,
            57896044618658097711785492504343953959642381924151312975676128924838081331200,
            57896044618658097711785492504343953961003511391835066829529627354565154177024,
            57896044618658097711785492504343953966448029262570082244943621073473445560320,
            57896044618658097711785492504343953970531417665621343806504116362654664097792
        ];
    }

    /**
        @notice Initializes the token ids of all epic cards.
        @dev Initializes the token ids of all epic cards.
        Reverts if array is initialized already.
    */
    function init_EPIC_CARDS() external isAuthorizedAdmin {
        require(_epic_card_ids.length == 0, "Array is initialized already");
        _epic_card_ids = [
            57896044618658097711785492504343953928336404167424974337045665041115405877248,
            57896044618658097711785492504343953935142051505843743606313157189750770106368,
            57896044618658097711785492504343953936503180973527497460166655619477842952192,
            57896044618658097711785492504343953947392216714997528290994643057294425718784,
            57896044618658097711785492504343953951475605118048789852555138346475644256256,
            57896044618658097711785492504343953952836734585732543706408636776202717102080,
            57896044618658097711785492504343953973253676600988851514211113222108809789440
        ];
    }

    /**
        @notice Initializes the token ids of all legendary cards.
        @dev Initializes the token ids of all legendary cards.
        Reverts if array is initialized already.
    */
    function init_LEGENDARY_CARDS() external isAuthorizedAdmin {
        require(
            _legendary_card_ids.length == 0,
            "Array is initialized already"
        );
        _legendary_card_ids = [
            57896044618658097711785492504343953929697533635108728190899163470842478723072,
            57896044618658097711785492504343953932419792570476235898606160330296624414720,
            57896044618658097711785492504343953939225439908895005167873652478931988643840,
            57896044618658097711785492504343953948753346182681282144848141487021498564608,
            57896044618658097711785492504343953962364640859518820683383125784292227022848,
            57896044618658097711785492504343953969170288197937589952650617932927591251968
        ];
    }

    /**
        @notice Initializes the token ids of all artifact cards.
        @dev Initializes the token ids of all artifact cards.
        Reverts if array is initialized already.
    */
    function init_ARTIFACT_CARDS() external isAuthorizedAdmin {
        require(_artifact_card_ids.length == 0, "Array is initialized already");
        _artifact_card_ids = [
            57896044618658097711785492504343953974614806068672605368064611651835882635264,
            57896044618658097711785492504343953974955088435593543831527986259267650846720,
            57896044618658097711785492504343953975295370802514482294991360866699419058176,
            57896044618658097711785492504343953975635653169435420758454735474131187269632,
            57896044618658097711785492504343953975975935536356359221918110081562955481088,
            57896044618658097711785492504343953976316217903277297685381484688994723692544,
            57896044618658097711785492504343953976656500270198236148844859296426491904000,
            57896044618658097711785492504343953976996782637119174612308233903858260115456,
            57896044618658097711785492504343953977337065004040113075771608511290028326912,
            57896044618658097711785492504343953977677347370961051539234983118721796538368,
            57896044618658097711785492504343953978017629737881990002698357726153564749824,
            57896044618658097711785492504343953978357912104802928466161732333585332961280
        ];
    }

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    /**
        @notice Returns a token id where the type id is increased.
        @dev Returns a token id where the type id is increased.
        @param typeId       A valid token id
        @param increment    The increment for the type id
        @return             The token id where the type is increased by `increment`
    */
    function getIncreasedTypeId(
        uint256 typeId,
        uint256 increment
    ) public pure returns (uint256) {
        return (((typeId >> 128) + increment) << 128);
    }

    /**
        @notice Get the crate pricing for each tier.
        @dev Get the crate pricing for each tier.
        @param  tokenId Token Id of the crate
        @return The crate pricing for each tier
    */
    function getCratePricing(
        uint256 tokenId
    ) public view returns (uint256[] memory) {
        uint256 len = _crate_pricing[tokenId].length;
        uint256[] memory result = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = _crate_pricing[tokenId][i];
        }
        return result;
    }

    /**
        @notice Get the total price in cents for a specific amount crates.
        @dev Get the total price in cents for a specific amount crates.
        @param tokenId  Token Id of the crate
        @param amount   The requested amount crates
        @return         The total price in cents for a specific amount of crates
    */
    function getCratePrice(
        uint256 tokenId,
        uint256 amount
    ) public view returns (uint256) {
        uint256 mintedSupply = _assetsContract().getMintedSupply(tokenId);
        return _getCratePrice(tokenId, amount, mintedSupply) / DECIMALS;
    }

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
    /**
        @dev Returns the target Assets Contract object.
        @return The target Assets Contract object
    */
    function _assetsContract() internal view returns (IAssets) {
        IAssets assetsContract = IAssets(getContractAddress(2));
        return assetsContract;
    }

    /**
        @dev Creates fungible and non-fungible types. This function only creates the type and is not used for minting.
        NFT types also has a maxSupply since there can be multiple tokens of the same type, e.g. 100x 'Pikachu'.
        Reverts if the `maxSupply` is 0 or exceeds the `MAX_TYPE_SUPPLY`.
        @param isNF             Flag if the creation should be a non-fungible, false for fungible tokens
        @param maxSupply        The maximum amount that can be created of this type, unlimited SHOULD be 2**128 (uint128) as the max. MUST NOT be set to 0
        @param releaseTimestamp The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
        @return                 The `typeId`
    */
    function _createNewTokenType(
        bool isNF,
        uint256 maxSupply,
        uint256 releaseTimestamp
    ) private returns (uint256) {
        if (isNF) {
            return
                _assetsContract().createNonFungibleType(
                    maxSupply,
                    releaseTimestamp
                );
        } else {
            return
                _assetsContract().createFungibleType(
                    maxSupply,
                    releaseTimestamp
                );
        }
    }

    /**
        @dev Calculates the price for a specific amount of crates.
        @param tokenId      Token Id of the crate
        @param amount       The requested amount crates
        @return             The total price in cents for a specific amount of crates
    */
    function _getCratePrice(
        uint256 tokenId,
        uint256 amount,
        uint256 mintedSupply
    ) private view returns (uint256) {
        uint256 result;

        (uint256 level, uint256 levelLeft) = _getTierLeft(
            tokenId,
            mintedSupply
        );
        mintedSupply += levelLeft;
        if (levelLeft < amount) {
            result += levelLeft * _crate_pricing[tokenId][level];
            result += _getCratePrice(tokenId, amount - levelLeft, mintedSupply);
        } else {
            result += amount * _crate_pricing[tokenId][level];
        }

        return result;
    }

    /**
        @dev Calculates how many crates are left at current tier based on the `mintedSupply` argument.
        @param tokenId      The token Id of a crate
        @param mintedSupply Indicator for how many crates are minted already
        @return             The tier index, the amount left for this tier
    */
    function _getTierLeft(
        uint256 tokenId,
        uint256 mintedSupply
    ) private view returns (uint256, uint256) {
        for (uint256 i = 0; i < _crate_amounts[tokenId].length; i++) {
            if (mintedSupply < _crate_amounts[tokenId][i]) {
                return (i, _crate_amounts[tokenId][i] - mintedSupply);
            }
        }
        revert("Out of stock.");
    }

    /**
        @dev Get the data hash required for checking the valid public key.
        @param MBBsignature     Signature for burning the crates (batch)
        @param signer           The signing account (CrateUnlockingAccount)
        @param recipient        The original owner of the crate
        @param typeIds          Array of crate ids
        @param amounts          Array of crate amounts
        @param nonce            Nonce for meta transaction
        @param maxTimestamp     Max duration until the signature is valid
        @return                 The keccak256 hash of the data input
    */
    function _getSeedHash(
        bytes memory MBBsignature,
        address signer,
        address recipient,
        uint256[] calldata typeIds,
        uint256[] calldata amounts,
        uint256 nonce,
        uint256 maxTimestamp
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    MBBsignature,
                    signer,
                    recipient,
                    typeIds,
                    amounts,
                    nonce,
                    maxTimestamp
                )
            );
    }

    /**
        @dev Returns a semi random number between 0 and `maxExcluded` (exluded).
        The randomness is based on the provided seed and gasleft().
        @param  maxExcluded The maximum value (excluded)
        @param  seed        The seed which the randomness is based on
        @return             Semi-Random uint256
    */
    function _getRandomNumber(
        uint256 maxExcluded,
        bytes memory seed
    ) private view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(seed, gasleft()))) % maxExcluded;
    }

    /**
        @dev Returns a random element of an uint256[] array.
        @param  arr     The array to choose a random index from
        @param  seed    The seed which the randomness is based on
        @return         The value of the random index within the array
    */
    function _getRandomArrayElement(
        uint256[] memory arr,
        bytes memory seed
    ) private view returns (uint256) {
        return arr[_getRandomNumber(arr.length, seed)];
    }

    /**
        @dev Returns the new tokenId of a card dependant on the chance of an upgrade.
        Increases the typeId of the card by 1, 2, 3 for bronze, silver, gold.
        @param cardId   The card ID (token ID) that potentially will be upgraded
        @param  seed    The seed which the randomness is based on
        @return         The new card ID
    */
    function _getRandomUpgrade(
        uint256 cardId,
        bytes memory seed
    ) private view returns (uint256) {
        uint256 randomNumber = _getRandomNumber(MAX_CHANCE, seed);
        uint256 increment;
        if (randomNumber < METAL_CHANCE) {
            return cardId;
        } else if (randomNumber < BRONZE_CHANCE) {
            increment = 1;
        } else if (randomNumber < SILVER_CHANCE) {
            increment = 2;
        } else if (randomNumber < GOLD_CHANCE) {
            increment = 3;
        } else {
            assert(false);
        }
        return getIncreasedTypeId(cardId, increment);
    }

    /**
        @dev Returns the tokenId of a randomly (based on drop chances) selected card.
        @param  seed    The seed which the randomness is based on
        @return tokenId The tokenId of the card
    */
    function _getRandomRarityCard(
        bytes memory seed
    ) private view returns (uint256 tokenId) {
        uint256 randomNumber = _getRandomNumber(MAX_CHANCE, seed);
        if (randomNumber < COMMON_CHANCE) {
            return _getRandomCard(_common_card_ids, seed);
        } else if (randomNumber < RARE_CHANCE) {
            return _getRandomCard(_rare_card_ids, seed);
        } else if (randomNumber < EPIC_CHANCE) {
            return _getRandomCard(_epic_card_ids, seed);
        } else if (randomNumber < LEGENDARY_CHANCE) {
            return _getRandomCard(_legendary_card_ids, seed);
        }
        assert(false);
    }

    /**
        @dev Returns a random cardId / tokenId based on chances including potential upgrade.
        Includes all scarcity levels (quality & rarity) of cards.
        @param  cardTypesArr    Array of card types
        @param  seed            The seed which the randomness is based on
        @return tokenId         The random cardId / tokenId
    */
    function _getRandomCard(
        uint256[] memory cardTypesArr,
        bytes memory seed
    ) private view returns (uint256 tokenId) {
        uint256 randomCardId = _getRandomArrayElement(cardTypesArr, seed);
        return _getRandomUpgrade(randomCardId, seed);
    }

    /**
        @dev A check if there is still an undiscovered artifact available.
        @return True if their are yet any artifacts to be discovered
    */
    function _artifactAvailable() private view returns (bool) {
        uint256[] memory artifactsArray = _artifact_card_ids;
        for (uint256 i = 0; i < artifactsArray.length; i++) {
            if (_assetsContract().getMintedSupply(artifactsArray[i]) == 0) {
                return true;
            }
        }
        return false;
    }

    /**
        @dev Buys booster(s) of a single booster type for a single user.
        Reverts if booster is not released yet.
        Reverts if booster type id does not exist.
        Reverts if out of stock.
        Emits the `TransferSingle` event.
        @param boosterType  The booster type which is bought
        @param amount       The amount of boosters
        @param to           The receiver
    */
    function _buyBooster(
        uint256 boosterType,
        uint256 amount,
        address to
    ) private isReleased(boosterType) {
        address[] memory toArr = new address[](1);
        toArr[0] = to;
        uint256[] memory amountArr = new uint256[](1);
        amountArr[0] = amount;
        _assetsContract().mintFungible(boosterType, toArr, amountArr);
    }

    /**
        @dev Mints an artifact card if the 1 / 100,000 chance was hit.
        @param  recipient   The owner of the new artifact asset
        @param  seed        The seed which the randomness is based on
    */
    function _mintArtifactIfLucky(
        address recipient,
        bytes memory seed
    ) private {
        if (_getRandomNumber(MAX_CHANCE, seed) < ARTIFACT_CHANCE) {
            if (_artifactAvailable()) {
                uint256[] memory artifactArray = _artifact_card_ids;
                for (uint256 k = 0; k < artifactArray.length; k++) {
                    if (
                        _assetsContract().getMintedSupply(artifactArray[k]) == 0
                    ) {
                        _mintNonFungible(artifactArray[k], recipient);
                        break;
                    }
                }
            }
        }
    }

    /**
        @notice Mints a single NFT.
        @dev Mints a single NFT.
        Reverts if card type id is not existing.
        Emits the `TransferSingle` event.
        @param typeId   The type which should be minted
        @param to       The receiver
    */
    function _mintNonFungible(uint256 typeId, address to) private {
        address[] memory toArr = new address[](1);
        toArr[0] = to;
        _assetsContract().mintNonFungible(typeId, toArr);
    }

    /**
        @notice Mints a cards as NFTs.
        @dev Mints a cards as NFTs.
        Reverts if card type id is not existing.
        Emits the `TransferSingle` event.
        @param typeIds  The types which should be minted
        @param to       The receiver
    */
    function _mintCards(uint256[] memory typeIds, address to) private {
        address[] memory toArr = new address[](1);
        toArr[0] = to;
        for (uint256 i = 0; i < typeIds.length; i++) {
            _assetsContract().mintNonFungible(typeIds[i], toArr);
        }
    }
}