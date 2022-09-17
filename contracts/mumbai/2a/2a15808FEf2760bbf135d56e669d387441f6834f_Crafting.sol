// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC1155.sol";
import "./interfaces/IAssetPool.sol";
import "./interfaces/ICrafting.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Crafting - Contract to facilitate crafting resources into game items in the PV Gaming Ecosystem
 * 
 * @author Jack Chuma
 */
contract Crafting is ICrafting, AccessControl {

    bytes32 constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 constant BACKEND_ROLE = keccak256("BACKEND_ROLE");

    uint256 fee;
    address rewards;
    address lockedResources;

    IERC1155 gameItems;
    IERC1155 resources;
    IAssetPool assetPool;

    struct GameItem {
        uint256 pow;
        uint256[] resourceIds;
        uint256[] amounts;
    }

    error ZeroAddress();
    error InvalidCaller();
    error InvalidFee();
    error LengthMismatch();

    event ItemUpgraded(
        uint256 indexed upgradeId,
        address indexed user,
        uint256[] fromIds,
        uint256[] amountsBurned,
        uint256[] toIds,
        uint256[] amountsSent
    );

    event Subscript(
        uint256 indexed subscriptId,
        address indexed user,
        uint256[] resourceIds,
        uint256[] resourceAmounts,
        uint256[] itemIds,
        uint256[] itemAmounts
    );

    event Destroy(
        uint256 indexed destroyId,
        address indexed prey,
        address indexed to,
        uint256[] itemIds,
        uint256[] itemAmounts,
        uint256[] resourceIds,
        uint256[] resourceAmounts
    );

    event FeeSet(uint256 fee);
    event RewardsAddressSet(address rewardsAddress);
    event LockedResourcesAddressSet(address lockedResourcesAddress);
    event GameItemsAddressSet(address gameItemsAddress);
    event ResourcesAddressSet(address resourcesAddress);

    constructor(
        uint256 _fee, 
        address _rewards, 
        address _lockedResources, 
        address _gameItems, 
        address _resources,
        address _assetPool,
        address _adminWallet,
        address _backendWallet
    ) {
        if (
            _rewards == address(0) || 
            _lockedResources == address(0) || 
            _gameItems == address(0) || 
            _resources == address(0) || 
            _assetPool == address(0) ||
            _adminWallet == address(0) ||
            _backendWallet == address(0)
        ) revert ZeroAddress();
        if (_fee > 1000000000000000000) revert InvalidFee();

        fee = _fee;
        rewards = _rewards;
        lockedResources = _lockedResources;
        gameItems = IERC1155(_gameItems);
        resources = IERC1155(_resources);
        assetPool = IAssetPool(_assetPool);

        _setupRole(DEFAULT_ADMIN_ROLE, _adminWallet);
        _setupRole(USER_ROLE, msg.sender);
        _setupRole(BACKEND_ROLE, _backendWallet);
    }

    /**
     * @notice Called by contract owner to update crafting fee
     * @dev Fee is a number between 0 and 10 ** 18 to be used as a percentage
     * @param _fee New fee value to be stored
     */
    function setFee(
        uint256 _fee
    ) external onlyRole(USER_ROLE) {
        if (_fee > 1000000000000000000) revert InvalidFee();
        fee = _fee;
        emit FeeSet(_fee);
    }

    /**
     * @notice Called by contract owner to update stored Rewards contract address
     * @param _rewards Address of Rewards contract
     */
    function setRewardsAddress(
        address _rewards
    ) external onlyRole(USER_ROLE) {
        if (_rewards == address(0)) revert ZeroAddress();
        rewards = _rewards;
        emit RewardsAddressSet(_rewards);
    }

    /**
     * @notice Called by contract owner to update stored Locked Resources contract address
     * @param _lockedResources Address of LockedResources contract
     */
    function setLockedResourcesAddress(
        address _lockedResources
    ) external onlyRole(USER_ROLE) {
        if (_lockedResources == address(0)) revert ZeroAddress();
        lockedResources = _lockedResources;
        emit LockedResourcesAddressSet(_lockedResources);
    }

    /**
     * @notice Called by contract owner to update stored Game Items contract address
     * @param _gameItems Address of GameItems contract
     */
    function setGameItemsAddress(
        address _gameItems
    ) external onlyRole(USER_ROLE) {
        if (_gameItems == address(0)) revert ZeroAddress();
        gameItems = IERC1155(_gameItems);
        emit GameItemsAddressSet(_gameItems);
    }

    /**
     * @notice Called by contract owner to update stored Resources contract address
     * @param _resources Address of Resources contract
     */
    function setResourcesAddress(
        address _resources
    ) external onlyRole(USER_ROLE) {
        if (_resources == address(0)) revert ZeroAddress();
        resources = IERC1155(_resources);
        emit ResourcesAddressSet(_resources);
    }

    /**
     * @notice Called by contract owner to upgrade an item on behalf of user
     * @dev Burns items being traded in and transfers upgraded item to user
     * @param _requests Array of requests with `UpgradeItemRequest` structure to enable batching
     */
    function upgradeItems(
        UpgradeItemRequest[] calldata _requests
    ) external onlyRole(BACKEND_ROLE) {
        for (uint i = 0; i < _requests.length; ) {
            UpgradeItemRequest calldata _request = _requests[i];

            if (_request.fromIds.length != _request.toIds.length) revert LengthMismatch();

            gameItems.burnBatch(
                _request.user, 
                _request.fromIds, 
                _request.amountsToBurn
            );

            gameItems.mintBatch(
                _request.user,
                _request.toIds,
                _request.toAmounts
            );

            emit ItemUpgraded(
                _request.upgradeId,
                _request.user,
                _request.fromIds,
                _request.amountsToBurn,
                _request.toIds,
                _request.toAmounts
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Called by Rewards contract to fulfill a game item reward
     * @dev Locks resources and sends game item to user
     * @param _user Address of user who earned the reward
     * @param _resourceIds Array of resource IDs to be locked in game item
     * @param _amounts Array of amounts of each resource to be locked in game item
     * @param _itemIds Array of IDs of game item to send to user
     */
    function craftGameItem(
        address _user,
        uint256[] calldata _resourceIds,
        uint256[] calldata _amounts,
        uint256[] calldata _itemIds,
        uint256[] calldata _itemAmounts
    ) external {
        if (msg.sender != rewards) revert InvalidCaller();

        resources.safeBatchTransferFrom(
            address(assetPool), 
            lockedResources, 
            _resourceIds, 
            _amounts, 
            ""
        );

        gameItems.safeBatchTransferFrom(
            address(assetPool), 
            _user, 
            _itemIds, 
            _itemAmounts, 
            ""
        );
    }

    /**
     * @notice Called by contract owner to subscript a game item for a user
     * @dev Locks resources and sends game item to user
     * @param _requests Array of subscript requests containing data in `SubscriptRequest` structure
     */
    function subscript(
        SubscriptRequest[] calldata _requests
    ) external onlyRole(BACKEND_ROLE) {
        for (uint i=0; i<_requests.length; ) {
            SubscriptRequest calldata _request = _requests[i];

            // calc POW out from Resources in
            uint256 powOut = assetPool.calcPOWOutFromResourcesIn(
                _request.resourceIds, 
                _request.resourceAmounts
            );

            // lock resources
            resources.safeBatchTransferFrom(
                _request.user, 
                lockedResources, 
                _request.resourceIds, 
                _request.resourceAmounts, 
                ""
            );

            // Calc fee using feePercentage
            uint256 powFee;
            unchecked { powFee = powOut * fee / 1000000000000000000; }

            // send POW fee from assetPool to Rewards contract
            assetPool.transfer(rewards, powFee);

            // send game items to user
            gameItems.safeBatchTransferFrom(
                address(assetPool),
                _request.user,
                _request.itemIds,
                _request.itemAmounts,
                ""
            );

            emit Subscript(
                _request.subscriptId, 
                _request.user, 
                _request.resourceIds, 
                _request.resourceAmounts, 
                _request.itemIds,
                _request.itemAmounts
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Called by contract owner to destroy a user's Game Item in exchange for the locked resources
     * @dev Burns game item and sends locked resources to `to` address
     * @param _requests Array of destroy for resources requests with `DestroyRequest` structure
     */
    function destroyForResources(
        DestroyRequest[] calldata _requests
    ) external onlyRole(BACKEND_ROLE) {
        for (uint i = 0; i < _requests.length; ) {
            DestroyRequest calldata _request = _requests[i];

            //Burn Game Item
            gameItems.burnBatch(_request.prey, _request.itemIds, _request.itemAmounts);

            // If we're sending the resources back to AssetPool, return locked POW to Rewards contract
            if (_request.to == address(assetPool)) {
                uint256 _powVal = assetPool.calcPOWOutFromResourcesIn(_request.resourceIds, _request.resourceAmounts);
                assetPool.transfer(rewards, _powVal);
            }

            // Send locked resources to _request.to
            resources.safeBatchTransferFrom(
                lockedResources, 
                _request.to, 
                _request.resourceIds, 
                _request.resourceAmounts, 
                ""
            );

            emit Destroy(
                _request.destroyId,
                _request.prey, 
                _request.to,
                _request.itemIds, 
                _request.itemAmounts,
                _request.resourceIds, 
                _request.resourceAmounts
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Called by contract owner to destroy a user's Game Item in exchange for the locked POW
     * @dev Burns game item and sends locked POW to `to` address
     * @param _requests Array of destroy for pow requests with `DestroyRequest` structure
     */
    function destroyForPow(
        DestroyRequest[] calldata _requests
    ) external onlyRole(BACKEND_ROLE) {
        for (uint i = 0; i < _requests.length; ) {
            DestroyRequest calldata _request = _requests[i];

            //Burn Game Item
            gameItems.burnBatch(_request.prey, _request.itemIds, _request.itemAmounts);

            // Calculate POW value
            uint256 _powVal = assetPool.calcPOWOutFromResourcesIn(_request.resourceIds, _request.resourceAmounts);

            // If we're sending the POW back to Rewards, return locked Resources to AssetPool contract. Otherwise, burn resources
            if (_request.to == rewards) {
                // Send locked resources to AssetPool
                resources.safeBatchTransferFrom(
                    lockedResources, 
                    address(assetPool), 
                    _request.resourceIds, 
                    _request.resourceAmounts, 
                    ""
                );
            } else {
                resources.burnBatch(lockedResources, _request.resourceIds, _request.resourceAmounts);
            }

            assetPool.transfer(_request.to, _powVal);

            emit Destroy(
                _request.destroyId,
                _request.prey, 
                _request.to,
                _request.itemIds, 
                _request.itemAmounts,
                _request.resourceIds, 
                _request.resourceAmounts
            );

            unchecked {
                ++i;
            }
        }
    }
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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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

    /**
     * @notice Called by contract owner to add new resources
     * @dev Mints new Resources to AssetPool contract
     * @dev Can only create resources that don't already exist
     * @param _to Address to mint assets to
     * @param _ids Array of resources IDs to add
     * @param _amounts Array of amount of each resource to mint
     */
    function mintBatch(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice Called by whitelisted address to burn a batch of Resources
     * @param _from Address that owns Resources to burn
     * @param _ids Array of Resource IDs
     * @param _amounts Array of amounts of each Resource to burn
     */
    function burnBatch(
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAssetPool {
    function transfer(address to, uint256 amount) external;

    function calcResourcesOutFromPOWIn(
        uint256 powIn,
        uint256[] memory resourceIds,
        uint256[] memory powSplitUp,
        uint256[] memory minAmountsOut
    ) external view returns (uint256[] memory);

    function calcPOWOutFromResourcesIn(
        uint256[] calldata resourceIds,
        uint256[] calldata amountsIn
    ) external view returns (uint256);

    function calcPOWInFromResourcesOut(
        uint256[] calldata resourceIds,
        uint256[] calldata amountsOut
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICrafting {
    struct UpgradeItemRequest {
        uint256 upgradeId;
        address user;
        uint256[] fromIds;
        uint256[] amountsToBurn;
        uint256[] toIds;
        uint256[] toAmounts;
    }

    struct SubscriptRequest {
        uint256 subscriptId;
        address user;
        uint256[] resourceIds;
        uint256[] resourceAmounts;
        uint256[] itemIds;
        uint256[] itemAmounts;
    }

    struct DestroyRequest {
        uint256 destroyId;
        address prey;
        address to;
        uint256[] itemIds;
        uint256[] itemAmounts;
        uint256[] resourceIds;
        uint256[] resourceAmounts;
    }

    function upgradeItems(UpgradeItemRequest[] calldata _requests) external;

    function craftGameItem(
        address _user,
        uint256[] calldata _resourceIds,
        uint256[] calldata _amounts,
        uint256[] calldata _itemIds,
        uint256[] calldata _itemAmounts
    ) external;

    function subscript(SubscriptRequest[] calldata _requests) external;

    function destroyForResources(DestroyRequest[] calldata _requests) external;

    function destroyForPow(DestroyRequest[] calldata _requests) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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