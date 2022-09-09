//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

import "./goFundMe.sol";
import "./IFundMe.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error reverted();

contract FundMeFactory {

    address private owner;

    uint256 balance;

    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        } else {
            revert notOwner();
        }
    }

    event newContract(string Name, address Addr);

    constructor() 
    {
        owner = msg.sender;
       
    }
    
    receive()external payable{
        balance+=msg.value;
    }

    function generateFundMe(
        address _owner,
        uint256 _amount,
        string calldata _name
    ) external returns (address) 
    {
        goFundMe child = new goFundMe();
        child.initializer(_owner, _amount, _name);
        emit newContract(_name, address(child));
        return address(child);
    }

    function withdraw(uint256 _amount)external onlyOwner
    {
        if(_amount>balance) revert reverted();
        balance-=_amount;
        (bool sent, )=payable(owner).call{value: _amount}("");
        if(!sent) revert reverted();
    }

    function getLatestPrice(uint256 _amountUSD) external view returns (uint) {
         /**
         * MATIC/USD MUMBAI TESTNET
         */
        AggregatorV3Interface priceFeed= AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        uint256 conversion= (_amountUSD*1e26)/uint256(price);
        return conversion;
    }

    function callBalance(address addr)external view returns(uint256){
        IFundMe child= IFundMe(addr);
        return child.getBalance();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error invalidState();
error notFactory();
error notOwner();
error failed();

contract goFundMe {
    address immutable factory;
    address public owner;

    uint256 public balance;
    uint256 public amountNeeded;
    uint256 public totalReceived;

    string public Name;


    struct funders {
        address funder;
        uint amount;
    }

    enum State {
        StandBy,
        Funding,
        Completed
    }

    State public state;

    funders[] private fundersList;

    modifier onlyFactory() {
        if (msg.sender == factory) {
            _;
        } else {
            revert notFactory();
        }
    }

    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        } else {
            revert notOwner();
        }
    }

    modifier inState(State state_) {
        if (state == state_) {
            _;
        } else {
            revert invalidState();
        }
    }

    constructor() {
        factory = msg.sender;
    }

    receive() external payable inState(State.Funding) 
    {
        if ((totalReceived + msg.value) < amountNeeded) {
            balance += msg.value;
            totalReceived += msg.value;
            fundersList.push(funders({funder: msg.sender, amount: msg.value}));
        } else {
            revert failed();
        }
    }

    function startFunding() external onlyOwner inState(State.StandBy) 
    {
        state = State.Funding;
    }

    function endFunding() external onlyOwner inState(State.Funding) 
    {
        state = State.Completed;
    }

    function pullFunds(uint256 _amount)
        external
        onlyOwner
        inState(State.Completed)
    {
        if(_amount > balance) revert failed();
        balance -= _amount;
        uint256 fee = (_amount*5)/100;
        (bool sent, ) = payable(owner).call{value: (_amount-fee)}("");
        (bool sentFee, )= payable(factory).call{value: fee}("");
        if (!(sent && sentFee)) revert failed();
    }

    function getBalance() external view returns (uint256) 
    {
        return balance;
    }

    function getAmountNeeded() external view returns(uint256)
    {
        return amountNeeded;
    }

    function getFunders() external view returns (funders[] memory) 
    {
        return fundersList;
    }

    function name() external view returns(string memory)
    {
        return Name;
    }

    function initializer(address _owner, uint256 _amount,string calldata _name) external onlyFactory 
    {
        owner = _owner;
        amountNeeded = _amount;
        Name = _name;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFundMe {
    function getBalance() external view returns (uint256) ;
    function initializer(address _owner, uint256 _amount,string calldata _name) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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