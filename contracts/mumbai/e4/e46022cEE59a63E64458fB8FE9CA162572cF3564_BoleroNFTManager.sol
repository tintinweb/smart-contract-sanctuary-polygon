// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IBoleroNFTDeployer {
    function rewards() external view returns (address);

    function setRewards(address _rewards) external;

    function management() external view returns (address);

    function setManagement(address _management) external;

    function acceptManagement() external;
}

interface IBoleroNFT {
    function newCollection(
        address artistAddress,
        address collectionPaymentAddress,
        address privateSaleToken,
        string memory collectionName,
        uint256 artistRoyalty,
        uint256 cap,
        uint256 privateSaleThreshold
    ) external;

    function newCollectionWithPaymentSplitter(
        address artistAddress,
        address privateSaleToken,
        string memory collectionName,
        address[] memory _payees,
        string[] memory _roles,
        uint256[] memory _shares,
        uint256 artistRoyalty,
        uint256 cap,
        uint256 privateSaleThreshold
    ) external;

    function newPaymentSplitter(
        address[] memory _payees,
        string[] memory _roles,
        uint256[] memory _shares,
        uint256 _collectionId
    ) external returns (address);

    function changeTokenURI(uint256 _tokenId, string memory _tokenURI) external;

    function setBoleroSwap(address _boleroSwap) external;

    function setCollectionPaymentAddress(
        address _payment,
        uint256 _collectionId
    ) external;

    function mintNFT(
        address _to,
        string memory _tokenURI,
        uint256 _collectionId
    ) external returns (uint256);

    function setBoleroPaymentSplitterImplementation(address _implementation)
        external;

    function setBoleroMultisigImplementation(address _implementation) external;

    function collectionPayment(uint256 _collectionId)
        external
        view
        returns (address);

    function collectionMultisig(uint256 _collectionId)
        external
        view
        returns (address);

    function isWithPaymentSplitter(uint256 _collectionId)
        external
        view
        returns (bool);

    function artistPayment(uint256 _tokenID) external view returns (bool);

    function getRoyalties(uint256 _tokenID) external view returns (uint256);

    function getCollectionIDForToken(uint256 _tokenID)
        external
        view
        returns (uint256);

    function listTokensForCollection(uint256 _collectionID)
        external
        view
        returns (uint256[] memory);

    function listTokensForArtist(address _artist)
        external
        view
        returns (uint256[] memory);

    function listCollectionsForArtist(address _artist)
        external
        view
        returns (uint256[] memory);
}

interface IBoleroNFTSwap {
    function rewards() external view returns (address);

    function setRewards(address _rewards) external;

    function getRewards() external view returns (address);
}

interface IPaymentSplitter {
    function migratePayee(
        address oldPayee,
        address newPayee,
        string memory role
    ) external;

    function addPayee(
        address account,
        uint256 shares,
        string memory role
    ) external;

    function updatePayeeShares(address account, uint256 newShares) external;

    function releaseToken(address _want) external;
}

