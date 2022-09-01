// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { ITokenLockerUniV3 } from "./ITokenLockerUniV3.sol";
import { TokenLockerManagerV2, LockData } from "./TokenLockerManagerV2.sol";
import { TokenLockerLPV2 } from "./TokenLockerLPV2.sol";
import { TokenLockerERC721V2 } from "./TokenLockerERC721V2.sol";
import { IERC20 } from "../library/IERC20.sol";
import { IERC721 } from "../library/IERC721.sol";
import { INonfungiblePositionManager } from "../library/uniswap-v3/INonfungiblePositionManager.sol";
import { UtilV2 } from "../UtilV2.sol";

contract TokenLockerUniV3 is ITokenLockerUniV3, TokenLockerLPV2, TokenLockerERC721V2 {
  /** @dev initialize TokenLockerManagerV2 without a valid factory, because we don't need one */
  constructor() TokenLockerManagerV2(address(0)) {}

  function _createTokenLocker(
    address tokenAddress_,
    uint256 tokenId_,
    uint40 unlockTime_
  ) internal virtual override returns (
    uint40 id
  ) {
    // check if this is a uniswap v3 lp token
    require(UtilV2.isUniV3Lp(tokenAddress_), "INVALID_TOKEN");

    INonfungiblePositionManager positionManager = INonfungiblePositionManager(
      tokenAddress_
    );

    (,,address token0,address token1,,,,,,,,) = positionManager.positions(
      tokenId_
    );

    id = uint40(_next());

    // write to state before transfer
    _locks[id].tokenAddress = tokenAddress_;
    _locks[id].createdAt = uint40(block.timestamp);
    _locks[id].createdBy = _msgSender();
    _locks[id].owner = _msgSender();

    // make the deposit - this also sets unlock time
    _deposit(id, tokenId_, unlockTime_);

    // build search index
    _tokenLockersForAddress[_msgSender()].push(id);
    _tokenLockersForAddress[tokenAddress_].push(id);
    _tokenLockersForAddress[token0].push(id);
    _tokenLockersForAddress[token1].push(id);

    emit TokenLockerCreated(
      id,
      tokenAddress_,
      token0,
      token1,
      _msgSender(),
      tokenId_,
      unlockTime_
    );
  }

  function _deposit(
    uint40 id_,
    uint256 tokenId_,
    uint40 newUnlockTime_
  ) internal virtual override {
    require(
      newUnlockTime_ >= _locks[id_].unlockTime && newUnlockTime_ > uint40(block.timestamp),
      "TOO_SOON"
    );

    _locks[id_].unlockTime = newUnlockTime_;
    _locks[id_].extendedAt = uint40(block.timestamp);
    _locks[id_].amountOrTokenId = tokenId_;

    IERC721(_locks[id_].tokenAddress).safeTransferFrom(
      _msgSender(),
      address(this),
      tokenId_
    );
  }

  function withdrawById(
    uint40 id_
  ) external virtual override onlyLockOwner(id_) nonReentrant {
    require(uint40(block.timestamp) >= _locks[id_].unlockTime, "LOCKED");

    IERC721(_locks[id_].tokenAddress).safeTransferFrom(
      address(this),
      _locks[id_].owner,
      _locks[id_].amountOrTokenId
    );
  }

  function getLpData(
    uint40 id_
  ) external virtual override view returns (
    bool hasLpData,
    uint40 id,
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  ) {
    hasLpData = true;
    // pass-through, don't like this, but w/e
    id = id_;

    (
      token0,
      token1,
      balance0,
      balance1
    ) = UtilV2.getUniV3LpData(
      _locks[id_].tokenAddress,
      _locks[id_].amountOrTokenId
    );

    // deprecated, but here to maintain interface compatibility
    price0 = 0;
    price1 = 0;
  }

  function migrate(
    uint40 id_,
    address /* oldRouterAddress_ */,
    address /* newRouterAddress_ */
  ) external virtual override onlyLockOwner(id_) nonReentrant {
    revert("NOT_IMPLEMENTED");

    // require(_allowedRouters[newRouterAddress_], "INVALID_ROUTER");

    // IUniswapV2Pair oldPair = IUniswapV2Pair(_locks[id_].tokenAddress);

    // // approve the old router
    // IERC20(_locks[id_].tokenAddress).safeApprove(oldRouterAddress_, _locks[id_].amountOrTokenId);

    // // unpair on old router and send tokens to this address
    // (
    //   uint256 amountRemoved0,
    //   uint256 amountRemoved1
    // ) = IUniswapV2Router02(
    //   oldRouterAddress_
    // ).removeLiquidity(
    //   oldPair.token0(),
    //   oldPair.token1(),
    //   _locks[id_].amountOrTokenId,
    //   // accept any amount of "slippage"
    //   0,0,
    //   // send unpaired tokens to this address temporarily
    //   address(this),
    //   // must finish in the same tx
    //   block.timestamp
    // );

    // // approve the new router
    // IERC20(oldPair.token0()).safeApprove(newRouterAddress_, amountRemoved0);
    // IERC20(oldPair.token1()).safeApprove(newRouterAddress_, amountRemoved1);

    // IUniswapV2Router02 newRouter = IUniswapV2Router02(newRouterAddress_);

    // (
    //   uint256 amountAdded0,
    //   uint256 amountAdded1,
    //   uint256 newTokenAmount
    // ) = newRouter.addLiquidity(
    //   oldPair.token0(),
    //   oldPair.token1(),
    //   amountRemoved0,
    //   amountRemoved1,
    //   // accept any amount of "slippage"
    //   0,0,
    //   // send the new lp tokens to this address
    //   address(this),
    //   // must finish in the same tx
    //   block.timestamp
    // );

    // // amount removed and amount added must match or something went wrong
    // require(
    //   amountAdded0 == amountRemoved0 && amountAdded1 == amountRemoved1,
    //   "LOST_TOKENS"
    // );

    // // update the existing lock instead of creating a new one
    // _locks[id_].tokenAddress = IUniswapV2Factory(
    //   newRouter.factory()
    // ).getPair(
    //   oldPair.token0(),
    //   oldPair.token1()
    // );
    // _locks[id_].amountOrTokenId = newTokenAmount;
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { ITokenLockerLPV2 } from "./ITokenLockerLPV2.sol";
import { ITokenLockerERC721V2 } from "./ITokenLockerERC721V2.sol";

interface ITokenLockerUniV3 is ITokenLockerLPV2, ITokenLockerERC721V2 {
  
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { ITokenLockerManagerV2 } from "./ITokenLockerManagerV2.sol";
import { Governable } from "../Governance/Governable.sol";
import { Pausable } from "../Control/Pausable.sol";
import { IDCounter } from "../IDCounter.sol";
import { ITokenLockerBaseV2 } from "./ITokenLockerBaseV2.sol";
import { ITokenLockerFactoryV2 } from "./ITokenLockerFactoryV2.sol";
import { IERC20 } from "../library/IERC20.sol";
import { ReentrancyGuard } from "../library/ReentrancyGuard.sol";
// import { INonfungiblePositionManager } from "../library/uniswap-v3/INonfungiblePositionManager.sol";

struct LockData {
  address tokenAddress;
  address owner;
  address createdBy;
  uint256 amountOrTokenId;
  uint40 createdAt;
  uint40 extendedAt;
  uint40 unlockTime;
}

contract TokenLockerManagerV2 is ITokenLockerManagerV2, Governable, Pausable, IDCounter, ReentrancyGuard {
  constructor(address factoryAddress_) Governable(_msgSender(), _msgSender()) {
    _setFactory(factoryAddress_);
  }

  ITokenLockerFactoryV2 internal _factory;

  mapping(uint40 => address) internal _lockAddresses;

  mapping(address => bool) internal _allowedRouters;

  /** @dev id => lock data */
  mapping(uint40 => LockData) internal _locks;

  /**
   * @dev this mapping makes it possible to search for locks,
   * at the cost of paying higher gas fees to store the data.
   */
  mapping(address => uint40[]) internal _tokenLockersForAddress;
  mapping(address => mapping(uint40 => bool)) internal _tokenLockersForAddressLookup;

  function factory() external virtual override view returns (address) {
    return address(_factory);
  }

  function _setFactory(address address_) internal virtual {
    _factory = ITokenLockerFactoryV2(address_);
  }

  function setFactory(address address_) external virtual override onlyOwner {
    _setFactory(address_);
  }

  /**
   * @dev _count is a uint256, but locker V1 used uint40, so we cast to uint40.
   * since the max value is uint40 is over a trillion, i think it will be ok.
   */
  function tokenLockerCount() external virtual override view returns (uint40) {
    return uint40(_count);
  }

  /**
   * @dev maps to !_paused to maintain compatibility with locker V1
   */
  function creationEnabled() external virtual override view returns (bool) {
    return !_paused;
  }
  
  /**
   * @dev maps to _setPaused to maintain compatibility with locker V1
   */
  function setCreationEnabled(bool value_) external virtual override onlyOwner {
    _setPaused(value_);
  }

  /** @dev override this */
  function _createTokenLocker(
    address tokenAddress_,
    uint256 amount_,
    uint40 unlockTime_
  ) internal virtual returns (
    uint40 id
  ) {}

  function createTokenLocker(
    address tokenAddress_,
    uint256 amount_,
    uint40 unlockTime_
  ) external virtual override onlyNotPaused nonReentrant {
    _createTokenLocker(tokenAddress_, amount_, unlockTime_);
  }

  function createTokenLockerV2(
    address tokenAddress_,
    uint256 amountOrTokenId_,
    uint40 unlockTime_
  ) external virtual override onlyNotPaused nonReentrant returns (
    uint40 id,
    address lockAddress
  ) {
    id = _createTokenLocker(tokenAddress_, amountOrTokenId_, unlockTime_);
    lockAddress = address(this);
  }

  /** @dev this may need overriding on inherited contracts! */
  function _getTokenLockAddress(uint40 id_) internal virtual view returns (address) {
    require(id_ < _count, "Invalid id");
    return address(this);
  }

  function getTokenLockAddress(uint40 id_) external virtual override view returns (address) {
    return _getTokenLockAddress(id_);
  }

  function getTokenLockData(uint40 id_) external virtual override view returns (
    bool isLpToken,
    uint40 id,
    address contractAddress,
    address lockOwner,
    address token,
    address createdBy,
    uint40 createdAt,
    uint40 unlockTime,
    uint256 balance,
    uint256 totalSupply
  ) {

  }

  function getLpData(uint40 id_) external virtual override view returns (
    bool hasLpData,
    uint40 id,
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  ) {

  }

  function getTokenLockersForAddress(
    address address_
  ) external virtual override view returns (
    uint40[] memory
  ) {
    return _tokenLockersForAddress[address_];
  }

  function notifyLockerOwnerChange(
    uint40 id_,
    address newOwner_,
    address previousOwner_,
    address createdBy_
  ) external virtual override {

  }

  /** @dev for overriding */
  function transferLockOwnership(uint40 id_, address newOwner_) external virtual {
    //
  }

  function setAllowedRouterAddress(
    address routerAddress_,
    bool allowed_
  ) external virtual override onlyGovernor {
    _allowedRouters[routerAddress_] = allowed_;
  }
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { ITokenLockerLPV2 } from "./ITokenLockerLPV2.sol";
import { ITokenLockerManagerV1 } from "../ITokenLockerManagerV1.sol";
import { ITokenLockerManagerV2 } from "./ITokenLockerManagerV2.sol";
import { TokenLockerManagerV2 } from "./TokenLockerManagerV2.sol";
import { TokenLockerBaseV2 } from "./TokenLockerBaseV2.sol";
import { IERC20 } from "../library/IERC20.sol";


abstract contract TokenLockerLPV2 is ITokenLockerLPV2, TokenLockerManagerV2, TokenLockerBaseV2 {
  function _isLockOwner(uint40 id_) internal virtual override view returns (bool) {
    return _locks[id_].owner == _msgSender();
  }

  function withdraw() external virtual override {
    revert("NOT_IMPLEMENTED");
  }

  function factory() external virtual override(
    ITokenLockerManagerV2,
    TokenLockerManagerV2
  ) pure returns (address) {
    return address(0);
  }

  function setFactory(
    address /* address_ */
  ) external virtual override(
    ITokenLockerManagerV2,
    TokenLockerManagerV2
  ) onlyOwner {
    revert("NOT_IMPLEMENTED");
  }

  function notifyLockerOwnerChange(
    uint40 /* id_ */,
    address /* newOwner_ */,
    address /* previousOwner_ */,
    address /* createdBy_ */
  ) external virtual override(
    ITokenLockerManagerV1,
    TokenLockerManagerV2
  ){
    revert("NOT_IMPLEMENTED");
  }

  function _transferLockOwnership(
    uint40 id_,
    address newOwner_
  ) internal virtual {
    address oldOwner = _locks[id_].owner;
    _locks[id_].owner = newOwner_;

    // we don't actually need to remove old owners from the search index. who cares.
    // but we do need to add the new owner. only add id if they didn't already have it.
    if (!_tokenLockersForAddressLookup[newOwner_][id_]) {
      _tokenLockersForAddress[newOwner_].push(id_);
      _tokenLockersForAddressLookup[newOwner_][id_] = true;
    }

    emit LockOwnershipTransfered(
      id_,
      oldOwner,
      newOwner_
    );
  }

  function transferLockOwnership(
    uint40 id_,
    address newOwner_
  ) external virtual override(
    ITokenLockerManagerV2,
    TokenLockerManagerV2
  ){
    _transferLockOwnership(id_, newOwner_);
  }

  function getTokenLockData(
    uint40 id_
  ) external virtual override(ITokenLockerManagerV1, TokenLockerManagerV2) view returns (
    bool isLpToken,
    uint40 id,
    address contractAddress,
    address lockOwner,
    address token,
    address createdBy,
    uint40 createdAt,
    uint40 unlockTime,
    uint256 balance,
    uint256 totalSupply
  ){
    isLpToken = id_ < _count;
    id = id_;
    contractAddress = address(this);
    lockOwner = _locks[id_].owner;
    token = _locks[id_].tokenAddress;
    createdBy = _locks[id_].createdBy;
    createdAt = _locks[id_].createdAt;
    unlockTime = _locks[id_].unlockTime;
    balance = _locks[id_].amountOrTokenId;
    totalSupply = IERC20(token).totalSupply();
  }

  // function getLockData() external virtual override returns (
  //   bool isLpToken,
  //   uint40 id,
  //   address contractAddress,
  //   address lockOwner,
  //   address token,
  //   address createdBy,
  //   uint40 createdAt,
  //   uint40 unlockTime,
  //   uint256 balance,
  //   uint256 totalSupply
  // ) {
    
  // }
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { ITokenLockerERC721V2 } from "./ITokenLockerERC721V2.sol";
import { IERC721Receiver } from "../library/IERC721Receiver.sol";

abstract contract TokenLockerERC721V2 is ITokenLockerERC721V2 {
  function onERC721Received(
    address /* operator */,
    address /* from */,
    uint256 /* tokenId */,
    bytes calldata /* data */
  ) external pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: GPL-3.0+

pragma solidity >=0.7.5;
pragma abicoder v2;

import "../IERC721Metadata.sol";
import "../IERC721Enumerable.sol";

import './IPoolInitializer.sol';
import '../IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import './PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IERC20 } from "./library/IERC20.sol";
import { IERC165 } from "./library/IERC165.sol";
import { IERC721 } from "./library/IERC721.sol";
import { INonfungiblePositionManager } from "./library/uniswap-v3/INonfungiblePositionManager.sol";

library UtilV2 {

  function isERC721(address address_) external view returns (bool) {
    try IERC165(address_).supportsInterface(type(IERC721).interfaceId) returns (bool isSupported) {
      return isSupported;
    } catch Error(string memory /* reason */) {
      return false;
    } catch (bytes memory /* reason */) {
      return false;
    }
  }

  function isUniV3Lp(address address_) external view returns (bool) {
    try IERC165(address_).supportsInterface(type(INonfungiblePositionManager).interfaceId) returns (bool isSupported) {
      return isSupported;
    } catch Error(string memory /* reason */) {
      return false;
    } catch (bytes memory /* reason */) {
      return false;
    }
  }

  function getUniV3LpData(address address_, uint256 tokenId_) external view returns (
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1
  ) {
    (,,token0,token1,,,,,,,,) = INonfungiblePositionManager(
      address_
    ).positions(
      tokenId_
    );

    // returns the total balance, not the portion of this position
    balance0 = IERC20(token0).balanceOf(address_);
    balance1 = IERC20(token1).balanceOf(address_);
  }
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { ITokenLockerManagerV2 } from "./ITokenLockerManagerV2.sol";
import { ITokenLockerBaseV2 } from "./ITokenLockerBaseV2.sol";


interface ITokenLockerLPV2 is ITokenLockerManagerV2, ITokenLockerBaseV2 {
  event Extended(uint40 id, uint40 newUnlockTime);
  event Deposited(uint40 id, uint256 amountOrTokenId);
  event Withdrew(uint40 id);
  event LockOwnershipTransfered(
    uint40 id,
    address oldOwner,
    address newOwner
  );

  function withdrawById(
    uint40 id_
  ) external;
  function migrate(
    uint40 id_,
    address oldRouterAddress_,
    address newRouterAddress_
  ) external;
  // function getLockData() external returns (
  //   bool isLpToken,
  //   uint40 id,
  //   address contractAddress,
  //   address lockOwner,
  //   address token,
  //   address createdBy,
  //   uint40 createdAt,
  //   uint40 unlockTime,
  //   uint256 balance,
  //   uint256 totalSupply
  // );
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { ITokenLockerBaseV2 } from "./ITokenLockerBaseV2.sol";
import { IERC721Receiver } from "../library/IERC721Receiver.sol";

interface ITokenLockerERC721V2 is ITokenLockerBaseV2, IERC721Receiver {
  // function splitLock() external;
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { ITokenLockerManagerV1 } from "../ITokenLockerManagerV1.sol";
import { IGovernable } from "../Governance/IGovernable.sol";
import { IPausable } from "../Control/IPausable.sol";
import { IIDCounter } from "../IIDCounter.sol";

interface ITokenLockerManagerV2 is ITokenLockerManagerV1, IGovernable, IPausable, IIDCounter {
  /**
   * @dev this should have been in ITokenLockerManagerV1,
   * but it wound up in TokenLockerManagerV1. define it here instead.
   */
  event TokenLockerCreated(
    uint40 id,
    address indexed token,
    /** @dev LP token pair addresses - these will be address(0) for regular tokens */
    address indexed token0,
    address indexed token1,
    address createdBy,
    /** this is balance for erc20 locks, and tokenId for erc721 locks */
    uint256 balanceOrTokenId,
    uint40 unlockTime
  );

  function factory() external view returns (address);

  function setFactory(address address_) external;

  function createTokenLockerV2(
    address tokenAddress_,
    uint256 amountOrTokenId_,
    uint40 unlockTime_
  ) external returns (
    uint40 id,
    address lockAddress
  );

  function transferLockOwnership(
    uint40 id_,
    address newOwner_
  ) external;

  function setAllowedRouterAddress(
    address routerAddress_,
    bool allowed_
  ) external;
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IOwnableV2 } from "../Control/IOwnableV2.sol";

interface ITokenLockerBaseV2 is IOwnableV2 {
  function setSocials(
    uint40 id_,
    string[] calldata keys_,
    string[] calldata urls_
  ) external;
  function getUrlForSocialKey(
    uint40 id_,
    string calldata key_
  ) external view returns (
    string memory
  );
  function withdraw() external;
  function deposit(
    uint40 id_,
    uint256 amountOrTokenId_,
    uint40 newUnlockTime_
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

interface ITokenLockerManagerV1 {
  function tokenLockerCount() external view returns (uint40);
  function creationEnabled() external view returns (bool);
  function setCreationEnabled(bool value_) external;
  function createTokenLocker(
    address tokenAddress_,
    uint256 amount_,
    uint40 unlockTime_
  ) external;
  function getTokenLockAddress(uint40 id_) external view returns (address);
  function getTokenLockData(uint40 id_) external view returns (
    bool isLpToken,
    uint40 id,
    address contractAddress,
    address lockOwner,
    address token,
    address createdBy,
    uint40 createdAt,
    uint40 unlockTime,
    uint256 balance,
    uint256 totalSupply
  );
  function getLpData(uint40 id_) external view returns (
    bool hasLpData,
    uint40 id,
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  );
  function getTokenLockersForAddress(address address_) external view returns (uint40[] memory);
  function notifyLockerOwnerChange(uint40 id_, address newOwner_, address previousOwner_, address createdBy_) external;
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IOwnableV2 } from "../Control/IOwnableV2.sol";

interface IGovernable is IOwnableV2 {
  event GovernorshipTransferred(address indexed oldGovernor, address indexed newGovernor);

  function governor() external view returns (address);
  function transferGovernorship(address newGovernor) external;
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IOwnableV2 } from "./IOwnableV2.sol";

interface IPausable is IOwnableV2 {
  function paused() external view returns (bool);
  function setPaused(bool value) external;
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

interface IIDCounter {
  function count() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;


/**
 * @title Ownable
 * 
 * parent for ownable contracts
 */
interface IOwnableV2 {
  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  function owner() external view returns (address);
  function transferOwnership(address newOwner_) external;
}

// SPDX-License-Identifier: MIT

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IGovernable } from "./IGovernable.sol";
import { OwnableV2 } from "../Control/OwnableV2.sol";

/**
 * @title Governable
 * 
 * parent for governable contracts
 */
abstract contract Governable is IGovernable, OwnableV2 {
  constructor(address owner_, address governor_) OwnableV2(owner_) {
    _governor_ = governor_;
    emit GovernorshipTransferred(address(0), _governor());
  }

  address internal _governor_;

  function _governor() internal view returns (address) {
    return _governor_;
  }

  function governor() external view override returns (address) {
    return _governor();
  }

  modifier onlyGovernor() {
    require(_governor() == _msgSender(), "Only the governor can execute this function");
    _;
  }

  // not currently used - but here it is in case we want this
  // modifier onlyOwnerOrGovernor() {
  //   require(_owner() == _msgSender() || _governor() == _msgSender(), "Only the owner or governor can execute this function");
  //   _;
  // }

  function _transferGovernorship(address newGovernor) internal virtual {
    // keep track of old owner for event
    address oldGovernor = _governor();

    // set the new owner
    _governor_ = newGovernor;

    // emit event about ownership change
    emit GovernorshipTransferred(oldGovernor, _governor());
  }

  function transferGovernorship(address newGovernor) external override onlyOwner {
    _transferGovernorship(newGovernor);
  }
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IPausable } from "./IPausable.sol";
import { OwnableV2 } from "./OwnableV2.sol";

abstract contract Pausable is IPausable, OwnableV2 {
  bool internal _paused;

  modifier onlyNotPaused() {
    require(!_paused, "Contract is paused");
    _;
  }

  function paused() external view override returns (bool) {
    return _paused;
  }

  function _setPaused(bool value) internal virtual {
    _paused = value;
  }

  function setPaused(bool value) external override onlyOwner {
    _setPaused(value);
  }
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IIDCounter } from "./IIDCounter.sol";

abstract contract IDCounter is IIDCounter {
  uint256 internal _count;

  function count() external view override returns (uint256) {
    return _count;
  }

  function _next() internal virtual returns (uint256) {
    return _count++;
  }
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

interface ITokenLockerFactoryV2 {
  function createLocker(
    // 0 = uniswap v2 lp token, 1 = uniswap v3 lp position nft, 2 = erc721 nft, 3 = erc20 token
    uint8 lockType_,
    address manager_,
    uint40 lockId_,
    bytes memory extraData_
  ) external returns (address lockAddress);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { Context } from "../library/Context.sol";
import { IOwnableV2 } from "./IOwnableV2.sol";

/**
 * @title Ownable
 * 
 * parent for ownable contracts
 */
abstract contract OwnableV2 is IOwnableV2, Context {
  constructor(address owner_) {
    _owner_ = owner_;
    emit OwnershipTransferred(address(0), _owner());
  }

  address internal _owner_;

  function _owner() internal virtual view returns (address) {
    return _owner_;
  }

  function owner() external virtual override view returns (address) {
    return _owner();
  }

  modifier onlyOwner() {
    require(_owner() == _msgSender(), "Only the owner can execute this function");
    _;
  }

  function _transferOwnership(address newOwner_) internal virtual onlyOwner {
    // keep track of old owner for event
    address oldOwner = _owner();

    // set the new owner
    _owner_ = newOwner_;

    // emit event about ownership change
    emit OwnershipTransferred(oldOwner, _owner());
  }

  function transferOwnership(address newOwner_) external virtual override onlyOwner {
    _transferOwnership(newOwner_);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

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

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { ITokenLockerBaseV2 } from "./ITokenLockerBaseV2.sol";
import { ReentrancyGuard } from "../library/ReentrancyGuard.sol";

abstract contract TokenLockerBaseV2 is ITokenLockerBaseV2, ReentrancyGuard {
  /** @dev id => siteKey => url */
  mapping(uint40 => mapping(string => string)) internal _socials;

  modifier onlyLockOwner(uint40 id_) {
    require(_isLockOwner(id_), "UNAUTHORIZED");
    _;
  }

  /** @dev override this */
  function _isLockOwner(uint40 id_) internal virtual view returns (bool) {}

  function _setSocials(
    uint40 id_,
    string[] calldata keys_,
    string[] calldata urls_
  ) internal virtual {
    require(keys_.length == urls_.length, "ARRAY_SIZE_MISMATCH");

    for (uint256 i = 0; i < keys_.length; i++) {
      _socials[id_][keys_[i]] = urls_[i];
    }
  }

  function setSocials(
    uint40 id_,
    string[] calldata keys_,
    string[] calldata urls_
  ) external virtual override onlyLockOwner(id_) {
    _setSocials(id_, keys_, urls_);
  }

  function getUrlForSocialKey(
    uint40 id_,
    string calldata key_
  ) external virtual override onlyLockOwner(id_) view returns (
    string memory
  ){
    return _socials[id_][key_];
  }

  function _deposit(
    uint40 id_,
    uint256 amountOrTokenId_,
    uint40 newUnlockTime_
  ) internal virtual {}

  function deposit(
    uint40 id_,
    uint256 amountOrTokenId_,
    uint40 newUnlockTime_
  ) external virtual override onlyLockOwner(id_) nonReentrant {
    _deposit(id_, amountOrTokenId_, newUnlockTime_);
  }
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

pragma solidity >=0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import './IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            // NOTE: later versions of solidity can only convert uint160 to address,
            // so convert the uint256 to uint160. - kevin
            uint160(
              uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
              )
            )
        );
    }
}