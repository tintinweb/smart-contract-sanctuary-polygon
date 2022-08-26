//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '../utils/Controllable.sol';
import '../tokens/IPxlbot.sol';
import '../minting/ScionCoordinator/IScionCoordinator.sol';
import './IMinter.sol';

contract AlphaMinter is Ownable, IERC721Receiver, Controllable, IMinter {
  IPxlbot pxlbot;
  IScionCoordinator scionCoordinator;

  uint256 public token_price = .01 ether;
  uint256 public token_price_pxl = 100;
  uint256 public bot_allowance = 0;
  uint256 bot_counter = 0;
  uint8 max_mint_per_txn = 5;
  uint8 base_attr_sum = 100;
  uint8 allowance_attr = 100;
  uint256 public staked_mint_multiplier = 1;
  mapping(uint256 => uint256) public attr_allowances;
  mapping(string => mapping(string => uint8)) public faction_attr_points;
  //the % by which the attrs go down based on minting from a scion
  uint8 default_degradation = 20;
  //tracking degradations for all scions
  mapping(uint256 => uint8) scion_degradation;
  //the number by which the degradation increases each time a scion is used
  uint8 scion_degradation_increment = 1;
  //the number by which the degradation is decreased if the bot is paid for
  uint8 scion_degradation_paid_divisor = 2;
  //for tracking original owners so they can claim a bot
  mapping(uint256 => address) private og_token_owners;
  //for tracking which bots have been claimed
  mapping(uint256 => bool) private claimed_playable_tokens;

  IERC20 token;

  constructor(IPxlbot _pxlbot, IScionCoordinator _scionCoordinator) {
    pxlbot = _pxlbot;
    scionCoordinator = _scionCoordinator;
  }

  function setMintPurchaseToken(address token_address) external override {
    token = IERC20(token_address);
  }

  function mintScion() public payable {
    require(
      canMintBot(1) == true,
      'unable to mint; either wrong caller or bot allowance exceeded'
    );
    (
      uint256 parent_id,
      string[] memory attr_ids,
      uint32[] memory attr_values
    ) = scionCoordinator.selectParent();
    uint8 _scion_degradation = scion_degradation[parent_id];
    if (_scion_degradation == 0) {
      _scion_degradation = default_degradation;
    }
    if (msg.value >= token_price) {
      _scion_degradation = _scion_degradation / scion_degradation_paid_divisor;
    }
    for (uint256 i = 0; i < attr_ids.length; i++) {
      attr_values[i] =
        ((attr_values[i] * 100) - (attr_values[i] * _scion_degradation)) /
        100;
    }
    pxlbot.mintScion(_msgSender(), parent_id, attr_ids, attr_values);
    uint256 tokenId = pxlbot.totalSupply();
    //connect the two in the coordinator
    scionCoordinator.connectScion(parent_id, tokenId);
    //put the token in play
    pxlbot.addTokenToGameplay(tokenId);
    //ensure scion order is updated
    scionCoordinator.updateParentIndex();
    //give the bot an attribute allowance
    attr_allowances[tokenId] = allowance_attr;
    //keep track of number of bots vs. allowance
    bot_counter++;
    //update degradation for scion
    scion_degradation[parent_id] =
      _scion_degradation +
      scion_degradation_increment;
  }

  function mintWithToken() external payable override {
    require(
      token_price_pxl <= token.balanceOf(msg.sender),
      'Insufficient balance'
    );
    token.transferFrom(msg.sender, address(this), token_price_pxl);
    mintScion();
  }

  //deprecated; only really for admins and testing (everything should come from a scion)
  function mint(uint8 num_bots) external payable override onlyController {
    require(
      num_bots < max_mint_per_txn,
      "you can't mint that many bots at a time"
    );
    _mint(num_bots);
  }

  function _mint(uint8 num_bots) internal {
    require(
      canMintBot(num_bots),
      'unable to mint; either wrong caller or bot allowance exceeded'
    );
    for (uint8 i = 0; i < num_bots; i++) {
      //mint the bot
      pxlbot.mint(1, address(this));
      uint256 tokenId = pxlbot.totalSupply();
      //assign the attributes
      //NOTE: can't seem to init a dynamic memory array with a fixed number of items to pass to setAttributeValues, so doing it one by one :(
      string[] memory attributes = new string[](5);
      attributes[0] = 'mobility';
      attributes[1] = 'intelligence';
      attributes[2] = 'durability';
      attributes[3] = 'communication';
      attributes[4] = 'stealth';

      uint32[] memory values = new uint32[](5);
      values[0] = uint32(random() % 100);
      values[1] = uint32(random() % 99);
      values[2] = uint32(random() % 98);
      values[3] = uint32(random() % 96);
      values[4] = uint32(random() % 95);

      pxlbot.setAttributeValues(tokenId, attributes, values);

      //give the bot an attribute allowance
      attr_allowances[tokenId] = allowance_attr;

      //re-assign to caller
      pxlbot.safeTransferFrom(address(this), msg.sender, tokenId);
      bot_counter++;

      //put the token in play
      pxlbot.addTokenToGameplay(tokenId);
    }
  }

  function claimFromCollectible(uint256 collectible_token_id) external payable {
    require(
      og_token_owners[collectible_token_id] == _msgSender(),
      'Minter: Caller does not own the collectible.'
    );
    require(
      claimed_playable_tokens[collectible_token_id] == false,
      'Minter: token has already been claimed.'
    );
    (string[] memory attr_ids, uint32[] memory attr_values) = scionCoordinator
      .getParent(collectible_token_id);
    //mint the bot
    pxlbot.mint(1, _msgSender());
    uint256 tokenId = pxlbot.totalSupply();
    //assign attrs (no degradation)
    pxlbot.setAttributeValues(tokenId, attr_ids, attr_values);
    //put the token in play
    pxlbot.addTokenToGameplay(tokenId);
    claimed_playable_tokens[collectible_token_id] = true;
  }

  function setBaseAttributeSum(uint8 new_sum) external onlyController {
    base_attr_sum = new_sum;
  }

  function setAllowanceAttr(uint8 new_allowance) external onlyController {
    allowance_attr = new_allowance;
  }

  function spendAttrAllowance(
    uint256 tokenId,
    string[] memory attrIds,
    uint8[] memory amounts
  ) external {
    uint32[] memory current_values = pxlbot.attributeValues(tokenId, attrIds);
    uint32[] memory new_amounts = new uint32[](amounts.length);
    for (uint8 i = 0; i < attrIds.length; i++) {
      uint32 amount = current_values[i];
      uint32 new_amount = amount + amounts[i];
      require(
        attr_allowances[tokenId] >= amounts[i],
        'Not enough attribute points left to spend'
      );
      require(
        new_amount <= 100,
        "You can't go over the max amount per attribute"
      );
      new_amounts[i] = new_amount;
      attr_allowances[tokenId] -= amounts[i];
    }
    pxlbot.setAttributeValues(tokenId, attrIds, new_amounts);
  }

  function canMintBot(uint8 num_bots) public view returns (bool) {
    return
      isController(_msgSender()) || bot_counter + num_bots <= bot_allowance;
  }

  function resetBotAllowance(uint256 num_staked_tokens)
    external
    override
    onlyController
  {
    bot_allowance = staked_mint_multiplier * num_staked_tokens;
  }

  function setMintMultiplier(uint256 new_multiplier)
    external
    override
    onlyController
  {
    staked_mint_multiplier = new_multiplier;
  }

  function setTokenPrice(uint256 new_price) external override onlyController {
    token_price = new_price;
  }

  function setScionDegradationIncrement(uint8 _inc) external onlyController {
    scion_degradation_increment = _inc;
  }

  function setScionDegradationPaidDivisor(uint8 _div) external onlyController {
    scion_degradation_paid_divisor = _div;
  }

  function setCollectibleTokenOwner(uint256 tokenId, address owner)
    external
    override
    onlyController
  {
    og_token_owners[tokenId] = owner;
  }

  //retrieved from https://stackoverflow.com/questions/48848948/how-to-generate-a-random-number-in-solidity
  function random() private view returns (uint256) {
    int256 thing = 100;
    return
      uint256(
        keccak256(abi.encodePacked(block.difficulty, block.timestamp, thing))
      );
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract Controllable is Ownable {
  mapping(address => bool) private _controllers;
  /**
   * @dev Initializes the contract setting the deployer as a controller.
   */
  constructor() {
    _addController(_msgSender());
  }

  modifier mutualControllersOnly(address _caller) {
    Controllable caller = Controllable(_caller);
    require(_controllers[_caller] && caller.isController(address(this)), 'Controllable: not mutual controllers');
    _;
  }

  /**
   * @dev Returns true if the address is a controller.
   */
  function isController(address controller) public view virtual returns (bool) {
    return _controllers[controller];
  }

  /**
   * @dev Throws if called by any account that isn't a controller
   */
  modifier onlyController() {
    require(_controllers[_msgSender()], "Controllable: not controller");
    _;
  }

  modifier nonZero(address a) {
    require(a != address(0), "Controllable: input is zero address");
    _;
  }

  /**
   * @dev Adds a new controller.
   * Can only be called by the current owner.
   */
  function addController(address c) public virtual onlyOwner nonZero(c) {
     _addController(c);
  }

  /**
   * @dev Adds a new controller.
   * Internal function without access restriction.
   */
  function _addController(address newController) internal virtual {
    _controllers[newController] = true;
  }

    /**
   * @dev Removes a controller.
   * Can only be called by the current owner.
   */
  function removeController(address c) public virtual onlyOwner nonZero(c) {
     _removeController(c);
  }
  
  /**
   * @dev Removes a controller.
   * Internal function without access restriction.
   */
  function _removeController(address controller) internal virtual {
    delete _controllers[controller];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import 'erc721a/contracts/interfaces/IERC721AQueryable.sol';
import '../gameplay/coordinators/InventoryCoordinator/IInventoryEntityContract.sol';
import '../gameplay/coordinators/AttributeCoordinator/IAttributeCoordinator.sol';
import './IERC721APlayable.sol';

interface IPxlbot is
  IInventoryEntityContract,
  IAttributeCoordinator,
  IERC721AQueryable,
  IERC721APlayable
{
  function mint(uint256 amount, address to) external payable;

  function mintScion(
    address to,
    uint256 parent_id,
    string[] memory attrsIds,
    uint32[] memory attrsVals
  ) external payable;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '../../gameplay/coordinators/InventoryCoordinator/IInventoryEntityContract.sol';

interface IScionCoordinator is IInventoryEntityContract {
  function addParent(
    uint256 parent_id,
    string[] memory attr_ids,
    uint32[] memory attr_vals,
    address owner
  ) external payable;

  function removeParent(uint256 parent_id) external payable;

  function parentOwnerChanged(uint256 parent_id, address new_owner)
    external
    payable;

  function getParent(uint256 parent_id)
    external
    view
    returns (string[] memory, uint32[] memory);

  function selectParent()
    external
    view
    returns (
      uint256 token,
      string[] memory attr_ids,
      uint32[] memory attr_values
    );

  function totalParents() external view returns (uint256);

  function currentParentIndex() external view returns (uint256);

  function updateParentIndex() external;

  function connectScion(uint256 parent_id, uint256 scion_id) external;

  function getScions(uint256 parent_id)
    external
    view
    returns (uint256[] memory);

  function hasParent(uint256 scion_token_id) external view returns (uint256);

  function tributePercentage(uint256 child_token_id)
    external
    view
    returns (uint256);

  function addTribute(uint256 scion_id, uint256 amount) external;

  function claimTribute(uint256 scion_id) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/interfaces/IERC20.sol';

interface IMinter {
  function setMintPurchaseToken(address token_address) external;

  function mintWithToken() external payable;

  function mint(uint8 num_tokens) external payable;

  function resetBotAllowance(uint256 stakedTokens) external;

  function setMintMultiplier(uint256 new_multiplier) external;

  function setTokenPrice(uint256 new_price) external;

  function setCollectibleTokenOwner(uint256 tokenId, address owner) external;
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
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../extensions/IERC721AQueryable.sol';

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//defines an "Entity" that can hold an item in inventory (e.g. a pxlbot; consisting of pxlbot contract address and a token ID)
interface IInventoryEntityContract {
  // Base id is determined by the contract. Examples might be tokenId in an ERC721 or simply putting 1 for ERC20
  function irlOwner(uint256 _baseId) external returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAttributeCoordinator {
    function attributeValues(uint256 botId, string[] memory attrIds) external returns(uint32[] memory);
    function setAttributeValues(uint256 botId, string[] memory attrIds, uint32[] memory values) external;
    function totalPossible() external returns(uint32);
    function getAttrIds() external returns (string[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import 'erc721a/contracts/interfaces/IERC721AQueryable.sol';
import '../gameplay/coordinators/GameplayCoordinator/IGameplayCoordinator.sol';

interface IERC721APlayable is IERC721AQueryable {
    function addTokenToGameplay(uint256 id) external;
    function removeTokenFromGameplay(uint256 id) external;
    function isTokenInPlay(uint256 tokenId) external view returns(bool);
    function setGameplayCoordinator(IGameplayCoordinator c) external;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IGameplayCoordinator {
    function isBotBusy(uint256 id) external returns(bool);
    function makeBotBusy(uint256 botId) external;
    function makeBotUnbusy(uint256 botId) external;
    function isBotInGame(uint256 botId) external returns(bool);
}