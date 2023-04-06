// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ILekkerFactoryGoerli {
    function getEulerPools(address collateral, address debt) external view returns (address[] memory pools);

    function getAavePools(address collateral, address debt) external view returns (address[] memory pools);

    function getAllPools() external view returns (address[] memory _pools);

    function getAllAavePools() external view returns (address[] memory _pools);

    function getAllEulerPools() external view returns (address[] memory _pools);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// solhint-disable max-line-length

import "./ILekkerFactory.sol";

interface ILekkerToken {
    function tokenCollateral() external view returns (address);

    function tokenBorrow() external view returns (address);

    function getInvaiant() external view returns (uint256);
}

interface IERC20Base {
    function decimals() external view returns (uint8);
}

interface IAavePool {
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

contract LekkerLens {
    struct AavePoolData {
        address lekkerPoolAddress;
        address collateral;
        uint8 collateralDecimals;
        address debt;
        uint8 debtDecimals;
        uint256 invariant;
        uint256 totalCollateralBase;
        uint256 totalDebtBase;
        uint256 availableBorrowsBase;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
    }

    struct AaveUserData {
        uint256 totalCollateralBase;
        uint256 totalDebtBase;
        uint256 availableBorrowsBase;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
    }

    function getAavePoolData(address _lekkerFactory, address _aavePool) external view returns (AavePoolData[] memory data) {
        address[] memory aavePools = ILekkerFactoryGoerli(_lekkerFactory).getAllAavePools();
        uint256 length = aavePools.length;
        data = new AavePoolData[](length);
        for (uint256 i = 0; i < length; i++) {
            address currentLekkerPool = aavePools[i];
            address collateral = ILekkerToken(currentLekkerPool).tokenCollateral();
            address debt = ILekkerToken(currentLekkerPool).tokenBorrow();
            AaveUserData memory userData = getAaveUserDataInternal(_aavePool, currentLekkerPool);
            data[i] = AavePoolData({
                invariant: ILekkerToken(currentLekkerPool).getInvaiant(),
                lekkerPoolAddress: currentLekkerPool,
                collateral: collateral,
                collateralDecimals: IERC20Base(collateral).decimals(),
                debt: debt,
                debtDecimals: IERC20Base(debt).decimals(),
                totalCollateralBase: userData.totalCollateralBase,
                totalDebtBase: userData.totalDebtBase,
                availableBorrowsBase: userData.availableBorrowsBase,
                currentLiquidationThreshold: userData.currentLiquidationThreshold,
                ltv: userData.ltv,
                healthFactor: userData.healthFactor
            });
        }
    }

    function getAaveUserDataInternal(address _pool, address _user) internal view returns (AaveUserData memory data) {
        (
            data.totalCollateralBase,
            data.totalDebtBase,
            data.availableBorrowsBase,
            data.currentLiquidationThreshold,
            data.ltv,
            data.healthFactor
        ) = IAavePool(_pool).getUserAccountData(_user);
    }
}