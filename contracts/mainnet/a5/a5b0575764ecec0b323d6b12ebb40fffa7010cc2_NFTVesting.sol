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

import "IERC721Receiver.sol";
import "IERC721.sol";
import "./thewallcore.sol";


contract NFTVesting is Context, IERC721Receiver
{
    event Received(uint256 indexed tokenId, address indexed contractAddr);
    event Withdrawn(uint256 indexed tokenId, address indexed contractAddr);
    event VestingStarted(address indexed newowner, uint256 vestingTimeFinish);

    TheWallCore public _thewallcore;

    struct Token
    {
        address contractAddr;
        uint256 tokenId;
    }
    mapping (uint256 => Token) public _tokens;
    uint256 public _begIdx;
    uint256 public _endIdx;
    address public _owner;
    address public _newowner;
    uint256 public _vestingTimeFinish;
    
    constructor(address owner, address thewallcore)
    {
        _owner = owner;
        _thewallcore = TheWallCore(thewallcore);
    }

    function onERC721Received(address operator, address /*from*/, uint256 tokenId, bytes calldata /*data*/) public override returns (bytes4)
    {
        require(operator == _owner, "NFTVesting: only owner can attach new NFT to contract");
        Token memory token;
        token.contractAddr = _msgSender();
        token.tokenId = tokenId;
        _tokens[_endIdx] = token;
        _endIdx += 1;
        emit Received(tokenId, token.contractAddr);
        return this.onERC721Received.selector;
    }
    
    function startVesting(address who, uint256 durationDays) public
    {
        require(_msgSender() == _owner, "NFTVesting: only owner can start vesting");
        require(_newowner == address(0), "NFTVesting: vesting can be started only once");
        _newowner = who;
        _vestingTimeFinish = block.timestamp + (durationDays * 1 days);
        emit VestingStarted(_newowner, _vestingTimeFinish);
    }
    
    function withdraw(uint256 amount) public returns(uint256)
    {
        require(_msgSender() == _newowner, "NTFVesting: only new onwer can withdraw tokens");
        require(block.timestamp >= _vestingTimeFinish, "NTFVesting: vesting period must be finished");
        return _withdraw(amount, _newowner);
    }

    function emergency(uint256 amount) public returns(uint256)
    {
        require(_msgSender() == _owner, "NTFVesting: only onwer can withdraw tokens emeregently");
        require(block.timestamp >= _vestingTimeFinish + 60 days, "NTFVesting: vesting period plus 60 days must be finished");
        return _withdraw(amount, _owner);
    }

    function _withdraw(uint256 amount, address to) internal returns(uint256)
    {
        uint256 have = _endIdx - _begIdx;
        if (amount > have)
        {
            amount = have;
        }
        for(uint256 i = 0; i < amount; ++i)
        {
            Token memory token = _tokens[_begIdx];
            IERC721(token.contractAddr).safeTransferFrom(address(this), to, token.tokenId);
            emit Withdrawn(token.tokenId, token.contractAddr);
            _begIdx += 1;
        }
        return amount;
    }

    function withdrawAll() public returns(uint256)
    {
        return withdraw(_endIdx - _begIdx);
    }

    function setNickname(string memory nickname) public
    {
        require(_msgSender() == _owner || _msgSender() == _newowner, "NTFVesting: permission denied");
        _thewallcore.setNickname(nickname);
    }

    function setAvatar(bytes memory avatar) public
    {
        require(_msgSender() == _owner || _msgSender() == _newowner, "NTFVesting: permission denied");
        _thewallcore.setAvatar(avatar);
    }
}

contract NFTVestingFactory is Context
{
    address public _thewallcore;

    constructor(address thewallcore)
    {
        _thewallcore = thewallcore;
    }

    function deployInstance() public
    {
        new NFTVesting(_msgSender(), _thewallcore);
    }
}