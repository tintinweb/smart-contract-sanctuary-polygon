/**
 *Submitted for verification at polygonscan.com on 2022-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract StakingContract is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct PoolIdentifier {
        IERC20 stakeToken;
        IERC20 rewardToken;
        uint256 poolIndex;
    }

    struct UserInfo {
        uint256 amount;                         // How many LP tokens the user has provided.
        uint256 subtractableReward;             // Reward debt. See explanation below.
        uint256 depositStamp;
    }

    struct BasicPoolInfo {
        bool doesExists;
        bool hasEnded;
        IERC20 stakeToken;
        IERC20 rewardToken;
        uint256 createBlock;                    // Block number when the pool was created
        uint256 startBlock;                     // Block number when reward distribution start
        uint256 rewardPerBlock;
        uint256 gasAmount;                      // Eth fee charged on deposits and withdrawals
        uint256 minStake;                       // Min. tokens that need to be staked
        uint256 maxStake;                       // Max. tokens that can be staked
        uint256 stakeTokenDepositFee;           // Fee (divide by 1000, so that 100 => 0.1%)
        uint256 stakeTokenWithdrawFee;          // Fee (divide by 1000, so that 100 => 0.1%)
        uint256 lockPeriod;                     // No. of blocks for which the stake tokens are locked
    }

    struct DetailedPoolInfo {
        uint256 tokensStaked;                   // Total tokens staked with the pool
        uint256 accRewardPerTokenStaked;        // (Accumulated reward per token staked) * (1e36).
        uint256 paidOut;                        // Total rewards distributed by pool
        uint256 lastRewardBlock;                // Last block number when the accRewardPerTokenStaked was updated
        uint256 endBlock;                       // Block number when reward distribution ends
        uint256 maxStakers;
        uint256 totalStakers;
        mapping(address => UserInfo) userInfo;  // Info of each user that stakes with the pool
    }

    IERC20 public accessToken = IERC20(address(0));
    uint256 public minAccessTokenRequired = 0;
    bool public requireAccessToken = false;

    uint256 public gasAmount = 0.005 ether;
    address payable public treasury;
    mapping(IERC20 => uint256) public withdrawableFee;

    uint256 public currentPoolToBeUpdated = 0;
    uint256 public maxNumOfPoolsToBeUpdated = 50;
    uint256 public staleBlockDuration = 1000;
    PoolIdentifier[] public activePools;
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => uint256))) public indicesOfActivePools;

    // Stake Token => (Reward Token => (Pool Id => BasicPoolInfo))
    mapping(IERC20 => mapping(IERC20 => uint256)) public latestPoolNumber;
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => BasicPoolInfo))) public allPoolsBasicInfo;
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => DetailedPoolInfo))) public allPoolsDetailedInfo;

    event Deposit(address indexed user, IERC20 indexed stakeToken, IERC20 indexed rewardToken, uint256 poolIndex, uint256 amount);
    event Withdraw(address indexed user, IERC20 indexed stakeToken, IERC20 indexed rewardToken, uint256 poolIndex, uint256 amount);
    event EmergencyWithdraw(address indexed user, IERC20 indexed stakeToken, IERC20 indexed rewardToken, uint256 poolIndex, uint256 amount);

    constructor() {
        treasury = payable(msg.sender);

        activePools.push(PoolIdentifier({
        stakeToken : IERC20(address(0)),
        rewardToken : IERC20(address(0)),
        poolIndex : 0
        }));
    }

    function currentBlock() external view returns (uint256) {
        return block.number;
    }

    function getActivePoolCount() external view returns (uint256) {
        return activePools.length;
    }

    // View function to see LP amount staked by a user.
    function getUserStakedAmount(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex, address _user) external view returns (uint256) {
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        return detailedPoolInfo.userInfo[_user].amount;
    }

    // View function to see pending rewards of a user.
    function getPendingRewardsOfUser(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex, address _user) public view returns (uint256) {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        UserInfo storage user = detailedPoolInfo.userInfo[_user];

        uint256 accRewardPerTokenStaked = detailedPoolInfo.accRewardPerTokenStaked;
        uint256 tokensStaked = detailedPoolInfo.tokensStaked;

        if (block.number > detailedPoolInfo.lastRewardBlock && tokensStaked != 0) {
            uint256 lastBlock = (block.number < detailedPoolInfo.endBlock) ? block.number : detailedPoolInfo.endBlock;
            uint256 noOfBlocks = lastBlock.sub(detailedPoolInfo.lastRewardBlock);
            uint256 newRewards = noOfBlocks.mul(basicPoolInfo.rewardPerBlock);
            accRewardPerTokenStaked = accRewardPerTokenStaked.add(newRewards.mul(1e36).div(tokensStaked));
        }

        return user.amount.mul(accRewardPerTokenStaked).div(1e36).sub(user.subtractableReward);
    }

    // View function for total reward the farm has yet to pay out.
    function getTotalPendingRewardsOfPool(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex) external view returns (uint256) {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        if (block.number <= basicPoolInfo.startBlock) {
            return 0;
        }

        uint256 elapsedBlockCount = (block.number < detailedPoolInfo.endBlock) ? block.number : detailedPoolInfo.endBlock;
        elapsedBlockCount = elapsedBlockCount.sub(basicPoolInfo.startBlock);

        return (basicPoolInfo.rewardPerBlock.mul(elapsedBlockCount)).sub(detailedPoolInfo.paidOut);
    }

    function getRewardPerBlockOfPool(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex) external view returns (uint) {
        return allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex].rewardPerBlock;
    }

    function finishActivePool(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex) internal {
        uint256 activePoolIndex = indicesOfActivePools[_stakeToken][_rewardToken][poolIndex];
        if (activePoolIndex <= 0) {
            return;
        }

        uint256 lastPoolIndex = activePools.length - 1;

        PoolIdentifier memory poolIdentifier = activePools[lastPoolIndex];
        activePools[activePoolIndex] = activePools[lastPoolIndex];
        indicesOfActivePools[poolIdentifier.stakeToken][poolIdentifier.rewardToken][poolIdentifier.poolIndex] = activePoolIndex;

        indicesOfActivePools[_stakeToken][_rewardToken][poolIndex] = 0;
        activePools.pop();

        latestPoolNumber[_stakeToken][_rewardToken] += 1;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // rewards are calculated per pool, so you can add the same stakeToken multiple times
    function createNewStakingPool(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _minStake,
        uint256 _maxStake,
        uint256 _lockBlocks,
        uint256 _maxStakers
    ) public onlyOwner {
        massUpdatePoolStatus();

        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        require(!basicPoolInfo.doesExists, "This pool already exists.");
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];

        basicPoolInfo.doesExists = true;
        basicPoolInfo.stakeToken = _stakeToken;
        basicPoolInfo.rewardToken = _rewardToken;
        basicPoolInfo.createBlock = block.number;
        basicPoolInfo.rewardPerBlock = _rewardPerBlock;
        basicPoolInfo.gasAmount = gasAmount;
        basicPoolInfo.minStake = _minStake;
        basicPoolInfo.maxStake = (_maxStake <= 0) ? ~uint256(0) : _maxStake;
        basicPoolInfo.stakeTokenDepositFee = 0;
        basicPoolInfo.stakeTokenWithdrawFee = 20;
        basicPoolInfo.lockPeriod = _lockBlocks;
        detailedPoolInfo.maxStakers = (_maxStakers <= 0) ? ~uint256(0) : _maxStakers;

        indicesOfActivePools[_stakeToken][_rewardToken][poolIndex] = activePools.length;
        activePools.push(PoolIdentifier(_stakeToken, _rewardToken, poolIndex));
    }

    // Fund the pool, consequently setting the end block
    function performInitialFunding(IERC20 _stakeToken, IERC20 _rewardToken, uint256 _amount, uint256 _startBlock) public {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][latestPoolNumber[_stakeToken][_rewardToken]];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][latestPoolNumber[_stakeToken][_rewardToken]];

        require(basicPoolInfo.doesExists, "performInitialFunding: No such pool exists.");
        require(basicPoolInfo.startBlock == 0, "performInitialFunding: Initial funding already complete");

        IERC20 erc20 = basicPoolInfo.rewardToken;

        uint256 startTokenBalance = erc20.balanceOf(address(this));
        erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = erc20.balanceOf(address(this));
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance);

        _startBlock = (_startBlock < block.number) ? block.number : _startBlock;

        detailedPoolInfo.lastRewardBlock = _startBlock;
        basicPoolInfo.startBlock = _startBlock;
        detailedPoolInfo.endBlock = _startBlock.add(trueDepositedTokens.div(basicPoolInfo.rewardPerBlock));
    }

    // Increase the funds the pool, consequently increasing the end block
    function increasePoolFunding(IERC20 _stakeToken, IERC20 _rewardToken, uint256 _amount) public {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][latestPoolNumber[_stakeToken][_rewardToken]];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][latestPoolNumber[_stakeToken][_rewardToken]];

        require(basicPoolInfo.doesExists, "increasePoolFunding: No such pool exists.");
        require(block.number < detailedPoolInfo.endBlock, "increasePoolFunding: Pool closed or perform initial funding first");

        IERC20 erc20 = basicPoolInfo.rewardToken;

        uint256 startTokenBalance = erc20.balanceOf(address(this));
        erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = erc20.balanceOf(address(this));
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance);

        detailedPoolInfo.endBlock += trueDepositedTokens.div(basicPoolInfo.rewardPerBlock);
    }

    // Deposit staking tokens to pool.
    function stakeWithPool(IERC20 _stakeToken, IERC20 _rewardToken, uint256 _amount) external payable {
        massUpdatePoolStatus();

        if (requireAccessToken) {
            require(accessToken.balanceOf(msg.sender) >= minAccessTokenRequired, "Insufficient access token held by staker");
        }

        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][latestPoolNumber[_stakeToken][_rewardToken]];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][latestPoolNumber[_stakeToken][_rewardToken]];
        UserInfo storage user = detailedPoolInfo.userInfo[msg.sender];

        updatePoolStatus(_stakeToken, _rewardToken, latestPoolNumber[_stakeToken][_rewardToken]);

        require(basicPoolInfo.doesExists, "stakeWithPool: No such pool exists.");
        require(!basicPoolInfo.hasEnded, "stakeWithPool: Pool has already ended.");
        require(detailedPoolInfo.totalStakers < detailedPoolInfo.maxStakers, "Max stakers reached!");
        require(msg.value >= basicPoolInfo.gasAmount, "Insufficient Value for the trx.");
        require(_amount >= basicPoolInfo.minStake && (_amount.add(user.amount)) <= basicPoolInfo.maxStake, "Stake amount out of range.");

        if (user.amount > 0) {
            uint256 pendingAmount = getPendingRewardsOfUser(_stakeToken, _rewardToken, latestPoolNumber[_stakeToken][_rewardToken], msg.sender);
            if (pendingAmount > 0) {
                erc20RewardTransfer(msg.sender, _stakeToken, _rewardToken, latestPoolNumber[_stakeToken][_rewardToken], pendingAmount);
            }
        }

        uint256 startTokenBalance = basicPoolInfo.stakeToken.balanceOf(address(this));
        basicPoolInfo.stakeToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 endTokenBalance = basicPoolInfo.stakeToken.balanceOf(address(this));
        uint256 trueDepositedTokens = endTokenBalance.sub(startTokenBalance);
        uint256 depositFee = basicPoolInfo.stakeTokenDepositFee.mul(trueDepositedTokens).div(1000);
        withdrawableFee[_stakeToken] += depositFee;
        trueDepositedTokens = trueDepositedTokens.sub(depositFee);

        user.amount = user.amount.add(trueDepositedTokens);
        user.depositStamp = block.number;
        detailedPoolInfo.tokensStaked = detailedPoolInfo.tokensStaked.add(trueDepositedTokens);
        user.subtractableReward = user.amount.mul(detailedPoolInfo.accRewardPerTokenStaked).div(1e36);

        treasury.transfer(msg.value);

        detailedPoolInfo.totalStakers = detailedPoolInfo.totalStakers.add(1);

        emit Deposit(msg.sender, _stakeToken, _rewardToken, latestPoolNumber[_stakeToken][_rewardToken], _amount);
    }

    // Withdraw staking tokens from pool.
    function unstakeFromPool(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex, uint256 _amount) public payable {
        massUpdatePoolStatus();

        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        UserInfo storage user = detailedPoolInfo.userInfo[msg.sender];

        require(basicPoolInfo.doesExists, "unstakeFromPool: No such pool exists.");
        require(msg.value >= basicPoolInfo.gasAmount, "Correct gas amount must be sent!");
        require(user.amount >= _amount, "unstakeFromPool: Can't withdraw more than deposit");

        updatePoolStatus(_stakeToken, _rewardToken, poolIndex);

        uint256 pendingAmount = getPendingRewardsOfUser(_stakeToken, _rewardToken, poolIndex, msg.sender);
        if (pendingAmount > 0) {
            erc20RewardTransfer(msg.sender, _stakeToken, _rewardToken, poolIndex, pendingAmount);
        }

        if (_amount > 0) {
            require(user.depositStamp.add(basicPoolInfo.lockPeriod) <= block.number, "Lock period not fulfilled");

            uint256 withdrawFee = basicPoolInfo.stakeTokenWithdrawFee.mul(_amount).div(1000);
            withdrawableFee[_stakeToken] = withdrawableFee[_stakeToken].add(withdrawFee);
            
            basicPoolInfo.stakeToken.safeTransfer(address(msg.sender), _amount.sub(withdrawFee));
            detailedPoolInfo.tokensStaked = detailedPoolInfo.tokensStaked.sub(_amount);
            user.amount = user.amount.sub(_amount);
            user.subtractableReward = user.amount.mul(detailedPoolInfo.accRewardPerTokenStaked).div(1e36);

            if (user.amount <= 0) {
                detailedPoolInfo.totalStakers = detailedPoolInfo.totalStakers.sub(1);
            }
        }

        treasury.transfer(msg.value);

        emit Withdraw(msg.sender, _stakeToken, _rewardToken, poolIndex, _amount);
    }

    // Withdraw without caring about rewards and lock period. EMERGENCY ONLY.
    function emergencyWithdraw(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex) public {
        massUpdatePoolStatus();

        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        UserInfo storage user = detailedPoolInfo.userInfo[msg.sender];

        if (user.amount > 0) {
            basicPoolInfo.stakeToken.safeTransfer(address(msg.sender), user.amount);
            detailedPoolInfo.tokensStaked = detailedPoolInfo.tokensStaked.sub(user.amount);
            user.amount = 0;
            user.subtractableReward = 0;
            detailedPoolInfo.totalStakers = detailedPoolInfo.totalStakers.sub(1);

            emit EmergencyWithdraw(msg.sender, _stakeToken, _rewardToken, poolIndex, user.amount);
        }
    }

    // Transfer reward and update the paid out reward
    function erc20RewardTransfer(address _to, IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex, uint256 _amount) internal {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        IERC20 erc20 = basicPoolInfo.rewardToken;

        try erc20.transfer(_to, _amount) {
            detailedPoolInfo.paidOut = detailedPoolInfo.paidOut.add(_amount);
        } catch {}
    }

    uint256 public a;
    uint256 public b;
    uint256 public c;
    uint256 public d;
    uint256 public e;

    // Updates status of the given pool.
    function updatePoolStatus(IERC20 _stakeToken, IERC20 _rewardToken, uint256 poolIndex) public {
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];

        if (basicPoolInfo.doesExists && ((basicPoolInfo.startBlock > 0) || (basicPoolInfo.createBlock < block.number.sub(staleBlockDuration)))) {
            uint256 lastRewardBlock;

            if (block.number < detailedPoolInfo.endBlock) {
                lastRewardBlock = block.number;
            } else {
                lastRewardBlock = detailedPoolInfo.endBlock;
                if (!basicPoolInfo.hasEnded) {
                    basicPoolInfo.hasEnded = true;
                    finishActivePool(_stakeToken, _rewardToken, poolIndex);
                }
            }

            if (lastRewardBlock > detailedPoolInfo.lastRewardBlock) {
                detailedPoolInfo.lastRewardBlock = lastRewardBlock;

                if (detailedPoolInfo.tokensStaked > 0) {
                    uint256 noOfBlocks = lastRewardBlock.sub(detailedPoolInfo.lastRewardBlock);
                    uint256 newRewards = noOfBlocks.mul(basicPoolInfo.rewardPerBlock);

                    a = noOfBlocks;
                    b = newRewards;
                    c = newRewards.mul(1e36);
                    d = detailedPoolInfo.tokensStaked;
                    e = newRewards.mul(1e36).div(detailedPoolInfo.tokensStaked);

                    detailedPoolInfo.accRewardPerTokenStaked = detailedPoolInfo.accRewardPerTokenStaked.add(newRewards.mul(1e36).div(detailedPoolInfo.tokensStaked));
                }
            }
        }
    }

    function massUpdatePoolStatus() public {
        for (uint256 i = 0; i < maxNumOfPoolsToBeUpdated; i++) {
            if (activePools.length < 2) {
                return;
            }
            if (currentPoolToBeUpdated < 1 || currentPoolToBeUpdated >= activePools.length) {
                currentPoolToBeUpdated = 1;
            }

            updatePoolStatus(
                activePools[currentPoolToBeUpdated].stakeToken,
                activePools[currentPoolToBeUpdated].rewardToken,
                activePools[currentPoolToBeUpdated].poolIndex
            );

            currentPoolToBeUpdated += 1;
        }
    }

    // Change no. of users that can stake with in a pool
    function changePoolMaxStakers(IERC20 _stakeToken, IERC20 _rewardToken, uint256 _maxStakers) public onlyOwner {
        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        DetailedPoolInfo storage detailedPoolInfo = allPoolsDetailedInfo[_stakeToken][_rewardToken][poolIndex];
        
        require(basicPoolInfo.doesExists, "No such pool exists.");
        require(basicPoolInfo.doesExists, "No such pool exists.");

        detailedPoolInfo.maxStakers = (_maxStakers < detailedPoolInfo.totalStakers) ? detailedPoolInfo.totalStakers : _maxStakers;
    }

    // Change deposit fee
    function changeDepositFee(IERC20 _stakeToken, IERC20 _rewardToken, uint256 fee) public onlyOwner {
        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];

        require(basicPoolInfo.doesExists, "No such pool exists.");
        require(fee >= 0 && fee <= 1000, "Invalid Fee Value");

        basicPoolInfo.stakeTokenDepositFee = fee;
    }

    // Change withdraw fee
    function changeWithdrawFee(IERC20 _stakeToken, IERC20 _rewardToken, uint256 fee) public onlyOwner {
        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        
        require(basicPoolInfo.doesExists, "No such pool exists.");
        require(fee >= 0 && fee <= 1000, "Invalid Fee Value");

        basicPoolInfo.stakeTokenWithdrawFee = fee;
    }

    // Adjusts Gas Fee
    function adjustGasGlobal(uint256 newGas) public onlyOwner {
        gasAmount = newGas;
    }

    function adjustPoolGas(IERC20 _stakeToken, IERC20 _rewardToken, uint256 newGas) public onlyOwner {
        uint256 poolIndex = latestPoolNumber[_stakeToken][_rewardToken];
        BasicPoolInfo storage basicPoolInfo = allPoolsBasicInfo[_stakeToken][_rewardToken][poolIndex];
        
        require(basicPoolInfo.doesExists, "No such pool exists.");

        basicPoolInfo.gasAmount = newGas;
    }

    // Treasury Management
    function changeTreasury(address payable newTreasury) public onlyOwner {
        treasury = newTreasury;
    }

    function transfer() public onlyOwner {
        treasury.transfer(address(this).balance);
    }

    function withdrawFees(IERC20 withdrawToken, address _to, uint256 _amount) external onlyOwner {
        require(withdrawableFee[withdrawToken] >= _amount, "Withdraw amount exceeds generated fee amount");

        if (_amount > 0) {
            withdrawToken.transfer(_to, _amount);
            withdrawableFee[withdrawToken] = withdrawableFee[withdrawToken].sub(_amount);
        }
    }

    // Handling Access Token
    function setAccessToken(IERC20 _accessToken) public onlyOwner {
        require(address(_accessToken) != address(0), "Access Token cannot be zero address");
        accessToken = _accessToken;
    }

    function setRequireAccessToken(bool required) public onlyOwner {
        if (required) {
            require(address(accessToken) != address(0), "Cannot set to true while access token is zero address");
        }

        requireAccessToken = required;
    }

    function setMinAccessTokenRequired(uint256 _minAccessTokenRequired) public onlyOwner {
        minAccessTokenRequired = _minAccessTokenRequired;
    }

    // Handling mass update
    function changeMaxNumOfPoolsToBeUpdated(uint256 num) external onlyOwner {
        maxNumOfPoolsToBeUpdated = num;
    }

    function changeStaleBlockDuration(uint256 _blockCount) external onlyOwner {
        require(_blockCount > 0, "Block count has to be greater than 0");
        staleBlockDuration = _blockCount;
    }
}