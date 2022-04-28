// SPDX-License-Identifier: MIT

/*

  ________ ___________ ____  ____  _______   _______   _______   ______   _____  ___        _______  __       _______  ___      ___ 
 /"       |"     _   "|"  _||_ " |/"      \ /" _   "| /"     "| /    " \ (\"   \|"  \      /"     "|/""\     /"      \|"  \    /"  |
(:   \___/ )__/  \\__/|   (  ) : |:        (: ( \___)(: ______)// ____  \|.\\   \    |    (: ______)    \   |:        |\   \  //   |
 \___  \      \\_ /   (:  |  | . )_____/   )\/ \      \/    | /  /    ) :): \.   \\  |     \/    |/' /\  \  |_____/   )/\\  \/.    |
  __/  \\     |.  |    \\ \__/ // //      / //  \ ___ // ___)(: (____/ //|.  \    \. |     // ___)/  __'  \  //      /|: \.        |
 /" \   :)    \:  |    /\\ __ //\|:  __   \(:   _(  _(:      "\        / |    \    \ |    (:  ( /   /  \\  \|:  __   \|.  \    /:  |
(_______/      \__|   (__________)__|  \___)\_______) \_______)\"_____/   \___|\____\)     \__/(___/    \___)__|  \___)___|\__/|___|
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
Sturgeon Farm - Muitichain Gold Miner (BNB Chain Version)
*/

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.9;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
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

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract SturgeonFarm is Context, Ownable {
    using SafeMath for uint256;


    uint256 private constant FISHES_TO_HATCH_1MINERS = 864000;
    uint256 private constant PSN = 10000;
    uint256 private constant PSNH = 5000;
    uint256 private constant MAX_DEV_FEE_VAL = 300;
    uint256 private constant REFERRAL_FEE_VAL = 1200;
    uint256[] private feeLevel = [1,10];
    uint256 private constant REWARD_FEE_VAL = 8;
    address private communityAddr;
    bool private initialized = false;
    address payable private recAdd;
    mapping (address => uint256) private hatcheryMiners;
    mapping (address => uint256) private claimedFishes;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) private referrals;
    uint256 private marketFishes;

    address private lastBuyer;
    uint256 private lastAmt;
    uint256 public lastBuyTimestamp;
    address public rewardAddr;
    uint256 public constant MAX_REWARD_INTERVAL = 12 hours;

    
    
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    constructor(address _communityAddr) {
        recAdd = payable(msg.sender);
        rewardAddr = address(new RewardPool());
        communityAddr = _communityAddr;
    }
    
    function hatchFishes(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(communityAddr);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {   
            referrals[msg.sender] = ref;
        }
        
        uint256 fishesUsed = getMyFishes(msg.sender);
        uint256 newMiners = fishesUsed.div(FISHES_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedFishes[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        
        //send referral fishes
        claimedFishes[referrals[msg.sender]] = SafeMath.add(claimedFishes[referrals[msg.sender]],fishesUsed.mul(REFERRAL_FEE_VAL).div(10000));
        
        //boost market to nerf miners hoarding 
        marketFishes=SafeMath.add(marketFishes,SafeMath.div(fishesUsed,5));
    }
    
    function sellFishes() public {
        require(initialized);
        uint256 hasFishes = getMyFishes(msg.sender);
        uint256 fishValue = calculateFishSell(hasFishes);
        uint256 devFeeVal = evalDevFeeVal(fishValue);
        uint256 fee = devFee(fishValue, devFeeVal);
        claimedFishes[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketFishes = SafeMath.add(marketFishes,hasFishes);
        recAdd.transfer(fee);
        payable (msg.sender).transfer(SafeMath.sub(fishValue,fee));
    }
    
    function beanRewards(address adr) public view returns(uint256) {
        uint256 hasFishes = getMyFishes(adr);
        uint256 fishValue = calculateFishSell(hasFishes);
        return fishValue;
    }
    
    function buyFishes(address ref) public payable notContract{
        require(initialized);
        require(msg.value > 0);
        if (block.timestamp > lastBuyTimestamp.add(MAX_REWARD_INTERVAL) && lastBuyTimestamp != 0){
            uint256 amt = RewardPool(rewardAddr).getRewardBalance();
            if (amt != 0){
                RewardPool(rewardAddr).withdraw(lastAmt * 5, lastBuyer);
            }
        }
        uint256 devFeeval = evalDevFeeVal(msg.value);
        uint256 fishesBought = calculateFishBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));  
        fishesBought = fishesBought.sub(devFee(fishesBought, devFeeval)).sub(rewardFee(fishesBought));
        uint256 fee = devFee(msg.value, devFeeval);
        uint256 reward = rewardFee(msg.value);
        recAdd.transfer(fee);
        RewardPool(rewardAddr).getReward{value:reward}();
        lastBuyTimestamp = block.timestamp;
        lastBuyer = address(msg.sender);
        lastAmt = msg.value;
        claimedFishes[msg.sender] = SafeMath.add(claimedFishes[msg.sender],fishesBought);
        hatchFishes(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateFishSell(uint256 fishes) public view returns(uint256) {
        return calculateTrade(fishes,marketFishes,address(this).balance);
    }
    
    function calculateFishBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketFishes);
    }
    
    function calculateFishBuySimple(uint256 eth) public view returns(uint256) {
        return calculateFishBuy(eth,address(this).balance);
    }
    
    function evalDevFeeVal(uint256 _amount) private view returns(uint256){
        uint256 devFeeval;
        if(_amount < feeLevel[0].mul(1e18)){
            devFeeval = MAX_DEV_FEE_VAL;
        } else if(_amount< feeLevel[1].mul(1e18)){
            devFeeval = MAX_DEV_FEE_VAL.sub(50);
        } else{
            devFeeval = MAX_DEV_FEE_VAL.sub(100);
        }
        return devFeeval;
    }
    
    function devFee(uint256 _amount, uint256 _devFeeVal) private pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(_amount, _devFeeVal),10000);
    }

    function rewardFee(uint256 amount) private pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,REWARD_FEE_VAL),100);
    }

    
    function seedMarket() public payable onlyOwner {
        require(marketFishes == 0);
        initialized = true;
        marketFishes = 86400000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return hatcheryMiners[adr];
    }
    
    function getMyFishes(address adr) public view returns(uint256) {
        return SafeMath.add(claimedFishes[adr],getFishesSinceLastHatch(adr));
    }

    function getMyFishesValue(address adr) public view returns(uint256){
        uint256 amt = getMyFishes(adr);
        return calculateFishSell(amt);
    }
    
    function getFishesSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(FISHES_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

}


contract RewardPool is Context, Ownable{
    using SafeMath for uint256;
    event GetReward(address winner, uint256 rewardAmt);
    uint256 public historyReward;

    function getReward() external payable{
    }

    function withdraw(uint256 _amt, address _address) public onlyOwner{
        uint256 amt = _amt > address(this).balance ? address(this).balance : _amt;
        payable(_address).transfer(amt);
        historyReward = historyReward.add(amt);
        
        emit GetReward(_address, amt);
    }

    function getRewardBalance() external view returns (uint256){
        return address(this).balance;
    }

    function getHistoryReward() external view returns (uint256){
        return historyReward;
    }

}