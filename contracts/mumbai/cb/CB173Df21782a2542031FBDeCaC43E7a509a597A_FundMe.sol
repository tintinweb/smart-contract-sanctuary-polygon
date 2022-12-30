/**
 *Submitted for verification at polygonscan.com on 2022-12-30
*/

// File: FundMe_flat.sol


// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: contracts/PriceConverter.sol


pragma solidity ^0.8.8;


library PriceConverter {
    function getPrice() internal view returns(uint) {
        // address - 0x0715A7794a1dc8e42615F059dD6e406A6594651A - eth/usd
        // 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada - matic/usd
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        (,int price,,,) = priceFeed.latestRoundData();
        return uint(price * 1e10);
    }

    function getVersion() internal view returns (uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        return priceFeed.version();
    }

    function getConversionRate(uint ethAmt) internal view returns (uint) {
        uint ethPrice = getPrice();
        uint ethAmtInUsd = (ethPrice * ethAmt) / 1e18;
        return ethAmtInUsd;
    }
}
// File: contracts/FundMe.sol


pragma solidity ^0.8.8;


error NotOwner();

contract FundMe {
    using PriceConverter for uint;
    // smart contracts can hold funds similar to wallets

    uint public constant MIN_USD = 1 * 1e18;
    address[] public funders;
    mapping(address => uint) public addressToAmtFunded;
    address public immutable i_owner;

    // constant and immutable are stored directly in contract and not in memory slot

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        // want to be able to set a min fund amnt in usd
        // 1 eth = 1 * 10 ^ 18 wei == 1e18
        require(msg.value.getConversionRate() > MIN_USD, "Not enough to fund :(");
        // 👆🏻 if the condn is reverted, undo any action above,
        // and send remaining gas back!
        funders.push(msg.sender);
        addressToAmtFunded[msg.sender] = msg.value;
    }
    
    function withdraw() public onlyOwner {
        for (uint funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            addressToAmtFunded[funders[funderIndex]] = 0;
        }

        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{ value: address(this).balance}("");
        require(callSuccess, "Call to transfer matic failed!");
    }

    modifier onlyOwner {
        // require(msg.sender == i_owner, "Sender is not owner!"); 
        if(msg.sender != i_owner) { // <- gas efficient than require
            revert NotOwner();
        }
        _;
    }

    // what happens if someone sends ETH to this contract without calling fund function?
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}