/**
 *Submitted for verification at polygonscan.com on 2022-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Product020802 {
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
        uint256 expirationDate;
        uint256 coverageStartDate;
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
        checkBusinessRulesToCreatePolicy(policyParams, subscriptionDate);

        Policy storage policy = allPolicies[policyParams.onChainPolicyID];
        policy.onChainPolicyID = policyParams.onChainPolicyID;
        policy.expirationDate = policyParams.expirationDate;
        policy.coverageStartDate = policyParams.coverageStartDate;
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

    function checkBusinessRulesToCreatePolicy(PolicyParams memory policyToBeChecked, uint256 subscriptionDate)
        private
        pure
    {
        uint256 maxSpeedAuthorized = 25;
        require(policyToBeChecked.exposure.maxSpeed <= maxSpeedAuthorized, "maxSpeed authorized is 25KM/H");
        require(policyToBeChecked.isOfLegalAge, "policyholder is less than legal age");
        require(
            subscriptionDate <= (policyToBeChecked.coverageStartDate + 1 hours), // One hour delay is allowed
            "subscriptionDate must be less than coverageStartDate"
        );
        require(
            policyToBeChecked.coverageStartDate <= (subscriptionDate + 26 weeks), // 26 weeks = 6 months
            "coverageStartDate must be less than subscriptionDate + 6 months"
        );
        require(
            policyToBeChecked.coverageStartDate < policyToBeChecked.expirationDate,
            "coverageStartDate must be less than expirationDate"
        );
    }
}