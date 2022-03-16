/**
 *Submitted for verification at polygonscan.com on 2022-03-16
*/

// File: contracts/Test.sol


pragma solidity ^0.8.7;

interface QiDaoLiquidator {
    function liquidateVault(uint256 _vaultId) external;
}

interface OldLiquidator {
    function checkCollat(uint256 _vaultId) external;
}

contract Test {
    address internal constant liquidatorAddress = 0x3Cf3eF488a47aBe2Bd4ccB26B03bEfbC2F43E1b1;

    address internal constant lq = 0x595B3E98641C4d66900a24aa6Ada590b41eF85AA;

    OldLiquidator oliq = OldLiquidator(lq);

    QiDaoLiquidator liquidator = QiDaoLiquidator(liquidatorAddress);

    function liquidate(uint256 _vaultId) public {
        liquidator.liquidateVault(_vaultId);    
    }

    function checkCollat(uint256 _vaultId) public {
        oliq.checkCollat(_vaultId);
    }

}