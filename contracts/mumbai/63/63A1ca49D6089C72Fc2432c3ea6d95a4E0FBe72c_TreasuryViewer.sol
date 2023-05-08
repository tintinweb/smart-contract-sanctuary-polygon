// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/// @title  Interface for Auth contract, which is a part of gNFT token
/// @notice Authorization model is based on AccessControl and Pausable contracts from OpenZeppelin:
///         (https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl) and
///         (https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
///         Blacklisting implemented with BLACKLISTED_ROLE, managed by MANAGER_ROLE
interface IAuth {
    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice Revert reason for protected functions being called by blacklisted address
    error BlacklistedUser(address account);

    /// @notice             Check for admin role
    /// @param user         User to check for role bearing
    /// @return             True if user has the DEFAULT_ADMIN_ROLE role
    function isAdmin(address user) external view returns (bool);

    /// @notice             Check for not being in blacklist
    /// @param user         User to check for
    /// @return             True if user is not blacklisted
    function isValidUser(address user) external view returns (bool);

    /// @notice             Control function of OpenZeppelin's Pausable contract
    ///                     Restricted to PAUSER_ROLE bearers only
    /// @param newState     New boolean status for affected whenPaused/whenNotPaused functions
    function setPause(bool newState) external;
}

// SPDX-License-Identifier: UNLICENSED

import "./ICToken.sol";

pragma solidity ^0.8.4;

/// @title  Partial interface for Tonpound Comptroller contract
/// @notice Based on Comptroller from Compound Finance with different governance model
///         (https://docs.compound.finance/v2/comptroller/)
///         Modified Comptroller stores gNFT and Treasury addresses
///         Unmodified descriptions are copied from Compound Finance GitHub repo:
///         (https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/Comptroller.sol)
interface IComptroller {
    /// @notice         Returns whether the given account is entered in the given asset
    /// @param account  The address of the account to check
    /// @param market   The market(cToken) to check
    /// @return         True if the account is in the asset, otherwise false
    function checkMembership(address account, address market) external view returns (bool);

    /// @notice         Claim all rewards accrued by the holders
    /// @param holders  The addresses to claim for
    /// @param markets  The list of markets to claim in
    /// @param bor      Whether or not to claim rewards earned by borrowing
    /// @param sup      Whether or not to claim rewards earned by supplying
    function claimComp(
        address[] memory holders,
        address[] memory markets,
        bool bor,
        bool sup
    ) external;

    /// @notice         Returns rewards accrued but not yet transferred to the user
    /// @param account  User address to get accrued rewards for
    /// @return         Value stored in compAccrued[account] mapping
    function compAccrued(address account) external view returns (uint256);

    /// @notice         Add assets to be included in account liquidity calculation
    /// @param markets  The list of addresses of the markets to be enabled
    /// @return         Success indicator for whether each corresponding market was entered
    function enterMarkets(address[] memory markets) external returns (uint256[] memory);

    /// @notice             Determine the current account liquidity wrt collateral requirements
    /// @return err         (possible error code (semi-opaque)
    ///         liquidity   account liquidity in excess of collateral requirements
    ///         shortfall   account shortfall below collateral requirements)
    function getAccountLiquidity(
        address account
    ) external view returns (uint256 err, uint256 liquidity, uint256 shortfall);

    /// @notice Return all of the markets
    /// @dev    The automatic getter may be used to access an individual market.
    /// @return The list of market addresses
    function getAllMarkets() external view returns (address[] memory);

    /// @notice         Returns the assets an account has entered
    /// @param  account The address of the account to pull assets for
    /// @return         A dynamic list with the assets the account has entered
    function getAssetsIn(address account) external view returns (address[] memory);

    /// @notice Return the address of the TPI token
    /// @return The address of TPI
    function getCompAddress() external view returns (address);

    /// @notice Return the address of the governance gNFT token
    /// @return The address of gNFT
    function gNFT() external view returns (address);

    /// @notice View function to read 'markets' mapping separately
    /// @return Market structure without nested 'accountMembership'
    function markets(address market) external view returns (Market calldata);

    /// @notice Return the address of the system Oracle
    /// @return The address of Oracle
    function oracle() external view returns (address);

    /// @notice Return the address of the Treasury
    /// @return The address of Treasury
    function treasury() external view returns (address);

    struct Market {
        bool isListed;
        uint256 collateralFactorMantissa;
        bool isComped;
    }
}

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

pragma solidity ^0.8.4;

