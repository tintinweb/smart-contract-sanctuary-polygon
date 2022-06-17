/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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


// File contracts/modules/Math.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

/**
 * @dev This library implements auxiliary math definitions.
 */
library Math
{
	function _min(uint256 _amount1, uint256 _amount2) internal pure returns (uint256 _minAmount)
	{
		return _amount1 < _amount2 ? _amount1 : _amount2;
	}

	function _max(uint256 _amount1, uint256 _amount2) internal pure returns (uint256 _maxAmount)
	{
		return _amount1 > _amount2 ? _amount1 : _amount2;
	}

	function _sqrt(uint256 _y) internal pure returns (uint256 _z)
	{
		unchecked {
			if (_y > 3) {
				_z = _y;
				uint256 _x = _y / 2 + 1;
				while (_x < _z) {
					_z = _x;
					_x = (_y / _x + _x) / 2;
				}
				return _z;
			}
			if (_y > 0) return 1;
			return 0;
		}
	}
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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


// File contracts/modules/Transfers.sol


pragma solidity 0.8.9;


/**
 * @dev This library abstracts ERC-20 operations in the context of the current
 * contract.
 */
library Transfers
{
	using SafeERC20 for IERC20;

	/**
	 * @dev Retrieves a given ERC-20 token balance for the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @return _balance The current contract balance of the given ERC-20 token.
	 */
	function _getBalance(address _token) internal view returns (uint256 _balance)
	{
		return IERC20(_token).balanceOf(address(this));
	}

	/**
	 * @dev Allows a spender to access a given ERC-20 balance for the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @param _to The spender address.
	 * @param _amount The exact spending allowance amount.
	 */
	function _approveFunds(address _token, address _to, uint256 _amount) internal
	{
		uint256 _allowance = IERC20(_token).allowance(address(this), _to);
		if (_allowance > _amount) {
			IERC20(_token).safeDecreaseAllowance(_to, _allowance - _amount);
		}
		else
		if (_allowance < _amount) {
			IERC20(_token).safeIncreaseAllowance(_to, _amount - _allowance);
		}
	}

	/**
	 * @dev Transfer a given ERC-20 token amount into the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @param _from The source address.
	 * @param _amount The amount to be transferred.
	 */
	function _pullFunds(address _token, address _from, uint256 _amount) internal
	{
		if (_amount == 0) return;
		IERC20(_token).safeTransferFrom(_from, address(this), _amount);
	}

	/**
	 * @dev Transfer a given ERC-20 token amount from the current contract.
	 * @param _token An ERC-20 compatible token address.
	 * @param _to The target address.
	 * @param _amount The amount to be transferred.
	 */
	function _pushFunds(address _token, address _to, uint256 _amount) internal
	{
		if (_amount == 0) return;
		IERC20(_token).safeTransfer(_to, _amount);
	}
}


// File contracts/interop/UniswapV2.sol


pragma solidity 0.8.9;

/**
 * @dev Minimal set of declarations for Uniswap V2 interoperability.
 */
interface Factory
{
	function getPair(address _tokenA, address _tokenB) external view returns (address _pair);
}

interface PoolToken is IERC20
{
}

interface Pair is PoolToken
{
	function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
	function price0CumulativeLast() external view returns (uint256 _price0CumulativeLast);
	function price1CumulativeLast() external view returns (uint256 _price1CumulativeLast);
	function token0() external view returns (address _token0);
	function token1() external view returns (address _token1);
}

interface Router01
{
	function factory() external pure returns (address _factory);
	function getAmountOut(uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut) external pure returns (uint256 _amountOut);
	function getAmountsIn(uint256 _amountOut, address[] calldata _path) external view returns (uint[] memory _amounts);
	function getAmountsOut(uint256 _amountIn, address[] calldata _path) external view returns (uint[] memory _amounts);

	function addLiquidity(address _tokenA, address _tokenB, uint256 _amountADesired, uint256 _amountBDesired, uint256 _amountAMin, uint256 _amountBMin, address _to, uint256 _deadline) external returns (uint256 _amountA, uint256 _amountB, uint256 _liquidity);
	function removeLiquidity(address _tokenA, address _tokenB, uint256 _liquidity, uint256 _amountAMin, uint256 _amountBMin, address _to, uint256 _deadline) external returns (uint256 _amountA, uint256 _amountB);
	function swapTokensForExactTokens(uint256 _amountOut, uint256 _amountInMax, address[] calldata _path, address _to, uint256 _deadline) external returns (uint256[] memory _amounts);
}

interface Router02 is Router01
{
	function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external;
}


// File contracts/modules/UniswapV2ExchangeAbstraction.sol


pragma solidity 0.8.9;

/**
 * @dev This library abstracts the Uniswap V2 token conversion functionality.
 */
library UniswapV2ExchangeAbstraction
{
	/**
	 * @dev Calculates how much output to be received from the given input
	 *      when converting between two assets.
	 * @param _router The router address.
	 * @param _wtoken The wrapped token address for the network (e.g. WETH).
	 * @param _from The input asset address.
	 * @param _to The output asset address.
	 * @param _inputAmount The input asset amount to be provided.
	 * @return _outputAmount The output asset amount to be received.
	 */
	function _calcConversionFromInput(address _router, address _wtoken, address _from, address _to, uint256 _inputAmount) internal view returns (uint256 _outputAmount)
	{
		address[] memory _path = _buildPath(_from, _wtoken, _to);
		return Router02(_router).getAmountsOut(_inputAmount, _path)[_path.length - 1];
	}

	/**
	 * @dev Calculates how much input to be received the given the output
	 *      when converting between two assets.
	 * @param _router The router address.
	 * @param _wtoken The wrapped token address for the network (e.g. WETH).
	 * @param _from The input asset address.
	 * @param _to The output asset address.
	 * @param _outputAmount The output asset amount to be received.
	 * @return _inputAmount The input asset amount to be provided.
	 */
	function _calcConversionFromOutput(address _router, address _wtoken, address _from, address _to, uint256 _outputAmount) internal view returns (uint256 _inputAmount)
	{
		address[] memory _path = _buildPath(_from, _wtoken, _to);
		return Router02(_router).getAmountsIn(_outputAmount, _path)[0];
	}

	/**
	 * @dev Convert funds between two assets given the exact input amount.
	 * @param _router The router address.
	 * @param _wtoken The wrapped token address for the network (e.g. WETH).
	 * @param _from The input asset address.
	 * @param _to The output asset address.
	 * @param _inputAmount The input asset amount to be provided.
	 * @param _minOutputAmount The output asset minimum amount to be received.
	 * @return _outputAmount The output asset amount received.
	 */
	function _convertFundsFromInput(address _router, address _wtoken, address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) internal returns (uint256 _outputAmount)
	{
		address[] memory _path = _buildPath(_from, _wtoken, _to);
		Transfers._approveFunds(_from, _router, _inputAmount);
		uint256 _oldBalance = Transfers._getBalance(_path[_path.length - 1]);
		Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(_inputAmount, _minOutputAmount, _path, address(this), type(uint256).max);
		uint256 _newBalance = Transfers._getBalance(_path[_path.length - 1]);
		assert(_newBalance >= _oldBalance);
		return _newBalance - _oldBalance;
	}

	/**
	 * @dev Convert funds between two assets given the exact output amount.
	 * @param _router The router address.
	 * @param _wtoken The wrapped token address for the network (e.g. WETH).
	 * @param _from The input asset address.
	 * @param _to The output asset address.
	 * @param _outputAmount The output asset amount to be received.
	 * @param _maxInputAmount The input asset maximum amount to be provided.
	 * @return _inputAmount The input asset amount provided.
	 */
	function _convertFundsFromOutput(address _router, address _wtoken, address _from, address _to, uint256 _outputAmount, uint256 _maxInputAmount) internal returns (uint256 _inputAmount)
	{
		address[] memory _path = _buildPath(_from, _wtoken, _to);
		Transfers._approveFunds(_from, _router, _maxInputAmount);
		_inputAmount = Router02(_router).swapTokensForExactTokens(_outputAmount, _maxInputAmount, _path, address(this), type(uint256).max)[0];
		Transfers._approveFunds(_from, _router, 0);
		return _inputAmount;
	}

	/**
	 * @dev Builds a routing path for conversion possibly using an asset as intermediate.
	 * @param _from The input asset address.
	 * @param _through The middle asset address.
	 * @param _to The output asset address.
	 * @return _path The route to perform conversion.
	 */
	function _buildPath(address _from, address _through, address _to) internal pure returns (address[] memory _path)
	{
		assert(_from != _to);
		if (_from == _through || _to == _through) {
			_path = new address[](2);
			_path[0] = _from;
			_path[1] = _to;
			return _path;
		} else {
			_path = new address[](3);
			_path[0] = _from;
			_path[1] = _through;
			_path[2] = _to;
			return _path;
		}
	}
}


// File contracts/modules/UniswapV2LiquidityPoolAbstraction.sol


pragma solidity 0.8.9;


/**
 * @dev This library provides functionality to facilitate adding/removing
 * single-asset liquidity to/from a Uniswap V2 pool.
 */
library UniswapV2LiquidityPoolAbstraction
{
	/**
	 * @dev Estimates the number of LP shares to be received by a single
	 *      asset deposit into a liquidity pool.
	 * @param _router The router address.
	 * @param _pair The liquidity pool address.
	 * @param _token The ERC-20 token for the asset being deposited.
	 * @param _amount The amount to be deposited.
	 * @return _shares The expected number of LP shares to be received.
	 */
	function _calcJoinPoolFromInput(address _router, address _pair, address _token, uint256 _amount) internal view returns (uint256 _shares)
	{
		if (_amount == 0) return 0;
		address _token0 = Pair(_pair).token0();
		address _token1 = Pair(_pair).token1();
		require(_token == _token0 || _token == _token1, "invalid token");
		(uint256 _reserve0, uint256 _reserve1,) = Pair(_pair).getReserves();
		uint256 _balance = _token == _token0 ? _reserve0 : _reserve1;
		uint256 _otherBalance = _token == _token0 ? _reserve1 : _reserve0;
		uint256 _totalSupply = Pair(_pair).totalSupply();
		uint256 _swapAmount = _calcSwapOutputFromInput(_balance, _amount);
		if (_swapAmount == 0) _swapAmount = _amount / 2;
		uint256 _leftAmount = _amount - _swapAmount;
		uint256 _otherAmount = Router02(_router).getAmountOut(_swapAmount, _balance, _otherBalance);
		_shares = Math._min(_totalSupply *_leftAmount / (_balance + _swapAmount), _totalSupply * _otherAmount / (_otherBalance - _otherAmount));
		return _shares;
	}

	/**
	 * @dev Estimates the amount of tokens to be received by a single
	 *      asset withdrawal from a liquidity pool.
	 * @param _router The router address.
	 * @param _pair The liquidity pool address.
	 * @param _token The ERC-20 token for the asset being withdrawn.
	 * @param _shares The number of LP shares provided to the withdrawal.
	 * @return _amount The expected amount to be received.
	 */
	function _calcExitPoolFromInput(address _router, address _pair, address _token, uint256 _shares) internal view returns (uint256 _amount)
	{
		if (_shares == 0) return 0;
		address _token0 = Pair(_pair).token0();
		address _token1 = Pair(_pair).token1();
		require(_token == _token0 || _token == _token1, "invalid token");
		(uint256 _reserve0, uint256 _reserve1,) = Pair(_pair).getReserves();
		uint256 _balance = _token == _token0 ? _reserve0 : _reserve1;
		uint256 _otherBalance = _token == _token0 ? _reserve1 : _reserve0;
		uint256 _totalSupply = Pair(_pair).totalSupply();
		uint256 _baseAmount = _balance * _shares / _totalSupply;
		uint256 _swapAmount = _otherBalance * _shares / _totalSupply;
		uint256 _additionalAmount = Router02(_router).getAmountOut(_swapAmount, _otherBalance - _swapAmount, _balance - _baseAmount);
		_amount = _baseAmount + _additionalAmount;
		return _amount;
	}

	/**
	 * @dev Deposits a single asset into a liquidity pool.
	 * @param _router The router address.
	 * @param _pair The liquidity pool address.
	 * @param _token The ERC-20 token for the asset being deposited.
	 * @param _amount The amount to be deposited.
	 * @param _minShares The minimum number of LP shares to be received.
	 * @return _shares The actual number of LP shares received.
	 */
	function _joinPoolFromInput(address _router, address _pair, address _token, uint256 _amount, uint256 _minShares) internal returns (uint256 _shares)
	{
		if (_amount == 0) return 0;
		address _token0 = Pair(_pair).token0();
		address _token1 = Pair(_pair).token1();
		require(_token == _token0 || _token == _token1, "invalid token");
		address _otherToken = _token == _token0 ? _token1 : _token0;
		(uint256 _reserve0, uint256 _reserve1,) = Pair(_pair).getReserves();
		uint256 _swapAmount = _calcSwapOutputFromInput(_token == _token0 ? _reserve0 : _reserve1, _amount);
		if (_swapAmount == 0) _swapAmount = _amount / 2;
		uint256 _leftAmount = _amount - _swapAmount;
		Transfers._approveFunds(_token, _router, _amount);
		uint256 _otherAmount;
		{
			address[] memory _path = new address[](2);
			_path[0] = _token;
			_path[1] = _otherToken;
			uint256 _oldBalance = Transfers._getBalance(_otherToken);
			Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(_swapAmount, 1, _path, address(this), type(uint256).max);
			uint256 _newBalance = Transfers._getBalance(_otherToken);
			assert(_newBalance >= _oldBalance);
			_otherAmount = _newBalance - _oldBalance;
		}
		Transfers._approveFunds(_otherToken, _router, _otherAmount);
		(,,_shares) = Router02(_router).addLiquidity(_token, _otherToken, _leftAmount, _otherAmount, 1, 1, address(this), type(uint256).max);
		require(_shares >= _minShares, "high slippage");
		return _shares;
	}

	/**
	 * @dev Withdraws a single asset from a liquidity pool.
	 * @param _router The router address.
	 * @param _pair The liquidity pool address.
	 * @param _token The ERC-20 token for the asset being withdrawn.
	 * @param _shares The number of LP shares provided to the withdrawal.
	 * @param _minAmount The minimum amount to be received.
	 * @return _amount The actual amount received.
	 */
	function _exitPoolFromInput(address _router, address _pair, address _token, uint256 _shares, uint256 _minAmount) internal returns (uint256 _amount)
	{
		if (_shares == 0) return 0;
		address _token0 = Pair(_pair).token0();
		address _token1 = Pair(_pair).token1();
		require(_token == _token0 || _token == _token1, "invalid token");
		address _otherToken = _token == _token0 ? _token1 : _token0;
		Transfers._approveFunds(_pair, _router, _shares);
		(uint256 _baseAmount, uint256 _swapAmount) = Router02(_router).removeLiquidity(_token, _otherToken, _shares, 1, 1, address(this), type(uint256).max);
		Transfers._approveFunds(_otherToken, _router, _swapAmount);
		uint256 _additionalAmount;
		{
			address[] memory _path = new address[](2);
			_path[0] = _otherToken;
			_path[1] = _token;
			uint256 _oldBalance = Transfers._getBalance(_token);
			Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(_swapAmount, 1, _path, address(this), type(uint256).max);
			uint256 _newBalance = Transfers._getBalance(_token);
			assert(_newBalance >= _oldBalance);
			_additionalAmount = _newBalance - _oldBalance;
		}
		_amount = _baseAmount + _additionalAmount;
		require(_amount >= _minAmount, "high slippage");
		return _amount;
	}

	/**
	 * @dev Estimates the amount of tokens to be swapped in order to join
	 * the pool providing both assets.
         */
	function _calcSwapOutputFromInput(uint256 _reserveAmount, uint256 _inputAmount) private pure returns (uint256 _outputAmount)
	{
		return (Math._sqrt(_reserveAmount * (_inputAmount * 3988000 + _reserveAmount * 3988009)) - _reserveAmount * 1997) / 1994;
	}
}


// File contracts/DelayedActionGuard.sol


pragma solidity 0.8.9;

abstract contract DelayedActionGuard
{
	uint256 private constant DEFAULT_WAIT_INTERVAL = 1 days;
	uint256 private constant DEFAULT_OPEN_INTERVAL = 1 days;

	struct DelayedAction {
		uint256 release;
		uint256 expiration;
	}

	mapping (address => mapping (bytes32 => DelayedAction)) private actions_;

	modifier delayed()
	{
		bytes32 _actionId = keccak256(msg.data);
		DelayedAction storage _action = actions_[msg.sender][_actionId];
		require(_action.release <= block.timestamp && block.timestamp < _action.expiration, "invalid action");
		delete actions_[msg.sender][_actionId];
		emit ExecuteDelayedAction(msg.sender, _actionId);
		_;
	}

	function announceDelayedAction(bytes calldata _data) external
	{
		bytes4 _selector = bytes4(_data);
		bytes32 _actionId = keccak256(_data);
		(uint256 _wait, uint256 _open) = _delayedActionIntervals(_selector);
		uint256 _release = block.timestamp + _wait;
		uint256 _expiration = _release + _open;
		actions_[msg.sender][_actionId] = DelayedAction({ release: _release, expiration: _expiration });
		emit AnnounceDelayedAction(msg.sender, _actionId, _selector, _data, _release, _expiration);
	}

	function _delayedActionIntervals(bytes4 _selector) internal pure virtual returns (uint256 _wait, uint256 _open)
	{
		_selector;
		return (DEFAULT_WAIT_INTERVAL, DEFAULT_OPEN_INTERVAL);
	}

	event AnnounceDelayedAction(address indexed _sender, bytes32 indexed _actionId, bytes4 indexed _selector, bytes _data, uint256 _release, uint256 _expiration);
	event ExecuteDelayedAction(address indexed _sender, bytes32 indexed _actionId);
}


// File contracts/IExchange.sol


pragma solidity 0.8.9;

/**
 * @notice Exchange contract interface. Facilitates the conversion between assets
 *         including liquidity pool shares.
 */
interface IExchange
{
	// view functions
	function calcConversionFromInput(address _from, address _to, uint256 _inputAmount) external view returns (uint256 _outputAmount);
	function calcConversionFromOutput(address _from, address _to, uint256 _outputAmount) external view returns (uint256 _inputAmount);
	function calcJoinPoolFromInput(address _pool, address _token, uint256 _inputAmount) external view returns (uint256 _outputShares);

	// open functions
	function convertFundsFromInput(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) external returns (uint256 _outputAmount);
	function convertFundsFromOutput(address _from, address _to, uint256 _outputAmount, uint256 _maxInputAmount) external returns (uint256 _inputAmount);
	function joinPoolFromInput(address _pool, address _token, uint256 _inputAmount, uint256 _minOutputShares) external returns (uint256 _outputShares);
	function oracleAveragePriceFactorFromInput(address _from, address _to, uint256 _inputAmount) external returns (uint256 _factor);
	function oraclePoolAveragePriceFactorFromInput(address _pool, address _token, uint256 _inputAmount) external returns (uint256 _factor);
}


// File contracts/IOracle.sol


pragma solidity 0.8.9;

/**
 * @notice Oracle contract interface. Provides average prices as basis to avoid
 *         price manipulations.
 */
interface IOracle
{
	// view functions
	function consultCurrentPrice(address _pair, address _token, uint256 _amountIn) external view returns (uint256 _amountOut);
	function consultAveragePrice(address _pair, address _token, uint256 _amountIn) external view returns (uint256 _amountOut);

	// open functions
	function updateAveragePrice(address _pair) external;
}


// File contracts/Exchange.sol


pragma solidity 0.8.9;







/**
 * @notice This contract provides a helper exchange abstraction to be used by other
 *         contracts, so that it can be replaced to accomodate routing changes.
 */
contract Exchange is IExchange, Ownable, ReentrancyGuard, DelayedActionGuard
{
	address immutable public wtoken;

	address public router;
	address public oracle;
	address public treasury;

	/**
	 * @dev Constructor for this exchange contract.
	 * @param _router The Uniswap V2 compatible router address to be used for operations.
	 * @param _treasury The treasury address used to recover lost funds.
	 */
	constructor(address _wtoken, address _router, address _oracle, address _treasury)
	{
		wtoken = _wtoken;
		router = _router;
		oracle = _oracle;
		treasury = _treasury;
	}

	/**
	 * @notice Calculates how much output to be received from the given input
	 *         when converting between two assets.
	 * @param _from The input asset address.
	 * @param _to The output asset address.
	 * @param _inputAmount The input asset amount to be provided.
	 * @return _outputAmount The output asset amount to be received.
	 */
	function calcConversionFromInput(address _from, address _to, uint256 _inputAmount) external view override returns (uint256 _outputAmount)
	{
		return UniswapV2ExchangeAbstraction._calcConversionFromInput(router, wtoken, _from, _to, _inputAmount);
	}

	/**
	 * @notice Calculates how much input to be received the given the output
	 *         when converting between two assets.
	 * @param _from The input asset address.
	 * @param _to The output asset address.
	 * @param _outputAmount The output asset amount to be received.
	 * @return _inputAmount The input asset amount to be provided.
	 */
	function calcConversionFromOutput(address _from, address _to, uint256 _outputAmount) external view override returns (uint256 _inputAmount)
	{
		return UniswapV2ExchangeAbstraction._calcConversionFromOutput(router, wtoken, _from, _to, _outputAmount);
	}

	/**
	 * @dev Estimates the number of LP shares to be received by a single
	 *      asset deposit into a liquidity pool.
	 * @param _pool The liquidity pool address.
	 * @param _token The ERC-20 token for the asset being deposited.
	 * @param _inputAmount The amount to be deposited.
	 * @return _outputShares The expected number of LP shares to be received.
	 */
	function calcJoinPoolFromInput(address _pool, address _token, uint256 _inputAmount) external view override returns (uint256 _outputShares)
	{
		return UniswapV2LiquidityPoolAbstraction._calcJoinPoolFromInput(router, _pool, _token, _inputAmount);
	}

	/**
	 * @notice Convert funds between two assets given the exact input amount.
	 * @param _from The input asset address.
	 * @param _to The output asset address.
	 * @param _inputAmount The input asset amount to be provided.
	 * @param _minOutputAmount The output asset minimum amount to be received.
	 * @return _outputAmount The output asset amount received.
	 */
	function convertFundsFromInput(address _from, address _to, uint256 _inputAmount, uint256 _minOutputAmount) external override nonReentrant returns (uint256 _outputAmount)
	{
		address _sender = msg.sender;
		Transfers._pullFunds(_from, _sender, _inputAmount);
		_inputAmount = Math._min(_inputAmount, Transfers._getBalance(_from)); // deals with potential transfer tax
		_outputAmount = UniswapV2ExchangeAbstraction._convertFundsFromInput(router, wtoken, _from, _to, _inputAmount, _minOutputAmount);
		_outputAmount = Math._min(_outputAmount, Transfers._getBalance(_to)); // deals with potential transfer tax
		Transfers._pushFunds(_to, _sender, _outputAmount);
		return _outputAmount;
	}

	/**
	 * @notice Convert funds between two assets given the exact output amount.
	 * @param _from The input asset address.
	 * @param _to The output asset address.
	 * @param _outputAmount The output asset amount to be received.
	 * @param _maxInputAmount The input asset maximum amount to be provided.
	 * @return _inputAmount The input asset amount provided.
	 */
	function convertFundsFromOutput(address _from, address _to, uint256 _outputAmount, uint256 _maxInputAmount) external override nonReentrant returns (uint256 _inputAmount)
	{
		address _sender = msg.sender;
		Transfers._pullFunds(_from, _sender, _maxInputAmount);
		_maxInputAmount = Math._min(_maxInputAmount, Transfers._getBalance(_from)); // deals with potential transfer tax
		_inputAmount = UniswapV2ExchangeAbstraction._convertFundsFromOutput(router, wtoken, _from, _to, _outputAmount, _maxInputAmount);
		uint256 _refundAmount = _maxInputAmount - _inputAmount;
		_refundAmount = Math._min(_refundAmount, Transfers._getBalance(_from)); // deals with potential transfer tax
		Transfers._pushFunds(_from, _sender, _refundAmount);
		_outputAmount = Math._min(_outputAmount, Transfers._getBalance(_to)); // deals with potential transfer tax
		Transfers._pushFunds(_to, _sender, _outputAmount);
		return _inputAmount;
	}

	/**
	 * @dev Deposits a single asset into a liquidity pool.
	 * @param _pool The liquidity pool address.
	 * @param _token The ERC-20 token for the asset being deposited.
	 * @param _inputAmount The amount to be deposited.
	 * @param _minOutputShares The minimum number of LP shares to be received.
	 * @return _outputShares The actual number of LP shares received.
	 */
	function joinPoolFromInput(address _pool, address _token, uint256 _inputAmount, uint256 _minOutputShares) external override nonReentrant returns (uint256 _outputShares)
	{
		address _sender = msg.sender;
		Transfers._pullFunds(_token, _sender, _inputAmount);
		_inputAmount = Math._min(_inputAmount, Transfers._getBalance(_token)); // deals with potential transfer tax
		_outputShares = UniswapV2LiquidityPoolAbstraction._joinPoolFromInput(router, _pool, _token, _inputAmount, _minOutputShares);
		_outputShares = Math._min(_outputShares, Transfers._getBalance(_pool)); // deals with potential transfer tax
		Transfers._pushFunds(_pool, _sender, _outputShares);
		return _outputShares;
	}

	function oracleAveragePriceFactorFromInput(address _from, address _to, uint256 _inputAmount) external override returns (uint256 _factor)
	{
		require(_inputAmount > 0, "invalid amount");
		address _factory = Router02(router).factory();
		address[] memory _path = UniswapV2ExchangeAbstraction._buildPath(_from, wtoken, _to);
		_factor = 1e18;
		uint256 _amount = _inputAmount;
		for (uint256 _i = 1; _i < _path.length; _i++) {
			address _tokenA = _path[_i - 1];
			address _tokenB = _path[_i];
			address _pool = Factory(_factory).getPair(_tokenA, _tokenB);
			IOracle(oracle).updateAveragePrice(_pool);
			uint256 _averageOutputAmount = IOracle(oracle).consultAveragePrice(_pool, _tokenA, _amount);
			uint256 _currentOutputAmount = IOracle(oracle).consultCurrentPrice(_pool, _tokenA, _amount);
			_factor = _currentOutputAmount * _factor / _averageOutputAmount;
			_amount = _currentOutputAmount;
		}
		return _factor;
	}

	function oraclePoolAveragePriceFactorFromInput(address _pool, address _token, uint256 _inputAmount) external override returns (uint256 _factor)
	{
		require(_inputAmount > 0, "invalid amount");
		IOracle(oracle).updateAveragePrice(_pool);
		uint256 _averageOutputAmount = IOracle(oracle).consultAveragePrice(_pool, _token, _inputAmount);
		uint256 _currentOutputAmount = IOracle(oracle).consultCurrentPrice(_pool, _token, _inputAmount);
		_factor = _currentOutputAmount * 1e18 / _averageOutputAmount;
		return _factor;
	}

	/**
	 * @notice Allows the recovery of tokens sent by mistake to this
	 *         contract, excluding tokens relevant to its operations.
	 *         The full balance is sent to the treasury address.
	 *         This is a privileged function.
	 * @param _token The address of the token to be recovered.
	 */
	function recoverLostFunds(address _token) external onlyOwner nonReentrant delayed
	{
		uint256 _balance = Transfers._getBalance(_token);
		Transfers._pushFunds(_token, treasury, _balance);
	}

	/**
	 * @notice Updates the Uniswap V2 compatible router address.
	 *         This is a privileged function.
	 * @param _newRouter The new router address.
	 */
	function setRouter(address _newRouter) external onlyOwner delayed
	{
		require(_newRouter != address(0), "invalid address");
		address _oldRouter = router;
		router = _newRouter;
		emit ChangeRouter(_oldRouter, _newRouter);
	}

	/**
	 * @notice Updates the Uniswap V2 compatible oracle address.
	 *         This is a privileged function.
	 * @param _newOracle The new oracle address.
	 */
	function setOracle(address _newOracle) external onlyOwner delayed
	{
		require(_newOracle != address(0), "invalid address");
		address _oldOracle = oracle;
		oracle = _newOracle;
		emit ChangeOracle(_oldOracle, _newOracle);
	}

	/**
	 * @notice Updates the treasury address used to recover lost funds.
	 *         This is a privileged function.
	 * @param _newTreasury The new treasury address.
	 */
	function setTreasury(address _newTreasury) external onlyOwner delayed
	{
		require(_newTreasury != address(0), "invalid address");
		address _oldTreasury = treasury;
		treasury = _newTreasury;
		emit ChangeTreasury(_oldTreasury, _newTreasury);
	}

	// events emitted by this contract
	event ChangeRouter(address _oldRouter, address _newRouter);
	event ChangeOracle(address _oldOracle, address _newOracle);
	event ChangeTreasury(address _oldTreasury, address _newTreasury);
}


// File contracts/uniswap-lib/FullMath.sol


pragma solidity 0.8.9;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        unchecked {
        uint256 mm = mulmod(x, y, type(uint256).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
        }
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        unchecked {
        uint256 pow2 = d & (0 - d);
        d /= pow2;
        l /= pow2;
        l += h * ((0 - pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
        }
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        unchecked {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
        }
    }
}


// File contracts/uniswap-lib/Babylonian.sol



pragma solidity 0.8.9;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        unchecked {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
        }
    }
}


