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
import "./thewallstaking.sol";


contract TheWallCouponsWrapped is Context, ERC20, IERC721Receiver, ERC223ReceivingContract
{
    event Deployed();
    event Wrapped(address indexed owner, uint256 amount);
    event Unwrapped(address indexed owner, uint256 amount);
    event Staked(address indexed owner, uint256 amount);
    event Unstaked(address indexed owner, uint256 amount);

    TheWall        public _thewall;
    TheWallCore    public _thewallcore;
    TheWallCoupons public _thewallcoupons;
    TheWallStaking public _thewallstaking;
    IERC20         public _governance;

    mapping (address => uint256) public _stakedCoupons;

    constructor(
        address payable thewall,
        address         thewallcore,
        address         thewallcoupons,
        address         thewallstaking,
        address         governance)
            ERC20("Wrapped The Wall Global Coupons", "wTWC")
    {
        _thewall = TheWall(thewall);
        _thewallcore = TheWallCore(thewallcore);
        _thewallcoupons = TheWallCoupons(thewallcoupons);
        _governance = IERC20(governance);
        _thewallstaking = TheWallStaking(thewallstaking);
        emit Deployed();
    }

    function decimals() public view virtual override returns (uint8)
    {
        return 0;
    }

    function onERC721Received(address /*operator*/, address /*from*/, uint256 /*tokenId*/, bytes calldata /*data*/) public view override returns (bytes4)
    {
        require(_msgSender() == address(_thewall), "TheWallCouponsWrapped: can receive TheWall Global tokens only");
        return this.onERC721Received.selector;
    }

    function tokenFallback(address sender, uint amount, bytes memory /*data*/) public override
    {
        require(_msgSender() == address(_thewallcoupons), "TheWallCouponsWrapped: can receive TheWall Global coupons only");
        _mint(sender, amount);
        emit Wrapped(sender, amount);
    }

    function burn(uint256 amount) public
    {
        require(balanceOf(_msgSender()) >= amount, "TheWallCouponsWrapped: not enough wTWC");
        _burn(_msgSender(), amount);
        require(_thewallcoupons.transfer(_msgSender(), amount), "TheWallCouponsWrapped: not enough TWC");
        emit Unwrapped(_msgSender(), amount);
    }

    function stake(uint256 amount) public
    {
        require(balanceOf(_msgSender()) >= amount, "TheWallCouponsWrapped: not enough wTWC");
        _stakedCoupons[_msgSender()] += amount;
        _burn(_msgSender(), amount);
        require(_thewallcoupons.transfer(address(_thewallstaking), amount), "TheWallCouponsWrapped: not enough TWC");
        require(_governance.transfer(_msgSender(), amount * _thewallstaking.multiplier()),"TheWallCouponsWrapped: not enough GTWG");
        emit Staked(_msgSender(), amount);
    }

    function unstake(uint256 amount) public
    {
        require(_stakedCoupons[_msgSender()] >= amount, "TheWallCouponsWrapped: not enought staked coupons");
        _stakedCoupons[_msgSender()] -= amount;
        require(_governance.transferFrom(_msgSender(), address(this), amount * _thewallstaking.multiplier()), "TheWallCouponsWrapped: can't get governance tokens back");
        _governance.approve(address(_thewallstaking), amount * _thewallstaking.multiplier());
        _thewallstaking.unstakeCoupons(amount);
        _mint(_msgSender(), amount);
        emit Unstaked(_msgSender(), amount);
    }

    function create(int256 x, int256 y, uint256 clusterId, address payable referrerCandidate, uint256 nonce, bytes memory content) public returns (uint256)
    {
        require(balanceOf(_msgSender()) > 0, "TheWallCouponsWrapped: not enough wTWC");
        _burn(_msgSender(), 1);
        uint256 areaId = _thewall.create(x, y, clusterId, referrerCandidate, nonce, content);
        _thewall.safeTransferFrom(address(this), _msgSender(), areaId);
        return areaId;
    }

    function createMulti(int256 x, int256 y, int256 width, int256 height, address payable referrerCandidate, uint256 nonce) public payable returns (uint256)
    {
        /* Actually, we don't know right here how many wTWC we need to execute this createMulti(...) call,  because some areas inside given rectangle
         * can be already occupied. That is why we require buyer to have maximum (width * height) wTWC for the worst case.
         * After _thewall.createMulti(...) execution, we will burn actual amount of wTWC for buyer.
         */
        require(balanceOf(_msgSender()) >= uint256(width * height), "TheWallCouponsWrapped: not enough wTWC");
        uint256 clusterId = _thewall.createMulti(x, y, width, height, referrerCandidate, nonce);
        uint256 actualSize = _thewallcore._areasInCluster(clusterId).length;
        if (actualSize > 0)
        {
            _burn(_msgSender(), actualSize);
        }
        return clusterId;
    }
}