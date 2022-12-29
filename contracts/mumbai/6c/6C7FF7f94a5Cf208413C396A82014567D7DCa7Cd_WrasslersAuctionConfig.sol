// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../Libraries/GBM/GBM/GBMInitiator.sol";

contract WrasslersAuctionConfig is Ownable, GBMInitiator {
    address public auctionContract;
    uint256 public auctionRound;

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

    function addAuctionRound(uint256 startTime, uint256 endTime) external onlyOwner {
        setStartTime(startTime);
        setEndTime(endTime);
        ++auctionRound;
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
pragma solidity ^0.8.9;

import "./IGBMInitiator.sol";

/// @title GBM auction contract Initiator
/// @dev Implementation of IGBM. Feel free to cook up your own implementation for more complex patterns.
/// @author Guillaume Gonnaud
contract GBMInitiator is IGBMInitiator {
    // To future developpers: All the getters are called AFTER the auction ID has been generated and hence you can lookup
    // token_ID/Token contract/token kind using the main GBM contract getters(auctionId) if you want to return determinstic values

    address internal _owner;

    uint256 internal auction_startTime; // _auctionID => timestamp
    uint256 internal auction_endTime; // _auctionID => timestamp
    uint256 internal auction_hammerTimeDuration; // _auctionID => duration in seconds
    uint256 internal auction_bidDecimals; // _auctionID => bidDecimals
    uint256 internal auction_stepMin; // _auctionID => stepMin
    uint256 internal auction_incMin; // _auctionID => minimal earned incentives
    uint256 internal auction_incMax; // _auctionID => maximal earned incentives
    uint256 internal auction_bidMultiplier; // _auctionID => bid incentive growth multiplier

    constructor() {
        _owner = msg.sender;
    }

    function getStartTime(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_startTime);
    }

    function getEndTime(
        uint256 /* _auctionID */
    ) external view override returns (uint256) {
        return (auction_endTime);
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

    function setStartTime(uint256 _auction_startTime) internal {
        require(_owner == msg.sender);
        auction_startTime = _auction_startTime;
    }

    function setEndTime(uint256 _auction_endTime) internal {
        require(_owner == msg.sender);
        auction_endTime = _auction_endTime;
    }

    function setHammerTimeDuration(uint256 _auction_hammerTimeDuration) internal {
        require(_owner == msg.sender);
        auction_hammerTimeDuration = _auction_hammerTimeDuration;
    }

    function setBidDecimals(uint256 _auction_bidDecimals) internal {
        require(_owner == msg.sender);
        auction_bidDecimals = _auction_bidDecimals;
    }

    function setStepMin(uint256 _auction_stepMin) internal {
        require(_owner == msg.sender);
        auction_stepMin = _auction_stepMin;
    }

    function setIncMin(uint256 _auction_incMin) internal {
        require(_owner == msg.sender);
        auction_incMin = _auction_incMin;
    }

    function setIncMax(uint256 _auction_incMax) internal {
        require(_owner == msg.sender);
        auction_incMax = _auction_incMax;
    }

    function setBidMultiplier(uint256 _auction_bidMultiplier) internal {
        require(_owner == msg.sender);
        auction_bidMultiplier = _auction_bidMultiplier;
    }
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

// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity ^0.8.9;

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