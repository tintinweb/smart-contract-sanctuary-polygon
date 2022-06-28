/**
 *Submitted for verification at polygonscan.com on 2022-06-27
*/

// Sources flattened with hardhat v2.9.7 https://hardhat.org

// File contracts/ChainlinkVRFProxy/consumer/ICCBVRFConsumer.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ICCBVRFConsumer {
    error ICCBVRFConsumer_RandomnessProviderUnauthorized(
        address unauthorizedProvider
    );
    error ICCBVRFConsumer_NativeFeeIncorrect(uint256 needed, uint256 provided);
    error ICCBVRFConsumer_InsufficientERC20Balance(
        address token,
        uint256 needed,
        uint256 balance
    );
    event CCBVRFRandomnessProviderSet(
        address indexed operator,
        address indexed prodiverAddress
    );

    function fulfillRandomRequestExt(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address requestOrigin,
        uint256 chainId,
        bytes32 requestId,
        bytes32 randomness
    ) external;
}


// File contracts/ChainlinkVRFProxy/producer/ICCBVRFRandomnessProvider.sol


interface ICCBVRFRandomnessProvider {
    function requestRandomness() external payable returns (bytes32 requestId);

    function fees()
        external
        view
        returns (
            uint256 nativeFee,
            address[] memory erc20Addresses,
            uint256[] memory erc20Fees
        );

    event ForwardGasSet(address indexed operator, uint256 indexed forwardGas);

    function setForwardGas(uint256 newForwardGas) external;

    function getForwardGas() external view returns (uint256 forwardGas);
}


// File contracts/ChainlinkVRFProxy/producer/proxy/ICCBVRFProducerProxy.sol


interface ICCBVRFProducerProxy is ICCBVRFRandomnessProvider {
    event RandomnessRequest(bytes32 indexed requestId);

    event NodeBackendAddressSet(
        address indexed operator,
        address indexed newNodeBackend
    );
    error ICCBVRFProducerProxy_InsufficientGasForConsumer(uint256 gasLeft);
    error ICCBVRFProducerProxy_UnauthorizedNodeBackend(
        address offendingAddress
    );
    error ICCBVRFProducerProxy_ZeroAddress();
    error ICCBVRFProducerProxy_RequestAlreadyHandled(bytes32 requestId);

    function setNodeBackendAddress(address newNodeBackend) external;

    function callBackWithRandomness(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address requestOrigin,
        uint256 chainId,
        bytes32 requestId,
        bytes32 randomness
    ) external;
}


// File contracts/util/IOwnable.sol


/// @title Ownable Interface
/// @author TIXL
/// @notice An interface for a custom implementation of Ownable contracts.
interface IOwnable {
    /// @dev Triggers when an unauthorized address attempts
    /// a restricted action
    /// @param account initiated the unauthorized action
    error Ownable_OwnershipUnauthorized(address account);
    /// @notice Triggers when assignment of a null address to the
    error Ownable_NullAddress();
    /// @dev Triggers when the ownership is transferred
    /// @param previousOwner the previous owner of the contract
    /// @param newOwner the new owner of the contract
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Returns the current owner address.
    /// @return owner the address of the current owner
    function owner() external view returns (address owner);

    /// @notice Leaves the contract without owner. It will not be possible to call
    /// `onlyOwner` functions anymore. Can only be called by the current owner.
    /// Triggers the {OwnershipTransferred} event.
    function renounceOwnershipPermanently() external;

    /// @notice Transfers the ownership to `newOwner`.
    /// Triggers the {OwnershipTransferred} event.
    /// `newOwner` can not be the zero address.
    /// @param newOwner the new owner of the contract
    function transferOwnership(address newOwner) external;
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File contracts/util/Ownable.sol



/// @title Ownable Contract
/// @author TIXL
/// @notice An abstract contract with a custom error implementation of Ownable contracts.
abstract contract Ownable is IOwnable, ERC165 {
    address private _owner;

    /// @dev Initializes the contract setting the deployer as the initial owner.
    constructor() {
        _setOwner(msg.sender);
    }

    /// @dev Reverts if called by any account other than the owner
    modifier onlyOwner() {
        if (msg.sender != _owner)
            revert Ownable_OwnershipUnauthorized(msg.sender);
        _;
    }

    /// @inheritdoc IOwnable
    function owner() public view override returns (address) {
        return _owner;
    }

    /// @inheritdoc IOwnable
    function renounceOwnershipPermanently() public override onlyOwner {
        _setOwner(address(0));
    }

    /// @inheritdoc IOwnable
    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == address(0)) revert Ownable_NullAddress();
        _setOwner(newOwner);
    }

    /// @notice this function transfers the ownership of
    /// @param newOwner the address of the new owner
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IOwnable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)


