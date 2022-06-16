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

import "ReentrancyGuard.sol";
import "./thewall.sol";


contract AreasPool is Ownable, IERC721Receiver, ReentrancyGuard
{
    using Address for address payable;

    event ContractDeployed(uint256 constLiquidity, uint256 maximumAreasInPool);
    event Payment(uint256 paidWei);
    event Deposited(address indexed provider, uint256 indexed areaId);
    event Withdrawn(uint256 indexed areaId, uint256 withdrawWei);
    event WithdrawnProfit(uint256 withdrawWei);

    TheWall     public _thewall;
    TheWallCore public _thewallcore;

    struct Balance
    {
        uint256 areas;
        uint256 amountLPT;
    }

    Balance public _total;
    bool    public _lock;
    mapping (uint256 => address) public _pool;
    mapping (address => Balance) public _balanceOf;

    uint256 public constant constLiquidity = 1 ether / 10;
    uint256 public constant maximumAreasInPool = 1000000;

    constructor(address payable thewall, address thewallcore)
    {
        _thewall = TheWall(thewall);
        _thewallcore = TheWallCore(thewallcore);
        _thewallcore.setNickname("Flick and Seek Protocol V1");
        // TODO: setAvatar
        //_thewallcore.setAvatar('\x06\x01\x55\x12\x20\x68\x8d\x76\x62\xb6\x9f\xc9\x1b\x11\x3f\x3b\x3d\xf8\xbf\xf2\xd5\x51\x49\xb6\x0c\x2c\x8b\xe2\xfe\x3c\x5d\x8e\xe2\x34\x93\x87\xdc');
        emit ContractDeployed(constLiquidity, maximumAreasInPool);
    }

    function onERC721Received(address /*operator*/, address /*from*/, uint256 /*tokenId*/, bytes calldata /*data*/) public view override returns (bytes4)
    {
        require(_msgSender() == address(_thewall), "AreasPool: can receive TheWall Global tokens only");
        return this.onERC721Received.selector;
    }

    function setLock(bool lock) public onlyOwner
    {
        _lock = lock;
    }

    receive () payable external
    {
        emit Payment(msg.value);
    }

    function depositArea(uint256 areaId) public payable
    {
        require(_total.areas < maximumAreasInPool, "AreasPool: No space in pool");
        require(msg.value == constLiquidity, "AreasPool: invalid amount deposited");
        uint256 amountLPT =
            (_total.areas == 0) ?
                (2**256 - 1) / (maximumAreasInPool * constLiquidity) :
                (_total.amountLPT * constLiquidity) / (address(this).balance - constLiquidity);
        require(amountLPT != 0, "AreasPool: Precision error");
        _pool[areaId] = _msgSender();
        _total.areas += 1;
        _total.amountLPT += amountLPT;
        Balance storage balance = _balanceOf[_msgSender()];
        balance.amountLPT += amountLPT;
        balance.areas += 1;

        _thewall.safeTransferFrom(_msgSender(), address(this), areaId);
        
        /* We need to clear the listing flags for sale or rent for an area,
         * but we have no way of knowing if it is listed for sale or for rent.
         * Using try-catch solves the problem, but results in a scary message
         * in polygonscan. Therefore, we first put the area up for sale and
         * immediately cancel the operation.
         */
        //try _thewall.cancel(areaId) {} catch {}
        _thewall.forSale(areaId, 0);
        _thewall.cancel(areaId);

        emit Deposited(_msgSender(), areaId);
    }

    function depositCluster(uint256 clusterId) public payable
    {
        uint256 [] memory areas = _thewallcore._areasInCluster(clusterId);
        require(areas.length > 0, "AreasPool: Empty cluster");
        require(_total.areas + areas.length <= maximumAreasInPool, "AreasPool: No space in pool");
        require(msg.value == constLiquidity * areas.length, "AreasPool: Invalid amount deposited");
        _thewall.safeTransferFrom(_msgSender(), address(this), clusterId);
        _thewall.removeCluster(clusterId);
        uint256 amountLPT =
            (_total.areas == 0) ?
                (2**256 - 1) / (maximumAreasInPool * constLiquidity * areas.length) :
                (_total.amountLPT * constLiquidity * areas.length) / (address(this).balance - constLiquidity * areas.length);
        require(amountLPT != 0, "AreasPool: Precision error");
        Balance storage balance = _balanceOf[_msgSender()];
        balance.areas += areas.length;
        balance.amountLPT += amountLPT;
        _total.areas += areas.length;
        _total.amountLPT += amountLPT;
        for(uint256 i = 0; i < areas.length; ++i)
        {
            uint256 areaId = areas[i];
            _pool[areaId] = _msgSender();
            emit Deposited(_msgSender(), areaId);
        }
    }

    function withdraw(uint256 areaId) public nonReentrant
    {
        require(!_lock, "AreaPool: Pool is locked");
        require(_pool[areaId] == _msgSender(), "AreasPool: No permissions");
        _thewall.safeTransferFrom(address(this), _msgSender(), areaId);

        Balance storage balance = _balanceOf[_msgSender()];
        uint256 amountLPT = balance.amountLPT / balance.areas;
        uint256 withdrawWei = address(this).balance * amountLPT / _total.amountLPT;
        _total.areas -= 1;
        _total.amountLPT -= amountLPT;
        balance.areas -= 1;
        balance.amountLPT -= amountLPT;
        payable(_msgSender()).sendValue(withdrawWei);
        delete _pool[areaId];
        emit Withdrawn(areaId, withdrawWei);
    }

    function withdrawProfit() public nonReentrant
    {
        Balance storage balance = _balanceOf[_msgSender()];
        require(balance.areas > 0, "AreasPool: No owned areas found in pool");
        uint256 withdrawWei = address(this).balance * balance.amountLPT / _total.amountLPT;
        uint256 newAmountLPT =
            (_total.areas == 1) ?
                balance.amountLPT : 
                (_total.amountLPT - balance.amountLPT) * constLiquidity * balance.areas / (address(this).balance - withdrawWei);
        uint256 deltaLPT = balance.amountLPT - newAmountLPT;
        balance.amountLPT -= deltaLPT;
        _total.amountLPT -= deltaLPT;
        balance.amountLPT = newAmountLPT;
        withdrawWei -= constLiquidity * balance.areas;
        payable(_msgSender()).sendValue(withdrawWei);
        emit WithdrawnProfit(withdrawWei);
    }

    function setContentMulti(uint256 [] memory areas, bytes [] memory contents) public onlyOwner
    {
        require(areas.length == contents.length, "AreasPool: Invalid parameters");
        for(uint216 i = 0; i < areas.length; ++i)
        {
            _thewall.setContent(areas[i], contents[i]);
        }
    }
}