/// @title  Partial interface for Tonpound cToken market
/// @notice Extension of IERC20 standard interface from OpenZeppelin
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20)
interface ICToken is IERC20MetadataUpgradeable {
    /**
     * @notice Accrues interest and reduces reserves by transferring to admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves() external returns (uint256);

    /**
     * @notice Block number that interest was last accrued at
     */
    function accrualBlockNumber() external view returns(uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    function comptroller() external returns (address);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Get cash balance of this cToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint256);

    /**
     * @notice Model which tells what the current interest rate should be
     */
    function interestRateModel() external view returns (address);

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    function reserveFactorMantissa() external view returns (uint256);

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    function totalBorrows() external view returns (uint256);

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    function totalReserves() external view returns (uint256);

    /**
     * @notice Underlying asset for this CToken
     */
    function underlying() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ISegmentManagement.sol";

/// @title  gNFT governance token for Tonpound protocol
/// @notice Built on ERC721Votes extension from OpenZeppelin Upgradeable library
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721Votes)
///         Supports Permit approvals (see IERC721Permit.sol) and Multicall
///         (https://docs.openzeppelin.com/contracts/4.x/api/utils#Multicall)
interface IgNFT {
    /// @notice Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice Revert reason for protected functions being called by blacklisted address
    error BlacklistedUser(address account);

    /// @notice Revert reason for accessing protected functions during pause
    error Paused();

    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice              Emitted during minting
    /// @param tokenId       tokenId of minted token
    /// @param data          Metadata of minted token
    event MintData(uint256 tokenId, TokenData data);

    /// @notice              Emitted during slot0 of metadata updating
    /// @param tokenId       tokenId of updated token
    /// @param data          New Slot0 of metadata of updated token
    event UpdatedTokenDataSlot0(uint256 tokenId, Slot0 data);

    /// @notice              Emitted during slot1 of metadata updating
    /// @param tokenId       tokenId of updated token
    /// @param data          New Slot1 of metadata of updated token
    event UpdatedTokenDataSlot1(uint256 tokenId, Slot1 data);

    /// @notice              View method to read SegmentManagement contract address
    /// @return              Address of SegmentManagement contract
    function SEGMENT_MANAGEMENT() external view returns (ISegmentManagement);

    /// @notice               View method to get total vote weight of minted tokens,
    ///                       only gNFTs with fully activated segments participates in the voting
    /// @return               Value of Votes._getTotalSupply(), i.e. latest total checkpoints
    function getTotalVotePower() external view returns (uint256);

    /// @notice               View method to read 'tokenDataById' mapping of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId]' of IgNFT.TokenData type
    function getTokenData(uint256 tokenId) external view returns (TokenData memory);

    /// @notice               View method to read first slot of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId].slot0' of IgNFT.Slot0 type
    function getTokenSlot0(uint256 tokenId) external view returns (Slot0 memory);

    /// @notice               View method to read second slot of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId].slot1' of IgNFT.Slot1 type
    function getTokenSlot1(uint256 tokenId) external view returns (Slot1 memory);

    /// @notice               Minting new gNFT token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param to             Address of recipient
    /// @param data           Parameters of new token to be minted
    function mint(address to, TokenData memory data) external;

    /// @notice               Update IgNFT.Slot0 parameters of IgNFT.TokenData of a token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param tokenId        Token to be updated
    /// @param data           Slot0 structure to update existed
    function updateTokenDataSlot0(uint256 tokenId, Slot0 memory data) external;

    /// @notice               Update IgNFT.Slot1 parameters of IgNFT.TokenData of a token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param tokenId        Token to be updated
    /// @param data           Slot1 structure to update existed
    function updateTokenDataSlot1(uint256 tokenId, Slot1 memory data) external;

    struct TokenData {
        Slot0 slot0;
        Slot1 slot1;
    }

    struct Slot0 {
        TokenType tokenType;
        uint8 activeSegment;
        uint8 voteWeight;
        uint8 rewardWeight;
        bool usedForMint;
        uint48 completionTimestamp;
        address lockedMarket;
    }

    struct Slot1 {
        uint256 lockedVaultShares;
    }

    enum TokenType {
        Topaz,
        Emerald,
        Diamond
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
interface IInterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    function isInterestRateModel() external view returns (bool);

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) external view returns (uint256);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint256 cash, uint256 borrows, uint256 reserves, uint256 reserveFactorMantissa) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/// @title  Partial interface for Oracle contract
/// @notice Based on PriceOracle from Compound Finance
///         (https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/PriceOracle.sol)
interface IOracle {
    /// @notice         Get the underlying price of a market(cToken) asset
    /// @param market   The market to get the underlying price of
    /// @return         The underlying asset price mantissa (scaled by 1e18).
    ///                 Zero means the price is unavailable.
    function getUnderlyingPrice(address market) external view returns (uint256);

