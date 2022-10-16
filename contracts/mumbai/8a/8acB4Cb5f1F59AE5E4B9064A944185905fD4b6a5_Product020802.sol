/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
contract Product020802 {
    bytes public constant PRODUCT_ID = "0208_02";

    struct Policy {
        string id;
        uint256 startCoverage;
    }
    uint256 public totalPolicies = 0;
    mapping(string => Policy) public allPolicies;
    mapping(string => bool) public isPolicyExists;

    event NewPolicyCreated(string policyId);

    function createPolicy(Policy memory policy) external {
        require(!isPolicyExists[policy.id], "policy already in storage");

        allPolicies[policy.id] = policy;
        isPolicyExists[policy.id] = true;
        totalPolicies += 1;
        emit NewPolicyCreated(policy.id);
    }
}