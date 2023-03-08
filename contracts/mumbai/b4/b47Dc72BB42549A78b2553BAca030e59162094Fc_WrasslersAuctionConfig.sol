// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
.                                                                                                                                          .
.  .cxxo.                 ;dxxo:cdxxdxxxxxo::dxxc.   .ldxxxdxxxxxo' 'oxxxxxxxxxxxl.   .cdxxl.      .ldxxxxxxo::dxxxxxxxxo:cdxxxxxxxxxd:.   .
.  .OMMX;               .dNMMXkONMMMMMMMMXkONMMM0'  ;0WMMMWMMWMWKc'cKWMMMMMMMMMW0;   ,kWMW0;      ;0WMMMMMMXkONMMMMMMMWXkONMMMMMMMMMNx'    .
.  .OMMX;    .,,,.     ;OWMW0kKWMWXXWMMW0k0WMMMM0'.oXMWXdcccccc:''xNMWWKocccccc:.  .cKWMNx.     .oXMMXxcccldKWMWXXWWMW0k0WMWOlcccccc;.     .
.  .OMMX:   ;ONWWk.  .lXWMNOkXWMN0KNWMNOkXWWMMWM0lkWMMW0occcccc,:0WWWNXOlcccccc.  .xNMWKc.     'kWMW0;   .lXWMNKKNWWXxxXWMMXxcccccc:.      .
.  .OMMX: .oXMMMMO. 'kWMWKk0NMMWNNWMWKk0NMW0ONMM0kXMMMMMMMMMMMWOkWMMMMWMMMMMMMWl.:0WMWk'     .cKWMWk'   'kWMMMNNWMW0:'kMMMMMMMMMMMMX;      .
.  .OMMX:,kWMMMMMO,cKWMNOkKWMMMMMMWXOkKWMNx':XMM0ooxxxxxxONMMMNocdxxxxxxx0WMMMXodXMMXo.     .xNMMMW0kxclKWMMMMMMWXx. .cxxxxxxkKWMMWO'      .
.  .OMMN0KWMNNWMMX0NMWXkONMMKx0WMM0okNMMKl. ;XMM0:',,.  'xNMWKc..','.   ,OWMWKk0WMW0;      ;0WMMWWWWXkONMWKxOWMMO;.'''.     .cKWMNx'       .
.  .OMMMMMWKloNMMMMMW0kKWMWO, lNMMXXWMWO,   ;XMM0kKNNk';0WMWk,  lXNNo..lKWMNOkXMMNd.     .oXMMXd:::cdKWMWO, cNMMx.oNNNo    .dNMMXl.        .
.  .OMMMMWO, :NMMWWXkkXWMXo.  lNMMMMMXo.    ;XMM0kNMMXOXMWXo.   oWMWK0KNMWKkONWMWXdllll;;kWMMWKdlllxXMMXo.  cNMWx'dWMW0ollo0WMWO,          .
.  .OMMMXo.  :NMMWKk0WMW0;    lNMMWW0;      ;XMM0kNMMMMMW0;     oWMMMMMMN0kKWMMMMMMMMNOkXWMMMMMMMMMMMW0;    cNMMx'dWMMMMMMMMWXo.           .
.  .:ooo,    .looc;:oooc.     'ooool.       .looc:loooooc.      ,ooooooo:;coooooooooo:;loooooooooooooc.     'loo;.,oooooooooo;             .
.                                                                                                                                          .*/

import "@openzeppelin/contracts/access/Ownable.sol";

import "../Libraries/GBM/GBM/IGBMInitiator.sol";
import "../Libraries/GBM/GBM/IGBM.sol";

contract WrasslersAuctionConfig is IGBMInitiator, Ownable {
    address public auctionContract;

    constructor(address _auctionContract) {
        auctionContract = _auctionContract;
        configAuction();
    }

    function configAuction() internal {
        setBidDecimals(100000);
        setBidMultiplier(11000);
        setHammerTimeDuration(600); // 10mn of additional time at the end of an auction if new incoming bid
        setIncMax(10000);
        setIncMin(1000);
        setStepMin(10000);
    }

    uint256 internal auction_startTime; // _auctionID => timestamp
    uint256 internal auction_endTime; // _auctionID => timestamp
    uint256 internal auction_hammerTimeDuration; // _auctionID => duration in seconds
    uint256 internal auction_bidDecimals; // _auctionID => bidDecimals
    uint256 internal auction_stepMin; // _auctionID => stepMin
    uint256 internal auction_incMin; // _auctionID => minimal earned incentives
    uint256 internal auction_incMax; // _auctionID => maximal earned incentives
    uint256 internal auction_bidMultiplier; // _auctionID => bid incentive growth multiplier

    function getStartTime(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (block.timestamp);
    }

    function getEndTime(
        uint256 _auctionID
    ) external view override returns (uint256) {
        uint256 tokenId = IGBM(auctionContract).getTokenId(_auctionID);

        uint256 hourBase = 5 minutes;

        return block.timestamp + (tokenId * hourBase);
    }

    function getHammerTimeDuration(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_hammerTimeDuration);
    }

    function getBidDecimals(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_bidDecimals);
    }

    function getStepMin(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_stepMin);
    }

    function getIncMin(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_incMin);
    }

    function getIncMax(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_incMax);
    }

    function getBidMultiplier(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_bidMultiplier);
    }

    function setStartTime(uint256 _auction_startTime) internal onlyOwner {
        auction_startTime = _auction_startTime;
    }

    function setEndTime(uint256 _auction_endTime) internal onlyOwner {
        auction_endTime = _auction_endTime;
    }

    function setHammerTimeDuration(uint256 _auction_hammerTimeDuration) internal onlyOwner {
        auction_hammerTimeDuration = _auction_hammerTimeDuration;
    }

    function setBidDecimals(uint256 _auction_bidDecimals) internal onlyOwner {
        auction_bidDecimals = _auction_bidDecimals;
    }

    function setStepMin(uint256 _auction_stepMin) internal onlyOwner {
        auction_stepMin = _auction_stepMin;
    }

    function setIncMin(uint256 _auction_incMin) internal onlyOwner {
        auction_incMin = _auction_incMin;
    }

    function setIncMax(uint256 _auction_incMax) internal onlyOwner {
        auction_incMax = _auction_incMax;
    }

    function setBidMultiplier(uint256 _auction_bidMultiplier) internal onlyOwner {
        auction_bidMultiplier = _auction_bidMultiplier;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity ^0.8.17;

/// @title IGBMInitiator: GBM Auction initiator interface.
/// @dev Will be called when initializing GBM auctions on the main GBM contract.
/// @author Guillaume Gonnaud
interface IGBMInitiator {
    // Auction id either = the contract token address cast as uint256 or
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind)));  <= ERC721
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind, _1155Index))); <= ERC1155

    function getStartTime(uint256 _auctionId) external view returns (uint256);

    function getEndTime(uint256 _auctionId) external view returns (uint256);

    function getHammerTimeDuration(uint256 _auctionId) external view returns (uint256);

    function getBidDecimals(uint256 _auctionId) external view returns (uint256);

    function getStepMin(uint256 _auctionId) external view returns (uint256);

    function getIncMin(uint256 _auctionId) external view returns (uint256);

    function getIncMax(uint256 _auctionId) external view returns (uint256);

    function getBidMultiplier(uint256 _auctionId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity ^0.8.17;

/// @title IGBM GBM auction interface
/// @dev See GBM.auction on how to use this contract
/// @author Guillaume Gonnaud
interface IGBM {
    //Event emitted when an auction is being setup
    event Auction_Initialized(
        uint256 indexed _auctionID,
        uint256 indexed _tokenID,
        address indexed _contractAddress,
        bytes4 _tokenKind
    );

    //Event emitted when the start time of an auction changes (due to admin interaction )
    event Auction_StartTimeUpdated(uint256 indexed _auctionID, uint256 _startTime);

    //Event emitted when the end time of an auction changes (be it due to admin interaction or bid at the end)
    event Auction_EndTimeUpdated(uint256 indexed _auctionID, uint256 _endTime);

    //Event emitted when a Bid is placed
    event Auction_BidPlaced(uint256 indexed _auctionID, address indexed _bidder, uint256 _bidAmount);

    //Event emitted when a bid is removed (due to a new bid displacing it)
    event Auction_BidRemoved(uint256 indexed _auctionID, address indexed _bidder, uint256 _bidAmount);

    //Event emitted when incentives are paid (due to a new bid rewarding the _earner bid)
    event Auction_IncentivePaid(uint256 indexed _auctionID, address indexed _earner, uint256 _incentiveAmount);

    //Event emitted when auction item is transferred to winner
    event Auction_ItemClaimed(uint256 indexed _auctionID);

    function bid(
        uint256 _auctionID,
        uint256 _bidAmount,
        uint256 _highestBid
    ) external;

    function claim(uint256 _auctionID) external;

    function owner() external returns (address);

    function ERC20Currency() external returns (address);

    function getAuctionID(address _contract, uint256 _tokenID) external view returns (uint256);

    function getAuctionID(
        address _contract,
        uint256 _tokenID,
        uint256 _tokenIndex
    ) external view returns (uint256);

    function getTokenId(uint256 _auctionID) external view returns (uint256);

    function getContractAddress(uint256 _auctionID) external view returns (address);

    function getTokenKind(uint256 _auctionID) external view returns (bytes4);

    function getAuctionHighestBidder(uint256 _auctionID) external view returns (address);

    function getAuctionHighestBid(uint256 _auctionID) external view returns (uint256);

    function getAuctionDebt(uint256 _auctionID) external view returns (uint256);

    function getAuctionDueIncentives(uint256 _auctionID) external view returns (uint256);

    function getAuctionStartTime(uint256 _auctionID) external view returns (uint256);

    function getAuctionEndTime(uint256 _auctionID) external view returns (uint256);

    function getHammerTimeDuration(uint256 _auctionID) external view returns (uint256);

    function getAuctionBidDecimals(uint256 _auctionID) external view returns (uint256);

    function getAuctionStepMin(uint256 _auctionID) external view returns (uint256);

    function getAuctionIncMin(uint256 _auctionID) external view returns (uint256);

    function getAuctionIncMax(uint256 _auctionID) external view returns (uint256);

    function getAuctionBidMultiplier(uint256 _auctionID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}