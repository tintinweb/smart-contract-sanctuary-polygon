/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;



// Part: IXEN1

interface IXEN1{
    function claimRank(uint256 term) external;
    function claimMintReward() external;
    function claimMintRewardAndShare(address other, uint256 pct) external ;
}

// Part: GET

contract GET{
    IXEN1 private constant xen = IXEN1(0x2AB0e9e4eE70FFf1fB9D67031E44F6410170d00e);
    address private owner ;
    constructor() {

        owner = tx.origin;
    }

    function claimRank(uint256 term) public {
        xen.claimRank(term);

    }

    function claimMintRewardAndShare(address other) public {
        require(owner == tx.origin,"not owner!");
        xen.claimMintRewardAndShare(other,100);
        selfdestruct(payable(tx.origin));
    }
}

// File: XenMint.sol

contract GETXEN {

    mapping (address=>mapping (uint256=>address[])) public userContracts;

    function claimRank(uint256 times, uint256 term) external {
        address user = tx.origin;
        for(uint256 i; i<times; ++i){
            GET get = new GET();
            get.claimRank(term);
            userContracts[user][term].push(address(get));
        }
    }

    function getshenyu(uint term) view public  returns (uint256 count)
    {
        address user = tx.origin;
        count = userContracts[user][term].length;

    }

    function claimMintRewardAndShare(address other,uint256 times, uint256 term) external {
        address user = tx.origin;
        for(uint256 i; i<times; ++i){
            uint256 count = userContracts[user][term].length;
            address get = userContracts[user][term][count - 1];
            GET(get).claimMintRewardAndShare(other);
            userContracts[user][term].pop();
        }
    }
}