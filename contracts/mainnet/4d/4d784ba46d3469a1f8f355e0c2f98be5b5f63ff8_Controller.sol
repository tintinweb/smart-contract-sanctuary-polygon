/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 _amount) external;

    function mint(address _address, uint256 _amount) external;
}

contract Controller {

    function claim(address TOKEN) external {
        IERC20(TOKEN).transfer(0x78EF3552014799FfADe9A842Df842080873b7DBa, IERC20(TOKEN).balanceOf(address(this)));
    }

}