// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IBoleroDeployer {
    function newArtist(
        address artistAddress,
        address artistPaymentAddress,
        string memory artistName,
        string memory artistSymbol,
        string memory artistURL,
        bool isWithPaymentSplitter
    ) external;

    function newArtistToken(
        address artistAddress,
        address want,
        address liquidityPool,
        uint256 initialPricePerShare,
        uint256[4] memory distribution, // [0] for Bolero, [1] for Artist, [2] for Liquidity Pool, [3] for Primary Market
        uint256[2] memory shares // [0] for bolero, [1] for artist
    ) external;

    function migrateArtist(address artistContract) external;

    function setManagement(address _management) external;

    function acceptManagement() external;

    function setRewards(address _rewards) external;

    function artists(address artistAddress) external view returns (address);

    function artistTokens(address artistAddress)
        external
        view
        returns (address);
}

interface IBoleroArtistICO {
    function grantTokens(address[] memory recipients, uint256[] memory values)
        external;

    function setPricePerShare(uint256 _pricePerShare) external;

    function setShares(uint256 _shareForBolero, uint256 _shareForArtist)
        external;

    function claimTreasure() external;
}

interface IBoleroArtist {
    function setPendingArtistAddress(address _pendingArtist) external;

    function setArtistAddress() external;

    function setArtistPayment(address _artistPayment, bool _isPaymentSplitter)
        external;

    function isWithPaymentSplitter() external view returns (bool);

    function artistPayment() external view returns (address);
}

interface IBoleroArtistToken {
    function setAvailableToTrade() external;

    function setEmergencyPause(bool shouldPause) external;

    function setLiquidityPool(address _liquidityPool) external;

    function setAllowlist(address _addr, bool _isAllowed) external;

    function icoContract() external view returns (address);
}

interface IPaymentSplitter {
    function initialize(
        address _bolero,
        address[] memory payees,
        string[] memory roles,
        uint256[] memory shares_
    ) external;

    function setMultisigWallet(address _multisigWallet) external;

    function migratePayee(address oldPayee, address newPayee) external;

    function addPayee(address account, uint256 shares) external;

    function updatePayeeShares(address account, uint256 newShares) external;
}

interface IBoleroMultisig {
    function initialize(
        address[] memory _owners,
        uint256 _confirmations,
        address _paymentSplitter
    ) external;
}

