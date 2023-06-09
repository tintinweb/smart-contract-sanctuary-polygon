// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Uncomment this line to use console.log
//import "hardhat/console.sol";

contract Payment {
    AggregatorV3Interface internal priceFeed;
    address splitAddress;
    address owner;

    event Withdrawal(uint256 amount, address addr);
    event TopUpEvent(uint256 amount, address addr);
    event createUser(string user, address addr);
    event GroupCreation(string groupName, address creator);
    event UserPayment(uint256 amount, string message, address creator, address payer, bool status, uint256 id);
    event updateUserPayment(uint256 id, address payer, bool status);
    event RaisePayment(
        uint256 amount,
        string message,
        address creator,
        address[] payerList,
        bool status,
        uint256 id,
        uint256 deadline,
        uint256 amountRaised
    );
    event updateRaisePayment(uint256 id, uint256 amountRaised, bool status, address addr);
    event requestUserEvent(address user, uint256 amount, address creator, uint256 status, uint256 id);
    event updateUserEvent(uint256 id, uint256 status);
    event updateWUserEvent(uint256 id, uint256 status);

    uint256 public payCounter;
    uint256 raiseCounter;
    uint256 requestId;

    mapping(string => address) public UserToAddr;
    mapping(address => string) public AddrToUser;
    mapping(string => address[]) public GroupsAddr;
    mapping(uint256 => PayLink) public idToPayLink;
    mapping(uint256 => RaisePay) public idToRaiseLink;
    mapping(uint256 => Request) public idToRequest;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => bool)) public approval;

    struct PayLink {
        uint256 amount;
        string message;
        address creator;
        address payer;
        bool status;
        uint256 id;
    }

    struct RaisePay {
        uint256 amount;
        string message;
        address creator;
        address[] payerList;
        bool status;
        uint256 id;
        uint256 deadline;
        uint256 amountRaised;
    }

    struct Request {
        uint256 amount;
        address user;
        address creator;
        uint256 status;
        uint256 id;
    }

    constructor(address addr) {
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        owner = addr;
    }

    /**
     * Returns the latest price.
     */
    function getLatest() public view returns (uint256) {
        // prettier-ignore
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        //int256 price = 77285014;
        uint256 result = (uint256(price * 10000000000));

        return result;
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice(uint256 amount) public view returns (uint256) {
        // prettier-ignore
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        //int256 price = 77285014;
        uint256 result = (((amount * 10 ** 18) / uint256(price * 10000000000)));

        return result;
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /*   
    * Set Username 
    */
    function setUsername(string calldata username) external {
        require(bytes(username).length > 3, "username too short");
        string memory user = _toLower(username);
        if (UserToAddr[username] == msg.sender) {
            delete UserToAddr[user];
            delete AddrToUser[msg.sender];
        }

        require(UserToAddr[user] == address(0), "Username has been taken");

        UserToAddr[user] = msg.sender;
        AddrToUser[msg.sender] = user;
        emit createUser(user, msg.sender);
    }

    /*   
    * Create Group
    */
    function createAddressGroup(address[] calldata group, string calldata name) external {
        string memory gname = _toLower(name);
        require(group.length > 0, "Group cannot be empty");
        require(bytes(name).length > 0, "No group name");

        require(GroupsAddr[gname].length == 0, "Group name has been taken");
        GroupsAddr[gname] = group;
        emit GroupCreation(name, msg.sender);
    }

    /*   
    * TopUp
    */

    function topUp() public payable {
        balances[msg.sender] = balances[msg.sender] + msg.value;
        emit TopUpEvent(msg.value, msg.sender);
    }

    /*   
    * Update balance
    */
    function updateBalance(address sender, address receiver, uint256 amount) public {
        require(msg.sender == splitAddress, "check");

        balances[sender] = balances[sender] - amount;
        balances[receiver] = balances[receiver] + amount;
    }

    function setAddr(address addr) public {
        require(msg.sender == owner);
        splitAddress = addr;
    }

    /*   
    * Withdraw from wallet
    */
    function withdraw(address addr, uint256 amount) public {
        require(msg.sender == addr, "Only owner can access");
        uint256 balance = balances[addr];
        require(balance >= amount, "Insuficient balance");

        balances[addr] = balances[addr] - amount;
        (bool success,) = (addr).call{value: amount}("");
        require(success, "Failed to send Matic");
        emit Withdrawal(amount, addr);
    }

    /*   
    * Create Payment Link for a customer
    */
    function createPay(string memory message, uint256 amount) public {
        uint256 maticAmount = uint256(getLatestPrice(amount));
        PayLink memory payl = PayLink(maticAmount, message, msg.sender, address(0), false, payCounter);
        idToPayLink[payCounter] = payl;
        emit UserPayment(maticAmount, message, msg.sender, address(0), false, payCounter);
        payCounter++;
    }

    /*   
    * Customer Pays with Payment Link 
    */
    function acceptPay(uint256 id) public payable {
        uint256 amount = idToPayLink[id].amount;
        address collector = idToPayLink[id].creator;
        require(msg.value >= amount, "Insufficient balance");
        idToPayLink[id].payer = msg.sender;
        idToPayLink[id].status = true;

        balances[collector] = balances[collector] + amount;
        emit updateUserPayment(id, msg.sender, true);
    }

    /*   
    * Create Payment Link for fundraising
    */

    function createRaisePay(string memory message, uint256 amount, uint256 dead) public {
        uint256 deadline = block.timestamp + dead;
        uint256 maticAmount = uint256(getLatestPrice(amount));
        address[] memory payerList;
        RaisePay memory raise = RaisePay(maticAmount, message, msg.sender, payerList, false, raiseCounter, deadline, 0);
        idToRaiseLink[raiseCounter] = raise;
        emit RaisePayment(maticAmount, message, msg.sender, payerList, false, raiseCounter, deadline, 0);
        raiseCounter++;
    }

    /*   
    * Fund Raising
    */
    function fundPay(uint256 id) public payable {
        require(idToRaiseLink[id].deadline > block.timestamp, "deadline exceeded");
        address collector = idToRaiseLink[id].creator;
        idToRaiseLink[id].payerList.push(msg.sender);

        idToRaiseLink[id].amountRaised = idToRaiseLink[id].amountRaised + msg.value;
        if (idToRaiseLink[id].amountRaised >= idToRaiseLink[id].amount) {
            idToRaiseLink[id].status = true;
        }

        balances[collector] = balances[collector] + msg.value;
        emit updateRaisePayment(id, idToRaiseLink[id].amountRaised, idToRaiseLink[id].status, msg.sender);
    }

    function fundData(uint256 id) public view returns (RaisePay memory) {
        return idToRaiseLink[id];
    }

    function getGroupAddr(string memory name) public view returns (address[] memory) {
        return GroupsAddr[name];
    }

    /*   
    * Request money from a user with username
    */
    function requestUser(string memory user, uint256 amount) public {
        require(UserToAddr[_toLower(user)] != address(0), "User does not exist");
        uint256 maticAmount = uint256(getLatestPrice(amount));
        Request memory req = Request(maticAmount, UserToAddr[_toLower(user)], msg.sender, 0, requestId);

        idToRequest[requestId] = req;

        emit requestUserEvent(UserToAddr[_toLower(user)], maticAmount, msg.sender, 0, requestId);
        requestId++;
    }

    /*   
    * Accept or reject request for money
    */
    function acceptRequestUser(uint256 id, uint256 paystatus) public {
        address user = idToRequest[id].user;
        require(user != address(0), "User does not exist");
        if (paystatus == 1) {
            idToRequest[id].status = 1;
            uint256 amount = idToRequest[id].amount;
            require(balances[msg.sender] >= amount, "Insufficient Wallet balance");
            balances[msg.sender] = balances[msg.sender] - amount;
            balances[user] = balances[user] + amount;
        } else {
            idToRequest[id].status = 2;
        }
        emit updateUserEvent(id, paystatus);
    }

    /*   
    * Request money from a user with address
    */
    function requestAddress(address user, uint256 amount) public {
        uint256 maticAmount = uint256(getLatestPrice(amount));
        Request memory req = Request(maticAmount, user, msg.sender, 0, requestId);

        idToRequest[requestId] = req;

        emit requestUserEvent(user, maticAmount, msg.sender, 0, requestId);
        requestId++;
    }

    /*   
    * Accept or reject request for money
    */
    function acceptRequestAddr(uint256 id, uint256 paystatus) public {
        if (paystatus == 1) {
            idToRequest[id].status = 1;
            address user = idToRequest[id].user;
            uint256 amount = idToRequest[id].amount;

            require(user != address(0), "Zero Address");
            require(balances[msg.sender] >= amount, "Insufficient Wallet balance");
            balances[msg.sender] = balances[msg.sender] - amount;
            balances[user] = balances[user] + amount;
        } else {
            idToRequest[id].status = 2;
        }
        emit updateUserEvent(id, paystatus);
    }

    /*   
    * send money to another user
    */

    function sendToUser(string memory user, uint256 amount) public {
        require(UserToAddr[_toLower(user)] != address(0), "User does not exist");
        uint256 maticAmount = uint256(getLatestPrice(amount));
        require(balances[msg.sender] >= maticAmount, "Insufficient Wallet balance");
        balances[msg.sender] = balances[msg.sender] - maticAmount;
        balances[UserToAddr[_toLower(user)]] = balances[UserToAddr[_toLower(user)]] + maticAmount;
    }

    /*   
    * send money to another user
    */
    function sendToAddress(address user, uint256 amount) public {
        require(user != address(0));
        uint256 maticAmount = uint256(getLatestPrice(amount));
        require(balances[msg.sender] >= maticAmount, "Insufficient Wallet balance");
        balances[msg.sender] = balances[msg.sender] - maticAmount;
        balances[user] = balances[user] + maticAmount;
    }

    /*   
    * send a specific amount to a group of users
    */
    function sendToGroupD(string calldata groupName, uint256 amount) external {
        address[] memory group = GroupsAddr[groupName];
        uint256 maticAmount = uint256(getLatestPrice(amount));

        uint256 totalAmount = maticAmount * group.length;
        require(balances[msg.sender] >= totalAmount, "Insufficient Wallet balance");

        for (uint256 i = 0; i < group.length; i++) {
            balances[msg.sender] = balances[msg.sender] - maticAmount;
            balances[group[i]] = balances[group[i]] + maticAmount;
        }
    }

    /*   
    * send a specific amount to a group of users
    */
    function sendToGroupM(string calldata groupName, uint256 amount) external {
        address[] memory group = GroupsAddr[groupName];
        uint256 totalAmount = amount * group.length;
        require(balances[msg.sender] >= totalAmount, "Insufficient Wallet balance");

        for (uint256 i = 0; i < group.length; i++) {
            balances[msg.sender] = balances[msg.sender] - amount;
            balances[group[i]] = balances[group[i]] + amount;
        }
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}