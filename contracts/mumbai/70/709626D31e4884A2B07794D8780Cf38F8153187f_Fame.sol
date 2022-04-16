// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Fame {

    bool internal locked;
    modifier noReentrant() {
        require(!locked, "Method's locked");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: You are not the owner, Bye.");
        _;
    }

    address public owner;
    uint256 public timeThreshold;
    uint256 public valueThreshold;

    address payable currentUser;
    uint256 public currentValue;
    uint256 public lastTimeStamp;
    string public text;
    mapping(address => uint256) public balances;

    uint256 public contractFund;

    struct Data {
        string text;
        uint256 value;
        uint256 timeStamp;
    }

    constructor() {

        owner = msg.sender;
        timeThreshold = 3; // seconds
        // valueThreshold = 1e18;
        valueThreshold = 1;
        
        currentUser = payable(owner);
        currentValue = 0;
        lastTimeStamp = block.timestamp;
        balances[owner] = 0;
        text = "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks.";
    }

    function isThresholdPassed() private view returns (bool) {
        return block.timestamp >= lastTimeStamp + timeThreshold;
    }

    function updateText(string calldata newText) external payable noReentrant {

        require(isThresholdPassed(), "Too soon!");
        require(msg.value >= currentValue + valueThreshold, "Not enough dough!");

        contractFund += msg.value - currentValue;

        balances[msg.sender] += msg.value;
        currentValue = msg.value;

        // address lastUser = currentUser;
        currentUser = payable(msg.sender);

        text = newText;
        lastTimeStamp = block.timestamp;
        // returnBalanceOfPreviousOwner(lastUser);
    }

    // function returnBalanceOfPreviousOwner(address receiver) internal{

    //     uint256 amountToSend = balances[receiver];
    //     balances[receiver] = 0;
    //     (bool sent, ) = receiver.call{value: amountToSend}("");
    //     if(sent){
    //         delete balances[msg.sender];
    //     } else {
    //         balances[receiver] = amountToSend;
    //     }
    // }

    function withdraw() external noReentrant {
        require(currentUser != payable(msg.sender), "You are currently the owner of the message!");

        uint256 balance = balances[msg.sender];
        require(balance > 0, "You have no money in this contract!");

        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "Transaction failed!");

        delete balances[msg.sender];
    }

    function withdrawContractFunds() external onlyOwner{
        (bool sent, ) = owner.call{value: contractFund}("");
        require(sent, "Transaction failed!");
        contractFund = 0;
    }

    function getData() public view returns(Data memory) {
        return Data(text, currentValue, lastTimeStamp);
    }

}

// Use safem math!
// update owner -> OppenZappline onwner contract
// get balance?
// ERC20 withdrawal?
// ReentrancyGuard contract
// fallback() external payable => balances[msg.sender] += msg.value;