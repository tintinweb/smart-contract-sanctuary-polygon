// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./libraries/Initializable.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/Transaction.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/ISwapToken.sol";
import "./interfaces/IWMATIC.sol";

contract Wallet is Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    /*
    State variables to determine the owner of the wallet
    and to assign access to only CLMAPSWAPTOKEN to invoke _update
    */
    address public Owner;
    address public CLAMPSWAPTOKEN;
    address constant wMatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    ISwapToken public SWAPTOKEN;
    /*
    Keep Track of reserveBaseTokenBalances we get after internalSwap
    */
    mapping(address => uint) public reserveBaseTokenBalances;
    /*
    Structure of Index elements
    */
    struct Index {
        bool Exists;
        address[] TokenAddresses;
        uint[] TokenHoldings;
    }
    /*
    mapping to keep account of indexIdentifiers and mapped Index
    */
    mapping(uint => Index) public userIndexes;
    /*
    Events
    */
    event MultSwap(
        Transaction.TransactionStatus indexed status,
        address sender,
        address receiver,
        address[] tokenAddresses,
        uint[] amounts,
        uint[] receivedAmounts,
        int256 price
    );
    event IntSwap(
        Transaction.TransactionStatus indexed eventType,
        address sender,
        address[] tokenAddresses,
        uint256[] receivedAmounts,
        uint256[] usedAmounts,
        address swappedTokenTo,
        int256 swappedTokenToPrice
    );
    event ExtMulWithdraw(
        Transaction.TransactionStatus indexed eventType,
        address sender,
        address receiver,
        address[] tokenAddresses,
        uint256[] amountsToEOA,
        int256[] priceOfWithdrawTokens,
        uint percentage
    );
    event ExternalSglWithdraw(
        Transaction.TransactionStatus indexed eventType,
        address sender,
        address receiver,
        address tokenAddress,
        uint256 amount,
        int256 priceOfWithdrawToken
    );

    /**************************************************************************************** MODIFIERS *********************************************************************************************/
    modifier onlyOwner() {
        require(msg.sender == Owner, "CLAMPV1: NOT-WALLET-OWNER");
        _;
    }
    modifier onlyClampContract() {
        require(msg.sender == CLAMPSWAPTOKEN, "CLAMPV1: ERROR-UPDATE");
        _;
    }

    /*************************************************************************************************************************************************************************************************/
    /*
    This fucntion is only called by SwapToken contract to update userIndexes Index values
    */
    function initialize(address _Owner) external initializer {
        Owner = _Owner;
        CLAMPSWAPTOKEN = msg.sender;
        SWAPTOKEN = ISwapToken(msg.sender);
    }

    /************************************************************************************ WALLET-FUNCTIONS ******************************************************************************************/

    /*
   _tokenAddresses is not - sorted and _tokenAmounts is mapped respectively when given as arguements
   soring is done and then IndexIdentifier is created and sorting is done with all three arrays together
   */
    function update(
        address _tokenIn,
        address[] memory _tokenAddresses,
        uint[] memory _tokenAmounts,
        uint[] memory _amountsOut
    ) external onlyClampContract {
        sortTokens(_tokenAddresses, _tokenAmounts, _amountsOut);
        uint _indexIdentifier = uint(keccak256(abi.encode(_tokenAddresses)));
        if (userIndexes[_indexIdentifier].Exists == true) {
            for (uint i = 0; i < _tokenAddresses.length; i++) {
                userIndexes[_indexIdentifier].TokenHoldings[i] += _amountsOut[
                    i
                ];
            }
        } else {
            userIndexes[_indexIdentifier] = Index(
                true,
                _tokenAddresses,
                _amountsOut
            );
        }
        emit MultSwap(
            Transaction.TransactionStatus.MultiSwap,
            Owner,
            address(this),
            _tokenAddresses,
            _tokenAmounts,
            _amountsOut,
            getLatestPrice(_tokenIn)
        );
    }

    /*
    function used for SWAP to Wallet-Contract functionality on sell-side with PERCENTAGE enabled
    _percentage should be in 1 Decimal place ex: 50%  means 500 should be given
    */

    function internalSwapToMatic(
        uint _indexIdentifier,
        uint _percentage
    ) external onlyOwner {
        uint[] memory amountsOut = internalSwap(
            _indexIdentifier,
            _percentage,
            wMatic
        );
        IWMATIC(payable(wMatic)).withdraw(sum(amountsOut));
    }

    function internalSwapToERC20(
        uint _indexIdentifier,
        uint _percentage,
        address _returnBaseToken
    ) external onlyOwner {
        uint[] memory amountsOut = internalSwap(
            _indexIdentifier,
            _percentage,
            _returnBaseToken
        );
        // Update the reserveBaseTokenBalances
        reserveBaseTokenBalances[_returnBaseToken] += sum(amountsOut);
    }

    function internalSwap(
        uint _indexIdentifier,
        uint _percentage,
        address _returnBaseToken
    ) internal returns (uint[] memory amountsOut) {
        require(
            userIndexes[_indexIdentifier].Exists,
            "CLAMPV1: INDEX-NOT-FOUND"
        );
        require(
            _percentage > 0 && _percentage <= 1000,
            "CLAMPV1: INVALID-PERCENTAGE"
        );
        require(
            SWAPTOKEN.isDefinedToken(_returnBaseToken),
            "CLAMPV1: INVALID-BASE-TOKEN"
        );

        Index storage indexToUpdate = userIndexes[_indexIdentifier];
        address[] memory _tokenAddrs = indexToUpdate.TokenAddresses;
        uint[] memory _tokenHoldings = indexToUpdate.TokenHoldings;
        uint n = indexToUpdate.TokenHoldings.length;
        uint[] memory swapAmounts = new uint[](n);
        amountsOut = new uint[](n);

        for (uint i = 0; i < n; ) {
            swapAmounts[i] = _tokenHoldings[i].mul(_percentage).div(1000);

            if (_tokenAddrs[i] == _returnBaseToken) {
                amountsOut[i] = swapAmounts[i];
            } else {
                IERC20 token = IERC20(_tokenAddrs[i]);
                token.approve(address(routerAddress), swapAmounts[i]);

                amountsOut[i] = swapExactInputSingle(
                    _returnBaseToken,
                    _tokenAddrs[i],
                    swapAmounts[i]
                );
            }
            unchecked {
                ++i;
            }
        }

        if (_percentage == 1000) {
            _removeIndex(_indexIdentifier);
        } else {
            for (uint i = 0; i < n; ) {
                indexToUpdate.TokenHoldings[i] -= swapAmounts[i];
                unchecked {
                    ++i;
                }
            }
        }

        // Get the price of the swapped token from Chainlink
        int256 swappedTokenPrice = getLatestPrice(_returnBaseToken);
        // Emit the event
        emit IntSwap(
            Transaction.TransactionStatus.InternalSwap,
            address(this),
            _tokenAddrs,
            amountsOut,
            swapAmounts,
            _returnBaseToken,
            swappedTokenPrice
        );
    }

    /*
    function used for WIDTHRAW to EOA functionality on sell-side with PERCENTAGE enabled
    */
    function externalMultiWithdraw(
        uint _indexIdentifier,
        uint _percentage
    ) external onlyOwner {
        require(
            userIndexes[_indexIdentifier].Exists,
            "CLAMPV1: INDEX-NOT-FOUND"
        );
        require(
            _percentage > 0 && _percentage < 1001,
            "CLAMPV1: INVALID-PERCENTAGE"
        ); //should be greater than 5% or 10%

        Index storage indexToUpdate = userIndexes[_indexIdentifier];
        address[] memory _tokenAddrs = indexToUpdate.TokenAddresses;
        uint256[] memory _tokenHoldings = indexToUpdate.TokenHoldings;
        uint n = indexToUpdate.TokenHoldings.length;
        uint[] memory swapAmounts = new uint[](n);
        int[] memory _priceOfWithdrawTokens = new int[](n);

        for (uint i = 0; i < n; ) {
            swapAmounts[i] = _tokenHoldings[i].mul(_percentage).div(1000);
            IERC20 token = IERC20(_tokenAddrs[i]);
            token.safeTransfer(Owner, swapAmounts[i]);
            _priceOfWithdrawTokens[i] = getLatestPrice(_tokenAddrs[i]);
            unchecked {
                ++i;
            }
        }

        if (_percentage == 1000) {
            _removeIndex(_indexIdentifier);
        } else {
            for (uint i = 0; i < n; ) {
                indexToUpdate.TokenHoldings[i] -= swapAmounts[i];
                unchecked {
                    ++i;
                }
            }
        }

        emit ExtMulWithdraw(
            Transaction.TransactionStatus.ExternalMultiWithdraw,
            address(this),
            Owner,
            _tokenAddrs,
            swapAmounts,
            _priceOfWithdrawTokens,
            _percentage
        );
    }

    /*
    used by wallet owner to take out reserveTokens after interSwap
    */
    // note : pass the owner address in _address in frontend to withdraw matic to owner address
    //so that we can use the below function for transferring tokens to between address
    function withdrawReserveBaseTokens(
        address _token,
        address _address,
        uint _amount
    ) external onlyOwner {
        require(_token != address(0), "token address cannot be 0");
        require(
            _amount <= reserveBaseTokenBalances[_token],
            "amount must be less than or equal to the balance of the token"
        );
        // transfer tokens to owner
        IERC20(_token).safeTransfer(_address, _amount);
        // update the balance of the token in the reserveBaseTokenBalances mapping
        reserveBaseTokenBalances[_token] -= _amount;

        emit ExternalSglWithdraw(
            Transaction.TransactionStatus.ExternalSingleWithdraw,
            address(this),
            _address,
            _token,
            _amount,
            getLatestPrice(_token)
        );
    }

    // note : pass the owner address in _address in frontend to withdraw matic to owner address
    function withdrawMaticToAddress(
        uint256 _amount,
        address _address
    ) external onlyOwner {
        require(
            _amount <= address(this).balance,
            "amount must be less than or equal to the balance of the token"
        );
        // transfer tokens to owner
        payable(_address).transfer(_amount);

        emit ExternalSglWithdraw(
            Transaction.TransactionStatus.ExternalSingleWithdraw,
            address(this),
            _address,
            address(0),
            _amount,
            getLatestPrice(wMatic)
        );
    }

    // funtion to swap reserveBaseToken to a Index
    function swapReserveToIndex(
        address _tokenIn,
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint256 _amountTotal,
        uint256 _amountWithFee
    ) external onlyOwner {
        IERC20(_tokenIn).approve(address(SWAPTOKEN), _amountWithFee);
        SWAPTOKEN.ERC20ToMultiSwapWithReceiver(
            _tokenIn,
            _tokenAddresses,
            _tokenAmounts,
            _amountTotal,
            _amountWithFee,
            msg.sender
        );
    }

    function swapMaticToIndex(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint256 _amountTotal,
        uint256 _amountWithFee
    ) external payable onlyOwner {
        SWAPTOKEN.MaticToMultiSwapWithReceiver{value: _amountWithFee}(
            _tokenAddresses,
            _tokenAmounts,
            _amountTotal,
            msg.sender
        );
    }

    /************************************************************************************************************************************************************************************************/
    /******************************************************************************************* HELPERS ********************************************************************************************/
    function _removeIndex(uint _indexIdentifier) private {
        require(
            userIndexes[_indexIdentifier].Exists == true,
            "CLAMPV1: NO-INDEX-EXISTS"
        );
        delete userIndexes[_indexIdentifier];
    }

    function getIndex(
        uint _indexIdentifier
    ) public view returns (uint[] memory, address[] memory) {
        require(
            userIndexes[_indexIdentifier].Exists == true,
            "CLAMPV1: NO-INDEX-EXISTS"
        );
        return (
            userIndexes[_indexIdentifier].TokenHoldings,
            userIndexes[_indexIdentifier].TokenAddresses
        );
    }

    function sum(uint[] memory arr) private pure returns (uint result) {
        uint length = arr.length;
        for (uint i = 0; i < length; ) {
            result += arr[i];
            unchecked {
                ++i;
            }
        }
    }

    function getLatestPrice(address _tokenAddress) private view returns (int) {
        require(
            SWAPTOKEN.isDefinedToken(_tokenAddress),
            "Token not in Defined set array"
        );
        address aggregatorAddress = SWAPTOKEN.getAggregatorAddress(
            _tokenAddress
        );
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

    function multicall(
        bytes[] memory data
    ) public returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            results[i] = result;
        }
        return results;
    }

    function sortTokens(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint[] memory _amountsOut
    ) private pure {
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

    /************************************************************************************************************************************************************************************************/
    /************************************************************************************ UNISWAP-CODE **********************************************************************************************/
    address constant routerAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);
    uint24 constant poolFee = 3000;

    //amountIn should be in terms of the token from which we are swapping
    function swapExactInputSingle(
        address _returnBaseToken,
        address _tokenIn,
        uint256 _amountIn
    ) internal returns (uint256 amountOut) {
        uint256 amountOutMin = getAmountOutMin(
            _tokenIn,
            _returnBaseToken,
            _amountIn
        );
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _returnBaseToken,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 60,
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
    ) public view returns (uint256 amountOutMin) {
        int256 price = getDerivedPrice(_tokenIn, _tokenOut, 8);
        if (price <= 0) {
            revert("CLAMPV1: INVALID-ORACLE-PRICE");
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
        uint256 slippage = (amountOut * 5) / 100;
        amountOutMin = amountOut - slippage;
    }

    function getDerivedPrice(
        address _tokenIn,
        address _tokenOut,
        uint8 _decimals
    ) public view returns (int256) {
        require(
            _decimals > uint8(0) && _decimals <= uint8(18),
            "CLAMPV1: INVALID-DECIMALS"
        );
        address _base = SWAPTOKEN.getAggregatorAddress(_tokenIn);
        address _quote = SWAPTOKEN.getAggregatorAddress(_tokenOut);

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

    receive() external payable {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

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
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

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
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

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
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ISwapToken {
    function routerAddress() external view returns (address);

    function isDefinedToken(address _address) external view returns (bool);

    function getAggregatorAddress(
        address tokenAddress
    ) external view returns (address);

    function MaticToMultiSwapWithReceiver(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint256 _amountTotal,
        address _receiver
    ) external payable;

    function ERC20ToMultiSwapWithReceiver(
        address _tokenIn,
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint256 _amountTotal,
        uint256 _amountWithFee,
        address _receiver
    ) external payable;

    function swapExactInputSingle(
        address _recipient,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external returns (uint256 amountOut);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "./Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Permit.sol";
import "./Address.sol";

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
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