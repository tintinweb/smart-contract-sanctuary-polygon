// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICO.sol";
import "./utils/IBalanceVaultV2.sol";
import "./utils/IICO.sol";

/**
 * @dev Use to create new ICO contract for each correspoding chain.
 * Has a function to create new ICO contract.
 * Has a function to update existing ICO contract project owner.
 * Has a function to update stable coin address for creating new ICO contract.
 */
contract ICOFactory is Ownable, AccessControl {
    bytes32 public constant WORKER = keccak256("WORKER");

    IBalanceVaultV2 public balanceVault;
    mapping(address => uint256) public icoIdByAddress;
    mapping(uint256 => ICO) public icoById;
    uint256 public latestIcoId;

    event BalanceVaultAddressUpdated(address balanceVaultAddress);
    event ICOContractCreated(
        address indexed ICOAddress,
        address stableCoinAddress,
        address initialTokenAddress,
        uint256 totalBuyingLimit,
        uint256 rate,
        uint256 buyingLimit,
        uint256 startDate,
        uint256 endDate,
        address projectOwner
    );
    event ICOContractProjectOwnerUpdated(
        address indexed ICOAddress,
        address projectOwner
    );
    event ICOContractTokenDecimalUpdated(
        address indexed ICOAddress,
        uint256 decimal
    );

    /**
     * @dev Setup role for deployer.
     */
    constructor(address _balanceVaultAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(WORKER, msg.sender);

        setBalanceVaultAddress(_balanceVaultAddress);
    }

    /**
     * @dev Revert receive and fallback functions.
     */
    receive() external payable {
        revert("[ICOFactory] Revert receive function.");
    }

    fallback() external payable {
        revert("[ICOFactory] Revert fallback function.");
    }

    /**
     * @dev Allow for staking contract.
     */
    modifier onlyICOContrct() {
        require(
            icoIdByAddress[msg.sender] > 0,
            "[ICOFactory.onlyICOContrct] Only ICO contract"
        );
        _;
    }

    /**
     * @dev Create new ico contract with specify arguments.
     * @param _stableCoinAddress - Stable coin address.
     * @param _initialTokenAddress - Initial token address of user.
     * @param _totalBuyingLimit - Initial token amount.
     * @param _rate - Stable coin to initial token convertion rate.
     * @param _buyingLimit - Initial token limit for each buyer.
     * @param _startDate - ICO start date.
     * @param _endDate - ICO end date.
     * @param _roundPaid - Initial token distribute interval and portion.
     * @param _projectOwner - Purchased user address (project owner).
     */
    function createICOContract(
        address _stableCoinAddress,
        address _initialTokenAddress,
        uint256 _totalBuyingLimit,
        uint256 _rate,
        uint256 _buyingLimit,
        uint256 _startDate,
        uint256 _endDate,
        ICO.RoundPaid[] calldata _roundPaid,
        address _projectOwner
    ) external onlyRole(WORKER) {
        ICO ico = new ICO(
            _stableCoinAddress,
            _initialTokenAddress,
            _totalBuyingLimit,
            _rate,
            _buyingLimit,
            _startDate,
            _endDate,
            _roundPaid,
            _projectOwner
        );

        latestIcoId++;
        icoIdByAddress[address(ico)] = latestIcoId;
        icoById[latestIcoId] = ico;

        emit ICOContractCreated(
            address(ico),
            _stableCoinAddress,
            _initialTokenAddress,
            _totalBuyingLimit,
            _rate,
            _buyingLimit,
            _startDate,
            _endDate,
            _projectOwner
        );
    }

    /**
     * @dev Update project owner role for specify ICO contract.
     * @param _ICOAddress - ICO contract address.
     * @param _projectOwner - Purchased user address (project owner).
     */
    function changeICOContractProjectOwner(
        address _ICOAddress,
        address _projectOwner
    ) external onlyOwner {
        IICO ico = IICO(_ICOAddress);
        ico.changeProjectOwner(_projectOwner);

        emit ICOContractProjectOwnerUpdated(_ICOAddress, _projectOwner);
    }

    /**
     * @dev Update token decimal for exceptional case.
     * @param _ICOAddress - ICO contract address.
     * @param _decimal - Token decimal.
     */
    function changeICOContractTokenDecimal(
        address _ICOAddress,
        uint256 _decimal
    ) external onlyOwner {
        IICO ico = IICO(_ICOAddress);
        ico.changeTokenDecimal(_decimal);

        emit ICOContractTokenDecimalUpdated(_ICOAddress, _decimal);
    }

    /**
     * @dev Pay with specify token through balance vault.
     * @param _userAddress - User address.
     * @param _tokenAddress - Token address.
     * @param _tokenAmount - Token amount.
     */
    function vaultPayWithToken(
        address _userAddress,
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyICOContrct {
        balanceVault.payWithToken(_userAddress, _tokenAddress, _tokenAmount);
    }

    /**
     * @dev Transfer token from balance vault to address.
     * @param _userAddress - User address.
     * @param _tokenAddress - Token address.
     * @param _tokenAmount - Token amount.
     */
    function vaultTransferTokenToAddress(
        address _userAddress,
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyICOContrct {
        balanceVault.transferTokenToAddress(
            _userAddress,
            _tokenAddress,
            _tokenAmount
        );
    }

    /**
     * @dev Set new address for balance vault using specify address.
     * @param _balanceVaultAddress - New address of balance vault.
     */
    function setBalanceVaultAddress(address _balanceVaultAddress)
        public
        onlyOwner
    {
        balanceVault = IBalanceVaultV2(_balanceVaultAddress);

        emit BalanceVaultAddressUpdated(_balanceVaultAddress);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./utils/IICOFactory.sol";

/**
 * @dev This contract is designed to work as Initial Coin Offering(ICO).
 * Has function to buy token with stable coin.
 * Has function to withdraw token after period of time.
 * Has function to withdraw stable coin in case owner failed to swap reward.
 * Has function for owner to swap their token for stable coin.
 */
contract ICO is Ownable, AccessControl, ReentrancyGuard, Pausable {
    struct UserInfo {
        uint256 stableCoinAmount;
        uint256 tokenAmount;
        uint256 withdrawnAmount;
    }
    struct RoundPaid {
        uint256 paidIntervals;
        uint256 paidPortions;
    }

    bytes32 public constant PROJECTOWNER = keccak256("PROJECTOWNER");
    IICOFactory public icoFactory;
    address public stableCoin;
    address public token;

    // In stableCoin (USD)
    uint256 public totalBuyingLimit;
    // Rate 1 USD : x Token (wei)
    uint256 public rate;
    // Buying limit per person in stableCoin
    uint256 public buyingLimit;
    uint256 public startDate;
    uint256 public endDate;
    RoundPaid[] public roundPaid;
    address public projectOwner;

    uint256 public userCount;
    uint256 public totalStableCoin;
    uint256 public totalWithdrawStableCoin;
    uint256 public totalToken;
    uint256 public totalWithdrawToken;
    // wei
    uint256 public tokenDecimal;

    mapping(address => UserInfo) public users;

    event RoundPaidAdded(
        uint256 indexed index,
        uint256 paidInterval,
        uint256 paidPortion
    );
    event TokenBought(
        address indexed userAddress,
        uint256 stableCoinAmount,
        uint256 tokenAmount
    );
    event TokenWithdrawn(address indexed userAddress, uint256 tokenAmount);
    event StableCoinWithdrawn(
        address indexed userAddress,
        uint256 stableCoinAmount
    );
    event TokenSwapped(
        address indexed ownerAddress,
        uint256 tokenAmount,
        uint256 stableCoinAmount
    );
    event ProjectOwnerChanged(address projectOwner);
    event TokenDecimalChanged(uint256 decimal);

    /**
     * @dev Setup contract params and interface.
     * Setup role for deployer.
     */
    constructor(
        address _stableCoinAddress,
        address _initialTokenAddress,
        uint256 _totalBuyingLimit,
        uint256 _rate,
        uint256 _buyingLimit,
        uint256 _startDate,
        uint256 _endDate,
        RoundPaid[] memory _roundPaid,
        address _projectOwner
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        icoFactory = IICOFactory(msg.sender);
        stableCoin = _stableCoinAddress;
        token = _initialTokenAddress;
        totalBuyingLimit = _totalBuyingLimit;
        rate = _rate;
        buyingLimit = _buyingLimit;
        startDate = _startDate;
        endDate = _endDate;
        for (uint256 i = 0; i < _roundPaid.length; i++) {
            roundPaid.push(_roundPaid[i]);

            emit RoundPaidAdded(i, _roundPaid[i].paidIntervals, _roundPaid[i].paidPortions );
        }
        projectOwner = _projectOwner;
        grantRole(PROJECTOWNER, projectOwner);
        tokenDecimal = 1000000000000000000;
    }

    /**
     * @dev Only allow user who bought token.
     */
    modifier onlyBought(address _userAddress) {
        require(
            users[msg.sender].stableCoinAmount > 0,
            "[ICO.withdraw] Cannot withdraw if user balance is 0"
        );
        _;
    }

    /**
     * @dev Revert receive and fallback functions.
     */
    receive() external payable {
        revert("[ICO] Revert receive function");
    }

    fallback() external payable {
        revert("[ICO] Revert fallback function");
    }

    function increaseTime(uint256 _time) external {
        startDate -= _time;
        endDate -= _time;
        for (uint256 i = 0; i < roundPaid.length; i++) {
            roundPaid[i].paidIntervals -= _time;
        }
    }

    /**
     * @dev Function for user to buy token with stable coin.
     * Save bought amount in users mapping as stableCoinAmount.
     * Count unique buyer.
     * @param _stableAmount - Amount of stable coin that user
     * wanted to buy to get token.
     */
    function buyToken(uint256 _stableAmount) external {
        require(
            block.timestamp > startDate && block.timestamp < endDate,
            "[ICO.buyToken] Not in buying period"
        );
        require(
            users[msg.sender].stableCoinAmount + _stableAmount <= buyingLimit,
            "[ICO.buyToken] Exceed user's buying limit"
        );
        require(
            totalStableCoin + _stableAmount <= totalBuyingLimit,
            "[ICO.buyToken] Exceed total buying limit"
        );

        totalStableCoin += _stableAmount;
        if (users[msg.sender].tokenAmount == 0) {
            userCount++;
        }
        uint256 tokenAmount = (rate * _stableAmount) / tokenDecimal;
        users[msg.sender].stableCoinAmount += _stableAmount;
        users[msg.sender].tokenAmount += tokenAmount;
        icoFactory.vaultPayWithToken(msg.sender, stableCoin, _stableAmount);

        emit TokenBought(msg.sender, _stableAmount, tokenAmount);
    }

    /**
     * @dev Function for user to withdraw token when owner
     * successfully swap token with stable coin.
     * Only user who bought token can withdraw and will track
     * withdrawn amount in users mapping.
     */
    function withdrawToken() external nonReentrant onlyBought(msg.sender) {
        require(
            totalToken > 0,
            "[ICO.withdrawToken] Cannot withdraw token if token balance is 0"
        );
        require(
            block.timestamp > roundPaid[0].paidIntervals,
            "[ICO.withdrawToken] Not in withdrawing period"
        );

        uint256 withdrawAmount = calculateWithdrawAmount(msg.sender);
        users[msg.sender].withdrawnAmount += withdrawAmount;
        totalWithdrawToken += withdrawAmount;

        icoFactory.vaultTransferTokenToAddress(
            msg.sender,
            token,
            withdrawAmount
        );

        emit TokenWithdrawn(msg.sender, withdrawAmount);
    }

    /**
     * @dev Function for user to withdraw stable coin when owner
     * failed to swap token with stable coin.
     * Only user who bought token can withdraw and will delete
     * user's data from users mapping.
     */
    function withdrawStableCoin() external nonReentrant onlyBought(msg.sender) {
        require(
            totalToken == 0,
            "[ICO.withdrawStableCoin] Cannot withdraw stable coin if token balance more than 0"
        );
        require(
            block.timestamp > roundPaid[0].paidIntervals,
            "[ICO.withdrawStableCoin] Cannot withdraw stable coin before first interval"
        );

        uint256 withdrawAmount = users[msg.sender].stableCoinAmount;
        delete users[msg.sender];
        totalWithdrawStableCoin += withdrawAmount;
        icoFactory.vaultTransferTokenToAddress(
            msg.sender,
            stableCoin,
            withdrawAmount
        );

        emit StableCoinWithdrawn(msg.sender, withdrawAmount);
    }

    /**
     * @dev Function for project owner to swap token for stable coin
     * token will be deduct from owner's wallet coresponding to amount
     * of stable coin in this contract. And all stable coin in this contract
     * will be transfer to owner's wallet.
     */
    function swapTokenWithStableCoin()
        external
        nonReentrant
        onlyRole(PROJECTOWNER)
    {
        require(
            totalToken == 0,
            "[ICO.swapTokenWithStableCoin] Cannot swap token more than once"
        );
        require(
            block.timestamp > endDate,
            "[ICO.swapTokenWithStableCoin] Cannot swap token before endDate"
        );
        require(
            block.timestamp < roundPaid[0].paidIntervals,
            "[ICO.swapTokenWithStableCoin] Cannot swap token after first interval"
        );

        uint256 tokenAmount = (totalStableCoin * rate) / tokenDecimal;
        totalToken = tokenAmount;
        totalWithdrawStableCoin += totalStableCoin;

        icoFactory.vaultPayWithToken(msg.sender, token, tokenAmount);
        icoFactory.vaultTransferTokenToAddress(
            msg.sender,
            stableCoin,
            totalStableCoin
        );

        emit TokenSwapped(msg.sender, tokenAmount, totalStableCoin);
    }

    /**
     * @dev Function for calculate user's withdrawable amount by comparing
     * current time with paidInterval and return withdrawable amount
     * corresponding to paidPortion and withdrawn amount.
     */
    function calculateWithdrawAmount(
        address _userAddress
    ) public view returns (uint256) {
        UserInfo memory user = users[_userAddress];
        uint256 withdrawAmount;
        uint256 totalPaidPortion;
        uint256 currentTime = block.timestamp;
        if (currentTime > roundPaid[0].paidIntervals) {
            for (uint256 i = 0; i < roundPaid.length; i++) {
                if (currentTime >= roundPaid[i].paidIntervals) {
                   totalPaidPortion += roundPaid[i].paidPortions;
                } else {
                    break;
                }
            }

            withdrawAmount =
                ((totalPaidPortion * user.tokenAmount) / 10000) -
                user.withdrawnAmount;
        }
        return withdrawAmount;
    }

    /**
     * @dev Function for admin to change project owner from contract factory
     * in case of emergency.
     */
    function changeProjectOwner(address _projectOwner) external onlyOwner {
        revokeRole(PROJECTOWNER, projectOwner);

        projectOwner = _projectOwner;
        grantRole(PROJECTOWNER, projectOwner);

        emit ProjectOwnerChanged(_projectOwner);
    }

    /**
     * @dev Function for admin to change token's decimal if some token does
     * not use 18 decimals.
     */
    function changeTokenDecimal(uint256 _decimal) external onlyOwner {
        tokenDecimal = _decimal;

        emit TokenDecimalChanged(_decimal);
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
pragma solidity ^0.8.7;

interface IICO{
    function changeProjectOwner(address _projectOwner) external;
    function changeTokenDecimal(uint256 _decimal) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
pragma solidity ^0.8.7;

interface IICOFactory{
    function vaultPayWithToken(address _userAddress, address _tokenAddress, uint256 _tokenAmount) external;
    function vaultTransferTokenToAddress(address _userAddress, address _tokenAddress, uint256 _tokenAmount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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