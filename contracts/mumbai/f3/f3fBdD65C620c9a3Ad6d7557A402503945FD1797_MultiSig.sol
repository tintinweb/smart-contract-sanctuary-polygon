/**
 *Submitted for verification at polygonscan.com on 2022-02-23
*/

pragma solidity 0.8.12;
pragma abicoder v2;

contract MultiSig {
    address contractOwner = 0xF9108C5B2B8Ca420326cBdC91D27c075ea60B749;
    address[] public approvers = [
        0xF9108C5B2B8Ca420326cBdC91D27c075ea60B749,
        0x7ab8a8dC4A602fAe3342697a762be22BB2e46d4d,
        0x813426c035f2658E50bFAEeBf3AAab073D956F31,
        0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1,
        0x89Ca0E3c4b93D9Ee8b1C1ab89266F1f6bA11Aa22
    ];
    event Deposit(address indexed fromThisGuy, uint valueGuy);
    event alertNewApproval(address indexed fromGuy, address sendToGuy, string  reasonGuy, uint amountGuy, uint idGuy);
    event Approval(address indexed signer, uint requestId, uint approvalId);
    event Payment(uint requestId, bool didSucceed, uint paymentAmount);


    bool contractHasLaunched = false;
    uint voteApprovalThreshold = 1;
    uint256 contractBalance = address(this).balance;

    function setVoteApprovalThreshold(uint thresholdPercentage) public {
        require(msg.sender == contractOwner, "Only owner can call this");
        voteApprovalThreshold = thresholdPercentage;
    }

    struct Custodian {
        address thisAddress;
        uint voteWeight;
    }
    Custodian[] custodians;

    function getContractOwner() public view returns (address) {
        return(contractOwner);
    }
    
    function firstRun() public returns(string memory){
        if(contractHasLaunched == false){
            if (msg.sender != contractOwner){
                return('only contract owner can run this function.');
            }
            else {
                for (uint256 i = 0; i < approvers.length; i++) {
                    Custodian memory newRequest = Custodian(approvers[i], 1);
                    custodians.push(newRequest);
                }
                contractHasLaunched = true;
                return('set approvers, vote weight, and voteApprovalThreshold!');
            }
        }
        else{
            return('contract has already been launched.');
        }
    }

    struct Requests {
        address payable receipient;
        uint id;
        uint amount;
        string _reason;
        uint status;
        
    }
    Requests[] transferRequests;
   
    struct ApprovalStruct {
        uint proposalId;
        address custodianMember;
        uint status; //0 untouched. 1 approved. 2 rejected
    }


    mapping(uint => mapping(address=> uint)) public approvedStatus;
 
    function getApprovalStatus(uint _requestId) public view returns(ApprovalStruct [] memory)  {
        ApprovalStruct [] memory custodianApprovals = new ApprovalStruct[](approvers.length);

        for (uint i=0; i < approvers.length; i++) {
            ApprovalStruct memory newCustodianApprovals = ApprovalStruct(_requestId, approvers[i], approvedStatus[ _requestId ][ approvers[i] ]);
            custodianApprovals[i] = newCustodianApprovals;
        }
        return(custodianApprovals);
    }

    function calculateApprovalCount(uint _requestId) public view returns(uint totalApproval) {
        ApprovalStruct [] memory custodianApprovals = new ApprovalStruct[](approvers.length);
        uint totalApproval1 = 0;

        for (uint i=0; i < approvers.length; i++) {
            ApprovalStruct memory newCustodianApprovals = ApprovalStruct(_requestId, approvers[i], approvedStatus[ _requestId ][ approvers[i] ]);
            custodianApprovals[i] = newCustodianApprovals;
            if (approvedStatus[ _requestId ][ approvers[i] ] != 0){
                totalApproval1 = totalApproval1+1;
            }
        }
        return(totalApproval1);
    }


    function sendTokens(uint id) public {
        require(msg.sender == contractOwner, "Only owner can call this");
        
        uint tallyVotes = calculateApprovalCount(id);
        require(tallyVotes >= voteApprovalThreshold, "not enough votes to take action.");
        require(transferRequests[id].status != 2, "proposal has already been executed.");

        transferRequests[id].receipient.transfer(transferRequests[id].amount); //only works for native coin (ETH/MATIC not erc20..yet)
        transferRequests[id].status = 2;
        emit Payment(id, true, transferRequests[id].amount);
    }

 
    function getAllApprovalRequests() public view returns (Requests [] memory, ApprovalStruct[][] memory){ 
        ApprovalStruct [][] memory tempApprovalStatusArray = new ApprovalStruct[][](transferRequests.length);
        for (uint i=0; i < transferRequests.length; i++) {
            tempApprovalStatusArray[i] = getApprovalStatus(transferRequests[i].id);
        }
        return(transferRequests, tempApprovalStatusArray);
    }

    function newApproval(address payable _sendTo, string memory _reason, uint _amount) public {
        Requests memory newRequest = Requests(_sendTo, transferRequests.length, _amount, _reason, 1); //1 is 'open' status
        transferRequests.push(newRequest);
        emit alertNewApproval(msg.sender, _sendTo, _reason, _amount, transferRequests.length);
    }

    function depositEth() public payable {
        contractBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function getContractBalance() public view returns(uint){
        // return contractBalance;
        return address(this).balance;
    }


    function approveRequest(uint _requestId, uint thisApproval) public {
        if ((thisApproval != 0) && (thisApproval != 1) && (thisApproval!=2)){return();}
        approvedStatus[_requestId][msg.sender] = thisApproval;
        emit Approval(msg.sender, _requestId, thisApproval);
    }

    function getCustodians() public view returns (Custodian [] memory){
        return(custodians);
    }
    


}