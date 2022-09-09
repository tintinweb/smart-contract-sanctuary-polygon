/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiHonor {
    function VEPower(uint256 tokenId) view external returns(uint256);
    function VEPoint(uint256 tokenId) view external returns(uint64);
    function TotalPoint(uint256 tokenId) view external returns(uint64); 
}

interface IERC721Enumerable {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract MultiDAO_VotePower {
    address public idcard;
    address public multihonor;

    string public name = "MultiDAOVotePower";
    string public symbol = "MDVP";
    uint8 public decimals = 0;

    constructor (address _idcard, address _multihonor) {
        idcard = _idcard;
        multihonor = _multihonor;
    }

    function votePower(uint256 dao_id) public view returns (uint256) {
        if (IMultiHonor(multihonor).VEPower(dao_id) < 100) {
            return 0;
        }
        return IMultiHonor(multihonor).TotalPoint(dao_id);
    }

    function balanceOf(address account) external view returns (uint256) {
        uint256 dao_id = IERC721Enumerable(idcard).tokenOfOwnerByIndex(account, 0);
        return votePower(dao_id);
    }
}