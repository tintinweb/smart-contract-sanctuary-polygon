// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity ^0.8.0;

import "../interfaces/IGBM.sol";
import "../interfaces/IGBMInitiator.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721TokenReceiver.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC1155TokenReceiver.sol";
import "../interfaces/Ownable.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibSignature.sol";

//import "hardhat/console.sol";

/// @title GBM auction contract
/// @dev See GBM.auction on how to use this contract
/// @author Guillaume Gonnaud
contract GBMFacet is IGBM, IERC1155TokenReceiver, IERC721TokenReceiver, Modifiers {
    error ContractNotAllowed();
    error AuctionNotStarted();
    error ContractEnabledAlready();
    error AuctionExists();
    error NotTokenOwner();
    error StartOrEndTimeTooLow();
    error InsufficientToken();
    error TokenTypeMismatch();
    error UndefinedPreset();
    error NoAuction();
    error NotAuctionOwner();
    error AuctionEnded();
    error AuctionClaimed();
    error ModifyAuctionError();
    error AuctionNotEnded(uint256 timeToEnd);
    error CancellationTimeExceeded();
    error BiddingNotAllowed();
    error NoZeroBidAmount();
    error UnmatchedHighestBid(uint256 currentHighestBid);
    error NotHighestBidderOrOwner();
    error MinBidNotMet();
    error EndTimeTooLow();
    error DurationTooLow();
    error DurationTooHigh();
    error InvalidAuctionParams(string arg);
    error ContractDisabledAlready();
    error ClaimNotReady(uint256 claimAvailable);
    error OwnerBid();

    /// @notice Place a GBM bid for a GBM auction
    /// @param _auctionID The auction you want to bid on
    /// @param _bidAmount The amount of the ERC20 token the bid is made of. They should be withdrawable by this contract.
    /// @param _highestBid The current higest bid. Throw if incorrect.
    /// @param _signature Signature
    function commitBid(
        uint256 _auctionID,
        uint256 _bidAmount,
        uint256 _highestBid,
        address _tokenContract,
        uint256 _tokenID,
        uint256 _amount,
        bytes memory _signature
    ) external {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _auctionID, _bidAmount, _highestBid));
        require(LibSignature.isValid(messageHash, _signature, s.backendPubKey), "bid: Invalid signature");

        bid(_auctionID, _tokenContract, _tokenID, _amount, _bidAmount, _highestBid);
    }

    /// @notice Place a GBM bid for a GBM auction
    /// @param _auctionID The auction you want to bid on
    /// @param _bidAmount The amount of the ERC20 token the bid is made of. They should be withdrawable by this contract.
    /// @param _highestBid The current higest bid. Throw if incorrect.
    function bid(
        uint256 _auctionID,
        address _tokenContract,
        uint256 _tokenID,
        uint256 _amount,
        uint256 _bidAmount,
        uint256 _highestBid
    ) internal {
        Auction storage a = s.auctions[_auctionID];
        if (msg.sender == a.owner) revert OwnerBid();
        //verify existence
        if (a.owner == address(0)) revert NoAuction();
        if (a.info.endTime < block.timestamp) revert AuctionEnded();
        if (a.claimed == true) revert AuctionClaimed();
        if (a.biddingAllowed == false) revert BiddingNotAllowed();
        if (_bidAmount < 1) revert NoZeroBidAmount();
        //short-circuit
        if (_highestBid != a.highestBid) revert UnmatchedHighestBid(a.highestBid);

        //Verify onchain Auction Params
        if (a.tokenContract != _tokenContract) revert InvalidAuctionParams("tokenContract");
        if (a.info.tokenID != _tokenID) revert InvalidAuctionParams("tokenID");
        if (a.info.tokenAmount != _amount) revert InvalidAuctionParams("amount");

        address tokenContract = a.tokenContract;
        if (s.contractBiddingAllowed[tokenContract] == false) revert BiddingNotAllowed();

        uint256 tmp = _highestBid * getAuctionBidDecimals(_auctionID);

        if (tmp + getAuctionStepMin(_auctionID) >= _bidAmount * getAuctionBidDecimals(_auctionID)) revert MinBidNotMet();

        //Transfer the money of the bidder to the GBM Diamond
        IERC20(s.GHST).transferFrom(msg.sender, address(this), _bidAmount);

        //Extend the duration time of the auction if we are close to the end
        if (getAuctionEndTime(_auctionID) < block.timestamp + getAuctionHammerTimeDuration()) {
            a.info.endTime = uint80(block.timestamp + getAuctionHammerTimeDuration());
            emit Auction_EndTimeUpdated(_auctionID, a.info.endTime);
        }

        // Saving incentives for later sending
        uint256 duePay = s.auctions[_auctionID].dueIncentives;
        address previousHighestBidder = s.auctions[_auctionID].highestBidder;
        uint256 previousHighestBid = s.auctions[_auctionID].highestBid;

        // Emitting the event sequence
        if (previousHighestBidder != address(0)) {
            emit Auction_BidRemoved(_auctionID, previousHighestBidder, previousHighestBid);
        }

        if (duePay != 0) {
            s.auctions[_auctionID].auctionDebt = uint88(a.auctionDebt + duePay);
            emit Auction_IncentivePaid(_auctionID, previousHighestBidder, duePay);
        }

        emit Auction_BidPlaced(_auctionID, msg.sender, _bidAmount);

        // Calculating incentives for the new bidder
        s.auctions[_auctionID].dueIncentives = uint88(calculateIncentives(_auctionID, _bidAmount));

        //Setting the new bid/bidder as the highest bid/bidder
        s.auctions[_auctionID].highestBidder = msg.sender;
        s.auctions[_auctionID].highestBid = uint96(_bidAmount);

        if (previousHighestBid + duePay != 0) {
            //Refunding the previous bid as well as sending the incentives
            IERC20(s.GHST).transfer(previousHighestBidder, previousHighestBid + duePay);
        }
    }

    function batchClaim(uint256[] memory _auctionIDs) external {
        for (uint256 index = 0; index < _auctionIDs.length; index++) {
            claim(_auctionIDs[index]);
        }
    }

    /// @notice Attribute a token to the winner of the auction and distribute the proceeds to the owner of this contract.
    /// throw if bidding is disabled or if the auction is not finished.
    /// @param _auctionID The auctionId of the auction to complete
    function claim(uint256 _auctionID) public {
        Auction storage a = s.auctions[_auctionID];
        if (a.owner == address(0)) revert NoAuction();
        if (a.claimed == true) revert AuctionClaimed();
        uint256 cancellationTime = s.cancellationTime;

        //only owner or highestBidder should claim or finalize auction
        //highestBidders have to wait after cancellationTime
        if (msg.sender == a.highestBidder) {
            if (a.info.endTime + getAuctionHammerTimeDuration() + cancellationTime > block.timestamp)
                revert ClaimNotReady(a.info.endTime + getAuctionHammerTimeDuration() + cancellationTime);
        }
        //owners don't need to wait for cancellationTime
        if (msg.sender == a.owner) {
            if (a.info.endTime + getAuctionHammerTimeDuration() > block.timestamp)
                revert ClaimNotReady(a.info.endTime + getAuctionHammerTimeDuration());
        }
        require(msg.sender == a.highestBidder || msg.sender == a.owner, "NotHighestBidderOrOwner");
        address ca = a.tokenContract;
        uint256 tid = a.info.tokenID;
        uint256 tam = a.info.tokenAmount;

        //Prevents re-entrancy
        a.claimed = true;
        uint256 _proceeds = a.highestBid - a.auctionDebt;
        //96% goes to auction owner
        uint256 ownerShare = (_proceeds * 96) / 100;
        IERC20(s.GHST).transfer(a.owner, ownerShare);
        _settleFees(_proceeds);

        if (a.info.tokenKind == ERC721) {
            _sendTokens(ca, a.highestBidder, ERC721, tid, 1);
            s.erc721AuctionExists[ca][tid] = false;
        }
        if (a.info.tokenKind == ERC1155) {
            _sendTokens(ca, a.highestBidder, ERC1155, tid, tam);
        }
        a.biddingAllowed = false;
        emit Auction_ItemClaimed(_auctionID);
    }

    /// @notice Allow/disallow bidding and claiming for a whole token contract address.
    /// @param _contract The token contract the auctionned token belong to
    /// @param _value True if bidding/claiming should be allowed.
    function setBiddingAllowed(address _contract, bool _value) external onlyOwner {
        s.contractBiddingAllowed[_contract] = _value;
        emit Contract_BiddingAllowed(_contract, _value);
    }

    /// @notice Allow/disallow auction creation for a whole token contract address.
    /// @param _tokenContract The token contract to allow/disallow auction creations for
    /// @param _allowed True if auctions can be created for the token, False if otherwise.
    function toggleContractWhitelist(address _tokenContract, bool _allowed) external onlyOwner {
        if (_allowed) {
            if (s.contractAllowed[_tokenContract]) revert ContractEnabledAlready();
            s.contractAllowed[_tokenContract] = _allowed;
        } else {
            if (!s.contractAllowed[_tokenContract]) revert ContractDisabledAlready();
            s.contractAllowed[_tokenContract] = _allowed;
        }
    }

    /// @notice Allows the creation of new Auctions
    /// @dev Will throw if the auction preset does not exist
    /// @dev For ERC721 auctions, will throw if that tokenId is already in an unsettled auction
    /// @param _info A struct containing various details about the auction
    /// @param _tokenContract The contract address of the token
    /// @param _auctionPresetID The identifier of the GBMM preset to use for this auction
    function createAuction(
        InitiatorInfo calldata _info,
        address _tokenContract,
        uint256 _auctionPresetID
    ) external returns (uint256) {
        if (s.auctionPresets[_auctionPresetID].incMin < 1) revert UndefinedPreset();
        uint256 id = _info.tokenID;
        uint256 amount = _info.tokenAmount;
        bytes4 tokenKind = _info.tokenKind;
        uint256 _aid;
        assert(tokenKind == ERC721 || tokenKind == ERC1155);
        address ca = _tokenContract;
        if (!s.contractAllowed[ca]) revert ContractNotAllowed();
        _validateInitialAuction(_info);
        if (tokenKind == ERC721) {
            if (s.erc721AuctionExists[ca][id] != false) revert AuctionExists();
            if (Ownable(ca).ownerOf(id) == address(0) || msg.sender != Ownable(ca).ownerOf(id)) revert NotTokenOwner();
            //transfer Token
            IERC721(ca).safeTransferFrom(msg.sender, address(this), id);
            amount = 1;
            s.erc721AuctionExists[ca][id] = true;
        }
        if (tokenKind == ERC1155) {
            if (IERC1155(ca).balanceOf(msg.sender, id) < amount) revert InsufficientToken();
            //transfer Token/s
            IERC1155(ca).safeTransferFrom(msg.sender, address(this), id, amount, "");
        }
        _aid = s.auctionNonce;
        //set initiator info and set bidding allowed
        Auction storage a = s.auctions[_aid];
        a.owner = msg.sender;
        a.tokenContract = _tokenContract;
        a.info = _info;
        a.presets = s.auctionPresets[_auctionPresetID];
        a.biddingAllowed = true;

        emit Auction_Initialized(_aid, id, amount, ca, tokenKind, _auctionPresetID);
        emit Auction_StartTimeUpdated(_aid, getAuctionStartTime(_aid), getAuctionEndTime(_aid));
        s.auctionNonce++;
        return _aid;
    }

    function modifyAuction(
        uint256 _auctionID,
        uint80 _newEndTime,
        uint56 _newTokenAmount,
        bytes4 _tokenKind
    ) external {
        Auction storage a = s.auctions[_auctionID];
        //verify existence
        if (a.owner == address(0)) revert NoAuction();
        //verify ownership
        if (a.owner != msg.sender) revert NotAuctionOwner();
        if (a.info.endTime < block.timestamp) revert AuctionEnded();
        if (a.claimed == true) revert AuctionClaimed();
        if (a.info.tokenKind != _tokenKind) revert TokenTypeMismatch();
        uint256 tid = a.info.tokenID;
        address ca = a.tokenContract;
        //verify that no bids have been entered yet
        if (a.highestBid > 0) revert ModifyAuctionError();
        //If the end time is being changed
        if (a.info.endTime != _newEndTime) {
            if (block.timestamp >= _newEndTime || a.info.startTime >= _newEndTime) revert EndTimeTooLow();
            uint256 duration = _newEndTime - a.info.startTime;
            //max time should not be greater than 7 days
            if (duration > 604800) revert DurationTooHigh();
        }
        if (_tokenKind == ERC721) {
            a.info.endTime = _newEndTime;
            emit Auction_Modified(_auctionID, 1, _newEndTime);
        }

        if (_tokenKind == ERC1155) {
            uint256 diff = 0;
            a.info.endTime = _newEndTime;
            uint256 currentAmount = a.info.tokenAmount;

            if (currentAmount < _newTokenAmount) {
                diff = _newTokenAmount - currentAmount;
                //retrieve Token
                IERC1155(ca).safeTransferFrom(msg.sender, address(this), a.info.tokenID, diff, "");
                // update storage
                a.info.tokenAmount = _newTokenAmount;
            }
            if (currentAmount > _newTokenAmount) {
                diff = currentAmount - _newTokenAmount;
                //refund tokens
                _sendTokens(ca, msg.sender, _tokenKind, tid, diff);
                //update storage
                a.info.tokenAmount = _newTokenAmount;
            }
            emit Auction_Modified(_auctionID, _newTokenAmount, _newEndTime);
        }
    }

    function _validateInitialAuction(InitiatorInfo memory _info) internal view {
        if (_info.startTime < block.timestamp || _info.startTime >= _info.endTime) revert StartOrEndTimeTooLow();
        uint256 duration = _info.endTime - _info.startTime;
        if (duration < 3600) revert DurationTooLow();
        if (duration > 604800) revert DurationTooHigh();
    }

    function _sendTokens(
        address _contract,
        address _recipient,
        bytes4 _tokenKind,
        uint256 _tokenID,
        uint256 _amount
    ) internal {
        if (_tokenKind == ERC721) {
            IERC721(_contract).safeTransferFrom(address(this), _recipient, _tokenID, "");
        }
        if (_tokenKind == ERC1155) {
            IERC1155(_contract).safeTransferFrom(address(this), _recipient, _tokenID, _amount, "");
        }
    }

    /// @notice Seller can cancel an auction during the cancellation time
    /// Throw if the token owner is not the caller of the function
    /// @param _auctionID The auctionId of the auction to cancel
    function cancelAuction(uint256 _auctionID) public {
        Auction storage a = s.auctions[_auctionID];
        //verify existence
        if (a.owner == address(0)) revert NoAuction();
        //verify ownership
        if (a.owner != msg.sender) revert NotAuctionOwner();
        if (a.info.endTime > block.timestamp) revert AuctionNotEnded(getAuctionEndTime(_auctionID));
        //check if not claimed
        if (a.claimed == true) revert AuctionClaimed();

        address ca = a.tokenContract;
        uint256 tid = a.info.tokenID;
        uint256 tam = a.info.tokenAmount;
        if (getAuctionEndTime(_auctionID) + s.cancellationTime < block.timestamp) revert CancellationTimeExceeded();
        a.claimed = true;
        // case where no bids have been made
        if (a.highestBid == 0) {
            // Transfer the token to the owner/canceller
            if (a.info.tokenKind == ERC721) {
                _sendTokens(ca, a.owner, ERC721, tid, 1);
                //update storage
                s.erc721AuctionExists[ca][tid] = false;
            }
            if (a.info.tokenKind == ERC1155) {
                _sendTokens(ca, a.owner, ERC1155, tid, tam);
            }
            emit AuctionCancelled(_auctionID, tid);
        }
        if (a.highestBid > 0) {
            uint256 _proceeds = a.highestBid - a.auctionDebt;
            //Fees of pixelcraft,GBM,DAO and Treasury
            uint256 _auctionFees = (_proceeds * 4) / 100;

            //Send the debt + his due incentives from the seller to the highest bidder
            IERC20(s.GHST).transferFrom(a.owner, address(this), _auctionFees + a.dueIncentives + a.auctionDebt);

            //Refund it's bid plus his incentives to the highest bidder
            uint256 ownerShare = _proceeds + a.auctionDebt + a.dueIncentives;
            IERC20(s.GHST).transfer(a.highestBidder, ownerShare);

            _settleFees(_proceeds);

            // Transfer the token to the owner/canceller
            if (a.info.tokenKind == ERC721) {
                _sendTokens(ca, a.owner, ERC721, tid, 1);
                //update storage
                s.erc721AuctionExists[ca][tid] = false;
            }
            if (a.info.tokenKind == ERC1155) {
                _sendTokens(ca, a.owner, ERC1155, tid, tam);
            }

            emit AuctionCancelled(_auctionID, tid);
        }
    }

    function _settleFees(uint256 _total) internal {
        //1.5% goes to pixelcraft
        uint256 pixelcraftShare = (_total * 15) / 1000;
        IERC20(s.GHST).transfer(s.pixelcraft, pixelcraftShare);
        //1% goes to GBM
        uint256 GBM = (_total * 1) / 100;
        IERC20(s.GHST).transfer(s.GBMAddress, GBM);
        //0.5% to DAO
        uint256 DAO = (_total * 5) / 1000;
        IERC20(s.GHST).transfer(s.DAO, DAO);
        //1% to treasury
        uint256 Treasury = (_total * 1) / 100;
        IERC20(s.GHST).transfer(s.Treasury, Treasury);
    }

    /// @notice Register parameters of auction to be used as presets
    /// Throw if the token owner is not the GBM smart contract
    function setAuctionPresets(uint256 _auctionPresetID, Preset calldata _preset) external onlyOwner {
        s.auctionPresets[_auctionPresetID] = _preset;
    }

    function getAuctionPresets(uint256 _auctionPresetID) public view returns (Preset memory presets_) {
        presets_ = s.auctionPresets[_auctionPresetID];
    }

    function getAuctionInfo(uint256 _auctionID) external view returns (Auction memory auctionInfo_) {
        auctionInfo_ = s.auctions[_auctionID];
    }

    function getAuctionHighestBidder(uint256 _auctionID) external view returns (address) {
        return s.auctions[_auctionID].highestBidder;
    }

    function getAuctionHighestBid(uint256 _auctionID) external view returns (uint256) {
        return s.auctions[_auctionID].highestBid;
    }

    function getAuctionDebt(uint256 _auctionID) external view returns (uint256) {
        return s.auctions[_auctionID].auctionDebt;
    }

    function getAuctionDueIncentives(uint256 _auctionID) external view returns (uint256) {
        return s.auctions[_auctionID].dueIncentives;
    }

    function getTokenKind(uint256 _auctionID) external view returns (bytes4) {
        return s.auctions[_auctionID].info.tokenKind;
    }

    function getTokenId(uint256 _auctionID) external view returns (uint256) {
        return s.auctions[_auctionID].info.tokenID;
    }

    function getContractAddress(uint256 _auctionID) external view returns (address) {
        return s.auctions[_auctionID].tokenContract;
    }

    function getAuctionStartTime(uint256 _auctionID) public view returns (uint256) {
        return s.auctions[_auctionID].info.startTime;
    }

    function getAuctionEndTime(uint256 _auctionID) public view returns (uint256) {
        return s.auctions[_auctionID].info.endTime;
    }

    function getAuctionHammerTimeDuration() public view returns (uint256) {
        return s.hammerTimeDuration;
    }

    function getAuctionBidDecimals(uint256 _auctionID) public view returns (uint256) {
        return s.auctions[_auctionID].presets.bidDecimals;
    }

    function getAuctionStepMin(uint256 _auctionID) public view returns (uint64) {
        return s.auctions[_auctionID].presets.stepMin;
    }

    function getAuctionIncMin(uint256 _auctionID) public view returns (uint64) {
        return s.auctions[_auctionID].presets.incMin;
    }

    function getAuctionIncMax(uint256 _auctionID) public view returns (uint64) {
        return s.auctions[_auctionID].presets.incMax;
    }

    function getAuctionBidMultiplier(uint256 _auctionID) public view returns (uint64) {
        return s.auctions[_auctionID].presets.bidMultiplier;
    }

    function isBiddingAllowed(address _contract) public view returns (bool) {
        return s.contractBiddingAllowed[_contract];
    }

    function onERC721Received(
        address, /* _operator */
        address, /*  _from */
        uint256, /*  _tokenId */
        bytes calldata /* _data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(
        address, /* _operator */
        address, /* _from */
        uint256, /* _id */
        uint256, /* _value */
        bytes calldata /* _data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address, /* _operator */
        address, /* _from */
        uint256[] calldata, /* _ids */
        uint256[] calldata, /* _values */
        bytes calldata /* _data */
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    /// @notice Calculating and setting how much payout a bidder will receive if outbid
    /// @dev Only callable internally
    function calculateIncentives(uint256 _auctionID, uint256 _newBidValue) internal view returns (uint256) {
        uint256 bidDecimals = getAuctionBidDecimals(_auctionID);
        uint256 bidIncMax = getAuctionIncMax(_auctionID);

        //Init the baseline bid we need to perform against
        uint256 baseBid = (s.auctions[_auctionID].highestBid * (bidDecimals + getAuctionStepMin(_auctionID))) / bidDecimals;

        //If no bids are present, set a basebid value of 1 to prevent divide by 0 errors
        if (baseBid == 0) {
            baseBid = 1;
        }

        //Ratio of newBid compared to expected minBid
        uint256 decimaledRatio = (bidDecimals * getAuctionBidMultiplier(_auctionID) * (_newBidValue - baseBid)) /
            baseBid +
            getAuctionIncMin(_auctionID) *
            bidDecimals;

        if (decimaledRatio > bidDecimals * bidIncMax) {
            decimaledRatio = bidDecimals * bidIncMax;
        }

        return (_newBidValue * decimaledRatio) / (bidDecimals * bidDecimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    )
        external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC-1155 Multi Token Standard
/// @dev ee https://eips.ethereum.org/EIPS/eip-1155
///  The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 { /* is ERC165 */
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    )
        external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    )
        external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    )
        external
        returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    )
        external
        returns (bytes4);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC20 interface
