/**
 *Submitted for verification at polygonscan.com on 2023-07-02
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IERC20 {
    
    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}
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
    function _returnProjectInfo(uint256 prinfo) external view returns(Project memory output);

    function _returnIsContributor(address NFMAddress) external view returns(bool);

    function approveOrDenyProject(uint256 ProjectID, bool Stat) external returns (bool);
}
interface IGovPolling{
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
    function returnPullTheme(uint256 PullID) external view returns (uint256);
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
contract UpgradeContributionLevel{
   event SetApprov(address indexed from, uint256 indexed Cid, uint256 Pid);
   INFMContributor private NFMCont;
   IERC20 private IERC;
   IGovPolling private IPoll;
   address private _Owner;
   uint256 private ptype=3;
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
   mapping(uint256 => bool) private Upgrades;
   modifier onlyOwner() {
        require(
            _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        _;
    }
    constructor(address Cont, address Nfm, address GovPolls){
        NFMCont=INFMContributor(address(Cont));
        IERC=IERC20(address(Nfm));
        IPoll=IGovPolling(address(GovPolls));
        _Owner=msg.sender;
    }
    
    //Check if sender is project owner
    function retPinfoContAddress(uint256 P,address S) internal virtual returns (bool){
        require(address(NFMCont._returnProjectInfo(P).contributor)==address(S),'NC');
        return true;
    }
    //Check if sender is not blocked contributor
    function retContAddressOK(address S) internal virtual returns (bool){
        require(NFMCont._returnIsContributor(address(S))==true,'BC');
        return true;
    }
    //Check if balance is >150NFM
    function retContBalOK(address S) internal virtual returns (bool){
        require(IERC.balanceOf(address(S))>=150*10**18,'NB');
        return true;
    }
    //Check if PollInfoMatches Contribution
    function checkPollReq(uint256 Pid, address Req) internal virtual returns (bool){
        IGovPolling.GeneralPulls[] memory T=IGovPolling(address(IPoll)).returnPullsOnLevelEnded(ptype);
        bool c=false;
        for(uint256 i=0; i<T.length; i++){
            if(T[i].Requester==Req && T[i].PullId==Pid && T[i].VotingThema==34  && T[i].Terminated<block.timestamp){
                c=true;
            }
        }
        return c;
    }
    //Check doble confirmations on Contributions
    function checkdoble(uint256 Pid) internal view returns (bool){
        if(Upgrades[Pid]!=true){
            return true;
        }else{
            return false;
        }
    }
    //Check Votings
    function checkVotings(uint256 Pid) internal view returns (bool){
        uint256 y=IPoll.returnVotesCounterAll(Pid,true,3);
        uint256 n=IPoll.returnVotesCounterAll(Pid,false,3);
        if(y>n){
            return true;
        }else{
            return false;
        }
    }
    //Execute Orders
    function approveNext(uint256 Pid, uint256 Cid) public returns (bool){
        address Sender=msg.sender;
        require(retPinfoContAddress(Cid,Sender)==true,'A1');
        require(retContAddressOK(Sender)==true,'A2');
        require(retContBalOK(Sender)==true,'A3');
        require(checkPollReq(Pid,Sender)==true,'A4');
        require(checkdoble(Pid)==true,'A5');
        require(checkVotings(Pid)==true,'A6');
        require(NFMCont.approveOrDenyProject(Cid, true)==true,'A7');
        Upgrades[Pid]=true;
        emit SetApprov(Sender, Cid, Pid);
        return true;
    }
    //Upgrader function
    function updateAdd(address U, uint256 T) public onlyOwner returns (bool){
        if(T==1){
            NFMCont=INFMContributor(address(U));
        }else if(T==2){
            IERC=IERC20(address(U));
        }else{
            IPoll=IGovPolling(address(U));
        }
        return true;
    }
}