/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}


// File contracts/ChainlinkVRFProxy/producer/components/ProxyERC156Utility.sol



abstract contract ProxyERC156Utility {
    using ERC165Checker for address;

    error ProxyERC156Utility_NonConsumerCall();

    // assures that there is no revert due to mismatched interfaces later on in
    // the callback state for direct calls
    modifier assureIsConsumerContract() {
        if (!msg.sender.supportsInterface(type(ICCBVRFConsumer).interfaceId))
            revert ProxyERC156Utility_NonConsumerCall();
        _;
    }
}


// File contracts/ChainlinkVRFProxy/producer/proxy/CCBVRFProducerProxy.sol




abstract contract CCBVRFProducerProxy is
    ICCBVRFProducerProxy,
    ProxyERC156Utility,
    Ownable
{
    // the only address allowed to call the callBackWithRandomness function
    address private _nodeBackendAddress;

    // internal counter for the request ids
    uint256 private _nonce;

    // the contracts for each of the request ids
    mapping(bytes32 => address) private _callingContracts;
    // map holding whether a request has been handled
    mapping(bytes32 => bool) private _requestHandled;
    // the gas which will be forwarded to the callbacks
    uint256 private _forwardGas;

    // sets the node backend address
    constructor(address nodeBackend, uint256 forwardGas) {
        _setNodeBackendAddress(nodeBackend);
        _setForwardGas(forwardGas);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(ICCBVRFProducerProxy).interfaceId ||
            interfaceId == type(ICCBVRFRandomnessProvider).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _setNodeBackendAddress(address newNodeBackend) private {
        if (newNodeBackend == address(0))
            revert ICCBVRFProducerProxy_ZeroAddress();
        _nodeBackendAddress = newNodeBackend;
        emit NodeBackendAddressSet(msg.sender, newNodeBackend);
    }

    // update the node backend address (only owner)
    function setNodeBackendAddress(address newNodeBackend)
        external
        override
        onlyOwner
    {
        _setNodeBackendAddress(newNodeBackend);
    }

    function _setForwardGas(uint256 forwardGas) private {
        _forwardGas = forwardGas;
        emit ForwardGasSet(msg.sender, forwardGas);
    }

    // update the forward gas (only owner)
    function setForwardGas(uint256 forwardGas) external override onlyOwner {
        _setForwardGas(forwardGas);
    }

    function getForwardGas()
        external
        view
        override
        returns (uint256 forwardGas)
    {
        return _forwardGas;
    }

    // internal helper which creates the request ids
    function makeRequestId(address proxy, uint256 nonce)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(proxy, nonce));
    }

    // modifier to revert if anyone but the node backend calls a function
    modifier onlyNodeBackend() {
        if (msg.sender != _nodeBackendAddress)
            revert ICCBVRFProducerProxy_UnauthorizedNodeBackend(msg.sender);
        _;
    }

    // external function that can be used to initiate a randomness request
    function requestRandomness()
        external
        payable
        override
        assureIsConsumerContract
        returns (bytes32 requestId)
    {
        requestId = makeRequestId(address(this), _nonce++);

        // optional user defined checks
        beforeRequestRandomness(msg.sender, requestId);

        _callingContracts[requestId] = msg.sender;

        // event which will be picked up by the back end node
        emit RandomnessRequest(requestId);
    }

    function callBackWithRandomness(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address requestOrigin,
        uint256 chainId,
        bytes32 requestId,
        bytes32 randomness
    ) external override onlyNodeBackend {
        if (_requestHandled[requestId])
            revert ICCBVRFProducerProxy_RequestAlreadyHandled(requestId);
        _requestHandled[requestId] = true;

        if (gasleft() < _forwardGas)
            revert ICCBVRFProducerProxy_InsufficientGasForConsumer(gasleft());

        // constant gas
        ICCBVRFConsumer(_callingContracts[requestId]).fulfillRandomRequestExt{
            gas: _forwardGas
        }(sigV, sigR, sigS, requestOrigin, chainId, requestId, randomness);
    }

    function beforeRequestRandomness(address sender, bytes32 seed)
        internal
        virtual;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)


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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)



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


// File contracts/ChainlinkVRFProxy/producer/components/ERC20FeeHandler.sol



// TODO check if possibly alternative using tx.origin is a good idea - more complex because both
// should be checked, but can save gas due to 1 less transaction needed

