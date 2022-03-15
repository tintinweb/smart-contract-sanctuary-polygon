/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.7;

interface QiDaoLiquidator {
    function liquidateVault(uint256 _vaultId) external;
}

contract Test {
    address internal constant liquidatorAddress = 0x3Cf3eF488a47aBe2Bd4ccB26B03bEfbC2F43E1b1;

    QiDaoLiquidator liquidator = QiDaoLiquidator(liquidatorAddress);

    function liquidate(uint256 _vaultId) public {
        liquidator.liquidateVault(_vaultId);
    }

}