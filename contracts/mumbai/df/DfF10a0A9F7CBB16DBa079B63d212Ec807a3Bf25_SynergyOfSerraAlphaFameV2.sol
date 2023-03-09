/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
    @author The Calystral Team
    @title The Fame' Interface
*/
interface IFameV2 {
    /* ========== DATA STRUCTURES ========== */
    /**
        @dev Each assets can be added to the contract and those track their info individually.
    */
    struct Asset {
        address contractAddress;
        uint256 tokenId;
        uint256 weight;
        uint256 lastUpdateBlock;
        uint256 famePerShare;
        bool isAllowed;
    }
    /**
        @dev Tracks the data of each user within each Asset.
    */
    struct UserData {
        uint256 balance; // The actual asset balance (owned).
        uint256 share; //   The share for a specific asset used for fame calculations. This is NOT the actual balance of what a user owns within this contract!
        uint256 vault; //   When a user withdraws assets or weights are updated, their current fame earnings are stored in the user's vault. (Removed from the calculated formula)
        uint256 debt; //    This is not the actual spent value, it also contains the deficit based on the time the user wasn't staking in the past.
    }
    /**
        @dev This is a helper object to avoid the "stack too deep" error.
    */
    struct DataObj {
        address from;
        address beneficiary;
        address contractAddress;
        uint256 tokenId;
        uint256 assetId;
        uint256 amount;
    }

    /* ========== EVENTS ========== */
    /**
        @dev MUST emit when crates are staked.
        The `from` argument MUST be the owner of the crates.
        The `beneficiary` argument MUST be befeniciary of the owner.
        The `contractAddress` argument MUST be the assets contract the token comes from.
        The `tokenId` argument MUST be tokenId of the staked asset.
        The `amount` argument MUST be amount of the staked asset.
    */
    event Staked(
        address indexed from,
        address beneficiary,
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 amount
    );
    /**
        @dev MUST emit when crates are withdrawn.
        The `owner` argument MUST be the owner of the crates.
        The `beneficiary` argument MUST be befeniciary of the owner.
        The `contractAddress` argument MUST be the assets contract the token comes from.
        The `tokenId` argument MUST be tokenId of the staked asset.
        The `amount` argument MUST be amount of the staked asset.
    */
    event Withdrawn(
        address indexed owner,
        address beneficiary,
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 amount
    );
    /**
        @dev MUST emit when a user is attributed fame.
        The `user` argument MUST be the user who is attributed fame.
        The `amount` argument MUST be the amount of attributed fame.
    */
    event FameAttributed(address indexed user, uint256 amount);
    /**
        @dev MUST emit when a user spent fame.
        The `user` argument MUST be the user who spent fame.
        The `amount` argument MUST be the amount of spent fame.
    */
    event FameSpent(address indexed user, uint256 amount);
    /**
        @dev MUST emit when a token updates its allowance.
        The `contractAddress` argument MUST be the assets contract adress of a token.
        The `tokenId` argument MUST be the tokenId.
        The `allowance` argument MUST be the allowance as a boolean.
     */
    event AssetAllowanceSet(
        address indexed contractAddress,
        uint256 indexed tokenId,
        bool allowance
    );
    /**
        @dev MUST emit when a token updates its weight.
        The `contractAddress` argument MUST be the assets contract adress of a token.
        The `tokenId` argument MUST be the tokenId.
        The `weight` argument MUST be the weight of the staked asset.
     */
    event AssetWeightSet(
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 weight
    );
    /**
        @dev MUST emit when the weekly reward is updated.
        The `value` argument MUST be the new weekly reward value.
    */
    event WeeklyRewardUpdated(uint256 value);
    /**
        @dev MUST emit when the block time is updated.
        The `milliseconds` argument MUST be the new block time in milliseconds.
    */
    event BlockTimeUpdated(uint256 milliseconds);
    /**
        @dev MUST emit when the fame per block is updated.
        The `famePerBlock` argument MUST be the new fame per block.
    */
    event FamePerBlockUpdated(uint256 famePerBlock);

