/**
 *Submitted for verification at polygonscan.com on 2022-02-15
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File contracts/_mock/MockERC20.sol

//pragma solidity 0.8.0;

// Only for testing purposes!!!
contract MockERC20 {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public constant decimals = 18;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory name_, string memory symbol_) public {
        name = name_;
        symbol = symbol_;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value, 'ERC20: NOT enough tokens');
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success) {
        require(_value <= balanceOf[_from], 'ERC20: NOT enough tokens');
        require(_value <= allowance[_from][msg.sender], 'ERC20: NOT enough allowance tokens');
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(address account, uint256 amount) external {
        require(account != address(0), 'ERC20: mint to the zero address');
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}


// File contracts/_mock/MockTokens.sol

//pragma solidity 0.8.0;
contract MockUSDC is MockERC20 {
    constructor() public MockERC20('MockUSDC', 'MUSDC') {}
}

contract MockToken is MockERC20 {
    constructor() public MockERC20('MockToken', 'MTOKEN') {}
}


// File contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

//pragma solidity ^0.8.0;

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


// File contracts/libs/Ownable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)
//pragma solidity 0.8.0;

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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
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


// File contracts/interfaces/IERC20.sol

//pragma solidity 0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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


// File contracts/libs/SafeERC20.sol

//pragma solidity 0.8.0;
library SafeERC20 {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20::safeTransfer: transfer failed');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'SafeERC20::transferFrom: transferFrom failed'
        );
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20::safeApprove: approve failed');
    }
}


// File contracts/libs/Lockable.sol

//pragma solidity 0.8.0;

abstract contract Lockable {
    bool private unlocked = true;

    modifier withLock() {
        require(unlocked, 'Call locked');
        unlocked = false;
        _;
        unlocked = true;
    }
}


// File contracts/Staking.sol

//pragma solidity ^0.8.0;
contract Staking is Ownable, Lockable {
    struct Stake {
        address creator;
        IERC20 rewardToken;
        IERC20 stackingToken;
        uint256 id;
        uint256 startsAt;
        uint256 lastRewardedBlock;
        uint256 lpLockTime;
        uint256 numberOfStakers;
        uint256 lpTotalAmount;
        uint256 lpTotalLimit;
        uint256 stakersLimit;
        uint256 maxStakePerStaker;
        uint256 rewardsValue;
        uint256 rewardsPerBlock;
        uint256 rewardPerTokenStored;
        uint256 lastUpdateBlock;
        uint256 durationInBlocks;
        bool isActive;
    }

    struct Staker {
        address stakerAddress;
        uint256 balance;
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
        uint256 startBlock;
        uint256 startTime;
    }

    Stake[] private _stakes;
    mapping(uint256 => mapping(address => Staker)) private _stakers;

    uint256 public stakesCount = 0;

    event StakeCreated(uint256 stakeId);

    modifier updateReward(uint256 stakeId, address stakerAddress) {
        Stake storage stake = _stakes[stakeId];
        Staker storage staker = _stakers[stakeId][stakerAddress];

        stake.rewardPerTokenStored = rewardPerToken(stake);
        stake.lastUpdateBlock = block.number;

        staker.rewards = earned(stake.id, stakerAddress);
        staker.userRewardPerTokenPaid = stake.rewardPerTokenStored;
        _;
    }

    constructor() {}

    receive() external payable {}

    function createStake(
        IERC20 rewardToken,
        IERC20 stackingToken,
        uint256 startsAt,
        uint256 durationInBlocks,
        uint256 lpLockTime,
        uint256 stakersLimit,
        uint256 maxStakePerStaker,
        uint256 lpTotalLimit,
        uint256 rewardsPerBlock
    ) external payable onlyOwner {
        _stakes.push(
            Stake({
                creator: _msgSender(),
                rewardToken: rewardToken,
                stackingToken: stackingToken,
                id: stakesCount,
                startsAt: startsAt,
                lastRewardedBlock: block.number + durationInBlocks,
                lpLockTime: lpLockTime,
                numberOfStakers: 0,
                lpTotalAmount: 0,
                lpTotalLimit: lpTotalLimit,
                stakersLimit: stakersLimit,
                maxStakePerStaker: maxStakePerStaker,
                rewardsValue: 0,
                rewardsPerBlock: rewardsPerBlock,
                rewardPerTokenStored: 0,
                lastUpdateBlock: 0,
                durationInBlocks: durationInBlocks,
                isActive: true
            })
        );
        uint256 stakeId = stakesCount;
        stakesCount += 1;

        emit StakeCreated(stakeId);
    }

    /**
     * Dev: owner or Creater can deposit Rewards tokens.
     **/
    function depositRewards(uint256 stakeId, uint256 amount) external onlyOwner {
        Stake storage stake = _stakes[stakeId];
        stake.rewardsValue += amount;
        stake.rewardToken.transferFrom(_msgSender(), address(this), amount);
    }

    /**
     * Dev: owner or Creater can withdrawal Rewards tokens.
     **/
    function withdrawalRewards(uint256 stakeId, uint256 amount) external onlyOwner {
        Stake storage stake = _stakes[stakeId];
        stake.rewardsValue -= amount;
        stake.rewardToken.transfer(_msgSender(), amount);
    }

    function stakeTokens(uint256 stakeId, uint256 amount) external withLock updateReward(stakeId, msg.sender) {
        Staker storage staker = _stakers[stakeId][_msgSender()];
        _stake(_stakes[stakeId], staker, amount);
    }

    /*
    withdraw only reward
  */
    function harvest(uint256 stakeId) external withLock updateReward(stakeId, msg.sender) {
        _withdrawHarvest(_stakes[stakeId], _stakers[stakeId][_msgSender()]);
    }

    /*
    withdraw both lp tokens and reward
  */
    function withdraw(uint256 stakeId) external withLock updateReward(stakeId, msg.sender) {
        Stake storage stake = _stakes[stakeId];
        Staker storage staker = _stakers[stakeId][_msgSender()];

        _withdrawHarvest(stake, staker);
        _withdrawLP(stake, staker);
    }

    function emergencyWithdrawal(
        address stakerAddress,
        uint256 stakeId,
        bool payHarvest
    ) external onlyOwner withLock updateReward(stakeId, stakerAddress) {
        Stake storage stake = _stakes[stakeId];
        Staker storage staker = _stakers[stakeId][stakerAddress];
        if (payHarvest) {
            _withdrawHarvest(stake, staker);
        }
        _withdrawLP(stake, staker);
    }

    function _stake(
        Stake storage stake,
        Staker storage staker,
        uint256 amount
    ) internal {
        require(amount > 0, 'Staking: Amount must be greater than zero');
        require(stake.isActive, 'Staking: This stake is inactive or not existt');
        require(block.timestamp >= stake.startsAt, 'Staking: This staking has not started yet');
        require(block.number <= stake.lastRewardedBlock, 'Staking: This staking is currently closed');

        uint256 stakersLimit = stake.stakersLimit;
        uint256 maxStakePerStaker = stake.maxStakePerStaker;
        uint256 lpTotalLimit = stake.lpTotalLimit;

        if (stakersLimit != 0) {
            require(stake.numberOfStakers <= stakersLimit, 'Staking: This stake is already full');
        }

        if (lpTotalLimit != 0) {
            require(stake.lpTotalAmount + amount <= lpTotalLimit, 'Staking: This stake is already full');
        }

        if (maxStakePerStaker != 0) {
            require(staker.balance + amount <= maxStakePerStaker, 'Staking: Your total stake size is too big');
        }

        stake.lpTotalAmount += amount;
        staker.balance += amount;

        stake.stackingToken.transferFrom(_msgSender(), address(this), amount);

        if (staker.startBlock == 0) {
            stake.numberOfStakers += 1;
            staker.startBlock = block.number;
            staker.startTime = block.timestamp;
            staker.stakerAddress = _msgSender();
        }
    }

    function _withdrawLP(Stake storage stake, Staker storage staker) internal {
        uint256 amount = staker.balance;

        require(amount > 0, 'Balance must be greater than zero');
        if (_msgSender() != owner()) {
            require(block.timestamp >= staker.startTime + stake.lpLockTime, 'Staking: Too early for withdraw');
        }

        stake.lpTotalAmount -= amount;
        stake.numberOfStakers -= 1;

        staker.startBlock = 0;
        staker.startTime = 0;
        staker.balance = 0;
        stake.stackingToken.transfer(staker.stakerAddress, amount);
    }

    function _withdrawHarvest(Stake storage stake, Staker storage staker) internal {
        require(staker.startBlock != 0, 'Staking: You are not a staker');
        uint256 reward = staker.rewards;

        require(stake.rewardsValue >= reward, 'Staking: Not enough tokens');
        if (reward > 0) {
            staker.rewards = 0;
            stake.rewardsValue = stake.rewardsValue - reward;
            staker.startBlock = block.number;
            stake.rewardToken.transfer(staker.stakerAddress, reward);
        }
    }

    function earned(uint256 stakeId, address stakerAddress) public view returns (uint256) {
        Stake memory stake = _stakes[stakeId];
        Staker memory staker = _stakers[stakeId][stakerAddress];
        uint256 rewardPerBlockNow = rewardPerToken(stake);
        return
            rewardPerBlockNow != 0
                ? ((staker.balance * (rewardPerBlockNow - staker.userRewardPerTokenPaid)) / 1 ether) + staker.rewards
                : 0;
    }

    function rewardPerToken(Stake memory stake) internal view returns (uint256) {
        uint256 lpTotalAmount = stake.lpTotalAmount;
        uint256 lastUpdateBlock = stake.lastUpdateBlock;
        uint256 lastRewardedBlock = stake.lastRewardedBlock;
        if (lpTotalAmount == 0 || lastUpdateBlock > stake.lastRewardedBlock) {
            return 0;
        }
        uint256 lastBlock = block.number;
        if (block.number > lastRewardedBlock) {
            lastBlock = lastRewardedBlock;
        }
        uint256 rewardedBlocks;
        if (lastUpdateBlock < lastBlock) {
            rewardedBlocks = lastBlock - lastUpdateBlock;
        }
        return (stake.rewardPerTokenStored + ((stake.rewardsPerBlock * rewardedBlocks * 1 ether) / lpTotalAmount));
    }

    function me(uint256 stakeId, address userAddress) external view returns (Staker memory) {
        return _stakers[stakeId][userAddress];
    }

    function updateStake(
        uint256 stakeId,
        uint256 startsAt,
        uint256 blocksDuration,
        uint256 lpLockTime,
        uint256 stakersLimit,
        uint256 maxStakePerStaker,
        uint256 newRewardPerBlock
    ) external onlyOwner {
        Stake storage stake = _stakes[stakeId];
        if (block.timestamp < stake.startsAt) {
            stake.lpLockTime = lpLockTime;
            stake.startsAt = startsAt;
        }

        stake.lastRewardedBlock = block.number + blocksDuration;
        stake.durationInBlocks = blocksDuration;
        stake.stakersLimit = stakersLimit;
        stake.maxStakePerStaker = maxStakePerStaker;
        stake.rewardsPerBlock = newRewardPerBlock;
    }

    function setActive(uint256 stakeId, bool value) external onlyOwner {
        _stakes[stakeId].isActive = value;
    }

    function setRewardPerBlock(uint256 stakeId, uint256 _newRewardPerBlock) public onlyOwner {
        Stake storage stake = _stakes[stakeId];
        stake.rewardsPerBlock = _newRewardPerBlock;
    }

    function stakes(uint256 start, uint256 size) external view returns (Stake[] memory) {
        Stake[] memory arrStakes = new Stake[](stakesCount);

        uint256 end = start + size > stakesCount ? stakesCount : start + size;

        for (uint256 i = start; i < end; i++) {
            Stake storage stake = _stakes[i];
            arrStakes[i] = stake;
        }

        return arrStakes;
    }
}


// File contracts/interfaces/IPancakeFactory.sol

//pragma solidity 0.8.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


// File contracts/interfaces/IPancakePair.sol

//pragma solidity 0.8.0;

interface IPancakePair {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}


// File contracts/interfaces/IPancakeRouter.sol

//pragma solidity 0.8.0;

interface IPancakeRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}