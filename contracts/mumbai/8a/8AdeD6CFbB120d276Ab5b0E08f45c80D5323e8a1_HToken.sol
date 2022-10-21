//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./HTokenInternal.sol";

/**
 * @title Honey Finance's HToken contract
 * @notice ERC-1155 contract which wraps an ERC-20 underlying liquid asset and an ERC-721 underlying collateral asset
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
contract HToken is HTokenInternal, ReentrancyGuard {
  using SafeERC20 for IERC20;

  /// @notice this corresponds to 1.0.0
  uint256 public constant version = 1_000_000;

  /**
   * @notice Initialize the market
   * @param _underlyingToken address of the underlying ERC-20 liquid asset
   * @param _collateralToken address of the underlying ERC-721 collateral asset
   * @param _hivemind address of the Hivemind
   * @param _interestRateModel address of the interest rate model
   * @param _liquidator address of the liquidator
   * @param _initialExchangeRateMantissa initial exchange rate, scaled by 1e18
   * @param _adminFeeReceiver admin address that receives the fees of the admin
   * @param _hiveFeeReceiver hive fee address that receives the fees of the hive
   * @param _name the name of the token
   * @param _symbol the symbol of the token
   */
  constructor(
    IERC20Metadata _underlyingToken,
    IERC721 _collateralToken,
    HivemindI _hivemind,
    InterestRateModelI _interestRateModel,
    address _liquidator,
    uint256 _initialExchangeRateMantissa,
    address _adminFeeReceiver,
    address _hiveFeeReceiver,
    string memory _name,
    string memory _symbol
  )
    HTokenInternal(
      _underlyingToken,
      _collateralToken,
      _hivemind,
      _interestRateModel,
      _liquidator,
      _initialExchangeRateMantissa,
      _adminFeeReceiver,
      _hiveFeeReceiver,
      _name,
      _symbol
    )
  {}

  // ----- Lend side functions -----

  /**
   * @notice Deposit underlying ERC-20 asset and mint hTokens
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _amount Quantity of underlying ERC-20 to transfer in
   */
  function depositUnderlying(uint256 _amount) external nonReentrant {
    depositUnderlyingInternal(_amount);
  }

  /**
   * @notice Redeem a specified amount of hTokens for their underlying ERC-20 asset
   * @param _amount Quantity of hTokens to redeem for underlying ERC-20
   */
  function redeem(uint256 _amount) external nonReentrant {
    redeemInternal(_amount);
  }

  /**
   * @notice Withdraws the specified _amount of underlying ERC-20 asset, consuming the minimum amount of hTokens necessary
   * @param _amount Quantity of underlying ERC-20 tokens to withdraw
   */
  function withdraw(uint256 _amount) external nonReentrant {
    withdrawInternal(_amount);
  }

  // ----- Borrow side functions -----

  /**
   * @notice Deposit a specified token of the underlying ERC-721 asset and mint an ERC-1155 deposit coupon NFT
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _collateralId Token ID of underlying ERC-721 to be transferred in
   */
  function depositCollateral(uint256 _collateralId) external nonReentrant {
    depositCollateralInternal(_collateralId);
  }

  /**
   * @notice Deposit multiple specified tokens of the underlying ERC-721 asset and mint ERC-1155 deposit coupons NFT
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _collateralIds Token IDs of underlying ERC-721 to be transferred in
   */
  function depositMultiCollateral(uint256[] calldata _collateralIds) external nonReentrant {
    uint256 len = _collateralIds.length;
    for (uint256 i; i < len; ) {
      depositCollateralInternal(_collateralIds[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Sender borrows assets from the protocol against the specified collateral asset
   * @dev Collateral must be deposited first.
   * @param _borrowAmount Amount of underlying ERC-20 to borrow
   * @param _collateralId Token ID of underlying ERC-721 to be borrowed against
   */
  function borrow(uint256 _borrowAmount, uint256 _collateralId) external nonReentrant {
    borrowInternal(_borrowAmount, _collateralId);
  }

  /**
   * @notice Sender repays their own borrow taken against the specified collateral asset
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _repayAmount Amount of underlying ERC-20 to repay
   * @param _collateralId Token ID of underlying ERC-721 to be repaid against
   */
  function repayBorrow(uint256 _repayAmount, uint256 _collateralId) external nonReentrant {
    repayBorrowInternal(msg.sender, _repayAmount, _collateralId);
  }

  /**
   * @notice Sender repays another user's borrow taken against the specified collateral asset
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _borrower User whose borrow will be repaid
   * @param _repayAmount Amount of underlying ERC-20 to repay
   * @param _collateralId Token ID of underlying ERC-721 to be repaid against
   */
  function repayBorrowBehalf(
    address _borrower,
    uint256 _repayAmount,
    uint256 _collateralId
  ) external nonReentrant {
    repayBorrowInternal(_borrower, _repayAmount, _collateralId);
  }

  /**
   * @notice Burn a deposit coupon NFT and withdraw the associated underlying ERC-721 NFT
   * @param _collateralId collateral Id, aka the NFT token Id
   */
  function withdrawCollateral(uint256 _collateralId) external nonReentrant {
    withdrawCollateralInternal(_collateralId);
  }

  /**
   * @notice Burn multiple deposit coupons NFT and withdraw the associated underlying ERC-721 NFTs
   * @param _collateralIds collateral Ids, aka the NFT token Ids
   */
  function withdrawMultiCollateral(uint256[] calldata _collateralIds) external nonReentrant {
    uint256 len = _collateralIds.length;
    for (uint256 i; i < len; ) {
      withdrawCollateralInternal(_collateralIds[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Triggers transfer of an NFT to the liquidation contract
   * @param _collateralId collateral Id, aka the NFT token Id representing the borrow position to liquidate
   */
  function liquidateBorrow(uint256 _collateralId) external nonReentrant {
    liquidateBorrowInternal(_collateralId);
  }

  /**
   * @notice Pay off the entirety of a borrow position and burn the coupon
   * @dev May only be called by the liquidator
   * @param _borrower borrower who pays
   * @param _collateralId what to pay for
   */
  function closeoutLiquidation(address _borrower, uint256 _collateralId) external nonReentrant {
    if (!hasRole(LIQUIDATOR_ROLE, msg.sender)) revert Unauthorized();
    closeoutLiquidationInternal(_borrower, _collateralId);
  }

  /**
   * @notice accrues interests to a selected set of coupons
   * @param _ids ids of coupons to accrue interest
   * @return all accrued interest
   */
  function accrueInterestToCoupons(uint256[] calldata _ids) external nonReentrant returns (uint256) {
    return accrueInterestToCouponsInternal(_ids);
  }

  // ----- Utility functions -----

  /**
   * @notice A public function to sweep accidental ERC-20 transfers to this contract.
   * @dev Tokens are sent to the dao for later distribution, we use transfer and not safeTransfer as this is admin only method
   * @param _token The address of the ERC-20 token to sweep
   */
  function sweepToken(IERC20 _token) external {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || _token == underlyingToken) revert Unauthorized();
    uint256 balance = _token.balanceOf(address(this));
    if (balance > 0) {
      _token.safeTransfer(dao, balance);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import ".././interfaces/HivemindI.sol";
import ".././interfaces/HTokenHelperI.sol";
import ".././interfaces/InterestRateModelI.sol";
import ".././utils/ErrorReporter.sol";

/**
 * @title Honey Finance's HToken Internal structure contract implemented by HToken
 * @notice ERC-1155 contract which wraps an ERC-20 underlying liquid asset and an ERC-721 underlying collateral asset
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
contract HTokenInternal is ERC1155, IERC721Receiver, ErrorReporter, AccessControl {
  // ----- Imports -----

  using SafeERC20 for IERC20Metadata;
  using Counters for Counters.Counter;

  // ----- Access Control -----

  bytes32 public constant SUPPLIER_ROLE = keccak256("SUPPLIER_ROLE");
  bytes32 public constant MARKET_ADMIN_ROLE = keccak256("MARKET_ADMIN_ROLE");
  bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

  // ----- Parameters -----

  /// @notice The mantissa-formatted maximum borrow rate which can ever be applied (.0005% / block)
  uint256 public constant borrowRateMaxMantissa = 0.0005e16;

  /// @notice The mantissa-formatted exchange rate used when hToken totalSupply = 0
  uint256 public immutable initialExchangeRateMantissa;

  /// @notice The mantissa-formatted fraction of interest set aside for reserves
  uint256 public reserveFactorMantissa;

  /// @notice The mantissa-formatted fraction of interest accrued to the hToken admin
  uint256 public adminFeeMantissa;

  /// @notice The mantissa-formatted fraction of interest accrued to the hive
  uint256 public hiveFeeMantissa;

  /// @notice The mantissa-formatted fraction of interest accrued to the Honey protocol
  uint256 public protocolFeeMantissa;

  /// @notice  The mantissa-formatted maximum fraction of interest which can be ever be accrued to reserves or fees
  uint256 public constant reserveFactorPlusFeesMaxMantissa = 5e17; // 50% - change later

  /// @notice the name of the token
  string public name;

  /// @notice the symbol of the token
  string public symbol;

  /// @notice decimals of the ERC-20 underlying token
  uint8 public immutable decimals;

  // ----- Addresses -----

  /// @notice Receiver of admin fees
  address public adminFeeReceiver;

  /// @notice Receiver of hive fees
  address public hiveFeeReceiver;

  /// @notice DAO address where swept tokens will be transmitted
  address constant dao = 0x9adBd648cb2238B72B05f3e488c6A75F8F186620;

  /// @notice Liquidation handler contract
  address public liquidator;

  /// @notice Contract which oversees inter-hToken operations
  HivemindI public hivemind;

  /// @notice Model which tells what the current interest rate should be
  InterestRateModelI public interestRateModel;

  /// @notice Underlying ERC-20 borrowable/lendable token
  IERC20Metadata public immutable underlyingToken;

  /// @notice Underlying ERC-721 collateral token
  IERC721 public immutable collateralToken;

  /// @notice Helper contract which handles URI
  HTokenHelperI public hTokenHelper;

  // ----- State Variables -----

  // Bookkeeping
  uint256 public totalBorrows;
  uint256 public totalReserves;
  uint256 public totalHTokenSupply;
  uint256 public totalHiveFees;
  uint256 public totalAdminFees;
  uint256 public totalProtocolFees;

  /// @notice Block number that interest was last accrued at
  uint256 public accrualBlockNumber;

  /// @notice Interest that will be earned for each unit of borrow principal
  uint256 public interestIndexStored;

  /// @notice a coupon can be in 3 states: when never created is COUPON_UNINITIALIZED,
  /// @notice if it is active then COUPON_ACTIVE, if deleted then COUPON_INACTIVE
  uint8 public constant COUPON_UNINITIALIZED = 0;
  uint8 public constant COUPON_INACTIVE = 1;
  uint8 public constant COUPON_ACTIVE = 2;

  Counters.Counter public idCounter;

  /// @notice Mapping of collateralId => Coupon struct
  mapping(uint256 => Coupon) public borrowCoupons;

  /// @notice Mapping of couponId => Collateral struct
  mapping(uint256 => Collateral) public collateralPerBorrowCouponId;

  /// @notice Stores how many coupons a user has
  mapping(address => uint256) public userToCoupons;

  /// @notice Stores the borrowBalancePerUser so we don't iterate through the coupons to calculate it
  mapping(address => uint256) public borrowBalancePerUser;

  struct Coupon {
    uint32 id; //Coupon's id
    uint8 active; // Coupon activity status
    address owner; // Who is the current owner of this coupon
    uint256 collateralId; // tokenId of the collateral collection that is borrowed against
    uint256 borrowAmount; // Principal borrow balance, denominated in underlying ERC20 token. Updated when interest is accrued to the coupon.
    uint256 interestIndex; // Mantissa formatted interestIndex. Updated when interest is accrued to the coupon.
  }

  struct Collateral {
    uint256 collateralId; // TokenId of the collateral
    bool active; // Collateral activity status
  }

  // ----- Market Events -----

  event InterestAccrued(uint256 _interestAccumulated, uint256 _interestIndex, uint256 _totalBorrows);
  event CouponInterestAccrued(
    Coupon _activeCoupon,
    uint256 _debtPrior,
    uint256 _interestAccumulated,
    uint256 _interestIndexPrior,
    uint256 _interestIndexCurrent
  );
  event Redeem(address indexed _initiator, uint256 _redeemAmount, uint256 _tokensWithdrawn, uint256 _totalHTokenSupply);
  event Withdraw(address indexed _initiator, uint256 _redeemAmount, uint256 _tokensWithdrawn, uint256 _totalHTokenSupply);
  event UnderlyingDeposited(address indexed _initiator, uint256 _amount, uint256 _tokensToMint, uint256 _totalhTokenSupply);

  event Borrow(address indexed _borrower, uint256 _borrowAmount, uint256 _tokenId, uint256 _totalBorrows);
  event RepayBorrow(
    address indexed _payer,
    address indexed _borrower,
    uint256 _repayAmount,
    uint256 _accountBorrows,
    uint256 _totalBorrows,
    uint256 _collateralId
  );
  event CollateralDeposited(address indexed _initiator, uint256 _collateralId, uint256 _couponId);
  event CollateralWithdrawn(address indexed _initiator, uint256 _collateralId);

  event BorrowLiquidated(address indexed _initiator, address indexed _liquidator, address _owner, uint256 _collateralId);
  event LiquidationClosed(address indexed _initiator, address indexed _borrower, uint256 _collateralId, uint256 _borrowAmount);

  // ----- Admin Events -----

  event NewContract(address indexed _oldReceiver, address indexed _newReceiver);
  event ReservesAdded(address indexed _supplier, uint256 _addAmount, uint256 _newTotalReserves);
  event ReservesReduced(address indexed _supplier, uint256 _reduceAmount, uint256 _newTotalReserves);
  event AdminFeesWithdrawn(uint256 _amount);
  event HiveFeesWithdrawn(uint256 _amount);
  event ProtocolFeesWithdrawn(uint256 _amount);
  event NewProtocolFees(
    uint256 _oldHiveFee,
    uint256 _newHiveFee,
    uint256 _oldAdminFee,
    uint256 _newAdminFee,
    uint256 _oldReserveFactor,
    uint256 _newReserveFactor,
    uint256 _oldProtocolFee,
    uint256 _newProtocolFee
  );

  constructor(
    IERC20Metadata _underlyingToken,
    IERC721 _collateralToken,
    HivemindI _hivemindAddress,
    InterestRateModelI _interestRateModel,
    address _liquidator,
    uint256 _initialExchangeRateMantissa,
    address _adminFeeReceiver,
    address _hiveFeeReceiver,
    string memory _name,
    string memory _symbol
  ) ERC1155("") {
    if (_liquidator == address(0) || _adminFeeReceiver == address(0) || _hiveFeeReceiver == address(0)) revert WrongParams();

    // Set initial exchange rate
    if (_initialExchangeRateMantissa == 0) revert HTokenError(Error.INITIAL_EXCHANGE_MANTISSA);
    initialExchangeRateMantissa = _initialExchangeRateMantissa;

    // Setup the collateral NFT collection
    if (!_collateralToken.supportsInterface(type(IERC721).interfaceId)) revert WrongParams();
    collateralToken = _collateralToken;

    // Setting roles
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MARKET_ADMIN_ROLE, msg.sender);
    _grantRole(SUPPLIER_ROLE, msg.sender);
    _grantRole(LIQUIDATOR_ROLE, msg.sender);

    // Setup underlying token
    underlyingToken = _underlyingToken;

    // Setup decimals
    decimals = _underlyingToken.decimals();

    // Set liquidator contract
    liquidator = _liquidator;

    // Increment to reserve id 0 for hTokens
    idCounter.increment();

    // Setup hivemind
    hivemind = _hivemindAddress;

    // Initialize block number
    accrualBlockNumber = block.number;

    // Setup interest rate
    interestRateModel = _interestRateModel;

    // Set fee receivers
    adminFeeReceiver = _adminFeeReceiver;
    hiveFeeReceiver = _hiveFeeReceiver;

    name = _name;
    symbol = _symbol;
  }

  /*/////////////////////////////////////////////////////////////
                    Coupon handler functions
    /////////////////////////////////////////////////////////////*/

  /**
   * @notice Get all a user's coupons
   * @param _user The user to search for
   * @return Array of all coupons belonging to the user
   */
  function getUserCoupons(address _user) external view returns (Coupon[] memory) {
    unchecked {
      Coupon[] memory userCoupons = new Coupon[](userToCoupons[_user]);
      uint256 length = idCounter.current();
      uint256 counter;
      for (uint256 i; i < length; ++i) {
        Collateral storage collateral = collateralPerBorrowCouponId[i];
        if (!collateral.active) continue;
        Coupon storage coupon = borrowCoupons[collateral.collateralId];

        if (coupon.owner == _user) {
          userCoupons[counter++] = coupon;
        }
      }

      return userCoupons;
    }
  }

  /**
   * @notice Get tokenIds of all a user's coupons
   * @param _user The user to search for
   * @return Array of indices of all coupons belonging to the user
   */
  function getUserCouponIndices(address _user) external view returns (uint256[] memory) {
    unchecked {
      uint256[] memory userCoupons = new uint256[](userToCoupons[_user]);
      uint256 length = idCounter.current();
      uint256 counter;
      for (uint256 i; i < length; ++i) {
        Collateral storage collateral = collateralPerBorrowCouponId[i];
        if (!collateral.active) continue;
        Coupon storage coupon = borrowCoupons[collateral.collateralId];

        if (coupon.owner == _user) {
          userCoupons[counter++] = i;
        }
      }

      return userCoupons;
    }
  }

  /**
   * @notice Get the coupon for a specific collateral NFT
   * @param _collateralId collateral id
   * @return Coupon
   */
  function getSpecificCouponByCollateralId(uint256 _collateralId) external view returns (Coupon memory) {
    return borrowCoupons[_collateralId];
  }

  /**
   * @notice Get the number of coupons deposited aka active
   * @return Array of all active coupons
   */
  function getActiveCoupons() external view returns (Coupon[] memory) {
    Coupon[] memory depositedCoupons;
    unchecked {
      uint256 length = idCounter.current();
      uint256 deposited;
      for (uint256 i; i < length; ++i) {
        if (collateralPerBorrowCouponId[i].active) {
          ++deposited;
        }
      }
      depositedCoupons = new Coupon[](deposited);
      uint256 j;
      for (uint256 i; i < length; ++i) {
        Collateral storage _collateral = collateralPerBorrowCouponId[i];
        if (_collateral.active) {
          depositedCoupons[j] = borrowCoupons[_collateral.collateralId];

          // This condition means "if j == deposited then break, else continue the loop with j + 1". This is a gas optimization to avoid potentially unnecessary storage readings
          if (j++ == deposited) {
            break;
          }
        }
      }
    }
    return depositedCoupons;
  }

  /*/////////////////////////////////////////////////////////////
                        Lending Functions
    /////////////////////////////////////////////////////////////*/

  /**
   * @dev Deposit underlying tokens and receive hTokens as proof of deposit
   * @dev Must be approved to transfer amount of underlying tokens. Accrues interest and updates exchange rate prior to depositing and minting
   * @param _amount Quantity of underlying tokens to deposit
   */
  function depositUnderlyingInternal(uint256 _amount) internal {
    uint256 exchangeRateCurr = exchangeRateCurrent();
    uint256 tokensToMint = (doUnderlyingTransferIn(msg.sender, _amount) * 1e18) / exchangeRateCurr;
    uint256 newTotalHTokenSupply = totalHTokenSupply + tokensToMint;

    totalHTokenSupply = newTotalHTokenSupply;
    _mint(msg.sender, 0, tokensToMint, "");

    emit UnderlyingDeposited(msg.sender, _amount, tokensToMint, newTotalHTokenSupply);
  }

  /**
   * @dev Redeem a specified amount of hTokens for the corresponding amount of the underlying ERC-20 asset
   * It does a check against Hivemind to see if it is allowed to redeem.
   * @param _amount The amount of hTokens to redeem.
   */
  function redeemInternal(uint256 _amount) internal {
    hivemind.redeemAllowed(HTokenI(address(this)), msg.sender, _amount);

    uint256 underlyingToWithdraw = (_amount * exchangeRateCurrent()) / 1e18;

    uint256 newTotalHTokenSupply = totalHTokenSupply - _amount;
    totalHTokenSupply = newTotalHTokenSupply;

    _burn(msg.sender, 0, _amount);

    doUnderlyingTransferOut(msg.sender, underlyingToWithdraw);
    emit Redeem(msg.sender, _amount, underlyingToWithdraw, newTotalHTokenSupply);
  }

  /**
   * @dev Withdraw a specified quantity of the underlying ERC-20 asset, redeeming any amount of hTokens necessary
   * It does a check against Hivemind to see if it is allowed to redeem the required amount of hTokens.
   * @param _amount Amount of ERC-20 underlying to be withdrawn.
   */
  function withdrawInternal(uint256 _amount) internal {
    hivemind.redeemAllowed(HTokenI(address(this)), msg.sender, _amount);

    uint256 tokensToRedeem = (_amount * 1e18) / exchangeRateCurrent();

    uint256 newTotalHTokenSupply = totalHTokenSupply - tokensToRedeem;
    totalHTokenSupply = newTotalHTokenSupply;

    _burn(msg.sender, 0, tokensToRedeem);

    doUnderlyingTransferOut(msg.sender, _amount);
    emit Withdraw(msg.sender, tokensToRedeem, _amount, newTotalHTokenSupply);
  }

  /**
   * @dev Transfers the ERC-20 underlying token from the contract to the recipient
   * @param _to transfer to
   * @param _amount amount to withdraw
   */
  function doUnderlyingTransferOut(address _to, uint256 _amount) internal {
    underlyingToken.safeTransfer(_to, _amount);
  }

  /**
   * @dev Transfers the ERC-20 underlying token from the sender to the contract
   * @dev `_from` needs to approve before hand
   * @param _from transfer from, it needs to have approved at least `_amount`
   * @param _amount amount to deposit
   * @return amount deposited
   */
  function doUnderlyingTransferIn(address _from, uint256 _amount) internal returns (uint256) {
    uint256 balanceBefore = underlyingToken.balanceOf(address(this));
    underlyingToken.safeTransferFrom(_from, address(this), _amount);
    uint256 balanceAfter = underlyingToken.balanceOf(address(this));

    if (balanceAfter < balanceBefore) revert HTokenError(Error.TRANSFER_ERROR);
    unchecked {
      return balanceAfter - balanceBefore;
    }
  }

  /*///////////////////////////////////////////////////////////////
                          Borrowing functions
    ///////////////////////////////////////////////////////////////*/

  /**
   * @dev used to deposit collateral
   * @param _collateralId to be deposited as collateral
   */
  function depositCollateralInternal(uint256 _collateralId) internal {
    collateralToken.safeTransferFrom(msg.sender, address(this), _collateralId);

    uint256 couponId = _mintCoupon(msg.sender, _collateralId);

    emit CollateralDeposited(msg.sender, _collateralId, couponId);
  }

  /**
   * @dev Borrow an amount against a specific collateral and accrue it to the coupon
   * @param _borrowAmount the amount to borrow
   * @param _collateralId token ID of the ERC-721 collateral asset being borrowed against
   */
  function borrowInternal(uint256 _borrowAmount, uint256 _collateralId) internal {
    Coupon storage coupon = borrowCoupons[_collateralId];

    // Coupon must exist
    if (coupon.active == COUPON_UNINITIALIZED) revert HTokenError(Error.COUPON_LOOKUP);

    // Sanity check to make sure the coupon was found correctly
    if (coupon.collateralId != _collateralId) revert WrongParams();

    // Sanity check to make sure the owner is the one who borrows
    address couponOwner = coupon.owner;
    if (couponOwner != msg.sender) revert NotOwner();

    // Our contract must own the relevant tokenId
    if (collateralToken.ownerOf(_collateralId) != address(this)) revert HTokenError(Error.TOKEN_NOT_PRESENT);

    accrueInterestToCollateral(_collateralId);

    uint256 protocolFee = (_borrowAmount * protocolFeeMantissa) / 1e18;
    uint256 borrowIncurred = _borrowAmount + protocolFee;

    // Check for borrow allowed
    hivemind.borrowAllowed(HTokenI(address(this)), msg.sender, _collateralId, borrowIncurred);

    // Add the borrow amount to the token
    coupon.borrowAmount += borrowIncurred;

    // Update accounting variables
    totalBorrows += borrowIncurred;
    borrowBalancePerUser[coupon.owner] += borrowIncurred;
    totalProtocolFees += protocolFee;

    // Transfer the funds to borrower
    doUnderlyingTransferOut(msg.sender, _borrowAmount);

    emit Borrow(msg.sender, _borrowAmount, _collateralId, borrowIncurred);
  }

  /**
   * @dev Repay a borrow for a given collateral
   * @param _repayAmount the amount to repay
   * @param _collateralId token ID of the ERC-721 collateral asset being repaid against
   */
  function repayBorrowInternal(
    address _borrower,
    uint256 _repayAmount,
    uint256 _collateralId
  ) internal {
    // Can't repay 0 amount
    if (_repayAmount == 0) revert HTokenError(Error.AMOUNT_ZERO);

    // Accrue interest
    accrueInterestToCollateral(_collateralId);

    hivemind.repayBorrowAllowed(HTokenI(address(this)), _repayAmount, _collateralId);

    // Find the user's coupon
    Coupon storage coupon = borrowCoupons[_collateralId];
    address couponOwner = coupon.owner;
    if (couponOwner != _borrower) revert Unauthorized();

    // Sanity check to make sure the coupon was found correctly
    if (coupon.collateralId != _collateralId) revert WrongParams();

    // Get outstanding debt
    uint256 debt = coupon.borrowAmount;
    if (debt == 0) revert HTokenError(Error.NO_DEBT);

    // Set amount to repay
    uint256 payment = (_repayAmount > debt) ? debt : _repayAmount;
    uint256 repayment = doUnderlyingTransferIn(msg.sender, payment);

    // Credit their account
    coupon.borrowAmount = debt - repayment;

    // Decrease balances
    uint256 newTotalBorrows = totalBorrows - repayment;
    totalBorrows = newTotalBorrows;

    borrowBalancePerUser[couponOwner] -= repayment;

    emit RepayBorrow(msg.sender, couponOwner, repayment, debt, newTotalBorrows, _collateralId);
  }

  /**
   * @dev withdraw collateral
   * @param _collateralId what to withdraw
   */
  function withdrawCollateralInternal(uint256 _collateralId) internal {
    Coupon storage activeCoupon = borrowCoupons[_collateralId];
    if (activeCoupon.owner != msg.sender) revert Unauthorized();

    // checks if withdrawal is allowed, if not will fail
    hivemind.withdrawalCollateralAllowed(HTokenI(address(this)), _collateralId);

    uint256 _activeCollateralId = activeCoupon.collateralId;
    burnAndDelete(msg.sender, _activeCollateralId, activeCoupon.id);

    collateralToken.safeTransferFrom(address(this), msg.sender, _activeCollateralId);

    emit CollateralWithdrawn(msg.sender, _collateralId);
  }

  /**
   * @dev Mint a borrow coupon NFT on collateral deposit
   * @dev Reuses old coupon IDs if they have been previously minted and burned
   * @param _to the receiver (who deposits the collateral)
   * @param _collateralId the id of the token that is deposited
   */
  function _mintCoupon(address _to, uint256 _collateralId) internal returns (uint256) {
    uint256 currentId = idCounter.current();
    Coupon storage coupon = borrowCoupons[_collateralId];
    if (coupon.active > COUPON_UNINITIALIZED) {
      currentId = coupon.id;
    } else {
      idCounter.increment();
      coupon.id = uint32(currentId);
    }

    // Construct a coupon
    coupon.collateralId = _collateralId;
    coupon.borrowAmount = 0;
    coupon.active = COUPON_ACTIVE;
    coupon.interestIndex = interestIndex();
    coupon.owner = _to;

    collateralPerBorrowCouponId[currentId] = Collateral(_collateralId, true);

    // Mint NFT
    _mint(_to, currentId, 1, "");
    return currentId;
  }

  /*/////////////////////////////////////////////////////////////
                  Liquidation functions
  /////////////////////////////////////////////////////////////*/

  /**
   * @dev Liquidate a borrow and send the collateral to the liquidator contract
   * @param _collateralId token ID of ERC-721 collateral to liquidate
   */
  function liquidateBorrowInternal(uint256 _collateralId) internal {
    Coupon storage activeCoupon = borrowCoupons[_collateralId];
    if (activeCoupon.active != COUPON_ACTIVE) revert HTokenError(Error.LIQUIDATION_NOT_ALLOWED);

    accrueInterestToCollateral(_collateralId);

    //checks if liquidation is allowed, e.g. debt > collateral factor
    hivemind.liquidationAllowed(HTokenI(address(this)), _collateralId);

    bytes memory data = abi.encode(address(this));

    address cachedLiquidator = liquidator;

    collateralToken.safeTransferFrom(address(this), cachedLiquidator, _collateralId, data);

    emit BorrowLiquidated(msg.sender, cachedLiquidator, activeCoupon.owner, _collateralId);
  }

  /**
   * @notice Pay off the entirety of a borrow position and burn the coupon
   * @dev May only be called by the liquidator
   * @param _borrower borrower who pays
   * @param _collateralId what to pay for
   */
  function closeoutLiquidationInternal(address _borrower, uint256 _collateralId) internal {
    accrueInterestToCollateral(_collateralId);

    Coupon storage coupon = borrowCoupons[_collateralId];
    if (coupon.owner != _borrower) revert Unauthorized();

    // Repay borrow
    uint256 cachedBorrowAmount = coupon.borrowAmount;
    repayBorrowInternal(_borrower, cachedBorrowAmount, _collateralId);

    // Burn the NFT coupon
    burnAndDelete(_borrower, coupon.collateralId, coupon.id);
    emit LiquidationClosed(msg.sender, _borrower, _collateralId, cachedBorrowAmount);
  }

  /**
   * @dev burns a coupon and deletes it from the data structure
   * @param _account User to burn from
   * @param _collateralId Collateral associated with this coupon
   * @param _couponId Coupon ID to burn
   */
  function burnAndDelete(
    address _account,
    uint256 _collateralId,
    uint256 _couponId
  ) internal {
    // makes coupon inactive and deletes it from user coupons
    _burn(_account, _couponId, 1);
    Coupon storage borrowCoupon = borrowCoupons[_collateralId];
    borrowCoupon.active = COUPON_INACTIVE;
    borrowCoupon.owner = address(0);
    borrowCoupon.borrowAmount = 0;
    borrowCoupon.interestIndex = 0;
    collateralPerBorrowCouponId[_couponId].active = false;
  }

  /*///////////////////////////////////////////////////////////////
                      Exchange rate functions
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Accrue interest then return the up-to-date exchange rate from the ERC-20 underlying to the HToken
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() public returns (uint256) {
    accrueInterest();
    return exchangeRateStored();
  }

  /**
   * @notice Calculates the exchange rate from the ERC-20 underlying to the HToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateStored() public view returns (uint256) {
    uint256 cachedTotalSupply = totalHTokenSupply;
    if (cachedTotalSupply == 0) {
      // If there are no tokens minted: exchangeRate = initialExchangeRate
      return initialExchangeRateMantissa;
    } else {
      /*
       * Otherwise:
       *  exchangeRate = (totalCash + totalBorrows - (totalReserves + totalHiveFees + totalAdminFees + totalProtocolFees)) / totalSupply
       */
      uint256 totalCash = getCashPrior();
      uint256 cashPlusBorrowsMinusReserves = totalCash +
        totalBorrows -
        (totalReserves + totalHiveFees + totalAdminFees + totalProtocolFees);

      uint256 exchangeRate = (cashPlusBorrowsMinusReserves * 1e18) / cachedTotalSupply;
      return exchangeRate;
    }
  }

  /*///////////////////////////////////////////////////////////////
                          View functions
    ///////////////////////////////////////////////////////////////*/
  /**
   * @notice Get the outstanding debt for a collateral
   * @dev Simulates accrual of interest
   * @param _collateralId collateral id we want to get the borrow amount for
   * @return The amount borrowed so far
   */
  function getBorrowAmountForCollateral(uint256 _collateralId) public view returns (uint256) {
    Coupon storage borrowCoupon = borrowCoupons[_collateralId];
    uint256 principal = borrowCoupon.borrowAmount;
    if (decimals < 18) {
      return principal + (principal * (interestIndex() - borrowCoupon.interestIndex)) / 10**(18 - decimals);
    } else {
      return principal + (principal * (interestIndex() - borrowCoupon.interestIndex)) / 1e18;
    }
  }

  /**
   * @notice Returns the current per-block borrow interest rate for this hToken
   * @return The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view returns (uint256) {
    return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
  }

  /**
   * @notice Get the outstanding debt of a coupon
   * @dev Simulates accrual of interest
   * @param _couponId ID of the coupon
   * @return Debt denominated in the underlying token
   */
  function getBorrowByCouponId(uint256 _couponId) external view returns (uint256) {
    uint256 collateralId = collateralPerBorrowCouponId[_couponId].collateralId;
    return getBorrowAmountForCollateral(collateralId);
  }

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying tokens owned by this contract
   */
  function getCashPrior() public view returns (uint256) {
    return underlyingToken.balanceOf(address(this));
  }

  /**
   * @notice Get a snapshot of the account's balances, and the cached exchange rate
   * @dev This is used by hivemind to more efficiently perform liquidity checks.
   * @param _account Address of the account to snapshot
   * @return (token balance, borrow balance, exchange rate mantissa)
   */
  function getAccountSnapshot(address _account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (balanceOf(_account, 0), borrowBalancePerUser[_account], exchangeRateStored());
  }

  /*///////////////////////////////////////////////////////////////
                          Interest functions
    ///////////////////////////////////////////////////////////////*/

  /**
   * @notice Calculate the prevailing interest due per token of debt principal
   * @return Mantissa formatted interest rate per token of debt
   */
  function interestIndex() public view returns (uint256) {
    // Calculate the number of blocks elapsed since the last accrual
    uint256 blockDelta = block.number - accrualBlockNumber;

    // Short-circuit if no protocol debt or no blocks elapsed since last calculation
    uint256 borrowsPrior = totalBorrows;
    if (borrowsPrior == 0 || blockDelta == 0) {
      return interestIndexStored;
    }

    // Read the previous values out of storage
    uint256 cashPrior = getCashPrior() - totalAdminFees - totalHiveFees - totalProtocolFees;
    uint256 reservesPrior = totalReserves;

    // Calculate and validate the current borrow interest rate
    uint256 borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);

    if (borrowRateMantissa > borrowRateMaxMantissa) revert AccrueInterestError(Error.BORROW_RATE_TOO_BIG);

    uint256 simpleInterestFactor = borrowRateMantissa * blockDelta;

    return interestIndexStored + (simpleInterestFactor);
  }

  /**
   * @notice Accrues all interest due to the protocol
   * @dev Call this before performing calculations using 'totalBorrows' or other contract-wide quantities
   */
  function accrueInterest() public {
    /*
     * Calculate the interest accumulated into borrows, fees, and reserves:
     *  interestAccumulated = SUM(individual coupon interest accumulated)
     *  totalBorrows = interestAccumulated + totalBorrows
     *  totalReserves = interestAccumulated * reserveFactor + totalReserves
     *  totalHiveFees = interestAccumulated * hiveFee + totalHiveFees
     *  totalAdminFees = interestAccumulated * adminFee + totalAdminFees
     */

    // Only update if they have not already been updated.
    if (block.number > accrualBlockNumber) {
      interestIndexStored = interestIndex();
      accrualBlockNumber = block.number;
    }

    uint256 interestAccumulated;
    uint256 length = idCounter.current();

    // We may start at position 1 as position 0 is reserved for the null coupon
    for (uint256 i = 1; i <= length; ) {
      Collateral storage collateral = collateralPerBorrowCouponId[i];

      if (!collateral.active) {
        unchecked {
          ++i;
        }
        continue;
      }

      uint256 collateralId = collateral.collateralId;
      Coupon memory coupon = borrowCoupons[collateralId];

      if (coupon.active == COUPON_ACTIVE) {
        interestAccumulated += _updateInterest(collateralId);
      }
      unchecked {
        ++i;
      }
    }

    uint256 newTotalBorrows = totalBorrows + interestAccumulated;
    totalBorrows = newTotalBorrows;

    totalReserves += (reserveFactorMantissa * interestAccumulated) / 1e18;
    totalHiveFees += (hiveFeeMantissa * interestAccumulated) / 1e18;
    totalAdminFees += (adminFeeMantissa * interestAccumulated) / 1e18;

    emit InterestAccrued(interestAccumulated, interestIndexStored, newTotalBorrows);
  }

  /**
   * @notice Accrue interest due on the coupon corresponding to a collateral
   * @dev Call before interacting with a specific collateral
   * @dev Updates contract global quantities
   * @param _collateralId Collateral tokenId to accrue for
   * @return Amount of interest accrued
   */
  function accrueInterestToCollateral(uint256 _collateralId) public returns (uint256) {
    // Only update if they have not already been updated.
    if (block.number > accrualBlockNumber) {
      interestIndexStored = interestIndex();
      accrualBlockNumber = block.number;
    }

    uint256 earned = _updateInterest(_collateralId);

    totalBorrows += earned;

    totalReserves += (reserveFactorMantissa * earned) / 1e18;
    totalHiveFees += (hiveFeeMantissa * earned) / 1e18;
    totalAdminFees += (adminFeeMantissa * earned) / 1e18;

    return earned;
  }

  function _updateInterest(uint256 _collateralId) internal returns (uint256) {
    Coupon storage userCoupon = borrowCoupons[_collateralId];
    uint256 principalPrior = userCoupon.borrowAmount;
    uint256 interestIndexPrior = userCoupon.interestIndex;
    uint256 cachedInterestIndexStored = interestIndexStored;

    uint256 earned;
    if (decimals < 18) {
      earned = ((principalPrior * (cachedInterestIndexStored - interestIndexPrior)) / 10**(18 - decimals));
    } else {
      earned = ((principalPrior * (cachedInterestIndexStored - interestIndexPrior)) / 1e18);
    }

    if (earned > 0) {
      userCoupon.borrowAmount = principalPrior + earned;
      borrowBalancePerUser[userCoupon.owner] += earned;
    }

    userCoupon.interestIndex = cachedInterestIndexStored;

    // We emit an AccrueInterest event
    emit CouponInterestAccrued(userCoupon, principalPrior, earned, interestIndexPrior, cachedInterestIndexStored);

    return earned;
  }

  /**
   * @notice accrues interests to a selected set of coupons
   * @param _ids ids of coupons to accrue interest
   * @return all accrued interest
   */
  function accrueInterestToCouponsInternal(uint256[] calldata _ids) internal returns (uint256) {
    // Only update if they have not already been updated.
    if (block.number > accrualBlockNumber) {
      interestIndexStored = interestIndex();
      accrualBlockNumber = block.number;
    }

    uint256 interestAccumulated;
    uint256 length = _ids.length;

    // We may start at position 1 as position 0 is reserved for the null coupon
    for (uint256 i = 1; i <= length; ) {
      Collateral storage collateral = collateralPerBorrowCouponId[_ids[i]];

      if (!collateral.active) {
        unchecked {
          ++i;
        }
        continue;
      }

      Coupon storage coupon = borrowCoupons[collateral.collateralId];

      if (coupon.active == COUPON_ACTIVE) {
        interestAccumulated += _updateInterest(collateral.collateralId);
      }
      unchecked {
        ++i;
      }
    }

    totalBorrows += interestAccumulated;

    totalReserves += (reserveFactorMantissa * interestAccumulated) / 1e18;
    totalHiveFees += (hiveFeeMantissa * interestAccumulated) / 1e18;
    totalAdminFees += (adminFeeMantissa * interestAccumulated) / 1e18;

    return interestAccumulated;
  }

  /*///////////////////////////////////////////////////////////////
                    Reserve handling functions
  ///////////////////////////////////////////////////////////////*/

  /**
   * @dev adds reserves, accrues interests
   * @param _addAmount what to add
   */
  function _addReserves(uint256 _addAmount) external {
    if (!hasRole(SUPPLIER_ROLE, msg.sender)) revert Unauthorized();

    accrueInterest();

    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != block.number) {
      revert AdminError(Error.MARKET_NOT_FRESH);
    }

    /*
     * We call doTransferIn for the caller and the addAmount
     *  Note: The hToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the hToken holds an additional addAmount of cash.
     *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
     *  it returns the amount actually transferred, in case of a fee.
     */

    uint256 actualAddAmount = doUnderlyingTransferIn(msg.sender, _addAmount);
    uint256 totalReservesNew = totalReserves + actualAddAmount;
    totalReserves = totalReservesNew;

    emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);
  }

  /**
   * @notice Accrues interest and reduces reserves by transferring to admin
   * @param _reduceAmount Amount of reduction to reserves
   */
  function _reduceReserves(uint256 _reduceAmount) external {
    if (!hasRole(SUPPLIER_ROLE, msg.sender)) revert Unauthorized();

    accrueInterest();

    if (accrualBlockNumber != block.number) {
      revert AdminError(Error.MARKET_NOT_FRESH);
    }

    if (getCashPrior() < _reduceAmount) {
      revert AdminError(Error.TOKEN_INSUFFICIENT_CASH);
    }

    if (_reduceAmount > totalReserves) {
      revert AdminError(Error.BAD_INPUT);
    }

    unchecked {
      totalReserves -= _reduceAmount;
    }

    doUnderlyingTransferOut(msg.sender, _reduceAmount);

    emit ReservesReduced(msg.sender, _reduceAmount, totalReserves);
  }

  /*///////////////////////////////////////////////////////////////
                        Admin functions
  ///////////////////////////////////////////////////////////////*/

  /**
   * @notice accrues interest and sets a new admin, hive, protocol and reserve factor mantissas
   * @dev protocolFeeMantissa can not be more than 1%, max fraction of interest that can be set aside for reserves can be 1e18
   * @param _newHiveFeeMantissa new hive fee mantissa
   * @param _newAdminFeeMantissa new admin fee mantissa
   * @param _newReserveFactorMantissa new reserve factor mantissa
   * @param _newProtocolFeeMantissa new protocol fee mantissa
   */
  function _setProtocolFees(
    uint256 _newHiveFeeMantissa,
    uint256 _newAdminFeeMantissa,
    uint256 _newReserveFactorMantissa,
    uint256 _newProtocolFeeMantissa
  ) public {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Unauthorized();
    if (_newProtocolFeeMantissa > 1e16) revert AdminError(Error.BAD_INPUT);
    if (_newReserveFactorMantissa > 1e18) revert AdminError(Error.BAD_INPUT);

    accrueInterest();

    if (_newReserveFactorMantissa + _newAdminFeeMantissa + _newHiveFeeMantissa > reserveFactorPlusFeesMaxMantissa) {
      revert AdminError(Error.BAD_INPUT);
    }

    emit NewProtocolFees(
      hiveFeeMantissa,
      _newHiveFeeMantissa,
      adminFeeMantissa,
      _newAdminFeeMantissa,
      reserveFactorMantissa,
      _newReserveFactorMantissa,
      protocolFeeMantissa,
      _newProtocolFeeMantissa
    );

    hiveFeeMantissa = _newHiveFeeMantissa;
    adminFeeMantissa = _newAdminFeeMantissa;
    reserveFactorMantissa = _newReserveFactorMantissa;
    protocolFeeMantissa = _newProtocolFeeMantissa;
  }

  /**
   * @notice Withdraw admin fees
   * @param _amount amount to withdraw
   */
  function _withdrawAdminFees(uint256 _amount) external {
    if (!hasRole(MARKET_ADMIN_ROLE, msg.sender)) revert Unauthorized();

    accrueInterest();

    if (accrualBlockNumber != block.number) {
      revert AdminError(Error.MARKET_NOT_FRESH);
    }

    uint256 cachedTotalAdminFees = totalAdminFees;
    if (cachedTotalAdminFees < _amount) {
      revert AdminError(Error.AMOUNT_TOO_BIG);
    }

    if (getCashPrior() < cachedTotalAdminFees) {
      revert AdminError(Error.TOKEN_INSUFFICIENT_CASH);
    }

    unchecked {
      totalAdminFees = cachedTotalAdminFees - _amount;
    }

    doUnderlyingTransferOut(adminFeeReceiver, _amount);

    emit AdminFeesWithdrawn(_amount);
  }

  /**
   * @notice Withdraw hive fees
   * @param _amount amount to withdraw from the hive fees
   */
  function _withdrawHiveFees(uint256 _amount) external {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Unauthorized();

    accrueInterest();

    if (accrualBlockNumber != block.number) {
      revert AdminError(Error.MARKET_NOT_FRESH);
    }

    uint256 cachedTotalHiveFees = totalHiveFees;
    if (cachedTotalHiveFees < _amount) {
      revert AdminError(Error.AMOUNT_TOO_BIG);
    }

    if (getCashPrior() < cachedTotalHiveFees) {
      revert AdminError(Error.TOKEN_INSUFFICIENT_CASH);
    }

    unchecked {
      totalHiveFees = cachedTotalHiveFees - _amount;
    }

    doUnderlyingTransferOut(hiveFeeReceiver, _amount);

    emit HiveFeesWithdrawn(_amount);
  }

  /**
   * @notice Withdraw protocol fees
   * @param _amount amount to withdraw from the protocol fees
   */
  function _withdrawProtocolFees(uint256 _amount) external {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Unauthorized();

    accrueInterest();

    if (accrualBlockNumber != block.number) {
      revert AdminError(Error.MARKET_NOT_FRESH);
    }

    uint256 cachedTotalProtocolFees = totalProtocolFees;
    if (cachedTotalProtocolFees < _amount) {
      revert AdminError(Error.AMOUNT_TOO_BIG);
    }

    if (getCashPrior() < cachedTotalProtocolFees) {
      revert AdminError(Error.TOKEN_INSUFFICIENT_CASH);
    }

    unchecked {
      totalProtocolFees = cachedTotalProtocolFees - _amount;
    }

    doUnderlyingTransferOut(dao, _amount);

    emit ProtocolFeesWithdrawn(_amount);
  }

  /**
   * @notice Sets a new contract for a specific target
   * @param _newContract the address of the new contract
   * @param _target the targeted contract that needs to be set
   */
  function _setContract(address _newContract, uint256 _target) external {
    if (_newContract == address(0)) revert WrongParams();
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Unauthorized();

    address oldContract;
    if (_target == 0) {
      oldContract = address(liquidator);
      liquidator = _newContract;
    } else if (_target == 1) {
      oldContract = address(hTokenHelper);
      hTokenHelper = HTokenHelperI(_newContract);
    } else if (_target == 2) {
      oldContract = address(hivemind);
      hivemind = HivemindI(_newContract);
    } else if (_target == 3) {
      oldContract = adminFeeReceiver;
      adminFeeReceiver = _newContract;
    } else if (_target == 4) {
      oldContract = hiveFeeReceiver;
      hiveFeeReceiver = _newContract;
    } else if (_target == 5) {
      oldContract = address(interestRateModel);
      interestRateModel = InterestRateModelI(_newContract);
    } else revert WrongParams();
    emit NewContract(_newContract, oldContract);
  }

  /*///////////////////////////////////////////////////////////////
                            Overrides
    ///////////////////////////////////////////////////////////////*/

  /**
   * @notice returns the uri by calling the hTokenHelper
   * @param _id id of the token we want to get the uri
   */
  function uri(uint256 _id) public view virtual override returns (string memory) {
    return hTokenHelper.uri(_id, address(this));
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   * @inheritdoc IERC165
   */
  function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
    return
      _interfaceId == type(IERC1155).interfaceId ||
      _interfaceId == type(AccessControl).interfaceId ||
      _interfaceId == type(IERC721Receiver).interfaceId ||
      _interfaceId == type(HTokenI).interfaceId;
  }

  /**
   * @inheritdoc IERC721Receiver
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function _beforeTokenTransfer(
    address _operator,
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) internal virtual override(ERC1155) {
    if (_from == _to) {
      super._beforeTokenTransfer(_operator, _from, _to, _ids, _amounts, _data);
      return;
    }
    uint256 len = _ids.length;
    uint256 lengthToModify;
    for (uint256 i; i < len; ) {
      // HTokens don't require coupon management
      if (_ids[i] > 0) {
        Collateral storage collateral = collateralPerBorrowCouponId[_ids[i]];
        if (!collateral.active) {
          unchecked {
            ++i;
          }
          continue;
        }

        Coupon storage coupon = borrowCoupons[collateral.collateralId];
        coupon.owner = _to;
        uint256 _borrowAmount = coupon.borrowAmount;
        borrowBalancePerUser[_from] -= _borrowAmount;
        borrowBalancePerUser[_to] += _borrowAmount;
        unchecked {
          ++lengthToModify;
        }
      }
      unchecked {
        ++i;
      }
    }

    hivemind.transferAllowed(HTokenI(address(this)));

    if (_from != address(0)) {
      userToCoupons[_from] -= lengthToModify;
    }
    if (_to != address(0)) {
      userToCoupons[_to] += lengthToModify;
    }
    super._beforeTokenTransfer(_operator, _from, _to, _ids, _amounts, _data);
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import ".././interfaces/HTokenI.sol";

/**
 * @title Interface for HTokenHelper
 * @author Honey Finance Labs
 * @custom:coauthor m4rio
 * @custom:contributor BowTiedPickle
 */
interface HTokenHelperI {
  /**
   * @notice Get the outstanding debt of the protocol
   * @dev call accrueInterest() first to ensure accurate data, otherwise some inaccuracy will result
   * @return Protocol debt
   */
  function getDebt(HTokenI _hToken) external view returns (uint256);

  /**
   * @notice Get cash balance of this hToken in the underlying asset
   * @return The quantity of underlying asset owned by this contract
   */
  function getCash(HTokenI _hToken) external view returns (uint256);

  /**
   * @notice Get underlying balance that is available for withdrawal or borrow
   * @return The quantity of underlying not tied up
   */
  function getAvailableUnderlying(HTokenI _hToken) external view returns (uint256);

  /**
   * @notice Get underlying balance for an account
   * @param _account the account to check the balance for
   * @return The quantity of underlying asset owned by this account
   */
  function getAvailableUnderlyingForUser(HTokenI _hToken, address _account) external view returns (uint256);

  /**
   * @notice Get underlying balance that is available to be withdrawn
   * @return The quantity of underlying that can be borrowed
   */
  function getAvailableUnderlyingToBorrow(HTokenI _hToken) external view returns (uint256);

  /**
   * @notice returns different assets per a hToken, helper method to reduce frontend calls
   * @param _hToken the hToken to get the assets for
   * @return total borrows
   * @return total reserves
   * @return total underlying balance
   * @return active coupons
   */
  function getAssets(HTokenI _hToken)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      HTokenI.Coupon[] memory
    );

  /**
   * @notice returns prices for a market to reduce frontend calls
   * @param _hToken the hToken to get the prices for
   * @return collection floor price in underlying value
   * @return underlying price in usd
   */
  function getMarketOraclePrices(HTokenI _hToken) external view returns (uint256, uint256);

  /**
   * @notice returns the collection price floor in usd
   * @param _hToken the hToken to get the price for
   * @return collection floor price in usd
   */
  function getFloorPriceInUSD(HTokenI _hToken) external view returns (uint256);

  /**
   * @notice get the underlying price in usd for a hToken
   * @param _hToken the hToken to get the price for
   * @return underlying price in usd
   */
  function getUnderlyingPriceInUSD(HTokenI _hToken) external view returns (uint256);

  /**
   * @notice uri function called from the HToken that returns the uri metadata for a coupon
   * @param _id id of the hToken
   * @param _hTokenAddress address of the hToken
   */
  function uri(uint256 _id, address _hTokenAddress) external view returns (string memory);
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
  function oracle() external view returns (PriceOracleI);

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
   */
  function getHypotheticalAccountLiquidity(
    HTokenI _hToken,
    address _account,
    uint256 _collateralId,
    uint256 _redeemTokens,
    uint256 _borrowAmount
  ) external view returns (uint256 liquidity, uint256 shortfall);

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
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title Modified Compound's InterestRateModel Interface
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:contributor m4rio
 */
interface InterestRateModelI {
  /**
   * @notice Calculates the current borrow rate per block
   * @param _cash The amount of cash in the market
   * @param _borrows The amount of borrows in the market
   * @param _reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(
    uint256 _cash,
    uint256 _borrows,
    uint256 _reserves
  ) external view returns (uint256);

  /**
   * @notice Calculates the current supply rate per block
   * @param _cash The amount of cash in the market
   * @param _borrows The amount of borrows in the market
   * @param _reserves The amount of reserves in the market
   * @param _reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 _cash,
    uint256 _borrows,
    uint256 _reserves,
    uint256 _reserveFactorMantissa
  ) external view returns (uint256);

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param _cash The amount of cash in the market
   * @param _borrows The amount of borrows in the market
   * @param _reserves The amount of reserves in the market
   * @return The utilization rate as a mantissa between [0, 1e18]
   */
  function utilizationRate(
    uint256 _cash,
    uint256 _borrows,
    uint256 _reserves
  ) external pure returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

error Unauthorized();
error AccrueInterestError(ErrorReporter.Error error);
error WrongParams();
error Unexpected(string error);
error InvalidCoupon();
error HivemindError(ErrorReporter.Error error);
error AdminError(ErrorReporter.Error error);
error MarketError(ErrorReporter.Error error);
error HTokenError(ErrorReporter.Error error);
error LiquidatorError(ErrorReporter.Error error);
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
contract ErrorReporter {
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
    AUCTION_PRICE_TOO_LOW,
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
    NOT_FOUND
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
import "./HTokenInternalI.sol";

/**
 * @title Interface of HToken
 * @author Honey Finance Labs
 * @custom:coauthor BowTiedPickle
 * @custom:coauthor m4rio
 */
interface HTokenI is HTokenInternalI {
  // ----- Lend side functions -----

  /**
   * @notice Deposit underlying ERC-20 asset and mint hTokens
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _amount Quantity of underlying ERC-20 to transfer in
   */
  function depositUnderlying(uint256 _amount) external;

  /**
   * @notice Redeem a specified amount of hTokens for their underlying ERC-20 asset
   * @param _amount Quantity of hTokens to redeem for underlying ERC-20
   */
  function redeem(uint256 _amount) external;

  /**
   * @notice Withdraws the specified _amount of underlying ERC-20 asset, consuming the minimum amount of hTokens necessary
   * @param _amount Quantity of underlying ERC-20 tokens to withdraw
   */
  function withdraw(uint256 _amount) external;

  // ----- Borrow side functions -----

  /**
   * @notice Deposit a specified token of the underlying ERC-721 asset and mint an ERC-1155 deposit coupon NFT
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _collateralId Token ID of underlying ERC-721 to be transferred in
   */
  function depositCollateral(uint256 _collateralId) external;

  /**
   * @notice Deposit multiple specified tokens of the underlying ERC-721 asset and mint ERC-1155 deposit coupons NFT
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _collateralIds Token IDs of underlying ERC-721 to be transferred in
   */
  function depositMultiCollateral(uint256[] calldata _collateralIds) external;

  /**
   * @notice Sender borrows assets from the protocol against the specified collateral asset
   * @dev Collateral must be deposited first.
   * @param _borrowAmount Amount of underlying ERC-20 to borrow
   * @param _collateralId Token ID of underlying ERC-721 to be borrowed against
   */
  function borrow(uint256 _borrowAmount, uint256 _collateralId) external;

  /**
   * @notice Sender repays their own borrow taken against the specified collateral asset
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _repayAmount Amount of underlying ERC-20 to repay
   * @param _collateralId Token ID of underlying ERC-721 to be repaid against
   */
  function repayBorrow(uint256 _repayAmount, uint256 _collateralId) external;

  /**
   * @notice Sender repays another user's borrow taken against the specified collateral asset
   * @dev Pull pattern, user must approve the contract before calling.
   * @param _borrower User whose borrow will be repaid
   * @param _repayAmount Amount of underlying ERC-20 to repay
   * @param _collateralId Token ID of underlying ERC-721 to be repaid against
   */
  function repayBorrowBehalf(
    address _borrower,
    uint256 _repayAmount,
    uint256 _collateralId
  ) external;

  /**
   * @notice Burn a deposit coupon NFT and withdraw the associated underlying ERC-721 NFT
   * @param _collateralId collateral Id, aka the NFT token Id
   */
  function withdrawCollateral(uint256 _collateralId) external;

  /**
   * @notice Burn multiple deposit coupons NFT and withdraw the associated underlying ERC-721 NFTs
   * @param _collateralIds collateral Ids, aka the NFT token Ids
   */
  function withdrawMultiCollateral(uint256[] calldata _collateralIds) external;

  /**
   * @notice Triggers transfer of an NFT to the liquidation contract
   * @param _collateralId collateral Id, aka the NFT token Id representing the borrow position to liquidate
   */
  function liquidateBorrow(uint256 _collateralId) external;

  /**
   * @notice Pay off the entirety of a borrow position and burn the coupon
   * @dev May only be called by the liquidator
   * @param _borrower borrower who pays
   * @param _collateralId what to pay for
   */
  function closeoutLiquidation(address _borrower, uint256 _collateralId) external;

  /**
   * @notice accrues interests to a selected set of coupons
   * @param _ids ids of coupons to accrue interest
   * @return all accrued interest
   */
  function accrueInterestToCoupons(uint256[] calldata _ids) external returns (uint256);

  // ----- Utility functions -----

  /**
   * @notice A public function to sweep accidental ERC-20 transfers to this contract.
   * @dev Tokens are sent to the dao for later distribution, we use transfer and not safeTransfer as this is admin only method
   * @param _token The address of the ERC-20 token to sweep
   */
  function sweepToken(IERC20 _token) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title Interface of HToken Internal
 * @author Honey Finance Labs
 * @custom:coauthor m4rio
 * @custom:coauthor BowTiedPickle
 */
interface HTokenInternalI is IERC1155 {
  // Coupon NFT metadata
  struct Coupon {
    uint32 id; //coupon id
    uint8 active; // Whether this coupon is active and should be counted in calculations etc. 0 = not initialized, 1 = inactive, 2 = active
    address owner; // Who is the owner of this coupon, this changes at transfer
    uint256 collateralId; // tokenId of the collateral collection that is borrowed against
    uint256 borrowAmount; // Principal borrow balance, denominated in underlying ERC20 token. Updated when interest is accrued to the coupon.
    uint256 interestIndex; // Mantissa formatted borrow interestIndex. Updated when interest is accrued to the coupon.
  }

  struct Collateral {
    uint256 collateralId;
    bool active;
  }

  // ----- Informational -----

  function decimals() external view returns (uint8);

  // ----- Addresses -----

  function collateralToken() external view returns (IERC721);

  function underlyingToken() external view returns (IERC20);

  function hivemind() external view returns (address);

  function dao() external view returns (address);

  function interestRateModel() external view returns (address);

  function initialExchangeRateMantissa() external view returns (address);

  // ----- Fee Information -----

  function reserveFactorMantissa() external view returns (uint256);

  function reserveFactorMaxMantissa() external view returns (uint256);

  function borrowRateMaxMantissa() external view returns (uint256);

  function adminFeeMantissa() external view returns (uint256);

  function fuseFeeMantissa() external view returns (uint256);

  function reserveFactorPlusFeesMaxMantissa() external view returns (uint256);

  // ----- Protocol Accounting -----

  function totalBorrows() external view returns (uint256);

  function totalReserves() external view returns (uint256);

  function totalHTokenSupply() external view returns (uint256);

  function totalFuseFees() external view returns (uint256);

  function totalAdminFees() external view returns (uint256);

  function accrualBlockNumber() external view returns (uint256);

  function interestIndexStored() external view returns (uint256);

  /**
   * @notice Calculate the prevailing interest due per token of debt principal
   * @return Mantissa formatted interest rate per token of debt
   */
  function interestIndex() external view returns (uint256);

  function totalHiveFees() external view returns (uint256);

  function userToCoupons(address _user) external view returns (uint256);

  function collateralPerBorrowCouponId(uint256 _couponId) external view returns (Collateral memory);

  function borrowCoupons(uint256 _collateralId) external view returns (Coupon memory);

  // ----- Views -----

  /**
   * @notice Get all a user's coupons
   * @param _user The user to search for
   * @return Array of all coupons belonging to the user
   */
  function getUserCoupons(address _user) external view returns (Coupon[] memory);

  /**
   * @notice Get tokenIds of all a user's coupons
   * @param _user The user to search for
   * @return Array of indices of all coupons belonging to the user
   */
  function getUserCouponIndices(address _user) external view returns (uint256[] memory);

  /**
   * @notice Get the coupon for a specific collateral NFT
   * @param _collateralId collateral id
   * @return Coupon
   */
  function getSpecificCouponByCollateralId(uint256 _collateralId) external view returns (Coupon memory);

  /**
   * @notice Get the number of coupons deposited aka active
   * @return Array of all active coupons
   */
  function getActiveCoupons() external view returns (Coupon[] memory);

  /**
   * @notice Returns the current per-block borrow interest rate for this hToken
   * @return The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view returns (uint256);

  /**
   * @notice Get the outstanding debt of a coupon
   * @dev Simulates accrual of interest
   * @param _collateralId collateral ID of the coupon
   * @return Debt denominated in the underlying token
   */
  function getBorrowFromCouponByCollateral(uint256 _collateralId) external view returns (uint256);

  /**
   * @notice Get a snapshot of the account's balances, and the cached exchange rate
   * @dev This is used by hivemind to more efficiently perform liquidity checks.
   * @param _account Address of the account to snapshot
   * @return (token balance, borrow balance, exchange rate mantissa)
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
   * @notice Get the outstanding debt for a collateral
   * @dev Simulates accrual of interest
   * @param _collateralId collateral id we want to get the borrow amount for
   * @return The amount borrowed so far
   */
  function getBorrowAmountForCollateral(uint256 _collateralId) external view returns (uint256);

  /**
   * @notice returns the uri by calling the hTokenHelper
   * @param _id id of the token we want to get the uri
   */
  function uri(uint256 _id) external view returns (string memory);

  // ----- State Changing Permissionless -----

  /**
   * @notice Accrues all interest due to the protocol
   * @dev Call this before performing calculations using 'totalBorrows' or other contract-wide quantities
   */
  function accrueInterest() external;

  /**
   * @notice Accrue interest due on the coupon corresponding to a collateral
   * @dev Call before interacting with a specific collateral
   * @dev Updates contract global quantities
   * @param _collateralId Collateral tokenId to accrue for
   * @return Amount of interest accrued
   */
  function accrueInterestToCollateral(uint256 _collateralId) external returns (uint256);

  /**
   * @notice Accrue interest then return the up-to-date exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() external returns (uint256);

  /**
   * @notice Calculates the exchange rate from the underlying to the HToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return (error code, calculated exchange rate scaled by 1e18)
   */
  function exchangeRateStored() external view returns (uint256);

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying tokens owned by this contract
   */
  function getCashPrior() external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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