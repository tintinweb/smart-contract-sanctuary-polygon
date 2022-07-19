/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

// Sources flattened with hardhat v2.9.7 https://hardhat.org

// File blk-smart-contract-master/Address.sol

// SPDX-License-Identifier: MIT

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


// File blk-smart-contract-master/IERC20.sol



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


// File blk-smart-contract-master/Ownership.sol



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


// File blk-smart-contract-master/Freezable.sol



pragma solidity 0.8.2;

contract Freezable is Ownership {
    
    mapping (address => bool) private frozen;
    bool public emergencyFreeze = false;

    event Freezed(address targetAddress, bool isFreezed);
    event EmerygencyFreezed(bool isFreezed);

    /**
      * @dev Modifier to check if an accout is unfreezed
     */
    modifier unfreezed(address account) { 
        require(!frozen[account]);
        _;  
    }
    
    /**
      * @dev Modifier to check if the smart contract is unfreezed
     */
    modifier noEmergencyFreeze() { 
        require(!emergencyFreeze);
        _; 
    }

    /**
     * @dev Freezes the `account` if `shouldFreeze` is true 
     * Unfreezes the `account` if `shouldFreeze` is true
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Freezed} event.
     */
    function freezeAccount (address account, bool shouldFreeze) public onlyOwner returns(bool) {
        frozen[account] = shouldFreeze;
        emit Freezed(account, shouldFreeze);
        return true;
    }

    // ------------------------------------------------------------------------
    // Emerygency freeze - onlyOwner
    // ------------------------------------------------------------------------
    /**
     * @dev Freezes the whole contract if `shouldFreeze` is  true.
     * Unfreezes if `shouldFreeze` is false.
     *
     * Emits a {EmerygencyFreezed} event.
     */
    function emergencyFreezeAllAccounts (bool shouldFreeze) public onlyOwner returns(bool) {
        emergencyFreeze = shouldFreeze;
        emit EmerygencyFreezed(shouldFreeze);
        return true;
    }

    // ------------------------------------------------------------------------
    // Get Freeze Status : view
    // ------------------------------------------------------------------------
     /**
     * @dev Returns the freeze status of `account`.
     */
    function isFreezed(address account) public view returns (bool) {
        return frozen[account]; 
    }

}


// File blk-smart-contract-master/CustomERC20.sol



pragma solidity 0.8.2;



interface TokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; 
  function tokenFallback(address _from, uint256 _value) external;
}

/**
  * @dev Implementation of the {IERC20} interface.
 */
