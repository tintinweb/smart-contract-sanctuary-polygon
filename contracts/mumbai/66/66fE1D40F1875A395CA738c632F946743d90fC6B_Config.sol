/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IAdminConfig.sol



pragma solidity 0.6.12;


interface IAdminConfig {
    function updateAdmin(address admin_) external returns(bool);
}
// File: contracts/interfaces/IConfig.sol


pragma solidity 0.6.12;

interface IConfig {

    function getAdmin() external view returns(address);
    function getAaveTimeThresold() external view returns(uint);
    function getBlacklistedAsset(address asset_) external view returns(bool);

    function setDisputeConfig(uint escrowAmount_,uint requirePaymentForRaiseDispute_,uint requirePaymentForJury_) external returns(bool);
    function getDisputeConfig() external view returns(uint,uint,uint);

    function setWalletAddress(address developer_,address escrow_) external returns(bool);
    function getWalletAddress() external view returns(address,address);

    function setFeeDeductionConfig(
        uint256 platformFees_,
        uint256 after_full_swap_treasury_wallet_transfer_,
        uint256 after_full_swap_without_trend_setter_treasury_wallet_transfer_,
        uint256 dbeth_swap_amount_with_trend_setter_,
        uint256 dbeth_swap_amount_without_trend_setter_,
        uint256 bet_trend_setter_reward_,
        uint256 pool_distribution_amount_,
        uint256 burn_amount_
    ) external returns(bool);

    function setAaveFeeConfig(
        uint aave_apy_bet_winner_distrubution_,
        uint aave_apy_bet_looser_distrubution_
    ) external returns(bool);

    function getFeeDeductionConfig() external view returns(uint,uint,uint,uint,uint,uint,uint,uint);

    function getAaveConfig() external view returns(uint,uint);
    
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

    function getAddresses() external view returns(address,address,address,address,address,address);

    function setPairAddresses(address tokenA_,address tokenB_) external returns(bool);

    function getPairAddress(address tokenA_) external view returns(address,address);

    function getUniswapRouterAddress() external view returns(address);

    function getAaveRecovery() external view returns(address,address,address);


}
// File: contracts/Config.sol


pragma solidity 0.6.12;



