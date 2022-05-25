// SPDX-License-Identifier: MIT
/*
@author Aayush Gupta. Twiiter: @Aayush_gupta_ji Github: AAYUSH-GUPTA-coder
 */
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error NOT_ENOUGH_MATIC_IN_CONTRACT();
error FUND_NOT_SEND();
error SEND_EFFICIENT_MATIC();
error FAILED_TO_SEND_ETHER_TO_OWNER();
error BET_UPKEEP_NOT_NEEDED();

contract CryptoBet is KeeperCompatibleInterface {
    AggregatorV3Interface internal priceFeedETH;
    address payable private immutable owner;
    uint256 private immutable entryAmount;
    uint256 private immutable interval;
    uint256 private lastTimeStamp;
    address payable[] private upBetAddresses;
    address payable[] private downBetAddresses;
    uint private lastTimeStampPrice;
    uint256 private marginValue;
    uint256 private winningValueUp;
    uint256 private winningValueDown;

    /**
     * Network: Mumbai Testnet
     * Aggregator: ETH / USD
     * Address: 0x0715A7794a1dc8e42615F059dD6e406A6594651A
     */
    constructor(uint256 _updateInterval, uint256 _entryAmount) {
        priceFeedETH = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );
        owner = payable(msg.sender);
        // chainlink keepers to update and excute placeBetUPDown function
        // interval after function will execute
        interval = _updateInterval;
        lastTimeStamp = block.timestamp;
        entryAmount = _entryAmount;
    }

    

    // eth/usd = $2,040.62
    //  2,040.52,871,350 / 100000000 = 2040

    /**
     * Returns the latest price
     */
    function getLatestPriceETH() public view returns (int256) {
        (, int256 price, , , ) = priceFeedETH.latestRoundData();
        return price / 100000000;
        //2040
    }

    /* Events */
    event EnterDownBet(address indexed player);
    event EnterUpBet(address indexed player);
    event BetEnter(address indexed player);
    event Winner(string winner);
    event Perform_UpKeep();
    event ExecutePlaceBet(string message);

    //  event Log(address indexed sender, string message);

    // amount should be less than contract_Balance / 2
    modifier notEnoughMaticInContract() {
        if ((entryAmount * 2) >= getBalance()) {
            revert NOT_ENOUGH_MATIC_IN_CONTRACT();
        }
        _;
    }

    // amount of the Matic send be greater or equal to amount specified
    modifier sendEnoughMatic() {
        if (entryAmount >= msg.value) {
            revert SEND_EFFICIENT_MATIC();
        }
        _;
    }

    // function to get last timestamp Price;
    function setLastTimeStampPrice() public {
        lastTimeStampPrice = uint(getLatestPriceETH());
        marginValue = (lastTimeStampPrice * 1) / 1000; // 0.01
        winningValueUp = lastTimeStampPrice + marginValue;
        winningValueDown = lastTimeStampPrice - marginValue;
    }
    

    // function to place Bet for price going Up
    function placeBetUp()
        public
        payable
        notEnoughMaticInContract
        sendEnoughMatic
    {
        upBetAddresses.push(payable(msg.sender));
        setLastTimeStampPrice();
        emit EnterUpBet(msg.sender);
        emit BetEnter(msg.sender);
    }

    // function to place Bet for price going down
    function placeBetDown()
        public
        payable
        notEnoughMaticInContract
        sendEnoughMatic
    {
        downBetAddresses.push(payable(msg.sender));
        setLastTimeStampPrice();
        emit EnterDownBet(msg.sender);
        emit BetEnter(msg.sender);
    }

    // Include a checkUpkeep function that contains the logic that will be executed off-chain to see if performUpkeep should be executed.
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool timePassed = ((block.timestamp - lastTimeStamp) > interval); // keep track of betting
        bool hasPlayers = upBetAddresses.length > 0 ||
            downBetAddresses.length > 0;
        upkeepNeeded = (timePassed && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    // function to send MATIC to the winners
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        // this is the way to get checkUpKeep function. we only need 1 parameter, therefore (bool upkeepNeede, ) next is blank.
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert BET_UPKEEP_NOT_NEEDED();
        }
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval) {
            executePlaceBet();
            lastTimeStamp = block.timestamp;
        }
        emit Perform_UpKeep();
    }

    // placing bet with simple up and down
    function executePlaceBet() private {
        // uint256 price = uint256(getLatestPriceETH());
        uint256 latestPrice = uint256(getLatestPriceETH());

        if (latestPrice >= winningValueUp) {
            sendWinningAmount(upBetAddresses);
            emit Winner("Up");
        }
        else if (latestPrice < winningValueDown) {
            sendWinningAmount(downBetAddresses);
            emit Winner("Down");
        } 
        else{
            emit Winner("None");
        }
        emit ExecutePlaceBet("DONE");
        upBetAddresses = new address payable[](0);
        downBetAddresses = new address payable[](0);
    }

    // sending winning amount to winner
    function sendWinningAmount(address payable[] memory winner) private {
        for (uint256 i = 0; i < winner.length; i++) {
            address payable winneraddr = winner[i];
            (bool sent, ) = (winneraddr).call{value: (entryAmount * 2)}("");
            if (!sent) {
                revert FUND_NOT_SEND();
            }
        }
    }

    // withdraw the matic to the owner account
    function withdraw() external {
        uint256 amount = address(this).balance;
        (bool sent, ) = owner.call{value: amount}("");
        if (!sent) {
            revert FAILED_TO_SEND_ETHER_TO_OWNER();
        }
    }

    // GETTER FUNCTION

    // get the contract balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // length of UP Bettor
    function getLengthOfUpBettors() public view returns (uint256) {
        return upBetAddresses.length;
    }

    // length of Down Bettor
    function getLengthOfDownBettors() public view returns (uint256) {
        return downBetAddresses.length;
    }

    // entry fees
    function getEntranceFee() public view returns (uint256) {
        return entryAmount;
    }

    // get time interval
    function getInterval() public view returns (uint256) {
        return interval;
    }

    // get UP bettor by index
    function getUpBettor(uint256 index) public view returns (address) {
        return upBetAddresses[index];
    }

    // get down bettor by index
    function getDownBettor(uint256 index) public view returns (address) {
        return downBetAddresses[index];
    }

    // get all UP bettor addresses
    function getUpBettor() public view returns (address payable[] memory) {
        return upBetAddresses;
    }

    // get all Down bettor addresses
    function getDownBettor() public view returns (address payable[] memory) {
        return downBetAddresses;
    }

    // get owner of the contract
    function getOwner() public view returns (address) {
        return owner;
    }

    // get lasttimestamp
    function getLastTimeStamp() public view returns (uint256) {
        return lastTimeStamp;
    }

    // get time left to execute performUpkeep
    function getTimeLeft() public view returns (uint256) {
        return ((lastTimeStamp + interval) - block.timestamp);
    }

    // get last timestamp price
    function getLastTimeStampPrice() public view returns(uint256) {
        return lastTimeStampPrice;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
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