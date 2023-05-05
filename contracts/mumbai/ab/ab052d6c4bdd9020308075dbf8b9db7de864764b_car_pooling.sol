//SPDX-License-Identifier: MIT
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
        uint256 time;
    }

    struct user{
        uint user_id;
        string name;
        uint age;
        string gender;
        string phone;
        string email;
        uint role;
        uint256 time;
    }

    mapping(address => user) public userInfo;
    mapping(uint => ride) rideInfo;
    mapping(address => ride[]) userActivity;
    mapping(address=> bool) public is_user;
    ride[] activeRides;
    mapping(address => bool) public isActiveRide;
    mapping(address => ride) public activeRide;
    mapping(address => uint) userId;
    uint256 user_id;
    uint256 ride_id;
    mapping(address => uint256) public balance;

    uint256 public costPerKM;
    address public Owner;

    IERC20 private _erc20Token;

    constructor (uint256 _cost, address erc20TokenAddress) {
        Owner = msg.sender;
        costPerKM = _cost;
        _erc20Token = IERC20(erc20TokenAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }
    modifier onlyPassenger() {
        require(userInfo[msg.sender].role == 1);
        _;
    }
    
    function setOwner(address _owner) public onlyOwner {
        Owner = _owner;
    }

    function setCostPerKM(uint256 _cost) public onlyOwner {
        costPerKM = _cost;
    }

    function setERC20Address(address _erc20Address) public onlyOwner {
        _erc20Token = IERC20(_erc20Address);
    }

    function requestTokens() public onlyPassenger {
        require(is_user[msg.sender] && msg.sender == tx.origin,"not user");
        // require(_erc20Token.balanceOf(msg.sender)<100 ether);
        _erc20Token.transfer(msg.sender,1000 ether);
    }

    function createUser(string memory name, uint age, string memory gender, string memory phone, string memory email, uint role) public {
        require(!is_user[msg.sender],"User account already exist");
        require(role>0 && role<=2,"Invalid role");
        uint _id = 1;
        if(userId[msg.sender]>0){
            _id = userId[msg.sender];
        } else {
            _id = user_id +=1;
            require(_erc20Token.transfer(msg.sender, 1000 ether),"Not Enough liquidity in pool");
        }
        userInfo[msg.sender] = user(_id,name,age,gender,phone,email,role,block.timestamp);
        userId[msg.sender] = _id;
        is_user[msg.sender] = true;
    }

    function updateUser(string memory name, uint age, string memory gender, string memory phone, string memory email, uint role) public  {
        require(is_user[msg.sender],"User account not exist");
        require(role>0 && role<=2,"Invalid role");
        uint _id = userInfo[msg.sender].user_id;
        userInfo[msg.sender] = user(_id,name,age,gender,phone,email,role,block.timestamp);
        // return("User account updated");
    }

    function requestRide(uint256 distance, string memory from,string memory to) public onlyPassenger {
        // require(userInfo[msg.sender].role==1,"the user is not a traveller");
        require(!isActiveRide[msg.sender],"User have already active ride");
        // require(msg.value>=distance*costPerKM);
        uint256 _price = (distance*costPerKM)*1 ether;
        ride_id +=1;
        rideInfo[ride_id] = ride(ride_id,address(0),msg.sender,distance,from,to,costPerKM,1,block.timestamp);
        userActivity[msg.sender].push(rideInfo[ride_id]);
        activeRides.push(rideInfo[ride_id]);
        activeRide[msg.sender] = rideInfo[ride_id];
        isActiveRide[msg.sender] = true;
        require(_erc20Token.transferFrom(msg.sender, address(this), _price), "Insufficient ERC20 balance");
        // return("ride requested");
    }

    function cancelRide(uint256 _ride_id) public  {
        require(rideInfo[_ride_id].traveller == msg.sender,"The user is not requested the ride");
        require(rideInfo[_ride_id].status == 1,"ride already accepted");
        ride memory data = rideInfo[_ride_id];
        rideInfo[_ride_id] = ride(data.id,address(0),msg.sender,data.distance,data.from,data.to,data.costPerKM,2,block.timestamp);
        userActivity[msg.sender].push(rideInfo[_ride_id]);
        delete activeRide[msg.sender];
        uint256 _balance = data.distance*data.costPerKM;
        // require(payable(msg.sender).send(_balance));
        uint256 _price = (_balance)*1 ether;
        require(_erc20Token.transfer(msg.sender, _price), "Insufficient ERC20 balance");
        isActiveRide[msg.sender] = false;
        for(uint i = 0; i <= activeRides.length; i++) {
            if(activeRides[i].id == _ride_id) {
                deleteEl(i);
                break;
            }
        }
        // return("ride cancelled");
    }

    function AcceptRide(uint256 _ride_id) public {
        require(userInfo[msg.sender].role==2,"the user is not a driver");
        require(rideInfo[_ride_id].status == 1,"ride cancelled or already accepted");
        require(!isActiveRide[msg.sender],"User have already active ride");
        require(rideInfo[_ride_id].traveller != msg.sender,"User must not be same as traveller");
        ride memory data = rideInfo[_ride_id];
        rideInfo[_ride_id].driver = msg.sender;
        rideInfo[_ride_id] = ride(data.id,msg.sender,data.traveller,data.distance,data.from,data.to,data.costPerKM,3,block.timestamp);
        userActivity[msg.sender].push(rideInfo[_ride_id]);
        userActivity[data.traveller].push(rideInfo[_ride_id]);
        activeRide[msg.sender] = rideInfo[_ride_id];
        activeRide[data.traveller] = rideInfo[_ride_id];
        isActiveRide[msg.sender] = true;
        for(uint i = 0; i <= activeRides.length; i++) {
            if(activeRides[i].id == _ride_id) {
                deleteEl(i);
                break;
            }
        }
        // return("ride accepted");
    }

    function approveRide(uint256 _ride_id) public {
        require(rideInfo[_ride_id].traveller == msg.sender,"The user is not requested the ride");
        require(rideInfo[_ride_id].status == 3,"ride cancelled or completed");
        ride memory data = rideInfo[_ride_id];
        rideInfo[_ride_id] = ride(data.id,data.driver,msg.sender,data.distance,data.from,data.to,data.costPerKM,4,block.timestamp);
        userActivity[msg.sender].push(rideInfo[_ride_id]);
        userActivity[data.driver].push(rideInfo[_ride_id]);
        uint256 _balance = data.distance*data.costPerKM;
        delete activeRide[msg.sender];
        delete activeRide[data.driver];
        isActiveRide[msg.sender] = false;
        isActiveRide[data.driver] = false;
        balance[data.driver] += _balance;
        // return("ride approved");
    }

    function claim() public  {
        require(is_user[msg.sender],"User account not exist");
        require(balance[msg.sender]>0,"Not balance to claim");
        // require(payable(msg.sender).send(balance[msg.sender]));
        uint256 bal = balance[msg.sender]*1 ether;
        require(_erc20Token.transfer(msg.sender, bal), "Insufficient ERC20 balance");
        balance[msg.sender] = 0;
        // return("claimed");
    }

    function deleteEl(uint index) internal {
        require(index <= activeRides.length, "Index out of range");
        if (index < activeRides.length - 1) {
            activeRides[index] = activeRides[activeRides.length - 1]; 
            }
            activeRides.pop();
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

    function getActiveRides() public view returns(ride[] memory) {
        return activeRides;
    }

    function deleteUser() public returns(string memory){
        require(is_user[msg.sender],"User account not exist");
        is_user[msg.sender] = false;
        delete userInfo[msg.sender];
        return("user deleted");
    }
    
}