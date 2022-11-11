/**
 *Submitted for verification at polygonscan.com on 2022-11-10
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
    }

    struct PolicyParams {
        string onChainPolicyID;
        uint256 expirationDate;
        uint256 coverageStartDate;
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
    }

    uint256 public totalPolicies = 0;
    mapping(string => Policy) private allPolicies;
    mapping(string => bool) public isPolicyExists;

    event NewPolicyCreated(string policyId);

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
        policy.onChainStatus = policyParams.onChainStatus;
        policy.terminationReason = policyParams.terminationReason;
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

        isPolicyExists[policyParams.onChainPolicyID] = true;
        totalPolicies += 1;
        emit NewPolicyCreated(policyParams.onChainPolicyID);
    }

    function getPolicyDataPart1(string calldata policyId)
        external
        view
        returns (
            string memory onChainPolicyID,
            uint256 expirationDate,
            uint256 coverageStartDate,
            uint256 subscriptionDate,
            uint256 riskType,
            uint256 policyType
        )
    {
        Policy memory policy = allPolicies[policyId];

        return (
            policy.onChainPolicyID,
            policy.expirationDate,
            policy.coverageStartDate,
            policy.subscriptionDate,
            policy.riskType,
            policy.policyType
        );
    }

    function getPolicyDataPart2(string calldata policyId)
        external
        view
        returns (
            uint256 onChainStatus,
            uint256 terminationReason,
            uint256 renewalType,
            string memory package,
            string[] memory selectedOptions,
            uint256 split,
            bool isOfLegalAge,
            uint256 policyholderType
        )
    {
        Policy memory policy = allPolicies[policyId];

        return (
            policy.onChainStatus,
            policy.terminationReason,
            policy.renewalType,
            policy.package,
            policy.selectedOptions,
            policy.split,
            policy.isOfLegalAge,
            policy.policyholderType
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

    function getPolicyCoverages(string calldata policyId) external view returns (Coverage[] memory selectedCoverages) {
        return (allPolicies[policyId].selectedCoverages);
    }
}