    /// @notice         Evaluates input amount according to stored price, accrues interest
    /// @param cToken   Market to evaluate
    /// @param amount   Amount of tokens to evaluate according to 'reverse' order
    /// @param reverse  Order of evaluation
    /// @return         Depending on 'reverse' order:
    ///                     false - return USD amount equal to 'amount' of 'cToken'
    ///                     true - return cTokens equal to 'amount' of USD
    function getEvaluation(address cToken, uint256 amount, bool reverse) external returns (uint256);

    /// @notice         Evaluates input amount according to stored price, doesn't accrue interest
    /// @param cToken   Market to evaluate
    /// @param amount   Amount of tokens to evaluate according to 'reverse' order
    /// @param reverse  Order of evaluation
    /// @return         Depending on 'reverse' order:
    ///                     false - return USD amount equal to 'amount' of 'cToken'
    ///                     true - return cTokens equal to 'amount' of USD
    function getEvaluationStored(
        address cToken,
        uint256 amount,
        bool reverse
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./IgNFT.sol";
import "./IComptroller.sol";
import "./ITPIToken.sol";
import "./ITreasury.sol";
import "./IOracle.sol";

/// @title  Segment management contract for gNFT governance token for Tonpound protocol
interface ISegmentManagement {
    /// @notice Revert reason for activating segments for a fully activated token
    error AlreadyFullyActivated();

    /// @notice Revert reason for repeating discount activation
    error DiscountUsed();

    /// @notice Revert reason for minting over the max segment number
    error ExceedingMaxSegments();

    /// @notice Revert reason for minting without liquidity in Tonpound protocol
    error FailedLiquidityCheck();

    /// @notice Revert reason for minting token with a market without membership
    error InvalidMarket();

    /// @notice Revert reason for activating segment with invalid Merkle proof for given account
    error InvalidProof();

    /// @notice Revert reason for activating more segments than available
    error InvalidSegmentsNumber();

    /// @notice Revert reason for operating tokens without ownership
    error InvalidTokenOwnership(uint256 tokenId);

    /// @notice Revert reason for activating last segment without specified liquidity for lock
    error MarketForLockNotSpecified();

    /// @notice Revert reason for minting high tier gNFT without providing proof of ownership
    error MintingRequirementsNotMet();

    /// @notice Revert reason for zero returned price from Oracle contract
    error OracleFailed();

    /// @notice Revert reason for trying to lock already locked token
    error TokenAlreadyLocked();

    /// @notice              Emitted during NFT segments activation
    /// @param tokenId       tokenId of activated token
    /// @param segment       New active segment after performed activation
    event ActivatedSegments(uint256 indexed tokenId, uint8 segment);

    /// @notice              Emitted after the last segment of gNFT token is activated
    /// @param tokenId       tokenId of completed token
    /// @param user          Address of the user who completed the token
    event TokenCompleted(uint256 indexed tokenId, address indexed user);

    /// @notice              Emitted when whitelisted users activate their segments with discount
    /// @param leaf          Leaf of Merkle tree being used in activation
    /// @param root          Root of Merkle tree being used in activation
    event Discounted(bytes32 leaf, bytes32 root);

    /// @notice             Emitted to notify about airdrop Merkle root change
    /// @param oldRoot      Old root
    /// @param newRoot      New updated root to be used after this tx
    event AirdropMerkleRootChanged(bytes32 oldRoot, bytes32 newRoot);

    /// @notice              View method to read Tonpound Comptroller address
    /// @return              Address of Tonpound Comptroller contract
    function TONPOUND_COMPTROLLER() external view returns (IComptroller);

    /// @notice View method to read gNFT
    /// @return Address of gNFT contract
    function gNFT() external view returns (IgNFT);

    /// @notice View method to read Tonpound TPI token
    /// @return Address of TPI token contract
    function TPI() external view returns (ITPIToken);

    /// @notice               View method to get price in TPI tokens to activate segments of gNFT token
    /// @param tokenId        tokenId of the token to activate segments of
    /// @param segmentsToOpen Number of segments to activate, fails if this number exceeds available segments
    /// @param discounted     Whether the user is eligible for activation discount
    /// @return               Price in TPI tokens to be burned from caller to activate specified number of segments
    function getActivationPrice(
        uint256 tokenId,
        uint8 segmentsToOpen,
        bool discounted
    ) external view returns (uint256);

    /// @notice              View method to get amount of liquidity to be provided for lock in order to
    ///                      complete last segment and make gNFT eligible for reward distribution in Treasury
    /// @param market        Tonpound Comptroller market (cToken) to be locked
    /// @param tokenType     Type of token to quote lock for
    /// @return              Amount of specified market tokens to be provided for lock
    function quoteLiquidityForLock(
        address market,
        IgNFT.TokenType tokenType
    ) external view returns (uint256);

    /// @notice              Minting new gNFT token with zero active segments and no voting power
    ///                      Minter must have total assets in Tonpound protocol over the threshold nominated in USD
    /// @param markets       User provided markets of Tonpound Comptroller to be checked for liquidity
    function mint(address[] memory markets) external;

    /// @notice              Minting new gNFT token of given type with zero active segments and no voting power
    ///                      Minter must have assets in given markets of Tonpound protocol over the threshold in USD
    ///                      Minter must own number of fully activated lower tier gNFTs to mint Emerald or Diamond
    /// @param markets       User provided markets of Tonpound Comptroller to be checked for liquidity
    /// @param tokenType     Token type to mint: Topaz, Emerald, or Diamond
    /// @param proofIds      List of tokenIds to be checked for ownership, activation, and type
    function mint(
        address[] memory markets,
        IgNFT.TokenType tokenType,
        uint256[] calldata proofIds
    ) external;

    /// @notice              Activating number of segments of given gNFT token
    ///                      Caller must be the owner, token may be completed with this function if
    ///                      caller provides enough liquidity for lock in specified Tonpound 'market'
    /// @param tokenId       tokenId to be activated for number of segments
    /// @param segments      Number of segments to be activated, must not exceed available segments of tokenId
    /// @param market        Optional address of Tonpound market to lock liquidity in order to complete gNFT
    function activateSegments(uint256 tokenId, uint8 segments, address market) external;

    /// @notice              Activating 1 segment of given gNFT token
    ///                      Caller must provide valid Merkle proof, token may be completed with this function if
    ///                      'account' provides enough liquidity for lock in specified Tonpound 'market'
    /// @param tokenId       tokenId to be activated for a single segment
    /// @param account       Address of whitelisted account, which is included in leaf of Merkle tree
    /// @param nonce         Nonce parameter included in leaf of Merkle tree
    /// @param proof         bytes32[] array of Merkle tree proof for whitelisted account
    /// @param market        Optional address of Tonpound market to lock liquidity in order to complete gNFT
    function activateSegmentWithProof(
        uint256 tokenId,
        address account,
        uint256 nonce,
        bytes32[] memory proof,
        address market
    ) external;

    /// @notice              Unlocking liquidity of a fully activated gNFT
    ///                      Caller must be the owner. If function is called before start of reward claiming,
    ///                      the given tokenId is de-registered in Treasury contract and stops acquiring rewards
    ///                      Any rewards acquired before unlocking will be available once claiming starts
    /// @param tokenId       tokenId to unlock liquidity for
    function unlockLiquidity(uint256 tokenId) external;

    /// @notice              Locking liquidity of a fully activated gNFT (reverting result of unlockLiquidity())
    ///                      Caller must be the owner. If function is called before start of reward claiming,
    ///                      the given tokenId is registered in Treasury contract and starts acquiring rewards
    ///                      Any rewards acquired before remains accounted and will be available once claiming starts
    /// @param tokenId       tokenId to lock liquidity for
    /// @param market        Address of Tonpound market to lock liquidity in
    function lockLiquidity(uint256 tokenId, address market) external;

    /// @notice             Updating Merkle root for whitelisting airdropped accounts
    ///                     Restricted to MANAGER_ROLE bearers only
    /// @param root         New root of Merkle tree of whitelisted addresses
    function setMerkleRoot(bytes32 root) external;
}

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

pragma solidity ^0.8.4;

/// @title  Partial interface for Tonpound TPI token
/// @notice Extension of IERC20 standard interface from OpenZeppelin
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20)
interface ITPIToken is IERC20Upgradeable {
    /// @notice View function to get current active circulating supply,
    ///         used to calculate price of gNFT segment activation
    /// @return Total supply without specific TPI storing address, e.g. vesting
    function getCirculatingSupply() external view returns (uint256);

