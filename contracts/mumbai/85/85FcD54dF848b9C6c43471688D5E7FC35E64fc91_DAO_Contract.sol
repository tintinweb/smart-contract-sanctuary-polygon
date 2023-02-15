//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Interfaces.sol"; 
import "./Ownable.sol";

contract DAO_Contract is Ownable{

    ERC721 public token;
    Ownable ownable;

    bool public approvalNeeded;
    uint public minCriteriaForApproval;
   
    string callerNotOwner = "Caller is not the Owner";
    string invalidProposalID = "Invalid proposal ID";
    string invalidMinimumNFTs = "invalid Minimum NFTs";
    string proposalCriteriaMismatched = "proposalCriteriaType mismatched with the given arguments.";

    struct DAO{
        address creator;
        uint proposalType;
        uint totalVotesForProposal;
        uint voteQuorem;
        uint timePeriodInHours;
        uint proposalCriteriaType;
        uint approvalNeeded;
        uint minCriteriaForApproval;
        uint totalVotesForApproval;     //for proposal approval
        uint weightage;                 // 0 for false, 1 for true
        uint minimumNFTsToVote;
        uint[] options;
        DAOStatus proposalStatus;
    }   

    mapping(uint => DAO) public proposalData;
    mapping(uint => mapping(address => bool)) addressVoted;         //Returns true if the address has already voted for the particular proposalID or vice versa.
    // mapping(uint => mapping(address => uint)) weightageVoting;      //
    mapping(uint => mapping(address => uint)) nonWeightageVotingCount;   //for non-weightage voting
    mapping(uint => mapping(address => bool)) private isVotedForProposalApproval;
    // mapping(uint => mapping(address => uint))

    //proposalID => option => votes
    mapping(uint => mapping(uint => uint)) proposalVotes;     
    mapping(uint => mapping(uint => uint)) proposalResults;

    enum DAOStatus {NotInitialized, Initialized, Running, Completed}
    event proposalCreated(uint proposalID, uint proposalType, uint proposalCriteriaType, uint approvalNeeded);
    event resultAnnounced(uint proposalID, uint proposalType, uint proposalCrioteriaType, uint result);

    modifier onlyTokenHolders{
        require(token.balanceOf(msg.sender) > 0, 
        "Insufficient Token balance.");
        _;
    }

    modifier onlyOwner() override {
        if(address(ownable) != address(0)){
        require(
        ownable.verifyOwner(msg.sender) == true ||
        verifyOwner(msg.sender) == true,
        callerNotOwner
        );
        } 
        else{
        require(
        verifyOwner(msg.sender) == true,
        callerNotOwner );
        }
        _;
    }

    constructor(address tokenAddress, bool approval, uint minCriteria){

        token = ERC721(tokenAddress);

        if(approval == true){
            require(minCriteria > 0 && minCriteria < token.totalSupply(),
            invalidMinimumNFTs);
        } else if(approval == false){
            require(minCriteria == 0,
            invalidMinimumNFTs);
        }

        approvalNeeded = approval;
        minCriteriaForApproval = minCriteria;
    }
    
    //PROPOSAL TYPE
    //mutuallyExclusive {Yes / No}                           1
    //multipleChoiceWithSingleAnswer                         2
    //MultipleChoiceWithMultipleAnswers                      3
    //Likert Scale                                           4

    //PROPOSAL CRITERIA TYPE
    //VoteQuorem(Threshold)                                  1
    //Time Limit                                             2
    //VoteQuorem and TimeLimit                               3

    function createProposal( 
        uint proposalID,
        uint proposalType,
        uint voteQuorem,
        uint timePeriodInHours,
        uint proposalCriteriaType,
        uint weightage,
        uint minimumNFTsToVote,
        bytes memory optionsInBytes
        ) public onlyTokenHolders{ 

          
            require(weightage <= 1, "Invalid weightage.");

            require(proposalData[proposalID].proposalStatus == DAOStatus.NotInitialized, 
                "Proposal ID already initialized."
            );

            require(proposalData[proposalID].proposalStatus != DAOStatus.Completed, 
                "Proposal ID status is completed."
            );

            require(proposalType > 0 && proposalType <= 4,
                "Invalid proposal type."
            );

            require(proposalCriteriaType > 0 && proposalCriteriaType <= 3,
                "Invalid proposal criteria type."
            );

            if(voteQuorem > 0 && timePeriodInHours == 0){
                require(proposalCriteriaType == 1,
                proposalCriteriaMismatched);
            }

            if(timePeriodInHours > 1 && voteQuorem == 0){
                require(proposalCriteriaType == 2, proposalCriteriaMismatched);
            }

            if(timePeriodInHours > 0 && voteQuorem > 0){
                require(proposalCriteriaType == 3,
                proposalCriteriaMismatched);
            }

            if(weightage == 0){
                require(minimumNFTsToVote > 0, "Zero min NFTs for weightage.");
            }

            uint approval;

            if(approvalNeeded == true){
                approval = 1;
            }else if(approvalNeeded == false){
                approval = 0;
            }

            uint[] memory options = returnOptions(optionsInBytes);
    
            proposalData[proposalID] = DAO(
                msg.sender,
                proposalType,
                0,
                voteQuorem,
                block.timestamp + (timePeriodInHours * 1 hours),
                proposalCriteriaType,
                approval,
                minCriteriaForApproval,
                0,
                weightage,
                minimumNFTsToVote,
                options,
                DAOStatus.Initialized
            );

            if(approvalNeeded == true){
                emit proposalCreated( proposalID, proposalType, proposalCriteriaType, getProposalData(proposalID).approvalNeeded);
            }
    }

    function voteToApproveProposal(uint proposalID) public onlyTokenHolders{
        
        require(getProposalData(proposalID).approvalNeeded == 1,
        "This proposal doesn't require approval");


        address msgSender = msg.sender;
      
        require(getVotedProposalApprovalStatus(proposalID, msgSender) != true,
            "This user has already voted for the given proposal ID");    

        // require(proposalData[proposalID].totalVotesForApproval < proposalData[proposalID].minCriteriaForApproval, "Votes reached till the approval");

        require(checkApprovalForProposal(proposalID) == true,
        "Maximum Vote limit reached.");

        // require(getAddressVotedStatus(proposalID, msgSender) == false,
        //     "This user has already voted for the given proposal ID");         

       proposalData[proposalID].totalVotesForApproval +=1;
       isVotedForProposalApproval[proposalID][msgSender] = true;


        if(getProposalData(proposalID).approvalNeeded == 1){
            emit proposalCreated( proposalID, getProposalType(proposalID), getProposalCriteriaType(proposalID), getProposalData(proposalID).approvalNeeded);
        }
    } 

    function calculateWeightage(uint proposalID, address addr) internal view returns (uint){
        require(getProposalData(proposalID).weightage == 1, invalidProposalID);
        uint balance = token.balanceOf(addr);
        // uint totalSupply = token.totalSupply();
        // uint weightage = (balance * 100 * 100) / totalSupply;
        return balance;
    }

    function voteForProposal (uint proposalID, bytes memory voteArray) public onlyTokenHolders{
        address msgSender = msg.sender;
        uint[] memory votes = abi.decode(voteArray, (uint[]));

        if(getProposalType(proposalID) == 1){
            require(votes.length == 1,
            "Invalid Votes length.");
        }

        require(getAddressVotedStatus(proposalID, msgSender) == false,
            "This user has already voted for the given proposal ID");   

        if(getProposalCriteriaType(proposalID) == 1){
            require(proposalData[proposalID].totalVotesForProposal <  proposalData[proposalID].voteQuorem,
                "This proposal has already completed its vote Quorem"
            );
        }

        else if(getProposalCriteriaType(proposalID) == 2){
            require(getTimeLimit(proposalID) >= block.timestamp, 
                "This proposal time limit has been completed."
            );

        } else if(getProposalCriteriaType(proposalID) == 3){
            require(proposalData[proposalID].totalVotesForProposal <  proposalData[proposalID].voteQuorem ||
                getTimeLimit(proposalID) >= block.timestamp, "This proposal already have completed its vote Quorem"
            );
        }

        if(getProposalData(proposalID).approvalNeeded == 1){
            require(getProposalData(proposalID).minCriteriaForApproval == getProposalData(proposalID).totalVotesForApproval,
            "This proposal has not been approved yet.");
        }

        
        bool isWeightage;
        uint weightage;
        
        if(getProposalData(proposalID).weightage == 0){
            bool votesAllowed = calculateNonWeightageVote(proposalID, msgSender);

            if(votesAllowed == true){
                nonWeightageVotingCount[proposalID][msgSender] += 1;
                
                isWeightage = false;
                proposalData[proposalID].totalVotesForProposal += 1;
            } else{
                revert ("No votes left");
            }
            
        } else if(getProposalData(proposalID).weightage == 1){
            weightage = calculateWeightage(proposalID, msgSender);
            
            isWeightage = true;
            // proposalData[proposalID].totalVotesForProposal += weightage;
            proposalData[proposalID].totalVotesForProposal += 1;
        }

        for(uint i = 0; i < votes.length; i++){
            if(isWeightage == true)
                proposalVotes[proposalID][votes[i]] += weightage;
            else
                proposalVotes[proposalID][votes[i]] += 1;
            require(votes[i] <=  getProposalData(proposalID).options.length, "invalid Vote");
        }
        
        addressVoted[proposalID][msgSender] = true;

        if(getProposalData(proposalID).proposalStatus == DAOStatus.Initialized){
            proposalData[proposalID].proposalStatus = DAOStatus.Running;
        }

        announceProposalResult(proposalID);
    }
    

    function checkApprovalForProposal(uint proposalID) internal view returns (bool){

        if(getProposalData(proposalID).totalVotesForApproval < getProposalData(proposalID).minCriteriaForApproval){
            return true;
        } else {
            return false;
        }
    }   

    function getProposalTotalVotes(uint proposalID) public view returns(uint){
        return proposalData[proposalID].totalVotesForProposal;
    }

    function announceProposalResult(uint proposalID) internal {
        if(
            (
                getProposalData(proposalID).proposalCriteriaType == 1 &&
                getProposalData(proposalID).totalVotesForProposal == getProposalData(proposalID).voteQuorem
            ) ||
            (
                getProposalData(proposalID).proposalCriteriaType == 2 &&
                block.timestamp >= getTimeLimit(proposalID)
            ) ||
            (
                getProposalData(proposalID).proposalCriteriaType == 3 &&
                (
                    getProposalData(proposalID).totalVotesForProposal == getProposalData(proposalID).voteQuorem 
                    &&
                    block.timestamp <= getTimeLimit(proposalID)
                )
            )
        ){
            announceResult(proposalID);
        }
    }

    function calculateNonWeightageVote(uint proposalID, address addr) internal view returns(bool){
        uint balance = token.balanceOf(addr);
        uint minimumVotes = getProposalData(proposalID).minimumNFTsToVote;
        uint votesAllowed = balance / minimumVotes;

        if(nonWeightageVotingCount[proposalID][addr] < votesAllowed){
            return true;
        } else {
            return false;
        }
    }

    function announceResult(uint proposalID) public onlyTokenHolders{
        if(getProposalData(proposalID).proposalType == 1){
            announceMEPResult(proposalID);
        }

        else if(
            getProposalData(proposalID).proposalType == 2 ||
            getProposalData(proposalID).proposalType == 3 ||
            getProposalData(proposalID).proposalType == 4
        )
        {
            announceSCAndMC(proposalID);
        }



    }

    function announceMEPResult(uint proposalID) internal {
        uint yesVotes = proposalVotes[proposalID][2];
        uint noVotes = proposalVotes[proposalID][1];  

        //1 for false/ NO
        //2 for true/ YES
        if(yesVotes > noVotes){
            proposalResults[proposalID][getProposalType(proposalID)] = 2;
            emit resultAnnounced(proposalID, getProposalType(proposalID), getProposalCriteriaType(proposalID), 2);
        } 
        else{
            proposalResults[proposalID][getProposalType(proposalID)] = 1;
            emit resultAnnounced(proposalID, getProposalType(proposalID), getProposalCriteriaType(proposalID), 1);
        }

        
        proposalData[proposalID].proposalStatus = DAOStatus.Completed;
        
    }

    //SC single choice
    //MC Multiple choice
    //Likert Scale
    function announceSCAndMC(uint proposalID) internal onlyTokenHolders{
        uint leadingOption = getLeadingOption(proposalID);  

        proposalResults[proposalID][getProposalType(proposalID)] = leadingOption;
        emit resultAnnounced(proposalID, getProposalType(proposalID), getProposalCriteriaType(proposalID), leadingOption);

        proposalData[proposalID].proposalStatus = DAOStatus.Completed;
    }

    function getLeadingOption(uint proposalID) internal view returns (uint){
        uint[] memory options = getProposalData(proposalID).options;
        uint leadingOption = 0;

        for(uint i = 1; i <= options.length; i++){
            if(proposalVotes[proposalID][i] > proposalVotes[proposalID][leadingOption])
                leadingOption = i;
        }
        return leadingOption;
    }   

    function deleteProposal(uint proposalID) public {
        require(msg.sender == getProposalData(proposalID).creator,
        "You don't own this proposal");

        delete proposalData[proposalID];

    }

    function getProposalCriteriaType(uint proposalID) public view returns(uint){
        return proposalData[proposalID].proposalCriteriaType;
    }

    function getProposalData(uint proposalID) public view returns(DAO memory){
        return proposalData[proposalID];
    }

    function getProposalType(uint proposalID) public view returns (uint){
        return proposalData[proposalID].proposalType;
    }

    function getResults(uint proposalID) public view returns (uint){
        return proposalResults[proposalID][getProposalType(proposalID)];
    }

    function getTimeLimit(uint proposalID) public view returns (uint){
        return getProposalData(proposalID).timePeriodInHours;
    }

    function getAddressVotedStatus(uint proposalID, address addr) public view returns(bool){
        return addressVoted[proposalID][addr];
    }

    function getVotedProposalApprovalStatus(uint proposalID, address addr) public view returns(bool){
        return isVotedForProposalApproval[proposalID][addr];
    }

    function setApprovalNeeded(bool approval, uint minCriteria) external onlyOwner{

        if(approval == true){
            require(minCriteria > 0 && minCriteria < token.totalSupply(),
            invalidMinimumNFTs);
        } else if(approval == false){
            require(minCriteria == 0,
            invalidMinimumNFTs);
        }

        approvalNeeded  = !approvalNeeded;
    }
    
    function returnOptions(bytes memory optionsInBytes) public pure returns(uint[] memory){

        uint[] memory options = abi.decode(optionsInBytes, (uint[])); 
        
        for(uint i = 0; i < options.length; i++){
            require(options[i] != 0, "Value 0 passed as options.");
        }
        return options;
    }

    function getProposalApprovalStatus(uint proposalID) public view returns(bool){
        if(proposalData[proposalID].totalVotesForApproval >= proposalData[proposalID].minCriteriaForApproval){
            return true;
        } 
        else {
            return false;
        }
    }

    function getProposalVotes(uint proposalID, uint optionNo) public view returns(uint){
        require(optionNo > 0 && optionNo <= getOptions(proposalID).length);
        return proposalVotes[proposalID][optionNo];
    }

    function getOptions(uint proposalID) public view returns (uint[] memory){
        return proposalData[proposalID].options;
    }

    function getProposalStatus(uint proposalID) public view returns(DAOStatus ){
        return proposalData[proposalID].proposalStatus;
    }

}