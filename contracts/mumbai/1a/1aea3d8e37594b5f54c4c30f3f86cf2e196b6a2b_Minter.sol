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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import "@openzeppelin/access/Ownable.sol";

import "../interfaces/IVoter.sol";
import "../interfaces/IDistributor.sol";
import "../interfaces/IKZA.sol";
import "../interfaces/IPool.sol";



// Minter mints tokens into emission according to schedule
// initial epoch has a weekly emission of 463_345
// each epoch has a reduction rate of 0.5%
// the final epoch 208 would have a rate of ~164,165
// the emission is distributed to DToken holder through BaseRewardPool.
// the emission ratio across each BaseRewardPool is decided by the voter

// governance owns this contract
contract Minter is Ownable {
    uint internal constant WEEK = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint internal constant PRECISION = 10000;
    IKZA public immutable KZA;
    // the only dependency to distribute reward tokens is referencing voter
    IVoter public voter;

    uint public decay = 50; // 0.5% weekly decay
    uint public emission = 463_345 * 1e18;
    uint public epoch;

    //mapping(address => address) public underlyingToDistributor;
    address public distributor;
    IPool public immutable pool;

    mapping(address => uint256) public rewardsCache;

    event NewVoter(address _newVoter);
    event NewDecay(uint256 _newDecay);
    event NewDistributor(address _newDistributor);

    constructor(
        address _pool,
        address _KZA,
        address _governance
    ) {
        pool = IPool(_pool);
        KZA = IKZA(_KZA);
        epoch = block.timestamp / WEEK;
        transferOwnership(_governance);
    }

    // gov can update voter 
    function updateVoter(address _newVoter) external onlyOwner {
        voter = IVoter(_newVoter);
        emit NewVoter(_newVoter);
    }

    // gov can update voter 
    function updateDecay(uint256 _newDecay) external onlyOwner {
        require(_newDecay <= PRECISION, "decay exceeds maximum");
        decay = _newDecay;
        emit NewDecay(_newDecay);
    }

    function updateDistributor(address _newDistributor) external onlyOwner {
        distributor = _newDistributor;
        emit NewDistributor(_newDistributor);
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint lastEpoch) {
        lastEpoch = epoch;
        uint current = block.timestamp / WEEK;
        require(address(voter) != address(0), "voter needs to be set");
        require(current > lastEpoch, "only trigger each new week"); 
        epoch = current;
        KZA.mint(address(this), emission);
        uint256 prevEmission = emission;
        emission = (emission * (PRECISION - decay)) / PRECISION;
        // get the scheduled total
        address[] memory reserves = getReserves();
        uint256 length = reserves.length;
        if (length != 0) {
            address market;
            uint256 reward;
            uint256 totalWeight = voter.totalWeight();
            if (totalWeight != 0) {
                for (uint i; i < length;) {
                market = reserves[i];
                uint256 vote = voter.weights(market);
                reward = prevEmission * vote / totalWeight;
                rewardsCache[market] += reward;
                unchecked {
                    ++i;
                    }  
                }
            }
        }
    }

    function notifyRewards() external {
        address[] memory reserves = getReserves();
        uint256 length = reserves.length;
        require(length != 0);
        address market;
        uint256 amount;
        for (uint i; i < length;) {
            market = reserves[i];
            amount = rewardsCache[market];
            if (amount != 0) {
                rewardsCache[market] = 0;
                KZA.increaseAllowance(distributor, amount);
                // notifyReward would call safetTransferFrom
                IDistributor(distributor).notifyReward(market, amount);
            }
            unchecked {
                 ++i;
            }
        }
    }

    function notifyReward(address _market) external {
        require(distributor != address(0));
        uint256 amount = rewardsCache[_market];
        if(amount != 0) {
            rewardsCache[_market] = 0;
            KZA.increaseAllowance(distributor, amount);
            // notifyReward would call safetTransferFrom
            IDistributor(distributor).notifyReward(_market, amount);
        }
    }

    function getReserves() public view returns(address[] memory) {
        return IPool(pool).getReservesList();

    }
}

interface IDistributor {
    function notifyReward(address market, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;
interface IEACAggregatorProxy {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

import "@openzeppelin/token/ERC20/IERC20.sol";

interface IKZA is IERC20 {
  function KZA() external view returns(address);
  function burn(uint256 amount) external;
  function mint(address to, uint256 amount) external;
  function increaseAllowance(address spender, uint256 amount) external;
  function balanceOf(address _user) view external returns(uint256);
  function getUserRedeemsLength(address _user) view external returns(uint256);
  function getUserRedeem(address _user, uint256 _index) view external returns (uint256 amount, uint256 xAmount, uint256 endTime);
  function convertTo(uint256 amount, address to) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

import '../libraries/DataTypes.sol';

interface IPool {
  
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);


  function getReservesList() external view returns (address[] memory);
}

pragma solidity 0.8.17;
interface ITransferStrategyBase {
    function performTransfer(address to, address reward, uint256 amount) external returns(bool);
}

interface IVoter {
    function weights(address market) external returns(uint256);
    function totalWeight() external returns(uint256);
    function reVote(address user) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

import {ITransferStrategyBase} from '../interfaces/ITransferStrategyBase.sol';
import {IEACAggregatorProxy} from '../interfaces/IEACAggregatorProxy.sol';

library DataTypes {

  struct RewardsConfigInput {
    uint88 emissionPerSecond;
    uint256 totalSupply;
    uint32 distributionEnd;
    address asset;
    address reward;
    ITransferStrategyBase transferStrategy;
    IEACAggregatorProxy rewardOracle;
    }

  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint256 data;
  }

  struct UserAssetBalance {
    address asset;
    uint256 userBalance;
    uint256 totalSupply;
  }
  
  struct UserData {
    // Liquidity index of the reward distribution for the user
    uint104 index;
    // Amount of accrued rewards for the user since last user index update
    uint128 accrued;
  }

  struct RewardData {
    // Liquidity index of the reward distribution
    uint104 index;
    // Amount of reward tokens distributed per second
    uint88 emissionPerSecond;
    // Timestamp of the last reward index update
    uint32 lastUpdateTimestamp;
    // The end of the distribution of rewards (in seconds)
    uint32 distributionEnd;
    // Map of user addresses and their rewards data (userAddress => userData)
    mapping(address => UserData) usersData;
  }

  struct AssetData {
    // Map of reward token addresses and their data (rewardTokenAddress => rewardData)
    mapping(address => RewardData) rewards;
    // List of reward token addresses for the asset
    mapping(uint128 => address) availableRewards;
    // Count of reward tokens for the asset
    uint128 availableRewardsCount;
    // Number of decimals of the asset
    uint8 decimals;
  }
}