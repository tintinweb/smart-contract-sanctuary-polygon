/**
 *Submitted for verification at polygonscan.com on 2022-04-16
*/

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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


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

// File: launchpad.sol


pragma solidity ^0.8.0;




// only for debugging
// import "hardhat/console.sol";

contract Launchpad is Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    event EventLaunched(
        uint256 indexed projectId,
        uint256 indexed startTime,
        uint256 price,
        uint256 stock
    );
    event WhitelistedUser(uint256 indexed projectId, address[] indexed users);
    event UndoWhitelistedUsers(
        uint256 indexed projectId,
        address[] indexed users
    );
    event UpdatePriceAndStock(
        uint256 indexed projectId,
        uint256 updatedPrice,
        uint256 updatedStock
    );
    event EventEnded(uint256 indexed projectId);
    event PurchasedNfts(
        uint256 indexed projectId,
        uint256 amountBought,
        uint256 amountPaid
    );
    event TokenUpdated(address indexed oldAddress, address indexed updatedAddress);

    // structure to hold the event description
    struct Project {
        uint256 id; // Project Id
        address projectOwner; // owner of the event
        uint256 stock; // Number of nft available in the event
        uint256 startTime; // time at which event will start
        uint256 price; // price for which nft will be sold
        uint256 sold; // number of nft sold in that event
        uint256 maxCap; // max no, of NFT that the user can buy
        bool endEvent; // bool if the event has ended
        bool whitelisted; // true if there will be whitelisted addresses
    }

    uint256[] public listProjectIds;
    mapping(uint256 => uint256) public collection; // collection made by a certain event
    mapping(uint256 => Project) public projectDescription; // returns event description based on projectId
    mapping(uint256 => address[]) private investorsForProject; // holds the array of addresses who have invested in an event
    mapping(uint256 => mapping(address => uint256)) private nftBoughtByUser; // holds the num of nft bought by a user (projectId => user Address => nftCount)
    mapping(uint256 => mapping(address => uint256)) private amountPaidByUser; // holds the amount user have paid (projectId => user Address => amountPaid)
    mapping(uint256 => mapping(address => uint256)) public whitelistingUsers; // holds the index of whitelisted users ((projectId => user Address => addressIndex))
    mapping(uint256 => address[]) private whitelistedUsers; // array of whitelisted addresses

    Counters.Counter private _projectIdTracker;

    // TODO: Needs to be changed for mainnet deployment
    // address public USDT = 0x8DC0fAF4778076A8a6700078A500C59960880F0F; // Only for Testing on frontend

    /// @notice USDT address on polygon mainnet
    address public usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    // modifier to check if the event exists or not
    modifier eventExist(uint256 projectId) {
        require(
            projectDescription[projectId].projectOwner != address(0),
            "Invalid Id"
        );
        _;
    }

    /// @notice updates the address of USDT
    /// @dev onlyOwner function
    function updateTokenAddress(address _usdt) external onlyOwner {
        require(_usdt != address(0), "Zero Address");
        address oldAddress = usdt;
        usdt = _usdt;

        emit TokenUpdated(oldAddress, _usdt);
    }

    /**
     * @notice Contract owner will launch the event after which it will be
     * available for the user
     * @param stock Number of NFT available for the User to buy from that event
     * @param startTime The Unix timestamp at which the launch will start
     * @param price The price at which user will buy NFT
     * @param maxCap Max number of NFT that a single user can buy,
     * if there is no limit then it can be 0
     * @param whitelisted If the event is for whitelisted users only then true
     *
     * @return projectId returns the projectId that will be created
     */
    function launchEvent(
        uint256 stock,
        uint256 startTime,
        uint256 price,
        uint256 maxCap,
        bool whitelisted
    ) public onlyOwner returns (uint256 projectId) {
        require(startTime >= block.timestamp, "Invalid Start Time");

        _projectIdTracker.increment();
        uint256 idTracker = _projectIdTracker.current();

        projectId = uint256(keccak256(abi.encodePacked(msg.sender, idTracker)));

        listProjectIds.push(projectId);

        projectDescription[projectId] = Project({
            id: projectId,
            projectOwner: msg.sender,
            stock: stock,
            startTime: startTime,
            endEvent: false,
            price: price,
            maxCap: maxCap,
            sold: 0,
            whitelisted: whitelisted
        });

        emit EventLaunched(projectId, startTime, price, stock);
    }

    /**
     * @notice Whitelist the users so that they can buy NFT on the private launchpad
     * @param projectId projectId for which the user will be whitelisted
     * @param users array of addresses that will be whitelisted
     *
     * @custom:note only Contract Owner can do the whitelisting
     */
    function whitelistUsers(uint256 projectId, address[] memory users)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            // if the address is already whitelisted, then it wont be
            // added to the array again
            if (whitelistingUsers[projectId][users[i]] == 0) {
                whitelistedUsers[projectId].push(users[i]);
                whitelistingUsers[projectId][users[i]] = whitelistedUsers[
                    projectId
                ].length;
            }
        }

        emit WhitelistedUser(projectId, users);
    }

    /**
     * @notice unWhitelist the whitelisted users so that they can not buy NFT
     * from the private launchpad
     * @param projectId projectId for which the user will be whitelisted
     * @param users array of addresses that will be unwhitelisted
     *
     * @custom:note only Contract Owner can do the unwhitelisting
     */
    function undoWhitelistedUsers(uint256 projectId, address[] memory users)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            if (whitelistingUsers[projectId][users[i]] > 0) {
                uint256 indexOfUser = whitelistingUsers[projectId][users[i]] -
                    1;
                address lastAddressOfArray = whitelistedUsers[projectId][
                    whitelistedUsers[projectId].length - 1
                ];
                uint256 lastIndex = whitelistingUsers[projectId][
                    lastAddressOfArray
                ] - 1;

                whitelistedUsers[projectId][indexOfUser] = whitelistedUsers[
                    projectId
                ][lastIndex];
                whitelistingUsers[projectId][users[i]] = 0;
                whitelistingUsers[projectId][lastAddressOfArray] =
                    indexOfUser +
                    1;
                whitelistedUsers[projectId].pop();
            }
        }

        emit UndoWhitelistedUsers(projectId, users);
    }

    /**
     * @notice updates the price and stock of the event even during the event is ongoing
     * @param projectId projetctId for which the price and stock will be updated
     * @param price the new price for which the nft will get sold
     * @param stock the new stock that will be available to user to buy nft
     */
    function updatePriceAndStock(
        uint256 projectId,
        uint256 price,
        uint256 stock
    ) external eventExist(projectId) {
        require(
            projectDescription[projectId].projectOwner == msg.sender,
            "Not Owner"
        );

        Project storage project = projectDescription[projectId];
        require(project.sold <= stock, "Raise the stock amount");

        project.price = price;
        project.stock = stock;

        emit UpdatePriceAndStock(projectId, price, stock);
    }

    /**
     * @notice The event can be ended by the owner, after which no one will be
     * able to buy the nft
     * @param projectId Id for the project, which will be ended
     *
     * @dev onlyOwner of contract can end the event
     */
    function endEvent(uint256 projectId) external eventExist(projectId) {
        require(
            projectDescription[projectId].projectOwner == msg.sender,
            "Not Owner"
        );

        Project storage project = projectDescription[projectId];

        project.endEvent = true;

        emit EventEnded(projectId);
    }

    /**
     * @notice User can buy the nft after the event goes live
     * @param projectId Id of the event for which user wants to the nft
     * @param amountBought the amount of nft that the user wants to buy
     */
    function buyTokens(uint256 projectId, uint256 amountBought) external {
        Project storage project = projectDescription[projectId];

        require(project.startTime <= block.timestamp, "Not started");

        // checks if the user is whitelisted
        if (project.whitelisted) {
            require(
                whitelistingUsers[projectId][msg.sender] > 0,
                "Not whitelisted"
            );
        }

        // checks if the user is exceeding the max limit
        if (project.maxCap > 0) {
            require(
                nftBoughtByUser[projectId][msg.sender] + amountBought <=
                    project.maxCap,
                "Max limit exceeds"
            );
        }

        require(!project.endEvent, "Ended");
        require(
            project.sold + amountBought <= project.stock,
            "Not enough stock"
        );

        IERC20(usdt).safeTransferFrom(
            msg.sender,
            address(this),
            project.price * amountBought
        );

        project.sold += amountBought;
        collection[projectId] += project.price * amountBought;

        if (nftBoughtByUser[projectId][msg.sender] == 0) {
            investorsForProject[projectId].push(msg.sender);
        }

        nftBoughtByUser[projectId][msg.sender] += amountBought;
        amountPaidByUser[projectId][msg.sender] += project.price * amountBought;

        emit PurchasedNfts(
            projectId,
            amountBought,
            project.price * amountBought
        );
    }

    /**
    * @notice transfers the usdt from the contract to the defined address
    * @param _add address that will receive the usdt
    * @param amount the amount of usdt that will be transferred
    *
    * @dev onlyOwner Function
    */
    function transferBalance(address _add, uint256 amount) public onlyOwner {
        uint256 balBefore = IERC20(usdt).balanceOf(address(this));

        IERC20(usdt).safeTransfer(_add, amount);

        require(
            IERC20(usdt).balanceOf(address(this)) == balBefore - amount,
            "Not Successful"
        );
    }

    /**
    * @notice transfers all the usdt from the contract to the defined address
    * @param _add address that will receive the usdt
    *
    * @dev onlyOwner Function
    */
    function withdrawAll(address _add) external onlyOwner {
        uint256 bal = IERC20(usdt).balanceOf(address(this));

        transferBalance(_add, bal);
    }

    function checkBalance() external view returns (uint256) {
        return IERC20(usdt).balanceOf(address(this));
    }

    function getInvestedUsers(uint256 projectId)
        external
        view
        returns (address[] memory)
    {
        return investorsForProject[projectId];
    }

    function getNftCountBought(uint256 projectId, address _add)
        external
        view
        returns (uint256)
    {
        return nftBoughtByUser[projectId][_add];
    }

    function amountPaidinProject(uint256 projectId, address _add)
        external
        view
        returns (uint256)
    {
        return amountPaidByUser[projectId][_add];
    }

    function getWhitelistedUsers(uint256 projectId)
        external
        view
        returns (address[] memory)
    {
        return whitelistedUsers[projectId];
    }
}