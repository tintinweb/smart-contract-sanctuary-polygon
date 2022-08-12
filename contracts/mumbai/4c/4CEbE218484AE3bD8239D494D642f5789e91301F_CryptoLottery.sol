// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./ChainLinkOracle.sol";

contract CryptoLottery is ChainLinkOracle {
  
  uint public _round_interval;
  uint public _ticket_price;

  uint public _max_five_numbers;
  uint public _max_last_number;

  enum RoundStatus {Progress, End, Start}

  mapping(uint => Ticket[]) public _tickets;

  Round[] public _rounds;
  
  constructor(
    uint round_interval, 
    uint ticket_price,
    uint max_five_numbers,
    uint max_last_number
    ) {
   _round_interval = round_interval;
   _ticket_price = ticket_price;
   _max_five_numbers = max_five_numbers;
   _max_last_number = max_last_number; 
  }
  
  struct Round {
    uint startTime;
    uint endTime;
    RoundStatus status;
  }

  struct Ticket {
    address owner;
    uint[] numbers;
    uint win;
  }
  
  
  function createRound () public {
    
    if(_rounds.length > 0 && _rounds[_rounds.length - 1].status != RoundStatus.End) {
      revert("Error: the last round in progress");
    }
 
    Round memory round = Round( 
        block.timestamp,
        block.timestamp + _round_interval,
        RoundStatus.Start
    );

    _rounds.push(round);
  
  }

  function buyTicket(uint[] memory _numbers) external payable  {
    require(_ticket_price == msg.value, "not valid value");
  
    Ticket memory ticket = Ticket(
      msg.sender,
      _numbers,
      0
    );

    _tickets[_rounds.length - 1].push(ticket);
  }

  function getTickets (uint id) external view returns (Ticket[] memory tickets){
      return _tickets[id];
  }
 
  function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(
         block.difficulty, 
         block.timestamp,
         _tickets[_rounds.length - 1].length,
         getLatestPrice()
       )));
  }

  function getPrice() public view returns(int256){
     int256 price = getLatestPrice();
     return price;
  }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./AggregatorV3Interface.sol";

contract ChainLinkOracle {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: BTC
     * Aggregator: BTC/USD
     * Address: 0x007A22900a3B98143368Bd5906f8E17e9867581b
     */

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x007A22900a3B98143368Bd5906f8E17e9867581b
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price,
            ,
            ,

        ) = /*uint startedAt*/
            /*uint timeStamp*/
            /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        return price;
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