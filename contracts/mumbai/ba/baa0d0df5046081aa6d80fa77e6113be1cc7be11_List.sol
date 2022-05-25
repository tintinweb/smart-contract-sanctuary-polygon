pragma solidity 0.8.9;
//SPDX-License-Identifier: MIT
// Version 3.00


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


interface IVerifierAdd {

    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[4] memory input
        ) external view returns (bool r);
} 
        
contract List is Initializable, OwnableUpgradeable, PausableUpgradeable
{
		// Version of the permalink object served by relay
		struct ObjectVersion {
			   uint128 version; // 0 - 1st version, 1 - revoked, >1 - version number
			   uint128 relayId; // relayId of SMT tree relay responsible for permalink
		   }
		
		mapping(uint256 => ObjectVersion) versions; // permalink => Version
	 
		// Relays maintaining Sparse Merkle Trees ("SMT")
		struct Relay {
			   address relayAddress;
			  // Sync roothash data to Ethereum mainnet
			   uint256 roothash; 	// roothash of the SMT
			   uint256 counter; 	// number of updates in SMT
			   uint256 timestamp; 	// timestamp of roothash update
			   bool isActive; 		// if false operations of relay are suspended except for transfers from relay
			   string ipfsHash; 	// IPFS hash of JSON configuration file describing relay API access
		}	
	 
		Relay[] public relays; // relays numbering starts from 1, relay[0] is empty
		uint128 public relaysCount; 
		mapping(address => uint128) public relaysIndex; // relayAddress => index in relays[]
	   
		// allowed transfers between relays
		// old relayId  => permalink => old relay's roothash
		mapping (uint128 => mapping(uint256 => uint256)) public allowedTransfers; 

		// Events
		event Version(uint256 indexed permalink, uint128 version, uint128 indexed relayId, uint256 indexed roothash); // new version recorded
		event Roothash(uint256 indexed roothash, uint128 indexed relayId); // Relay's roothash changed
		event Transfer(uint256 indexed permalink, uint128 indexed fromRelayId, uint128 indexed toRelayId);

		event RelayAdded(address indexed relayAddress, uint128 indexed relayId); // Added new relay
		event RelayConfig(uint128 indexed relayId, string ipfsHash); 
		event ShutdownRelay(uint128 indexed relayId);

		IVerifierAdd verifierAdd;

		function initialize(IVerifierAdd _verifierAdd) public initializer {
			 __Ownable_init();
			 __Pausable_init();
			 verifierAdd = _verifierAdd;
			 relays.push();
		 }
	   
		 modifier onlyRelay() 
		 {
			 _isRelay();
			 _;
		 }

		 function _isRelay() internal view 
		 {
			 require((relaysIndex[msg.sender] > 0) , "LIST01: not a relay"); 
		 }  
   
		 function getContractVersion() public pure
			 returns (uint64)
		 {
				 return 300; // 300 = version 3.00
		 }
   
		 function addRelay(address to)
			  external whenNotPaused onlyOwner
		 {
			  require((relaysIndex[to] == 0) , "LIST02: relay already added"); 
			  relays.push();
			  relaysCount++;
			  uint128 relayId = relaysCount;
			  relays[relayId].relayAddress = to;
			  relays[relayId].isActive = true;
			  relays[relayId].timestamp = block.timestamp;
			  relaysIndex[to] = relayId;
			  
			  emit RelayAdded(to, relayId);
			  emit Roothash( 0, relayId);
		 }
		 
		 function shutdownRelay(address to)
			  external onlyOwner
		 {
			  uint128 relayId = relaysIndex[to];
			  require( relayId > 0, "LIST02a: not a relay"); 
			  relays[relayId].isActive = false;
			  
			  emit ShutdownRelay(relayId);
		 }
  
  		 function setRelayConfig(string memory ipfsHash)
			 external whenNotPaused onlyRelay
		 { 
			  uint128 relayId = relaysIndex[msg.sender];			  
			  relays[relayId].ipfsHash = ipfsHash;
			  emit RelayConfig(relayId, ipfsHash); 
		 }
 
  
		 function add( uint[2] memory a,
					   uint[2][2] memory b,
					   uint[2] memory c,
					   uint[4] memory input) 
			 external whenNotPaused onlyRelay
		 { 
              require( verifierAdd.verifyProof(a, b, c, input) == true, "LIST03a wrong proof");
			  uint128 relayId = relaysIndex[msg.sender];
			  uint256 newRoot 	= input[0];
			  uint256 oldRoot 	= input[1];
			  uint256 permalink = input[2];
			  uint128 version 	= uint128(input[3]);
			  require(oldRoot == relays[relayId].roothash, "LIST03 wrong roothash");
			  require(versions[permalink].relayId == 0, "LIST04 already added");
			  
			  relays[relayId].timestamp = block.timestamp;
			  relays[relayId].roothash = newRoot;
			  relays[relayId].counter++;
			  
			  versions[permalink].version = version;
			  versions[permalink].relayId = relayId;
			  emit Version(permalink, version, relayId, newRoot); 
		 }
		 
		 
		 function update(	uint256 permalink, 
		 					uint128 version,
		 					uint256 oldRoot,
		 					uint256 newRoot)
			 external whenNotPaused onlyRelay
		 { 
			 // TODO: add ZK verification of newRoot
			  uint128 relayId = relaysIndex[msg.sender];
			  require(oldRoot == relays[relayId].roothash, "LIST05 wrong roothash");
			  require(versions[permalink].relayId == relayId, "LIST06 wrong relay");
			  require((version - versions[permalink].version) == 1, "LIST07 wrong version increment");
			  
			  relays[relayId].timestamp = block.timestamp;
			  relays[relayId].roothash = newRoot;
			  relays[relayId].counter++;
			  
			  versions[permalink].version = version;
			  emit Version(permalink, version, relayId, newRoot); 
		 }
		 
		 function revoke(	uint256 permalink, 
		 					uint256 oldRoot,
		 					uint256 newRoot)
			 external whenNotPaused onlyRelay
		 { 
			 // TODO: add ZK verification of newRoot
			  uint128 relayId = relaysIndex[msg.sender];
			  require(oldRoot == relays[relayId].roothash, "LIST08 wrong roothash");
			  require(versions[permalink].relayId == relayId, "LIST09 wrong relay");
			  
			  relays[relayId].timestamp = block.timestamp;
			  relays[relayId].roothash = newRoot;
			  relays[relayId].counter++;			  
			  versions[permalink].version = 1;
			  
			  emit Version(permalink, 1, relayId, newRoot); 
		 }

		 // Allow transfer from relay
		 function allowTransfer(uint256 permalink, uint256 roothash)
			 external whenNotPaused onlyRelay
		 { 
			  uint128 relayId = relaysIndex[msg.sender];
			  require(roothash == relays[relayId].roothash, "LIST10 wrong roothash");
			  require(versions[permalink].relayId == relayId, "LIST11 wrong relay");
			  allowedTransfers[relayId][permalink] = roothash;	
		 }

		 // Allow transfer from suspended relay
		 function allowForcedTransfer(uint256 permalink, uint128 relayId, uint256 roothash)
			 external whenNotPaused onlyOwner
		 { 
			  require(relayId <= relaysCount, "LIST10 wrong relayId");
			  require(roothash == relays[relayId].roothash, "LIST10a wrong roothash");
			  require(relays[relayId].isActive == false, "LIST10b please shutdown relay first");
			  require(versions[permalink].relayId == relayId, "LIST11 wrong relay");
			  allowedTransfers[relayId][permalink] = roothash;	
		 }

		 function transfer(uint256 permalink, 
		 					uint128 oldRelayId,	 
		 					uint256 oldRelayOldRoot,
		 					uint256 oldRelayNewRoot,
		 					uint256 newRelayOldRoot,
		 					uint256 newRelayNewRoot)
			 external whenNotPaused onlyRelay
		 { 
			  uint128 newRelayId = relaysIndex[msg.sender];
			  require(oldRelayId != newRelayId, "LIST12 cannot transfer to myself");
			  require(newRelayId <= relaysCount, "LIST13 not a relay");
			  require(oldRelayOldRoot == relays[oldRelayId].roothash, "LIST14 wrong roothash");
			  require(newRelayOldRoot == relays[newRelayId].roothash, "LIST15 wrong roothash");
			  require(versions[permalink].relayId == oldRelayId, "LIST16 wrong relay");
			  require(allowedTransfers[newRelayId][permalink] == relays[newRelayId].roothash, "LIST17 wrong roothash");

			  relays[newRelayId].timestamp = block.timestamp;
			  relays[newRelayId].roothash = newRelayNewRoot;
			  relays[newRelayId].counter++;
			  
  
			  relays[oldRelayId].timestamp = block.timestamp;
			  relays[oldRelayId].roothash = oldRelayNewRoot;
			  relays[oldRelayId].counter++;
			  

			  versions[permalink].relayId = newRelayId;
			  emit Version(permalink, versions[permalink].version, newRelayId, newRelayNewRoot);  
			  emit Roothash( oldRelayNewRoot, oldRelayId);
			  emit Transfer(permalink, oldRelayId, newRelayId); // relays should ping after the transfer to confirm the state	
		 }

		 // Confirm that roothash is not changed
		 function ping(uint256 roothash)
			 external whenNotPaused onlyRelay
		 { 
			  uint128 relayId = relaysIndex[msg.sender];
			  require(roothash == relays[relayId].roothash, "LIST18 wrong roothash");
			  relays[relayId].timestamp = block.timestamp;
			  emit Roothash( roothash, relayId);
		 }

		 function getVersion(uint256 permalink)
			  external view returns (uint128)
		 {
			  return versions[permalink].version;			  
		 }
		 
		 function getRelay(uint256 permalink)
			  external view returns (uint128)
		 {
			  return versions[permalink].relayId;			  
		 }
		 
		 function isRevoked(uint256 permalink)
			  external view returns (bool)
		 {
			  return versions[permalink].version == 1;			  
		 }
	
		 function isVersionUnchanged(uint256 permalink, uint128 version)
			  external view returns (bool)
		 {
			  return versions[permalink].version == version;			  
		 }	 
		 
		 function pause()
			  external whenNotPaused onlyOwner
		 {
			  _pause(); 
		 }

		 function unpause()
			  external whenPaused onlyOwner
		  {
			  _unpause(); 
		  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}