// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// User should be able to deposit minimum funds in term of USD to the contract
// Only owner should be able to withdraw funds

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    // Minimum USD to Deposit
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 50_000000000000000000
    address[] public funders;
    address public immutable owner;
    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    constructor(address _priceFeed) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    mapping(address => uint256) public addressToFundMap;

    function fund() public payable {
        require(
            msg.value.getCoversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough funds"
        );
        addressToFundMap[msg.sender] = msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        // Reset the Funders Array and Map
        for (uint256 j = 0; j < funders.length; j++) {
            address funder = funders[j];
            addressToFundMap[funder] = 0;
        }
        // Reset the array
        funders = new address[](0);
        //Transfer the funds
        (bool ok, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(ok, "Tx Failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData(); // Price 8 Decimal
        return uint256(price * 1e10); // price -> (8 decimal * 1e10) (3_00000000 * 1_0000000000)
    }

    function getCoversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed); // 3000_000000000000000000
        uint256 ethPriceInUSD = (_ethAmount * ethPrice) / 1e18; // (1_000000000000000000 * 3000_000000000000000000) 1e36 / 1e18 -> 1e2
        return ethPriceInUSD;
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