    /// @notice         Function to be used for gNFT segment activation
    /// @param account  Address, whose token to be burned
    /// @param amount   Amount to be burned
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

import "./IComptroller.sol";
import "./IgNFT.sol";
import "./IAuth.sol";

pragma solidity ^0.8.4;

/// @title  Interface for Tonpound Treasury contract, which is a part of gNFT token
/// @notice Authorization model is based on AccessControl and Pausable contracts from OpenZeppelin:
///         (https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl) and
///         (https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
///         Blacklisting implemented with BLACKLISTED_ROLE, managed by MANAGER_ROLE
interface ITreasury {
    /// @notice Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice Revert reason claiming rewards before start of claiming period
    error ClaimingNotStarted();

    /// @notice Revert reason claiming unregistered reward token
    error InvalidRewardToken();

    /// @notice Revert reason for distributing rewards in unsupported reward token
    error InvalidMarket();

    /// @notice Revert reason for setting too high parameter value
    error InvalidParameter();

    /// @notice Revert reason for claiming reward for not-owned gNFT token
    error InvalidTokenOwnership();

    /// @notice Revert reason for accessing protected functions during pause
    error Paused();

    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice Emitted in governance function when reserveBPS variable is updated
    event ReserveFactorUpdated(uint256 oldValue, uint256 newValue);