/// @dev https://github.com/ethereum/EIPs/issues/20
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value)
        external
        returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 { /* is ERC165 */
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    )
        external
        payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
        external
        payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title IERC721TokenReceiver
/// @dev See https://eips.ethereum.org/EIPS/eip-721. Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity ^0.8.0;

/// @title IGBM GBM auction interface
/// @dev See GBM.auction on how to use this contract
/// @author Guillaume Gonnaud
interface IGBM {
    //Event emitted when an auction is being setup
    event Auction_Initialized(
        uint256 indexed _auctionID,
        uint256 indexed _tokenID,
        uint256 indexed _tokenAmount,
        address _contractAddress,
        bytes4 _tokenKind,
        uint256 _presetID
    );

    //Event emitted when the start time of an auction changes (due to admin interaction )
    event Auction_StartTimeUpdated(
        uint256 indexed _auctionID,
        uint256 _startTime,
        uint256 _endTime
    );

    //Event emitted when the end time of an auction changes (be it due to admin interaction or bid at the end)
    event Auction_EndTimeUpdated(uint256 indexed _auctionID, uint256 _endTime);

    //Event emitted when a Bid is placed
    event Auction_BidPlaced(
        uint256 indexed _auctionID,
        address indexed _bidder,
        uint256 _bidAmount
    );

