// SPDX-License-Identifier: UNLICENCE

pragma solidity ^0.8.0;
interface AggregatorV3Interface {

  function decimals() external view returns ( uint8);
  function description()external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData( uint80 _roundId)external view returns ( uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
  function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

}

contract Ownable {
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

interface IRate {
    function getIRA_USDT() external view returns(uint256 iraprice,uint8 decimal);
}
// mumbai testnet 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada

// mainnet 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0

contract Rate is Ownable {

    AggregatorV3Interface internal priceFeed;
    uint8 public usdDecimal=8;
    uint256 public IRA_USDT = 100000000;

    bool public isEnableChainLink=false;

    address public priceAddress=address(0);

    constructor()
    {
        
    }

    function getIRA_USDT() external view returns(uint256 iraprice ,uint8 decimal){
        if(isEnableChainLink)
        {
            (,int price,,uint timeStamp,)= priceFeed.latestRoundData();
            // If the round is not complete yet, timestamp is 0
            require(timeStamp > 0, "Round not complete");
            iraprice = (uint256)(price);
            decimal = usdDecimal;
        }else
        {
            iraprice = IRA_USDT;
            decimal = usdDecimal;
        }       

    }

    function updateIRA_USDT(uint256 _irausd,uint8 _decimal) external onlyOwner {
        IRA_USDT = _irausd;
        usdDecimal = _decimal;
    }

    function EnableChainLink(bool _isEnable) external onlyOwner {      
      isEnableChainLink = _isEnable;
    }

    function updatePriceAddress(address _priceAddress) external onlyOwner {
        // enable here Matic Rate here
        priceAddress = _priceAddress;
        priceFeed = AggregatorV3Interface(_priceAddress);
        usdDecimal = priceFeed.decimals();
    }

}