    /// @notice Emitted in governance function when reserveFund variable is updated
    event ReserveFundUpdated(address oldValue, address newValue);

    /// @notice             View method to read 'fixedRewardPayments' mapping of
    ///                     solid reward payments for tokenId
    /// @param rewardToken  Address of reward token to read mapping for
    /// @param tokenId      gNFT tokenId to read mapping for
    /// @return             Stored bool value of 'fixedRewardPayments[rewardToken][tokenId], 
    ///                     that can be claimed regardless of tokenId registration status
    function fixedRewardPayments(address rewardToken, uint256 tokenId) external view returns (uint256);

    /// @notice             View method to read all supported reward tokens
    /// @return             Array of addresses of registered reward tokens
    function getRewardTokens() external view returns (address[] memory);

    /// @notice             View method to read number of supported reward tokens
    /// @return             Number of registered reward tokens
    function getRewardTokensLength() external view returns (uint256);

    /// @notice             View method to read a single reward token address
    /// @param index        Index of reward token in array to return
    /// @return             Address of reward token at given index in array
    function getRewardTokensAtIndex(uint256 index) external view returns (address);

    /// @notice             View method to read 'lastClaimForTokenId' mapping
    ///                     storing 'rewardPerShare' parameter for 'tokenId'
    ///                     from time of registration or last claiming event
    /// @param rewardToken  Address of reward token to read mapping for
    /// @param tokenId      gNFT tokenId to read mapping for
    /// @return             Stored value of 'lastClaimForTokenId[rewardToken][tokenId]',
    ///                     last claim value of reward per share multiplied by REWARD_PER_SHARE_MULTIPLIER = 1e12
    function lastClaimForTokenId(
        address rewardToken,
        uint256 tokenId
    ) external view returns (uint256);

    /// @notice             View method to get pending rewards for given
    ///                     reward token and gNFT token, contains fixed part for
    ///                     de-registered tokens and calculated part of distributed rewards
    /// @param rewardToken  Address of reward token to calculate pending rewards
    /// @param tokenId      gNFT tokenId to calculate pending rewards for
    /// @return             Value of rewards in rewardToken that would be claimed if claim is available
    function pendingReward(address rewardToken, uint256 tokenId) external view returns (uint256);

    /// @notice             View method to read 'registeredTokenIds' mapping of
    ///                     tracked registered gNFT tokens
    /// @param tokenId      tokenId of gNFT token to read
    /// @return             Stored bool value of 'registeredTokenIds[tokenId]', true if registered
    function registeredTokenIds(uint256 tokenId) external view returns (bool);

    /// @notice             View method to read reserve factor
    /// @return             Fraction (in bps) of rewards going to reserves, can be set to 0
    function reserveBPS() external view returns (uint256);

    /// @notice             View method to read address of reserve fund
    /// @return             Address to collect reserved part of rewards, can be set to 0
    function reserveFund() external view returns (address);

    /// @notice             View method to read 'rewardPerShare' mapping of
    ///                     tracked balances of Treasury contract to properly distribute rewards
    /// @param rewardToken  Address of reward token to read mapping for
    /// @return             Stored value of 'rewardPerShare[rewardToken]',
    ///                     reward per share multiplied by REWARD_PER_SHARE_MULTIPLIER = 1e12
    function rewardPerShare(address rewardToken) external view returns (uint256);

