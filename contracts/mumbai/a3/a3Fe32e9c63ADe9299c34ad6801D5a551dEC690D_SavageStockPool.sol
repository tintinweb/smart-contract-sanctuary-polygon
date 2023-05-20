// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Operator.sol";
import "./interfaces/ISavageStock.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SavageStockPool is Operator {
    ISavageStock public stock;
    IERC20 public immutable token;

    event StockUpdated(address oldStock, address newStock);
    event Purchased(address indexed buyer, uint256 saleId, uint256 tokenId, uint256 price);
    event Deposited(address from, uint256 amount);
    event Withdrawed(address to, uint256 amount);

    constructor(address stock_, address operator_) Operator() {
        _setStock(stock_);
        setOperator(operator_);
        token = IERC20(stock.intermediateStablecoin());
    }

    function deposit(uint256 amount) external {
        address from = msg.sender;
        address stockAddress = address(stock);
        address thisAddress = address(this);
        uint256 newAllowance = token.allowance(stockAddress, thisAddress) + amount;
        token.transferFrom(from, thisAddress, amount);
        token.approve(stockAddress, newAllowance);
        emit Deposited(from, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        address to = owner();
        address stockAddress = address(stock);
        address thisAddress = address(this);
        uint256 newAllowance = token.allowance(stockAddress, thisAddress) + amount;
        token.transfer(to, amount);
        token.approve(stockAddress, newAllowance);
        emit Withdrawed(to, amount);
    }

    function buy(address buyer, uint256 saleId) external onlyOwnerOrOperator {
        ISavageStock.SaleResponse memory sale = stock.sale(saleId);
        uint256 price = sale.price;
        uint256 tokenId = sale.tokenIds[sale.tokenIds.length - 1];
        address tokenIn = address(token);
        address thisAddress = address(this);
        stock.buy(thisAddress, saleId, tokenIn, price);
        stock.nft().transferFrom(thisAddress, buyer, tokenId);
        emit Purchased(buyer, saleId, tokenId, price);
    }

    function setStock(address stock_) external onlyOwnerOrOperator {
        _setStock(stock_);
    }

    function _setStock(address stock_) private {
        address oldStock = address(stock);
        stock = ISavageStock(stock_);
        emit StockUpdated(oldStock, stock_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IStripeToken is IERC20 {
  function collateralPool() external view returns (address);
  function mint(address account, uint256 amount) external returns (bool);
  function burn(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ISavageNFT.sol";
import "./ICollateralPool.sol";
import "../dex/interfaces/IUniswapV2Router02.sol";


interface ISavageStock {

  enum SaleType { PRIMARY, SECONDARY }

  struct SavageDistribution {
    address creator;
    uint256 creatorAmount;
    address seller;
    uint256 sellerAmount;
    address systemFeeRecipient;
    uint256 systemFeeAmount;
  }

  struct Sale {
    SaleType saleType;
    address seller;
    EnumerableSet.UintSet tokenIds;
    uint256 price;
    uint256 stepPercent;
    uint256 step;
    address bidder;
    address tokenIn;
    uint256 startTimestamp;
    uint256 endTimestamp;
    bool isNative;
    bool isAuction;
    bool active;
    bool stopped;
  }

  struct SaleResponse {
    SaleType saleType;
    address seller;
    uint256[] tokenIds;
    uint256 price;
    uint256 stepPercent;
    uint256 step;
    address bidder;
    address tokenIn;
    uint256 startTimestamp;
    uint256 endTimestamp;
    bool isNative;
    bool isAuction;
    bool active;
    bool stopped;
  }

  function collateralPool() external view returns (ICollateralPool);
  function intermediateStablecoin() external view returns (address);
  function minimumPrice() external view returns (uint256);
  function nft() external view returns (ISavageNFT);
  function paymentTokens() external view returns (address[] memory);
  function paymentTokensLength() external view returns (uint256);
  function primarySaleSystemFee() external view returns (uint256);
  function router() external view returns (IUniswapV2Router02);
  function salesCount() external view returns (uint256);
  function savageDiscountPercent() external view returns (uint256);
  function savageToken() external view returns (address);
  function secondarySaleSystemFee() external view returns (uint256);
  function stripeToken() external view returns (address);
  function systemFeeRecipient() external view returns (address);
  function wrappedToken() external view returns (address);
  function isPaymentTokenExist(address token) external view returns (bool);
  function paymentToken(uint256 tokenId) external view returns (address);
  function sale(uint256 saleId) external view returns (SaleResponse memory);

  event AuctionFinished(
    uint256 saleId,
    uint256 indexed tokenId,
    address indexed caller
  );
  event Bidded(
    uint256 indexed saleId,
    uint256 indexed tokenId,
    address caller,
    address indexed bidder,
    address tokenIn,
    uint256 amountIn,
    uint256 stableAmountIn,
    bool isNative
  );
  event CollateralPoolUpdated(address collateralPool_);
  event FeeRecipientUpdated(address recipient);
  event IntermediateStablecoinUpdated(address intermediateStablecoin_);
  event MinimumPriceUpdated(uint256 minimumPrice_);
  event RouterUpdated(address router_);
  event SavageDiscountPercentUpdated(uint256 savageDiscountPercent_);
  event PaymentTokenAdded(address indexed token, address indexed sender);
  event PaymentTokenRemoved(address indexed token, address indexed sender);
  event SaleCreated(
    SaleType indexed saleType,
    address indexed seller,
    uint256[] tokenIds,
    uint256 price,
    uint256 stepPercent,
    uint256 step,
    uint256 startTimestamp,
    uint256 endTimestamp,
    bool indexed isAuction,
    uint256 saleId
  );
  event SaleStopped(uint256 saleId, address indexed sender);
  event SavageDistributed(
    uint256 indexed saleId,
    address creator,
    address seller,
    address feeRecipient,
    uint256 creatorAmount,
    uint256 sellerAmount,
    uint256 feeRecipientAmount
  );
  event Sold(
    uint256 indexed saleId,
    uint256 indexed tokenId,
    address caller,
    address indexed buyer,
    address tokenIn,
    uint256 amountIn,
    uint256 stableAmountIn,
    SavageDistribution savageDistribution
  );
  // isNative in sold 

  function addPaymentToken(address token) external returns (bool);
  function bid(address bidder, uint256 saleId) external payable returns (bool);
  function bid(address bidder, uint256 saleId, address tokenIn, uint256 amountIn) external returns (bool);
  function buy(address buyer, uint256 saleId) external payable returns (bool);
  function buy(address buyer, uint256 saleId, address tokenIn, uint256 amountIn) external returns (bool);
  function createAndSaleNFT(
    address creator,
    uint256 count,
    string memory uri,
    uint256 creatorFee,
    ISavageNFT.License license,
    bool isAuction,
    uint256 price,
    uint256 stepPercent,
    uint256 startTimestamp,
    uint256 endTimestamp
  ) external returns (uint256[] memory tokenIds, uint256 saleId);
  function finishAuction(uint256 saleId) external returns (bool);
  function removePaymentToken(address token) external returns (bool);
  function saleNFT(
    address seller,
    uint256 tokenId,
    bool isAuction,
    uint256 price,
    uint256 stepPercent,
    uint256 startTimestamp,
    uint256 endTimestamp
  ) external returns (uint256 saleId);
  function stopSale(uint256 saleId) external returns (bool);
  function updateCollateralPool(address collateralPool_) external returns (bool);
  function updateFeeRecipient(address recipient) external returns (bool);
  function updateIntermediateStablecoin(address intermediateStablecoin_) external returns (bool);
  function updateMinimumPrice(uint256 minimumPrice_) external returns (bool);
  function updatePrimarySaleSystemFee(uint256 primarySaleSystemFee_) external returns (bool);
  function updateRouter(address router_) external returns (bool);
  function updateSavageDiscountPercent(uint256 savageDiscountPercent_) external returns (bool);
  function updateSecondarySaleSystemFee(uint256 secondarySaleSystemFee_) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface ISavageNFT is IERC721 {

  enum License {
    EXCLUSIVE,
    NON_EXCLUSIVE,
    CREATIVE_COMMONS
  }

  struct Token {
    address creator;
    uint256 creatorFee;
    string uri;
    License license;
  }

  struct CollectionItem {
    uint256 id;
    uint256 copyId;
  }

  function collectionsCount() external view returns (uint256);
  function tokensCount() external view returns (uint256);
  function tokenCreator(uint256 tokenId) external view returns (address);
  function tokenCreatorFee(uint256 tokenId) external view returns (uint256);
  function tokenData(uint256 tokenId) external view returns (Token memory);
  function collection(uint256 collectionId) external view returns (CollectionItem[] memory);
  function collectionLength(uint256 collectionId) external view returns (uint256);
  function tokenLicense(uint256 tokenId) external view returns (License);

  event Minted(uint256 id, address indexed to, uint256 creatorFee, string uri);
  event CollectionMinted(CollectionItem[] tokens, address indexed to, uint256 collectionId, uint256 creatorFee, string uri);

  function mint(
    address creator,
    uint256 creatorFee,
    address to,
    uint256 count,
    string memory uri,
    License license
  ) external returns (uint256[] memory tokenIds);
  function multiApprove(address to, uint256[] memory tokenIds) external returns (bool);
  function multiTransferFrom(address from, address to, uint256[] memory tokenIds) external returns (bool);
  function multiSafeTransferFrom(address from, address to, uint256[] memory tokenIds) external returns (bool);
  function multiSafeTransferFromWithData(
    address from,
    address to,
    uint256[] memory tokenIds,
    bytes memory data
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IStripeToken.sol";
import "../dex/interfaces/IUniswapV2Router02.sol";


interface ICollateralPool {
  function inited() external view returns (bool);
  function reserve() external view returns (uint256);
  function router() external view returns (IUniswapV2Router02);
  function savage() external view returns (IERC20);
  function stable() external view returns (address);
  function stripe() external view returns (IStripeToken);
  function wrapped() external view returns (address);

  event ReserveDeposited(address indexed sender, uint256 amount);
  event ReserveWithdrawn(address indexed sender, address indexed to, uint256 amount);
  event Swapped(address indexed sender, address indexed account, uint256 stripeAmount, uint256 savageAmount);

  function depositReserve(uint256 amount) external returns (bool);
  function setContracts(
    address savage_,
    address stripe_,
    address stable_,
    address wrapped_,
    address router_
  ) external returns (bool);
  function swap(address account, uint256 amount) external returns (uint256);
  function withdrawReserve(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IUniswapV2Router01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract Operator is Ownable {
  address private _operator;

  function operator() public view virtual returns (address) {
    return _operator;
  }

  event OperatorUpdated(address operator_);

  constructor() Ownable() {
    _setOperator(_msgSender());
  }

  function setOperator(address operator_) public virtual onlyOwner returns (bool) {
    _setOperator(operator_);
    return true;
  }

  function _setOperator(address operator_) private {
    require(operator_ != address(0), "Operator is zero address");
    _operator = operator_;
    emit OperatorUpdated(operator_);
  }

  modifier onlyOperator() {
    require(_operator == _msgSender(), "Operator: caller is not operator");
    _;
  }

  modifier onlyOwnerOrOperator() {
    require(_operator == _msgSender() || owner() == _msgSender(), "Operator: caller is not operator or owner");
    _;
  }
}

// SPDX-License-Identifier: MIT

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}