// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./libs/WkmDateTime.sol";
import "./authentication/Ownable.sol";

contract Product020802 is Ownable {
    using WkmDateTime for uint256;
    bytes public constant PRODUCT_ID = "0208_02";

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
        bytes32 partnershipId;
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
        bytes32 partnershipId;
        uint256 requestedCoverageStartDate;
        uint256 riskType;
        uint256 policyType;
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
    }

    uint256 public totalPolicies = 0;
    mapping(string => Policy) private allPolicies;
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

    function createPolicy(PolicyParams memory policyParams) external onlyPartnerOrWakam(policyParams.partnershipId) {
        uint256 subscriptionDate = block.timestamp;
        require(!isPolicyExists[policyParams.onChainPolicyId], "policy already in storage");
        uint256 coverageStartDate = computeCoverageStartDate(policyParams.requestedCoverageStartDate, subscriptionDate);

        checkBusinessRulesToCreatePolicy(policyParams, subscriptionDate, coverageStartDate);

        Policy storage policy = allPolicies[policyParams.onChainPolicyId];
        policy.onChainPolicyId = policyParams.onChainPolicyId;
        policy.partnershipId = policyParams.partnershipId;
        policy.expirationDate = coverageStartDate.addYears(1);
        policy.coverageStartDate = coverageStartDate;
        policy.subscriptionDate = subscriptionDate;
        policy.riskType = policyParams.riskType;
        policy.policyType = policyParams.policyType;
        // 1 = Not applicable
        policy.termination = 1;
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

        policy.operationType = 1; // Subscription
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

    function cancelPolicy(
        string memory onChainPolicyId,
        uint256 termination,
        uint256 notificationDate,
        bool ongoingClaim
    ) external onlyPartnerOrWakam(allPolicies[onChainPolicyId].partnershipId) {
        require(isPolicyExists[onChainPolicyId], "policy does not exist");
        require(!ongoingClaim, "impossible to withdraw with an ongoing claim");

        require(termination == 2, "termination invalid"); // WithdrawalDuringCoolingOffPeriod
        Policy storage policy = allPolicies[onChainPolicyId];
        require(getPolicyStatus(policy.operationType, policy.operationEffectiveDate) != 3, "policy already terminated");
        uint256 subscriptionDate = policy.subscriptionDate;

        int256 subscriptionDatePlus14DaysComparedToNotificationDate = (subscriptionDate + 14 days).dailyCompareTo(
            notificationDate
        );
        require(
            subscriptionDatePlus14DaysComparedToNotificationDate == 1 ||
                subscriptionDatePlus14DaysComparedToNotificationDate == 0,
            "impossible to withdraw after 14 days"
        );
        int256 notificationDateComparedToSubscriptionDate = notificationDate.dailyCompareTo(subscriptionDate);
        require(
            notificationDateComparedToSubscriptionDate == 1 || notificationDateComparedToSubscriptionDate == 0,
            "impossible to withdraw before subscribing"
        );

        policy.operationType = 2; // Cancellation
        policy.termination = termination;
        policy.operationEffectiveDate = notificationDate.setDateAt23h59m59s();

        emit PolicyCancelled(
            policy.onChainPolicyId,
            policy.termination,
            policy.operationType,
            policy.operationEffectiveDate
        );
    }

    function computeCoverageStartDate(
        uint256 requestedCoverageStartDate,
        uint256 subscriptionDate
    ) private pure returns (uint256) {
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

        return requestedCoverageStartDate.setDateAtMidnight() + 1 minutes;
    }

    function getPolicyHolderData(
        string calldata onChainPolicyId
    ) external view returns (bool isOfLegalAge, uint256 policyholderType) {
        Policy memory policy = allPolicies[onChainPolicyId];

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
        Policy memory policy = allPolicies[onChainPolicyId_];

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
        returns (string memory package, string[] memory selectedOptions, Coverage[] memory selectedCoverages)
    {
        Policy memory policy = allPolicies[onChainPolicyId];

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
        Policy memory policy = allPolicies[onChainPolicyId];

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
        Exposure memory exposure = allPolicies[onChainPolicyId].exposure;

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
        if (operationType == 1) {
            return 1; // PolicyStatus.Active
        }
        if (operationEffectiveDate > block.timestamp) {
            return 2; // PolicyStatus.PendingTerminated
        }
        return 3; // PolicyStatus.Terminated
    }

    function checkBusinessRulesToCreatePolicy(
        PolicyParams memory policyToBeChecked,
        uint256 subscriptionDate,
        uint256 coverageStartDate
    ) private pure {
        uint256 maxSpeedAuthorized = 25;
        require(policyToBeChecked.exposure.maxSpeed <= maxSpeedAuthorized, "maxSpeed authorized is 25KM/H");
        require(policyToBeChecked.isOfLegalAge, "policyholder is less than legal age");
        require(
            coverageStartDate <= (subscriptionDate + 26 weeks), // 26 weeks = 6 months
            "coverageStartDate must be less than subscriptionDate + 6 months"
        );
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

    function addYears(uint256 timestamp, uint256 _years) public pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
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
        uint256 date1AtMidnight = setDateAtMidnight(date1);
        uint256 date2AtMidnight = setDateAtMidnight(date2);

        if (date1AtMidnight > date2AtMidnight) {
            comparisonResult = 1;
        } else if (date1AtMidnight < date2AtMidnight) {
            comparisonResult = -1;
        } else {
            comparisonResult = 0;
        }
    }

    function setDateAtMidnight(uint256 date) public pure returns (uint256 dateAtMidnight) {
        uint256 totalSecondsInDay = date % 1 days;
        dateAtMidnight = date - totalSecondsInDay;
    }

    function setDateAt23h59m59s(uint256 date) public pure returns (uint256 dateAt23h59m59s) {
        dateAt23h59m59s = setDateAtMidnight(date) + 86399 seconds; // 86399 seconds = 23h59m59s
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract Ownable {
    mapping(address => bool) private _wakamAddresses;
    mapping(bytes32 => mapping(address => bool)) private _partnerAddressesByPartnershipId;

    constructor() {
        _wakamAddresses[msg.sender] = true;
    }

    modifier onlyWakam() {
        require(_wakamAddresses[msg.sender], "Ownable: caller is not Wakam");
        _;
    }

    modifier onlyPartnerOrWakam(bytes32 partnershipId) {
        require(
            _partnerAddressesByPartnershipId[partnershipId][msg.sender] || _wakamAddresses[msg.sender],
            "Ownable: caller is not Wakam or Bpartner"
        );
        _;
    }

    function addWakamAddress(address newWakamAddress) external onlyWakam {
        _wakamAddresses[newWakamAddress] = true;
    }

    function removeWakamAddress(address wakamAddressToRemove) external onlyWakam {
        _wakamAddresses[wakamAddressToRemove] = false;
    }

    function addPartnerAddress(address newPartnerAddress, bytes32 partnershipId) external onlyWakam {
        _partnerAddressesByPartnershipId[partnershipId][newPartnerAddress] = true;
    }

    function removePartnerAddress(address partnerAddressToRemove, bytes32 partnershipId) external onlyWakam {
        _partnerAddressesByPartnershipId[partnershipId][partnerAddressToRemove] = false;
    }

    function isWakamAddress(address wakamAddressToCheck) external view returns (bool) {
        return _wakamAddresses[wakamAddressToCheck];
    }

    function isPartnerAddress(address wakamAddressToCheck, bytes32 partnershipId) external view returns (bool) {
        return _partnerAddressesByPartnershipId[partnershipId][wakamAddressToCheck];
    }
}