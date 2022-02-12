// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminModule {

    function listPool(
        address pool_,
        uint minTick_,
        uint128 borrowLimitNormal_,
        uint128 borrowLimitExtended_,
        uint priceSlippage_,
        uint24[] memory tickSlippages_,
        uint24[] memory timeAgos_,
        address[] memory borrowMarkets_,
        uint256[] memory borrowLimits_,
        address[] memory oracles_
    ) external {}

    function updateMinTick(address pool_, uint minTick_) public {}

    function addBorrowMarket(
        address pool_,
        address[] memory tokens_
    ) public {}

    function updatePoolBorrowLimit(address pool_, address[] memory tokens_, uint256[] memory borrowLimits_) public {}

    function updateBorrowLimit(address pool_, uint128 normal_, uint128 extended_) public {}

    function enableBorrow(address pool_, address token_) external {}

    function disableBorrow(address pool_, address token_) external {}

    function updatePriceSlippage(address pool_, uint priceSlippage_) public {}

    function updateTicksCheck(
        address pool_,
        uint24[] memory tickSlippages_,
        uint24[] memory timeAgos_
    ) public {}

    function addChainlinkOracle(address[] memory tokens_, address[] memory oracles_) public {}

    function setupRewards(address token_, address rewardtoken_, uint128 rewardAmount_, uint64 startTime_, uint64 duration_) external {}

}

contract UserModule1 {
    
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata
    ) external returns (bytes4) {}

    function withdraw(uint96 NFTID_) external {}

    function transferPosition(uint96 NFTID_, address to_) public {}

}

contract UserModule2 {

    function getFeeAccruedWrapper(uint256 NFTID_, address poolAddr_)
        public
        view
        returns (uint256 amount0_, uint256 amount1_)
    {}

    function getNetNFTLiquidity(
        address poolAddr_,
        int24 tickLower_,
        int24 tickUpper_,
        uint128 liquidity_
    ) public view returns (uint256 amount0Total_, uint256 amount1Total_) {}

    function getNetNFTDebt(uint256 NFTID_, address poolAddr_)
        public
        view
        returns (uint256[] memory borrowBalances_)
    {}

    function getOverallPosition(uint256 NFTID_)
        public
        view
        returns (
            address poolAddr_,
            address token0_,
            address token1_,
            uint128 liquidity_,
            uint256 totalSupplyInUsd_,
            uint256 totalNormalSupplyInUsd_,
            uint256 totalBorrowInUsd_,
            uint256 totalNormalBorrowInUsd_
        )
    {}

    function updateRewards(address token_) public returns (uint[] memory newRewardPrices_) {}

    function updateNftReward(uint96 NFTID_, address token_) public returns (uint[] memory updatedRewards_) {}

    function updateNftRewardsForAllMarkets(uint96 NFTID_, address pool_) public {}

    function addLiquidity(
        uint96 NFTID_,
        uint256 amount0_,
        uint256 amount1_,
        uint256 minAmount0_,
        uint256 minAmount1_,
        uint256 deadline_
    ) external returns (uint256 exactAmount0_, uint256 exactAmount1_) {}

    function removeLiquidity(
        uint96 NFTID_,
        uint256 liquidity_,
        uint256 amount0Min_,
        uint256 amount1Min_
    )
        external
        returns (uint256 exactAmount0_, uint256 exactAmount1_)
    {}

    function borrow(
        uint96 NFTID_,
        address token_,
        uint256 amount_
    ) external {}

    function payback(
        uint96 NFTID_,
        address token_,
        uint256 amount_
    ) external returns (uint exactAmount_) {}

    function collectFees(uint96 NFTID_)
        external
        returns (uint256 amount0_, uint256 amount1_)
    {}

    function depositNFT(uint96 NFTID_)
        external
    {}

    function withdrawNFT(uint96 NFTID_) external {}

    function stake(
        address rewardToken_,
        uint256 startTime_,
        uint256 endTime_,
        address refundee_,
        uint96 NFTID_
    ) external {}

    function unstake(
        address rewardToken_,
        uint256 startTime_,
        uint256 endTime_,
        address refundee_,
        uint96 NFTID_
    ) external {}

    function claimStakingRewards(
        address rewardToken_,
        uint96 NFTID_
    ) public returns (uint256 rewards_) {}

     struct BorrowingReward {
        address token;
        address[] rewardTokens;
        uint[] rewardAmounts;
    }

    function claimBorrowingRewards(uint96 NFTID_) public returns (BorrowingReward[] memory) {}

    function claimBorrowingRewards(uint96 NFTID_, address token_) public returns (address[] memory rewardTokens_, uint[] memory rewardAmounts_) {}

}

contract ReadModule {

    function poolEnabled(address pool_) external view returns (bool) {}

    function position(address owner_, uint NFTID_) external view returns (bool) {}

    function nftOwner(uint96 NFTID_) external view returns (address) {}

    function nftLink(address user_) external view returns (uint96 first_, uint96 last_, uint64 count_) {}

    function nftList(uint96 NFTID_) external view returns (uint48 prev_, uint48 next_, address owner_) {}

    function isStaked(uint NFTID_) external view returns (bool) {}

    function stakeCount(uint NFTID_) external view returns (uint) {}

    function minTick(address pool_) external view returns (uint) {}

    function borrowBalRaw(uint NFTID_, address token_) external view returns (uint) {}

    function borrowAllowed(address pool_, address token_) external view returns (bool) {}

    function poolMarkets(address pool_) external view returns (address[] memory) {}

    function poolRawBorrow(address pool_, address token_) external view returns (uint256) {}

    function poolBorrowLimit(address pool_, address token_) external view returns (uint256) {}

    function borrowLimit(address pool_) external view returns (uint128 normal_, uint128 extended_) {}

    function priceSlippage(address pool_) external view returns (uint) {}

    struct TickCheck {
        uint24 tickSlippage1;
        uint24 secsAgo1;
        uint24 tickSlippage2;
        uint24 secsAgo2;
        uint24 tickSlippage3;
        uint24 secsAgo3;
        uint24 tickSlippage4;
        uint24 secsAgo4;
        uint24 tickSlippage5;
        uint24 secsAgo5;
    }

    function tickCheck(address pool_) external view returns (TickCheck memory tickCheck_) {}

    function rewardTokens(address token_) external view returns (address[] memory) {}

    struct RewardRate {
        uint128 rewardRate; // reward rate per sec
        uint64 startTime; // reward start time
        uint64 endTime; // reward end time
    }

    function rewardRate(address token_, address rewardToken_) external view returns (RewardRate memory) {}

    function rewardPrice(address token_, address rewardToken_) external view returns (uint rewardPrice_, uint lastUpdateTime_) {}

    function nftRewards(uint96 NFTID_, address token_, address rewardToken_) external view returns (uint lastRewardPrice_, uint reward_) {}

}

contract Protocol3DummyImplementation is AdminModule, UserModule1, UserModule2, ReadModule {

    receive() external payable {}
    
}