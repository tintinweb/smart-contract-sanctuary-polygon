/**
 *Submitted for verification at polygonscan.com on 2023-06-11
*/

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


contract Shieldpay {
    address private _owner;
    int256 private _fee;
    // will provide chain specifc price feed.
    AggregatorV3Interface internal priceFeed;

    error ZeroAmountSent();
    error NotOwner();

    constructor(
        address owner,
        address priceFeedAddress
    ) {
        _owner = owner;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        _fee= 99 * 1e6;
    }

    modifier onlyOwner() {
        if(msg.sender != _owner) revert  NotOwner();
        _;
    }

    function setGasFee(int256 fee) public onlyOwner {
        _fee = fee;
    }

       function setNewOwner(address owner) public onlyOwner {
        _owner = owner;
    }

 
   function transfer(address receipent) public payable {
        if(msg.value == 0) revert ZeroAmountSent();
        uint256 fee  = uint256(getFeeRate());
           // send  Fee to owner
          (bool success, bytes memory returnError) = payable(_owner).call{
            value: fee
        }("");
        require(success, string(returnError));

        // send remaining amount to mes.sender
        (bool successAmount, bytes memory returnErrorAmount) = payable(receipent).call{
            value: (msg.value - fee)
        }("");
        require(successAmount, string(returnErrorAmount));
    }

    /// chain link aggragtor to get price of native currency  in usd
    function getFeeRate() private view returns (int256) {
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        // emit PriceScan(price);
        return (_fee * 1e18)/(price);

    }
}