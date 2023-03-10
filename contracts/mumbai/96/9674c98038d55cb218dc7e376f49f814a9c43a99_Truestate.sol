/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

/**
 *Submitted for verification at polygonscan.com on 2023-02-27
*/

/**
 *Submitted for verification at polygonscan.com on 2023-02-16
*/

/**
 *Submitted for verification at polygonscan.com on 2022-12-29
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

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


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
     *    * Returns a boolean value indicating whether the operation succeeded.
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


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


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


interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

    function latestAnswer() external view returns (int256);
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


interface ITrustate {
    function getAdmin() external view returns (address);
    function _minBuy() external view returns (uint256);
    function getRate() external view returns (int256);
}

interface ITokenContract is IERC20 {
    function burn() external;
    function setMinAmount(uint256 amount) external;
    function getMinAmount() external view returns (uint256);
    function claim(address _account) external;
    function claimExpired(address _account, address _to) external;
    function payoutDone() external view returns (bool);
}


contract TruEstateObject is Initializable, ContextUpgradeable, IERC20Upgradeable, OwnableUpgradeable {
    
    using Address for address;
    /*@dev mapping of users balances of tokens*/
    mapping (address => uint256) private _balances;

    /*@dev mapping of users allowances*/
    mapping (address => mapping (address => uint256)) private _allowances;

    /*@dev totalSupply*/
    uint256 private _totalSupply;

    /*@dev state of payout*/
    bool public payoutDone;

    /*@dev payout expire date*/
    uint256 public payoutDate;

    /*@dev dividends value*/
    uint256 private _dividends;

    uint256 private _minbuy = 10;

    /*@dev number of token holders*/
    uint256 public holdersCount = 0;

    /*@dev mapping of token holders address*/
    mapping (uint256 => address) public holders; 

    /*@dev time to pay dividends*/
    //uint256 private expireTerm = 365 * 24 * 60 * 60;
    uint256 private expireTerm = 60 * 60;

    /*@dev Token decimals*/
    uint8 private _decimals = 2;

    /*@dev Token name*/
    string private _name;

    /*@dev Token symbol*/
    string private _symbol;

    event DividendClaim(address indexed _account, address indexed _contract, uint256 _tokens, uint256 _ethereum);

    /*@dev Initialization func`s*/
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    ) public virtual initializer {
        __ERC20Upgradable_init(name_, symbol_, initialSupply);
    }

    function __ERC20Upgradable_init (
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20Upgradable_init_unchained(name_, symbol_, initialSupply);
    }

    function __ERC20Upgradable_init_unchained (
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    ) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialSupply;
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    /*@dev Get token Name*/
    function name() public view virtual override returns (string memory) {
        return _name;
    }

  function minbuy() public view virtual  returns (uint256) {
        return _minbuy;
    }
    /*@dev Get token Symbol*/
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /*@dev Get token Decimals*/
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /*@dev Get token Total Supply*/
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /*@dev Get token balance of account */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /*@dev Get transfer tokens (from, to)*/
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /*@dev Get allowance*/
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /*@dev Approve spend*/
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /*@dev Transfer from another account*/
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

    /*@dev Increase account allowance*/
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /*@dev Decrease account allowance*/
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    /*@dev Internal transfer func*/
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(amount > 0, "ERC20: Amount cannot be a zero value");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require((recipient != address(0) && recipient != address(this)), "ERC20: invalid recepient address");
        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    /*@dev Burn tokens*/
    function burn() public onlyOwner () {
        uint256 balance = balanceOf(address(this));
        _burn(address(this), balance);
    }

    /*@dev Burn tokens internal func*/
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /*@dev Approve allowance*/
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

    /*@dev Calculate received eth to tokens*/
    function getTokenAmount(uint256 _amount) public view returns (uint256) {
      int256 rate = ITrustate(owner()).getRate();
      uint256 result = _amount * uint256(rate) / 10 ** 24;
      return (result);
    }

    /*@dev Automatic payment tokens*/

    function getMinAmount() external view returns (uint256) {
      int256 rate =  ITrustate(owner()).getRate();
      uint256 result = _minbuy * 10 ** 24 / uint256(rate);
      return result;
    }

    function setMinAmount(uint256 minAmount) external {
         address admin = ITrustate(owner()).getAdmin();
        require(_msgSender()==admin || _msgSender() == owner(), "Access:Only owner");
        _minbuy = minAmount;
    }

    /*@dev Deposit eth to receive tokens*/
    function deposit() external payable{
        address admin = ITrustate(owner()).getAdmin();
        if (_msgSender() == admin) {
            require(!payoutDone, "Dividends can be sent only once");
            _dividends = msg.value;
            uint256 balance = balanceOf(address(this));
            _burn(address(this), balance);
            payoutDone = true;
            payoutDate = block.timestamp + expireTerm;
        } else {
            require(balanceOf(address(this)) > 0, "No tokens left to buy .");
            (uint256 tokenAmount) = getTokenAmount(msg.value);
            require(tokenAmount >= _minbuy, "Insufficient ETH amount to buy tokens.");
            _transfer(address(this), _msgSender(), tokenAmount);
            holders[holdersCount] = _msgSender();
            holdersCount++;
            payable(admin).transfer(msg.value);
        }
    }

    /*@dev Internal claiming tokens*/
    function _claim() external {
        require(payoutDone,"No dividends for this project");
        require(msg.sender != address(0), "Invalid user wallet");
        uint256 senderBalance = balanceOf(msg.sender);
        require(senderBalance > 0, "You cannot claim reward");
        uint256 reward = _dividends * senderBalance / totalSupply();
        require(address(this).balance >= reward, "Insufficient amount of ETH on contract");
        _balances[msg.sender] = 0;
        _balances[address(0)] += senderBalance;
        emit Transfer(msg.sender, address(0), senderBalance);
        (bool sent, ) = payable(msg.sender).call{value: reward, gas: 30000}("");
        require(sent, "Failed to send Ether");
        emit DividendClaim(msg.sender, address(this), senderBalance, reward);
    }

    /*@dev avoid storage clashes while using inheritance*/
    uint256[50] private __gap;
}


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