    //Event emitted when a bid is removed (due to a new bid displacing it)
    event Auction_BidRemoved(
        uint256 indexed _auctionID,
        address indexed _bidder,
        uint256 _bidAmount
    );

    //Event emitted when an Auction is modified
    event Auction_Modified(
        uint256 indexed _auctionID,
        uint64 indexed _newTokenAmount,
        uint80 indexed _newEndTime
    );

    //Event emitted when incentives are paid (due to a new bid rewarding the _earner bid)
    event Auction_IncentivePaid(
        uint256 indexed _auctionID,
        address indexed _earner,
        uint256 _incentiveAmount
    );

    event Contract_BiddingAllowed(
        address indexed _contract,
        bool _biddingAllowed
    );

    event Auction_ItemClaimed(uint256 indexed _auctionID);

    event AuctionCancelled(uint256 indexed _auctionId, uint256 _tokenId); //        uint256 _auctionID,
} //        uint256 _bidAmount,
    //        uint256 _highestBid
    //    ) external;
    // function getAuctionID(address _contract, uint256 _tokenID) external view returns (uint256);
    // function getAuctionID(address _contract, uint256 _tokenID, uint256 _tokenIndex) external view returns (uint256);
//    function bid(
// function batchClaim(uint256[] memory _auctionIds) external;
// function claim(uint256 _auctionId) external;
// function erc20Currency() external view returns (address);
// //DEPRECATED
// //DEPRECATED
// function getTokenId(uint256 _auctionId) external view returns (uint256);
// function getContractAddress(uint256 _auctionId) external view returns (address);
// function getTokenKind(uint256 _auctionId) external view returns (bytes4);
// function getAuctionHighestBidder(uint256 _auctionId) external view returns (address);
// function getAuctionHighestBid(uint256 _auctionId) external view returns (uint256);
// function getAuctionDebt(uint256 _auctionId) external view returns (uint256);
// function getAuctionDueIncentives(uint256 _auctionId) external view returns (uint256);
// function getAuctionStartTime(uint256 _auctionId) external view returns (uint256);
// function getAuctionEndTime(uint256 _auctionId) external view returns (uint256);
// function getAuctionHammerTimeDuration(uint256 _auctionId) external view returns (uint256);
// function getAuctionBidDecimals(uint256 _auctionId) external view returns (uint256);
// function getAuctionStepMin(uint256 _auctionId) external view returns (uint256);
// function getAuctionIncMin(uint256 _auctionId) external view returns (uint256);
// function getAuctionIncMax(uint256 _auctionId) external view returns (uint256);
// function getAuctionBidMultiplier(uint256 _auctionId) external view returns (uint256);
// function getAuctionID(address _contract, uint256 _tokenID, uint256 _tokenIndex, bytes4 _tokenKind) external view returns (uint256);

// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity ^0.8.0;

/// @title IGBMInitiator: GBM Auction initiator interface.
/// @dev Will be called when initializing GBM auctions on the main GBM contract.
/// @author Guillaume Gonnaud
interface IGBMInitiator {
    // Auction id either = the contract token address cast as uint256 or
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind)));  <= ERC721
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind, _1155Index))); <= ERC1155

    function getStartTime(uint256 _auctionId)
        external
        view
        returns (uint256);

    function getEndTime(uint256 _auctionId) external view returns (uint256);

    function getHammerTimeDuration(uint256 _auctionId)
        external
        view
        returns (uint256);

    function getBidDecimals(uint256 _auctionId)
        external
        view
        returns (uint256);

    function getStepMin(uint256 _auctionId) external view returns (uint256);

    function getIncMin(uint256 _auctionId) external view returns (uint256);

    function getIncMax(uint256 _auctionId) external view returns (uint256);

    function getBidMultiplier(uint256 _auctionId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface Ownable {
    function ownerOf(uint256 _tokenId) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";

bytes4 constant ERC721 = 0x73ad2146;
bytes4 constant ERC1155 = 0x973bb640;

struct InitiatorInfo {
    uint80 startTime;
    uint80 endTime;
    uint56 tokenAmount;
    uint8 category; //0 = portal 1 = open portal 2 = pending 3 = aavegotchi
    bytes4 tokenKind;
    uint256 tokenID;
}

//Generic presets
struct Preset {
    uint64 incMin;
    uint64 incMax;
    uint64 bidMultiplier;
    uint64 stepMin;
    uint256 bidDecimals;
}

struct Auction {
    address owner;
    uint96 highestBid;
    address highestBidder;
    uint88 auctionDebt;
    uint88 dueIncentives;
    bool biddingAllowed;
    bool claimed;
    address tokenContract;
    InitiatorInfo info;
    Preset presets;
}

struct AppStorage {
    address pixelcraft;
    address DAO;
    address GBMAddress;
    address Treasury;
    address GHST;
    mapping(address => bool) contractBiddingAllowed;
    mapping(address => bool) contractAllowed; //Token contract address=>allowed
    mapping(uint256 => Auction) auctions; //_auctionId => auctions
    mapping(address => mapping(uint256 => uint256)) erc1155TokensIndex; //Contract => TokenID => Amount being auctionned
    bytes backendPubKey;
    mapping(address => mapping(uint256 => bool)) erc721AuctionExists; //Contract => TokenID => Existence
    mapping(uint256 => Preset) auctionPresets; // presestID => Configuration parameters
    uint128 hammerTimeDuration;
    uint128 cancellationTime;
    uint256 auctionNonce;
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    error InValidFacetCutAction();
    error NotDiamondOwner();
    error NoSelectorsInFacet();
    error NoZeroAddress();
    error SelectorExists(bytes4 selector);
    error SameSelectorReplacement(bytes4 selector);
    error MustBeZeroAddress();
    error NoCode();
    error NonExistentSelector(bytes4 selector);
    error ImmutableFunction(bytes4 selector);
    error NonEmptyCalldata();
    error EmptyCalldata();
    error InitCallFailed();
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner) revert NotDiamondOwner();
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert InValidFacetCutAction();
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) revert SelectorExists(selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress == _facetAddress) revert SameSelectorReplacement(selector);
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        if (_facetAddress != address(0)) revert MustBeZeroAddress();
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress);
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (_facetAddress == address(0)) revert NonExistentSelector(_selector);
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) revert ImmutableFunction(_selector);
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            if (_calldata.length > 0) revert NonEmptyCalldata();
        } else {
            if (_calldata.length == 0) revert EmptyCalldata();
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitCallFailed();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize <= 0) revert NoCode();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibSignature {
    function isValid(
        bytes32 messageHash,
        bytes memory signature,
        bytes memory pubKey
    )
        internal
        pure
        returns (bool)
    {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature)
            == address(uint160(uint256(keccak256(pubKey))));
    }

    function getEthSignedMessageHash(bytes32 messageHash)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        } // implicitly return (r, s, v)
    }
}