/**
 *Submitted for verification at polygonscan.com on 2022-03-06
*/

pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

interface ILendingPool {
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
}

interface IIGainAAVEIRS {
    function mintB(uint256 amount, uint256 min_b) external returns (uint256 _b);
    function b() external returns (address);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract iGainAAVEBorrowProxy {
    ILendingPool public AAVE; // AAVE LendingPool
    IIGainAAVEIRS public IGain;
    IERC20 public B;
    IERC20 public asset; // underlying asset's address

    constructor(address _asset, address _aave, address _igain) {
        asset = IERC20(_asset);
        AAVE = ILendingPool(_aave);
        IGain = IIGainAAVEIRS(_igain);
        B = IERC20(IGain.b());
        asset.approve(_aave, type(uint256).max);
        asset.approve(_igain, type(uint256).max);
    }

    // user needs to first invoke debtToken.approveDelegation(proxyAddress, mount)
    function borrow(uint256 borrowAmount, uint256 igainAmount, uint256 minToken) external {
        AAVE.borrow(address(asset), borrowAmount, 2, uint16(0), msg.sender);
        uint256 b = IGain.mintB(igainAmount, minToken);
        asset.transfer(msg.sender, borrowAmount - igainAmount);
        B.transfer(msg.sender, b);
    }

}