contract Config is IConfig {

    uint256 public Platform_Fees;
    uint256 public After_Full_Swap_Treasury_Wallet_Transfer;
    uint256 public After_Full_Swap_Without_Trend_Setter_Treasury_Wallet_Transfer;
    uint256 public DBETH_Swap_Amount_With_Trend_Setter;
    uint256 public DBETH_Swap_Amount_WithOut_Trend_Setter;
    uint256 public Bet_Trend_Setter_Reward;
    uint256 public Pool_Distribution_Amount;
    uint256 public Burn_Amount;

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

    uint public escrowAmount;
    uint public requirePaymentForRaiseDispute;
    uint public requirePaymentForJury;

    constructor(address admin_) public {
        admin = admin_;
    }

    modifier isAdmin() {
        require(msg.sender == admin, "Caller Is Not Admin");
        _;
    }

    mapping (address => address) public tokenPair;

    mapping(address => bool) public blackListedAssets;

    function setAdmin(address admin_,address foundationFactory_) external isAdmin returns(bool) {
        admin = admin_;
        IAdminConfig(foundationFactory_).updateAdmin(admin_);

        return true;
    }

    function setDisputeConfig(uint escrowAmount_,uint requirePaymentForRaiseDispute_,uint requirePaymentForJury_) external override returns(bool) {
        escrowAmount = escrowAmount_;
        requirePaymentForRaiseDispute = requirePaymentForRaiseDispute_;
        requirePaymentForJury = requirePaymentForJury_;

        return true;
    }

    function getDisputeConfig() external view override returns(uint,uint,uint) {
        return (escrowAmount,requirePaymentForRaiseDispute,requirePaymentForJury);
    }

    function setWalletAddress(address developer_,address escrow_) external override returns(bool) {
        developerAddress = developer_;
        escrowAccount = escrow_;
        return true;
    }

    function getWalletAddress() external view override returns(address,address) {
        return (developerAddress,escrowAccount);
    }

    function getAdmin() public override view returns(address) {
        return developerAddress;
    }
 
    function setBlacklistedAsset(address asset_) public returns(bool) {
        require(!blackListedAssets[asset_],"Already Blacklisted");
        blackListedAssets[asset_] = true;
    }

    function getBlacklistedAsset(address asset_) public override view returns(bool) {
        return blackListedAssets[asset_];
    }

    function setAaveThreshold(uint threshold_) public isAdmin returns(bool) {
        aaveTimeThreshold = threshold_;
        return true;
    }

    function getAaveTimeThresold() public view override returns(uint) {
        return aaveTimeThreshold;
    }

    event FeeDeductionConfigUpdated(uint,uint,uint,uint,uint,uint,uint,uint);
    event AaveFeeConfigUpdated(uint,uint);

    function setFeeDeductionConfig(
        uint256 platformFees_,
        uint256 after_full_swap_treasury_wallet_transfer_,
        uint256 after_full_swap_without_trend_setter_treasury_wallet_transfer_,
        uint256 dbeth_swap_amount_with_trend_setter_,
        uint256 dbeth_swap_amount_without_trend_setter_,
        uint256 bet_trend_setter_reward_,
        uint256 pool_distribution_amount_,
        uint256 burn_amount_
    ) public override isAdmin returns(bool) {
        Platform_Fees = platformFees_;
        After_Full_Swap_Treasury_Wallet_Transfer = after_full_swap_treasury_wallet_transfer_;
        After_Full_Swap_Without_Trend_Setter_Treasury_Wallet_Transfer = after_full_swap_without_trend_setter_treasury_wallet_transfer_;
        DBETH_Swap_Amount_With_Trend_Setter = dbeth_swap_amount_with_trend_setter_;
        DBETH_Swap_Amount_WithOut_Trend_Setter = dbeth_swap_amount_without_trend_setter_;
        Bet_Trend_Setter_Reward = bet_trend_setter_reward_;
        Pool_Distribution_Amount = pool_distribution_amount_;
        Burn_Amount = burn_amount_;

        emit FeeDeductionConfigUpdated(platformFees_,after_full_swap_treasury_wallet_transfer_,after_full_swap_without_trend_setter_treasury_wallet_transfer_,dbeth_swap_amount_with_trend_setter_,dbeth_swap_amount_without_trend_setter_,bet_trend_setter_reward_,pool_distribution_amount_,burn_amount_);

        return true;
    }

    function setAaveFeeConfig(
        uint aave_apy_bet_winner_distrubution_,
        uint aave_apy_bet_looser_distrubution_
    ) public override isAdmin returns(bool) {
        Aave_APY_Bet_Winner_Distribution = aave_apy_bet_winner_distrubution_;
        Aave_APY_Bet_Looser_Distribution = aave_apy_bet_looser_distrubution_;

        emit AaveFeeConfigUpdated(aave_apy_bet_winner_distrubution_,aave_apy_bet_looser_distrubution_);

        return true;
    }

    function getFeeDeductionConfig() public override view returns(uint,uint,uint,uint,uint,uint,uint,uint) {
        return(Platform_Fees,After_Full_Swap_Treasury_Wallet_Transfer,After_Full_Swap_Without_Trend_Setter_Treasury_Wallet_Transfer,DBETH_Swap_Amount_With_Trend_Setter,DBETH_Swap_Amount_WithOut_Trend_Setter,Bet_Trend_Setter_Reward,Pool_Distribution_Amount,Burn_Amount);
    }

    function getAaveConfig() public override view returns(uint,uint) {
        return(Aave_APY_Bet_Winner_Distribution,Aave_APY_Bet_Looser_Distribution);
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
    }

    function getAddresses() external override view returns(address,address,address,address,address,address) {
        return (LendingPoolAddressProvider,WETHGateway,aWMATIC,aDAI,UniswapV2Factory,UniswapV2Router);
    }

    function setPairAddresses(address tokenA_,address tokenB_) external override returns(bool) {
        tokenPair[tokenA_] = tokenB_;

        return true;
    }

    function getPairAddress(address tokenA_) external view override returns(address,address) {
        return (tokenA_,tokenPair[tokenA_]);
    }

    function getUniswapRouterAddress() external view override returns(address) {
        return UniswapV2Router;
    }

    function getAaveRecovery() external view override returns(address,address,address) {
        return (LendingPoolAddressProvider,WETHGateway,aWMATIC);
    }

}