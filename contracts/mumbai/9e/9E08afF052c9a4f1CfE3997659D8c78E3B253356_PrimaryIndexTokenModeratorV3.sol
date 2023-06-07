// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


interface IBLendingToken{

    
     /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param minter the address of account which earn liquidity
     * @param mintAmount The amount of the underlying asset to supply to minter
     * return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     * return uint minted amount
     */
    function mintTo(address minter, uint mintAmount) external returns (uint err, uint mintedAmount);


    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemTo(address redeemer, uint redeemTokens) external returns (uint);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlyingTo(address redeemer, uint redeemAmount) external returns (uint);

    function borrowTo(address borrower, uint borrowAmount) external returns (uint borrowError);

    function repayTo(address payer, address borrower, uint256 repayAmount) external returns (uint repayBorrowError, uint amountRepayed);

    function repayBorrowToBorrower(address projectToken, address payer,address borrower, uint repayAmount) external returns (uint repayBorrowError, uint amountRepayed);

     /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrowBalanceStored(address account) external view returns (uint);
  
    function totalSupply() external view returns(uint256);

    function totalBorrows() external view returns(uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);

    function getEstimatedBorrowBalanceStored(address account) external view returns(uint accrual);


}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPriceProviderAggregator {
    
    function MODERATOR_ROLE() external view returns(bytes32);
    
    function usdDecimals() external view returns(uint8);

    function tokenPriceProvider(address projectToken) external view returns(address priceProvider, bool hasSignedFunction);

    event GrandModeratorRole(address indexed who, address indexed newModerator);
    event RevokeModeratorRole(address indexed who, address indexed moderator);
    event SetTokenAndPriceProvider(address indexed who, address indexed token, address indexed priceProvider);
    event ChangeActive(address indexed who, address indexed priceProvider, address indexed token, bool active);

    function initialize() external;

    /****************** Admin functions ****************** */

    function grandModerator(address newModerator) external;

    function revokeModerator(address moderator) external;

    /****************** end Admin functions ****************** */

    /****************** Moderator functions ****************** */

    function setTokenAndPriceProvider(address token, address priceProvider, bool hasFunctionWithSign) external;

    function changeActive(address priceProvider, address token, bool active) external;

    /****************** main functions ****************** */

    /**
     * @dev returns tuple (priceMantissa, priceDecimals)
     * @notice price = priceMantissa / (10 ** priceDecimals)
     * @param token the address of token wich price is to return
     */
    function getPrice(address token) external view returns(uint256 priceMantissa, uint8 priceDecimals);

    /**
     * @dev returns the price of token multiplied by 10 ** priceDecimals given by price provider.
     * price can be calculated as  priceMantissa / (10 ** priceDecimals)
     * i.e. price = priceMantissa / (10 ** priceDecimals)
     * @param token the address of token
     * @param _priceMantissa - the price of token (used in verifying the signature)
     * @param _priceDecimals - the price decimals (used in verifying the signature)
     * @param validTo - the timestamp in seconds (used in verifying the signature)
     * @param signature - the backend signature of secp256k1. length is 65 bytes
     */
    function getPriceSigned(address token, uint256 _priceMantissa, uint8 _priceDecimals, uint256 validTo, bytes memory signature) external view returns(uint256 priceMantissa, uint8 priceDecimals);

    /**
     * @dev returns the USD evaluation of token by its `tokenAmount`
     * @param token the address of token to evaluate
     * @param tokenAmount the amount of token to evaluate
     */
    function getEvaluation(address token, uint256 tokenAmount) external view returns(uint256 evaluation);
    
    /**
     * @dev returns the USD evaluation of token by its `tokenAmount`
     * @param token the address of token
     * @param tokenAmount the amount of token including decimals
     * @param priceMantissa - the price of token (used in verifying the signature)
     * @param priceDecimals - the price decimals (used in verifying the signature)
     * @param validTo - the timestamp in seconds (used in verifying the signature)
     * @param signature - the backend signature of secp256k1. length is 65 bytes
     */
    function getEvaluationSigned(address token, uint256 tokenAmount, uint256 priceMantissa, uint8 priceDecimals, uint256 validTo, bytes memory signature) external view returns(uint256 evaluation);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPrimaryIndexTokenV3 {
    function setBorrowLimitPerCollateral(
        address projectToken,
        uint256 _borrowLimit
    ) external;

    function setBorrowLimitPerLendingAsset(
        address lendingToken,
        uint256 _borrowLimit
    ) external;

    function grantRole(bytes32 role, address newModerator) external;

    function revokeRole(bytes32 role, address moderator) external;

    function setPrimaryIndexTokenLeverage(
        address newPrimaryIndexTokenLeverage
    ) external;

    function setRelatedContract(
        address relatedContract,
        bool isRelated
    ) external;

    function getRelatedContract(
        address relatedContract
    ) external view returns (bool);

    function setUSDCToken(address usdc) external;

    function setTotalBorrowPerLendingToken(
        address lendingToken,
        uint totalBorrowAmount
    ) external;

    function _depositPosition(
        address,
        address,
        address
    ) external returns (uint);

    function usdcToken() external view returns (address);

    function getLendingToken(
        address user,
        address projectToken
    ) external view returns (address);

    function totalOutstandingInUSD(
        address account
    ) external view returns (uint256 totalEvaluation);

    function getTokenEvaluation(
        address token,
        uint256 tokenAmount
    ) external view returns (uint256);

    function getBorrowedPerLendingTokenInUSD(
        address lendingToken
    ) external view returns (uint);

    function getPriceConvert(
        address lendingToken,
        uint amount
    ) external view returns (uint256);

    function calcDepositPosition(
        address projectToken,
        uint256 projectTokenAmount,
        address user
    ) external;

    function calcAndTransferDepositPosition(
        address projectToken,
        uint256 projectTokenAmount,
        address user,
        address receiver
    ) external returns (uint256);

    function calcBorrowPosition(
        address borrower,
        address lendingToken,
        uint256 lendingTokenAmount
    ) external;

    function getTotalBorrowPerLendingToken(
        address lendingToken
    ) external view returns (uint);

    function borrowLimitPerLendingToken(address) external view returns (uint);

    function depositFromRelatedContracts(
        address projectToken,
        uint256 projectTokenAmount,
        address user,
        address beneficiary
    ) external;

    function withdrawFromRelatedContracts(
        address projectToken,
        uint256 projectTokenAmount,
        address user,
        address beneficiar
    ) external returns (uint256);

    function supplyFromRelatedContract(
        address lendingToken,
        uint256 lendingTokenAmount,
        address user
    ) external;

    function redeemFromRelatedContract(
        address lendingToken,
        uint256 bLendingTokenAmount,
        address user
    ) external;

    function redeemUnderlyingFromRelatedContract(
        address lendingToken,
        uint256 lendingTokenAmount,
        address user
    ) external;

    function borrowFromRelatedContract(
        address projectToken,
        address lendingToken,
        uint256 lendingTokenAmount,
        address user
    ) external;

    function repayFromRelatedContract(
        address lendingToken,
        uint256 lendingTokenAmount,
        address repairer,
        address borrower
    ) external returns (uint256);

    /**
     * @dev return keccak("MODERATOR_ROLE")
     */
    function MODERATOR_ROLE() external view returns (bytes32);

    /**
     * @dev return address of price oracle with interface of PriceProviderAggregator
     */
    function priceOracle() external view returns (address);

    /**
     * @dev return address project token in array `projectTokens`
     * @param projectTokenId - index of project token in array `projectTokens`. Numetates from 0 to array length - 1
     */
    function projectTokens(
        uint256 projectTokenId
    ) external view returns (address);

    /**
     * @dev return info of project token, that declared in struct ProjectTokenInfo
     * @param projectToken - address of project token in array `projectTokens`. Numetates from 0 to array length - 1
     */
    function projectTokenInfo(
        address projectToken
    ) external view returns (ProjectTokenInfo memory);

    /**
     * @dev return address lending token in array `lendingTokens`
     * @param lendingTokenId - index of lending token in array `lendingTokens`. Numetates from 0 to array length - 1
     */
    function lendingTokens(
        uint256 lendingTokenId
    ) external view returns (address);

    /**
     * @dev return info of lending token, that declared in struct LendingTokenInfo
     * @param lendingToken - address of lending token in array `lendingTokens`. Numetates from 0 to array length - 1
     */
    function lendingTokenInfo(
        address lendingToken
    ) external view returns (LendingTokenInfo memory);

    /**
     * @dev return total amount of deposited project token
     * @param projectToken - address of project token in array `projectTokens`. Numetates from 0 to array length - 1
     */
    function totalDepositedProjectPerToken(
        address projectToken
    ) external view returns (uint256);

    /**
     * @dev return deposit position struct
     * @param account - address of depositor
     * @param projectToken - address of project token
     */
    function depositedAmount(
        address account,
        address projectToken
    ) external view returns (uint256);

    /**
     * @dev return borrow position struct
     * @param account - address of borrower
     * @param lendingToken - address of lending token
     */
    function borrowPosition(
        address account,
        address lendingToken
    ) external view returns (BorrowPosition memory);

    /**
     * @dev return total borrow amount of `lendingToken` by `projectToken`
     * @param projectToken - address of project token
     * @param lendingToken - address of lending token
     */
    function totalBorrow(
        address projectToken,
        address lendingToken
    ) external view returns (uint256);

    /**
     * @dev return borrow limit amount of `lendingToken` by `projectToken`
     * @param projectToken - address of project token
     * @param lendingToken - address of lending token
     */
    function borrowLimit(
        address projectToken,
        address lendingToken
    ) external view returns (uint256);

    struct Ratio {
        uint8 numerator;
        uint8 denominator;
    }

    struct ProjectTokenInfo {
        bool isListed;
        bool isDepositPaused; // true - paused, false - not paused
        bool isWithdrawPaused; // true - paused, false - not paused
        Ratio loanToValueRatio;
    }

    struct LendingTokenInfo {
        bool isListed;
        bool isPaused;
        address bLendingToken;
        Ratio loanToValueRatio;
    }

    struct DepositPosition {
        uint256 depositedProjectTokenAmount;
    }

    struct BorrowPosition {
        uint256 loanBody; // [loanBody] = lendingToken
        uint256 accrual; // [accrual] = lendingToken
    }

    event AddPrjToken(address indexed tokenPrj);

    event LoanToValueRatioSet(
        address indexed tokenPrj,
        uint8 lvrNumerator,
        uint8 lvrDenominator
    );

    event LiquidationThresholdFactorSet(
        address indexed tokenPrj,
        uint8 ltfNumerator,
        uint8 ltfDenominator
    );

    event Deposit(
        address indexed who,
        address indexed tokenPrj,
        uint256 prjDepositAmount,
        address indexed beneficiar
    );

    event Withdraw(
        address indexed who,
        address indexed tokenPrj,
        uint256 prjWithdrawAmount,
        address indexed beneficiar
    );

    event Supply(
        address indexed who,
        address indexed supplyToken,
        uint256 supplyAmount,
        address indexed supplyBToken,
        uint256 amountSupplyBTokenReceived
    );

    event Redeem(
        address indexed who,
        address indexed redeemToken,
        address indexed redeemBToken,
        uint256 redeemAmount
    );

    event RedeemUnderlying(
        address indexed who,
        address indexed redeemToken,
        address indexed redeemBToken,
        uint256 redeemAmountUnderlying
    );

    event Borrow(
        address indexed who,
        address indexed borrowToken,
        uint256 borrowAmount,
        address indexed prjAddress,
        uint256 prjAmount
    );

    event RepayBorrow(
        address indexed who,
        address indexed borrowToken,
        uint256 borrowAmount,
        address indexed prjAddress,
        bool isPositionFullyRepaid
    );

    event Liquidate(
        address indexed liquidator,
        address indexed borrower,
        address lendingToken,
        address indexed prjAddress,
        uint256 amountPrjLiquidated
    );

    function initialize() external;

    //************* ADMIN FUNCTIONS ********************************

    function addProjectToken(
        address _projectToken,
        uint8 _loanToValueRatioNumerator,
        uint8 _loanToValueRatioDenominator,
        uint8 _liquidationTresholdFactorNumerator,
        uint8 _liquidationTresholdFactorDenominator,
        uint8 _liquidationIncentiveNumerator,
        uint8 _liquidationIncentiveDenominator
    ) external;

    function removeProjectToken(
        uint256 _projectTokenId,
        address projectToken
    ) external;

    function addLendingToken(
        address _lendingToken,
        address _bLendingToken,
        bool _isPaused
    ) external;

    function removeLendingToken(
        uint256 _lendingTokenId,
        address lendingToken
    ) external;

    function setPriceOracle(address _priceOracle) external;

    function grandModerator(address newModerator) external;

    function revokeModerator(address moderator) external;

    //************* MODERATOR FUNCTIONS ********************************

    /**
     * @dev sets borrow limit
     * @param projectToken - address of project token
     * @param lendingToken - address of lending token
     * @param _borrowLimit - limit amount of lending token
     */
    function setBorrowLimit(
        address projectToken,
        address lendingToken,
        uint256 _borrowLimit
    ) external;

    /**
     * @dev sets project token info
     * @param _projectToken - address of project token
     * @param _isDepositPaused The new pause status for deposit
     * @param _isWithdrawPaused The new pause status for withdrawal
     * @param _loanToValueRatioNumerator - numerator of loan to value ratio
     * @param _loanToValueRatioDenominator - denominator of loan to value ratio
     */
    function setProjectTokenInfo(
        address _projectToken,
        bool _isDepositPaused,
        bool _isWithdrawPaused,
        uint8 _loanToValueRatioNumerator,
        uint8 _loanToValueRatioDenominator
    ) external;

    /**
     * @dev sets pause of project token
     * @param _projectToken - address of project token
     * @param _isDepositPaused - true - if pause, false - if unpause
     * @param _isWithdrawPaused - true - if pause, false - if unpause
     */
    function setPausedProjectToken(
        address _projectToken,
        bool _isDepositPaused,
        bool _isWithdrawPaused
    ) external;

    /**
     * @dev Sets the parameters for a lending token
     * @param _lendingToken The address of the lending token
     * @param _bLendingToken The address of the corresponding bLending token
     * @param _isPaused The new pause status for the lending token
     * @param _loanToValueRatioNumerator The numerator of the loan-to-value ratio for the lending token
     * @param _loanToValueRatioDenominator The denominator of the loan-to-value ratio for the lending token
     */
    function setLendingTokenInfo(
        address _lendingToken,
        address _bLendingToken,
        bool _isPaused,
        uint8 _loanToValueRatioNumerator,
        uint8 _loanToValueRatioDenominator
    ) external;

    /**
     * @dev sets pause of lending token
     * @param _lendingToken - address of lending token
     * @param _isPaused - true - if pause, false - if unpause
     */
    function setPausedLendingToken(
        address _lendingToken,
        bool _isPaused
    ) external;

    //************* PUBLIC FUNCTIONS ********************************

    /**
     * @dev deposit project token to PrimaryIndexToken
     * @param projectToken - address of project token
     * @param projectTokenAmount - amount of project token to deposit
     */
    function deposit(address projectToken, uint256 projectTokenAmount) external;

    /**
     * @dev withdraw project token from PrimaryIndexToken
     * @param projectToken - address of project token
     * @param projectTokenAmount - amount of project token to deposit
     */
    function withdraw(
        address projectToken,
        uint256 projectTokenAmount
    ) external;

    /**
     * @dev supply lending token
     * @param lendingToken - address of lending token
     * @param lendingTokenAmount - amount of lending token to supply
     */
    function supply(address lendingToken, uint256 lendingTokenAmount) external;

    /**
     * @dev redeem lending token
     * @param lendingToken - address of lending token
     * @param bLendingTokenAmount - amount of fLending token to redeem
     */
    function redeem(address lendingToken, uint256 bLendingTokenAmount) external;

    /**
     * @dev redeem underlying lending token
     * @param lendingToken - address of lending token
     * @param lendingTokenAmount - amount of lending token to redeem
     */
    function redeemUnderlying(
        address lendingToken,
        uint256 lendingTokenAmount
    ) external;

    /**
     * @dev borrow lending token
     * @param projectToken - address of project token
     * @param lendingToken - address of lending token
     * @param lendingTokenAmount - amount of lending token
     */
    function borrow(
        address projectToken,
        address lendingToken,
        uint256 lendingTokenAmount
    ) external;

    /**
     * @dev repay lending token
     * @param projectToken - address of project token
     * @param lendingToken - address of lending token
     * @param lendingTokenAmount - amount of lending token
     */
    function repay(
        address projectToken,
        address lendingToken,
        uint256 lendingTokenAmount
    ) external returns (uint256);

    /**
     * @dev update borrow position
     * @param account - address of borrower
     */
    function updateInterestInAllBorrowPositions(address account) external;

    //************* VIEW FUNCTIONS ********************************

    /**
     * @dev Returns the total PIT (primary index token) value for a given account and all project tokens.
     * @param account Address of the account.
     * @return totalEvaluation total PIT value.
     * Formula: pit = $ * LVR
     * total PIT = sum of PIT for all project tokens
     */
    function totalPIT(address account) external view returns (uint256);

    /**
     * @dev return pit remaining amount of borrow position
     * @param account - address of borrower
     */
    function totalPITRemaining(address account) external view returns (uint256);

    /**
     * @dev Returns the total estimated remaining PIT (primary index token) of a given account and all project tokens.
     * @param account The address of the user's borrow position
     */
    function totalEstimatedPITRemaining(
        address account
    ) external view returns (uint256);

    /**
     * @dev return liquidationThreshold of borrow position
     * @param account - address of borrower
     * @param projectToken - address of project token
     * @param lendingToken - address of lending token
     */
    function liquidationThreshold(
        address account,
        address projectToken,
        address lendingToken
    ) external view returns (uint256);

    /**
     * @dev return total outstanding of borrow position
     * @param account - address of borrower
     * @param projectToken - address of project token
     * @param lendingToken - address of lending token
     */
    function totalOutstanding(
        address account,
        address projectToken,
        address lendingToken
    ) external view returns (uint256);

    /**
     * @dev Returns the estimated outstanding amount of a user's borrow position for a specific lending token
     * @param account The address of the user's borrow position
     * @param lendingToken The address of the lending token
     */
    function getEstimatedOutstanding(
        address account,
        address lendingToken
    ) external view returns (uint256 loanBody, uint256 accrual);

    /**
     * @dev Returns the health factor of a user account
     * @param account The address of the user's borrow position
     * @return numerator The numerator of the health factor
     * @return denominator The denominator of the health factor
     */
    function healthFactor(
        address account
    ) external view returns (uint256 numerator, uint256 denominator);

    /**
     * @dev return length of array `lendingTokens`
     */
    function lendingTokensLength() external view returns (uint256);

    /**
     * @dev return length of array `projectTokens`
     */
    function projectTokensLength() external view returns (uint256);

    /**
     * @dev return decimals of PrimaryIndexToken
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Get the loan to value ratio of a position taken by a project token and a lending token
     * @param projectToken The address of the project token
     * @param lendingToken The address of the lending token
     * @return lvrNumerator The numerator of the loan to value ratio
     * @return lvrDenominator The denominator of the loan to value ratio
     */
    function getLoanToValueRatio(
        address projectToken,
        address lendingToken
    ) external view returns (uint256 lvrNumerator, uint256 lvrDenominator);

    /**
     * @dev Returns the estimated health factor of a user account at current
     * @param account The address of the user's borrow position
     * @return numerator The numerator of the health factor
     * @return denominator The denominator of the health factor
     */
    function estimatedHealthFactor(
        address account
    ) external view returns (uint256 numerator, uint256 denominator);

    /**
     * @dev Returns the total deposited amount in USD for a given account and all project tokens.
     * @param account Address of the account.
     * @return totalEvaluation total deposited amount.
     */
    function totalDepositedAmountInUSD(
        address account
    ) external view returns (uint256);

    /**
     * @dev Returns the total estimated outstanding amount of all user's borrow positions to USD
     * @param account The address of the user account
     * @return totalEvaluation total outstanding amount in USD
     */
    function totalEstimatedOutstandingInUSD(
        address account
    ) external view returns (uint256 totalEvaluation);

    /**
     * @dev Convert the total estimated weighted loan amount of all user's borrow positions to USD
     * @param account The address of the user account
     * @return totalEvaluation total weighted loan amount in USD
     */
    function totalEstimatedWeightedLoanInUSD(
        address account
    ) external view returns (uint256 totalEvaluation);

    /**
     * @dev Returns the total outstanding amount of a user's borrow position for a specific lending token to USD
     * @param account The address of the user's borrow position
     * @param lendingToken The address of the lending token
     * @return loanBody The amount of the lending token borrowed by the user
     * @return accrual The accrued interest of the borrow position
     * @return estimatedOutstandingInUSD estimated outstanding amount in USD
     */
    function getEstimatedOutstandingInUSD(
        address account,
        address lendingToken
    )
        external
        view
        returns (
            uint256 loanBody,
            uint256 accrual,
            uint256 estimatedOutstandingInUSD
        );

    /**
     * @dev Returns the total outstanding amount of a user's borrow position for a specific lending token
     * @param account The address of the user's borrow position
     * @param lendingToken The address of the lending token
     * @return total outstanding amount of the user's borrow position
     */
    function outstanding(
        address account,
        address lendingToken
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IPriceProviderAggregator.sol";
import "../interfaces/IBLendingToken.sol";
import "../interfaces/V3/IPrimaryIndexTokenV3.sol";

contract PrimaryIndexTokenModeratorV3 is Initializable, AccessControlUpgradeable
{
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    IPrimaryIndexTokenV3 public primaryIndexToken;

    event AddPrjToken(address indexed tokenPrj, string name, string symbol);
    event RemoveProjectToken(address indexed tokenPrj);
    event SetPausedProjectToken(address _projectToken, bool _isDepositPaused, bool _isWithdrawPaused);

    event AddLendingToken(address indexed lendingToken, string name, string symbol);
    event RemoveLendingToken(address indexed lendingToken);
    event SetPausedLendingToken(address _lendingToken, bool _isPaused);
    event SetBorrowLimitPerLendingAsset(address lendingToken, uint256 _borrowLimit);

    event LoanToValueRatioSet(address indexed tokenPrj, uint8 lvrNumerator, uint8 lvrDenominator);

    event GrandModerator(address newModerator);
    event RevokeModerator(address moderator); 

    event SetPrimaryIndexTokenLeverage(address newPrimaryIndexTokenLeverage);
    event SetPriceOracle(address newOracle);

    event AddRelatedContracts(address newRelatedContract);
    event RemoveRelatedContracts(address relatedContract);
    event LendingTokenLoanToValueRatioSet(address indexed lendingToken, uint8 lvrNumerator, uint8 lvrDenominator);

    /** 
     * @dev Initializes the contract by setting up the default admin role, the moderator role, and the primary index token. 
     * @param pit The address of the primary index token.
     */
    function initialize(address pit) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, msg.sender);
        primaryIndexToken = IPrimaryIndexTokenV3(pit);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the Admin");
        _;
    }

    modifier onlyModerator() {
        require(hasRole(MODERATOR_ROLE, msg.sender), "Caller is not the Moderator");
        _;
    }

    modifier isProjectTokenListed(address _projectToken) {
        require(primaryIndexToken.projectTokenInfo(_projectToken).isListed, "PIT: project token is not listed");
        _;
    }

    modifier isLendingTokenListed(address _lendingToken) {
        require(primaryIndexToken.lendingTokenInfo(_lendingToken).isListed, "PIT: lending token is not listed");
        _;
    }

    //************* ADMIN FUNCTIONS ********************************

    /**
     * @dev Grants the moderator role to a new address. 
     * @param newModerator The address of the new moderator.
     */
    function grandModerator(address newModerator) public onlyAdmin {
        require(newModerator != address(0), "PIT: invalid address");
        grantRole(MODERATOR_ROLE, newModerator);
        emit GrandModerator(newModerator);
    }

    /** 
     * @dev Revokes the moderator role from an address. 
     * @param moderator The address of the moderator to be revoked.
     */
    function revokeModerator(address moderator) public onlyAdmin {
        require(moderator != address(0), "PIT: invalid address");
        revokeRole(MODERATOR_ROLE, moderator);
        emit RevokeModerator(moderator);
    }

    /** 
     * @dev Transfers the admin role to a new address. 
     * @param newAdmin The address of the new admin.
     */
    function transferAdminRole(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "PIT: invalid newAdmin");
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /** 
     * @dev Transfers the admin role for the primary index token to a new address. 
     * @param currentAdmin The address of the current admin. 
     * @param newAdmin The address of the new admin.
     */
    function transferAdminRoleForPIT(address currentAdmin, address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "PIT: invalid newAdmin");
        primaryIndexToken.grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        primaryIndexToken.revokeRole(DEFAULT_ADMIN_ROLE, currentAdmin);
    }

    /** 
     * @dev Adds a new project token to the primary index token. 
     * @param _projectToken The address of the project token. 
     * @param _loanToValueRatioNumerator The numerator of the loan-to-value ratio. 
     * @param _loanToValueRatioDenominator The denominator of the loan-to-value ratio. 
     */
    function addProjectToken(
        address _projectToken,
        uint8 _loanToValueRatioNumerator,
        uint8 _loanToValueRatioDenominator
    ) public onlyAdmin {
        require(_projectToken != address(0), "invalid _projectToken");

        string memory projectTokenName = ERC20Upgradeable(_projectToken).name();
        string memory projectTokenSymbol = ERC20Upgradeable(_projectToken).symbol();
        emit AddPrjToken(_projectToken, projectTokenName, projectTokenSymbol);
        
        setProjectTokenInfo(
            _projectToken,
            false,
            false,
            _loanToValueRatioNumerator, 
            _loanToValueRatioDenominator
        );
    }

    /** 
     * @dev Removes a project token from the primary index token. 
     * @param _projectTokenId The ID of the project token to be removed.
     */
    function removeProjectToken(
        uint256 _projectTokenId
    ) public onlyAdmin isProjectTokenListed(primaryIndexToken.projectTokens(_projectTokenId)) {
        address projectToken = primaryIndexToken.projectTokens(_projectTokenId);
        require(primaryIndexToken.totalDepositedProjectPerToken(projectToken) == 0, "PIT: projectToken amount exist on PIT");
        primaryIndexToken.removeProjectToken(_projectTokenId, projectToken);
        emit RemoveProjectToken(projectToken);
    }

    /** 
     * @dev Adds a new lending token to the primary index token. 
     * @param _lendingToken The address of the lending token. 
     * @param _bLendingToken The address of the corresponding bLending token. 
     * @param _isPaused The initial pause status for the lending token
     * @param _loanToValueRatioNumerator The numerator of the loan-to-value ratio.
     * @param _loanToValueRatioDenominator The denominator of the loan-to-value ratio.
     */
    function addLendingToken(
        address _lendingToken, 
        address _bLendingToken,
        bool _isPaused,
        uint8 _loanToValueRatioNumerator,
        uint8 _loanToValueRatioDenominator
    ) public onlyAdmin {
        require(_lendingToken != address(0) && _bLendingToken != address(0), "PIT: invalid address");

        string memory lendingTokenName = ERC20Upgradeable(_lendingToken).name();
        string memory lendingTokenSymbol = ERC20Upgradeable(_lendingToken).symbol();
        emit AddLendingToken(_lendingToken, lendingTokenName, lendingTokenSymbol);

        setLendingTokenInfo(
            _lendingToken, 
            _bLendingToken, 
            _isPaused,
            _loanToValueRatioNumerator,
            _loanToValueRatioDenominator
        );
    }

    /** 
     * @dev Removes a lending token from the primary index token. 
     * @param _lendingTokenId The ID of the lending token to be removed.
     */
    function removeLendingToken(
        uint256 _lendingTokenId
    ) public onlyAdmin isLendingTokenListed(primaryIndexToken.lendingTokens(_lendingTokenId)) {
        address lendingToken = primaryIndexToken.lendingTokens(_lendingTokenId);

        for(uint256 i = 0; i < primaryIndexToken.projectTokensLength(); i++) {
            require(primaryIndexToken.totalBorrow(primaryIndexToken.projectTokens(i),lendingToken) == 0, "PIT: exist borrow of lendingToken");
        }
        primaryIndexToken.removeLendingToken(_lendingTokenId, lendingToken);
        emit RemoveLendingToken(lendingToken);
    }

    /** 
     * @dev Sets the leverage of the primary index token. 
     * @param newPrimaryIndexTokenLeverage The new leverage value.
     */
    function setPrimaryIndexTokenLeverage(address newPrimaryIndexTokenLeverage) public onlyAdmin {
        require(newPrimaryIndexTokenLeverage != address(0), "PIT: invalid address");
        primaryIndexToken.setPrimaryIndexTokenLeverage(newPrimaryIndexTokenLeverage);
        emit SetPrimaryIndexTokenLeverage(newPrimaryIndexTokenLeverage);
    }

    /** 
     * @dev Sets the price oracle for the primary index token. 
     * @param newOracle The address of the new price oracle.
     */
    function setPriceOracle(address newOracle) public onlyAdmin {
        require(newOracle != address(0), "PIT: invalid address");
        primaryIndexToken.setPriceOracle(newOracle);
        emit SetPriceOracle(newOracle);
    }

    /** 
     * @dev Adds an address to the list of related contracts.
     * @param newRelatedContract The address of the new related contract to be added.
     */
    function addRelatedContracts(address newRelatedContract) public onlyAdmin {
        require(newRelatedContract != address(0), "PIT: invalid address");
        primaryIndexToken.setRelatedContract(newRelatedContract, true);
        emit AddRelatedContracts(newRelatedContract);
    }

    /** 
     * @dev Removes an address from the list of related contracts. 
     * @param relatedContract The address of the related contract to be removed.
     */
    function removeRelatedContracts(address relatedContract) public onlyAdmin {
        require(relatedContract != address(0), "PIT: invalid address");
        primaryIndexToken.setRelatedContract(relatedContract, false);
        emit RemoveRelatedContracts(relatedContract);
    }

    //************* MODERATOR FUNCTIONS ********************************

    /** 
     * @dev Sets the parameters for a project token 
     * @param _projectToken The address of the project token
     * @param _isDepositPaused The new pause status for deposit 
     * @param _isWithdrawPaused The new pause status for withdrawal
     * @param _loanToValueRatioNumerator The numerator of the loan-to-value ratio for the project token 
     * @param _loanToValueRatioDenominator The denominator of the loan-to-value ratio for the project token 
     */
    function setProjectTokenInfo(
        address _projectToken,
        bool _isDepositPaused,
        bool _isWithdrawPaused,
        uint8 _loanToValueRatioNumerator,
        uint8 _loanToValueRatioDenominator
    ) public onlyModerator {
        require(_loanToValueRatioNumerator <= _loanToValueRatioDenominator, "invalid loanToValueRatio");
        
        primaryIndexToken.setProjectTokenInfo(
            _projectToken,
            _isDepositPaused,
            _isWithdrawPaused,
            _loanToValueRatioNumerator, 
            _loanToValueRatioDenominator
        );
        emit SetPausedProjectToken(_projectToken, _isDepositPaused, _isWithdrawPaused);
        emit LoanToValueRatioSet(_projectToken, _loanToValueRatioNumerator, _loanToValueRatioDenominator);
    }

    /** 
     * @dev Sets the pause status for deposit and withdrawal of a project token 
     * @param _projectToken The address of the project token 
     * @param _isDepositPaused The new pause status for deposit 
     * @param _isWithdrawPaused The new pause status for withdrawal
     */
    function setPausedProjectToken(
        address _projectToken, 
        bool _isDepositPaused, 
        bool _isWithdrawPaused
    ) public onlyModerator isProjectTokenListed(_projectToken) {
        primaryIndexToken.setPausedProjectToken(_projectToken, _isDepositPaused, _isWithdrawPaused);
        emit SetPausedProjectToken(_projectToken, _isDepositPaused, _isWithdrawPaused);
    } 

    /** 
     * @dev Sets the parameters for a lending token 
     * @param _lendingToken The address of the lending token 
     * @param _bLendingToken The address of the corresponding bLending token 
     * @param _isPaused The new pause status for the lending token
     * @param _loanToValueRatioNumerator The numerator of the loan-to-value ratio for the lending token
     * @param _loanToValueRatioDenominator The denominator of the loan-to-value ratio for the lending token
     */
    function setLendingTokenInfo(
        address _lendingToken, 
        address _bLendingToken,
        bool _isPaused,
        uint8 _loanToValueRatioNumerator,
        uint8 _loanToValueRatioDenominator
    ) public onlyModerator {
        primaryIndexToken.setLendingTokenInfo(_lendingToken, _bLendingToken, _isPaused, _loanToValueRatioNumerator, _loanToValueRatioDenominator);
        require(IBLendingToken(_bLendingToken).underlying() == _lendingToken, "PIT: underlyingOfbLendingToken!=lendingToken");
        emit SetPausedLendingToken(_lendingToken, _isPaused);
        emit LendingTokenLoanToValueRatioSet(_lendingToken, _loanToValueRatioNumerator, _loanToValueRatioDenominator);
    }

    /** 
     * @dev Sets the pause status for a lending token 
     * @param _lendingToken The address of the lending token 
     * @param _isPaused The new pause status for the lending token
     */
    function setPausedLendingToken(address _lendingToken, bool _isPaused) public onlyModerator isLendingTokenListed(_lendingToken) {
        primaryIndexToken.setPausedLendingToken(_lendingToken, _isPaused);
        emit SetPausedLendingToken(_lendingToken, _isPaused);
    }

    /**
     * @dev Sets the borrow limit per lending asset for a given lending token.
     * @param lendingToken The lending token for which to set the borrow limit.
     * @param _borrowLimit The new borrow limit.
     */
    function setBorrowLimitPerLendingAsset(address lendingToken, uint256 _borrowLimit) public onlyModerator isLendingTokenListed(lendingToken) {
        require(_borrowLimit > 0, "PIT: borrowLimit=0");
        require(lendingToken != address(0), "PIT: invalid address");
        primaryIndexToken.setBorrowLimitPerLendingAsset(lendingToken, _borrowLimit);
        emit SetBorrowLimitPerLendingAsset(lendingToken, _borrowLimit);
    }
}