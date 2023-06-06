// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./libs/WkmDateTime.sol";
import "./libs/Product020802Lib.sol";
import "./authentication/OwnableV01.sol";

contract Product020802V01 is OwnableV01 {
    using WkmDateTime for uint256;
    using Product020802Lib for uint256;
    bytes public constant PRODUCT_ID = "0208_02";
    int public constant TIME_ZONE_OFFSET = 1;

    uint256 public totalPolicies;
    mapping(string => Product020802Lib.Policy) private allPolicies;
    mapping(string => bool) public isPolicyExists;

    event NewPolicyCreated(
        string onChainPolicyId,
        uint256 termination,
        uint256 subscriptionDate,
        uint256 coverageStartDate,
        uint256 expirationDate
    );

    event PolicyCancelled(
        string onChainPolicyId,
        uint256 termination,
        uint256 operationType,
        uint256 operationEffectiveDate
    );

    function createPolicy(
        Product020802Lib.PolicyParams memory policyParams
    ) external onlyPartnerOrWakam(policyParams.partnershipCodeHash) {
        uint256 subscriptionDate = block.timestamp;
        require(!isPolicyExists[policyParams.onChainPolicyId], "policy already in storage");
        uint256 coverageStartDate = policyParams.requestedCoverageStartDate.computeCoverageStartDate(
            subscriptionDate,
            TIME_ZONE_OFFSET
        );

        Product020802Lib.checkBusinessRulesToCreatePolicy(policyParams, subscriptionDate, coverageStartDate);

        Product020802Lib.Policy storage policy = allPolicies[policyParams.onChainPolicyId];
        policy.onChainPolicyId = policyParams.onChainPolicyId;
        policy.partnershipCodeHash = policyParams.partnershipCodeHash;
        policy.expirationDate = coverageStartDate.addYears(1, TIME_ZONE_OFFSET);
        policy.coverageStartDate = coverageStartDate;
        policy.subscriptionDate = subscriptionDate;
        policy.riskType = policyParams.riskType;
        policy.policyType = policyParams.policyType;
        policy.termination = 1; // Termination.NotApplicable_NotApplicable
        policy.renewalType = policyParams.renewalType;
        policy.package = policyParams.package;
        policy.exposure = policyParams.exposure;
        policy.selectedOptions = policyParams.selectedOptions;
        for (uint256 index = 0; index < policyParams.selectedCoverages.length; index++) {
            policy.selectedCoverages.push(policyParams.selectedCoverages[index]);
        }

        policy.split = policyParams.split;
        policy.isOfLegalAge = policyParams.isOfLegalAge;
        policy.policyholderType = policyParams.policyholderType;

        policy.commonSensitiveData = policyParams.commonSensitiveData;
        policy.claimsAdminSensitiveData = policyParams.claimsAdminSensitiveData;
        policy.policiesAdminSensitiveData = policyParams.policiesAdminSensitiveData;
        policy.distributorSensitiveData = policyParams.distributorSensitiveData;
        policy.insurerSensitiveData = policyParams.insurerSensitiveData;

        policy.operationType = 1; // OperationType.Subscription
        policy.operationEffectiveDate = subscriptionDate;

        isPolicyExists[policyParams.onChainPolicyId] = true;
        totalPolicies += 1;
        emit NewPolicyCreated(
            policy.onChainPolicyId,
            policy.termination,
            policy.subscriptionDate,
            policy.coverageStartDate,
            policy.expirationDate
        );
    }

    function endorsePolicy(
        Product020802Lib.EndorsementParams memory endorsementParams,
        bool updateSelectedOptions,
        bool updateCoverages
    ) external onlyPartnerOrWakam(allPolicies[endorsementParams.onChainPolicyId].partnershipCodeHash) {
        require(isPolicyExists[endorsementParams.onChainPolicyId], "Unknown policy");

        Product020802Lib.checkEndorsePolicyBusinessRules(endorsementParams, allPolicies[endorsementParams.onChainPolicyId].operationType );

        if (endorsementParams.requestedCoverageStartDate != 0) {
            uint256 coverageStartDate = endorsementParams.requestedCoverageStartDate.computeCoverageStartDate(
                allPolicies[endorsementParams.onChainPolicyId].subscriptionDate,
                TIME_ZONE_OFFSET
            );
            allPolicies[endorsementParams.onChainPolicyId].coverageStartDate = coverageStartDate;
            allPolicies[endorsementParams.onChainPolicyId].expirationDate = coverageStartDate.addYears(
                1,
                TIME_ZONE_OFFSET
            );
        }

        if (bytes(endorsementParams.package).length != 0) {
            allPolicies[endorsementParams.onChainPolicyId].package = endorsementParams.package;
        }

        if (endorsementParams.exposure.vehicleType != 0) {
            allPolicies[endorsementParams.onChainPolicyId].exposure.vehicleType = endorsementParams.exposure.vehicleType;
        }
        if (bytes(endorsementParams.exposure.brand).length != 0) {
            allPolicies[endorsementParams.onChainPolicyId].exposure.brand = endorsementParams.exposure.brand;
        }
        if (bytes(endorsementParams.exposure.model).length != 0) {
            allPolicies[endorsementParams.onChainPolicyId].exposure.model = endorsementParams.exposure.model;
        }
        if (endorsementParams.exposure.purchaseDate != 0) {
            allPolicies[endorsementParams.onChainPolicyId].exposure.purchaseDate = endorsementParams
                .exposure
                .purchaseDate;
        }
        if (endorsementParams.exposure.purchasePrice != 0) {
            allPolicies[endorsementParams.onChainPolicyId].exposure.purchasePrice = endorsementParams
                .exposure
                .purchasePrice;
        }
        if (endorsementParams.exposure.usage != 0) {
            allPolicies[endorsementParams.onChainPolicyId].exposure.usage = endorsementParams.exposure.usage;
        }
        if (endorsementParams.exposure.householdSize != 0) {
            allPolicies[endorsementParams.onChainPolicyId].exposure.householdSize = endorsementParams
                .exposure
                .householdSize;
        }
        if (endorsementParams.exposure.maxSpeed != 0) {
            allPolicies[endorsementParams.onChainPolicyId].exposure.maxSpeed = endorsementParams.exposure.maxSpeed;
        }
        if (endorsementParams.split != 0) {
            allPolicies[endorsementParams.onChainPolicyId].split = endorsementParams.split;
        }
        if (bytes(endorsementParams.commonSensitiveData).length != 0) {
            allPolicies[endorsementParams.onChainPolicyId].commonSensitiveData = endorsementParams.commonSensitiveData;
        }
        if (bytes(endorsementParams.claimsAdminSensitiveData).length != 0) {
            allPolicies[endorsementParams.onChainPolicyId].claimsAdminSensitiveData = endorsementParams
                .claimsAdminSensitiveData;
        }
        if (bytes(endorsementParams.policiesAdminSensitiveData).length != 0) {
            allPolicies[endorsementParams.onChainPolicyId].policiesAdminSensitiveData = endorsementParams
                .policiesAdminSensitiveData;
        }
        if (bytes(endorsementParams.distributorSensitiveData).length != 0) {
            allPolicies[endorsementParams.onChainPolicyId].distributorSensitiveData = endorsementParams
                .distributorSensitiveData;
        }
        if (bytes(endorsementParams.insurerSensitiveData).length != 0) {
            allPolicies[endorsementParams.onChainPolicyId].insurerSensitiveData = endorsementParams.insurerSensitiveData;
        }
        if (updateSelectedOptions) {
            allPolicies[endorsementParams.onChainPolicyId].selectedOptions = endorsementParams.selectedOptions;
        }
        if (updateCoverages) {
            delete allPolicies[endorsementParams.onChainPolicyId].selectedCoverages;
            for (uint256 index = 0; index < endorsementParams.selectedCoverages.length; index++) {
                allPolicies[endorsementParams.onChainPolicyId].selectedCoverages.push(
                    endorsementParams.selectedCoverages[index]
                );
            }
        }

        allPolicies[endorsementParams.onChainPolicyId].operationType = endorsementParams.operationType;
        allPolicies[endorsementParams.onChainPolicyId].operationEffectiveDate = block.timestamp;
    }

    function cancelPolicy(
        string memory onChainPolicyId,
        uint256 termination,
        uint256 dateOfNotice,
        bool hasNoClaim
    ) external onlyPartnerOrWakam(allPolicies[onChainPolicyId].partnershipCodeHash) {
        require(isPolicyExists[onChainPolicyId], "policy does not exist");

        Product020802Lib.Policy storage policy = allPolicies[onChainPolicyId];
        require(
            getPolicyStatus(policy.operationType, policy.operationEffectiveDate) != 2, // Termination.Terminated
            "policy is not active"
        );

        int256 dateOfNoticeComparedToToday = dateOfNotice.dailyCompareTo(block.timestamp);
        require(
            dateOfNoticeComparedToToday == -1 || dateOfNoticeComparedToToday == 0,
            "date of notice cannot be in the past"
        );

        int256 dateOfNoticeComparedToSubscriptionDate = dateOfNotice.dailyCompareTo(policy.subscriptionDate);
        require(
            dateOfNoticeComparedToSubscriptionDate == 1 || dateOfNoticeComparedToSubscriptionDate == 0,
            "policy is not underwritten"
        );

        // Termination.WithdrawalDuringCoolingOffPeriod_NotApplicable
        if (termination == 2) {
            require(hasNoClaim, "impossible to withdraw with claims");

            int256 subscriptionDatePlus14DaysComparedToDateOfNotice = (policy.subscriptionDate + 14 days)
                .dailyCompareTo(dateOfNotice);
            require(
                subscriptionDatePlus14DaysComparedToDateOfNotice == 1 ||
                    subscriptionDatePlus14DaysComparedToDateOfNotice == 0,
                "impossible to withdraw after 14 days"
            );

            if (dateOfNoticeComparedToToday == 0) {
                policy.operationEffectiveDate = block.timestamp;
            } else {
                policy.operationEffectiveDate = dateOfNotice.setDateAt23h59m59s(TIME_ZONE_OFFSET);
            }
        }
        /*
            - Termination.WithdrawalByPolicyHolder_Death
            - Termination.WithdrawalByInsurer_Fraud
            - Termination.WithdrawalByInsurer_UnpaidPremium
        */
        else if (termination == 3 || termination == 11 || termination == 13) {
            policy.operationEffectiveDate = dateOfNotice.setDateAt23h59m59s(TIME_ZONE_OFFSET) + 10 days;
        }
        /*
            - Termination.WithdrawalByPolicyHolder_ChangesInRisk
            - Termination.WithdrawalByPolicyHolder_RequestedTerminationBecauseOfOtherContractCancellation
            - Termination.WithdrawalByInsurer_TooManyClaims
        */
        else if (termination == 4 || termination == 6 || termination == 15) {
            policy.operationEffectiveDate = dateOfNotice.setDateAt23h59m59s(TIME_ZONE_OFFSET) + 30 days;
        }
        // Termination.WithdrawalByPolicyHolder_NonRenewed
        else if (termination == 5) {
            policy.operationEffectiveDate = policy.expirationDate.setDateAt23h59m59s(TIME_ZONE_OFFSET);
        }
        // Termination.WithdrawalByPolicyHolder_CancellationAfterFirstYear
        else if (termination == 7) {
            require(policy.coverageStartDate + 365 days <= block.timestamp, "1 year of coverage required");
            policy.operationEffectiveDate = dateOfNotice.setDateAt23h59m59s(TIME_ZONE_OFFSET) + 30 days;
        }
        // Termination.WithdrawalByPolicyHolder_AutomaticTermination
        else if (termination == 8) {
            policy.operationEffectiveDate = dateOfNotice.setDateAt23h59m59s(TIME_ZONE_OFFSET);
        }
        // Termination.WithdrawalByPolicyHolder_InsurerLicenceWithdrawal
        else if (termination == 9) {
            policy.operationEffectiveDate = dateOfNotice.setDateAtMidday(TIME_ZONE_OFFSET) + 40 days;
        }
        // Termination.TechnicalCancellation_NotApplicable
        else if (termination == 17) {
            require(wakamAddresses[msg.sender], "admin rights required");
            policy.operationEffectiveDate = block.timestamp;
        } else {
            revert("termination invalid");
        }

        policy.operationType = 2; // OperationType.Cancellation
        policy.termination = termination;

        emit PolicyCancelled(
            policy.onChainPolicyId,
            policy.termination,
            policy.operationType,
            policy.operationEffectiveDate
        );
    }

    function getPolicyHolderData(
        string calldata onChainPolicyId
    ) external view returns (bool isOfLegalAge, uint256 policyholderType) {
        Product020802Lib.Policy memory policy = allPolicies[onChainPolicyId];

        return (policy.isOfLegalAge, policy.policyholderType);
    }

    function getPolicyData(
        string calldata onChainPolicyId_
    )
        external
        view
        returns (
            string memory onChainPolicyId,
            uint256 onChainStatus,
            uint256 termination,
            uint256 subscriptionDate,
            uint256 coverageStartDate,
            uint256 expirationDate,
            uint256 policyType,
            uint256 riskType,
            uint256 renewalType,
            uint256 split,
            uint256 operationType,
            uint256 operationEffectiveDate
        )
    {
        Product020802Lib.Policy memory policy = allPolicies[onChainPolicyId_];

        return (
            policy.onChainPolicyId,
            getPolicyStatus(policy.operationType, policy.operationEffectiveDate),
            policy.termination,
            policy.subscriptionDate,
            policy.coverageStartDate,
            policy.expirationDate,
            policy.policyType,
            policy.riskType,
            policy.renewalType,
            policy.split,
            policy.operationType,
            policy.operationEffectiveDate
        );
    }

    function getPolicyCoverages(
        string calldata onChainPolicyId
    )
        external
        view
        returns (
            string memory package,
            string[] memory selectedOptions,
            Product020802Lib.Coverage[] memory selectedCoverages
        )
    {
        Product020802Lib.Policy memory policy = allPolicies[onChainPolicyId];

        return (policy.package, policy.selectedOptions, policy.selectedCoverages);
    }

    function getPolicySensitiveData(
        string calldata onChainPolicyId
    )
        external
        view
        returns (
            string memory commonSensitiveData,
            string memory claimsAdminSensitiveData,
            string memory policiesAdminSensitiveData,
            string memory distributorSensitiveData,
            string memory insurerSensitiveData
        )
    {
        Product020802Lib.Policy memory policy = allPolicies[onChainPolicyId];

        return (
            policy.commonSensitiveData,
            policy.claimsAdminSensitiveData,
            policy.policiesAdminSensitiveData,
            policy.distributorSensitiveData,
            policy.insurerSensitiveData
        );
    }

    function getPolicyExposure(
        string calldata onChainPolicyId
    )
        external
        view
        returns (
            uint256 vehicleType,
            string memory brand,
            string memory model,
            uint256 purchaseDate,
            uint256 purchasePrice,
            string memory purchaseCurrency,
            uint256 usage,
            uint256 householdSize,
            uint256 maxSpeed
        )
    {
        Product020802Lib.Exposure memory exposure = allPolicies[onChainPolicyId].exposure;

        return (
            exposure.vehicleType,
            exposure.brand,
            exposure.model,
            exposure.purchaseDate,
            exposure.purchasePrice,
            exposure.purchaseCurrency,
            exposure.usage,
            exposure.householdSize,
            exposure.maxSpeed
        );
    }

    function getPolicyStatus(uint operationType, uint operationEffectiveDate) private view returns (uint) {
        if (operationType == 0) {
            return 0; // PolicyStatus.Active
        }
        if (operationEffectiveDate > block.timestamp) {
            return 1; // PolicyStatus.PendingTerminated
        }
        return 2; // PolicyStatus.Terminated
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library WkmDateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    int256 constant OFFSET19700101 = 2440588;

    function getDaysInMonth(uint256 year, uint256 month) public pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = isLeapYear(year) ? 29 : 28;
        }
    }

    function isLeapYear(uint256 year) public pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function addYears(
        uint256 timestamp,
        uint256 _years,
        int timeZoneOffset
    ) public pure returns (uint256 newTimestamp) {
        uint timestampWithoutOffset = resetTimezoneOffSet(timestamp, timeZoneOffset);
        (uint256 year, uint256 month, uint256 day) = daysToDate(timestampWithoutOffset / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        uint newTimestampWithoutOffset = daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestampWithoutOffset % SECONDS_PER_DAY);
        newTimestamp = setTimezoneOffSet(newTimestampWithoutOffset, timeZoneOffset);
        require(newTimestamp >= timestamp);
    }

    function daysToDate(uint256 _days) public pure returns (uint256 year, uint256 month, uint256 day) {
        int256 __days = int256(_days);
        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function daysFromDate(uint256 year, uint256 month, uint256 day) public pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    function dailyCompareTo(uint256 date1, uint256 date2) public pure returns (int256 comparisonResult) {
        uint256 date1AtMidnight = date1 - (date1 % 1 days);
        uint256 date2AtMidnight = date2 - (date2 % 1 days);

        if (date1AtMidnight > date2AtMidnight) {
            comparisonResult = 1;
        } else if (date1AtMidnight < date2AtMidnight) {
            comparisonResult = -1;
        } else {
            comparisonResult = 0;
        }
    }

    function setDateAtMidday(uint256 date, int timeZoneOffset) public pure returns (uint256 dateAtMidday) {
        dateAtMidday = setDateAtMidnight(date, timeZoneOffset) + 43200 seconds; // 43200 seconds = 12h00m00s
    }

    function setDateAtMidnight(uint256 date, int timeZoneOffset) public pure returns (uint256 dateAtMidnight) {
        uint256 dateWithResetedOffset = resetTimezoneOffSet(date, timeZoneOffset);
        uint256 totalSecondsInDay = dateWithResetedOffset % 1 days;
        dateAtMidnight = setTimezoneOffSet(dateWithResetedOffset, timeZoneOffset) - totalSecondsInDay;
    }

    function setDateAt23h59m59s(uint256 date, int timeZoneOffset) public pure returns (uint256 dateAt23h59m59s) {
        dateAt23h59m59s = setDateAtMidnight(date, timeZoneOffset) + 86399 seconds; // 86399 seconds = 23h59m59s
    }

    function setTimezoneOffSet(uint date, int timeZoneOffset) public pure returns (uint256 dateWithOffSet) {
        if (timeZoneOffset >= 0) {
            dateWithOffSet = date - uint(timeZoneOffset) * 3600 seconds;
        } else {
            dateWithOffSet = date + uint(-timeZoneOffset) * 3600 seconds;
        }
    }

    function resetTimezoneOffSet(uint date, int timeZoneOffset) public pure returns (uint256 dateWithoutOffSet) {
        if (timeZoneOffset >= 0) {
            dateWithoutOffSet = date + uint(timeZoneOffset) * 3600 seconds;
        } else {
            dateWithoutOffSet = date - uint(-timeZoneOffset) * 3600 seconds;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./WkmDateTime.sol";

library Product020802Lib {
    using WkmDateTime for uint256;

    struct Exposure {
        uint256 vehicleType;
        string brand;
        string model;
        uint256 purchaseDate;
        uint256 purchasePrice;
        string purchaseCurrency;
        uint256 usage;
        uint256 householdSize;
        uint256 maxSpeed;
    }

    struct Coverage {
        string code;
        string limit;
        string excess;
    }

    struct Policy {
        bytes32 partnershipCodeHash;
        string onChainPolicyId;
        uint256 expirationDate;
        uint256 coverageStartDate;
        uint256 subscriptionDate;
        uint256 riskType;
        uint256 policyType;
        uint256 termination;
        uint256 renewalType;
        string package;
        Exposure exposure;
        string[] selectedOptions;
        Coverage[] selectedCoverages;
        uint256 split;
        bool isOfLegalAge;
        uint256 policyholderType;
        string commonSensitiveData;
        string claimsAdminSensitiveData;
        string policiesAdminSensitiveData;
        string distributorSensitiveData;
        string insurerSensitiveData;
        uint256 operationType;
        uint256 operationEffectiveDate;
    }

    struct PolicyParams {
        string onChainPolicyId;
        bytes32 partnershipCodeHash;
        uint256 requestedCoverageStartDate;
        uint256 riskType;
        uint256 policyType;
        uint256 renewalType;
        string package;
        Product020802Lib.Exposure exposure;
        string[] selectedOptions;
        Product020802Lib.Coverage[] selectedCoverages;
        uint256 split;
        bool isOfLegalAge;
        uint256 policyholderType;
        string commonSensitiveData;
        string claimsAdminSensitiveData;
        string policiesAdminSensitiveData;
        string distributorSensitiveData;
        string insurerSensitiveData;
    }

    struct EndorsementParamsStruct {
        string key;
        string stringValue;
        uint256 uintValue;
    }

    function computeCoverageStartDate(
        uint256 requestedCoverageStartDate,
        uint256 subscriptionDate,
        int timeZoneOffset
    ) public pure returns (uint256) {
        int256 requestedCoverageStartDateComparedToSubscriptionDate = requestedCoverageStartDate.dailyCompareTo(
            subscriptionDate
        );
        require(
            requestedCoverageStartDateComparedToSubscriptionDate != -1,
            "requestedCoverageStartDate cannot be in the past"
        );

        if (requestedCoverageStartDateComparedToSubscriptionDate == 0) {
            return subscriptionDate;
        }

        return requestedCoverageStartDate.setDateAtMidnight(timeZoneOffset) + 1 minutes;
    }

    struct EndorsementExposureParams {
        uint256 vehicleType;
        string brand;
        string model;
        uint256 purchaseDate;
        uint256 purchasePrice;
        uint256 usage;
        uint256 householdSize;
        uint256 maxSpeed;
    }

     struct EndorsementParams {
        bytes32 partnershipCodeHash;
        string onChainPolicyId;
        uint256 requestedCoverageStartDate;
        string package;
        EndorsementExposureParams exposure;
        string[] selectedOptions;
        Coverage[] selectedCoverages;
        uint256 split;
        string commonSensitiveData;
        string claimsAdminSensitiveData;
        string policiesAdminSensitiveData;
        string distributorSensitiveData;
        string insurerSensitiveData;
        uint256 operationType;
        uint256 operationEffectiveDate;
    }


    function checkBusinessRulesToCreatePolicy(
        PolicyParams memory policyToBeChecked,
        uint256 subscriptionDate,
        uint256 coverageStartDate
    ) external pure {
        checkMaxSpeed(policyToBeChecked.exposure.maxSpeed);
        checkLegalAge(policyToBeChecked.isOfLegalAge);
        checkCoverageStartDate(coverageStartDate, subscriptionDate);
    }

    function checkEndorsePolicyBusinessRules(EndorsementParams memory endorsementParams, uint256 currentOperationType) external view {
        checkIfOngoingWithdrawal(currentOperationType);

        if (endorsementParams.exposure.maxSpeed != 0) {
            checkMaxSpeed(endorsementParams.exposure.maxSpeed);
        }
        if (endorsementParams.requestedCoverageStartDate !=0 ) {
            checkIfCoverageStartDateIsNotThePast(endorsementParams.requestedCoverageStartDate);
        }
    }

    function checkMaxSpeed(uint256 maxSpeed) private pure {
        uint256 authorizedMaxSpeed = 25;
        require(maxSpeed <= authorizedMaxSpeed, "Authorized maxSpeed is 25KM/H");
    }

    function checkCoverageStartDate(uint256 coverageStartDate, uint256 subscriptionDate) private pure {
        require(
            coverageStartDate <= subscriptionDate + 26 weeks, // 26 weeks = 6 months
            "coverageStartDate must be less than subscriptionDate + 6 months"
        );
    }

    function checkLegalAge(bool isOfLegalAge) private pure {
        require(isOfLegalAge, "policyholder is less than legal age");
    }

    function checkIfCoverageStartDateIsNotThePast(uint256 coverageStartDate) private view {
        bool coverageStartDateIsInThePast = coverageStartDate.dailyCompareTo(block.timestamp) == -1;

        require(coverageStartDateIsInThePast, "coverageStartDate cannot be in the past");
    }

    function checkIfOngoingWithdrawal(uint256 operationType) private pure {
        require(operationType != 2, "No action with ongoing withdrawal");
    }
}



// ["0x64499a2015da168f281a5976dfcaa97db11e5f482e4076d1cf6b76eebfcee553","1111",1688563210,"ABCD",[1,"Xiaomi2","PR266O2",2235465,40000,"€ cents",1,5,22],["FV_2"],[["ABC","CCC","BBB"]],2,"chiffre144444444ZHGDF","cdcQKLJLKDQJVLKDJhiffre2","chiLKSDVQJLKDJKLSQJVLKQJLKDVJLffre3","cDLKJVSLKJVDLKJDVLKJDlkvlkjvdslhiffre4","vldksjlvdskjvlkdsjlvkjdlkschiffre5",2,1688563210]

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract OwnableV01 is Initializable {
    mapping(address => bool) internal wakamAddresses;
    mapping(bytes32 => mapping(address => bool)) private _partnerAddressesByPartnershipCodeHash;

    modifier onlyWakam() {
        require(wakamAddresses[msg.sender], "OwnableV01: caller is not Admin");
        _;
    }

    modifier onlyPartnerOrWakam(bytes32 partnershipCodeHash) {
        require(
            _partnerAddressesByPartnershipCodeHash[partnershipCodeHash][msg.sender] || wakamAddresses[msg.sender],
            "OwnableV01: caller is not Admin or Business Partner"
        );
        _;
    }

    function initialize() external initializer {
        wakamAddresses[msg.sender] = true;
    }

    function addWakamAddress(address newWakamAddress) external onlyWakam {
        wakamAddresses[newWakamAddress] = true;
    }

    function removeWakamAddress(address wakamAddressToRemove) external onlyWakam {
        wakamAddresses[wakamAddressToRemove] = false;
    }

    function addPartnerAddress(address newPartnerAddress, bytes32 partnershipCodeHash) external onlyWakam {
        _partnerAddressesByPartnershipCodeHash[partnershipCodeHash][newPartnerAddress] = true;
    }

    function removePartnerAddress(address partnerAddressToRemove, bytes32 partnershipCodeHash) external onlyWakam {
        _partnerAddressesByPartnershipCodeHash[partnershipCodeHash][partnerAddressToRemove] = false;
    }

    function isWakamAddress(address wakamAddressToCheck) external view returns (bool) {
        return wakamAddresses[wakamAddressToCheck];
    }

    function isPartnerAddress(address wakamAddressToCheck, bytes32 partnershipCodeHash) external view returns (bool) {
        return _partnerAddressesByPartnershipCodeHash[partnershipCodeHash][wakamAddressToCheck];
    }
}