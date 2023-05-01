// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Medclaim {
    address public owner;
    uint256 silverPlanCost = 0.1 ether;
    uint256 goldPlanCost = 0.2 ether;
    uint256 platinumPlanCost = 0.3 ether;
    uint256 tolerance = 500 wei;
    
    struct Policy {
        address customerAddress;
        uint256 planCost;
        bool isClaimed;
        string reportUrl;
        string hospitalName;
        uint256 totalAmount;
        address customerPolicyAddress;
        bool isApproved;
    }

    mapping(address => Policy) policies;

    modifier isOperator() {
        require((msg.sender == owner), "Caller is not the owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }
    
    function buyPlan(uint256 plan) public payable returns (address) {
        require(
            policies[msg.sender].customerAddress == address(0),
            "You already have a policy"
        );
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        address customerPolicyAddress = address(uint160(uint256(hash)));

        if (plan == 1) {
            require(msg.value >= silverPlanCost - tolerance && msg.value <= silverPlanCost + tolerance, "Incorrect amount sent for silver plan");
            policies[customerPolicyAddress] = Policy({
                customerAddress: msg.sender,
                planCost: silverPlanCost,
                isClaimed: false,
                reportUrl: "",
                hospitalName: "",
                totalAmount: 0,
                customerPolicyAddress: customerPolicyAddress,
                isApproved: false
            });
        } else if (plan == 2) {
            require(msg.value >= goldPlanCost - tolerance && msg.value <= goldPlanCost + tolerance, "Incorrect amount sent for gold plan");
            policies[customerPolicyAddress] = Policy({
                customerAddress: msg.sender,
                planCost: goldPlanCost,
                isClaimed: false,
                reportUrl: "",
                hospitalName: "",
                totalAmount: 0,
                customerPolicyAddress: customerPolicyAddress,
                isApproved: false
            });
        } else if (plan == 3) {
            require(msg.value >= platinumPlanCost - tolerance && msg.value <= platinumPlanCost + tolerance, "Incorrect amount sent for platinum plan");
            policies[customerPolicyAddress] = Policy({
                customerAddress: msg.sender,
                planCost: platinumPlanCost,
                isClaimed: false,
                reportUrl: "",
                hospitalName: "",
                totalAmount: 0,
                customerPolicyAddress: customerPolicyAddress,
                isApproved: false
            });
        } else {
            revert("Invalid plan");
        }
        payable(owner).transfer(msg.value);
        return customerPolicyAddress;
    }
    

    function claimInsurance(
        address _policyAddress,
        string memory _reportUrl,
        string memory _hospitalName,
        uint256 _totalAmount
    ) public {
        Policy storage policy = policies[_policyAddress];
        require(
            policy.customerAddress == msg.sender,
            "You do not have a policy"
        );
        require(!policy.isClaimed, "This policy has already been claimed");
        require(
            policy.isApproved,
            "This claim has not been approved by the operator"
        );
        policy.reportUrl = _reportUrl;
        policy.hospitalName = _hospitalName;
        policy.totalAmount = _totalAmount;
        policy.isClaimed = true;
        payable(msg.sender).transfer(policy.planCost);
    }

    function approve(address _policyAddress) public isOperator {
        Policy storage policy = policies[_policyAddress];
        require(policy.customerAddress != address(0), "Policy does not exist");
        require(!policy.isClaimed, "This policy has already been claimed");
        require(
            !policy.isApproved,
            "This claim has already been approved by the operator"
        );
        policy.isApproved = true;
    }

    function displayPolicyAddress() public view returns (address) {
        Policy storage policy = policies[msg.sender];
        require(policy.customerAddress != address(0), "You do not have a policy");
        return policy.customerPolicyAddress;
    }      
}