contract BoleroNFTManager is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    IBoleroNFTDeployer public BoleroNFTDeployer;
    IBoleroNFT public BoleroNFT;
    IBoleroNFTSwap public BoleroNFTSwap;
    IPaymentSplitter public boleroPaymentSplitter;

    address public rewards = address(0);
    address public management = address(0);

    /*******************************************************************************
     **	@notice Initialize the new contract.
     **	@param _admin The admin of BoleroManager
     *******************************************************************************/
    constructor(address _admin) {
        _setupRole(ADMIN_ROLE, _admin);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
    }

    /*******************************************************************************
     **	@notice Initialize the new contract with all contract's addresses.
     ** It also initialize the management.
     **	@param _boleroDeployer address of the boleroDeployer contract needed for management rights
     ** @param _boleroNFT address of the BoleroNFT contract.
     ** @param _boleroSwap address of the BoleroSwap.
     *******************************************************************************/
    function initializeManager(
        address _boleroDeployer,
        address _boleroNFT,
        address _boleroSwap
    ) public onlyRole(ADMIN_ROLE) {
        BoleroNFTDeployer = IBoleroNFTDeployer(_boleroDeployer);
        BoleroNFT = IBoleroNFT(_boleroNFT);
        BoleroNFTSwap = IBoleroNFTSwap(_boleroSwap);
        rewards = BoleroNFTDeployer.rewards();
        management = BoleroNFTDeployer.management();
        // set implementations here
        // Emit event when initialization.
    }

    /*******************************************************************************
     **	@dev Initialize the management address
     **	@param _management address of the management.
     *******************************************************************************/
    function setManagement(address _management) public onlyRole(OPERATOR_ROLE) {
        BoleroNFTDeployer.setManagement(_management);
    }

    /*******************************************************************************
     **	@dev Aceept the new management.
     *******************************************************************************/
    function acceptManagement() public {
        BoleroNFTDeployer.acceptManagement();
    }

    /**
     *@notice BoleroNFT functions
     * */

    /*******************************************
     **	@dev Setting the address of the BoleroNFTSwap contract
     ** @param _boleroSwap the address of the new BoleroNFTSwap contract.
     ***************************************************/
    function setBoleroSwap(address _boleroSwap) public onlyRole(OPERATOR_ROLE) {
        BoleroNFT.setBoleroSwap(_boleroSwap);
    }

     /*******************************************************************************
     **	@dev Set the implementation of the paymentSplitter to be cloned.
     ** @param implementation Address of the contract to be cloned.
     *******************************************************************************/
    function setBoleroPaymentSplitterImplementation(address _implementation)
        public
        onlyRole(OPERATOR_ROLE)
    {
        BoleroNFT.setBoleroPaymentSplitterImplementation(_implementation);
    }

    /*******************************************************************************
     **	@dev Set the implementation of the boleroMultisig to be cloned.
     ** @param implementation Address of the contract to be cloned.
     *******************************************************************************/
    function setBoleroMultisigImplementation(address _implementation)
        public
        onlyRole(OPERATOR_ROLE)
    {
        BoleroNFT.setBoleroMultisigImplementation(_implementation);
    }

    /*******************************************************************************
     **	@notice Initialize the new contract.
     **	@param artistAddress The address of the artist
     **	@param collectionPaymentAddress payment address for this artist
     **	@param collectionName Name of the collection
     **	@param artistRoyalty amount of royalties in % for this artist
     **	@param cap the maximum amount of tokens in the collection
     **	@param privateSaleThreshold the amount of tokens needed to be able to buy
     **  a token from this collection on the swap.
     *******************************************************************************/
    function newCollection(
        address artistAddress,
        address collectionPaymentAddress,
        address privateSaleToken,
        string memory collectionName,
        uint256 artistRoyalty,
        uint256 cap,
        uint256 privateSaleThreshold
    ) public onlyRole(OPERATOR_ROLE) {
        BoleroNFT.newCollection(
            artistAddress,
            collectionPaymentAddress,
            privateSaleToken,
            collectionName,
            artistRoyalty,
            cap,
            privateSaleThreshold
        );
    }

    /*******************************************************************************
     **	@notice Initialize a collection with paymentSplitter and a Multisig with it.
     **	@param artistAddress The address of the artist
     **	@param collectionPaymentAddress payment address for this artist
     **	@param collectionName Name of the collection
     ** @param _payees Array of addresses of the different beneficiaries.
     ** @param _roles The roles of each beneficiaries/payees per index.
     ** @param _shares The ammount of shares each payees will get, index per index.
     **	@param artistRoyalty amount of royalties in % for this artist
     **	@param cap the maximum amount of tokens in the collection
     **	@param privateSaleThreshold the amount of tokens needed to be able to buy
     **  a token from this collection on the swap.
     *******************************************************************************/
    function newCollectionWithPaymentSplitter(
        address artistAddress,
        address privateSaleToken,
        string memory collectionName,
        address[] memory _payees,
        string[] memory _roles,
        uint256[] memory _shares,
        uint256 artistRoyalty,
        uint256 cap,
        uint256 privateSaleThreshold
    ) public onlyRole(OPERATOR_ROLE) {
        BoleroNFT.newCollectionWithPaymentSplitter(
            artistAddress,
            privateSaleToken,
            collectionName,
            _payees,
            _roles,
            _shares,
            artistRoyalty,
            cap,
            privateSaleThreshold
        );
    }

    /**
     ** @dev Admins can mintNFT on behalf of any artists if they want it too
     ** this is purely because some of our clients wants us to take care of that part for them.
     **@param _to: Address of the address receiving the new token
     **@param _tokenURI: Data to attach to this token
     **@param _collectionId: the collection in wich we should put this token
     **/
    function mintNFT(
        address _to,
        string memory _tokenURI,
        uint256 _collectionId
    ) public onlyRole(OPERATOR_ROLE) returns (uint256) {
        return BoleroNFT.mintNFT(_to, _tokenURI, _collectionId);
    }

    /*******************************************************************************
     **  @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     **  `tokenId` must exist.
     *******************************************************************************/
    function changeTokenURI(uint256 _tokenId, string memory _tokenURI)
        public
        onlyRole(OPERATOR_ROLE)
    {
        BoleroNFT.changeTokenURI(_tokenId, _tokenURI);
    }

     /*******************************************************************************
     **	@notice Create a new paymentSplitter for an existing collection w/ a multisig.
     ** @param _payees Array of addresses of the different beneficiaries.
     ** @param _roles The roles of each beneficiaries/payees per index.
     ** @param _shares The ammount of shares each payees will get, index per index.
     **	@param collectionId The id of the collection.
     *******************************************************************************/
    function newPaymentSplitter(
        address[] memory _payees,
        string[] memory _roles,
        uint256[] memory _shares,
        uint256 _collectionId
    ) public returns (address) {
        return
            BoleroNFT.newPaymentSplitter(
                _payees,
                _roles,
                _shares,
                _collectionId
            );
    }

    /*******************************************************************************
     **	@notice Replace the payment address of a collection. Can only be called by
     **	the artist or Bolero.
     **	@param _payment new address to use as payment address
     **	@param _collectionId id of the collection to update
     *******************************************************************************/
    function setCollectionPaymentAddress(
        address _payment,
        uint256 _collectionId
    ) public onlyRole(OPERATOR_ROLE) {
        BoleroNFT.setCollectionPaymentAddress(_payment, _collectionId);
    }

    /*******************************************************************************
     **  @dev Return the payment address for a specific collection id
     *******************************************************************************/
    function collectionPayment(uint256 _collectionId)
        public
        view
        returns (address)
    {
        return BoleroNFT.collectionPayment(_collectionId);
    }

    /*******************************************************************************
     **  @dev Return the multisig address for a specific collection id
     *******************************************************************************/
    function collectionMultisig(uint256 _collectionId)
        public
        view
        returns (address)
    {
        return BoleroNFT.collectionMultisig(_collectionId);
    }

    /*******************************************************************************
     **  @dev Return a boolean to know if a specific collection id comes w/ a paymentSplitter
     *******************************************************************************/
    function isWithPaymentSplitter(uint256 _collectionId)
        public
        view
        returns (bool)
    {
        return BoleroNFT.isWithPaymentSplitter(_collectionId);
    }

    /*******************************************************************************
     **  @dev Return the payment address for a specific token id
     *******************************************************************************/
    function artistPayment(uint256 _tokenID) public view returns (bool) {
        return BoleroNFT.artistPayment(_tokenID);
    }

    /*******************************************************************************
     **  @dev Return the royalties for a specific token id
     *******************************************************************************/
    function getRoyalties(uint256 _tokenID) public view returns (uint256) {
        return BoleroNFT.getRoyalties(_tokenID);
    }

    /*******************************************************************************
     **  @dev Return the collection id for a specific token id
     *******************************************************************************/
    function getCollectionIDForToken(uint256 _tokenID)
        public
        view
        returns (uint256)
    {
        return BoleroNFT.getCollectionIDForToken(_tokenID);
    }

    function listTokensForCollection(uint256 _collectionID)
        public
        view
        returns (uint256[] memory)
    {
        return BoleroNFT.listTokensForCollection(_collectionID);
    }

    function listTokensForArtist(address _artist)
        public
        view
        returns (uint256[] memory)
    {
        return BoleroNFT.listTokensForArtist(_artist);
    }

    function listCollectionsForArtist(address _artist)
        public
        view
        returns (uint256[] memory)
    {
        return BoleroNFT.listCollectionsForArtist(_artist);
    }

    /**
     *@notice getters to get the paymentSplitters addresses
     * */
    function getCollectionPaymentAddress(uint256 _collectionId)
        public
        view
        returns (address)
    {
        return BoleroNFT.collectionPayment(_collectionId);
    }

    /*******************************************************************************
     **	@dev Update the adresse of a specific payee
     **       This function is not cheap as it need to reorganize the table and swap
     **       all the addresses to ensure the correct price.
     **       If the address is already in the payees, it's shares will be replaced.
     **@param contractAddress the address of the paymentSplitter of the collection.
     **@param oldPayee the address of the older payee
     **@param newPayee the address of the new payee
     **@param role the role of the new payee
     *******************************************************************************/
    function migratePayee(
        address contractAddress,
        address oldPayee,
        address newPayee,
        string memory role
    ) public onlyRole(OPERATOR_ROLE) {
        boleroPaymentSplitter = IPaymentSplitter(contractAddress);
        boleroPaymentSplitter.migratePayee(oldPayee, newPayee, role);
    }

    /*******************************************************************************
     **	@dev Add a new payee to the contract.
     ** @param contractAddress the address of the paymentSplitter of the collection.
     **	@param account The address of the payee to add.
     **	@param shares_ The number of shares owned by the payee.
     *******************************************************************************/
    function addPayee(
        address contractAddress,
        address account,
        uint256 shares,
        string memory role
    ) public onlyRole(OPERATOR_ROLE) {
        boleroPaymentSplitter = IPaymentSplitter(contractAddress);
        boleroPaymentSplitter.addPayee(account, shares, role);
    }

    /*******************************************************************************
     **	@dev Update the shares for a payee
     ** @param contractAddress the address of the paymentSplitter of the collection.
     **	@param account The address of the payee to add.
     **	@param newShares The number of shares to set for the account
     *******************************************************************************/
    function updatePayeeShares(
        address contractAddress,
        address account,
        uint256 newShares
    ) public onlyRole(OPERATOR_ROLE) returns (bool success) {
        boleroPaymentSplitter = IPaymentSplitter(contractAddress);
        boleroPaymentSplitter.updatePayeeShares(account, newShares);
        return true;
    }

    /*******************************************************************************
     **	@dev Triggers a transfer to `account` of the amount of `want` they
     **		 are owed, according to their percentage of the total shares and their
     **		 previous withdrawals.
     **  note: Anyone can trigger this release
     ** @param contractAddress the address of the paymentSplitter of the collection.
     *******************************************************************************/
    function releaseToken(address contractAddress, address _want)
        public
        onlyRole(OPERATOR_ROLE)
    {
        boleroPaymentSplitter = IPaymentSplitter(contractAddress);
        boleroPaymentSplitter.releaseToken(_want);
    }

    /*******************************************
     ** @notice
     **	@dev Setting the reward address for the boleroSwap
     ** @param _rewards address of the rewards
     ***************************************************/
    function setRewards(address _rewards) public onlyRole(OPERATOR_ROLE) {
        BoleroNFTSwap.setRewards(_rewards);
        rewards = BoleroNFTSwap.rewards();
    }

    /*******************************************
     **	@dev Getting the reward address for the boleroSwap
     ***************************************************/
    function getRewards() public view returns (address) {
        return BoleroNFTSwap.rewards();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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