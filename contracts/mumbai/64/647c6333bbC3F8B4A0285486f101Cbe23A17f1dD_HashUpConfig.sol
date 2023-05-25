// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/IHashUpConfig.sol";
import "./utilities/HashUpErrors.sol";

contract HashUpConfig is IHashUpConfig, Ownable {
    uint256 public buyFee = 125; // initial buy fee is 1.25%, 10000 basis
    uint256 public sellFee = 125; // initial sell fee is 1.25%, 10000 basis
    uint256 public maxFee = 2000; // max buy/sell fee cap, 20%, 10000 basis
    uint256 public maxRoyaltyFee = 20; // 20%

    address public treasury;

    function updateTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) {
            revert ZeroAddress();
        }
        treasury = newTreasury;
    }

    function updateFee(uint256 newBuyFee, uint256 newSellFee)
        external
        onlyOwner
    {
        if (newBuyFee >= maxFee) {
            revert InvalidBasisProvided(newBuyFee);
        }
        if (newSellFee >= maxFee) {
            revert InvalidBasisProvided(newSellFee);
        }
        buyFee = newBuyFee;
        sellFee = newSellFee;
    }

    function updateMaxFee(uint256 newMaxFee) external onlyOwner {
        maxFee = newMaxFee;
    }

    function updateMaxRoyaltyFee(uint256 newMaxRoyaltyFee) external onlyOwner {
        maxRoyaltyFee = newMaxRoyaltyFee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IHashUpConfig {
    function buyFee() external view returns (uint256);

    function sellFee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function maxRoyaltyFee() external view returns (uint256);

    function treasury() external view returns (address);

    function updateFee(uint256 newBuyFee, uint256 newSellFee) external;

    function updateTreasury(address newTreasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Common Errors
error ZeroAddress();
error WithdrawalFailed();
error NoTrailingSlash(string _uri);
error InvalidArgumentsProvided();
error PriceMustBeAboveZero(uint256 _price);
error PermissionDenied();
error InvalidTokenId(uint256 _tokenId);
error TransferFailed(address recipient, uint amount);

// HashUp Base Contract
error NotTokenOwnerOrInsufficientAmount();
error NotApprovedMarketplace();
error ZeroAmountTransfer();
error TransactionError();
error InvalidAddressProvided(address _invalidAddress);

// PreAuthorization Contract
error NoAuthorizedOperator();

// Auction Contract
error NotExistingAuction(uint256 _auctionId);
error NotExistingBidder(address _bidder);
error NotEnoughPriceToBid();
error SelfBid();
error ExpiredAuction(uint256 _auctionId);
error RunningAuction(uint256 _auctionId);
error NotAuctionCreatorOrOwner();
error InvalidAmountOfTokens(uint256 _amount);
error AlreadyWithdrawn(uint256 _auctionId, address _bidder);
error NotBidder(uint256 _auctionId, address _bidder);

// Offer Contract
error NotExistingOffer(uint256 _offerId);
error PriceMustBeDifferent(uint256 _price);
error InsufficientETHProvided(uint256 _value);
error InvalidOfferState();

// Marketplace Contract
error NotListed();
error NotEnoughEthProvided(uint256 providedEth, uint256 requiredEth);
error NotTokenOwner();
error NotTokenSeller();
error TokenSeller();
error InvalidBasisProvided(uint256 _newBasis);

// HashUp Single Token Contract
error MaxBatchMintLimitExceeded();
error AlreadyExistentToken();
error NotApprovedOrOwner();
error MaxMintLimitExceeded();

// HashUp Token Manager Contract
error AlreadyRegisteredAddress();

// HashUpSignature
error HashUsed(bytes32 _hash);
error SignatureFailed(address _signatureAddress, address _signer);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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