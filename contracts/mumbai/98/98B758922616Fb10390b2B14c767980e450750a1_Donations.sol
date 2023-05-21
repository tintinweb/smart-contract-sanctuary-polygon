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

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Donations {
    struct Donor {
        uint256 ethDonation;
        uint256 usdDonation;
        uint256 timestamp;
        string name;
    }
    // 1819,783790820000000000
    mapping(address => Donor[]) public donorHistory;
    Donor[] public donorsList;
    AggregatorV3Interface internal priceFeed;

    constructor() {
        // Replace this with the actual Chainlink price feed for ETH/USD
        priceFeed = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );
    }

    function donate(string memory _name) external payable {
        uint256 ethAmount = msg.value;
        uint256 usdAmount = getEthToUsdPrice(ethAmount);

        Donor memory newDonor = Donor({
            ethDonation: ethAmount,
            usdDonation: usdAmount,
            timestamp: block.timestamp,
            name: _name
        });

        donorHistory[msg.sender].push(newDonor);
        donorsList.push(newDonor);
    }

    function getEthToUsdPrice(
        uint256 ethAmount
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 ethToUsdPrice = uint256(price) * (10 ** 10);
        return (ethAmount * ethToUsdPrice) / 1e18;
    }

    function getETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price feed");
        uint256 priceValue = uint256(price) * (10 ** 10);
        return priceValue;
    }

    function getTotalDonationsInEth(
        address donor
    ) external view returns (uint256) {
        Donor[] memory donations = donorHistory[donor];
        uint256 totalDonations = 0;

        for (uint256 i = 0; i < donations.length; i++) {
            totalDonations += donations[i].ethDonation;
        }

        return totalDonations;
    }

    function getTotalDonationsInUsd(
        address donor
    ) external view returns (uint256) {
        Donor[] memory donations = donorHistory[donor];
        uint256 totalDonations = 0;

        for (uint256 i = 0; i < donations.length; i++) {
            totalDonations += donations[i].usdDonation;
        }

        return totalDonations;
    }

    function getDonars() public view returns (Donor[] memory) {
        return donorsList;
    }
}
// 1817,685262650000000000
// 1817,685262650000000000
// 3639353373440000000000000000000000000000