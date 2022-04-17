/**
 *Submitted for verification at polygonscan.com on 2022-04-17
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}


pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity 0.7.6;

interface IPrivBonusFactory{
    event ProjectCreated(address indexed project, uint index);
    
    function owner() external  view returns (address);
    function savior() external  view returns (address);
    function devAddr() external view returns (address);

    function stakingV1() external view returns (address);
    function stakingV2() external view returns (address);
    
    function allProjectsLength() external view returns(uint);
    function allPaymentsLength() external view returns(uint);
    function allProjects(uint) external view returns(address);
    function allPayments(uint) external view returns(address);
    function getPaymentIndex(address) external view returns(uint);

    function createProject(address, uint, uint, uint, uint, uint[2] calldata) external returns (address);
    
    function transferOwnership(address) external;
    function setPayment(address) external;
    function removePayment(address) external;
    function config(address, address) external;
}


pragma solidity 0.7.6;

interface KommunitasStaking{
    function getUserStakedTokens(address _of) external view returns (uint256);
}

pragma solidity 0.7.6;

interface KommunitasStakingV2{
    function getUserStakedTokens(address _of) external view returns (uint256);
    function minPrivateSale() external view returns(uint256);
}


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


pragma solidity 0.7.6;

contract PrivateBonus{
    using SafeMath for uint;
    
    bool public initialized;
    bool public isPaused;
    
    address public owner;
    IPrivBonusFactory public factory;
    enum StakingChoice { V1, V2 }
    
    uint public revenue;
    IERC20 public payment;
    
    uint public target;
    uint public price;
    uint public start;
    uint public achieve;
    uint public sale;

    uint public whitelistTotalAlloc;
    address[] public whitelists;

    uint public minPublicBuy;
    uint public maxPublicBuy;
    address[] public buyers;
    
    struct Invoice{
        uint buyersIndex;
        uint boughtAt;
        uint bought;
        uint received;
    }
    
    mapping(address => Invoice[]) public invoices;
    mapping(address => string) public recipient;
    mapping(address => uint) public whitelist;
    mapping(address => uint) public purchase;
    
    modifier onlyOwner{
        require(msg.sender == owner, "!owner");
        _;
    }
    
    modifier onlyFactory{
        require(msg.sender == address(factory), "!factory");
        _;
    }
    
    modifier isNotInitialized{
        require(!initialized, "initialized");
        _;
    }
    
    modifier isNotPaused{
        require(!isPaused, "paused");
        _;
    }
    
    modifier isBoosterProgress{
        require(block.timestamp >= start, "!good");
        _;
    }
    
    event TokenBought(address indexed buyer, uint buyAmount, uint tokenReceived);
    
    constructor(){
        factory = IPrivBonusFactory(msg.sender);
        owner = tx.origin;
    }
    
    /**
     * @dev Initialize project for raise fund
     * @param _payment Tokens to raise
     * @param _sale Amount token project to sell (based on token decimals of project)
     * @param _target Target amount to raise (decimals 18)
     * @param _start Epoch date to start round 1
     * @param _price Token project price in 6 decimal
     * @param _minMaxPublicBuy Min and max token to buy
     */
    function initialize(
        address _payment,
        uint _sale,
        uint _target,
        uint _start,
        uint _price,
        uint[2] calldata _minMaxPublicBuy
    ) external onlyFactory isNotInitialized{
        require(block.timestamp < _start, "!good");
        
        payment = IERC20(_payment);
        sale = _sale;
        target = _target;
        price = _price;
        start = _start;

        minPublicBuy = _minMaxPublicBuy[0];
        maxPublicBuy = _minMaxPublicBuy[1];

        initialized = true;
    }
    
    // **** VIEW AREA ****

    /**
     * @dev Get all whitelists length
     */
    function getWhitelistLength() external view returns(uint){
        return whitelists.length;
    }
    
    /**
     * @dev Get all buyers/participants length
     */
    function getBuyersLength() external view returns(uint){
        return buyers.length;
    }
    
    /**
     * @dev Get total number transactions of buyer
     */
    function getBuyerHistoryLength(address _buyer) external view returns(uint){
        return invoices[_buyer].length;
    }

    /**
     * @dev Get User Staked Info
     * @param _choice V1 or V2 Staking
     * @param _target User address
     */
    function getUserStakedInfo(StakingChoice _choice, address _target) private view returns(uint userStaked){
        if(_choice == StakingChoice.V1){
            userStaked = KommunitasStaking(factory.stakingV1()).getUserStakedTokens(_target);
        }else if(_choice == StakingChoice.V2){
            userStaked = KommunitasStakingV2(factory.stakingV2()).getUserStakedTokens(_target);
        }else{
            revert("!good");
        }
    }
    
    /**
     * @dev Get User Staked Token both V1 & V2
     * @param _target User address
     */
    function getUserStakedToken(address _target) private view returns(uint userStaked){
        uint userV1Staked = getUserStakedInfo(StakingChoice.V1, _target);
        uint userV2Staked = getUserStakedInfo(StakingChoice.V2, _target);
        userStaked = userV1Staked.add(userV2Staked);
    }
    
    /**
     * @dev Check whether buyer/participant eligible
     * @param _user User address
     */
    function isEligible(address _user) public view returns (bool){
        if(whitelist[_user] > 0) return true;
        uint userStaked = getUserStakedToken(_user);
        return (userStaked >= KommunitasStakingV2(factory.stakingV2()).minPrivateSale());
    }
    
    /**
     * @dev Check whether buyer/participant or not
     * @param _user User address
     */
    function isBuyer(address _user) public view returns (bool){
        if(buyers.length == 0) return false;
        return (invoices[_user].length > 0);
    }
    
    /**
     * @dev Calculate amount in
     * @param _tokenReceived Token received amount
     * @param _amountIn Amount in to buy
     */
    function amountInCalc(uint _tokenReceived, uint _amountIn, address _user) private view returns(uint amountInFinal, uint tokenReceivedFinal){
        require(sale.sub(achieve) > 0, "!sale");
        if(_tokenReceived > sale.sub(achieve)){
            _tokenReceived = sale.sub(achieve);
        }
        _amountIn = _tokenReceived.mul(price).div(10**18);
        (amountInFinal, tokenReceivedFinal) = amountInCalcInner(_user, _tokenReceived, _amountIn);
    }
    
    /**
     * @dev Calculate amount in inner
     * @param _user User address
     * @param _tokenReceived Token received amount
     * @param _amountIn Amount in to buy
     */
    function amountInCalcInner(address _user, uint _tokenReceived, uint _amountIn) private view returns(uint amountInFinal, uint tokenReceivedFinal){
        amountInFinal = _amountIn;

        uint alloc;
        if(whitelist[_user] > 0){
            alloc = whitelist[_user];
        } else{
            require(_tokenReceived >= minPublicBuy, "<min");
            alloc = maxPublicBuy;
        }
        
        require(purchase[_user] < alloc, "max");
        if(purchase[_user].add(_tokenReceived) > alloc){
            amountInFinal = (alloc.sub(purchase[_user])).mul(price).div(10**18);
        }

        require(amountInFinal > 0, "small");
        tokenReceivedFinal = amountInFinal.mul(10**18).div(price);
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
     * @dev Move fund to devAddr
     */
    function moveFund() external {
        require(payment.balanceOf(address(this)) > 0 && (msg.sender == factory.savior() || msg.sender == owner), "!good");
        TransferHelper.safeTransfer(address(payment), factory.devAddr(), payment.balanceOf(address(this)));
    }
    
    /**
     * @dev Buy token project using token raise
     * @param _amountIn Buy amount
     * @param _tokenIn token raise address
     */
    function buyToken(uint _amountIn, address _tokenIn) external isBoosterProgress isNotPaused {
        require(isEligible(msg.sender), "!eligible");
        require(_tokenIn == address(payment), "!good");
        
        uint buyerId = setBuyer(msg.sender);
        
        uint tokenReceived = _amountIn.mul(10**18).div(price);
        
        (uint amountInFinal, uint tokenReceivedFinal) = amountInCalc(tokenReceived, _amountIn, msg.sender);
        
        TransferHelper.safeTransferFrom(address(payment), msg.sender, address(this), amountInFinal);
        
        invoices[msg.sender].push(Invoice(buyerId, block.timestamp, amountInFinal, tokenReceivedFinal));
        
        revenue = revenue.add(amountInFinal);
        purchase[msg.sender] = purchase[msg.sender].add(tokenReceivedFinal);
        achieve = achieve.add(tokenReceivedFinal);
        
        emit TokenBought(msg.sender, amountInFinal, tokenReceivedFinal);
    }

    /**
     * @dev Team buys some left tokens
     * @param _tokenAmount Token amount to buy
     */
    function teamBuy(uint _tokenAmount) external isBoosterProgress isNotPaused {
        require(msg.sender == factory.savior() || msg.sender == owner, "Who?");

        uint buyerId = setBuyer(msg.sender);

        if(_tokenAmount > sale.sub(achieve)) _tokenAmount = sale.sub(achieve);

        invoices[msg.sender].push(Invoice(buyerId, block.timestamp, 0, _tokenAmount));
        
        purchase[msg.sender] = purchase[msg.sender].add(_tokenAmount);
        achieve = achieve.add(_tokenAmount);
        
        emit TokenBought(msg.sender, 0, _tokenAmount);
    }

    /**
     * @dev Set buyer id
     * @param _user User address
     */
    function setBuyer(address _user) private returns(uint buyerId){
        if(!isBuyer(_user)){
            buyers.push(_user);
            buyerId = buyers.length.sub(1);
            
            if(bytes(recipient[_user]).length == 0){
                recipient[_user] = toAsciiString(_user);
            }
        }else{
            buyerId = invoices[_user][0].buyersIndex;
        }
    }
    
    /**
     * @dev Set recipient address
     * @param _recipient Recipient address
     */
    function setRecipient(string calldata _recipient) external isNotPaused {
        require(bytes(_recipient).length != 0, "!good");

        recipient[msg.sender] = _recipient;
    }
    
    // **** ADMIN AREA ****

    /**
     * @dev Set whitelist allocation token in 6 decimals
     * @param _user User address
     * @param _allocation Token allocation in 6 decimals
     */
    function setWhitelist_d6(address[] calldata _user, uint[] calldata _allocation) external onlyOwner {
        require(block.timestamp < start && _user.length == _allocation.length, "!good");
        
        for(uint i=0; i<_user.length; i++){
            whitelists.push(_user[i]);
            whitelist[_user[i]] = _allocation[i].mul(10**18).div(10**6);
            whitelistTotalAlloc = whitelistTotalAlloc.add(whitelist[_user[i]]);
        }
    }

    /**
     * @dev Update whitelist allocation token in 6 decimals
     * @param _user User address
     * @param _allocation Token allocation in 6 decimals
     */
    function updateWhitelist_d6(address _user, uint _allocation) external onlyOwner{
        require(purchase[_user] == 0 && whitelist[_user] > 0, "!good");
        uint oldAlloc = whitelist[_user];
        whitelist[_user] = _allocation.mul(10**18).div(10**6);
        whitelistTotalAlloc = whitelistTotalAlloc.sub(oldAlloc).add(whitelist[_user]);
    }

    /**
     * @dev Set Min & Max in FCFS
     * @param _minMaxPublicBuy Min and max token to buy
     */
    function setMinMax(uint[2] calldata _minMaxPublicBuy) external onlyOwner{
        if(block.timestamp < start) minPublicBuy = _minMaxPublicBuy[0];
        maxPublicBuy = _minMaxPublicBuy[1];
    }

    /**
     * @dev Set Sale
     * @param _sale Token sale
     */
    function setSale(uint _sale) external onlyOwner{
        require(block.timestamp < start, "!good");

        sale = _sale;
    }

    /**
     * @dev Set Target
     * @param _target Token target
     */
    function setTarget(uint _target) external onlyOwner{
        target = _target;
    }

    /**
     * @dev Set Start
     * @param _start Sale start
     */
    function setStart(uint _start) external onlyOwner{
        require(block.timestamp < start, "!good");

        start = _start;
    }

    /**
     * @dev Set Price
     * @param _price Token price in 6 decimal
     */
    function setPrice(uint _price) external onlyOwner{
        require(block.timestamp < start, "!good");

        price = _price;
    }
    
    function transferOwnership(address _newOwner) external onlyOwner{
        require(_newOwner != address(0), "!good");
        owner = _newOwner;
    }
    
    function togglePause() external onlyOwner{
        isPaused = !isPaused;
    }
}


