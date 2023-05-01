// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWNATIVE.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Transaction.sol";

contract ClampSwap {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address payable owner;
    uint16 fee;
    uint24 constant poolFee = 3000;

    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IWNATIVE public immutable wNative;

    struct Index {
        bool Exists;
        address[] TokenAddresses;
        uint[] TokenHoldings;
    }

    struct User {
        bool Exists;
        string UserName;
        address UserAddress;
    }

    mapping(address => bool) public definedTokens;
    mapping(address => address) public tokenToAggregator;
    mapping(address => mapping(uint => Index)) public userIndexes;
    mapping(address => mapping(address => uint))
        public reserveBaseTokenBalancesByAddress;
    mapping(address => User) public usersByAddress;
    mapping(string => User) public usersByUserName;

    event MultSwap(
        Transaction.TransactionStatus indexed status,
        address sender,
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

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT THE OWNER");
        _;
    }

    constructor(address payable _owner, uint16 _fee, address wNativeAddress) {
        owner = _owner;
        fee = _fee;
        wNative = IWNATIVE(wNativeAddress);
    }

    /********** core functions for swapping tokens to indexes ************/

    function NativeToMultiSwapWithReceiver(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint256 _amountTotal,
        address _receiver
    ) external payable {
        require(msg.value == amountWithFee(_amountTotal), "INCORRECT AMOUNT");
        totalValueCheck(_tokenAmounts, _amountTotal);
        require(
            areAddressesUniqueAndDefined(_tokenAddresses),
            "NOT DEFINED AND UNIQUE"
        );

        wNative.deposit{value: _amountTotal}();
        wNative.approve(address(swapRouter), _amountTotal);

        multiSwapHelper(
            address(wNative),
            _tokenAddresses,
            _tokenAmounts,
            _receiver
        );
    }

    // funtion for swapping IERC20 tokens to other  tokens
    // @dev need to take IERC20 token approval from user before calling this function
    // no need of amountWithFee as it is already taken from user
    function ERC20ToMultiSwapWithReceiver(
        address _tokenIn,
        address[] memory _tokenAddresses,
        uint256[] memory _tokenAmounts,
        uint256 _amount,
        address _receiver
    ) external {
        totalValueCheck(_tokenAmounts, _amount);
        require(
            areAddressesUniqueAndDefined(_tokenAddresses),
            "NOT DEFINED AND NOT UNIQUE"
        );
        // amount with fee
        uint _amountWithFee = amountWithFee(_amount);
        // Transfer IERC20 token from user to contract
        IERC20 tokenIn = IERC20(_tokenIn);
        tokenIn.safeTransferFrom(_receiver, address(this), _amountWithFee);
        // Approve router to spend IERC20 token
        tokenIn.approve(address(swapRouter), _amount);

        multiSwapHelper(_tokenIn, _tokenAddresses, _tokenAmounts, _receiver);
    }

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
                IERC20(_tokenIn).safeTransfer(_receiver, _tokenAmounts[i]);
                amountsOut[i] = _tokenAmounts[i];
            }
        }

        update(_receiver, _tokenAddresses, _tokenAmounts, amountsOut);

        emit MultSwap(
            Transaction.TransactionStatus.MultiSwap,
            msg.sender,
            _tokenAddresses,
            _tokenAmounts,
            amountsOut,
            getLatestPrice(_tokenIn)
        );
    }

    /********* Index to Token swap functions *********/
    // using this user able to swap and withdraw native token to a address
    function indexSwapToNativeWithReceiver(
        uint _indexIdentifier,
        uint _percentage,
        address _receiver
    ) external {
        uint[] memory amountsOut = internalSwapWithReceiver(
            _indexIdentifier,
            _percentage,
            address(wNative),
            _receiver
        );
        wNative.withdraw(sum(amountsOut));
    }

    // @dev need to take IERC20 token approval from user before calling this function
    // using this user able to swap and withdraw token to a address
    // if receiver was not msg.sender and it's also a clamp account then it was need to update the reserveBaseTokenBalancesByAddress
    // @note need to check for above condition
    function indexSwapToERC20WithReceiver(
        uint _indexIdentifier,
        uint _percentage,
        address _returnBaseToken,
        address _receiver
    ) external {
        uint[] memory amountsOut = internalSwapWithReceiver(
            _indexIdentifier,
            _percentage,
            _returnBaseToken,
            _receiver
        );

        if (_receiver == msg.sender) {
            reserveBaseTokenBalancesByAddress[_receiver][
                _returnBaseToken
            ] += sum(amountsOut);
        }
    }

    function internalSwapWithReceiver(
        uint _indexIdentifier,
        uint _percentage,
        address _returnBaseToken,
        address _receiver
    ) internal returns (uint[] memory amountsOut) {
        require(
            userIndexes[msg.sender][_indexIdentifier].Exists,
            "CLAMPV1: INDEX-NOT-FOUND"
        );
        require(
            _percentage > 0 && _percentage <= 1000,
            "CLAMPV1: INVALID-PERCENTAGE"
        );
        require(
            isDefinedToken(_returnBaseToken),
            "CLAMPV1: INVALID-BASE-TOKEN"
        );

        Index storage indexToUpdate = userIndexes[msg.sender][_indexIdentifier];
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
                token.safeTransferFrom(
                    msg.sender,
                    address(this),
                    swapAmounts[i]
                );
                token.safeApprove(address(swapRouter), swapAmounts[i]);

                amountsOut[i] = swapExactInputSingle(
                    _receiver,
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

        // Emit the event
        emit IntSwap(
            Transaction.TransactionStatus.InternalSwap,
            msg.sender,
            _tokenAddrs,
            amountsOut,
            swapAmounts,
            _returnBaseToken,
            getLatestPrice(_returnBaseToken)
        );
        if (msg.sender != _receiver) {
            emit ExternalSglWithdraw(
                Transaction.TransactionStatus.ExternalSingleWithdraw,
                msg.sender,
                _receiver,
                _returnBaseToken,
                sum(amountsOut),
                getLatestPrice(_returnBaseToken)
            );
        }
    }

    /*****************  Withdraw Functions  *******************/
    // @dev use this function to transfer indexes between users
    function transferIndexToAddress(
        uint _indexIdentifier,
        uint _percentage,
        address _receiver
    ) external {
        require(usersByAddress[msg.sender].Exists, "NOT A CLAMP USER");
        require(
            userIndexes[msg.sender][_indexIdentifier].Exists,
            "CLAMPV1: INDEX-NOT-FOUND"
        );
        require(
            _percentage > 0 && _percentage < 1001,
            "CLAMPV1: INVALID-PERCENTAGE"
        ); //should be greater than 5% or 10%

        Index storage indexToUpdate = userIndexes[msg.sender][_indexIdentifier];
        address[] memory _tokenAddrs = indexToUpdate.TokenAddresses;
        uint256[] memory _tokenHoldings = indexToUpdate.TokenHoldings;
        uint n = indexToUpdate.TokenHoldings.length;
        uint[] memory swapAmounts = new uint[](n);
        int[] memory _priceOfWithdrawTokens = new int[](n);

        for (uint i = 0; i < n; ) {
            swapAmounts[i] = _tokenHoldings[i].mul(_percentage).div(1000);
            IERC20 token = IERC20(_tokenAddrs[i]);
            token.safeTransferFrom(msg.sender, _receiver, swapAmounts[i]);
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

        update(_receiver, _tokenAddrs, swapAmounts, swapAmounts);

        emit ExtMulWithdraw(
            Transaction.TransactionStatus.ExternalMultiWithdraw,
            msg.sender,
            _receiver,
            _tokenAddrs,
            swapAmounts,
            _priceOfWithdrawTokens,
            _percentage
        );
    }

    // @dev need to take IERC20 token approval from user before calling this function
    // @dev you can use this function to transfer erc between accounts
    function withdrawReserveTokensToAddress(
        address _token,
        address _address,
        uint _amount
    ) external {
        require(_token != address(0), "token address cannot be 0");
        require(
            _amount <= reserveBaseTokenBalancesByAddress[msg.sender][_token],
            "amount must be less than or equal to the balance of the token"
        );
        // transfer tokens to address
        IERC20(_token).safeTransferFrom(msg.sender, _address, _amount);
        // update the balance of the token in the reserveBaseTokenBalances mapping
        reserveBaseTokenBalancesByAddress[msg.sender][_token] -= _amount;

        emit ExternalSglWithdraw(
            Transaction.TransactionStatus.ExternalSingleWithdraw,
            msg.sender,
            _address,
            _token,
            _amount,
            getLatestPrice(_token)
        );
    }

    // @dev you can use this for transfer native token between accounts
    function withdrawNativeToAddress(address _address) external payable {
        (bool sent, ) = _address.call{value: msg.value}("");
        require(sent, "Failed to send");
        emit ExternalSglWithdraw(
            Transaction.TransactionStatus.ExternalSingleWithdraw,
            msg.sender,
            _address,
            address(0),
            msg.value,
            getLatestPrice(address(wNative))
        );
    }

    /************ Owner Accessible Funtions **************/
    function ownerTransfer(address payable _owner) external onlyOwner {
        owner = _owner;
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

    function ownerWithdraw(uint256 amount) external onlyOwner {
        owner.transfer(amount);
    }

    function ownerIERC20Withdraw(
        address _token,
        uint256 amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(owner, amount);
    }

    /*************  View Functions  ***************/

    function isDefinedToken(address _tokenAddress) public view returns (bool) {
        return definedTokens[_tokenAddress];
    }

    function getAggregatorAddress(
        address _tokenAddress
    ) public view returns (address) {
        return tokenToAggregator[_tokenAddress];
    }

    function getIndex(
        uint _indexIdentifier
    ) public view returns (uint[] memory, address[] memory) {
        require(
            userIndexes[msg.sender][_indexIdentifier].Exists == true,
            "CLAMPV1: NO-INDEX-EXISTS"
        );
        return (
            userIndexes[msg.sender][_indexIdentifier].TokenHoldings,
            userIndexes[msg.sender][_indexIdentifier].TokenAddresses
        );
    }

    /******** Private Helpers ***********/

    function update(
        address _receiver,
        address[] memory _tokenAddresses,
        uint[] memory _tokenAmounts,
        uint[] memory _amountsOut
    ) private {
        sortTokens(_tokenAddresses, _tokenAmounts, _amountsOut);
        uint _indexIdentifier = uint(keccak256(abi.encode(_tokenAddresses)));
        if (userIndexes[_receiver][_indexIdentifier].Exists == true) {
            for (uint i = 0; i < _tokenAddresses.length; i++) {
                userIndexes[_receiver][_indexIdentifier].TokenHoldings[
                        i
                    ] += _amountsOut[i];
            }
        } else {
            userIndexes[_receiver][_indexIdentifier] = Index(
                true,
                _tokenAddresses,
                _amountsOut
            );
        }
    }

    function _removeIndex(uint _indexIdentifier) private {
        require(
            userIndexes[msg.sender][_indexIdentifier].Exists == true,
            "CLAMPV1: NO-INDEX-EXISTS"
        );
        delete userIndexes[msg.sender][_indexIdentifier];
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
    ) private returns (uint256 amountOut) {
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
    ) private view returns (uint256 amountOutMin) {
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
    ) private view returns (int256) {
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
    ) private pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    receive() external payable {
        if (msg.value > 0) {
            owner.transfer(msg.value);
        }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.6;

interface IWNATIVE {
    function withdraw(uint256 amount) external;

    function deposit() external payable;

    function approve(address spender, uint256 amount) external returns (bool);
}

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