/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0 < 0.9.0;

contract Registry{

    address public superAdmin;
    uint public totalAdmins;
    
    struct Admin{
        address adminAddress;
        string city;
        string district;
        string state;
    }

    struct LandDetails{
        address owner;
        address admin;
        uint256 propertyId;
        uint surveyNumber;
        uint index;
        bool registered;
        uint marketValue;
        bool markAvailable;
        mapping(uint => RequestDetails) requests; // reqNo => RequestDetails
        uint noOfRequests;  // other users requested to this land
        uint sqft;
    }

    struct UserProfile{
        address userAddr;
        string fullName;
        string gender;
        string email;
        uint256 contact;
        string residentialAddr;
        uint totalIndices;
        uint requestIndices;  // this user requested to other lands
    }

    struct OwnerOwns{
        uint surveyNumber;
        string state;
        string district;
        string city;
    }
    
    struct RequestedLands{
        uint surveyNumber;
        string state;
        string district;
        string city;
    }

    struct RequestDetails{
        address whoRequested;
        uint reqIndex;
    }

    mapping(address => Admin) public admins;
    mapping(address => mapping(uint => OwnerOwns)) public ownerMapsProperty;  // ownerAddr => index no. => OwnerOwns 
    mapping(address => mapping(uint => RequestedLands)) public requestedLands;  // ownerAddr => reqIndex => RequestedLands
    mapping(string => mapping(string => mapping(string => mapping(uint => LandDetails)))) public landDetalsMap; // state => district => city => surveyNo => LandDetails
    mapping(address => UserProfile) public userProfile;
    

    constructor(){
        superAdmin = msg.sender;
    }

    modifier onlyAdmin(){
        require(admins[msg.sender].adminAddress == msg.sender, "Only admin can Register land");
        _;
    }


    // SuperAdmin: Registers new admin
    function addAdmin(address _adminAddr, string memory _state, string memory _district, string memory _city) external{
        Admin storage newAdmin = admins[_adminAddr];
        totalAdmins++;

        newAdmin.adminAddress = _adminAddr;
        newAdmin.city = _city;
        newAdmin.district = _district;
        newAdmin.state = _state;
    }


    // check if it is admin
    function isAdmin() external view returns(bool){
        if(admins[msg.sender].adminAddress == msg.sender){
            return true;
        }
        else return false;
    }


    // Admin: registers land
    function registerLand(string memory _state, string memory _district, string memory _city, uint256 _propertyId, uint _surveyNo, address _owner, uint _marketValue, uint _sqft) external onlyAdmin{
        
        require(keccak256(abi.encodePacked(admins[msg.sender].state)) == keccak256(abi.encodePacked(_state))  
        && keccak256(abi.encodePacked(admins[msg.sender].district)) == keccak256(abi.encodePacked(_district))
        && keccak256(abi.encodePacked(admins[msg.sender].city)) == keccak256(abi.encodePacked(_city)), "Admin can only register land of same city.");

        require(landDetalsMap[_state][_district][_city][_surveyNo].registered == false, "Survey Number already registered!");

        LandDetails storage newLandRegistry = landDetalsMap[_state][_district][_city][_surveyNo];
        OwnerOwns storage newOwnerOwns = ownerMapsProperty[_owner][userProfile[_owner].totalIndices];
        

        newLandRegistry.owner = _owner;
        newLandRegistry.admin = msg.sender;
        newLandRegistry.propertyId = _propertyId;
        newLandRegistry.surveyNumber = _surveyNo;
        newLandRegistry.index = userProfile[_owner].totalIndices;
        newLandRegistry.registered = true;
        newLandRegistry.marketValue = _marketValue;
        newLandRegistry.markAvailable = false;
        newLandRegistry.sqft = _sqft;

        newOwnerOwns.surveyNumber = _surveyNo;
        newOwnerOwns.state = _state;
        newOwnerOwns.district = _district;
        newOwnerOwns.city = _city;

        userProfile[_owner].totalIndices++;
    }


    // User_1: set user profile
    function setUserProfile(string memory _fullName, string memory _gender, string memory _email, uint256 _contact, string memory _residentialAddr) external{
        
        UserProfile storage newUserProfile = userProfile[msg.sender];

        newUserProfile.fullName = _fullName;
        newUserProfile.gender = _gender;
        newUserProfile.email = _email;
        newUserProfile.contact = _contact;
        newUserProfile.residentialAddr = _residentialAddr;
    }


    // User_1: mark property available
    function markMyPropertyAvailable(uint indexNo) external {
        
        string memory state = ownerMapsProperty[msg.sender][indexNo].state;
        string memory district = ownerMapsProperty[msg.sender][indexNo].district;
        string memory city = ownerMapsProperty[msg.sender][indexNo].city;
        uint surveyNumber = ownerMapsProperty[msg.sender][indexNo].surveyNumber;

        require(landDetalsMap[state][district][city][surveyNumber].markAvailable == false, "Property already marked available");

        landDetalsMap[state][district][city][surveyNumber].markAvailable = true;
    
    }


    // User_2: Request for buy  **ownerAddress & index = arguements** 
    function RequestForBuy(string memory _state, string memory _district, string memory _city, uint _surveyNo) external{

        LandDetails storage thisLandDetail = landDetalsMap[_state][_district][_city][_surveyNo];
        require(thisLandDetail.markAvailable == true, "This property is NOT marked for sale!");

        uint req_serialNum = thisLandDetail.noOfRequests; 
        thisLandDetail.requests[req_serialNum].whoRequested = msg.sender;
        thisLandDetail.requests[req_serialNum].reqIndex = userProfile[msg.sender].requestIndices;
        thisLandDetail.noOfRequests++;

        // adding requested land to user_2 profile
        RequestedLands storage newReqestedLands = requestedLands[msg.sender][userProfile[msg.sender].requestIndices];
        newReqestedLands.surveyNumber = _surveyNo;
        newReqestedLands.state = _state;
        newReqestedLands.district = _district;
        newReqestedLands.city = _city;

        userProfile[msg.sender].requestIndices++;

    }


    // User_1: Accept the buy request; sell.
    function AcceptRequest(uint _index, uint _reqNo) external{

        uint _surveyNo = ownerMapsProperty[msg.sender][_index].surveyNumber;
        string memory _state = ownerMapsProperty[msg.sender][_index].state; 
        string memory _district = ownerMapsProperty[msg.sender][_index].district;
        string memory _city = ownerMapsProperty[msg.sender][_index].city;
        
        // updating LandDetails
        address newOwner = landDetalsMap[_state][_district][_city][_surveyNo].requests[_reqNo].whoRequested;
        uint newOwner_reqIndex = landDetalsMap[_state][_district][_city][_surveyNo].requests[_reqNo].reqIndex;
        uint noOfReq = landDetalsMap[_state][_district][_city][_surveyNo].noOfRequests;

        // deleting requested land from all requesters AND removing all incoming requests
        for(uint i=0; i<noOfReq; i++){
            address requesterAddr = landDetalsMap[_state][_district][_city][_surveyNo].requests[i].whoRequested;
            uint requester_reqIndx = landDetalsMap[_state][_district][_city][_surveyNo].requests[i].reqIndex;
            
            delete requestedLands[requesterAddr][requester_reqIndx];
            delete landDetalsMap[_state][_district][_city][_surveyNo].requests[i];
        }

        landDetalsMap[_state][_district][_city][_surveyNo].owner = newOwner;
        landDetalsMap[_state][_district][_city][_surveyNo].markAvailable = false;
        landDetalsMap[_state][_district][_city][_surveyNo].noOfRequests = 0;

        // deleting property from user_1's ownerMapsProperty 
        delete ownerMapsProperty[msg.sender][_index];

        // adding ownerMapsProperty for newOwner
        uint newOwnerTotProp = userProfile[newOwner].totalIndices;
        OwnerOwns storage newOwnerOwns = ownerMapsProperty[newOwner][newOwnerTotProp];
       
        newOwnerOwns.surveyNumber = _surveyNo;
        newOwnerOwns.state = _state;
        newOwnerOwns.district = _district;
        newOwnerOwns.city = _city;

        landDetalsMap[_state][_district][_city][_surveyNo].index = newOwnerTotProp;

        userProfile[newOwner].totalIndices++;

    }


    
    //******* GETTERS **********

    // return land details 
    function getLandDetails(string memory _state, string memory _district, string memory _city, uint _surveyNo) external view returns(address, uint256, uint, uint, uint){
        
        address owner = landDetalsMap[_state][_district][_city][_surveyNo].owner;
        uint256 propertyid = landDetalsMap[_state][_district][_city][_surveyNo].propertyId;
        uint indx = landDetalsMap[_state][_district][_city][_surveyNo].index;
        uint mv = landDetalsMap[_state][_district][_city][_surveyNo].marketValue;
        uint sqft = landDetalsMap[_state][_district][_city][_surveyNo].sqft;

        return(owner, propertyid, indx, mv, sqft);
    }

    function getRequestCnt_propId(string memory _state, string memory _district, string memory _city, uint _surveyNo) external view returns(uint, uint256){
        uint _noOfRequests = landDetalsMap[_state][_district][_city][_surveyNo].noOfRequests;
        uint256 _propertyId = landDetalsMap[_state][_district][_city][_surveyNo].propertyId;
        return(_noOfRequests, _propertyId);
    }

    function getRequesterDetail(string memory _state, string memory _district, string memory _city, uint _surveyNo, uint _reqIndex) external view returns(address){
        address requester = landDetalsMap[_state][_district][_city][_surveyNo].requests[_reqIndex].whoRequested;
        return(requester);
    }

    function isAvailable(string memory _state, string memory _district, string memory _city, uint _surveyNo) external view returns(bool){
        bool available = landDetalsMap[_state][_district][_city][_surveyNo].markAvailable;
        return(available);
    }

    function getOwnerOwns(uint indx) external view returns(string memory, string memory, string memory, uint){
        
        uint surveyNo = ownerMapsProperty[msg.sender][indx].surveyNumber;
        string memory state = ownerMapsProperty[msg.sender][indx].state;
        string memory district = ownerMapsProperty[msg.sender][indx].district;
        string memory city = ownerMapsProperty[msg.sender][indx].city;

        return(state, district, city, surveyNo);
    }

    function getRequestedLands(uint indx) external view returns(string memory, string memory, string memory, uint){
        
        uint surveyNo = requestedLands[msg.sender][indx].surveyNumber;
        string memory state = requestedLands[msg.sender][indx].state;
        string memory district = requestedLands[msg.sender][indx].district;
        string memory city = requestedLands[msg.sender][indx].city;

        return(state, district, city, surveyNo);
    }

    function getUserProfile() external view returns(string memory, string memory, string memory, uint256, string memory){
        
        string memory fullName = userProfile[msg.sender].fullName;
        string memory gender = userProfile[msg.sender].gender;
        string memory email = userProfile[msg.sender].email;
        uint256 contact = userProfile[msg.sender].contact;
        string memory residentialAddr = userProfile[msg.sender].residentialAddr;

        return(fullName, gender, email, contact, residentialAddr);
    }

    function getIndices() external view returns(uint, uint){

        uint _totalIndices = userProfile[msg.sender].totalIndices;
        uint _reqIndices = userProfile[msg.sender].requestIndices;

        return(_totalIndices, _reqIndices);
    }


    function didIRequested(string memory _state, string memory _district, string memory _city, uint _surveyNo) external view returns(bool){
        
        LandDetails storage thisLandDetail = landDetalsMap[_state][_district][_city][_surveyNo];
        uint _noOfRequests = thisLandDetail.noOfRequests;

        if(_noOfRequests == 0) 
            return (false);

        for(uint i=0; i<_noOfRequests; i++){
            if(thisLandDetail.requests[i].whoRequested == msg.sender){
                return (true);
            }
        } 

        return(false);
    } 

}