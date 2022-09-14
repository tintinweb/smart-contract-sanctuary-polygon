/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// SPDX-License-Identifier: MIT
// File: contracts/Interfaces/IFeeAgreegator.sol


pragma solidity >=0.6.12;

interface   IFeeAgreegator {
    function calculateAaveDistribution(uint amount_,address configAddress_) external view returns(uint calculatedAmountForWiner_,uint calculatedAmountForLooser_);
    function calculatePlatformFeeDeduction(uint amount_,address configAddress_)
        external
        view
        returns (uint calculatedAmount_);
    function calculateAfterFullSwapFeeDistribution(
        uint receivedSwappedAmount_,
        bool isTrendSetterAvailable,
        address configAddress_
    )
        external
        view
        returns (
            uint calculatedAmountForTreasury_);
    function calculateAfterDBETHSwapFeeDistribution(
        uint receivedSwappedDBETHAmount_,
        bool isTrendSetterAvailable,
        address configAddress_
    )
        external
        view
        returns (
            uint calculatedAmountForTrendSetter_,
            uint calculatedAmountForPoolDistribution_,
            uint calculatedAmountForBurn_
        );
    
}
// File: contracts/Interfaces/IConfig.sol


pragma solidity >=0.6.12;

interface IConfig {

    function getAdmin() external view returns(address);
    function getAaveTimeThresold() external view returns(uint);
    function getBlacklistedAsset(address asset_) external view returns(bool);

    function setDisputeConfig(uint escrowAmount_,uint requirePaymentForJury_) external returns(bool);
    function getDisputeConfig() external view returns(uint,uint);

    function setWalletAddress(address developer_,address escrow_) external returns(bool);
    function getWalletAddress() external view returns(address,address);

    function getTokensPerStrike(uint strike_) external view returns(uint);
    function getJuryTokensShare(uint strike_) external view returns(uint);

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
    ) external returns(bool);

    function setAaveFeeConfig(
        uint aave_apy_bet_winner_distrubution_,
        uint aave_apy_bet_looser_distrubution_
    ) external returns(bool);

    function getFeeDeductionConfig() external view returns(uint,uint,uint,uint,uint,uint,uint,uint,uint);

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
// File: contracts/MainContractBucket/Agreegators/FeeAggregator.sol


pragma solidity >=0.6.12;



contract FeeAgreegator is  IFeeAgreegator{

    function calculateAaveDistribution(uint amount_,address configAddress_) public override view returns(uint calculatedAmountForWiner_,uint calculatedAmountForLooser_) {
        (uint256 Aave_APY_Bet_Winner_Distribution,
            uint256 Aave_APY_Bet_Looser_Distribution
        ) = IConfig(configAddress_).getAaveConfig();

        calculatedAmountForWiner_ += Aave_APY_Bet_Winner_Distribution * amount_;
        calculatedAmountForWiner_ = calculatedAmountForWiner_ / 100;
        calculatedAmountForLooser_ += Aave_APY_Bet_Looser_Distribution * amount_;
        calculatedAmountForLooser_ = calculatedAmountForLooser_ / 100; 

    }

    function calculatePlatformFeeDeduction(uint amount_,address configAddress_)
        public
        override
        view
        returns (uint calculatedAmount_)
    {
        uint256 platformFees_;
        (platformFees_,,,,,,,,
        ) = IConfig(configAddress_).getFeeDeductionConfig();
        calculatedAmount_ = amount_ * platformFees_;
        calculatedAmount_ = calculatedAmount_ / 100;

        return calculatedAmount_;
    }

    function calculateAfterFullSwapFeeDistribution(
        uint receivedSwappedAmount_,
        bool isTrendSetterAvailable,
        address configAddress_
    )
        public
        override
        view
        returns (
            uint calculatedAmountForTreasury_
        )
    {
        uint256 after_full_swap_treasury_wallet_transfer_;
        uint256 after_full_swap_without_trend_setter_treasury_wallet_transfer_;
        (,after_full_swap_treasury_wallet_transfer_,after_full_swap_without_trend_setter_treasury_wallet_transfer_,,,,,,
        ) = IConfig(configAddress_).getFeeDeductionConfig();
        if (isTrendSetterAvailable == false) {
            calculatedAmountForTreasury_ +=
                (receivedSwappedAmount_ *
                    (after_full_swap_without_trend_setter_treasury_wallet_transfer_ + after_full_swap_treasury_wallet_transfer_)) /
                100;
        } else {
            calculatedAmountForTreasury_ =
                (receivedSwappedAmount_ *
                    after_full_swap_treasury_wallet_transfer_) /
                100;
        }

        return (calculatedAmountForTreasury_);
    }

    function calculateAfterDBETHSwapFeeDistribution(
        uint receivedSwappedDBETHAmount_,
        bool isTrendSetterAvailable,
        address configAddress_
    )
        public
        override
        view
        returns (
            uint calculatedAmountForTrendSetter_,
            uint calculatedAmountForPoolDistribution_,
            uint calculatedAmountForBurn_
        )
    {
        uint256 bet_trend_setter_reward_;
        uint256 pool_distribution_amount_;
        uint256 burn_amount_;
        uint256 pool_distribution_amount_without_trendsetter_;
        (,,,,,
        bet_trend_setter_reward_,
        pool_distribution_amount_,
        burn_amount_,
        pool_distribution_amount_without_trendsetter_
        ) = IConfig(configAddress_).getFeeDeductionConfig();
        uint _availableAmount = receivedSwappedDBETHAmount_;
        if (isTrendSetterAvailable) {
            calculatedAmountForTrendSetter_ =
                (_availableAmount * bet_trend_setter_reward_) /
                100;
            // _availableAmount -= calculatedAmountForTrendSetter_;
            calculatedAmountForPoolDistribution_ =
                (_availableAmount * pool_distribution_amount_) /
                100;
            // _availableAmount -= calculatedAmountForPoolDistribution_;
            calculatedAmountForBurn_ =
                (_availableAmount * burn_amount_) /
                100;
        } else {
            calculatedAmountForPoolDistribution_ =
                (_availableAmount * pool_distribution_amount_without_trendsetter_) /
                100;
            calculatedAmountForBurn_ = calculatedAmountForPoolDistribution_;
        }

        return (
            calculatedAmountForTrendSetter_,
            calculatedAmountForPoolDistribution_,
            calculatedAmountForBurn_
        );
    }
}