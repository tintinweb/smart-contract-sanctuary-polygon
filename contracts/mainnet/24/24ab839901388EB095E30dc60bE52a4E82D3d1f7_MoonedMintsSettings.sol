/**
 *Submitted for verification at polygonscan.com on 2022-05-02
*/

// SPDX-License-Identifier: AGPLv3"

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/interfaces/IMoonedMintsSettings.sol


 
pragma solidity ^0.8.0;


interface IMoonedMintsSettings {
    function treasure() external view returns(address);
    function erc20Impl() external view returns(address);
    function crowdsaleImpl() external view returns(address);
    function auctionImpl() external view returns(address);
    function crowdsaleTreasurePercent() external view returns(uint256);
    function transferTreasurePercent() external view returns(uint256);
    function auctionQuorumPercent() external view returns(uint256);
    function auctionNextBidPercent() external view returns(uint256);
    function auctionDuration() external view returns(uint256);
    function auctionMinReservePercent() external view returns(uint256);
    function auctionMaxReservePercent() external view returns(uint256);

    event SetTreasure(address, address);
    event SetErc20Impl(address, address);
    event SetCrowdsaleImpl(address, address);
    event SetAuctionImpl(address, address);
    event SetCrowdsaleTreasurePercent(address, uint256);
    event SetTransferTreasurePercent(address, uint256);
    event SetAuctionQuorumPercent(address, uint256);
    event SetAuctionNextBidPercent(address, uint256);
    event SetAuctionDuration(address, uint256);
    event SetAuctionMinReservePercent(address, uint256);
    event SetAuctionMaxReservePercent(address, uint256);

    function setTreasure(address treasure_) external;
    function setErc20Impl(address erc20Impl_) external;
    function setCrowdsaleImpl(address crowdsale_) external;
    function setAuctionImpl(address erc20Impl_) external;
    function setCrowdsaleTreasurePercent(uint256 crowdsalePercent_) external;
    function setTransferTreasurePercent(uint256 treasurePercent_) external;
    function setAuctionQuorumPercent(uint256 auctionQuorumPercent_) external;
    function setAuctionNextBidPercent(uint256 auctionNextBidPercent_) external;
    function setAuctionDuration(uint256 auctionDuration_) external;
    function setAuctionMinReservePercent(uint256 auctionDuration_) external;
    function setAuctionMaxReservePercent(uint256 auctionDuration_) external;
}


// File contracts/utils/MoonedMintsConstants.sol


pragma solidity ^0.8.0;


library MoonedMintsConstants {
    uint256 public constant ERC20_CROWDSALE_TREASURE_PERCENT = 5;
    uint256 public constant ERC20_TRANSFER_TREASURE_PERCENT = 3;
    uint256 public constant AUCTION_QUORUM_PERCENT = 50;
    uint256 public constant AUCTION_NEXT_BID_PERCENT = 5;
    uint256 public constant AUCTION_DURATION = 7 days;
    uint256 public constant AUCTION_MIN_RESERVE_PERCENT = 80;
    uint256 public constant AUCTION_MAX_RESERVE_PERCENT = 120;
}


// File contracts/MoonedMintsSettings.sol


