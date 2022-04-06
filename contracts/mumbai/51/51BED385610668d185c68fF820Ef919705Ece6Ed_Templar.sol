/**
 *Submitted for verification at polygonscan.com on 2022-04-05
*/

// SPDX-License-Identifier: MIT

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Owner {
    bool private _contractCallable = false;
    bool private _pause = false;
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);
    event SetContractCallable(bool indexed able, address indexed owner);

    constructor() {
        _owner = msg.sender;
    }

    // ownership
    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function setPendingOwner(address account) public onlyOwner {
        require(account != address(0), "zero address");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }

    function becomeOwner() external {
        require(msg.sender == _pendingOwner, "not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }

    modifier checkPaused() {
        require(!paused(), "paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _pause;
    }

    function setPaused(bool p) external onlyOwner {
        _pause = p;
    }

    modifier checkContractCall() {
        require(contractCallable() || notContract(msg.sender), "non contract");
        _;
    }

    function contractCallable() public view virtual returns (bool) {
        return _contractCallable;
    }

    function setContractCallable(bool able) external onlyOwner {
        _contractCallable = able;
        emit SetContractCallable(able, _owner);
    }

    function notContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size == 0;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Templar is Owner {
    using SafeMath for uint256;

    struct RewardInfo {
        uint256 pdReward;
        uint256 ngcReward;
    }
    struct AccountInfo {
        RewardInfo rewardInfo;
        address inviter;
        address[] invitee;
    }
    struct Miner {
        string name;
        bool exist;
        bool enable;
    }

    address public pdToken;
    address public ngcToken;
    address public pdPair;

    address public destroyAddress =
        address(0x000000000000000000000000000000000000dEaD);

    address public platformAddress;

    mapping(address => Miner) public miners;
    address[] private allMiners;

    mapping(address => mapping(address => RewardInfo)) private userRewardinfo;
    mapping(address => AccountInfo) private accountInfo;

    event Bind(address indexed inviter, address indexed invitee);
    event AddMiner(address indexed miner);
    event MinerEnable(address indexed miner, bool enable);

    constructor(
        address pdToken_,
        address ngcToken_,
        address pdPair_
    ) Owner() {
        pdToken = pdToken_;
        ngcToken = ngcToken_;
        pdPair = pdPair_;

        platformAddress = msg.sender;
    }

    function setPlatformAddress(address _token) public onlyOwner {
        require(_token != address(0), "_token is empty");

        platformAddress = _token;
    }

    receive() external payable {}

    function addMinter(address miner_, string memory name_) external onlyOwner {
        require(!miners[miner_].exist, "Comptroller: miner is exist");

        miners[miner_] = Miner({name: name_, exist: true, enable: true});

        allMiners.push(miner_);
        emit AddMiner(miner_);
    }

    function minerEnable(address miner_, bool enable) external onlyOwner {
        miners[miner_].enable = enable;
        emit MinerEnable(miner_, enable);
    }

    function getAllMiners() external view returns (address[] memory) {
        return allMiners;
    }

    function swap(uint256 amount) public checkContractCall checkPaused {
        IERC20(ngcToken).transferFrom(msg.sender, destroyAddress, amount);

        address parent = accountInfo[msg.sender].inviter;

        if (parent != address(0)) {
            IERC20(pdToken).transfer(pdPair, amount.mul(5).div(100));
            IERC20(pdToken).transfer(parent, amount.mul(5).div(100));

            accountInfo[parent].rewardInfo.pdReward += amount.mul(5).div(100);
            userRewardinfo[parent][msg.sender].pdReward += amount.mul(5).div(
                100
            );
        } else {
            IERC20(pdToken).transfer(pdPair, amount.mul(5).div(100));
            IERC20(pdToken).transfer(platformAddress, amount.mul(5).div(100));
        }
        IERC20(pdToken).transfer(msg.sender, amount.mul(90).div(100));
    }

    function setParentByAdmin(address user, address parent) public onlyOwner {
        require(accountInfo[user].inviter == address(0), "already bind");
        accountInfo[user].inviter = parent;
        accountInfo[parent].invitee.push(user);
        emit Bind(parent, user);
    }

    function bind(address inviter) external checkContractCall checkPaused {
        require(inviter != address(0), "not zero account");
        require(inviter != msg.sender, "can not be yourself");
        require(accountInfo[msg.sender].inviter == address(0), "already bind");
        accountInfo[msg.sender].inviter = inviter;
        accountInfo[inviter].invitee.push(msg.sender);
        emit Bind(inviter, msg.sender);
    }

    function setUserReward(
        address user,
        uint256 pdRew,
        uint256 ngcRew
    ) external checkContractCall checkPaused {
        require(miners[msg.sender].enable, "get out");

        address parent = accountInfo[user].inviter;
        if (parent != address(0)) {
            accountInfo[parent].rewardInfo.pdReward += pdRew;
            accountInfo[parent].rewardInfo.ngcReward += ngcRew;

            userRewardinfo[parent][user].pdReward += pdRew;
            userRewardinfo[parent][user].ngcReward += ngcRew;
        }
    }

    function getUserRewardInfo(address parent, address user)
        public
        view
        returns (uint256 pdReward, uint256 ngcReward)
    {
        RewardInfo memory reward = userRewardinfo[parent][user];
        return (reward.pdReward, reward.ngcReward);
    }

    function getInvitation(address account)
        external
        view
        returns (
            address inviter,
            address[] memory invitees,
            uint256 pdReward,
            uint256 ngcReward
        )
    {
        AccountInfo memory info = accountInfo[account];
        return (
            info.inviter,
            info.invitee,
            info.rewardInfo.pdReward,
            info.rewardInfo.ngcReward
        );
    }
}