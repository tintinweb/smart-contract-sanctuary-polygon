//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/IHERC20.sol";

interface NFT20Factory {
  function nftToToken(address) external returns (address);
}

interface NFT20Pair {
  function nftAddress() external returns (address);
}

/**
 * @title Honey Finance Liquidator v1
 * @notice Execute liquidations for HERC20 IRM contracts
 * @author BowTiedPickle for Honey Labs
 */
contract Liquidator01 is IERC721Receiver, AccessControl {
  // ----- Protocol Parameters -----

  /// @notice Additional fraction of outstanding debt that will be incurred on clawback, scaled by 1e18
  uint256 public clawbackFeeMantissa = 2.5e17; // 25%

  /// @notice Clawback window allowable
  uint256 public clawbackWindow = 12 hours;

  // ----- Key external addresses -----

  /// @notice NFT20 pool factory
  NFT20Factory public niftyFactory;

  /// @notice UniswapV2 Router
  IUniswapV2Router02 public immutable swapRouter;

  /// @notice Honey Finance Treasury
  address public immutable treasury;

  // ----- State Variables -----

  /// @notice HToken to address of its underlying ERC20
  mapping(address => IERC20) public poolToUnderlyingToken;

  /// @notice HToken to address of its collateral ERC721
  mapping(address => IERC721) public poolToCollateralToken;

  /// @notice HToken to NFT20 pool for that collateral
  mapping(address => address) public poolToNiftyPair;

  /// @notice Maps ERC721 contracts to mapping of tokenIds to block number the token was received at
  mapping(IERC721 => mapping(uint256 => uint256)) public collectionToTokenToTimeReceived;

  // ----- Events -----

  event NewClawbackWindow(uint256 oldWindow, uint256 newWindow);
  event NewClawbackFee(uint256 oldFee, uint256 newFee);
  event NFTFactoryInitialized(address factory);
  event NFT20PairInitialized(address pair, address hToken);
  event HErc20Initialized(address hToken, address underlying, address collateral);
  event ClawbackExecuted(address hToken, address borrower, uint256 _couponNFTId, uint256 amount);
  event NFT20LiquidationExecuted(address pair, address hToken, uint256 _couponNFTId);

  // ----- Roles -----
  bytes32 public constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
  bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");
  bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

  constructor(
    IUniswapV2Router02 _swapRouter,
    address _admin,
    address _treasury
  ) {
    require(_admin != address(0), "Cannot be zero address");
    require(address(_swapRouter) != address(0), "Cannot be zero address");

    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    _grantRole(INITIALIZER_ROLE, _admin);
    _grantRole(LIQUIDATOR_ROLE, _admin);
    _grantRole(SWAPPER_ROLE, _admin);

    swapRouter = _swapRouter;
    treasury = _treasury;
  }

  // ----- Configuration Functions -----

  /**
   * @notice Initializes the NFT20Factory that will be queried
   * @dev May only be called once
   * @param _NFT20Factory address of NFT20 factory proxy contract
   * @return true on success
   */
  function initializeFactory(NFT20Factory _NFT20Factory) external onlyRole(INITIALIZER_ROLE) returns (bool) {
    require(address(niftyFactory) == address(0), "Factory already set");
    niftyFactory = _NFT20Factory;
    emit NFTFactoryInitialized(address(niftyFactory));
    return true;
  }

  /**
   * @notice Setup an NFT20 pair if one exists for the collateral asset underlying the given HToken
   * @dev Does not create an NFT20 pool if one does not exist.
   * @param hToken address of the target hToken.
   * @return true on success
   */
  function initializePair(IHERC20 hToken) external onlyRole(INITIALIZER_ROLE) returns (bool) {
    IERC721 collateralToken = hToken.collateralToken();

    // Check for existence of NFT20 pool
    address pair = niftyFactory.nftToToken(address(collateralToken));

    // If NFT20 pair exists, add it to mapping
    if (pair != address(0)) {
      // Sanity check
      if (NFT20Pair(pair).nftAddress() == address(collateralToken)) {
        poolToNiftyPair[address(hToken)] = pair;
        emit NFT20PairInitialized(pair, address(hToken));
        return true;
      }
    }

    return false;
  }

  /**
   * @notice Perform the setup to handle liquidations from the given HErc20
   * @param hToken address of the hToken to setup
   * @return true on success
   */
  function initializeHErc20(IHERC20 hToken) external onlyRole(INITIALIZER_ROLE) returns (bool) {
    //TODO: require(msg.sender == contractFactory or other WL);

    require(hToken.isHToken(), "Attempted initializing non-hToken");

    // Add underlyings to mapping
    IERC20 underlyingToken = hToken.underlyingToken();
    IERC721 collateralToken = hToken.collateralToken();
    poolToUnderlyingToken[address(hToken)] = underlyingToken;
    poolToCollateralToken[address(hToken)] = collateralToken;

    // Unlimited approve the underlying token of the hToken
    underlyingToken.approve(address(hToken), type(uint256).max);

    emit HErc20Initialized(address(hToken), address(underlyingToken), address(collateralToken));

    return true;
  }

  // ----- Liquidation -----

  /**
   * @notice Performs liquidation on the NFT20 platform against a given IRM's deposit coupon in exchange for droplet tokens
   * @dev This will leave the protocol underwater in ERC20 terms unless the droplets are liquidated. Business logic needs to understand and account for this.
   * @param hToken address of the HErc20 IRM
   * @param _couponNFTId ERC1155 tokenId of the target deposit coupon
   */

  function liquidateViaNFT20(IHERC20 hToken, uint256 _couponNFTId) external onlyRole(LIQUIDATOR_ROLE) returns (bool) {
    // Only if NFT20 pair exists
    address pair = poolToNiftyPair[address(hToken)];
    require(pair != address(0), "NFT20 pool not found");

    // Only if HErc20 has been initialized
    IERC721 collateralToken = poolToCollateralToken[address(hToken)];
    require(address(collateralToken) != address(0), "HErc20 not initialized?");

    // Only against active deposit coupons
    IHERC20.Coupon memory activeCoupon = hToken.getSpecificCoupon(_couponNFTId);
    require(activeCoupon.active, "Inactive coupon");

    // Get collateral asset tokenId
    uint256 _tokenId = activeCoupon.id;

    // May only execute if this contract owns the relevant NFT
    require(collateralToken.ownerOf(_tokenId) == address(this));

    // Only after clawback window
    require(
      block.timestamp > collectionToTokenToTimeReceived[collateralToken][_tokenId] + clawbackWindow,
      "Clawback window not elapsed."
    );

    // Straight token transfer, IERC721Reciever hook in NFT20 pair will mint pair tokens.
    collateralToken.safeTransferFrom(address(this), pair, _tokenId);

    emit NFT20LiquidationExecuted(pair, address(hToken), _couponNFTId);

    return true;
  }

  /**
   * @notice Swap droplets for ERC20 using a single Uniswap V3 pool, and use the funds to repay a borrow
   * @dev Only use this when a pool exists for the droplet and the underlying ERC20.
   * @param hToken address of the HErc20 to repay on
   * @param borrower address of the current owner of the deposit coupon
   * @param _couponNFTId tokenId of the deposit coupon
   * @param amountIn quantity of droplets to liquidate
   * @param amountOutMinimum minimum acceptable output quantity of output token
   * @return true upon success
   */
  function swapDropletsSingleAndRepayBorrow(
    IHERC20 hToken,
    address borrower,
    uint256 _couponNFTId,
    uint256 amountIn,
    uint256 amountOutMinimum
  ) external onlyRole(SWAPPER_ROLE) returns (bool) {
    // Retrieve addresses
    address droplet = poolToNiftyPair[address(hToken)];
    IERC20 outputToken = poolToUnderlyingToken[address(hToken)];

    address[] memory path = new address[](2);
    path[0] = droplet;
    path[1] = address(outputToken);

    // Set approval
    IERC20(droplet).approve(address(swapRouter), amountIn);

    // Dex swap
    swapExactDropletsSingle(amountIn, amountOutMinimum, path);

    IHERC20.Coupon memory activeCoupon = hToken.getSpecificCoupon(_couponNFTId);

    // Only against active coupons
    require(activeCoupon.active, "Inactive coupon");

    // Get collateral asset tokenId
    uint256 _tokenId = activeCoupon.id;

    // Closeout and repay funds
    require(hToken.closeoutLiquidation(borrower, _tokenId), "Closeout failed");

    return true;
  }

  /**
   * @notice Holder of the deposit coupon for a liquidated asset pays back the borrow in full + a fee, to reclaim the liquidated asset
   * @dev Transfer-taxed underlying tokens are not supported by this function
   * @param hToken address of the relevant HErc20 IRM
   * @param borrower Holder of the deposit coupon
   * @param _couponNFTId ERC1155 tokenId of the target deposit coupon
   * @return true upon success
   */
  function clawback(
    IHERC20 hToken,
    address borrower,
    uint256 _couponNFTId
  ) external returns (bool) {
    IERC20 underlyingToken = poolToUnderlyingToken[address(hToken)];
    IERC721 collateralToken = poolToCollateralToken[address(hToken)];

    IHERC20.Coupon memory activeCoupon = hToken.getSpecificCoupon(_couponNFTId);

    // Only against active coupons
    require(activeCoupon.active, "Inactive coupon");

    // Get collateral asset tokenId
    uint256 _tokenId = activeCoupon.id;

    // May only clawback if this contract owns the relevant NFT
    require(collateralToken.ownerOf(_tokenId) == address(this));

    // Only within clawback window
    require(
      block.timestamp <= collectionToTokenToTimeReceived[collateralToken][_tokenId] + clawbackWindow,
      "Clawback window expired."
    );

    /**
     * repayAmount = debt * (clawbackFee in percent + 1)
     */

    // TODO: Need to refactor this chain of calls to ensure fresh data
    uint256 debt = hToken.getBorrowFromCoupon(_couponNFTId);
    uint256 repayAmount = (debt * (clawbackFeeMantissa + 1e18)) / 1e18;

    // Intake user's funds
    // DEV NOTE: This require check eliminates ability to use clawback using transfer taxed underlying tokens
    require(doUnderlyingTransferIn(underlyingToken, borrower, repayAmount) == repayAmount);

    // Repay user's debt and burn coupon
    hToken.closeoutLiquidation(borrower, _tokenId);

    // Return collateral NFT to borrower
    collateralToken.transferFrom(address(this), borrower, _tokenId);

    emit ClawbackExecuted(address(hToken), borrower, _couponNFTId, repayAmount);

    return true;
  }

  /**
   * @notice ERC721 safeTransferFrom transfer hook
   * @dev Will only return the magic value if data contains a valid encoded address of HErc20 contract
   * @inheritdoc IERC721Receiver
   */
  function onERC721Received(
    address,
    address,
    uint256 tokenId,
    bytes calldata data
  ) public virtual override returns (bytes4) {
    if (data.length > 0) {
      // Data must contain encoded address of the HErc20 contract
      // Decode data to retrieve address
      address reconstructedAddress = abi.decode(data, (address));

      // Legitimate safeTransferFrom will come from token contract
      IERC721 collateralToken = poolToCollateralToken[reconstructedAddress];
      require(msg.sender == address(collateralToken), "Txn must come from token contract");

      // Check that the NFT was actually transferred
      require(collateralToken.ownerOf(tokenId) == address(this), "NFT not transferred");

      // Write the recieved block timestamp
      collectionToTokenToTimeReceived[collateralToken][tokenId] = block.timestamp;

      return this.onERC721Received.selector;
    } else {
      return bytes4(0);
    }
  }

  // ----- Utility Functions -----

  function swapExactDropletsSingle(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path
  ) internal returns (uint256[] memory) {
    uint256[] memory amounts = swapRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp);
    return amounts;
  }

  /**
   * @dev Transfer the given amount of the given underlying token to this contract
   * @dev Requires this contract to be adequately approved to transfer the amount
   * @param underlyingToken The ERC20 to transfer
   * @param from Address to transfer from
   * @param amount quantity of tokens to transfer
   * @return Quantity of tokens actually transferred
   */
  function doUnderlyingTransferIn(
    IERC20 underlyingToken,
    address from,
    uint256 amount
  ) internal returns (uint256) {
    uint256 balanceBefore = underlyingToken.balanceOf(address(this));
    underlyingToken.transferFrom(from, address(this), amount);
    uint256 balanceAfter = underlyingToken.balanceOf(address(this));

    // TODO: Additional checking to handle false returns

    require(balanceAfter >= balanceBefore, "Transfer invariant error");
    return balanceAfter - balanceBefore;
  }

  // ----- Administrative Functions -----

  /**
   * @notice Change the clawback window
   * @param newWindow in seconds
   * @return true on success
   */
  function updateClawbackWindow(uint256 newWindow) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
    uint256 oldWindow = clawbackWindow;
    clawbackWindow = newWindow;
    emit NewClawbackWindow(oldWindow, clawbackWindow);
    return true;
  }

  /**
   * @notice Change the clawback fee
   * @param newFee as fraction of borrow scaled by 1e18
   * @return true on success
   */
  function updateClawbackFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
    uint256 oldFee = clawbackFeeMantissa;
    clawbackFeeMantissa = newFee;
    emit NewClawbackFee(oldFee, clawbackFeeMantissa);
    return true;
  }

  /**
   * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
   * @param token The address of the ERC-20 token to sweep
   */
  function sweepToken(IERC20 token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 balance = token.balanceOf(address(this));
    token.transfer(treasury, balance);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IHERC20 {
  // Coupon NFT metadata
  struct Coupon {
    uint256 id; // Collateral collection token borrowed against
    uint256 borrowAmount; // Underlying token amount initially borrowed
    bool active; // Collateral asset currently held by contract?
    uint256 index; // Mantissa formatted borrow index at time of minting
  }

  function getSpecificCoupon(uint256 _couponNFTId) external view returns (Coupon memory);

  function closeoutLiquidation(address borrower, uint256 _tokenId) external returns (bool);

  function getBorrowFromCoupon(uint256 index) external view returns (uint256);

  function underlyingToken() external view returns (IERC20);

  function collateralToken() external view returns (IERC721);

  function isHToken() external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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