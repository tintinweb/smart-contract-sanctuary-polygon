/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

// File: contracts/operator-filter-registry/src/IOperatorFilterRegistry.sol


pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// File: contracts/operator-filter-registry/src/UpdatableOperatorFilterer.sol


pragma solidity ^0.8.13;


/**
 * @title  UpdatableOperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry. This contract allows the Owner to update the
 *         OperatorFilterRegistry address via updateOperatorFilterRegistryAddress, including to the zero address,
 *         which will bypass registry checks.
 *         Note that OpenSea will still disable creator fee enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract UpdatableOperatorFilterer {
    error OperatorNotAllowed(address operator);
    error OnlyOwner();

    IOperatorFilterRegistry public operatorFilterRegistry;

    constructor(address _registry, address subscriptionOrRegistrantToCopy, bool subscribe) {
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(_registry);
        operatorFilterRegistry = registry;
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(registry).code.length > 0) {
            if (subscribe) {
                registry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    registry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    registry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public virtual {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
    }

    /**
     * @dev assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract
     */
    function owner() public view virtual returns (address);

    function _checkFilterOperator(address operator) internal view virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// File: contracts/EthereumContracts/contracts/utils/Whitelist_ECDSA.sol



/**
* Author: Lambdalf the White
* Edit  : Squeebo
*/

pragma solidity 0.8.17;

abstract contract Whitelist_ECDSA {
	// Errors
  /**
  * @dev Thrown when trying to query the whitelist while it's not set
  */
	error Whitelist_NOT_SET();
  /**
  * @dev Thrown when `account` has consumed their alloted access and tries to query more
  * 
  * @param account : address trying to access the whitelist
  */
	error Whitelist_CONSUMED( address account );
  /**
  * @dev Thrown when `account` does not have enough alloted access to fulfil their query
  * 
  * @param account : address trying to access the whitelist
  */
	error Whitelist_FORBIDDEN( address account );

	/**
  * @dev A structure representing a signature proof to be decoded by the contract
  */
	struct Proof {
		bytes32 r;
		bytes32 s;
		uint8   v;
	}

	address private _adminSigner;
	mapping( uint8 => mapping ( address => uint256 ) ) private _consumed;

	/**
	* @dev Ensures that `account_` has `qty_` alloted access on the `whitelistId_` whitelist.
	* 
	* @param account_     : the address to validate access
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param alloted_     : the max amount of whitelist spots allocated
	* @param proof_       : the signature proof to validate whitelist allocation
	* @param qty_         : the amount of whitelist access requested
	*/
	modifier isWhitelisted( address account_, uint8 whitelistId_, uint256 alloted_, Proof memory proof_, uint256 qty_ ) {
		uint256 _allowed_ = checkWhitelistAllowance( account_, whitelistId_, alloted_, proof_ );

		if ( _allowed_ < qty_ ) {
			revert Whitelist_FORBIDDEN( account_ );
		}

		_;
	}

	/**
	* @dev Sets the pass to protect the whitelist.
	* 
	* @param adminSigner_ : the address validating the whitelist signatures
	*/
	function _setWhitelist( address adminSigner_ ) internal virtual {
		_adminSigner = adminSigner_;
	}

	/**
	* @dev Returns the amount that `account_` is allowed to access from the whitelist.
	* 
	* @param account_     : the address to validate access
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param alloted_     : the max amount of whitelist spots allocated
	* @param proof_       : the signature proof to validate whitelist allocation
	* 
	* @return uint256 : the total amount of whitelist allocation remaining for `account_`
	* 
	* Requirements:
	* 
	* - `_adminSigner` must be set.
	*/
	function checkWhitelistAllowance( address account_, uint8 whitelistId_, uint256 alloted_, Proof memory proof_ ) public view returns ( uint256 ) {
		if ( _adminSigner == address( 0 ) ) {
			revert Whitelist_NOT_SET();
		}

		if ( _consumed[ whitelistId_ ][ account_ ] >= alloted_ ) {
			revert Whitelist_CONSUMED( account_ );
		}

		if ( ! _validateProof( account_, whitelistId_, alloted_, proof_ ) ) {
			revert Whitelist_FORBIDDEN( account_ );
		}

		return alloted_ - _consumed[ whitelistId_ ][ account_ ];
	}

	/**
	* @dev Internal function to decode a signature and compare it with the `_adminSigner`.
	* 
	* @param account_     : the address to validate access
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param alloted_     : the max amount of whitelist spots allocated
	* @param proof_       : the signature proof to validate whitelist allocation
	* 
	* @return bool : whether the signature is valid or not
	*/ 
	function _validateProof( address account_, uint8 whitelistId_, uint256 alloted_, Proof memory proof_ ) private view returns ( bool ) {
		bytes32 _digest_ = keccak256( abi.encode( whitelistId_, alloted_, account_ ) );
		address _signer_ = ecrecover( _digest_, proof_.v, proof_.r, proof_.s );
		return _signer_ == _adminSigner;
	}

	/**
	* @dev Consumes `amount_` whitelist access passes from `account_`.
	* 
	* @param account_     : the address to consume access from
	* @param whitelistId_ : the identifier of the whitelist being queried
	* @param qty_         : the amount of whitelist access consumed
	* 
	* Note: Before calling this function, eligibility should be checked through {Whitelistable-checkWhitelistAllowance}.
	*/
	function _consumeWhitelist( address account_, uint8 whitelistId_, uint256 qty_ ) internal {
		unchecked {
			_consumed[ whitelistId_ ][ account_ ] += qty_;
		}
	}
}

// File: contracts/EthereumContracts/contracts/utils/ProxyAccess.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

contract ProxyRegistry {
	function proxies( address tokenOwner_ ) external view returns ( address ) {}
}

