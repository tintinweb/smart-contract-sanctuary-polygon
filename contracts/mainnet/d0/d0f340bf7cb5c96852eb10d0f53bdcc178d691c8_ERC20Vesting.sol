/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
// SPDX-License-Identifier: GNU lesser General Public License


pragma solidity ^0.8.0;

import "ERC20.sol";


contract ERC20Vesting is Context, ERC20
{
    event Deployed(string name, string symbol, address token, uint256 finishTime);
    event Staked(address indexed holder, uint256 amount);
    event Redeemed(address indexed holder, uint256 amount);

    uint256 public _vestingTimeFinish;
    IERC20  public _token;

    // Our decimals is 18
    constructor(
        string memory name,
        string memory symbol,
        address       token,
        uint256       finishTime) ERC20(name, symbol)
    {
        _token = IERC20(token);
        _vestingTimeFinish = finishTime;
        emit Deployed(name, symbol, token, finishTime);
    }

    function stake(uint256 amount) public
    {
        require(_token.transferFrom(_msgSender(), address(this), amount), "ERC20Vesting: not enough tokens");
        _mint(_msgSender(), amount);
        emit Staked(_msgSender(), amount);
    }

    function redeem(uint256 amount) public
    {
        require(block.timestamp >= _vestingTimeFinish, "ERC20Vesting: too haste");
        require(balanceOf(_msgSender()) >= amount, "ERC20Vesting: not enough LP tokens");
        _burn(_msgSender(), amount);
        require(_token.transfer(_msgSender(), amount), "ERC20Vesting: not enough tokens");
        emit Redeemed(_msgSender(), amount);
    }

    function redeemAll() public
    {
        redeem(balanceOf(_msgSender()));
    }
}