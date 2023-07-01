// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './StakingV2Vendor.sol';
import './IStakingV2.sol';
import "./IStakingV2Factory.sol";

/**
 * @title Token Staking
 * @dev BEP20 compatible token.
 */
contract StakingV2Factory is IStakingV2Factory {

    function createVendor(address _parent, IERC20 _token) external virtual override returns (address) {
        StakingV2Vendor vendor = new StakingV2Vendor(_parent, _token);
        vendor.transferOwnership(_parent);
        return address(vendor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './IStakingV2.sol';

/**
 * @title Token Staking
 * @dev BEP20 compatible token.
 */
contract StakingV2Vendor is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct SuperPoolInfo {
        uint256 lastBlock;
        uint256 tokenPerShare;
        uint256 tokenRealStaked;
        uint256 tokenVirtStaked;
        uint256 tokenRewarded;
        uint256 tokenTotalLimit;
        uint256 lockupMaxTimerange;
        uint256 lockupMinTimerange;
    }

    struct SuperUserInfo {
        uint256 amount;
        uint256 rewardDebt; // backwards compatibility
        uint256 pendingRewards; // backwards compatibility
        uint256 lockedTimestamp;
        uint256 lockupTimestamp;
        uint256 lockupTimerange;
        uint256 virtAmount;
    }

    struct UserInfo {
        uint256 rewardDebt;
        uint256 pendingRewards;
    }

    struct PoolInfo {
        uint256 lastBlock;
        uint256 tokenPerShare;
        uint256 tokenRewarded;
        uint256 realTokenPerShare;
        uint256 realTokenReceived;
        uint256 realTokenRewarded;
    }

    IERC20 public token;
    IStakingV2 public parent;

    uint256 public tokenPerBlock;
    uint256 public tokenParentPrecision;
    uint256 public startBlock;
    uint256 public closeBlock;
    
    uint256 public maxPid;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event WithdrawnReward(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event WithdrawnRemain(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event TokenAddressChanged(address indexed token);
    event TokenRewardsChanged(address indexed token, uint256 amount);

    event ParentChanged(address indexed addr);
    event StartBlockChanged(uint256 block);
    event CloseBlockChanged(uint256 block);

    constructor(address _parent, IERC20 _token) {
        setParent(_parent);
        setTokenAddress(_token);
        for (uint i=0; i<parent.maxPid(); i++) addPool(i);
        tokenParentPrecision = parent.tokenPerBlock();
    }

    function setParent(address _parent) public onlyOwner {
        require(_parent != address(0), 'Staking: parent address needs to be different than zero!');
        parent = IStakingV2(_parent);
        emit ParentChanged(address(parent));
    }

    function setTokenAddress(IERC20 _token) public onlyOwner {
        require(address(_token) != address(0), 'Staking: token address needs to be different than zero!');
        require(address(token) == address(0), 'Staking: tokens already set!');
        token = _token;
        emit TokenAddressChanged(address(token));
    }

    function setTokenPerBlock(uint256 _tokenPerBlock, uint256 _startBlock, uint256 _closeBlock) public virtual onlyOwner {
        if (_startBlock != startBlock) setStartBlock(_startBlock);
        if (_closeBlock != closeBlock) setCloseBlock(_closeBlock);
        setTokenPerBlock(_tokenPerBlock);
    }

    function setTokenPerBlock(uint256 _tokenPerBlock) public virtual onlyOwner {
        require(startBlock != 0, 'Staking: cannot set reward before setting start block');
        for (uint i=0; i<maxPid; i++) updatePool(i);
        tokenPerBlock = _tokenPerBlock;
        emit TokenRewardsChanged(address(token), _tokenPerBlock);
    }

    function setStartBlock(uint256 _startBlock) public virtual onlyOwner {
        require(startBlock == 0 || startBlock > block.number, 'Staking: start block already set');
        require(_startBlock > 0, 'Staking: start block needs to be higher than zero!');
        startBlock = _startBlock;
        emit StartBlockChanged(_startBlock);
    }

    function setCloseBlock(uint256 _closeBlock) public virtual onlyOwner {
        require(startBlock != 0, 'Staking: start block needs to be set first');
        require(closeBlock == 0 || closeBlock > block.number, 'Staking: close block already set');
        require(_closeBlock == 0 || _closeBlock > startBlock, 'Staking: close block needs to be higher than start one!');
        closeBlock = _closeBlock;
        emit CloseBlockChanged(_closeBlock);
    }

    function withdrawRemaining(address addr) external virtual onlyOwner {
        if (startBlock == 0 || closeBlock == 0 || block.number <= closeBlock) {
            return;
        }
        for (uint i=0; i<maxPid; i++) {
            updatePool(i);
        }

        uint256 allTokenRewarded = 0;
        uint256 allTokenReceived = 0;

        for (uint i=0; i<maxPid; i++) {
            allTokenRewarded = allTokenRewarded.add(poolInfo[i].realTokenRewarded);
            allTokenReceived = allTokenReceived.add(poolInfo[i].realTokenReceived);
        }

        uint256 unlockedAmount = 0;
        uint256 possibleAmount = token.balanceOf(address(parent));
        uint256 reservedAmount = allTokenRewarded.sub(allTokenReceived);

        // if token is the same as deposit token then deduct staked tokens as non withdrawable
        if (address(token) == address(parent.token())) {
            for (uint i=0; i<maxPid; i++) {
                reservedAmount = reservedAmount.add(getParentPoolInfo(i).tokenRealStaked);
            }
        }

        if (possibleAmount > reservedAmount) {
            unlockedAmount = possibleAmount.sub(reservedAmount);
        }
        if (unlockedAmount > 0) {
            token.safeTransferFrom(address(parent), addr, unlockedAmount);
            emit WithdrawnRemain(addr, 0, address(token), unlockedAmount);
        }
    }

    function pendingRewards(uint256 pid, address addr) external virtual view returns (uint256) {
        if (pid >= maxPid || startBlock == 0 || block.number < startBlock) {
            return 0;
        }

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];
        SuperUserInfo memory superUser = getParentUserInfo(pid, addr);
        uint256 amount = superUser.virtAmount;

        uint256 lastMintedBlock = pool.lastBlock;
        if (lastMintedBlock == 0) {
            lastMintedBlock = startBlock;
        }
        uint256 lastBlock = getLastRewardBlock();
        if (lastBlock == 0) {
            return 0;
        }
        SuperPoolInfo memory superPool = getParentPoolInfo(pid);
        uint256 poolTokenRealStaked = superPool.tokenVirtStaked;

        uint256 realTokenPerShare = pool.realTokenPerShare;
        if (lastBlock > lastMintedBlock && poolTokenRealStaked != 0) {
            uint256 multiplier = lastBlock.sub(lastMintedBlock);
            uint256 tokenAward = multiplier.mul(parent.tokenPerBlock());
            uint256 tokenPerShare = tokenAward.mul(1e12).div(poolTokenRealStaked);
            realTokenPerShare = realTokenPerShare.add(tokenPerShare.mul(tokenPerBlock));
        }

        return amount.mul(realTokenPerShare).div(1e12).div(tokenParentPrecision).sub(user.rewardDebt).add(user.pendingRewards);
    }

    function update(uint256 pid, address user, uint256 amount) external virtual onlyOwner {
        if (pid >= maxPid || startBlock == 0 || block.number < startBlock) {
            return;
        }
        updatePool(pid);
        updatePendingReward(pid, user);
        updateRealizeReward(pid, user, amount);
    }

    function claim(uint256 pid, address addr) external virtual onlyOwner returns (uint256) {
        if (pid >= maxPid || startBlock == 0 || block.number < startBlock) {
            return 0;
        }

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];

        updatePool(pid);
        updatePendingReward(pid, addr);

        uint256 claimedAmount = 0;
        if (user.pendingRewards > 0) {
            claimedAmount = transferPendingRewards(pid, addr, user.pendingRewards);
            emit WithdrawnReward(addr, pid, address(token), claimedAmount);
            user.pendingRewards = user.pendingRewards.sub(claimedAmount);
            pool.realTokenReceived = pool.realTokenReceived.add(claimedAmount);
        }

        updateRealizeReward(pid, addr);

        return claimedAmount;
    }

    function addPool(uint256 pid) internal {
        require(maxPid < 10, 'Staking: Cannot add more than 10 pools!');

        SuperPoolInfo memory superPool = getParentPoolInfo(pid);
        poolInfo.push(PoolInfo({
            lastBlock: 0,
            tokenPerShare: superPool.tokenPerShare,
            tokenRewarded: superPool.tokenRewarded,
            realTokenPerShare: 0,
            realTokenReceived: 0,
            realTokenRewarded: 0
        }));
        maxPid = maxPid.add(1);
    }

    function updatePool(uint256 pid) internal {
        if (pid >= maxPid) {
            return;
        }
        if (startBlock == 0 || block.number < startBlock) {
            return;
        }
        PoolInfo storage pool = poolInfo[pid];
        if (pool.lastBlock == 0) {
            pool.lastBlock = startBlock;
        }
        uint256 lastBlock = getLastRewardBlock();
        if (lastBlock <= pool.lastBlock) {
            return;
        }
        SuperPoolInfo memory superPool = getParentPoolInfo(pid);
        uint256 poolTokenRealStaked = superPool.tokenVirtStaked;
        if (poolTokenRealStaked == 0) {
            return;
        }

        // compute the difference between last update in vendor and last update in core staking contract
        // then multiply it by rewardPerBlock value to correctly compute reward
        uint256 multiplier = lastBlock.sub(pool.lastBlock);
        uint256 divisor = superPool.lastBlock.sub(pool.lastBlock);

        uint256 tokenRewarded = superPool.tokenRewarded.sub(pool.tokenRewarded);
        uint256 tokenPerShare = superPool.tokenPerShare.sub(pool.tokenPerShare);

        // if multiplier is different than divisor it means, that before update vendor contract has been closed, therefore
        // we need to multiply the values instead of overwtiitng as the block after close should not count here
        if (multiplier != divisor) {
            tokenRewarded = tokenRewarded.mul(multiplier).div(divisor);
            tokenPerShare = tokenPerShare.mul(multiplier).div(divisor);
        }
        pool.tokenRewarded = pool.tokenRewarded.add(tokenRewarded);
        pool.tokenPerShare = pool.tokenPerShare.add(tokenPerShare);

        pool.realTokenRewarded = pool.realTokenRewarded.add(tokenRewarded.mul(tokenPerBlock).div(tokenParentPrecision));
        pool.realTokenPerShare = pool.realTokenPerShare.add(tokenPerShare.mul(tokenPerBlock));
        pool.lastBlock = lastBlock;
    }

    function updatePendingReward(uint256 pid, address addr) internal {
        if (pid >= maxPid) {
            return;
        }
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];
        SuperUserInfo memory superUser = getParentUserInfo(pid, addr);
        uint256 amount = superUser.virtAmount;

        uint256 reward;
        reward = amount.mul(pool.realTokenPerShare).div(1e12).div(tokenParentPrecision).sub(user.rewardDebt);
        if (reward > 0) {
            user.pendingRewards = user.pendingRewards.add(reward);
            user.rewardDebt = user.rewardDebt.add(reward);
        }
    }

    function updateRealizeReward(uint256 pid, address addr) internal {
        if (pid >= maxPid) {
            return;
        }
        SuperUserInfo memory superUser = getParentUserInfo(pid, addr);
        uint256 amount = superUser.virtAmount;
        return updateRealizeReward(pid, addr, amount);
    }

    function updateRealizeReward(uint256 pid, address addr, uint256 amount) internal {
        if (pid >= maxPid) {
            return;
        }
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];
        uint256 reward;
        reward = amount.mul(pool.realTokenPerShare).div(1e12).div(tokenParentPrecision);
        user.rewardDebt = reward;
    }

    function transferPendingRewards(uint256 pid, address to, uint256 amount) internal returns (uint256) {
        if (pid >= maxPid) {
            return 0;
        }
        if (amount == 0) {
            return 0;
        }
        uint256 tokenAmount = token.balanceOf(address(parent));

        // if reward token is the same as deposit token deduct its balane from withdrawable amount
        if (tokenAmount != 0 && address(token) == address(parent.token())) {
            for (uint i=0; i<maxPid && tokenAmount > 0; i++) {
                uint256 tokenRealStaked = getParentPoolInfo(i).tokenRealStaked;
                tokenAmount = (tokenRealStaked >= tokenAmount) ? 0 : tokenAmount.sub(tokenRealStaked);
            }
        }
        if (tokenAmount == 0) {
            return 0;
        }
        if (tokenAmount > amount) {
            tokenAmount = amount;
        }
        token.safeTransferFrom(address(parent), to, tokenAmount);
        return tokenAmount;
    }

    function getLastRewardBlock() internal view returns (uint256) {
        if (startBlock == 0) return 0;
        if (closeBlock != 0 && closeBlock < block.number) return closeBlock;
        return block.number;
    }

    function getParentUserInfo(uint256 pid, address addr) internal view returns (SuperUserInfo memory) {
        ( uint256 amount, uint256 rewardDebt, uint256 pending, uint256 lockedTimestamp, uint256 lockupTimestamp,
        uint256 lockupTimerange, uint256 virtAmount ) = parent.userInfo(pid, addr);
        return SuperUserInfo({
            amount: amount, rewardDebt: rewardDebt, pendingRewards: pending, lockedTimestamp: lockedTimestamp,
            lockupTimestamp: lockupTimestamp, lockupTimerange: lockupTimerange, virtAmount: virtAmount
        });
    }

    function getParentPoolInfo(uint256 pid) internal view returns (SuperPoolInfo memory) {
        ( uint256 lastBlock, uint256 tokenPerShare, uint256 tokenRealStaked, uint256 tokenVirtStaked,
        uint256 tokenRewarded, uint256 tokenTotalLimit, uint256 lockupMaxTimerange, uint256 lockupMinTimerange ) = parent.poolInfo(pid);
        return SuperPoolInfo({
            lastBlock: lastBlock, tokenPerShare: tokenPerShare, tokenRealStaked: tokenRealStaked,
            tokenVirtStaked: tokenVirtStaked, tokenRewarded: tokenRewarded, tokenTotalLimit: tokenTotalLimit,
            lockupMaxTimerange: lockupMaxTimerange, lockupMinTimerange: lockupMinTimerange
        });
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './StakingV2Vendor.sol';
import './IStakingV2.sol';

/**
 * @title Token Staking
 * @dev BEP20 compatible token.
 */
interface IStakingV2Factory {

    function createVendor(address _parent, IERC20 _token) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

abstract contract IStakingV2 {

    function userInfo(uint256 pid, address addr)
    public virtual view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    function poolInfo(uint256 pid)
    public virtual view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    function maxPid() public virtual view returns (uint256);

    function token() public virtual view returns (address);

    function tokenPerBlock() public virtual view returns (uint256);

    function pendingRewards(uint256 pid, address addr, address asset) external virtual view returns (uint256);

    function deposit(uint256 pid, address addr, uint256 amount, uint256 timerange) external virtual;

    function restake(uint256 pid, address addr, uint256 amount, uint256 timerange) external virtual;

    function withdraw(uint256 pid, address addr, uint256 amount) external virtual;

    function claim(uint256 pid) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}