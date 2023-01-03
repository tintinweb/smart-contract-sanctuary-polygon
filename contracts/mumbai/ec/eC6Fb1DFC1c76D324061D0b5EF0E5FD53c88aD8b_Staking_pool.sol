//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeERC20: decreased allowance below zero");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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
    using SafeMath for uint256;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

      /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20, Ownable {
    using SafeMath for uint256;
   
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view  override returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public  virtual override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

      function transferERC20(IERC20 token, address to, uint256 amount) public onlyOwner virtual returns (bool) { 
    
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(to, amount);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public  virtual override returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */

    function transferFrom(address from, address to, uint256 value) public  virtual override returns (bool) {

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public  virtual returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public  virtual returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    function burn(address account, uint256 value) public onlyOwner returns (bool){
        _burn(account, value);
        return true;
    }


    function burnFrom(address account, uint256 value) internal returns (bool) {
         _burnFrom(account, value);
         return true;
    }


    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: openzeppelin-solidity/contracts/access/roles/PauserRole.sol

contract PauserRole is Ownable {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

    function renouncePauser() public onlyOwner {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public  whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public  whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol

/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 **/
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused override returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused override returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused override returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused override returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused override returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/MEAC.sol

contract MeacToken is ERC20Pausable, ERC20Detailed {
    constructor (string memory name, string memory symbol, uint8 decimals, uint256 totalSupply)
    public
    ERC20Detailed (name, symbol, decimals) {
        _mint(msg.sender, totalSupply);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./MEAC.sol";

contract Staking_pool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserRewardInfo {
        uint256 amount;
        uint256 depositAt;
        uint256 canHarvestTimestamp;
        uint256 bonusRate;
        bool isPaid;
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many MEAC tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 doneDays;
        uint256 stakedDays;
        UserRewardInfo[] userRewardInfo;
       
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 MeaceToken;           // Address of MEAC token contract.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The MEAC TOKEN!
    MeacToken public local;
    // MEAC tokens created per block.
    // Bonus muliplier for early local makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes MEAC tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    
    mapping (uint256 => uint256) public bonusRateForTime;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        MeacToken _local,
        address _feeAddress
    ) public {
        local = _local;
        feeAddress = _feeAddress;
        bonusRateForTime[60] = 6;
        bonusRateForTime[90] = 9;
        bonusRateForTime[360] = 70;

        poolInfo.push(PoolInfo({
            MeaceToken: local,
            depositFeeBP: 0
        }));
    }
    
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new MEAC to the pool. Can only be called by the owner.
    // XXX DO NOT add the same MEAC token more than once. Rewards will be messed up if you do.
    function add(IERC20 _MeaceToken, uint16 _depositFeeBP) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
       
        poolInfo.push(PoolInfo({
            MeaceToken: _MeaceToken,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's MeaceToken allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint16 _depositFeeBP) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
       
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    function getBonusRateFromLockedDate(uint256 _days) public view returns (uint256 bonusRate) {
        if (_days >= 60 && _days < 90) {
            bonusRate = bonusRateForTime[60];
        }
        else if (_days >= 90 && _days < 360) {
            bonusRate = bonusRateForTime[90];
        }
        else if (_days >= 360) {
            bonusRate = bonusRateForTime[360];   
        }
    }

    // View function to see pending MeaceToken on frontend.
    function pendingMEAC(uint256 _pid, address _user) public view returns (uint256) {

        UserInfo storage user = userInfo[_pid][_user];
        uint256 pending;
        if (user.amount > 0) {
            uint256 currentTime = block.timestamp;
                for (uint256 i = 0; i < user.userRewardInfo.length; i++ ) {
                    UserRewardInfo storage rewardInfo = user.userRewardInfo[i];
                    if (rewardInfo.isPaid) continue;
                    if (currentTime > rewardInfo.canHarvestTimestamp) {
                        // uint256 lockedDays = block.timestamp.sub(rewardInfo.depositAt);
                        // lockedDays = lockedDays.div(1 days);
                        // uint256 bonusRate = getBonusRateFromLockedDate(lockedDays);
                        uint256 bonusRate= rewardInfo.bonusRate;
                        pending = rewardInfo.amount;
                        pending = pending.add(rewardInfo.amount.mul(bonusRate).div(100));
                    }
                }
        }
        return pending;
    }

    function addOldUsers(address[] memory _walletAddresses, uint256[] memory amounts, uint256[] memory doneDaysList, uint256[] memory stakedDaysList) public onlyOwner() {
        require(_walletAddresses.length == amounts.length, 'different length of list');
        require(_walletAddresses.length == doneDaysList.length, 'different length of list');
        require(_walletAddresses.length == stakedDaysList.length, 'different length of list');
        for (uint256 i = 0; i < _walletAddresses.length; i ++) {
            address _account = _walletAddresses[i];
            UserInfo storage user = userInfo[0][_account];
            uint256 _amount = amounts[i];
            uint256 _doneDays = doneDaysList[i];
            uint256 _stakedDays= stakedDaysList[i];
            user.amount = user.amount.add(_amount);
            user.doneDays= user.doneDays.add(_doneDays);
            user.stakedDays= user.stakedDays.add(_stakedDays);
             if(_doneDays > _stakedDays){
            user.userRewardInfo.push(UserRewardInfo({
                amount: _amount,
                depositAt: block.timestamp.sub(_doneDays * 1 days),
                canHarvestTimestamp: block.timestamp,
                bonusRate: bonusRateForTime[_stakedDays],
                isPaid: false
                }));
        }else{
            uint256 harvestTime= _stakedDays.sub(_doneDays);
            user.userRewardInfo.push(UserRewardInfo({
                amount: _amount,
                depositAt: block.timestamp.sub(_doneDays * 1 days),
                canHarvestTimestamp: block.timestamp.add(harvestTime * 1 days),
                bonusRate: bonusRateForTime[_stakedDays],
                isPaid: false
                }));    
        }
        }
    }

    /*
     *Updated addOldUser function 
     *_amount is the MeaceToken amount with decimals
     *Added new parameter StakedDays and doneDays.
     *Both doneDays and StakeDays Parameter will store in userInfo
     **/
    function addOldUser(address _walletAddress, uint256 _amount, uint256 _doneDays,uint256 _stakedDays) public onlyOwner() {
        UserInfo storage user = userInfo[0][_walletAddress];
        user.amount = user.amount.add(_amount);
        user.doneDays= user.doneDays.add(_doneDays);
        user.stakedDays= user.stakedDays.add(_stakedDays);
       
        if(_doneDays > _stakedDays){
        user.userRewardInfo.push(UserRewardInfo({
                amount: _amount,
                depositAt: block.timestamp.sub(_doneDays * 1 days),
                canHarvestTimestamp: block.timestamp,
                bonusRate: bonusRateForTime[_stakedDays],
                isPaid: false
                }));
        }else{
             uint256 harvestTime= _stakedDays.sub(_doneDays);
             user.userRewardInfo.push(UserRewardInfo({
                amount: _amount,
                depositAt: block.timestamp.sub(_doneDays * 1 days),
                canHarvestTimestamp: block.timestamp.add(harvestTime * 1 days),
                bonusRate: bonusRateForTime[_stakedDays],
                isPaid: false
                }));
        }
    }

    // Deposit MeaceToken to MasterChef for MeaceToken allocation.
    function deposit(uint256 _pid, uint256 _amount, uint256 _days) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // updatePool(_pid);
        if (user.amount > 0) {
            uint256 currentTime = block.timestamp;
            uint256 pending;
            for (uint256 i = 0; i < user.userRewardInfo.length; i++ ) {
                UserRewardInfo storage rewardInfo = user.userRewardInfo[i];
                if (rewardInfo.isPaid) continue;
                
                if (currentTime > rewardInfo.canHarvestTimestamp) {
                    // uint256 lockedDays = block.timestamp.sub(rewardInfo.depositAt);
                    // lockedDays = lockedDays.div(1 days);
                    // uint256 bonusRate = getBonusRateFromLockedDate(lockedDays);
                    uint256 bonusRate= rewardInfo.bonusRate;
                    pending = pending.add(rewardInfo.amount.add(rewardInfo.amount.mul(bonusRate).div(100)));
                    rewardInfo.isPaid = true;
                    rewardInfo.amount = 0;
                    user.amount = user.amount.sub(rewardInfo.amount);
                }
            }

            if(pending > 0) {
                safeLocalTransfer(msg.sender, pending);
            }    
            
        }

        if(_amount > 0) {
            pool.MeaceToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 realAmount = _amount;
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.MeaceToken.safeTransfer(feeAddress, depositFee);
                realAmount = realAmount.sub(depositFee);
            }

            user.amount = user.amount.add(realAmount);
            user.userRewardInfo.push(UserRewardInfo({
                amount: realAmount,
                depositAt: block.timestamp,
                canHarvestTimestamp: block.timestamp.add(_days * 1 days),
                bonusRate: bonusRateForTime[_days],
                isPaid: false
                }));
        }
        emit Deposit(msg.sender, _pid, _amount);
    }
    
    function AuserRewardInfo(uint256 _pid, address account, uint256 index) public view returns (uint256, uint256, uint256, bool) {
        UserInfo storage user = userInfo[_pid][account];
        UserRewardInfo storage rewardInfo = user.userRewardInfo[index];
        return (rewardInfo.amount, rewardInfo.canHarvestTimestamp, rewardInfo.bonusRate, rewardInfo.isPaid);
    }
    
    // Withdraw MEAC tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
         if (user.amount > 0) {
            uint256 currentTime = block.timestamp;
            uint256 pending;
            uint256 sumAmount;
            uint256 restAmount;
            for (uint256 i = 0; i < user.userRewardInfo.length; i++ ) {
                UserRewardInfo storage rewardInfo = user.userRewardInfo[i];
                if (rewardInfo.isPaid) continue;
                if ( currentTime <= rewardInfo.canHarvestTimestamp ) continue;

                // uint256 lockedDays = block.timestamp.sub(rewardInfo.depositAt);
                // lockedDays = lockedDays.div(1 days);
                // uint256 bonusRate = getBonusRateFromLockedDate(lockedDays);
                uint256 bonusRate= rewardInfo.bonusRate;
                sumAmount = sumAmount.add(rewardInfo.amount);
                if (sumAmount <= _amount){
                    pending = pending.add(rewardInfo.amount.mul(bonusRate).div(100));
                    rewardInfo.isPaid = true;
                    rewardInfo.amount = 0;
                }
                else {
                    restAmount = sumAmount.sub(_amount);
                    pending = pending.add(rewardInfo.amount.sub(restAmount).mul(bonusRate).div(100));
                    rewardInfo.amount = restAmount;
                    break;
                }
            }
            require(pending > 0, "funds still in lock period.");
            user.amount = user.amount.sub(_amount);
            safeLocalTransfer(msg.sender, _amount.add(pending));
        }
    }

    // Safe local transfer function, just in case if rounding error causes pool to not have enough MeaceToken.
    function safeLocalTransfer(address _to, uint256 _amount) internal {
        uint256 localBal = local.balanceOf(address(this));
        if (_amount > localBal) {
            local.transfer(_to, localBal);
        } else {
            local.transfer(_to, _amount);
        }
    }

    // Update fee address
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }


    // Shows the count of days since user had staked their MeaceToken
    function userDoneDays(uint256 _pid, address _user) public view returns (uint256 stakedDays){

        UserInfo storage user = userInfo[_pid][_user];
        UserRewardInfo storage rewardInfo = user.userRewardInfo[_pid];
        stakedDays= block.timestamp.sub(rewardInfo.depositAt);
        stakedDays= stakedDays.div(1 days);
        return stakedDays;
    }

    // Shows for how many days users staked the MeaceToken
    function userStakedDays(uint256 _pid, address _user) public view returns (uint256 lockedDays){

        UserInfo storage user = userInfo[_pid][_user];
        lockedDays= user.userRewardInfo[_pid].canHarvestTimestamp.sub(user.userRewardInfo[_pid].depositAt);
        lockedDays= lockedDays.div(1 days);
        return lockedDays;
    }

    // Allow owner to tranfer any ERC20 token from this contract to other addresses 
    function transferERC20(IERC20 token, address to, uint256 amount) external onlyOwner returns (bool) { 

        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(to, amount);
        return true;
    }
 
}