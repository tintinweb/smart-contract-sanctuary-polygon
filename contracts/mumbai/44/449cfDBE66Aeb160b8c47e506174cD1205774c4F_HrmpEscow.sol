/**
 *Submitted for verification at polygonscan.com on 2022-07-16
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File contracts/Address.sol



pragma solidity 0.8.2;


/**
 * Utility library of inline functions on addresses
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
	// solhint-disable-next-line no-inline-assembly
	assembly { size := extcodesize(account) }
	return size > 0;
	}

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


// File contracts/SafeERC20.sol



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
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        // functionCall(target, data, "Address: low-level call failed")
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/Ownership.sol



pragma solidity 0.8.2;

contract Ownership {

  address public owner;
  address public deputyOwner;

  event OwnershipUpdated(address oldOwner, address newOwner);
  event DeputyOwnershipUpdated(address oldDeputy, address newDeputy);

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  modifier onlyDeputyOwner() {
    require(msg.sender == owner || msg.sender == deputyOwner, "Not owner/deputy owner");
    _;
  }


  /**
   * @dev Transfer the ownership to some other address.
   * new owner can not be a zero address.
   * Only owner can call this function
   * @param _newOwner Address to which ownership is being transferred
   */
  function updateOwner(address _newOwner)
    public
    onlyOwner
  {
    require(_newOwner != address(0x0), "Invalid address");
    owner = _newOwner;
    emit OwnershipUpdated(msg.sender, owner);
  }

  /**
   * @dev Transfer the deputy ownership to some other address.
   * Only owner can call this function
   * @param _newDeputyOwner Address to which deputy ownership is being transferred
   */
  function updateDeputyOwner(address _newDeputyOwner)
    public
    onlyOwner
  {
    emit DeputyOwnershipUpdated(deputyOwner, _newDeputyOwner);
    deputyOwner = _newDeputyOwner;
  }


  /**
   * @dev Renounce the ownership.
   * This will leave the contract without any owner.
   * Only owner can call this function
   * @param _validationCode A code to prevent aaccidental calling of this function
   */
  function renounceOwnership(uint _validationCode)
    public
    onlyOwner
  {
    require(_validationCode == 123456789, "Invalid code");
    owner = address(0);
    emit OwnershipUpdated(msg.sender, owner);
  }

}


// File contracts/Escrow.sol



pragma solidity 0.8.2;



contract HrmpEscow is Ownership {

	using SafeERC20 for IERC20;
	IERC20 public hrmpContract;
	IERC20 public usdtContract;
	address public depositor;
	uint256 public totalReservedTokens;
	mapping(address => uint256) private reservedTokens;


	event Reserve(address merchant, uint256 amount);
	event Swap(address user, uint256 amount);
  event DepositorUpdated(address newDepositor, address oldDepositor);

	constructor(address hrmpTokenAddress, address usdtTokenAddress, address _depositor) {
	  owner = msg.sender;
		hrmpContract = IERC20(hrmpTokenAddress);
		usdtContract = IERC20(usdtTokenAddress);
		depositor = _depositor;
	}

	function updateDepositir(address _depositor) public onlyDeputyOwner {
		depositor = _depositor;
	}
  
  
	function reserveTokens(address merchant, uint256 amount) public onlyDeputyOwner {
		require(uint256(usdtContract.balanceOf(address(this)) + totalReservedTokens) >= amount, "Insufficient USDT balance");
		reservedTokens[merchant]  += amount;
		emit Reserve(merchant, amount);
	}


	function transferHRMP(address merchant, uint256 amount) public onlyDeputyOwner {
		require(reservedTokens[merchant] >= amount, "Insufficient reserved tokens");
		reservedTokens[merchant] -= amount;
		hrmpContract.safeTransfer(merchant, amount);
	}


	function tokenFallback(address sender, uint256 amount) public  {
		require(msg.sender == address(hrmpContract), "Only HRMP token can be received");
    if(sender != depositor) {
      usdtContract.safeTransfer(sender, amount);
		  emit Swap(sender, amount);
    }
	}
  
}