/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

/**
 *Submitted for verification at BscScan.com on 2021-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;


interface IERC20Upgradeable {
    function balanceOf(address account) external view returns (uint256);
}


contract ERC20Upgradeable is IERC20Upgradeable{
    mapping(address => uint256) private _balances;

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[48] private __gap;
}