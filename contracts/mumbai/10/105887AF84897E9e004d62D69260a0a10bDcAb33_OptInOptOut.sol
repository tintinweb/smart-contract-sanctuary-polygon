// // SPDX-License-Identifier: MIT
/*
   _____ ____  __    ____  _____ ______________  ______  ______
  / ___// __ \/ /   / __ \/ ___// ____/ ____/ / / / __ \/ ____/
  \__ \/ / / / /   / / / /\__ \/ __/ / /   / / / / /_/ / __/   
 ___/ / /_/ / /___/ /_/ /___/ / /___/ /___/ /_/ / _, _/ /___   
/____/\____/_____/\____//____/_____/\____/\____/_/ |_/_____/   

*/

pragma solidity ^0.8.9;

import "./UserContract.sol";
contract OptInOptOut{
    /**
     * @dev OptIn/OptOut contract is used to log in the details from the solosecure application.
     * Location -> Network -> Oura ring(wearables).
    */
    error zeroAddressNotSupported();
    error adminAlreadyExist();
    error notAdminAddress();
    error userContractError();

    address[] private adminAddresses;
    address public owner;
    address userContractAddress;
    mapping(address => bool) private adminAddress;
    mapping(address => optIns) private userOptins;

    event Location(address indexed User, bool indexed Status);
    event Network(address indexed User, bool indexed Status);
    event OuraRing(address indexed User, bool indexed Status);
    event UserTransaction(address indexed User, uint indexed userTxIndex);

    struct optIns{
        bool location;
        bool network;
        bool ouraRing;
    }

    mapping(address => data[]) private userDataTx;

    struct data{
        bool location;
        bool network;
        bool age;
        bool weight;
        bool height;
        bool biologicalSex;
        bool bodyTemperature;
        bool day;
        bool prevDayActivity;
        bool restingHeartRate;
        bool tempDeviation;
        bool bedTimeStart;
        bool bedTimeEnd;
        bool timeInBed;
        bool avgBreath;
        bool avgHeartRate;
        bool bpm;
        bool source;
        uint256 timestamp;
    }

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"you are not the admin");
        _;
    }

    /**
        * whitelistAdmin. 
        * @param _admin Enter the admin address to be logged to the smart contract.
    */
    function whitelistAdmin(address _admin) external onlyOwner{
        if(_admin == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[_admin] == true){ revert adminAlreadyExist();}
        adminAddress[_admin] = true;
        adminAddresses.push(_admin);
    }

    function whitelistUserContract(address _userContractAd) external{
        if(_userContractAd == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[msg.sender] != true){ revert notAdminAddress();}
        userContractAddress = _userContractAd;
    }

    function optLocation(address _userAd, bool _optStatus) external {
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[msg.sender] != true){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(status != true || id != 3){ revert userContractError();}
        userOptins[_userAd].location = _optStatus; 
        emit Location(_userAd,_optStatus);
    }

    function optNetwork(address _userAd, bool _optStatus) external {
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[msg.sender] != true){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(status != true || id != 3){ revert userContractError();}
        userOptins[_userAd].network = _optStatus; 
        emit Network(_userAd,_optStatus);
    }

    function optOuraRing(address _userAd, bool _optStatus) external {
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[msg.sender] != true){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(status != true || id != 3){ revert userContractError();}
        userOptins[_userAd].ouraRing = _optStatus; 
        emit OuraRing(_userAd,_optStatus);
    }

    function userDataTransfer(address _userAd, data memory _data) external{
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[msg.sender] != true){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(status != true || id != 3){ revert userContractError();}
        userDataTx[_userAd].push(_data);
        emit UserTransaction(_userAd,userDataTx[_userAd].length);
    }

    //Read Functions:
    function userOptStatus(address _userAd) external view returns(optIns memory status){
        return userOptins[_userAd];
    }

    function allAdmins() external view returns(address[] memory){
        return adminAddresses;
    }
}

// // SPDX-License-Identifier: MIT
/*  
 _____ ____  __    ____  _____ ______________  ______  ______
  / ___// __ \/ /   / __ \/ ___// ____/ ____/ / / / __ \/ ____/
  \__ \/ / / / /   / / / /\__ \/ __/ / /   / / / / /_/ / __/   
 ___/ / /_/ / /___/ /_/ /___/ / /___/ /___/ /_/ / _, _/ /___   
/____/\____/_____/\____//____/_____/\____/\____/_/ |_/_____/   

*/

pragma solidity ^0.8.9;

contract UserContract{
    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error notAdmin();
    error addressAlreadyRegistered();
    error invalidType();
    
    address[] private pushUsers;
    address public admin;
    mapping(address => bool) private isUser;
    mapping(address => uint) private userTypeData;
    mapping(uint => string) public userTypes;

    /**
        * constructor
        * @param _setAdmin - Set the admin for the smart contract. 
    */
    constructor(address _setAdmin){
        admin = _setAdmin;
        userTypes[1] = "admin";
        userTypes[2] = "corporateUser";
        userTypes[3] = "appUser"; 
    }

    modifier onlyAdmin {
        require(msg.sender == admin,"you are not the admin");
        _;
    }

    /**
        *  addUser
        * @param _ad - Admin has the access to enter the user address to the blockchain.
        * @param _type - Enter the type, whether admin, corporate user, app user. 
    */
    function addUser(address _ad, uint _type) external onlyAdmin{
        if(isUser[_ad] == true){ revert addressAlreadyRegistered();}
        if(bytes(userTypes[_type]).length == 0){ revert invalidType();}
        isUser[_ad] = true;
        userTypeData[_ad] = _type;
        pushUsers.push(_ad);
    }

    /**
        *  verifyUser
        * @param _ad - Enter the address, to know about the role
    */
    function verifyUser(address _ad) external view returns(bool, uint){
        if(isUser[_ad]){
            return (true, userTypeData[_ad]);
        }else{
            return (false, userTypeData[_ad]);
        }
    }

    /**
        *  getAllUserAddress
        *  outputs all the entered user address from the blockchain.
    */
    function getAllUserAddress() external view returns(address[] memory){
        return pushUsers;
    }    
}