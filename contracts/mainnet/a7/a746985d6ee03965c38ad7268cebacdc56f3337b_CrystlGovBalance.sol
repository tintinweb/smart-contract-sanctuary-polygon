/**
 *Submitted for verification at polygonscan.com on 2022-06-03
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-08
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/*
Join us at crystl.finance!
 █▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █░░ 
 █░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █░░ 
 ▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀▀▀
*/

interface IERC20 {
    function balanceOf(address _account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}
interface IMiniChefV2 {
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
}
interface IVaultHealerV2 {
    function stakedWantTokens(uint256 _pid, address _user) external view returns (uint256);
}
interface IStakingPool {
    function userInfo(address _user) external view returns (uint amount, uint);
}

contract CrystlGovBalance {

    IERC20 constant public CRYSTL = IERC20(0x76bF0C28e604CC3fE9967c83b3C3F31c213cfE64);
    IERC20 constant public CRYSTL_MATIC_LP = IERC20(0xB8e54c9Ea1616beEBe11505a419DD8dF1000E02a);
    IStakingPool constant public REVSHARE_POOL = IStakingPool(0x6fC18fA07bC68D16A254ACCB2986ec0da40c2B98);

    function balanceOf(address account) external view returns (uint256 amount) {

        uint supply = CRYSTL_MATIC_LP.totalSupply();
        uint crystlTotalInLP = CRYSTL.balanceOf(address(CRYSTL_MATIC_LP));
        uint lpAmount = CRYSTL_MATIC_LP.balanceOf(account); //lp tokens in wallet

        (uint revshareAmount,) = REVSHARE_POOL.userInfo(account);
        lpAmount += revshareAmount;
        
        return CRYSTL.balanceOf(account) + lpAmount * crystlTotalInLP / supply; //underlying value
    }
}