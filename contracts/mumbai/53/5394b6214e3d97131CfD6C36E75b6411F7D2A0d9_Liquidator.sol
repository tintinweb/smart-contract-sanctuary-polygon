//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import ".././interfaces/HTokenI.sol";
import ".././interfaces/LiquidatorI.sol";
import ".././interfaces/MarketplaceI.sol";
import ".././interfaces/HivemindI.sol";
import ".././utils/ErrorReporter.sol";
import "./LiquidatorModuleNFT20.sol";
import "./LiquidatorModuleNFTX.sol";
import "./LiquidatorStorage.sol";

/**
 * @title Honey Finance Liquidator v4
 * @notice Execute liquidations for HToken IRM contracts
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:contributor m4rio
 */
contract Liquidator is
  IERC721Receiver,
  AccessControl,
  ReentrancyGuard,
  Pausable,
  LiquidatorI,
  LiquidatorStorage,
  LiquidatorModuleNFT20,
  LiquidatorModuleNFTX
{
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @notice this corresponds to 1.0.0
  uint256 public constant version = 1_000_000;

  // ----- Key External Addresses -----

  /// @notice Honey Finance Treasury
  address public treasury;

  /// @notice Hivemind address
  HivemindI public hivemind;

  // ----- State Variables -----

  /// @notice HToken to address of its underlying ERC20
  mapping(HTokenI => IERC20) public poolToUnderlyingToken;

  /// @notice HToken to address of its collateral ERC721
  mapping(HTokenI => IERC721) public poolToCollateralToken;

  /// @notice List of registered underlying tokens
  EnumerableSet.AddressSet internal registeredUnderlyingTokens;

  /// @notice List of registered pools
  EnumerableSet.AddressSet internal registeredPools;

  // ----- Events -----

  event MarketplaceUpdated(MarketplaceI indexed _oldMarketplace, MarketplaceI indexed _newMarketplace);
  event HTokenInitialized(address indexed _hToken, address indexed _underlying, address indexed _collateral);
  event TokenSwept(IERC20 indexed _token, uint256 _qty);
  event ProfitsWithdrawn(IERC20 indexed _token, uint256 _qty);
  event NFTWithdrawn(address indexed _hToken, IERC721 indexed _collateralToken, uint256 _collateralId);
  event LiquidatorPaused(bool _paused);
  event TreasuryUpdated(address _oldTreasury, address _newTreasury);
  event HivemindUpdated(HivemindI _oldHivemind, address _newHivemind);

  // ----- Construction -----

  /**
   * @param _swapRouter Uniswap V2 compliant swap router
   * @param _treasury   Address that will receive profits and swept tokens
   */
  constructor(
    IUniswapV2Router02 _swapRouter,
    address _treasury,
    HivemindI _hivemind
  ) LiquidatorStorage(_swapRouter) {
    if (address(_swapRouter) == address(0)) revert WrongParams();
    if (_treasury == address(0)) revert WrongParams();
    if (address(_hivemind) == address(0)) revert WrongParams();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(INITIALIZER_ROLE, msg.sender);
    _grantRole(LIQUIDATOR_ROLE, msg.sender);
    _grantRole(SWAPPER_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);

    treasury = _treasury;
    hivemind = _hivemind;
  }

  // ----- Configuration Functions -----

  /**
   * @notice  Perform the setup to handle liquidations from the given HToken
   * @param   _hToken address of the hToken to setup
   */
  function _initializeHToken(HTokenI _hToken) external nonReentrant onlyRole(INITIALIZER_ROLE) {
    if (!hivemind.marketExists(_hToken)) revert Uninitialized();
    if (registeredPools.contains(address(_hToken))) revert Initialized();

    if (!_hToken.supportsInterface(type(HTokenI).interfaceId)) revert WrongParams();

    // Add underlyings to mapping
    IERC20 underlyingToken = _hToken.underlyingToken();
    IERC721 collateralToken = _hToken.collateralToken();
    poolToUnderlyingToken[_hToken] = underlyingToken;
    poolToCollateralToken[_hToken] = collateralToken;
    registeredUnderlyingTokens.add(address(underlyingToken));
    registeredPools.add(address(_hToken));

    // Unlimited approve the underlying token of the hToken
    underlyingToken.safeIncreaseAllowance(address(_hToken), type(uint256).max);

    emit HTokenInitialized(address(_hToken), address(underlyingToken), address(collateralToken));
  }

  // ----- View Functions -----

  /**
   * @notice  View whether an ERC-20 token is registered as an underlying token in this contract
   * @param   _token Address of the ERC-20 token in question
   * @return  True if registered
   */
  function isRegisteredUnderlying(address _token) external view override returns (bool) {
    return registeredUnderlyingTokens.contains(address(_token));
  }

  /**
   * @notice  View whether an hToken is registered in this contract
   * @param   _hToken Address of the hToken in question
   * @return  True if registered
   */
  function isRegisteredHToken(address _hToken) external view override returns (bool) {
    return registeredPools.contains(address(_hToken));
  }

  // ----- Transfer Hook -----

  /**
   * @notice ERC721 safeTransferFrom transfer hook
   * @dev Will only return the magic value if data contains a valid encoded address of HToken contract
   * @inheritdoc IERC721Receiver
   */
  function onERC721Received(
    address,
    address,
    uint256 _tokenId,
    bytes calldata data
  ) public virtual override returns (bytes4) {
    if (data.length > 0) {
      // Data must contain encoded address of the HToken contract
      // Decode data to retrieve address
      address reconstructedAddress = abi.decode(data, (address));

      // Legitimate safeTransferFrom will come from token contract
      IERC721 collateralToken = poolToCollateralToken[HTokenI(reconstructedAddress)];

      if (address(collateralToken) == address(0)) revert Uninitialized();
      if (msg.sender != address(collateralToken)) revert Unauthorized();

      // Check that the NFT was actually transferred
      if (collateralToken.ownerOf(_tokenId) != address(this)) revert Unauthorized();

      marketplace.toggleLiquidation(HTokenI(reconstructedAddress), _tokenId, true);

      // approving the marketplace to transfer this token
      collateralToken.approve(address(marketplace), _tokenId);

      return this.onERC721Received.selector;
    } else {
      return bytes4(0);
    }
  }

  // ----- AMM Liquidation Hooks -----

  /**
   * @dev     Called before NFT20 liquidation. Should handle auctions, refunding, and any other logic.
   * @param   _hToken           Contract address of the hToken
   * @param   _collateralId     NFT tokenId
   * @return  (Collateral ERC-721 address, vault address)
   */
  function _NFT20PreLiquidationHook(HTokenI _hToken, uint256 _collateralId) internal override whenNotPaused returns (IERC721, address) {
    // Only if HToken has been initialized
    if (address(_hToken) == address(0)) revert LiquidatorError(Error.TOKEN_LOOKUP_ERROR);
    if (!registeredPools.contains(address(_hToken))) revert Uninitialized();

    IERC721 collateralToken = poolToCollateralToken[_hToken];

    // Only if NFT20 pair exists
    address pair = poolToNiftyPair[_hToken];
    if (pair == address(0)) revert LiquidatorError(Error.NFT20_PAIR_NOT_FOUND);

    // Only against active deposit coupons
    if (_hToken.getSpecificCouponByCollateralId(_collateralId).active != COUPON_ACTIVE) revert InvalidCoupon();

    // May only execute if this contract owns the relevant NFT
    if (collateralToken.ownerOf(_collateralId) != address(this)) revert LiquidatorError(Error.TOKEN_NOT_PRESENT);

    // Update marketplace
    marketplace.toggleLiquidation(_hToken, _collateralId, false);

    return (collateralToken, pair);
  }

  /**
   * @dev     Called before NFTX droplet swap. Should handle auctions, refunding, and any other logic.
   * @param   _hToken           Contract address of the hToken
   * @param   _collateralId     NFT tokenId
   * @return  (Collateral ERC-721 address, underlying ERC-20 address)
   */
  function _NFT20PreSwapHook(HTokenI _hToken, uint256 _collateralId) internal view override returns (IERC721, IERC20) {
    IERC20 underlyingToken = poolToUnderlyingToken[_hToken];
    IERC721 collateralToken = poolToCollateralToken[_hToken];

    // Only if HToken has been initialized
    if (!registeredPools.contains(address(_hToken))) revert Uninitialized();
    if (address(underlyingToken) == address(0)) revert Uninitialized();

    HTokenI.Coupon memory activeCoupon = _hToken.getSpecificCouponByCollateralId(_collateralId);

    // Only against active coupons
    if (activeCoupon.active != COUPON_ACTIVE) revert InvalidCoupon();

    return (collateralToken, underlyingToken);
  }

  /**
   * @dev     Called before NFTX liquidation. Should handle auctions, refunding, and any other logic.
   * @param   _hToken Contract address of the HToken
   * @param   _collateralId NFT tokenId
   * @param   _vaultIndex 0 if only one vault exists, otherwise index of the desired vault in the address[] mapping of poolToNFTXVaults
   * @return  (Collateral ERC-721 address, vault address)
   */
  function _NFTXPreLiquidationHook(
    HTokenI _hToken,
    uint256 _collateralId,
    uint256 _vaultIndex
  ) internal override whenNotPaused returns (IERC721, address) {
    IERC20 underlyingToken = poolToUnderlyingToken[_hToken];
    IERC721 collateralToken = poolToCollateralToken[_hToken];

    // Only if HToken has been initialized
    if (address(_hToken) == address(0)) revert LiquidatorError(Error.TOKEN_LOOKUP_ERROR);
    if (address(underlyingToken) == address(0)) revert Uninitialized();

    // Only if NFTX vault exists
    address[] storage vaults = poolToNFTXVaults[_hToken];
    if (vaults.length == 0) revert LiquidatorError(Error.NFTX_PAIR_NOT_FOUND);
    address pair = vaults[_vaultIndex];

    // Only against active deposit coupons
    HTokenI.Coupon memory activeCoupon = _hToken.getSpecificCouponByCollateralId(_collateralId);
    if (activeCoupon.active != COUPON_ACTIVE) revert InvalidCoupon();

    // May only execute if this contract owns the relevant NFT
    if (collateralToken.ownerOf(_collateralId) != address(this)) revert LiquidatorError(Error.TOKEN_NOT_PRESENT);

    // Update marketplace
    marketplace.toggleLiquidation(_hToken, _collateralId, false);

    return (collateralToken, pair);
  }

  /**
   * @dev     Called before NFTX droplet swap. Should handle auctions, refunding, and any other logic.
   * @param   _hToken         Contract address of the hToken
   * @param   _collateralId   NFT tokenId
   * @return  (Collateral ERC-721 address, underlying ERC-20 address)
   */
  function _NFTXPreSwapHook(HTokenI _hToken, uint256 _collateralId) internal view override returns (IERC721, IERC20) {
    IERC20 underlyingToken = poolToUnderlyingToken[_hToken];
    IERC721 collateralToken = poolToCollateralToken[_hToken];

    // Only if HToken has been initialized
    if (!registeredPools.contains(address(_hToken))) revert Uninitialized();
    if (address(underlyingToken) == address(0)) revert Uninitialized();

    HTokenI.Coupon memory activeCoupon = _hToken.getSpecificCouponByCollateralId(_collateralId);

    // Only against active coupons
    if (activeCoupon.active != COUPON_ACTIVE) revert InvalidCoupon();

    return (collateralToken, underlyingToken);
  }

  function postSwapHook(
    HTokenI _hToken,
    IERC20 _underlyingToken,
    uint256 _collateralId
  ) internal override(LiquidatorModuleNFT20, LiquidatorModuleNFTX) {
    super.postSwapHook(_hToken, _underlyingToken, _collateralId);
  }

  function swapExactUniV2(
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path
  ) internal override(LiquidatorModuleNFT20, LiquidatorModuleNFTX) returns (uint256[] memory) {
    return super.swapExactUniV2(_amountIn, _amountOutMin, _path);
  }

  // ----- Utility Functions -----

  /**
   * @dev     Transfer the given amount of the given underlying token to this contract
   * @dev     Requires this contract to be adequately approved to transfer the amount
   * @param   _underlyingToken  The ERC20 token to transfer
   * @param   _from             Address to transfer from
   * @param   _amount           The quantity of tokens to transfer
   * @return  Quantity of tokens actually transferred
   */
  function doUnderlyingTransferIn(
    IERC20 _underlyingToken,
    address _from,
    uint256 _amount
  ) internal returns (uint256) {
    uint256 balanceBefore = _underlyingToken.balanceOf(address(this));
    _underlyingToken.safeTransferFrom(_from, address(this), _amount);
    uint256 balanceAfter = _underlyingToken.balanceOf(address(this));

    if (balanceAfter < balanceBefore) revert Unexpected("Transfer invariant error");
    unchecked {
      return balanceAfter - balanceBefore;
    }
  }

  // ----- Administrative Functions -----

  function _manualCloseout(
    HTokenI _hToken,
    address _borrower,
    uint256 _collateralId
  ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    if (!registeredPools.contains(address(_hToken))) revert Uninitialized();

    _hToken.accrueInterest();
    uint256 debt = _hToken.getDebtForCollateral(_collateralId);
    if (debt == 0) revert LiquidatorError(Error.TOKEN_DEBT_NONEXISTENT);

    IERC20 underlyingToken = poolToUnderlyingToken[_hToken];

    // Intake funds
    doUnderlyingTransferIn(underlyingToken, msg.sender, debt);

    // Closeout and repay funds
    _hToken.closeoutLiquidation(_borrower, _collateralId);

    emit BorrowRepaid(address(_hToken), _borrower, _collateralId);
  }

  /**
   * @notice  Sweep accidental ERC-20 transfers to this contract, or withdraw droplets for OTC. Tokens are sent to treasury
   * @dev     Cannot be used to withdraw underlying tokens
   * @param   _token The address of the ERC-20 token to sweep
   */
  function _sweepToken(IERC20 _token) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    if (registeredUnderlyingTokens.contains(address(_token))) revert Unauthorized();

    uint256 balance = _token.balanceOf(address(this));
    if (balance > 0) {
      _token.safeTransfer(treasury, balance);
    }
    emit TokenSwept(_token, balance);
  }

  /**
   * @notice  Withdraw the profits earned by the protocol to the treasury
   * @dev     Cannot be used to withdraw dust tokens
   * @param   _token ERC-20 token to withdraw
   */
  function _withdrawProfits(IERC20 _token) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    if (!registeredUnderlyingTokens.contains(address(_token))) revert Unauthorized();

    uint256 profits = _token.balanceOf(address(this));

    if (profits > 0) {
      _token.safeTransfer(treasury, profits);
    }

    emit ProfitsWithdrawn(_token, profits);
  }

  /**
   * @notice  Withdraw an NFT to the treasury for use in OTC or manual closeout.
   * @param   _hToken         The hToken used to determine the collection
   * @param   _collateralId   The collateral id that we must withdraw
   */
  function _withdrawNFT(HTokenI _hToken, uint256 _collateralId) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
    IERC721 collateralToken = poolToCollateralToken[_hToken];

    marketplace.toggleLiquidation(_hToken, _collateralId, false);

    emit NFTWithdrawn(address(_hToken), collateralToken, _collateralId);
  }

  /**
   * @notice Set the marketplace module address
   * @param  _marketplace The new marketplace
   */
  function _setMarketplace(MarketplaceI _marketplace) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (address(_marketplace) == address(0)) revert WrongParams();
    emit MarketplaceUpdated(marketplace, _marketplace);
    marketplace = _marketplace;
  }

  /**
   * @notice Set the marketplace treasury address
   * @param  _newTreasury The new treasury address
   */
  function _setTreasury(address _newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_newTreasury == address(0)) revert WrongParams();
    emit TreasuryUpdated(treasury, _newTreasury);
    treasury = _newTreasury;
  }

  /**
   * @notice Set the hivemind address
   * @param  _newHivemind The new hivemind address
   */
  function _setHivemind(address _newHivemind) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_newHivemind == address(0)) revert WrongParams();
    emit HivemindUpdated(hivemind, _newHivemind);
    hivemind = HivemindI(_newHivemind);
  }

  /**
   * @notice  Pause the AMM liquidation functionality
   * @param   _pausing True to pause, false to unpause
   */
  function _pauseLiquidator(bool _pausing) external onlyRole(PAUSER_ROLE) {
    emit LiquidatorPaused(_pausing);
    if (_pausing) _pause();
    else _unpause();
  }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
