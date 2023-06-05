// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

contract MegaArb {
  using Address for address;

  enum OffsetType {
    AMOUNT_IN,
    AMOUNT_OUT,
    DEADLINE
  }

  struct Offset {
    OffsetType kind;
    uint256 offset;
  }

  enum FundingType {
    BALANCE,
    TRANSFER,
    FLASHLOAN
  }

  struct Funding {
    FundingType kind;
    address source;
  }

  struct Swap {
    address tokenOut;
    address receiver;
    address[] targets;
    bytes[] data;
    bool[] needsApproval;
    bool[] returnsAmountOut;
    Offset[] offsets;
  }

  IVault private immutable _vault;
  mapping(address => bool) private _whitelisted;

  constructor() {
    _vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    _whitelisted[msg.sender] = true;
  }

  function arb(
    address _tokenIn,
    uint256 _amountIn,
    Funding calldata _funding,
    Swap[] calldata _swaps,
    address _receiver
  ) external returns (uint256 _profit) {
    require(_whitelisted[msg.sender], 'WL');
    uint256 _amountOut;
    if (_funding.kind == FundingType.FLASHLOAN) {
      bytes memory _data = abi.encode(_swaps);
      IERC20[] memory flashLoanTokens = new IERC20[](1);
      uint256[] memory flashLoanAmounts = new uint256[](1);
      flashLoanTokens[0] = IERC20(_tokenIn);
      flashLoanAmounts[0] = _amountIn;
      _vault.flashLoan(IFlashLoanRecipient(address(this)), flashLoanTokens, flashLoanAmounts, _data);
      /*
      if (!IERC3156FlashLender(_funding.source).flashLoan(this, _tokenIn, _amountIn, _data)) {
        revert('FF');
      }
      */
      _profit = _amountOut = IERC20(_swaps[_swaps.length - 1].tokenOut).balanceOf(address(this));
    } else {
      if (_funding.kind == FundingType.TRANSFER) {
        safeTransferFrom(_tokenIn, _funding.source, address(this), _amountIn);
      }
      _amountOut = _executeArb(_tokenIn, _amountIn, _swaps);
      unchecked {
        _profit = _amountOut - _amountIn;
      }
    }
    if (_amountOut > 0) {
      if (_funding.kind == FundingType.BALANCE) {
        assembly {
          mstore(0, _amountOut)
          revert(0, 0x20)
        }
      }
      safeTransfer(_tokenIn, _receiver, _amountOut);
    }
  }

  struct OptimizerStats {
    bool breakIfZero;
    bool reevaluateLeft;
    bool reevaluateRight;
    uint256 leftAmountOut;
    uint256 rightAmountOut;
    uint256 avgGas;
    uint256 gasBefore;
  }

  /**
   * @dev This function conducts a ternary search on the optimal token in amount that would yield the most output tokens.
   * The ternary search will stop when the difference between _left and _right is smaller than _precision.
   * It uses the MegaArb contract's arb function for searching optimal amounts.
   *
   * @param _tokenIn Address of the input token
   * @param _left Minimum amount of token
   * @param _right Maximum amount of token
   * @param _precision The search precision
   * @param _swaps Array of Swap instances (which define possible swap paths)
   * @return _amountIn Optimal amount of the input token
   */
  function optimize(
    address _tokenIn,
    uint256 _left,
    uint256 _right,
    uint256 _precision,
    Swap[] calldata _swaps
  ) external returns (uint256 _amountIn) {
    // Initializes a new Funding struct with default values
    Funding memory _funding = Funding({kind: FundingType.BALANCE, source: address(0)});

    // Initializes a new OptimizerStats struct with default values
    OptimizerStats memory _stats = OptimizerStats({
      breakIfZero: true,
      reevaluateLeft: true,
      reevaluateRight: true,
      leftAmountOut: 0,
      rightAmountOut: 0,
      avgGas: 0,
      gasBefore: gasleft() // Initial gas amount
    });

    // Conducts a ternary search
    while (_right - _left >= _precision) {
      uint256 _third;
      uint256 _leftThird;
      uint256 _rightThird;
      bytes memory _result;

      unchecked {
        _third = (_right - _left) / 3; // Dividing the search space into thirds
        _leftThird = _left + _third;
        _rightThird = _right - _third;
      }

      // Evaluates the left third
      if (_stats.reevaluateLeft) {
        // Calls the arb function of the MegaArb contract
        (, _result) = address(this).call(abi.encodeWithSelector(MegaArb.arb.selector, _tokenIn, _left, _funding, _swaps, address(this)));
        uint256 _leftAmountOut;
        assembly {
          if eq(mload(_result), 0x20) {
            _leftAmountOut := mload(add(_result, 0x20)) // Reading the output amount from the result
          }
        }
        _stats.leftAmountOut = _leftAmountOut;
        // If leftAmountOut is zero, it breaks the while loop and sets both _left and _right to zero
        if (_stats.breakIfZero) {
          if (_stats.leftAmountOut == 0) {
            _left = _right = 0;
            break;
          }
          _stats.breakIfZero = false;
        }
      }
      // Evaluates the right third
      if (_stats.reevaluateRight) {
        // Calls the arb function of the MegaArb contract
        (, _result) = address(this).call(abi.encodeWithSelector(MegaArb.arb.selector, _tokenIn, _right, _funding, _swaps, address(this)));
        uint256 _rightAmountOut;
        assembly {
          if eq(mload(_result), 0x20) {
            _rightAmountOut := mload(add(_result, 0x20)) // Reading the output amount from the result
          }
        }
        _stats.rightAmountOut = _rightAmountOut;
      }
      // Decides which part of the search space to evaluate next based on the outputs of the left and right thirds
      if (_stats.leftAmountOut <= _stats.rightAmountOut) {
        _left = _leftThird;
        _stats.reevaluateLeft = true;
        _stats.reevaluateRight = false;
      } else {
        _right = _rightThird;
        _stats.reevaluateLeft = false;
        _stats.reevaluateRight = true;
      }

      // Tracks the gas usage for each iteration
      uint256 _gasAfter = gasleft();
      uint256 _gasUsed;
      unchecked {
        _gasUsed = _stats.gasBefore - _gasAfter;
        _stats.avgGas = _stats.avgGas == 0 ? _gasUsed : (_stats.avgGas + _gasUsed) / 2;
        // Stops the ternary search if gas usage is too high
        if (_gasAfter < (_stats.avgGas * 2) / 3) break;
      }
    }

    // Returns the optimal amount of the input token
    assembly {
      _amountIn := shr(1, add(_left, _right))
      mstore(0, _amountIn)
      revert(0, 0x20)
    }
  }

  function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
    address tokenIn;
    address receiver;
    assembly {
      function get_address(offset) -> addr {
        addr := shr(96, calldataload(offset))
      }
      tokenIn := get_address(data.offset)
      receiver := get_address(add(data.offset, 20))
    }
    uint256 amountIn;
    uint256 amountOut;
    if (amount0Delta > 0) {
      amountIn = uint256(amount0Delta);
      amountOut = uint256(-amount1Delta);
    } else {
      amountIn = uint256(amount1Delta);
      amountOut = uint256(-amount0Delta);
    }
    IERC20(tokenIn).transfer(msg.sender, amountIn);
  }

  function receiveFlashLoan(
    IFlashLoanRecipient[] memory _tokens,
    uint256[] calldata _amounts,
    uint256[] calldata _feeAmounts,
    bytes calldata _userData
  ) external {
    require(msg.sender == address(_vault));
    onFlashLoan(address(0), address(_tokens[0]), _amounts[0], _feeAmounts[0], _userData);
  }

  function onFlashLoan(
    address /*initiator*/,
    address _token,
    uint256 _amount,
    uint256 _fee,
    bytes calldata _data
  ) public returns (bytes32 _hash) {
    // solhint-disable-next-line avoid-tx-origin
    require(_whitelisted[tx.origin], 'WL');
    Swap[] memory _swaps = abi.decode(_data, (Swap[]));
    uint256 _amountOut = _executeArb(_token, _amount, _swaps);
    uint256 _repayAmount = _amount + _fee;
    require(_amountOut >= _repayAmount, 'NP');
    uint256 _profit;
    unchecked {
      _profit = _amountOut - _amount;
    }
    safeTransfer(_token, msg.sender, _repayAmount);
    _hash = keccak256('ERC3156FlashBorrower.onFlashLoan');
  }

  function _executeArb(address _tokenIn, uint256 _amountIn, Swap[] memory _swaps) private returns (uint256 _amountOut) {
    require(msg.sender == address(this), 'NA');
    address _tokenOut = _tokenIn;
    _amountOut = _amountIn;
    uint256 _numSwaps = _swaps.length;
    for (uint256 _i; _i < _numSwaps; ) {
      (_tokenOut, _amountOut) = _executeSwap(_tokenOut, _amountOut, _swaps[_i]);
      unchecked {
        ++_i;
      }
    }
    require(_amountOut >= _amountIn, 'NP');
  }

  function _executeSwap(address _tokenIn, uint256 _amountIn, Swap memory _swap) private returns (address _tokenOut, uint256 _amountOut) {
    _tokenOut = _swap.tokenOut;
    uint256 _balanceBefore = IERC20(_tokenOut).balanceOf(_swap.receiver);
    uint256 _numSwaps = _swap.targets.length;
    for (uint256 _i; _i < _numSwaps; ) {
      address _target = _swap.targets[_i];
      bytes memory _data = _swap.data[_i];
      uint256 _numOffsets = _swap.offsets.length;
      for (uint256 _j; _j < _numOffsets; ) {
        Offset memory _offset = _swap.offsets[_j];
        OffsetType _kind = _offset.kind;
        uint256 _value;
        if (_kind == OffsetType.AMOUNT_IN) {
          _value = _amountIn;
        } else if (_kind == OffsetType.AMOUNT_OUT) {
          _value = _amountOut;
        } else if (_kind == OffsetType.DEADLINE) {
          _value = block.timestamp;
        }
        _replaceUint(_data, _offset.offset, _value);
        unchecked {
          ++_j;
        }
      }
      if (_swap.needsApproval[_i]) {
        _approveIfNeeded(_tokenIn, _target, _amountIn);
      }
      (bool _success, bytes memory _result) = _target.call(_data);
      if (_success == false) {
        assembly {
          revert(add(_result, 32), mload(_result))
        }
      }
      if (_swap.returnsAmountOut[_i]) {
        _amountOut = abi.decode(_result, (uint256));
      }
      unchecked {
        ++_i;
      }
    }
    if (_amountOut == 0) {
      _amountOut = IERC20(_tokenOut).balanceOf(_swap.receiver) - _balanceBefore;
    }
  }

  function _approveIfNeeded(address _token, address _spender, uint256 _amount) internal {
    IERC20 _erc20 = IERC20(_token);
    uint256 _allowance = _erc20.allowance(address(this), _spender);
    if (_allowance < _amount) {
      _erc20.approve(_spender, type(uint256).max);
    }
  }

  function safeTransfer(address token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(IERC20.transfer.selector, to, value));
  }

  function safeTransferFrom(address token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(address token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = token.functionCall(data, 'SafeERC20: low-level call failed');
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }

  function _replaceUint(bytes memory _data, uint256 _offset, uint256 _value) internal pure {
    assembly {
      mstore(add(add(_data, 32), _offset), _value)
    }
  }
}

interface IFlashLoanRecipient {
  /**
   * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
   *
   * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
   * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
   * Vault, or else the entire flash loan will revert.
   *
   * `userData` is the same value passed in the `IVault.flashLoan` call.
   */
  function receiveFlashLoan(IERC20[] memory tokens, uint256[] memory amounts, uint256[] memory feeAmounts, bytes memory userData) external;
}

interface IVault {
  function flashLoan(IFlashLoanRecipient recipient, IERC20[] memory tokens, uint256[] memory amounts, bytes memory userData) external;
}