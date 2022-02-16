/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

/**
 *Submitted for verification at polygonscan.com on 2021-10-07
 */

/**
 *Submitted for verification at polygonscan.com on 2021-09-14
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

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
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  // function name() external view returns (string memory);
  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  // function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint256); //owner: userAddress

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool); //check allowance

  function permit(
    address owner,
    address spender,
    uint256 rawAmount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

contract NewPool is Ownable {
  using SafeMath for uint256;
  // address public token; //Token address (BITEPOINT, BITE)
  address public gift_token;
  // address public exchangeToken;
  address public walletAddress;
  // address public deployedContractAddress = address(this);

  // margin percentage
  uint256 private margin_int = 0;
  uint256 private margin_decimals = 1;
  
  // list of token addresses
  address[] private tokenAddresses;
  // map token address to bool
  // mapping(address => bool) public baseTokens;
  
  // map data feed contract address to bool
  // mapping(address => bool) public isInstantiation;
  
  // map token address to data feed contract address
  // mapping(address => address) public dataFeedContractAddress;

  uint256 private _gift_amount_nominator = 5;
  uint256 private _gift_amount_denominator = 1;

  // path from bite to usdt on quickswap
  // address[] private path;

  //Events
  event ContractInstantiation(address instantiation, address token);
  event Deposit(
    address indexed from,
    address indexed to,
    uint256 value,
    uint256 orderId
  );
  event Gift(
    address indexed from,
    address indexed to,
    uint256 value,
    uint256 orderId
  );
  event Withdraw(
    address indexed from,
    address indexed to,
    address token_address,
    uint256 value
  );

  constructor() {
    // address _gift_token
    // gift_token = _gift_token;
    // address gift_token = '';

    //the wallet for withdraw money
    walletAddress = msg.sender; 

    tokenAddresses.push(address(gift_token));
  }

  // power function
  function pow(uint256 base, uint256 exponent) private pure returns (uint256) {
    if (exponent == 0) {
      return 1;
    } else if (exponent == 1) {
      return base;
    } else if (base == 0 && exponent != 0) {
      return 0;
    } else {
      uint256 z = base;
      for (uint256 i = 1; i < exponent; i++) z = SafeMath.mul(z, base);
      return z;
    }
  }

  // set the percentage markup
  function setMargin(uint256 margin, uint256 decimals) public onlyOwner {
    require(decimals > 0, "DECIMAL CANNOT BE 0");
    require(
      margin < SafeMath.mul(3, pow(10, SafeMath.sub(decimals, 1))),
      " Margin CANNOT BE HIGHER THAN 30%"
    );
    margin_int = margin;
    margin_decimals = decimals;
  }

  // get the percentage markup
  function getMargin() public view onlyOwner returns (uint256, uint256) {
    return (margin_int, margin_decimals);
  }

  function abs(int256 x) private pure returns (int256) {
    return x >= 0 ? x : -x;
  }

  function pos(int256 x) private pure returns (bool) {
    return x > 0 ? true : false;
  }

  // struct ExchangeInfo {
  //   uint256 exchangeAmount;
  //   uint256 fee;
  //   address dataFeedContract;
  //   uint256 exchangeRate;
  // int256 decimalsBaseTokens;
  
  //   int256 decimalsExchangeTokens;
  //   int256 decimalsPair;

  //   int256 decimalsConversionValue;
  //   uint256 exp;
  //   bool isPositive;
  //   uint256 userBalance;
  //   uint256 exchangeTokenBalance;
  // }

  // function getExchangeRateInfo(address baseToken)
  //   public
  //   view
  //   returns (uint256, int256)
  // {
  //   // e.g. BITE > RISE OR GET ER for ETH v.s.RISE
  //   ExchangeInfo memory eInfo;
  //   eInfo.dataFeedContract = dataFeedContractAddress[baseToken];
  //   eInfo.exchangeRate = uint256(
  //     PriceConsumerV3(eInfo.dataFeedContract).getLatestPrice()
  //   );
  //   eInfo.decimalsPair = int8(
  //     PriceConsumerV3(eInfo.dataFeedContract).getDecimals()
  //   );
  //   return (eInfo.exchangeRate, eInfo.decimalsPair);
  // }

  // function computeExchangeAmount(
  //   ExchangeInfo memory eInfo,
  //   address baseToken,
  //   uint256 amount
  // ) internal view {
  //   // get decimals for exchangeToken
  //   eInfo.decimalsExchangeTokens = int8(IERC20(baseToken).decimals()); //exchangeToken

  //   // check chainlink for conversion rate
  //   eInfo.dataFeedContract = dataFeedContractAddress[baseToken];
  //   eInfo.exchangeRate = uint256(
  //     PriceConsumerV3(eInfo.dataFeedContract).getLatestPrice()
  //   );
  //   eInfo.decimalsPair = int8(
  //     PriceConsumerV3(eInfo.dataFeedContract).getDecimals()
  //   );

  //   // conversion (safemath cannot be applied to int)
  //   eInfo.decimalsConversionValue = eInfo.decimalsBaseTokens - eInfo.decimalsExchangeTokens +eInfo.decimalsPair;

  //   assert(eInfo.decimalsConversionValue < 50); // assert the outcome is not weird
  //   eInfo.exp = uint256(abs(eInfo.decimalsConversionValue));
  //   eInfo.isPositive = pos(eInfo.decimalsConversionValue);

  //   // compute exchange amount based on exchange rate and adjust for the difference in decimals
  //   if (eInfo.isPositive) {
  //     eInfo.exchangeAmount = amount.mul(eInfo.exchangeRate).div(
  //       pow(10, eInfo.exp)
  //     );
  //   } else {
  //     eInfo.exchangeAmount = amount.mul(eInfo.exchangeRate).mul(
  //       pow(10, eInfo.exp)
  //     );
  //   }

  //   // compute transation fee and subtract from exchangeAmount
  //   eInfo.fee = eInfo.exchangeAmount.mul(margin_int).div(
  //     pow(10, margin_decimals)
  //   );
  //   eInfo.exchangeAmount = eInfo.exchangeAmount.sub(eInfo.fee);

  //   // conversion
  //   eInfo.exchangeTokenBalance = balanceOfExchangeToken(baseToken); // no token as param
  //   require(
  //     eInfo.exchangeTokenBalance >= eInfo.exchangeAmount,
  //     "CONTRACT_HAS_INSUFFICIENT_TOKEN_IN_POOL"
  //   );
  // }

  function getGiftToken() public view returns (address addr) {
     return gift_token;
  }

  function setGiftToken(address giftTokenAddress) public onlyOwner {
    gift_token = giftTokenAddress;
  }

  //update deposit walletaddress from the owner
  function updateWalletAddress(address poolV2WalletAddress) public onlyOwner {
    walletAddress = poolV2WalletAddress;
  }

  // get the tokens that supports (READ)
  function getSupportedTokenAddresses() public view returns (address[] memory) {
    address[] memory supportedTokenAddresses = new address[](tokenAddresses.length);

    for (uint256 i = 0; i < tokenAddresses.length; i++) {
      supportedTokenAddresses[i] = tokenAddresses[i];
    }
    return supportedTokenAddresses;
  }

  function setSupportedTokenAddresses(address[] memory _tokenAddresses) public onlyOwner{
    for (uint i = 0 ; i < _tokenAddresses.length ; i++){
        address token_address = _tokenAddresses[uint(i)];
        //check whether token_address is exsit
        if( !checkTokenAddressExists(token_address)){ 
        tokenAddresses.push(token_address);
        }
    }
  }

  function checkTokenAddressExists(address token_address)
    internal
    view
    returns (bool)
  {
    bool exists = false;
    for (uint256 i = 0; i < tokenAddresses.length; i++) {
      if (tokenAddresses[i] == token_address) {
        exists = true;
      }
    }
    return exists;
  }

  // for registering data feed contracts
  // function register(address instantiation, address token) internal {
  //   isInstantiation[instantiation] = true;
  //   dataFeedContractAddress[token] = instantiation;
  //   emit ContractInstantiation(instantiation, token);
  // }

  // function setDataFeedContractAddress(
  // address[] memory _baseTokens,
  
  //   address[] memory _dataFeedLinkPairAddress
  // ) public onlyOwner {

  //   // length check
  //   require(
      // _baseTokens.length == _dataFeedLinkPairAddress.length,
  
  //     "Length of Input Does Not Match"
  // );


  //   // A list of acceptable token addresses
  // for (uint256 i = 0; i < _baseTokens.length; i++) {
  
  //     //baseToken >>> token you want to add (baseToken, dataFeedlinkPairAddress)
  // 
      
  // address token_address = _baseTokens[uint256(i)];
  
  //     address dataFeedLinkPairAddress = _dataFeedLinkPairAddress[uint256(i)];
  // store token address // check if exist first

  //     if (!checkTokenAddressExists(token_address)) {
  //       //add new tokenPair if not exists
  //       tokenAddresses.push(token_address);
  //     }
  //     // enable token to be exchanged
      // baseTokens[token_address] = true;


      // create data feed contracts for monitoring price
  
  //     address contractAddress = address(
  //       new PriceConsumerV3(dataFeedLinkPairAddress)
  //     );

  //     // register data feed contracts creation
  //     register(contractAddress, token_address);

  //     // enable base token for exchangeForToken
      // baseTokens[token_address] = true;
  
  //   }
  // }


  // update walletAddress
  function setSpenderWalletAddress(address addr) public onlyOwner {
    walletAddress = addr;
  }

  function getSpenderWalletAddress() public view returns (address value) {
    return walletAddress;
  }

  function _sendGiftToken(
    uint256 amount,
    address sender,
    uint256 orderId
  ) private {
    uint256 _gift_amount = amount.mul(_gift_amount_nominator).div(
      _gift_amount_denominator
    );
    uint256 _gift_balance = IERC20(gift_token).balanceOf(address(this));
    require(_gift_balance >= _gift_amount, "Pool: INSUFFICIENT GIFT TOKEN");
    IERC20(gift_token).transfer(sender, _gift_amount);

    //give user Bite for free
    emit Gift(sender, address(this), _gift_amount, orderId); //from, to, amount, orderId
  }

  function depositForToken(
    address token,
    uint256 amount,
    uint256 orderId,
    address sender
  ) public {
    // get token balance
    uint256 balance = IERC20(token).balanceOf(sender); // check token balance
    require(balance >= amount, "Pool: INSUFFICIENT_INPUT_AMOUNT");

    // get token allowance
    uint256 allowance = IERC20(token).allowance(address(sender), address(this)); //owner, spender this: POOL
    require(allowance >= amount, "INSUFFICIENT_ALLOWANCE");

    // check gift_token balance
    // transfer gift_token from contract to sender
    _sendGiftToken(amount, sender, orderId);

    // transfer token from sender to contract
    IERC20(token).transferFrom(sender, address(this), amount); //(V1)

    // emit Events
    emit Deposit(sender, address(this), amount, orderId);
  }

  function _sendGiftTokenV2(uint256 amount, uint256 orderId) private {
    //100x5/1
    uint256 _gift_amount = amount.mul(_gift_amount_nominator).div(
      _gift_amount_denominator
    );
    // check exisit gt balance in pool
    uint256 _gift_balance = IERC20(gift_token).balanceOf(address(this));
    require(_gift_balance >= _gift_amount, "Pool: INSUFFICIENT GIFT TOKEN");
    IERC20(gift_token).transfer(msg.sender, _gift_amount);
    //RISE send gift_token to sender in $amount)

    //give user Bite for free
    emit Gift(msg.sender, address(this), _gift_amount, orderId); //from, to, value, orderId
  }

  function depositForTokenV2(
    address token,
    uint256 amount,
    uint256 orderId
  ) public {
    // create a strct to store data in memory
    // ExchangeInfo memory eInfo;
    
    // To check whether token is accepted
    for (uint i = 0; i< tokenAddresses.length; i++){
      address token_address = token;
      bool isSupported = checkTokenAddressExists(token_address);
      require(isSupported == true, "Pool: NOT SUPPORTED TOKEN FOR PAYMENT");
    }

    // get token balance
    uint256 balance = IERC20(token).balanceOf(msg.sender); // check user token balance
    require(balance >= amount, "Pool: INSUFFICIENT_INPUT_AMOUNT");

    // get token allowance
    uint256 allowance = IERC20(token).allowance(
      address(msg.sender),
      address(this)
    ); //owner, spender this: POOL
    require(allowance >= amount, "INSUFFICIENT_ALLOWANCE");

    // check gift_token balance + transfer gift_token from contract to sender
    _sendGiftTokenV2(amount, orderId);

    // compute exchange amount
    // computeExchangeAmount(eInfo, token, amount);

    IERC20(token).transferFrom(msg.sender, address(walletAddress), amount); //(V2)

    // emit Events
    emit Deposit(msg.sender, address(walletAddress), amount, orderId);
  }

  function depositForNativeToken(
    uint256 amount,
    uint256 orderId,
    address sender
  ) public payable {
    // get token balance <= native token
    require(msg.value >= amount, "Pool: INSUFFICIENT_BALANCE");

    _sendGiftToken(amount, msg.sender, orderId);

    payable(walletAddress).transfer(amount);

    emit Deposit(sender, address(this), amount, orderId);
  }

  function depositForNativeTokenV2(
    address token,
    uint256 amount,
    uint256 orderId
  ) public payable {
    // To check whether token is accepted
    for (uint i = 0; i< tokenAddresses.length; i++){
      address token_address = token;
      bool isSupported = checkTokenAddressExists(token_address);
      require(isSupported == true, "Pool: NOT SUPPORTED TOKEN FOR PAYMENT");
    }

    // get token balance <= native token
    require(msg.value >= amount, "Pool: INSUFFICIENT_BALANCE");

    // transfer gift_token from contract to sender (shareable)
    _sendGiftToken(amount, msg.sender, orderId);

    // transfer token from sender to contract
    payable(walletAddress).transfer(amount);

    emit Deposit(msg.sender, address(this), amount, orderId);
  }

  function setGiftTokenPercent(uint256 nominator, uint256 denominator)
    public
    onlyOwner
  {
    _gift_amount_nominator = nominator;
    _gift_amount_denominator = denominator;
  }

  function getGiftTokenPercent()
    public
    view
    onlyOwner
    returns (uint256, uint256)
  {
    return (_gift_amount_nominator, _gift_amount_denominator);
  }

  // Withdraw token from address(this) to new wallet address
  function withdrawBaseToken(address baseToken) public payable onlyOwner {
    uint256 balance = 0;
    if (baseToken == address(0)) {
      // Get token balance 
      balance = address(this).balance;
      payable(walletAddress).transfer(balance);
    } else {
      // Get baseToken balance 
      balance = IERC20(baseToken).balanceOf(address(this));

      IERC20(baseToken).transfer(walletAddress, balance);
    }
    emit Withdraw(address(this), walletAddress, baseToken, balance);
  }

  function withdrawGiftToken() public {
    uint256 balance = IERC20(gift_token).balanceOf(address(this));
    IERC20(gift_token).transfer(walletAddress, balance);
    emit Withdraw(address(this), walletAddress, gift_token, balance);
  }

  // Get Ether balance of this contract
  function balanceOfNativeToken() public view returns (uint256 amount) {
    uint256 balance = address(this).balance;
    return balance;
  }

  // Get specific token balance in this contract
  function balanceOfToken(address token) public view returns (uint256 amount) {
    uint256 balance = IERC20(token).balanceOf(address(this)); //this: Pool contract
    return balance;
  }

  function balanceOfExchangeToken(address token) public view returns (uint256) {
    uint256 balance = IERC20(token).balanceOf(address(this));
    return balance;
  }

  function balanceOfGiftToken() public view returns (uint256 amount) {
    uint256 balance = IERC20(gift_token).balanceOf(address(this));
    return balance;
  }
}