// File contracts/uniswap-lib/BitMath.sol


pragma solidity 0.8.9;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        unchecked {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
        }
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        unchecked {
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
        }
    }
}


// File contracts/uniswap-lib/FixedPoint.sol


pragma solidity 0.8.9;



// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        unchecked {
        return uq112x112(uint224(x) << RESOLUTION);
        }
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        unchecked {
        return uq144x112(uint256(x) << RESOLUTION);
        }
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        unchecked {
        return uint112(self._x >> RESOLUTION);
        }
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        unchecked {
        return uint144(self._x >> RESOLUTION);
        }
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        unchecked {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
        }
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        unchecked {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
        }
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        unchecked {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= type(uint112).max, 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= type(uint224).max, 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
        }
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        unchecked {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= type(uint144).max) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= type(uint224).max, 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= type(uint224).max, 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
        }
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        unchecked {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        unchecked {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
        }
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        unchecked {
        if (self._x <= type(uint144).max) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
        }
    }
}


// File contracts/Oracle.sol


pragma solidity 0.8.9;


contract Oracle is IOracle, Ownable, DelayedActionGuard
{
	using FixedPoint for FixedPoint.uq112x112;
	using FixedPoint for FixedPoint.uq144x112;

	struct PairInfo {
		bool active;
		uint256 price0CumulativeLast;
		uint256 price1CumulativeLast;
		uint32 blockTimestampLast;
		FixedPoint.uq112x112 price0Average;
		FixedPoint.uq112x112 price1Average;
		uint256 minimumInterval;
	}

	uint256 constant DEFAULT_MINIMUM_INTERVAL = 5 minutes;

	mapping(address => PairInfo) private pairInfo;

	function minimumInterval(address _pair) external view returns (uint256 _minimumInterval)
	{
		PairInfo storage _pairInfo = pairInfo[_pair];
		if (_pairInfo.minimumInterval == 0) {
			return DEFAULT_MINIMUM_INTERVAL;
		}
		return _pairInfo.minimumInterval;
	}

	function consultCurrentPrice(address _pair, address _token, uint256 _inputAmount) external view override returns (uint256 _outputAmount)
	{
		address _token0 = Pair(_pair).token0();
		address _token1 = Pair(_pair).token1();
		bool _use0 = _token == _token0;
		bool _use1 = _token == _token1;
		require(_use0 || _use1, "invalid token");
		(,,, FixedPoint.uq112x112 memory _price0Current, FixedPoint.uq112x112 memory _price1Current) = _calcCurrentPrice(_pair);
		FixedPoint.uq112x112 memory _priceCurrent = _use0 ? _price0Current : _price1Current;
		return _priceCurrent.mul(_inputAmount).decode144();
	}

	function consultAveragePrice(address _pair, address _token, uint256 _inputAmount) external view override returns (uint256 _outputAmount)
	{
		address _token0 = Pair(_pair).token0();
		address _token1 = Pair(_pair).token1();
		bool _use0 = _token == _token0;
		bool _use1 = _token == _token1;
		require(_use0 || _use1, "invalid token");
		(,,, FixedPoint.uq112x112 memory _price0Average, FixedPoint.uq112x112 memory _price1Average,) = _calcAveragePrice(_pair);
		FixedPoint.uq112x112 memory _priceAverage = _use0 ? _price0Average : _price1Average;
		return _priceAverage.mul(_inputAmount).decode144();
	}

	function updateAveragePrice(address _pair) external override
	{
		PairInfo storage _pairInfo = pairInfo[_pair];
		if (!_pairInfo.active) {
			(uint256 _price0CumulativeLast, uint256 _price1CumulativeLast, uint32 _blockTimestampLast, FixedPoint.uq112x112 memory _price0Current, FixedPoint.uq112x112 memory _price1Current) = _calcCurrentPrice(_pair);
			_pairInfo.active = true;
			_pairInfo.price0CumulativeLast = _price0CumulativeLast;
			_pairInfo.price1CumulativeLast = _price1CumulativeLast;
			_pairInfo.blockTimestampLast = _blockTimestampLast;
			_pairInfo.price0Average = _price0Current;
			_pairInfo.price1Average = _price1Current;
			if (_pairInfo.minimumInterval == 0) {
				_pairInfo.minimumInterval = DEFAULT_MINIMUM_INTERVAL;
			}
		} else {
			(uint256 _price0CumulativeLast, uint256 _price1CumulativeLast, uint32 _blockTimestampLast, FixedPoint.uq112x112 memory _price0Average, FixedPoint.uq112x112 memory _price1Average, uint32 _timeElapsed) = _calcAveragePrice(_pair);
			if (_timeElapsed >= _pairInfo.minimumInterval) {
				_pairInfo.price0CumulativeLast = _price0CumulativeLast;
				_pairInfo.price1CumulativeLast = _price1CumulativeLast;
				_pairInfo.blockTimestampLast = _blockTimestampLast;
				_pairInfo.price0Average = _price0Average;
				_pairInfo.price1Average = _price1Average;
			}
		}
	}

	function setMinimumInterval(address _pair, uint256 _newMinimumInterval) external onlyOwner delayed
	{
		require(_newMinimumInterval > 0, "invalid interval");
		PairInfo storage _pairInfo = pairInfo[_pair];
		uint256 _oldMinimumInterval = _pairInfo.minimumInterval;
		_pairInfo.minimumInterval = _newMinimumInterval;
		emit ChangeMinimumInterval(_pair, _oldMinimumInterval, _newMinimumInterval);
	}

	function _calcCurrentPrice(address _pair) internal view returns (uint256 _price0CumulativeLast, uint256 _price1CumulativeLast, uint32 _blockTimestampLast, FixedPoint.uq112x112 memory _price0Current, FixedPoint.uq112x112 memory _price1Current)
	{
		_price0CumulativeLast = Pair(_pair).price0CumulativeLast();
		_price1CumulativeLast = Pair(_pair).price1CumulativeLast();
		uint112 _reserve0;
		uint112 _reserve1;
		(_reserve0, _reserve1, _blockTimestampLast) = Pair(_pair).getReserves();
		require(_reserve0 > 0 && _reserve1 > 0, "no reserves"); // ensure that there's liquidity in the pair
		_price0Current = FixedPoint.fraction(_reserve1, _reserve0);
		_price1Current = FixedPoint.fraction(_reserve0, _reserve1);
		return (_price0CumulativeLast, _price1CumulativeLast, _blockTimestampLast, _price0Current, _price1Current);
	}

	function _calcAveragePrice(address _pair) internal view returns (uint256 _price0Cumulative, uint256 _price1Cumulative, uint32 _blockTimestamp, FixedPoint.uq112x112 memory _price0Average, FixedPoint.uq112x112 memory _price1Average, uint32 _timeElapsed)
	{
		unchecked {
		PairInfo storage _pairInfo = pairInfo[_pair];
		require(_pairInfo.active, "not active");
		uint256 _price0CumulativeLast = _pairInfo.price0CumulativeLast;
		uint256 _price1CumulativeLast = _pairInfo.price1CumulativeLast;
		uint32 _blockTimestampLast = _pairInfo.blockTimestampLast;
		FixedPoint.uq112x112 memory _price0AverageLast = _pairInfo.price0Average;
		FixedPoint.uq112x112 memory _price1AverageLast = _pairInfo.price1Average;

		// cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
		{
			_price0Cumulative = Pair(_pair).price0CumulativeLast();
			_price1Cumulative = Pair(_pair).price1CumulativeLast();
			_blockTimestamp = uint32(block.timestamp % 2 ** 32);
			(uint112 _reserve0, uint112 _reserve1, uint32 __blockTimestampLast) = Pair(_pair).getReserves();
			if (_blockTimestamp > __blockTimestampLast) {
				_timeElapsed = _blockTimestamp - __blockTimestampLast; // overflow is desired
				_price0Cumulative += uint256(FixedPoint.fraction(_reserve1, _reserve0)._x) * _timeElapsed; // overflow is desired
				_price1Cumulative += uint256(FixedPoint.fraction(_reserve0, _reserve1)._x) * _timeElapsed; // overflow is desired
			}
		}

		_price0Average = _price0AverageLast;
		_price1Average = _price1AverageLast;
		_timeElapsed = _blockTimestamp - _blockTimestampLast; // overflow is desired
		if (_timeElapsed > 0) {
			_price0Average = FixedPoint.uq112x112(uint224((_price0Cumulative - _price0CumulativeLast) / _timeElapsed)); // overflow is desired, casting never truncates
			_price1Average = FixedPoint.uq112x112(uint224((_price1Cumulative - _price1CumulativeLast) / _timeElapsed)); // overflow is desired, casting never truncates
		}
		return (_price0Cumulative, _price1Cumulative, _blockTimestamp, _price0Average, _price1Average, _timeElapsed);
		}
	}

	// events emitted by this contract
	event ChangeMinimumInterval(address indexed _pair, uint256 _oldMinimumInterval, uint256 _newMinimumInterval);
}