/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

// File: @openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol


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
library SafeMathUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// File: bid.sol



pragma solidity ^0.8.3;





/**
 * @title Interface for contracts conforming to ERC-20
 */
interface ERC20Interface {
    function balanceOf(address from) external view returns (uint256);
    function transfer(address to, uint tokens) external returns (bool);
    function transferFrom(address from, address to, uint tokens) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}


/**
 * @title Interface for contracts conforming to ERC-721
 */
interface ERC721Interface {
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function supportsInterface(bytes4) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function mint(address _to, string calldata _tokenURI) external returns (uint256);
}

interface CertificateInterface {
    function transferOwnership(address newOwner) external;
}

interface ERC721Verifiable is ERC721Interface {
    function verifyFingerprint(uint256, bytes memory) external view returns (bool);
}


contract ERC721BidStorage {
    // 182 days - 26 weeks - 6 months
    uint256 public constant MAX_BID_DURATION = 182 days;
    uint256 public constant MIN_BID_DURATION = 1 minutes;
    uint256 public constant ONE_MILLION = 1000000;
    bytes4 public constant ERC721_Interface = 0x80ac58cd;
    bytes4 public constant ERC721_Received = 0x150b7a02;
    bytes4 public constant ERC721Composable_ValidateFingerprint = 0x8f9f4b63;
    address public _certificateAddress;
    
    struct Bid {
        // Bid Id
        bytes32 id;
        // Bidder address 
        address bidder;
        // ERC721 address
        address tokenAddress;
        // ERC721 token id
        uint256 tokenId;
        // Price for the bid in wei 
        uint256 price;
        // Time when this bid ends 
        uint256 expiresAt;
        // Fingerprint for composable
        bytes fingerprint;
        
        string name;

        string description;

        string bidImage;
    }

    struct Order {
        // Orderer address
        address orderer;
        // Bidder address 
        address bidder;
        // ERC721 address
        address tokenAddress;
        // ERC721 token id
        uint256 tokenId;
        // Price for the bid in wei 
        uint256 price;
        // Time when this bid ends 
        uint256 expiresAt;
    }

    // EGGT token
    ERC20Interface public eggtToken;

    // Bid by token address => token id => bid index => bid
    mapping(address => mapping(uint256 => mapping(uint256 => Bid))) internal bidsByToken;
    // Bid by token address => token id => bid
    mapping(address => mapping(uint256 => Order)) internal orders;
    // Bid count by token address => token id => bid counts
    mapping(address => mapping(uint256 => uint256)) public bidCounterByToken;
    // Index of the bid at bidsByToken mapping by bid id => bid index
    mapping(bytes32 => uint256) public bidIndexByBidId;
    // Bid id by token address => token id => bidder address => bidId
    mapping(address => mapping(uint256 => mapping(address => bytes32))) 
    public 
    bidIdByTokenAndBidder;


    mapping(uint256 => uint256) public ownerCutPerMillion;

    // EVENTS
    event BidCreated(
        bytes32 _id,
        address indexed _tokenAddress,
        uint256 indexed _tokenId,
        address indexed _bidder,
        uint256 _price,
        uint256 _expiresAt,
        bytes _fingerprint,
        string _name,
        string _description,
        string _bidImage
    );
    
    event BidAccepted(
        bytes32 _id,
        address indexed _tokenAddress,
        uint256 indexed _tokenId,
        address _bidder,
        address indexed _seller,
        uint256 _price,
        uint256 _fee
    );

    event BidCancelled(
        bytes32 _id,
        address indexed _tokenAddress,
        uint256 indexed _tokenId,
        address indexed _bidder
    );

    event OrderCreated(
        address indexed _orderer,
        address indexed _bidder,
        address indexed _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _expiresAt
    );

    event OrderAccepted(
        address indexed _orderer,
        address indexed _bidder,
        address indexed _tokenAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _fee
    );

    event OrderCancelled(
        address indexed _orderer,
        address indexed _bidder,
        address indexed _tokenAddress
    );

    event ChangedOwnerCutPerMillion(uint256 categoryId, uint256 _ownerCutPerMillion);
}


