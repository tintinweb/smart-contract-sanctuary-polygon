/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INTERFACES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getTreasury() external view returns (address);

    function _getNFM() external pure returns (address);
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMTREASURY
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmTreasury {
    function _getWithdraw(
        address Coin,
        address To,
        uint256 amount,
        bool percent
    ) external returns (bool);
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMContributor.sol
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice This contract governs the Contributors. The contract manages project applications, payment orders,...
///         The contract is set up so that anyone who owns 10 NFM can register as a contributor however, contributors 
///         can be blacklisted.
///                
///
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMContributor{
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    INfmController private _Controller;
    address private _SController;
    address private _Owner;
    struct Contributor{
        address cont;
        string typ;
        uint256 timer;
    }
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
    Contributor[] public contributorAll;
    Project[] public projectsAll;
    Project[] public projectsAccepted;
    Project[] public projectsCompleted;
    address[] public RewardAddressArray;
    uint256[] public RewardAmountArray;
    uint256[] public RewardProjectIDArray;
    uint256 public contributorAllCounter=0;
    uint256 public projectAllCounter=0;
    uint256 public projectAcceptedCounter=0;
    uint256 public projectCompletedCounter=0;
    uint256 public projectPaid=0;
    uint256 public totalpaid=0;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MODIFIER
    onlyOwner       => Only Controller listed Contracts and Owner can interact with this contract.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier onlyOwner() {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        _;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(address => bool) public _contributorExist; //check if contributor exist
    mapping(address => bool) public _contributorCheck; //check if contributor is accepted false if blocked
    mapping(uint256 => bool) public _projectCheck; //check if project is accepted or blocked
    mapping(address => Contributor) public _contributorInfo;
    mapping(uint256 => Project) public _projectInfo;
    mapping(uint256 => bool) public _projectOK; //if project offer is allowed then true otherwise is denied
    mapping(uint256 => bool) public _projectcompleted;  //if true completed otherwise false
    mapping(uint256 => string) public _projectNotification;  //Message return
    mapping(uint256 => bool) public _projectReward;    //true if reward payment allowed false if not sufficient for reward
    mapping(uint256 => uint256) public _projectRewardAmount;    //Reward Amount to be paid.
    mapping(uint256 => bool) public _projectPaid;      //true if payment done
    mapping(address => Project[]) public ContributorProjects; //contains all projects of an contributor

    constructor(address Controller
                ) {
        _Owner = msg.sender;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        _SController= Controller;        
    }
    
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addContributor(string calldata cname,  string calldata ctyp,string calldata cmail,string calldata homepage) returns (bool);
    This function is to add contributors              
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addContributor(string calldata ctyp, address ContToAdd) public returns (bool){
        address user;
        bool bal;
        if(msg.sender==_Owner){
            user=ContToAdd;
            bal=true;
        }else{
            user=msg.sender;
            if(IERC20(_Controller._getNFM()).balanceOf(user)>10*10**18){
                bal=true;
            }else{
                bal=false;
            }
        }
        
        if(bal==true){
        if(_contributorCheck[user]==false){
        _contributorCheck[user]=true;
        _contributorExist[user]=true;
        _contributorInfo[user]=Contributor(
            user,
            ctyp,
            block.timestamp
        );
        contributorAll.push(Contributor(
            user,
            ctyp,
            block.timestamp
        ));
        contributorAllCounter++;
        
        }
        }
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_returnProjects(uint256 allAccComp) returns (Project);
    This function is to add my address for contributions This function is for the output of all projects.             
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnProjects(uint256 allAccComp) public view returns(Project[] memory output){
        if(allAccComp==1){
            return projectsAll;
        }else if(allAccComp==2){
            return projectsAccepted;
        }else{
            return projectsCompleted;
        }
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_returnProjectsContributor(address ContributorsAll) returns (Project);
    This function is for outputting all projects of a contributor by address       
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnProjectsContributor(address ContributorsAll) public view returns(Project[] memory output){
        return ContributorProjects[ContributorsAll];        
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_returnProjectInfo(uint256 prinfo) returns (Project);
    This function is for the output of all information about a project       
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnProjectInfo(uint256 prinfo) public view returns(Project memory output){
        return _projectInfo[prinfo];        
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_returnProjectNotify(uint256 pr) returns (string);
    This function is for outputting specified messaging      
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnProjectNotify(uint256 pr) public view returns(string memory output){
        return _projectNotification[pr];        
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_returnAllContributors() returns (Contributor);
    This function returns all contributors    
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnAllContributors() public view returns(Contributor[] memory output){
        return contributorAll;        
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_returnIsContributor(address NFMAddress) returns (bool);
    This function is for reviewing a contributor  
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnIsContributor(address NFMAddress) public view returns(bool){
        return _contributorCheck[NFMAddress];        
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addProject(string calldata ptyp, string calldata pname,string calldata pdesc,uint256 rewardExpected) returns (bool);
    This function is to add projects for contributions              
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addProject(string calldata ptyp, string calldata pname,string calldata pdesc,uint256 rewardExpected) public returns (bool){
        if(IERC20(_Controller._getNFM()).balanceOf(msg.sender) > 10*10**18){
        if(_contributorCheck[msg.sender]==true){
            _projectInfo[projectAllCounter]=Project(
                projectAllCounter,
                ptyp,
                pname,
                pdesc,
                msg.sender,
                rewardExpected,
                block.timestamp,
                0,
                false
            );
            _projectCheck[projectAllCounter]=false;
            projectsAll.push(Project(
                projectAllCounter,
                ptyp,
                pname,
                pdesc,
                msg.sender,
                rewardExpected,
                block.timestamp,
                0,
                false
            ));
            ContributorProjects[msg.sender].push(Project(
                projectAllCounter,
                ptyp,
                pname,
                pdesc,
                msg.sender,
                rewardExpected,
                block.timestamp,
                0,
                false
            ));
            _projectNotification[projectAllCounter]="Your project request has been listed. If your project is accepted, you get access to additional functions.";
            projectAllCounter++;
            
        }
        }
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_setProjectCompleted(uint256 ProjectID) returns (bool);
    This feature is for the contributor. He can declare his project finished in order to receive the reward. The project is then checked by the governance. 
    If it is deemed unsatisfactory, the contributor will be notified.             
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _setProjectCompleted(uint256 ProjectID) public returns (bool){
        if(msg.sender == _projectInfo[ProjectID].contributor){
            _projectInfo[ProjectID].enddate=block.timestamp;
            _projectInfo[ProjectID].projectstatus=true;
            _projectcompleted[ProjectID]=true;
            for(uint256 i=0; i<ContributorProjects[msg.sender].length;i++){
                if(ContributorProjects[msg.sender][i].projectID==ProjectID){
                    ContributorProjects[msg.sender][i].enddate=block.timestamp;
                    ContributorProjects[msg.sender][i].projectstatus=true;
                }
            }
            _projectNotification[ProjectID]="Your project will now be checked! If accepted, you will be listed for the reward. Otherwise, it reverts to development.";
            
        }
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_approveReward(uint256 ProjectID, uint256 Amount, bool stat) returns (bool);
    This feature is governed and designed to award the reward to a completed project.            
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _approveReward(uint256 ProjectID, uint256 Amount, bool stat) public onlyOwner returns (bool){       
            if(stat == true){
            _projectRewardAmount[ProjectID]=Amount;
            _projectReward[ProjectID]=stat;
            _projectcompleted[ProjectID]=stat;
            projectsCompleted.push(_projectInfo[ProjectID]);
            projectCompletedCounter++;
            RewardAddressArray.push(_projectInfo[ProjectID].contributor);
            RewardAmountArray.push(Amount);
            INfmTreasury(_Controller._getTreasury())._getWithdraw(_Controller._getNFM(),address(this),Amount,false);
            RewardProjectIDArray.push(ProjectID);
            _projectNotification[ProjectID]="Congratulations, your project has been accepted. The reward will be paid out on the next distribution date.";
            
            }else{
                _projectNotification[ProjectID]="Your project does not sufficiently fulfill its purpose. More work needed.";
                _projectcompleted[ProjectID]=false;
            }
            return true;
        
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @approveOrDenyProject(uint256 ProjectID, bool Stat) returns (bool);
    This function is subject to governance and is used to ban or allow projects.          
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function approveOrDenyProject(uint256 ProjectID, bool Stat) public onlyOwner returns (bool){
        _projectOK[ProjectID]=Stat;
        _projectCheck[ProjectID]=Stat;
        if(Stat == true){
        _projectNotification[ProjectID]="Congratulations! Your project does match our requirements.";
        projectsAccepted.push(_projectInfo[ProjectID]);
        projectAcceptedCounter++;        
        }else{
            _projectNotification[ProjectID]="Your project does not match our requirements.";
        }
        return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @resetPayArrays() returns (bool);
    This function is subject to governance and is used to update payment addresses         
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function resetPayArrays() public onlyOwner returns (bool){
                address[] memory n; 
                RewardAddressArray=n;
                uint[] memory u;
                RewardAmountArray=u;
                uint[] memory d;
                RewardProjectIDArray=d;
                
                return true;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @payRewardsToContributors() returns (bool);
    This function is subject to governance and is used to pay out the reward        
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function payRewardsToContributors() public onlyOwner returns (bool){
        uint256 AmountsOfPayments=RewardAddressArray.length;
        if(AmountsOfPayments > 0){
            uint256 zaehler;
            for(uint256 i = 0; i<RewardAddressArray.length; i++){
                if(IERC20(_Controller._getNFM()).transfer(RewardAddressArray[i], RewardAmountArray[i])==true){
                    zaehler++;
                    projectPaid++;
                    totalpaid+=RewardAmountArray[i];
                    _projectPaid[RewardProjectIDArray[i]]=true;
                    _projectNotification[RewardProjectIDArray[i]]="Contribution has been paid.";
                }
            }
            if(zaehler == AmountsOfPayments){
                resetPayArrays();
            }
        }
        return true;
    }
}