abstract contract ERC20FeeHandler {
    using SafeERC20 for IERC20;
    error ERC20FeeHandler_InsufficientAllowance(
        uint256 needed,
        uint256 current
    );
    error ERC20FeeHandler_ArrayLengthMismatch(
        uint256 addressArrayLength,
        uint256 feeArrayLength
    );
    event ERC20FeeSet(
        address indexed operator,
        address indexed token,
        uint256 indexed fee
    );

    constructor(
        address[] memory erc20TokenAddresses,
        uint256[] memory erc20TokenFees
    ) {
        uint256 length = erc20TokenAddresses.length;
        if (length != erc20TokenFees.length)
            revert ERC20FeeHandler_ArrayLengthMismatch(
                erc20TokenAddresses.length,
                erc20TokenFees.length
            );
        for (uint256 i = 0; i < length; i++) {
            _setERC20Fee(erc20TokenAddresses[i], erc20TokenFees[i]);
        }
    }

    mapping(address => uint256) private _erc20Fee;

    function _getERC20Fee(address token) internal view returns (uint256) {
        return _erc20Fee[token];
    }

    function _setERC20Fee(address token, uint256 newFee) internal {
        _erc20Fee[token] = newFee;
        emit ERC20FeeSet(msg.sender, token, newFee);
    }

    function _ensureAndTakeERC20Fee(address token) internal {
        if (
            IERC20(token).allowance(msg.sender, address(this)) <
            _erc20Fee[token]
        )
            revert ERC20FeeHandler_InsufficientAllowance(
                _erc20Fee[token],
                IERC20(token).allowance(msg.sender, address(this))
            );

        IERC20(token).safeTransferFrom(
            msg.sender,
            address(this),
            _erc20Fee[token]
        );
    }

    function _withdrawErc20Fee(address token) internal {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(address(this), msg.sender, balance);
    }
}


// File contracts/ChainlinkVRFProxy/producer/components/NativeFeeHandler.sol


abstract contract NativeFeeHandler {
    error NativeFeeHandler_IncorrectMessageValue(uint256 needed, uint256 sent);
    event NativeFeeSet(address indexed operator, uint256 indexed nativeFee);

    uint256 private _nativeFee;

    function _getNativeFee() internal view returns (uint256) {
        return _nativeFee;
    }

    function _setNativeFee(uint256 newNativeFee) internal {
        _nativeFee = newNativeFee;
        emit NativeFeeSet(msg.sender, newNativeFee);
    }

    function _ensureNativeFee() internal view {
        if (msg.value != _nativeFee)
            revert NativeFeeHandler_IncorrectMessageValue(
                _nativeFee,
                msg.value
            );
    }

    function _withdrawNativeBalance() internal {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw() external virtual;

    constructor(uint256 initialNativeFee) {
        _setNativeFee(initialNativeFee);
    }
}


// File contracts/ChainlinkVRFProxy/producer/components/SingleValueToArr.sol


//solhint-disable func-name-mixedcase
//solhint-disable func-visibility
function __to_memory_arr_addr(address input) pure returns (address[] memory) {
    address[] memory arr = new address[](1);
    arr[0] = input;
    return arr;
}

function __to_memory_arr_int(uint256 input) pure returns (uint256[] memory) {
    uint256[] memory arr = new uint256[](1);
    arr[0] = input;
    return arr;
}


// File contracts/AutobahnNetwork/AutobahnCCBVRF.sol





contract AutobahnCCBVRF is
    CCBVRFProducerProxy,
    ERC20FeeHandler,
    NativeFeeHandler
{
    address private immutable LINKTOKEN;

    // sets the node backend address
    constructor(
        address nodeBackend,
        uint256 forwardGas,
        address linkToken,
        uint256 linkFee,
        uint256 nativeFee
    )
        CCBVRFProducerProxy(nodeBackend, forwardGas)
        NativeFeeHandler(nativeFee)
        ERC20FeeHandler(
            __to_memory_arr_addr(linkToken),
            __to_memory_arr_int(linkFee)
        )
    {
        LINKTOKEN = linkToken;
    }

    function beforeRequestRandomness(address, bytes32)
        internal
        virtual
        override
    {
        _ensureAndTakeERC20Fee(LINKTOKEN);
        _ensureNativeFee();
    }

    function fees()
        external
        view
        returns (
            uint256 nativeFee,
            address[] memory erc20Addresses,
            uint256[] memory erc20Fees
        )
    {
        nativeFee = _getNativeFee();
        erc20Addresses = new address[](1);
        erc20Fees = new uint256[](1);
        erc20Addresses[0] = LINKTOKEN;
        erc20Fees[0] = _getERC20Fee(LINKTOKEN);
    }

    function withdraw() external virtual override onlyOwner {
        _withdrawNativeBalance();
    }
}