pragma solidity ^0.8.0;
contract MoonedMintsSettings is
    Context,
    IMoonedMintsSettings,
    Ownable {
    address public override treasure;
    address public override erc20Impl;
    address public override crowdsaleImpl;
    address public override auctionImpl;
    uint256 public override crowdsaleTreasurePercent;
    uint256 public override transferTreasurePercent;
    uint256 public override auctionQuorumPercent;
    uint256 public override auctionNextBidPercent;
    uint256 public override auctionDuration;
    uint256 public override auctionMinReservePercent;
    uint256 public override auctionMaxReservePercent;

    constructor(
        address treasure_,
        address erc20Impl_,
        address crowdsaleImpl_,
        address auctionImpl_) {
        treasure = treasure_;
        erc20Impl = erc20Impl_;
        crowdsaleImpl = crowdsaleImpl_;
        auctionImpl = auctionImpl_;
        crowdsaleTreasurePercent = MoonedMintsConstants.ERC20_CROWDSALE_TREASURE_PERCENT;
        transferTreasurePercent = MoonedMintsConstants.ERC20_TRANSFER_TREASURE_PERCENT;
        auctionQuorumPercent = MoonedMintsConstants.AUCTION_QUORUM_PERCENT;
        auctionNextBidPercent = MoonedMintsConstants.AUCTION_NEXT_BID_PERCENT;
        auctionDuration = MoonedMintsConstants.AUCTION_DURATION;
        auctionMinReservePercent = MoonedMintsConstants.AUCTION_MIN_RESERVE_PERCENT;
        auctionMaxReservePercent = MoonedMintsConstants.AUCTION_MAX_RESERVE_PERCENT;
    }

    function setTreasure(address treasure_) external override onlyOwner {
        require(treasure_ != address(0), "TDS: invalid input");
        treasure = treasure_;
        emit SetTreasure(_msgSender(), treasure_);
    }

    function setErc20Impl(address erc20Impl_) external override onlyOwner {
        require(erc20Impl_ != address(0), "TDS: invalid input");
        erc20Impl = erc20Impl_;
        emit SetErc20Impl(_msgSender(), erc20Impl_);
    }

    function setCrowdsaleImpl(address crowdsaleImpl_) external override onlyOwner {
        require(crowdsaleImpl_ != address(0), "TDS: invalid input");
        crowdsaleImpl = crowdsaleImpl_;
        emit SetCrowdsaleImpl(_msgSender(), crowdsaleImpl_);
    }

    function setAuctionImpl(address auctionImpl_) external override onlyOwner {
        require(auctionImpl_ != address(0), "TDS: invalid input");
        auctionImpl = auctionImpl_;
        emit SetAuctionImpl(_msgSender(), auctionImpl_);
    }

    function setCrowdsaleTreasurePercent(uint256 crowdsaleTreasurePercent_) external override onlyOwner {
        crowdsaleTreasurePercent = crowdsaleTreasurePercent_;
        emit SetCrowdsaleTreasurePercent(_msgSender(), crowdsaleTreasurePercent_);
    }

    function setTransferTreasurePercent(uint256 transferTreasurePercent_) external override onlyOwner {
        transferTreasurePercent = transferTreasurePercent_;
        emit SetTransferTreasurePercent(_msgSender(), transferTreasurePercent_);
    }

    function setAuctionQuorumPercent(uint256 auctionQuorumPercent_) external override onlyOwner {
        auctionQuorumPercent = auctionQuorumPercent_;
        emit SetAuctionQuorumPercent(_msgSender(), auctionQuorumPercent_);
    }

    function setAuctionNextBidPercent(uint256 auctionNextBidPercent_) external override onlyOwner {
        auctionNextBidPercent = auctionNextBidPercent_;
        emit SetAuctionNextBidPercent(_msgSender(), auctionNextBidPercent_);
    }

    function setAuctionDuration(uint256 auctionDuration_) external override onlyOwner {
        auctionDuration = auctionDuration_;
        emit SetAuctionDuration(_msgSender(), auctionDuration_);
    }

    function setAuctionMinReservePercent(uint256 auctionMinReservePercent_) external override onlyOwner {
        auctionMinReservePercent = auctionMinReservePercent_;
        emit SetAuctionMinReservePercent(_msgSender(), auctionMinReservePercent_);
    }

    function setAuctionMaxReservePercent(uint256 auctionMaxReservePercent_) external override onlyOwner {
        auctionMaxReservePercent = auctionMaxReservePercent_;
        emit SetAuctionMaxReservePercent(_msgSender(), auctionMaxReservePercent_);
    }
}