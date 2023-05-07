/**
 *Submitted for verification at polygonscan.com on 2023-05-06
*/

/**
 *Submitted for verification at Etherscan.io on 2023-04-29
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

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// interface AggregatorV3Interface {
//    function latestAnswer() external view returns (int256);
// }


contract Wallet {
    address private _owner;
    mapping(address => bool) private _operators;
    mapping(address => uint256) private _balances;
    // mapping(address => mapping(address => uint256)) private _allowances;
    int256 private _fee;
    address private _busdAddress;
    event PriceScan(int indexed price);

    // will provide chain specifc price feed.
       AggregatorV3Interface internal priceFeed;

    constructor(
        address owner,
        // address busdAddress,
        address priceFeedAddress
    ) {
        _owner = owner;
        // _busdAddress = busdAddress;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        // the price return from aggregator in unto 8 decimal point and we deduct fee of 0.99 per transaction there for we need to have 1e6
        _fee= 99 * 1e6;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    modifier onlyOperator() {
        require(_operators[msg.sender], "Not operator");
        _;
    }

    function addOperator(address operator) public onlyOwner {
        _operators[operator] = true;
    }

    function removeOperator(address operator) public onlyOwner {
        delete _operators[operator];
    }

    function setGasFee(int256 fee) public onlyOwner {
        _fee = fee;
    }

    function depositBUSD(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        IERC20(_busdAddress).transferFrom(msg.sender, address(this), amount);
        _balances[msg.sender] += amount;
    }

    function depositBUSDFor(address recipient, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        IERC20(_busdAddress).transferFrom(msg.sender, address(this), amount);
        _balances[recipient] += amount;
    }
    function depositBNB() public payable {
        require(msg.value > 0, "Value must be greater than 0");
        _balances[msg.sender] += msg.value;
    }

    function depositBNBFor(address recipient) public payable {
        require(msg.value > 0, "Value must be greater than 0");
        _balances[recipient] += msg.value;
    }

    function depositBEP20(address tokenAddress, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        _balances[msg.sender] += amount;
    }

    function depositBEP20For(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public {
        require(amount > 0, "Amount must be greater than 0");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        _balances[recipient] += amount;
    }

    function withdrawBUSD(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        // onwer fee is 0.99 $ se we need to minus this from amount and withdraw remaining amount to 
        uint256 ownerFee = 99*1e16;
        IERC20(_busdAddress).transfer(msg.sender, ownerFee);
        IERC20(_busdAddress).transfer(msg.sender, (amount - ownerFee));
    }

    function withdrawBNB(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        // get Fee Rate in native Currency
        uint256 fee  = uint256(gatFeeRate(_fee));
           // send  Fee to owner
          (bool success, bytes memory returnError) = payable(_owner).call{
            value: fee
        }("");
        require(success, string(returnError));

        // send remaining amount to mes.sender
        (bool successAmount, bytes memory returnErrorAmount) = payable(msg.sender).call{
            value: amount - fee
        }("");
        require(successAmount, string(returnErrorAmount));
    }


    /// chain link aggragtor to get price of native currency  in usd
    function gatFeeRate(int256 fee) public view returns (int256) {
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        // emit PriceScan(price);
        return (fee * 1e18)/(price);

    }
}