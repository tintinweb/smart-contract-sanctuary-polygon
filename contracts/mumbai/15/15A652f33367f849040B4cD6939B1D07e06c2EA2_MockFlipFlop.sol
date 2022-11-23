// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

contract MockFlipFlop {

    enum FlipFlopStates {
        EpochOnGoing,
        PerformanceFeeNeedsToBeCharged,
        UserLastEpochFundsNeedsToBeRedeemed,
        SwapNeedsToTakePlace,
        SwapIsInProgress,
        InternalRatioComputationToBeDone,
        FundsToBeSendToFundamentalVaults,
        CalculateS_EAndS_U,
        MintUserShares,
        ContractIsPaused
    }

    FlipFlopStates public vaultState;

    event NextUser(address nextUser);

    function resetMockFlipFlop() external {
        vaultState = FlipFlopStates.EpochOnGoing;
    }

    function scheduleWithdrawFromFundamentalVaults() external {
        require(vaultState == FlipFlopStates.EpochOnGoing, "e24");
    }

    function withdrawFromFundamentalVaults() external {
        require(vaultState == FlipFlopStates.EpochOnGoing, "e24");
        vaultState = FlipFlopStates.PerformanceFeeNeedsToBeCharged;
    }

    function chargePerformanceFee() external {
        require(
            vaultState == FlipFlopStates.PerformanceFeeNeedsToBeCharged,
            "e31"
        );
        vaultState = FlipFlopStates.UserLastEpochFundsNeedsToBeRedeemed;
    }

    function redeemUserShares(address _startFrom)
        external
        returns (address _toContinue)
    {
        require(
            vaultState == FlipFlopStates.UserLastEpochFundsNeedsToBeRedeemed,
            "e29"
        );
        vaultState = FlipFlopStates.SwapNeedsToTakePlace;
        emit NextUser(address(0));
        vaultState = FlipFlopStates.SwapIsInProgress;
        return address(0);
    }

    function internalSwapComputationPostSwap() external {
        vaultState = FlipFlopStates.FundsToBeSendToFundamentalVaults;
    }

    function startEpoch() external {
        require(
            vaultState == FlipFlopStates.FundsToBeSendToFundamentalVaults,
            "e39"
        );
        vaultState = FlipFlopStates.CalculateS_EAndS_U;
    }

    function calculateS_E_S_U(address _startFrom)
        external
        returns (address _toContinue)
    {
        require(vaultState == FlipFlopStates.CalculateS_EAndS_U, "e40");
        vaultState = FlipFlopStates.MintUserShares;
        emit NextUser(address(0));
        return address(0);
    }

    function startMint(address _startFrom)
        external
        returns (address _toContinue)
    {
        require(vaultState == FlipFlopStates.MintUserShares, "e41");
        vaultState = FlipFlopStates.EpochOnGoing;
        emit NextUser(address(0));
        return address(0);
    }

}