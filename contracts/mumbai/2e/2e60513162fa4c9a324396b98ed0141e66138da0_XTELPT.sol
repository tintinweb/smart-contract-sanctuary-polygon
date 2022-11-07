/**
 *Submitted for verification at polygonscan.com on 2022-11-06
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
// import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract XTELPT is  KeeperCompatibleInterface {

    enum XTELPState {
        OPEN,
        CLOSED
    }

    uint public counter;    
    // Use an i_interval in seconds and a timestamp to slow execution of Upkeep
    uint private i_interval;
    uint public s_lastTimeStamp;
    uint public v_lastTimeStamp;


    /* string User Types */
    string userType = "User";
    string hostType = "Host";
    string volunType = "Volun";


    /* Campaign and Meeting variables */

    mapping(address => campaign[]) public Campaign;

    mapping(address => meeting[]) public Meeting;

    uint256 public campaignIndex;
    
    uint256 public meetingIndex;    
    
    /* User profile mapping */
    mapping(address => profile) public UserProfile;

    /* State mapping */
    mapping(address => XTELPState) private s_xtelpState;
    mapping(address => XTELPState) private volunState;

    /* User Types Arrays */
    address [] public AllAccount;

    address [] public recentCampaignCreator;


    /* Struct */
    struct profile {
        address addr;
        string name;
        string role;
        uint256 rating;
        string bio;
        string profilePic;
        bool avaliable;
        bool volun;
    }

    struct meeting {
        address host;
        address user;
        uint256 start;
        uint256 end;
        uint256 time;
        uint256 fee;
        bool completed;
    }


    struct campaign {
        address volunteer;
        address user;
        uint256 start_time;
        uint256 end_time;
        uint256 fee;
        bool completed;
    }

    campaign [] public AllCampaign;


    /* Modifiers */
    modifier onlyHost  {
        require(keccak256(abi.encodePacked(UserProfile[msg.sender].role)) == keccak256(abi.encodePacked("Host")), "NOT A HOST");
        _;
    }
   
    modifier onlyVolun  {
        require(keccak256(abi.encodePacked(UserProfile[msg.sender].role)) == keccak256(abi.encodePacked("Host")) && UserProfile[msg.sender].avaliable == true , "NOT A VOLUNTEER");
        _;
    }

    modifier onlyUser  {
        require(keccak256(abi.encodePacked(UserProfile[msg.sender].role)) == keccak256(abi.encodePacked("User")), "NOT A USER");
        _;
    }

    event RequestedID(uint256 indexed requestId);

    /**
     * @dev constructor used to assign values that will not change
     */
    constructor() {
      
        s_lastTimeStamp = block.timestamp;
        v_lastTimeStamp = block.timestamp;
        s_xtelpState[msg.sender] = XTELPState.OPEN;
        volunState[msg.sender] = XTELPState.OPEN;
    }


    /**
     * @dev This function `createUser` any body can call this functions and the senders profile
     * would be set to that of a `User`
     */
    function createUser(uint256 _rating, string memory _name, string memory _pic, string memory _bio) public {
         if(UserProfile[msg.sender].addr == address(0)){
            AllAccount.push(msg.sender);
        }
        
        UserProfile[msg.sender].addr = msg.sender;
        UserProfile[msg.sender].name = _name;
        UserProfile[msg.sender].rating = _rating;
        UserProfile[msg.sender].role = userType;
        UserProfile[msg.sender].profilePic = _pic;
        UserProfile[msg.sender].bio = _bio;
    }

    
    /**
     * @dev This function `createHost` any body can call this functions and the senders profile
     * would be set to that of a `Host`
     */
    function createHost(uint256 _rating, string memory _name, string memory _pic, string memory _bio) public {  
        if(UserProfile[msg.sender].addr == address(0)){
            AllAccount.push(msg.sender);
        }
        
        s_xtelpState[msg.sender] = XTELPState.OPEN;

        UserProfile[msg.sender].addr = msg.sender;
        UserProfile[msg.sender].name = _name;
        UserProfile[msg.sender].rating = _rating;
        UserProfile[msg.sender].role = hostType;
        UserProfile[msg.sender].profilePic = _pic;
        UserProfile[msg.sender].bio = _bio;
    }

     /**
     * @dev This function `createVolun` allows only the Host to call it hence the `OnlyHost` modifier
     * A host can toggle being a volunteer for campaign mode on, thereby making the profile avaliable for campaign 
     */
     function becomeVolun() public onlyHost {
       
        UserProfile[msg.sender].volun = true;
        UserProfile[msg.sender].avaliable = true;
    }


    /**
     * @dev This function `unVolun` allows only the Host to call it hence the `OnlyHost` modifier
     * A host can toggle being a volunteer for campaign mode off, thereby making the profile unavaliable for campaign 
     */
    function unVolun() public onlyHost {       
        UserProfile[msg.sender].volun = false;
        UserProfile[msg.sender].avaliable = false;

    }

    /**
     * @dev This function `createSchedule` allows only the Host to call it hence the `OnlyHost` modifier
     * after which a Host can create a meeting with some parameters like time and fee needed
     */
    function createSchedule(uint256 _time, uint256 _fee) public onlyHost {
        meetingIndex ++;
        

        meeting memory NewMeeting;
        NewMeeting.host = msg.sender;
        NewMeeting.time = _time * 60;
        NewMeeting.start = block.timestamp;
        NewMeeting.fee = _fee;

        i_interval = _time * 60;
        s_xtelpState[msg.sender] = XTELPState.OPEN;

        Meeting[msg.sender].push(NewMeeting);
      
    }

    /**
     * @dev This function `joinMeeting` allows only the User to call it hence the `OnlyUser` modifier
     * after which the meeting ID is specified and the user would be assigned to the meeting
     */
    function joinMeeting(address _host, uint256 _id) public onlyUser {
        Meeting[_host][_id].user = msg.sender;
    } 

    /**
     * @dev This function `createCampaign` allows only the User to call it hence the `OnlyUser` modifier
     * after which any avaliable volunteer would be assigned to the campaign
     */
    function createCampaign() public onlyUser {
        campaignIndex ++;

        campaign memory NewCampaign;
        NewCampaign.user = msg.sender;
        NewCampaign.start_time = block.timestamp;
        NewCampaign.fee = 0;

        i_interval = 1;
        s_xtelpState[msg.sender] = XTELPState.OPEN;

        for(uint i = 0; i < AllAccount.length; i++){
            if(UserProfile[AllAccount[i]].avaliable == true){
                NewCampaign.volunteer = AllAccount[i];
                UserProfile[AllAccount[i]].avaliable = false;
                break;
            }
        }

        Campaign[msg.sender].push(NewCampaign);
        AllCampaign.push(NewCampaign);
      
    }


    /**
     * @dev This function `endCampaign` allows only the User end the campaign
     */
    function endCampaign(address _user, uint256 _id) public onlyUser {
       Campaign[_user][_id].completed = true;
       Campaign[_user][_id].end_time = block.timestamp;
    }


      


    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. It makes sure that the campaign or meeting is not yet completed
     * 2. The time interval has passed for either meeting or campaign.
     */
   
   function checkUpkeep(bytes memory /* checkData */) public view override returns ( bool upkeepNeeded,
    bytes memory /* performData */  ) {
        
        for (uint i = 0; i < AllAccount.length; i++) {
            for (uint j = 0; j < Meeting[AllAccount[i]].length; j++) {
                if(Meeting[AllAccount[i]][j].time > 0 && Meeting[AllAccount[i]][j].completed == false){
                    bool isOpen = XTELPState.OPEN == s_xtelpState[msg.sender];
                    bool timePassed = ((block.timestamp - Meeting[AllAccount[i]][j].start) >  Meeting[AllAccount[i]][j].time);
                    upkeepNeeded = (isOpen && timePassed);
                }
                
            }
        }
       
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     */
    function performUpkeep(bytes calldata /*performData*/) external override {

        for (uint i = 0; i < AllAccount.length; i++) {
            for (uint j = 0; j < Meeting[AllAccount[i]].length; j++) {
               (bool upkeepNeeded, ) = checkUpkeep("");
                require(upkeepNeeded, "Doesn't meet requirement for UpKeep");
                Meeting[AllAccount[i]][j].completed = true;
                Meeting[AllAccount[i]][j].end = block.timestamp;
                s_xtelpState[AllAccount[i]] = XTELPState.CLOSED;
            }
        }
        
        
        
    }
   
   
    /** Getter Functions */

    function meetingNum() public view returns (uint256) {
        return meetingIndex;
    }
    
    function campaignNum() public view returns (uint256) {
        return campaignIndex;
    }

    function getMeeting(address _prof) public view returns (meeting [] memory) {
        return Meeting[_prof];
    }
    
    function getCampaign(address _prof) public view returns (campaign [] memory) {
        return Campaign[_prof];
    }
    

    function getProfile(address userAdd) public view returns (profile memory) {
        return UserProfile[userAdd];
    }

    function getAllAccount() public view returns (address [] memory) {
        return AllAccount;
    }

    function getAllCampaign() public view returns (campaign [] memory) {
        return AllCampaign;
    }
    

   
}