    /* ========== EXTERNAL FUNCTIONS ========== */
    /**
        @notice SOULD NOT accept single transfer assets.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function SHOULD reject any transfer and MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("false"))`
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
        Reverts if the user sets a new beneficary while holding stakes.
        Reverts if _data does not cointain a valid address as the beneficiary.
        Reverts if nothing is staked.
        Reverts if anything else than base set or transcendent set from the original Assets contract are staked.
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

    /**
        @notice Withdraws any amounts of any tokens from a specific contract.
        @dev Withdraws any amounts of any tokens from a specific contract.
        @param contractAddress  The contract address
        @param tokenIds         The token Id
        @param amounts          The amount
        Reverts if there is nothing to withdraw.
    */
    function withdraw(
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
        @dev    Updates the fame reward for all existing assets based on the asset's weight and their balance.
                Updates lastUpdateBlock and famePerShare of an asset.
                ! Be aware of the gas limit !
                IF block gas limit is reached the Admin needs to manually call updateFameReward for all assetIds before changing any weights.
    */
    function massUpdateFameRewards() external;

    /**
        @dev    Updates the fame reward for one specific asset based on the asset's weight and their balance.
                Updates lastUpdateBlock and famePerShare of an asset.
        @param  assetId The index of an Asset
    */
    function updateFameReward(uint256 assetId) external;

    /* ========== VIEW FUNCTIONS ========== */
    /**
        @notice Get the current total fame balance of a user.
        @dev    Get the current total fame balance of a user.
        @param  userAddress Address of the user
        @return             The current fame balance of a user
    */
    function calculatedFameBalance(address userAddress)
        external
        view
        returns (uint256);

    /**
        @notice Get the current fame balance a user collected for a specific asset.
        @dev    Get the current fame balance a user collected for a specific asset Id.
        @param  assetId     Id of the asset to check the balance for
        @param  userAddress Address of the user
        @return             Fame collected from a specific asset Id 
    */
    function calculatedFameBalanceById(uint256 assetId, address userAddress)
        external
        view
        returns (uint256);

    /**
        @notice Get the fame per block of a user.
        @dev    Get the fame per block of a user.
        @param  userAddress         Address of the user
        @return userFamePerBlock    The fame per block of a user 
    */
    function getUserFamePerBlock(address userAddress)
        external
        view
        returns (uint256 userFamePerBlock);

    /**
        @notice Get the fame per block of a user for a specific asset.
        @dev    Get the fame per block of a user for a specific asset.
        @param  userAddress Address of the user
        @return             The fame per block of a user for a specific asset
    */
    function getUserFamePerBlockById(uint256 assetId, address userAddress)
        external
        view
        returns (uint256);

    /**
        @notice Get an array of the initiated assets.
        @dev    Get an array of the initiated assets.
        @return The array of the initiated assets. 
    */
    function getAssets() external view returns (Asset[] memory);

    /**
        @notice Get the UserData of a user for all initiated assets.
        @dev    Get the UserData of a user for all initiated assets.
        @param userAddress  Address of the user
        @return             The UserData struct of this user for all initiated assets.
    */
    function getUserData(address userAddress)
        external
        view
        returns (UserData[] memory);

    /**
        @notice Get the block time.
        @dev    Get the block time. This value is set by the admin and does not reflect the actual block time of the blockchain.
        @return The block time
    */
    function getBlockTime() external view returns (uint256);

    /**
        @notice Get the weekly fame reward.
        @dev    Get the weekly fame reward.
        @return The weekly fame reward
    */
    function getWeeklyReward() external view returns (uint256);

    /**
        @notice Get the fame reward per block.
        @dev    Get the fame reward per block.
        @return The fame reward per block
    */
    function getFamePerBlock() external view returns (uint256);

    /**
        @notice Get the staked amount of a user's token.
        @dev    Get the staked amount of a user's token.
        @param  contractAddress Token contract address
        @param  tokenId         The token Id
        @param  owner           Address of the owner
        @return                 The staked amount of a user's token
    */
    function getStakedBalance(
        address contractAddress,
        uint256 tokenId,
        address owner
    ) external view returns (uint256);

    /**
        @notice Get the share used to calculate fame of a user.
        @dev    Get the share used to calculate fame of a user.
        @param  contractAddress Token contract address
        @param  tokenId         The token Id
        @param  user            Address of the user
        @return                 The share used to calculate fame of a user
    */
    function getShare(
        address contractAddress,
        uint256 tokenId,
        address user
    ) external view returns (uint256);

    /**
        @notice Get the beneficiary of a user.
        @dev    Get the beneficiary of a user.
        @param  owner   Address of the owner
        @return         The beneficiary of a user
    */
    function getBeneficiary(address owner) external view returns (address);

    /**
        @notice Get the total amount of rewarded fame.
        @dev    Get the total amount of rewarded fame.
        @return The total amount of rewarded fame
    */
    function getTotalFameRewarded() external view returns (uint256);

    /**
        @notice Get the total amount of spent fame.
        @dev    Get the total amount of spent fame.
        @return The total amount of spent fame
    */
    function getTotalFameSpent() external view returns (uint256);

    /**
        @notice Get the total weights.
        @dev    Get the total weights.
        @return The total weights.
    */
    function getTotalWeights() external view returns (uint256);

    /**
        @notice Get the amount of fame a user has in his/her vault.
        @dev    Get the amount of fame a user has in his/her vault.
        @param  userAddress Address of the user
        @return The amount of fame a user has in his/her vault
    */
    function getFameVault(address userAddress) external view returns (uint256);

    /**
        @notice Get the fame debit of a user.
        @dev    Get the fame debit of a user.
        @param  userAddress Address of the user
        @return The fame debit of a user
    */
    function getFameSpent(address userAddress) external view returns (uint256);

    /**
        @notice Get the total asset balance of a user.
        @dev    Get the total asset balance of a user.
        @param  userAddress Address of the user
        @return The total asset balance of a user
    */
    function getTotalAssetBalance(address userAddress)
        external
        view
        returns (uint256);

    /**
        @notice Get the assetId of a token.
        @dev    Get the assetId of a token.
        @param  contractAddress Token contract address
        @param  tokenId         The token Id
        @return assetId         The assetId (index in assets array)
    */
    function getAssetId(address contractAddress, uint256 tokenId)
        external
        returns (uint256 assetId);

    /* ========== RESTRICTED FUNCTIONS ========== */
    /**
        @notice Withdraws any amounts of any tokens from a specific contract for a certain owner.
        @dev Withdraws any amounts of any tokens from a specific contract for a certain owner.
        Attention: The ownership of the asset always stays with the original owner, the function can only enforce
        the return of an asset to the original owner.
        This function can be used to force a full exit when there is an issue, especially with non-SoS-assets.
        This function is a replacement for the metaWithdraw function.
        @param owner            The asset(s)' owner
        @param contractAddress  The contract address
        @param tokenIds         Array of token Ids
        @param amounts          Array of amounts
        Reverts if there is nothing to withdraw.
    */
    function managedWithdraw(
        address owner,
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
        @dev Emergency Withdraw for an amounts of any tokens from a specific contract.
        ! Does not reward Fame !
        Emits Withdrawn(from, beneficiary, contractAddress, tokenId, amount).
        @param owner            The asset(s)' owner
        @param contractAddress  Address of the assets' contract
        @param tokenIds         An array containing ids of each token being transferred
        @param amounts          An array containing amounts of each token being transferred
    */
    function managedEmergencyWithdraw(
        address owner,
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
        @notice Attribute fame.
        @dev    Attribute fame.
        Reverts if attributing amount is 0.
        Reverts if array lengths don't match.
        @param  toArr       address of the user
        @param  amountsArr  amount to attribute
    */
    function attributeFame(
        address[] calldata toArr,
        uint256[] calldata amountsArr
    ) external;

    /**
        @notice Spend fame.
        @dev    Spend fame.
        Reverts if spending amount is 0.
        Reverts if array lengths don't match.
        Reverts if user doesn't have enough fame.
        @param  fromArr     address of the user
        @param  amountsArr  amount to spend
    */
    function spendFame(
        address[] calldata fromArr,
        uint256[] calldata amountsArr
    ) external;

    /**
        @notice Sets an asset to be allowed or not.
        @dev    Sets an asset to be allowed or not (boolean).
        @param contractAddress  Address of the supported assets contract
        @param tokenIds         An array containing ids of each token for allowance
        @param allowedArr       An array containing the allowance of each token
    */
    function setAssetAllowanceBatch(
        address contractAddress,
        uint256[] calldata tokenIds,
        bool[] calldata allowedArr
    ) external;

    /**
        @notice Sets the weight for a specific token of a specific asset contract.
        @dev    Sets the weight for a specific token of a specific asset contract.
        @param contractAddress  Address of the supported assets contract
        @param tokenIds         An array containing ids of each token being weighted
        @param weights          An array containing weights of each token being weighted
        @param withUpdate       True => Updates the rewards for all assets before setting new weights
    */
    function setAssetWeightBatch(
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata weights,
        bool withUpdate
    ) external;

    /**
        @notice Set a new value for the weekly reward.
        @dev    Set a new value for the weekly reward.
        Reverts if value is smaller than 1e18 (as decimals).
        @param  value       new weekly reward value
        @param withUpdate   True => Updates the rewards for all assets before setting new weights
    */
    function setWeeklyReward(uint256 value, bool withUpdate) external;

    /**
        @notice Set a new millisecond value for the block time.
        @dev    Set a new millisecond value for the block time.
        Reverts if block time is set to 0.
        @param  milliseconds new millisecond value
    */
    function setBlockTime(uint256 milliseconds) external;
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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
    Note: Simple contract to use as base for const vals
*/
contract CommonConstants {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
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
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
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
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
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
    @author The Calystral Team
    @title Earn Synergy of Serra's Alpha Fame through Crate deposit!
*/
contract SynergyOfSerraAlphaFameV2 is
    IFameV2,
    IERC1155TokenReceiver,
    RegistrableContractState,
    ReentrancyGuard,
    CommonConstants
{
    /*==============================
    =          CONSTANTS           =
    ==============================*/
    /**
        @notice Count of decimals for fame.
        @dev    10^64 decimals for fame.
    */
    uint256 public constant FAME_DECIMALS = 1e64;
    /**
        @notice Count of max decimals for weekly fame.
        @dev    10^64 decimals for fame.
    */
    uint256 public constant MAX_WEEKLY_FAME = 1e74;
    /**
        @notice Milliseconds per week.
        @dev    Milliseconds per week.
    */
    uint256 public constant MS_PER_WEEK = 604800000;
    /*==============================
    =            STORAGE           =
    ==============================*/
    /**
        @notice The block time in milliseconds for the Polygon Mainnet.
        @dev    The block time in milliseconds for the Polygon Mainnet.
    */
    uint256 public msBlockTime;
    /**
        @notice The weekly distribution amount of fame.
        @dev    The weekly distribution amount of fame.
    */
    uint256 public weeklyReward;
    /**
        @notice Alpha fame distributed in each block.
        @dev    Alpha fame distributed in each block.
    */
    uint256 public famePerBlock;
    /**
        @notice The total amount of fame ever rewarded.
        @dev    The total amount of fame ever rewarded.
    */
    uint256 public totalFameRewarded;
    /**
        @notice The total amount of fame ever spent.
        @dev    The total amount of fame ever spent.
    */
    uint256 public totalFameSpent;

    /**
        @notice Contains all added assets.
        @dev    Contains all added assets.
    */
    Asset[] public assets;

    /**
        @notice Contains the data of an owner related to a specific asset.
        @dev assetId => userAddress => UserData
    */
    mapping(uint256 => mapping(address => UserData)) public assetIdToUserToData;
    /**
        @notice Maps contract address and token Id to the asset Id.
        @dev contractAddress => tokenId => assetId
    */
    mapping(address => mapping(uint256 => uint256))
        public contractAddressToTokenIdToAssetId;

    /// @dev The total amount of weights.
    uint256 private _totalWeights;
    /// @dev When a user withdraws, his current fame earnings are stored in the user's vault. (Removed from the calculated formula)
    mapping(address => uint256) private _fameVault;
    /// @dev This is the actual spent value.
    mapping(address => uint256) private _fameSpent;
    /// @dev owner => beneficiary (CAN NOT be updated as long as the owner has assets in this contract! -> _ownerToTotalAssetBalance)
    mapping(address => address) private _ownerToBeneficiary;
    /// @dev ownerAddress => total asset balance
    mapping(address => uint256) private _ownerToTotalAssetBalance;

    /*==============================
    =          MODIFIERS           =
    ==============================*/
    modifier isAuthorizedFameManager() {
        _isAuthorizedFameManager();
        _;
    }

    modifier updateFameRewards(
        address contractAddress,
        uint256[] calldata tokenIds
    ) {
        _updateFameRewards(contractAddress, tokenIds);
        _;
    }

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /**
        @notice Creates and initializes the contract.
        @dev Creates and initializes the contract.
        Registers all implemented interfaces.
        Contract is INACTIVE by default.
        @param registryAddress  Address of the Registry
    */
    constructor(address registryAddress)
        RegistrableContractState(registryAddress)
    {
        _setBlockTime(2100);

        _registerInterface(type(IFameV2).interfaceId);
        _registerInterface(type(IERC1155TokenReceiver).interfaceId);

        assets.push(Asset(address(0x0), 0, 0, 0, 0, false));

        require(msBlockTime != 0, "BlockTime should not be 0");
    }

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    )
        external
        view
        override(IERC1155TokenReceiver, IFameV2)
        isActive
        returns (bytes4)
    {
        return bytes4(keccak256("false"));
    }

    // deposit
    function onERC1155BatchReceived(
        address,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    )
        external
        override(IERC1155TokenReceiver, IFameV2)
        isActive
        returns (bytes4)
    {
        bytes memory addressData = _data;
        address beneficiary;
        assembly {
            beneficiary := mload(add(addressData, 20))
        }
        _stake(_from, beneficiary, msg.sender, _ids, _values);
        return ERC1155_BATCH_ACCEPTED;
    }

    function withdraw(
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external override {
        _withdraw(msg.sender, contractAddress, tokenIds, amounts);
    }

    function massUpdateFameRewards() public {
        for (uint256 i = 1; i < assets.length; i++) {
            updateFameReward(i);
        }
    }

    function updateFameReward(uint256 assetId) public {
        Asset storage asset = assets[assetId];
        if (asset.weight == 0) {
            asset.lastUpdateBlock = block.number;
            return;
        }
        if (block.number <= asset.lastUpdateBlock) {
            return;
        }
        uint256 stakedAssetBalance = IERC1155(asset.contractAddress).balanceOf(
            address(this),
            asset.tokenId
        );
        if (stakedAssetBalance == 0) {
            asset.lastUpdateBlock = block.number;
            return;
        }
        uint256 fameReward = _getFameReward(asset);
        asset.famePerShare += fameReward / stakedAssetBalance;
        totalFameRewarded += fameReward;
        asset.lastUpdateBlock = block.number;
    }

    /*==============================
    =          RESTRICTED          =
    ==============================*/
    function managedWithdraw(
        address owner,
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external override isAuthorizedFameManager {
        _withdraw(owner, contractAddress, tokenIds, amounts);
    }

    /**
    IF we make use of this - even once - the totalFameRewarded, totalFameSpent and events for spent and attributed fame will be messy because
     a user is able to spend pending fame (it's legit!) which will not be attributed in the emergency exit function.
    */
    function managedEmergencyWithdraw(
        address owner,
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external override isAuthorizedFameManager {
        _emergencyWithdraw(owner, contractAddress, tokenIds, amounts);
    }

    function attributeFame(
        address[] calldata toArr,
        uint256[] calldata amountsArr
    ) external override isAuthorizedFameManager {
        _attributeFame(toArr, amountsArr);
    }

    function spendFame(
        address[] calldata fromArr,
        uint256[] calldata amountsArr
    ) external override isAuthorizedFameManager {
        _spendFame(fromArr, amountsArr);
    }

    function setAssetAllowanceBatch(
        address contractAddress,
        uint256[] calldata tokenIds,
        bool[] calldata allowedArr
    ) external override isAuthorizedFameManager {
        _setAssetAllowanceBatch(contractAddress, tokenIds, allowedArr);
    }

    function setAssetWeightBatch(
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata weights,
        bool withUpdate
    ) external override isAuthorizedFameManager {
        _setAssetWeightBatch(contractAddress, tokenIds, weights, withUpdate);
    }

    // The value param is required to have 1e64 decimals
    function setWeeklyReward(uint256 value, bool withUpdate)
        external
        override
        isAuthorizedFameManager
    {
        _setWeeklyReward(value, withUpdate);
    }

    function setBlockTime(uint256 milliseconds)
        external
        override
        isAuthorizedFameManager
    {
        _setBlockTime(milliseconds);
    }

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    function calculatedFameBalance(address userAddress)
        public
        view
        override
        returns (uint256 fameBalance)
    {
        for (uint256 i = 1; i < assets.length; i++) {
            fameBalance += calculatedFameBalanceById(i, userAddress);
        }

        fameBalance =
            fameBalance +
            _fameVault[userAddress] -
            _fameSpent[userAddress];
    }

    function calculatedFameBalanceById(uint256 assetId, address userAddress)
        public
        view
        override
        returns (uint256)
    {
        Asset storage asset = assets[assetId];
        UserData storage user = assetIdToUserToData[assetId][userAddress];
        uint256 famePerShare = asset.famePerShare;
        uint256 stakedAssetBalance = IERC1155(asset.contractAddress).balanceOf(
            address(this),
            asset.tokenId
        );
        if (block.number > asset.lastUpdateBlock && stakedAssetBalance != 0) {
            uint256 fameReward = _getFameReward(asset);
            famePerShare += fameReward / stakedAssetBalance;
        }

        return user.share * famePerShare + user.vault - user.debt;
    }

    function getUserFamePerBlock(address userAddress)
        public
        view
        override
        returns (uint256 userFamePerBlock)
    {
        for (uint256 i = 1; i < assets.length; i++) {
            userFamePerBlock += getUserFamePerBlockById(i, userAddress);
        }
    }

    function getUserFamePerBlockById(uint256 assetId, address userAddress)
        public
        view
        override
        returns (uint256)
    {
        Asset storage asset = assets[assetId];
        UserData storage user = assetIdToUserToData[assetId][userAddress];
        uint256 stakedAssetBalance = IERC1155(asset.contractAddress).balanceOf(
            address(this),
            asset.tokenId
        );
        if (_totalWeights == 0 || stakedAssetBalance == 0) {
            return 0;
        }
        uint256 famePerAssetPerBlock = (famePerBlock / _totalWeights) *
            asset.weight;
        return (famePerAssetPerBlock / stakedAssetBalance) * user.share;
    }

    function getAssets() public view override returns (Asset[] memory) {
        return assets;
    }

    function getUserData(address userAddress)
        public
        view
        override
        returns (UserData[] memory)
    {
        UserData[] memory userData = new UserData[](assets.length - 1);
        for (uint256 i = 1; i < assets.length; i++) {
            userData[i - 1] = (assetIdToUserToData[i][userAddress]);
        }
        return userData;
    }

    function getBlockTime() public view override returns (uint256) {
        return msBlockTime;
    }

    function getWeeklyReward() public view override returns (uint256) {
        return weeklyReward;
    }

    function getFamePerBlock() public view override returns (uint256) {
        return famePerBlock;
    }

    function getStakedBalance(
        address contractAddress,
        uint256 tokenId,
        address owner
    ) public view override returns (uint256) {
        return
            assetIdToUserToData[getAssetId(contractAddress, tokenId)][owner]
                .balance;
    }

    function getShare(
        address contractAddress,
        uint256 tokenId,
        address user
    ) public view override returns (uint256) {
        return
            assetIdToUserToData[getAssetId(contractAddress, tokenId)][user]
                .share;
    }

    function getBeneficiary(address owner)
        public
        view
        override
        returns (address)
    {
        return _ownerToBeneficiary[owner];
    }

    function getTotalFameRewarded() public view override returns (uint256) {
        return totalFameRewarded;
    }

    function getTotalFameSpent() public view override returns (uint256) {
        return totalFameSpent;
    }

    function getTotalWeights() public view override returns (uint256) {
        return _totalWeights;
    }

    function getFameVault(address userAddress)
        public
        view
        override
        returns (uint256)
    {
        return _fameVault[userAddress];
    }

    function getFameSpent(address userAddress)
        public
        view
        override
        returns (uint256)
    {
        return _fameSpent[userAddress];
    }

    function getTotalAssetBalance(address userAddress)
        public
        view
        override
        returns (uint256)
    {
        return _ownerToTotalAssetBalance[userAddress];
    }

    function getAssetId(address contractAddress, uint256 tokenId)
        public
        view
        override
        returns (uint256 assetId)
    {
        assetId = contractAddressToTokenIdToAssetId[contractAddress][tokenId];
        require(assetId != 0, "AssetId can not be 0");
    }

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
    /**
        @dev Stores the user's assets and rewards his/her beneficiary with fame over time.
        Reverts if the user sets a new beneficary while holding stakes.
        Reverts if nothing is staked.
        Reverts if one of the staked assets is not allowed by this contract.
        Emits Staked(from, beneficiary, contractAddress, tokenId, amount).
        @param from             The address which previously owned the token
        @param beneficiary      The beneficiary address
        @param contractAddress  Address of the supported assets contract
        @param tokenIds         An array containing ids of each token being transferred
        @param amounts          An array containing amounts of each token being transferred
    */
    function _stake(
        address from,
        address beneficiary,
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private nonReentrant updateFameRewards(contractAddress, tokenIds) {
        require(beneficiary != address(0), "Beneficiary is not set");
        require(
            _ownerToBeneficiary[from] == beneficiary ||
                _ownerToTotalAssetBalance[from] == 0,
            "You are not allowed to benefit a new SoS account"
        );
        _ownerToBeneficiary[from] = beneficiary;

        DataObj memory stakingData = DataObj(
            from,
            _ownerToBeneficiary[from],
            contractAddress,
            0,
            0,
            0
        );

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            stakingData.tokenId = tokenIds[i];
            stakingData.amount = amounts[i];
            stakingData.assetId = getAssetId(
                stakingData.contractAddress,
                stakingData.tokenId
            );
            Asset storage asset = assets[stakingData.assetId];
            UserData storage owner = assetIdToUserToData[stakingData.assetId][
                stakingData.from
            ];
            UserData storage fameBeneficiary = assetIdToUserToData[
                stakingData.assetId
            ][stakingData.beneficiary];

            require(asset.isAllowed == true, "The asset is not allowed");

            _attributePendingFame(asset, fameBeneficiary);
            _increaseBalance(
                stakingData.from,
                owner,
                fameBeneficiary,
                stakingData.amount
            );
            _updateDebt(asset, fameBeneficiary);

            emit Staked(
                stakingData.from,
                stakingData.beneficiary,
                stakingData.contractAddress,
                stakingData.tokenId,
                stakingData.amount
            );
        }
    }

    /**
        @dev Withdraws any amounts of any tokens from a specific contract for a certain user.
        Emits Withdrawn(from, beneficiary, contractAddress, tokenId, amount).
        @param from             The address which previously owned the token
        @param contractAddress  Address of the assets' contract
        @param tokenIds         An array containing ids of each token being transferred
        @param amounts          An array containing amounts of each token being transferred
    */
    function _withdraw(
        address from,
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private nonReentrant updateFameRewards(contractAddress, tokenIds) {
        DataObj memory withdrawData = DataObj(
            from,
            _ownerToBeneficiary[from],
            contractAddress,
            0,
            0,
            0
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            withdrawData.tokenId = tokenIds[i];
            withdrawData.amount = amounts[i];
            withdrawData.assetId = getAssetId(
                withdrawData.contractAddress,
                withdrawData.tokenId
            );
            Asset storage asset = assets[withdrawData.assetId];
            UserData storage owner = assetIdToUserToData[withdrawData.assetId][
                withdrawData.from
            ];
            UserData storage fameBeneficiary = assetIdToUserToData[
                withdrawData.assetId
            ][withdrawData.beneficiary];

            _attributePendingFame(asset, fameBeneficiary);
            _decreaseBalance(
                withdrawData.from,
                owner,
                fameBeneficiary,
                withdrawData.amount
            );
            _updateDebt(asset, fameBeneficiary);

            emit Withdrawn(
                withdrawData.from,
                withdrawData.beneficiary,
                withdrawData.contractAddress,
                withdrawData.tokenId,
                withdrawData.amount
            );
        }

        IERC1155(contractAddress).safeBatchTransferFrom(
            address(this),
            from,
            tokenIds,
            amounts,
            "0x0"
        );
    }

    /**
        @dev Emergency Withdraw for an amounts of any tokens from a specific contract.
        ! Does not reward Fame !
        Emits Withdrawn(from, beneficiary, contractAddress, tokenId, amount).
        @param from             The address which previously owned the token
        @param contractAddress  Address of the assets' contract
        @param tokenIds         An array containing ids of each token being transferred
        @param amounts          An array containing amounts of each token being transferred
    */
    function _emergencyWithdraw(
        address from,
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private nonReentrant {
        DataObj memory withdrawData = DataObj(
            from,
            _ownerToBeneficiary[from],
            contractAddress,
            0,
            0,
            0
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            withdrawData.tokenId = tokenIds[i];
            withdrawData.amount = amounts[i];
            withdrawData.assetId = getAssetId(
                withdrawData.contractAddress,
                withdrawData.tokenId
            );
            UserData storage owner = assetIdToUserToData[withdrawData.assetId][
                withdrawData.from
            ];
            UserData storage fameBeneficiary = assetIdToUserToData[
                withdrawData.assetId
            ][withdrawData.beneficiary];

            _decreaseBalance(
                withdrawData.from,
                owner,
                fameBeneficiary,
                withdrawData.amount
            );

            emit Withdrawn(
                withdrawData.from,
                withdrawData.beneficiary,
                withdrawData.contractAddress,
                withdrawData.tokenId,
                withdrawData.amount
            );
        }

        IERC1155(contractAddress).safeBatchTransferFrom(
            address(this),
            from,
            tokenIds,
            amounts,
            "0x0"
        );
    }

    /**
        @dev    Updates the debt of a user.
        @param  asset   The Asset object
        @param  user    The UserData object
    */
    function _updateDebt(Asset storage asset, UserData storage user) private {
        user.debt = user.share * asset.famePerShare;
    }

    /**
        @dev    Calculates and attributes the pending alpha fame to the user's vault.
        @param  asset   The Asset object
        @param  user    The UserData object
    */
    function _attributePendingFame(Asset storage asset, UserData storage user)
        private
    {
        if (user.share > 0) {
            uint256 pending = user.share * asset.famePerShare - user.debt;
            user.vault += pending;
        }
    }

    /**
        @dev    Increases the balance of a user while increasing the share of his shareholder (the beneficiary).
        @param  from        Address of the owner
        @param  owner       The UserData object of the owner
        @param  shareholder The UserData object of the shareholder
        @param  amount      The amount to increase the balance/share by
    */
    function _increaseBalance(
        address from,
        UserData storage owner,
        UserData storage shareholder,
        uint256 amount
    ) private {
        require(amount > 0, "Zero amount not allowed");
        owner.balance += amount;
        shareholder.share += amount;
        _ownerToTotalAssetBalance[from] += amount;
    }

    /**
        @dev    Decreases the balance of a user while decreasing the share of his shareholder (the beneficiary).
                MUST throw if a user wants to withdraw more than he owns
        @param  from        Address of the owner
        @param  owner       The UserData object of the owner
        @param  shareholder The UserData object of the shareholder
        @param  amount      The amount to decrease the balance/share by
    */
    function _decreaseBalance(
        address from,
        UserData storage owner,
        UserData storage shareholder,
        uint256 amount
    ) private {
        require(amount > 0, "Zero amount not allowed");
        owner.balance -= amount; //throws if user wants to withdraw more than he owns
        shareholder.share -= amount;
        _ownerToTotalAssetBalance[from] -= amount;
    }

    /**
        @dev    Attribute fame.
        Reverts if attributing amount is 0.
        Reverts if array lengths don't match.
        @param  toArr       address of the user
        @param  amountsArr  amount to attribute
    */
    function _attributeFame(
        address[] calldata toArr,
        uint256[] calldata amountsArr
    ) private nonReentrant {
        require(toArr.length == amountsArr.length, "Array length must match");
        for (uint256 i = 0; i < toArr.length; ++i) {
            address to = toArr[i];
            uint256 amount = amountsArr[i];

            require(amount > 0, "Zero amount not allowed");
            _fameVault[to] += amount;
            totalFameRewarded += amount;

            emit FameAttributed(to, amount);
        }
    }

    /**
        @dev    Spend fame.
        Reverts if spending amount is 0.
        Reverts if array lengths don't match.
        Reverts if user doesn't have enough fame.
        @param  fromArr     address of the user
        @param  amountsArr  amount to spend
    */
    function _spendFame(
        address[] calldata fromArr,
        uint256[] calldata amountsArr
    ) private nonReentrant {
        require(fromArr.length == amountsArr.length, "Array length must match");
        for (uint256 i = 0; i < fromArr.length; ++i) {
            address from = fromArr[i];
            uint256 amount = amountsArr[i];

            require(amount > 0, "Zero amount not allowed");
            require(calculatedFameBalance(from) >= amount, "Not enough Fame");
            _fameSpent[from] += amount;
            totalFameSpent += amount;

            emit FameSpent(from, amount);
        }
    }

    /**
        @dev    Sets an asset to be allowed or not (boolean).
        @param  contractAddress  Address of the supported assets contract
        @param  tokenIds         An array containing ids of each token for allowance
        @param  allowedArr       An array containing the allowance of each token
    */
    function _setAssetAllowanceBatch(
        address contractAddress,
        uint256[] calldata tokenIds,
        bool[] calldata allowedArr
    ) private {
        require(
            tokenIds.length == allowedArr.length,
            "Array length must match"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 assetId = contractAddressToTokenIdToAssetId[
                contractAddress
            ][tokenId]; // we don't use the function here because 0 would be a legit outcome (not existing!)
            if (assetId == 0) {
                Asset memory asset = Asset(
                    contractAddress,
                    tokenId,
                    0,
                    block.number,
                    0,
                    allowedArr[i]
                );
                contractAddressToTokenIdToAssetId[contractAddress][
                    tokenId
                ] = assets.length;
                assets.push(asset);
            } else {
                Asset storage asset = assets[assetId];
                asset.isAllowed = allowedArr[i];
            }

            emit AssetAllowanceSet(contractAddress, tokenId, allowedArr[i]);
        }
    }

    /**
        @dev    Sets the weight for a specific token of a specific asset contract.
        @param  contractAddress  Address of the supported assets contract
        @param  tokenIds         An array containing ids of each token being weighted
        @param  weights          An array containing weights of each token being weighted
        @param  withUpdate       Updates all asset calculations before setting new weights. SHOULD be true unless the block gas limit is reached (requires manual update in multiple txs).
    */
    function _setAssetWeightBatch(
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata weights,
        bool withUpdate
    ) private {
        require(tokenIds.length == weights.length, "Array length must match");
        if (withUpdate) {
            massUpdateFameRewards();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 assetId = getAssetId(contractAddress, tokenId);
            Asset storage asset = assets[assetId];
            uint256 currentWeight = asset.weight;
            uint256 newWeight = weights[i];

            _totalWeights = _totalWeights - currentWeight + newWeight;
            asset.weight = newWeight;

            emit AssetWeightSet(contractAddress, tokenId, newWeight);
        }
    }

    /**
        @dev    Set a new value for the weekly reward.
        Reverts if value is smaller than 1e64 (as decimals).
        Reverts if value is bigger than 1e74 (as decimals).
        It updates the `famePerBlock` value.
        Emits WeeklyRewardUpdated(value).
        @param  value       new weekly reward value
        @param  withUpdate  Updates all asset calculations before setting new weights. SHOULD be true unless the block gas limit is reached (requires manual update in multiple txs).
    */
    function _setWeeklyReward(uint256 value, bool withUpdate) private {
        if (withUpdate) {
            massUpdateFameRewards();
        }

        require(
            value == 0 || (value >= FAME_DECIMALS && value <= MAX_WEEKLY_FAME),
            "Fame requires 64 decimals"
        );
        weeklyReward = value;
        _updateFamePerBlock();

        emit WeeklyRewardUpdated(value);
    }

    /**
        @dev    Set a new millisecond value for the block time. It also updated the `famePerBlock` value.
        Reverts if block time is set to 0.
        Emits BlockTimeUpdated(milliseconds).
        @param  milliseconds new millisecond value
    */
    function _setBlockTime(uint256 milliseconds) private {
        require(milliseconds != 0, "BlockTime should not be 0");

        msBlockTime = milliseconds;
        _updateFamePerBlock();

        emit BlockTimeUpdated(milliseconds);
    }

    /**
        @dev    Updates the fame per block reward: Weekly Reward / (milliseconds per week / block time in milliseconds).
        Reverts if block time is set to 0.
        Emits FamePerBlockUpdated(famePerBlock).
    */
    function _updateFamePerBlock() private {
        uint256 blocksPerWeek = MS_PER_WEEK / msBlockTime;
        famePerBlock = weeklyReward / blocksPerWeek;

        emit FamePerBlockUpdated(famePerBlock);
    }

    /**
        @dev    Updates the fame reward for one or multiple tokens of one asset contract.
        Updates lastUpdateBlock and famePerShare of an asset.
        @param  contractAddress Address of an asset contract
        @param  tokenIds        Array of token Ids to be updated
    */
    function _updateFameRewards(
        address contractAddress,
        uint256[] calldata tokenIds
    ) private {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 assetId = getAssetId(contractAddress, tokenId);
            updateFameReward(assetId);
        }
    }

    /**
        @dev    Calculates the fame reward based on blocks passed since last update, weight of an asset, and the total weights.
        @param  asset   The Asset object
        @return         The calculated fame reward
    */
    function _getFameReward(Asset storage asset)
        private
        view
        returns (uint256)
    {
        if (_totalWeights == 0) {
            return 0;
        } else {
            return
                (block.number - asset.lastUpdateBlock) *
                ((famePerBlock * asset.weight) / _totalWeights);
        }
    }

    /**
        @dev Checks if the msg.sender is the FameManager.
        Reverts if msg.sender is not the FameManager.
    */
    function _isAuthorizedFameManager() private view {
        require(
            getContractAddress(7) == msg.sender,
            "Unauthorized call. Thanks for supporting the network with your ETH."
        );
    }
}