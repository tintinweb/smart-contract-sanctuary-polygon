//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IMysteryBox.sol" as IMB;
import "../libraries/ArrayUtils.sol" as Utils;
import "@openzeppelin/contracts/utils/math/SafeMath.sol" as SafeMath;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MysterBox3 is Initializable, IMB.IMysteryBox {
  ///@dev connect libs
  using SafeMath.SafeMath for uint256;
  using Utils.ArrayUtils for uint256[];

  ///@dev global private varibles
  uint256 private _counter;

  /// @notice collection address => contextId => last contextId
  mapping(address => uint256) private _lastContextId;

  ///@dev global public varibles

  /// @notice collection address => contextId => Box
  mapping(address => mapping(uint256 => Box)) public boxes;

  /// @notice collection address => contextId => ContextBox
  mapping(address => mapping(uint256 => ContextBox)) public contextsBox;

  ///@notice collection address => admin address => is active => bool
  mapping(address => mapping(address => bool)) public collectionAdmins;

  // CONSTRUCTOR
  function initialize() public initializer {
    _counter = 1;
  }

  ///@dev view functions
  function getSeries(
    address collection,
    uint256 contextId,
    string calldata series
  ) external view override returns (BoxSeries memory) {
    return _getSeries(collection, contextId, series);
  }

  function getBox(
    address collection,
    uint256 contextId,
    uint256 boxTokenId
  ) external view override returns (Box memory) {
    return _getBox(collection, contextId, boxTokenId);
  }

  function getAllSeries(address collection, uint256 contextId) external view override returns (string[] memory) {
    return _getAllSeries(collection, contextId);
  }

  ///@dev external functions

  function openBox(
    IMB.ICollection collection,
    uint256 contextId,
    uint256 tokenBoxId
  ) external override {
    return _openBox(collection, contextId, tokenBoxId, msg.sender);
  }

  ///@dev admin collection functions

  function createContextBox(address collection, InputBoxSeries[] calldata inputBoxes)
    external
    override
    onlyAdminCollection(collection)
    returns (uint256)
  {
    return _createContextBox(collection, inputBoxes);
  }

  function mintOneBox(
    IMB.ICollection collection,
    string calldata boxURI,
    uint256 contextId
  ) external override onlyAdminCollection(address(collection)) returns (uint256) {
    return _mintOneBox(collection, boxURI, contextId, msg.sender);
  }

  function mintOneToken(
    address collection,
    string calldata tokenURI,
    uint256 contextId,
    string calldata nameSeries
  ) external override onlyAdminCollection(collection) returns (uint256) {
    return _mintOneToken(collection, tokenURI, contextId, nameSeries, address(this));
  }

  ///@dev owner collection functions

  function setCollectionAdmin(
    address collection,
    address admin,
    bool isActive
  ) external onlyOwnerCollection(collection) {
    collectionAdmins[collection][admin] = isActive;
    emit SetCollectionAdmin(collection, admin, isActive);
  }

  ///@dev private functions

  function _openBox(
    IMB.ICollection collection,
    uint256 contextId,
    uint256 tokenBoxId,
    address recepient
  ) internal {
    ContextBox storage context = contextsBox[address(collection)][contextId];
    require(!context.entityBox[tokenBoxId].isOpen, "MB: The box is already open");
    require(collection.ownerOf(tokenBoxId) == msg.sender, "MB: You are not the owner of Box");
    collection.transferFrom(msg.sender, address(this), tokenBoxId);

    context.entityBox[tokenBoxId].isOpen = true;

    uint256 maxPercentageRandom = _getMaxPercentageRandom(address(collection), contextId);

    uint256 randomPercentage = _randomRange(1, maxPercentageRandom);
    uint256 sumPercentageOfLuck = 0;
    uint256 droppedTokenId;
    for (uint256 i = 0; i < context.seriesKeys.length; i++) {
      BoxSeries storage series = context.series[context.seriesKeys[i]];
      if (series.tokens.length == 0) continue;
      if (randomPercentage > sumPercentageOfLuck && randomPercentage <= sumPercentageOfLuck + series.probability) {
        uint256 randomItemIndex = _randomRange(0, series.tokens.length.sub(1));
        series.soldAmount = series.soldAmount.add(1);
        droppedTokenId = series.tokens[randomItemIndex];
        series.tokens.removeAtIndex(randomItemIndex);
        collection.transferFrom(address(this), recepient, droppedTokenId);
        break;
      }
      sumPercentageOfLuck = sumPercentageOfLuck + series.probability;
    }
    require(droppedTokenId != 0, "MB: No tokens available to drop");
    emit OpenBox(contextId, address(collection), tokenBoxId, droppedTokenId);
  }

  function _mintOneToken(
    address collection,
    string calldata tokenURI,
    uint256 contextId,
    string calldata nameSeries,
    address recepient
  ) internal returns (uint256) {
    require(contextsBox[address(collection)][contextId].series[nameSeries].probability != 0, "MB: series not allowed");

    uint256 tokenId = IMB.ICollection(collection).mintToken(tokenURI, recepient);
    ContextBox storage context = contextsBox[collection][contextId];
    context.countTokens = context.countTokens.add(1);

    BoxSeries storage series = context.series[nameSeries];
    series.issueAmount = series.issueAmount.add(1);
    series.tokens.push(tokenId);

    emit MintToken(contextId, collection, nameSeries, tokenId);
    return tokenId;
  }

  function _mintOneBox(
    IMB.ICollection collection,
    string calldata boxURI,
    uint256 contextId,
    address recepient
  ) internal returns (uint256) {
    ContextBox storage context = contextsBox[address(collection)][contextId];
    require(context.countBoxs < context.countTokens, "MB: Number of boxes cannot be more than tokens");
    uint256 tokenId = collection.mintToken(boxURI, recepient);
    contextsBox[address(collection)][contextId].entityBox[tokenId].isOpen = false;

    context.countBoxs = context.countBoxs.add(1);
    emit MintBox(contextId, address(collection), tokenId);
    return tokenId;
  }

  function _createContextBox(address collection, InputBoxSeries[] calldata inputBoxes) internal returns (uint256) {
    uint256 lastContextId = _getLastContextAndIncrement(collection);

    for (uint256 i = 0; i < inputBoxes.length; i++) {
      contextsBox[collection][lastContextId].series[inputBoxes[i].nameSeries].probability = inputBoxes[i].probability;
      contextsBox[collection][lastContextId].seriesKeys.push(inputBoxes[i].nameSeries);
    }
    require(_validateSeries(collection, lastContextId), "MB: Incorrect token loss percentage or series duplication.");
    emit CreateContextBox(lastContextId, collection);
    return lastContextId;
  }

  function _getMaxPercentageRandom(address collection, uint256 contextId) private view returns (uint256) {
    ContextBox storage context = contextsBox[collection][contextId];

    uint256 maxPercentageRandom;
    for (uint256 i = 0; i < context.seriesKeys.length; i++) {
      BoxSeries storage series = context.series[context.seriesKeys[i]];
      if (series.tokens.length > 0) {
        maxPercentageRandom = maxPercentageRandom.add(series.probability);
      }
    }
    return maxPercentageRandom;
  }

  function _getAllSeries(address collection, uint256 contextId) private view returns (string[] memory) {
    return contextsBox[collection][contextId].seriesKeys;
  }

  function _getBox(
    address collection,
    uint256 contextId,
    uint256 boxTokenId
  ) private view returns (Box memory) {
    return contextsBox[collection][contextId].entityBox[boxTokenId];
  }

  function _getSeries(
    address collection,
    uint256 contextId,
    string calldata series
  ) private view returns (BoxSeries memory) {
    return contextsBox[collection][contextId].series[series];
  }

  function _getLastContextAndIncrement(address collection) private returns (uint256) {
    _lastContextId[collection] = _lastContextId[collection].add(1);
    return _lastContextId[collection];
  }

  function _validateSeries(address collection, uint256 contextId) internal view returns (bool) {
    uint256 sumProbability = 0;
    ContextBox storage context = contextsBox[address(collection)][contextId];
    for (uint256 i = 0; i < context.seriesKeys.length; i++) {
      sumProbability = sumProbability.add(context.series[context.seriesKeys[i]].probability);
      require(context.series[context.seriesKeys[i]].probability != 0, "MB: Probability is not positive");
    }
    return sumProbability == 100;
  }

  function _randomRange(uint256 a, uint256 b) internal returns (uint256) {
    if (b != 0) {
      return ((_random() % b) + a);
    }
    return ((_random() % 1) + a);
  }

  function _random() internal returns (uint256) {
    _counter++;
    return
      uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, msg.sender, _counter)));
  }

  modifier onlyOwnerCollection(address collection) {
    require(IMB.ICollection(collection).owner() == msg.sender, "MB: Only owner collection");
    _;
  }

  modifier onlyAdminCollection(address collection) {
    require(
      IMB.ICollection(collection).owner() == msg.sender || collectionAdmins[address(collection)][msg.sender],
      "MB: Only admin collection or owner collection"
    );
    _;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMysteryBox {
  ///@dev global struct
  struct ContextBox {
    uint256 countBoxs;
    uint256 countTokens;
    mapping(uint256 => Box) entityBox;
    mapping(string => BoxSeries) series;
    string[] seriesKeys;
  }

  struct Box {
    bool isOpen;
    uint256 droppedTokenId;
  }

  struct BoxSeries {
    uint256 probability;
    uint256 issueAmount;
    uint256 soldAmount;
    uint256[] tokens;
  }

  struct InputBoxSeries {
    uint256 probability;
    string nameSeries;
  }

  ///@dev events
  event CreateContextBox(uint256 indexed contextId, address collection);

  event MintBox(uint256 indexed contextId, address collection, uint256 boxId);

  event MintToken(uint256 indexed contextId, address collection, string nameSeries, uint256 tokenId);

  event OpenBox(uint256 indexed contextId, address collection, uint256 boxId, uint256 droppedTokenId);

  event SetCollectionAdmin(address collection, address admin, bool isActive);

  //@dev view functions

  function getSeries(
    address collection,
    uint256 contextId,
    string calldata series
  ) external returns (BoxSeries memory);

  function getBox(
    address collection,
    uint256 contextId,
    uint256 boxTokenId
  ) external returns (Box memory);

  function getAllSeries(address collection, uint256 contextId) external view returns (string[] memory);

  ///@dev external functions

  function createContextBox(address collection, InputBoxSeries[] calldata inputBoxes) external returns (uint256);

  function mintOneBox(
    ICollection collection,
    string calldata boxURI,
    uint256 templateId
  ) external returns (uint256);

  function mintOneToken(
    address collection,
    string calldata tokenURI,
    uint256 templateId,
    string calldata nameSeries
  ) external returns (uint256);

  function openBox(
    ICollection collection,
    uint256 templateId,
    uint256 tokenBoxId
  ) external;
}

interface ICollection is IERC721 {
  function mintToken(string calldata tokenURI, address mintTo) external returns (uint256);

  function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ArrayUtils {
  /**
   * @dev Removes an element from a dynamic array at a specified index.
   * The last element of the array is moved to the position of the removed element,
   * and the array length is decreased by 1.
   * @param array The dynamic array to modify.
   * @param index The index of the element to remove.
   * @return The removed element.
   */
  function removeAtIndex(uint256[] storage array, uint256 index) internal returns (uint256) {
    require(index < array.length, "Index out of bounds");
    uint256 removed = array[index];
    uint256 last = array[array.length - 1];
    array[index] = last;
    array.pop();
    return removed;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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