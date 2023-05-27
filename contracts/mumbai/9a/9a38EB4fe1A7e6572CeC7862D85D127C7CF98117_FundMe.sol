// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;
import "AggregatorV3Interface.sol";

contract FundMe{
    
    mapping (address => uint256) public addressToAmount;
    address[] public funders;

    function Fund() public payable {
        uint256 minimumUsd = 50 * 10 ** 18;
        require(GetUsd(msg.value)>=minimumUsd,"You need to spend more eth");
        addressToAmount[msg.sender]+= msg.value;
        funders.push(msg.sender);
    }   
    address public owner;
    constructor()  {
        owner = msg.sender;
    }
    modifier  Onlyowner  {
 require(msg.sender == owner,"You are not the owner");
    _;
    }
    function Withdraw()  payable public Onlyowner {
       
        payable(msg.sender).transfer(address(this).balance);
        for(uint256 i=0;i<funders.length;i++){
            addressToAmount[address(funders[i])] = 0;
        }
        funders = new address[](0);
    }

    function GetPrice() public view returns(uint256){
       (,int price,,,) =  AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).latestRoundData();
       return uint256(price * 10000000000);
    }

    function GetUsd(uint256 eth) public  view returns (uint256){
        uint256 ethPrice = GetPrice();
        uint256 ethAmount = (ethPrice * eth) / 1000000000000000000;
        return ethAmount; 
    }
}

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