contract HRMP is IERC20, Freezable {

  using Address for address;

  /**
    * @dev State variable declaration
   */
  string public name;
  string public symbol;
  uint256 public decimals;
  uint256 private _totalSupply;

  mapping (address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;
  mapping (address => bool) public trustedContracts;
  
  event TrustedContractUpdate(address _contractAddress, bool _added);

  constructor (address _owner){
    owner = _owner;
    name = "HRM Processing";
    symbol = "HRMP";
    decimals = 6;
    _totalSupply = 1000000000 * (10 ** decimals);
    _mintInitialSupply(_owner, _totalSupply);
  }

  function _mintInitialSupply(address user, uint256 amount) internal {
    balances[user] = balances[user] + amount;
    emit Transfer(address(0), user, amount);
    notifyTrustedContract(address(0), user, amount);
  }

  /**
    * @dev Modifier to revert for zero address
   */
  modifier onlyNonZeroAddress(address account) {
    require(account != address(0), "Zero address not allowed");
    _;
  }

  /**
    * @dev See {IERC20-allowance}.
    */
  function allowance(address owner, address spender) public override view returns (uint256 remaining) {
    return allowed[owner][spender];
  }

  /**
    * @dev See {IERC20-balanceOf}.
    */
  function balanceOf(address accouny) public override view returns (uint256 balance) {
    return balances[accouny];
  }
  
  
  /**
    * @dev See {IERC20-totalSupply}.
    */
  function totalSupply() public override view returns (uint256 remaining) {
    return _totalSupply;
  }


  /**
    * @dev See {IERC20-transfer}.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    * - the caller must not be freezed.
    * - the recipient must not be freezed.
    * - contract must not be freezed.
   */
  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /**
    * @dev See {IERC20-transfer}.
    * Bulk action for transfer tokens
    * Requirements:
    *
    * - number of `recipients` and number of `amounts` must match
    * - the caller must have a balance of at least sum of `amounts`.
    * - the caller must not be freezed.
    * - the recipients must not be freezed.
    * - contract must not be freezed.
   */
  function bulkTransfer (address[] memory recipients, uint256[] memory amounts) public returns (bool) {
    require(recipients.length == amounts.length, "Invalid length");
    for(uint256 i = 0 ; i < recipients.length; i++){
      _transfer(msg.sender, recipients[i], amounts[i]);
    }
    return true;
  }

  /**
    * @dev See {IERC20-transferFrom}.
    *
    * Requirements:
    *
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - the caller must have allowance for ``sender``'s tokens of at least `amount`.
    * - the caller must not be freezed.
    * - the recipient must not be freezed.
    * - contract must not be freezed.
    */
  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    require(amount <= allowed[sender][msg.sender], "Insufficient allowance");
    allowed[sender][msg.sender] = allowed[sender][msg.sender] - amount;
    _transfer(sender, recipient, amount);
    return true;
  }

  /**
    * @dev See {IERC20-approve}.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
  function approve(address spender, uint256 amount) public override returns (bool) {
    return _approve(msg.sender, spender, amount);
  }

  /**
    * @dev Atomically increases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {IERC20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    * - the caller must not be freezed.
    * - the recipient must not be freezed.
    * - contract must not be freezed.
    */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    return _approve(msg.sender, spender, allowed[msg.sender][spender] + addedValue);
  }

  /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least `subtractedValue`.
     * - the caller must not be freezed.
     * - the recipient must not be freezed.
     * - contract must not be freezed.
     */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    uint256 _value = allowed[msg.sender][spender] - subtractedValue;
    if (subtractedValue > _value) {
      _value = 0;
    }
    return _approve(msg.sender, spender, _value);
  }

  

  function addTrustedContracts(address _contractAddress, bool _isActive)
    public
    onlyOwner
  {
    require(_contractAddress.isContract(), "Only contract address can be added");
    trustedContracts[_contractAddress] = _isActive;
    emit TrustedContractUpdate(_contractAddress, _isActive);
  }

  /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     * Calls `tokenFallback` function if recipeitn is a trusted contract address
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least `amount`.
     * - the caller must not be freezed.
     * - the recipient must not be freezed.
     * - contract must not be freezed.
     */
  function _transfer(address sender, address recipient, uint256 amount)
    unfreezed(recipient)
    unfreezed(sender)
    noEmergencyFreeze
    onlyNonZeroAddress(recipient)
    internal returns (bool) 
  {
    require(balances[sender] >= amount, "Insufficient funds");
    balances[sender] = balances[sender] - amount;
    balances[recipient] = balances[recipient] + amount;
    emit Transfer(sender, recipient, amount);
    notifyTrustedContract(sender, recipient, amount);
    return true;
  }

  /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
    *
    * This internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    * - `owner` can not be freezed
    * - `spender` can not be freezed
    * - contract can not be freezed
    */
  function _approve(address owner, address spender, uint256 amount)
    unfreezed(owner)
    unfreezed(spender)
    noEmergencyFreeze
    onlyNonZeroAddress(spender)
    internal returns(bool)
  {
    allowed[owner][spender] = amount;
    emit Approval(owner, spender, amount);
    return true;
  }


  /**
    * @dev Notifier trusted contracts when tokens are transferred to them
    *
    * Requirements:
    *
    * - `recipient` must be a trusted contract.
    * - `recipient` must implement `tokenFallback` function
    */
  function notifyTrustedContract(address sender, address recipient, uint256 amount) internal {
    // if the contract is trusted, notify it about the transfer
    if(trustedContracts[recipient]) {
      TokenRecipient trustedContract = TokenRecipient(recipient);
      trustedContract.tokenFallback(sender, amount);
    }
  }

  /**
    * @dev Owner can transfer any ERC20 compitable tokens send to this contract
    *
    */
  function transferAnyERC20Token(address _tokenAddress, uint256 _value) public onlyOwner returns (bool) {
      return IERC20(_tokenAddress).transfer(owner, _value);
  }
}