contract ERC721Bid is OwnableUpgradeable, PausableUpgradeable, ERC721BidStorage {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    address public auctionContract;

    /**
    * @dev Constructor of the contract.
    * @param _eggtToken - address of the eggt token
    * @param _owner - address of the owner for the contract
    */
    function initialize(address _eggtToken, address _owner) public initializer {

        __Ownable_init();
        __Pausable_init();

        eggtToken = ERC20Interface(_eggtToken);
        transferOwnership(_owner);
    }

    /**
    * @dev Place a bid for an ERC721 token.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _price - uint256 of the price for the bid
    * @param _duration - uint256 of the duration in seconds for the bid
    * @param _name - string of bid name
    * @param _description - string of bid description
    */
    function placeBid(
        address _tokenAddress, 
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration,
        string memory _name,
        string memory _description,
        string memory _bidImage
    )
        public
    {
        _placeBid(
            _tokenAddress, 
            _tokenId,
            _price,
            _duration,
            "",
            _name,
            _description,
            _bidImage
        );
    }

    /**
    * @dev Place a bid for an ERC721 token with fingerprint.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _price - uint256 of the price for the bid
    * @param _duration - uint256 of the duration in seconds for the bid
    * @param _fingerprint - bytes of ERC721 token fingerprint 
    * @param _name - string of bid name
    * @param _description - string of bid description
    */
    function placeBid(
        address _tokenAddress, 
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration,
        bytes memory _fingerprint,
        string memory _name,
        string memory _description,
        string memory _bidImage
    )
        public
    {
        _placeBid(
            _tokenAddress, 
            _tokenId,
            _price,
            _duration,
            _fingerprint,
            _name,
            _description,
            _bidImage
        );
    }

    /**
    * @dev Place a bid for an ERC721 token with fingerprint.
    * @notice Tokens can have multiple bids by different users.
    * Users can have only one bid per token.
    * If the user places a bid and has an active bid for that token,
    * the older one will be replaced with the new one.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _price - uint256 of the price for the bid
    * @param _duration - uint256 of the duration in seconds for the bid
    * @param _fingerprint - bytes of ERC721 token fingerprint 
    * @param _name - string of bid name
    * @param _description - string of bid description
    */
    function _placeBid(
        address _tokenAddress, 
        uint256 _tokenId,
        uint256 _price,
        uint256 _duration,
        bytes memory _fingerprint,
        string memory _name,
        string memory _description,
        string memory _bidImage
    )
        private
        whenNotPaused()
    {
        _requireERC721(_tokenAddress);
        // _requireComposableERC721(_tokenAddress, _tokenId, _fingerprint);

        require(_price > 0, "Price should be bigger than 0");

        uint8 auctionType = IEGGVERSEAuction(auctionContract).getAuctionId(_tokenId);
        
        if(auctionType != 0) {
            _requireAddressBalance(msg.sender, _price);
        }

        require(
            _duration >= MIN_BID_DURATION, 
            "The bid should be last longer than a minute"
        );

        require(
            _duration <= MAX_BID_DURATION, 
            "The bid can not last longer than 6 months"
        );

        isTokenOwner(_tokenAddress, _tokenId);
        uint256 expiresAt = block.timestamp.add(_duration);

        bytes32 bidId = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                _tokenAddress,
                _tokenId,
                _price,
                _duration,
                _fingerprint,
                _name,
                _description
            )
        );

        uint256 bidIndex;

        if (_bidderHasABid(_tokenAddress, _tokenId, msg.sender)) {
            bytes32 oldBidId;
            (bidIndex, oldBidId,,,) = getBidByBidder(_tokenAddress, _tokenId, msg.sender);
            
            // Delete old bid reference
            delete bidIndexByBidId[oldBidId];
        } else {
            // Use the bid counter to assign the index if there is not an active bid. 
            bidIndex = bidCounterByToken[_tokenAddress][_tokenId];  
            // Increase bid counter 
            bidCounterByToken[_tokenAddress][_tokenId]++;
        }

        // Set bid references
        bidIdByTokenAndBidder[_tokenAddress][_tokenId][msg.sender] = bidId;
        bidIndexByBidId[bidId] = bidIndex;

        // Save Bid
        bidsByToken[_tokenAddress][_tokenId][bidIndex] = Bid({
            id: bidId,
            bidder: msg.sender,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            price: _price,
            expiresAt: expiresAt,
            fingerprint: _fingerprint,
            name: _name,
            description: _description,
            bidImage: _bidImage
        });

        // auction 컨트랙트 데이터 등록용 함수 호출
        if(address(0) != auctionContract && _tokenAddress == auctionContract){

            // auction 상태 업데이트
            // uint256 _tokenId, address acceptBidder, uint256 acceptedAt, uint256 acceptedPrice
            IEGGVERSEAuction(auctionContract).placeBid(_tokenId, bidId, msg.sender, _price);
        }

        emit BidCreated(
            bidId,
            _tokenAddress,
            _tokenId,
            msg.sender,
            _price,
            expiresAt,
            _fingerprint,
            _name,
            _description,
            _bidImage
        );
    }

    function isTokenOwner(address _tokenAddress, uint256 _tokenId)
    public view
    {
        ERC721Interface token = ERC721Interface(_tokenAddress);
        address tokenOwner = token.ownerOf(_tokenId);
        require(
            tokenOwner != address(0) && tokenOwner != msg.sender,
            "The token should have an owner different from the sender"
        );

    }


    /**
    * @dev Used as the only way to accept a bid. 
    * The token owner should send the token to this contract using safeTransferFrom.
    * The last parameter (bytes) should be the bid id.
    * @notice  The ERC721 smart contract calls this function on the recipient
    * after a `safetransfer`. This function MAY throw to revert and reject the
    * transfer. Return of other than the magic value MUST result in the
    * transaction being reverted.
    * Note: 
    * Contract address is always the message sender.
    * This method should be seen as 'acceptBid'.
    * It validates that the bid id matches an active bid for the bid token.
    * @param _from The address which previously owned the token
    * @param _tokenId The NFT identifier which is being transferred
    * @param _data Additional data with no specified format
    * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    */
    function onERC721Received(
        address _from,
        address /*_to*/,
        uint256 _tokenId,
        bytes memory _data
    )
        public
        whenNotPaused()
        returns (bytes4)
    {
        bytes32 bidId = _bytesToBytes32(_data);
        uint256 bidIndex = bidIndexByBidId[bidId];

        // _getBid(address _tokenAddress, uint256 _tokenId, uint256 _index) 
        Bid memory bid = _getBid(msg.sender, _tokenId, bidIndex);

        // Check if the bid is valid.
        require(
            // solium-disable-next-line operator-whitespace
            bid.id == bidId &&
            bid.expiresAt >= block.timestamp, 
            "Invalid bid"
        );

        address bidder = bid.bidder;
        uint256 price = bid.price;
        
        // Check fingerprint if necessary
        _requireComposableERC721(msg.sender, _tokenId, bid.fingerprint);

        uint8 auctionType = IEGGVERSEAuction(auctionContract).getAuctionId(_tokenId);
        if(auctionType == 0) {
            // 역경매 : Check if orderer has funds
            _requireAddressBalance(_from, price);
        } else {
            // 경매 : Check if bidder has fundes
            _requireAddressBalance(bidder, price);
        }

        delete bidsByToken[msg.sender][_tokenId][bidIndex];
        delete bidIndexByBidId[bidId];
        delete bidIdByTokenAndBidder[msg.sender][_tokenId][bidder];

        // Reset bid counter to invalidate other bids placed for the token
        delete bidCounterByToken[msg.sender][_tokenId];
        
        // Transfer token to bidder
        // ERC721Interface(msg.sender).transferFrom(address(this), bidder, _tokenId);

        uint256 saleShareAmount = 0;

        // Transfer EGGT from offerer to bidding contract
        if(auctionType == 0) {
            require(
                eggtToken.transferFrom(_from, address(this), price),
                "Transfering EGGT to contract failed"
            );
        } else {
            require(
                eggtToken.transferFrom(bidder, address(this), price),
                "Transfering EGGT to contract failed"
            );
        }

        uint256 categoryId = IEGGVERSEAuction(auctionContract).getAuctionCategory(_tokenId);
        if (ownerCutPerMillion[categoryId] > 0) {
            // Calculate sale share
            saleShareAmount = price.mul(ownerCutPerMillion[categoryId]).div(ONE_MILLION);
            // Transfer share amount to the bid conctract Owner
            require(
                eggtToken.transfer(owner(), saleShareAmount),
                "Transfering the cut to the bid contract owner failed"
            );
        }

        // Delete bid references from contract storage
        Order memory order = Order({
            orderer: _from, // 역경매 제시자(구매자) 
            bidder: bid.bidder, // 판매자
            tokenAddress: msg.sender,
            tokenId: bid.tokenId,
            price: price.sub(saleShareAmount), // 이러면 수수료는 판매자가 지불하는 것.
            expiresAt: block.timestamp + 14 days // tmp value
        });
        orders[msg.sender][_tokenId] = order;

        // event BidAccepted(
        //   bytes32 _id,
        //   address indexed _tokenAddress,
        //   uint256 indexed _tokenId,
        //   address _bidder,
        //   address indexed _seller,
        //   uint256 _price,
        //   uint256 _fee
        // );
        emit BidAccepted(
            bidId,
            msg.sender, // auction 주소
            _tokenId,
            bidder, // 판매자 // gql _bidder
            _from, // 역경매 제시자(구매자) // gql _seller
            price,
            saleShareAmount
        );

        // auction 컨트랙트 데이터 등록용 함수 호출
        if(address(0) != auctionContract && msg.sender == auctionContract){
            // auction 상태 업데이트
            // uint256 _tokenId, address acceptBidder, uint256 acceptedAt, uint256 acceptedPrice, bytes32 acceptedBidId, uint256 acceptedBidImage, string memory acceptedBidName, string memory acceptedBidDescription
            IEGGVERSEAuction(auctionContract).acceptBid(_tokenId, bidder, block.timestamp, price, bidId, bid.bidImage, bid.name, bid.description);
        }

        return ERC721_Received;
    }

    function getOrder(address _tokenAddress, uint256 _tokenId) public view returns (address, address, uint256){
        Order memory order = orders[_tokenAddress][_tokenId];
        return (
            order.bidder,
            order.orderer,
            order.price
        );
    }

    function finalizeOrder(address _tokenAddress, uint256 _tokenId, string memory cid) public {
        Order memory order = orders[_tokenAddress][_tokenId];
        uint8 auctionType = IEGGVERSEAuction(auctionContract).getAuctionId(_tokenId);
        require(
            (order.orderer == msg.sender && auctionType == 0) ||
            (order.bidder == msg.sender && auctionType != 0)
        );
        address bidder = order.bidder;
        address orderer = order.orderer;
        uint256 price = order.price;
        
        if(auctionType == 0) {
            // 역경매
            require(
                eggtToken.transfer(bidder, price),
                "Transfering EGGT to bidder failed"
            );
        } else {
            // 일반 경매
            require(
                eggtToken.transfer(orderer, price),
                "Transfering EGGT to orderer failed"
            );
        }

        //   string memory URI = ERC721Interface(_tokenAddress).tokenURI(_tokenId);
        uint256 certificateTokenId = ERC721Interface(_certificateAddress).mint(bidder, cid);

        // auction에 이벤트 보냄
        // auction 컨트랙트 데이터 등록용 함수 호출
        if(address(0) != auctionContract && _tokenAddress == auctionContract){
            // auction 상태 업데이트
            // uint256 _tokenId, uint256 _certificateTokenId
            IEGGVERSEAuction(auctionContract).finalizeOrder(_tokenId, certificateTokenId);
        }


        delete orders[_tokenAddress][_tokenId];
    }

    function forceFinalizeOrder(address _tokenAddress, uint256 _tokenId, string memory cid) onlyOwner public {
        Order memory order = orders[_tokenAddress][_tokenId];
        // require(order.orderer == msg.sender);
        address bidder = order.bidder;
        address orderer = order.orderer;
        uint256 price = order.price;

        uint8 auctionType = IEGGVERSEAuction(auctionContract).getAuctionId(_tokenId);
        
        if(auctionType == 0) {
            // 역경매
            require(
                eggtToken.transfer(bidder, price),
                "Transfering EGGT to bidder failed"
            );
        } else {
            // 일반 경매
            require(
                eggtToken.transfer(orderer, price),
                "Transfering EGGT to orderer failed"
            );
        }

        //   string memory URI = ERC721Interface(_tokenAddress).tokenURI(_tokenId);
        uint256 certificateTokenId = ERC721Interface(_certificateAddress).mint(bidder, cid);

        // auction에 이벤트 보냄
        // auction 컨트랙트 데이터 등록용 함수 호출
        if(address(0) != auctionContract && _tokenAddress == auctionContract){
            // auction 상태 업데이트
            // uint256 _tokenId, uint256 _certificateTokenId
            IEGGVERSEAuction(auctionContract).finalizeOrder(_tokenId, certificateTokenId);
        }


        delete orders[_tokenAddress][_tokenId];
    }

    function forceCancelOrder(address _tokenAddress, uint256 _tokenId) onlyOwner public {
        Order memory order = orders[_tokenAddress][_tokenId];
        // require(order.orderer == msg.sender);
        address bidder = order.bidder;
        address orderer = order.orderer;
        uint256 price = order.price;

        uint8 auctionType = IEGGVERSEAuction(auctionContract).getAuctionId(_tokenId);
        
        if(auctionType == 0) {
            // 역경매
            require(
                eggtToken.transfer(orderer, price),
                "Transfering EGGT to bidder failed"
            );
        } else {
            // 경매
            require(
                eggtToken.transfer(bidder, price),
                "Transfering EGGT to orderer failed"
            );
        }

        // auction에 이벤트 보냄
        // auction 컨트랙트 데이터 등록용 함수 호출
        if(address(0) != auctionContract && _tokenAddress == auctionContract){
            // auction 상태 업데이트
            // uint256 _tokenId
            IEGGVERSEAuction(auctionContract).cancelOrder(_tokenId);
        }


        delete orders[_tokenAddress][_tokenId];
    }

    function setCertificateAddress(address _tokenAddress) onlyOwner public {
        _certificateAddress = _tokenAddress;
    }
    /**
    * @dev Remove expired bids
    * @param _tokenAddresses - address[] of the ERC721 tokens
    * @param _tokenIds - uint256[] of the token ids
    * @param _bidders - address[] of the bidders
    */
    function removeExpiredBids(address[] memory _tokenAddresses, uint256[] memory _tokenIds, address[] memory _bidders)
    public 
    {
        uint256 loopLength = _tokenAddresses.length;

        require(loopLength == _tokenIds.length, "Parameter arrays should have the same length");
        require(loopLength == _bidders.length, "Parameter arrays should have the same length");

        for (uint256 i = 0; i < loopLength; i++) {
            _removeExpiredBid(_tokenAddresses[i], _tokenIds[i], _bidders[i]);
        }
    }
    
    /**
    * @dev Remove expired bid
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _bidder - address of the bidder
    */
    function _removeExpiredBid(address _tokenAddress, uint256 _tokenId, address _bidder)
    internal 
    {
        (uint256 bidIndex, bytes32 bidId,,,uint256 expiresAt) = getBidByBidder(
            _tokenAddress, 
            _tokenId,
            _bidder
        );
        
        require(expiresAt < block.timestamp, "The bid to remove should be expired");

        _cancelBid(
            bidIndex, 
            bidId, 
            _tokenAddress, 
            _tokenId, 
            _bidder
        );
    }

    /**
    * @dev Cancel a bid for an ERC721 token
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    */
    function cancelBid(address _tokenAddress, uint256 _tokenId) public whenNotPaused() {
        // Get active bid
        (uint256 bidIndex, bytes32 bidId,,,) = getBidByBidder(
            _tokenAddress, 
            _tokenId,
            msg.sender
        );

        _cancelBid(
            bidIndex, 
            bidId, 
            _tokenAddress, 
            _tokenId, 
            msg.sender
        );
    }

    /**
    * @dev Cancel a bid for an ERC721 token
    * @param _bidIndex - uint256 of the index of the bid
    * @param _bidId - bytes32 of the bid id
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _bidder - address of the bidder
    */
    function _cancelBid(
        uint256 _bidIndex,
        bytes32 _bidId, 
        address _tokenAddress,
        uint256 _tokenId, 
        address _bidder
    ) 
        internal 
    {
        // Delete bid references
        delete bidIndexByBidId[_bidId];
        delete bidIdByTokenAndBidder[_tokenAddress][_tokenId][_bidder];
        
        // Check if the bid is at the end of the mapping
        uint256 lastBidIndex = bidCounterByToken[_tokenAddress][_tokenId].sub(1);
        if (lastBidIndex != _bidIndex) {
            // Move last bid to the removed place
            Bid storage lastBid = bidsByToken[_tokenAddress][_tokenId][lastBidIndex];
            bidsByToken[_tokenAddress][_tokenId][_bidIndex] = lastBid;
            bidIndexByBidId[lastBid.id] = _bidIndex;
        }
        
        // Delete empty index
        delete bidsByToken[_tokenAddress][_tokenId][lastBidIndex];

        // Decrease bids counter
        bidCounterByToken[_tokenAddress][_tokenId]--;

        // emit BidCancelled event
        emit BidCancelled(
            _bidId,
            _tokenAddress,
            _tokenId,
            _bidder
        );
    }

    /**
    * @dev Check if the bidder has a bid for an specific token.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _bidder - address of the bidder
    * @return bool whether the bidder has an active bid
    */
    function _bidderHasABid(address _tokenAddress, uint256 _tokenId, address _bidder) 
        internal
        view 
        returns (bool)
    {
        bytes32 bidId = bidIdByTokenAndBidder[_tokenAddress][_tokenId][_bidder];
        uint256 bidIndex = bidIndexByBidId[bidId];
        // Bid index should be inside bounds
        if (bidIndex < bidCounterByToken[_tokenAddress][_tokenId]) {
            Bid memory bid = bidsByToken[_tokenAddress][_tokenId][bidIndex];
            return bid.bidder == _bidder;
        }
        return false;
    }

    /**
    * @dev Get the active bid id and index by a bidder and an specific token. 
    * @notice If the bidder has not a valid bid, the transaction will be reverted.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the token id
    * @param _bidder - address of the bidder
    * @return bidIndex - uint256 of the bid index to be used within bidsByToken mapping
    * @return bidId - bytes32 of the bid id
    * @return bidder - address of the bidder address
    * @return price - uint256 of the bid price
    * @return expiresAt - uint256 of the expiration time
    */
    function getBidByBidder(address _tokenAddress, uint256 _tokenId, address _bidder) 
        public
        view 
        returns (
            uint256 bidIndex, 
            bytes32 bidId, 
            address bidder, 
            uint256 price, 
            uint256 expiresAt
        ) 
    {
        bidId = bidIdByTokenAndBidder[_tokenAddress][_tokenId][_bidder];
        bidIndex = bidIndexByBidId[bidId];
        (bidId, bidder, price, expiresAt) = getBidByToken(_tokenAddress, _tokenId, bidIndex);
        if (_bidder != bidder) {
            revert("Bidder has not an active bid for this token");
        }
    }

    function getBidByToken(address _tokenAddress, uint256 _tokenId, uint256 _index) 
        public 
        view
        returns (bytes32, address, uint256, uint256) 
    {
        
        Bid memory bid = _getBid(_tokenAddress, _tokenId, _index);
        return (
            bid.id,
            bid.bidder,
            bid.price,
            bid.expiresAt
        );
    }

    /**
    * @dev Get the active bid id and index by a bidder and an specific token. 
    * @notice If the index is not valid, it will revert.
    * @param _tokenAddress - address of the ERC721 token
    * @param _tokenId - uint256 of the index
    * @param _index - uint256 of the index
    * @return Bid
    */
    function _getBid(address _tokenAddress, uint256 _tokenId, uint256 _index) 
        internal 
        view 
        returns (Bid memory)
    {
        require(_index < bidCounterByToken[_tokenAddress][_tokenId], "Invalid index");
        return bidsByToken[_tokenAddress][_tokenId][_index];
    }

    /**
    * @dev Sets the share cut for the owner of the contract that's
    * charged to the seller on a successful sale
    * @param _ownerCutPerMillion - Share amount, from 0 to 999,999
    */
    function setOwnerCutPerMillion(uint256 categoryId, uint256 _ownerCutPerMillion) external onlyOwner {
        require(_ownerCutPerMillion < ONE_MILLION, "The owner cut should be between 0 and 999,999");

        ownerCutPerMillion[categoryId] = _ownerCutPerMillion;
        emit ChangedOwnerCutPerMillion(categoryId, _ownerCutPerMillion);
    }

    /**
    * @dev Convert bytes to bytes32
    * @param _data - bytes
    * @return bytes32
    */
    function _bytesToBytes32(bytes memory _data) internal pure returns (bytes32) {
        require(_data.length == 32, "The data should be 32 bytes length");

        bytes32 bidId;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            bidId := mload(add(_data, 0x20))
        }
        return bidId;
    }

    /**
    * @dev Check if the token has a valid ERC721 implementation
    * @param _tokenAddress - address of the token
    */
    function _requireERC721(address _tokenAddress) internal view {
        require(_tokenAddress.isContract(), "Token should be a contract");

        ERC721Interface token = ERC721Interface(_tokenAddress);
        require(
            token.supportsInterface(ERC721_Interface),
            "Token has an invalid ERC721 implementation"
        );
    }

    /**
    * @dev Check if the token has a valid Composable ERC721 implementation
    * And its fingerprint is valid
    * @param _tokenAddress - address of the token
    * @param _tokenId - uint256 of the index
    * @param _fingerprint - bytes of the fingerprint
    */
    function _requireComposableERC721(
        address _tokenAddress,
        uint256 _tokenId,
        bytes memory _fingerprint
    )
        internal
        view
    {
        ERC721Verifiable composableToken = ERC721Verifiable(_tokenAddress);
        if (composableToken.supportsInterface(ERC721Composable_ValidateFingerprint)) {
            require(
                composableToken.verifyFingerprint(_tokenId, _fingerprint),
                "Token fingerprint is not valid"
            );
        }
    }

    /**
    * @dev Check if the bidder has balance and the contract has enough allowance
    * to use bidder EGGT on his belhalf
    * @param _bidder - address of bidder
    * @param _amount - uint256 of amount
    */
    function _requireAddressBalance(address _bidder, uint256 _amount) internal view {
        require(
            eggtToken.balanceOf(_bidder) >= _amount,
            "Insufficient funds"
        );
        require(
            eggtToken.allowance(_bidder, address(this)) >= _amount,
            "The contract is not authorized to use EGGT on bidder behalf"
        );        
    }

    /**
    * @dev set bid Contract address
    */
    function setAuctionContract(address _auctionContract) external onlyOwner{
        auctionContract = _auctionContract;
    }

    /**
    * @dev certificate의 owner는 bid 컨트랙트로 설정된다. bid 컨트랙트를 변경할 때 이전 certifiate 컨트랙트를 그대로 사용하기 위해 이 함수를 호출한다. 
    */
    function transferCertificateOwnership(address newBidContract) external onlyOwner {
        CertificateInterface(_certificateAddress).transferOwnership(newBidContract);
    }

}

interface IEGGVERSEAuction {
    function acceptBid(
        uint256 _tokenId,
        address acceptBidder,
        uint256 acceptedAt,
        uint256 acceptedPrice,
        bytes32 acceptedBidId,
        string memory acceptedBidImage,
        string memory acceptedBidName,
        string memory acceptedBidDescription
    ) external;
    function finalizeOrder(uint256 _tokenId, uint256 _certificateTokenId) external;
    function cancelOrder(uint256 _tokenId) external;
    function placeBid(uint256 _tokenId, bytes32 bidId, address bidder, uint256 price) external;
    function getAuctionCategory(uint256 _auctionType) external returns (uint256);
    function getAuctionId(uint256 _tokenId) external returns (uint8);
}