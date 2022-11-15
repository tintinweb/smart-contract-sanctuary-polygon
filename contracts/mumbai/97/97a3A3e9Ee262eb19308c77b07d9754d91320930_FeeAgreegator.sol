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

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IFeeAgreegator {
    function calculateAaveDistribution(uint256 amount_, address configAddress_)
        external
        view
        returns (
            uint256 calculatedAmountForWiner_,
            uint256 calculatedAmountForLooser_
        );

    function calculatePlatformFeeDeduction(
        uint256 amount_,
        address configAddress_
    ) external view returns (uint256 calculatedAmount_);

    function calculateAfterFullSwapFeeDistribution(
        uint256 receivedSwappedAmount_,
        bool isTrendSetterAvailable,
        address configAddress_
    ) external view returns (uint256 calculatedAmountForTreasury_);

    function calculateAfterDBETHSwapFeeDistribution(
        uint256 receivedSwappedDBETHAmount_,
        bool isTrendSetterAvailable,
        address configAddress_
    )
        external
        view
        returns (
            uint256 calculatedAmountForTrendSetter_,
            uint256 calculatedAmountForPoolDistribution_,
            uint256 calculatedAmountForBurn_
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "../../Interfaces/IConfig.sol";
import "../../Interfaces/IFeeAgreegator.sol";

contract FeeAgreegator is IFeeAgreegator {
    function calculateAaveDistribution(uint256 amount_, address configAddress_)
        public
        view
        override
        returns (
            uint256 calculatedAmountForWiner_,
            uint256 calculatedAmountForLooser_
        )
    {
        (
            uint256 Aave_APY_Bet_Winner_Distribution,
            uint256 Aave_APY_Bet_Looser_Distribution
        ) = IConfig(configAddress_).getAaveConfig();

        calculatedAmountForWiner_ += Aave_APY_Bet_Winner_Distribution * amount_;
        calculatedAmountForWiner_ = calculatedAmountForWiner_ / 100;
        calculatedAmountForLooser_ +=
            Aave_APY_Bet_Looser_Distribution *
            amount_;
        calculatedAmountForLooser_ = calculatedAmountForLooser_ / 100;
    }

    function calculatePlatformFeeDeduction(
        uint256 amount_,
        address configAddress_
    ) public view override returns (uint256 calculatedAmount_) {
        uint256 platformFees_;
        (platformFees_, , , , , , , , , ) = IConfig(configAddress_)
            .getFeeDeductionConfig();
        calculatedAmount_ = amount_ * platformFees_;
        calculatedAmount_ = calculatedAmount_ / 100;

        return calculatedAmount_;
    }

    function calculateAfterFullSwapFeeDistribution(
        uint256 receivedSwappedAmount_,
        bool isTrendSetterAvailable,
        address configAddress_
    ) public view override returns (uint256 calculatedAmountForTreasury_) {
        uint256 after_full_swap_treasury_wallet_transfer_;
        uint256 after_full_swap_without_trend_setter_treasury_wallet_transfer_;
        (
            ,
            after_full_swap_treasury_wallet_transfer_,
            after_full_swap_without_trend_setter_treasury_wallet_transfer_,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = IConfig(configAddress_).getFeeDeductionConfig();
        if (isTrendSetterAvailable == false) {
            calculatedAmountForTreasury_ +=
                (receivedSwappedAmount_ *
                    (after_full_swap_without_trend_setter_treasury_wallet_transfer_ +
                        after_full_swap_treasury_wallet_transfer_)) /
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
        uint256 receivedSwappedDBETHAmount_,
        bool isTrendSetterAvailable,
        address configAddress_
    )
        public
        view
        override
        returns (
            uint256 calculatedAmountForTrendSetter_,
            uint256 calculatedAmountForPoolDistribution_,
            uint256 calculatedAmountForBurn_
        )
    {
        uint256 bet_trend_setter_reward_;
        uint256 pool_distribution_amount_;
        uint256 burn_amount_;
        uint256 pool_distribution_amount_without_trendsetter_;
        uint256 burn_amount_without_trendsetter;
        (
            ,
            ,
            ,
            ,
            ,
            bet_trend_setter_reward_,
            pool_distribution_amount_,
            burn_amount_,
            pool_distribution_amount_without_trendsetter_,
            burn_amount_without_trendsetter
        ) = IConfig(configAddress_).getFeeDeductionConfig();
        uint256 _availableAmount = receivedSwappedDBETHAmount_;
        if (isTrendSetterAvailable) {
            calculatedAmountForTrendSetter_ =
                (_availableAmount * bet_trend_setter_reward_) /
                100;
            // _availableAmount -= calculatedAmountForTrendSetter_;
            calculatedAmountForPoolDistribution_ =
                (_availableAmount * pool_distribution_amount_) /
                100;
            // _availableAmount -= calculatedAmountForPoolDistribution_;
            calculatedAmountForBurn_ = (_availableAmount * burn_amount_) / 100;
        } else {
            calculatedAmountForPoolDistribution_ =
                (_availableAmount *
                    pool_distribution_amount_without_trendsetter_) /
                100;
            calculatedAmountForBurn_ =
                (_availableAmount * burn_amount_without_trendsetter) /
                100;
        }

        return (
            calculatedAmountForTrendSetter_,
            calculatedAmountForPoolDistribution_,
            calculatedAmountForBurn_
        );
    }
}