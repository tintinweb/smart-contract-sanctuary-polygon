/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiHonor {
    function POC(uint256 tokenId) view external returns(uint64);
    function VEPower(uint256 tokenId) view external returns(uint64);
    function VEPoint(uint256 tokenId) view external returns(uint64);
    function EventPoint(uint256 tokenId) view external returns(uint64);
    function TotalPoint(uint256 tokenId) view external returns(uint64); 
    function Level(uint256 tokenId) view external returns(uint8);
    function addPOC(uint256[] calldata ids, uint64[] calldata poc, uint64 time) external;
}

interface IERC721Enumerable {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

/**
 * Query MultiHonor point as ERC1155
 */
contract MultiHonor_1155Querier {
    /**
        id 0 Total point
        id 1 POC
        id 2 VE point
        id 3 Event point
        id 4 Level
     */

    address public MultiHonor;
    address public idcard;

    constructor (address _MultiHonor, address _idcard) {
        MultiHonor = _MultiHonor;
        idcard = _idcard;
    }

    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        uint256 tokenId = IERC721Enumerable(idcard).tokenOfOwnerByIndex(account, 0);
        if (id == 0) {
            return uint256(IMultiHonor(MultiHonor).TotalPoint(tokenId));
        }
        if (id == 1) {
            return uint256(IMultiHonor(MultiHonor).POC(tokenId));
        }
        if (id == 2) {
            return uint256(IMultiHonor(MultiHonor).VEPoint(tokenId));
        }
        if (id == 3) {
            return uint256(IMultiHonor(MultiHonor).EventPoint(tokenId));
        }
        if (id == 4) {
            return uint256(IMultiHonor(MultiHonor).Level(tokenId));
        }
        return 0;
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) public view returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }
}