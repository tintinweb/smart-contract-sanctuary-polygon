// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '../common/RegistryHelper.sol';
import '../common/KeeperCompatible.sol';

import './interfaces/IRecurringDynamicPP.sol';
import '../common/interfaces/IPullPaymentRegistry.sol';
import '../common/interfaces/IVersionedContract.sol';
import '../common/interfaces/IExecutor.sol';

/**
 * @title RecurringDynamicPullPayment
 * @author The Pumapay Team
 * @notice A Dynamic PullPayment, like a recurring PullPayment. However, in this case, the payment properties (currency, price, name etc.) can be injected straight onto merchant websites and not through the Business Console.
 * This type of billing model is most suited to merchants who sell tens/hundreds/thousands of products with different descriptions and prices.
 * This billing model allows merchants to create the paid trial, free trial and normal recurring pullPayments.
 */
contract RecurringDynamicPullPayment is
	ReentrancyGuard,
	RegistryHelper,
	IRecurringDynamicPullPayment,
	KeeperCompatible,
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
		SubscriptionData data;
		//PullPayment ID => pullPayment
		mapping(uint256 => PullPayment) pullPayments;
	}

	struct FreeTrial {
		//subscription Id => Subscription
		mapping(uint256 => Subscription) subscription;
		uint256 trialPeriod;
	}

	struct PaidTrial {
		//subscription Id => Subscription
		mapping(uint256 => Subscription) subscription;
		uint256 trialPeriod;
		uint256 initialAmount;
	}

	struct BillingModel {
		address payee;
		string merchantName;
		string uniqueReference;
		string merchantURL;
		uint8 recurringPPType; // 1-normal recurringPP, 2-free trial recurringPP, 3-Paid trial recurringPP
		uint256[] subscriptionIDs;
		uint256 creationTime;
	}

	struct PullPaymentData {
		uint256 paymentAmount;
		uint256 executionTimestamp;
		uint256 billingModelID;
		uint256 subscriptionID;
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
	mapping(uint256 => Subscription) private subscriptions;
	/// @dev subscription ID => Free trial model details
	mapping(uint256 => FreeTrial) private freeTrialSubscriptions;
	/// @dev subscription ID => Paid trial details
	mapping(uint256 => PaidTrial) private paidTrialSubscriptions;

	/// @notice Mappings by ids

	/// @dev billing model ID => billing model details
	mapping(uint256 => BillingModel) private _billingModels;
	/// @dev subscription ID => billing model ID
	mapping(uint256 => uint256) private _subscriptionToBillingModel;
	/// @dev pull payment ID => subscription ID
	mapping(uint256 => uint256) private _pullPaymentToSubscription;

	/// @notice Mappings by address

	/// @dev Billing Model Creator => billing model IDs
	mapping(address => uint256[]) private _billingModelIdsByAddress;
	/// @dev Customer address => subscription IDs
	mapping(address => uint256[]) private _subscriptionIdsByAddress;
	/// @dev Customer address => pull payment IDs
	mapping(address => uint256[]) private _pullPaymentIdsByAddress;
	// @dev customer address => list of inactive subscription Ids
	mapping(address => uint256[]) private _inactiveSubscriptionsByAddress;

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
	event BillingModelCreated(
		uint256 indexed billingModelID,
		address indexed payee,
		uint8 indexed recurringPPType
	);
	event NewSubscription(
		uint256 indexed billingModelID,
		uint256 indexed subscriptionID,
		address payee,
		address payer
	);

	event PullPaymentExecuted(
		uint256 indexed subscriptionID,
		uint256 indexed pullPaymentID,
		uint256 indexed billingModelID,
		address payee,
		address payer,
		uint256 executionFee,
		uint256 userAmount,
		uint256 receiverAmount
	);

	event SubscriptionCancelled(
		uint256 indexed billingModelID,
		uint256 indexed subscriptionID,
		address payee,
		address payer
	);

	event BillingModelEdited(
		uint256 indexed billingModelID,
		address indexed newPayee,
		address indexed oldPayee,
		string newMerchantName
	);

	/*
   	=======================================================================
   	======================== Modifiers ====================================
    =======================================================================
 	*/
	modifier onlyValidSubscriptionId(uint256 _subscriptionID) {
		require(
			_subscriptionID > 0 && _subscriptionID <= _subscriptionIDs.current(),
			'RecurringDynamicPullPayment: INVALID_SUBSCRIPTION_ID'
		);
		_;
	}

	modifier onlyValidBillingModelId(uint256 _billingModelID) {
		require(
			_billingModelID > 0 && _billingModelID <= _billingModelIDs.current(),
			'RecurringDynamicPullPayment: INVALID_BILLING_MODEL_ID'
		);
		_;
	}

	/*
   	=======================================================================
   	======================== Public Methods ===============================
   	=======================================================================
 	*/
	/**
	 * @notice Allows merchants to create a new billing model with required configurations.
	 * here merchant specifies only the basic information of bm. The type of recurring bm is specified while creating dynamic bm.
	 * @dev _name, _merchantName, _reference and _merchantURL can be empty.
	 *
	 * @param _payee             - payee (receiver) address for pull payment
	 * @param _recurringPPType   - indicates the type of Recurring PullPayment, 1- Normal RecurringPP, 2- Free trial RecurringPP, 3- Paid trial RecurringPP
	 * @param _merchantName		 	 - name of the merchant
	 * @param _reference				 - unique refernce for billing model
	 * @param _merchantURL			 - merchant` personal url
	 * @return billingModelID 	 - newly generated billing model id
	 */
	function createBillingModel(
		address _payee,
		uint8 _recurringPPType,
		string memory _merchantName,
		string memory _reference,
		string memory _merchantURL
	) external virtual override returns (uint256 billingModelID) {
		require(_payee != address(0), 'RecurringDynamicPullPayment: INVALID_PAYEE_ADDRESS');
		require(
			_recurringPPType > 0 && _recurringPPType <= 3,
			'RecurringDynamicPullPayment: INVALID_RECURRING_PP_TYPE'
		);

		_billingModelIDs.increment();
		uint256 newBillingModelID = _billingModelIDs.current();
		BillingModel storage bm = _billingModels[newBillingModelID];

		// Billing Model Details
		bm.payee = _payee;
		bm.merchantName = _merchantName;
		bm.recurringPPType = _recurringPPType;
		bm.creationTime = block.timestamp;
		bm.merchantURL = _merchantURL;

		// Owner/Creator of the billing model
		_billingModelIdsByAddress[msg.sender].push(newBillingModelID);

		if (bytes(_reference).length > 0) {
			require(
				_bmReferences[_reference] == 0,
				'RecurringDynamicPullPayment: REFERENCE_ALREADY_EXISTS'
			);
			_bmReferences[_reference] = newBillingModelID;
			bm.uniqueReference = _reference;
		} else {
			string memory newReference = string(
				abi.encodePacked('RecurringDynamicPullPayment_', Strings.toString(newBillingModelID))
			);
			_bmReferences[newReference] = newBillingModelID;
			bm.uniqueReference = newReference;
		}

		// emit event for new billing model
		emit BillingModelCreated(newBillingModelID, _payee, _recurringPPType);

		return newBillingModelID;
	}

	/**
	 * @notice Allows users to subscribe to a new billing model.
	 * @dev the dynamic parameters are provided based on the type of the dynamic billing model i.e free trial, paid trial, no trial
	 * for no trial 	- _trialPeriod and _initialAmount can be empty
	 * for free trial -	_initialAmount can be empty
	 * for paid trial -	needs to provide all parameters.
	 * @param _billingModelID    - the ID of the billing model
	 * @param _bmName,           - indicates the billing model name
	 * @param _settlementToken,  - indicates the token address that payee wants to get paid in
	 * @param _paymentToken      - indicates the token address the customer wants to pay in
	 * @param _paymentAmount     - indicates the amount that customer would pay for subscription,
	 * @param _frequency         - indicates the interval at which pull payment will get executed
	 * @param _totalPayments     - indicates the total no. of payments to be executed
	 * @param _trialPeriod       - indicates the trial period for pullPayment, should be zero in case of recurringType=1 i.e normal recurringPP
	 * @param _initialAmount     - indicates the Amount to pay for paid trial, should be zero in case of recurringType =2 i.e free trial recurringPP
	 * @param _reference				 - unique reference for the subscription. can be kept empty
	 * @return newSubscriptionID - newly generated subscription id
	 */
	function subscribeToBillingModel(
		uint256 _billingModelID,
		string memory _bmName,
		address _settlementToken,
		address _paymentToken,
		uint256 _paymentAmount,
		uint256 _frequency,
		uint256 _totalPayments,
		uint256 _trialPeriod,
		uint256 _initialAmount,
		string memory _reference
	)
		external
		virtual
		override
		nonReentrant
		onlyValidBillingModelId(_billingModelID)
		returns (uint256 newSubscriptionID)
	{
		require(_paymentAmount > 0, 'RecurringDynamicPullPayment: INVALID_PAYMENT_AMOUNT');
		require(_frequency > 0, 'RecurringDynamicPullPayment: INVALID_FREQUENCY');
		require(_totalPayments > 0, 'RecurringDynamicPullPayment: INVALID_TOTAL_NO_OF_PAYMENTS');
		require(
			registry.isSupportedToken(_settlementToken),
			'RecurringDynamicPullPayment: UNSUPPORTED_TOKEN'
		);
		_subscriptionIDs.increment();
		newSubscriptionID = _subscriptionIDs.current();

		//initialize the subscription
		SubscriptionData storage newSubscription = subscriptions[newSubscriptionID].data;
		BillingModel storage bm = _billingModels[_billingModelID];

		newSubscription.subscriber = msg.sender;
		newSubscription.bmName = _bmName;
		newSubscription.settlementToken = _settlementToken;
		newSubscription.paymentToken = _paymentToken;
		newSubscription.paymentAmount = _paymentAmount;
		newSubscription.frequency = _frequency;
		newSubscription.totalPayments = _totalPayments;
		newSubscription.remainingPayments = _totalPayments;
		newSubscription.startTimestamp = block.timestamp;

		_subscribe(_billingModelID, newSubscriptionID, _trialPeriod, _initialAmount, _reference);

		_executeFirstPayment(
			_billingModelID,
			bm,
			newSubscriptionID,
			_settlementToken,
			_paymentToken,
			_initialAmount
		);

		emit NewSubscription(_billingModelID, newSubscriptionID, bm.payee, msg.sender);

		return newSubscriptionID;
	}

	function _subscribe(
		uint256 _billingModelID,
		uint256 newSubscriptionID,
		uint256 _trialPeriod,
		uint256 _initialAmount,
		string memory _reference
	) internal {
		BillingModel storage bm = _billingModels[_billingModelID];
		SubscriptionData storage newSubscription = subscriptions[newSubscriptionID].data;

		if (bm.recurringPPType != 1) {
			require(_trialPeriod > 0, 'RecurringDynamicPullPayment: INVALID_TRIAL_PERIOD');

			// payment will be executed after the trial period
			newSubscription.nextPaymentTimestamp = newSubscription.startTimestamp + _trialPeriod;
		}

		if (bm.recurringPPType == 1) {
			// Normal Recurring PullPayment
			subscriptions[newSubscriptionID].data = newSubscription;
			newSubscription.nextPaymentTimestamp = block.timestamp;
		} else if (bm.recurringPPType == 2) {
			// Free Trial Recurring PullPayment
			freeTrialSubscriptions[newSubscriptionID]
				.subscription[newSubscriptionID]
				.data = newSubscription;
			freeTrialSubscriptions[newSubscriptionID].trialPeriod = _trialPeriod;
		} else if (bm.recurringPPType == 3) {
			// Paid Trial Recurring PullPayment
			require(_initialAmount > 0, 'RecurringDynamicPullPayment: INVALID_INITIAL_AMOUNT');
			newSubscription.lastPaymentTimestamp = block.timestamp;

			paidTrialSubscriptions[newSubscriptionID]
				.subscription[newSubscriptionID]
				.data = newSubscription;
			paidTrialSubscriptions[newSubscriptionID].trialPeriod = _trialPeriod;
			paidTrialSubscriptions[newSubscriptionID].initialAmount = _initialAmount;
		}

		bm.subscriptionIDs.push(newSubscriptionID);

		_subscriptionToBillingModel[newSubscriptionID] = _billingModelID;
		_subscriptionIdsByAddress[msg.sender].push(newSubscriptionID);

		if (bytes(_reference).length > 0) {
			require(
				_subscriptionReferences[_reference] == 0,
				'RecurringDynamicPullPayment: REFERENCE_ALREADY_EXISTS'
			);
			_subscriptionReferences[_reference] = newSubscriptionID;
			newSubscription.uniqueReference = _reference;
		} else {
			string memory newReference = string(
				abi.encodePacked(
					'RecurringDynamicPullPayment_',
					Strings.toString(_billingModelID),
					'_',
					Strings.toString(newSubscriptionID)
				)
			);
			_subscriptionReferences[newReference] = newSubscriptionID;
			newSubscription.uniqueReference = newReference;
		}
	}

	function _executeFirstPayment(
		uint256 _billingModelID,
		BillingModel storage bm,
		uint256 newSubscriptionID,
		address _settlementToken,
		address _paymentToken,
		uint256 _initialAmount
	) internal {
		if (bm.recurringPPType == 1) {
			_executePullPayment(newSubscriptionID);
		} else if (bm.recurringPPType == 3) {
			//execute the payment for paid trial
			(uint256 executionFee, uint256 userAmount, uint256 receiverAmount) = IExecutor(
				registry.getExecutor()
			).execute(_settlementToken, _paymentToken, msg.sender, bm.payee, _initialAmount);

			emit PullPaymentExecuted(
				newSubscriptionID,
				0,
				_billingModelID,
				bm.payee,
				msg.sender,
				executionFee,
				userAmount,
				receiverAmount
			);
		}
	}

	/**
	 * @notice This method allows anyone to execute the recurring pullpayment for the subscription.
	 * The pullpayment for subscription will be executed only after the paid trial ends
	 * @dev our backend will call this method to execute the recurring payment for the subscription at regular interval of time.
	 * @param _subscriptionID 	- The subscription id for which recurring pullpayment to execute.
	 * @return pullPaymentID		- The newly generated pullPayment id
	 */
	function executePullPayment(uint256 _subscriptionID)
		public
		virtual
		override
		nonReentrant
		onlyValidSubscriptionId(_subscriptionID)
		returns (uint256 pullPaymentID)
	{
		return _executePullPayment(_subscriptionID);
	}

	/**
	 * @dev This method contains actual logic for executing the pull payment for the subscription.
	 * Requirements-
	 * 1. current time should exceed next payment` time. i.e should complete  free/paid trial period if exists.
	 * 2. subscription is not cancelled.
	 * 3. total number of payments are not completed.
	 * @param _subscriptionID 	- The subscription id for which recurring pullpayment to execute.
	 * @return pullPaymentID		- The newly generated pullPayment id
	 */
	function _executePullPayment(uint256 _subscriptionID) private returns (uint256 pullPaymentID) {
		BillingModel storage bm = _billingModels[_subscriptionToBillingModel[_subscriptionID]];

		//intialize the subscription
		SubscriptionData storage _subscription = subscriptions[_subscriptionID].data;

		_initilizeSubscription(_subscription, bm.recurringPPType, _subscriptionID);

		uint256 billingModelID = _subscriptionToBillingModel[_subscriptionID];

		require(
			block.timestamp >= _subscription.startTimestamp &&
				block.timestamp >= _subscription.nextPaymentTimestamp,
			'RecurringDynamicPullPayment: INVALID_EXECUTION_TIME'
		);
		require(
			_subscription.cancelTimestamp == 0 || block.timestamp < _subscription.cancelTimestamp,
			'RecurringDynamicPullPayment: SUBSCRIPTION_CANCELED'
		);
		require(
			_subscription.remainingPayments > 0,
			'RecurringDynamicPullPayment: NO_OF_PAYMENTS_EXCEEDED'
		);

		_pullPaymentIDs.increment();
		uint256 newPullPaymentID = _pullPaymentIDs.current();

		// update subscription
		_subscription.remainingPayments = _subscription.remainingPayments - 1;
		_subscription.lastPaymentTimestamp = block.timestamp;
		_subscription.nextPaymentTimestamp =
			_subscription.nextPaymentTimestamp +
			_subscription.frequency;
		_subscription.pullPaymentIDs.push(newPullPaymentID);

		// update pull payment
		if (bm.recurringPPType == 1) {
			subscriptions[_subscriptionID].pullPayments[newPullPaymentID].paymentAmount = _subscription
				.paymentAmount;

			subscriptions[_subscriptionID].pullPayments[newPullPaymentID].executionTimestamp = block
				.timestamp;
		} else if (bm.recurringPPType == 2) {
			freeTrialSubscriptions[_subscriptionID]
				.subscription[_subscriptionID]
				.pullPayments[newPullPaymentID]
				.paymentAmount = _subscription.paymentAmount;
			freeTrialSubscriptions[_subscriptionID]
				.subscription[_subscriptionID]
				.pullPayments[newPullPaymentID]
				.executionTimestamp = block.timestamp;
		} else if (bm.recurringPPType == 3) {
			paidTrialSubscriptions[_subscriptionID]
				.subscription[_subscriptionID]
				.pullPayments[newPullPaymentID]
				.paymentAmount = _subscription.paymentAmount;
			paidTrialSubscriptions[_subscriptionID]
				.subscription[_subscriptionID]
				.pullPayments[newPullPaymentID]
				.executionTimestamp = block.timestamp;
		}

		// link pull payment with subscription
		_pullPaymentToSubscription[newPullPaymentID] = _subscriptionID;
		// link pull payment with "payer"
		_pullPaymentIdsByAddress[_subscription.subscriber].push(newPullPaymentID);

		(uint256 executionFee, uint256 userAmount, uint256 receiverAmount) = IExecutor(
			registry.getExecutor()
		).execute(
				_subscription.settlementToken,
				_subscription.paymentToken,
				_subscription.subscriber,
				bm.payee,
				_subscription.paymentAmount
			);

		emit PullPaymentExecuted(
			_subscriptionID,
			newPullPaymentID,
			billingModelID,
			bm.payee,
			_subscription.subscriber,
			executionFee,
			userAmount,
			receiverAmount
		);

		return newPullPaymentID;
	}

	/**
	 * @notice This method allows customer / merchant to cancel the on going subscription.
	 * @dev cancelling subscription adds the subscription to inactive subscriptions list of subscriber
	 * @param _subscriptionID - the id of the subscription to cancel
	 * @return subscriptionID - the id of the cancelled subscription
	 */
	function cancelSubscription(uint256 _subscriptionID)
		external
		virtual
		override
		onlyValidSubscriptionId(_subscriptionID)
		returns (uint256 subscriptionID)
	{
		BillingModel storage bm = _billingModels[_subscriptionToBillingModel[_subscriptionID]];

		//intialize the subscription
		SubscriptionData storage subscription = subscriptions[_subscriptionID].data;
		require(subscription.cancelTimestamp == 0, 'RecurringDynamicPullPayment: ALREADY_CANCELLED');

		_initilizeSubscription(subscription, bm.recurringPPType, _subscriptionID);

		require(
			msg.sender == subscription.subscriber || msg.sender == bm.payee,
			'RecurringDynamicPullPayment: INVALID_CANCELER'
		);
		subscription.cancelTimestamp = block.timestamp;
		subscription.cancelledBy = msg.sender;

		_inactiveSubscriptionsByAddress[msg.sender].push(_subscriptionID);

		emit SubscriptionCancelled(
			_subscriptionToBillingModel[_subscriptionID],
			_subscriptionID,
			bm.payee,
			subscription.subscriber
		);

		return _subscriptionID;
	}

	/**
	 * @notice Edit a billing model
	 * Editing a billing model allows the creator of the billing model to update only attributes
	 * that does not affect the billing cycle of the customer, i.e. the name and the payee address.
	 * Any other changes are not allowed.
	 * @dev _newName, _newMerchantName and _newMerchantURL can be empty.
	 *
	 * @param _billingModelID - the ID of the billing model
	 * @param _newPayee - the address of new payee
	 * @param _newMerchantName - new name for merchant
	 * @param _newMerchantURL  - merchant` new personal url
	 */
	function editBillingModel(
		uint256 _billingModelID,
		address _newPayee,
		string memory _newMerchantName,
		string memory _newMerchantURL
	)
		external
		virtual
		override
		onlyValidBillingModelId(_billingModelID)
		returns (uint256 billingModelID)
	{
		BillingModel storage bm = _billingModels[_billingModelID];

		require(msg.sender == bm.payee, 'RecurringDynamicPullPayment: INVALID_EDITOR');
		require(_newPayee != address(0), 'RecurringDynamicPullPayment: INVALID_PAYEE_ADDRESS');

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
	 * @dev This method is called by Keeper network nodes per block. This returns the list of subscription ids and their count which needs to be executed.
	 * @param checkData specified in the upkeep registration so it is always the same for a registered upkeep.
	 * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
	 * @return performData bytes that the keeper should call performUpkeep with, if upkeep is needed.
	 */
	function checkUpkeep(bytes calldata checkData)
		external
		view
		override
		returns (bool upkeepNeeded, bytes memory performData)
	{
		checkData;

		(uint256[] memory subsctionIds, uint256 subcriptionCount) = getSubscriptionIds();

		if (subcriptionCount > 0) {
			upkeepNeeded = true;
			performData = abi.encode(subsctionIds, subcriptionCount);
		}
	}

	/**
	 * @notice method that is actually executed by the keepers, via the registry.
	 * The data returned by the checkUpkeep simulation will be passed into this method to actually be executed.
	 * @param performData is the data which was passed back from the checkData
	 * simulation. If it is encoded, it can easily be decoded into other types by
	 * calling `abi.decode`. This data should not be trusted, and should be
	 * validated against the contract's current state.
	 */
	function performUpkeep(bytes calldata performData) external override {
		(uint256[] memory subsctionIds, uint256 subcriptionCount) = abi.decode(
			performData,
			(uint256[], uint256)
		);

		for (uint256 subIndex = 0; subIndex < subcriptionCount; subIndex++) {
			_executePullPayment(subsctionIds[subIndex]);
		}
	}

	/**
	 * @notice This method gets the list of subscription ids which needs to be executed
	 * @return subscriptionIds - indicates the list of subscrtipion ids
	 * count - indicates the total number of subscriptions to execute
	 */
	function getSubscriptionIds()
		public
		view
		returns (uint256[] memory subscriptionIds, uint256 count)
	{
		uint256 batchSize = IPullPaymentRegistry(registry.getPullPaymentRegistry()).BATCH_SIZE();
		subscriptionIds = new uint256[](batchSize);

		for (uint256 id = 1; id <= _subscriptionIDs.current(); id++) {
			if (isPullpayment(id) && count < batchSize) {
				subscriptionIds[count] = id;
				count++;
			}
		}
	}

	/**
	 * @notice This method checks whether to execute the pullpayment for the given subscription id or not.
	 * returns true if pullpayment is needed, otherwise returns false
	 * @param _subsctptionId - indicates the subscription id
	 */
	function isPullpayment(uint256 _subsctptionId) public view returns (bool) {
		BillingModel storage bm = _billingModels[_subscriptionToBillingModel[_subsctptionId]];

		SubscriptionData storage _subscription = subscriptions[_subsctptionId].data;
		_initilizeSubscription(_subscription, bm.recurringPPType, _subsctptionId);

		return (block.timestamp >= _subscription.startTimestamp &&
			block.timestamp >= _subscription.nextPaymentTimestamp &&
			_subscription.cancelTimestamp == 0 &&
			_subscription.remainingPayments > 0);
	}

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
		bm.recurringPPType = bmDetails.recurringPPType;
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
		returns (Data memory sb)
	{
		uint256 bmID = _subscriptionToBillingModel[_subscriptionID];
		BillingModel storage bm = _billingModels[bmID];

		//intialize the subscription
		SubscriptionData storage subscription = subscriptions[_subscriptionID].data;

		_initilizeSubscription(subscription, bm.recurringPPType, _subscriptionID);

		sb.subscription.subscriber = subscription.subscriber;
		sb.subscription.bmName = subscription.bmName;
		sb.subscription.paymentAmount = subscription.paymentAmount;
		sb.subscription.settlementToken = subscription.settlementToken;
		sb.subscription.paymentToken = subscription.paymentToken;
		sb.subscription.frequency = subscription.frequency;
		sb.subscription.totalPayments = subscription.totalPayments;
		sb.subscription.remainingPayments = subscription.remainingPayments;
		sb.subscription.startTimestamp = subscription.startTimestamp;
		sb.subscription.cancelTimestamp = subscription.cancelTimestamp;
		sb.subscription.nextPaymentTimestamp = subscription.nextPaymentTimestamp;
		sb.subscription.lastPaymentTimestamp = subscription.lastPaymentTimestamp;
		sb.subscription.billingModelID = bmID;
		sb.subscription.uniqueReference = subscription.uniqueReference;
		sb.subscription.cancelledBy = subscription.cancelledBy;

		if (bm.recurringPPType == 2) {
			sb.trialPeriod = freeTrialSubscriptions[_subscriptionID].trialPeriod;
		} else if (bm.recurringPPType == 3) {
			sb.trialPeriod = paidTrialSubscriptions[_subscriptionID].trialPeriod;
			sb.initialAmount = paidTrialSubscriptions[_subscriptionID].initialAmount;
		}

		if (msg.sender == bm.payee || msg.sender == subscription.subscriber) {
			sb.subscription.pullPaymentIDs = subscription.pullPaymentIDs;
		} else {
			// Return an empty array for `_subscriptionPullPaymentIDs`in case the caller is not
			// the payee or the subscriber
			uint256[] memory emptyArray;
			sb.subscription.pullPaymentIDs = emptyArray;
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
		returns (PullPaymentData memory pullPayment)
	{
		require(
			_pullPaymentID > 0 && _pullPaymentID <= _pullPaymentIDs.current(),
			'RecurringDynamicPullPayment: INVALID_PULLPAYMENT_ID'
		);

		uint256 bmID = _subscriptionToBillingModel[_pullPaymentToSubscription[_pullPaymentID]];
		BillingModel storage bm = _billingModels[bmID];
		pullPayment.billingModelID = bmID;
		pullPayment.subscriptionID = _pullPaymentToSubscription[_pullPaymentID];

		//intialize the subscription
		SubscriptionData storage subscription = subscriptions[
			_pullPaymentToSubscription[_pullPaymentID]
		].data;

		_initilizeSubscription(
			subscription,
			bm.recurringPPType,
			_pullPaymentToSubscription[_pullPaymentID]
		);

		if (
			msg.sender != bm.payee &&
			msg.sender != subscription.subscriber &&
			IPullPaymentRegistry(registry.getPullPaymentRegistry()).isExecutorGranted(msg.sender) == false
		) {
			return pullPayment;
		} else {
			if (bm.recurringPPType == 1) {
				pullPayment.paymentAmount = subscriptions[_pullPaymentToSubscription[_pullPaymentID]]
					.pullPayments[_pullPaymentID]
					.paymentAmount;
				pullPayment.executionTimestamp = subscriptions[_pullPaymentToSubscription[_pullPaymentID]]
					.pullPayments[_pullPaymentID]
					.executionTimestamp;
			} else if (bm.recurringPPType == 2) {
				pullPayment.paymentAmount = freeTrialSubscriptions[
					_pullPaymentToSubscription[_pullPaymentID]
				]
					.subscription[_pullPaymentToSubscription[_pullPaymentID]]
					.pullPayments[_pullPaymentID]
					.paymentAmount;
				pullPayment.executionTimestamp = freeTrialSubscriptions[
					_pullPaymentToSubscription[_pullPaymentID]
				]
					.subscription[_pullPaymentToSubscription[_pullPaymentID]]
					.pullPayments[_pullPaymentID]
					.executionTimestamp;
			} else if (bm.recurringPPType == 3) {
				pullPayment.paymentAmount = paidTrialSubscriptions[
					_pullPaymentToSubscription[_pullPaymentID]
				]
					.subscription[_pullPaymentToSubscription[_pullPaymentID]]
					.pullPayments[_pullPaymentID]
					.paymentAmount;
				pullPayment.executionTimestamp = paidTrialSubscriptions[
					_pullPaymentToSubscription[_pullPaymentID]
				]
					.subscription[_pullPaymentToSubscription[_pullPaymentID]]
					.pullPayments[_pullPaymentID]
					.executionTimestamp;
			}
		}
	}

	/**
     @notice This method gets the subscription details of given subscripton Id for particular reucurring pullPayment
     @param subscription       - indicates the subscription struct which contains subscription data
     @param recurringPPType    - indicates the recurring pullPayment type
     @param subscriptionId     - indicates the subscription Id
     */
	function _initilizeSubscription(
		SubscriptionData storage subscription,
		uint256 recurringPPType,
		uint256 subscriptionId
	) internal view {
		if (recurringPPType == 1) {
			subscription = subscriptions[subscriptionId].data;
		} else if (recurringPPType == 2) {
			subscription = freeTrialSubscriptions[subscriptionId].subscription[subscriptionId].data;
		} else if (recurringPPType == 3) {
			subscription = paidTrialSubscriptions[subscriptionId].subscription[subscriptionId].data;
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
	 * @notice Retrieves canceled subscription ids for an address
	 * @dev Returns an array with the subscription IDs related with that address
	 * @param _subscriber 			- address the pull payment relates to
	 * @return subscriptionIDs 	- contains the list of cancelled subscriptions
	 */
	function getCanceledSubscriptionIdsByAddress(address _subscriber)
		external
		view
		returns (uint256[] memory subscriptionIDs)
	{
		return _inactiveSubscriptionsByAddress[_subscriber];
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

interface IRecurringDynamicPullPayment {
	struct BillingModelData {
		address payee;
		string merchantName;
		string uniqueReference;
		string merchantURL;
		uint8 recurringPPType;
		uint256[] subscriptionIDs;
		uint256 creationTime;
	}

	struct SubscriptionData {
		address subscriber;
		string bmName;
		uint256 paymentAmount;
		address settlementToken;
		address paymentToken;
		uint256 totalPayments;
		uint256 remainingPayments;
		uint256 frequency;
		uint256 startTimestamp;
		uint256 cancelTimestamp;
		uint256 nextPaymentTimestamp;
		uint256 lastPaymentTimestamp;
		uint256[] pullPaymentIDs;
		uint256 billingModelID;
		string uniqueReference;
		address cancelledBy;
	}

	struct Data {
		SubscriptionData subscription;
		uint256 trialPeriod;
		uint256 initialAmount;
	}

	function createBillingModel(
		address _payee,
		uint8 _recurringPPType,
		string memory _merchantName,
		string memory _reference,
		string memory _merchantURL
	) external returns (uint256 billingModelID);

	function subscribeToBillingModel(
		uint256 _billingModelID,
		string memory _bmName,
		address _settlementToken,
		address _paymentToken,
		uint256 _paymentAmount,
		uint256 _frequency,
		uint256 _totalPayments,
		uint256 _trialPeriod,
		uint256 _initialAMount,
		string memory _reference
	) external returns (uint256 subscriptionID);

	function executePullPayment(uint256 _subscriptionID) external returns (uint256);

	function cancelSubscription(uint256 _subscriptionID) external returns (uint256);

	function editBillingModel(
		uint256 _billingModelID,
		address _newPayee,
		string memory _newMerchantName,
		string memory _newMerchantURL
	) external returns (uint256);

	function getBillingModel(uint256 _billingModelID) external view returns (BillingModelData memory);

	function getSubscription(uint256 _subscriptionID) external view returns (Data memory);
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

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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
pragma solidity ^0.8.0;

import './KeeperBase.sol';
import './interfaces/IKeeperCompatibleInterface.sol';

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
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