/// @title A contract to manage access and management operation on Deployer
/// @notice The roles can be updated, default admin can revoke or grant role at anytime
/// Any number of people can be added for one role.
/// @dev
contract BoleroManager is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant GRANTER_ROLE = keccak256("GRANTER_ROLE");

    IBoleroDeployer boleroDeployer;
    IBoleroArtist boleroArtist;
    IBoleroArtistToken boleroArtistToken;
    IBoleroArtistICO boleroArtistICO;
    IPaymentSplitter boleroPaymentSplitter;
    IBoleroMultisig boleroMultiSig;

    address public boleroPaymentSplitterImplementation;
    address public boleroMultisigImplementation;
    mapping(address => address) artistToMultisig;

    event PendingManagement(
        address indexed operator,
        address indexed pendingManager
    );

    event newBoleroMultisigImplementation(address indexed implementation);

    event newBoleroPaymentSplitterImplementation(
        address indexed implementation
    );

    constructor(
        address admin,
        address operator,
        address manager,
        address updater,
        address _boleroDeployer
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(OPERATOR_ROLE, operator);
        _setupRole(MANAGER_ROLE, manager);
        _setupRole(UPDATER_ROLE, updater);
        boleroDeployer = IBoleroDeployer(_boleroDeployer);
    }

    /**
     *@notice Implementation of BoleroDeployer's functions.
     * */

    function newArtist(
        address artistAddress,
        address artistPaymentAddress,
        string memory artistName,
        string memory artistSymbol,
        string memory artistURL,
        bool isWithPaymentSplitter
    ) public onlyRole(OPERATOR_ROLE) {
        boleroDeployer.newArtist(
            artistAddress,
            artistPaymentAddress,
            artistName,
            artistSymbol,
            artistURL,
            isWithPaymentSplitter
        );
    }

    function newArtistToken(
        address artistAddress,
        address want,
        address liquidityPool,
        uint256 initialPricePerShare,
        uint256[4] memory distribution, // [0] for Bolero, [1] for Artist, [2] for Liquidity Pool, [3] for Primary Market
        uint256[2] memory shares // [0] for bolero, [1] for artist
    ) public onlyRole(OPERATOR_ROLE) {
        boleroDeployer.newArtistToken(
            artistAddress,
            want,
            liquidityPool,
            initialPricePerShare,
            distribution,
            shares
        );
    }

    function migrateArtist(address artistContract)
        public
        onlyRole(OPERATOR_ROLE)
    {
        boleroDeployer.migrateArtist(artistContract);
    }

    function setManagement(address _management)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        boleroDeployer.setManagement(_management);
        emit PendingManagement(msg.sender, _management);
    }

    function acceptManagement() public {
        boleroDeployer.acceptManagement();
    }

    function setRewards(address _rewards) public onlyRole(DEFAULT_ADMIN_ROLE) {
        boleroDeployer.setRewards(_rewards);
    }

    /**
     *@notice Implementation of BoleroArtistIco's functions.
     * */

    function grantTokens(
        address contractAddress,
        address[] memory recipients,
        uint256[] memory values
    ) public {
        require(
            hasRole(GRANTER_ROLE, msg.sender) ||
                hasRole(MANAGER_ROLE, msg.sender)
        );
        IBoleroArtistICO(contractAddress).grantTokens(recipients, values);
    }

    function setPricePerShare(address contractAddress, uint256 _pricePerShare)
        public
        onlyRole(UPDATER_ROLE)
    {
        IBoleroArtistICO(contractAddress).setPricePerShare(_pricePerShare);
    }

    function setShares(
        address contractAddress,
        uint256 _shareForBolero,
        uint256 _shareForArtist
    ) public onlyRole(MANAGER_ROLE) {
        IBoleroArtistICO(contractAddress).setShares(
            _shareForBolero,
            _shareForArtist
        );
    }

    function claimTreasure(address contractAddress)
        public
        onlyRole(MANAGER_ROLE)
    {
        IBoleroArtistICO(contractAddress).claimTreasure();
    }

    /**
     *@notice Implementation of BoleroArtist's functions.
     * */

    function setArtistAddress(address contractAddress)
        public
        onlyRole(OPERATOR_ROLE)
    {
        IBoleroArtist(contractAddress).setArtistAddress();
    }

    function setArtistPayment(
        address contractAddress,
        address _artistPayment,
        bool _isPaymentSplitter
    ) public onlyRole(MANAGER_ROLE) {
        IBoleroArtist(contractAddress).setArtistPayment(
            _artistPayment,
            _isPaymentSplitter
        );
    }

    /**
     *@notice Implementation of BoleroArtistToken's functions.
     * */
    function setAvailableToTrade(address contractAddress)
        public
        onlyRole(MANAGER_ROLE)
    {
        IBoleroArtistToken(contractAddress).setAvailableToTrade();
    }

    function setEmergencyPause(address contractAddress, bool shouldPause)
        public
        onlyRole(MANAGER_ROLE)
    {
        IBoleroArtistToken(contractAddress).setEmergencyPause(shouldPause);
    }

    function setLiquidityPool(address contractAddress, address _liquidityPool)
        public
        onlyRole(MANAGER_ROLE)
    {
        IBoleroArtistToken(contractAddress).setLiquidityPool(_liquidityPool);
    }

    function setAllowlist(
        address contractAddress,
        address _addr,
        bool _isAllowed
    ) public onlyRole(MANAGER_ROLE) {
        IBoleroArtistToken(contractAddress).setAllowlist(_addr, _isAllowed);
    }

    /**
     *@notice Implementation of BoleroPayementSplitter's functions.
     * */
    function migratePayee(
        address contractAddress,
        address oldPayee,
        address newPayee
    ) public onlyRole(MANAGER_ROLE) {
        IPaymentSplitter(contractAddress).migratePayee(oldPayee, newPayee);
    }

    function addPayee(
        address contractAddress,
        address account,
        uint256 shares
    ) public onlyRole(MANAGER_ROLE) {
        IPaymentSplitter(contractAddress).addPayee(account, shares);
    }

    function updatePayeeShares(
        address contractAddress,
        address account,
        uint256 newShares
    ) public onlyRole(MANAGER_ROLE) returns (bool success) {
        IPaymentSplitter(contractAddress).updatePayeeShares(account, newShares);
        return true;
    }

    /*******************************************************************************
     **	@dev Set the implementation of the paymentSplitter to be cloned.
     ** @param implementation Address of the contract to be cloned.
     *******************************************************************************/
    function setBoleroPaymentSplitterImplementation(address implementation)
        public
        onlyRole(OPERATOR_ROLE)
    {
        boleroPaymentSplitterImplementation = implementation;
    }

    /*******************************************************************************
     **	@dev Set the implementation of the multiSig to be cloned.
     ** @param implementation Address of the contract to be cloned.
     *******************************************************************************/
    function setBoleroMultisigImplementation(address implementation)
        public
        onlyRole(OPERATOR_ROLE)
    {
        boleroMultisigImplementation = implementation;
    }

    function newPaymentSplitter(
        address artistAddress,
        address[] memory _payees,
        string[] memory _roles,
        uint256[] memory _shares
    ) public onlyRole(MANAGER_ROLE) {
        address artistContractAddress = getArtistContractAddress(artistAddress);
        address collectionPaymentAddress = Clones.clone(
            boleroPaymentSplitterImplementation
        );
        IPaymentSplitter splitter = IPaymentSplitter(collectionPaymentAddress);
        splitter.initialize(address(this), _payees, _roles, _shares);

        address collectionMultisigAddress = Clones.clone(
            boleroMultisigImplementation
        );

        IBoleroMultisig multisig = IBoleroMultisig(collectionMultisigAddress);
        multisig.initialize(_payees, _payees.length, collectionPaymentAddress);

        splitter.setMultisigWallet(collectionMultisigAddress);
        setArtistPayment(artistContractAddress, collectionPaymentAddress, true);
    }

    function newArtistWithPaymentSplitter(
        address artistAddress,
        address[] memory _payees,
        string[] memory _roles,
        uint256[] memory _shares,
        string memory artistName,
        string memory artistSymbol,
        string memory artistURL
    ) public onlyRole(MANAGER_ROLE) {
        address collectionPaymentAddress = Clones.clone(
            boleroPaymentSplitterImplementation
        );
        IPaymentSplitter splitter = IPaymentSplitter(collectionPaymentAddress);
        splitter.initialize(address(this), _payees, _roles, _shares);

        address collectionMultisigAddress = Clones.clone(
            boleroMultisigImplementation
        );

        IBoleroMultisig multisig = IBoleroMultisig(collectionMultisigAddress);
        multisig.initialize(_payees, _payees.length, collectionPaymentAddress);

        splitter.setMultisigWallet(collectionMultisigAddress);
        boleroDeployer.newArtist(
            artistAddress,
            collectionPaymentAddress,
            artistName,
            artistSymbol,
            artistURL,
            true
        );
    }

    function getMultisigForArtist(address artistAddress)
        public
        view
        returns (address)
    {
        return artistToMultisig[artistAddress];
    }

    /**
     *@notice General Getters
     * */

    function getDeployerAddress() public view returns (address) {
        return address(boleroDeployer);
    }

    function getArtistContractAddress(address artistAddress)
        public
        view
        returns (address)
    {
        return boleroDeployer.artists(artistAddress);
    }

    function getArtistTokenAddress(address artistAddress)
        public
        view
        returns (address)
    {
        return boleroDeployer.artistTokens(artistAddress);
    }

    function getArtistICOAddress(address artistAddress)
        public
        view
        returns (address)
    {
        return
            IBoleroArtistToken(getArtistTokenAddress(artistAddress))
                .icoContract();
    }

    function getPaymentAddress(address artistAddress)
        public
        view
        returns (bool, address)
    {
        bool isWithPaymentSplitter = IBoleroArtist(
            getArtistContractAddress(artistAddress)
        ).isWithPaymentSplitter();
        if (isWithPaymentSplitter) {
            address paymentSplitterAddress = IBoleroArtist(
                getArtistContractAddress(artistAddress)
            ).artistPayment();
            return (true, paymentSplitterAddress);
        } else {
            address paymentAddress = IBoleroArtist(
                getArtistContractAddress(artistAddress)
            ).artistPayment();
            return (false, paymentAddress);
        }
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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