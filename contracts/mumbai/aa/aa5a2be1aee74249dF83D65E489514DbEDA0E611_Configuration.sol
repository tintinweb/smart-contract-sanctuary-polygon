// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IAdminConfig {
    function updateAdmin(address admin_) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IConfig {

    function getLatestVersion() external view returns (uint);

    function getAdmin() external view returns (address);

    function getAaveTimeThresold() external view returns (uint256);

    function getBlacklistedAsset(address asset_) external view returns (bool);

    function setDisputeConfig(
        uint256 escrowAmount_,
        uint256 requirePaymentForJury_
    ) external returns (bool);

    function getDisputeConfig() external view returns (uint256, uint256);

    function setWalletAddress(address developer_, address escrow_)
        external
        returns (bool);

    function getWalletAddress() external view returns (address, address);

    function getTokensPerStrike(uint256 strike_)
        external
        view
        returns (uint256);

    function getJuryTokensShare(uint256 strike_, uint256 version_)
        external
        view
        returns (uint256);

    function setFeeDeductionConfig(
        uint256 platformFees_,
        uint256 after_full_swap_treasury_wallet_transfer_,
        uint256 after_full_swap_without_trend_setter_treasury_wallet_transfer_,
        uint256 dbeth_swap_amount_with_trend_setter_,
        uint256 dbeth_swap_amount_without_trend_setter_,
        uint256 bet_trend_setter_reward_,
        uint256 pool_distribution_amount_,
        uint256 burn_amount_,
        uint256 pool_distribution_amount_without_trendsetter_,
        uint256 burn_amount_without_trendsetter
    ) external returns (bool);

    function setAaveFeeConfig(
        uint256 aave_apy_bet_winner_distrubution_,
        uint256 aave_apy_bet_looser_distrubution_
    ) external returns (bool);

    function getFeeDeductionConfig()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getAaveConfig() external view returns (uint256, uint256);

    function setAddresses(
        address lendingPoolAddressProvider_,
        address wethGateway_,
        address aWMATIC_,
        address aDAI_,
        address uniswapV2Factory,
        address uniswapV2Router
    )
        external
        returns (
            address,
            address,
            address,
            address
        );

    function getAddresses()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            address
        );

    function setPairAddresses(address tokenA_, address tokenB_)
        external
        returns (bool);

    function getPairAddress(address tokenA_)
        external
        view
        returns (address, address);

    function getUniswapRouterAddress() external view returns (address);

    function getAaveRecovery()
        external
        view
        returns (
            address,
            address,
            address
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "../Interfaces/IConfig.sol";
import "../Interfaces/IAdminConfig.sol";

contract Configuration is IConfig {
    uint256 public Platform_Fees;
    uint256 public After_Full_Swap_Treasury_Wallet_Transfer;
    uint256
        public After_Full_Swap_Without_Trend_Setter_Treasury_Wallet_Transfer;
    uint256 public DBETH_Swap_Amount_With_Trend_Setter;
    uint256 public DBETH_Swap_Amount_WithOut_Trend_Setter;
    uint256 public Bet_Trend_Setter_Reward;
    uint256 public Pool_Distribution_Amount;
    uint256 public Pool_Distribution_Amount_Without_TrendSetter;
    uint256 public Burn_Amount;
    uint256 public Burn_Amount_Without_TrendSetter;

    uint256 public Aave_APY_Bet_Winner_Distribution;
    uint256 public Aave_APY_Bet_Looser_Distribution;

    address public LendingPoolAddressProvider;
    address public WETHGateway;
    address public aWMATIC;
    address public aDAI;
    address public UniswapV2Factory;
    address public UniswapV2Router;

    address public admin;

    uint256 public aaveTimeThreshold;

    address public developerAddress;
    address public escrowAccount;

    uint256 public escrowAmount;
    uint256 public requirePaymentForRaiseDispute;
    uint256 public requirePaymentForJury;

    constructor(address admin_) public {
        require(admin_ != address(0), "NON ZERO ADDRESS");
        admin = admin_;
    }

    modifier isAdmin() {
        require(tx.origin == admin, "Caller Is Not Admin");
        _;
    }

    uint256 public tokenStatisticsVersionCounter;

    struct TokenStatistics {
        mapping(uint256 => uint256) juryTokensSharePerStrike;
    }

    mapping(address => address) public tokenPair;

    mapping(address => bool) public blackListedAssets;

    mapping(uint256 => uint256) public tokensPerStrike;

    mapping(uint256 => uint256) public juryTokensSharePerStrike;

    mapping(uint256 => TokenStatistics) internal tokenStatisticsVersion;

    //mapping(address => uint) public tokenStatisticsVersionWithUser;

    function getLatestVersion() external view override returns (uint256) {
        return tokenStatisticsVersionCounter;
    }

    function setTokensPerStrike(uint256 strike_, uint256 requiredPayment)
        external
        returns (bool)
    {
        tokensPerStrike[strike_] = requiredPayment;

        return true;
    }

    function setJuryTokensSharePerStrike(
        uint256[] memory strike_,
        uint256[] memory requiredShare_
    ) external returns (bool) {
        tokenStatisticsVersionCounter += 1;
        for (uint256 i = 0; i < strike_.length; i++) {
            tokenStatisticsVersion[tokenStatisticsVersionCounter]
                .juryTokensSharePerStrike[strike_[i]] = requiredShare_[i];
        }

        return true;
    }

    function getTokensPerStrike(uint256 strike_)
        external
        view
        override
        returns (uint256)
    {
        return tokensPerStrike[strike_];
    }

    function getJuryTokensShare(uint256 strike_, uint256 version_)
        external
        view
        override
        returns (uint256)
    {
        return
            tokenStatisticsVersion[version_].juryTokensSharePerStrike[strike_];
    }

    function setAdmin(address admin_, address foundationFactory_)
        external
        isAdmin
        returns (bool)
    {
        require(admin_ != address(0), "NON ZERO ADDRESS");
        admin = admin_;
        IAdminConfig(foundationFactory_).updateAdmin(admin_);

        return true;
    }

    function setDisputeConfig(
        uint256 escrowAmount_,
        uint256 requirePaymentForJury_
    ) external override returns (bool) {
        escrowAmount = escrowAmount_;
        requirePaymentForJury = requirePaymentForJury_;

        return true;
    }

    function getDisputeConfig()
        external
        view
        override
        returns (uint256, uint256)
    {
        return (escrowAmount, requirePaymentForJury);
    }

    function setWalletAddress(address developer_, address escrow_)
        external
        override
        isAdmin
        returns (bool)
    {
        developerAddress = developer_;
        escrowAccount = escrow_;
        return true;
    }

    function getWalletAddress()
        external
        view
        override
        returns (address, address)
    {
        return (developerAddress, escrowAccount);
    }

    function getAdmin() public view override returns (address) {
        return developerAddress;
    }

    function setBlacklistedAsset(address asset_) public isAdmin returns (bool) {
        //require(!blackListedAssets[asset_],"Already Blacklisted");
        blackListedAssets[asset_] = !blackListedAssets[asset_];

        return true;
    }

    function getBlacklistedAsset(address asset_)
        public
        view
        override
        returns (bool)
    {
        return blackListedAssets[asset_];
    }

    function setAaveThreshold(uint256 threshold_)
        public
        isAdmin
        returns (bool)
    {
        aaveTimeThreshold = threshold_;
        return true;
    }

    function getAaveTimeThresold() public view override returns (uint256) {
        return aaveTimeThreshold;
    }

    event FeeDeductionConfigUpdated(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );
    event AaveFeeConfigUpdated(uint256, uint256);

    function setFeeDeductionConfig(
        uint256 platformFees_,
        uint256 after_full_swap_treasury_wallet_transfer_,
        uint256 after_full_swap_without_trend_setter_treasury_wallet_transfer_,
        uint256 dbeth_swap_amount_with_trend_setter_,
        uint256 dbeth_swap_amount_without_trend_setter_,
        uint256 bet_trend_setter_reward_,
        uint256 pool_distribution_amount_,
        uint256 burn_amount_,
        uint256 pool_distribution_amount_without_trendsetter_,
        uint256 burn_amount_without_trendsetter
    ) public override isAdmin returns (bool) {
        Platform_Fees = platformFees_;
        After_Full_Swap_Treasury_Wallet_Transfer = after_full_swap_treasury_wallet_transfer_;
        After_Full_Swap_Without_Trend_Setter_Treasury_Wallet_Transfer = after_full_swap_without_trend_setter_treasury_wallet_transfer_;
        DBETH_Swap_Amount_With_Trend_Setter = dbeth_swap_amount_with_trend_setter_;
        DBETH_Swap_Amount_WithOut_Trend_Setter = dbeth_swap_amount_without_trend_setter_;
        Bet_Trend_Setter_Reward = bet_trend_setter_reward_;
        Pool_Distribution_Amount = pool_distribution_amount_;
        Burn_Amount = burn_amount_;
        Pool_Distribution_Amount_Without_TrendSetter = pool_distribution_amount_without_trendsetter_;
        Burn_Amount_Without_TrendSetter = burn_amount_without_trendsetter;

        emit FeeDeductionConfigUpdated(
            platformFees_,
            after_full_swap_treasury_wallet_transfer_,
            after_full_swap_without_trend_setter_treasury_wallet_transfer_,
            dbeth_swap_amount_with_trend_setter_,
            dbeth_swap_amount_without_trend_setter_,
            bet_trend_setter_reward_,
            pool_distribution_amount_,
            burn_amount_,
            pool_distribution_amount_without_trendsetter_,
            burn_amount_without_trendsetter
        );

        return true;
    }

    function setAaveFeeConfig(
        uint256 aave_apy_bet_winner_distrubution_,
        uint256 aave_apy_bet_looser_distrubution_
    ) public override isAdmin returns (bool) {
        Aave_APY_Bet_Winner_Distribution = aave_apy_bet_winner_distrubution_;
        Aave_APY_Bet_Looser_Distribution = aave_apy_bet_looser_distrubution_;

        emit AaveFeeConfigUpdated(
            aave_apy_bet_winner_distrubution_,
            aave_apy_bet_looser_distrubution_
        );

        return true;
    }

    function getFeeDeductionConfig()
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            Platform_Fees,
            After_Full_Swap_Treasury_Wallet_Transfer,
            After_Full_Swap_Without_Trend_Setter_Treasury_Wallet_Transfer,
            DBETH_Swap_Amount_With_Trend_Setter,
            DBETH_Swap_Amount_WithOut_Trend_Setter,
            Bet_Trend_Setter_Reward,
            Pool_Distribution_Amount,
            Burn_Amount,
            Pool_Distribution_Amount_Without_TrendSetter,
            Burn_Amount_Without_TrendSetter
        );
    }

    function getAaveConfig() public view override returns (uint256, uint256) {
        return (
            Aave_APY_Bet_Winner_Distribution,
            Aave_APY_Bet_Looser_Distribution
        );
    }

    function setAddresses(
        address lendingPoolAddressProvider_,
        address wethGateway_,
        address aWMATIC_,
        address aDAI_,
        address uniswapV2Factory,
        address uniswapV2Router
    )
        public
        override
        returns (
            address,
            address,
            address,
            address
        )
    {
        LendingPoolAddressProvider = lendingPoolAddressProvider_;
        WETHGateway = wethGateway_;
        aWMATIC = aWMATIC_;
        aDAI = aDAI_;
        UniswapV2Factory = uniswapV2Factory;
        UniswapV2Router = uniswapV2Router;

        return (LendingPoolAddressProvider,WETHGateway,uniswapV2Factory,uniswapV2Router);
    }

    function getAddresses()
        external
        view
        override
        returns (
            address,
            address,
            address,
            address,
            address,
            address
        )
    {
        return (
            LendingPoolAddressProvider,
            WETHGateway,
            aWMATIC,
            aDAI,
            UniswapV2Factory,
            UniswapV2Router
        );
    }

    function setPairAddresses(address tokenA_, address tokenB_)
        external
        override
        returns (bool)
    {
        tokenPair[tokenA_] = tokenB_;

        return true;
    }

    function getPairAddress(address tokenA_)
        external
        view
        override
        returns (address, address)
    {
        return (tokenA_, tokenPair[tokenA_]);
    }

    function getUniswapRouterAddress()
        external
        view
        override
        returns (address)
    {
        return UniswapV2Router;
    }

    function getAaveRecovery()
        external
        view
        override
        returns (
            address,
            address,
            address
        )
    {
        return (LendingPoolAddressProvider, WETHGateway, aWMATIC);
    }
}