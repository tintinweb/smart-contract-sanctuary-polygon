/**
 *Submitted for verification at polygonscan.com on 2022-06-30
*/

/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

abstract contract ReentrancyGuard {
    
        uint256 private constant _NOT_ENTERED = 1;
        uint256 private constant _ENTERED = 2;

        uint256 private _status;

        constructor() {
            _status = _NOT_ENTERED;
        }

    
        modifier nonReentrant() {
            // On the first call to nonReentrant, _notEntered will be true
            require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

            // Any calls to nonReentrant after this point will fail
            _status = _ENTERED;

            _;

            // By storing the original value once again, a refund is triggered (see
            // https://eips.ethereum.org/EIPS/eip-2200)
            _status = _NOT_ENTERED;
        }
    }

contract KarbunSale is ReentrancyGuard  {
    AggregatorV3Interface internal USDpriceFeed;
    AggregatorV3Interface internal ETHpriceFeed;
    AggregatorV3Interface internal BNBpriceFeed;
    AggregatorV3Interface internal BTCpriceFeed;
    AggregatorV3Interface internal  MaticpriceFeed;
    

    uint256 usdPrice = 18;
    uint256 tokenDecimal = 18;
    address payable wallet;
    address payable KBNwallet;
    address _ETH = 0x9caA1718a213E7aA18a7ff189B662574B0fD8B05;
    address _BNB = 0x9caA1718a213E7aA18a7ff189B662574B0fD8B05;
    address token = 0x9caA1718a213E7aA18a7ff189B662574B0fD8B05;
    address _BTC = 0x9caA1718a213E7aA18a7ff189B662574B0fD8B05;

    // decimal place
    uint256 decimalPlaceForEth = 26;
    uint256 decimalPlaceForBNB = 26;
    uint256 decimalPlaceForMatic = 26;
    uint256 decimalPlaceForBTC = 26;



    constructor() {
        ETHpriceFeed = AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);
        // polygon test - DAI/USD
        BNBpriceFeed = AggregatorV3Interface(0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046);
        BTCpriceFeed = AggregatorV3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b);
        MaticpriceFeed=AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        
        // wallet = payable(msg.sender);
        KBNwallet = payable(0xF24a24Ab64a29edd50ACC655f4dd78360888A83e);
        wallet = payable(0x03539374eA1E31c48C35A48d159757492e74c81F);
    }


    modifier onlyOwner() {
        require(msg.sender == wallet,"Sender is not the Owner");
        _;
    }

    function getMaticLatestPrice() public view returns (uint256) {
    (
        uint80 roundID, 
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = MaticpriceFeed.latestRoundData();
        return uint256(price);
    }

// ------------- FUNCTION FOR CHAINLINK -------------- //
   function getETHLatestPrice() public view returns (uint256) {
    (
        uint80 roundID, 
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = ETHpriceFeed.latestRoundData();
        return uint256(price);
    }

     function getBNBLatestPrice() public view returns (uint256) {
    (
        uint80 roundID, 
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = BNBpriceFeed.latestRoundData();
        return uint256(price);
    }

     function getBTCLatestPrice() public view returns (uint256) {
    (
        uint80 roundID, 
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = BTCpriceFeed.latestRoundData();
        return uint256(price);
    }


    function setUsdPrice(uint256 price) public onlyOwner returns(bool) {
        usdPrice = price;
        return true;
    }

                                                                                                
    function BuyFromBNB(uint256 _amount) public nonReentrant {
        uint256 EthAmount = priceOfTokenInBNB(_amount);
        IERC20(_BNB).transferFrom(msg.sender,wallet,EthAmount);
        IERC20(token).transferFrom(KBNwallet,msg.sender,_amount);
    }

    function BuyFromEth(uint256 _amount) public nonReentrant{
        uint256 EthAmount = priceOfTokenInETH(_amount);
        IERC20(_BNB).transferFrom(msg.sender,wallet,EthAmount);
        IERC20(token).transferFrom(KBNwallet,msg.sender,_amount);
    }

    function BuyFromMatic(uint256 _amount) public payable nonReentrant{
        uint totalPayable= priceOfTokenInMatic(_amount);
        require(msg.value >= totalPayable,"Incorrect Amount Paid");
        payable(wallet).transfer(totalPayable);
        IERC20(token).transferFrom(KBNwallet,msg.sender,_amount);
    }   

      function BuyFromBTC(uint256 _amount) public nonReentrant {
         uint256 BTCAmount = priceOfTokenInBTC(_amount);
        IERC20(_BNB).transferFrom(msg.sender,wallet,BTCAmount);
        IERC20(token).transferFrom(KBNwallet,msg.sender,_amount);
    } 

    function priceOfTokenInMatic(uint _amount) public view returns(uint256){
        uint256 priceOfMatic= getMaticLatestPrice();
        uint256 priceOfOneToken= (usdPrice * 10 ** decimalPlaceForMatic)/priceOfMatic;
        uint256 maticPayable= priceOfOneToken * _amount / 10**18;
        return maticPayable;
    }

     function priceOfTokenInBTC(uint _amount) public view returns(uint256){
        uint256 priceOfBTC = getBTCLatestPrice();
        uint256 priceOfOneToken= (usdPrice * 10 ** decimalPlaceForBTC)/priceOfBTC;
        uint256 maticPayable= priceOfOneToken * _amount / 10**18;
        return maticPayable;
    }

     function priceOfTokenInBNB(uint _amount) public view returns(uint256){
        uint256 priceOfBNB = getBNBLatestPrice();
        uint256 priceOfOneToken= (usdPrice * 10 ** decimalPlaceForBNB)/priceOfBNB;
        uint256 maticPayable= priceOfOneToken * _amount / 10**18;
        return maticPayable;
    }


    function priceOfTokenInETH(uint _amount) public view returns(uint256){
        uint256 priceOfETH= getETHLatestPrice();
        uint256 priceOfOneToken= (usdPrice * 10 ** decimalPlaceForEth)/priceOfETH;
        uint256 maticPayable= priceOfOneToken * _amount / 10**18;
        return maticPayable;
    }

    function changeOwner(address payable _newOwner) public onlyOwner {
        wallet = _newOwner;
    }

    function changeTokenAddress(address _newaddress) public onlyOwner{
        token = _newaddress;
    }

    function changeBNBTokenAddress(address _newaddress) public onlyOwner {
        _BNB = _newaddress;
    }

    function changeETHTokenAddress(address _newaddress) public onlyOwner {
        _ETH = _newaddress;
    }

     function changeBTCTokenAddress(address _newaddress) public onlyOwner {
        _BTC = _newaddress;
    }

     function changeDecimalForETH(uint256 decimal) public onlyOwner {
        decimalPlaceForEth = decimal;
    }

     function changeDecimalForBNB(uint256 decimal) public onlyOwner {
        decimalPlaceForBNB = decimal;
    }

     function changeDecimalForBTC(uint256 decimal) public onlyOwner {
        decimalPlaceForBTC = decimal;
    }
    
     function changeDecimalForMatic(uint256 decimal) public onlyOwner {
        decimalPlaceForMatic = decimal;
    }
}