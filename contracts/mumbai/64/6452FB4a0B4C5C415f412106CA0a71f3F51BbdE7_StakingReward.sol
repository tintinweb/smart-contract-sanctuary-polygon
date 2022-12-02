// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./OwnerPausable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingReward is OwnerPausable {
    using SafeERC20 for IERC20;

    event Withdrawn(
        address indexed withdrawer,
        uint256 withdrawn,
        uint256 remained
    );

    event Claimed(
        address indexed withdrawer,
        uint256 rewardDebt,
        uint256 pendingRewards
    );

    struct UserInfo {
        uint256 stakedAmount; // Amount of staked tokens provided by user
        uint256 rewardDebt; // Reward debt
       // uint256 lastRewardBlock;
        uint256 level; //0-18%
       // uint256 firstOrderEndedBlock;
    }

    struct OrderInfo {
        uint256 index;
        uint256 addedBlock;
        uint256 amount;
        uint256 remainedAmount;
        uint256 lastRewardBlock;
    }

    struct LevelApy {
        uint256 startBlock;
        uint256 apy;
    }

    address immutable _ttAddress;
    address private _ttPayOutAddress;
    address private _privatePlacementAddress;

    // Precision factor for calculating rewards
    uint256 public constant PRECISION_FACTOR = 10**18;

    uint256 public constant RELEASE_CYCLE = 3 minutes;
    uint256 public constant RELEASE_CYCLE_TIMES = 6;

    uint256 private immutable SECONDS_PER_BLOCK;
    uint256 public immutable BASE_REWARD_PER_BLOCK; //1个代币单位 1%的apy 对应1个区块的奖励
    //uint256[] private apy = [18, 20, 28, 35, 60] ;
    mapping(address => UserInfo) private _userInfo;
    mapping(address => OrderInfo[]) private _orders;
    
    //index => apy
    mapping(uint256 => LevelApy[]) private apys;
    
    uint256 public loopCounter = 250;

    constructor(address owner, uint256 secondsPerBlock, address ttAddress, address ttPayOutAddress) OwnerPausable(owner) {
        SECONDS_PER_BLOCK = secondsPerBlock;
        BASE_REWARD_PER_BLOCK = secondsPerBlock*PRECISION_FACTOR/365 days/100;
        _ttAddress = ttAddress;
        _ttPayOutAddress = ttPayOutAddress;

        //uint256 number = block.number;
        
        // LevelApy[] storage apy0 = apys[0];
        // apy0[0] = LevelApy(number, 18);
        // LevelApy[] storage apy1 = apys[1];
        // apy1[0] = LevelApy(number, 20);
        // LevelApy[] storage apy2 = apys[2];
        // apy2[0] = LevelApy(number, 28);
        // LevelApy[] storage apy3 = apys[3];
        // apy3[0] = LevelApy(number, 30);
        // LevelApy[] storage apy4 = apys[4];
        // apy4[0] = LevelApy(number, 32);

        // apys[1] = [LevelApy(number, 20)];
        // apys[2] = [LevelApy(number, 28)];
        // apys[3] = [LevelApy(number, 30)];
        // apys[4] = [LevelApy(number, 32)];
    }

    modifier onlyPP() {
        require(msg.sender == _privatePlacementAddress, "not PrivatePlacement");
        _;
    }


    function setPrivatePlacementAddress(address privatePlacementAddress_) external onlyOwner{
        _privatePlacementAddress = privatePlacementAddress_;
    }

    function privatePlacementAddress() external view returns(address){
        return _privatePlacementAddress;
    }

    function deposit(address staker, uint256 amount) external onlyPP {
        
    }

    function updateUserLevel(address user, uint256 level) external {
        _userInfo[user].level = level;
        //TODO claim first
    }

    function addApy(uint256[] memory levels, uint256[] memory apys_) external {
        require(levels.length == apys_.length, "size error");
        for (uint i; i<levels.length; i++) {
            apys[levels[i]].push(LevelApy(block.number, apys_[i]));
        }
    }

    function setLoopCounter(uint256 counter) external {
        loopCounter = counter;
    }

    function depositMock(uint256 index, uint256 amount) external {
        address staker = msg.sender;
        UserInfo storage user = _userInfo[staker];
        OrderInfo[] storage userOrders = _orders[staker];

        //发放已有收益
        // if (_userInfo[staker].stakedAmount > 0) {
        //     uint256 pendingRewards;
        //     for (uint256 i; i < _orders[staker].length; i++) {
        //         uint256 multiplier = _getMultiplier(_orders[staker].lastRewardBlock, block.number, 
        //                 userOrders[i].addedBlock+RELEASE_CYCLE_TIMES*RELEASE_CYCLE/SECONDS_PER_BLOCK);
        //         pendingRewards += userOrders[i].amount*multiplier*apy[user.level]*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
        //     }
        //     user.rewardDebt += pendingRewards;
        // }

        //记录新记录
        // user.stakedAmount += amount;
        // userOrders.push(OrderInfo(index, block.number, amount, amount, block.number));
        
        user.stakedAmount += loopCounter*amount;
        for (uint256 i; i<loopCounter; i++) {
            userOrders.push(OrderInfo(index, block.number, amount, amount, block.number));
        }
    }


    function calculatePendingRewards(address staker) public view returns(uint256, uint256) {
        UserInfo memory user = _userInfo[staker];
        OrderInfo[] memory userOrders = _orders[staker];
        uint256 pendingRewards;
        if (_userInfo[staker].stakedAmount > 0) {
            for (uint256 i; i < userOrders.length; i++) {
                uint256 lastRewardBlock = userOrders[i].lastRewardBlock;
                uint256 endBlock = userOrders[i].addedBlock + RELEASE_CYCLE_TIMES*RELEASE_CYCLE/SECONDS_PER_BLOCK;
                LevelApy[] memory levelApys = apys[user.level];
                uint256 apySize = levelApys.length;
                if (lastRewardBlock >= levelApys[apySize-1].startBlock) {
                    uint256 multiplier = _getMultiplier(lastRewardBlock, block.number, endBlock);
                    pendingRewards += userOrders[i].amount*multiplier*levelApys[apySize-1].apy*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
                } else {
                    uint256 matches; //0-没有重合，1-第一次重合 2-第n次重合 n>1
                    for (uint256 j; j<apySize-1; j++) {
                        if (levelApys[j].startBlock <= lastRewardBlock && lastRewardBlock < levelApys[j+1].startBlock) {
                            matches = 1;
                        }

                        if (matches >= 1) {
                            //block[lastRewardBlock, [j+1].block] 享受 [j]的收益
                            uint256 multiplier = _getMultiplier(matches == 1 ? lastRewardBlock : levelApys[j].startBlock, levelApys[j+1].startBlock, endBlock);
                            pendingRewards += userOrders[i].amount*multiplier*levelApys[j].apy*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
                            matches = 2;
                        }
                    }
                    uint256 multiplier_ = _getMultiplier(levelApys[apySize-1].startBlock, block.number, endBlock);
                    pendingRewards += userOrders[i].amount*multiplier_*levelApys[apySize-1].apy*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
                }
            }
        }
        return (user.rewardDebt, pendingRewards);
    }

    function calculateWithdrawBack(address staker) public view returns(uint256[] memory, uint256) {
        OrderInfo[] memory userOrders = _orders[staker];
        uint256[] memory result = new uint256[](userOrders.length);
        uint256 total;
        if (_userInfo[staker].stakedAmount > 0) {
            for (uint256 i; i < userOrders.length; i++) {
                if (userOrders[i].remainedAmount == 0) {
                    continue;
                }
                uint256 period = (block.number - userOrders[i].addedBlock)/(RELEASE_CYCLE/SECONDS_PER_BLOCK);
                if (period > RELEASE_CYCLE_TIMES) {
                    period = RELEASE_CYCLE_TIMES;
                }
                if (period > 0) {
                    result[i] = userOrders[i].amount*period/RELEASE_CYCLE_TIMES - (userOrders[i].amount-userOrders[i].remainedAmount);
                    total += result[i];
                }
            }
        }
        return (result, total);
    }


    function userInfo(address staker) external view returns(UserInfo memory) {
        return _userInfo[staker];
    }

    function orders(address staker) external view returns(OrderInfo[] memory) {
        return _orders[staker];
    }

    function claim() external {
        address staker = msg.sender;

        (, uint256 pendingReward) = calculatePendingRewards(staker);
        UserInfo storage user = _userInfo[staker];
        uint256 claimAmount = user.rewardDebt + pendingReward;
        require(claimAmount > 0, "no claim tt");

        user.rewardDebt = 0;
        
        OrderInfo[] storage userOrders = _orders[staker];
        for (uint256 i; i < userOrders.length; i++) {
            userOrders[i].lastRewardBlock = block.number;
        }

        IERC20(_ttAddress).safeTransferFrom(_ttPayOutAddress, staker, claimAmount);
        emit Claimed(staker, user.rewardDebt, pendingReward);
    }

    // function harvest(uint256[] memory indexes) external {
    //     address staker = msg.sender;
    //     UserInfo storage user = _userInfo[staker];
    //     OrderInfo[] storage userOrders = _orders[staker];
    //     for (uint256 i; i < indexes.length; i++) {

    //     }

    // }


    function withdraw(uint256 amount) external {
        address withdrawer = msg.sender;
        (uint256[] memory arr, uint256 total) = calculateWithdrawBack(withdrawer);
        require(total >= amount, "withdraw too much");

        
        (, uint256 pendingReward) = calculatePendingRewards(withdrawer);
        UserInfo storage user = _userInfo[withdrawer];
        user.rewardDebt += pendingReward;

        uint256 withdrawn;
        OrderInfo[] storage userOrders = _orders[withdrawer];
        
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] == 0) {
                continue;
            }
            uint256 orderWithdrawAmount;
            if (amount - withdrawn >= arr[i]) {
                orderWithdrawAmount = arr[i];
            } else {
                orderWithdrawAmount = amount - withdrawn;
            }
            userOrders[i].remainedAmount = userOrders[i].remainedAmount - orderWithdrawAmount;
            withdrawn += orderWithdrawAmount;
            if (withdrawn == amount) {
                break;
            }
        }

        for (uint256 i; i < arr.length; i++) {
            userOrders[i].lastRewardBlock = block.number;
        }
        user.stakedAmount -= withdrawn;

        //TODO tt要从本身合约进行transfer，这里是mock版本
        IERC20(_ttAddress).safeTransferFrom(_ttPayOutAddress, withdrawer, withdrawn);

        emit Withdrawn(withdrawer, withdrawn, user.stakedAmount);
    }

    /**
     * @notice Return reward multiplier over the given "from" to "to" block.
     * @param from block to start calculating reward
     * @param to block to finish calculating reward
     * @return the multiplier for the period
     */
    function _getMultiplier(uint256 from, uint256 to, uint256 endBlock) internal pure returns (uint256) {
        if (to <= endBlock) {
            return to - from;
        } else if (from >= endBlock) {
            return 0;
        } else {
            return endBlock - from;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";

contract OwnerPausable is Pausable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;
    address private _candidate;
    address private _operator;

    
    constructor(address owner_) {
        require(owner_ != address(0), "owner is zero");
        _owner = owner_;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(_owner == msg.sender, "Ownable: caller is not the operator");
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(_operator == msg.sender || _owner == msg.sender, "Ownable: caller is not the operator or owner");
        _;
    }

    function setOperator(address operator) external onlyOwner {
        _operator = operator;
    }


    function candidate() public view returns (address) {
        return _candidate;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner zero address");
        require(newOwner != _owner, "newOwner same as original");
        require(newOwner != _candidate, "newOwner same as candidate");
        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() public {
        require(_candidate != address(0), "candidate is zero address");
        require(_candidate == _msgSender(), "not the new owner");

        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}