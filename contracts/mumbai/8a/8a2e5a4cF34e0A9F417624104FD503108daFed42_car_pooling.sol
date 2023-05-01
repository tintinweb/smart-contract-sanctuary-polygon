//SPDX-License-Identifier: Unlicensed
import "./IERC20.sol";
pragma solidity >=0.8.0;
contract car_pooling {

    struct ride {
        uint id;
        address driver;
        address traveller;
        uint distance;
        string from;
        string to;
        uint256 costPerKM;
        uint256 status;
    }

    struct user {
        uint user_id;
        string name;
        uint age;
        string gender;
        string phone;
        string email;
        uint role;
    }
    
    mapping(address => user) public userInfo;
    mapping(address => uint) public userRole; // 1 = traveller, 2 = driver
    mapping(uint => ride) public rideInfo;
    mapping(address => ride[]) public userActivity;
    mapping(address=> bool) public is_user;
    mapping(uint256 => uint) public rideStatus;
    mapping(address => uint) userId;
    mapping(uint => uint[]) activeRides;
    uint256 user_id;
    uint256 ride_id;

    uint256 public costPerKM;
    address public Owner;

    IERC20 private _erc20Token;

    constructor (uint256 _cost, address erc20TokenAddress) {
        Owner = msg.sender;
        costPerKM = _cost;
        _erc20Token = IERC20(erc20TokenAddress);
    }



    function setOwner(address _owner) public {
        require(Owner == msg.sender, "No access");
        Owner = _owner;
    }

    function setCostPerKM(uint256 _cost) public {
        require(Owner == msg.sender, "No access");
        costPerKM = _cost;
    }

    function setERC20Address(address _erc20Address) public {
        require(Owner == msg.sender, "No Access");
        _erc20Token = IERC20(_erc20Address);
    }

    function forceTransaction(uint256 _rideId, uint _type) public  { // approve : 1, cancel : 2
        require(Owner == msg.sender, "No Access");
        ride memory data = rideInfo[_rideId];
        require(data.status ==3,"Ride not active");
        uint statusId = _type == 1? 4:2;
        rideInfo[_rideId] = ride(_rideId,data.driver,data.traveller,data.distance,data.from,data.to,data.costPerKM,statusId);
        userActivity[data.traveller].push(rideInfo[_rideId]);
        userActivity[data.driver].push(rideInfo[_rideId]);
        uint256 _balance = data.distance*data.costPerKM;
        // require(payable(data.driver).send(_balance));
        uint256 _price = (_balance)*1 ether;
        address rUser = _type == 1?data.driver:data.traveller;
        require(_erc20Token.transferFrom(address(this), rUser, _price), "Insufficient ERC20 balance");
    }
    

    function createUser(string memory name, uint age, string memory gender, string memory phone, string memory email, uint role) public returns(string memory) {
        require(!is_user[msg.sender],"User account already exist");
        require(role>0 && role<=2,"Invalid role");
        uint _id = 1;
        if(userId[msg.sender]>0){
            _id = userId[msg.sender];
        } else {
            _id = user_id +=1;
        }
        userInfo[msg.sender] = user(_id,name,age,gender,phone,email,role);
        userId[msg.sender] = _id;
        is_user[msg.sender] = true;
        return("User account created");
    }

    function updateUser(string memory name, uint age, string memory gender, string memory phone, string memory email, uint role) public returns(string memory) {
        require(is_user[msg.sender],"User account not exist");
        require(role>0 && role<=2,"Invalid role");
        uint _id = userInfo[msg.sender].user_id;
        userInfo[msg.sender] = user(_id,name,age,gender,phone,email,role);
        return("User account updated");
    }

    function requestRide(uint256 distance, string memory from,string memory to) public returns(string memory){
        require(is_user[msg.sender],"User account not exist");
        require(userInfo[msg.sender].role==1,"the user is not a traveller");
        // require(msg.value>=distance*costPerKM);
        uint256 _price = (distance*costPerKM)*1 ether;
        require(_erc20Token.transferFrom(msg.sender, address(this), _price), "Insufficient ERC20 balance");
        ride_id +=1;
        rideInfo[ride_id] = ride(ride_id,address(0),msg.sender,distance,from,to,costPerKM,1);
        userActivity[msg.sender].push(rideInfo[ride_id]);
        activeRides[1].push(ride_id);
        return("ride requested");
    }

    function cancelRide(uint256 _ride_id) public returns(string memory){
        require(is_user[msg.sender],"User account not exist");
        require(userInfo[msg.sender].role==1,"the user is not a traveller");
        require(rideInfo[_ride_id].traveller == msg.sender,"The user is not requested the ride");
        require(rideInfo[_ride_id].status == 1,"ride already accepted");
        ride memory data = rideInfo[_ride_id];
        rideInfo[_ride_id] = ride(_ride_id,address(0),msg.sender,data.distance,data.from,data.to,data.costPerKM,2);
        userActivity[msg.sender].push(rideInfo[_ride_id]);
        uint256 _balance = data.distance*data.costPerKM;
        // require(payable(msg.sender).send(_balance));
        uint256 _price = (_balance)*1 ether;
        require(_erc20Token.transferFrom(address(this), msg.sender, _price), "Insufficient ERC20 balance");
        return("ride cancelled");
    }

    function AcceptRide(uint256 _ride_id) public returns(string memory){
        require(is_user[msg.sender],"User account not exist");
        require(userInfo[msg.sender].role==2,"the user is not a driver");
        require(rideInfo[_ride_id].status == 1,"ride cancelled or already accepted");
        ride memory data = rideInfo[_ride_id];
        rideInfo[_ride_id] = ride(_ride_id,msg.sender,data.traveller,data.distance,data.from,data.to, data.costPerKM,3);
        userActivity[msg.sender].push(rideInfo[_ride_id]);
        userActivity[data.traveller].push(rideInfo[_ride_id]);
        return("ride accepted");
    }

    function completeRide(uint256 _ride_id) public returns(string memory){
        require(is_user[msg.sender],"User account not exist");
        require(userInfo[msg.sender].role==1,"the user is not a traveller");
        require(rideInfo[_ride_id].traveller == msg.sender,"The user is not requested the ride");
        require(rideInfo[_ride_id].status == 3,"ride not accepted yet or already completed");
        ride memory data = rideInfo[_ride_id];
        rideInfo[_ride_id] = ride(_ride_id,data.driver,msg.sender,data.distance,data.from,data.to,data.costPerKM,4);
        userActivity[msg.sender].push(rideInfo[_ride_id]);
        userActivity[data.driver].push(rideInfo[_ride_id]);
        uint256 _balance = data.distance*data.costPerKM;
        // require(payable(data.driver).send(_balance));
        uint256 _price = (_balance)*1 ether;
        require(_erc20Token.transferFrom(address(this), data.driver, _price), "Insufficient ERC20 balance");
        return("ride completed");
    }

    function getUserActivities(address _user) public view returns(ride[] memory) {
        require(is_user[_user],"User account not exist");
        // return userActivity[_user];
        ride[] memory userActivities = userActivity[_user];
        uint length = userActivities.length;
        ride[] memory reversedArray = new ride[](length);
        uint j = 0;
        for(uint i = length; i >= 1; i--) {
            reversedArray[j] = userActivities[i-1];
            j++;
        }
        return reversedArray;
    }

    function deleteUser() public returns(string memory){
        require(is_user[msg.sender],"User account not exist");
        is_user[msg.sender] = false;
        delete userInfo[msg.sender];
        return("user deleted");
    }
}