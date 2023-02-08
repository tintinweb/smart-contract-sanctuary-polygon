/**
 *Submitted for verification at polygonscan.com on 2023-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IAdmin {
    function isValidAdmin(address adminAddress) external view returns (bool);
}

interface IYugERC721 {
    function getInfo(uint256 id) external view returns (uint64, uint64, string memory, uint8);
    function userTokens(address user) external view returns(uint256[] memory);
}


contract YugIDManager {

    address _admin;
    address _yugToken;

    constructor() {
    }

    function initialize(address admin, address yugToken) public {
        require(_yugToken == address(0) || _admin != address(0) && IAdmin(_admin).isValidAdmin(msg.sender), "Unauthorized");
        _admin = admin;
        _yugToken = yugToken;
    }

    function hasValidID(address addr, uint64 kind) external view returns (bool) {
        uint256[] memory userTokens = IYugERC721(_yugToken).userTokens(addr);
        for(uint256 i = 0; i < userTokens.length; i++) {
            (uint256 expiry, uint64 _kind,,) = IYugERC721(_yugToken).getInfo(userTokens[i]);
            if(_kind == kind && expiry > block.timestamp) {
                return true;
            }
        }
        return false;
    }

}