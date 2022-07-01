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
interface IStakingPool {
    function userInfo(address _user) external view returns (uint amount, uint);
}

contract CrystlGovBalance {

    IERC20 constant public CRYSTL = IERC20(0x76bF0C28e604CC3fE9967c83b3C3F31c213cfE64);
    IERC20 constant public CRYSTL_MATIC_LP = IERC20(0xB8e54c9Ea1616beEBe11505a419DD8dF1000E02a);
    IStakingPool constant public REVSHARE_POOL_OLD = IStakingPool(0x6fC18fA07bC68D16A254ACCB2986ec0da40c2B98);
    IStakingPool constant public REVSHARE_POOL_NEW = IStakingPool(0x2aBaF1D78F57f87399B6Ffe76b959363a7C67D58);

    IStakingPool constant public SINGLE_STAKE_0 = IStakingPool(0x284B5F8fB9b25F195929905567f9B626F989A73a);
    IStakingPool constant public SINGLE_STAKE_1 = IStakingPool(0xe9DA403d5250997e5484260993c3657B2AA0EF8D);

    function balanceOf(address account) external view returns (uint256 amount) {

        amount = CRYSTL.balanceOf(account);

        (uint singleStakeAmount,) = SINGLE_STAKE_0.userInfo(account);
        amount += singleStakeAmount;
        (singleStakeAmount,) = SINGLE_STAKE_1.userInfo(account);
        amount += singleStakeAmount;

        uint lpAmount = CRYSTL_MATIC_LP.balanceOf(account); //lp tokens in wallet
        (uint revshareAmount,) = REVSHARE_POOL_OLD.userInfo(account);
        lpAmount += revshareAmount;
        (revshareAmount,) = REVSHARE_POOL_NEW.userInfo(account);
        lpAmount += revshareAmount;

        amount += lpAmount * CRYSTL.balanceOf(address(CRYSTL_MATIC_LP)) / CRYSTL_MATIC_LP.totalSupply(); //underlying value
    }
}