    /// @notice             View method to read 'rewardBalance' mapping of distributed rewards
    ///                     in specified rewardToken stored to properly account fresh rewards
    /// @param rewardToken  Address of reward token to read mapping for
    /// @return             Stored value of 'rewardBalance[rewardToken]'
    function rewardBalance(address rewardToken) external view returns (uint256);

    /// @notice             View method to get the remaining time until start of claiming period
    /// @return             Seconds until claiming is available, zero if claiming has started
    function rewardsClaimRemaining() external view returns (uint256);

    /// @notice             View method to read Tonpound Comptroller address
    /// @return             Address of Tonpound Comptroller contract
    function TONPOUND_COMPTROLLER() external view returns (IComptroller);

    /// @notice             View method to read total weight of registered gNFT tokens,
    ///                     eligible for rewards distribution
    /// @return             Stored value of 'totalRegisteredWeight'
    function totalRegisteredWeight() external view returns (uint256);

    /// @notice             Register and distribute incoming rewards in form of all tokens
    ///                     supported by the Tonpound Comptroller contract
    ///                     Rewards must be re-distributed if there's no users to receive at the moment
    function distributeRewards() external;

    /// @notice             Register and distribute incoming rewards in form of underlying of 'market'
    ///                     Market address must be listed in the Tonpound Comptroller
    ///                     Rewards must be re-distributed if there's no users to receive at the moment
    /// @param market       Address of market cToken to try to distribute
    function distributeReward(address market) external;

    /// @notice             Claim all supported pending rewards for given gNFT token
    ///                     Claimable only after rewardsClaimRemaining() == 0 and
    ///                     only by the owner of given tokenId
    /// @param tokenId      gNFT tokenId to claim rewards for
    function claimRewards(uint256 tokenId) external;

    /// @notice             Claim pending rewards for given gNFT token in form of single 'rewardToken'
    ///                     Claimable only after rewardsClaimRemaining() == 0 and
    ///                     only by the owner of given tokenId
    /// @param tokenId      gNFT tokenId to claim rewards for
    /// @param rewardToken  Address of reward token to claim rewards in
    function claimReward(uint256 tokenId, address rewardToken) external;

    /// @notice             Register or de-register tokenId for rewards distribution
    ///                     De-registering saves acquired rewards in fixed part for claiming when available
    ///                     Restricted for gNFT contract only
    /// @param tokenId      gNFT tokenId to update registration status for
    /// @param state        New boolean registration status
    function registerTokenId(uint256 tokenId, bool state) external;

    /// @notice             Updating reserveBPS factor for reserve fund part of rewards
    /// @param newFactor    New value to be less than 5000
    function setReserveFactor(uint256 newFactor) external;

    /// @notice             Updating reserve fund address
    /// @param newFund      New address to receive future reserve rewards
    function setReserveFund(address newFund) external;

    struct RewardInfo {
        address market;
        uint256 amount;
    }
}

// SPDX-License-Identifier: UNLICENSED

import "./ITreasury.sol";
import "./IOracle.sol";
import "./IInterestRateModel.sol";

pragma solidity ^0.8.4;

/// @title  Interface for Tonpound TreasuryViewer contract, which is a part of Tonpound gNFT
/// @notice Implementing interest accruing view methods
interface ITreasuryViewer {
    /// @notice             View method to get pending gNFT token rewards without state-modifying accrueInterest()
    /// @param tokenId      gNFT tokenId to calculate rewards for
    /// @param tokenWeight  Reward weigh of gNFT tokenId, can be obtained from gNFT.slot0() structure
    /// @param market       Address of Tonpound market to check rewards from
    /// @param underlying   Underlying token of given 'market'
    /// @param treasury     Address of Tonpound Treasury
    /// @return             Amount of 'underlying' rewards to be pending after distribution to Treasury
    function rewardSingleMarket(
        uint256 tokenId,
        uint8 tokenWeight,
        address market,
        address underlying,
        ITreasury treasury
    ) external view returns (uint256);

    /// @notice             View method to get pending gNFT token rewards without state-modifying accrueInterest()
    ///                     Given markets are checked and evaluated (with fixed decimals) in USD using the given oracle
    /// @param tokenId      gNFT tokenId to calculate rewards for
    /// @param tokenWeight  Reward weigh of gNFT tokenId, can be obtained from gNFT.slot0() structure
    /// @param markets      Addresses of Tonpound markets to check rewards from
    /// @param underlying   Addresses of underlying tokens of given 'markets'
    /// @param decimals     Decimals of 'underlying' tokens
    /// @param oracle       Address of Tonpound Oracle
    /// @param treasury     Address of Tonpound Treasury
    /// @return             USD evaluation of 'underlying' rewards to be pending after distribution to Treasury 
    function rewardSingleIdWithEvaluation(
        uint256 tokenId,
        uint8 tokenWeight,
        address[] memory markets,
        address[] memory underlying,
        uint8[] memory decimals,
        IOracle oracle,
        ITreasury treasury
    ) external view returns (uint256);