abstract contract ProxyAccess {
	// list of accepted proxy registries
	address[] public proxyRegistries;

	/**
	* @dev Internal function that adds a proxy registry to the list of accepted proxy registries.
	* 
	* @param proxyRegistryAddress_ : the address of the new proxy registry
	*/
	function _addProxyRegistry( address proxyRegistryAddress_ ) internal {
		uint256 _index_ = proxyRegistries.length;
		while ( _index_ > 0 ) {
			unchecked {
				_index_ --;
			}
			if ( proxyRegistries[ _index_ ] == proxyRegistryAddress_ ) {
				return;
			}
		}
		proxyRegistries.push( proxyRegistryAddress_ );
	}

	/**
	* @dev Internal function that removes a proxy registry from the list of accepted proxy registries.
	* 
	* @param proxyRegistryAddress_ : the address of the proxy registry to remove
	*/
	function _removeProxyRegistry( address proxyRegistryAddress_ ) internal {
		uint256 _len_ = proxyRegistries.length;
		uint256 _index_ = _len_;
		while ( _index_ > 0 ) {
			unchecked {
				_index_ --;
			}
			if ( proxyRegistries[ _index_ ] == proxyRegistryAddress_ ) {
				if ( _index_ + 1 != _len_ ) {
					proxyRegistries[ _index_ ] = proxyRegistries[ _len_ - 1 ];
				}
				proxyRegistries.pop();
				return;
			}
		}
	}

	/**
	* @dev Internal function that checks if `operator_` is a registered proxy for `tokenOwner_`.
	* 
	* Note: Use this function to allow whitelisting of registered proxy.
	* 
	* @param tokenOwner_ : the address the proxy operates on the behalf of
	* @param operator_   : the proxy address that operates on behalf of the token owner
	* 
	* @return bool : whether `operator_` is allowed to operate on behalf of `tokenOwner_` or not
	*/
	function _isRegisteredProxy( address tokenOwner_, address operator_ ) internal view returns ( bool ) {
		uint256 _index_ = proxyRegistries.length;
		while ( _index_ > 0 ) {
			unchecked {
				_index_ --;
			}
			ProxyRegistry _proxyRegistry_ = ProxyRegistry( proxyRegistries[ _index_ ] );
			if ( address( _proxyRegistry_.proxies( tokenOwner_ ) ) == operator_ ) {
				return true;
			}
		}
		return false;
	}
}
// File: contracts/EthereumContracts/contracts/utils/ContractState.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

