/**
 *Submitted for verification at polygonscan.com on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

contract NftInformationObserver {
    struct OwnerNftData {
        uint256 collectionId;
        uint256 tokenId;
    }
    struct StakeNftData {
        uint256 collectionId;
        uint256 tokenId;
        uint256 duration;
    }

    constructor() {}

    function ownedNftInWallet(address owner)
        public
        view
        returns (
            OwnerNftData[] memory gameNftInfo,
            OwnerNftData[] memory boxNftInfo
        )
    {
        require(owner != address(0), "zero owner address");

        OwnerNftData memory newOwnerNftData0 = OwnerNftData({
           collectionId: 0,
           tokenId: 1
        });
        OwnerNftData memory newOwnerNftData1 = OwnerNftData({
           collectionId: 1,
           tokenId: 2
        });
        gameNftInfo[0] = newOwnerNftData0;
        gameNftInfo[1] = newOwnerNftData1;

        OwnerNftData memory newOwnerNftData2 = OwnerNftData({
           collectionId: 2,
           tokenId: 3
        });
        OwnerNftData memory newOwnerNftData3 = OwnerNftData({
           collectionId: 3,
           tokenId: 4
        });
        OwnerNftData memory newOwnerNftData4 = OwnerNftData({
           collectionId: 4,
           tokenId: 5
        });
        boxNftInfo[0] = newOwnerNftData2;
        boxNftInfo[1] = newOwnerNftData3;
        boxNftInfo[2] = newOwnerNftData4;
    }

    function ownedNftInStake(address owner)
        public
        view
        returns (
            StakeNftData[] memory stakeInfo
        )
    {
        require(owner != address(0), "zero owner address");

        StakeNftData memory newStakeNftData0 = StakeNftData({
           collectionId: 5,
           tokenId: 6,
           duration: block.timestamp - 10000
        });
        StakeNftData memory newStakeNftData1 = StakeNftData({
           collectionId: 6,
           tokenId: 7,
           duration: block.timestamp - 20000
        });
        StakeNftData memory newStakeNftData2 = StakeNftData({
           collectionId: 7,
           tokenId: 8,
           duration: block.timestamp - 30000
        });
        stakeInfo[0] = newStakeNftData0;
        stakeInfo[1] = newStakeNftData1;
        stakeInfo[2] = newStakeNftData2;
    }
}