    /// @notice             View method to get pending gNFT token rewards without state-modifying accrueInterest()
    ///                     Assumed to be used for tokens of the same owner
    /// @param tokenIds     Array of gNFT tokenIds to calculate rewards for
    /// @param treasury     Address of Tonpound Treasury
    /// @return             Array of sums of reward tokens to be pending after distribution to Treasury 
    function rewardMultipleIdsWithoutEvaluation(
        uint256[] calldata tokenIds,
        ITreasury treasury
    ) external view returns (uint256[] memory);

    /// @notice             View method to get pending gNFT token rewards without state-modifying accrueInterest()
    ///                     All active markets are checked and evaluated (with fixed decimals) in USD using the given oracle
    /// @param tokenIds     Array of gNFT tokenIds to calculate rewards for
    /// @param treasury     Address of Tonpound Treasury
    /// @return             Array of USD evaluations of 'underlying' rewards to be pending after distribution to Treasury 
    function rewardMultipleIdsWithEvaluation(
        uint256[] calldata tokenIds,
        ITreasury treasury
    ) external view returns (uint256[] memory);

    /// @notice             View method to get Treasury's total pending rewards without state-modifying accrueInterest()
    ///                     All active markets are checked and evaluated (with fixed decimals) in USD using the given oracle
    /// @param treasury     Address of Tonpound Treasury
    /// @return             USD evaluation of 'underlying' rewards ready to be distributed
    function totalRewardsWithEvaluation(ITreasury treasury) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

import "./interfaces/ITreasuryViewer.sol";

pragma solidity ^0.8.4;

contract TreasuryViewer is ITreasuryViewer {
    uint8 public constant decimals = 6;
    uint256 internal constant FACTOR_ORACLE = 10 ** (36 - decimals);
    uint256 internal constant FACTOR_TREASURY = 10 ** 12;
    uint256 internal constant FACTOR_BPS = 10 ** 4;

    function _accrueInterest(ICToken market) internal view returns (uint256) {
        uint256 reservesStored = market.totalReserves();
        uint256 blockNumberStored = market.accrualBlockNumber();
        if (block.number > blockNumberStored) {
            uint256 cashStored = market.getCash();
            uint256 borrowsStored = market.totalBorrows();
            uint256 reserveFactorMantissa = market.reserveFactorMantissa();

            IInterestRateModel interestRateModel = IInterestRateModel(market.interestRateModel());
            uint256 borrowRateMantissa = interestRateModel.getBorrowRate(
                cashStored,
                borrowsStored,
                reservesStored
            );

            uint256 blockDelta = block.number - blockNumberStored;
            uint256 simpleInterestFactor = borrowRateMantissa * blockDelta;
            uint256 interestAccumulated = (simpleInterestFactor * borrowsStored) / 1e18;
            reservesStored = reservesStored + (reserveFactorMantissa * interestAccumulated) / 1e18;
        }
        return reservesStored;
    }

    function _distributeRewards(
        address market,
        address underlying,
        ITreasury treasury
    ) internal view returns (uint256, uint256) {
        uint256 reserveBPSStored = treasury.reserveBPS();
        address reserveFundStored = treasury.reserveFund();
        uint256 rewardBalanceStored = treasury.rewardBalance(underlying);
        uint256 reservesStored = _accrueInterest(ICToken(market));
        uint256 rewards = reservesStored +
            ICToken(underlying).balanceOf(address(treasury)) -
            rewardBalanceStored;

        if (reserveFundStored != address(0) && reserveBPSStored > 0) {
            rewards = rewards - (rewards * reserveBPSStored) / FACTOR_BPS;
        }
        return (rewards, rewardBalanceStored);
    }

    /// @inheritdoc ITreasuryViewer
    function rewardSingleMarket(
        uint256 tokenId,
        uint8 tokenWeight,
        address market,
        address underlying,
        ITreasury treasury
    ) public view returns (uint256) {
        uint256 fixedPayment = treasury.fixedRewardPayments(underlying, tokenId);
        uint256 pendingPart;

        if (treasury.registeredTokenIds(tokenId)) {
            (uint256 rewards, ) = _distributeRewards(market, underlying, treasury);
            pendingPart = (tokenWeight *
                (treasury.rewardPerShare(underlying) +
                    (rewards * FACTOR_TREASURY) /
                    treasury.totalRegisteredWeight() -
                    treasury.lastClaimForTokenId(underlying, tokenId))) / FACTOR_TREASURY;
        }
        return fixedPayment + pendingPart;
    }

    /// @inheritdoc ITreasuryViewer
    function rewardSingleIdWithEvaluation(
        uint256 tokenId,
        uint8 tokenWeight,
        address[] memory markets,
        address[] memory underlying,
        uint8[] memory decimals,
        IOracle oracle,
        ITreasury treasury
    ) public view returns (uint256) {
        uint256 totalReward;
        for (uint256 i; i < markets.length; ) {
            uint256 rewardMarket = rewardSingleMarket(
                tokenId,
                tokenWeight,
                markets[i],
                underlying[i],
                treasury
            );
            totalReward += (oracle.getUnderlyingPrice(markets[i]) * rewardMarket) / FACTOR_ORACLE;
            unchecked {
                i++;
            }
        }
        return totalReward;
    }

    /// @inheritdoc ITreasuryViewer
    function rewardMultipleIdsWithoutEvaluation(
        uint256[] calldata tokenIds,
        ITreasury treasury
    ) external view returns (uint256[] memory) {
        address[] memory markets = treasury.TONPOUND_COMPTROLLER().getAllMarkets();
        address[] memory underlying = new address[](markets.length);
        uint256[] memory rewards = new uint256[](markets.length);
        for (uint256 i; i < markets.length; ) {
            underlying[i] = ICToken(markets[i]).underlying();
            unchecked {
                i++;
            }
        }

        IgNFT gNFT = IgNFT(treasury.TONPOUND_COMPTROLLER().gNFT());
        for (uint256 i; i < tokenIds.length; i++) {
            for (uint256 j; j < markets.length; j++) {
                rewards[j] += rewardSingleMarket(
                    tokenIds[i],
                    gNFT.getTokenSlot0(tokenIds[i]).rewardWeight,
                    markets[j],
                    underlying[j],
                    treasury
                );
            }
        }
        return rewards;
    }

    /// @inheritdoc ITreasuryViewer
    function rewardMultipleIdsWithEvaluation(
        uint256[] calldata tokenIds,
        ITreasury treasury
    ) external view returns (uint256[] memory) {
        address[] memory markets = treasury.TONPOUND_COMPTROLLER().getAllMarkets();
        address[] memory underlying = new address[](markets.length);
        uint8[] memory underlyingDecimals = new uint8[](markets.length);
        uint256[] memory rewards = new uint256[](tokenIds.length);
        for (uint256 i; i < markets.length; ) {
            underlying[i] = ICToken(markets[i]).underlying();
            underlyingDecimals[i] = ICToken(underlying[i]).decimals();
            unchecked {
                i++;
            }
        }

        IOracle oracle = IOracle(treasury.TONPOUND_COMPTROLLER().oracle());
        IgNFT gNFT = IgNFT(treasury.TONPOUND_COMPTROLLER().gNFT());
        for (uint256 i; i < tokenIds.length; i++) {
            rewards[i] = rewardSingleIdWithEvaluation(
                tokenIds[i],
                gNFT.getTokenSlot0(tokenIds[i]).rewardWeight,
                markets,
                underlying,
                underlyingDecimals,
                oracle,
                treasury
            );
        }
        return rewards;
    }

    /// @inheritdoc ITreasuryViewer
    function totalRewardsWithEvaluation(ITreasury treasury) external view returns (uint256) {
        address[] memory markets = treasury.TONPOUND_COMPTROLLER().getAllMarkets();
        IOracle oracle = IOracle(treasury.TONPOUND_COMPTROLLER().oracle());
        uint256 totalReward;
        for (uint256 i; i < markets.length; ) {
            address underlying = ICToken(markets[i]).underlying();
            uint8 underlyingDecimals = ICToken(underlying).decimals();
            (uint256 rewardFresh, uint256 rewardStored) = _distributeRewards(
                markets[i],
                underlying,
                treasury
            );
            uint256 price = oracle.getUnderlyingPrice(markets[i]);
            totalReward += ((rewardStored + rewardFresh) * price) / FACTOR_ORACLE;
            unchecked {
                i++;
            }
        }
        return totalReward;
    }
}