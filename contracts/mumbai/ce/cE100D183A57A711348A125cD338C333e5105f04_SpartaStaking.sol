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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title IAccessControlHolder
 * @notice Interface created to store reference to the access control.
 */
interface IAccessControlHolder {
    /**
     * @notice Function returns reference to IAccessControl.
     * @return IAccessControl reference to access control.
     */
    function acl() external view returns (IAccessControl);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * @title IWithFees.
 * @notice This interface describes the functions for managing fees in a contract.
 */
interface IWithFees {
    error OnlyFeesManagerAccess();
    error OnlyWithFees();
    error ETHTransferFailed();

    /**
     * @notice Function returns the treasury address where fees are collected.
     * @return The address of the treasury .
     */
    function treasury() external view returns (address);

    /**
     * @notice Function returns the value of the fees.
     * @return uint256 Amount of fees to pay.
     */
    function value() external view returns (uint256);

    /**
     * @notice Function transfers the collected fees to the treasury address.
     */
    function transfer() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface ISpartaStaking {
    error TransferFailed();
    error RewardBalanceTooSmall();
    error BeforeStakingStart();
    error AfterStakingFinish();
    error AmountZero();
    error TokensAlreadyClaimed();
    error RoundDoesNotExist();
    error BeforeReleaseTime();
    error TooSmallAmount();
    error StartInPast();

    struct TokensToClaim {
        bool taken;
        uint256 release;
        uint256 value;
    }

    event Staked(address indexed wallet, uint256 value);
    event Unstaked(
        address indexed wallet,
        uint256 tokensAmount,
        uint256 tokensToClaim,
        uint256 duration
    );
    event TokensClaimed(
        address indexed wallet,
        uint256 indexed roundId,
        uint256 tokensToClaimid
    );
    event RewardTaken(address indexed wallet, uint256 amount);

    event Initialized(uint256 start, uint256 duration, uint256 reward);

    function finishAt() external view returns (uint256);

    function stake(uint256 _amount) external;

    function stakeAs(address _wallet, uint256 _amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../tokens/interfaces/IStakedSparta.sol";
import "./interfaces/ISpartaStaking.sol";
import "../ToInitialize.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../WithFees.sol";
import "../ZeroAddressGuard.sol";
import "../ZeroAmountGuard.sol";

contract SpartaStaking is
    ISpartaStaking,
    ToInitialize,
    Ownable,
    WithFees,
    ZeroAddressGuard,
    ZeroAmountGuard
{
    uint256 public constant MINIMAL_LOCK_AMOUNT = 1e16;

    IERC20 public immutable sparta;
    IStakedSparta public immutable stakedSparta;
    uint256 public totalSupply;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;
    uint256 public start;
    uint256 public updatedAt;
    uint256 public duration;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public userTokensToClaimCounter;
    mapping(address => mapping(uint256 => TokensToClaim))
        public userTokensToClaim;

    modifier isOngoing() {
        if (block.timestamp < start) {
            revert BeforeStakingStart();
        }
        if (finishAt() < block.timestamp) {
            revert AfterStakingFinish();
        }
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    modifier minimumAmoutOfTokens(uint256 amount) {
        if (amount < MINIMAL_LOCK_AMOUNT) {
            revert TooSmallAmount();
        }
        _;
    }

    constructor(
        IERC20 sparta_,
        IStakedSparta stakedSparta_,
        IAccessControl _acl,
        address _treasury,
        uint256 _value
    ) WithFees(_acl, _treasury, _value) {
        sparta = sparta_;
        stakedSparta = stakedSparta_;
        _transferOwnership(msg.sender);
    }

    function stake(uint256 _amount) external {
        stakeAs(msg.sender, _amount);
    }

    function initialize(
        uint256 _amount,
        uint256 _start,
        uint256 _duration
    ) external notInitialized onlyOwner updateReward(address(0)) {
        if (sparta.balanceOf(address(this)) < _amount) {
            revert RewardBalanceTooSmall();
        }

        duration = _duration;
        start = _start;
        rewardRate = _amount / duration;

        updatedAt = block.timestamp;

        initialized = true;

        emit Initialized(_start, _duration, _amount);
    }

    function finishAt() public view override returns (uint256) {
        return start + duration;
    }

    function stakeAs(
        address wallet,
        uint256 amount
    )
        public
        isInitialized
        isOngoing
        minimumAmoutOfTokens(amount)
        updateReward(wallet)
        notZeroAddress(wallet)
    {
        if (!sparta.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }

        balanceOf[wallet] += amount;
        totalSupply += amount;
        stakedSparta.mintTo(wallet, amount);

        emit Staked(wallet, amount);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0 || block.timestamp < start) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt(), block.timestamp);
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function unstake(
        uint256 _amount,
        uint256 _after
    ) public payable onlyWithFees isInitialized updateReward(msg.sender) {
        if (_amount == 0) {
            revert AmountZero();
        }
        uint256 round = userTokensToClaimCounter[msg.sender];
        uint256 tokensToWidthdraw = calculateWithFee(_amount, _after);
        uint256 releaseTime = _after + block.timestamp;

        userTokensToClaim[msg.sender][round] = TokensToClaim(
            false,
            releaseTime,
            tokensToWidthdraw
        );
        stakedSparta.burnFrom(msg.sender, _amount);
        ++userTokensToClaimCounter[msg.sender];
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;

        emit Unstaked(msg.sender, _amount, tokensToWidthdraw, releaseTime);
    }

    function calculateWithFee(
        uint256 input,
        uint256 _duration
    ) public pure returns (uint256) {
        uint256 saturatedDuration = _duration > 100 days ? 100 days : _duration;
        uint256 feesNominator = ((100 days - saturatedDuration) * 500) / 1 days;
        uint256 feesOnAmount = (input * feesNominator) / 100000;
        return input - feesOnAmount;
    }

    function getReward()
        public
        payable
        isInitialized
        updateReward(msg.sender)
        onlyWithFees
    {
        uint256 reward = rewards[msg.sender];
        if (reward == 0) {
            revert AmountZero();
        }
        if (!sparta.transfer(msg.sender, reward)) {
            revert TransferFailed();
        }
        rewards[msg.sender] = 0;

        emit RewardTaken(msg.sender, reward);
    }

    function toEnd() external view returns (uint256) {
        return block.timestamp >= finishAt() ? 0 : finishAt() - block.timestamp;
    }

    function withdrawTokensToClaim(uint256 round) public payable onlyWithFees {
        TokensToClaim storage tokensToClaim = userTokensToClaim[msg.sender][
            round
        ];
        if (tokensToClaim.release == 0) {
            revert RoundDoesNotExist();
        }
        if (block.timestamp < tokensToClaim.release) {
            revert BeforeReleaseTime();
        }
        if (tokensToClaim.taken) {
            revert TokensAlreadyClaimed();
        }
        if (!sparta.transfer(msg.sender, tokensToClaim.value)) {
            revert TransferFailed();
        }

        tokensToClaim.taken = true;

        emit TokensClaimed(msg.sender, tokensToClaim.value, round);
    }

    function withdrawTokensToClaimFromRounds(uint256[] memory rounds) external {
        uint256 roundsLength = rounds.length;
        for (uint roundIndex = 0; roundIndex < roundsLength; ++roundIndex) {
            withdrawTokensToClaim(rounds[roundIndex]);
        }
    }

    function totalPendingToClaim(address wallet) public view returns (uint256) {
        uint256 toClaim = 0;
        uint256 rounds = userTokensToClaimCounter[wallet];
        for (uint256 roundIndex = 0; roundIndex < rounds; ++roundIndex) {
            TokensToClaim memory tokensToClaim = userTokensToClaim[wallet][
                roundIndex
            ];
            if (!tokensToClaim.taken) {
                toClaim += tokensToClaim.value;
            }
        }
        return toClaim;
    }

    function totalLocked(address wallet) external view returns (uint256) {
        return totalPendingToClaim(wallet) + earned(wallet) + balanceOf[wallet];
    }

    function getUserAllocations(
        address _wallet
    ) external view returns (TokensToClaim[] memory) {
        uint256 counter = userTokensToClaimCounter[_wallet];
        TokensToClaim[] memory toClaims = new TokensToClaim[](counter);

        for (uint256 i = 0; i < counter; ++i) {
            toClaims[i] = userTokensToClaim[_wallet][i];
        }

        return toClaims;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

contract ToInitialize {
    error AlreadyInitialized();
    error NotInitialized();

    bool internal initialized = false;

    modifier isInitialized() {
        _isInitialized();
        _;
    }

    function _isInitialized() internal view {
        if (!initialized) {
            revert NotInitialized();
        }
    }

    modifier notInitialized() {
        if (initialized) {
            revert AlreadyInitialized();
        }
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakedSparta is IERC20 {
    function mintTo(address to, uint256 amount) external;

    function burnFrom(address wallet, uint256 amount) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./IAccessControlHolder.sol";
import "./IWithFees.sol";

/**
 * @title WithFees
 * @notice This contract is responsible for managing, calculating and transferring fees.
 */
contract WithFees is IAccessControlHolder, IWithFees {
    address public immutable override treasury;
    uint256 public immutable override value;
    IAccessControl public immutable override acl;
    bytes32 public constant FEES_MANAGER = keccak256("FEES_MANAGER");

    /**
     * @notice Modifier to allow only function calls that are accompanied by the required fee.
     * @dev Function reverts with OnlyWithFees, if the value is smaller than expected.
     */
    modifier onlyWithFees() {
        if (value > msg.value) {
            revert OnlyWithFees();
        }
        _;
    }

    /**
     * @notice Modifier to allow only accounts with FEES_MANAGER role.
     * @dev Reverts with OnlyFeesManagerAccess, if the sender does not have the role.
     */
    modifier onlyFeesManagerAccess() {
        if (!acl.hasRole(FEES_MANAGER, msg.sender)) {
            revert OnlyFeesManagerAccess();
        }
        _;
    }

    constructor(IAccessControl _acl, address _treasury, uint256 _value) {
        acl = _acl;
        treasury = _treasury;
        value = _value;
    }

    /**
     * @notice Transfers the balance of the contract to the treasury.
     * @dev  Only accessible by an account with the FEES_MANAGER role.
     */
    function transfer() external onlyFeesManagerAccess {
        (bool sent, ) = treasury.call{value: address(this).balance}("");
        if (!sent) {
            revert ETHTransferFailed();
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * @title ZeroAddressGuard.
 * @notice This contract is responsible for ensuring that a given address is not a zero address.
 */

contract ZeroAddressGuard {
    error ZeroAddress();

    /**
     * @notice Modifier to make a function callable only when the provided address is non-zero.
     * @dev If the address is a zero address, the function reverts with ZeroAddress error.
     * @param _addr Address to be checked..
     */
    modifier notZeroAddress(address _addr) {
        _ensureIsNotZeroAddress(_addr);
        _;
    }

    /// @notice Checks if a given address is a zero address and reverts if it is.
    /// @param _addr Address to be checked.
    /// @dev If the address is a zero address, the function reverts with ZeroAddress error.
    /**
     * @notice Checks if a given address is a zero address and reverts if it is.
     * @dev     .
     * @param   _addr  .
     */
    function _ensureIsNotZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) {
            revert ZeroAddress();
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * @title ZeroAmountGuard
 * @notice This contract provides a modifier to guard against zero values in a transaction.
 */
contract ZeroAmountGuard {
    error ZeroAmount();

    /**
     * @notice Modifier ensures the amount provided is not zero.
     * param _amount The amount to check.
     * @dev If the amount is zero, the function reverts with a ZeroAmount error.
     */
    modifier notZeroAmount(uint256 _amount) {
        _ensureIsNotZero(_amount);
        _;
    }

    /**
     * @notice Function verifies that the given amount is not zero.
     * @param _amount The amount to check.
     */
    function _ensureIsNotZero(uint256 _amount) internal pure {
        if (_amount == 0) {
            revert ZeroAmount();
        }
    }
}