abstract contract ContractState {
	// Enum to represent the sale state, defaults to ``PAUSED``.
	uint8 public constant PAUSED = 0;

	// Errors
  /**
  * @dev Thrown when a function is called with the wrong contract state.
  * 
  * @param currentState : the current state of the contract
  */
	error ContractState_INCORRECT_STATE( uint8 currentState );
  /**
  * @dev Thrown when trying to set the contract state to an invalid value.
  * 
  * @param invalidState : the invalid contract state
  */
	error ContractState_INVALID_STATE( uint8 invalidState );

	// The current state of the contract
	uint8 private _contractState;

	/**
	* @dev Emitted when the sale state changes
	*/
	event ContractStateChanged( uint8 indexed previousState, uint8 indexed newState );

	/**
	* @dev Ensures that contract state is `expectedState_`.
	* 
	* @param expectedState_ : the desirable contract state
	*/
	modifier isState( uint8 expectedState_ ) {
		if ( _contractState != expectedState_ ) {
			revert ContractState_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Ensures that contract state is not `unexpectedState_`.
	* 
	* @param unexpectedState_ : the undesirable contract state
	*/
	modifier isNotState( uint8 unexpectedState_ ) {
		if ( _contractState == unexpectedState_ ) {
			revert ContractState_INCORRECT_STATE( _contractState );
		}
		_;
	}

	/**
	* @dev Internal function setting the contract state to `newState_`.
	* 
	* Note: Contract state defaults to ``PAUSED``.
	* 			To maintain extendability, this value kept as uint8 instead of enum.
	* 			As a result, it is possible to set the state to an incorrect value.
	* 			To avoid issues, `newState_` should be validated before calling this function
	*/
	function _setContractState( uint8 newState_ ) internal virtual {
		uint8 _previousState_ = _contractState;
		_contractState = newState_;
		emit ContractStateChanged( _previousState_, newState_ );
	}

	/**
	* @dev Returns the current contract state.
	* 
	* @return uint8 : the current contract state
	*/
	function getContractState() public virtual view returns ( uint8 ) {
		return _contractState;
	}
}

// File: contracts/EthereumContracts/contracts/interfaces/IERC2981.sol


pragma solidity 0.8.17;

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 /* is IERC165 */ {
  /// ERC165 bytes to add to interface array - set in parent contract
  /// implementing this standard
  ///
  /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  /// _registerInterface(_INTERFACE_ID_ERC2981);

  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param tokenId_ - the NFT asset queried for royalty information
  /// @param salePrice_ - the sale price of the NFT asset specified by tokenId_
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for salePrice_
  function royaltyInfo( uint256 tokenId_, uint256 salePrice_ ) external view returns ( address receiver, uint256 royaltyAmount );
}

// File: contracts/EthereumContracts/contracts/utils/ERC2981.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;


abstract contract ERC2981 is IERC2981 {
	// Errors
  /**
  * @dev Thrown when the desired royalty rate is higher than 10,000
  * 
  * @param royaltyRate : the desired royalty rate
  * @param royaltyBase : the maximum royalty rate
  */
	error IERC2981_INVALID_ROYALTIES( uint256 royaltyRate, uint256 royaltyBase );

	// Royalty rate is stored out of 10,000 instead of a percentage to allow for
	// up to two digits below the unit such as 2.5% or 1.25%.
	uint private constant ROYALTY_BASE = 10000;

	// Represents the percentage of royalties on each sale on secondary markets.
	// Set to 0 to have no royalties.
	uint256 private _royaltyRate;

	// Address of the recipient of the royalties.
	address private _royaltyRecipient;

	/**
	* @notice Called with the sale price to determine how much royalty is owed and to whom.
	* 
	* Note: This function should be overriden to revert on a query for non existent token.
	* 
  * @param tokenId_   : identifier of the NFT being referenced
  * @param salePrice_ : the sale price of the token sold
  * 
  * @return address : the address receiving the royalties
  * @return uint256 : the royalty payment amount
	*/
	function royaltyInfo( uint256 tokenId_, uint256 salePrice_ ) public view virtual override returns ( address, uint256 ) {
		if ( salePrice_ == 0 || _royaltyRate == 0 ) {
			return ( _royaltyRecipient, 0 );
		}
		uint256 _royaltyAmount_ = _royaltyRate * salePrice_ / ROYALTY_BASE;
		return ( _royaltyRecipient, _royaltyAmount_ );
	}

	/**
	* @dev Sets the royalty rate to `royaltyRate_` and the royalty recipient to `royaltyRecipient_`.
	* 
	* @param royaltyRecipient_ : the address that will receive royalty payments
	* @param royaltyRate_      : the percentage of the sale price that will be taken off as royalties, expressed in Basis Points (100 BP = 1%)
	* 
	* Requirements: 
	* 
	* - `royaltyRate_` cannot be higher than `10,000`;
	*/
	function _setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) internal virtual {
		if ( royaltyRate_ > ROYALTY_BASE ) {
			revert IERC2981_INVALID_ROYALTIES( royaltyRate_, ROYALTY_BASE );
		}
		_royaltyRate      = royaltyRate_;
		_royaltyRecipient = royaltyRecipient_;
	}
}

// File: contracts/EthereumContracts/contracts/interfaces/IERC173.sol



pragma solidity 0.8.17;

/**
* @dev Required interface of an ERC173 compliant contract, as defined in the
* https://eips.ethereum.org/EIPS/eip-173[EIP].
*/
interface IERC173 /* is IERC165 */ {
    /// @dev This emits when ownership of a contract changes.    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner    
    /// @return The address of the owner.
    function owner() view external returns(address);
	
    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract    
    function transferOwnership(address _newOwner) external;	
}

// File: contracts/EthereumContracts/contracts/utils/ERC173.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;


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
abstract contract ERC173 is IERC173 {
	// Errors
  /**
  * @dev Thrown when `operator` is not the contract owner.
  * 
  * @param operator : address trying to use a function reserved to contract owner without authorization
  */
  error IERC173_NOT_OWNER( address operator );

	// The owner of the contract
	address private _owner;

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner() {
		address _sender_ = msg.sender;
		if ( owner() != _sender_ ) {
			revert IERC173_NOT_OWNER( _sender_ );
		}
		_;
	}

	/**
	* @dev Sets the contract owner.
	* 
	* Note: This function needs to be called in the contract constructor to initialize the contract owner, 
	* if it is not, then parts of the contract might be non functional
	* 
	* @param owner_ : address that owns the contract
	*/
	function _setOwner( address owner_ ) internal {
		_owner = owner_;
	}

	/**
	* @dev Returns the address of the current contract owner.
	* 
	* @return address : the current contract owner
	*/
	function owner() public view virtual returns ( address ) {
		return _owner;
	}

	/**
	* @dev Transfers ownership of the contract to `newOwner_`.
	* 
	* @param newOwner_ : address of the new contract owner
	* 
	* Requirements:
	* 
  * - Caller must be the contract owner.
	*/
	function transferOwnership( address newOwner_ ) public virtual onlyOwner {
		address _oldOwner_ = _owner;
		_owner = newOwner_;
		emit OwnershipTransferred( _oldOwner_, newOwner_ );
	}
}

// File: contracts/EthereumContracts/contracts/interfaces/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity 0.8.17;

/**
* @dev Interface of the optional ERC1155MetadataExtension interface, as defined
* in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
*
* _Available since v3.1._
*/
interface IERC1155MetadataURI /* is IERC1155 */ {
	/**
	* @dev Returns the URI for token type `id`.
	*
	* If the `\{id\}` substring is present in the URI, it must be replaced by
	* clients with the actual token type ID.
	*/
	function uri(uint256 id) external view returns (string memory);
}

// File: contracts/EthereumContracts/contracts/interfaces/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity 0.8.17;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/EthereumContracts/contracts/interfaces/IERC1155.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

// import "./IERC165.sol";

/**
* @title ERC-1155 Multi Token Standard
* @dev See https://eips.ethereum.org/EIPS/eip-1155
* Note: The ERC-165 identifier for this interface is 0xd9b67a26.
*/
interface IERC1155 /* is IERC165 */ {
	/**
	* @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
	* The `operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
	* The `from` argument MUST be the address of the holder whose balance is decreased.
	* The `to` argument MUST be the address of the recipient whose balance is increased.
	* The `id` argument MUST be the token type being transferred.
	* The `value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
	* When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
	* When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).        
	*/
	event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

	/**
	* @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
	* The `operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
	* The `from` argument MUST be the address of the holder whose balance is decreased.
	* The `to` argument MUST be the address of the recipient whose balance is increased.
	* The `ids` argument MUST be the list of tokens being transferred.
	* The `values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in ids) the holder balance is decreased by and match what the recipient balance is increased by.
	* When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
	* When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).                
	*/
	event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

	/**
	* @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
	*/
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	/**
	* @dev MUST emit when the URI is updated for a token ID.
	* URIs are defined in RFC 3986.
	* The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
	*/
	event URI(string value, uint256 indexed id);

	/**
	* @notice Transfers `value` amount of an `id` from the `from` address to the `to` address specified (with safety call).
	* @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
	* MUST revert if `to` is the zero address.
	* MUST revert if balance of holder for token `id` is lower than the `value` sent.
	* MUST revert on any other error.
	* MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
	* After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
	* @param from    Source address
	* @param to      Target address
	* @param id      ID of the token type
	* @param value   Transfer amount
	* @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
	*/
	function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

	/**
	* @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
	* @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
	* MUST revert if `to` is the zero address.
	* MUST revert if length of `ids` is not the same as length of `values`.
	* MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
	* MUST revert on any other error.        
	* MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
	* Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before ids[1]/_values[1], etc).
	* After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
	* @param from    Source address
	* @param to      Target address
	* @param ids     IDs of each token type (order and length must match values array)
	* @param values  Transfer amounts per token type (order and length must match ids array)
	* @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
	*/
	function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external;

	/**
	* @notice Get the balance of an account's tokens.
	* @param owner  The address of the token holder
	* @param id     ID of the token
	* @return       The owner's balance of the token type requested
	*/
	function balanceOf(address owner, uint256 id) external view returns (uint256);

	/**
	* @notice Get the balance of multiple account/token pairs
	* @param owners The addresses of the token holders
	* @param ids    ID of the tokens
	* @return       The owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
	*/
	function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

	/**
	* @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
	* @dev MUST emit the ApprovalForAll event on success.
	* @param operator  Address to add to the set of authorized operators
	* @param approved  True if the operator is approved, false to revoke approval
	*/
	function setApprovalForAll(address operator, bool approved) external;

	/**
	* @notice Queries the approval status of an operator for a given owner.
	* @param owner     The owner of the tokens
	* @param operator  Address of authorized operator
	* @return          True if the operator is approved, false if not
	*/
	function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/EthereumContracts/contracts/interfaces/IERC165.sol



pragma solidity 0.8.17;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: contracts/EthereumContracts/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
// https://eips.ethereum.org/EIPS/eip-20

pragma solidity 0.8.17;

/**
* @dev Interface of the ERC20 standard as defined in the EIP.
*/
interface IERC20 /* is IERC165 */ {
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

// File: contracts/EthereumContracts/contracts/interfaces/INFTSupplyErrors.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface INFTSupplyErrors {
  /**
  * @dev Thrown when trying to mint 0 token.
  */
  error NFT_INVALID_QTY();
  /**
  * @dev Thrown when trying to set max supply to an invalid amount.
  */
  error NFT_INVALID_SUPPLY();
  /**
  * @dev Thrown when trying to mint more tokens than the max allowed per transaction.
  * 
  * @param qtyRequested : the amount of tokens requested
  * @param maxBatch     : the maximum amount that can be minted per transaction
  */
  error NFT_MAX_BATCH( uint256 qtyRequested, uint256 maxBatch );
  /**
  * @dev Thrown when trying to mint more tokens from the reserve than the amount left.
  * 
  * @param qtyRequested : the amount of tokens requested
  * @param reserveLeft  : the amount of tokens left in the reserve
  */
  error NFT_MAX_RESERVE( uint256 qtyRequested, uint256 reserveLeft );
  /**
  * @dev Thrown when trying to mint more tokens than the amount left to be minted (except reserve).
  * 
  * @param qtyRequested    : the amount of tokens requested
  * @param remainingSupply : the amount of tokens left in the reserve
  */
  error NFT_MAX_SUPPLY( uint256 qtyRequested, uint256 remainingSupply );
}

// File: contracts/EthereumContracts/contracts/interfaces/IERC1155Errors.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC1155Errors {
  /**
  * @dev Thrown when `operator` has not been approved to manage `tokenId` on behalf of `tokenOwner`.
  * 
  * @param from     : address owning the token
  * @param operator : address trying to manage the token
  */
  error IERC1155_CALLER_NOT_APPROVED( address from, address operator );
  /**
  * @dev Thrown when trying to create series `id` that already exists.
  * 
  * @param id : identifier of the NFT being referenced
  */
  error IERC1155_EXISTANT_TOKEN( uint256 id );
  /**
  * @dev Thrown when `from` tries to transfer more than they own.
  * 
  * @param from    : address that the NFT are being transferred from
  * @param id      : identifier of the NFT being referenced
  * @param balance : amount of tokens that the address owns
  */
  error IERC1155_INSUFFICIENT_BALANCE( address from, uint256 id, uint256 balance );
  /**
  * @dev Thrown when operator tries to approve themselves for managing a token they own.
  */
  error IERC1155_INVALID_CALLER_APPROVAL();
  /**
  * @dev Thrown when a token is being transferred to the zero address.
  */
  error IERC1155_INVALID_TRANSFER();
  /**
  * @dev Thrown when the requested token doesn't exist.
  * 
  * @param id : identifier of the NFT being referenced
  */
  error IERC1155_NON_EXISTANT_TOKEN( uint256 id );
  /**
  * @dev Thrown when a token is being safely transferred to a contract unable to handle it.
  * 
  * @param receiver : address unable to receive the token
  */
  error IERC1155_NON_ERC1155_RECEIVER( address receiver );
  /**
  * @dev Thrown when an ERC1155Receiver contract rejects a transfer.
  */
  error IERC1155_REJECTED_TRANSFER();
}

// File: contracts/EthereumContracts/contracts/interfaces/IEtherErrors.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IEtherErrors {
  /**
  * @dev Thrown when an incorrect amount of eth is being sent for a payable operation.
  * 
  * @param amountReceived : the amount the contract received
  * @param amountExpected : the actual amount the contract expected to receive
  */
  error ETHER_INCORRECT_PRICE( uint256 amountReceived, uint256 amountExpected );
  /**
  * @dev Thrown when trying to withdraw from the contract with no balance.
  */
  error ETHER_NO_BALANCE();
  /**
  * @dev Thrown when contract fails to send ether to recipient.
  * 
  * @param to     : the recipient of the ether
  * @param amount : the amount of ether being sent
  */
  error ETHER_TRANSFER_FAIL( address to, uint256 amount );
}

