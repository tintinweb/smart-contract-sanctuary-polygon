import "./IBalancerVault.sol";
import "./IBalancerVault.sol";

contract BalancerPriceQuery {

    IBalancerVault public immutable VAULT = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);


    function query(
        bytes32 poolId,
        address fromAsset,
        address toAsset,
        uint256 amount,
        address user) external returns (int256[] memory) {

        IBalancerVault.SwapKind swapKind = IBalancerVault.SwapKind.GIVEN_IN;

        IBalancerVault.BatchSwapStep memory step = IBalancerVault.BatchSwapStep(
            poolId,
            0,
            1,
            amount,
            ""
        );

        IBalancerVault.BatchSwapStep[] memory steps = new  IBalancerVault.BatchSwapStep[](1);
        steps[0] = step;

        address[] memory assets = new address[](2);
        assets[0] = fromAsset;
        assets[1] = toAsset;

        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(
            user, true, payable(user), true
        );

        return VAULT.queryBatchSwap(
            swapKind,
            steps,
            assets,
            funds
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBalancerVault {
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function getPool(bytes32 poolId)
        external
        view
        returns (address, uint8);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

}