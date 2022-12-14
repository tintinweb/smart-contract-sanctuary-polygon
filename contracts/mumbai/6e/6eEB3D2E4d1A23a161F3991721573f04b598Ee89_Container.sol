// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC20} from "ERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {Pausable} from "Pausable.sol";
import {Ownable} from "Ownable.sol";
import {Math} from "Math.sol";
import {IERC20Metadata} from "IERC20Metadata.sol";

import {IStrategy} from "IStrategy.sol";
import {IERC4626, IERC20} from "IERC4626.sol";
import {KeeperCompatibleInterface} from "KeeperCompatibleInterface.sol";
import {IAggregatorV3} from "IAggregatorV3.sol";

import {PercentageHelper} from "PercentageHelper.sol";

contract Container is
    ERC20,
    IERC4626,
    Pausable,
    Ownable,
    KeeperCompatibleInterface
{
    using SafeERC20 for IERC20;
    using Math for uint256;
    using PercentageHelper for uint256;

    // stable token (usually USDC)
    IERC20 public immutable stableToken;

    // target token that container is exposed to (WBTC-WETH-WMATIC-WFTM etc)
    IERC20 public immutable targetToken;

    // decimals of the stable token (stableToken). Used when
    // account shares.
    uint256 public immutable stableTokenDecimals;

    // decimals of the target token (targetToken). Used when
    // account shares.
    uint256 public immutable targetTokenDecimals;

    // Current active strategy that the container operating with
    IStrategy public strategy;

    // after a stop loss happens deposit to this strategy immediately.
    IStrategy public safeStrategy;

    // Chainlink price feed for target token
    IAggregatorV3 internal targetTokenPriceFeed;

    // 0-10K bp, how much loss to stop
    uint256 public stopLimitRate = 1000;

    // perf fee
    uint256 public performanceFee = 1000;

    // default to 0
    // can be set to anything as long as < DEPOSIT_WITHDRAWAL_FEE_CAP
    uint256 public depositFee;
    uint256 public withdrawalFee;

    // address will receive the treasury fee
    address public treasuryFeeRecipient;

    // type of strategy i.e: 'LP', 'risk', 'stable', 'delta-neutral'
    string public containerType;

    uint256 private constant PERFORMANCE_FEE_CAP = 1040;
    uint256 private constant STOP_LIMIT_RATE_CAP = 5000;
    uint256 private constant DEPOSIT_WITHDRAWAL_FEE_CAP = 200;
    uint256 private constant DENOMINATOR = 10_000;

    struct StrategyParams {
        uint256 debtLimit; // maximum 'stableToken' that the strategy can take from container
        uint256 targetTokenStopPrice; // used on stop lossess and profit/loss accountant
        bool riskOn; // checks whether the strategy is 'stable' strategy or 'risky'
        bool active; // container currently using strategy or not
    }

    struct DepositInfo {
        uint256 depositedAmountStable; // usually USDC
        uint256 depositedAmountTargetToken; // target token
        uint256 sharesMinted; // how much shares we minted for user
    }

    // address => StrategyParams
    // shows all the strategies registered. To register a strategy
    // 'owner()' needs to call 'addStrategy' and add the proper strategy
    mapping(address => StrategyParams) public registeredStrategies;

    // for fee accounting
    mapping(address => DepositInfo) public userDepositInfo;

    // If this is 'false' then onlyOwner can update the stop price of the strategy
    // if it is 'true' then it is callable by anyone.
    bool public updateStopPricePublicly; // default to false

    // If this is 'false' then strategy can only be stopped by hardcoded route
    // inside the strategy. Callers do not need to provide calldata.
    // if this is 'true' then strategy can only be stopped by providing 0x swapdata
    bool public stopWithAggregator; // default to false

    event StrategyAdded(address indexed strategy, bool riskOn);
    event StrategySwitched(
        address indexed newStrategy,
        address indexed oldStrategy,
        uint256 retiredWant
    );
    event SafeStrategyUpdated(address safeStrategy);
    event StopPriceUpdated(
        address strategy,
        uint256 newStopLossTarget,
        uint256 time
    );
    event StopLimitRateUpdated(uint256 stopLimitRate);
    event PerformanceFeeUpdated(uint256 performanceFee);
    event WithdrawalFeeUpdated(uint256 withdrawalFee);
    event DepositFeeUpdated(uint256 depositFee);
    event StopPriceCallableUpdated(bool publiclyCallable);
    event StopWithAggregatorUpdated(bool stopWithAggregator);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _containerType,
        address _treasuryFeeRecipient,
        IERC20 _stableToken,
        IERC20 _targetToken,
        IAggregatorV3 _targetTokenPriceFeed
    ) ERC20(_name, _symbol) {
        containerType = _containerType;
        stableToken = _stableToken;
        treasuryFeeRecipient = _treasuryFeeRecipient;
        targetToken = _targetToken;
        targetTokenPriceFeed = _targetTokenPriceFeed;
        stableTokenDecimals = IERC20Metadata(address(_stableToken)).decimals();
        targetTokenDecimals = IERC20Metadata(address(_targetToken)).decimals();
    }

    // ERC4626 LOGIC ----------------------------------------------------------------------------------------

    modifier onlyStrategy() {
        require(msg.sender == address(strategy), "ONLY_ACTIVE_STRATEGY");
        _;
    }

    // @notice Total assets to consider when minting shares
    // mainly based on the working positions of the strategy
    function totalAssets() public view returns (uint256) {
        return strategy.balanceOfWorkingPositionsPrecised();
    }

    // @notice Use this when mint/burn shares to account the positions index
    function getIndex() public view returns (uint256) {
        if (totalSupply() == 0) return 1e18;
        if (registeredStrategies[address(strategy)].riskOn) {
            return
                (totalSupply() * 1e18) /
                strategy.balanceOfWorkingPositionsPrecised();
        }
        return ((totalSupply() * 1e18) /
            strategy.balanceOfWorkingPositionsPrecised());
    }

    // @notice Returns the depositable token to container
    function getDepositableToken() external view returns (address) {
        if (!registeredStrategies[address(strategy)].active) return address(0);
        if (registeredStrategies[address(strategy)].riskOn) {
            return address(targetToken);
        } else return address(stableToken);
    }

    // @notice Sets the safest strategy for the container.
    function setSafeStrategy(IStrategy _strategy) external onlyOwner {
        require(address(_strategy) != address(0), "ZERO_ADDRESS");
        require(
            registeredStrategies[address(_strategy)].debtLimit > 0,
            "ADD_STRATEGY_FIRST"
        );

        safeStrategy = _strategy;

        emit SafeStrategyUpdated(address(_strategy));
    }

    function setStopLimitRate(uint256 _stopLimitRate) external onlyOwner {
        require(_stopLimitRate <= STOP_LIMIT_RATE_CAP, "HIGH_STOP_RATE");
        stopLimitRate = _stopLimitRate;

        emit StopLimitRateUpdated(_stopLimitRate);
    }

    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        require(_performanceFee <= PERFORMANCE_FEE_CAP, "HIGH_PERFORMANCE_FEE");
        performanceFee = _performanceFee;

        emit PerformanceFeeUpdated(_performanceFee);
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external onlyOwner {
        require(
            _withdrawalFee <= DEPOSIT_WITHDRAWAL_FEE_CAP,
            "HIGH_WITHDRAWAL_FEE"
        );
        withdrawalFee = _withdrawalFee;

        emit WithdrawalFeeUpdated(_withdrawalFee);
    }

    function setDepositFee(uint256 _depositFee) external onlyOwner {
        require(_depositFee <= DEPOSIT_WITHDRAWAL_FEE_CAP, "HIGH_DEPOSIT_FEE");
        depositFee = _depositFee;

        emit DepositFeeUpdated(_depositFee);
    }

    function setPublicStopPrice(bool _updateStopPricePublicly)
        external
        onlyOwner
    {
        updateStopPricePublicly = _updateStopPricePublicly;

        emit StopPriceCallableUpdated(_updateStopPricePublicly);
    }

    function setStopWithAggregator(bool _stopWithAggregator)
        external
        onlyOwner
    {
        stopWithAggregator = _stopWithAggregator;

        emit StopWithAggregatorUpdated(_stopWithAggregator);
    }

    // @notice Deposits funds from 'msg.sender' to the container for the container shares.
    // @dev Whatever the depositable token is container will try to take that from 'msg.sender'
    // and deposit behalf of the 'receiver'
    // @param assets How much to deposit (denominated in 'getDepositableToken()')
    // @param receiver Address that will receive the shares
    // @return Returns the total shares minted to 'receiver'
    // IMPORTANT: shares are 18 decimal ERC20 tokens, we account share maths
    ///////////// according to 18 decimals.
    function deposit(uint256 assets, address receiver)
        public
        whenNotPaused
        returns (uint256)
    {
        require(assets > 0, "ZERO_DEPOSIT_AMOUNT");

        StrategyParams storage strategyParams = registeredStrategies[
            address(strategy)
        ];
        DepositInfo storage user = userDepositInfo[receiver];
        uint256 shares;
        uint256 depositFeeCached = depositFee; // save gas cache
        // IF STRATEGY IS 'RISKY'
        if (strategyParams.riskOn) {
            // Check if there are enough room for users deposit
            require(
                ((totalAssets() * getTargetTokenPrice()) / 1e18) +
                    (assets * 10**(18 - targetTokenDecimals)) <=
                    strategyParams.debtLimit,
                "MAX_DEBT_LIMIT_REACHED"
            );

            targetToken.safeTransferFrom(msg.sender, address(this), assets);

            // Deduct the deposit fee
            if (depositFeeCached != 0) {
                uint256 depositFeeTaken = (assets * depositFeeCached) /
                    DENOMINATOR;
                targetToken.safeTransfer(treasuryFeeRecipient, depositFeeTaken);
                assets -= depositFeeTaken;
            }

            // Calculate the storage variables for user
            user.depositedAmountStable +=
                (assets *
                    10**(18 - targetTokenDecimals) *
                    getTargetTokenPrice()) /
                10**(36 - stableTokenDecimals); // we treat stableToken is 1$ (USDC/DAI/USDT)
            user.depositedAmountTargetToken += assets;

            // Calculate the share needs to be minted for the user
            shares = _calculateSharesToBeMinted(assets);
            user.sharesMinted += shares;

            _mint(msg.sender, shares);

            emit Deposited(msg.sender, receiver, shares, assets);
            return shares;
        }

        // IF STRATEGY IS 'STABLE'

        // Check if there are enough room for users deposit
        require(
            totalAssets() + (assets * 10**(18 - stableTokenDecimals)) <=
                strategyParams.debtLimit,
            "MAX_DEBT_LIMIT_REACHED"
        );

        stableToken.safeTransferFrom(msg.sender, address(this), assets);

        // Deduct the deposit fee
        if (depositFeeCached != 0) {
            uint256 depositFeeTaken = (assets * depositFeeCached) / DENOMINATOR;
            stableToken.safeTransfer(treasuryFeeRecipient, depositFeeTaken);
            assets -= depositFeeTaken;
        }

        // Calculate the storage variables for user
        user.depositedAmountStable += assets; // we treat stableToken is 1$ (USDC/DAI/USDT)
        user.depositedAmountTargetToken +=
            ((assets * 10**(36 - stableTokenDecimals)) /
                getTargetTokenPrice()) /
            10**(18 - targetTokenDecimals);

        // Calculate the share needs to be minted for the user
        shares = _calculateSharesToBeMinted(assets);
        user.sharesMinted += shares;
        _mint(msg.sender, shares);

        emit Deposited(msg.sender, receiver, shares, assets);
        return shares;
    }

    // NOTE: Delta positions and index are always in 18 decimals!!
    function _calculateSharesToBeMinted(uint256 _assets)
        internal
        returns (uint256 shares)
    {
        uint256 indexNormal = getIndex();
        uint256 deltaPositions = strategy.getInPosition(_assets);
        shares = (deltaPositions * indexNormal) / 1e18;
    }

    // @notice Burns the shares from 'owner' for the 'stableToken' token and sends it to 'receiver'.
    // @param assets Shares to burn
    // @param receiver Where the funds go after redeem
    // @return Returns the 'getDepositableToken()' amount sent to 'receiver'
    // IMPORTANT: shares are 18 decimal ERC20 tokens, we account share maths
    ///////////// according to 18 decimals.
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public returns (uint256) {
        // IMPORTANT: 'liquidateAmount' is always 18 decimals
        // working positions are the tokens that the strategy is earning yield from. (curve lps, aave tokens etc)
        // proportion to the shares working tokens will be liquidated and return to container in form of either
        // 'stableToken' or 'targetToken' depending on the strategy type (Risk on == targetToken, Stable == stableToken).
        // If the strategy is in emergency mode than it means that the strategy is not in the position meaning that
        // there are no working tokens and strategy has 'targetToken' or 'stableToken' idle. In that case, 'balanceOfWorkingPositionsPrecised()'
        // will return the idle amounts.
        uint256 liquidateAmount = (shares *
            strategy.balanceOfWorkingPositionsPrecised()) / totalSupply(); // precision to 1e18 //

        if (owner != msg.sender) _spendAllowance(owner, msg.sender, shares);
        _burn(owner, shares);

        // Calculate the user storage variables proportion to the shares been withdrawning
        DepositInfo storage user = userDepositInfo[owner];
        uint256 sharesRatio = (shares * 1e18) / user.sharesMinted;
        uint256 withdrawnAmountRatioStable = (sharesRatio *
            user.depositedAmountStable) / 1e18;
        uint256 withdrawnAmountRatioTarget = (sharesRatio *
            user.depositedAmountTargetToken) / 1e18;

        // Update storage variables for user
        user.sharesMinted -= shares;
        user.depositedAmountStable -= withdrawnAmountRatioStable;
        user.depositedAmountTargetToken -= withdrawnAmountRatioTarget;

        uint256 liquidated = 0;
        uint256 fee = 0;
        uint256 profit = 0;

        // IF STRATEGY IS 'RISKY'
        if (registeredStrategies[address(strategy)].riskOn) {
            // 'getOutPosition()' liquidates the proper position and sends the 'targetToken' to container.
            liquidated = strategy.getOutPosition(liquidateAmount);
            if (withdrawalFee != 0) {
                fee = (liquidated * withdrawalFee) / DENOMINATOR;
            }
            if (liquidated > withdrawnAmountRatioTarget) {
                unchecked {
                    profit = liquidated - withdrawnAmountRatioTarget;
                }
                fee += (profit * performanceFee) / DENOMINATOR;
            } else {
                uint256 wantWorthTargetToken = (withdrawnAmountRatioStable *
                    10**(36 - stableTokenDecimals)) / getTargetTokenPrice();
                if (liquidated > wantWorthTargetToken) {
                    unchecked {
                        profit = liquidated - wantWorthTargetToken;
                    }
                    fee += (profit * performanceFee) / DENOMINATOR;
                }
            }

            if (profit > 0) {
                profit = profit - fee;
                liquidated = liquidated - fee;
            }

            if (fee > 0) {
                targetToken.safeTransfer(treasuryFeeRecipient, fee);
            }

            targetToken.safeTransfer(receiver, liquidated);
            emit Withdrawn(
                msg.sender,
                receiver,
                shares,
                liquidated,
                profit,
                fee
            );
            return liquidated;

            // IF STRATEGY IS 'STABLE'
        } else {
            liquidated = strategy.getOutPosition(liquidateAmount);
            if (withdrawalFee != 0) {
                fee = (liquidated * withdrawalFee) / DENOMINATOR;
            }
            if (liquidated > withdrawnAmountRatioStable) {
                unchecked {
                    profit = liquidated - withdrawnAmountRatioStable;
                }
                fee += (profit * performanceFee) / DENOMINATOR;
            } else {
                uint256 targetTokenWorthStable = (withdrawnAmountRatioTarget *
                    10**(18 - targetTokenDecimals) *
                    getTargetTokenPrice()) / 10**(36 - stableTokenDecimals);
                if (liquidated > targetTokenWorthStable) {
                    unchecked {
                        profit = liquidated - targetTokenWorthStable;
                    }
                    fee += (profit * performanceFee) / DENOMINATOR;
                }
            }

            if (profit > 0) {
                profit = profit - fee;
                liquidated = liquidated - fee;
            }

            if (fee > 0) {
                stableToken.safeTransfer(treasuryFeeRecipient, fee);
            }

            stableToken.safeTransfer(receiver, liquidated);
            emit Withdrawn(
                msg.sender,
                receiver,
                shares,
                liquidated,
                profit,
                fee
            );
            return liquidated;
        }

        return 0;
    }

    // CONTAINER LOGIC ----------------------------------------------------------------------------------------------------

    // @notice Adds a strategy to the container.
    // @params _newStrategy Strategy address to be added
    // @params _debtLimit Debt limit of the strategy to be added a.k.a max deposit amount in terms of USD value 18 decimals
    // @params _riskOn True if the strategy is 'risky' type.
    function addStrategy(
        address _newStrategy,
        uint256 _debtLimit, // 18 decimals $ value
        bool _riskOn
    ) external whenNotPaused onlyOwner {
        require(address(_newStrategy) != address(0), "ZERO_ADDRESS");
        require(
            registeredStrategies[address(_newStrategy)].debtLimit == 0,
            "ALREADY_ADDED"
        );
        require(_debtLimit != 0, "ZERO_DEBT_LIMIT");
        require(
            IStrategy(_newStrategy).stableToken() == address(stableToken),
            "STABLE_TOKEN"
        );

        registeredStrategies[_newStrategy] = StrategyParams(
            _debtLimit,
            0,
            _riskOn,
            false
        );
        // if no strategy set. This scenario can happen when you first deploy the container.
        if (address(strategy) == address(0)) {
            strategy = IStrategy(_newStrategy);
            registeredStrategies[_newStrategy].active = true;
            if (_riskOn) {
                registeredStrategies[_newStrategy]
                    .targetTokenStopPrice = getTargetTokenPrice()
                    .percentageSubstract(stopLimitRate);
            }
        }

        // Strategies are trusted, approve max.
        stableToken.approve(_newStrategy, type(uint256).max);
        if (_riskOn) {
            targetToken.approve(_newStrategy, type(uint256).max);
        }

        emit StrategyAdded(_newStrategy, _riskOn);
    }

    // @dev Switches to new strategy. If the strategy being switched
    // is 'stable' then funds will be immediately deposited to work. If the strategy being swithced
    // is 'risky' funds will be idle untill someone swaps them for target token and put it into position
    function _switchStrategy(
        address _newStrategy,
        address _callFeeRecipient,
        bytes memory swapData,
        uint256 _possibility
    ) internal {
        StrategyParams storage newStrategyParams = registeredStrategies[
            _newStrategy
        ];

        require(newStrategyParams.debtLimit > 0, "ADD_STRATEGY_FIRST");
        require(address(strategy) != _newStrategy, "SAME_STRATEGIES");

        uint256 wantRetired;
        if (strategy.balanceOfWorkingPositions() > 0) {
            if (_possibility == 0)
                // strategy is 'risky'
                wantRetired = strategy.retire(
                    swapData,
                    _newStrategy,
                    _callFeeRecipient
                );
            else if (_possibility == 1)
                // strategy is 'stable'
                wantRetired = strategy.retire(_newStrategy);
            else strategy.stopStrategy(_newStrategy); // stop
        }

        strategy = IStrategy(_newStrategy);
        newStrategyParams.active = true;
        emit StrategySwitched(address(strategy), _newStrategy, wantRetired);

        if (!newStrategyParams.riskOn) {
            strategy.deposit();
        }
        // if switching to risk on call 'deposit(bytes data)' inside risky strat.
        // Since we are using 0x API migrations might revert because of the math flaws.
        // It is guaranteed when strategy first migrates and we see exact amount of 'stableToken'
        // then we can call deposit() with the proper 0x data and make sure it not reverts.
        else {
            newStrategyParams.targetTokenStopPrice = getTargetTokenPrice()
                .percentageSubstract(stopLimitRate);
        }
    }

    // @notice Switches the containers active strategy
    // @dev Only registered strategies can be switched to
    // @params _newStrategy Strategy to switch
    // @params swapData 0x API Data that will swap all 'targetToken' to 'stableToken'
    function switchStrategy(address _newStrategy, bytes calldata swapData)
        external
        whenNotPaused
        onlyOwner
    {
        require(
            registeredStrategies[address(strategy)].riskOn,
            "USE_OTHER_FUNCTION"
        );
        _switchStrategy(_newStrategy, address(0), swapData, 0);
    }

    function switchStrategy(address _newStrategy) external onlyOwner {
        require(
            !registeredStrategies[address(strategy)].riskOn,
            "USE_OTHER_FUNCTION"
        );
        _switchStrategy(_newStrategy, address(0), "", 1);
    }

    // @notice Pauses some functions
    // @dev Pauses deposits, switching and adding strategies
    // withdrawals are not paused so that users can always withdraw
    // their portion of the container regardless of the pause statement.
    // any function that have 'whenNotPaused' modifier will not be able to
    // used. 'unpause()' can be called to return to the normal state.
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // CHAINLINK FUNCTIONS //

    // @notice Updates the stop price of the strategy
    // @dev Only callable if the active strategy is 'riskOn'
    function updateStopPrice(uint256 _stopTarget) external {
        if (!updateStopPricePublicly)
            require(msg.sender == owner(), "ONLY_OWNER");
        require(
            registeredStrategies[address(strategy)].riskOn,
            "STRATEGY_NOT_RISKY"
        );
        require(_stopTarget != 0, "STOP_TARGET_ZERO");
        require(_stopTarget <= getTargetTokenPrice(), "TOO_CLOSE_STOP");

        registeredStrategies[address(strategy)]
            .targetTokenStopPrice = _stopTarget;

        emit StopPriceUpdated(address(strategy), _stopTarget, block.timestamp);
    }

    // @notice Liquidates all positions and sends it to new strategy
    // @dev Calls 'reportStop()' in container which it will switch the strategy
    // to the 'safestStrategy'. Whoever calls this function will be rewarded with the
    // call fee which is been calculated inside the '_exchange()' if only 'callFee' != 0
    function performUpkeep(bytes calldata performData) external {
        (bool stoppable, ) = checkUpkeep("blank data");
        require(stoppable, "NOT_STOPPABLE");

        // stop by hardcoded route, no bounty for this action!
        if (!stopWithAggregator) {
            _switchStrategy(address(safeStrategy), address(0), "", 2);
        }
        // if 'performData' is not '0' then that means it could be the 0x swap data
        // if the data is not valid, then the execution will fail in the strategy level.
        else {
            _switchStrategy(address(safeStrategy), msg.sender, performData, 0);
        }
    }

    function checkUpkeep(bytes memory checkData)
        public
        returns (bool, bytes memory)
    {
        StrategyParams memory params = registeredStrategies[address(strategy)];

        require(params.active, "STRATEGY_NOT_ACTIVE");
        require(params.riskOn, "STRATEGY_NOT_RISKY");
        require(
            getTargetTokenPrice() <= params.targetTokenStopPrice,
            "STOP_LIMIT_NOT_REACHED"
        );
        return (true, "");
    }

    // 18 DECIMALS!!
    function getTargetTokenPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = targetTokenPriceFeed.latestRoundData();
        uint256 decimals = targetTokenPriceFeed.decimals();
        return uint256(price) * 10**(18 - decimals);
    }

    // this is here for test but can be exist in actual contract code aswell.
    function setPriceFeed(IAggregatorV3 _newTargetTokenPriceFeed)
        external
        onlyOwner
    {
        targetTokenPriceFeed = _newTargetTokenPriceFeed;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IStrategy {

  // all strategies must include these functions
  function estimatedTotalAssets() external view returns (uint256);
  function balanceOfWorkingPositions() external view returns (uint256);
  function balanceOfWorkingPositionsPrecised() external view returns (uint256);
  function targetToken() external view returns (address);
  function getInPosition(uint256 _amount) external returns (uint256);
  function getOutPosition(uint256 _amount) external returns (uint256);
  function deposit(bytes calldata swapData, bytes calldata swapDataAlternative) external;
  function deposit() external;
  function stableToken() external view returns (address stableToken);
  function retire(bytes calldata swapData, address _newStrategy, address _callFeeRecipient) external returns (uint256);
  function retire(address _newStrategy) external returns (uint256);
  function liquidate(uint256 _liquidateAmount) external returns (uint256);
  function stopStrategy(address _newStrategy) external;

  /// @dev Defines a transformation to run in `transformERC20()`.
  struct Transformation {
      // The deployment nonce for the transformer.
      // The address of the transformer contract will be derived from this
      // value.
      uint32 deploymentNonce;
      // Arbitrary data to pass to the transformer.
      bytes data;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "IERC20.sol";

interface IERC4626 is IERC20 {

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() external view returns (uint256);


    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposited(address indexed caller, address indexed receiver, uint256 sharesMinted, uint256 assets);
    event Withdrawn(address indexed caller, address indexed receiver, uint256 sharesBurned, uint256 assetsReceived, uint256 profit, uint256 fee);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAggregatorV3 {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library PercentageHelper {

  function percentageAdd(uint256 _number, uint256 _percentage) internal pure returns (uint256) {
    require(_percentage != 0 && _percentage <= 10_000, 'LIB: Percentage basis out of index');
    uint256 percentageOf = (_number * _percentage) / 10_000;
    return _number + percentageOf;
  }

  function percentageSubstract(uint256 _number, uint256 _percentage) internal pure returns (uint256) {
    require(_percentage != 0 && _percentage <= 10_000, 'LIB: Percentage basis out of index');
    uint256 percentageOf = (_number * _percentage) / 10_000;
    return _number - percentageOf;
  }
}