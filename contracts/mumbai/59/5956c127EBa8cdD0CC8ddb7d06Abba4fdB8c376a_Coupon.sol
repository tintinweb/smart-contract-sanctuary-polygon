// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Coupon {
    struct UserInfo {
       string user; 
       uint64 value;
        uint64 expires; // unix timestamp, user expires
    }

    mapping(uint256 => UserInfo) internal _users;
event UpdateUser(
        uint256 indexed tokenId,
        string indexed user,
        uint64 value,
        uint64 expires
    );

    function setUser(
        uint256 tokenId,
        string memory user,
        uint64 value,
        uint64 expires
    ) public {
       
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, value, expires);
    }


    function userOf(uint256 tokenId) public view virtual returns (string memory) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return string("");
        }
    }

 
    function userExpires(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _users[tokenId].expires;
    }
}