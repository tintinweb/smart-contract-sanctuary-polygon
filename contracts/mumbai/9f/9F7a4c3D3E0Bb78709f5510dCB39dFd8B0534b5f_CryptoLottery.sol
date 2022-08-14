// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "./ChainLinkOracle.sol";

contract CryptoLottery is ChainLinkOracle {
    uint256 public _round_interval;
    uint256 public _ticket_price;

    enum RoundStatus {
        Progress,
        End,
        Start
    }

    mapping(uint256 => Ticket[]) public _tickets;

    Round[] public _rounds;

    constructor(uint256 round_interval, uint256 ticket_price) {
        _round_interval = round_interval;
        _ticket_price = ticket_price;
    }

    struct Round {
        uint256 startTime;
        uint256 endTime;
        RoundStatus status;
        uint256[] combination;
    }

    struct Ticket {
        address owner;
        uint256[] numbers;
        uint256 win;
    }

    function createRound() public {
        if (
            _rounds.length > 0 &&
            _rounds[_rounds.length - 1].status != RoundStatus.End
        ) {
            revert("Error: the last round in progress");
        }

        uint256[] memory _combination;

        Round memory round = Round(
            block.timestamp,
            block.timestamp + _round_interval,
            RoundStatus.Start,
            _combination
        );

        _rounds.push(round);
    }

    function buyTicket(uint256[] memory _numbers) external payable {
        require(_ticket_price == msg.value, "not valid value");

        Ticket memory ticket = Ticket(msg.sender, _numbers, 0);

        _tickets[_rounds.length - 1].push(ticket);
    }

    function _random() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        _tickets[_rounds.length - 1].length,
                        getLatestPrice()
                    )
                )
            );
    }

    function _last_combination() public {
        for (uint256 i = 0; i < 6; i++) {
            if (i < 5) {
                uint256 _number = _random() % 69;
                _rounds[_rounds.length - 1].combination.push(_number + 1);
            } else {
                uint256 _number = _random() % 26;
                _rounds[_rounds.length - 1].combination.push(_number + 1);
            }
        }
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