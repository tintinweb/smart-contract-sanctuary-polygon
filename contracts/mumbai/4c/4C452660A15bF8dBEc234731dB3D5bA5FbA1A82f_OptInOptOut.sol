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
    mapping(address => optIns) private userOptIns;
    // mapping(address => optInsData[]) private userDataTx;
    mapping(uint => mapping(address => optInsData)) private userTxCount;
    mapping(uint => mapping(address => uint)) private userTxValue;
    mapping(uint => uint) private packageValue;
    mapping(uint => address[]) private packageUsers;

    event Location(address indexed User, bool indexed Status);
    event Network(address indexed User, bool indexed Status);
    event OuraRing(address indexed User, bool indexed Status);
    event UserTransaction(uint indexed PackageId, address indexed User, uint indexed userFieldsCount);

    struct optIns{
        bool location;
        bool network;
        bool ouraRing;
    }

    struct optInsData{
        uint location;
        uint network;
        ouraRingData ouraData;
        uint timeStamp;
    }

    struct ouraRingData{
        uint age;
        uint weight;
        uint height;
        uint biologicalSex;
        uint bodyTemperature;
        uint day;
        uint prevDayActivity;
        uint restingHeartRate;
        uint tempDeviation;
        uint bedTimeStart;
        uint bedTimeEnd;
        uint timeInBed;
        uint avgBreath;
        uint avgHeartRate;
        uint bpm;
        uint source;
        uint timestamp;
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
        * admin has the access to control most of the function in this contract.
    */
    function whitelistAdmin(address _admin) external onlyOwner{
        if(_admin == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[_admin] == true){ revert adminAlreadyExist();}
        adminAddress[_admin] = true;
        adminAddresses.push(_admin);
    }

    /**
        * whitelistUserContract.
        * @param _userContractAd The deployede userContract address needs to be added by the admin.
    */
    function whitelistUserContract(address _userContractAd) external{
        if(_userContractAd == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[msg.sender] != true){ revert notAdminAddress();}
        userContractAddress = _userContractAd;
    }

    /**
        * optLocation
        * @param _userAd The app user address is expected as parameter.
        * @param _optStatus The status of opting (true or false) needs to be registered to the contract.
    */
    function optLocation(address _userAd, bool _optStatus) external {
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(!status || id != 3){ revert userContractError();}
        userOptIns[_userAd].location = _optStatus; 
        emit Location(_userAd,_optStatus);
    }

    /**
        * optNetwork
        * @param _userAd The app user address is expected as parameter.
        * @param _optStatus The status of opting (true or false) needs to be registered to the contract.
    */
    function optNetwork(address _userAd, bool _optStatus) external {
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(!status || id != 3){ revert userContractError();}
        userOptIns[_userAd].network = _optStatus; 
        emit Network(_userAd,_optStatus);
    }

    /**
        * optOuraRing
        * @param _userAd The app user address is expected as parameter.
        * @param _optStatus The status of opting (true or false) needs to be registered to the contract.
    */
    function optOuraRing(address _userAd, bool _optStatus) external {
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(!status || id != 3){ revert userContractError();}
        userOptIns[_userAd].ouraRing = _optStatus; 
        emit OuraRing(_userAd,_optStatus);
    }

    // /**
    //     *  userDataTransfer.
    //     * @param _userAd The app user address is expected as parameter.
    //     * @param _location This is a additional condition to control the user rights for location.
    //     * @param _network This is a additional condition to control the user rights for network.
    //     * @param _ouraData OuraRing data is expected as struct.
    // */
    // function userDataTransfer(address _userAd, bool _location , bool _network, ouraRingData memory _ouraData) external{
    //     if(_userAd == address(0)){ revert zeroAddressNotSupported();}
    //     if(!adminAddress[msg.sender]){ revert notAdminAddress();}
    //     UserContract useC = UserContract(userContractAddress);
    //     (bool status,uint id) = useC.verifyUser(_userAd);
    //     if(!status || id != 3){ revert userContractError();}
    //     if(!userOptIns[_userAd].location){
    //         _location = false; //parameter value changes based on optIn status
    //     }
    //     if(!userOptIns[_userAd].network){
    //         _network = false; //parameter value changes based on optIn status
    //     }
    //     optInsData memory data;
    //     data.location = _location;
    //     data.network = _network;
    //     if(userOptIns[_userAd].ouraRing){ //If ouraRing data is set true in oura function, only then data is stored.
    //         data.ouraData = _ouraData;
    //     }
    //     data.timeStamp = block.timestamp;
    //     userDataTx[_userAd].push(data);
    //     emit UserTransaction(_userAd,userDataTx[_userAd].length);
    // }

    function userDataTransfer(address _userAd, uint _packageId, uint _location, uint _network, ouraRingData memory _ouraData) 
    external{
        if(_userAd == address(0)){ revert zeroAddressNotSupported();}
        if(!adminAddress[msg.sender]){ revert notAdminAddress();}
        UserContract useC = UserContract(userContractAddress);
        (bool status,uint id) = useC.verifyUser(_userAd);
        if(!status || id != 3){ revert userContractError();}

        uint count = 0;
        count += _location;
        count += _network;
        count += _ouraData.age;
        count += _ouraData.weight;
        count += _ouraData.height;
        count += _ouraData.biologicalSex;
        count += _ouraData.bodyTemperature;
        count += _ouraData.prevDayActivity;
        count += _ouraData.restingHeartRate;
        count += _ouraData.tempDeviation;
        count += _ouraData.bedTimeStart;
        count += _ouraData.bedTimeEnd;
        count += _ouraData.timeInBed;
        count += _ouraData.avgBreath;
        count += _ouraData.avgHeartRate;
        count += _ouraData.bpm;
        count += _ouraData.source;

        optInsData memory data;
        data.location = _location;
        data.network = _network;
        data.ouraData = _ouraData;
        data.timeStamp = block.timestamp;
        userTxCount[_packageId][_userAd] = data;
        userTxValue[_packageId][_userAd] = count;
        packageValue[_packageId] += count; // package id is same but _userAd will be different.
        packageUsers[_packageId].push(_userAd); // assuming there will be no duplicate tx per user in the same package.
        emit UserTransaction(_packageId, _userAd, count);
    }

    //Read Functions:
    function userOptStatus(address _userAd) external view returns(optIns memory status){
        return userOptIns[_userAd];
    }

    function userTransferredData(address _userAd, uint _packageId) external view returns(optInsData memory data){
        return userTxCount[_packageId][_userAd];
    }

    function userTransferredDataValue(address _userAd, uint _packageId) external view returns(uint){
        return userTxValue[_packageId][_userAd];
    }

    function packageTotalValue(uint _packageId) external view returns(uint){
        return packageValue[_packageId];
    }

    function packageUserAddresses(uint _packageId) external view returns(address[] memory){
        return packageUsers[_packageId];
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