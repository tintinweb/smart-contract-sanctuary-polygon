// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPragmaHub.sol";

contract PragmaDutchAuctionV1 is ReentrancyGuard, Ownable {
  // Auction details updated for project `projectId`
  event SetAuctionDetails (
    uint256 indexed _projectId,
    uint256 _auctionTimestampStart,
    uint256 _auctionTimestampEnd,
    uint256 _startPrice,
    uint256 _basePrice
  );

  /// Auction details cleared for project `projectId`.
  event ResetAuctionDetails(uint256 indexed projectId);

  /// Minimum allowed auction length updated
  event MinAuctionLengthSecondsUpdated(
    uint256 _minAuctionLengthSeconds
  );

  error MaxMintsReached();
  error InvalidProject();
  error InvalidTokenId();
  error PausedProject();
  error NotAllowed();

  IPragmaHub public immutable pragmaHubContract;

  string public constant minterType = "DutchAuctionV1";

  uint256 private constant SEED = 1_000_000;

  // Keep track of mints per project
  mapping(uint256 => bool) public projectMaxHasBeenMinted;
  mapping(uint256 => uint256) public projectMaxMints;

  uint256 public minAuctionLengthSeconds = 3600;

  // projectId => auction settings
  mapping(uint256 => AuctionParams) public projectAuctionSettings;
  struct AuctionParams {
    uint256 timestampStart;
    uint256 timestampEnd;
    uint256 startPrice;
    uint256 basePrice;
  }

  modifier onlyHubWhitelisted() {
    if (!pragmaHubContract.whitelist(_msgSender())) revert NotAllowed();
    _;
  }

  modifier onlyArtist(uint256 _projectId) {
    if (_msgSender() != pragmaHubContract.projectIdToArtistAddress(_projectId))
      revert NotAllowed();
    _;
  }

  constructor(address _pragmaHubAddress) ReentrancyGuard() {
    pragmaHubContract = IPragmaHub(_pragmaHubAddress);
  }


  function setProjectMaxMints(uint256 _projectId) public onlyHubWhitelisted {
    uint256 maxMints;
    uint256 mints;
    (, mints, maxMints, , , ) = pragmaHubContract.projectInfo(_projectId);
    projectMaxMints[_projectId] = maxMints;

    if (mints < maxMints) {
      projectMaxHasBeenMinted[_projectId] = false;
    }
  }

  // set the minimum auction lengt in seconds
  function setMinAuctionLengthSeconds(uint256 _minAuctionLengthSeconds) external onlyHubWhitelisted {
    minAuctionLengthSeconds = _minAuctionLengthSeconds;
    emit MinAuctionLengthSecondsUpdated(_minAuctionLengthSeconds);
  }

  function setAuctionDetails(
    uint256 _projectId,
    uint256 _auctionTimestampStart,
    uint256 _auctionTimestampEnd,
    uint256 _startPrice,
    uint256 _basePrice
  ) external onlyArtist(_projectId) {
    AuctionParams memory auctionParams = projectAuctionSettings[_projectId];

    require(auctionParams.timestampStart == 0 || block.timestamp < auctionParams.timestampStart, "Can't modify mid-auction");

    require(block.timestamp < _auctionTimestampStart, "Only future timestamps");

    require(_auctionTimestampEnd > _auctionTimestampStart, "Auction end must be greater than auction start");

    require(_auctionTimestampEnd >= _auctionTimestampStart + minAuctionLengthSeconds, "Auction length must be at least minimum auction lengt in seconds");

    require(_startPrice > _basePrice, "Auction start price must be greater than the auction end price");

    projectAuctionSettings[_projectId] = AuctionParams(
      _auctionTimestampStart,
      _auctionTimestampEnd,
      _startPrice,
      _basePrice
    );

    emit SetAuctionDetails(
      _projectId,
      _auctionTimestampStart,
      _auctionTimestampEnd,
      _startPrice,
      _basePrice
    );
  }

  function resetAuctionDetails(uint256 _projectId) external onlyHubWhitelisted {
    delete projectAuctionSettings[_projectId];
    emit ResetAuctionDetails(_projectId);
  }

  function purchase(uint256 _projectId) public payable returns (uint256 _tokenId) {
    return purchaseTo(_msgSender(), _projectId);
  }

  function purchaseTo(address _to, uint256 _projectId)
    public
    payable
    nonReentrant returns (uint256 _tokenId) {
      if (projectMaxHasBeenMinted[_projectId]) revert MaxMintsReached();

      uint256 currentPriceInWei = _getPrice(_projectId);
      if (msg.value < currentPriceInWei) revert NotAllowed();

      uint256 tokenId = pragmaHubContract.mint(_to, _projectId, _msgSender());

      if (
        projectMaxMints[_projectId] > 0 &&
        tokenId % SEED == projectMaxMints[_projectId] - 1
      ) {
        projectMaxHasBeenMinted[_projectId] = true;
      }

      _splitFunds(_projectId, currentPriceInWei);

      return tokenId;
  }

  function _splitFunds(uint256 _projectId, uint256 _currentPriceInWei) internal {
    if (msg.value > 0) {
      uint256 refund = msg.value - _currentPriceInWei;

      if (refund > 0) {
        (bool success_,) = msg.sender.call{value: refund}("");
        require(success_, "Refund failed");
      }

      uint256 treasuryAmount = (_currentPriceInWei *
        pragmaHubContract.treasuryPercentage()) / 100;
      if (treasuryAmount > 0) {
        (bool success_, ) = pragmaHubContract.treasuryAddress().call{
          value: treasuryAmount
        }("");
        require(success_, "Treasury payment failed");
      }

      uint256 projectFunds = _currentPriceInWei - treasuryAmount;
      uint256 additionalPayeeAmount;

      if (
        pragmaHubContract.projectIdToAdditionalPayeePercentage(_projectId) > 0
      ) {
        additionalPayeeAmount =
          (projectFunds *
            pragmaHubContract.projectIdToAdditionalPayeePercentage(
              _projectId
            )) /
          100;

        if (additionalPayeeAmount > 0) {
          (bool success_, ) = pragmaHubContract
            .projectIdToAdditionalPayee(_projectId)
            .call{value: additionalPayeeAmount}("");

          require(success_, "Additional payment failed");
        }
      }

      uint256 creatorFunds = projectFunds - additionalPayeeAmount;
      if (creatorFunds > 0) {
        (bool success_, ) = pragmaHubContract
          .projectIdToArtistAddress(_projectId)
          .call{value: creatorFunds}("");
        require(success_, "Artist payment failed");
      }
    }
  }

  function _getPrice(uint256 _projectId) private view returns (uint256) {
    AuctionParams memory auctionParams = projectAuctionSettings[_projectId];

    require(block.timestamp > auctionParams.timestampStart, "auction not yet started");

    if (block.timestamp >= auctionParams.timestampEnd) {
      require(auctionParams.timestampEnd > 0, "Only configured auctions");
      return auctionParams.basePrice;
    }

    uint256 elapsedTime = block.timestamp - auctionParams.timestampStart;
    uint256 duration = auctionParams.timestampEnd - auctionParams.timestampStart;
    uint256 startToEndDifference = auctionParams.startPrice - auctionParams.basePrice;

    return auctionParams.startPrice - ((elapsedTime * startToEndDifference) / duration);
  }

  function getPriceInfo(uint256 _projectId) external view returns (
    bool isConfigured,
    uint256 tokenPriceInWei,
    string memory currencySymbol,
    address currencyAddress
  ) {

    AuctionParams memory auctionParams = projectAuctionSettings[_projectId];

    isConfigured = (auctionParams.startPrice > 0);

    if (block.timestamp <= auctionParams.timestampStart) {
      tokenPriceInWei = auctionParams.startPrice;
    } else if (auctionParams.timestampEnd == 0) {
      tokenPriceInWei = 0;
    } else {
      tokenPriceInWei = _getPrice(_projectId);
    }

    currencySymbol = "MATIC";
    currencyAddress = address(0);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPragmaHub {
  event Mint(address indexed _to, uint256 indexed _tokenId);
  event ProxyUpdated(address indexed _minter);

  function nextProjectId() external view returns (uint256);

  function tokenIdToProjectId(uint256 _tokenId)
    external
    pure
    returns (uint256 _projectId);

  function whitelist(address minter) external view returns (bool);

  function projectIdToArtistAddress(uint256 _projectId)
    external
    view
    returns (address payable);

  function projectIdToAdditionalPayee(uint256 _projectId)
    external
    view
    returns (address payable);

  function projectIdToAdditionalPayeePercentage(uint256 _projectId)
    external
    view
    returns (uint256);

  function projectInfo(uint256 _projectId)
    external
    view
    returns (
      address,
      uint256,
      uint256,
      bool,
      address,
      uint256
    );

  function treasuryAddress() external view returns (address payable);

  function treasuryPercentage() external view returns (uint256);

  function getRoyaltyData(uint256 _tokenId)
    external
    view
    returns (
      address artistAddress,
      address additionalPayee,
      uint256 additionalPayeePercentage,
      uint256 royaltyFeeByID
    );

  function mint(
    address _to,
    uint256 _projectId,
    address _by
  ) external returns (uint256 tokenId);
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