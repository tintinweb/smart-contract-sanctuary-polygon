// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./PriceFeed.sol";

contract Game is AutomationCompatibleInterface {
    Player public winner;
    string public winnerName;
    int public winnerRange;
    address public winnerAddress;

    PriceFeed internal priceFeed;

    uint public players;
    uint public ticketPrice;

    uint public counter;

    uint public period;
    uint public start;

    bool public paused = true;

    event playerAdded(string _name, uint _choice);

    struct Player {
        string name;
        address wallet;
        uint choice;
        int open;
        int close;
        int range;
    }

    struct Coin {
        int open;
        int close;
    }

    mapping(uint => Player) public counterToPlayer;
    mapping(uint => Coin) public choiceToCoin;

    constructor(
        address _priceFeed,
        uint _players,
        uint _ticketPrice,
        uint _period
    ) {
        priceFeed = PriceFeed(_priceFeed);
        players = _players;
        ticketPrice = _ticketPrice;
        period = _period;
    }

    function getPlayersInformation(
        uint _counter
    ) public view returns (string memory, uint, int, int, int) {
        string memory name = counterToPlayer[_counter].name;
        uint choice = counterToPlayer[_counter].choice;
        int open = counterToPlayer[_counter].open;
        int close = counterToPlayer[_counter].close;
        int range = counterToPlayer[_counter].range;
        return (name, choice, open, close, range);
    }

    function takePart(
        string calldata _name,
        uint _choice
    ) public returns (Player memory) {
        Player memory user = Player(_name, msg.sender, _choice, 0, 0, 0);

        counter += 1;
        counterToPlayer[counter] = user;

        emit playerAdded(_name, _choice);

        return user;
    }

    function startGame() public {
        uint option;
        int response;
        for (uint i = 1; i < counter + 1; i++) {
            option = counterToPlayer[i].choice;
            response = optionToOpenPrice(option);
            counterToPlayer[i].open = response;
        }
        start = block.timestamp;
        paused = false;
    }

    function optionToOpenPrice(uint _option) public returns (int) {
        int response;
        if (_option == 1) {
            if (choiceToCoin[1].open != 0) {
                response = choiceToCoin[1].open;
            } else {
                response = priceFeed.getBTCLatestPrice();
                choiceToCoin[1].open = response;
            }
        } else if (_option == 2) {
            if (choiceToCoin[2].open != 0) {
                response = choiceToCoin[2].open;
            } else {
                response = priceFeed.getETHLatestPrice();
                choiceToCoin[2].open = response;
            }
        } else if (_option == 3) {
            if (choiceToCoin[3].open != 0) {
                response = choiceToCoin[3].open;
            } else {
                response = priceFeed.getLINKLatestPrice();
                choiceToCoin[3].open = response;
            }
        } else if (_option == 4) {
            if (choiceToCoin[4].open != 0) {
                response = choiceToCoin[4].open;
            } else {
                response = priceFeed.getMATICLatestPrice();
                choiceToCoin[4].open = response;
            }
        } else if (_option == 5) {
            if (choiceToCoin[5].open != 0) {
                response = choiceToCoin[5].open;
            } else {
                response = priceFeed.getSANDLatestPrice();
                choiceToCoin[5].open = response;
            }
        } else if (_option == 6) {
            if (choiceToCoin[6].open != 0) {
                response = choiceToCoin[6].open;
            } else {
                response = priceFeed.getSOLLatestPrice();
                choiceToCoin[6].open = response;
            }
        }
        return response;
    }

    function optionToClosePrice(uint _option) public returns (int) {
        int response;
        if (_option == 1) {
            if (choiceToCoin[1].close != 0) {
                response = choiceToCoin[1].close;
            } else {
                response = priceFeed.getBTCLatestPrice();
                choiceToCoin[1].close = response;
            }
        } else if (_option == 2) {
            if (choiceToCoin[2].close != 0) {
                response = choiceToCoin[2].close;
            } else {
                response = priceFeed.getETHLatestPrice();
                choiceToCoin[2].close = response;
            }
        } else if (_option == 3) {
            if (choiceToCoin[3].close != 0) {
                response = choiceToCoin[3].close;
            } else {
                response = priceFeed.getLINKLatestPrice();
                choiceToCoin[3].close = response;
            }
        } else if (_option == 4) {
            if (choiceToCoin[4].close != 0) {
                response = choiceToCoin[4].close;
            } else {
                response = priceFeed.getMATICLatestPrice();
                choiceToCoin[4].close = response;
            }
        } else if (_option == 5) {
            if (choiceToCoin[5].close != 0) {
                response = choiceToCoin[5].close;
            } else {
                response = priceFeed.getSANDLatestPrice();
                choiceToCoin[5].close = response;
            }
        } else if (_option == 6) {
            if (choiceToCoin[6].close != 0) {
                response = choiceToCoin[6].close;
            } else {
                response = priceFeed.getSOLLatestPrice();
                choiceToCoin[6].close = response;
            }
        }
        return response;
    }

    function endGame() public {
        uint option;
        int response;
        for (uint i = 1; i < counter + 1; i++) {
            option = counterToPlayer[i].choice;
            response = optionToClosePrice(option);
            counterToPlayer[i].close = response;
        }
        paused = true;
        calculateRange();
    }

    function calculateRange() public {
        int first;
        int second;
        for (uint i = 1; i < counter + 1; i++) {
            first = counterToPlayer[i].open;
            second = counterToPlayer[i].close;
            counterToPlayer[i].range = (((second - first) * 1e18) / first);
        }
        pickWinner();
    }

    function pickWinner() public returns (Player memory) {
        int bestRange;
        int secondRange;
        Player memory potentialWinner = counterToPlayer[1];
        for (uint i = 1; i < counter; i++) {
            bestRange = potentialWinner.range;
            secondRange = counterToPlayer[i + 1].range;
            if (secondRange > bestRange) {
                potentialWinner = counterToPlayer[i + 1];
            }
        }
        winner = potentialWinner;
        winnerName = potentialWinner.name;
        winnerRange = potentialWinner.range;
        winnerAddress = potentialWinner.wallet;

        return winner;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded =
            ((block.timestamp - start) > period) &&
            (paused == false);
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - start) > period) {
            // helper +=1;
            endGame();
        }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getTimestamp() public view returns (uint) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Game.sol";

