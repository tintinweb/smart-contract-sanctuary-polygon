/**
 *Submitted for verification at polygonscan.com on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IErc20 {
    function decimals() external pure returns(uint8);
    function balanceOf(address) external view returns(uint256);
    function transfer(address, uint256) external returns(bool);
    function approve(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
}

interface IExchangeV1forV2 {
    function incentive() external view returns(uint8);
    function swap() external;
}

contract ExchangeV1forV2Wrapper {
    IErc20 internal constant jpycv1 = IErc20(0x6AE7Dfc73E0dDE2aa99ac063DcF7e8A63265108c);
    IErc20 internal constant jpycv2 = IErc20(0x431D5dfF03120AFA4bDf332c61A6e1766eF37BDB);
    IExchangeV1forV2 internal constant exchangeV1forV2 = IExchangeV1forV2(0x382d78E8BcEa98fA04b63C19Fe97D8138C3bfC5D);
    constructor() {
        jpycv1.approve(address(exchangeV1forV2), type(uint256).max);
    }
    function quote(uint256 amount) public view returns(uint256) {
        return amount * (100 + exchangeV1forV2.incentive()) / 100;
    }
    function swap(uint256 amount) public {
        jpycv1.transferFrom(msg.sender, address(this), amount);
        exchangeV1forV2.swap();
        jpycv2.transfer(msg.sender, jpycv2.balanceOf(address(this)));
    }
}