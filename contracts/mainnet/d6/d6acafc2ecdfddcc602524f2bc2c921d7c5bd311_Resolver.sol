/**
 *Submitted for verification at polygonscan.com on 2022-07-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPoolAddressesProvider {
    function getPool() external view returns (address);
}

interface IPool {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

contract Resolver {
    IPool internal pool =
        IPool(
            IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb)
                .getPool()
        );

    mapping(address => uint256) customHfMap;

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        (
            totalCollateralBase,
            totalDebtBase,
            availableBorrowsBase,
            currentLiquidationThreshold,
            ltv,
            healthFactor
        ) = pool.getUserAccountData(user);

        if (customHfMap[user] != 0) healthFactor = customHfMap[user];
    }

    function updateCustomHf(address user, uint256 hf) external {
        customHfMap[user] = hf;
    }
}