contract Hub {
    uint public games;
    uint public totalGames;

    address public priceFeed;

    constructor(address _priceFeed) {
        priceFeed = _priceFeed;
    }

    event gameCreated(
        uint _players,
        uint _ticketPrice,
        address _newGame,
        uint _period,
        address _deployer
    );

    function createGame(
        uint _players,
        uint _ticketPrice,
        uint _period
    ) public returns (address _newGame) {
        Game newGame = new Game(priceFeed, _players, _ticketPrice, _period);
        emit gameCreated(
            _players,
            _ticketPrice,
            address(newGame),
            _period,
            msg.sender
        );
        totalGames += 1;
        return address(newGame);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceFeed {
    AggregatorV3Interface internal BTCpriceFeed;
    AggregatorV3Interface internal ETHpriceFeed;
    AggregatorV3Interface internal LINKpriceFeed;
    AggregatorV3Interface internal MATICpriceFeed;
    AggregatorV3Interface internal SANDpriceFeed;
    AggregatorV3Interface internal SOLpriceFeed;

    constructor() {
        BTCpriceFeed = AggregatorV3Interface(
            0x007A22900a3B98143368Bd5906f8E17e9867581b
        );
        ETHpriceFeed = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );
        LINKpriceFeed = AggregatorV3Interface(
            0x1C2252aeeD50e0c9B64bDfF2735Ee3C932F5C408
        );
        MATICpriceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
        SANDpriceFeed = AggregatorV3Interface(
            0x9dd18534b8f456557d11B9DDB14dA89b2e52e308
        );
        SOLpriceFeed = AggregatorV3Interface(
            0xEB0fb293f368cE65595BeD03af3D3f27B7f0BD36
        );
    }

    function getBTCLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = BTCpriceFeed.latestRoundData();
        return price;
    }

    function getETHLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ETHpriceFeed.latestRoundData();
        return price;
    }

    function getLINKLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = LINKpriceFeed.latestRoundData();
        return price;
    }

    function getMATICLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = MATICpriceFeed.latestRoundData();
        return price;
    }

    function getSANDLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = SANDpriceFeed.latestRoundData();
        return price;
    }

    function getSOLLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = SOLpriceFeed.latestRoundData();
        return price;
    }
}