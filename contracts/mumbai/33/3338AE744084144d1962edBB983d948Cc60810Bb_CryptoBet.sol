// SPDX-License-Identifier: MIT
/*
@author Aayush Gupta. Twiiter: @Aayush_gupta_ji Github: AAYUSH-GUPTA-coder
 */
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NOT_Enough_MATIC_IN_CONTRACT();
error NOT_ENOUGH_RANGE();
error FUND_NOT_SEND();
error SEND_EFFICIENT_MATIC();

contract CryptoBet {
    AggregatorV3Interface internal priceFeedETH;
    address payable owner;

    /**
     * Network: Mumbai Testnet
     * Aggregator: ETH / USD
     * Address: 0x0715A7794a1dc8e42615F059dD6e406A6594651A
     */
    constructor() {
        priceFeedETH = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );
        owner = payable(msg.sender);
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

    // amount should be less than contract_Balance / 1.5
    modifier notEnoughMatic(uint256 _amount) {
        if ((_amount * 15) / 10 >= getBalance()) {
            revert NOT_Enough_MATIC_IN_CONTRACT();
        }
        _;
    }

    // amount of the Matic send be greater or equal to amount specified
    modifier sendEnoughMatic(uint256 _amount) {
        if (_amount >= msg.value) {
            revert SEND_EFFICIENT_MATIC();
        }
        _;
    }

    // get the contract balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // placing bet with simple up and down
    function placeBetUPDown(uint256 _amount, bool _isUp)
        public
        payable
        notEnoughMatic(_amount)
        sendEnoughMatic(_amount)
    {
        // amount should be less than contract_Balance / 2
        // if (_amount < getBalance() / 2) {
        //     revert Not_Enough_MATIC();
        // }
        // if (_amount > msg.value) {
        //     revert SEND_EFFICIENT_MATIC();
        // }
        uint256 price = uint256(getLatestPriceETH());
        // new predicted value should be +- 0.1 % of existing value
        // 2040 % 0.1 = 2.04
        // valid newvalue > 2042, (2040 + 2.04) or
        // newvalue < 2037.96 , (2040 - 2.04)
        uint256 marginValue = (price * 1) / 1000;
        uint256 winningValueUp = price + marginValue;
        uint256 winningValueDown = price - marginValue;
        uint256 betTimeStamp = block.timestamp;
        if (block.timestamp > (betTimeStamp + 1 hours)) {
            if (price >= winningValueUp && _isUp == true) {
                sendWinningAmount(msg.sender, _amount);
            }
            if (price <= winningValueDown && _isUp == false) {
                sendWinningAmount(msg.sender, _amount);
            }
        }
    }

    // sending winning amount to winner
    function sendWinningAmount(address winner, uint256 _amount) private {
        (bool sent, ) = payable(winner).call{value: (_amount * 15) / 10}("");
        if (!sent) {
            revert FUND_NOT_SEND();
        }
    }

    // withdraw the money to the owner account
    function withdraw() external {
        uint256 amount = address(this).balance;
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
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