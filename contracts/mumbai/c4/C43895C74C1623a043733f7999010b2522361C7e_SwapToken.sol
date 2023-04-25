// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWMATIC.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Transaction.sol";

contract SwapToken {
    using SafeMath for uint256;

    address owner;
    uint16 fee;
    uint24 constant poolFee = 3000;

    address public constant routerAddress =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public immutable _wmaticAddress;

    ISwapRouter public constant swapRouter = ISwapRouter(routerAddress);
    IWMATIC public immutable _wmatic;

    mapping(address => bool) public definedTokens;
    mapping(address => address) public tokenToAggregator;
    mapping(address => mapping(uint => Index)) public userIndexes;
    mapping(address => mapping(address => uint))
        public nativeTokenBalancesByAddress;
    mapping(address => mapping(address => uint))
        public reserveBaseTokenBalancesByAddress;

    struct Index {
        bool Exists;
        address[] TokenAddresses;
        uint[] TokenHoldings;
    }

    event MultSwap(
        Transaction.TransactionStatus indexed status,
        address[] tokenAddresses,
        uint[] amounts,
        uint[] receivedAmounts,
        int256 price
    );

    event OneToMultiSwaps(
        address _tokenIn,
        address[] _tokenAddresses,
        uint[] _tokenAmounts,
        uint[] amountsOut
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT THE OWNER");
        _;
    }

    constructor(address _owner, uint16 _fee, address payable _WMaticAddress) {
        owner = _owner;
        fee = _fee;
        _wmaticAddress = _WMaticAddress;
        _wmatic = IWMATIC(payable(_wmaticAddress));
    }

    // owner accessible functions
    function ownerTransfer(address _address) external onlyOwner {
        owner = _address;
    }

    function setFee(uint16 _fee) external onlyOwner {
        fee = _fee;
    }

    function addInDefinedToken(address _tokenAddress) external onlyOwner {
        require(!definedTokens[_tokenAddress], "CLAMP: TOKEN ADDRESS EXISTS"); // Check that the address is not already in the mapping
        definedTokens[_tokenAddress] = true; // Add the address to the mapping
    }

    function setTokenAggregators(
        address[] memory tokensArray,
        address[] memory aggregators
    ) external onlyOwner {
        require(
            tokensArray.length == aggregators.length,
            "Tokens and aggregators length mismatch"
        );
        for (uint256 i = 0; i < tokensArray.length; i++) {
            definedTokens[tokensArray[i]] = true;
            tokenToAggregator[tokensArray[i]] = aggregators[i];
        }
    }

    function removeFromDefinedToken(address _tokenAddress) external onlyOwner {
        require(
            definedTokens[_tokenAddress],
            "CLAMP: TOKEN ADDRESS DOES NOT EXISTS"
        ); // Check that the address is in the mapping
        definedTokens[_tokenAddress] = false; // Remove the address from the mapping
    }

    function ownerWithdraw() external onlyOwner {
        payable(owner).transfer((address(this)).balance);
    }

    function ownerErc20Withdraw(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, balance);
    }

    // view functions
    function isDefinedToken(address _tokenAddress) public view returns (bool) {
        return definedTokens[_tokenAddress];
    }

    function getAggregatorAddress(
        address _tokenAddress
    ) public view returns (address) {
        return tokenToAggregator[_tokenAddress];
    }

    // core functions for swapping tokens
    function MaticToMultiSwap(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint256 _amountTotal
    ) external payable {
        MaticToMultiSwapWithReceiver(
            _tokenAddresses,
            _tokenAmounts,
            _amountTotal,
            msg.sender
        );
    }

    // need receiver if we want to swap from wallet contract
    function MaticToMultiSwapWithReceiver(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint256 _amountTotal,
        address _receiver
    ) public payable {
        require(msg.value > 0, "MSG.VALUE CONDITION FAILED - 1"); //will change msg.value in future
        require(
            msg.value == amountWithFee(_amountTotal),
            "MSG.VALUE CONDITION FAILED - 2"
        );

        totalValueCheck(_tokenAmounts, _amountTotal);

        require(
            areAddressesUniqueAndDefined(_tokenAddresses),
            "NOT DEFINED AND UNIQUE"
        );

        // Convert received MATIC to WMATIC

        _wmatic.deposit{value: _amountTotal}();
        _wmatic.approve(address(routerAddress), _amountTotal);

        multiSwapHelper(
            _wmaticAddress,
            _tokenAddresses,
            _tokenAmounts,
            _receiver
        );
    }

    // funtion for swapping erc20 tokens to other  tokens
    // @dev need to take erc20 token approval from user before calling this function
    function ERC20ToMultiSwap(
        address _tokenIn,
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint256 _amountTotal,
        uint256 _amountWithFee
    ) external payable {
        ERC20ToMultiSwapWithReceiver(
            _tokenIn,
            _tokenAddresses,
            _tokenAmounts,
            _amountTotal,
            _amountWithFee,
            msg.sender
        );
    }

    // need receiver if we want to swap from wallet contract
    function ERC20ToMultiSwapWithReceiver(
        address _tokenIn,
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint256 _amountTotal,
        uint256 _amountWithFee,
        address _receiver
    ) public payable {
        require(
            _amountWithFee == amountWithFee(_amountTotal),
            "MSG.VALUE CONDITION FAILED - 2"
        );
        totalValueCheck(_tokenAmounts, _amountTotal);
        require(
            areAddressesUniqueAndDefined(_tokenAddresses),
            "NOT DEFINED AND UNIQUE"
        );
        // Transfer ERC20 token from user to contract
        IERC20 tokenIn = IERC20(_tokenIn);
        tokenIn.transferFrom(msg.sender, address(this), _amountWithFee);
        // Approve router to spend ERC20 token
        tokenIn.approve(address(routerAddress), _amountTotal);

        multiSwapHelper(_tokenIn, _tokenAddresses, _tokenAmounts, _receiver);
    }

    //HELPERS
    // Private functions
    function multiSwapHelper(
        address _tokenIn,
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        address _receiver
    ) private {
        // Determine whether token address is present in the input array
        uint256 ercIndex = type(uint256).max;
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            if (_tokenAddresses[i] == _tokenIn) {
                ercIndex = i;
                break;
            }
        }

        //SWAPPING and SAVING in amountOut
        uint[] memory amountsOut = new uint[](_tokenAddresses.length);
        for (uint i = 0; i < _tokenAddresses.length; i++) {
            if (ercIndex != i) {
                amountsOut[i] = swapExactInputSingle(
                    _receiver,
                    _tokenIn,
                    _tokenAddresses[i],
                    _tokenAmounts[i]
                );
            } else {
                IERC20(_tokenIn).transfer(_receiver, _tokenAmounts[i]);
                amountsOut[i] = _tokenAmounts[i];
            }
        }

        update(_tokenIn, _tokenAddresses, _tokenAmounts, amountsOut);

        emit OneToMultiSwaps(
            _tokenIn,
            _tokenAddresses,
            _tokenAmounts,
            amountsOut
        );
    }

    function update(
        address _tokenIn,
        address[] memory _tokenAddresses,
        uint[] memory _tokenAmounts,
        uint[] memory _amountsOut
    ) internal {
        sortTokens(_tokenAddresses, _tokenAmounts, _amountsOut);
        uint _indexIdentifier = uint(keccak256(abi.encode(_tokenAddresses)));
        if (userIndexes[msg.sender][_indexIdentifier].Exists == true) {
            for (uint i = 0; i < _tokenAddresses.length; i++) {
                userIndexes[msg.sender][_indexIdentifier].TokenHoldings[
                        i
                    ] += _amountsOut[i];
            }
        } else {
            userIndexes[msg.sender][_indexIdentifier] = Index(
                true,
                _tokenAddresses,
                _amountsOut
            );
        }
        emit MultSwap(
            Transaction.TransactionStatus.MultiSwap,
            _tokenAddresses,
            _tokenAmounts,
            _amountsOut,
            getLatestPrice(_tokenIn)
        );
    }

    function sortTokens(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint[] memory _amountsOut
    ) private pure {
        require(
            _tokenAddresses.length > 1 && _tokenAddresses.length < 16,
            "CLAMP: Index Tokens number mis-match"
        );
        for (uint i = 0; i < _tokenAddresses.length - 1; i++) {
            uint minIndex = i;
            for (uint j = i + 1; j < _tokenAddresses.length; j++) {
                if (_tokenAddresses[j] < _tokenAddresses[minIndex]) {
                    minIndex = j;
                }
            }
            if (minIndex != i) {
                (_tokenAddresses[i], _tokenAddresses[minIndex]) = (
                    _tokenAddresses[minIndex],
                    _tokenAddresses[i]
                );
                (_tokenAmounts[i], _tokenAmounts[minIndex]) = (
                    _tokenAmounts[minIndex],
                    _tokenAmounts[i]
                );
                (_amountsOut[i], _amountsOut[minIndex]) = (
                    _amountsOut[minIndex],
                    _amountsOut[i]
                );
            }
        }
    }

    function getLatestPrice(address _tokenAddress) private view returns (int) {
        require(
            isDefinedToken(_tokenAddress),
            "Token not in Defined set array"
        );
        address aggregatorAddress = getAggregatorAddress(_tokenAddress);
        require(
            aggregatorAddress != address(0),
            "Aggregator not found for the token"
        );
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            aggregatorAddress
        );
        (, int price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function areAddressesUniqueAndDefined(
        address[] memory _tokenAddresses
    ) private view returns (bool) {
        require(_tokenAddresses.length > 0, "Array must not be empty");
        require(_tokenAddresses.length <= 15, "Array size must be at most 15");
        uint256 bitfield;
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            address tokenAddress = _tokenAddresses[i];
            if (!definedTokens[tokenAddress]) {
                return false;
            }
            uint256 bit = uint256(uint160(tokenAddress)) % 256;
            if ((bitfield & (1 << bit)) > 0) {
                return false;
            }
            bitfield |= (1 << bit);
        }
        return true;
    }

    function amountWithFee(uint256 _value) private view returns (uint256) {
        // 20000000 + 3 * 20000000
        require(_value > 1000, "Value too less"); // (200000 * 3)/1000 = 600 -> 200000 + 600 = 200600
        return _value.add(_value.mul(fee).div(1000));
    }

    function totalValueCheck(
        uint256[] memory _tokenAmounts,
        uint256 _amountTotal
    ) private pure {
        uint256 total = 0;
        for (uint256 i = 0; i < _tokenAmounts.length; ) {
            total += _tokenAmounts[i];
            unchecked {
                ++i;
            }
        }
        require(total == _amountTotal, "should match but not matching");
    }

    function swapExactInputSingle(
        address _recipient,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal returns (uint256 amountOut) {
        uint256 amountOutMin = getAmountOutMin(_tokenIn, _tokenOut, _amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: _recipient,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
        return amountOut;
    }

    function getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal view returns (uint256 amountOutMin) {
        int256 price = getDerivedPrice(_tokenIn, _tokenOut, 8);
        if (price <= 0) {
            return 0;
        }
        uint256 tokenIndecimal = IERC20(_tokenIn).decimals();
        uint256 tokenOutdecimal = IERC20(_tokenOut).decimals();
        uint256 amountOut;
        if (tokenIndecimal > tokenOutdecimal) {
            amountOut =
                (uint256(price) * _amountIn) /
                10 ** ((tokenIndecimal - tokenOutdecimal) + 8);
        } else {
            amountOut =
                ((uint256(price) * _amountIn) *
                    (10 ** ((tokenOutdecimal - tokenIndecimal)))) /
                1e8;
        }
        // take care of slippage more
        // 1 % of amountOut
        uint256 slippage = (amountOut * 100) / 1000;
        amountOutMin = amountOut - slippage;
    }

    function getDerivedPrice(
        address _tokenIn,
        address _tokenOut,
        uint8 _decimals
    ) internal view returns (int256) {
        require(
            _decimals > uint8(0) && _decimals <= uint8(18),
            "Invalid _decimals"
        );
        address _base = tokenToAggregator[_tokenIn];
        address _quote = tokenToAggregator[_tokenOut];

        int256 decimals = int256(10 ** uint256(_decimals));
        (, int256 basePrice, , , ) = AggregatorV3Interface(_base)
            .latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        (, int256 quotePrice, , , ) = AggregatorV3Interface(_quote)
            .latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return (basePrice * decimals) / quotePrice;
    }

    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    //MICELLANEOUS
    receive() external payable {
        transferNativeRemainder();
    }

    function transferNativeRemainder() public payable {
        require(msg.value > 0, "Amount must be greater than zero 00");
        payable(owner).transfer(msg.value);
    }
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
pragma solidity >=0.8.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IWMATIC {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);

    fallback() external payable;

    receive() external payable;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"guy","type":"address"},{"name":"wad","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"src","type":"address"},{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"name":"wad","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"deposit","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"name":"","type":"address"},{"name":"","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"guy","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Withdrawal","type":"event"}]
*/

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library Transaction {
    enum TransactionStatus {
        MultiSwap,
        InternalSwap,
        ExternalMultiWithdraw,
        ExternalSingleWithdraw
    }
}