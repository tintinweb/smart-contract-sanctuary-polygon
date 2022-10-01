// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract EntityPolicyBank {

    event EntityRegistration (
        address entity
    );
    /**
        Policy ID: Hash(address,userId)
     */
    struct Policy {
        address owner;
        //TODO Support Payment Splits
        address payable routeTo;
        //Is Active 
        bool isActive;
    }
    //PlatformIds
    mapping (bytes32 => bool) private registeredPlatformIds;
    mapping (address => bool) private approveChanges;
    mapping (address => bool) private approvedViewers;
    //Address -> PolicyId
    mapping (address => bytes32) private certificates;
    //Policy Id -> Policy
    mapping(bytes32 => Policy) private policyMapping;
    int256 private policyCounter = 0;
    //Public view of terms users agree to by using Entity Policy Bank
    //string public terms;

    constructor() {

    }

    modifier canView() {
        require(approvedViewers[msg.sender], "Only registered users can access this information");
        _;
    }

    modifier isPolicyOwner(bytes32 policyId) {
        require(policyMapping[policyId].owner == msg.sender, "Only the policy owner can perform this action");
        _;
    }

    function walletHasPolicy() public view returns(bool) {
        return policyMapping[certificates[msg.sender]].isActive && policyMapping[certificates[msg.sender]].owner == msg.sender;
    }

    function removePolicy(bytes32 policyId) public isPolicyOwner(policyId) {        
        policyMapping[policyId] = Policy(
            address(0),
            payable(address(this)),
            false
        );

        policyMapping[certificates[msg.sender]].isActive = false;
        certificates[msg.sender] = bytes32("");
    }

    function getPolicy(bytes32 policyId) public canView view returns(address, bool) {
        return (policyMapping[policyId].routeTo, policyMapping[policyId].isActive);
    }

    function policyExists() public view returns(bool) {
        return policyMapping[certificates[msg.sender]].isActive && certificates[msg.sender] != "";
    }

    function updatePolicyPaymentWallet(bytes32 policyId, address payable paymentWallet) public isPolicyOwner(policyId) {
        policyMapping[policyId].routeTo = payable(paymentWallet);
    }

    function certifyPolicy(bytes32 platformId, address payable paymentWallet) public {
        //
        if (walletHasPolicy() || registeredPlatformIds[platformId]) {
            //Already Registered
            revert();
        }
        approvedViewers[msg.sender] = true;
        certificates[msg.sender] = platformId;
        //TODO: Fix Id Generation.
        policyMapping[platformId] = Policy(
            msg.sender,
            payable(paymentWallet),
            true
        );

        registeredPlatformIds[platformId] = true;
        policyCounter++;

        emit EntityRegistration(
            msg.sender
        );
    }
}