import "./HTokenInternalI.sol";

/**
 * @title   Interface of HToken
 * @author  Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
interface HTokenI is HTokenInternalI {
  /**
   * @notice  Deposit underlying ERC-20 asset and mint hTokens
   * @dev     Pull pattern, user must approve the contract before calling. If _to is address(0) then it becomes msg.sender
   * @param   _amount   Quantity of underlying ERC-20 to transfer in
   * @param   _to       Target address to mint hTokens to
   */
  function depositUnderlying(uint256 _amount, address _to) external;

  /**
   * @notice  Redeem a specified amount of hTokens for their underlying ERC-20 asset
   * @param   _amount   Quantity of hTokens to redeem for underlying ERC-20
   */
  function redeem(uint256 _amount) external;

  /**
   * @notice  Withdraws the specified amount of underlying ERC-20 asset, consuming the minimum amount of hTokens necessary
   * @param   _amount   Quantity of underlying ERC-20 tokens to withdraw
   */
  function withdraw(uint256 _amount) external;

  /**
   * @notice  Deposit multiple specified tokens of the underlying ERC-721 asset and mint ERC-1155 deposit coupon NFTs
   * @dev     Pull pattern, user must approve the contract before calling.
   * @param   _collateralIds  Token IDs of underlying ERC-721 to be transferred in
   */
  function depositCollateral(uint256[] calldata _collateralIds) external;

  /**
   * @notice  Sender borrows assets from the protocol against the specified collateral asset, without a referral code
   * @dev     Collateral must be deposited first.
   * @param   _borrowAmount   Amount of underlying ERC-20 to borrow
   * @param   _collateralId   Token ID of underlying ERC-721 to be borrowed against
   */
  function borrow(uint256 _borrowAmount, uint256 _collateralId) external;

  /**
   * @notice  Sender borrows assets from the protocol against the specified collateral asset, using a referral code
   * @param   _borrowAmount   Amount of underlying ERC-20 to borrow
   * @param   _collateralId   Token ID of underlying ERC-721 to be borrowed against
   * @param   _referral       Referral code as a plain string
   * @param   _signature      Signed message authorizing the referral, provided by Honey Labs
   */
  function borrowReferred(
    uint256 _borrowAmount,
    uint256 _collateralId,
    string calldata _referral,
    bytes calldata _signature
  ) external;

  /**
   * @notice  Sender repays a borrow taken against the specified collateral asset
   * @dev     Pull pattern, user must approve the contract before calling.
   * @param   _repayAmount    Amount of underlying ERC-20 to repay
   * @param   _collateralId   Token ID of underlying ERC-721 to be repaid against
   */
  function repayBorrow(
    uint256 _repayAmount,
    uint256 _collateralId,
    address _to
  ) external;

  /**
   * @notice  Burn deposit coupon NFTs and withdraw the associated underlying ERC-721 NFTs
   * @param   _collateralIds  Token IDs of underlying ERC-721 to be withdrawn
   */
  function withdrawCollateral(uint256[] calldata _collateralIds) external;

  /**
   * @notice  Trigger transfer of an NFT to the liquidation contract
   * @param   _collateralId   Token ID of underlying ERC-721 to be liquidated
   */
  function liquidateBorrow(uint256 _collateralId) external;

  /**
   * @notice  Pay off the entirety of a liquidated debt position and burn the coupon
   * @dev     May only be called by the liquidator
   * @param   _borrower       Owner of the debt position
   * @param   _collateralId   Token ID of underlying ERC-721 to be closed out
   */
  function closeoutLiquidation(address _borrower, uint256 _collateralId) external;

  /**
   * @notice  Accrues all interest due to the protocol
   * @dev     Call this before performing calculations using 'totalBorrows' or other contract-wide quantities
   */
  function accrueInterest() external;

  // ----- Utility functions -----

  /**
   * @notice  Sweep accidental ERC-20 transfers to this contract.
   * @dev     Tokens are sent to the DAO for later distribution
   * @param   _token  The address of the ERC-20 token to sweep
   */
  function sweepToken(IERC20 _token) external;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface LiquidatorI is IERC721Receiver {
  function isRegisteredUnderlying(address _token) external view returns (bool);

  function isRegisteredHToken(address _hToken) external view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import ".././interfaces/HTokenI.sol";

interface MarketplaceI {
  struct Auction {
    IERC20 underlying;
    address highestBidder;
    uint256 highestBid;
    address[50] bidders; // Arrays are sorted ascending
    uint256[50] bids;
    uint256[50] unlockTimes;
  }

  function toggleLiquidation(
    HTokenI _hToken,
    uint256 _collateralId,
    bool _enabled
  ) external;

  function bidSingle(
    HTokenI _hToken,
    uint256 _collateralId,
    uint256 _amount
  ) external;

  function increaseBidSingle(
    HTokenI _hToken,
    uint256 _collateralId,
    uint256 _increaseAmount
  ) external;

  function bidCollection(HTokenI _hToken, uint256 _amount) external;

  function increaseBidCollection(HTokenI _hToken, uint256 _increaseAmount) external;

  function settleAuction(
    HTokenI _hToken,
    address _borrower,
    uint256 _collateralId
  ) external;

  function withdrawRefund(IERC20 _token) external returns (uint256);

  function cancelBidSingle(HTokenI _hToken, uint256 _collateralId) external;

  function cancelBidCollection(HTokenI _hToken) external;

  function viewMinimumNextBidSingle(HTokenI _hToken, uint256 _collateralId) external view returns (uint256);

  function viewMinimumNextBidCollection(HTokenI _hToken) external view returns (uint256);

  function viewAuctionSingle(HTokenI _hToken, uint256 _collateralId) external view returns (Auction memory);

  function viewAuctionCollection(HTokenI _hToken) external view returns (Auction memory);

  function viewAvailableRefund(IERC20 _token, address _user) external view returns (uint256);

  function viewUserBidSingle(
    address _user,
    HTokenI _hToken,
    uint256 _collateralId
  ) external view returns (uint256, uint256);

  function viewUserBidCollection(address _user, HTokenI _hToken) external view returns (uint256, uint256);

  function _refundAllBidsPerCollateral(HTokenI _hToken, uint256 _collateralId) external;

  function _refundAllBidsPerCollection(HTokenI _hToken) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./HTokenI.sol";
import "./PriceOracleI.sol";

/**
 * @title Interface of Hivemind
 * @author Honey Finance Labs
 * @custom:coauthor m4rio
 * @custom:contributor BowTiedPickle
 */
interface HivemindI {
  /**
   * @notice returns the oracle per market
   */
  function oracle(HTokenI _hToken) external view returns (PriceOracleI);

  /**
   * @notice Add assets to be included in account liquidity calculation
   * @param _hTokens The list of addresses of the hToken markets to be enabled
   */
  function enterMarkets(HTokenI[] calldata _hTokens) external;

  /**
   * @notice Removes asset from sender's account liquidity calculation
   * @dev Sender must not have an outstanding borrow balance in the asset,
   *  or be providing necessary collateral for an outstanding borrow.
   * @param _hToken The address of the asset to be removed
   */
  function exitMarket(HTokenI _hToken) external;

  /**
   * @notice Checks if the account should be allowed to deposit underlying in the market
   * @param _hToken The market to verify the redeem against
   * @param _depositor The account which that wants to deposit
   * @param _amount The number of underlying it wants to deposit
   */
  function depositAllowed(
    HTokenI _hToken,
    address _depositor,
    uint256 _amount
  ) external;

  /**
   * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
   * @param _hToken The market to verify the borrow against
   * @param _borrower The account which would borrow the asset
   * @param _collateralId collateral Id, aka the NFT token Id
   * @param _borrowAmount The amount of underlying the account would borrow
   */
  function borrowAllowed(
    HTokenI _hToken,
    address _borrower,
    uint256 _collateralId,
    uint256 _borrowAmount
  ) external;

  /**
   * @notice Checks if the account should be allowed to deposit a collateral
   * @param _hToken The market to verify the deposit of the collateral
   * @param _depositor The account which deposits the collateral
   * @param _collateralId The collateral token id
   */
  function depositCollateralAllowed(
    HTokenI _hToken,
    address _depositor,
    uint256 _collateralId
  ) external view;

  /**
   * @notice Checks if the account should be allowed to redeem tokens in the given market
   * @param _hToken The market to verify the redeem against
   * @param _redeemer The account which would redeem the tokens
   * @param _redeemTokens The number of hTokens to exchange for the underlying asset in the market
   */
  function redeemAllowed(
    HTokenI _hToken,
    address _redeemer,
    uint256 _redeemTokens
  ) external view;

  /**
   * @notice Checks if the collateral is at risk of being liquidated
   * @param _hToken The market to verify the liquidation
   * @param _collateralId collateral Id, aka the NFT token Id
   */
  function liquidationAllowed(HTokenI _hToken, uint256 _collateralId) external view;

  /**
   * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
   * @param _hToken The market to hypothetically redeem/borrow in
   * @param _account The account to determine liquidity for
   * @param _redeemTokens The number of tokens to hypothetically redeem
   * @param _borrowAmount The amount of underlying to hypothetically borrow
   * @param _collateralId collateral Id, aka the NFT token Id
   * @return liquidity - hypothetical account liquidity in excess of collateral requirements
   * @return shortfall - hypothetical account shortfall below collateral requirements
   * @return ltvShortfall - Loan to value shortfall, this is the max a user can borrow
   */
  function getHypotheticalAccountLiquidity(
    HTokenI _hToken,
    address _account,
    uint256 _collateralId,
    uint256 _redeemTokens,
    uint256 _borrowAmount
  )
    external
    view
    returns (
      uint256 liquidity,
      uint256 shortfall,
      uint256 ltvShortfall
    );

  /**
   * @notice Returns the assets an account has entered
   * @param _account The address of the account to pull assets for
   * @return A dynamic list with the assets the account has entered
   */
  function getAssetsIn(address _account) external view returns (HTokenI[] memory);

  /**
   * @notice Returns whether the given account is entered in the given asset
   * @param _hToken The hToken to check
   * @param _account The address of the account to check
   * @return True if the account is in the asset, otherwise false.
   */
  function checkMembership(HTokenI _hToken, address _account) external view returns (bool);

  /**
   * @notice Checks if the account should be allowed to transfer tokens in the given market
   * @param _hToken The market to verify the transfer against
   */
  function transferAllowed(HTokenI _hToken) external;

  /**
   * @notice Checks if the account should be allowed to repay a borrow in the given market
   * @param _hToken The market to verify the repay against
   * @param _repayAmount The amount of the underlying asset the account would repay
   * @param _collateralId collateral Id, aka the NFT token Id
   */
  function repayBorrowAllowed(
    HTokenI _hToken,
    uint256 _repayAmount,
    uint256 _collateralId
  ) external view;

  /**
   * @notice checks if withdrawal are allowed for this token id
   * @param _hToken The market to verify the withdrawal from
   * @param _collateralId what to pay for
   */
  function withdrawalCollateralAllowed(HTokenI _hToken, uint256 _collateralId) external view;

  /**
   * @notice Return the length of all markets
   * @return the length
   */
  function getAllMarketsLength() external view returns (uint256);

  /**
   * @notice checks if a market exists and it's listed
   * @param _hToken the market we check to see if it exists
   * @return bool true or false
   */
  function marketExists(HTokenI _hToken) external view returns (bool);

  /**
   * @notice Returns market data for a specific market
   * @param _hToken the market we want to retrieved Hivemind data
   * @return bool If the market is listed
   * @return uint256 Collateral Factor Mantissa
   * @return uint256 MAX Factor Mantissa
   */
  function getMarketData(HTokenI _hToken)
    external
    view
    returns (
      bool,
      uint256,
      uint256
    );

  /**
   * @notice checks if an underlying exists in the market
   * @param _underlying the underlying to check if exists
   * @param _start start index to verify if exists *NOT USED THIS VERSION*
   * @param _end start index to verify if exists *NOT USED THIS VERSION*
   * @return bool true or false
   */
  function underlyingExistsInMarkets(
    IERC20 _underlying,
    uint256 _start,
    uint256 _end
  ) external view returns (bool);

  /**
   * @notice returns the collateral factor for a given market
   * @param _hToken the market we want the market of
   * @return collateral factor in 1e18
   */
  function getCollateralFactor(HTokenI _hToken) external view returns (uint256);

  /**
   * @notice returns the borrow fee per market, accounts for referral
   * @param _hToken the market we want the borrow fee for
   * @param _referral referral code for Referral program of Honey Labs
   * @param _signature signed message provided by Honey Labs
   */
  function getBorrowFeePerMarket(
    HTokenI _hToken,
    string calldata _referral,
    bytes calldata _signature
  ) external view returns (uint256, bool);

  /**
   * @notice returns the borrow fee per market if provided a referral code, accounts for referral
   * @param _hToken the market we want the borrow fee for
   */
  function getReferralBorrowFeePerMarket(HTokenI _hToken) external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

error Unauthorized();
error AccrueInterestError(Error error);
error WrongParams();
error Unexpected(string error);
error InvalidCoupon();
error HivemindError(Error error);
error AdminError(Error error);
error MarketError(Error error);
error HTokenError(Error error);
error LiquidatorError(Error error);
error Paused();
error NotOwner();
error ExternalFailure(string error);
error Initialized();
error Uninitialized();
error OracleNotUpdated();
error TransferError();
error StalePrice();

/**
 * @title Errors reported across Honey Finance Labs contracts
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
enum Error {
  UNAUTHORIZED, //0
  INSUFFICIENT_LIQUIDITY,
  INVALID_COLLATERAL_FACTOR,
  MAX_MARKETS_IN,
  MARKET_NOT_LISTED,
  MARKET_ALREADY_LISTED, //5
  MARKET_CAP_BORROW_REACHED,
  MARKET_NOT_FRESH,
  PRICE_ERROR,
  BAD_INPUT,
  AMOUNT_ZERO, //10
  NO_DEBT,
  LIQUIDATION_NOT_ALLOWED,
  WITHDRAW_NOT_ALLOWED,
  INITIAL_EXCHANGE_MANTISSA,
  TRANSFER_ERROR, //15
  COUPON_LOOKUP,
  TOKEN_INSUFFICIENT_CASH,
  BORROW_RATE_TOO_BIG,
  NONZERO_BORROW_BALANCE,
  AMOUNT_TOO_BIG, //20
  AUCTION_NOT_ACTIVE,
  AUCTION_FINISHED,
  AUCTION_NOT_FINISHED,
  AUCTION_BID_TOO_LOW,
  AUCTION_NO_BIDS, //25
  CLAWBACK_WINDOW_EXPIRED,
  CLAWBACK_WINDOW_NOT_EXPIRED,
  REFUND_NOT_OWED,
  TOKEN_LOOKUP_ERROR,
  INSUFFICIENT_WINNING_BID, //30
  TOKEN_DEBT_NONEXISTENT,
  AUCTION_SETTLE_FORBIDDEN,
  NFT20_PAIR_NOT_FOUND,
  NFTX_PAIR_NOT_FOUND,
  TOKEN_NOT_PRESENT, //35
  CANCEL_TOO_SOON,
  AUCTION_USER_NOT_FOUND,
  NOT_FOUND,
  INVALID_MAX_LTV_FACTOR,
  BALANCE_INSUFFICIENT, //40
  ORACLE_NOT_SET
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import ".././interfaces/MarketplaceI.sol";

import ".././utils/ErrorReporter.sol";

/**
 * @title Liquidator Storage
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
contract LiquidatorStorage {
  event DropletsSwapped(address indexed _droplet, address[] _path, uint256 _amountIn, uint256 _amountOut);

  event BorrowRepaid(address indexed _hToken, address indexed _borrower, uint256 _collateralId);

  /// @notice Uniswap router used for swapping droplets
  IUniswapV2Router02 public immutable swapRouter;

  /// @notice The Marketplace contract used for selling the NFTs
  MarketplaceI public marketplace;

  // ----- Roles -----
  bytes32 public constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");
  bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

  // ----- Constants -----
  uint8 internal constant COUPON_UNINITIALIZED = 0;
  uint8 internal constant COUPON_INACTIVE = 1;
  uint8 internal constant COUPON_ACTIVE = 2;

  constructor(IUniswapV2Router02 _swapRouter) {
    if (address(_swapRouter) == address(0)) revert WrongParams();

    swapRouter = _swapRouter;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import ".././interfaces/HTokenI.sol";
import "./LiquidatorStorage.sol";
import ".././utils/ErrorReporter.sol";

import { INFTXVault } from ".././interfaces/INFTXVault.sol";
import { INFTXVaultFactory } from ".././interfaces/INFTXVaultFactory.sol";

/**
 * @title   Honey Finance Liquidator Module - NFTX
 * @notice  Execute liquidations via NFTX for HToken IRM contracts
 * @author  Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:contributor m4rio
 */
abstract contract LiquidatorModuleNFTX is AccessControl, ReentrancyGuard, LiquidatorStorage {
  using SafeERC20 for IERC20;

  /// @notice NFTX pool factory
  INFTXVaultFactory public NFTXFactory;

  /// @notice HToken to NFTX vaults for that collateral
  mapping(HTokenI => address[]) public poolToNFTXVaults;

  event NFTXFactoryInitialized(address _factory);
  event NFTXVaultsInitialized(address _pair, address _hToken);
  event NFTXLiquidationExecuted(address indexed _pair, address indexed _hToken, uint256 _collateralId);

  /**
   * @notice  Initializes the NFTXFactory that will be queried
   * @dev     May only be called once
   * @param   _NFTXFactory address of NFTX factory proxy contract
   * @return  True on success
   */
  function initializeNFTXFactory(INFTXVaultFactory _NFTXFactory) external nonReentrant onlyRole(INITIALIZER_ROLE) returns (bool) {
    // May only initialize once
    if (address(NFTXFactory) != address(0)) revert Unauthorized();
    NFTXFactory = _NFTXFactory;
    emit NFTXFactoryInitialized(address(_NFTXFactory));
    return true;
  }

  /**
   * @notice  Setup NFTX vault(s) if they exists for the collateral asset underlying the given HToken
   * @dev     Does not create an NFTX vault if one does not exist.
   * @param   _hToken address of the target hToken.
   * @return  True on success
   */
  function initializeNFTXVault(HTokenI _hToken) external nonReentrant onlyRole(INITIALIZER_ROLE) returns (bool) {
    IERC721 collateralToken = _hToken.collateralToken();

    // Check for existence of NFTX pool
    address[] memory vaults = NFTXFactory.vaultsForAsset(address(collateralToken));

    uint256 length = vaults.length;

    if (length > 0) {
      address vault;
      for (uint256 i; i < length; ) {
        vault = vaults[i];

        // Sanity check
        if (INFTXVault(vault).assetAddress() == address(collateralToken)) {
          poolToNFTXVaults[_hToken].push(vault);

          emit NFTXVaultsInitialized(vault, address(_hToken));
        }

        unchecked {
          ++i;
        }
      }

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev     Called before NFTX liquidation. Should handle auctions, refunding, and any other logic.
   * @param   _hToken Contract address of the HToken
   * @param   _collateralId NFT tokenId
   * @param   _vaultIndex 0 if only one vault exists, otherwise index of the desired vault in the address[] mapping of poolToNFTXVaults
   * @return  (Collateral ERC-721 address, vault address)
   */
  function _NFTXPreLiquidationHook(
    HTokenI _hToken,
    uint256 _collateralId,
    uint256 _vaultIndex
  ) internal virtual returns (IERC721, address) {}

  /**
   * @dev     Called before NFTX droplet swap. Should handle auctions, refunding, and any other logic.
   * @param   _hToken Contract address of the HToken
   * @param   _collateralId NFT tokenId
   * @return  (Collateral ERC-721 address, underlying ERC-20 address)
   */
  function _NFTXPreSwapHook(HTokenI _hToken, uint256 _collateralId) internal virtual returns (IERC721, IERC20) {}

  /**
   * @dev     Called after dex swap to ensure we have enough to repay without dipping into protected funds
   * @param   _hToken hToken we're repaying against
   * @param   _underlyingToken ERC-20 token to be used for repayment
   * @param   _collateralId NFT tokenId which we are repaying against
   */
  function postSwapHook(
    HTokenI _hToken,
    IERC20 _underlyingToken,
    uint256 _collateralId
  ) internal virtual {}

  /**
   * @notice  Sends a given NFT to the NFTX platform in exchange for droplet tokens
   * @dev     This will leave the protocol underwater in ERC20 terms unless the droplets are liquidated.
              Business logic needs to understand and account for this.
   * @dev     May only be called after clawback window expires
   * @param   _hToken           Contract address of the HToken
   * @param   _collateralId     NFT Token Id
   * @param   _vaultIndex       Index of the NFTX vault in poolToNFTXVaults. 0 if only one NFTX vault exists for this collateral.
   */
  function liquidateViaNFTX(
    HTokenI _hToken,
    uint256 _collateralId,
    uint256 _vaultIndex
  ) external nonReentrant onlyRole(LIQUIDATOR_ROLE) returns (bool) {
    (IERC721 collateralToken, address pair) = _NFTXPreLiquidationHook(_hToken, _collateralId, _vaultIndex);

    uint256[] memory assets = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    assets[0] = _collateralId;
    amounts[0] = 1;

    collateralToken.approve(pair, _collateralId);

    INFTXVault(pair).mint(assets, amounts);

    emit NFTXLiquidationExecuted(pair, address(_hToken), _collateralId);

    return true;
  }

  /**
   * @notice  Swap droplets for ERC20 using Uniswap V2 pools, and use the funds to repay a borrow
   * @param   _hToken hToken contract address
   * @param   _vaultIndex Which of the NFTX vaults for that collateral should be used
   * @param   _borrower address of the current owner of the deposit coupon
   * @param   _collateralId collateral Id, aka the NFT token ID
   * @param   _path tokens to swap through, starting at droplet and ending at HToken's underlying
   * @param   _amountIn quantity of droplets to liquidate
   * @param   _amountOutMinimum minimum acceptable output quantity of output token
   * @return  True upon success
   */
  function swapNFTXDropletsAndRepayBorrow(
    HTokenI _hToken,
    uint256 _vaultIndex,
    address _borrower,
    uint256 _collateralId,
    address[] memory _path,
    uint256 _amountIn,
    uint256 _amountOutMinimum
  ) external nonReentrant onlyRole(SWAPPER_ROLE) returns (bool) {
    (, IERC20 underlying) = _NFTXPreSwapHook(_hToken, _collateralId);

    // Retrieve address
    address droplet = poolToNFTXVaults[_hToken][_vaultIndex];

    // Arbitrary swap path is allowed, but it must start and end in the right place
    if (_path[0] != droplet) revert WrongParams();
    if (_path[_path.length - 1] != address(underlying)) revert WrongParams();

    // Set approval
    address cachedSwapRouter = address(swapRouter);
    uint256 currentAllowance = IERC20(droplet).allowance(address(this), cachedSwapRouter);
    if (currentAllowance != _amountIn) {
      // Decrease to 0 first for tokens mitigating the race condition
      IERC20(droplet).safeDecreaseAllowance(cachedSwapRouter, currentAllowance);
      IERC20(droplet).safeIncreaseAllowance(cachedSwapRouter, _amountIn);
    }

    // Dex swap
    swapExactUniV2(_amountIn, _amountOutMinimum, _path);

    postSwapHook(_hToken, underlying, _collateralId);

    // Closeout and repay funds
    _hToken.closeoutLiquidation(_borrower, _collateralId);

    marketplace.toggleLiquidation(_hToken, _collateralId, false);

    emit DropletsSwapped(droplet, _path, _amountIn, _amountOutMinimum);
    emit BorrowRepaid(address(_hToken), _borrower, _collateralId);

    return true;
  }

  function swapExactUniV2(
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path
  ) internal virtual returns (uint256[] memory) {
    uint256[] memory amounts = swapRouter.swapExactTokensForTokens(_amountIn, _amountOutMin, _path, address(this), block.timestamp);
    return amounts;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import ".././interfaces/HTokenI.sol";
import "./LiquidatorStorage.sol";
import ".././utils/ErrorReporter.sol";

import { NFT20Factory, NFT20Pair } from ".././interfaces/NFT20I.sol";

/**
 * @title   Honey Finance Liquidator Module - NFT20
 * @notice  Execute liquidations via NFT20 for HToken IRM contracts
 * @author  Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:contributor m4rio
 */
abstract contract LiquidatorModuleNFT20 is AccessControl, ReentrancyGuard, LiquidatorStorage {
  using SafeERC20 for IERC20;

  /// @notice NFT20 pool factory
  NFT20Factory public niftyFactory;

  /// @notice HToken to NFT20 pool for that collateral
  mapping(HTokenI => address) public poolToNiftyPair;

  event NFTFactoryInitialized(address _factory);
  event NFT20PairInitialized(address _pair, address _hToken);
  event NFT20LiquidationExecuted(address indexed _pair, address indexed _hToken, uint256 _collateralId);

  /**
   * @notice  Initializes the NFT20Factory that will be queried
   * @dev     May only be called once
   * @param   _NFT20Factory address of NFT20 factory proxy contract
   * @return  True on success
   */
  function initializeNFT20Factory(NFT20Factory _NFT20Factory) external nonReentrant onlyRole(INITIALIZER_ROLE) returns (bool) {
    // May only initialize once
    if (address(niftyFactory) != address(0)) revert Unauthorized();
    niftyFactory = _NFT20Factory;
    emit NFTFactoryInitialized(address(_NFT20Factory));
    return true;
  }

  /**
   * @notice  Setup an NFT20 pair if one exists for the collateral asset underlying the given HToken
   * @dev     Does not create an NFT20 pool if one does not exist.
   * @param   _hToken address of the target hToken.
   * @return  True on success
   */
  function initializeNFT20Pair(HTokenI _hToken) external nonReentrant onlyRole(INITIALIZER_ROLE) returns (bool) {
    IERC721 collateralToken = _hToken.collateralToken();

    // Check for existence of NFT20 pool
    address pair = niftyFactory.nftToToken(address(collateralToken));

    // If NFT20 pair exists, add it to mapping
    if (pair != address(0)) {
      // Sanity check
      if (NFT20Pair(pair).nftAddress() == address(collateralToken)) {
        poolToNiftyPair[_hToken] = pair;
        emit NFT20PairInitialized(pair, address(_hToken));
        return true;
      }
    }

    return false;
  }

  /**
   * @dev     Called before NFT20 liquidation. Should handle auctions, refunding, and any other logic.
   * @param   _hToken           Contract address of the hToken
   * @param   _collateralId     NFT tokenId
   * @return  (Collateral ERC-721 address, vault address)
   */
  function _NFT20PreLiquidationHook(HTokenI _hToken, uint256 _collateralId) internal virtual returns (IERC721, address) {}

  /**
   * @dev     Called before NFTX droplet swap. Should handle auctions, refunding, and any other logic.
   * @param   _hToken           Contract address of the hToken
   * @param   _collateralId     NFT tokenId
   * @return  (Collateral ERC-721 address, underlying ERC-20 address)
   */
  function _NFT20PreSwapHook(HTokenI _hToken, uint256 _collateralId) internal view virtual returns (IERC721, IERC20) {}

  /**
   * @dev     Called after DEX swap to ensure we have enough to repay without dipping into protected funds
   * @param   _hToken           hToken we're repaying against
   * @param   _underlyingToken  ERC-20 token to be used for repayment
   * @param   _collateralId      NFT token ID which we are repaying against
   */
  function postSwapHook(
    HTokenI _hToken,
    IERC20 _underlyingToken,
    uint256 _collateralId
  ) internal virtual {}

  /**
   * @notice  Sends a given NFT to the NFT20 platform in exchange for droplet tokens
   * @dev     This will leave the protocol underwater in ERC20 terms unless the droplets are liquidated.
   *          Business logic needs to understand and account for this.
   * @param   _hToken           Contract address of the hToken
   * @param   _collateralId     NFT Token ID
   */
  function liquidateViaNFT20(HTokenI _hToken, uint256 _collateralId) external nonReentrant onlyRole(LIQUIDATOR_ROLE) returns (bool) {
    // TODO add incentivisation on executing this
    (IERC721 collateralToken, address pair) = _NFT20PreLiquidationHook(_hToken, _collateralId);

    // Straight token transfer, IERC721Receiver hook in NFT20 pair will mint pair tokens.
    collateralToken.safeTransferFrom(address(this), pair, _collateralId);

    emit NFT20LiquidationExecuted(pair, address(_hToken), _collateralId);

    return true;
  }

  /**
   * @notice  Swap droplets for ERC20 using Uniswap V2 pools, and use the funds to repay a borrow
   * @param   _hToken             The hToken contract address
   * @param   _borrower           The address of the current owner of the deposit coupon
   * @param   _collateralId       Token ID of the collateral token
   * @param   _path               Array of tokens to swap through, starting at droplet and ending at HToken's underlying
   * @param   _amountIn           Quantity of droplets to liquidate
   * @param   _amountOutMinimum   Minimum acceptable output quantity of output token
   * @return  True upon success
   */
  function swapNFT20DropletsAndRepayBorrow(
    HTokenI _hToken,
    address _borrower,
    uint256 _collateralId,
    address[] memory _path,
    uint256 _amountIn,
    uint256 _amountOutMinimum
  ) external nonReentrant onlyRole(SWAPPER_ROLE) returns (bool) {
    (, IERC20 underlying) = _NFT20PreSwapHook(_hToken, _collateralId);

    // Retrieve address
    address droplet = poolToNiftyPair[_hToken];

    // Arbitrary swap path is allowed, but it must start and end in the right place
    if (_path[0] != droplet) revert WrongParams();
    if (_path[_path.length - 1] != address(underlying)) revert WrongParams();

    // Set approval
    address cachedSwapRouter = address(swapRouter);
    uint256 currentAllowance = IERC20(droplet).allowance(address(this), cachedSwapRouter);
    if (currentAllowance != _amountIn) {
      // Decrease to 0 first for tokens mitigating the race condition
      IERC20(droplet).safeDecreaseAllowance(cachedSwapRouter, currentAllowance);
      IERC20(droplet).safeIncreaseAllowance(cachedSwapRouter, _amountIn);
    }

    // Dex swap
    swapExactUniV2(_amountIn, _amountOutMinimum, _path);

    postSwapHook(_hToken, underlying, _collateralId);

    // Closeout and repay funds
    _hToken.closeoutLiquidation(_borrower, _collateralId);

    marketplace.toggleLiquidation(_hToken, _collateralId, false);

    emit DropletsSwapped(droplet, _path, _amountIn, _amountOutMinimum);
    emit BorrowRepaid(address(_hToken), _borrower, _collateralId);

    return true;
  }

  function swapExactUniV2(
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path
  ) internal virtual returns (uint256[] memory) {
    uint256[] memory amounts = swapRouter.swapExactTokensForTokens(_amountIn, _amountOutMin, _path, address(this), block.timestamp);
    return amounts;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title   Interface of HToken Internal
 * @author  Honey Finance Labs
 * @custom:coauthor m4rio
 * @custom:coauthor BowTiedPickle
 */
interface HTokenInternalI is IERC1155 {
  struct Coupon {
    uint32 id; //Coupon's id
    uint8 active; // Coupon activity status
    address owner; // Who is the current owner of this coupon
    uint256 collateralId; // tokenId of the collateral collection that is borrowed against
    uint256 borrowAmount; // Principal borrow balance, denominated in underlying ERC20 token.
    uint256 debtShares; // Debt shares, keeps the shares of total debt by the protocol
  }

  struct Collateral {
    uint256 collateralId; // TokenId of the collateral
    bool active; // Collateral activity status
  }

  // ----- Informational -----

  function decimals() external view returns (uint8);

  // ----- Addresses -----

  function collateralToken() external view returns (IERC721);

  function underlyingToken() external view returns (IERC20);

  // ----- Protocol Accounting -----

  function totalBorrows() external view returns (uint256);

  function totalReserves() external view returns (uint256);

  function totalHTokenSupply() external view returns (uint256);

  function totalFuseFees() external view returns (uint256);

  function totalAdminFees() external view returns (uint256);

  function accrualBlockNumber() external view returns (uint256);

  function interestIndexStored() external view returns (uint256);

  function totalHiveFees() external view returns (uint256);

  function userToCoupons(address _user) external view returns (uint256);

  function collateralPerBorrowCouponId(uint256 _couponId) external view returns (Collateral memory);

  function borrowCoupons(uint256 _collateralId) external view returns (Coupon memory);

  // ----- Views -----

  /**
   * @notice  Get the outstanding debt of a collateral
   * @dev     Simulates accrual of interest
   * @param   _collateralId   Token ID of underlying ERC-721
   * @return  Outstanding debt in units of underlying ERC-20
   */
  function getDebtForCollateral(uint256 _collateralId) external view returns (uint256);

  /**
   * @notice  Returns the current per-block borrow interest rate for this hToken
   * @return  The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view returns (uint256);

  /**
   * @notice  Get the outstanding debt of a coupon
   * @dev     Simulates accrual of interest
   * @param   _couponId   ID of the coupon
   * @return  Outstanding debt in units of underlying ERC-20
   */
  function getDebtForCoupon(uint256 _couponId) external view returns (uint256);

  /**
   * @notice  Gets balance of this contract in terms of the underlying excluding the fees
   * @dev     This excludes the value of the current message, if any
   * @return  The quantity of underlying ERC-20 tokens owned by this contract
   */
  function getCashPrior() external view returns (uint256);

  /**
   * @notice  Get a snapshot of the account's balances, and the cached exchange rate
   * @dev     This is used by hivemind to more efficiently perform liquidity checks.
   * @param   _account  Address of the account to snapshot
   * @return  (token balance, borrow balance, exchange rate mantissa)
   */
  function getAccountSnapshot(address _account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /**
   * @notice  Get the outstanding debt of the protocol
   * @return  Protocol debt
   */
  function getDebt() external view returns (uint256);

  /**
   * @notice  Returns protocol fees
   * @return  Reserve factor mantissa
   * @return  Admin fee mantissa
   * @return  Hive fee mantissa
   * @return  Initial exchange rate mantissa
   * @return  Maximum borrow rate mantissa
   */
  function getProtocolFees()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  /**
   * @notice  Returns different addresses of the protocol
   * @return  Liquidator address
   * @return  HTokenHelper address
   * @return  Hivemind address
   * @return  Admin Fee Receiver address
   * @return  Hive Fee Receiver address
   * @return  Interest Model address
   * @return  Referral Pool address
   * @return  DAO address
   */
  function getAddresses()
    external
    view
    returns (
      address,
      address,
      address,
      address,
      address,
      address,
      address,
      address
    );

  /**
   * @notice  Get the last minted coupon ID
   * @return  The last minted coupon ID
   */
  function getIdCounterLength() external view returns (uint256);

  /**
   * @notice  Get the coupon for a specific collateral NFT
   * @param   _collateralId   Token ID of underlying ERC-721
   * @return  Coupon
   */
  function getSpecificCouponByCollateralId(uint256 _collateralId) external view returns (Coupon memory);

  /**
   * @notice  Calculate the prevailing interest due per token of debt principal
   * @return  Mantissa formatted interest rate per token of debt
   */
  function interestIndex() external view returns (uint256);

  /**
   * @notice  Accrue interest then return the up-to-date exchange rate from the ERC-20 underlying to the HToken
   * @return  Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() external returns (uint256);

  /**
   * @notice  Calculates the exchange rate from the ERC-20 underlying to the HToken
   * @dev     This function does not accrue interest before calculating the exchange rate
   * @return  Calculated exchange rate scaled by 1e18
   */
  function exchangeRateStored() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./HTokenI.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title PriceOracle interface for Chainlink oracles
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
interface PriceOracleI {
  /**
   * @notice requesting the floor price of the entire collection
   * @dev must have REQUESTOR_ROLE
   * @param _collection collection name
   * @param _pricingAsset the returned price currency eth/usd
   */
  function requestFloor(address _collection, string calldata _pricingAsset) external;

  /**
   * @notice this just calls the requestFloor multiple times
   * @param _collections an array of collection names
   * @param _pricingAssets an array of the returned price currency eth/usd
   */
  function requestFloors(address[] calldata _collections, string[] calldata _pricingAssets) external;

  /**
   * @notice requesting a price for an individual token id within a collection
   * @dev must have REQUESTOR_ROLE
   * @param _collection collection name
   * @param _pricingAsset the returned price currency eth/usd
   * @param _tokenId the token id we request the price for
   */
  function requestIndividual(
    address _collection,
    string calldata _pricingAsset,
    uint256 _tokenId
  ) external;

  /**
   * @notice returns the underlying price for the floor of a collection
   * @param _collection address of the collection
   * @param _decimals adjust decimals of the returned price
   */
  function getUnderlyingFloorNFTPrice(address _collection, uint256 _decimals) external view returns (uint128, uint128);

  /**
   * @notice returns the underlying price for an individual token id
   * @param _collection address of the collection
   * @param _tokenId token id within this collection
   * @param _decimals adjust decimals of the returned price
   */
  function getUnderlyingIndividualNFTPrice(
    address _collection,
    uint256 _tokenId,
    uint256 _decimals
  ) external view returns (uint256);

  /**
   * @notice returns the latest price for a given pair
   * @param _erc20 the erc20 we want to get the price for in USD
   * @param _decimals decimals to denote the result in
   */
  function getUnderlyingPriceInUSD(IERC20 _erc20, uint256 _decimals) external view returns (uint256);

  /**
   * @notice get price of eth
   * @param _decimals adjust decimals of the returned price
   */
  function getEthPrice(uint256 _decimals) external view returns (uint256);

  /**
   * @notice get price feeds for a token
   * @return returns the Chainlink Aggregator interface
   */
  function priceFeeds(IERC20 _token) external view returns (AggregatorV3Interface);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./INFTXVaultFactory.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface INFTXEligibility {
  // Read functions.
  function name() external pure returns (string memory);

  function finalized() external view returns (bool);

  function targetAsset() external pure returns (address);

  function checkAllEligible(uint256[] calldata tokenIds) external view returns (bool);

  function checkEligible(uint256[] calldata tokenIds) external view returns (bool[] memory);

  function checkAllIneligible(uint256[] calldata tokenIds) external view returns (bool);

  function checkIsEligible(uint256 tokenId) external view returns (bool);

  // Write functions.
  function __NFTXEligibility_init_bytes(bytes calldata configData) external;

  function beforeMintHook(uint256[] calldata tokenIds) external;

  function afterMintHook(uint256[] calldata tokenIds) external;

  function beforeRedeemHook(uint256[] calldata tokenIds) external;

  function afterRedeemHook(uint256[] calldata tokenIds) external;
}

interface INFTXVault is IERC20Upgradeable {
  function manager() external view returns (address);

  function assetAddress() external view returns (address);

  function vaultFactory() external view returns (INFTXVaultFactory);

  function eligibilityStorage() external view returns (INFTXEligibility);

  function is1155() external view returns (bool);

  function allowAllItems() external view returns (bool);

  function enableMint() external view returns (bool);

  function enableRandomRedeem() external view returns (bool);

  function enableTargetRedeem() external view returns (bool);

  function enableRandomSwap() external view returns (bool);

  function enableTargetSwap() external view returns (bool);

  function vaultId() external view returns (uint256);

  function nftIdAt(uint256 holdingsIndex) external view returns (uint256);

  function allHoldings() external view returns (uint256[] memory);

  function totalHoldings() external view returns (uint256);

  function mintFee() external view returns (uint256);

  function randomRedeemFee() external view returns (uint256);

  function targetRedeemFee() external view returns (uint256);

  function randomSwapFee() external view returns (uint256);

  function targetSwapFee() external view returns (uint256);

  function vaultFees()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  event VaultInit(uint256 indexed vaultId, address assetAddress, bool is1155, bool allowAllItems);

  event ManagerSet(address manager);
  event EligibilityDeployed(uint256 moduleIndex, address eligibilityAddr);
  // event CustomEligibilityDeployed(address eligibilityAddr);

  event EnableMintUpdated(bool enabled);
  event EnableRandomRedeemUpdated(bool enabled);
  event EnableTargetRedeemUpdated(bool enabled);
  event EnableRandomSwapUpdated(bool enabled);
  event EnableTargetSwapUpdated(bool enabled);

  event Minted(uint256[] nftIds, uint256[] amounts, address to);
  event Redeemed(uint256[] nftIds, uint256[] specificIds, address to);
  event Swapped(uint256[] nftIds, uint256[] amounts, uint256[] specificIds, uint256[] redeemedIds, address to);

  function __NFTXVault_init(
    string calldata _name,
    string calldata _symbol,
    address _assetAddress,
    bool _is1155,
    bool _allowAllItems
  ) external;

  function finalizeVault() external;

  function setVaultMetadata(string memory name_, string memory symbol_) external;

  function setVaultFeatures(
    bool _enableMint,
    bool _enableRandomRedeem,
    bool _enableTargetRedeem,
    bool _enableRandomSwap,
    bool _enableTargetSwap
  ) external;

  function setFees(
    uint256 _mintFee,
    uint256 _randomRedeemFee,
    uint256 _targetRedeemFee,
    uint256 _randomSwapFee,
    uint256 _targetSwapFee
  ) external;

  function disableVaultFees() external;

  // This function allows for an easy setup of any eligibility module contract from the EligibilityManager.
  // It takes in ABI encoded parameters for the desired module. This is to make sure they can all follow
  // a similar interface.
  function deployEligibilityStorage(uint256 moduleIndex, bytes calldata initData) external returns (address);

  // The manager has control over options like fees and features
  function setManager(address _manager) external;

  function mint(
    uint256[] calldata tokenIds,
    uint256[] calldata amounts /* ignored for ERC721 vaults */
  ) external returns (uint256);

  function mintTo(
    uint256[] calldata tokenIds,
    uint256[] calldata amounts, /* ignored for ERC721 vaults */
    address to
  ) external returns (uint256);

  function redeem(uint256 amount, uint256[] calldata specificIds) external returns (uint256[] calldata);

  function redeemTo(
    uint256 amount,
    uint256[] calldata specificIds,
    address to
  ) external returns (uint256[] calldata);

  function swap(
    uint256[] calldata tokenIds,
    uint256[] calldata amounts, /* ignored for ERC721 vaults */
    uint256[] calldata specificIds
  ) external returns (uint256[] calldata);

  function swapTo(
    uint256[] calldata tokenIds,
    uint256[] calldata amounts, /* ignored for ERC721 vaults */
    uint256[] calldata specificIds,
    address to
  ) external returns (uint256[] calldata);

  function allValidNFTs(uint256[] calldata tokenIds) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBeacon {
  /**
   * @dev Must return an address that can be used as a delegate call target.
   *
   * {BeaconProxy} will check that this address is a contract.
   */
  function childImplementation() external view returns (address);

  function upgradeChildTo(address newImplementation) external;
}

interface INFTXVaultFactory is IBeacon {
  // Read functions.
  function numVaults() external view returns (uint256);

  function zapContract() external view returns (address);

  function feeDistributor() external view returns (address);

  function eligibilityManager() external view returns (address);

  function vault(uint256 vaultId) external view returns (address);

  function allVaults() external view returns (address[] memory);

  function vaultsForAsset(address asset) external view returns (address[] memory);

  function isLocked(uint256 id) external view returns (bool);

  function excludedFromFees(address addr) external view returns (bool);

  function factoryMintFee() external view returns (uint64);

  function factoryRandomRedeemFee() external view returns (uint64);

  function factoryTargetRedeemFee() external view returns (uint64);

  function factoryRandomSwapFee() external view returns (uint64);

  function factoryTargetSwapFee() external view returns (uint64);

  function vaultFees(uint256 vaultId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  event NewFeeDistributor(address oldDistributor, address newDistributor);
  event NewZapContract(address oldZap, address newZap);
  event FeeExclusion(address feeExcluded, bool excluded);
  event NewEligibilityManager(address oldEligManager, address newEligManager);
  event NewVault(uint256 indexed vaultId, address vaultAddress, address assetAddress);
  event UpdateVaultFees(
    uint256 vaultId,
    uint256 mintFee,
    uint256 randomRedeemFee,
    uint256 targetRedeemFee,
    uint256 randomSwapFee,
    uint256 targetSwapFee
  );
  event DisableVaultFees(uint256 vaultId);
  event UpdateFactoryFees(uint256 mintFee, uint256 randomRedeemFee, uint256 targetRedeemFee, uint256 randomSwapFee, uint256 targetSwapFee);

  // Write functions.
  function __NFTXVaultFactory_init(address _vaultImpl, address _feeDistributor) external;

  function createVault(
    string calldata name,
    string calldata symbol,
    address _assetAddress,
    bool is1155,
    bool allowAllItems
  ) external returns (uint256);

  function setFeeDistributor(address _feeDistributor) external;

  function setEligibilityManager(address _eligibilityManager) external;

  function setZapContract(address _zapContract) external;

  function setFeeExclusion(address _excludedAddr, bool excluded) external;

  function setFactoryFees(
    uint256 mintFee,
    uint256 randomRedeemFee,
    uint256 targetRedeemFee,
    uint256 randomSwapFee,
    uint256 targetSwapFee
  ) external;

  function setVaultFees(
    uint256 vaultId,
    uint256 mintFee,
    uint256 randomRedeemFee,
    uint256 targetRedeemFee,
    uint256 randomSwapFee,
    uint256 targetSwapFee
  ) external;

  function disableVaultFees(uint256 vaultId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface NFT20Factory {
  function nftToToken(address) external returns (address);
}

interface NFT20Pair {
  function nftAddress() external returns (address);
}