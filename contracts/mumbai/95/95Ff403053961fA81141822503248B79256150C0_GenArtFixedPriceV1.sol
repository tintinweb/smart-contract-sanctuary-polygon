// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IGenArtHub.sol";

contract GenArtFixedPriceV1 is ReentrancyGuard {
  event PricePerTokenInWeiUpdated(
      uint256 indexed _projectId,
      uint256 indexed _pricePerTokenInWei
  );

  error MaxMintsReached();
  error InvalidProject();
  error InvalidTokenId();
  error PausedProject();
  error NotAllowed();

  IGenArtHub public immutable genArtHubContract;

  string public constant minterType = "GenArtFixedPriceV1";

  uint256 constant SEED = 1_000_000;

  // Keep track of mints per wallet
  mapping(address => mapping(uint256 => uint256)) public projectMintCounter;
  mapping(uint256 => uint256) public projectMintLimit;

  // Keep track of mints per project
  mapping(uint256 => bool) public projectMaxHasBeenMinted;
  mapping(uint256 => uint256) public projectMaxMints;

  // Price
  mapping(uint256 => uint256) private projectIdToPricePerTokenInWei;
  mapping(uint256 => bool) private projectIdToPriceIsConfigured;

  modifier onlyHubWhitelisted() {
    if (!genArtHubContract.whitelist(msg.sender)) revert NotAllowed();
    _;
  }

  modifier onlyArtist(uint256 _projectId) {
      if (msg.sender != genArtHubContract.projectIdToArtistAddress(_projectId)) revert NotAllowed();
      _;
  }

  constructor(address _genArtHubAddress) ReentrancyGuard() {
    genArtHubContract = IGenArtHub(_genArtHubAddress);
  }

  function updatePricePerTokenInWei(
      uint256 _projectId,
      uint256 _pricePerTokenInWei
  ) external onlyArtist(_projectId) {
      projectIdToPricePerTokenInWei[_projectId] = _pricePerTokenInWei;
      projectIdToPriceIsConfigured[_projectId] = true;
      emit PricePerTokenInWeiUpdated(_projectId, _pricePerTokenInWei);
  }

  function setProjectMintLimit(uint256 _projectId, uint8 _limit) public onlyHubWhitelisted {
    projectMintLimit[_projectId] = _limit;
  }

  function setProjectMaxMints(uint256 _projectId) public onlyHubWhitelisted {
        uint256 maxMints;
        uint256 mints;
        (,mints,maxMints,,,) = genArtHubContract.projectInfo(_projectId);
        projectMaxMints[_projectId] = maxMints;

        if (mints < maxMints) {
            projectMaxHasBeenMinted[_projectId] = false;
        }
  }

  function purchase(uint256 _projectId) public payable returns (uint256 _tokenId) {
    return purchaseTo(msg.sender, _projectId);
  }

  function purchaseTo(address _to, uint256 _projectId) public payable nonReentrant
    returns (uint256 _tokenId) {

      // max amount of mints have been minted
      if(projectMaxHasBeenMinted[_projectId]) revert MaxMintsReached();

      // if we have a mint limit
      if (projectMintLimit[_projectId] > 0) {
        if (projectMintCounter[msg.sender][_projectId] < projectMintLimit[_projectId]) {
          projectMintCounter[msg.sender][_projectId]++;
        } else {
          revert MaxMintsReached();
        }
      }

      // make sure your price is configured
      if (!projectIdToPriceIsConfigured[_projectId]) revert NotAllowed();

      // make sure the payment equals the price
      if (msg.value < projectIdToPricePerTokenInWei[_projectId]) revert NotAllowed();

      // token id
      uint256 tokenId = genArtHubContract.mint(_to, _projectId, msg.sender);

      if (projectMaxMints[_projectId] > 0 && tokenId % SEED == projectMaxMints[_projectId] - 1) {
        projectMaxHasBeenMinted[_projectId] = true;
      }

      _splitFunds(_projectId);

      return tokenId;
  }

  function _splitFunds(uint256 _projectId) internal {
    if (msg.value > 0) {
      uint256 pricePerTokenInWei = projectIdToPricePerTokenInWei[_projectId];

      uint256 refund = msg.value - pricePerTokenInWei;
      if (refund > 0) {
        (bool _success,) = msg.sender.call{value: refund}("");
        require(_success, "Refund failed");
      }

      uint256 treasuryAmount = (pricePerTokenInWei * genArtHubContract.treasuryPercentage()) / 100;

      if (treasuryAmount > 0) {
        (bool success_,) = genArtHubContract.treasuryAddress().call{value: treasuryAmount}("");
        require(success_, "Artist payment failed");
      }

      uint256 projectFunds = pricePerTokenInWei - treasuryAmount;
      uint256 additionalPayeeAmount;

      if (genArtHubContract.projectIdToAdditionalPayeePercentage(_projectId) > 0) {
        additionalPayeeAmount = (projectFunds * genArtHubContract.projectIdToAdditionalPayeePercentage(_projectId)) / 100;

        if (additionalPayeeAmount > 0) {
          (bool success_, ) = genArtHubContract.projectIdToAdditionalPayee(_projectId)
            .call{value: additionalPayeeAmount}("");

          require(success_, "Additional payment failed");
        }
      }

      uint256 creatorFunds = projectFunds - additionalPayeeAmount;
      if (creatorFunds > 0) {
        (bool success_, ) = genArtHubContract.projectIdToArtistAddress(_projectId)
          .call{value: creatorFunds}("");
        require(success_, "Artist payment failed");
      }
    }
  }

  function getPriceInfo(uint256 _projectId)
      external
      view
      returns (
          bool isConfigured,
          uint256 tokenPriceInWei,
          string memory currencySymbol,
          address currencyAddress
      )
  {
      isConfigured = projectIdToPriceIsConfigured[_projectId];
      tokenPriceInWei = projectIdToPricePerTokenInWei[_projectId];
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGenArtHub {
  event Mint(address indexed _to, uint256 indexed _tokenId);
  event ProxyUpdated(address indexed _minter);

  function nextProjectId() external view
    returns (uint256);

  function tokenIdToProjectId(uint256 _tokenId) external pure
    returns (uint256 _projectId);

  function whitelist(address minter) external view
    returns (bool);

  function projectIdToArtistAddress(uint256 _projectId) external view
    returns (address payable);

  function projectIdToAdditionalPayee(uint256 _projectId) external view
    returns (address payable);

  function projectIdToAdditionalPayeePercentage(uint256 _projectId) external view
    returns (uint256);

  function projectInfo(uint256 _projectId) external view
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

  function getRoyaltyData(uint256 _tokenId) external view
    returns (
        address artistAddress,
        address additionalPayee,
        uint256 additionalPayeePercentage,
        uint256 royaltyFeeByID
    );

  function mint(address _to, uint256 _projectId, address _by) external returns (uint256 tokenId);
}