contract Truestate is Ownable {

    using Strings for uint256;
    /*@dev Mapping of all object contracts */
    mapping(uint256 => address) private tokenContracts;

    /*@dev Last created object id || Count of objects*/
    uint256 private _currentProjectID;

    /*@dev Wallets for pay dividends*/
    //address private _paymentWallet = 0x294658373ADBDBe836e2E841BB1996ceA9e56Fe3;
    address private _paymentWallet = 0x0609A94237f6578700e8a876C2d98C080f4c6beb;

    /*@dev Object name prefix*/
    string private _name = "TRUESTATE";

    /*@dev Object symbol prefix*/
    string private _symbol = "TRUESTATE";

    /*@dev Min tokens buy*/
    //uint256 private _minBuy = 10000;


    /*@dev Price agregator addresses*/
    //mainnet
    //address private _ethusd = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    //address private _eurusd = 0xb49f677943BC038e9857d61E7d053CaA2C1734C1;
    //Mumbai
    address private _ethusd = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
    address private _eurusd = 0x7d7356bF6Ee5CDeC22B216581E48eCC700D0497A;

    event NewProject(uint256 _id, address indexed _cntr, uint256 _supply);

    /*@dev Get prefix name*/
    function name() public view returns (string memory) {
        return _name;
    }

    /*@dev Get prefix symbol*/
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     /*@dev Get contract address*/
    function getContractAddressByID(uint256 _id) public view returns(address) {
        return tokenContracts[_id];
    }

     /*@dev Get contract tokens balance*/
    function getBalanceByID(uint256 _id) public view returns (uint256) {
        require(tokenContracts[_id] != address(0), "Invalid project ID");
        return IERC20(tokenContracts[_id]).balanceOf(tokenContracts[_id]);
    }

     /*@dev Burn contract tokens*/
    function burn(uint256 _id) public onlyOwner {
        require(tokenContracts[_id] != address(0), "Invalid project ID");
        require(getBalanceByID(_id) > 0, "No tokens to burn");
        ITokenContract(tokenContracts[_id]).burn();
    }

     /*@dev Create new object*/
    function createProject(uint256 _supply) public onlyOwner() {
        require (_supply > 0, "Insufficient supply");
        uint256 _id = _currentProjectID + 1;
        TruEstateObject cntr = new TruEstateObject();
        cntr.initialize(
            string(abi.encodePacked(name(), Strings.toString(_id))),
            string(abi.encodePacked("TRUEST", Strings.toString(_id))),
            _supply * 10 ** 2);
        tokenContracts[_id] = address(cntr);
        _currentProjectID = _id;
        emit NewProject(_id, address(cntr), _supply * 10 ** 2);
    }

    /*@dev get payment wallet*/
    function getAdmin() public view returns (address) {
        return _paymentWallet;
    }

    /*@dev get current prices*/
    function getRate() public view returns (int256) {
        (int256 basePrice) = AggregatorV3Interface(_ethusd).latestAnswer();
        (int256 quotePrice) = AggregatorV3Interface(_eurusd).latestAnswer();
        return basePrice * int256(10 ** uint256(8)) / quotePrice;
    }

    /*@dev get min value for deposit*/
    
    /*@dev set new payment wallet*/
    function setAdmin(address account) external onlyOwner {
        _paymentWallet = account;
    }

    function getMinAmountByID(uint256 _id) external view returns(uint256){
        require(tokenContracts[_id] != address(0), "Invalid project ID");
        return ITokenContract(tokenContracts[_id]).getMinAmount();
    }

    function setMinAmountByID(uint256 _minAmount, uint256 _id) external onlyOwner{
        require(tokenContracts[_id] != address(0), "Invalid project ID");
        ITokenContract(tokenContracts[_id]).setMinAmount(_minAmount);
    }
}