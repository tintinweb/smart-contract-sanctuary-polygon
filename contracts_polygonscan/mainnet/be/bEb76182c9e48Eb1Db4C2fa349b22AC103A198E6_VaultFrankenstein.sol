/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
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
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
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
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IStrategy {
    function liquidityRouter() external view returns (address);
    function lpToken() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function farm() external view returns (address);
    function pid() external view returns (uint256);
    function totalCapital() external view returns (uint256);
    function totalLP() external view returns (uint256);
    function getPendingYel(address) external view returns (uint256);
    function claimYel(address) external;
    function requestWithdraw(address, uint256) external;
    function withdrawUSDTFee(address) external;
    function autoCompound() external;
    function updateTotalCapital() external;
    function deposit() external payable;
    function depositAsMigrate(uint256) external;
    function migrate(uint256) external;
}

contract VaultFrankenstein is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

	mapping(address => uint256) private requestBlock;
    mapping(uint256 => bool) private nameExist;
    mapping(uint256 => address) public strategies;
    mapping(address => bool) public strategyExist;

    uint256 public constant REQUIRED_NUMBER_OF_BLOCKS = 10;
    uint256 public depositLimit;
    address public government;
    address public constant WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    uint256[] private names;
	
    event DepositToVault(uint256 amount);
    event RequestYelFromStrategies();
    event PartialMigrate(uint256 amount);
    event Migrate(uint256 amount);

    modifier onlyOwnerOrGovernment() {
        require(
            owner() == _msgSender() || government == _msgSender(),
            "Ownable: caller is not the owner or government"
        );
        _;
    }

    modifier whenNotBlocked() {
    	uint256 currentBlock = block.number;
    	if(requestBlock[msg.sender] == 0) {
    		_;
    		requestBlock[msg.sender] = currentBlock;
    	} else {
    		if(_isNotBlockedByTime()) {
    			_;
    			requestBlock[msg.sender] = currentBlock;
    		} else {
    			revert("The contract is blocked. Difference of blocks is less then REQUIRED_NUMBER_OF_BLOCKS");
    		}
    	}
   	}

    modifier notBlocked() {
    	_checkBlockedByTime();
    	_;
    }

    function _isNotBlockedByTime() internal view returns (bool) {
    	uint256 currentBlock = block.number;
		return true ? currentBlock - requestBlock[msg.sender] >= REQUIRED_NUMBER_OF_BLOCKS : false;
    }

    function _checkBlockedByTime() internal view {
    	require(
    		_isNotBlockedByTime(),
    		"The contract is blocked. Difference of blocks is less then REQUIRED_NUMBER_OF_BLOCKS"
    	);
    }

    constructor(string memory name__, string memory symbol__) ERC20(name__, symbol__) {
    	depositLimit = 1000 * 10 ** 18;
    	government = 0x0C64Ee4d4Ed50293B6709b1fcEa12c0D7CAD88d2;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
    	require(msg.value != 0, "The number of funds can not be zero value");
        autoCompound();
        _checkDeposit(getTotalCapital(), msg.value);
        require(names.length != 0, "There is no strategy");
        IStrategy(getCurrentStrategy()).deposit{value: msg.value}();
        IStrategy(getCurrentStrategy()).updateTotalCapital();
        uint256 percent = (msg.value * 100 * 1000) / getTotalCapital();
        require(percent > 0, "Percent can not be zero, try to deposit more");
        uint256 shares = percent * getTotalCapital() / 1000;
        require(shares > 0, "Shares can not be zero, try to deposit more");
        _mint(msg.sender, shares);
        emit DepositToVault(msg.value);
    }

    function requestWithdraw(uint256 _shares) public whenNotBlocked {
    	require(names.length != 0, "There is no strategy");
        require(totalSupply() != 0, "Total share value is zero");
        require(_shares > 0, "Amount of shares can not be a zero value");
        autoCompound();
        uint256 percent = _shares * 100 * 10**12 / totalSupply();
        require(percent <= 100 * 10**12, "Percent can not be more then 100");
        _burn(msg.sender, _shares);
        _requestYelFromStrategies(msg.sender, percent);
        emit RequestYelFromStrategies();
    }

    function claimYel() public notBlocked {
    	uint256 _YELamount = 0;
    	for (uint256 i; i < names.length; i++) {
    		_YELamount = IStrategy(strategies[names[i]]).getPendingYel(msg.sender);
    		if(_YELamount > 0) {
    			IStrategy(strategies[names[i]]).claimYel(msg.sender);
    		}
        }
        require(_YELamount > 0, "You don't have any pending YEL");
    }

    function getNamesOfStrategies() public view returns (uint256[] memory) {
        return names;
    }

    function getCurrentStrategy() public view returns (address) {
    	require(names.length > 0, "This vault does not have any strategies");
        return strategies[names[0]];
    }

    function getStrategyInfo(uint256 _nameID) public view returns (
        address _liquidityRouter,
        address _lpToken,
        address _token1,
        address _token0,
        address _farm,
        uint256 _pid,
        uint256 _totalLP,
        uint256 _totalCapital) {
    	require(nameExist[_nameID], "The Name of strategy with this ID does not exist");
        _liquidityRouter = IStrategy(strategies[_nameID]).liquidityRouter();
        _lpToken = IStrategy(strategies[_nameID]).lpToken();
        _token1 = IStrategy(strategies[_nameID]).token1();
        _token0 = IStrategy(strategies[_nameID]).token0();
        _farm = IStrategy(strategies[_nameID]).farm();
        _pid = IStrategy(strategies[_nameID]).pid();
        _totalCapital = IStrategy(strategies[_nameID]).totalCapital();
        _totalLP = IStrategy(strategies[_nameID]).totalLP();
    }

    function autoCompound() public {
    	require(names.length != 0, "There is no strategy");
        for (uint256 i; i < names.length; i++) {
            IStrategy(strategies[names[i]]).autoCompound();
        }
    }

    function getTotalCapital() public view returns (uint256 totalCapital) {
    	require(names.length != 0, "There is no strategy");
        for (uint256 i; i < names.length; i++) {
            totalCapital += IStrategy(strategies[names[i]]).totalCapital();
        }
    }

    function withdrawFee() onlyOwner public {
    	for(uint256 i; i < names.length; i++){
    		IStrategy(strategies[names[i]]).withdrawUSDTFee(msg.sender);
    	}
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("Transfer is not supporting for share tokens.");
    }

    function allowance(address, address) public pure override returns (uint256) {
        revert("Allowance is not supporting for share tokens.");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("Approve is not supporting for share tokens.");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("TransferFrom is not supporting for share tokens.");
    }

    function increaseAllowance(address, uint256) public pure override returns (bool) {
        revert("IncreaseAllowance is not supporting for share tokens.");
    }

    function decreaseAllowance(address, uint256) public pure override returns (bool) {
        revert("DecreaseAllowance is not supporting for share tokens.");
    }

    function setGovernment(address _government) external onlyOwner {
        require(
        	_government != address(0),
        	"The address of government can not be a zero address"
        );
        government = _government;
    }

    function setDepositLimit(uint256 _amount) external onlyOwnerOrGovernment {
        depositLimit = _amount;
    }

    function addStrategy(address _newStrategy, uint256 _nameID) public onlyOwnerOrGovernment {
    	require(_newStrategy != address(0), "The address of YELtoken can not be a zero address");
    	require(strategies[_nameID] == address(0), "The address for this nameID is not empty");
    	require(!strategyExist[_newStrategy], "This strategy address already exists");
        if (!nameExist[_nameID]) {
            names.push(_nameID);
            nameExist[_nameID] = true;
            strategyExist[_newStrategy] = true;
        }
        strategies[_nameID] = _newStrategy;
    }

    function removeStrategy(uint256 _nameID) public onlyOwnerOrGovernment {
       	require(
    		strategies[_nameID] != getCurrentStrategy(),
    		"Can not remove the current strategy"
    	);
    	// send all 100% funds to current strategy
    	_migrate(_nameID, 100, names[0]);

    	// continue removing strategy
        nameExist[_nameID] = false;
        strategyExist[strategies[_nameID]] = false;
        strategies[_nameID] = address(0);
        if(names.length != 1) {
        	for(uint256 i; i < names.length; i++){
	        	if(names[i] == _nameID) {
	        		if(i != names.length-1) {
	        			names[i] = names[names.length-1];
	        		}
		  			names.pop();
	        	}
	        }
        } else {
        	names.pop();
	    }
    }

    function migrate(uint256 _oldNameId, uint256 _amount, uint256 _newNameId) public onlyOwnerOrGovernment {
        _migrate(_oldNameId, _amount, _newNameId);
    }

    function _migrate(uint256 _oldNameId, uint256 _amount, uint256 _newNameId) internal {
    	require(names.length > 1, "Not enough strategies for removing");
        require(nameExist[_oldNameId], "The _oldNameId value does not exist");
        require(nameExist[_newNameId], "The _newNameId value does not exist");
        require(
        	_amount > 0 && _amount <= 100,
        	"The _amount value sould be more then ZERO and less then 100"
        );
        autoCompound();

        // take Native Tokens from old strategy
        IStrategy(strategies[_oldNameId]).migrate(_amount);
        uint _balance = IERC20(WETH).balanceOf(address(this));
        if(_balance > 0){
        	// put Native Tokens to new strategy
        	IStrategy(strategies[_newNameId]).depositAsMigrate(_balance);
        }
        emit PartialMigrate(_amount);
    }

    function _requestYelFromStrategies(address _reciever, uint256 _percent) internal {
        for (uint256 i; i < names.length; i++) {
            IStrategy(strategies[names[i]]).requestWithdraw(_reciever, _percent);
        }
    }

    function _checkDeposit(uint256 _totalCapital, uint256 _depositValue) internal view {
    	require(_totalCapital + _depositValue <= depositLimit, "Deposit is limited by contract");
    }
}