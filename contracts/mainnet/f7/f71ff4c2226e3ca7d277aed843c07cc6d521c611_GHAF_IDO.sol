/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

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

// File: contracts/GHAF/GHAF_IDO.sol


pragma solidity ^0.8.7;








contract GHAF_IDO is Ownable {    
    using SafeMath for uint256;
    using Address for address;

    IERC20 constant USDC_TOKEN = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public GHAF_TOKEN = IERC20(0xDe3F6e45985b2E706C3BAc12b10F6427E6f9C53d);
    address private COMPANY_WALLET = address(0xe01fA40A34Fa7d5a023C98b09Af707C199e8eb63);

    uint256 public MAX_PAY_LIMIT_GHOG_HOLDER = 2000_000_000; // 2000 USDC
    uint256 public MAX_PAY_LIMIT_WHITELIST_1 = 300_000_000; // 300 USDC
    uint256 public MAX_PAY_LIMIT_WHITELIST_2 = 300_000_000; // 300 USDC
    uint256 public MAX_PAY_LIMIT_PUBLIC = 500_000_000; // 500 USDC

    uint256 public GHAF_AMOUNT_PER_USDC_GHOG_HOLDER = 200 * 10**18 / 10**6; // 200 GHAF per 1 USDC
    uint256 public GHAF_AMOUNT_PER_USDC_WHITELIST_1 = 170 * 10**18 / 10**6; // 170 GHAF per 1 USDC
    uint256 public GHAF_AMOUNT_PER_USDC_WHITELIST_2 = 135 * 10**18 / 10**6; // 135 GHAF per 1 USDC
    uint256 public GHAF_AMOUNT_PER_USDC_PUBLIC = 115 * 10**18 / 10**6; // 115 GHAF per 1 USDC
    
    uint256 public START_DATETIME_GHOG_HOLDER = 1651708800; // May 5, 2022 12:00:00 AM GMT
    uint256 public END_DATETIME_GHOG_HOLDER = 1652054400; // May 9, 2022 12:00:00 AM GMT
    uint256 public START_DATETIME_WHITELIST_1 = 1652572800; // May 15, 2022 12:00:00 AM GMT
    uint256 public END_DATETIME_WHITELIST_1 = 1653091200; // May 21, 2022 12:00:00 AM GMT
    uint256 public START_DATETIME_WHITELIST_2 = 1653436800; // May 25, 2022 12:00:00 AM GMT
    uint256 public END_DATETIME_WHITELIST_2 = 1653955200; // May 31, 2022 12:00:00 AM GMT
    uint256 public START_DATETIME_PUBLIC = 1654819200; // June 10, 2022 12:00:00 AM GMT
    uint256 public END_DATETIME_PUBLIC = 1656201600; // June 26, 2022 12:00:00 AM GMT

    mapping(address=>uint256) public MAP_DEPOSIT_GHOG_HOLDER;
    mapping(address=>uint256) public MAP_DEPOSIT_WHITELIST_1;
    mapping(address=>uint256) public MAP_DEPOSIT_WHITELIST_2;
    mapping(address=>uint256) public MAP_DEPOSIT_PUBLIC;

    mapping(address=>uint256) public MAP_CLAIM_GHOG_HOLDER;
    mapping(address=>uint256) public MAP_CLAIM_WHITELIST_1;
    mapping(address=>uint256) public MAP_CLAIM_WHITELIST_2;
    mapping(address=>uint256) public MAP_CLAIM_PUBLIC;

    mapping(address=>uint256) public MAP_CLAIM_DATETIME_GHOG_HOLDER;
    mapping(address=>uint256) public MAP_CLAIM_DATETIME_WHITELIST_1;
    mapping(address=>uint256) public MAP_CLAIM_DATETIME_WHITELIST_2;
    mapping(address=>uint256) public MAP_CLAIM_DATETIME_PUBLIC;

    uint256 public TOTAL_DEPOSIT_GHOG_HOLDER;
    uint256 public TOTAL_DEPOSIT_WHITELIST_1;
    uint256 public TOTAL_DEPOSIT_WHITELIST_2;
    uint256 public TOTAL_DEPOSIT_PUBLIC;

    bytes32 public WHITELIST_ROOT_GHOG_HOLDER;
    bytes32 public WHITELIST_ROOT_WHITELIST_1;
    bytes32 public WHITELIST_ROOT_WHITELIST_2;

    uint256 public CLAIM_INTERVAL = 30 days;

    bool public IDO_ENDED = false;

    constructor() {}

    function setGHAFToken(address _address) public onlyOwner {
        GHAF_TOKEN = IERC20(_address);
    }

    function setCompanyWallet(address _address) public onlyOwner {
        COMPANY_WALLET = _address;
    }

    function setWhitelistingRootForGHOGHolder(bytes32 _root) public onlyOwner {
        WHITELIST_ROOT_GHOG_HOLDER = _root;
    }

    function setWhitelistingRootForWhitelist1(bytes32 _root) public onlyOwner {
        WHITELIST_ROOT_WHITELIST_1 = _root;
    }

    function setWhitelistingRootForWhitelist2(bytes32 _root) public onlyOwner {
        WHITELIST_ROOT_WHITELIST_2 = _root;
    }

    function isWhiteListedForGHOGHolder(bytes32 _leafNode, bytes32[] memory _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, WHITELIST_ROOT_GHOG_HOLDER, _leafNode);
    }

    function isWhiteListedForWhitelist1(bytes32 _leafNode, bytes32[] memory _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, WHITELIST_ROOT_WHITELIST_1, _leafNode);
    }

    function isWhiteListedForWhitelist2(bytes32 _leafNode, bytes32[] memory _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, WHITELIST_ROOT_WHITELIST_2, _leafNode);
    }

    function toLeaf(address account, uint256 index, uint256 amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, account, amount));
    }

    function contributeForGHOGHolder(uint256 _contributeAmount, uint256 _index, uint256 _amount, bytes32[] calldata _proof) public {
        require(block.timestamp >= START_DATETIME_GHOG_HOLDER && block.timestamp <= END_DATETIME_GHOG_HOLDER, "IDO is not activated");

        require(isWhiteListedForGHOGHolder(toLeaf(msg.sender, _index, _amount), _proof), "Invalid proof");
        
        require((MAP_DEPOSIT_GHOG_HOLDER[msg.sender] + _contributeAmount) <= MAX_PAY_LIMIT_GHOG_HOLDER, "Exceeds Max Contribute Amount");

        USDC_TOKEN.transferFrom(msg.sender, COMPANY_WALLET, _contributeAmount);

        MAP_DEPOSIT_GHOG_HOLDER[msg.sender] = MAP_DEPOSIT_GHOG_HOLDER[msg.sender] + _contributeAmount;

        TOTAL_DEPOSIT_GHOG_HOLDER += _contributeAmount;
    }
    function contributeForWhitelist1(uint256 _contributeAmount, uint256 _index, uint256 _amount, bytes32[] calldata _proof) public {
        require(block.timestamp >= START_DATETIME_WHITELIST_1 && block.timestamp <= END_DATETIME_WHITELIST_1, "IDO is not activated");

        require(isWhiteListedForWhitelist1(toLeaf(msg.sender, _index, _amount), _proof), "Invalid proof");
        
        require((MAP_DEPOSIT_WHITELIST_1[msg.sender] + _contributeAmount) <= MAX_PAY_LIMIT_WHITELIST_1, "Exceeds Max Contribute Amount");

        USDC_TOKEN.transferFrom(msg.sender, COMPANY_WALLET, _contributeAmount);

        MAP_DEPOSIT_WHITELIST_1[msg.sender] = MAP_DEPOSIT_WHITELIST_1[msg.sender] + _contributeAmount;

        TOTAL_DEPOSIT_WHITELIST_1 += _contributeAmount;
    }
    function contributeForWhitelist2(uint256 _contributeAmount, uint256 _index, uint256 _amount, bytes32[] calldata _proof) public {
        require(block.timestamp >= START_DATETIME_WHITELIST_2 && block.timestamp <= END_DATETIME_WHITELIST_2, "IDO is not activated");

        require(isWhiteListedForWhitelist2(toLeaf(msg.sender, _index, _amount), _proof), "Invalid proof");
        
        require((MAP_DEPOSIT_WHITELIST_2[msg.sender] + _contributeAmount) <= MAX_PAY_LIMIT_WHITELIST_2, "Exceeds Max Contribute Amount");

        USDC_TOKEN.transferFrom(msg.sender, COMPANY_WALLET, _contributeAmount);

        MAP_DEPOSIT_WHITELIST_2[msg.sender] = MAP_DEPOSIT_WHITELIST_2[msg.sender] + _contributeAmount;

        TOTAL_DEPOSIT_WHITELIST_2 += _contributeAmount;
    }
    function contributeForPublic(uint256 _contributeAmount) public {
        require(block.timestamp >= START_DATETIME_PUBLIC && block.timestamp <= END_DATETIME_PUBLIC, "IDO is not activated");

        require((MAP_DEPOSIT_PUBLIC[msg.sender] + _contributeAmount) <= MAX_PAY_LIMIT_PUBLIC, "Exceeds Max Contribute Amount");

        USDC_TOKEN.transferFrom(msg.sender, COMPANY_WALLET, _contributeAmount);

        MAP_DEPOSIT_PUBLIC[msg.sender] = MAP_DEPOSIT_PUBLIC[msg.sender] + _contributeAmount;

        TOTAL_DEPOSIT_PUBLIC += _contributeAmount;
    }

    function reservedTokenAmountForGHOGHolder(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_GHOG_HOLDER[_address] * GHAF_AMOUNT_PER_USDC_GHOG_HOLDER;
    }
    function reservedTokenAmountForWhitelist1(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_WHITELIST_1[_address] * GHAF_AMOUNT_PER_USDC_WHITELIST_1;
    }
    function reservedTokenAmountForWhitelist2(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_WHITELIST_2[_address] * GHAF_AMOUNT_PER_USDC_WHITELIST_2;
    }
    function reservedTokenAmountForPublic(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_PUBLIC[_address] * GHAF_AMOUNT_PER_USDC_PUBLIC;
    }

    function claimForGHOGHolder() public {
        require(IDO_ENDED , "IDO is not finished");
        
        require(MAP_CLAIM_DATETIME_GHOG_HOLDER[msg.sender] <= block.timestamp, "Should wait until next claim date");

        uint256 remainedAmount = reservedTokenAmountForGHOGHolder(msg.sender) - MAP_CLAIM_GHOG_HOLDER[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        uint256 claimAmount = reservedTokenAmountForGHOGHolder(msg.sender) / 10;
        
        if (claimAmount > remainedAmount) claimAmount = remainedAmount;
        
        GHAF_TOKEN.transfer(msg.sender, claimAmount);

        MAP_CLAIM_GHOG_HOLDER[msg.sender] = MAP_CLAIM_GHOG_HOLDER[msg.sender] + claimAmount;

        MAP_CLAIM_DATETIME_GHOG_HOLDER[msg.sender] = block.timestamp + CLAIM_INTERVAL;
    }
    function claimForWhitelist1() public {
        require(IDO_ENDED , "IDO is not finished");
        
        require(MAP_CLAIM_DATETIME_WHITELIST_1[msg.sender] <= block.timestamp, "Should wait until next claim date");

        uint256 remainedAmount = reservedTokenAmountForWhitelist1(msg.sender) - MAP_CLAIM_WHITELIST_1[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        uint256 claimAmount = reservedTokenAmountForWhitelist1(msg.sender) / 10;
        
        if (claimAmount > remainedAmount) claimAmount = remainedAmount;

        GHAF_TOKEN.transfer(msg.sender, claimAmount);

        MAP_CLAIM_WHITELIST_1[msg.sender] = MAP_CLAIM_WHITELIST_1[msg.sender] + claimAmount;

        MAP_CLAIM_DATETIME_WHITELIST_1[msg.sender] = block.timestamp + CLAIM_INTERVAL;

    }
    function claimForWhitelist2() public {
        require(IDO_ENDED , "IDO is not finished");
        
        require(MAP_CLAIM_DATETIME_WHITELIST_2[msg.sender] <= block.timestamp, "Should wait until next claim date");

        uint256 remainedAmount = reservedTokenAmountForWhitelist2(msg.sender) - MAP_CLAIM_WHITELIST_2[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        uint256 claimAmount = reservedTokenAmountForWhitelist2(msg.sender) / 10;
        
        if (claimAmount > remainedAmount) claimAmount = remainedAmount;

        GHAF_TOKEN.transfer(msg.sender, claimAmount);

        MAP_CLAIM_WHITELIST_2[msg.sender] = MAP_CLAIM_WHITELIST_2[msg.sender] + claimAmount;

        MAP_CLAIM_DATETIME_WHITELIST_2[msg.sender] = block.timestamp + CLAIM_INTERVAL;
    }
    function claimForPublic() public {
        require(IDO_ENDED , "IDO is not finished");
        
        require(MAP_CLAIM_DATETIME_PUBLIC[msg.sender] <= block.timestamp, "Should wait until next claim date");

        uint256 remainedAmount = reservedTokenAmountForPublic(msg.sender) - MAP_CLAIM_PUBLIC[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        uint256 claimAmount = reservedTokenAmountForPublic(msg.sender) / 10;
        
        if (claimAmount > remainedAmount) claimAmount = remainedAmount;

        GHAF_TOKEN.transfer(msg.sender, claimAmount);

        MAP_CLAIM_PUBLIC[msg.sender] = MAP_CLAIM_PUBLIC[msg.sender] + claimAmount;

        MAP_CLAIM_DATETIME_PUBLIC[msg.sender] = block.timestamp + CLAIM_INTERVAL;
    }

    function airdrop(address[] memory _airdropAddresses, uint256 _airdropAmount) public onlyOwner {
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            address to = _airdropAddresses[i];
            GHAF_TOKEN.transfer(to, _airdropAmount);
        }
    }

    function setCostForGHOGHolder(uint256 _newCost) public onlyOwner {
        GHAF_AMOUNT_PER_USDC_GHOG_HOLDER = _newCost;
    }
    function setCostForWhitelist1(uint256 _newCost) public onlyOwner {
        GHAF_AMOUNT_PER_USDC_WHITELIST_1 = _newCost;
    }
    function setCostForWhitelist2(uint256 _newCost) public onlyOwner {
        GHAF_AMOUNT_PER_USDC_WHITELIST_2 = _newCost;
    }
    function setCostForPublic(uint256 _newCost) public onlyOwner {
        GHAF_AMOUNT_PER_USDC_PUBLIC = _newCost;
    }

    function setMaxPayLimitForGHOGHolder(uint16 _amount) public onlyOwner {
        MAX_PAY_LIMIT_GHOG_HOLDER = _amount;
    }
    function setMaxPayLimitForWhitelist1(uint16 _amount) public onlyOwner {
        MAX_PAY_LIMIT_WHITELIST_1 = _amount;
    }
    function setMaxPayLimitForWhitelist2(uint16 _amount) public onlyOwner {
        MAX_PAY_LIMIT_WHITELIST_2 = _amount;
    }
    function setMaxPayLimitForPublic(uint16 _amount) public onlyOwner {
        MAX_PAY_LIMIT_PUBLIC = _amount;
    }


    function finishIDO(bool bEnded) public onlyOwner {
        IDO_ENDED = !bEnded;
    }

    function withdrawUSDC() public onlyOwner {
        USDC_TOKEN.transfer(msg.sender, USDC_TOKEN.balanceOf(address(this)));
    }

    function withdrawGHAF() public onlyOwner {
        GHAF_TOKEN.transfer(msg.sender, GHAF_TOKEN.balanceOf(address(this)));
    }
}