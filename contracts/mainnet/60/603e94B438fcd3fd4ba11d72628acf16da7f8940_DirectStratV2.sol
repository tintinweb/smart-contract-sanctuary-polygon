// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {
  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(
        clone,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )
      mstore(add(clone, 0x14), targetBytes)
      mstore(
        add(clone, 0x28),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query)
    internal
    view
    returns (bool result)
  {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(
        clone,
        0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
      )
      mstore(add(clone, 0xa), targetBytes)
      mstore(
        add(clone, 0x1e),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import './Strat.sol';
import './CloneFactory.sol';

interface IStrat {
  function swapJava(uint256 amountDlyPerSale, uint256 minUsdtToReceive)
    external
    returns (uint256 amountUsdtReceived);

  function swapPegdex(uint256 amountDlyPerSale, uint256 minUsdtToReceive)
    external
    returns (uint256 amountUsdtReceived);

  function destroy() external;

  function setAdmin(address _admin) external;
}

contract DirectStratV2 is OwnableUpgradeable, CloneFactory {
  using SafeERC20 for IERC20;

  address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
  address public constant DLYCOP = 0x1659fFb2d40DfB1671Ac226A0D9Dcc95A774521A;
  IJava public constant JAVA_VENDOR =
    IJava(0x4d4b120d144393bF1304eff6db4ad3080dBc43D6);
  IPegdex public constant PEDGEX =
    IPegdex(0x1A18cE7F608931a38c4af1Bd93c914423f26d6B4);

  uint256 public amountDlyPerSale;
  uint256 public constant MAX_DIFF = 10000;
  uint256 public minDiff;

  address public stratImpl;
  address public currentStrat;

  // EVENTS
  event SwapPeg(uint256 amount);
  event SwapJava(uint256 amount);

  function initialize(
    uint256 _amountDlyPerSale,
    uint256 _minDiff,
    address _stratImpl
  ) external initializer {
    __Ownable_init();

    amountDlyPerSale = _amountDlyPerSale;
    minDiff = _minDiff;
    stratImpl = _stratImpl;

    currentStrat = createClone(stratImpl);
    IStrat(currentStrat).setAdmin(address(this));
  }

  function formatDecimals(address token, uint256 amount)
    public
    view
    returns (uint256)
  {
    uint256 decimals = IERC20Metadata(token).decimals();

    if (decimals == 18) return amount;
    else return (amount * (1 ether)) / (10**decimals);
  }

  function getStrategyJava() internal returns (address _strat) {
    (uint256 lastSale, , ) = JAVA_VENDOR.getLastSell(currentStrat);

    // Found strategy that works
    if (block.timestamp > lastSale + 1 days) {
      _strat = currentStrat;
    }
    // If not ready, deploy a new one
    else {
      IStrat(currentStrat).destroy();
      _strat = createClone(stratImpl);
      currentStrat = _strat;
      IStrat(_strat).setAdmin(address(this));
    }
  }

  function getStrategyPegdex() internal returns (address _strat) {
    uint256 daySellLimit = PEDGEX.daySellLimit();

    (uint256 amount, ) = PEDGEX.salesInADay(currentStrat);

    // Found strategy that works
    if (amount + amountDlyPerSale < daySellLimit) {
      _strat = currentStrat;
    }
    // If not ready, deploy a new one and delete old one
    else {
      IStrat(currentStrat).destroy();
      _strat = createClone(stratImpl);
      currentStrat = _strat;
      IStrat(_strat).setAdmin(address(this));
    }
  }

  function triggerJava() external {
    uint256 copBal = IERC20(DLYCOP).balanceOf(address(this));
    require(copBal > amountDlyPerSale, 'NO DLYCOP IN CONTRACT');

    require(
      IERC20(USDT).balanceOf(address(JAVA_VENDOR)) >= 100e6,
      'NO USDT LEFT IN POOL'
    );

    address _strat = getStrategyJava();

    // Calculate Current DLYCOP price in USD
    (, int256 answer, , , ) = AggregatorV3Interface(
      0xDe6302Dfa0ac45B2B1b1a23304469DA630b2F59B
    ).latestRoundData();

    // Amount of USDT received according to price
    uint256 usdtAmountFromFeed = ((amountDlyPerSale * uint256(answer)) /
      10**8) / 10**12;

    // Min amount of USDT to receive compared to real price - a percentage
    uint256 minUsdtToReceive = (usdtAmountFromFeed * (MAX_DIFF - minDiff)) /
      MAX_DIFF;

    // Make swap in strat contract
    IERC20(DLYCOP).safeTransfer(_strat, amountDlyPerSale);
    uint256 amountUsdtReceived = IStrat(_strat).swapJava(
      amountDlyPerSale,
      minUsdtToReceive
    );

    emit SwapJava(amountUsdtReceived);
  }

  function triggerPegdex() external {
    uint256 copBal = IERC20(DLYCOP).balanceOf(address(this));
    require(copBal > amountDlyPerSale, 'NO DLYCOP IN CONTRACT');

    require(
      IERC20(USDT).balanceOf(address(PEDGEX)) >= 100e6,
      'NO USDT LEFT IN POOL'
    );

    address _strat = getStrategyPegdex();

    // Calculate Current DLYCOP price in USD
    (, int256 answer, , , ) = AggregatorV3Interface(
      0xDe6302Dfa0ac45B2B1b1a23304469DA630b2F59B
    ).latestRoundData();

    // Amount of USDT received according to price
    uint256 usdtAmountFromFeed = ((amountDlyPerSale * uint256(answer)) /
      10**8) / 10**12;

    // Min amount of USDT to receive compared to real price - a percentage
    uint256 minUsdtToReceive = (usdtAmountFromFeed * (MAX_DIFF - minDiff)) /
      MAX_DIFF;

    // Amount of USDT received in swap
    IERC20(DLYCOP).safeTransfer(_strat, amountDlyPerSale);
    uint256 amountUsdtReceived = IStrat(_strat).swapPegdex(
      amountDlyPerSale,
      minUsdtToReceive
    );

    emit SwapPeg(amountUsdtReceived);
  }

  // ADMIN FUNCTIONS
  function setMinDiff(uint256 _minDiff) external onlyOwner {
    minDiff = _minDiff;
  }

  function setDlyAmt(uint256 _amountDlyPerSale) external onlyOwner {
    amountDlyPerSale = _amountDlyPerSale;
  }

  function setImpl(address _stratImpl) external onlyOwner {
    stratImpl = _stratImpl;
  }

  function withdraw(
    IERC20 token,
    address to,
    uint256 amount
  ) external onlyOwner {
    token.safeTransfer(to, amount);
  }

  receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

interface IJava {
  function sellUSDT(uint256 tokenAmountToSell)
    external
    returns (uint256 tokenAmount);

  function getLastSell(address _a)
    external
    view
    returns (
      uint256 timestamp,
      uint8,
      uint256
    );
}

interface IPegdex {
  function swapCOPForTokens(
    address token,
    uint256 amountIn,
    uint256 minAmountOut,
    uint256 deadline
  ) external returns (uint256 amountOut);

  function daySellLimit() external view returns (uint256 limit);

  function salesInADay(address user)
    external
    view
    returns (uint256 amount, uint256 startOfDay);
}

contract Strat {
  using SafeERC20 for IERC20;

  address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
  address public constant DLYCOP = 0x1659fFb2d40DfB1671Ac226A0D9Dcc95A774521A;
  IJava public constant JAVA_VENDOR =
    IJava(0x4d4b120d144393bF1304eff6db4ad3080dBc43D6);
  IPegdex public constant PEDGEX =
    IPegdex(0x1A18cE7F608931a38c4af1Bd93c914423f26d6B4);

  uint256 public constant MAX_DIFF = 10000;

  address public admin;

  modifier onlyAdmin() {
    require(msg.sender == admin, 'NOT ADMIN');
    _;
  }

  function setAdmin(address _admin) external {
    require(admin == address(0), 'admin already set');
    admin = _admin;
  }

  function swapJava(uint256 amountDlyPerSale, uint256 minUsdtToReceive)
    external
    onlyAdmin
    returns (uint256 amountUsdtReceived)
  {
    // Amount of USDT received in swap
    IERC20(DLYCOP).safeApprove(address(JAVA_VENDOR), amountDlyPerSale);
    amountUsdtReceived = JAVA_VENDOR.sellUSDT(amountDlyPerSale);

    // Check that enough funds were sent
    require(amountUsdtReceived >= minUsdtToReceive, 'INSUFFICIENT_OUTPUT');

    // Send USDT to admin
    IERC20(USDT).safeTransfer(admin, amountUsdtReceived);
  }

  function swapPegdex(uint256 amountDlyPerSale, uint256 minUsdtToReceive)
    external
    onlyAdmin
    returns (uint256 amountUsdtReceived)
  {
    // Amount of USDT received in swap
    IERC20(DLYCOP).safeApprove(address(PEDGEX), amountDlyPerSale);
    amountUsdtReceived = PEDGEX.swapCOPForTokens(
      USDT,
      amountDlyPerSale,
      minUsdtToReceive,
      block.timestamp + 1
    );

    // Send USDT to admin
    IERC20(USDT).safeTransfer(admin, amountUsdtReceived);
  }

  function destroy() external onlyAdmin {
    selfdestruct(payable(admin));
  }
}