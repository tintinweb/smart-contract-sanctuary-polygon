// SPDX-License-Identifier: Covest-Finance-v.1

pragma solidity 0.8.11;

import "./interfaces/IERC20.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ISubsidized.sol";
import "./interfaces/IAdminRouter.sol";
import "./interfaces/IRiskManager.sol";
import "./interfaces/INameRegistry.sol";
import "./interfaces/ICapitalProvider.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract PolicyDetails_Covest is
	Initializable,
	UUPSUpgradeable,
	ReentrancyGuardUpgradeable
{
	mapping(address => bool) internal _blacklistUser;
	mapping(address => mapping(address => bool)) internal _blacklistUserAssets;
	mapping(address => mapping(uint256 => uint256)) internal _amountRequest;
	mapping(address => mapping(uint256 => address)) internal _whoIsRequest;
	mapping(address => mapping(uint256 => uint256[])) internal _weightRequest;
	mapping(address => mapping(uint256 => RedeemData)) internal _redeemData;
	mapping(string => PolicyIdData) internal _policyIdData;
	mapping(address => mapping(uint256 => string)) private _requestPolicyId;
	mapping(string => bool) private _existPolicies;
	mapping(address => string[]) internal _keepPolicyUser;

	struct RedeemData {
		address user;
		uint256 id;
		bool approved;
		uint256 amountRequest;
		uint256[] weightOfThisRequest;
		address signature;
	}

	struct PolicyIdData {
		address user;
		address asset;
		address referrer;
		string policyId;
		string orgSubsidized;
		uint256 startDate;
		uint256 untilDate;
		uint256 buyValue;
		uint256 maxCoverage;
		uint256 valueSubsidized;
		uint256 percentSubsidized;
		uint256[] fundAllocationWeight;
		bool isRedeemed;
	}

	struct IssuePolicyParams {
		string policyId;
		address user;
		address asset;
		uint256[] pricing;
		address referrer;
		uint256 valueSub;
		uint256 percentSub;
		string orgSub;
	}

	uint256[] internal _fundAllocationWeight_;

	uint256 private redeemId;

	string[] private _keepPolicyPool;
	/**
	 *  @notice Get poolName.
	 *  @return The string value that is the name of the pool.
	 */
	string public poolName;
	/**
	 *  @notice Get poolId.
	 *  @return The string value that is the id of the pool.
	 */
	string public poolId;

	/**
	 *  @notice Get count totalPolicies.
	 *  @return The uint256 value that tell totalPolicies in this moment.
	 */
	uint256 public totalPolicies;
	uint256 internal allPoliciesBeforeCalculate;

	/**
	 *  @notice Get totalPoliciesValue.
	 *  @return The uint256 value that tell totalPoliciesValue in this moment.
	 */
	uint256 public totalPoliciesValue;
	uint256 internal allPoliciesValueBeforeCalculate;

	/**
	 *  @notice Get totalPoliciesCoverageValue.
	 *  @return The uint256 value that tell totalPoliciesCoverageValue in this moment.
	 */
	uint256 public totalPoliciesCoverageValue;
	uint256 internal allPoliciesCoverageValueBeforeCalculate;

	uint256 private _countPoliciesIndex;

	/**
	 *  @notice Get lossProb.
	 *  @dev e.g. In the reallife lossProb is 0.0027 %
	 *  that lossProb in Blockchain is 0.0027 * 10 ** ${decimals}
	 *  e.g. decimals is 27 => 0.0027 * 10 ** 27 that is value of the lossProb.
	 *  @return The uint256 value of lossProb.
	 */
	uint256 public lossProb;

	/**
	 *  @notice Get isOnlyDistributor.
	 *  @dev To tell this pool who can buy if `false` the `user` that already approve and `distributor` can buy
	 *  if `true` oinly distributor can buy.
	 *  @return The boolean value.
	 */
	bool public isOnlyDistributor;

	mapping(uint256 => string) private _keepPoliciesIndex;
	mapping(string => bool) private _isMinusPolices;

	bytes32 public constant SUPER_MANAGER_ROLE =
		keccak256("SUPER_MANAGER_ROLE");
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

	event BoughtPolicy(
		string indexed policyIdForIndex,
		string policyId,
		address indexed asset,
		uint256[] pricing,
		address indexed referrer,
		uint256[] fundAllocationWeight
	);
	event PolicySubsidized(
		string indexed OrgForIndex,
		string Org,
		uint256 valueSubsidized,
		uint256 percentSubsidized
	);
	event Redeemed(
		uint256 indexed caseId,
		address indexed user,
		address indexed asset
	);

	event BlacklistUserChanged(address[] user, bool[] boolean);
	event BlacklistAssetsUserChanged(
		address[] assets,
		address[] user,
		bool[] boolean
	);
	event FundAllocationWeightChanged(uint256[] weightOfFundAllocation);

	INameRegistry public NR;
	IAdminRouter public AR;
	IRiskManager public RM;
	ISubsidized public SUB;
	ICapitalProvider public CP;

	modifier thisContract() {
		require(msg.sender == address(this), "You are not me haha.");
		_;
	}

	modifier isReady() {
		require(NR.paused() == false, "Closed.");
		_;
	}

	modifier isApprove(address _user) {
		require(RM.isApprove(_user), "You aren't Approve.");
		_;
	}

	modifier isSuperManager() {
		require(
			AR.hasRole(SUPER_MANAGER_ROLE, msg.sender),
			"You're not Super Manager."
		);
		_;
	}

	modifier onlyPolicyManager() {
		require(
			msg.sender == NR.getContract("PM"),
			"You aren't an Policy Manager."
		);
		_;
	}

	function initialize(
		string memory _poolName,
		string memory _poolId,
		address _nameRegistry,
		uint256[] memory _fundAllocationWeight
	) public initializer {
		__ReentrancyGuard_init();
		__UUPSUpgradeable_init();

		NR = INameRegistry(_nameRegistry);
		poolName = _poolName;
		poolId = _poolId;
		_setFundAllocationWeight(_fundAllocationWeight);
	}

	function _authorizeUpgrade(address newImplementation)
		internal
		override
		isSuperManager
	{}

	function init(INameRegistry.InitStructerParams memory initData) public {
		require(address(NR) == msg.sender, "Caller is not NameRegistry");
		AR = IAdminRouter(initData.AR);
		RM = IRiskManager(initData.RM);
		SUB = ISubsidized(initData.SUB);
		CP = ICapitalProvider(initData.CP);
	}

	/**
	 *  @notice Get count activePolicies.
	 *  @return The uint256 value that tell activePolicies in this moment.
	 */
	function activePolicies() public view returns (uint256) {
		uint256 allPoliciesBeforeCalculated = allPoliciesBeforeCalculate;
		uint256 allExpires = 0;
		uint256 allAlreadyMinus;
		for (uint256 i = 0; i < _countPoliciesIndex; i++) {
			string memory _policyId = _keepPoliciesIndex[i];
			if (_isMinusPolices[_policyId]) {
				allAlreadyMinus++;
			} else if (
				(block.timestamp > _policyIdData[_policyId].untilDate) &&
				!_isMinusPolices[_policyId]
			) {
				allExpires++;
			}
		}

		return allPoliciesBeforeCalculated - allAlreadyMinus - allExpires;
	}

	/**
	 *  @notice Get activePoliciesValue.
	 *  @return The uint256 value that tell activePoliciesValue in this moment.
	 */
	function activePoliciesValue() public view returns (uint256) {
		uint256 allPoliciesValueBeforeCalculated = allPoliciesValueBeforeCalculate;
		uint256 allValueExpires;
		uint256 allValueAlreadyMinus;
		for (uint256 i = 0; i < _countPoliciesIndex; i++) {
			string memory _policyId = _keepPoliciesIndex[i];
			if (_isMinusPolices[_policyId]) {
				allValueAlreadyMinus += _policyIdData[_policyId].buyValue;
			} else if (
				(block.timestamp > _policyIdData[_policyId].untilDate) &&
				!_isMinusPolices[_policyId]
			) {
				allValueExpires += _policyIdData[_policyId].buyValue;
			}
		}

		return
			allPoliciesValueBeforeCalculated -
			allValueAlreadyMinus -
			allValueExpires;
	}

	/**
	 *  @notice Get activePoliciesCoverageValue.
	 *  @return The uint256 value that tell activePoliciesCoverageValue in this moment.
	 */
	function activePoliciesCoverageValue() public view returns (uint256) {
		uint256 allPoliciesCoverageValueBeforeCalculated = allPoliciesCoverageValueBeforeCalculate;
		uint256 allCoverageValueExpires = 0;
		uint256 allCoverageValueAlreadyMinus;
		for (uint256 i = 0; i < _countPoliciesIndex; i++) {
			string memory _policyId = _keepPoliciesIndex[i];
			if (_isMinusPolices[_policyId]) {
				allCoverageValueAlreadyMinus += _policyIdData[_policyId]
					.maxCoverage;
			} else if (
				(block.timestamp > _policyIdData[_policyId].untilDate) &&
				!_isMinusPolices[_policyId]
			) {
				allCoverageValueExpires += _policyIdData[_policyId].maxCoverage;
			}
		}

		return
			allPoliciesCoverageValueBeforeCalculated -
			allCoverageValueAlreadyMinus -
			allCoverageValueExpires;
	}

	/**
	 *  @notice Set the value of lossProb.
	 *  @param _lossProb The probability of loss of a policy.
	 *
	 *  Requirements:
	 *   - `msg.sender` Must be a SuperManager.
	 *   - `_lossProb` Has a decimal 27.
	 */
	function setLossProb(uint256 _lossProb) public isSuperManager {
		lossProb = _lossProb;
	}

	/**
	 *  @notice Set the value of isOnlyDistributor.
	 *  @param _boolean The value of isOnlyDistributor.
	 *
	 *  Requirements:
	 *   - `msg.sender` Must be a SuperManager.
	 *   - `_boolean` Must be true or false.
	 */
	function setOnlyDistributor(bool _boolean) public isSuperManager {
		isOnlyDistributor = _boolean;
	}

	/**
	 *  @notice Get the requester of the redeemed.
	 *  @param _asset  The asset address.
	 *  @param _redeemId The redeemId.
	 *  @return The address value of the requestor.
	 */
	function whoIsRequest(address _asset, uint256 _redeemId)
		public
		view
		returns (address)
	{
		return _whoIsRequest[_asset][_redeemId];
	}

	/**
	 *  @notice Get the fundAllocationWeight of the redeemed.
	 *  @param _asset  The asset address.
	 *  @param _redeemId The redeemId.
	 *  @return The array value of the uint256 that is fundAllocationWeight.
	 */
	function weightRequest(address _asset, uint256 _redeemId)
		public
		view
		returns (uint256[] memory)
	{
		return _weightRequest[_asset][_redeemId];
	}

	/**
	 *  @notice Get the amountRequest of the redeemed.
	 *  @param _asset  The asset address.
	 *  @param _redeemId The redeemId.
	 *  @return The uint256 value of the amountRequest.
	 */
	function amountRequest(address _asset, uint256 _redeemId)
		public
		view
		returns (uint256)
	{
		return _amountRequest[_asset][_redeemId];
	}

	/**
	 *  @notice Get the redeemData of the redeemed.
	 *  @param _asset  The asset address.
	 *  @param _redeemId The redeemId.
	 *  @return The tuple value of the redeemData.
	 */
	function redeemData(address _asset, uint256 _redeemId)
		public
		view
		returns (RedeemData memory)
	{
		return _redeemData[_asset][_redeemId];
	}

	/**
	 *  @notice Get isPolicyActive status as true or false.
	 *  @param _policyId The policyId.
	 *  @return isActive The boolean value of the policy that is active or not.
	 */
	function isPolicyActive(string memory _policyId)
		public
		view
		returns (bool isActive)
	{
		if (
			isBlacklistUser(_policyIdData[_policyId].user) == true ||
			isBlacklistAssetsUser(
				_policyIdData[_policyId].user,
				_policyIdData[_policyId].asset
			) ==
			true
		) {
			return false;
		} else if (
			_policyIdData[_policyId].untilDate >= block.timestamp &&
			block.timestamp >= _policyIdData[_policyId].startDate
		) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 *  @notice Get decimals of this poolId.
	 *  @return The uint256 value of the decimals.
	 */
	function decimals() public pure returns (uint8) {
		return 18;
	}

	/**
	 *  @notice Get policyId exist or not.
	 *  @param _policyId The policyId.
	 *  @return The boolean value that policyId exist as true or false.
	 */
	function exist(string memory _policyId) public view returns (bool) {
		return _existPolicies[_policyId];
	}

	/**
	 *  @notice Get policyData of the policyId.
	 *  @param _policyId The policyId.
	 *  @return PolicyIdData The tuple value of the PolicyIdData.
	 *  @return isActive The boolean value of the policy that is active or not.
	 *  @return isRedeem The boolean value of the policy that is redeem or not.
	 */
	function policyData(string memory _policyId)
		public
		view
		returns (
			PolicyIdData memory,
			bool isActive,
			bool isRedeem
		)
	{
		if (
			isBlacklistUser(_policyIdData[_policyId].user) == true ||
			isBlacklistAssetsUser(
				_policyIdData[_policyId].user,
				_policyIdData[_policyId].asset
			) ==
			true ||
			_policyIdData[_policyId].isRedeemed == true
		) {
			return (
				_policyIdData[_policyId],
				false,
				_policyIdData[_policyId].isRedeemed
			);
		} else if (
			_policyIdData[_policyId].untilDate >= block.timestamp &&
			block.timestamp >= _policyIdData[_policyId].startDate
		) {
			return (
				_policyIdData[_policyId],
				true,
				_policyIdData[_policyId].isRedeemed
			);
		} else {
			return (
				_policyIdData[_policyId],
				false,
				_policyIdData[_policyId].isRedeemed
			);
		}
	}

	/**
	 *  @dev Set the value of fundAllocationWeight.
	 *  @param _fundAllocationWeight The array value of the uint256 that is fundAllocationWeight.
	 *
	 *  Requirements:
	 *   - `_fundAllocationWeight` Sum of the fundAllocationWeight must be 100.
	 */
	function _setFundAllocationWeight(uint256[] memory _fundAllocationWeight)
		private
	{
		uint256 countpercent;

		for (uint256 i = 0; i < _fundAllocationWeight.length; i++) {
			countpercent += _fundAllocationWeight[i];
		}

		require(countpercent == 100, "Error Counting Percentage");
		_fundAllocationWeight_ = _fundAllocationWeight;

		emit FundAllocationWeightChanged(_fundAllocationWeight);
	}

	/**
	 *  @notice Set the value of fundAllocationWeight (fundAllocationWeight).
	 *  @param _fundAllocationWeight The array value of the uint256 that is fundAllocationWeight.
	 *
	 *  Requirements:
	 *   - `msg.sender` Must be a SuperManager.
	 *   - `_fundAllocationWeight` Sum of the fundAllocationWeight must be 100.
	 */
	function setFundAllocationWeight(uint256[] memory _fundAllocationWeight)
		public
		isSuperManager
	{
		require(
			_fundAllocationWeight.length == 7,
			"Percent should be have 7 arguments."
		);

		_setFundAllocationWeight(_fundAllocationWeight);
	}

	/**
	 *  @dev Get tuple value of IssuePolicyParams.
	 *  @param _data The value of the byte for decode.
	 *  @return The tuple value of IssuePolicyParams.
	 */
	function decodedIssuePolicy(bytes memory _data)
		internal
		pure
		returns (IssuePolicyParams memory)
	{
		(
			string memory _policyId,
			address _user,
			address _asset,
			uint256[] memory _pricing,
			address _referrer,
			uint256 _valueSub,
			uint256 _percentSub,
			string memory _orgSub
		) = abi.decode(
				_data,
				(
					string,
					address,
					address,
					uint256[],
					address,
					uint256,
					uint256,
					string
				)
			);

		IssuePolicyParams memory decodedData = IssuePolicyParams(
			_policyId,
			_user,
			_asset,
			_pricing,
			_referrer,
			_valueSub,
			_percentSub,
			_orgSub
		);

		return decodedData;
	}

	/**
	 *  @notice issuePolicy.
	 *  @param _data The value of the byte for decode.
	 *
	 *  Requirements:
	 *   - `isReady` The pool must be ready.
	 *   - `msg.sender` Must be a PolicyManager address.
	 *   - `policyId` Must not exist in this pool.
	 */
	function issuePolicy(bytes calldata _data)
		public
		isReady
		onlyPolicyManager
	{
		// _dPD = decodedPolicyData //
		IssuePolicyParams memory _dPD = decodedIssuePolicy(_data);

		uint256[] memory mempercent = _fundAllocationWeight_;

		require(
			mempercent.length == 7,
			"Invaild Length of fundAllocationWeight"
		);
		require(exist(_dPD.policyId) != true, "This policyId exist");
		require(
			_dPD.pricing[2] == IERC20(_dPD.asset).decimals(),
			"Invalid Decimals of assets."
		);

		uint256 decimal = decimals();

		_existPolicies[_dPD.policyId] = true;

		_policyIdData[_dPD.policyId] = PolicyIdData(
			_dPD.user,
			_dPD.asset,
			_dPD.referrer,
			_dPD.policyId,
			_dPD.orgSub,
			block.timestamp,
			block.timestamp + 365 days,
			_dPD.pricing[0] * 10**decimal,
			_dPD.pricing[1] * 10**decimal,
			_dPD.valueSub,
			_dPD.percentSub,
			mempercent,
			false
		);

		_keepPolicyUser[_dPD.user].push(_dPD.policyId);
		_keepPolicyPool.push(_dPD.policyId);

		totalPolicies++;
		allPoliciesBeforeCalculate++;

		totalPoliciesValue += _dPD.pricing[0] * 10**decimal;
		allPoliciesValueBeforeCalculate += _dPD.pricing[0] * 10**decimal;

		totalPoliciesCoverageValue += _dPD.pricing[1] * 10**decimal;
		allPoliciesCoverageValueBeforeCalculate +=
			_dPD.pricing[1] *
			10**decimal;

		uint256 countPolicyIndex = _countPoliciesIndex;
		_keepPoliciesIndex[countPolicyIndex] = _dPD.policyId;

		_countPoliciesIndex++;

		emit BoughtPolicy(
			_dPD.policyId,
			_dPD.policyId,
			_dPD.asset,
			_dPD.pricing,
			_dPD.referrer,
			mempercent
		);

		if (_dPD.valueSub > 0) {
			SUB.claimSubsidized(
				_dPD.user,
				_dPD.asset,
				_dPD.pricing[0] * 10**_dPD.pricing[2],
				poolId
			);

			emit PolicySubsidized(
				_dPD.orgSub,
				_dPD.orgSub,
				_dPD.valueSub,
				_dPD.percentSub
			);
		}
	}

	/**
	 *  @dev Get redeemPolicy that tell can be redeem or not and with reason.
	 *  @param _policyId The policyId.
	 *  @param _percentRedeem The percentage to redeem.
	 *
	 *  Requirements:
	 *   - `_policyId` The policyId must be active.
	 *   - `_policyId` The policyId must not redeemed.
	 *   - `_policyId` The policyId must have pendingClaimRequest is zero.
	 *   - `_percentRedeem` The uint256 of _percentRedeem must greather than 0 and lessthan or equal to 100.
	 *   - `_policyId` The owner and asset of policyId must not be blacklisted.
	 *   - `_policyId` The fundAllocationWeight of policyId must have length 7.
	 */
	function checkRedeemPolicy(string memory _policyId, uint256 _percentRedeem)
		internal
		view
		returns (bool, string memory)
	{
		(, bool isActive, ) = policyData(_policyId);

		if (isActive == false) {
			return (false, "This Policy are not active at this moment.");
		}

		if (_policyIdData[_policyId].isRedeemed == true) {
			return (false, "This Policy already redeem.");
		}

		if (CP.pendingClaimRequest(_policyId) == 0) {
			return (false, "You are on request");
		}

		if (!(_percentRedeem <= 100 && _percentRedeem > 0)) {
			return (false, "Error Percentage.");
		}

		if (isBlacklistUser(_policyIdData[_policyId].user) == true) {
			return (false, "Blacklist User.");
		}

		if (
			(isBlacklistAssetsUser(
				_policyIdData[_policyId].user,
				_policyIdData[_policyId].asset
			) == true)
		) {
			return (false, "Blacklist assets of User.");
		}

		if (!((_policyIdData[_policyId].fundAllocationWeight).length == 7)) {
			return (false, "Percent should be have 7 arguments.");
		}

		return (true, "Success");
	}

	/**
	 *  @notice redeemPolicy.
	 *  @param _policyId The policyId.
	 *  @param _percentRedeem The percentage to redeem.
	 *
	 *  Requirements:
	 *   - `isReady` The pool must be ready.
	 *   - `msg.sender` Must be a PolicyManager address.
	 *
	 *  @return bool The boolean value that true is success or false is error.
	 *  @return string The message successful or error reason.
	 *  @return uint256 The redeemId of this.
	 */
	function redeemPolicy(string memory _policyId, uint256 _percentRedeem)
		public
		isReady
		onlyPolicyManager
		returns (
			bool,
			string memory,
			uint256
		)
	{
		(bool isCheckedPass, string memory messageIs) = checkRedeemPolicy(
			_policyId,
			_percentRedeem
		);

		if (isCheckedPass == false) {
			return (isCheckedPass, messageIs, 0);
		}

		redeemId++;

		address _user = _policyIdData[_policyId].user;
		address _asset = _policyIdData[_policyId].asset;

		if ((_policyIdData[_policyId].isRedeemed == true)) {
			return (false, "Already redeem.", 0);
		}

		_policyIdData[_policyId].isRedeemed = true;
		_amountRequest[_asset][redeemId] =
			(_policyIdData[_policyId].buyValue * _percentRedeem) /
			100;

		_whoIsRequest[_asset][redeemId] = _user;
		_weightRequest[_asset][redeemId] = _policyIdData[_policyId]
			.fundAllocationWeight;
		_requestPolicyId[_asset][redeemId] = _policyId;

		_redeemData[_asset][redeemId] = RedeemData(
			_user,
			redeemId,
			true,
			_amountRequest[_asset][redeemId],
			_weightRequest[_asset][redeemId],
			_user
		);

		_policyIdData[_policyId].isRedeemed = true;

		_isMinusPolices[_policyId] = true;

		emit Redeemed(redeemId, _user, _asset);

		return (true, "Success", redeemId);
	}

	/**
	 *  @notice Get fundAllocationWeight of the pool.
	 *  @return The array value of the uint256 that is fundAllocationWeight.
	 */
	function fundAllocationWeight() public view returns (uint256[] memory) {
		return _fundAllocationWeight_;
	}

	/**
	 *  @notice Get buyValue of the policyId.
	 *  @param _policyId The policyId.
	 *  @return The uint256 value of buyValue.
	 */
	function policyBuyValue(string memory _policyId)
		public
		view
		returns (uint256)
	{
		return _policyIdData[_policyId].buyValue;
	}

	/**
	 *  @notice Get boolean of the policyId that is redeem or not.
	 *  @param _policyId The policyId.
	 *  @return The boolean value that policyId is redeem or not.
	 */
	function isPolicyRedeem(string memory _policyId)
		public
		view
		returns (bool)
	{
		return _policyIdData[_policyId].isRedeemed;
	}

	/**
	 *  @notice Get fundAllocationWeight of the policyId.
	 *  @return The array value of the uint256 that is fundAllocationWeight of the policyId.
	 */
	function fundAllocationWeightPolicy(string memory _policyId)
		public
		view
		returns (uint256[] memory)
	{
		return _policyIdData[_policyId].fundAllocationWeight;
	}

	/**
	 *  @notice Get maxCoverage of the policyId.
	 *  @return The uint256 value fundAllocationWeight of the policyId.
	 */
	function maxCoveragePolicy(string memory _policyId)
		public
		view
		returns (uint256)
	{
		return _policyIdData[_policyId].maxCoverage;
	}

	/**
	 *  @notice Set blacklist user in this pool.
	 *  @param _user The user address array.
	 *  @param _boolean The boolean array.
	 *
	 *  Requirements:
	 *   - `msg.sender` Must be a SuperManager.
	 */
	function setBlacklistUser(address[] memory _user, bool[] memory _boolean)
		public
		isSuperManager
	{
		require(_user.length == _boolean.length, "Invaild Arrays");

		for (uint256 i = 0; i < _user.length; i++) {
			require(_user[i] != address(0), "Invaild Address");
			_blacklistUser[_user[i]] = _boolean[i];
		}

		emit BlacklistUserChanged(_user, _boolean);
	}

	/**
	 *  @notice Set blacklist asset of user in this pool.
	 *  @param _user The user address array.
	 *  @param _assets The assets address array.
	 *  @param _boolean The boolean array.
	 *
	 *  Requirements:
	 *   - `msg.sender` Must be a SuperManager.
	 */
	function blacklistAssetsUser(
		address[] memory _user,
		address[] memory _assets,
		bool[] memory _boolean
	) public isSuperManager {
		require(
			_user.length == _assets.length &&
				_user.length == _boolean.length &&
				_assets.length == _boolean.length,
			"Invaild Arrays"
		);

		for (uint256 i = 0; i < _user.length; i++) {
			require(_user[i] != address(0), "Invaild Address");
			require(_assets[i] != address(0), "Invaild Address");
			_blacklistUserAssets[_assets[i]][_user[i]] = _boolean[i];
		}

		emit BlacklistAssetsUserChanged(_assets, _user, _boolean);
	}

	/**
	 *  @notice Get isBlacklistUser that tell blacklisted or not.
	 *  @param _user The user address.
	 *  @return The boolean that tell blacklisted or not.
	 */
	function isBlacklistUser(address _user) public view returns (bool) {
		return _blacklistUser[_user];
	}

	/**
	 *  @notice Get isBlacklistAssetsUser that tell blacklisted or not.
	 *  @param _user The user address.
	 *  @param _asset The asset address.
	 *  @return The boolean that tell blacklisted or not.
	 */
	function isBlacklistAssetsUser(address _user, address _asset)
		public
		view
		returns (bool)
	{
		return _blacklistUserAssets[_asset][_user];
	}

	/**
	 *  @notice Get policyId array in this pool.
	 *  @return The policyId array.
	 */
	function policy() public view returns (string[] memory) {
		return _keepPolicyPool;
	}

	/**
	 *  @notice Get policyId array of the user in this pool.
	 *  @param _user The user address.
	 *  @return The policyId array.
	 */
	function policyUser(address _user) public view returns (string[] memory) {
		return _keepPolicyUser[_user];
	}

	/**
	 *  @notice Get count policy that is active of the user.
	 *  @param _user The user address.
	 *  @return The uint256 value that tell policy are active.
	 */
	function activePoliciesUser(address _user) public view returns (uint256) {
		uint256 countPoliciesActive = 0;
		string[] memory _policy = policyUser(_user);
		for (uint256 i = 0; i < _policy.length; i++) {
			if (isPolicyActive(_policy[i]) == true) {
				countPoliciesActive++;
			}
		}

		return countPoliciesActive;
	}

	/**
	 *  @notice Get count redeemId.
	 *  @return The uint256 value that tell redeemId in this moment.
	 */
	function redeemIdLength() public view returns (uint256) {
		return redeemId;
	}
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.11;

interface IERC20 {
	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function totalSupply() external view returns (uint256);

	function decimals() external view returns (uint8);

	function symbol() external view returns (string memory);

	function name() external view returns (string memory);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.11;

interface IFactory {
	struct PairsData {
		string poolName;
		string poolId;
		address policy;
		address nameRegistry;
	}

	function AR() external view returns (address);

	function MANAGER_ROLE() external view returns (bytes32);

	function SUPER_MANAGER_ROLE() external view returns (bytes32);

	function allPairs(uint256 _index) external view returns (PairsData memory);

	function allPairsLength() external view returns (uint256 length);

	function createPair(address _policyDetails, address _nameRegistry) external;

	function getPair(string memory _poolId) external view returns (address policy, address nameRegistry);

	function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.11;

interface ISubsidized {
	function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

	function MANAGER_ROLE() external view returns (bytes32);

	function PARTNER_ROLE() external view returns (bytes32);

	function SUPER_MANAGER_ROLE() external view returns (bytes32);

	function checkSubsidized(
		address _subsidized,
		address _asset,
		uint256 _price,
		string memory _poolId
	)
		external
		view
		returns (
			uint256 value,
			uint256 percent,
			uint256 valuePercent,
			string memory organizationName
		);

	function claimSubsidized(
		address _subsidized,
		address _asset,
		uint256 _price,
		string memory _poolId
	) external;

	function getImplementation() external view returns (address implementation);

	function getRoleAdmin(bytes32 role) external view returns (bytes32);

	function grantRole(bytes32 role, address _address) external;

	function hasRole(bytes32 role, address account) external view returns (bool);

	function renounceRole(bytes32 role, address account) external;

	function revokeRole(bytes32 role, address account) external;

	function setAdminRounterAddress(address _address) external;

	function setBulkSubsidizeInformation(
		address[] memory _addresses,
		uint256 _amount,
		string memory _poolId,
		uint256 _ended
	) external;

	function setNFTAddress(address _address) external;

	function setOrganizationName(string memory _name) external;

	function setSigner(address signer) external;

	function setSubsidizeInformation(
		address _subsidized,
		uint256 _amount,
		string memory _poolId,
		uint256 _ended
	) external;

	function setSubsidizeTank(address _address) external;

	function supportsInterface(bytes4 interfaceId) external view returns (bool);

	function updateNFTSubsidizeValue(uint256 tokenId, uint256 value) external;
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.11;

interface IAdminRouter {
	function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

	function MANAGER_ROLE() external view returns (bytes32);

	function SUPER_MANAGER_ROLE() external view returns (bytes32);

	function getAssetSupports(string memory _poolId) external view returns (address[] memory);

	function getAssetSupportsMI(string memory _poolId) external view returns (address);

	function getRoleAdmin(bytes32 role) external view returns (bytes32);

	function grantRole(bytes32 role, address account) external;

	function hasRole(bytes32 role, address account) external view returns (bool);

	function isNameRegistry(string memory _poolId, address _nameRegistry) external view returns (bool);

	function isPolicy(string memory _poolId, address _policy) external view returns (bool);

	function isPolicyDistributor(string memory _poolId, address _distributor) external view returns (bool);

	function isSupportAssets(string memory _poolId, address _currency) external view returns (bool);

	function isSupportAssetsMI(string memory _poolId, address _currency) external view returns (bool);

	function renounceRole(bytes32 role, address account) external;

	function revokeRole(bytes32 role, address account) external;

	function setAssestsMI(
		address _policyDetails,
		address _MI,
		bool _boolean
	) external;

	function setAssets(
		address _policyDetails,
		address[] memory _currency,
		bool[] memory _boolean
	) external;

	function setNameRegistry(address _nameRegistry, bool _boolean) external;

	function setPolicy(address _policy, bool _boolean) external;

	function setPolicyDistributor(
		address _policy,
		address _distributor,
		bool _boolean
	) external;

	function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.11;

interface IRiskManager {
	function AR() external view returns (address);

	function MANAGER_ROLE() external view returns (bytes32);

	function NR() external view returns (address);

	function S() external view returns (address);

	function SUPER_MANAGER_ROLE() external view returns (bytes32);

	function UW() external view returns (address);

	function approveUser(address _user, uint8 _riskCoefficient) external;

	function isApprove(address _user) external view returns (bool);

	function maxRiskCoefficient() external view returns (uint8);

	function reApproveUser(address _user, uint8 _riskCoefficient) external;

	function riskCoefficientOfUser(address _user) external view returns (uint8);

	function riskProfileUser(address _user) external view returns (bool approved, uint8 riskCoefficient);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.11;

interface INameRegistry {
	struct InitStructerParams {
		address F;
		address RF;
		address UW;
		address CA;
		address PD;
		address CM;
		address PF;
		address RM;
		address S;
		address CP;
		address AR;
		address PM;
		address PDS;
		address SUB;
		address MI;
		address V;
		string poolName;
		string poolId;
	}

	function AR() external view returns (address);

	function MANAGER_ROLE() external view returns (bytes32);

	function PDS() external view returns (address);

	function SUPER_MANAGER_ROLE() external view returns (bytes32);

	function getContract(string memory _contractName)
		external
		view
		returns (address);

	function getContracts(string[] memory _contractsName)
		external
		view
		returns (address[] memory);

	function pause() external;

	function paused() external view returns (bool);

	function poolId() external view returns (string memory);

	function poolName() external view returns (string memory);

	function proxiableUUID() external view returns (bytes32);

	function setContract(string memory _contractName, address _addr) external;

	function setup(address[] memory _contract) external;

	function unpause() external;
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.11;

import "./IPolicyDetails.sol";

interface ICapitalProvider {
	struct HistoryOfPolicyIdData {
		address owner;
		address asset;
		uint256 claimPending;
		uint256 claimAmountPaid;
		uint256 claimIdLasted;
	}

	struct ClaimIdRequestData {
		string proofData;
		string policyId;
		address user;
		address asset;
		uint256 timeout;
		uint256 requestAmount;
		uint256 approveAmount;
		address first;
		bool firstCheckerBool;
		uint256 caSnapshotValue;
		uint256 caSnapshotCount;
		uint256 caSnapshotVoteCount;
		uint256 votingPass;
		uint256 votingFailed;
	}

	function AR() external view returns (address);

	function CA() external view returns (address);

	function MANAGER_ROLE() external view returns (bytes32);

	function NR() external view returns (address);

	function PDS() external view returns (address);

	function S() external view returns (address);

	function SUPER_MANAGER_ROLE() external view returns (bytes32);

	function V() external view returns (address);

	function accessForClaimId(address _user, uint256 _claimId)
		external
		view
		returns (bool haveAccess, bool alreadyVote);

	function caProposalVoting(uint256 _claimId, bool _boolean) external;

	function claimIdCancel(uint256 _claimId) external;

	function claimIdStatus(uint256 _claimId) external view returns (uint8);

	function claimAmountPaid(string memory _policyId) external view returns (uint256);

	function claimIdLastedUserWithPolicyId(string memory _policyId) external view returns (uint256 claimId);

	function claimIdData(uint256 _claimId) external view returns (ClaimIdRequestData memory);

	function claimPolicyDataId(string memory _policyId) external view returns (HistoryOfPolicyIdData memory);

	function countClaimForRequest() external view returns (uint256);

	function existsIpfs(string memory _ipfsHash) external view returns (bool);

	function finalize(uint256 _claimId) external;

	function firstCAVote(
		uint256 _claimId,
		bool _boolean,
		uint256 _valueApprove
	) external;

	function fundInFlow(
		address _caller,
		address _asset,
		string memory _policyId,
		uint256 _value
	) external;

	function fundOutFlow(
		address _caller,
		address _asset,
		string memory _policyId,
		uint256 _value
	) external;

	function getAllClaimStatus(uint8 _status) external view returns (ClaimIdRequestData[] memory, uint256[] memory);

	function pendingClaimRequest(string memory _policyId) external view returns (uint256);

	function percentageWillPassWhenRequest() external view returns (uint256);

	function policyClaimId(string memory _policy) external view returns (uint256[] memory);

	function policyClaimRequest(
		string memory _policyId,
		string memory _ipfsHash,
		uint256 _value,
		bytes memory _data
	) external;

	function poolId() external view returns (string memory);

	function poolName() external view returns (string memory);

	function reInsuranceFeeAsset(
		address _to,
		address _asset,
		uint256 _value
	) external;

	function reInsuranceFeeNative(address _to, uint256 _value) external;

	function setPassPercentage(uint256 _percentage) external;

	function totalClaimValuePaid() external view returns (uint256);

	function totalClaimValueReserve() external view returns (uint256);

	function userClaimId(address _user) external view returns (uint256[] memory);

	function verifyClaimRequest(
		address _user,
		address _asset,
		string memory _ipfsHash,
		uint256 _value,
		uint256 _generatedAt,
		uint256 _expiresAt
	) external view returns (bytes32);

	function withdraw(
		address _to,
		address _asset,
		uint256 _value
	) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.11;

interface IPolicyDetails {

    struct PolicyIdData {
        address user;
        address asset;
        address referrer;
        string policyId;
        string orgSubsidized;
        uint256 startDate;
        uint256 untilDate;
        uint256 buyValue;
        uint256 maxCoverage;
        uint256 valueSubsidized;
        uint256 percentSubsidized;
        uint256[] fundAllocationWeight;
        bool isRedeemed;
    }

    struct RedeemData {
        address user;
        uint256 id;
        bool approved;
        uint256 amountRequest;
        uint256[] weightOfThisRequest;
        address signature;
    }

   function AR() external view returns (address);

    function MANAGER_ROLE() external view returns (bytes32);

    function NR() external view returns (address);

    function R() external view returns (address);

    function RM() external view returns (address);

    function SUB() external view returns (address);

    function SUPER_MANAGER_ROLE() external view returns (bytes32);

    function activePolicies() external view returns (uint256);

    function activePoliciesCoverageValue() external view returns (uint256);

    function activePoliciesUser(address _user) external view returns (uint256);

    function activePoliciesValue() external view returns (uint256);

    function amountRequest(address _asset, uint256 _redeemId)
        external
        view
        returns (uint256);

    function blacklistAssetsUser(
        address[] memory _user,
        address[] memory _assets,
        bool[] memory _boolean
    ) external;

    function decimals() external pure returns (uint8);

    function exist(string memory _policyId) external view returns (bool);

    function fundAllocationWeight() external view returns (uint256[] memory);

    function fundAllocationWeightPolicy(string memory _policyId)
        external
        view
        returns (uint256[] memory);

    function isBlacklistAssetsUser(address _user, address _asset)
        external
        view
        returns (bool);

    function isBlacklistUser(address _user) external view returns (bool);

    function isOnlyDistributor() external view returns (bool);

    function isPolicyActive(string memory _policyId)
        external
        view
        returns (bool isActive);

    function isPolicyRedeem(string memory _policyId)
        external
        view
        returns (bool);

    function issuePolicy(bytes memory _data) external;

    function lossProb() external view returns (uint256);

    function maxCoveragePolicy(string memory _policyId)
        external
        view
        returns (uint256);

    function policy() external view returns (string[] memory);

    function policyBuyValue(string memory _policyId)
        external
        view
        returns (uint256);

    function policyData(string memory _policyId)
        external
        view
        returns (
            PolicyIdData memory,
            bool isActive,
            bool isRedeem
        );

    function policyUser(address _user) external view returns (string[] memory);

    function poolId() external view returns (string memory);

    function poolName() external view returns (string memory);

    function redeemData(address _asset, uint256 _redeemId)
        external
        view
        returns (RedeemData memory);

    function redeemIdLength() external view returns (uint256);

    function redeemPolicy(string memory _policyId, uint256 _percentRedeem)
        external
        returns (
            bool,
            string memory,
            uint256
        );

    function setBlacklistUser(address[] memory _user, bool[] memory _boolean)
        external;

    function setFundAllocationWeight(uint256[] memory _fundAllocationWeight)
        external;

    function setLossProb(uint256 _lossProb) external;

    function setOnlyDistributor(bool _boolean) external;

    function totalPolicies() external view returns (uint256);

    function totalPoliciesCoverageValue() external view returns (uint256);

    function totalPoliciesValue() external view returns (uint256);

    function weightRequest(address _asset, uint256 _redeemId)
        external
        view
        returns (uint256[] memory);

    function whoIsRequest(address _asset, uint256 _redeemId)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
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
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
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

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}