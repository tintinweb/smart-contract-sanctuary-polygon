/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Define the interface for the contract with the makeCustomBid function
interface ICustomBidContract {
    function makeCustomBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount,
        address _nftRecipient
    ) external;
}

contract LensportMarketplaceMultiBids {
    // Struct to store the required parameters for makeCustomBid
    struct CustomBid {
        address targetContract;
        address nftContractAddress;
        uint256 tokenId;
        address erc20Token;
        uint128 tokenAmount;
        address nftRecipient;
    }

    // Call the makeCustomBid function from the target contract for multiple bids
    function callMakeCustomBids(CustomBid[] memory bids) public {
        for (uint i = 0; i < bids.length; i++) {
            CustomBid memory bid = bids[i];
            ICustomBidContract customBidContract = ICustomBidContract(bid.targetContract);
            customBidContract.makeCustomBid(
                bid.nftContractAddress,
                bid.tokenId,
                bid.erc20Token,
                bid.tokenAmount,
                bid.nftRecipient
            );
        }
    }
}