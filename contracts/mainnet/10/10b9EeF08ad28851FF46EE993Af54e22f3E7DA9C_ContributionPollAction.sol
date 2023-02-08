/**
 *Submitted for verification at polygonscan.com on 2023-02-07
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTRIBUTOR
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INFMContributor {
    struct Project{
        uint256 projectID;
        string projecttyp;
        string projectname;
        string projectdesc;        
        address contributor;
        uint256 expectedrewardNFM;
        uint256 startdate;
        uint256 enddate;
        bool   projectstatus;
    }
    function _returnProjectNotify(uint256 pr) external view returns(string memory output);
    function _returnProjectInfo(uint256 prinfo) external view returns(Project memory output);
    function _returnIsContributor(address NFMAddress)
        external
        view
        returns (bool);
    function approveOrDenyProject(uint256 ProjectID, bool Stat) external returns (bool);
    function _approveReward(uint256 ProjectID, uint256 Amount, bool stat) external returns (bool);
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IAFTGENERAL POLLING
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IAFTGeneralPolling{
    struct GeneralPulls {
        uint256 PullId;
        string PullTitle;
        string PullDescription;
        uint256 PullTyp;
        address Requester;
        uint256 Terminated;
        uint256 VotingThema;
        bool PullVoteapproved;
        uint256 Timestart;
    }
    function returnAFTVotes(uint256 PullID)
        external
        view
        returns (
            uint256[] memory,
            address[] memory,
            uint256
        );
    function returnAddressesOnVotes(uint256 PullID)
        external
        view
        returns (address[] memory, uint256);
    function returnVotesCounterAll(
        uint256 PullID,
        bool Vote,
        uint256 Type
    ) external view returns (uint256);
    function returnPullsOnLevelEnded(uint256 Level)
        external
        view
        returns (GeneralPulls[] memory);
    
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// CONTRIBUTION POLL ACTION CONTRACT
// This contract enables the execution of voted contributions
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract ContributionPollAction{
   
   
   INFMContributor public Cont;
   IAFTGeneralPolling public TPoll;
   //ContrID => true is approved maps all rewarded Contributions, to deny double payments
   mapping(uint256 => bool) public _IsApprovedForPayment; 

   constructor(address _cont, address _tpoll){
       INFMContributor C= INFMContributor(address(_cont));
       Cont= C;
       IAFTGeneralPolling T= IAFTGeneralPolling(address(_tpoll));
       TPoll=T;       
   }

   //Returns if a contribution Pull has had success or not the different voting Levels 
   function checkVoting(string calldata ContributionString, uint256 Level) public view returns (bool,bool){
       (bool found, uint256 polId)=getEndedPulls(Level, ContributionString, msg.sender);
       if(found==true){
          uint256 yes=TPoll.returnVotesCounterAll(polId, true, Level); 
          uint256 no=TPoll.returnVotesCounterAll(polId, false, Level); 
          if(yes==0 && no == 0){
              return (true,false);
          }else if(no > yes){
              return (true,false);
          }else if(yes > no){
              return (true,true);
          }else{
              return (true,false);
          }
       }else{
           return (false,false);
       }
   }
   //CHECKS RESULT OF ENDED PULLS 
   function getEndedPulls(uint256 Level, string calldata Title, address sender) internal view returns (bool,uint256) {
        IAFTGeneralPolling.GeneralPulls[] memory Polls = TPoll.returnPullsOnLevelEnded(Level);
        uint256 p=0;
        for(uint256 i=Polls.length-1; i>=0; i--){
            if(keccak256(abi.encodePacked(Polls[i].PullTitle))==keccak256(abi.encodePacked(Title)) && (Polls[i].Requester==sender)){
                p=Polls[i].PullId;
            }
        }
        if(p>0){
        return (true, p);
        }else{
        return (false, p);
        }
    }
    //Function to approve or delete my Contribution request after Level 3 voting is done
    function approveOrDeleteMyContri(uint256 ProjectID,string calldata ContributionString,uint256 Level,bool action) public returns (bool){
        (bool a, bool b) = checkVoting(ContributionString,Level);
        INFMContributor.Project memory pr= Cont._returnProjectInfo(ProjectID);
        if(action==true){
        require(pr.contributor==msg.sender,"Oo");
        require(a==true && b == true,'VF');
        require(Cont.approveOrDenyProject(ProjectID, true)==true,'NA');
        }else{
        require(pr.contributor==msg.sender,"Oo");
        require(a==true && b == false,'VF');
        require(Cont.approveOrDenyProject(ProjectID, false)==true,'NA');    
        }
        return true;
    }
    //Function to approve Contribution Payment after AFT has voted
    function approvePaymentApprovalContri(uint256 ProjectID,string calldata ContributionString,bool action) public returns (bool){
        (bool a, bool b) = checkVoting(ContributionString,1);
        INFMContributor.Project memory pr= Cont._returnProjectInfo(ProjectID);
        if(action==true){
        require(pr.contributor==msg.sender,"Oo");
        require(a==true && b == true,'VF');
        require(_IsApprovedForPayment[ProjectID]==false, "AR");
        require(Cont._approveReward(ProjectID, pr.expectedrewardNFM , true)==true,'RE');
        _IsApprovedForPayment[ProjectID]=true;
        }else{
        require(pr.contributor==msg.sender,"Oo");
        require(a==true && b == false,'VF');
        require(Cont._approveReward(ProjectID, pr.expectedrewardNFM , false)==true,'RE');  
        }
        return true;
    }
}