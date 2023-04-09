// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./../../../utils/UpgradeableBase.sol";
import "./../../../interfaces/IXToken.sol";
import "./../../../interfaces/IDForce.sol";
import "./../../../interfaces/IMultiLogicProxy.sol";
import "./../../../interfaces/ILogicContract.sol";
import "./../../../interfaces/IStrategyStatistics.sol";
import "./../../../interfaces/IStrategyContract.sol";

contract DForceStrategy is UpgradeableBase, IStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct RewardsTokenPriceInfo {
        uint256 latestAnswer;
        uint256 timestamp;
    }

    uint256 internal constant DECIMALS = 18;
    uint256 internal constant BASE = 10**DECIMALS;

    address public logic;
    address public blid;
    address public strategyXToken;
    address public comptroller;
    address public rewardsToken;

    // Strategy Parameter
    uint8 public circlesCount;
    uint8 public avoidLiquidationFactor;

    uint256 private minStorageAvailable;
    uint256 public borrowRateMin;
    uint256 public borrowRateMax;

    address public multiLogicProxy;
    address public strategyStatistics;

    // RewardsTokenPrice kill switch
    uint256 public rewardsTokenPriceDeviationLimit; // percentage, decimal = 18
    RewardsTokenPriceInfo private rewardsTokenPriceInfo;

    // Swap Rewards to BLID
    address public swapRouter_RewardsToBLID;
    address[] public path_RewardsToBLID;
    uint8 public swapType_RewardsToBLID; // 0 : pancakeswap, 1: uniswapV3

    // Swap Rewards to StrategyToken
    address public swapRouter_RewardsToStrategyToken;
    address[] public path_RewardsToStrategyToken;
    uint8 public swapType_RewardsToStrategyToken;

    // Swap StrategyToken to BLID
    address public swapRouter_StrategyTokenToBLID;
    address[] public path_StrategyTokenToBLID;
    uint8 public swapType_StrategyTokenToBLID;

    uint256 minimumBLIDPerRewardToken;
    uint256 minRewardsSwapLimit;
    address public strategyToken;

    event SetBLID(address blid);
    event SetCirclesCount(uint8 circlesCount);
    event SetAvoidLiquidationFactor(uint8 avoidLiquidationFactor);
    event SetMinRewardsSwapLimit(uint256 _minRewardsSwapLimit);
    event SetStrategyXToken(address strategyXToken);
    event SetMinStorageAvailable(uint256 minStorageAvailable);
    event SetRebalanceParameter(uint256 borrowRateMin, uint256 borrowRateMax);
    event SetRewardsTokenPriceDeviationLimit(uint256 deviationLimit);
    event SetRewardsTokenPriceInfo(uint256 latestAnser, uint256 timestamp);
    event BuildCircle(address token, uint256 amount, uint256 circlesCount);
    event DestroyCircle(
        address token,
        uint256 circlesCount,
        uint256 destroyAmountLimit
    );
    event DestroyAll(address token, uint256 destroyAmount, uint256 blidAmount);
    event ClaimRewards(uint256 amount);
    event UseToken(address token, uint256 amount);
    event ReleaseToken(address token, uint256 amount);

    function __DForceStrategy_init(address _comptroller, address _logic)
        public
        initializer
    {
        UpgradeableBase.initialize();
        comptroller = _comptroller;
        rewardsToken = IDistributionDForce(
            IComptrollerDForce(comptroller).rewardDistributor()
        ).rewardToken();
        logic = _logic;

        rewardsTokenPriceDeviationLimit = (1 ether) / uint256(86400); // limit is 1% within 1 day
        minRewardsSwapLimit = 20 * (1 ether); // 1.5 USD is required
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyMultiLogicProxy() {
        require(msg.sender == multiLogicProxy, "DF1");
        _;
    }

    modifier onlyStrategyPaused() {
        require(_checkStrategyPaused(), "DF2");
        _;
    }

    /*** Public Initialize Function ***/

    /**
     * @notice Set blid in contract
     * @param _blid Address of BLID
     */
    function setBLID(address _blid) external onlyOwner {
        require(blid == address(0), "DF3");
        blid = _blid;
        emit SetBLID(_blid);
    }

    /**
     * @notice Set MultiLogicProxy, you can call the function once
     * @param _multiLogicProxy Address of Multilogic Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        require(multiLogicProxy == address(0), "DF5");
        multiLogicProxy = _multiLogicProxy;
    }

    /**
     * @notice Set StrategyStatistics
     * @param _strategyStatistics Address of StrategyStatistics
     */
    function setStrategyStatistics(address _strategyStatistics)
        external
        onlyOwner
    {
        strategyStatistics = _strategyStatistics;

        // Save RewardsTokenPriceInfo
        rewardsTokenPriceInfo.latestAnswer = IStrategyStatistics(
            _strategyStatistics
        ).getRewardsTokenPrice(comptroller, rewardsToken);
        rewardsTokenPriceInfo.timestamp = block.timestamp;
    }

    /**
     * @notice Set circlesCount
     * @param _circlesCount Count number
     */
    function setCirclesCount(uint8 _circlesCount) external onlyOwner {
        circlesCount = _circlesCount;

        emit SetCirclesCount(_circlesCount);
    }

    /**
     * @notice Set min Rewards swap limit
     * @param _minRewardsSwapLimit minimum swap amount for rewards token
     */
    function setMinRewardsSwapLimit(uint256 _minRewardsSwapLimit)
        external
        onlyOwner
    {
        minRewardsSwapLimit = _minRewardsSwapLimit;

        emit SetMinRewardsSwapLimit(_minRewardsSwapLimit);
    }

    /**
     * @notice Set Rewards -> BLID swap information
     * @param swapRouter : address of swap Router
     * @param path path to rewards to BLID
     * @param swapType 0 : pancakeswap, 1 : uniswapV3
     * @param _minimumBLIDPerRewardToken minimum BLID for RewardsToken
     */
    function setRewardsToBLID(
        address swapRouter,
        address[] calldata path,
        uint8 swapType,
        uint256 _minimumBLIDPerRewardToken
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "DF6");
        require(path[0] == rewardsToken, "DF7");
        require(path[length - 1] == blid, "DF8");

        swapRouter_RewardsToBLID = swapRouter;
        path_RewardsToBLID = new address[](length);
        for (uint256 i = 0; i < length; ) {
            path_RewardsToBLID[i] = path[i];

            unchecked {
                ++i;
            }
        }

        swapType_RewardsToBLID = swapType;
        minimumBLIDPerRewardToken = _minimumBLIDPerRewardToken;
    }

    /**
     * @notice Set Rewards to StrategyToken swap information
     * @param swapRouter : address of swap Router
     * @param path path to rewards to BLID
     * @param swapType 0 : pancakeswap, 1 : uniswapV3
     */
    function setRewardsToStrategyToken(
        address swapRouter,
        address[] calldata path,
        uint8 swapType
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "DF6");
        require(path[0] == rewardsToken, "DF7");
        require(path[length - 1] == strategyToken, "DF8");

        swapRouter_RewardsToStrategyToken = swapRouter;
        path_RewardsToStrategyToken = new address[](length);
        for (uint256 i = 0; i < length; ) {
            path_RewardsToStrategyToken[i] = path[i];

            unchecked {
                ++i;
            }
        }

        swapType_RewardsToStrategyToken = swapType;
    }

    /**
     * @notice Set StrategyToken to BLID swap information
     * @param swapRouter : address of swap Router
     * @param path path to rewards to BLID
     * @param swapType 0 : pancakeswap, 1 : uniswapV3
     */
    function setStrategyTokenToBLID(
        address swapRouter,
        address[] calldata path,
        uint8 swapType
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "DF6");
        require(path[0] == strategyToken, "DF7");
        require(path[length - 1] == blid, "DF8");

        swapRouter_StrategyTokenToBLID = swapRouter;
        path_StrategyTokenToBLID = new address[](length);
        for (uint256 i = 0; i < length; ) {
            path_StrategyTokenToBLID[i] = path[i];

            unchecked {
                ++i;
            }
        }

        swapType_StrategyTokenToBLID = swapType;
    }

    /**
     * @notice Set avoidLiquidationFactor
     * @param _avoidLiquidationFactor factor value (0-99)
     */
    function setAvoidLiquidationFactor(uint8 _avoidLiquidationFactor)
        external
        onlyOwner
    {
        require(_avoidLiquidationFactor < 100, "DF4");

        avoidLiquidationFactor = _avoidLiquidationFactor;
        emit SetAvoidLiquidationFactor(_avoidLiquidationFactor);
    }

    /**
     * @notice Set MinStorageAvailable
     * @param amount amount of min storage available for token using : decimals = token decimals
     */
    function setMinStorageAvailable(uint256 amount) external onlyOwner {
        minStorageAvailable = amount;
        emit SetMinStorageAvailable(amount);
    }

    /**
     * @notice Set RebalanceParameter
     * @param _borrowRateMin borrowRate min : decimals = 18
     * @param _borrowRateMax borrowRate max : deciamls = 18
     */
    function setRebalanceParameter(
        uint256 _borrowRateMin,
        uint256 _borrowRateMax
    ) external onlyOwner {
        require(_borrowRateMin < BASE, "DF4");
        require(_borrowRateMax < BASE, "DF4");
        borrowRateMin = _borrowRateMin;
        borrowRateMax = _borrowRateMax;
        emit SetRebalanceParameter(_borrowRateMin, _borrowRateMin);
    }

    /**
     * @notice Set RewardsTokenPriceDeviationLimit
     * @param _rewardsTokenPriceDeviationLimit price Diviation per seccond limit
     */
    function setRewardsTokenPriceDeviationLimit(
        uint256 _rewardsTokenPriceDeviationLimit
    ) external onlyOwner {
        rewardsTokenPriceDeviationLimit = _rewardsTokenPriceDeviationLimit;

        emit SetRewardsTokenPriceDeviationLimit(
            _rewardsTokenPriceDeviationLimit
        );
    }

    /**
     * @notice Force update rewardsTokenPrice
     * @param latestAnswer new latestAnswer
     */
    function setRewardsTokenPrice(uint256 latestAnswer) external onlyOwner {
        rewardsTokenPriceInfo.latestAnswer = latestAnswer;
        rewardsTokenPriceInfo.timestamp = block.timestamp;

        emit SetRewardsTokenPriceInfo(latestAnswer, block.timestamp);
    }

    /*** Public Automation Check view function ***/

    /**
     * @notice Check wheather storageAvailable is bigger enough
     * @return canUseToken true : useToken is possible
     */
    function checkUseToken() public view override returns (bool canUseToken) {
        if (
            IMultiLogicProxy(multiLogicProxy).getTokenAvailable(
                strategyToken,
                logic
            ) < minStorageAvailable
        ) {
            canUseToken = false;
        } else {
            canUseToken = true;
        }
    }

    /**
     * @notice Check whether borrow rate is ok
     * @return canRebalance true : rebalance is possible, borrow rate is abnormal
     */
    function checkRebalance() public view override returns (bool canRebalance) {
        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(strategyXToken, logic);

        // If no lending, can't rebalance
        if (xTokenInfo.totalSupply == 0) return false;

        uint256 borrowRate = xTokenInfo.borrowLimit == 0
            ? 0
            : (xTokenInfo.borrowAmount * BASE) / xTokenInfo.borrowLimit;

        if (borrowRate > borrowRateMax || borrowRate < borrowRateMin) {
            canRebalance = true;
        } else {
            canRebalance = false;
        }
    }

    /*** Public Strategy Function ***/

    /**
     * @notice Set StrategyXToken
     * Add XToken in Contract and approve token
     * entermarkets to lending system
     * @param _xToken Address of XToken
     */
    function setStrategyXToken(address _xToken)
        external
        onlyOwner
        onlyStrategyPaused
    {
        require(strategyXToken != _xToken, "DF10");

        address _logic = logic;
        address _strategyToken = IiToken(_xToken).underlying();

        // Add token/iToken to Logic
        ILogic(_logic).addXTokens(_strategyToken, _xToken);

        // Entermarkets with token/iToken
        address[] memory tokens = new address[](1);
        tokens[0] = _xToken;
        ILogic(_logic).enterMarkets(tokens);

        strategyXToken = _xToken;
        strategyToken = _strategyToken;
        emit SetStrategyXToken(_xToken);
    }

    function setStrategyToken() external onlyOwner {
        strategyToken = IiToken(strategyXToken).underlying();
    }

    function useToken() external override {
        address _logic = logic;
        address _strategyXToken = strategyXToken;
        address _strategyToken = strategyToken;

        // Check if storageAvailable is bigger enough
        uint256 availableAmount = IMultiLogicProxy(multiLogicProxy)
            .getTokenAvailable(_strategyToken, _logic);
        if (availableAmount < minStorageAvailable) return;

        // Take token from storage
        ILogic(_logic).takeTokenFromStorage(availableAmount, _strategyToken);

        // Mint
        ILogic(_logic).mint(_strategyXToken, availableAmount);

        emit UseToken(_strategyToken, availableAmount);
    }

    function rebalance() external override {
        address _logic = logic;
        address _strategyXToken = strategyXToken;
        uint8 _circlesCount = circlesCount;
        uint256 _borrowRateMin = borrowRateMin;
        uint256 _borrowRateMax = borrowRateMax;
        uint256 targetBorrowRate = _borrowRateMin +
            (_borrowRateMax - _borrowRateMin) /
            2;
        (
            uint256 collateralFactor,
            uint256 collateralFactorApplied
        ) = _getCollateralFactor(_strategyXToken);

        // Call mint with 0 amount to accrueInterest
        ILogic(_logic).mint(_strategyXToken, 0);

        // get statistics
        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, _logic);

        uint256 borrowRate = xTokenInfo.borrowLimit == 0
            ? 0
            : (xTokenInfo.borrowAmount * BASE) / xTokenInfo.borrowLimit;

        // Build
        if (borrowRate < _borrowRateMin) {
            uint256 Y = 0;
            uint256 accLTV = BASE;
            for (uint256 i = 0; i < _circlesCount; ) {
                Y = Y + accLTV;
                accLTV = (accLTV * collateralFactorApplied) / BASE;
                unchecked {
                    ++i;
                }
            }
            uint256 buildAmount = ((((((xTokenInfo.totalSupply *
                targetBorrowRate) / BASE) * collateralFactor) / BASE) -
                xTokenInfo.borrowAmount) * BASE) /
                ((Y * (BASE - (targetBorrowRate * collateralFactor) / BASE)) /
                    BASE);
            if (buildAmount > 0) {
                createCircles(_strategyXToken, buildAmount, _circlesCount);

                emit BuildCircle(_strategyXToken, buildAmount, _circlesCount);
            }
        }

        // Destroy
        if (borrowRate > _borrowRateMax) {
            uint256 LTV = collateralFactor; // don't apply avoidLiquidationFactor
            uint256 destroyAmount = ((xTokenInfo.borrowAmount -
                (((xTokenInfo.totalSupply * targetBorrowRate) / BASE) * LTV) /
                BASE) * BASE) / (BASE - (targetBorrowRate * LTV) / BASE);

            destructCircles(_strategyXToken, _circlesCount, destroyAmount);

            emit DestroyCircle(_strategyXToken, _circlesCount, destroyAmount);
        }
    }

    /**
     * @notice Destroy circle strategy
     * destroy circle and return all tokens to storage
     */
    function destroyAll() external override onlyOwnerAndAdmin {
        address _logic = logic;
        address _rewardsToken = rewardsToken;
        address _strategyXToken = strategyXToken;
        address _strategyToken = strategyToken;
        uint256 amountBLID = 0;

        // Destruct circle
        destructCircles(_strategyXToken, circlesCount, 0);

        // Claim Rewards token
        ILogic(_logic).claim();

        // RewardsToken Price/Amount Kill Switch
        bool rewardsTokenKill = _rewardsPriceKillSwitch(
            strategyStatistics,
            _rewardsToken
        );
        uint256 amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken)
            .balanceOf(_logic);
        if (amountRewardsToken <= minRewardsSwapLimit) rewardsTokenKill = true;

        // swap rewardsToken to StrategyToken
        if (
            rewardsTokenKill == false &&
            IERC20MetadataUpgradeable(_rewardsToken).balanceOf(_logic) > 0
        ) {
            ILogic(_logic).swap(
                swapRouter_RewardsToStrategyToken,
                IERC20MetadataUpgradeable(_rewardsToken).balanceOf(_logic),
                0,
                path_RewardsToStrategyToken,
                true,
                swapType_RewardsToStrategyToken
            );
        }

        // Get strategy amount, current balance of underlying
        uint256 amountStrategy = IMultiLogicProxy(multiLogicProxy)
            .getTokenTaken(_strategyToken, _logic);
        uint256 balanceToken = IERC20Upgradeable(_strategyToken).balanceOf(
            _logic
        );

        // If we have extra, swap StrategyToken to BLID
        if (balanceToken > amountStrategy) {
            ILogic(_logic).swap(
                swapRouter_StrategyTokenToBLID,
                balanceToken - amountStrategy,
                0,
                path_StrategyTokenToBLID,
                true,
                swapType_StrategyTokenToBLID
            );

            // Add BLID earn to storage
            amountBLID = _addEarnToStorage();
        } else {
            amountStrategy = balanceToken;
        }

        // Return all tokens to strategy
        ILogic(_logic).returnTokenToStorage(amountStrategy, _strategyToken);

        emit DestroyAll(_strategyXToken, amountStrategy, amountBLID);
    }

    /**
     * @notice claim distribution rewards USDT both borrow and lend swap banana token to BLID
     */
    function claimRewards() public override onlyOwnerAndAdmin {
        require(path_RewardsToBLID.length >= 2, "DF6");

        address _logic = logic;
        address _strategyXToken = strategyXToken;
        address _rewardsToken = rewardsToken;
        address _strategyStatistics = strategyStatistics;
        uint256 amountRewardsToken;

        // Call mint with 0 amount to accrueInterest
        ILogic(_logic).mint(_strategyXToken, 0);

        // Claim Rewards token
        ILogic(_logic).claim();

        // RewardsToken Price/Amount Kill Switch
        bool rewardsTokenKill = _rewardsPriceKillSwitch(
            _strategyStatistics,
            _rewardsToken
        );
        amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken).balanceOf(
                _logic
            );
        if (amountRewardsToken <= minRewardsSwapLimit) rewardsTokenKill = true;

        /**** Supply / Redeem adjustment with lending amount ****/
        // Get remained amount
        XTokenInfo memory xTokenInfo = IStrategyStatistics(_strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, _logic);
        int256 diff = int256(xTokenInfo.lendingAmount) -
            int256(xTokenInfo.totalSupply) +
            int256(xTokenInfo.borrowAmount);

        // If we need to lending,  swap Rewards to StrategyToken -> mint
        if (diff > 0 && rewardsTokenKill == false) {
            ILogic(_logic).swap(
                swapRouter_RewardsToStrategyToken,
                amountRewardsToken,
                uint256(diff),
                path_RewardsToStrategyToken,
                false,
                swapType_RewardsToStrategyToken
            );
            ILogic(_logic).mint(_strategyXToken, uint256(diff));
        }

        // swap Rewards to BLID
        if (rewardsTokenKill == false) {
            amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken)
                .balanceOf(_logic);
            ILogic(_logic).swap(
                swapRouter_RewardsToBLID,
                amountRewardsToken,
                (amountRewardsToken * minimumBLIDPerRewardToken) / BASE,
                path_RewardsToBLID,
                true,
                swapType_RewardsToBLID
            );
        }

        // If we need to redeem, redeeom -> swap StrategyToken to BLID
        if (diff < 0) {
            ILogic(_logic).redeemUnderlying(_strategyXToken, uint256(0 - diff));
            ILogic(_logic).swap(
                swapRouter_StrategyTokenToBLID,
                uint256(0 - diff),
                0,
                path_StrategyTokenToBLID,
                true,
                swapType_StrategyTokenToBLID
            );
        }

        // Add BLID earn to storage
        uint256 amountBLID = _addEarnToStorage();

        emit ClaimRewards(amountBLID);
    }

    /**
     * @notice Frees up tokens for the user, but Storage doesn't transfer token for the user,
     * only Storage can this function, after calling this function Storage transfer
     * from Logic to user token.
     * @param amount Amount of token
     * @param token Address of token
     */
    function releaseToken(uint256 amount, address token)
        external
        override
        onlyMultiLogicProxy
    {
        address _strategyXToken = strategyXToken;
        address _logic = logic;
        uint8 _circlesCount = circlesCount;
        require(token == strategyToken, "DF13");

        // Call mint with 0 amount to accrueInterest
        ILogic(_logic).mint(_strategyXToken, 0);

        // Calculate destroy amount
        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, _logic);

        uint256 destroyAmount = (xTokenInfo.borrowAmount * amount) /
            (xTokenInfo.totalSupply - xTokenInfo.borrowAmount);

        // destruct circle
        destructCircles(_strategyXToken, _circlesCount, destroyAmount);

        // Redeem for release token
        ILogic(_logic).redeemUnderlying(_strategyXToken, amount);

        uint256 balance;

        if (token == address(0)) {
            balance = address(_logic).balance;
        } else {
            balance = IERC20Upgradeable(token).balanceOf(_logic);
        }

        if (balance < amount) {
            revert("no money");
        } else if (token == address(0)) {
            ILogic(_logic).returnETHToMultiLogicProxy(amount);
        }

        emit ReleaseToken(token, amount);
    }

    /**
     * @notice multicall to Logic
     */
    function multicall(bytes[] memory callDatas)
        public
        onlyOwnerAndAdmin
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        uint256 length = callDatas.length;
        returnData = new bytes[](length);
        for (uint256 i = 0; i < length; ) {
            (bool success, bytes memory ret) = address(logic).call(
                callDatas[i]
            );
            require(success, "F99");
            returnData[i] = ret;

            unchecked {
                ++i;
            }
        }
    }

    /*** Private Function ***/

    /**
     * @notice creates circle (borrow-lend) of the base token
     * token (of amount) should be mint before start build
     * @param xToken xToken address
     * @param amount amount to build (borrowAmount)
     * @param iterateCount the number circles to
     */
    function createCircles(
        address xToken,
        uint256 amount,
        uint8 iterateCount
    ) private {
        address _logic = logic;
        uint256 _amount = amount;

        require(amount > 0, "DF12");

        // Get collateralFactor, the maximum proportion of borrow/lend
        // apply avoidLiquidationFactor
        (, uint256 collateralFactorApplied) = _getCollateralFactor(xToken);
        require(collateralFactorApplied > 0, "DF11");

        for (uint256 i = 0; i < iterateCount; ) {
            ILogic(_logic).borrow(xToken, _amount);
            ILogic(_logic).mint(xToken, _amount);
            _amount = (_amount * collateralFactorApplied) / BASE;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice unblock all the money
     * @param xToken xToken address
     * @param _iterateCount the number circles to : maximum iterates to do, the real number might be less then iterateCount
     * @param destroyAmountLimit if > 0, stop destroy if total repay is destroyAmountLimit
     */
    function destructCircles(
        address xToken,
        uint8 _iterateCount,
        uint256 destroyAmountLimit
    ) private {
        uint256 collateralFactorApplied;
        uint8 iterateCount = _iterateCount + 3; // additional iteration to repay all borrowed
        address _logic = logic;
        uint256 _destroyAmountLimit = destroyAmountLimit;

        // Get collateralFactor, apply avoidLiquidationFactor
        (, collateralFactorApplied) = _getCollateralFactor(xToken);
        require(collateralFactorApplied > 0, "DF11");

        for (uint256 i = 0; i < iterateCount; ) {
            uint256 xTokenBalance; // balance of xToken
            uint256 borrowBalance; // balance of borrowed amount
            uint256 exchangeRateMantissa; //conversion rate from iToken to token

            // get infromation of account
            xTokenBalance = IERC20Upgradeable(xToken).balanceOf(_logic);
            borrowBalance = IiToken(xToken).borrowBalanceCurrent(_logic);
            exchangeRateMantissa = IiToken(xToken).exchangeRateStored();

            // calculates of supplied balance, divided by 10^18 to safe digits correctly
            uint256 supplyBalance = (xTokenBalance * exchangeRateMantissa) /
                BASE;

            // if nothing to repay
            if (borrowBalance == 0) {
                if (xTokenBalance > 0) {
                    // redeem and exit
                    ILogic(_logic).redeemUnderlying(xToken, supplyBalance);
                    return;
                }
            }
            // if already redeemed
            if (supplyBalance == 0) {
                return;
            }

            // calculates how much percents could be borroewed and not to be liquidated, then multiply fo supply balance to calculate the amount
            uint256 withdrawBalance = ((collateralFactorApplied -
                ((BASE * borrowBalance) / supplyBalance)) * supplyBalance) /
                BASE;

            // If we have destroylimit, redeem only limit
            if (
                destroyAmountLimit > 0 && withdrawBalance > _destroyAmountLimit
            ) {
                withdrawBalance = _destroyAmountLimit;
            }

            // if redeem tokens
            ILogic(_logic).redeemUnderlying(xToken, withdrawBalance);
            uint256 repayAmount = IERC20Upgradeable(strategyToken).balanceOf(
                _logic
            );

            // if there is something to repay
            if (repayAmount > 0) {
                // if borrow balance more then we have on account
                if (borrowBalance <= repayAmount) {
                    repayAmount = borrowBalance;
                }
                ILogic(_logic).repayBorrow(xToken, repayAmount);
            }

            // Stop destroy if destroyAmountLimit < sumRepay
            if (destroyAmountLimit > 0) {
                if (_destroyAmountLimit <= repayAmount) break;
                _destroyAmountLimit = _destroyAmountLimit - repayAmount;
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice check if strategy distroy circles
     * @return paused true : strategy is empty, false : strategy has some lending token
     */
    function _checkStrategyPaused() private view returns (bool paused) {
        address _strategyXToken = strategyXToken;
        if (_strategyXToken == address(0)) return true;

        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, logic);

        if (xTokenInfo.totalSupply > 0 || xTokenInfo.borrowAmount > 0) {
            paused = false;
        } else {
            paused = true;
        }
    }

    /**
     * @notice get CollateralFactor from market
     * Apply avoidLiquidationFactor
     * @param xToken : address of xToken
     * @return collateralFactor decimal = 18
     */
    function _getCollateralFactor(address xToken)
        private
        view
        returns (uint256 collateralFactor, uint256 collateralFactorApplied)
    {
        // get collateralFactor from market
        (collateralFactor, , , , , , ) = IComptrollerDForce(comptroller)
            .markets(xToken);

        // Apply avoidLiquidationFactor to collateralFactor
        collateralFactorApplied =
            collateralFactor -
            avoidLiquidationFactor *
            10**16;
    }

    /**
     * @notice Send all BLID to storage
     * @return amountBLID BLID amount
     */
    function _addEarnToStorage() private returns (uint256 amountBLID) {
        address _logic = logic;
        amountBLID = IERC20Upgradeable(blid).balanceOf(_logic);
        if (amountBLID > 0) {
            ILogic(_logic).addEarnToStorage(amountBLID);
        }
    }

    /**
     * @notice Process RewardsTokenPrice kill switch
     * @param _strategyStatistics : stratgyStatistics
     * @param _rewardsToken : rewardsToken
     * @return killSwitch true : DF price should be protected, false : DF price is ok
     */
    function _rewardsPriceKillSwitch(
        address _strategyStatistics,
        address _rewardsToken
    ) private returns (bool killSwitch) {
        RewardsTokenPriceInfo
            memory _rewardsTokenPriceInfo = rewardsTokenPriceInfo;
        killSwitch = false;

        // Calculate delta
        uint256 latestAnswer = IStrategyStatistics(_strategyStatistics)
            .getRewardsTokenPrice(comptroller, _rewardsToken);
        int256 delta = int256(_rewardsTokenPriceInfo.latestAnswer) -
            int256(latestAnswer);
        if (delta < 0) delta = 0 - delta;

        // Check deviation
        if (
            block.timestamp == _rewardsTokenPriceInfo.timestamp ||
            _rewardsTokenPriceInfo.latestAnswer == 0
        ) {
            delta = 0;
        } else {
            delta =
                (delta * (1 ether) * 100) /
                (int256(_rewardsTokenPriceInfo.latestAnswer) *
                    (int256(block.timestamp) -
                        int256(_rewardsTokenPriceInfo.timestamp)));
        }
        if (uint256(delta) > rewardsTokenPriceDeviationLimit) {
            killSwitch = true;
        }

        // Keep current status
        rewardsTokenPriceInfo.latestAnswer = latestAnswer;
        rewardsTokenPriceInfo.timestamp = block.timestamp;
    }
}

contract DForceStrategyOld is UpgradeableBase, IStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct RewardsTokenPriceInfo {
        uint256 latestAnswer;
        uint256 timestamp;
    }

    uint256 internal constant DECIMALS = 18;
    uint256 internal constant BASE = 10**DECIMALS;

    address public logic;
    address public blid;
    address public strategyXToken;
    address public comptroller;
    address public rewardsToken;

    // Strategy Parameter
    uint8 public circlesCount;
    uint8 public avoidLiquidationFactor;

    uint256 private minStorageAvailable;
    uint256 public borrowRateMin;
    uint256 public borrowRateMax;

    address public multiLogicProxy;
    address public strategyStatistics;

    // RewardsTokenPrice kill switch
    uint256 public rewardsTokenPriceDeviationLimit; // percentage, decimal = 18
    RewardsTokenPriceInfo private rewardsTokenPriceInfo;

    // Swap Rewards to BLID
    address public swapRouter_RewardsToBLID;
    address[] public path_RewardsToBLID;
    uint8 public swapType_RewardsToBLID; // 0 : pancakeswap, 1: uniswapV3

    // Swap Rewards to StrategyToken
    address public swapRouter_RewardsToStrategyToken;
    address[] public path_RewardsToStrategyToken;
    uint8 public swapType_RewardsToStrategyToken;

    // Swap StrategyToken to BLID
    address public swapRouter_StrategyTokenToBLID;
    address[] public path_StrategyTokenToBLID;
    uint8 public swapType_StrategyTokenToBLID;

    uint256 minimumBLIDPerRewardToken;
    uint256 minRewardsSwapLimit;
    address public strategyToken;

    event SetBLID(address blid);
    event SetCirclesCount(uint8 circlesCount);
    event SetAvoidLiquidationFactor(uint8 avoidLiquidationFactor);
    event SetMinRewardsSwapLimit(uint256 _minRewardsSwapLimit);
    event SetStrategyXToken(address strategyXToken);
    event SetMinStorageAvailable(uint256 minStorageAvailable);
    event SetRebalanceParameter(uint256 borrowRateMin, uint256 borrowRateMax);
    event SetRewardsTokenPriceDeviationLimit(uint256 deviationLimit);
    event SetRewardsTokenPriceInfo(uint256 latestAnser, uint256 timestamp);
    event BuildCircle(address token, uint256 amount, uint256 circlesCount);
    event DestroyCircle(
        address token,
        uint256 circlesCount,
        uint256 destroyAmountLimit
    );
    event DestroyAll(address token, uint256 destroyAmount, uint256 blidAmount);
    event ClaimRewards(uint256 amount);
    event UseToken(address token, uint256 amount);
    event ReleaseToken(address token, uint256 amount);

    function __DForceStrategy_init(address _comptroller, address _logic)
        public
        initializer
    {
        UpgradeableBase.initialize();
        comptroller = _comptroller;
        rewardsToken = IDistributionDForce(
            IComptrollerDForce(comptroller).rewardDistributor()
        ).rewardToken();
        logic = _logic;

        rewardsTokenPriceDeviationLimit = (1 ether) / uint256(86400); // limit is 1% within 1 day
        minRewardsSwapLimit = 20 * (1 ether); // 1.5 USD is required
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyMultiLogicProxy() {
        require(msg.sender == multiLogicProxy, "DF1");
        _;
    }

    modifier onlyStrategyPaused() {
        require(_checkStrategyPaused(), "DF2");
        _;
    }

    /*** Public Initialize Function ***/

    /**
     * @notice Set blid in contract
     * @param _blid Address of BLID
     */
    function setBLID(address _blid) external onlyOwner {
        require(blid == address(0), "DF3");
        blid = _blid;
        emit SetBLID(_blid);
    }

    /**
     * @notice Set MultiLogicProxy, you can call the function once
     * @param _multiLogicProxy Address of Multilogic Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        require(multiLogicProxy == address(0), "DF5");
        multiLogicProxy = _multiLogicProxy;
    }

    /**
     * @notice Set StrategyStatistics
     * @param _strategyStatistics Address of StrategyStatistics
     */
    function setStrategyStatistics(address _strategyStatistics)
        external
        onlyOwner
    {
        strategyStatistics = _strategyStatistics;

        // Save RewardsTokenPriceInfo
        rewardsTokenPriceInfo.latestAnswer = IStrategyStatistics(
            _strategyStatistics
        ).getRewardsTokenPrice(comptroller, rewardsToken);
        rewardsTokenPriceInfo.timestamp = block.timestamp;
    }

    /**
     * @notice Set circlesCount
     * @param _circlesCount Count number
     */
    function setCirclesCount(uint8 _circlesCount) external onlyOwner {
        circlesCount = _circlesCount;

        emit SetCirclesCount(_circlesCount);
    }

    /**
     * @notice Set min Rewards swap limit
     * @param _minRewardsSwapLimit minimum swap amount for rewards token
     */
    function setMinRewardsSwapLimit(uint256 _minRewardsSwapLimit)
        external
        onlyOwner
    {
        minRewardsSwapLimit = _minRewardsSwapLimit;

        emit SetMinRewardsSwapLimit(_minRewardsSwapLimit);
    }

    /**
     * @notice Set Rewards -> BLID swap information
     * @param swapRouter : address of swap Router
     * @param path path to rewards to BLID
     * @param swapType 0 : pancakeswap, 1 : uniswapV3
     * @param _minimumBLIDPerRewardToken minimum BLID for RewardsToken
     */
    function setRewardsToBLID(
        address swapRouter,
        address[] calldata path,
        uint8 swapType,
        uint256 _minimumBLIDPerRewardToken
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "DF6");
        require(path[0] == rewardsToken, "DF7");
        require(path[length - 1] == blid, "DF8");

        swapRouter_RewardsToBLID = swapRouter;
        path_RewardsToBLID = new address[](length);
        for (uint256 i = 0; i < length; ) {
            path_RewardsToBLID[i] = path[i];

            unchecked {
                ++i;
            }
        }

        swapType_RewardsToBLID = swapType;
        minimumBLIDPerRewardToken = _minimumBLIDPerRewardToken;
    }

    /**
     * @notice Set Rewards to StrategyToken swap information
     * @param swapRouter : address of swap Router
     * @param path path to rewards to BLID
     * @param swapType 0 : pancakeswap, 1 : uniswapV3
     */
    function setRewardsToStrategyToken(
        address swapRouter,
        address[] calldata path,
        uint8 swapType
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "DF6");
        require(path[0] == rewardsToken, "DF7");
        require(path[length - 1] == strategyToken, "DF8");

        swapRouter_RewardsToStrategyToken = swapRouter;
        path_RewardsToStrategyToken = new address[](length);
        for (uint256 i = 0; i < length; ) {
            path_RewardsToStrategyToken[i] = path[i];

            unchecked {
                ++i;
            }
        }

        swapType_RewardsToStrategyToken = swapType;
    }

    /**
     * @notice Set StrategyToken to BLID swap information
     * @param swapRouter : address of swap Router
     * @param path path to rewards to BLID
     * @param swapType 0 : pancakeswap, 1 : uniswapV3
     */
    function setStrategyTokenToBLID(
        address swapRouter,
        address[] calldata path,
        uint8 swapType
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "DF6");
        require(path[0] == strategyToken, "DF7");
        require(path[length - 1] == blid, "DF8");

        swapRouter_StrategyTokenToBLID = swapRouter;
        path_StrategyTokenToBLID = new address[](length);
        for (uint256 i = 0; i < length; ) {
            path_StrategyTokenToBLID[i] = path[i];

            unchecked {
                ++i;
            }
        }

        swapType_StrategyTokenToBLID = swapType;
    }

    /**
     * @notice Set avoidLiquidationFactor
     * @param _avoidLiquidationFactor factor value (0-99)
     */
    function setAvoidLiquidationFactor(uint8 _avoidLiquidationFactor)
        external
        onlyOwner
    {
        require(_avoidLiquidationFactor < 100, "DF4");

        avoidLiquidationFactor = _avoidLiquidationFactor;
        emit SetAvoidLiquidationFactor(_avoidLiquidationFactor);
    }

    /**
     * @notice Set MinStorageAvailable
     * @param amount amount of min storage available for token using : decimals = token decimals
     */
    function setMinStorageAvailable(uint256 amount) external onlyOwner {
        minStorageAvailable = amount;
        emit SetMinStorageAvailable(amount);
    }

    /**
     * @notice Set RebalanceParameter
     * @param _borrowRateMin borrowRate min : decimals = 18
     * @param _borrowRateMax borrowRate max : deciamls = 18
     */
    function setRebalanceParameter(
        uint256 _borrowRateMin,
        uint256 _borrowRateMax
    ) external onlyOwner {
        require(_borrowRateMin < BASE, "DF4");
        require(_borrowRateMax < BASE, "DF4");
        borrowRateMin = _borrowRateMin;
        borrowRateMax = _borrowRateMax;
        emit SetRebalanceParameter(_borrowRateMin, _borrowRateMin);
    }

    /**
     * @notice Set RewardsTokenPriceDeviationLimit
     * @param _rewardsTokenPriceDeviationLimit price Diviation per seccond limit
     */
    function setRewardsTokenPriceDeviationLimit(
        uint256 _rewardsTokenPriceDeviationLimit
    ) external onlyOwner {
        rewardsTokenPriceDeviationLimit = _rewardsTokenPriceDeviationLimit;

        emit SetRewardsTokenPriceDeviationLimit(
            _rewardsTokenPriceDeviationLimit
        );
    }

    /**
     * @notice Force update rewardsTokenPrice
     * @param latestAnswer new latestAnswer
     */
    function setRewardsTokenPrice(uint256 latestAnswer) external onlyOwner {
        rewardsTokenPriceInfo.latestAnswer = latestAnswer;
        rewardsTokenPriceInfo.timestamp = block.timestamp;

        emit SetRewardsTokenPriceInfo(latestAnswer, block.timestamp);
    }

    /*** Public Strategy Function ***/

    /**
     * @notice Check wheather storageAvailable is bigger enough
     * @return canUseToken true : useToken is possible
     */
    function checkUseToken() public view override returns (bool canUseToken) {
        if (
            IMultiLogicProxy(multiLogicProxy).getTokenAvailable(
                strategyToken,
                logic
            ) < minStorageAvailable
        ) {
            canUseToken = false;
        } else {
            canUseToken = true;
        }
    }

    /**
     * @notice Check whether borrow rate is ok
     * @return canRebalance true : rebalance is possible, borrow rate is abnormal
     */
    function checkRebalance() public view override returns (bool canRebalance) {
        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(strategyXToken, logic);

        // If no lending, can't rebalance
        if (xTokenInfo.totalSupply == 0) return false;

        uint256 borrowRate = xTokenInfo.borrowLimit == 0
            ? 0
            : (xTokenInfo.borrowAmount * BASE) / xTokenInfo.borrowLimit;

        if (borrowRate > borrowRateMax || borrowRate < borrowRateMin) {
            canRebalance = true;
        } else {
            canRebalance = false;
        }
    }

    /**
     * @notice Set StrategyXToken
     * Add XToken in Contract and approve token
     * entermarkets to lending system
     * @param _xToken Address of XToken
     */
    function setStrategyXToken(address _xToken)
        external
        onlyOwner
        onlyStrategyPaused
    {
        require(strategyXToken != _xToken, "DF10");

        address _logic = logic;
        address _strategyToken = IiToken(_xToken).underlying();

        // Add token/iToken to Logic
        ILogic(_logic).addXTokens(_strategyToken, _xToken);

        // Entermarkets with token/iToken
        address[] memory tokens = new address[](1);
        tokens[0] = _xToken;
        ILogic(_logic).enterMarkets(tokens);

        strategyXToken = _xToken;
        strategyToken = _strategyToken;
        emit SetStrategyXToken(_xToken);
    }

    function useToken() external override {
        address _logic = logic;
        address _strategyXToken = strategyXToken;
        address _strategyToken = strategyToken;

        // Check if storageAvailable is bigger enough
        uint256 availableAmount = IMultiLogicProxy(multiLogicProxy)
            .getTokenAvailable(_strategyToken, _logic);
        if (availableAmount < minStorageAvailable) return;

        // Take token from storage
        ILogic(_logic).takeTokenFromStorage(availableAmount, _strategyToken);

        // Mint
        ILogic(_logic).mint(_strategyXToken, availableAmount);

        emit UseToken(_strategyToken, availableAmount);
    }

    function rebalance() external override {
        address _logic = logic;
        address _strategyXToken = strategyXToken;
        uint8 _circlesCount = circlesCount;
        uint256 _borrowRateMin = borrowRateMin;
        uint256 _borrowRateMax = borrowRateMax;
        uint256 targetBorrowRate = _borrowRateMin +
            (_borrowRateMax - _borrowRateMin) /
            2;
        (
            uint256 collateralFactor,
            uint256 collateralFactorApplied
        ) = _getCollateralFactor(_strategyXToken);

        // Call mint with 0 amount to accrueInterest
        ILogic(_logic).mint(_strategyXToken, 0);

        // get statistics
        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, _logic);

        uint256 borrowRate = xTokenInfo.borrowLimit == 0
            ? 0
            : (xTokenInfo.borrowAmount * BASE) / xTokenInfo.borrowLimit;

        // Build
        if (borrowRate < _borrowRateMin) {
            uint256 Y = 0;
            uint256 accLTV = BASE;
            for (uint256 i = 0; i < _circlesCount; ) {
                Y = Y + accLTV;
                accLTV = (accLTV * collateralFactorApplied) / BASE;
                unchecked {
                    ++i;
                }
            }
            uint256 buildAmount = ((((((xTokenInfo.totalSupply *
                targetBorrowRate) / BASE) * collateralFactor) / BASE) -
                xTokenInfo.borrowAmount) * BASE) /
                ((Y * (BASE - (targetBorrowRate * collateralFactor) / BASE)) /
                    BASE);
            if (buildAmount > 0) {
                createCircles(_strategyXToken, buildAmount, _circlesCount);

                emit BuildCircle(_strategyXToken, buildAmount, _circlesCount);
            }
        }

        // Destroy
        if (borrowRate > _borrowRateMax) {
            uint256 LTV = collateralFactor; // don't apply avoidLiquidationFactor
            uint256 destroyAmount = ((xTokenInfo.borrowAmount -
                (((xTokenInfo.totalSupply * targetBorrowRate) / BASE) * LTV) /
                BASE) * BASE) / (BASE - (targetBorrowRate * LTV) / BASE);

            destructCircles(_strategyXToken, _circlesCount, destroyAmount);

            emit DestroyCircle(_strategyXToken, _circlesCount, destroyAmount);
        }
    }

    /**
     * @notice Destroy circle strategy
     * destroy circle and return all tokens to storage
     */
    function destroyAll() external override onlyOwnerAndAdmin {
        address _logic = logic;
        address _rewardsToken = rewardsToken;
        address _strategyXToken = strategyXToken;
        address _strategyToken = strategyToken;
        uint256 amountBLID = 0;

        // Destruct circle
        destructCircles(_strategyXToken, circlesCount, 0);

        // Claim Rewards token
        ILogic(_logic).claim();

        // RewardsToken Price/Amount Kill Switch
        bool rewardsTokenKill = _rewardsPriceKillSwitch(
            strategyStatistics,
            _rewardsToken
        );
        uint256 amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken)
            .balanceOf(_logic);
        if (amountRewardsToken <= minRewardsSwapLimit) rewardsTokenKill = true;

        // swap rewardsToken to StrategyToken
        if (
            rewardsTokenKill == false &&
            IERC20MetadataUpgradeable(_rewardsToken).balanceOf(_logic) > 0
        ) {
            ILogic(_logic).swap(
                swapRouter_RewardsToStrategyToken,
                IERC20MetadataUpgradeable(_rewardsToken).balanceOf(_logic),
                0,
                path_RewardsToStrategyToken,
                true,
                swapType_RewardsToStrategyToken
            );
        }

        // Get strategy amount, current balance of underlying
        uint256 amountStrategy = IMultiLogicProxy(multiLogicProxy)
            .getTokenTaken(_strategyToken, _logic);
        uint256 balanceToken = IERC20Upgradeable(_strategyToken).balanceOf(
            _logic
        );

        // If we have extra, swap StrategyToken to BLID
        if (balanceToken > amountStrategy) {
            ILogic(_logic).swap(
                swapRouter_StrategyTokenToBLID,
                balanceToken - amountStrategy,
                0,
                path_StrategyTokenToBLID,
                true,
                swapType_StrategyTokenToBLID
            );

            // Add BLID earn to storage
            amountBLID = _addEarnToStorage();
        } else {
            amountStrategy = balanceToken;
        }

        // Return all tokens to strategy
        ILogic(_logic).returnTokenToStorage(amountStrategy, _strategyToken);

        emit DestroyAll(_strategyXToken, amountStrategy, amountBLID);
    }

    /**
     * @notice claim distribution rewards USDT both borrow and lend swap banana token to BLID
     */
    function claimRewards() public override onlyOwnerAndAdmin {
        require(path_RewardsToBLID.length >= 2, "DF6");

        address _logic = logic;
        address _strategyXToken = strategyXToken;
        address _rewardsToken = rewardsToken;
        address _strategyStatistics = strategyStatistics;
        uint256 amountRewardsToken;

        // Call mint with 0 amount to accrueInterest
        ILogic(_logic).mint(_strategyXToken, 0);

        // Claim Rewards token
        ILogic(_logic).claim();

        // RewardsToken Price/Amount Kill Switch
        bool rewardsTokenKill = _rewardsPriceKillSwitch(
            _strategyStatistics,
            _rewardsToken
        );
        amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken).balanceOf(
                _logic
            );
        if (amountRewardsToken <= minRewardsSwapLimit) rewardsTokenKill = true;

        /**** Supply / Redeem adjustment with lending amount ****/
        // Get remained amount
        XTokenInfo memory xTokenInfo = IStrategyStatistics(_strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, _logic);
        int256 diff = int256(xTokenInfo.lendingAmount) -
            int256(xTokenInfo.totalSupply) +
            int256(xTokenInfo.borrowAmount);

        // If we need to lending,  swap Rewards to StrategyToken -> mint
        if (diff > 0 && rewardsTokenKill == false) {
            ILogic(_logic).swap(
                swapRouter_RewardsToStrategyToken,
                amountRewardsToken,
                uint256(diff),
                path_RewardsToStrategyToken,
                false,
                swapType_RewardsToStrategyToken
            );
            ILogic(_logic).mint(_strategyXToken, uint256(diff));
        }

        // swap Rewards to BLID
        if (rewardsTokenKill == false) {
            amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken)
                .balanceOf(_logic);
            ILogic(_logic).swap(
                swapRouter_RewardsToBLID,
                amountRewardsToken,
                (amountRewardsToken * minimumBLIDPerRewardToken) / BASE,
                path_RewardsToBLID,
                true,
                swapType_RewardsToBLID
            );
        }

        // If we need to redeem, redeeom -> swap StrategyToken to BLID
        if (diff < 0) {
            ILogic(_logic).redeemUnderlying(_strategyXToken, uint256(0 - diff));
            ILogic(_logic).swap(
                swapRouter_StrategyTokenToBLID,
                uint256(0 - diff),
                0,
                path_StrategyTokenToBLID,
                true,
                swapType_StrategyTokenToBLID
            );
        }

        // Add BLID earn to storage
        uint256 amountBLID = _addEarnToStorage();

        emit ClaimRewards(amountBLID);
    }

    /**
     * @notice Frees up tokens for the user, but Storage doesn't transfer token for the user,
     * only Storage can this function, after calling this function Storage transfer
     * from Logic to user token.
     * @param amount Amount of token
     * @param token Address of token
     */
    function releaseToken(uint256 amount, address token)
        external
        override
        onlyMultiLogicProxy
    {
        address _strategyXToken = strategyXToken;
        address _logic = logic;
        uint8 _circlesCount = circlesCount;
        require(token == strategyToken, "DF13");

        // Call mint with 0 amount to accrueInterest
        ILogic(_logic).mint(_strategyXToken, 0);

        // Calculate destroy amount
        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, _logic);

        uint256 destroyAmount = (xTokenInfo.borrowAmount * amount) /
            (xTokenInfo.totalSupply - xTokenInfo.borrowAmount);

        // destruct circle
        destructCircles(_strategyXToken, _circlesCount, destroyAmount);

        // Redeem for release token
        ILogic(_logic).redeemUnderlying(_strategyXToken, amount);

        uint256 balance;

        if (token == address(0)) {
            balance = address(_logic).balance;
        } else {
            balance = IERC20Upgradeable(token).balanceOf(_logic);
        }

        if (balance < amount) {
            revert("no money");
        } else if (token == address(0)) {
            ILogic(_logic).returnETHToMultiLogicProxy(amount);
        }

        emit ReleaseToken(token, amount);
    }

    /**
     * @notice multicall to Logic
     */
    function multicall(bytes[] memory callDatas)
        public
        onlyOwnerAndAdmin
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        uint256 length = callDatas.length;
        returnData = new bytes[](length);
        for (uint256 i = 0; i < length; ) {
            (bool success, bytes memory ret) = address(logic).call(
                callDatas[i]
            );
            require(success, "F99");
            returnData[i] = ret;

            unchecked {
                ++i;
            }
        }
    }

    /*** Private Function ***/

    /**
     * @notice creates circle (borrow-lend) of the base token
     * token (of amount) should be mint before start build
     * @param xToken xToken address
     * @param amount amount to build (borrowAmount)
     * @param iterateCount the number circles to
     */
    function createCircles(
        address xToken,
        uint256 amount,
        uint8 iterateCount
    ) private {
        address _logic = logic;
        uint256 _amount = amount;

        require(amount > 0, "DF12");

        // Get collateralFactor, the maximum proportion of borrow/lend
        // apply avoidLiquidationFactor
        (, uint256 collateralFactorApplied) = _getCollateralFactor(xToken);
        require(collateralFactorApplied > 0, "DF11");

        for (uint256 i = 0; i < iterateCount; ) {
            ILogic(_logic).borrow(xToken, _amount);
            ILogic(_logic).mint(xToken, _amount);
            _amount = (_amount * collateralFactorApplied) / BASE;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice unblock all the money
     * @param xToken xToken address
     * @param _iterateCount the number circles to : maximum iterates to do, the real number might be less then iterateCount
     * @param destroyAmountLimit if > 0, stop destroy if total repay is destroyAmountLimit
     */
    function destructCircles(
        address xToken,
        uint8 _iterateCount,
        uint256 destroyAmountLimit
    ) private {
        uint256 collateralFactorApplied;
        uint8 iterateCount = _iterateCount + 3; // additional iteration to repay all borrowed
        address _logic = logic;
        uint256 _destroyAmountLimit = destroyAmountLimit;

        // Get collateralFactor, apply avoidLiquidationFactor
        (, collateralFactorApplied) = _getCollateralFactor(xToken);
        require(collateralFactorApplied > 0, "DF11");

        for (uint256 i = 0; i < iterateCount; ) {
            uint256 xTokenBalance; // balance of xToken
            uint256 borrowBalance; // balance of borrowed amount
            uint256 exchangeRateMantissa; //conversion rate from iToken to token

            // get infromation of account
            xTokenBalance = IERC20Upgradeable(xToken).balanceOf(_logic);
            borrowBalance = IiToken(xToken).borrowBalanceCurrent(_logic);
            exchangeRateMantissa = IiToken(xToken).exchangeRateStored();

            // calculates of supplied balance, divided by 10^18 to safe digits correctly
            uint256 supplyBalance = (xTokenBalance * exchangeRateMantissa) /
                BASE;

            // if nothing to repay
            if (borrowBalance == 0) {
                if (xTokenBalance > 0) {
                    // redeem and exit
                    ILogic(_logic).redeemUnderlying(xToken, supplyBalance);
                    return;
                }
            }
            // if already redeemed
            if (supplyBalance == 0) {
                return;
            }

            // calculates how much percents could be borroewed and not to be liquidated, then multiply fo supply balance to calculate the amount
            uint256 withdrawBalance = ((collateralFactorApplied -
                ((BASE * borrowBalance) / supplyBalance)) * supplyBalance) /
                BASE;

            // If we have destroylimit, redeem only limit
            if (
                destroyAmountLimit > 0 && withdrawBalance > _destroyAmountLimit
            ) {
                withdrawBalance = _destroyAmountLimit;
            }

            // if redeem tokens
            ILogic(_logic).redeemUnderlying(xToken, withdrawBalance);
            uint256 repayAmount = IERC20Upgradeable(strategyToken).balanceOf(
                _logic
            );

            // if there is something to repay
            if (repayAmount > 0) {
                // if borrow balance more then we have on account
                if (borrowBalance <= repayAmount) {
                    repayAmount = borrowBalance;
                }
                ILogic(_logic).repayBorrow(xToken, repayAmount);
            }

            // Stop destroy if destroyAmountLimit < sumRepay
            if (destroyAmountLimit > 0) {
                if (_destroyAmountLimit <= repayAmount) break;
                _destroyAmountLimit = _destroyAmountLimit - repayAmount;
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice check if strategy distroy circles
     * @return paused true : strategy is empty, false : strategy has some lending token
     */
    function _checkStrategyPaused() private view returns (bool paused) {
        address _strategyXToken = strategyXToken;
        if (_strategyXToken == address(0)) return true;

        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, logic);

        if (xTokenInfo.totalSupply > 0 || xTokenInfo.borrowAmount > 0) {
            paused = false;
        } else {
            paused = true;
        }
    }

    /**
     * @notice get CollateralFactor from market
     * Apply avoidLiquidationFactor
     * @param xToken : address of xToken
     * @return collateralFactor decimal = 18
     */
    function _getCollateralFactor(address xToken)
        private
        view
        returns (uint256 collateralFactor, uint256 collateralFactorApplied)
    {
        // get collateralFactor from market
        (collateralFactor, , , , , , ) = IComptrollerDForce(comptroller)
            .markets(xToken);

        // Apply avoidLiquidationFactor to collateralFactor
        collateralFactorApplied =
            collateralFactor -
            avoidLiquidationFactor *
            10**16;
    }

    /**
     * @notice Send all BLID to storage
     * @return amountBLID BLID amount
     */
    function _addEarnToStorage() private returns (uint256 amountBLID) {
        address _logic = logic;
        amountBLID = IERC20Upgradeable(blid).balanceOf(_logic);
        if (amountBLID > 0) {
            ILogic(_logic).addEarnToStorage(amountBLID);
        }
    }

    /**
     * @notice Process RewardsTokenPrice kill switch
     * @param _strategyStatistics : stratgyStatistics
     * @param _rewardsToken : rewardsToken
     * @return killSwitch true : DF price should be protected, false : DF price is ok
     */
    function _rewardsPriceKillSwitch(
        address _strategyStatistics,
        address _rewardsToken
    ) private returns (bool killSwitch) {
        RewardsTokenPriceInfo
            memory _rewardsTokenPriceInfo = rewardsTokenPriceInfo;
        killSwitch = false;

        // Calculate delta
        uint256 latestAnswer = IStrategyStatistics(_strategyStatistics)
            .getRewardsTokenPrice(comptroller, _rewardsToken);
        int256 delta = int256(_rewardsTokenPriceInfo.latestAnswer) -
            int256(latestAnswer);
        if (delta < 0) delta = 0 - delta;

        // Check deviation
        if (
            block.timestamp == _rewardsTokenPriceInfo.timestamp ||
            _rewardsTokenPriceInfo.latestAnswer == 0
        ) {
            delta = 0;
        } else {
            delta =
                (delta * (1 ether) * 100) /
                (int256(_rewardsTokenPriceInfo.latestAnswer) *
                    (int256(block.timestamp) -
                        int256(_rewardsTokenPriceInfo.timestamp)));
        }
        if (uint256(delta) > rewardsTokenPriceDeviationLimit) {
            killSwitch = true;
        }

        // Keep current status
        rewardsTokenPriceInfo.latestAnswer = latestAnswer;
        rewardsTokenPriceInfo.timestamp = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IXToken {
    function mint(uint256 mintAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function underlying() external view returns (address);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function interestRateModel() external view returns (address);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function getCash() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalBorrows() external view returns (uint256);
}

interface IXTokenETH {
    function mint() external payable;

    function borrow(uint256 borrowAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./OwnableUpgradeableVersionable.sol";
import "./OwnableUpgradeableAdminable.sol";

abstract contract UpgradeableBase is
    Initializable,
    OwnableUpgradeableVersionable,
    OwnableUpgradeableAdminable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    function initialize() public onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IComptrollerDForce {
    function enterMarkets(address[] calldata iTokens)
        external
        returns (bool[] memory);

    function markets(address iTokenAddress)
        external
        view
        returns (
            uint256 _collateralFactor,
            uint256 _borrowFactor,
            uint256 _borrowCapacity,
            uint256 _supplyCapacity,
            bool mintPaused,
            bool redeemPaused,
            bool borrowPaused
        );

    function getAlliTokens() external view returns (address[] memory);

    function calcAccountEquity(address)
        external
        view
        returns (
            uint256 equity,
            uint256 shortfall,
            uint256 collaterals,
            uint256 borrows
        );

    function priceOracle() external view returns (address);

    function hasiToken(address _iToken) external view returns (bool);

    function rewardDistributor() external view returns (address);
}

interface IDistributionDForce {
    function claimReward(address[] memory _holders, address[] memory _iTokens)
        external;

    function rewardToken() external view returns (address);

    function reward(address _account) external view returns (uint256);

    function distributionBorrowState(address _asset)
        external
        view
        returns (uint256 index, uint256 block);

    function distributionBorrowerIndex(address _asset, address _account)
        external
        view
        returns (uint256);

    function distributionSupplyState(address _asset)
        external
        view
        returns (uint256 index, uint256 block);

    function distributionSupplierIndex(address _asset, address _account)
        external
        view
        returns (uint256);

    function distributionSupplySpeed(address _asset)
        external
        view
        returns (uint256);

    function distributionSpeed(address _asset) external view returns (uint256);
}

interface IiToken {
    function mint(address recipient, uint256 mintAmount) external;

    function borrow(uint256 borrowAmount) external;

    function redeemUnderlying(address from, uint256 redeemAmount) external;

    function repayBorrow(uint256 repayAmount) external;

    function borrowBalanceCurrent(address account) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);

    function name() external view returns (string memory);

    function isiToken() external view returns (bool);
}

interface IiTokenETH {
    function mint(address recipient) external payable;

    function repayBorrow() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IStrategyVenus {
    function farmingPair() external view returns (address);

    function lendToken() external;

    function build(uint256 usdAmount) external;

    function destroy(uint256 percentage) external;

    function claimRewards(uint8 mode) external;
}

interface IStrategy {
    function releaseToken(uint256 amount, address token) external; // onlyMultiLogicProxy

    function logic() external view returns (address);

    function useToken() external; // Automation

    function rebalance() external; // Automation

    function checkUseToken() external view returns (bool); // Automation

    function checkRebalance() external view returns (bool); // Automation

    function destroyAll() external; // onlyOwnerAdmin

    function claimRewards() external; // onlyOwnerAdmin
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMultiLogicProxy {
    function releaseToken(uint256 amount, address token) external;

    function takeToken(uint256 amount, address token) external;

    function addEarn(uint256 amount, address blidToken) external;

    function returnToken(uint256 amount, address token) external;

    function setLogicTokenAvailable(
        uint256 amount,
        address token,
        uint256 deposit_withdraw
    ) external;

    function getTokenAvailable(address _token, address _logicAddress)
        external
        view
        returns (uint256);

    function getTokenTaken(address _token, address _logicAddress)
        external
        view
        returns (uint256);

    function getUsedTokensStorage() external view returns (address[] memory);

    function multiStrategyLength() external view returns (uint256);

    function multiStrategyName(uint256) external view returns (string memory);

    function strategyInfo(string memory)
        external
        view
        returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
struct XTokenInfo {
    string symbol;
    address xToken;
    uint256 totalSupply;
    uint256 totalSupplyUSD;
    uint256 lendingAmount;
    uint256 lendingAmountUSD;
    uint256 borrowAmount;
    uint256 borrowAmountUSD;
    uint256 borrowLimit;
    uint256 borrowLimitUSD;
    uint256 underlyingBalance;
    uint256 priceUSD;
}

struct XTokenAnalytics {
    string symbol;
    address platformAddress;
    string underlyingSymbol;
    address underlyingAddress;
    uint256 underlyingDecimals;
    uint256 underlyingPrice;
    uint256 totalSupply;
    uint256 totalSupplyUSD;
    uint256 totalBorrows;
    uint256 totalBorrowsUSD;
    uint256 liquidity;
    uint256 collateralFactor;
    uint256 borrowApy;
    uint256 borrowRewardsApy;
    uint256 supplyApy;
    uint256 supplyRewardsApy;
}

struct StrategyStatistics {
    XTokenInfo[] xTokensStatistics;
    WalletInfo[] walletStatistics;
    uint256 lendingEarnedUSD;
    uint256 totalSupplyUSD;
    uint256 totalBorrowUSD;
    uint256 totalBorrowLimitUSD;
    uint256 borrowRate;
    uint256 storageAvailableUSD;
    int256 totalAmountUSD;
}

struct FarmingPairInfo {
    uint256 index;
    address lpToken;
    uint256 farmingAmount;
    uint256 rewardsAmount;
    uint256 rewardsAmountUSD;
}

struct WalletInfo {
    string symbol;
    address token;
    uint256 balance;
    uint256 balanceUSD;
}

struct PriceInfo {
    address token;
    uint256 priceUSD;
}

interface IStrategyStatistics {
    function getXTokenInfo(address _asset, address comptroller)
        external
        view
        returns (XTokenAnalytics memory);

    function getXTokensInfo(address comptroller)
        external
        view
        returns (XTokenAnalytics[] memory);

    function getStrategyStatistics(address logic)
        external
        view
        returns (StrategyStatistics memory statistics);

    function getStrategyXTokenInfo(address xToken, address logic)
        external
        view
        returns (XTokenInfo memory tokenInfo);

    function getRewardsTokenPrice(address comptroller, address rewardsToken)
        external
        view
        returns (uint256 priceUSD);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ILogicContract {
    function addXTokens(
        address token,
        address xToken,
        uint8 leadingTokenType
    ) external;

    function approveTokenForSwap(address token) external;

    function claim(address[] calldata xTokens, uint8 leadingTokenType) external;

    function mint(address xToken, uint256 mintAmount)
        external
        returns (uint256);

    function borrow(
        address xToken,
        uint256 borrowAmount,
        uint8 leadingTokenType
    ) external returns (uint256);

    function repayBorrow(address xToken, uint256 repayAmount) external;

    function redeemUnderlying(address xToken, uint256 redeemAmount)
        external
        returns (uint256);

    function swapExactTokensForTokens(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOut,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function addLiquidityETH(
        address swap,
        address token,
        uint256 amountTokenDesired,
        uint256 amountETHDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address swap,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH);

    function addEarnToStorage(uint256 amount) external;

    function enterMarkets(address[] calldata xTokens, uint8 leadingTokenType)
        external
        returns (uint256[] memory);

    function returnTokenToStorage(uint256 amount, address token) external;

    function takeTokenFromStorage(uint256 amount, address token) external;

    function returnETHToMultiLogicProxy(uint256 amount) external;

    function deposit(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdraw(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function returnToken(uint256 amount, address token) external; // for StorageV2 only
}

/************* New Architecture *************/

interface ILendingSystem {
    function enterMarkets(address[] calldata xTokens)
        external
        returns (uint256[] memory);

    function claim() external;

    function mint(address xToken, uint256 mintAmount)
        external
        returns (uint256);

    function borrow(address xToken, uint256 borrowAmount)
        external
        returns (uint256);

    function repayBorrow(address xToken, uint256 repayAmount)
        external
        returns (uint256);

    function redeemUnderlying(address xToken, uint256 redeemAmount)
        external
        returns (uint256);
}

interface IFarming {
    function addLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function farmingDeposit(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function farmingWithdraw(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;
}

interface ISwapLogic {
    function swap(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool exactInput,
        uint8 swapType
    ) external payable returns (uint256[] memory amounts);
}

interface ILogic is ISwapLogic, ILendingSystem {
    function addXTokens(address token, address xToken) external;

    function addEarnToStorage(uint256 amount) external;

    function returnTokenToStorage(uint256 amount, address token) external;

    function takeTokenFromStorage(uint256 amount, address token) external;

    function returnETHToMultiLogicProxy(uint256 amount) external;

    function multiLogicProxy() external view returns (address);

    function comptroller() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function approveTokenForSwap(address _swap, address token) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableAdminable is OwnableUpgradeable {
    address private _admin;

    event SetAdmin(address admin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "OA1");
        _;
    }

    modifier onlyOwnerAndAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "OA2");
        _;
    }

    /**
     * @notice Set admin
     * @param newAdmin Addres of new admin
     */
    function setAdmin(address newAdmin) external onlyOwner {
        _admin = newAdmin;
        emit SetAdmin(newAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableVersionable is OwnableUpgradeable {
    string private _version;
    string private _purpose;

    event UpgradeVersion(string version, string purpose);

    function getVersion() external view returns (string memory) {
        return _version;
    }

    function getPurpose() external view returns (string memory) {
        return _purpose;
    }

    /**
     * @notice Set version and purpose
     * @param version Version string, ex : 1.2.0
     * @param purpose Purpose string
     */
    function upgradeVersion(string memory version, string memory purpose)
        external
        onlyOwner
    {
        require(bytes(version).length != 0, "OV1");

        _version = version;
        _purpose = purpose;

        emit UpgradeVersion(version, purpose);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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