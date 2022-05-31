// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/IBalanceVault.sol";
import "./utils/IVoting.sol";
import "./utils/IStakingLevel.sol";

/**
 * @dev Use to create and store purchasable package used for token distribution.
 * Has a function to create package.
 * Has a function to approve package purchased by user.
 * Has a function to retrieve package information.
 * @notice Utilize balance vault to minimize gas cost in fund distribution.
 */
contract Packages is Ownable, AccessControl {
    bytes32 public constant WORKER = keccak256("WORKER");
    IERC20 public token;
    IBalanceVault public balanceVault;
    IVoting public voting;
    IStakingLevel public stakingLevel;
    address public adminAddress;
    mapping(string => Package) packageByPackageId;

    struct Package {
        string packageId;
        uint256 votePortion;
        uint256 commentPortion;
        uint256 stakePortion;
        uint256 adminPortion;
        uint256 price;
        uint256 baseRewardPerVote;
        uint256 baseRewardPerComment;
    }

    event AdminAddressUpdated(address adminAddress);
    event BalanceVaultAddressUpdated(address balanceVaultAddress);
    event VotingAddressUpdated(address votingAddress);
    event StakingLevelAddressUpdated(address stakingLevelAddress);
    event PackageCreated(
        string indexed packageId,
        uint256 votePortion,
        uint256 commentPortion,
        uint256 stakePortion,
        uint256 adminPortion,
        uint256 price,
        uint256 baseRewardPerVote,
        uint256 baseRewardPerComment
    );
    event PackageUpdated(
        string indexed packageId,
        uint256 votePortion,
        uint256 commentPortion,
        uint256 stakePortion,
        uint256 adminPortion,
        uint256 price,
        uint256 baseRewardPerVote,
        uint256 baseRewardPerComment
    );
    event PackageApproved(
        string indexed packageId,
        string indexed contestId,
        string indexed projectId,
        address userAddress
    );

    /**
     * @dev Set the address of Upo token, balance vault, voting, staking and admin.
     * Setup role for deployer.
     * @param _tokenAddress - Contract address of Upo token.
     * @param _balanceVaultAddress - Contract address of balance vault.
     * @param _votingAddress - Contract address of voting.
     * @param _stakingAddress - Contract address of stakingLevel.
     * @param _adminAddress - Address of admin.
     */
    constructor(
        address _tokenAddress,
        address _balanceVaultAddress,
        address _votingAddress,
        address _stakingAddress,
        address _adminAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(WORKER, msg.sender);

        token = IERC20(_tokenAddress);
        setBalanceVaultAddress(_balanceVaultAddress);
        setVotingAddress(_votingAddress);
        setStakingLevelAddress(_stakingAddress);
        setAdminAddress(_adminAddress);
    }

    /**
     * @dev Revert receive and fallback functions.
     */
    receive() external payable {
        revert("[Package] Revert receive function.");
    }

    fallback() external payable {
        revert("[Package] Revert fallback function.");
    }

    /**
     * @dev Create package to stored each parameters value.
     * @param _packageId - New package id
     * @param _votePortion - Token portion for vote reward
     * @param _commentPortion - Token portion for comment reward
     * @param _stakePortion - Token portion for stake reward
     * @param _adminPortion - Token portion for administration cost
     * @param _baseRewardPerVote - Base reward per vote reward
     * @param _baseRewardPerComment - Base reward per comment reward
     */
    function createPackage(
        string memory _packageId,
        uint256 _votePortion,
        uint256 _commentPortion,
        uint256 _stakePortion,
        uint256 _adminPortion,
        uint256 _baseRewardPerVote,
        uint256 _baseRewardPerComment
    ) external onlyRole(WORKER) {
        require(
            bytes(_packageId).length > 0,
            "[Package.createPackage] Package id length invalid"
        );
        Package storage package = packageByPackageId[_packageId];
        require(
            bytes(package.packageId).length == 0,
            "[Package.CreatePackage] Package id exist"
        );

        package.packageId = _packageId;
        package.votePortion = _votePortion;
        package.commentPortion = _commentPortion;
        package.stakePortion = _stakePortion;
        package.adminPortion = _adminPortion;
        package.price = (_votePortion +
            _commentPortion +
            _stakePortion +
            _adminPortion);
        package.baseRewardPerVote = _baseRewardPerVote;
        package.baseRewardPerComment = _baseRewardPerComment;

        emit PackageCreated(
            _packageId,
            _votePortion,
            _commentPortion,
            _stakePortion,
            _adminPortion,
            package.price,
            _baseRewardPerVote,
            _baseRewardPerComment
        );
    }

    /**
     * @dev Update package stored parameters value.
     * @param _packageId - Package id
     * @param _votePortion - Token portion for vote reward
     * @param _commentPortion - Token portion for comment reward
     * @param _stakePortion - Token portion for stake reward
     * @param _adminPortion - Token portion for administration cost
     * @param _baseRewardPerVote - Base reward per vote reward
     * @param _baseRewardPerComment - Base reward per comment reward
     */
    function updatePackage(
        string memory _packageId,
        uint256 _votePortion,
        uint256 _commentPortion,
        uint256 _stakePortion,
        uint256 _adminPortion,
        uint256 _baseRewardPerVote,
        uint256 _baseRewardPerComment
    ) external onlyRole(WORKER) {
        Package storage package = packageByPackageId[_packageId];
        require(
            bytes(package.packageId).length != 0,
            "[Package.updatePackage] Package id not exist"
        );

        package.votePortion = _votePortion;
        package.commentPortion = _commentPortion;
        package.stakePortion = _stakePortion;
        package.adminPortion = _adminPortion;
        package.price = (_votePortion +
            _commentPortion +
            _stakePortion +
            _adminPortion);
        package.baseRewardPerVote = _baseRewardPerVote;
        package.baseRewardPerComment = _baseRewardPerComment;

        emit PackageUpdated(
            _packageId,
            _votePortion,
            _commentPortion,
            _stakePortion,
            _adminPortion,
            package.price,
            _baseRewardPerVote,
            _baseRewardPerComment
        );
    }

    /**
     * @dev Approve package purchasing made by user.
     * Distribute token for each portion using stored value.
     * Add entry to specify voting contest id using specify project id.
     * @param _packageId - Purchased package id.
     * @param _contestId - Contest id of voting contet.
     * @param _projectId - Project id of purchased user.
     * @param _userAddress - Purchased user address.
     */
    function approvePackage(
        string memory _packageId,
        string memory _contestId,
        string memory _projectId,
        address _userAddress
    ) external onlyRole(WORKER) {
        require(
            bytes(packageByPackageId[_packageId].packageId).length > 0,
            "[Package.approvePackage] Package not exist"
        );
        Package storage package = packageByPackageId[_packageId];
        require(
            balanceVault.getBalance(_userAddress) >= package.price,
            "[Package.approvePackage] Insufficient user balance"
        );

        // Distribute package fund
        balanceVault.decreaseBalance(_userAddress, package.price);
        // Vote and Comment
        if(package.votePortion > 0 || package.commentPortion > 0) {
            balanceVault.increaseReward(
                package.votePortion + package.commentPortion
            );
            voting.addContestEntry(
                _contestId,
                _projectId,
                package.votePortion,
                package.commentPortion,
                package.baseRewardPerVote,
                package.baseRewardPerComment
            );
        }
        // Stake
        if(package.stakePortion > 0) {
            balanceVault.increaseBalance(address(this), package.stakePortion);
            balanceVault.withdrawUpo(package.stakePortion);
            token.approve(address(stakingLevel), package.stakePortion);
            stakingLevel.addPoolReward(package.stakePortion);
        }
        // Admin
        if(package.adminPortion > 0) {
            balanceVault.increaseBalance(adminAddress, package.adminPortion);
        }

        emit PackageApproved(_packageId, _contestId, _projectId, _userAddress);
    }

    function getPackageInfo(string memory _packageId)
        external
        view
        returns (
            string memory packageId,
            uint256 votePortion,
            uint256 commentPortion,
            uint256 stakePortion,
            uint256 adminPortion,
            uint256 price,
            uint256 baseRewardPerVote,
            uint256 baseRewardPerComment
        )
    {
        Package storage package = packageByPackageId[_packageId];
        packageId = package.packageId;
        votePortion = package.votePortion;
        commentPortion = package.commentPortion;
        stakePortion = package.stakePortion;
        adminPortion = package.adminPortion;
        price = package.price;
        baseRewardPerVote = package.baseRewardPerVote;
        baseRewardPerComment = package.baseRewardPerComment;
    }

    /**
     * @dev Set new address for balance vault using specify address.
     * @param _balanceVaultAddress - New address of balance vault.
     */
    function setBalanceVaultAddress(address _balanceVaultAddress)
        public
        onlyOwner
    {
        balanceVault = IBalanceVault(_balanceVaultAddress);
        emit BalanceVaultAddressUpdated(_balanceVaultAddress);
    }

    /**
     * @dev Set new address for voting using specify address.
     * @param _votingAddress - New address of voting.
     */
    function setVotingAddress(address _votingAddress) public onlyOwner {
        voting = IVoting(_votingAddress);
        emit VotingAddressUpdated(_votingAddress);
    }

    /**
     * @dev Set new address for staking level using specify address.
     * @param _stakingLevelAddress - New address of staking level.
     */
    function setStakingLevelAddress(address _stakingLevelAddress) public onlyOwner {
        stakingLevel = IStakingLevel(_stakingLevelAddress);
        emit StakingLevelAddressUpdated(_stakingLevelAddress);
    }

    /**
     * @dev Set new address for admin using specify address.
     * @param _adminAddress - New address of admin.
     */
    function setAdminAddress(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
        emit AdminAddressUpdated(_adminAddress);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.7;

interface IBalanceVault{
    function depositUpo(uint256 _upoAmount) external;
    function withdrawUpo(uint256 _upoAmount) external;
    function increaseBalance(address _userAddress, uint256 _upoAmount) external;
    function decreaseBalance(address _userAddress, uint256 _upoAmount) external;
    function increaseReward(uint256 _upoAmount) external;
    function decreaseReward(uint256 _upoAmount) external;
    function getBalance(address _userAddress) external view returns (uint256);
    function getReward() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVoting{
    function addContestEntry(string memory _contestId, string memory _projectId, uint256 _entryVoteReward, uint256 _entryCommentReward, uint256 _entryRewardPerVote, uint256 _entryRewardPerComment) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IStakingLevel {
    function getUserStakeLevel(address _userAddress) external view returns (uint256);
    function setWithdrawDelay(address _userAddress, uint256 _endDate) external;
    function addPoolReward(uint256 _upoAmount) external;
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