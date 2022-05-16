// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./INFTSaleFactory.sol";
import "./IKommunitasStaking.sol";
import "./IKommunitasStakingV2.sol";
import "./TransferHelper.sol";

contract NFTSale {
  INFTSaleFactory public immutable factory = INFTSaleFactory(msg.sender);

  address public owner = tx.origin;
  
  bool private initialized;
  bool public isPaused;

  enum StakingChoice { V1, V2 }

  uint64 public calculation;
  uint64 public start;
  uint64 public end;
  uint16 public nftType;
  uint32 public nftTotalSale;
  uint16 public fee_d2; // in percent 2 decimal

  uint128 public minKom;
  uint128 public feeMoved;

  uint128 public raised; // sale amount get
  uint128 public revenue; // fee amount get

  IERC20 public payment;
  address[] public buyers;

  struct Detail{
    uint128 sale;
    uint128 price;
  }

  struct Invoice{
    uint32 buyersIndex;
    uint16 nftTypeBought;
    uint64 boughtAt;
    uint128 received;
    uint128 bought;
    uint128 charged;
  }

  mapping(uint16 => Detail) public nft;
  mapping(address => Invoice[]) public invoices;
  mapping(address => string) public recipient;
  mapping(uint16 => uint128) public nftSold;
  mapping(address => mapping(uint16 => uint128)) public userBought;

  mapping(address => uint128) private userAllocation;

  modifier onlyOwner{
    require(msg.sender == owner, "!owner");
    _;
  }
    
  modifier isNotPaused{
    require(!isPaused, "paused");
    _;
  }

  modifier isOnGoing{
    require(uint64(block.timestamp) >= start && uint64(block.timestamp) <= end, "!start");
    _;
  }

  event NFTBought(uint16 indexed nftType, address indexed buyer, uint128 nftReceived, uint128 buyAmount, uint128 feeCharged);

  /**
    * @dev Initialize project for raise fund
    * @param _calculation Epoch date to start buy allocation calculation
    * @param _start Epoch date to start round 1
    * @param _duration Duration per booster (in seconds)
    * @param _minKom KOM staked minimum to join sale
    * @param _sale Amount NFT to sell
    * @param _price NFT price in payment decimal
    * @param _fee_d2 Fee project percent in 2 decimal
    * @param _payment Tokens to raise
    */
  function initialize(
    uint64 _calculation,
    uint64 _start,
    uint64 _duration,
    uint128 _minKom,
    uint128[] calldata _sale,
    uint128[] calldata _price,
    uint16 _fee_d2,
    address _payment
  ) external {
    require(!initialized && _sale.length == _price.length && msg.sender == address(factory) && _calculation < _start, "bad");

    calculation = _calculation;
    start = _start;
    end = _start + _duration;
    minKom = _minKom;
    fee_d2 = _fee_d2;
    payment = IERC20(_payment);
    nftType = uint16(_sale.length);

    uint32 total;
    for(uint16 i=0; i<nftType; ++i){
      nft[i].sale = _sale[i];
      nft[i].price = _price[i];
      total += uint32(_sale[i]);
    }
    nftTotalSale = total;

    initialized = true;
  }
    
  // **** VIEW AREA ****
  
  /**
    * @dev Get all buyers/participants length
    */
  function getBuyersLength() external view returns(uint) {
    return buyers.length;
  }
  
  /**
    * @dev Get total number transactions of buyer
    */
  function getBuyerHistoryLength(address _buyer) external view returns(uint) {
    return invoices[_buyer].length;
  }

  /**
    * @dev Get User Staked Info
    * @param _choice V1 or V2 Staking
    * @param _target User address
    */
  function getUserStakedInfo(StakingChoice _choice, address _target) private view returns(uint128 staked) {
    if(_choice == StakingChoice.V1){
      staked = uint128(IKommunitasStaking(factory.stakingV1()).getUserStakedTokens(_target));
    }else if(_choice == StakingChoice.V2){
      staked = uint128(IKommunitasStakingV2(factory.stakingV2()).getUserStakedTokensBeforeDate(_target, calculation));
    }else{
      revert("bad");
    }
  }

  /**
    * @dev Get User Total Staked Kom
    * @param _user User address
    */
  function getUserTotalStaked(address _user) public view returns(uint128){
    uint128 userV1Staked = getUserStakedInfo(StakingChoice.V1, _user);
    uint128 userV2Staked = getUserStakedInfo(StakingChoice.V2, _user);
    return userV1Staked + userV2Staked;
  }

  /**
    * @dev Get User Total Staked Allocation
    * @param _user User address
    * @param _nftType NFT type
    */
  function getUserAllocation(address _user, uint16 _nftType) public view returns(uint128 userAlloc){
    uint128 min = minKom;
    if(min > 0){
      userAlloc = getUserTotalStaked(_user) >= min ? getUserTotalStaked(_user) / min : 0;
    } else{
      userAlloc = nft[_nftType].sale - nftSold[_nftType];
    }
  }

  /**
    * @dev Check whether buyer/participant or not
    * @param _user User address
    */
  function isBuyer(address _user) private view returns (bool) {
    if(buyers.length == 0) return false;
    return (invoices[_user].length > 0);
  }

  /**
    * @dev Calculate amount in
    * @param _nftReceived Token received amount
    * @param _user User address
    * @param _nftType NFT type
    */
  function amountInCalc(
    uint128 _nftReceived,
    address _user,
    uint16 _nftType,
    uint128 _nftPrice
  ) private view returns(uint128 amountInFinal, uint128 nftReceivedFinal) {
    uint128 left = nft[_nftType].sale - nftSold[_nftType];
    require(left > 0, "!sale");

    if(_nftReceived > left) _nftReceived = left;

    amountInFinal = _nftReceived * _nftPrice;
    
    uint128 alloc;
    if(minKom > 0){
      alloc = userAllocation[_user];
    } else {
      alloc = nftTotalSale;
    }

    uint128 userPurchase;
    for(uint16 i=0; i<nftType; ++i){
      userPurchase += userBought[_user][i];
    }

    require(userPurchase < alloc, "max");

    if(userPurchase + _nftReceived > alloc) amountInFinal = (alloc - userPurchase) * _nftPrice;

    nftReceivedFinal = amountInFinal / _nftPrice;
  }
    
  /**
    * @dev Convert address to string
    * @param x Address to convert
    */
  function toAsciiString(address x) private pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);            
    }
    return string(s);
  }
    
  function char(bytes1 b) private pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  // **** MAIN AREA ****
    
  /**
    * @dev Move raised fund to devAddr/project owner
    */
  function moveFund(uint16 _percent_d2, bool _devAddr, address _target) external {
    uint amount = (raised * _percent_d2) / 10000;
    require(payment.balanceOf(address(this)) >= amount && (msg.sender == factory.savior() || msg.sender == owner), "bad");

    if(_devAddr){
      TransferHelper.safeTransfer(address(payment), factory.operational(), amount);
    } else{
      require(_target != address(0), "wat");
      TransferHelper.safeTransfer(address(payment), _target, amount);
    }
  }

  /**
    * @dev Move fee to devAddr
    */
  function moveFee() external {
    uint128 amount = revenue;
    uint128 left = amount - feeMoved;
    require(payment.balanceOf(address(this)) >= left && left > 0 && (msg.sender == factory.savior() || msg.sender == owner), "bad");
    
    feeMoved = amount;

    TransferHelper.safeTransfer(address(payment), factory.operational(), (left * factory.operationalPercentage_d2()) / 10000);
    TransferHelper.safeTransfer(address(payment), factory.marketing(), (left * factory.marketingPercentage_d2()) / 10000);
    TransferHelper.safeTransfer(address(payment), factory.treasury(), (left * factory.treasuryPercentage_d2()) / 10000);
  }
    
  /**
    * @dev Buy token project using token raise
    * @param _amountIn Buy amount
    * @param _nftType NFT type
    */
  function buyToken(uint16 _nftType, uint128 _amountIn) external isOnGoing isNotPaused {
    if(minKom > 0 && userAllocation[msg.sender] == 0) require(setAllocation(msg.sender, _nftType), "!eligible");

    uint32 buyerId = setBuyer(msg.sender);

    uint128 price = nft[_nftType].price;
    require(_amountIn >= price, "bad");

    uint128 nftReceived = _amountIn / price;
    
    (uint128 amountInFinal, uint128 nftReceivedFinal) = amountInCalc(nftReceived, msg.sender, _nftType, price);
    
    uint128 feeCharged = (amountInFinal * uint128(fee_d2)) / 10000;

    invoices[msg.sender].push(Invoice(buyerId, _nftType, uint64(block.timestamp), nftReceivedFinal, amountInFinal, feeCharged));
    
    raised += amountInFinal;
    revenue += feeCharged;
    userBought[msg.sender][_nftType] += nftReceivedFinal;
    nftSold[_nftType] += nftReceivedFinal;

    TransferHelper.safeTransferFrom(address(payment), msg.sender, address(this), amountInFinal + feeCharged);

    emit NFTBought(_nftType, msg.sender, nftReceivedFinal, amountInFinal, feeCharged);
  }

  /**
    * @dev KOM Team buy some left tokens
    * @param _nftAmount NFT amount to buy
    * @param _nftType NFT type
    */
  function teamBuy(uint16 _nftType, uint128 _nftAmount) external isOnGoing isNotPaused {
    require(msg.sender == factory.savior() || msg.sender == owner, "??");

    uint32 buyerId = setBuyer(msg.sender);

    uint128 left = nft[_nftType].sale - nftSold[_nftType];
    if(_nftAmount > left) _nftAmount = left;

    invoices[msg.sender].push(Invoice(buyerId, _nftType, uint64(block.timestamp), _nftAmount, 0, 0));

    userBought[msg.sender][_nftType] += _nftAmount;
    nftSold[_nftType] += _nftAmount;

    emit NFTBought(_nftType, msg.sender, _nftAmount, 0, 0);
  }

  /**
    * @dev Set buyer allocation
    * @param _user User address
    * @param _nftType NFT type
    */
  function setAllocation(address _user, uint16 _nftType) private returns(bool) {
    userAllocation[_user] = getUserAllocation(_user, _nftType);

    if(userAllocation[_user] == 0) return false;

    return true;
  }
    
  /**
    * @dev Set buyer id
    * @param _user User address
    */
  function setBuyer(address _user) private returns(uint32 buyerId) {
    if(!isBuyer(_user)){
      buyers.push(_user);
      buyerId = uint32(buyers.length - 1);
      
      if(bytes(recipient[_user]).length == 0) recipient[_user] = toAsciiString(_user);
    }else{
      buyerId = invoices[_user][0].buyersIndex;
    }
  }
  
  /**
    * @dev Set recipient address
    * @param _recipient Recipient address
    */
  function setRecipient(string calldata _recipient) external isNotPaused  {
    require(uint64(block.timestamp) <= end && bytes(_recipient).length != 0, "bad");

    recipient[msg.sender] = _recipient;
  }

  // **** ADMIN AREA ****

  /**
    * @dev Set Calculation
    * @param _calculation Epoch date to start buy allocation calculation
    */
  function setCalculation(uint64 _calculation) external onlyOwner {
    require(uint64(block.timestamp) < calculation, "bad");

    calculation = _calculation;
  }

  /**
    * @dev Set Start
    * @param _start Epoch date to start round 1
    */
  function setStart(uint64 _start, uint64 _duration) external onlyOwner {
    require(uint64(block.timestamp) < start, "bad");
      
    start = _start;
    end = start + _duration;
  }

  /**
    * @dev Set Sale
    * @param _sale Amount token project to sell (based on token decimals of project)
    */
  function setSale(uint128[] calldata _sale) external onlyOwner {
    require(uint64(block.timestamp) < start, "bad");

    for(uint16 i=0; i<nftType; ++i){
      nft[i].sale = _sale[i];
    }
  }
    
  /**
    * @dev Set price
    * @param _price Token project price in payment decimal
    */
  function setPrice(uint128[] calldata _price) external onlyOwner {
    require(uint64(block.timestamp) < start, "bad");

    for(uint16 i=0; i<nftType; ++i){
      nft[i].price = _price[i];
    }
  }

    /**
     * @dev Set fee
     * @param _fee_d2 Fee project percent in 2 decimal
     */
    function setFee_d2(uint16 _fee_d2) external onlyOwner {
      require(uint64(block.timestamp) < start, "bad");

      fee_d2 = _fee_d2;
    }

  /**
    * @dev Set Payment
    * @param _payment Tokens to raise
    */
  function setPayment(address _payment) external onlyOwner {
    require(uint64(block.timestamp) < start, "bad");

    payment = IERC20(_payment);
  }

  /**
    * @dev Transfer Ownership
    * @param _newOwner New owner address
    */
  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "bad");
    owner = _newOwner;
  }

  /**
    * @dev Toggle buyToken pause
    */
  function togglePause() external onlyOwner {
    isPaused = !isPaused;
  }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface INFTSaleFactory {
  event ProjectCreated(address indexed project, uint index);  
    
  function owner() external  view returns (address);
  function savior() external  view returns (address);
  function operational() external  view returns (address);
  function marketing() external  view returns (address);
  function treasury() external  view returns (address);

  function operationalPercentage_d2() external  view returns (uint64);
  function marketingPercentage_d2() external  view returns (uint64);
  function treasuryPercentage_d2() external  view returns (uint128);

  function stakingV1() external view returns (address);
  function stakingV2() external view returns (address);
  
  function allProjectsLength() external view returns(uint);
  function allPaymentsLength() external view returns(uint);
  function allProjects(uint) external view returns(address);
  function allPayments(uint) external view returns(address);
  function getPaymentIndex(address) external view returns(uint);

  function createProject(uint64, uint64, uint64, uint128, uint128[] calldata, uint128[] calldata, uint16, address) external returns (address);
  
  function transferOwnership(address) external;
  function setPayment(address) external;
  function removePayment(address) external;
  function config(address, address, address, address) external;
  function setPercentage_d2(uint64, uint64, uint128) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IKommunitasStaking{
	function getUserStakedTokens(address _of) external view returns (uint256);
	function communityStaked() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IKommunitasStakingV2{
	function getUserStakedTokensBeforeDate(address _of, uint256 _before) external view returns (uint256);
	function staked(uint256) external view returns (uint256,uint256,uint256);
	function lockPeriod(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
	function safeApprove(address token, address to, uint value) internal {
		// bytes4(keccak256(bytes('approve(address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
	}

	function safeTransfer(address token, address to, uint value) internal {
		// bytes4(keccak256(bytes('transfer(address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
	}

	function safeTransferFrom(address token, address from, address to, uint value) internal {
		// bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
	}

	function safeTransferETH(address to, uint value) internal {
		(bool success,) = to.call{value:value}(new bytes(0));
		require(success, "TransferHelper: ETH_TRANSFER_FAILED");
	}
}