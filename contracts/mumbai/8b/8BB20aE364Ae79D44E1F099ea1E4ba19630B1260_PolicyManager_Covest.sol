// SPDX-License-Identifier: Covest-Finance-v.1

pragma solidity 0.8.11;

import "./interfaces/IERC20.sol";
import "./interfaces/ICommander.sol";
import "./interfaces/ISubsidized.sol";
import "./interfaces/IAdminRouter.sol";
import "./interfaces/IRiskManager.sol";
import "./interfaces/INameRegistry.sol";
import "./interfaces/IPolicyDetails.sol";
import "./interfaces/ICapitalProvider.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract PolicyManager_Covest is
	Initializable,
	UUPSUpgradeable,
	ReentrancyGuardUpgradeable
{
	address public nameRegistry;

	mapping(bytes32 => bool) private _existsHashMessage;

	bytes32 public constant SUPER_MANAGER_ROLE =
		keccak256("SUPER_MANAGER_ROLE");
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

	event BoughtPolicy(
		string indexed policyIdForIndex,
		string policyId,
		address indexed asset,
		uint256[] pricing,
		address indexed referrer,
		uint256[] fundAllocationWeight,
		uint256 timeStamp
	);

	event RedeemedPolicy(
		string indexed policyIdForIndex,
		string policyId,
		address indexed user,
		address indexed asset,
		uint256 amountRequested,
		uint256[] weightRequested,
		uint256 timeStamp
	);

	struct BuyPolicyParams {
		address asset;
		string policyId;
		uint256[] pricing;
		uint256 generatedAt;
		uint256 expiresAt;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	struct RedeemPolicyParams {
		address user;
		address asset;
		string policyId;
		uint256 percentage;
		uint256 generatedAt;
		uint256 expiresAt;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	struct CallFundInFlowParams {
		string policyId;
		address caller;
		address asset;
		address referrer;
		address[7] addr;
		uint256 value;
		uint256[] weightRequested;
	}

	struct CallFundOutFlowParams {
		string policyId;
		address caller;
		address asset;
		address[7] addr;
		uint256 value;
		uint256[] weightRequested;
	}

	INameRegistry public NR;
	IAdminRouter public AR;
	IPolicyDetails public PDS;
	ICapitalProvider public CP;
	IRiskManager public RM;
	ISubsidized public SUB;
	address public V;

	INameRegistry.InitStructerParams private dataNameRegistry;

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

	modifier isReady() {
		require(NR.paused() == false, "Closed.");
		_;
	}

	modifier isApprove() {
		require(RM.isApprove(msg.sender), "You aren't Approve.");
		_;
	}

	modifier isSuperManager() {
		require(
			AR.hasRole(SUPER_MANAGER_ROLE, msg.sender),
			"You're not Super Manager."
		);
		_;
	}

	modifier checkAsset(address _asset) {
		require(
			AR.isSupportAssets(poolId, _asset),
			"This asset was not accept."
		);
		_;
	}

	function initialize(address _nameRegistry) public initializer {
		__ReentrancyGuard_init();
		__UUPSUpgradeable_init();

		NR = INameRegistry(_nameRegistry);
	}

	function init(INameRegistry.InitStructerParams memory initData) public {
		require(address(NR) == msg.sender, "Caller is not NameRegistry");

		dataNameRegistry = initData;
		poolName = initData.poolName;
		poolId = initData.poolId;

		AR = IAdminRouter(initData.AR);
		PDS = IPolicyDetails(initData.PDS);
		CP = ICapitalProvider(initData.CP);
		RM = IRiskManager(initData.RM);
		SUB = ISubsidized(initData.SUB);
		V = initData.V;
	}

	function _authorizeUpgrade(address newImplementation)
		internal
		override
		isSuperManager
	{}

	/**
	 *  @notice Get decimals of this poolId.
	 *  @return The uint8 value of the decimals that call to policyDetails.
	 */
	function decimals() public view returns (uint8) {
		return PDS.decimals();
	}

	/**
	 *  @notice Get isBlacklistUser that tell blacklisted or not.
	 *  @param _user The user address.
	 *  @return The boolean value that call policyDetails and it will return that tell blacklisted or not.
	 */
	function isBlacklistUser(address _user) public view returns (bool) {
		return PDS.isBlacklistUser(_user);
	}

	/**
	 *  @notice Get isBlacklistAssetsUser that tell blacklisted or not.
	 *  @param _user The user address.
	 *  @param _asset The asset address.
	 *  @return The boolean value that call policyDetails and it will return that tell blacklisted or not.
	 */
	function isBlacklistAssetsUser(address _user, address _asset)
		public
		view
		returns (bool)
	{
		return PDS.isBlacklistAssetsUser(_user, _asset);
	}

	/**
	 *  @notice Get fundAllocationWeight of the pool.
	 *  @return The array value that call policyDetails and it return the uint256 that is fundAllocationWeight.
	 */
	function fundAllocationWeight() public view returns (uint256[] memory) {
		return PDS.fundAllocationWeight();
	}

	/**
	 * @dev buyPolicyInternal for buyPolicy is valid or not.
	 * @return The boolean value that tell the policy param for buyPolicy is valid or not.
	 */
	function buyPolicyInternal(
		address _user,
		string memory _policyId,
		address _asset,
		uint256[] memory _pricing,
		bytes memory _data
	) private returns (bool) {
		BuyPolicyParams memory decodedData = decodedBuyPolicy(_data);
		require(
			keccak256(bytes(_policyId)) ==
				keccak256(bytes(decodedData.policyId)),
			"Data Policyid."
		);
		require(_asset == decodedData.asset, "Data Assets.");
		require(
			_pricing.length == decodedData.pricing.length,
			"pricing Length."
		);
		for (uint256 i = 0; i < decodedData.pricing.length; i++) {
			require(_pricing[i] == decodedData.pricing[i], "pricing Equal.");
		}
		require(decodedData.expiresAt > block.timestamp, "Time has expired");
		bytes32 hashMessage = verifyBuyCover(
			_user,
			_policyId,
			_asset,
			_pricing,
			decodedData.generatedAt,
			decodedData.expiresAt
		);

		require(
			_existsHashMessage[hashMessage] == false,
			"This hashMessage already used."
		);
		bytes32 message = ECDSAUpgradeable.toEthSignedMessageHash(hashMessage);
		address signer = ECDSAUpgradeable.recover(
			message,
			decodedData.v,
			decodedData.r,
			decodedData.s
		);
		if (signer == V) {
			_existsHashMessage[hashMessage] = true;
			return true;
		} else {
			return false;
		}
	}

	/**
	 * @dev decodedBuyPolicy for decode `_data` and put it into tuple.
	 * @return The tuple value that is BuyPolicyParams.
	 */
	function decodedBuyPolicy(bytes memory _data)
		internal
		pure
		returns (BuyPolicyParams memory)
	{
		(
			address asset,
			string memory policyId,
			uint256[] memory pricing,
			uint256 generatedAt,
			uint256 expiresAt,
			uint8 v,
			bytes32 r,
			bytes32 s
		) = abi.decode(
				_data,
				(
					address,
					string,
					uint256[],
					uint256,
					uint256,
					uint8,
					bytes32,
					bytes32
				)
			);

		BuyPolicyParams memory decodedData = BuyPolicyParams(
			asset,
			policyId,
			pricing,
			generatedAt,
			expiresAt,
			v,
			r,
			s
		);

		return decodedData;
	}

	/**
	 * @dev decodedRedeemPolicy for decode `_data` and put it into tuple.
	 * @return The tuple value that is RedeemPolicyParams.
	 */
	function decodedRedeemPolicy(bytes memory _data)
		internal
		pure
		returns (RedeemPolicyParams memory)
	{
		(
			address user,
			address asset,
			string memory policyId,
			uint256 percentage,
			uint256 generatedAt,
			uint256 expiresAt,
			uint8 v,
			bytes32 r,
			bytes32 s
		) = abi.decode(
				_data,
				(
					address,
					address,
					string,
					uint256,
					uint256,
					uint256,
					uint8,
					bytes32,
					bytes32
				)
			);
		RedeemPolicyParams memory decodedData = RedeemPolicyParams(
			user,
			asset,
			policyId,
			percentage,
			generatedAt,
			expiresAt,
			v,
			r,
			s
		);
		return decodedData;
	}

	/**
	 * @dev redeemPolicyInternal for redeem is valid or not.
	 * @return The boolean value that tell the policy param for redeem is valid or not.
	 */
	function redeemPolicyInternal(
		address _user,
		string memory _policyId,
		address _asset,
		uint256 _percentRedeem,
		bytes memory _data
	) private returns (bool) {
		RedeemPolicyParams memory decodedData = decodedRedeemPolicy(_data);
		require(_user == decodedData.user, "Invalid User.");
		require(
			keccak256(bytes(_policyId)) ==
				keccak256(bytes(decodedData.policyId)),
			"Data policyid."
		);
		require(_asset == decodedData.asset, "Invalid asset.");
		require(
			_percentRedeem == decodedData.percentage,
			"Invalid Percentage."
		);
		require(decodedData.expiresAt > block.timestamp, "Time has expired");

		bytes32 hashMessage = verifyRedeem(
			_user,
			_policyId,
			_asset,
			decodedData.percentage,
			decodedData.generatedAt,
			decodedData.expiresAt
		);

		require(
			_existsHashMessage[hashMessage] == false,
			"This hashMessage already used."
		);

		bytes32 message = ECDSAUpgradeable.toEthSignedMessageHash(hashMessage);
		address signer = ECDSAUpgradeable.recover(
			message,
			decodedData.v,
			decodedData.r,
			decodedData.s
		);
		if (signer == V) {
			_existsHashMessage[hashMessage] = true;
			return true;
		} else {
			return false;
		}
	}

	/**
	 * @dev buyPolicyWillIssue for issuePolicy to policyDetails and return it true.
	 * @return The boolean value that tell the policy param for buyPolicy is valid or not.
	 */
	function buyPolicyWillIssue(
		string memory _policyId,
		address _asset,
		uint256[] memory _pricing,
		address _userIsRefer
	) private returns (bool) {
		(uint256 _valueSub, , uint256 _percentSub, string memory _orgSub) = SUB
			.checkSubsidized(
				msg.sender,
				_asset,
				_pricing[0] * 10**_pricing[2],
				poolId
			);
		bytes memory _data = abi.encode(
			_policyId,
			msg.sender,
			_asset,
			_pricing,
			_userIsRefer,
			_valueSub,
			_percentSub,
			_orgSub
		);
		try PDS.issuePolicy(_data) {
			return true;
		} catch {
			return false;
		}
	}

	/**
	 * @notice buyPolicy.
	 * @param _policyId The policyId for issuePolicy.
	 * @param _asset The asset address.
	 * @param _pricing The uint256 value of pricing array.
	 * @param _referrer The referrer address.
	 * @param _data The data for valid params and verify it from verifyAddress.
	 *
	 * Requirements:
	 *  - `nonReentrant` Can't call multiple when the first tx is pending of a user.
	 *  - `isReady` The pool must not paused.
	 *  - `isApprove` The ( user || distributor ) must approve from riskManager.
	 *  - `checkASset` The asset address must approve from adminRouter for this pool.
	 *  - `msg.sender` Must not be blacklisted "user" and "asset".
	 */
	function buyPolicy(
		string memory _policyId,
		address _asset,
		uint256[] memory _pricing,
		address _referrer,
		bytes calldata _data
	) public nonReentrant isReady isApprove checkAsset(_asset) {
		IERC20 _ERC20 = IERC20(_asset);
		INameRegistry.InitStructerParams memory _DMR = dataNameRegistry;
		require(
			RM.riskCoefficientOfUser(msg.sender) > 0 &&
				RM.riskCoefficientOfUser(msg.sender) <= RM.maxRiskCoefficient(),
			"RiskLevel is not valid."
		);
		require(isBlacklistUser(msg.sender) != true, "Blacklist User.");
		require(
			isBlacklistAssetsUser(msg.sender, _asset) != true,
			"Blacklist Assets of User."
		);
		uint256[] memory _fundAllocationWeight = fundAllocationWeight();
		require(
			_fundAllocationWeight.length == 7,
			"Invaild Length of fundAllocationWeight"
		);
		require(PDS.exist(_policyId) != true, "This _policyId exist.");

		{
			bool isDistributor = AR.isPolicyDistributor(poolId, msg.sender);

			if (isDistributor == false) {
				require(
					PDS.activePoliciesUser(msg.sender) == 0,
					"You have active policy."
				);
			}

			if (PDS.isOnlyDistributor() == true) {
				require(isDistributor == true, "You are not Distributor.");
			}
		}

		require(
			buyPolicyInternal(msg.sender, _policyId, _asset, _pricing, _data),
			"Data error."
		);

		uint256 _value = _pricing[0] * 10**_pricing[2];
		require(
			_ERC20.allowance(msg.sender, address(this)) >= _value,
			"Insufficient allowance"
		);
		require(_ERC20.balanceOf(msg.sender) >= _value, "Insufficient balance");
		require(
			_pricing[2] == _ERC20.decimals(),
			"Invalid Decimals of Assets."
		);

		{
			address[7] memory _paymentAddress = [
				_DMR.RF,
				_DMR.UW,
				_DMR.CA,
				_DMR.PD,
				_DMR.CM,
				_DMR.PF,
				_DMR.CP
			];

			_batchTransfer(
				msg.sender,
				_asset,
				_paymentAddress,
				_value,
				_fundAllocationWeight
			);

			bool isSuccess = buyPolicyWillIssue(
				_policyId,
				_asset,
				_pricing,
				_referrer
			);
			require(isSuccess == true, "BuyPolicy Error");

			// percentall = [RF,UW,CA,PD,CP,PF,Investment Profit + Profit(CSM) + Claim Reserve ** all above in 3 item it is CapitalProvier]

			_callFundInFlow(
				CallFundInFlowParams(
					_policyId,
					msg.sender,
					_asset,
					_referrer,
					_paymentAddress,
					_value,
					_fundAllocationWeight
				)
			);
		}

		emit BoughtPolicy(
			_policyId,
			_policyId,
			_asset,
			_pricing,
			_referrer,
			_fundAllocationWeight,
			block.timestamp
		);
	}

	/**
	 * @dev _batchTransfer for transfer assets from _caller to other contracts and it is called by buyPolicy.
	 * @param _caller The caller address.
	 * @param _asset The asset address.
	 * @param _addr The payment address array in this is contract 7 contracts.
	 * @param _amount The amount value to transfer.
	 * @param _fundAllocationWeight The fundAllocationWeight array.
	 */
	function _batchTransfer(
		address _caller,
		address _asset,
		address[7] memory _addr,
		uint256 _amount,
		uint256[] memory _fundAllocationWeight
	) internal {
		IERC20 _ERC20 = IERC20(_asset);

		require(
			_addr.length == _fundAllocationWeight.length,
			"Error Length BATCHTRANSFER"
		);

		for (uint256 i = 0; i < _addr.length; i++) {
			bool isMoreThanZero = (_amount * _fundAllocationWeight[i]) / 100 > 0
				? true
				: false;
			if (isMoreThanZero) {
				_ERC20.transferFrom(
					_caller,
					_addr[i],
					(_amount * _fundAllocationWeight[i]) / 100
				);
			}
		}
	}

	/**
	 * @dev _callFundInFlow for set the data that recevied transfer to that contract and others data from _caller to other contracts and it is called by buyPolicy.
	 * @param _params The CallFundInFlowParams tuple.
	 */
	function _callFundInFlow(CallFundInFlowParams memory _params) private {
		require(
			_params.addr.length == _params.weightRequested.length,
			"Error Length CALLDATA"
		);

		for (uint256 i = 0; i < _params.addr.length; i++) {
			if (i == 0) {
				ICommander(_params.addr[i]).fundInFlow(
					_params.caller,
					_params.asset,
					_params.referrer,
					_params.policyId,
					(_params.value * _params.weightRequested[i]) / 100
				);
			} else {
				ICommander(_params.addr[i]).fundInFlow(
					_params.caller,
					_params.asset,
					_params.policyId,
					(_params.value * _params.weightRequested[i]) / 100
				);
			}
		}
	}

	/**
	 * @dev _callFundOutFlow for set the data that recevied that want to redeem that will transfer from contract to user and set others data to contracts and it is called by redeemPolicy.
	 * @param _params The CallFundInFlowParams tuple.
	 */
	function _callFundOutFlow(CallFundOutFlowParams memory _params) private {
		require(
			_params.addr.length == _params.weightRequested.length,
			"Error Length CALLDATA"
		);

		for (uint256 i = 0; i < _params.addr.length; i++) {
			ICommander(_params.addr[i]).fundOutFlow(
				_params.caller,
				_params.asset,
				_params.policyId,
				(_params.value * _params.weightRequested[i]) / 100
			);
		}
	}

	/**
	 * @notice redeemPolicy.
	 * @param _policyId The policyId for issuePolicy.
	 * @param _percentRedeem The percentage that from backend to tell this user will get how many percent that will cash back to user.
	 * @param _data The data for valid params and verify it from verifyAddress.
	 *
	 * Requirements:
	 *  - `nonReentrant` Can't call multiple when the first tx is pending of a user.
	 *  - `isReady` The pool must not paused.
	 *  - `msg.sender` Must not be blacklisted "user" and "asset".
	 *  - `_policyId` The pending claim request of policyId must be zero.
	 *  - `_policyId` The policyId must be active and must not redeemed.
	 */
	function redeemPolicy(
		string memory _policyId,
		uint256 _percentRedeem,
		bytes calldata _data
	) public nonReentrant isReady {
		(
			IPolicyDetails.PolicyIdData memory PolicyIdUserData,
			bool isActive,
			bool isRedeem
		) = PDS.policyData(_policyId);
		INameRegistry.InitStructerParams memory _DMR = dataNameRegistry;

		if (PDS.isOnlyDistributor() == true) {
			require(
				AR.isPolicyDistributor(poolId, msg.sender) == true,
				"You are not Distributor."
			);
		}

		require(
			PolicyIdUserData.user == msg.sender,
			"You aren't own this policy."
		);
		require(
			CP.pendingClaimRequest(_policyId) == 0,
			"You are on Request Claim."
		);
		require(isActive == true, "Policy are not active.");
		require(isRedeem != true, "PolicyId already redeem.");
		require(isBlacklistUser(msg.sender) != true, "Blacklist User.");
		require(
			isBlacklistAssetsUser(msg.sender, PolicyIdUserData.asset) != true,
			"Blacklist Assets of User."
		);
		require(
			(PolicyIdUserData.fundAllocationWeight).length == 7,
			"Percent should be have 7 arguments."
		);
		require(
			redeemPolicyInternal(
				msg.sender,
				_policyId,
				PolicyIdUserData.asset,
				_percentRedeem,
				_data
			),
			"Redeem Error."
		);
		require(
			_percentRedeem <= 100 && _percentRedeem > 0,
			"Error Percentage."
		);

		(, string memory errorMessage, uint256 redeemId) = PDS.redeemPolicy(
			_policyId,
			_percentRedeem
		);

		require(redeemId != 0, errorMessage);
		require(
			PDS.whoIsRequest(PolicyIdUserData.asset, redeemId) == msg.sender,
			"ERROR THIS REDEEMID NOT YOUR OWN."
		);

		uint256 amountRequested = (PDS.amountRequest(
			PolicyIdUserData.asset,
			redeemId
		) / 10**(decimals() - IERC20(PolicyIdUserData.asset).decimals()));
		uint256[] memory weightRequested = PDS.weightRequest(
			PolicyIdUserData.asset,
			redeemId
		);

		_callFundOutFlow(
			CallFundOutFlowParams(
				_policyId,
				msg.sender,
				PolicyIdUserData.asset,
				[_DMR.RF, _DMR.UW, _DMR.CA, _DMR.PD, _DMR.CM, _DMR.PF, _DMR.CP],
				amountRequested,
				weightRequested
			)
		);

		emit RedeemedPolicy(
			_policyId,
			_policyId,
			msg.sender,
			PolicyIdUserData.asset,
			amountRequested,
			weightRequested,
			block.timestamp
		);
	}

	/**
	 * @notice verifyBuyCover.
	 * @dev This function for verifyMessage from backend.
	 * _pricing must be [buyAmount,coverAmount,decimalsOfAsset] e.g. [200,1000,6] in this meaning it should receive 200*10**6 from the user and coverAmount is cover of that policyId.
	 * _generatedAt Timestamp in second.
	 * _expiresAt Timestamp in second.
	 * @param _user The user address.
	 * @param _policyId The policyId for issuePolicy.
	 * @param _asset The asset address.
	 * @param _pricing The pricing.
	 * @param _generatedAt The timestamp of generateAt.
	 * @param _expiresAt The timestamp of expiresAt.
	 * @return The bytes32 value.
	 */
	function verifyBuyCover(
		address _user,
		string memory _policyId,
		address _asset,
		uint256[] memory _pricing,
		uint256 _generatedAt,
		uint256 _expiresAt
	) public view returns (bytes32) {
		IRiskManager _RM_ = RM;
		return
			keccak256(
				abi.encodePacked(
					_user,
					_asset,
					_policyId,
					_pricing,
					_RM_.isApprove(_user),
					_RM_.riskCoefficientOfUser(_user),
					_generatedAt,
					_expiresAt,
					address(this)
				)
			);
	}

	/**
	 * @notice verifyRedeem.
	 * @dev This function for verifyMessage from backend.
	 * _percentRedeem e.g. 100 that mean it will cash back 100%.
	 * _generatedAt Timestamp in second.
	 * _expiresAt Timestamp in second.
	 * @param _user The user address.
	 * @param _policyId The policyId for issuePolicy.
	 * @param _asset The asset address.
	 * @param _percentRedeem The percentage that will cash back to the user.
	 * @param _generatedAt The timestamp of generateAt.
	 * @param _expiresAt The timestamp of expiresAt.
	 * @return The bytes32 value.
	 */
	function verifyRedeem(
		address _user,
		string memory _policyId,
		address _asset,
		uint256 _percentRedeem,
		uint256 _generatedAt,
		uint256 _expiresAt
	) public view returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					_user,
					_asset,
					_policyId,
					_percentRedeem,
					_generatedAt,
					_expiresAt,
					address(this)
				)
			);
	}

	/**
	 * @dev existsHashMessage for chcek that is exists hashMessage or not.
	 * @param _hashMessage Hashmessage.
	 * @return The boolean value that means `_hashMessage` exists or not.
	 */
	function existsHashMessage(bytes32 _hashMessage)
		private
		view
		returns (bool)
	{
		return _existsHashMessage[_hashMessage];
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

import "./INameRegistry.sol";

interface ICommander {

    function fundInFlow(address _caller,address _asset,string memory _policyId, uint256 _value) external;
    function fundInFlow(address _caller,address _asset, address _referer,string memory _policyId, uint256 _value) external;
    function fundOutFlow(address _caller,address _asset,string memory _policyId, uint256 _value) external;
    function init(INameRegistry.InitStructerParams memory initData) external;
    
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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