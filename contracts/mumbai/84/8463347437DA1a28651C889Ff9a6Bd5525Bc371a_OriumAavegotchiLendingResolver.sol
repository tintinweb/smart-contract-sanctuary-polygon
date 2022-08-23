// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import { IGelatoResolver } from "./interfaces/IGelatoResolver.sol";
import { IOriumAavegotchiLending } from "./interfaces/IOriumAavegotchiLending.sol";

contract OriumAavegotchiLendingResolver is IGelatoResolver {

    IOriumAavegotchiLending public immutable _oriumAavegotchiLending;

    constructor(address oriumAavegotchiLending) {
        _oriumAavegotchiLending = IOriumAavegotchiLending(oriumAavegotchiLending);
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        (uint32[] memory listNfts, uint32[] memory claimAndListNfts, uint32[] memory removeNfts) = _oriumAavegotchiLending.getPendingActions(true);
        if (listNfts.length > 0 || claimAndListNfts.length > 0) {
            canExec = true;
            execPayload = abi.encodeWithSelector(
                IOriumAavegotchiLending.manageLendings.selector, listNfts, claimAndListNfts, removeNfts
            );
        } else {
            canExec = false;
            execPayload = bytes("No actions to perform");
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

interface IGelatoResolver {

    // @notice Checks if Gelato should execute a task
    // @return canExec True if Gelato should execute task
    // @return execPayload Encoded function name and params
    function checker() external view returns (bool canExec, bytes memory execPayload);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import { AddGotchiListing } from "./IGotchiLendingFacet.sol";

interface IOriumAavegotchiLending {

    function getPendingActions(bool limit) external view returns (
        uint32[] memory listNfts, uint32[] memory claimAndListNfts, uint32[] memory removeNfts
    );

    function manageLendings(uint32[] calldata listNfts, uint32[] calldata claimAndListNfts, uint32[] calldata removeNfts) external;

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

// @param _erc721TokenId The identifier of the NFT to lend
// @param _initialCost The lending fee of the aavegotchi in $GHST
// @param _period The lending period of the aavegotchi, unit: second
// @param _revenueSplit The revenue split of the lending, 3 values, sum of the should be 100
// @param _originalOwner The account for original owner, can be set to another address if the owner wishes to have profit split there.
// @param _thirdParty The 3rd account for receive revenue split, can be address(0)
// @param _whitelistId The identifier of whitelist for agree lending, if 0, allow everyone
struct AddGotchiListing {
    uint32 tokenId;
    uint96 initialCost;
    uint32 period;
    uint8[3] revenueSplit;
    address originalOwner;
    address thirdParty;
    uint32 whitelistId;
    address[] revenueTokens;
}

interface IGotchiLendingFacet {

    // @notice Allow aavegotchi lenders (msg sender) or their lending operators to add request for lending
    // @dev If the lending request exist, cancel it and replaces it with the new one
    // @dev If the lending is active, unable to cancel
    function batchAddGotchiListing(AddGotchiListing[] memory listings) external;

    // @notice Claim and end and relist gotchi lendings in batch by token ID
    function batchClaimAndEndAndRelistGotchiLending(uint32[] calldata _tokenIds) external;

    // @notice Allow a borrower to agree an lending for the NFT
    // @dev Will throw if the NFT has been lent or if the lending has been canceled already
    // @param _listingId The identifier of the lending to agree
    function agreeGotchiLending(
        uint32 _listingId, uint32 _erc721TokenId, uint96 _initialCost, uint32 _period, uint8[3] calldata _revenueSplit
    ) external;

}