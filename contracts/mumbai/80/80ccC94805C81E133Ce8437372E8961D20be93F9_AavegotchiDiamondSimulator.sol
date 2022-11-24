/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

contract AavegotchiDiamondSimulator {
    event ScholarshipProgramCreated(
        address indexed scholarshipProgram,
        uint256 platform, // the plataform game
        uint256[] shares, // the split
        address indexed owner
    );
    event DelegatedScholarshipProgram(
        address owner,
        address vaultAddress, // the vault address
        address indexed nftAddress, // the nft contract address
        uint256 indexed tokenId, // the gotchiId
        address indexed scholarshipProgram, // the guild address
        uint256 allowedPeriod
    );
    event GotchiLendingExecuted(
        uint32 indexed listingId, // The listing id of the lending
        address indexed lender,
        address indexed borrower, // The user that has lent the gotchi
        uint32 tokenId, // The nft token id same as gotchiId
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit, // The split percentage for each party in this revenue
        address originalOwner,
        address thirdParty, // Splitter contract address
        uint32 whitelistId,
        address[] revenueTokens, // Array of ERC tokens used in the calculation
        uint256 timeAgreed
    );

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
    event ChannelAlchemica(
        uint256 indexed _realmId,
        uint256 indexed _gotchiId,
        uint256[4] _alchemica, // total alchemica generated (spillover + sent to user)
        uint256 _spilloverRate, // percentage of amount to spillover
        uint256 _spilloverRadius
    );

    event AlchemicaClaimed(uint256 indexed _realmId, uint256 indexed _gotchiId, uint256 indexed _alchemicaType, uint256 _amount, uint256 _spilloverRate, uint256 _spilloverRadius);
    event GotchiLendingClaimed(
        uint32 indexed listingId,
        address indexed lender,
        address indexed borrower,
        uint32 tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256[] amounts,
        uint256 timeClaimed
    );

    constructor() {}

    function simulateGotchiLendingClaimedEvent(
        AddGotchiListing calldata listing,
        uint32 _listingId,
        address _lender,
        address _borrower,
        uint256 _timeClaimed
    ) public {
        emit GotchiLendingClaimed(
            _listingId,
            _lender,
            _borrower,
            listing.tokenId,
            listing.initialCost,
            listing.period,
            listing.revenueSplit,
            listing.originalOwner,
            listing.thirdParty,
            listing.whitelistId,
            listing.revenueTokens,
            new uint256[](0),
            _timeClaimed
        );
    }

    function simulateChannelAlchemicaEvent(
        uint256 _realmId,
        uint256 _gotchiId,
        uint256[4] memory _alchemica,
        uint256 _spilloverRate,
        uint256 _spilloverRadius
    ) public {
        emit ChannelAlchemica(_realmId, _gotchiId, _alchemica, _spilloverRate, _spilloverRadius);
    }

    function simulateAlchemicaClaimedEvent(
        uint256 _realmId,
        uint256 _gotchiId,
        uint256 _alchemicaType,
        uint256 _amount,
        uint256 _spilloverRate,
        uint256 _spilloverRadius
    ) public {
        emit AlchemicaClaimed(_realmId, _gotchiId, _alchemicaType, _amount, _spilloverRate, _spilloverRadius);
    }

    function simulateGotchiLendingExecutedEvent(
        AddGotchiListing calldata listing,
        uint32 listingId,
        address lender,
        address borrower,
        uint256 timeAgreed
    ) public {
        emit GotchiLendingExecuted(
            listingId,
            lender,
            borrower,
            listing.tokenId,
            listing.initialCost,
            listing.period,
            listing.revenueSplit,
            listing.originalOwner,
            listing.thirdParty,
            listing.whitelistId,
            listing.revenueTokens,
            timeAgreed
        );
    }

    function simulateDelegatedScholarshipProgramEvent(
        address _owner,
        address _vaultAddress,
        address _nftAddress,
        uint256 _tokenId,
        address _scholarshipProgram,
        uint256 _allowedPeriod
    ) public {
        emit DelegatedScholarshipProgram(_owner, _vaultAddress, _nftAddress, _tokenId, _scholarshipProgram, _allowedPeriod);
    }

    function simulateScholarshipProgramCreatedEvent(
        address _scholarshipProgram,
        uint256 _platform,
        uint256[] memory _shares,
        address _owner
    ) public {
        emit ScholarshipProgramCreated(_scholarshipProgram, _platform, _shares, _owner);
    }
}