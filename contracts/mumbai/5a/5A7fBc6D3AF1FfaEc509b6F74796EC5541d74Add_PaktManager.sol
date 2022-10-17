// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IPaktToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

error UnhandledPaktType(uint8 paktType);
error UserAlreadyHasActivePaktOfType(uint8 paktType);
error LevelNotAllowed(uint8 paktType, uint8 level);
error IncorrectAmount(uint8 level, uint256 amount);
error NotEnoughAllowance(uint256 amount);
error FailedTransfer(uint256 amount);
error PaktMustBeActive();
error PaktMustNotBeCustom();
error PaktNotFinished();
error GoalNotReached();
error PaktMustBeCustom();
error NeedToPayFee();
error WalletAlreadyLinked(address wallet);
error SourceIdAlreadyLinked(uint256 sourceId);
error NoSourceIdLinked();

/**
 * @title Contract to manage all possible actions on pakts
 * @author Alexandre Bensimon
 */
contract PaktManager is AccessControl {
    struct Pakt {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint8 paktType;
        uint8 level;
        bool active;
        bool success;
        string description;
    }

    struct PaktInfo {
        address user;
        uint256 index;
    }

    IPaktToken private immutable paktToken;

    bytes32 public constant PAKT_VERIFIER_ROLE =
        keccak256("PAKT_VERIFIER_ROLE");

    // One week
    uint48 public constant PAKT_DURATION = 7 * 24 * 60 * 60;

    uint256 public s_unlockFundsFee = 0.1 ether;

    uint8 private s_paktTypeCount = 4;
    uint16[6] public s_maxAmountByLevel = [0, 100, 200, 300, 400, 500];
    uint8[6] public s_interestRateByLevel = [0, 8, 9, 10, 11, 12];
    uint8 public s_burnInterestRatio = 4;

    mapping(address => uint256) public s_walletToSourceId;
    mapping(uint256 => address) public s_sourceIdToWallet;
    mapping(address => Pakt[]) public s_pakts;
    mapping(address => mapping(uint8 => bool)) public s_activePaktTypes;

    event WalletAndSourceIdLinked(address indexed wallet, uint256 sourceId);
    event PaktCreated(address indexed user, uint256 paktIndex);
    event PaktVerified(address indexed user, uint256 paktIndex);
    event PaktExtended(address indexed user, uint256 paktIndex);
    event PaktEnded(address indexed user, uint256 paktIndex);

    constructor(address _paktTokenAddress) {
        paktToken = IPaktToken(_paktTokenAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {}

    /**
     * @notice Link a wallet and a source id to prevent the use of the same source accounts by multiple wallets
     * @param _wallet The wallet address to link
     * @param _sourceId The source id to link
     */
    function linkWalletAndSourceId(address _wallet, uint256 _sourceId)
        external
        onlyRole(PAKT_VERIFIER_ROLE)
    {
        if (s_walletToSourceId[_wallet] != 0)
            revert WalletAlreadyLinked(_wallet);
        if (s_sourceIdToWallet[_sourceId] != address(0x0))
            revert SourceIdAlreadyLinked(_sourceId);

        s_walletToSourceId[_wallet] = _sourceId;
        s_sourceIdToWallet[_sourceId] = _wallet;

        emit WalletAndSourceIdLinked(_wallet, _sourceId);
    }

    /**
     * @notice Creates a new pakt
     * @param _paktType Custom pakts are of type 0, other pakt types are between 1 and paktTypeCount-1
     * @param _level For pakts that are not custom, the level represents the difficulty
     * @param _amount The amount to lock. For pakts that are not custom, there is a max amount for each level
     * @param _description For custom pakts, stores the goal written by the user
     */
    function makeNewPakt(
        uint8 _paktType,
        uint8 _level,
        uint256 _amount,
        string calldata _description
    ) external {
        if (s_walletToSourceId[msg.sender] == 0) revert NoSourceIdLinked();

        if (_paktType >= s_paktTypeCount) revert UnhandledPaktType(_paktType);

        if (_paktType != 0 && s_activePaktTypes[msg.sender][_paktType])
            revert UserAlreadyHasActivePaktOfType(_paktType);

        if (_paktType != 0 && !(_level >= 1 && _level <= 5))
            revert LevelNotAllowed(_paktType, _level);

        if (
            _amount == 0 ||
            (_paktType != 0 &&
                _amount > uint256(s_maxAmountByLevel[_level]) * 1e18)
        ) revert IncorrectAmount(_level, _amount);

        if (paktToken.allowance(msg.sender, address(this)) < _amount)
            revert NotEnoughAllowance(_amount);

        // startTime: block.timestamp,
        // endTime: block.timestamp + PAKT_DURATION
        Pakt memory pakt = Pakt({
            paktType: _paktType,
            level: _level,
            amount: _amount,
            startTime: block.timestamp - 2 * PAKT_DURATION, // FIXME: For testing
            endTime: block.timestamp - PAKT_DURATION, // FIXME: For testing
            description: _description,
            active: true,
            success: false
        });

        s_pakts[msg.sender].push(pakt);
        s_activePaktTypes[msg.sender][_paktType] = true;

        emit PaktCreated(msg.sender, s_pakts[msg.sender].length - 1);

        bool success = paktToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        if (!success) revert FailedTransfer(_amount);
    }

    /**
     * @notice Extends an already existing pakt
     * @param _paktIndex The index in the pakt array of the user
     * @param _amount The amount the lock in addition to the amount already locked in the pakt
     */
    function extendPakt(uint256 _paktIndex, uint256 _amount) external {
        Pakt storage s_pakt = s_pakts[msg.sender][_paktIndex];

        if (!s_pakt.active) revert PaktMustBeActive();
        if (s_pakt.endTime > block.timestamp) revert PaktNotFinished();

        if (
            _amount == 0 ||
            (s_pakt.paktType != 0 &&
                _amount > uint256(s_maxAmountByLevel[s_pakt.level]) * 1e18)
        ) revert IncorrectAmount(s_pakt.level, _amount);

        if (paktToken.allowance(msg.sender, address(this)) < _amount)
            revert NotEnoughAllowance(_amount);

        s_pakt.endTime += PAKT_DURATION;
        s_pakt.amount += _amount;

        emit PaktExtended(msg.sender, _paktIndex);

        bool success = paktToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        if (!success) revert FailedTransfer(_amount);
    }

    /**
     * @notice After verification, mark that a pakt has been a success. This function can only be called by the Pakt Verifier
     * @param _paktOwner The address of the owner whose pakt to be verified
     * @param _paktIndex The index in the pakt array of the user
     */
    function markPaktVerified(address _paktOwner, uint256 _paktIndex)
        external
        onlyRole(PAKT_VERIFIER_ROLE)
    {
        Pakt storage s_pakt = s_pakts[_paktOwner][_paktIndex];

        if (!s_pakt.active) revert PaktMustBeActive();
        if (s_pakt.paktType == 0) revert PaktMustNotBeCustom();
        if (s_pakt.endTime > block.timestamp) revert PaktNotFinished();

        s_pakt.success = true;

        emit PaktVerified(_paktOwner, _paktIndex);
    }

    /**
     * @notice After a pakt has been verified, the user can unlock the funds
     * @param _paktIndex The index in the pakt array of the user
     */
    function unlockFunds(uint256 _paktIndex) external payable {
        if (msg.value < s_unlockFundsFee) revert NeedToPayFee();

        Pakt storage s_pakt = s_pakts[msg.sender][_paktIndex];

        if (!s_pakt.active) revert PaktMustBeActive();
        if (!s_pakt.success) revert GoalNotReached();

        s_pakt.active = false;
        s_activePaktTypes[msg.sender][s_pakt.paktType] = false;

        emit PaktEnded(msg.sender, _paktIndex);

        uint256 interest = computeInterestForAmount(
            s_pakt.amount,
            s_pakt.level
        );

        paktToken.mint(address(this), interest);
        bool success = paktToken.transfer(msg.sender, s_pakt.amount + interest);
        if (!success) revert FailedTransfer(s_pakt.amount + interest);
    }

    /**
     * @notice If the pakt is not successful, the user can call this function to archive the pakt and recover some of the tokens locked
     * @param _paktIndex The index in the pakt array of the user
     */
    function failPakt(uint256 _paktIndex) external {
        Pakt storage s_pakt = s_pakts[msg.sender][_paktIndex];

        if (!s_pakt.active) revert PaktMustBeActive();
        if (s_pakt.paktType == 0) revert PaktMustNotBeCustom();
        if (s_pakt.endTime > block.timestamp) revert PaktNotFinished();

        s_pakt.active = false;
        s_activePaktTypes[msg.sender][s_pakt.paktType] = false;

        emit PaktEnded(msg.sender, _paktIndex);

        uint256 interest = computeInterestForAmount(
            s_pakt.amount,
            s_pakt.level
        );
        uint256 burnAmount = s_burnInterestRatio * interest;

        paktToken.burn(burnAmount);

        bool success = paktToken.transfer(
            msg.sender,
            s_pakt.amount - burnAmount
        );
        if (!success) revert FailedTransfer(s_pakt.amount - burnAmount);
    }

    /**
     * @notice End a custom pakt
     * @param _paktIndex The index in the pakt array of the user
     * @param _isPaktSuccess For a custom pakt, there is no verification by API so the user must specify if the pakt is successful or not
     */
    function endCustomPakt(uint256 _paktIndex, bool _isPaktSuccess) external {
        Pakt storage s_pakt = s_pakts[msg.sender][_paktIndex];

        if (!s_pakt.active) revert PaktMustBeActive();
        if (s_pakt.paktType != 0) revert PaktMustBeCustom();
        if (s_pakt.endTime > block.timestamp) revert PaktNotFinished();

        s_pakt.active = false;

        if (_isPaktSuccess) {
            s_pakt.success = true;

            emit PaktEnded(msg.sender, _paktIndex);

            bool success = paktToken.transfer(msg.sender, s_pakt.amount);
            if (!success) revert FailedTransfer(s_pakt.amount);
        } else {
            emit PaktEnded(msg.sender, _paktIndex);

            paktToken.burn(s_pakt.amount);
        }
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert FailedTransfer(address(this).balance);
    }

    /**
     * @dev If new pakts are added, can use this function to handle new pakt types without deploying new contract
     */
    function setPaktTypeCount(uint8 _count)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        s_paktTypeCount = _count;
    }

    /**
     * @dev For tweeking authorized token ranges by level if necessary during beta phase
     */
    function setMaxAmountByLevel(uint16[6] calldata _maxAmountByLevel)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        s_maxAmountByLevel = _maxAmountByLevel;
    }

    /**
     * @dev For tweeking authorized interest rate by level if necessary during beta phase
     */
    function setInterestRateByLevel(uint8[6] calldata _interestRateByLevel)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        s_interestRateByLevel = _interestRateByLevel;
    }

    /**
     * @dev For tweeking amount of token burned when pakt is not successful if necessary during beta phase
     */
    function setBurnInterestRatio(uint8 _burnInterestRatio)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        s_burnInterestRatio = _burnInterestRatio;
    }

    /**
     * @dev For tweeking the unlock funds fee if necessary
     */
    function setUnlockFundsFee(uint8 _unlockFundsFee)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        s_unlockFundsFee = _unlockFundsFee;
    }

    /**
     * @dev Getter necessary to get full array
     */
    function getMaxAmountByLevel() external view returns (uint16[6] memory) {
        return s_maxAmountByLevel;
    }

    /**
     * @dev Getter necessary to get full array
     */
    function getInterestRateByLevel() external view returns (uint8[6] memory) {
        return s_interestRateByLevel;
    }

    /**
     * @dev Getter necessary to get full array
     */
    function getAllPaktsFromUser(address _user)
        public
        view
        returns (Pakt[] memory)
    {
        return s_pakts[_user];
    }

    /**
     * @notice For each pakt level, an interest rate is calculated on the amount locked and is used as a reward with new tokens minted or as a punishment with tokens burned
     */
    function computeInterestForAmount(uint256 _amount, uint8 _paktLevel)
        public
        view
        returns (uint256)
    {
        // 1% of amount = amount * 10 / 1000
        return (_amount * s_interestRateByLevel[_paktLevel]) / 1000;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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