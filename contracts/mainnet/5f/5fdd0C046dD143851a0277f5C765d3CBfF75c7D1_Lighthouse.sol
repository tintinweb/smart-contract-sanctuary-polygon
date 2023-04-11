// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILighthouse.sol";
import "./utils/Address.sol";
import "./utils/StorageSlot.sol";
import "./utils/Ownable.sol";


/// @title Lighthouse
/// @notice This contract implements a Lighthouse that stores the implementation address for each source.
/// @dev Each sourceOwner can an implementationAddress for each , thus upgrading the proxies that use this lighthouse.
contract Lighthouse is 
    ILighthouse, 
    Ownable
{
    /**
     * PUBLIC VARIABLES
     */

    address  public defaultDelegatedSource;

    mapping(address => address) public delegatedSource;

    mapping(address => mapping( bytes32 => address)) public implementation;

    /**
     * PRIVATE VARIABLES
     */

    mapping(address => address) private sourceOwner;


    /**
     * MODIFIERS
     */

    /**
     * @dev Throws if called by any account other than the sourceOwner.
     */
    modifier onlySourceOwner(
        address source
    ) 
    {
        _checkSourceOwner(source);
        _;
    }


    /**
     * INITIALIZE
     */

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the Lighthouse
     */
    constructor(
        address _defaultDelegatedSource
    ) 
    {
        defaultDelegatedSource = _defaultDelegatedSource;
    }

    function setDefaultDelegatedSource(
        address _defaultDelegatedSource
    ) 
        external 
        onlyOwner
    {
        defaultDelegatedSource = _defaultDelegatedSource;
    }


    /**
     * PUBLIC FUNCTIONS
     */

    function initializeSource(
        address _sourceOwner,
        address _delegatedSource
    ) 
        external
    {
        _checkInitialized(msg.sender);

        if(_sourceOwner == address(0))
            _sourceOwner = msg.sender;

        if(_delegatedSource == address(0))
            _delegatedSource = defaultDelegatedSource;
            
        _changeSourceOwner(msg.sender, _sourceOwner);
        _setDelegatedSource(msg.sender, _delegatedSource);
    }

    /**
     * @dev Upgrades the lighthouse source to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the source.
     * - `newImplementation` must be a contract.
     */
    function changeImplementation(
        address source,
        bytes32 id,
        address newImplementation
    ) 
        public 
        virtual 
        onlySourceOwner(source)
    {
        _setImplementation(source, id, newImplementation);

        emit ImplementationChanged(
            source,
            id,
            newImplementation
        );
    }

    /**
     * @dev Upgrades the lighthouse source to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the source.
     * - `newImplementation` must be a contract.
     */
    function changeImplementationBatch(
        address source,
        address[] memory implementationAddresses,
        bytes32[] memory implementationIds
    ) 
        external
        onlySourceOwner(source)
    {
        if(implementationAddresses.length != implementationIds.length)
            revert("Lighthouse: implementationAddresses and implementationIds must have the same length");

        for (uint256 i = 0; i < implementationIds.length; i++)
        {
            _setImplementation(
                source, 
                implementationIds[i], 
                implementationAddresses[i]
            );
        }
    }

    function changeDelegatedSource(
        address source,
        address newDelegatedSource
    ) 
        external
        onlySourceOwner(source)
    {
        _setDelegatedSource(
            source, 
            newDelegatedSource
        );

        emit DelegatedSourceChanged(
            source,
            newDelegatedSource
        );
    }

    /**
     * @dev Leaves the source without owner. It will not be possible to call related
     * `onlySourceOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceSourceOwner(
        address source
    ) 
        public 
        virtual 
        onlySourceOwner (source)
    {
        _changeSourceOwner(
            source, 
            address(0)
        );
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function changeSourceOwner(
        address source,
        address newSourceOwner
    ) 
        public 
        virtual 
        onlySourceOwner (source)
    {
        require(
            newSourceOwner != address(0), 
            "Lighthouse: new owner is the zero address"
        );

        _changeSourceOwner(
            source, 
            newSourceOwner
        );
    }


    /**
     * INTERNAL FUNCTIONS
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _changeSourceOwner(
        address source,
        address newSourceOwner
    ) 
        internal 
        virtual 
    {
        address oldSourceOwner = getSourceOwner(source);

        _setSourceOwner(
            source, 
            newSourceOwner
        );

        emit SourceOwnerTransferred(
            source,
            oldSourceOwner, 
            newSourceOwner
        );
    }

    /**
     * @dev Sets the implementation contract address for this lighthouse source
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(
        address source,
        bytes32 id,
        address newImplementation
    ) 
        private 
    {
        if(!Address.isContract(newImplementation))
            revert Lighthouse_ImplementationNotContract();
            
        implementation[source][id] = newImplementation;
    }
    /**
     * @dev Stores a new address as sourceOwner
     */
    function _setSourceOwner(
        address source,
        address newSourceOwner
    ) 
        private 
    {
        require(
            newSourceOwner != address(0), 
            "Lighthouse: new sourceOwner is the zero address"
        );

        sourceOwner[source] = newSourceOwner;
    }

    /**
     * @dev Stores a new address as delegatedSource
     */
    function _setDelegatedSource(
        address source,
        address newDelegatedSource
    ) 
        private 
    {
        require(
            newDelegatedSource != address(0), 
            "Lighthouse: new delegatedSource is the zero address"
        );

        delegatedSource[source] = newDelegatedSource;
    }


    /**
     * READ-ONLY FUNCTIONS
     */

    function isInitialized(
        address source
    ) 
        external
        view
        returns(bool)
    {
        return getSourceOwner(source) == address(0);
    }
    
    function getImplementation(
        address source,
        bytes32 id
    ) 
        public 
        view 
        virtual 
        returns (address) 
    {
        return implementation[delegatedSource[source]][id];
    }
   

    /**
     * @dev Returns the address of the current sourceOwner.
     */
    function getSourceOwner(
        address source
    ) 
        public 
        view 
        virtual
        override
        returns (address) 
    {
        return sourceOwner[source];
    }

    /**
     * @dev Returns the address of the current sourceOwner.
     */
    function getDelegatedSource(
        address source
    ) 
        public 
        view 
        virtual
        override
        returns (address) 
    {
        return delegatedSource[source];
    }

    /**
     * @dev Throws if the sender is not the sourceOwner.
     */
    function _checkSourceOwner(
        address source
    ) 
        internal 
        view 
        virtual 
    {
        require(
            getSourceOwner(source) == _msgSender(), 
            "Lighthouse: caller is not the sourceOwner"
        );
    }

    /**
     * @dev Throws if the sender is not the sourceOwner.
     */
    function _checkInitialized(
        address source
    ) 
        internal 
        view 
        virtual 
    {
        require(
            getSourceOwner(source) == address(0), 
            "Lighthouse: source already intialize"
        );
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./errors/ILighthouseErrors.sol";
import "./events/ILighthouseEvents.sol";

/// @title Lighthouse
/// @notice This interface defines the functions that a Lighthouse must implement
interface ILighthouse is
    ILighthouseErrors,
    ILighthouseEvents
{
    /**
     * EXTERNAL FUNCTIONS
     */

    /**
     * @dev address must be contract
     */

    function initializeSource(
        address sourceOwner,
        address delegatedSource
    ) 
        external;

    function changeImplementationBatch(
        address source,
        address[] memory implementationAddresses,
        bytes32[] memory implementationIds
    ) 
        external;

    function changeDelegatedSource(
        address source,
        address newDelegatedSource
    ) 
        external;

    function isInitialized(
        address source
    ) 
        external
        view
        returns(bool);

    function getImplementation(
        address source,
        bytes32 id
    ) 
        external 
        view 
        returns (address);

    function getSourceOwner(
        address source
    ) 
        external 
        view 
        returns (address);

    function getDelegatedSource(
        address source
    ) 
        external 
        view 
        returns (address);

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Lighthouse Errors
/// @notice This interface defines the errors for Lighthouse
interface ILighthouseErrors{
    /**
     * ERRORS
     */
    
    error Lighthouse_ImplementationNotContract();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Events emitted by the Lighthouse
/// @notice Contains all events emitted by the Lighthouse
interface ILighthouseEvents{
    /**
     * EVENTS
     */

    /**
     * @dev Emitted when the source has changed.
     */
    event SourceChanged(
        address previousSource, 
        address newSource
    );

    /**
     * @dev Emitted when the source has changed.
     */
    event IdChanged(
        bytes32 previousId, 
        bytes32 newId
    );

    /**
     * @dev Emitted when the implementation returned by the lighthouse is changed.
     */
    event ImplementationChanged(
        address source,
        bytes32 id,
        address implementation
    );

    /**
     * @dev
     */
    event SourceOwnerTransferred(
        address source, 
        address previousOwner, 
        address newOwner
    );

    /**
     * @dev
     */
    event DelegatedSourceChanged(
        address source, 
        address newDelegatedSource
    );
}

// SPDX-License-Identifier: MIT
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