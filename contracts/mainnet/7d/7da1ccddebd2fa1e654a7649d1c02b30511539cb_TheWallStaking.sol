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

import "IERC20.sol";
import "./thewall.sol";


contract TheWallStaking is Context, IERC721Receiver, ERC223ReceivingContract
{
    event Deployed(address governance);
    event StakedToken(address indexed owner, uint256 indexed tokenId, uint256 areasCount);
    event UnstakedToken(address indexed owner, uint256 indexed tokenId);
    event StakedCoupons(address indexed owner, uint256 amount);
    event UnstakedCoupons(address indexed owner, uint256 amount);

    TheWall        public _thewall;
    TheWallCore    public _thewallcore;
    TheWallCoupons public _thewallcoupons;
    IERC20         public _governance;

    uint256 public constant multiplier = 10 ** 18;

    mapping (uint256 => address) public _tokens;
    mapping (address => uint256) public _coupons;
    
    constructor(
        address payable thewall,
        address         thewallcore,
        address         thewallcoupons,
        address         governance)
    {
        _thewall = TheWall(thewall);
        _thewallcore = TheWallCore(thewallcore);
        _thewallcoupons = TheWallCoupons(thewallcoupons);
        _governance = IERC20(governance);
        _thewallcore.setNickname("The Wall Staking Protocol V1");
        _thewallcore.setAvatar('\x06\x01\x55\x12\x20\xd2\xce\x9f\x0c\x43\x8a\x5b\x10\xba\x02\x0f\x02\xef\xda\xcf\x5f\xa5\x58\x39\xe1\xac\xad\xf1\x3a\x2f\x10\x83\x9b\x8a\xd7\xd0\x40');
        emit Deployed(governance);
    }

    function onERC721Received(address /*operator*/, address /*from*/, uint256 /*tokenId*/, bytes calldata /*data*/) public view override returns (bytes4)
    {
        require(_msgSender() == address(_thewall), "TheWallStaking: can receive TheWall Global tokens only");
        return this.onERC721Received.selector;
    }

    function stakeToken(uint256 tokenId) public
    {
        uint256 amount = areasInside(tokenId);
        require(amount > 0, "TheWallStaking: invalid token");
        require(_governance.transfer(_msgSender(), amount * multiplier), "TheWallStaking: not enough governance tokens");
        _thewall.safeTransferFrom(_msgSender(), address(this), tokenId);
        _tokens[tokenId] = _msgSender();

        /* We need to clear the listing flags for sale or rent for an area/cluster,
         * but we have no way of knowing if it is listed for sale or for rent.
         * Using try-catch solves the problem, but results in a scary message
         * in polygonscan. Therefore, we first put the area/cluster up for sale and
         * immediately cancel the operation.
         */
        //try _thewall.cancel(tokenId) {} catch {}
        _thewall.forSale(tokenId, 0);
        _thewall.cancel(tokenId);

        emit StakedToken(_msgSender(), tokenId, amount);
    }

    function unstakeToken(uint256 tokenId) public
    {
        require(_tokens[tokenId] == _msgSender(), "TheWallStaking: not the owner");
        uint256 amount = areasInside(tokenId);
        require(_governance.transferFrom(_msgSender(), address(this), amount * multiplier), "TheWallStaking: can't get governance tokens back");
        _thewall.safeTransferFrom(address(this), _msgSender(), tokenId);
        delete _tokens[tokenId];
        emit UnstakedToken(_msgSender(), tokenId);
    }

    function tokenFallback(address sender, uint amount, bytes memory /*data*/) public override
    {
        require(_msgSender() == address(_thewallcoupons), "TheWallStaking: can receive TheWall Global tokens only");
        require(_governance.transfer(sender, amount * multiplier), "TheWallStaking: not enough governance tokens");
        _coupons[sender] += amount;
        emit StakedCoupons(sender, amount);
    }

    function unstakeCoupons(uint256 amount) public
    {
        require(_coupons[_msgSender()] >= amount, "TheWallStaking: not enought staked coupons");
        _coupons[_msgSender()] -= amount;
        require(_thewallcoupons.transfer(_msgSender(), amount), "TheWallStaking: not enough coupons");
        require(_governance.transferFrom(_msgSender(), address(this), amount * multiplier), "TheWallStaking: TheWallStaking: can't get governance tokens back");
        emit UnstakedCoupons(_msgSender(), amount);
    }

    function areasInside(uint256 tokenId) public view returns(uint256 amount)
    {
        amount = _thewallcore._areasInCluster(tokenId).length;
        if (amount == 0)
        {
            _thewallcore._isOrdinaryArea(tokenId);
            amount = 1;
        }
    }

    function setContent(uint256 tokenId, bytes memory content) public
    {
        require(_tokens[tokenId] == _msgSender(), "TheWallStaking: not the owner");
        _thewall.setContent(tokenId, content);
    }

    function setContentMulti(uint256[] memory tokens, bytes[] memory contents) public
    {
        // We can't call _thewall.setContentMulti(...) directly, because we need to
        // check ownership of all tokens
        require(tokens.length == contents.length, "TheWallStaking: length must be equal");
        for(uint i = 0; i < tokens.length; ++i)
        {
            setContent(tokens[i], contents[i]);
        }
    }
}