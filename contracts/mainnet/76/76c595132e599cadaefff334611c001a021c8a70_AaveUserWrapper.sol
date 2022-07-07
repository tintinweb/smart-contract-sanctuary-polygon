/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.11;

interface aERC20 {
    function balanceOf(address a) external view returns(uint);
}

interface IAaveLendingPool {
    function getReservesList() external view returns(address[] memory);
    function getUserConfiguration(address user) external view returns(uint);
    function getReserveData(address asset)
        external
        view
        returns
        (
            uint256 configuration,
            uint128 liquidityIndex,
            uint128 variableBorrowIndex,
            uint128 currentLiquidityRate,
            uint128 currentVariableBorrowRate,
            uint128 currentStableBorrowRate,
            uint40 lastUpdateTimestamp,
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress,
            address interestRateStrategyAddress,
            uint8 id
        );
}

contract AaveUserWrapper {
    struct UserInfo {
        address[] assets;
        uint[] collaterals;
        uint[] debts;
    }

    function getReservesList(IAaveLendingPool pool) public view returns(address[] memory) {
        return pool.getReservesList();
    }

    function getActiveAssets(IAaveLendingPool pool, address user)
        public
        view
        returns(address[] memory activeAssets, bool[] memory collateral, bool[] memory borrow) {
        address[] memory allAssets = pool.getReservesList();

        uint numActiveAssets = 0;
        uint userCfg = pool.getUserConfiguration(user);
        for(uint i = 0 ; i < allAssets.length ; i++) {
            if((userCfg >> (2 * i)) & 0x3 > 0) numActiveAssets++;
        }

        activeAssets = new address[](numActiveAssets);
        collateral = new bool[](numActiveAssets);
        borrow = new bool[](numActiveAssets);

        numActiveAssets = 0;
        for(uint i = 0 ; i < allAssets.length ; i++) {
            if((userCfg >> (2*i + 1)) & 0x1 > 0) collateral[numActiveAssets] = true;
            if((userCfg >> (2*i)) & 0x1 > 0) borrow[numActiveAssets] = true;
            if((userCfg >> (2 * i)) & 0x3 > 0) activeAssets[numActiveAssets++] = allAssets[i];
        }
    }

    function getUserInfo(IAaveLendingPool pool, address user) public view returns(UserInfo memory) {
        UserInfo memory userData;
        
        (address[] memory assets, bool[] memory collateral, bool[] memory debt) = getActiveAssets(pool, user);
        
        userData.assets = new address[](assets.length);
        userData.collaterals = new uint[](assets.length);
        userData.debts = new uint[](assets.length);

        for(uint i = 0 ; i < assets.length ; i++) {
            userData.assets[i] = assets[i];
            (,,,,,,,
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress,,) = pool.getReserveData(assets[i]);         

            if(collateral[i]) {
                userData.collaterals[i] = aERC20(aTokenAddress).balanceOf(user);
            }
            if(debt[i]) {
                userData.debts[i] =
                    aERC20(stableDebtTokenAddress).balanceOf(user) + aERC20(variableDebtTokenAddress).balanceOf(user);
            }
        }

        return userData;
    }
}