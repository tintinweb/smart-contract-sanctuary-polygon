pragma solidity ^0.8.0; //SPDX-License-Identifier: UNLICENSED

/**
 *    Here owner refers to `Owner` refers to owner of the contract.
 *    & `Partner` refers to new member of multi sig wallet.
 */
contract accessRegistry {
    address payable public seller;
    bool isPausedForAll; // 1 bytes

    struct partnerInfo {
        bool isPartner;
        bool hasVoted;
    }

    mapping(address => partnerInfo) isPartner;
    address[] partners;

    // event for announcing new contract owner
    event ContractOwnerChange(address indexed currentOwner,address indexed newOwner);

    // event for announcing new partner
    event newPartner(address indexed newPartner);

     /**
     * @dev assigning _seller address to owner
     */
    constructor (address payable _seller) {
        seller = _seller; 
        isPartner[_seller].isPartner = true; 
        partners.push(_seller);
    }

     // to check address is owner or not
    modifier onlyContractOwner() {
        require(msg.sender == seller,"only owner can access this function !");
        _;
    }

    // to check address is partner or not
    modifier onlyPartners() {
        require(isPartner[msg.sender].isPartner,"caller is not an partner !!");
        _;
    }

    // to check that owner has paused or not
    modifier hasNotPaused() {
        require(!isPausedForAll,"owner has paused the access");
        _;
    }

    /**
     * @dev to get the current owner
     */
    function getContractOwner() public view returns(address){
        return seller;
    }

    /**
     * @dev to check address is partner or not
     * @param user to check
     */
    function isPartnerOrNot(address user) public view returns(bool){
        require(user != address(0),"invalid address");
        return isPartner[user].isPartner;
    }

    /**
     *@dev to assign new owner
     * @param newOwner address of new owner
     */
    function setContractOwner(address payable newOwner) external onlyContractOwner {
        require(newOwner != address(0),"invalid address");
        emit ContractOwnerChange(msg.sender, newOwner);
        seller = newOwner;
    }

    /**
     * @dev to pause access of partners
     */
    function pauseAllPartners() external onlyContractOwner {
        isPausedForAll = true;
    }

    /**
     * @dev to unpause access of partners
     */
    function unpauseAllPartners() external onlyContractOwner {
        isPausedForAll = false;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './test-accessRegistry.sol';

contract Escrow is accessRegistry {
    enum EscrowState { Created, onRelease, Released, Disputed }

    address payable public buyer;
    address public arbitrator;
    uint public value;
    EscrowState public state;
    uint8 immutable fundReleaseThreshold;
    uint voteCount;

    constructor(address payable _buyer, address payable _seller, uint8 _fundReleaseThreshold,  address _arbitrator, address[] memory _subPartners) accessRegistry(_seller) payable {
        
        require(msg.value > 0,'invalid value provided');
        require(_fundReleaseThreshold > 0 && _fundReleaseThreshold <= 100,"invalid threshold value");
        
        buyer = _buyer;
        arbitrator = _arbitrator;
        fundReleaseThreshold = _fundReleaseThreshold;
        value = msg.value;
        state = EscrowState.Created;

            for(uint i = 0; i < _subPartners.length; i++){
                address newPartner = _subPartners[i];
                
                require(newPartner != address(0),"invalid address");
                require(isPartner[newPartner].isPartner == false,"not an  unique partner");
                
                isPartner[newPartner].isPartner = true;
            }
       
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can call this function.");
        _;
    }

    modifier inState(EscrowState _state) {
        require(state == _state, "Invalid escrow state.");
        _;
    }

    event PaymentReleased(address recipient, uint amount);
    event PaymentRefunded(address recipient, uint amount);
    event Dispute(address recipient);
    event InitiateRelease(address recipient);
    event DisputeResolved(bool resolved);
    event Deposit (address indexed sender, uint amount, uint Contractbalance);
    event ApprovedRelease(address indexed recipient);
    event DisapprovedRelease(address indexed recipient);

    /**
     * To receive eth directly into contract
     */
    receive() external payable { 
        value += msg.value;
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /**
     * @dev to approve the address to be the one of the owners
     * @param partnerAddress address of approving to be the part
     */
    function addNewPartner(address partnerAddress) external onlyContractOwner inState(EscrowState.Created) {
        require(partnerAddress != address(0),"invalid address");
        require(!isPartnerOrNot(partnerAddress), "is already an partner");
        emit newPartner(partnerAddress);
        partners.push(partnerAddress);
        isPartner[partnerAddress].isPartner = true;
    }

    function initiateReleasePayment() public onlyPartners inState(EscrowState.Created) {
        state = EscrowState.onRelease;

    
        isPartner[msg.sender].hasVoted = true;
        voteCount++;

        emit InitiateRelease(msg.sender);
    }

    function approveReleasePayment() public onlyPartners inState(EscrowState.onRelease) {
        require(!isPartner[msg.sender].hasVoted,"Already voted");

        isPartner[msg.sender].hasVoted = true;
        voteCount++;

        emit ApprovedRelease(msg.sender);
    }

    function disapproveReleasePayment() public onlyPartners inState(EscrowState.onRelease) {
        require(isPartner[msg.sender].hasVoted,"haven't voted");

        isPartner[msg.sender].hasVoted = false;
        voteCount--;

        emit DisapprovedRelease(msg.sender);
    }

    function hasPassedThresold() public view returns(bool) {
        return (voteCount * 100) / partners.length >= fundReleaseThreshold;

        // V% = actualValue / TotalValue * 100

    }

    function releasePayment() public onlyPartners inState(EscrowState.onRelease) {
        state = EscrowState.Released;

        seller.transfer(value);
        emit PaymentReleased(seller, value);
    }

    function refundPayment() public onlyBuyer inState(EscrowState.Created) {
        state = EscrowState.Released;
        buyer.transfer(value);
        emit PaymentRefunded(buyer, value);
    }

    function initiateDispute() public inState(EscrowState.Created) {
        require(msg.sender == buyer || msg.sender == seller, "Only the buyer or seller can initiate a dispute.");
        state = EscrowState.Disputed;
        emit Dispute(msg.sender);
    }

    function resolveDispute(bool resolved) public inState(EscrowState.Disputed) {
        require(arbitrator == msg.sender, "Only the arbitrator can resolve the dispute.");
        state = EscrowState.Released;
        if (resolved) {
            seller.transfer(value);
            emit PaymentReleased(seller, value);
        } else {
            buyer.transfer(value);
            emit PaymentRefunded(buyer, value);
        }
        emit DisputeResolved(resolved);
    }
}