pragma solidity 0.7.6;

contract PrivBonusFactory is IPrivBonusFactory{
    address[] public override allProjects; // all projects created
    address[] public override allPayments; // all payment Token accepted
    
    address public override owner;
    address public override savior; // KOM address to spend left tokens
    address public override devAddr; // dev address to receive revenue
    
    address public override immutable stakingV1;
    address public override immutable stakingV2;
    
    modifier onlyOwner{
        require(owner == msg.sender, "!owner");
        _;
    }
    
    mapping(address => uint) public override getPaymentIndex;
    
    constructor(
        address _devAddr,
        address _savior,
        address _stakingV1,
        address _stakingV2
    ){
        require(
            _devAddr != address(0) &&
            _savior != address(0) &&
            _stakingV1 != address(0) &&
            _stakingV2 != address(0)
        , "!good");
        
        owner = msg.sender;
        devAddr = _devAddr;
        savior = _savior;
        stakingV1 = _stakingV1;
        stakingV2 = _stakingV2;
    }
    
    /**
     * @dev Get total number of projects created
     */
    function allProjectsLength() external override view returns (uint) {
        return allProjects.length;
    }
    
    /**
     * @dev Get total number of payment Toked accepted
     */
    function allPaymentsLength() external override view returns (uint) {
        return allPayments.length;
    }
    
    /**
     * @dev Create new project for raise fund
     * @param _payment Tokens to raise
     * @param _sale Amount token project to sell (based on token decimals of project)
     * @param _target Target amount to raise (based on token to raise decimals)
     * @param _start Epoch date to start round 1
     * @param _price Token project price in 6 decimal
     * @param _minMaxPublicBuy Min and max token to buy
     */
    function createProject(
        address _payment,
        uint _sale,
        uint _target,
        uint _start,
        uint _price,
        uint[2] calldata _minMaxPublicBuy
    ) external override onlyOwner returns(address project){
        require(_payment != address(0), "!good");
        require(_payment == allPayments[getPaymentIndex[_payment]], "!accept");
        
        project = address(new PrivateBonus());

        allProjects.push(project);
        
        PrivateBonus(project).initialize(
            _payment,
            _sale,
            _target,
            _start,
            _price,
            _minMaxPublicBuy
        );
        
        emit ProjectCreated(project, allProjects.length-1);
    }
    
    /**
     * @dev Transfer ownership to new owner
     * @param _newOwner New owner
     */
    function transferOwnership(address _newOwner) external override onlyOwner{
        require(_newOwner != address(0), "!good");
        owner = _newOwner;
    }
    
    /**
     * @dev Set new token to be accepted
     * @param _token New token address
     */
    function setPayment(address _token) external override onlyOwner{
        require(_token != address(0), "!good");
        if(allPayments.length > 0) {
            require(_token != allPayments[getPaymentIndex[_token]], "exist");
        }
        
        allPayments.push(_token);
        getPaymentIndex[_token] = allPayments.length-1;
    }
    
    /**
     * @dev Remove token as payment
     * @param _token Token address
     */
    function removePayment(address _token) external override onlyOwner{
        require(_token != address(0), "!good");
        require(_token == allPayments[getPaymentIndex[_token]], "!found");
        
        uint indexToDelete = getPaymentIndex[_token];
        address addressToMove = allPayments[allPayments.length-1];
        
        allPayments[indexToDelete] = addressToMove;
        getPaymentIndex[addressToMove] = indexToDelete;
        
        allPayments.pop();
        delete getPaymentIndex[_token];
    }

    /**
     * @dev Config Factory addresses
     * @param _devAddr Dev address
     * @param _savior Savior address
     */
    function config(address _devAddr, address _savior) external override onlyOwner{
        require(_devAddr != address(0) && _savior != address(0), "!good");
        devAddr = _devAddr;
        savior = _savior;
    }
}