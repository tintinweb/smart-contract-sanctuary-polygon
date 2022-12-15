// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./utils/IBalanceVaultV2.sol";

/**
 * @dev Use to provide blogging service.
 * Has a function to approve user blog creation request for paid and free type.
 * Has a function to pay to unlock blog content.
 * Has functions to retrieve blog, paid blog, blog owner information.
 * @notice Is pausable to prevent malicious behavior.
 */
contract Blogging is Ownable, AccessControl, Pausable {
    struct Blog {
        uint256 blogId;
        bool isPaidType;
        uint256 price;
        uint256 blogOwnerId;
        uint256 donate;
        uint256 income;
        mapping(uint256 => bool) paidByUserId;
    }
    struct BlogOwner {
        address blogOwner;
        uint256 totalDonate;
        uint256 totalIncome;
    }

    bytes32 public constant WORKER = keccak256("WORKER");

    IBalanceVaultV2 public balanceVault;

    uint256 public latestBlogId;
    uint256 public totalFees;
    uint256 public payFeeRate;
    uint256 public donateFeeRate;
    mapping(uint256 => Blog) public blogByBlogId;
    mapping(uint256 => BlogOwner) public blogOwnerByBlogOwnerId;
    mapping(address => uint256) public blogOwnerIdByAddress;
    uint256 public latestBlogOwnerId;
    mapping(uint256 => address) public userByUserId;
    mapping(address => uint256) public userIdByAddress;
    uint256 public latestUserId;

    event PayFeeRateUpdated(uint256 payFeeRate);
    event DonateFeeRateUpdated(uint256 donateFeeRate);
    event BalanceVaultAddressUpdated(address balanceVault);
    event BlogOwnerRegistered(address indexed blogOwner);
    event UserWalletRegistered(address indexed userWallet);
    event BlogOwnerUpdated(
        address indexed currentBlogOwner,
        address indexed newBlogOwner
    );
    event UserWalletUpdated(
        address indexed currentUserWallet,
        address indexed newUserWallet
    );
    event BlogCreated(
        uint256 indexed blogId,
        address indexed blogOwner,
        bool isPaidType,
        uint256 blogPrice
    );
    event BlogPriceUpdated(uint256 indexed blogId, uint256 newPrice);
    event BlogPaid(
        uint256 indexed blogId,
        address indexed userAddress,
        uint256 payAmount
    );
    event BlogDonated(
        uint256 indexed blogId,
        address indexed userAddress,
        uint256 donateAmount
    );
    event AdminFeesWithdrawn(address adminAddress, uint256 withdrawAmount);

    /**
     * @dev Setup role for deployer, setup contract variables.
     * @param _balanceVaultAddress - Token address.
     * @param _payFeeRate - Paid blog fee rate.
     * @param _donateFeeRate - Donation fee rate.
     */
    constructor(
        address _balanceVaultAddress,
        uint256 _payFeeRate,
        uint256 _donateFeeRate
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(WORKER, msg.sender);

        setPayFeeRate(_payFeeRate);
        setDonateFeeRate(_donateFeeRate);
        setBalanceVaultAddress(_balanceVaultAddress);
    }

    /**
     * @dev Revert receive and fallback functions.
     */
    receive() external payable {
        revert("[Blogging] Revert receive function.");
    }

    fallback() external payable {
        revert("[Blogging] Revert fallback function.");
    }

    /**
     * @dev Allow for created blog.
     */
    modifier blogCreated(uint256 _blogId) {
        require(
            blogByBlogId[_blogId].blogId > 0,
            "[Blogging.blogCreated] Blog not created yet"
        );
        _;
    }

    /**
     * @dev Set contract into pause state.
     */
    function pauseBlogging() external onlyOwner {
        _pause();
    }

    /**
     * @dev Set contract back to normal state.
     */
    function unpauseBlogging() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Set new fee rate for paid blog.
     * @param _payFeeRate - Paid blog fee rate.
     */
    function setPayFeeRate(uint256 _payFeeRate) public onlyOwner {
        payFeeRate = _payFeeRate;
        emit PayFeeRateUpdated(_payFeeRate);
    }

    /**
     * @dev Set new fee rate for donation.
     * @param _donateFeeRate - Donation fee rate.
     */
    function setDonateFeeRate(uint256 _donateFeeRate) public onlyOwner {
        donateFeeRate = _donateFeeRate;
        emit DonateFeeRateUpdated(_donateFeeRate);
    }

    /**
     * @dev Set new address for balance vault interface.
     * @param _balanceVaultAddress - New balance vault address.
     */
    function setBalanceVaultAddress(address _balanceVaultAddress)
        public
        onlyOwner
    {
        balanceVault = IBalanceVaultV2(_balanceVaultAddress);
        emit BalanceVaultAddressUpdated(_balanceVaultAddress);
    }

    /**
     * @dev Set new owner for blog.
     * @param _currentBlogOwner - Current blog owner address.
     * @param _newBlogOwner - New blog owner address.
     * @notice Incase of emergency.
     */
    function setBlogOwner(address _currentBlogOwner, address _newBlogOwner)
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        require(
            blogOwnerIdByAddress[_newBlogOwner] == 0,
            "[Blogging.setBlogOwner] New blog owner already existed"
        );
        uint256 id = blogOwnerIdByAddress[_currentBlogOwner];
        delete blogOwnerIdByAddress[_currentBlogOwner];
        blogOwnerIdByAddress[_newBlogOwner] = id;
        blogOwnerByBlogOwnerId[id].blogOwner = _newBlogOwner;

        emit BlogOwnerUpdated(_currentBlogOwner, _newBlogOwner);
    }

    /**
     * @dev Set new owner for blog.
     * @param _currentUserWallet - Current blog owner address.
     * @param _newUserWallet - New blog owner address.
     * @notice Incase of emergency.
     */
    function setUserWallet(address _currentUserWallet, address _newUserWallet)
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        require(
            userIdByAddress[_newUserWallet] == 0,
            "[Blogging.setUserWallet] New user wallet already existed"
        );
        uint256 id = userIdByAddress[_currentUserWallet];
        delete userIdByAddress[_currentUserWallet];
        userIdByAddress[_newUserWallet] = id;
        userByUserId[id] = _newUserWallet;

        emit UserWalletUpdated(_currentUserWallet, _newUserWallet);
    }

    /**
     * @dev Set blog price.
     * @param _blogId - Blog id.
     * @param _price - New blog price.
     */
    function setBlogPrice(uint256 _blogId, uint256 _price)
        external
        whenNotPaused
        blogCreated(_blogId)
    {
        Blog storage blog = blogByBlogId[_blogId];
        require(
            blog.blogOwnerId == blogOwnerIdByAddress[msg.sender],
            "[Blogging.setBlogPrice] Caller is not owner"
        );
        blog.price = _price;

        emit BlogPriceUpdated(_blogId, _price);
    }

    /**
     * @dev Create blog and register blog owner.
     * @param _isPaidType - Boolean of blog paid type.
     * @param _price - Blog price.
     */
    function createBlog(
        bool _isPaidType,
        uint256 _price
    ) external whenNotPaused {
        Blog storage blog = blogByBlogId[++latestBlogId];
        blog.blogId = latestBlogId;
        _registerBlogOwner(msg.sender);
        blog.blogOwnerId = blogOwnerIdByAddress[msg.sender];
        blog.isPaidType = _isPaidType;
        blog.price = _price;

        emit BlogCreated(latestBlogId, msg.sender, _isPaidType, _price);
    }

    /**
     * @dev Withdraw fees stored.
     */
    function adminFeesWithdraw() external whenNotPaused onlyRole(WORKER) {
        uint256 withdrawAmount = totalFees;
        require(
            withdrawAmount > 0,
            "[Blogging.adminFeesWithdraw] Insufficient fees to withdraw"
        );
        totalFees = 0;
        balanceVault.transferUpoToAddress(msg.sender, withdrawAmount);

        emit AdminFeesWithdrawn(msg.sender, withdrawAmount);
    }

    /**
     * @dev Transfer token from sender, update user paid data, update blog and blogowner paid data.
     * @param _blogId - Blog id.
     */
    function payToBlog(uint256 _blogId)
        external
        whenNotPaused
        blogCreated(_blogId)
    {
        Blog storage blog = blogByBlogId[_blogId];
        require(blog.isPaidType, "[Blogging.payToBlog] Blog is not paid type");
        BlogOwner storage blogOwner = blogOwnerByBlogOwnerId[blog.blogOwnerId];
        _registerUserWallet(msg.sender);
        uint256 userId = userIdByAddress[msg.sender];

        require(
            !blog.paidByUserId[userId],
            "[Blogging.payToBlog] User already paid for this blog"
        );
        blog.paidByUserId[userId] = true;

        uint256 blogPrice = blog.price;
        if (blogPrice > 0) {
            uint256 fees = (blogPrice * payFeeRate) / 10000;
            uint256 actualPayAmount = blogPrice - fees;
            blog.income += actualPayAmount;
            blogOwner.totalIncome += actualPayAmount;
            totalFees += fees;
            balanceVault.payWithUpo(msg.sender, blogPrice);
            balanceVault.transferUpoToAddress(
                blogOwner.blogOwner,
                actualPayAmount
            );
        }

        emit BlogPaid(_blogId, msg.sender, blogPrice);
    }

    /**
     * @dev Transfer token from sender, update blog and blogowner donation data.
     * @param _blogId - Blog id.
     * @param _donateAmount - donate amount.
     */
    function donateToBlog(uint256 _blogId, uint256 _donateAmount)
        external
        whenNotPaused
        blogCreated(_blogId)
    {
        require(
            _donateAmount > 0,
            "[Blogging.donateToBlog] Invalid donate amount"
        );
        Blog storage blog = blogByBlogId[_blogId];
        BlogOwner storage blogOwner = blogOwnerByBlogOwnerId[blog.blogOwnerId];

        uint256 fees = (_donateAmount * donateFeeRate) / 10000;
        uint256 actualDonateAmount = _donateAmount - fees;
        blog.donate += actualDonateAmount;
        blogOwner.totalDonate += actualDonateAmount;
        totalFees += fees;
        balanceVault.payWithUpo(msg.sender, _donateAmount);
        balanceVault.transferUpoToAddress(
            blogOwner.blogOwner,
            actualDonateAmount
        );

        emit BlogDonated(_blogId, msg.sender, _donateAmount);
    }

    /**
     * @dev Retrieve blog infomation.
     * @param _blogId - Blog id.
     */
    function getBlogInfo(uint256 _blogId)
        external
        view
        returns (
            uint256 blogId,
            bool isPaidType,
            uint256 price,
            address blogOwner,
            uint256 donate,
            uint256 income
        )
    {
        Blog storage blog = blogByBlogId[_blogId];
        blogId = blog.blogId;
        isPaidType = blog.isPaidType;
        price = blog.price;
        blogOwner = blogOwnerByBlogOwnerId[blog.blogOwnerId].blogOwner;
        donate = blog.donate;
        income = blog.income;
    }

    /**
     * @dev Retrieve blog owner infomation.
     * @param _blogOwnerAddress - Blog owner address.
     */
    function getBlogOwnerInfo(address _blogOwnerAddress)
        external
        view
        returns (BlogOwner memory)
    {
        return blogOwnerByBlogOwnerId[blogOwnerIdByAddress[_blogOwnerAddress]];
    }

    /**
     * @dev Retrieve user paid status for specify list.
     * @param _userAddress - User address.
     * @param _blogIdList - List of blog id.
     */
    function getUserBlogPaidStatusList(
        address _userAddress,
        uint256[] calldata _blogIdList
    ) external view returns (bool[] memory blogPaidStatusList) {
        uint256 userId = userIdByAddress[_userAddress];
        blogPaidStatusList = new bool[](_blogIdList.length);
        for (uint256 i = 0; i < _blogIdList.length; i++) {
            blogPaidStatusList[i] = blogByBlogId[_blogIdList[i]].paidByUserId[
                userId
            ];
        }
    }

    /**
     * @dev Register blog owner if not exist.
     * @param _blogOwner - Blog owner address.
     */
    function _registerBlogOwner(address _blogOwner) internal {
        if (blogOwnerIdByAddress[_blogOwner] == 0) {
            latestBlogOwnerId++;
            BlogOwner storage blogOwner = blogOwnerByBlogOwnerId[
                latestBlogOwnerId
            ];
            blogOwnerIdByAddress[_blogOwner] = latestBlogOwnerId;
            blogOwner.blogOwner = _blogOwner;

            emit BlogOwnerRegistered(_blogOwner);
        }
    }

    /**
     * @dev Register user wallet if not exist.
     * @param _userWallet - User wallet address.
     */
    function _registerUserWallet(address _userWallet) internal {
        if (userIdByAddress[_userWallet] == 0) {
            latestUserId++;
            userIdByAddress[_userWallet] = latestUserId;
            userByUserId[latestUserId] = _userWallet;

            emit UserWalletRegistered(_userWallet);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBalanceVaultV2 {
    // UPO
    function getBalance(address _userAddress) external view returns (uint256);
    function depositUpo(uint256 _upoAmount) external;
    function withdrawUpo(uint256 _upoAmount) external;
    function increaseBalance(address _userAddress, uint256 _upoAmount) external;
    function decreaseBalance(address _userAddress, uint256 _upoAmount) external;
    function payWithUpo(address _userAddress, uint256 _upoAmount) external;
    function transferUpoToAddress(address _userAddress, uint256 _upoAmount) external;

    // Token
    function getTokenBalance(address _userAddress, address _tokenAddress) external view returns (uint256);
    function depositToken(address _tokenAddress, uint256 _tokenAmount) external;
    function withdrawToken(address _tokenAddress, uint256 _tokenAmount) external;
    function increaseTokenBalance(address _userAddress, address _tokenAddress, uint256 _upoAmount) external;
    function decreaseTokenBalance(address _userAddress, address _tokenAddress, uint256 _upoAmount) external;
    function payWithToken(address _userAddress, address _tokenAddress, uint256 _upoAmount) external;
    function transferTokenToAddress(address _userAddress, address _tokenAddress, uint256 _tokenAmount) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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