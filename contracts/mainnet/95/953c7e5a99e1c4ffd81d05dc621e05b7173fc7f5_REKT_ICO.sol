/**
 *Submitted for verification at polygonscan.com on 2022-05-27
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: contracts/REKT/REKT_ICO.sol


pragma solidity ^0.8.7;







contract REKT_ICO is Ownable {    
    using SafeMath for uint256;
    using Address for address;

    IERC20 constant USDC_TOKEN = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public REKT_TOKEN;
    uint256 public REKT_TOKEN_DECIMALS = 18;
    address public COMPANY_WALLET;

    uint256 public MIN_CONTRIBUTE_PRIVATE = 1000_000_000; // 1000 USDC
    uint256 public MIN_CONTRIBUTE_WHITELIST = 300_000_000; // 300 USDC
    uint256 public MAX_CONTRIBUTE_WHITELIST = 1500_000_000; // 1500 USDC
    uint256 public MIN_CONTRIBUTE_PUBLIC = 500_000_000; // 500 USDC
    uint256 public MAX_CONTRIBUTE_PUBLIC = 5000_000_000; // 5000 USDC

    uint256 public REKT_PRICE_PRIVATE = 8000; // 0.008 USDC/REKT
    uint256 public REKT_PRICE_WHITELIST = 12500; // 0.0125 USDC/REKT
    uint256 public REKT_PRICE_PUBLIC = 14000; // 0.014 USDC/REKT
    
    uint256 public HARD_CAP_PRIVATE = 40_000_000_000; // 40000 USDC
    uint256 public HARD_CAP_WHITELIST = 250_000_000_000; // 250000 USDC
    uint256 public HARD_CAP_PUBLIC = 70_000_000_000; // 70000 USDC
    

    uint256 public START_DATETIME_WHITELIST;
    uint256 public END_DATETIME_WHITELIST;
    uint256 public START_DATETIME_PUBLIC;
    uint256 public END_DATETIME_PUBLIC;

    mapping(address=>uint256) public MAP_DEPOSIT_PRIVATE;
    mapping(address=>uint256) public MAP_DEPOSIT_WHITELIST;
    mapping(address=>uint256) public MAP_DEPOSIT_PUBLIC;

    mapping(address=>uint256) public MAP_CLAIM_PRIVATE;
    mapping(address=>uint256) public MAP_CLAIM_WHITELIST;
    mapping(address=>uint256) public MAP_CLAIM_PUBLIC;

    mapping(address=>uint256) public MAP_CLAIM_DATETIME_PRIVATE;
    mapping(address=>uint256) public MAP_CLAIM_DATETIME_WHITELIST;
    mapping(address=>uint256) public MAP_CLAIM_DATETIME_PUBLIC;

    uint256 public FIRST_CLAIM_PERCENT = 70;
    uint256 public WEEKLY_CLAIM_PERCENT = 10;

    uint256 public TOTAL_DEPOSIT_PRIVATE;
    uint256 public TOTAL_DEPOSIT_WHITELIST;
    uint256 public TOTAL_DEPOSIT_PUBLIC;

    mapping(address=>bool) public MAP_PRIVATE;
    mapping(address=>bool) public MAP_WHITELIST;

    bool public ICO_ENDED = false;

    constructor() {
        COMPANY_WALLET = address(this);
    }

    function setREKTToken(address _address, uint256 _decimals) external onlyOwner {
        REKT_TOKEN = IERC20(_address);
        REKT_TOKEN_DECIMALS = _decimals;
    }

    function setCompanyWallet(address _address) external onlyOwner {
        COMPANY_WALLET = _address;
    }

    function setClaimPercent(uint256 _firstClaimPercent, uint256 _weeklyClaimPercent) external onlyOwner {
        FIRST_CLAIM_PERCENT = _firstClaimPercent;
        WEEKLY_CLAIM_PERCENT = _weeklyClaimPercent;
    }

    function setPrivateList(address[] memory privateListAddress, bool bEnable) external onlyOwner {
        for (uint256 i = 0; i < privateListAddress.length; i++) {
            MAP_PRIVATE[privateListAddress[i]] = bEnable;
        }
    }

    function setWhiteList(address[] memory whiteListAddress, bool bEnable) external onlyOwner {
        for (uint256 i = 0; i < whiteListAddress.length; i++) {
            MAP_WHITELIST[whiteListAddress[i]] = bEnable;
        }
    }

    function contributeForPrivate(uint256 _contributeAmount) external {
        require(TOTAL_DEPOSIT_PRIVATE < HARD_CAP_PRIVATE, "Raised Fund is enough.");

        require(MAP_PRIVATE[msg.sender], "Invalid proof");
        
        MAP_DEPOSIT_PRIVATE[msg.sender] = MAP_DEPOSIT_PRIVATE[msg.sender] + _contributeAmount;

        require(MAP_DEPOSIT_PRIVATE[msg.sender] >= MIN_CONTRIBUTE_PRIVATE, "Should be higher than Min Contribute Amount");

        USDC_TOKEN.transferFrom(msg.sender, COMPANY_WALLET, _contributeAmount);

        TOTAL_DEPOSIT_PRIVATE += _contributeAmount;
    }
    function contributeForWhitelist(uint256 _contributeAmount) external {
        require(block.timestamp >= START_DATETIME_WHITELIST && block.timestamp <= END_DATETIME_WHITELIST, "ICO is not activated");

        require(TOTAL_DEPOSIT_WHITELIST < HARD_CAP_WHITELIST, "Raised Fund is enough.");

        require(MAP_WHITELIST[msg.sender], "Invalid proof");
        
        MAP_DEPOSIT_WHITELIST[msg.sender] = MAP_DEPOSIT_WHITELIST[msg.sender] + _contributeAmount;

        require(MAP_DEPOSIT_WHITELIST[msg.sender] >= MIN_CONTRIBUTE_WHITELIST && MAP_DEPOSIT_WHITELIST[msg.sender] <= MAX_CONTRIBUTE_WHITELIST, "Invalid Contribute Amount");

        USDC_TOKEN.transferFrom(msg.sender, COMPANY_WALLET, _contributeAmount);
        
        TOTAL_DEPOSIT_WHITELIST += _contributeAmount;
    }

    function contributeForPublic(uint256 _contributeAmount) external {
        require(block.timestamp >= START_DATETIME_PUBLIC && block.timestamp <= END_DATETIME_PUBLIC, "ICO is not activated");

        require(TOTAL_DEPOSIT_PUBLIC < HARD_CAP_PUBLIC, "Raised Fund is enough.");

        MAP_DEPOSIT_PUBLIC[msg.sender] = MAP_DEPOSIT_PUBLIC[msg.sender] + _contributeAmount;

        require(MAP_DEPOSIT_PUBLIC[msg.sender] >= MIN_CONTRIBUTE_PUBLIC && MAP_DEPOSIT_PUBLIC[msg.sender] <= MAX_CONTRIBUTE_PUBLIC, "Invalid Contribute Amount");

        USDC_TOKEN.transferFrom(msg.sender, COMPANY_WALLET, _contributeAmount);

        TOTAL_DEPOSIT_PUBLIC += _contributeAmount;
    }

    function reservedPrivateTokenAmount(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_PRIVATE[_address] / REKT_PRICE_PRIVATE * 10**REKT_TOKEN_DECIMALS;
    }
    function reservedWhitelistTokenAmount(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_WHITELIST[_address] / REKT_PRICE_WHITELIST * 10**REKT_TOKEN_DECIMALS;
    }
    function reservedPublicTokenAmount(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_PUBLIC[_address] / REKT_PRICE_PUBLIC * 10**REKT_TOKEN_DECIMALS;
    }

    function claimPrivate() external {
        require(ICO_ENDED , "ICO is not finished");
        
        uint256 remainedAmount = reservedPrivateTokenAmount(msg.sender) - MAP_CLAIM_PRIVATE[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        uint256 claimAmount = 0;

        if (MAP_CLAIM_DATETIME_PRIVATE[msg.sender] == 0) {
            claimAmount = reservedPrivateTokenAmount(msg.sender) * FIRST_CLAIM_PERCENT / 100;
        } else {
            claimAmount = reservedPrivateTokenAmount(msg.sender) * WEEKLY_CLAIM_PERCENT / 100;
        }
        
        if (claimAmount > remainedAmount) claimAmount = remainedAmount;
        
        REKT_TOKEN.transfer(msg.sender, claimAmount);

        MAP_CLAIM_PRIVATE[msg.sender] = MAP_CLAIM_PRIVATE[msg.sender] + claimAmount;

        MAP_CLAIM_DATETIME_PRIVATE[msg.sender] = block.timestamp;
    }

    function claimWhitelist() external {
        require(ICO_ENDED , "ICO is not finished");

        uint256 remainedAmount = reservedWhitelistTokenAmount(msg.sender) - MAP_CLAIM_WHITELIST[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        uint256 claimAmount = 0;

        if (MAP_CLAIM_DATETIME_WHITELIST[msg.sender] == 0) {
            claimAmount = reservedWhitelistTokenAmount(msg.sender) * FIRST_CLAIM_PERCENT / 100;
        } else {
            claimAmount = reservedWhitelistTokenAmount(msg.sender) * WEEKLY_CLAIM_PERCENT / 100;
        }
        
        if (claimAmount > remainedAmount) claimAmount = remainedAmount;

        REKT_TOKEN.transfer(msg.sender, claimAmount);

        MAP_CLAIM_WHITELIST[msg.sender] = MAP_CLAIM_WHITELIST[msg.sender] + claimAmount;

        MAP_CLAIM_DATETIME_WHITELIST[msg.sender] = block.timestamp;

    }
    function claimForPublic() external {
        require(ICO_ENDED , "ICO is not finished");

        uint256 remainedAmount = reservedPublicTokenAmount(msg.sender) - MAP_CLAIM_PUBLIC[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        uint256 claimAmount = 0;

        if (MAP_CLAIM_DATETIME_PUBLIC[msg.sender] == 0) {
            claimAmount = reservedPublicTokenAmount(msg.sender) * FIRST_CLAIM_PERCENT / 100;
        } else {
            claimAmount = reservedPublicTokenAmount(msg.sender) * WEEKLY_CLAIM_PERCENT / 100;
        }
        
        if (claimAmount > remainedAmount) claimAmount = remainedAmount;

        REKT_TOKEN.transfer(msg.sender, claimAmount);

        MAP_CLAIM_PUBLIC[msg.sender] = MAP_CLAIM_PUBLIC[msg.sender] + claimAmount;

        MAP_CLAIM_DATETIME_PUBLIC[msg.sender] = block.timestamp;
    }

    function airdrop(address[] memory _airdropAddresses, uint256 _airdropAmount) external onlyOwner {
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            address to = _airdropAddresses[i];
            REKT_TOKEN.transfer(to, _airdropAmount);
        }
    }

    function setWhitelistStartEndTimestamp(uint256 _startTimestamp, uint256 _endTimestamp) external onlyOwner {
        START_DATETIME_WHITELIST = _startTimestamp;
        END_DATETIME_WHITELIST = _endTimestamp;
    }
    function setPublicStartEndTimestamp(uint256 _startTimestamp, uint256 _endTimestamp) external onlyOwner {
        START_DATETIME_PUBLIC = _startTimestamp;
        END_DATETIME_PUBLIC = _endTimestamp;
    }


    function setPrivatePrice(uint256 _newPrice) external onlyOwner {
        REKT_PRICE_PRIVATE = _newPrice;
    }
    function setWhitelistPrice(uint256 _newPrice) external onlyOwner {
        REKT_PRICE_WHITELIST = _newPrice;
    }
    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        REKT_PRICE_PUBLIC = _newPrice;
    }

    
    function setPrivateHardCap(uint256 _newHardCap) external onlyOwner {
        HARD_CAP_PRIVATE = _newHardCap;
    }
    function setWhitelistHardCap(uint256 _newHardCap) external onlyOwner {
        HARD_CAP_WHITELIST = _newHardCap;
    }
    function setPublicHardCap(uint256 _newHardCap) external onlyOwner {
        HARD_CAP_PUBLIC = _newHardCap;
    }


    function setPrivateMinContribute(uint256 _minLimit) external onlyOwner {
        MIN_CONTRIBUTE_PRIVATE = _minLimit;
    }
    function setWhitelistMaxMinContribute(uint256 _minLimit, uint256 _maxLimit) external onlyOwner {
        MIN_CONTRIBUTE_WHITELIST = _minLimit;
        MAX_CONTRIBUTE_WHITELIST = _maxLimit;
    }
    function setPublicMaxMinContribute(uint256 _minLimit, uint256 _maxLimit) external onlyOwner {
        MIN_CONTRIBUTE_PUBLIC = _minLimit;
        MAX_CONTRIBUTE_PUBLIC = _maxLimit;
    }


    function finishICO(bool bEnded) external onlyOwner {
        ICO_ENDED = !bEnded;
    }

    function withdrawUSDC() external onlyOwner {
        USDC_TOKEN.transfer(msg.sender, USDC_TOKEN.balanceOf(address(this)));
    }

    function withdrawREKT() external onlyOwner {
        REKT_TOKEN.transfer(msg.sender, REKT_TOKEN.balanceOf(address(this)));
    }
}