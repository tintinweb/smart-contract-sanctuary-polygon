// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../interfaces/IPool.sol";
import "../../interfaces/IFactory.sol";
import "../../interfaces/IStakingPool.sol";

import "../../utils/DebetBase.sol";

/**
 * @title Pool contract
 * @author Debet
 * @notice Template used to create the token pool in factory contract
 */
contract Pool is IPool, ReentrancyGuard, ERC20, DebetBase {
    using SafeERC20 for IERC20;

    /// @notice The underlying token address
    address public immutable override token;
    /// @notice The factory contract address
    address public immutable override factory;

    /// @notice Counter for the number of requests
    uint256 public override poolId;
    /// @notice Total amount of token in the pool
    uint256 public override totalAmount;
    /// @notice Amount of the current rewards in the pool
    uint256 public override totalRewards;
    /// @notice Number of times the pool receive rewards
    uint256 public override addRewardsCounts;

    PoolInfo internal _poolInfo;
    mapping(uint256 => LockInfo) internal _lockInfo;

    /**
     * @dev Only factory contract can call functions marked by this modifier.
     **/
    modifier onlyFactory() {
        require(msg.sender == factory, "forbidden");
        _;
    }

    /**
     * @dev Only valid caller in factory can call functions marked by this modifier.
     **/
    modifier onlyValidCaller() {
        require(IFactory(factory).isValidCaller(msg.sender), "invalid caller");
        _;
    }

    /**
     * @dev Constructor.
     * @param _token The address of the underlying token
     */
    constructor(address _token)
        ERC20(
            string.concat("Debet ", IERC20Metadata(_token).name(), " Pool"),
            string.concat("DBP-", IERC20Metadata(_token).symbol())
        )
    {
        factory = msg.sender;
        token = _token;
    }

    /**
     * @notice Add liquidity to this pool
     * @dev only the factory contract can call this function
     * @dev Emit the Mint event
     * @param banker The address of the user who added liquidity
     * @return receivedAmount The amount of token actual received by the pool
     * @return share The amount of the pool share that mint to user
     */
    function mint(address banker)
        external
        override
        onlyFactory
        nonReentrant
        returns (uint256 receivedAmount, uint256 share)
    {
        PoolInfo memory tempPoolInfo = _poolInfo;
        receivedAmount = _receive();
        require(receivedAmount > 0, "need none-zero amount");

        uint256 totalPoolAmount = tempPoolInfo.freeAmount +
            tempPoolInfo.frozenAmount;
        if (totalPoolAmount == 0) {
            share = receivedAmount;
        } else {
            share = (receivedAmount * totalSupply()) / totalPoolAmount;
        }

        tempPoolInfo.freeAmount += receivedAmount;
        _poolInfo = tempPoolInfo;

        _mint(banker, share);

        emit Mint(banker, receivedAmount, share);
    }

    /**
     * @notice remove liquidity from this pool
     * @dev only the factory contract can call this function
     * @dev Emit the Burn event
     * @param banker The address of the user who removed liquidity
     * @param share The amount of pool share to burn
     * @param receiver The address of user that receive the return token
     * @return withdrawAmount The amount of token to return
     */
    function burn(
        address banker,
        uint256 share,
        address receiver
    )
        external
        override
        onlyFactory
        nonReentrant
        returns (uint256 withdrawAmount)
    {
        require(share > 0, "need non-zero share amount");

        uint256 totalShare = totalSupply();
        _burn(banker, share);

        PoolInfo memory tempPoolInfo = _poolInfo;
        uint256 totalPoolAmount = tempPoolInfo.freeAmount +
            tempPoolInfo.frozenAmount;

        withdrawAmount = (totalPoolAmount * share) / totalShare;
        require(
            withdrawAmount <= tempPoolInfo.freeAmount,
            "insufficient free amount to withdraw"
        );

        tempPoolInfo.freeAmount -= withdrawAmount;
        _poolInfo = tempPoolInfo;

        _sendout(receiver, withdrawAmount);

        emit Burn(banker, withdrawAmount, share);
    }

    /**
     * @notice Receive the bet amount of user and lock the payout amountof pool
     * @dev Only invalid game contract can call this function
     * @dev Emit the ReceiveAndLock event
     * @param player The address of the player
     * @param referrer The address of the referrer who recommends the user to play
     * @param betAmountInfo The information of bet
     * @return gameId The id of the request in this pool
     */
    function receiveAndLock(
        address player,
        address referrer,
        BetAmountInfo memory betAmountInfo
    ) external override onlyValidCaller nonReentrant returns (uint256 gameId) {
        uint256 actualReceiveAmount = _receive();
        require(actualReceiveAmount > 0, "need none-zero receive amount");

        if (actualReceiveAmount < betAmountInfo.totalBetAmount) {
            betAmountInfo.actualBetAmount =
                (betAmountInfo.actualBetAmount * actualReceiveAmount) /
                betAmountInfo.totalBetAmount;
            betAmountInfo.referralFee =
                actualReceiveAmount -
                betAmountInfo.actualBetAmount;
            betAmountInfo.frozenPoolAmount =
                (betAmountInfo.frozenPoolAmount * actualReceiveAmount) /
                betAmountInfo.totalBetAmount;
        }

        gameId = ++poolId;
        _lockInfo[gameId] = LockInfo(
            gameId,
            player,
            referrer,
            betAmountInfo.actualBetAmount,
            betAmountInfo.referralFee,
            0,
            betAmountInfo.frozenPoolAmount,
            false,
            GameResult.LOSE
        );

        _lock(betAmountInfo.frozenPoolAmount);

        emit ReceiveAndLock(
            player,
            gameId,
            actualReceiveAmount,
            betAmountInfo.frozenPoolAmount
        );
    }

    /**
     * @notice Release the lock amount of pool and send the prize out if player win
     * @dev Only invalid game contract can call this function
     * @dev Emit the ReleaseAndSend event
     * @param gameId The id of the sepecified request in this pool
     * @param result The result of this game (0 for lose, 1 for success, 2 for cancel)
     * @param receiver The address of user that receive the prize if the game winner is player
     * @return totalPrize The amount of the prize to return
     */
    function releaseAndSend(
        uint256 gameId,
        GameResult result,
        address receiver
    )
        external
        override
        onlyValidCaller
        nonReentrant
        returns (uint256 totalPrize)
    {
        require(gameId > 0 && gameId <= poolId, "invalid game id");

        LockInfo memory tempLockinfo = _lockInfo[gameId];
        require(!tempLockinfo.handled, "the game has been handled already");

        PoolInfo memory tempPoolInfo = _poolInfo;

        tempPoolInfo.frozenAmount -= tempLockinfo.frozenPoolAmount;

        uint256 rewardsFee;
        uint256 referralFee;
        if (result == GameResult.LOSE) {
            tempPoolInfo.freeAmount =
                tempPoolInfo.freeAmount +
                tempLockinfo.frozenPoolAmount +
                tempLockinfo.betAmount;
            (referralFee, rewardsFee) = _sendReferralFee(
                tempLockinfo.referrer,
                tempLockinfo.referralFee
            );
        } else if (result == GameResult.WIN) {
            totalPrize = tempLockinfo.betAmount + tempLockinfo.frozenPoolAmount;
            _sendout(receiver, totalPrize);
            (referralFee, rewardsFee) = _sendReferralFee(
                tempLockinfo.referrer,
                tempLockinfo.referralFee
            );
        } else {
            tempPoolInfo.freeAmount =
                tempPoolInfo.freeAmount +
                tempLockinfo.frozenPoolAmount;
            totalPrize = tempLockinfo.betAmount + tempLockinfo.referralFee;
            _sendout(receiver, totalPrize);
        }

        _poolInfo = tempPoolInfo;

        if (rewardsFee > 0) {
            tempLockinfo.rewardsFee = rewardsFee;
            tempLockinfo.referralFee -= rewardsFee;
        }
        tempLockinfo.handled = true;
        tempLockinfo.result = result;
        _lockInfo[gameId] = tempLockinfo;

        emit ReleaseAndSend(gameId, result);
    }

    /**
     * @notice Get the information of this pool
     * @return The information of this pool
     */
    function poolInfo() external view override returns (PoolInfo memory) {
        return _poolInfo;
    }

    /**
     * @notice Get the lock information of a sepecified request
     * @param gameId The id of the sepecified request in this pool
     */
    function lockInfo(uint256 gameId)
        external
        view
        override
        returns (LockInfo memory)
    {
        return _lockInfo[gameId];
    }

    // ============================= helper functions =============================== //

    function _lock(uint256 amount) internal onlyValidCaller {
        PoolInfo memory tempPoolInfo = _poolInfo;

        uint256 maxPrize = (tempPoolInfo.freeAmount *
            IFactory(factory).maxPrizeRate()) / RATE_DENOMINATOR;
        require(amount <= maxPrize, "the prize amount exceeds the limit");

        tempPoolInfo.freeAmount -= amount;
        tempPoolInfo.frozenAmount += amount;
        _poolInfo = tempPoolInfo;
    }

    function _sendReferralFee(address referrer, uint256 referralFee)
        internal
        returns (uint256, uint256)
    {
        uint256 rewardsFee = referralFee;

        if (referrer != address(0)) {
            rewardsFee =
                (referralFee * IFactory(factory).protocolInReferralFee()) /
                RATE_DENOMINATOR;

            referralFee -= rewardsFee;
            _sendout(referrer, referralFee);
        }

        if (rewardsFee > 0) {
            totalRewards += rewardsFee;
            addRewardsCounts += 1;
            if (
                IFactory(factory).rewardsPool() != address(0) &&
                addRewardsCounts >= IFactory(factory).countsToAddRewards(token)
            ) {
                _sendToRewardsPool();
                addRewardsCounts = 0;
            }
        }

        return (referralFee, rewardsFee);
    }

    function _sendToRewardsPool() internal {
        address rewardsPool = IFactory(factory).rewardsPool();
        uint256 currentRewards = totalRewards;

        if (
            IERC20(token).allowance(address(this), rewardsPool) < currentRewards
        ) {
            IERC20(token).safeApprove(rewardsPool, 0);
            IERC20(token).safeApprove(rewardsPool, type(uint256).max);
        }

        IStakingPool(IFactory(factory).rewardsPool()).addRewards(
            token,
            currentRewards
        );

        totalRewards = 0;
    }

    function _receive() internal returns (uint256 received) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        received = balance - totalAmount;
        totalAmount = balance;
    }

    function _sendout(address to, uint256 amount) internal {
        IERC20(token).safeTransfer(to, amount);
        totalAmount -= amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface PoolType {
    enum GameResult {
        LOSE,
        WIN,
        CANCEL
    }

    struct PoolInfo {
        uint256 freeAmount;
        uint256 frozenAmount;
    }

    struct BetAmountInfo {
        uint256 totalBetAmount;
        uint256 actualBetAmount;
        uint256 referralFee;
        uint256 frozenPoolAmount;
    }

    struct LockInfo {
        uint256 id;
        address player;
        address referrer;
        uint256 betAmount;
        uint256 referralFee;
        uint256 rewardsFee;
        uint256 frozenPoolAmount;
        bool handled;
        GameResult result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./PoolType.sol";

/**
 * @title IPool interface
 * @author Debet
 * @notice The interface for pool contract
 */
interface IPool is PoolType {
    /**
     * @dev Emit on mint function
     * @param banker The address of user who add liquidity
     * @param tokenAmount The amount of underlying token banker added to pool
     * @param shareAmount The amount of share in token pool banker received
     */
    event Mint(
        address indexed banker,
        uint256 tokenAmount,
        uint256 shareAmount
    );

    /**
     * @dev Emit on burn function
     * @param banker The address of user who remove liquidity
     * @param tokenAmount The amount of underlying token banker received
     * @param shareAmount The amount of share in token pool banker burned
     */
    event Burn(
        address indexed banker,
        uint256 tokenAmount,
        uint256 shareAmount
    );

    /**
     * @dev Emit on receiveAndLock function
     * @param player The address of player
     * @param gameId The unique request id in the toke pool
     * @param received The amount od underlying token pool received actually
     * @param locked The amount of underlying token pool locked
     */
    event ReceiveAndLock(
        address indexed player,
        uint256 indexed gameId,
        uint256 received,
        uint256 locked
    );

    /**
     * @dev Emit on releaseAndSend function
     * @param gameId The unique request id in the toke pool
     * @param result The result of the sepecified game (0 for lose, 1 for success, 2 for cancel)
     */
    event ReleaseAndSend(uint256 indexed gameId, GameResult result);

    /**
     * @notice Add liquidity to this pool
     * @dev only the factory contract can call this function
     * @dev Emit the Mint event
     * @param banker The address of the user who added liquidity
     * @return receivedAmount The amount of token actual received by the pool
     * @return share The amount of the pool share that mint to user
     */
    function mint(address banker)
        external
        returns (uint256 receivedAmount, uint256 share);

    /**
     * @notice remove liquidity from this pool
     * @dev only the factory contract can call this function
     * @dev Emit the Burn event
     * @param banker The address of the user who removed liquidity
     * @param share The amount of pool share to burn
     * @param receiver The address of user that receive the return token
     * @return withdrawAmount The amount of token to return
     */
    function burn(
        address banker,
        uint256 share,
        address receiver
    ) external returns (uint256 withdrawAmount);

    /**
     * @notice Receive the bet amount of user and lock the payout amountof pool
     * @dev Only invalid game contract can call this function
     * @dev Emit the ReceiveAndLock event
     * @param player The address of the player
     * @param referrer The address of the referrer who recommends the user to play
     * @param betAmountInfo The information of bet
     * @return gameId The id of the request in this pool
     */
    function receiveAndLock(
        address player,
        address referrer,
        BetAmountInfo memory betAmountInfo
    ) external returns (uint256 gameId);

    /**
     * @notice Release the lock amount of pool and send the prize out if player win
     * @dev Only invalid game contract can call this function
     * @dev Emit the ReleaseAndSend event
     * @param gameId The id of the sepecified request in this pool
     * @param result The result of this game (0 for lose, 1 for success, 2 for cancel)
     * @param receiver The address of user that receive the prize if the game winner is player
     * @return totalPrize The amount of the prize to return
     */
    function releaseAndSend(
        uint256 gameId,
        GameResult result,
        address receiver
    ) external returns (uint256 totalPrize);

    /**
     * @notice Get the address of underlying token
     * @return The address of underlying token
     */
    function token() external view returns (address);

    /**
     * @notice Get the address of factory contract
     * @return The address of actory contract
     */
    function factory() external view returns (address);

    /**
     * @notice Get the curent pool id
     * @dev current pool id is also the amount of all requests
     * @return The curent pool id
     */
    function poolId() external view returns (uint256);

    /**
     * @notice Get the total amount of underlying token in the pool
     * @return The total amount of underlying token in the pool
     */
    function totalAmount() external view returns (uint256);

    /**
     * @notice Get the current rewards in the pool waiting to be added to rewards pool
     * @return The amount of current rewards in the pool
     */
    function totalRewards() external view returns (uint256);

    /**
     * @notice Get the number of times the pool receive rewards
     * @return The number of times the pool receive rewards
     */
    function addRewardsCounts() external view returns (uint256);

    /**
     * @notice Get the information of this pool
     * @return The information of this pool
     */
    function poolInfo() external view returns (PoolInfo memory);

    /**
     * @notice Get the lock information of a sepecified request
     * @param gameId The id of the sepecified request in this pool
     */
    function lockInfo(uint256 gameId) external view returns (LockInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IFactoryStorage.sol";
import "./IFactoryConfig.sol";
import "./IFactoryLogic.sol";

/**
 * @title IFactory interface
 * @author Debet
 * @notice The interface for Factory
 */
interface IFactory is IFactoryStorage, IFactoryConfig, IFactoryLogic {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title IFactoryStorage interface
 * @author Debet
 * @notice The interface for FactoryStorage
 */
interface IFactoryStorage {
    /**
     * @notice Get wether the address is a valid caller
     * @param caller The address of the caller
     * @return Wether the caller is valid or not
     */
    function isValidCaller(address caller) external view returns (bool);

    /**
     * @notice Get the ratio of the rawards pool fee in the referral fee
     * @return The ratio of the rawards pool fee in the referral fee
     */
    function protocolInReferralFee() external view returns (uint256);

    /**
     * @notice Get the maximum ratio of pool free amount to payout
     * @return The maximum ratio of pool free amount to payout
     */
    function maxPrizeRate() external view returns (uint256);

    /**
     * @notice Get the address of the rewards pool contract
     * @return The address of the rewards pool contract
     */
    function rewardsPool() external view returns (address);

    /**
     * @notice Get the address of the random engine contract
     * @return The address of the random engine contract
     */
    function randomEngine() external view returns (address);

    /**
     * @notice Get the address of the wrapped native token
     * @return The address of the wrapped native token
     */
    function nativeWrapper() external view returns (address);

    /**
     * @notice Get the token pool address by sepecified token address
     * @return pool The token pool address
     */
    function tokenPools(address token) external view returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title IFactoryConfig interface
 * @author Debet
 * @notice The interface for FactoryConfig
 */
interface IFactoryConfig {
    /**
     * @dev Emit on setDefaultCountsToAddRewards function
     * @param defaultCounts The default number of times
     */
    event UpdateDefaultCountsToAddRewards(uint256 defaultCounts);

    /**
     * @dev Emit on setCountsToAddRewards function
     * @param token The specified token address
     * @param counts The number of times
     */
    event UpdateCountsToAddRewards(address token, uint256 counts);

    /**
     * @dev Emit on setProtocolInReferralFee function
     * @param newProtocolInReferralFee The percentage
     */
    event UpdateProtocolInReferralFee(uint256 newProtocolInReferralFee);

    /**
     * @dev Emit on setMaxPrizeRate function
     * @param newMaxPrizeRate The maximun ratio
     */
    event UpdateMaxPrizeRate(uint256 newMaxPrizeRate);

    /**
     * @dev Emit on setRandomEngine function
     * @param newRandomEngine The address of random engine
     */
    event UpdateRandomEngine(address newRandomEngine);

    /**
     * @dev Emit on setRewardsPool function
     * @param newRewardsPool The address of rewards pool
     */
    event UpdateRewardsPool(address newRewardsPool);

    /**
     * @dev Emit on setGame function
     * @param game The address of game contract
     * @param enable Whether to enable or disable
     */
    event SetGame(address game, bool enable);

    /**
     * @notice Set the default number of times the pool receive rewards before
     * adding rewards to rewards pool for all tokens
     * @dev Only owner can call this function
     * @param defaultCounts The default number of times
     */
    function setDefaultCountsToAddRewards(uint256 defaultCounts) external;

    /**
     * @notice Set the number of times the pool receive rewards before adding
     * rewards to rewards pool for specified token
     * @dev Only owner can call this function
     * @param token The specified token address
     * @param counts The number of times
     */
    function setCountsToAddRewards(address token, uint256 counts) external;

    /**
     * @notice Set the ratio of the rawards pool fee in the referral fee
     * @dev Only owner can call this function
     * @param newProtocolInReferralFee The percentage
     */
    function setProtocolInReferralFee(uint256 newProtocolInReferralFee)
        external;

    /**
     * @notice Set the maximum ratio of the total free amount
     * in a token pool that will be paid out at one time
     * @dev Only owner can call this function
     * @param newMaxPrizeRate The maximun ratio
     */
    function setMaxPrizeRate(uint256 newMaxPrizeRate) external;

    /**
     * @notice Set the address of the random engine contract
     * @dev Only owner can call this function
     * @param newRandomEngine The address of random engine
     */
    function setRandomEngine(address newRandomEngine) external;

    /**
     * @notice Set the address of the rewards pool contract
     * @dev Only owner can call this function
     * @param newRewardsPool The address of rewards pool
     */
    function setRewardsPool(address newRewardsPool) external;

    /**
     * @notice Enable or disable a game contract to call token pools
     * @dev Only owner can call this function
     * @param game The address of game contract
     * @param enable Whether to enable or disable
     */
    function setGame(address game, bool enable) external;

    /**
     * @notice Query the number of times the specified token pool
     * receive rewards before adding rewards to rewards pool.
     * @param token the specified token address
     * @return the number of times
     */
    function countsToAddRewards(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./PoolType.sol";

/**
 * @title IFactoryLogic interface
 * @author Debet
 * @notice The interface for FactoryLogic
 */
interface IFactoryLogic {
    /**
     * @dev Emit on createPool function
     * @param token The address of underlying token
     * @param pool The address of new pool
     */
    event CreatePool(address token, address pool);

    /**
     * @dev Emit on mint and mintNative function
     * @param pool The address of token pool
     * @param banker The address of user who add liquidity
     * @param token The address of underlying token
     * @param amount The amount of underlying token added to pool
     * @param share The amount of share in pool banker received
     */
    event Mint(
        address indexed pool,
        address indexed banker,
        address token,
        uint256 amount,
        uint256 share
    );

    /**
     * @dev Emit on burn and burnNative function
     * @param pool The address of token pool
     * @param banker The address of user who remove liquidity
     * @param token The address of underlying token
     * @param amount The amount of underlying token banker received
     * @param share The amount of share in pool banker burned
     */
    event Burn(
        address indexed pool,
        address indexed banker,
        address token,
        uint256 amount,
        uint256 share
    );

    /**
     * @notice Add liquidity to a specified token pool
     * @param token The specified roken address
     * @param amount Amount of the token
     */
    function mint(address token, uint256 amount) external;

    /**
     * @notice Add liquidity to the wrapped native token pool
     * with native token
     */
    function mintNative() external payable;

    /**
     * @notice remove liquidity from the sepecified token pool
     * @param token The sepecified token address
     * @param share The amount of the token pool share
     */
    function burn(address token, uint256 share) external;

    /**
     * @notice Remove liquidity from the wrapped native token pool
     * and reveive the native token
     * @param share The amount of the token pool share
     */
    function burnNative(uint256 share) external;

    /**
     * @notice create a new token pool
     * @param token The address of the token
     */
    function createPool(address token) external;

    /**
     * @notice query the token pool address by token address
     * @param token The address of the token
     * @return poolInfo The information of the specified token pool
     */
    function getPoolInfo(address token)
        external
        view
        returns (PoolType.PoolInfo memory poolInfo);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IStakingPool {
    function addRewards(address token, uint256 rewards) external;

    function addNativeRewards() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract DebetBase {
    uint256 public constant RATE_DENOMINATOR = 10000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}