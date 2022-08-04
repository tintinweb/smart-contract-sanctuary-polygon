/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// File: contracts/Library.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library Library {
    struct Policy {
        string quoteId;
        uint policyId;
        uint partnerId;
        uint startPolicy;
        uint endPolicy;
        uint startCoverage;
        uint endCoverage;
        bool isActive;
        uint productId;
        string sensitiveData;
    }
}

// File: contracts/products/IProduct.sol


interface IProduct {
    function withdrawPolicyProduct(Library.Policy memory policy, uint endDate, string memory sensitiveData) external returns (Library.Policy memory withdrawedPolicy);
}

// File: contracts/Main.sol

pragma solidity 0.8.0;


contract Main {
    enum Lifecycle {
        Create,
        Cancel,
        Withdraw,
        Suspend,
        Resume,
        Extend,
        Endorse
    }

    struct Product {
        uint productId;
        mapping(Lifecycle => bool) possibleActs;
        address productAddress;
    }

    struct Partner {
        uint partnerId;
        mapping(address => bool) addresses;
    }

    IProduct public ProductContract;

    uint public totalPolicies;
    mapping(address => bool) public wakamAddresses;
    mapping(uint => Library.Policy) public policies;
    mapping(uint => Partner) public partners;
    mapping(uint => Product) public products;

    constructor(uint[] memory partnerIds, address[][] memory partnerAddresses, address[] memory _wakamAddresses) {
        require(partnerIds.length == partnerAddresses.length, "partner IDs and partner addresses must have the same length");

        for (uint256 i = 0; i < partnerIds.length; i++) {
            uint currentPartnerId = partnerIds[i];
            require(currentPartnerId > 0, "partnerId must be > 0");
            partners[currentPartnerId].partnerId = currentPartnerId;

            address[] memory currentPartnerAddresses = partnerAddresses[i];
            for (uint256 j = 0; j < currentPartnerAddresses.length; j++) {
                partners[currentPartnerId].addresses[currentPartnerAddresses[j]] = true;
            }
        }

        for (uint256 i = 0; i < _wakamAddresses.length; i++) {
            wakamAddresses[_wakamAddresses[i]] = true;
        }
    }

    function createPolicy(Library.Policy memory policy) external {
        require(policy.policyId > 0, "policyId must be > 0");
        require(policies[policy.policyId].policyId == 0, "policy already in smart contract");
        require(partners[policy.partnerId].partnerId > 0, "unknown partner");
        require(policy.startPolicy <= policy.startCoverage && policy.endPolicy > policy.startCoverage, "verification in createPolicy function failed");

        policies[policy.policyId] = policy;
        totalPolicies += 1;
    }

    function withdrawPolicy(uint policyId, uint endDate) external {
        Library.Policy storage policy = policies[policyId];
        require(policy.policyId > 0, "policy does not exist in smart contract");

        Product storage product = products[policy.productId];
        require(product.possibleActs[Lifecycle.Withdraw], "invalid management act");

        bool callerIsWakamee = wakamAddresses[msg.sender];
        bool callerIsPolicyHolder = partners[policy.partnerId].addresses[msg.sender];
        require(callerIsWakamee || callerIsPolicyHolder, "not allowed to perform management act on this policy");

        ProductContract = IProduct(product.productAddress);
        policies[policyId] = ProductContract.withdrawPolicyProduct(policy, endDate, "");
    }

    function addProduct(uint productId, address productAddress, Lifecycle[] memory possibleActs) external {
        require(wakamAddresses[msg.sender], "caller not a wakamee");

        Product storage product = products[productId];
        product.productId = productId;
        for (uint256 i = 0; i < possibleActs.length; i++) {
            product.possibleActs[possibleActs[i]] = true;
        }
        product.productAddress = productAddress;
    }

    function addWakamee(address wakameeAddress) public {
        require(wakamAddresses[msg.sender], "caller not a wakamee");

        wakamAddresses[wakameeAddress] = true;
    }

    function getProduct(uint _productId) external view returns (uint productId, address productAddress, Lifecycle[] memory possibleActs) {
        Product storage product = products[_productId];

        uint numberOfPossibleActs = 0;
        for (uint256 i = uint(Lifecycle.Create); i < uint(Lifecycle.Endorse); i++) {
            if (product.possibleActs[Lifecycle(i)]) {
                numberOfPossibleActs++;
            }
        }
        possibleActs = new Lifecycle[](numberOfPossibleActs);

        uint j = 0;
        for (uint256 i = uint(Lifecycle.Create); i < uint(Lifecycle.Endorse); i++) {
            if (product.possibleActs[Lifecycle(i)]) {
                possibleActs[j] = Lifecycle(i);
                j++;
            }
        }

        return (product.productId, product.productAddress, possibleActs);
    }

    function doesPartnerAddressExist(uint partnerId, address partnerAddress) external view returns (bool) {
        return partners[partnerId].addresses[partnerAddress];
    }
}