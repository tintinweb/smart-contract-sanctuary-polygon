// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '../common/RegistryHelper.sol';

import './interfaces/ISingleDynamicPullPayment.sol';
import '../common/interfaces/IPullPaymentRegistry.sol';
import '../common/interfaces/IVersionedContract.sol';
import '../common/interfaces/IExecutor.sol';

/**
 * @title SingleDynamicPullPayment - The billing model for dynamic one time payment
 * @author The Pumapay Team
 * @notice A Dynamic PullPayment, like a Single PullPayment is a one-time payment.
 * However, in this case, the payment properties (currency, price, name) can be injected straight onto merchant websites and not through the Business Console.
 * This type of billing model is most suited to merchants who sell tens/hundreds/thousands of products with different descriptions and prices.
 */
contract SingleDynamicPullPayment is
	RegistryHelper,
	ReentrancyGuard,
	ISingleDynamicPullPayment,
	IVersionedContract
{
	using Counters for Counters.Counter;

	/*
   	=======================================================================
   	======================== Structures ===================================
   	=======================================================================
 	*/
	struct PullPayment {
		uint256 paymentAmount;
		uint256 executionTimestamp;
	}

	struct Subscription {
		address subscriber;
		string name;
		address settlementToken;
		address paymentToken;
		uint256[] pullPaymentIDs;
		mapping(uint256 => PullPayment) pullPayments;
		string uniqueReference;
	}

	struct BillingModel {
		address payee;
		string merchantName;
		string uniqueReference;
		string merchantURL;
		uint256[] subscriptionIDs;
		mapping(uint256 => Subscription) subscriptions;
		uint256 creationTime;
	}
	/*
   	=======================================================================
   	======================== Private Variables ============================
   	=======================================================================
 	*/
	/// @dev The couter for billing model ids
	Counters.Counter private _billingModelIDs;
	/// @dev The couter for subscription ids
	Counters.Counter private _subscriptionIDs;
	/// @dev The couter for pullpayment ids
	Counters.Counter private _pullPaymentIDs;

	/// @notice Mappings by ids

	/// @dev billing model ID => billing model details
	mapping(uint256 => BillingModel) private _billingModels;
	/// @dev subscription ID => billing model ID
	mapping(uint256 => uint256) private _subscriptionToBillingModel;
	/// @dev pull payment ID => subscription ID
	mapping(uint256 => uint256) private _pullPaymentToSubscription;

	/// @notice Mappings by address

	// Billing Model Creator => billing model IDs
	mapping(address => uint256[]) private _billingModelIdsByAddress;
	// Customer address => subscription IDs
	mapping(address => uint256[]) private _subscriptionIdsByAddress;
	// Customer address => pull payment IDs
	mapping(address => uint256[]) private _pullPaymentIdsByAddress;

	/// @notice Mappings by strings

	/// @dev bm unique reference => bmId
	mapping(string => uint256) private _bmReferences;
	/// @dev subscription unique reference => bmId
	mapping(string => uint256) private _subscriptionReferences;

	/*
   	=======================================================================
   	======================== Constructor/Initializer ======================
   	=======================================================================
 	*/
	/**
	 * @dev This method initializes registry helper to be able to access method of core registry
	 */
	constructor(address registryAddress) RegistryHelper(registryAddress) {}

	/*
   	=======================================================================
   	======================== Events =======================================
    =======================================================================
 	*/
	event BillingModelCreated(uint256 indexed billingModelID, address indexed payee);
	event NewSubscription(
		uint256 indexed billingModelID,
		uint256 indexed subscriptionID,
		uint256 indexed pullPaymentID,
		address payee,
		address payer,
		uint256 executionFee,
		uint256 userAmount,
		uint256 receiverAmount
	);

	event BillingModelEdited(
		uint256 indexed billingModelID,
		address indexed newPayee,
		address indexed oldPayee,
		string newMerhantName
	);
	/*
   	=======================================================================
   	======================== Modifiers ====================================
    =======================================================================
 	*/
	modifier onlyValidSubscriptionId(uint256 _subscriptionID) {
		require(
			_subscriptionID > 0 && _subscriptionID <= _subscriptionIDs.current(),
			'SingleDynamicPullPayment: INVALID_SUBSCRIPTION_ID'
		);
		_;
	}

	modifier onlyValidBillingModelId(uint256 _billingModelID) {
		require(
			_billingModelID > 0 && _billingModelID <= _billingModelIDs.current(),
			'SingleDynamicPullPayment: INVALID_BILLING_MODEL_ID'
		);
		_;
	}

	/*
   	=======================================================================
   	======================== Public Methods ===============================
   	=======================================================================
 	*/
	/**
	 * @notice Allows merchants to create a new billing model with required configurations
	 * @dev _merchantName, _reference and _merchantURL can be kept empty
	 * @param _payee 						- payee (receiver) address for pull payment
	 * @param _merchantName		 	- name of the merchant
	 * @param _reference				- unique refernce for billing model. if no external reference is passed, unique reference is generated on chain.
	 * @param _merchantURL			- merchant` personal url
	 * @return billingModelID 	- newly generated billing model id
	 */
	function createBillingModel(
		address _payee,
		string memory _merchantName,
		string memory _reference,
		string memory _merchantURL
	) public virtual override returns (uint256 billingModelID) {
		require(_payee != address(0), 'SingleDynamicPullPayment: INVALID_PAYEE_ADDRESS');

		_billingModelIDs.increment();
		uint256 newBillingModelID = _billingModelIDs.current();
		BillingModel storage bm = _billingModels[newBillingModelID];

		// Billing Model Details
		bm.payee = _payee;
		bm.creationTime = block.timestamp;
		bm.merchantName = _merchantName;
		bm.merchantURL = _merchantURL;

		// Owner/Creator of the billing model
		_billingModelIdsByAddress[msg.sender].push(newBillingModelID);

		if (bytes(_reference).length > 0) {
			require(_bmReferences[_reference] == 0, 'SingleDynamicPullPayment: REFERENCE_ALREADY_EXISTS');
			_bmReferences[_reference] = newBillingModelID;
			bm.uniqueReference = _reference;
		} else {
			string memory newReference = string(
				abi.encodePacked('SingleDynamicPullPayment_', Strings.toString(newBillingModelID))
			);
			_bmReferences[newReference] = newBillingModelID;
			bm.uniqueReference = newReference;
		}

		// emit event for new billing model
		emit BillingModelCreated(newBillingModelID, _payee);

		return newBillingModelID;
	}

	/**
	 * @notice Allows users to subscribe to a new billing model
	 * @dev One time payment is done at the time of subscription itself.
	 * @param _billingModelID    - the ID of the billing model
	 * @param _name              - the name that can be injected from the creator of the billing model for any future reference
	 * @param _settlementToken   - the token address that payee wants to get paid in
	 * @param _paymentToken      - the token address the customer wants to pay in
	 * @param _paymentAmount     - the amount for billing model that needs to be paid
	 * @param _reference 				 - the unique reference for the subscription.
	 */
	function subscribeToBillingModel(
		uint256 _billingModelID,
		string memory _name,
		address _settlementToken,
		address _paymentToken,
		uint256 _paymentAmount,
		string memory _reference
	)
		public
		virtual
		override
		nonReentrant
		onlyValidBillingModelId(_billingModelID)
		returns (uint256 subscriptionID)
	{
		require(
			registry.isSupportedToken(_settlementToken),
			'SingleDynamicPullPayment: UNSUPPORTED_TOKEN'
		);
		require(_paymentAmount > 0, 'SingleDynamicPullPayment: INVALID_AMOUNT');

		//update counters
		_subscriptionIDs.increment();
		_pullPaymentIDs.increment();
		uint256 newSubscriptionID = _subscriptionIDs.current();
		uint256 newPullPaymentID = _pullPaymentIDs.current();

		BillingModel storage bm = _billingModels[_billingModelID];
		{
			Subscription storage suscription = bm.subscriptions[newSubscriptionID];
			//update the data
			suscription.subscriber = msg.sender;
			suscription.name = _name;
			suscription.settlementToken = _settlementToken;
			suscription.paymentToken = _paymentToken;

			bm
				.subscriptions[newSubscriptionID]
				.pullPayments[newPullPaymentID]
				.paymentAmount = _paymentAmount;
			suscription.pullPayments[newPullPaymentID].executionTimestamp = block.timestamp;

			//update the ids
			bm.subscriptionIDs.push(newSubscriptionID);
			suscription.pullPaymentIDs.push(newPullPaymentID);

			_subscriptionToBillingModel[newSubscriptionID] = _billingModelID;
			_subscriptionIdsByAddress[msg.sender].push(newSubscriptionID);

			// link pull payment with subscription
			_pullPaymentToSubscription[newPullPaymentID] = newSubscriptionID;
			// link pull payment with "payer"
			_pullPaymentIdsByAddress[msg.sender].push(newPullPaymentID);

			if (bytes(_reference).length > 0) {
				require(
					_subscriptionReferences[_reference] == 0,
					'SingleDynamicPullPayment: REFERENCE_ALREADY_EXISTS'
				);
				_subscriptionReferences[_reference] = newSubscriptionID;
				suscription.uniqueReference = _reference;
			} else {
				string memory newReference = string(
					abi.encodePacked(
						'SingleDynamicPullPayment_',
						Strings.toString(_billingModelID),
						'_',
						Strings.toString(newSubscriptionID)
					)
				);
				_subscriptionReferences[newReference] = newSubscriptionID;
				bm.subscriptions[newSubscriptionID].uniqueReference = newReference;
			}
		}
		{
			//execute the payment
			(uint256 executionFee, uint256 userAmount, uint256 receiverAmount) = IExecutor(
				registry.getExecutor()
			).execute(_settlementToken, _paymentToken, msg.sender, bm.payee, _paymentAmount);

			emit NewSubscription(
				_billingModelID,
				newSubscriptionID,
				newPullPaymentID,
				bm.payee,
				msg.sender,
				executionFee,
				userAmount,
				receiverAmount
			);
		}
		return newSubscriptionID;
	}

	/**
	 * @notice Allows merchants to edit their billing models
	 * Editing a billing model allows the creator of the billing model to update only attributes
	 * that does not affect the billing cycle of the customer, i.e. the name and the payee address etc.
	 * @dev _newMerchantName and _newMerchantURL can be empty
	 * @param _billingModelID 	- the ID of the billing model
	 * @param _newPayee 				- the address of new payee
	 * @param _newMerchantName 	- new name for merchant
	 * @param _newMerchantURL  	- merchant` new personal url
	 * @return billingModelID  	- billing model id edited
	 */
	function editBillingModel(
		uint256 _billingModelID,
		address _newPayee,
		string memory _newMerchantName,
		string memory _newMerchantURL
	)
		public
		virtual
		override
		onlyValidBillingModelId(_billingModelID)
		returns (uint256 billingModelID)
	{
		BillingModel storage bm = _billingModels[_billingModelID];

		require(msg.sender == bm.payee, 'SingleDynamicPullPayment: INVALID_EDITOR');
		require(_newPayee != address(0), 'SingleDynamicPullPayment: INVALID_PAYEE_ADDRESS');
		bm.payee = _newPayee;
		bm.merchantName = _newMerchantName;
		bm.merchantURL = _newMerchantURL;

		emit BillingModelEdited(_billingModelID, _newPayee, msg.sender, _newMerchantName);
		return _billingModelID;
	}

	/*
   	=======================================================================
   	======================== Getter Methods ===============================
   	=======================================================================
 	*/

	/**
	 * @notice Retrieves a billing model
	 * @dev shows subscription ids of billing model to only bm creator
	 * @param _billingModelID - the ID of the billing model
	 * @return bm							- returns the Billing model data struct
	 */
	function getBillingModel(uint256 _billingModelID)
		external
		view
		virtual
		override
		onlyValidBillingModelId(_billingModelID)
		returns (BillingModelData memory bm)
	{
		BillingModel storage bmDetails = _billingModels[_billingModelID];

		// If the caller is the address owning this billing model, then return the array with the
		// subscription IDs as well
		bm.payee = bmDetails.payee;
		bm.creationTime = bmDetails.creationTime;
		bm.merchantName = bmDetails.merchantName;
		bm.uniqueReference = bmDetails.uniqueReference;
		bm.merchantURL = bmDetails.merchantURL;

		if (msg.sender == bmDetails.payee) {
			bm.subscriptionIDs = bmDetails.subscriptionIDs;
		} else {
			// Otherwise, return an empty array for `_bmSubscriptionIDs`
			uint256[] memory emptyArray;
			bm.subscriptionIDs = emptyArray;
		}
	}

	/**
	 * @notice Retrieves subscription details
	 * @dev shows pullpayment ids of subscription to merchant of bm and subscriber only
	 * @param _subscriptionID - the ID of the subscription
	 * @return sb 						- the subscription information
	 */
	function getSubscription(uint256 _subscriptionID)
		external
		view
		virtual
		override
		onlyValidSubscriptionId(_subscriptionID)
		returns (SubscriptionData memory sb)
	{
		uint256 bmID = _subscriptionToBillingModel[_subscriptionID];
		BillingModel storage bm = _billingModels[bmID];
		Subscription storage subscription = bm.subscriptions[_subscriptionID];

		sb.payee = bm.payee;
		sb.name = subscription.name;
		sb.subscriber = subscription.subscriber;
		sb.settlementToken = subscription.settlementToken;
		sb.paymentToken = subscription.paymentToken;
		sb.uniqueReference = subscription.uniqueReference;

		if (msg.sender == bm.payee || msg.sender == subscription.subscriber) {
			sb.pullPaymentIDs = subscription.pullPaymentIDs;
		} else {
			// Return an empty array for `_subscriptionPullPaymentIDs`in case the caller is not
			// the payee or the subscriber
			uint256[] memory emptyArray;
			sb.pullPaymentIDs = emptyArray;
		}
	}

	/**
	 * @notice Returns the details of a pull payment
	 * @dev shows pullpayment amount and timestamp to granted executor, bm creator and subscriber only
	 * @param _pullPaymentID 	- the Id of the pull payment
	 * @return pullPayment 		- the pullpayment informations
	 */
	function getPullPayment(uint256 _pullPaymentID)
		external
		view
		virtual
		returns (PullPayment memory pullPayment)
	{
		require(
			_pullPaymentID > 0 && _pullPaymentID <= _pullPaymentIDs.current(),
			'RecurringPullPayment: INVALID_PULLPAYMENT_ID'
		);
		uint256 bmID = _subscriptionToBillingModel[_pullPaymentToSubscription[_pullPaymentID]];
		BillingModel storage bm = _billingModels[bmID];
		Subscription storage subscription = bm.subscriptions[
			_pullPaymentToSubscription[_pullPaymentID]
		];
		pullPayment.paymentAmount = bm
			.subscriptions[_pullPaymentToSubscription[_pullPaymentID]]
			.pullPayments[_pullPaymentID]
			.paymentAmount;
		pullPayment.executionTimestamp = bm
			.subscriptions[_pullPaymentToSubscription[_pullPaymentID]]
			.pullPayments[_pullPaymentID]
			.executionTimestamp;

		if (
			msg.sender != bm.payee &&
			msg.sender != subscription.subscriber &&
			IPullPaymentRegistry(registry.getPullPaymentRegistry()).isExecutorGranted(msg.sender) == false
		) {
			pullPayment.paymentAmount = 0;
			pullPayment.executionTimestamp = 0;
		}
	}

	/**
	 * @notice Retrieves billing model IDs for an address
	 * @dev Returns an array with the billing model IDs related with that address
	 * @param _creator 					- address that created the billing model
	 * @return billingModelIDs 	- returns list of billing model ids for merchant
	 */
	function getBillingModelIdsByAddress(address _creator)
		external
		view
		returns (uint256[] memory billingModelIDs)
	{
		return _billingModelIdsByAddress[_creator];
	}

	/**
	 * @notice Retrieves subscription ids for an address
	 * @dev Returns an array with the subscription IDs related with that address
	 * @param _subscriber 			- address the pull payment relates to
	 * @return subscriptionIDs 	- the list of subscription ids for subscriber
	 */
	function getSubscriptionIdsByAddress(address _subscriber)
		external
		view
		returns (uint256[] memory subscriptionIDs)
	{
		return _subscriptionIdsByAddress[_subscriber];
	}

	/**
	 * @notice Retrieves pull payment ids for an address
	 * @dev Returns an array with the pull payment IDs related with that address
	 * @param _subscriber 		- address the pull payment relates to
	 * @return pullPaymentIDs - the list of pullpayment ids
	 */
	function getPullPaymentsIdsByAddress(address _subscriber)
		external
		view
		returns (uint256[] memory pullPaymentIDs)
	{
		return _pullPaymentIdsByAddress[_subscriber];
	}

	/**
	 * @notice Gives current billing model id
	 */
	function getCurrentBillingModelId() external view virtual returns (uint256) {
		return _billingModelIDs.current();
	}

	/**
	 * @notice Gives current subscription id
	 */
	function getCurrentSubscriptionId() external view virtual returns (uint256) {
		return _subscriptionIDs.current();
	}

	/**
	 * @notice Gives current pullpayment id
	 */
	function getCurrentPullPaymentId() external view virtual returns (uint256) {
		return _pullPaymentIDs.current();
	}

	/**
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		override
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		return (1, 0, 0, 0);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISingleDynamicPullPayment {
	struct BillingModelData {
		address payee;
		string merchantName;
		string uniqueReference;
		string merchantURL;
		uint256[] subscriptionIDs;
		uint256 creationTime;
	}

	struct SubscriptionData {
		address payee;
		string name;
		address subscriber;
		address settlementToken;
		address paymentToken;
		uint256[] pullPaymentIDs;
		string uniqueReference;
	}

	function createBillingModel(
		address _payee,
		string memory _merchantName,
		string memory _reference,
		string memory _merchantURL
	) external returns (uint256 billingModelID);

	function subscribeToBillingModel(
		uint256 _billingModelID,
		string memory _name,
		address _settlementToken,
		address _paymentToken,
		uint256 _paymentAmount,
		string memory _reference
	) external returns (uint256 subscriptionID);

	function editBillingModel(
		uint256 _billingModelID,
		address _newPayee,
		string memory _newMerchantName,
		string memory _newMerchantURL
	) external returns (uint256);

	function getBillingModel(uint256 _billingModelID) external view returns (BillingModelData memory);

	function getSubscription(uint256 _subscriptionID) external view returns (SubscriptionData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVersionedContract {
	/**
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICoreRegistry.sol';
import './IPullPaymentConfig.sol';

interface IRegistry is ICoreRegistry, IPullPaymentConfig {
	function getPMAToken() external view returns (address);

	function getWBNBToken() external view returns (address);

	function getFreezer() external view returns (address);

	function getExecutor() external view returns (address);

	function getUniswapFactory() external view returns (address);

	function getUniswapPair() external view returns (address);

	function getUniswapRouter() external view returns (address);

	function getPullPaymentRegistry() external view returns (address);

	function getKeeperRegistry() external view returns (address);

	function getTokenConverter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPullPaymentRegistry {
	function grantExecutor(address _executor) external;

	function revokeExecutor(address _executor) external;

	function addPullPaymentContract(string calldata _identifier, address _addr) external;

	function getPPAddressForOrDie(bytes32 _identifierHash) external view returns (address);

	function getPPAddressFor(bytes32 _identifierHash) external view returns (address);

	function getPPAddressForStringOrDie(string calldata _identifier) external view returns (address);

	function getPPAddressForString(string calldata _identifier) external view returns (address);

	function isExecutorGranted(address _executor) external view returns (bool);

	function BATCH_SIZE() external view returns (uint256);

	function setUpkeepId(address upkeepAddress, uint256 upkeepId) external;

	function upkeepIds(address upkeepAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPullPaymentConfig {
	function getSupportedTokens() external view returns (address[] memory);

	function isSupportedToken(address _tokenAddress) external view returns (bool isExists);

	function executionFeeReceiver() external view returns (address);

	function executionFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExecutor {
	function execute(
		address,
		address,
		address,
		address,
		uint256
	)
		external
		returns (
			uint256 executionFee,
			uint256 userAmount,
			uint256 receiverAmount
		);

	function execute(string calldata _bmType, uint256 _subscriptionId) external returns (uint256);
	//    function executePullPayment(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoreRegistry {
	function setAddressFor(string calldata, address) external;

	function getAddressForOrDie(bytes32) external view returns (address);

	function getAddressFor(bytes32) external view returns (address);

	function isOneOf(bytes32[] calldata, address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IRegistry.sol';

/**
 * @title RegistryHelper - initializer for core registry
 * @author The Pumapay Team
 * @notice This contract helps to initialize the core registry contract in parent contracts.
 */
contract RegistryHelper is Ownable {
	/*
   	=======================================================================
   	======================== Public variatibles ===========================
   	=======================================================================
 	*/
	/// @notice The core registry contract
	IRegistry public registry;

	/*
   	=======================================================================
   	======================== Constructor/Initializer ======================
   	=======================================================================
 	*/
	/**
	 * @notice Used in place of the constructor to allow the contract to be upgradable via proxy.
	 * @dev initializes the core registry with registry address
	 */
	constructor(address _registryAddress) {
		setRegistry(_registryAddress);
	}

	/*
   	=======================================================================
   	======================== Events =======================================
 	=======================================================================
 	*/
	event RegistrySet(address indexed registryAddress);

	/*
   	=======================================================================
   	======================== Public Methods ===============================
   	=======================================================================
 	*/

	/**
	 * @notice Updates the address pointing to a Registry contract.
	 * @dev only owner can set the registry address.
	 * @param registryAddress - The address of a registry contract for routing to other contracts.
	 */
	function setRegistry(address registryAddress) public virtual onlyOwner {
		require(registryAddress != address(0), 'RegistryHelper: CANNOT_REGISTER_ZERO_ADDRESS');
		registry = IRegistry(registryAddress);
		emit RegistrySet(registryAddress);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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