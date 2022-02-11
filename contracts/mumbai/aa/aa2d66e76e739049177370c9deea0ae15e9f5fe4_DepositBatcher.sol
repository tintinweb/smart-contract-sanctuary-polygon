// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/// NPM Imports
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// Internal Imports
import "./interfaces/IDepositBatcher.sol";
import "./interfaces/IProtocol.sol";
import "./lib/DepositBatcherLib.sol";
import "./tunnel/FxBaseChildTunnel.sol";
import {DepositBatch, PurchaseChannel} from "./type/Batch.sol";
import {DepositData, MintedData} from "./type/Tunnel.sol";
import {Errors} from "./lib/helpers/Error.sol";

/// @title Deposit Batcher
/// @author SmartDeFi
/// @dev This is a batcher contract, that batches all the token minting requests in POLYGON Layer into one aggregated call and batch them to the Ethereum Layer.
/// Note: This smart contract inherits the Interface {IDepositBatcher} and {DepositBatcherLib} library.

contract DepositBatcher is
    Initializable,
    IDepositBatcher,
    FxBaseChildTunnel,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    using DepositBatcherLib for DepositBatch;
    /// @dev maps the batchId to a deposit batch.
    mapping(uint256 => DepositBatch) private _batch;
    /// @dev maps the user & channelId to channel info.
    mapping(address => mapping(uint256 => PurchaseChannel)) private _channel;
    /// @dev maps the user to the total recurring channels.
    mapping(address => uint256) private _channelCount;

    IERC20L2 private _usdc;
    IL2Factory private _factory;
    IWhitelist private _whitelist;
    uint256 private _currentBatch;

    modifier onlyWhitelisted() {
        require(
            _whitelist.whitelisted(_msgSender()),
            Errors.AC_USER_NOT_WHITELISTED
        );
        _;
    }

    /// @dev initializes the smart contract.
    function initialize(
        address sdAdmin,
        address usdcAddress,
        address factoryAddress,
        address whitelistAddress,
        address fxChild
    ) public virtual initializer {
        _usdc = IERC20L2(usdcAddress);
        _factory = IL2Factory(factoryAddress);
        _whitelist = IWhitelist(whitelistAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, sdAdmin);
        FxBaseChildTunnel.setInitialParams(fxChild);
    }

    /// @dev see {IDepositBatcher-mint}
    function mint(
        bytes32[] memory protocols,
        uint256[] memory amounts,
        uint256 total
    ) public virtual override onlyWhitelisted nonReentrant returns (bool) {
        /// @dev destructures the user information.
        address user = _msgSender();
        bool result = true;

        /// @dev validates & transfers usdc from user to smart contract.
        require(_usdc.balanceOf(user) >= total, Errors.VL_INSUFFICIENT_BALANCE);
        require(
            _usdc.allowance(user, address(this)) >= total,
            Errors.VL_INSUFFICIENT_ALLOWANCE
        );
        result = result && _usdc.transferFrom(user, address(this), total);

        for (uint256 i = 0; i < protocols.length; i++) {
            address _protocolAddress = _factory.fetchProtocolAddressL2(
                protocols[i]
            );
            if (_protocolAddress != address(0)) {
                result = result && instantMint(
                    user,
                    protocols[i],
                    amounts[i],
                    _protocolAddress
                );
            } else {
                result = result && batch(user, protocols[i], amounts[i]);
            }
        }

        return result;
    }

    /// @dev see {IDepositBatcher-mint}
    function batch(
        address user,
        bytes32 protocol,
        uint256 amount
    ) internal virtual returns (bool) {
        bool update = _batch[_currentBatch].insert(user, protocol, amount);
        emit Batched(user, protocol, amount, _currentBatch);
        return update;
    }

    /// @dev instantly mints the tokens at the protocol address available on L2.
    function instantMint(
        address user,
        bytes32 protocol,
        uint256 amount,
        address protocolAddress
    ) internal virtual returns (bool) {
        bool result = _usdc.transfer(protocolAddress, amount);
        (bool r, uint256 minted) = IProtocol(protocolAddress).mintProtocolToken(
            user,
            amount
        );
        emit Minted(user, protocol, amount, minted, _currentBatch);
        return result && r;
    }

    /// @dev see {IDepositBatcher-execute}
    function execute()
        public
        virtual
        override
        onlyRole(GOVERNOR_ROLE)
        nonReentrant
        returns (bool)
    {
        uint256 batchId = _currentBatch;
        DepositBatch storage b = _batch[_currentBatch];
        /// @dev does the sanitary check to make sure the batchId is valid
        require(b.status == BatchStatus.LIVE, Errors.VL_BATCH_NOT_ELLIGIBLE);

        DepositData memory tunneldata;

        uint256[] memory amounts = new uint256[](b.protocols.length);

        /// @dev constructs an array to be sent via data tunnel.
        for (uint256 i = 0; i < b.protocols.length; i++) {
            amounts[i] = b.tokens[b.protocols[i]];
        }

        /// @dev constructs the tunnel data.
        tunneldata.batchId = batchId;
        tunneldata.protocols = b.protocols;
        tunneldata.amounts = amounts;

        b.status = BatchStatus.BATCHED;
        _currentBatch += 1;

        /// @dev withdraws the tokens to L1.
        _usdc.withdraw(b.total);
        /// @dev send the BatchData via Data Tunnel.
        _sendMessageToRoot(abi.encode(tunneldata));
        emit UpdateBatch(batchId, BatchStatus.BATCHED);
        return true;
    }

    /// @dev see {IDepositBatcher-createPurchaseChannel}
    function createPurchaseChannel(
        uint256[] memory amounts,
        bytes32[] memory protocols,
        uint256 totalPerTenure,
        uint256 tenures,
        uint256 frequency,
        bool withExistingPower
    ) public virtual override onlyWhitelisted nonReentrant returns (uint256) {
        address user = _msgSender();
        _channelCount[user] = _channelCount[user] + 1;

        // Creation of Mapping
        _channel[user][_channelCount[user]] = PurchaseChannel(
            amounts,
            protocols,
            totalPerTenure,
            tenures,
            0,
            frequency,
            0,
            withExistingPower
        );

        return _channelCount[user];
    }

    /// @dev see {IDepostBatcher-executePurchaseChannel}
    function executePurchaseChannel(address user, uint256 channelId)
        public
        virtual
        override
        onlyRole(GOVERNOR_ROLE)
        nonReentrant
        returns (bool)
    {
        bool result = true;

        require(
            channelId <= _channelCount[user],
            Errors.VL_NONEXISTENT_CHANNEL
        );

        PurchaseChannel storage channel = _channel[user][channelId];
        require(channel.completed < channel.tenures, Errors.VL_INVALID_CHANNEL);
        require(
            channel.lastPurchase + channel.frequency < block.timestamp,
            Errors.VL_INVALID_RECURRING_PURCHASE
        );

        channel.completed += 1;
        channel.lastPurchase = block.timestamp;

        /// @dev Only for purchasing with existing power
        if (channel.withExistingPower) {
            require(
                _usdc.allowance(user, address(this)) >= channel.totalPerTenure,
                Errors.VL_INSUFFICIENT_ALLOWANCE
            );
            require(
                _usdc.balanceOf(user) >= channel.totalPerTenure,
                Errors.VL_INSUFFICIENT_BALANCE
            );
            result = result && _usdc.transferFrom(user, address(this), channel.totalPerTenure);
        }

        /// @dev Validating USDC
        require(
            _usdc.balanceOf(address(this)) >=
                _batch[_currentBatch].total + channel.totalPerTenure,
            Errors.VL_USDC_NOT_ARRIVED
        );

        for (uint256 i = 0; i < channel.protocols.length; i++) {
            address _protocolAddress = _factory.fetchProtocolAddressL2(
                channel.protocols[i]
            );
            if (_protocolAddress != address(0)) {
                result = result && instantMint(
                    user,
                    channel.protocols[i],
                    channel.amounts[i],
                    _protocolAddress
                );
            } else {
                result = result && batch(user, channel.protocols[i], channel.amounts[i]);
            }
        }

        return result;
    }

    /// @dev see {IDepositBatcher-cancelPurchaseChannel}
    function cancelPurchaseChannel(uint256 channelId)
        public
        virtual
        override
        onlyWhitelisted
        nonReentrant
        returns (bool)
    {
        address user = _msgSender();
        require(
            channelId <= _channelCount[user],
            Errors.VL_NONEXISTENT_CHANNEL
        );

        PurchaseChannel storage channel = _channel[user][channelId];
        require(channel.completed < channel.tenures, Errors.VL_INVALID_CHANNEL);

        channel.completed = channel.tenures;
        return true;
    }

    /// @dev see {IDepositBatcher-usdc}
    function usdc() public view virtual override returns (IERC20L2) {
        return _usdc;
    }

    /// @dev see {IDepositBatcher-usdc}
    function factory() public view virtual override returns (IL2Factory) {
        return _factory;
    }

    /// @dev see {IDepositBatcher-whitelist}
    function whitelist() public view override returns (IWhitelist) {
        return _whitelist;
    }

    /// @dev see {IDepositBatcher-currentBatch}
    function currentBatch() public view override returns (uint256) {
        return _currentBatch;
    }

    /// @dev see {IDepositBatcher-fetchPurchaseChannel}
    function fetchPurchaseChannel(address user, uint256 channelId)
        public
        view
        override
        returns (PurchaseChannel memory)
    {
        return _channel[user][channelId];
    }

    /// @dev see {IDepositBatcher-fetchUserDeposits}
    function fetchUserDeposit(
        bytes32 protocol,
        uint256 batchId,
        address user
    ) public view override returns (uint256) {
        DepositBatch storage b = _batch[batchId];
        return b.individualUser[protocol][user];
    }

    /// @dev see {IDepositBatcher-fetchUsersInBatch}
    function fetchUsersInBatch(bytes32 protocol, uint256 batchId)
        public
        view
        returns (address[] memory)
    {
        DepositBatch storage b = _batch[batchId];
        return b.users[protocol];
    }

    /// @dev see {IDepositBatcher-fetchTotalDepositInBatch}
    function fetchTotalDepositInBatch(bytes32 protocol, uint256 batchId)
        public
        view
        returns (uint256)
    {
        DepositBatch storage b = _batch[batchId];
        return b.tokens[protocol];
    }

    /// @dev see {IDepositBatcher-fetchTotalDepositInBatch}
    function fetchProtocolsInBatch(uint256 batchId)
        public
        view
        returns (bytes32[] memory)
    {
        DepositBatch storage b = _batch[batchId];
        return b.protocols;
    }

    /// @dev see {IDepositBatcher-fetchBatchStatus}
    function fetchBatchStatus(uint256 batchId)
        public
        view
        override
        returns (BatchStatus)
    {
        DepositBatch storage b = _batch[batchId];
        return b.status;
    }

    /// @dev see {FxBaseChildTunnel-_processMessageFromRoot}
    function _processMessageFromRoot(
        uint256 _stateId,
        address _sender,
        bytes memory _data
    ) internal override nonReentrant validateSender(_sender) {
        /// @dev destructure the tunnel data.
        MintedData memory data = abi.decode(_data, (MintedData));
        DepositBatch storage b = _batch[data.batchId];

        require(
            b.status == BatchStatus.BATCHED,
            Errors.AC_BATCH_ALREADY_PROCESSED
        );

        /// @dev distribute the tokens to all depositors.
        for (uint256 i = 0; i < b.protocols.length; i++) {
            bytes32 protocol = b.protocols[i];
            address tokenAddress = _factory
                .fetchProtocolInfo(protocol)
                .tokenAddressL2;
            for (uint256 j = 0; j < b.users[protocol].length; j++) {
                address user = b.users[protocol][j];

                /// @dev calculates amount;
                uint256 percent = (b.individualUser[protocol][user] * 10**18) /
                    b.tokens[protocol];
                uint256 value = percent * data.tokens[i];
                /// decimal management
                /// @dev distributes tokens;
                IERC20(tokenAddress).transfer(user, value);
                // if(!result) {revert()}
            }
        }

        b.status = BatchStatus.DISTRIBUTED;
        emit UpdateBatch(data.batchId, BatchStatus.DISTRIBUTED);
    }

    /// @dev mock function for testing
    function mockProcessMessageFromRoot(
        address sender,
        uint256[] memory tokens,
        uint256 batchId
    ) public virtual {
        MintedData memory data = MintedData(batchId, tokens);
        _processMessageFromRoot(0, sender, abi.encode(data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "../interfaces/whitelist/IWhitelist.sol";
import "../interfaces/factory/IL2Factory.sol";
import "./IERC20L2.sol";
import {BatchStatus, PurchaseChannel} from "../type/Batch.sol";


/// @dev Interface of the Deposit Batcher Contract.
interface IDepositBatcher {
    /// @dev Emitted when an user makes a deposit to the batch.
    event Batched(
        address user,
        bytes32 protocol,
        uint256 amount,
        uint256 batchId
    );

    /// @dev Emitted when the batch status is updated.
    event UpdateBatch(
        uint256 batchId,
        BatchStatus status
    );

    /// @dev Emitted when an user instantly mints on L2.
    event Minted(
        address user,
        bytes32 protocol,
        uint256 amount,
        uint256 minted,
        uint256 batchId
    );

    /// Moves the USDC tokens from user gnosis-safe to
    /// deposit batcher smart contract & adds it to the batching
    /// queue. If the tokens are available on L2 it'll directly mint the tokens and not batch it.
    /// @dev make sure the usdc value is approved before making the transaction.
    /// @param protocols represents the array of protocol tokens to be minted.
    /// @param amounts represents the array of value of USDC deposits in each.
    /// @param total is  the sum of usdc deposits in each protocol.
    /// @return the status of the transaction
    ///  Note: the protocols index is mapped to the values index so make sure they're in right order.
    function mint(
        bytes32[] memory protocols,
        uint256[] memory amounts,
        uint256 total
    ) external returns (bool);

    /// @dev creates a recurring purchase channel for a user.
    /// @param amounts represents the array of value of USDC deposits in each.
    /// @param protocols represents the array of protocol tokens to be minted.
    /// @param tenures represents the total tenure of recurring payments.
    /// @param frequency represents the interval between two consecutive payments.
    /// @return the channelId created for the specific user.
    function createPurchaseChannel(
        uint256[] memory amounts,
        bytes32[] memory protocols,
        uint256 totalPerTenure,
        uint256 tenures,
        uint256 frequency,
        bool withExistingPower
    ) external returns (uint256);

    /// @dev creates a executes a recurring purchase channel.
    /// @param user represents the address of the user for whom we've to process the purchase.
    /// @param channelId represents the identifier of the payment channel.
    /// @return bool representing the status of the execute transaction.
    function executePurchaseChannel(address user, uint256 channelId)
        external
        returns (bool);

    /// @dev terminates a purchase channel prematurely.
    /// @param channelId represents the identifier of the payment channel.
    /// @return bool representing the status of the canel transaction.
    function cancelPurchaseChannel(uint256 channelId) external returns (bool);

    /// Withdraws the USDC & send it to L1 Router Contract.
    /// Send the minting information via Data Tunnel.
    /// @dev send the current batch to L1 for minting.
    /// @return the status of the batching transaction.
    function execute() external returns (bool);

    /// @dev returns the current usdc contract address.
    /// @return address of the usdc contract configured.
    function usdc() external view returns (IERC20L2);

    /// @dev returns the factory contract address.
    /// @return address of the factory contract address.
    function factory() external view returns (IL2Factory);

    /// @dev returns the whitelist oracle contract address.
    /// @return address of the whitelist oracle address.
    function whitelist() external view returns (IWhitelist);

    /// @dev can query the current batch identifier.
    /// @return an uint256 representing current batch id.
    function currentBatch() external view returns (uint256);

    /// @dev can query the purchase channel info of an user using his address and channel identifier.
    /// @param user represents the wallet address of the user/safe.
    /// @param channelId represents the identifier of the channel.
    /// @return the PurchaseChannel struct.
    function fetchPurchaseChannel(address user, uint256 channelId)
        external
        view
        returns (PurchaseChannel memory);

    /// @dev can query the deposit of a specific user in a specific protocol in a specific batch.
    /// @param protocol is the protocol name in bytes32 representation.
    /// @param batchId is the identifier of the batch you wish to query.
    /// @param user is the address of the safe you wish to query.
    /// @return an uint256 representing the deposits.
    function fetchUserDeposit(
        bytes32 protocol,
        uint256 batchId,
        address user
    ) external view returns (uint256);

    /// @dev is used to check the status of the batch.
    /// @return the status of the batchId queried
    function fetchBatchStatus(uint256 batchId)
        external
        view
        returns (BatchStatus);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/// @dev Shared Interface of All Protocol-Children Contracts.

interface IProtocol {
    /// @dev is emitted when the withdraw batcher is updated.
    event WithdrawBatcherUpdated(address newBatcher);

    /// @dev is emitted when the deposit batcher is updated.
    event DepositBatcherUpdated(address newBatcher);

    /// @dev allows developers to custom code the Protocol Minting Functions.
    /// @param user represents the address of the safe requesting mint.
    /// @param amount represents the amount of USDC.
    /// @return the amount of protocol tokens minted.
    function mintProtocolToken(address user, uint256 amount)
        external
        returns (bool,uint256);

    /// @dev allows developers to custom code the Protocol Withdrawal Functions.
    /// @param user represent the address of the safe requesting to redeem.
    /// @param amount represents the amount of tokens to be sold/redeemed.
    /// @return the amount of USDC received.
    function redeemProtocolToken(address user, uint256 amount)
        external
        returns (bool,uint256);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.8;

// Type Imports
import {DepositBatch} from "../type/Batch.sol";
import {Errors} from "./helpers/Error.sol";

/// @title Deposit Batcher Library
/// @author SmartDefi
/// @dev This is a library contract for handling user deposits in a specific protocol during the minting process.
/// Note: It's main purpose is to make sure the contract processes are gas efficient.

library DepositBatcherLib {
    /// @dev checks for hit-miss chances and maintains the batchInfo including
    /// - total USDC deposits in batch
    /// - protocols included in the batch
    /// - mapping of protocols to USDC
    /// - deposit of every user in individual protocols
    /// - users deposited in each protocol in a batch
    /// @param self represents the Batch Struct.
    /// @param user refers to the address of the gnosis-safe of user.
    /// @param amount refers the amount of USDC in protocol.
    /// @param protocol refers to the protocol to be minted.
    /// @return bool representing the status of the process.
    /// Note: the above information is most predominantly used
    /// for sending information via data tunnels & distribution of minted tokens
    /// back to user's safes without spending much gas & avoid LOOPS.
    function insert(
        DepositBatch storage self,
        address user,
        bytes32 protocol,
        uint256 amount
    ) internal returns (bool) {
        if (!self.created[protocol]) {
            self.protocols.push(protocol);
            self.created[protocol] = true;
        }

        if (self.individualUser[protocol][user] == 0) {
            self.users[protocol].push(user);
        }

        self.tokens[protocol] += amount;
        self.individualUser[protocol][user] += amount;
        self.total += amount;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor, Initializable {
    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(
            sender == fxRootTunnel,
            "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT"
        );
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(
            fxRootTunnel == address(0x0),
            "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET"
        );
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    function setInitialParams(address _fxChild) public virtual initializer {
        fxChild = _fxChild;
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.8;

/// @dev declares the required structures & enumerators.
enum BatchStatus {
    LIVE,
    BATCHED,
    DISTRIBUTED
}

struct DepositBatch {
    bytes32[] protocols;
    uint256 total;
    BatchStatus status;
    mapping(bytes32 => bool) created;
    mapping(bytes32 => uint256) tokens;
    mapping(bytes32 => address[]) users;
    mapping(bytes32 => mapping(address => uint256)) individualUser;
}

struct WithdrawBatch {
    bytes32[] protocols;
    BatchStatus status;
    mapping(bytes32 => bool) created;
    mapping(bytes32 => uint256) tokens;
    mapping(bytes32 => address[]) users;
    mapping(bytes32 => mapping(address => uint256)) individualUser;
}

struct PurchaseChannel {
    uint256[] amounts;
    bytes32[] protocols;
    uint256 totalPerTenure;
    uint256 tenures;
    uint256 completed;
    uint256 frequency;
    uint256 lastPurchase;
    bool withExistingPower;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

/// @dev is the tunnel data sent via child data tunnel to L1.
struct DepositData {
    uint256 batchId;
    bytes32[] protocols;
    uint256[] amounts;
}

/// @dev represents the tokens to be redeemed. Sent to Root tunnel via State tunnel.
struct RedemptionData {
    uint256 batchId;
    bytes32[] protocols;
    uint256[] amounts;
}

/// @dev Avoiding nested maps for using data in memory.
/// @dev Preventing use of storage in state-tunnels.
struct MintedData {
    uint256 batchId;
    uint256[] tokens;
}

/// Redeemed Data
struct RedeemedData {
    uint256 batchId;
    bytes32[] protocols;
    uint256[] amounts;
}

/// @dev represents the Factory Data to be sent via Data Tunnels
struct FactoryData {
    bytes32 protocolName;
    address tokenAddressL1;
    address tokenAddressL2;
    address protocolAddressL1;
    address protocolAddressL2;
    address stablecoinL1;
    address stablecoinL2;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/// @title Errors library
/// @author SmartDefi
/// @dev Error messages prefix glossary:
/// - VL = ValidationLogic
/// - AC = AccessContract

library Errors {
     /// Note: 'The sum of deposits in each protocol should be equal to the total'
    string public constant VL_INVALID_DEPOSIT = "Error: Invalid Deposit Input";
     /// Note: 'The user doesn't have enough balance of tokens'
    string public constant VL_INSUFFICIENT_BALANCE =
        "Error: Insufficient Balance";
    
    /// Note: 'The spender doesn't have enough allowance of tokens'
    string public constant VL_INSUFFICIENT_ALLOWANCE =
        "Error: Insufficient Allowance"; 
    /// Note: The current batch Id doesn't have the ability for current operation
    string public constant VL_BATCH_NOT_ELLIGIBLE = "Error: Invalid BatchId"; 
    /// Note: The protocol address is not found in factory.
    string public constant VL_INVALID_PROTOCOL = "Error: Invalid Protocol"; 
    /// Note: 'The sum of deposits in each protocol should be equal to the total'
    string public constant VL_ZERO_ADDRESS = "Error: Zero Address"; 

    /// Note: 'The sum of deposits in each protocol should be equal to the total'
    string public constant AC_USER_NOT_WHITELISTED =
        "Error: Address Not Whitelisted"; 
    /// Note: The caller is not governor of the whitelist contract.
    string public constant AC_INVALID_GOVERNOR =
        "Error: Invalid Governor Address"; 
    /// Note: The caller is not a valid router contract.
    string public constant AC_INVALID_ROUTER = "Error: Invalid Router"; 
        /// Note: The caller is not a valid batcher contract.
    string public constant AC_INVALID_BATCHER = "Error: Invalid Batcher"; 
    /// Note: The caller is not a valid router contract.
    string public constant AC_BATCH_ALREADY_PROCESSED =
        "Error: Batch Already Processed"; 
    /// Note: 'The recurring payment channel is not yet created.'
    string public constant VL_NONEXISTENT_CHANNEL =
        "Error: Non-Existent ChannelId"; 
    /// Note: 'The channel is invalid for this operation'
    string public constant VL_INVALID_CHANNEL = "Error: Invalid ChannelId"; 
    /// Note: 'The usdc for recurring channel is not available'
    string public constant VL_USDC_NOT_ARRIVED = "Error: USDC not available"; 
    /// Note: 'User tried to do recurring purchase less than the frequency of time'
    string public constant VL_INVALID_RECURRING_PURCHASE =
        "Error: Invalid Purchase Invocation"; 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
interface IERC165Upgradeable {
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

pragma solidity ^0.8.8;

/// @dev interface for whitelisting contract.
/// Note: Only whitelisted addresses can mint from SD contracts.

interface IWhitelist {
    /// @dev emitted when a wallet whitelist status is changed.
    event ToggleStatus(address user, bool status);

    /// @dev whitelist the `user` for using SD contracts.
    /// @param user represents EOA/SC to be whitelisted.
    /// @return bool representing the status of whitelisting.
    /// Note: user cannot be zero address.
    function whitelist(address user) external returns (bool);

    /// @dev blacklists the `user` from using SD contracts.
    /// @param user represents the EOA/SC to be blacklisted.
    /// @return bool representing the status of blacklisting process.
    /// Note: user should be whitelisted before and cannot be a zero address.
    function blacklist(address user) external returns (bool);

    /// @dev can check the status of whitelisting of an EOA/SC address.
    /// @return bool representing the status of whitelisitng.
    /// Note: 
    /// true - address is whitelisted and can purchase tokens.
    /// false - prevented from sale.
    function whitelisted(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import {FactoryData} from "../../type/Tunnel.sol";

/// @dev Interface of Matic Protocols Factory.
interface IL2Factory {
    /// @dev Emitted when a new `protocol` is added to the factory.
    event ProtocolUpdated(
        bytes32 protocolName,
        address protocolAddressL1,
        address protocolAddressL2,
        address tokenAddressL1,
        address tokenAddressL2,
        address stablecoinL1,
        address stablecoinL2
    );

    /// @dev can get the address of the protocol token in MATIC POS Bridge by using it's name.
    /// @param protocolName - name of the protocol in bytes32
    function fetchProtocolInfo(bytes32 protocolName)
        external
        view
        returns (FactoryData memory);

    /// @dev returns the l2 protocol address.
    /// @param protocolName - name of protocol in bytes32
    function fetchProtocolAddressL2(bytes32 protocolName)
        external
        view
        returns (address);

    /// @dev returns the l2 token address.
    /// @param protocolName - name of protocol in bytes32
    function fetchTokenAddressL2(bytes32 protocolName)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20L2 is IERC20 {
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}