// File: contracts/EthereumContracts/contracts/interfaces/IArrayErrors.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IArrayErrors {
  /**
  * @dev Thrown when two related arrays have different lengths
  */
  error ARRAY_LENGTH_MISMATCH();
}

// File: contracts/JuiceTeam.sol



/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;
















contract JuiceTeam is 
	IERC1155Errors, IArrayErrors, IEtherErrors, INFTSupplyErrors,
	IERC165, IERC1155, IERC1155MetadataURI,
	UpdatableOperatorFilterer, ProxyAccess, ERC2981, ERC173, ContractState, Whitelist_ECDSA {
	/**
	* @dev Thrown when `account` doesn't own the expected amount of `tokenAddress` tokens.
	* 
	* @param account      : the operating account
	* @param amount       : the amount of tokens expected
	* @param tokenAddress : the contract address being checked
	*/
	error JT_INSUFFICIENT_BALANCE( address account, uint256 amount, address tokenAddress );

	/**
	* @dev A structure representing the deployment configuration of the contract.
	* It contains several pieces of information:
	* - maxBatch         : The maximum amount of tokens that can be minted in one transaction (for public sale)
	* - name             : The name of the tokens, for token trackers (i.e. 'Cool Cats')
	* - symbol           : The symbol of the tokens, for token trackers (i.e. 'COOL')
	*/
	struct Config {
		uint256 maxBatch;
		string  name;
		string  symbol;
	}

	uint8 private constant _OPEN = 1;
	uint256 public constant DEFAULT_PASS_ID = 1;
	address public constant DEFAULT_SUBSCRIPTION = address( 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6 );
	address public constant DEFAULT_OPERATOR_FILTER_REGISTRY = address( 0x000000000000AAeB6D7670E522A718067333cd4E );
	address public constant OS_PROXY_REGISTRY = address( 0xa5409ec958C83C3f309868babACA7c86DCB077c1 );
	address public constant WETH_ADDRESS = address( 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619 );

	Config  private _config;
	address private _treasury;
	string  private _uri;
	IERC20  public  immutable WETH;
	// Mapping from token ID to reserves
	mapping( uint256 => uint256 ) private _reserves;
	// Mapping from series ID to public prices
	mapping( uint256 => uint256 ) public publicSalePrices;
	// Mapping from series ID to presale prices
	mapping( uint256 => uint256 ) public privateSalePrices;
	// Mapping from series ID to remaining supplies
	mapping( uint256 => uint256 ) public remainingSupplies;
	// Mapping from series ID to max supplies
	mapping( uint256 => uint256 ) public maxSupplies;
	// Mapping from series ID to balances
	mapping( uint256 => mapping( address => uint256 ) ) private _balances;
	// Mapping from owner to operator approvals
	mapping( address => mapping( address => bool ) ) private _operatorApprovals;

	constructor(
		address treasury_
	) UpdatableOperatorFilterer( DEFAULT_OPERATOR_FILTER_REGISTRY, DEFAULT_SUBSCRIPTION, true ) {
		Config memory _config_ = Config(
			10,
			"Juice Team Founder Key",
			"JTFK"
		);
		__init_NFT1155(
			treasury_,
			_config_
		);
		_uri = "https://gateway.pinata.cloud/ipfs/QmaunTfDSG5B3avd69GbmJrVogkrzTcHoC62rPyy4FJt4s/";
		_setOwner( msg.sender );
		_setRoyaltyInfo( treasury_, 500 );
		_addProxyRegistry( OS_PROXY_REGISTRY );
		WETH = IERC20( WETH_ADDRESS );
	}

	function __init_NFT1155(
		address treasury_,
		Config memory config_
	) internal {
		_treasury = treasury_;
		_config = config_;
	}

	// **************************************
	// *****          MODIFIER          *****
	// **************************************
		/**
		* @dev Throws if sale state is not `whitelist[ id_ ]`.
		*/
		modifier isWhitelist( uint256 id_ ) {
			if ( getContractState() != id_ ) {
				revert ContractState_INCORRECT_STATE( getContractState() );
			}
			_;
		}

		modifier isWhitelistOrOpen ( uint256 id_ ) {
			uint8 _currentState_ = getContractState();
			if ( _currentState_ != _OPEN &&
					 _currentState_ != id_ ) {
				revert ContractState_INCORRECT_STATE( _currentState_ );
			}
			_;
		}

		/**
		* @dev Ensures that `qty_` is higher than 0
		* 
		* @param qty_ : the amount to validate 
		*/
		modifier validateAmount( uint256 qty_ ) {
			if ( qty_ == 0 ) {
				revert NFT_INVALID_QTY();
			}
			_;
		}

		/**
		* @dev Ensures that `id_` is a valid series
		* 
		* @param id_ : the series id to validate 
		*/
		modifier isValidSeries( uint256 id_ ) {
			if ( maxSupplies[ id_ ] == 0 ) {
				revert IERC1155_NON_EXISTANT_TOKEN( id_ );
			}
			_;
		}
	// **************************************

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function that checks if the receiver address is a smart contract able to handle batches of IERC1155 tokens.
		*/
		function _doSafeBatchTransferAcceptanceCheck( address operator_, address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_ ) private {
			uint256 _size_;
			assembly {
				_size_ := extcodesize( to_ )
			}
			if ( _size_ > 0 ) {
				try IERC1155Receiver( to_ ).onERC1155BatchReceived( operator_, from_, ids_, amounts_, data_ ) returns ( bytes4 response ) {
					if ( response != IERC1155Receiver.onERC1155BatchReceived.selector ) {
						revert IERC1155_REJECTED_TRANSFER();
					}
				}
				catch ( bytes memory reason ) {
					if ( reason.length == 0 ) {
						revert IERC1155_REJECTED_TRANSFER();
					}
					else {
						assembly {
							revert( add( 32, reason ), mload( reason ) )
						}
					}
				}
			}
		}

		/**
		* @dev Internal function that checks if the receiver address is a smart contract able to handle IERC1155 tokens.
		*/
		function _doSafeTransferAcceptanceCheck( address operator_, address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_ ) private {
			uint256 _size_;
			assembly {
				_size_ := extcodesize( to_ )
			}
			if ( _size_ > 0 ) {
				try IERC1155Receiver( to_ ).onERC1155Received( operator_, from_, id_, amount_, data_ ) returns ( bytes4 response ) {
					if ( response != IERC1155Receiver.onERC1155Received.selector ) {
						revert IERC1155_REJECTED_TRANSFER();
					}
				}
				catch ( bytes memory reason ) {
					if ( reason.length == 0 ) {
						revert IERC1155_REJECTED_TRANSFER();
					}
					else {
						assembly {
							revert( add( 32, reason ), mload( reason ) )
						}
					}
				}
			}
		}

		/**
		* @dev Internal function that checks if `operator_` is allowed to handle tokens on behalf of `owner_`
		*/
		function _isApprovedOrOwner( address owner_, address operator_ ) internal view returns ( bool ) {
			return owner_ == operator_ ||
						 isApprovedForAll( owner_, operator_ );
		}

		/**
		* @dev Internal function that checks whether `id_` is an existing series.
		*/
		function _isValidSeries( uint256 id_ ) internal view returns ( bool ) {
			if ( maxSupplies[ id_ ] == 0 ) {
				return false;
			}
			return true;
		}

		/**
		* @dev Internal function that mints `amount_` tokens from series `id_` into `account_`.
		*/
		function _mint( address account_, uint256 id_, uint256 amount_ ) internal {
			unchecked {
				_balances[ id_ ][ account_ ] += amount_;
				remainingSupplies[ id_ ] -= amount_;
			}
			emit TransferSingle( account_, address( 0 ), account_, id_, amount_ );
		}

		/**
		* @dev Internal function burning the necessary amount of currency from `tokenOwner_`.
		* 
		* @param tokenOwner_ : the token owner to check
		* @param amount_     : the amount of coin to be paid
		*/
		function _processPayment( address tokenOwner_, uint256 amount_ ) internal {
			try WETH.transferFrom( tokenOwner_, address( this ), amount_ ) {}
			catch Error( string memory ) {
				revert JT_INSUFFICIENT_BALANCE( tokenOwner_, amount_, address( WETH ) );
			}
		}

		/**
		* @dev Converts a `uint256` to its ASCII `string` decimal representation.
		*/
		function _toString( uint256 value_ ) internal pure returns ( string memory ) {
			// Inspired by OraclizeAPI's implementation - MIT licence
			// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
			if ( value_ == 0 ) {
				return "0";
			}
			uint256 _temp_ = value_;
			uint256 _digits_;
			while ( _temp_ != 0 ) {
				_digits_ ++;
				_temp_ /= 10;
			}
			bytes memory _buffer_ = new bytes( _digits_ );
			while ( value_ != 0 ) {
				_digits_ -= 1;
				_buffer_[ _digits_ ] = bytes1( uint8( 48 + uint256( value_ % 10 ) ) );
				value_ /= 10;
			}
			return string( _buffer_ );
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @notice Mints `qty_` amount of `id_` to the caller address.
		* 
		* @param id_       The series id to mint 
		* @param qty_      Amount of tokens to mint
		* @param alloted_  Amount of tokens that caller is allowed to claim
		* @param proof_    Signature confirming that the caller is allowed to mint `alloeted_` number of tokens
		* 
		* Requirements:
		* 
		* - Contract state must be `whitelist[ id_ ]`
		* - Whitelist must be set 
		* - Caller must be allowed to mint `qty_` tokens
		*/
		function mintWhitelist( uint256 id_, uint256 qty_, uint256 alloted_, Proof memory proof_ ) external isValidSeries( id_ ) isWhitelist( id_ ) validateAmount( qty_ ) isWhitelisted( msg.sender, uint8( id_ ), alloted_, proof_, qty_ ) {
			if ( qty_ > remainingSupplies[ id_ ] ) {
				revert NFT_MAX_SUPPLY( qty_, remainingSupplies[ id_ ] );
			}

			uint256 _expected_ = qty_ * privateSalePrices[ id_ ];
			if ( _expected_ > WETH.balanceOf( msg.sender ) ) {
				revert JT_INSUFFICIENT_BALANCE( msg.sender, _expected_, address( WETH ) );
			}

			_consumeWhitelist( msg.sender, uint8( id_ ), qty_ );
			_mint( msg.sender, id_, qty_ );
			_processPayment( msg.sender, _expected_ );
		}

		/**
		* @notice Mints `qty_` amount of `id_` to the caller address.
		* 
		* @param qty_  Amount of tokens to mint
		* 
		* Requirements:
		* 
		* - Contract state must be `OPEN`
		* - `qty_` must be lower than `_config.maxBatch`
		* - `qty_` must be lower or equal to `remainingSupplies[ id_ ]`
		* - Caller must send enough eth to pay for `qty_` tokens
		*/
		function mintPublicOrWhitelist( uint256 id_, uint256 qty_ ) external payable isValidSeries( id_ ) isWhitelistOrOpen( id_ ) validateAmount( qty_ ) {
			if ( qty_ > remainingSupplies[ id_ ] ) {
				revert NFT_MAX_SUPPLY( qty_, remainingSupplies[ id_ ] );
			}
			if ( qty_ > _config.maxBatch ) {
				revert NFT_MAX_BATCH( qty_, _config.maxBatch );
			}

			uint256 _expected_ = qty_ * publicSalePrices[ id_ ];
			if ( _expected_ > WETH.balanceOf( msg.sender ) ) {
				revert JT_INSUFFICIENT_BALANCE( msg.sender, _expected_, address( WETH ) );
			}

			_mint( msg.sender, id_, qty_ );
			_processPayment( msg.sender, _expected_ );
		}

		/**
		* @notice Mints `qty_` amount of `id_` to the caller address.
		* 
		* @param qty_  Amount of tokens to mint
		* 
		* Requirements:
		* 
		* - Contract state must be `OPEN`
		* - `qty_` must be lower than `_config.maxBatch`
		* - `qty_` must be lower or equal to `remainingSupplies[ id_ ]`
		* - Caller must send enough eth to pay for `qty_` tokens
		*/
		function mintPublic( uint256 id_, uint256 qty_ ) external payable isValidSeries( id_ ) isState( _OPEN ) validateAmount( qty_ ) {
			if ( qty_ > remainingSupplies[ id_ ] ) {
				revert NFT_MAX_SUPPLY( qty_, remainingSupplies[ id_ ] );
			}
			if ( qty_ > _config.maxBatch ) {
				revert NFT_MAX_BATCH( qty_, _config.maxBatch );
			}

			uint256 _expected_ = qty_ * publicSalePrices[ id_ ];
			if ( _expected_ > WETH.balanceOf( msg.sender ) ) {
				revert JT_INSUFFICIENT_BALANCE( msg.sender, _expected_, address( WETH ) );
			}

			_mint( msg.sender, id_, qty_ );
			_processPayment( msg.sender, _expected_ );
		}

		/**
		* @notice Transfers `amounts_` amount(s) of `ids_` from the `from_` address to the `to_` address specified (with safety call).
		* 
		* @param from_     Source address
		* @param to_       Target address
		* @param ids_      IDs of each token type (order and length must match `amounts_` array)
		* @param amounts_  Transfer amounts per token type (order and length must match `ids_` array)
		* @param data_     Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to_`
		* 
		* Requirements:
		* 
		* - Caller must be approved to manage the tokens being transferred out of the `from_` account (see "Approval" section of the standard).
		* - MUST revert if `to_` is the zero address.
		* - MUST revert if length of `ids_` is not the same as length of `amounts_`.
		* - MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids_` is lower than the respective amount(s) in `amounts_` sent to the recipient.
		* - MUST revert on any other error.        
		* - MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
		* - Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_amounts[0] before ids_[1]/_amounts[1], etc).
		* - After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to_` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
		*/
		function safeBatchTransferFrom( address from_, address to_, uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_ ) external override onlyAllowedOperator( msg.sender ) {
			if ( to_ == address( 0 ) ) {
				revert IERC1155_INVALID_TRANSFER();
			}

			uint256 _len_ = ids_.length;
			if ( amounts_.length != _len_ ) {
				revert ARRAY_LENGTH_MISMATCH();
			}

			address _operator_ = msg.sender;
			if ( ! _isApprovedOrOwner( from_, _operator_ ) ) {
				revert IERC1155_CALLER_NOT_APPROVED( from_, _operator_ );
			}

			for ( uint256 i; i < _len_; ) {
				if ( ! _isValidSeries( ids_[ i ] ) ) {
					continue;
				}
				uint256 _balance_ = _balances[ ids_[ i ] ][ from_ ];
				if ( _balance_ < amounts_[ i ] ) {
					revert IERC1155_INSUFFICIENT_BALANCE( from_, ids_[ i ], _balance_);
				}
				unchecked {
					_balances[ ids_[ i ] ][ from_ ] = _balance_ - amounts_[ i ];
				}
				_balances[ ids_[ i ] ][ to_ ] += amounts_[ i ];
				unchecked {
					++i;
				}
			}
			emit TransferBatch( _operator_, from_, to_, ids_, amounts_ );

			_doSafeBatchTransferAcceptanceCheck( _operator_, from_, to_, ids_, amounts_, data_ );
		}

		/**
		* @notice Transfers `amount_` amount of an `id_` from the `from_` address to the `to_` address specified (with safety call).
		* 
		* @param from_    Source address
		* @param to_      Target address
		* @param id_      ID of the token type
		* @param amount_  Transfer amount
		* @param data_    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to_`
		* 
		* Requirements:
		* 
		* - Caller must be approved to manage the tokens being transferred out of the `from_` account (see "Approval" section of the standard).
		* - MUST revert if `to_` is the zero address.
		* - MUST revert if balance of holder for token type `id_` is lower than the `amount_` sent.
		* - MUST revert on any other error.
		* - MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
		* - After the above conditions are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to_` and act appropriately (see "Safe Transfer Rules" section of the standard).        
		*/
		function safeTransferFrom( address from_, address to_, uint256 id_, uint256 amount_, bytes calldata data_ ) external override isValidSeries( id_ ) onlyAllowedOperator( msg.sender ) {
			if ( to_ == address( 0 ) ) {
				revert IERC1155_INVALID_TRANSFER();
			}

			address _operator_ = msg.sender;
			if ( ! _isApprovedOrOwner( from_, _operator_ ) ) {
				revert IERC1155_CALLER_NOT_APPROVED( from_, _operator_ );
			}

			uint256 _balance_ = _balances[ id_ ][ from_ ];
			if ( _balance_ < amount_ ) {
				revert IERC1155_INSUFFICIENT_BALANCE( from_, id_, _balance_ );
			}
			unchecked {
				_balances[ id_ ][ from_ ] = _balance_ - amount_;
			}
			_balances[ id_ ][ to_ ] += amount_;
			emit TransferSingle( _operator_, from_, to_, id_, amount_ );

			_doSafeTransferAcceptanceCheck( _operator_, from_, to_, id_, amount_, data_ );
		}

		/**
		* @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
		* 
		* @param operator_  Address to add to the set of authorized operators
		* @param approved_  True if the operator is approved, false to revoke approval
		* 
		* Requirements:
		* 
		* - MUST emit the ApprovalForAll event on success.
		*/
		function setApprovalForAll( address operator_, bool approved_ ) external override onlyAllowedOperatorApproval( msg.sender ) {
			address _tokenOwner_ = msg.sender;
			if ( _tokenOwner_ == operator_ ) {
				revert IERC1155_INVALID_CALLER_APPROVAL();
			}

			_operatorApprovals[ _tokenOwner_ ][ operator_ ] = approved_;
			emit ApprovalForAll( _tokenOwner_, operator_, approved_ );
		}
	// **************************************

	// **************************************
	// *****       CONTRACT OWNER       *****
	// **************************************
		/**
		* @notice Adds a proxy registry to the list of accepted proxy registries.
		* 
		* @param proxyRegistryAddress_  the address of the proxy registry to be added
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function addProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
			_addProxyRegistry( proxyRegistryAddress_ );
		}

		/**
		* @notice Mints `amounts_` tokens of `id_` and transfers them to `accounts_`.
		* 
		* @param accounts_ : the list of accounts that will receive airdropped tokens
		* @param amounts_  : the amount of tokens each account will receive
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		* - `accounts_` and `amounts_` must have the same length.
		* - There must be enough tokens left in the reserve.
		*/
		function airdrop( uint256 id_, address[] memory accounts_, uint256[] memory amounts_ ) public onlyOwner isValidSeries( id_ ) {
			uint256 _amountsLen_ = amounts_.length;
			if ( accounts_.length != _amountsLen_ ) {
				revert ARRAY_LENGTH_MISMATCH();
			}

			uint256 _totalQty_;
			for ( uint256 i = _amountsLen_; i > 0; i -- ) {
				_totalQty_ += amounts_[ i - 1 ];
			}
			if ( _totalQty_ > _reserves[ id_ ] ) {
				revert NFT_MAX_RESERVE( _totalQty_, _reserves[ id_ ] );
			}
			unchecked {
				_reserves[ id_ ] -= _totalQty_;
			}

			uint256 _count_ = _amountsLen_;
			while ( _count_ > 0 ) {
				unchecked {
					_count_ --;
				}
				_mint( accounts_[ _count_ ], id_, amounts_[ _count_ ] );
			}
		}

		/**
		* @notice Creates a new series
		* 
		* @param id_               the new series ID
		* @param maxSupply_        the new series max supply
		* @param publicSalePrice_  the new series public price
		* @param privateSalePrice_ the new series private price
		* @param reserve_          the new series reserve
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function createSeries( uint256 id_, uint256 maxSupply_, uint256 publicSalePrice_, uint256 privateSalePrice_, uint256 reserve_ ) external onlyOwner {
			if ( maxSupplies[ id_ ] != 0 ) {
				revert IERC1155_EXISTANT_TOKEN( id_ );
			}

			maxSupplies[ id_ ] = maxSupply_;
			remainingSupplies[ id_ ] = maxSupply_;
			publicSalePrices[ id_ ] = publicSalePrice_;
			privateSalePrices[ id_ ] = privateSalePrice_;
			_reserves[ id_ ] = reserve_;
		}

		/**
		* @notice Updates an existing series
		* 
		* @param id_               the new series ID
		* @param maxSupply_        the new series max supply
		* @param publicSalePrice_  the new series public price
		* @param privateSalePrice_ the new series private price
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function updateSeries( uint256 id_, uint256 maxSupply_, uint256 publicSalePrice_, uint256 privateSalePrice_, uint256 reserve_ ) external onlyOwner isValidSeries( id_ ) {
			uint256 _diff_ = maxSupplies[ id_ ] - maxSupply_;
			if ( maxSupplies[ id_ ] > maxSupply_ ||
					 _diff_ > remainingSupplies[ id_ ] ) {
				revert NFT_INVALID_SUPPLY();
			}

			unchecked {
				remainingSupplies[ id_ ] -= _diff_;
			}
			maxSupplies[ id_ ] = maxSupply_;
			publicSalePrices[ id_ ] = publicSalePrice_;
			privateSalePrices[ id_ ] = privateSalePrice_;
			_reserves[ id_ ] = reserve_;
		}

		/**
		* @notice Removes a proxy registry from the list of accepted proxy registries.
		* 
		* @param proxyRegistryAddress_  the address of the proxy registry to be removed
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function removeProxyRegistry( address proxyRegistryAddress_ ) external onlyOwner {
			_removeProxyRegistry( proxyRegistryAddress_ );
		}

		/**
		* @notice Sets the contract state to `newState_`.
		* 
		* @param newState_  the new sale state
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		*/
		function setContractState( uint8 newState_ ) external onlyOwner {
			_setContractState( newState_ );
		}

		/**
		* @notice Updates the royalty recipient and rate.
		* 
		* @param royaltyRecipient_  the new recipient of the royalties
		* @param royaltyRate_       the new royalty rate
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner
		* - `royaltyRate_` must be between 0 and 10,000
		*/
		function setRoyaltyInfo( address royaltyRecipient_, uint256 royaltyRate_ ) external onlyOwner {
			_setRoyaltyInfo( royaltyRecipient_, royaltyRate_ );
		}

		/**
		* @notice Sets the uri of the tokens.
		* 
		* @param uri_  The new uri of the tokens
		*/
		function setURI( string memory uri_ ) external onlyOwner {
			_uri = uri_;
			emit URI( uri_, DEFAULT_PASS_ID );
		}

		/**
		* @notice Sets the whitelist signer.
		* 
		* @param adminSigner_  The address signing the whitelist permissions
		*/
		function setWhitelist( address adminSigner_ ) public onlyOwner {
			_setWhitelist( adminSigner_ );
		}

		/**
		* @notice Withdraws all the money stored in the contract and sends it to the caller.
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner.
		* - Contract must have a positive balance.
		*/
		function withdraw() public onlyOwner {
			uint256 _balance_ = WETH.balanceOf( address( this ) );
			if ( _balance_ == 0 ) {
				revert ETHER_NO_BALANCE();
			}

			try WETH.transfer( _treasury, _balance_ ) {}
			catch Error( string memory ) {
				revert JT_INSUFFICIENT_BALANCE( address( this ), _balance_, address( WETH ) );
			}
		}
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		/**
		* @notice Get the balance of an account's tokens.
		* 
		* @param owner_  The address of the token holder
		* @param id_     ID of the token type
		* @return        The owner_'s balance of the token type requested
		*/
		function balanceOf( address owner_, uint256 id_ ) public view override isValidSeries( id_ ) returns ( uint256 ) {
			return _balances[ id_ ][ owner_ ];
		}

		/**
		* @notice Get the balance of multiple account/token pairs
		* 
		* @param owners_  The addresses of the token holders
		* @param ids_     ID of the token types
		* @return         The owners_' balance of the token types requested (i.e. balance for each (owner, id) pair)
		*/
		function balanceOfBatch( address[] calldata owners_, uint256[] calldata ids_ ) public view override returns ( uint256[] memory ) {
			uint256 _len_ = owners_.length;
			if ( _len_ != ids_.length ) {
				revert ARRAY_LENGTH_MISMATCH();
			}

			uint256[] memory _balances_ = new uint256[]( _len_ );
			while ( _len_ > 0 ) {
				unchecked {
					--_len_;
				}
				if ( ! _isValidSeries( ids_[ _len_ ] ) ) {
					_balances_[ _len_ ] = 0;
					continue;
				}

				_balances_[ _len_ ] = _balances[ ids_[ _len_ ] ][ owners_[ _len_ ] ];
			}

			return _balances_;
		}

		/**
		* @notice Queries the approval status of an operator for a given owner.
		* 
		* @param owner_     The owner of the tokens
		* @param operator_  Address of authorized operator
		* @return           True if the operator is approved, false if not
		*/
		function isApprovedForAll( address owner_, address operator_ ) public view override returns ( bool ) {
			return _operatorApprovals[ owner_ ][ operator_ ] ||
						 _isRegisteredProxy( owner_, operator_ );
		}

		/**
		* @dev returns the contract owner.
		*/
		function owner() public view override(ERC173, UpdatableOperatorFilterer) returns ( address ) {
			return ERC173.owner();
		}

		/**
		* @notice Query if a contract implements an interface.
		* 
		* @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
		* @param interfaceID_  The interface identifier, as specified in ERC-165
		* @return 						 `true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise
		*/
		function supportsInterface( bytes4 interfaceID_ ) public pure override returns ( bool ) {
			return interfaceID_ == type( IERC165 ).interfaceId ||
						 interfaceID_ == type( IERC173 ).interfaceId ||
						 interfaceID_ == type( IERC1155 ).interfaceId ||
						 interfaceID_ == type( IERC1155MetadataURI ).interfaceId ||
						 interfaceID_ == type( IERC2981 ).interfaceId;
		}

		/**
		* @dev Returns the URI for token type `id`.
		*
		* If the `\{id\}` substring is present in the URI, it must be replaced by
		* clients with the actual token type ID.
		*/
		function uri( uint256 id_ ) external view isValidSeries( id_ ) returns ( string memory ) {
			return bytes( _uri ).length > 0 ? string( abi.encodePacked( _uri, _toString( id_ ) ) ) : _toString( id_ );
		}
	// **************************************
}