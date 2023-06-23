// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DataTypesDemo {
    // Basic data types
    uint256 public myUint;
    // myUint()
    int256 public myInt;
    bool public myBool;
    address public myAddress; // 20 bytes
    string public myString;
    uint256 public constant myUintConstant = 101;
    address public immutable myImmutableAddress;

    // Events for fallback and receive functions
    event FallbackCalled(string message);
    event ReceiveCalled(string message);

    event ChangedBasicData(
        uint256 myUint,
        int256 myInt,
        bool myBool,
        address myAddress,
        string myString
    );

    // Enum type
    enum Status { Pending, Active, Completed }
    Status public myStatus;

    // Mapping type
    mapping(address => uint256) public balances;

    // Struct type
    struct User {
        string name;
        uint256 age;
    }

    mapping(uint256 => User) public users;
    
    uint256 public userCount;

    constructor() {
        myImmutableAddress = msg.sender; //0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    }

    // Set immutable address -> error
    // function setImmutable(address _myImmutableAddress) public {
    //     myImmutableAddress = _myImmutableAddress;
    // }

    // Set basic data types
    function setBasicDataTypes(
        uint256 _myUint,
        int256 _myInt,
        bool _myBool,
        address _myAddress,
        string memory _myString
    ) public {
        
        myUint = _myUint;
        myInt = _myInt;
        myBool = _myBool;
        myAddress = _myAddress;
        myString = _myString;

        emit ChangedBasicData(
            myUint,
            myInt,
            myBool,
            myAddress,
            myString
        );
    }

    // Set enum type
    function setMyStatus(Status _myStatus) public {
        myStatus = _myStatus;
    }

    // Update mapping type
    function updateBalance(address _account, uint256 _balance) public {
        balances[_account] = _balance;
    }

    // Add a new user using the struct type
    function addUser(string memory _name, uint256 _age) public {
        userCount = 1;
        users[userCount] = User(_name, _age);
    }

    // Payable function that returns the amount of Ether transferred
    function deposit() public payable returns (uint256) {
        return msg.value;
    }

    // call data 0xa9059cbb000000000000000000000000ececa1dab1fa867192ba95424b49139cd0c148e4000000000000000000000000000000000000000000000000000000000bebc200
    // Fallback function that emits an event with a message
    fallback() external payable {
        emit FallbackCalled("It is fallback");
    }

    // transact just some amount without calling any function
    // Receive function that emits an event with a message
    receive() external payable {
        emit ReceiveCalled("It is receive");
    }
}