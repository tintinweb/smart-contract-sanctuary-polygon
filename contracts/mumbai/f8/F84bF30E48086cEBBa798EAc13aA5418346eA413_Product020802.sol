/**
 *Submitted for verification at polygonscan.com on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library WkmDateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    int256 constant OFFSET19700101 = 2440588;

    function getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = isLeapYear(year) ? 29 : 28;
        }
    }

    function isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
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

    function daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
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
}

contract Product020802 {
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
        string coverageCode;
        string limit;
        string excess;
    }

    struct Policy {
        string onChainPolicyID;
        uint256 expirationDate;
        uint256 coverageStartDate;
        uint256 subscriptionDate;
        uint256 riskType;
        uint256 policyType;
        uint256 onChainStatus;
        uint256 terminationReason;
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

    struct PolicyParams {
        string onChainPolicyID;
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
        uint256 onChainStatus,
        uint256 terminationReason,
        uint256 subscriptionDate
    );

    function createPolicy(PolicyParams memory policyParams) external {
        uint256 subscriptionDate = block.timestamp;
        require(!isPolicyExists[policyParams.onChainPolicyID], "policy already in storage");
        require(
            policyParams.requestedCoverageStartDate >= subscriptionDate,
            "requestedCoverageStartDate cannot be in the past"
        );
        uint256 coverageStartDate = computeCoverageStartDate(policyParams.requestedCoverageStartDate, subscriptionDate);

        checkBusinessRulesToCreatePolicy(policyParams, subscriptionDate, coverageStartDate);

        Policy storage policy = allPolicies[policyParams.onChainPolicyID];
        policy.onChainPolicyID = policyParams.onChainPolicyID;
        policy.expirationDate = computeExpirationDate(coverageStartDate);
        policy.coverageStartDate = coverageStartDate;
        policy.subscriptionDate = subscriptionDate;
        policy.riskType = policyParams.riskType;
        policy.policyType = policyParams.policyType;
        // 1 = Active
        policy.onChainStatus = 1;
        // 1 = Not applicable
        policy.terminationReason = 1;
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

        isPolicyExists[policyParams.onChainPolicyID] = true;
        totalPolicies += 1;
        emit NewPolicyCreated(
            policy.onChainPolicyID,
            policy.onChainStatus,
            policy.terminationReason,
            policy.subscriptionDate
        );
    }

    function computeCoverageStartDate(uint256 requestedCoverageStartDate, uint256 subscriptionDate)
        private
        pure
        returns (uint256)
    {
        if (requestedCoverageStartDate - subscriptionDate < 1 days) {
            return subscriptionDate;
        }

        uint256 secondsInRequestedCoverageStartDate = requestedCoverageStartDate % 1 days;
        uint256 requestedCoverageStartDateAtMidnight = requestedCoverageStartDate - secondsInRequestedCoverageStartDate;
        return requestedCoverageStartDateAtMidnight + 1 minutes;
    }

    function computeExpirationDate(uint256 coverageStartDate) private pure returns (uint256) {
        uint256 expirationDate = coverageStartDate.addYears(1);
        return expirationDate;
    }

    function getPolicyHolderData(string calldata policyId)
        external
        view
        returns (bool isOfLegalAge, uint256 policyholderType)
    {
        Policy memory policy = allPolicies[policyId];

        return (policy.isOfLegalAge, policy.policyholderType);
    }

    function getPolicyData(string calldata policyId)
        external
        view
        returns (
            string memory onChainPolicyID,
            uint256 onChainStatus,
            uint256 terminationReason,
            uint256 subscriptionDate,
            uint256 coverageStartDate,
            uint256 expirationDate,
            uint256 policyType,
            uint256 riskType,
            uint256 renewalType,
            uint256 split
        )
    {
        Policy memory policy = allPolicies[policyId];

        return (
            policyId,
            policy.onChainStatus,
            policy.terminationReason,
            policy.subscriptionDate,
            policy.coverageStartDate,
            policy.expirationDate,
            policy.policyType,
            policy.riskType,
            policy.renewalType,
            policy.split
        );
    }

    function getPolicyCoverages(string calldata policyId)
        external
        view
        returns (
            string memory package,
            string[] memory selectedOptions,
            Coverage[] memory selectedCoverages
        )
    {
        Policy memory policy = allPolicies[policyId];

        return (policy.package, policy.selectedOptions, policy.selectedCoverages);
    }

    function getPolicySensitiveData(string calldata policyId)
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
        Policy memory policy = allPolicies[policyId];

        return (
            policy.commonSensitiveData,
            policy.claimsAdminSensitiveData,
            policy.policiesAdminSensitiveData,
            policy.distributorSensitiveData,
            policy.insurerSensitiveData
        );
    }

    function getPolicyExposure(string calldata policyId)
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
        Exposure memory exposure = allPolicies[policyId].exposure;

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