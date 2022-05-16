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

import "Ownable.sol";


contract TheWallCensorship is Ownable
{
    event ItemCensored(uint256 indexed tokenId, bool censored);
    event TagCensored(string tag, bool censored);
    event UserCensored(address indexed user, bool censored);

    mapping (uint256 => bool) public _items;
    mapping (string => bool) public  _tags;
    mapping (address => bool) public _users;

    function censorItem(uint256 tokenId, bool censored) public onlyOwner
    {
        _items[tokenId] = censored;
        emit ItemCensored(tokenId, censored);
    }

    function censorTag(string memory tag, bool censored) public onlyOwner
    {
        _tags[tag] = censored;
        emit TagCensored(tag, censored);
    }

    function censorUser(address user, bool censored) public onlyOwner
    {
        _users[user] = censored;
        emit UserCensored(user, censored);
    }
}