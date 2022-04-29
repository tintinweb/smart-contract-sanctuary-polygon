// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPrivateGovFactory.sol";
import "./IKommunitasStaking.sol";
import "./IKommunitasStakingV2.sol";
import "./TransferHelper.sol";

contract PrivateGovSale{
    IPrivateGovFactory public immutable factory = IPrivateGovFactory(msg.sender);
    uint256 private immutable minStake;
    
    address public owner = tx.origin;

    bool public initialized;
    bool public isPaused;
    bool public buyEnded;
    
    enum StakingChoice { V1, V2 }

    uint128 public calculation;
    uint128 public revenue;

    uint128 public target;
    uint128 public sale;
    
    uint128 public whitelistTotalAlloc;
    uint128 public candidateTotalStaked;

    uint128 public minFCFSBuy;
    uint128 public maxFCFSBuy;

    IERC20 public payment;

    address public gov;
    
    address[] public buyers;
    address[] public whitelists;
    address[] public candidates;
    
    struct Round{
        uint128 start;
        uint128 end;
        uint128 price;
        uint128 achieve;
    }
    
    struct Invoice{
        uint64 buyersIndex;
        uint64 boosterId;
        uint128 boughtAt;
        uint128 bought;
        uint128 received;
    }
    
    mapping(uint64 => Round) public booster;
    mapping(address => Invoice[]) public invoices;
    mapping(address => string) public recipient;
    mapping(address => uint128) public whitelist;
    mapping(address => mapping(uint64 => uint128)) public purchasePerRound;
    
    mapping(address => uint128) private userStaked;
    mapping(address => mapping(uint64 => uint128)) private userAllocation;
    
    modifier onlyOwner{
        require(msg.sender == owner, "owner");
        _;
    }
    
    modifier isNotPaused{
        require(!isPaused, "paused");
        _;
    }
    
    modifier isBoosterProgress{
        require(boosterProgress() > 0, "!booster");
        _;
    }
    
    event TokenBought(uint64 indexed booster, address indexed buyer, uint128 buyAmount, uint128 tokenReceived);
    
    constructor(){
        minStake = IKommunitasStakingV2(factory.stakingV2()).minPrivateSale();
    }

    /**
     * @dev Initialize project for raise fund
     * @param _calculation Epoch date to start buy allocation calculation
     * @param _start Epoch date to start round 1
     * @param _sale Amount token project to sell (based on token decimals of project)
     * @param _target Target amount to raise
     * @param _price Token project price in each rounds in payment decimal
     * @param _payment Tokens to raise
     * @param _gov Governance address
     */
    function initialize(
        uint128 _calculation,
        uint128 _start,
        uint128 _sale,
        uint128 _target,
        uint128[2] calldata _price,
        address _payment,
        address _gov
    ) external {
        require(!initialized && msg.sender == address(factory) && _calculation < _start, "bad");
        
        payment = IERC20(_payment);
        sale = _sale;
        target = _target;
        calculation = _calculation;
        gov = _gov;
        
        for(uint64 i=1; i<=2; i++){
            if(i==1){
                booster[i].start = _start;
            }else{
                booster[i].start = booster[i-1].end + 1;
            }
            booster[i].end = booster[i].start + 14400;
            booster[i].price = _price[i-1];
        }
        
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
     * @dev Get all candidates length
     */
    function getCandidatesLength() external view returns(uint) {
        return candidates.length;
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
     * @dev Check whether buyer/participant is eligible
     * @param _user User address
     * @param _boosterRunning Booster progress
     */
    function isEligible(address _user, uint64 _boosterRunning) public view returns (bool){
        if(_boosterRunning == 1) {
            if(whitelist[_user] > 0) return true;
            return (userStaked[_user] >= uint128(minStake));
        } else if(_boosterRunning == 2) {
            return (getUserTotalStaked(_user) >= uint128(minStake));
        }
    }
    
    /**
     * @dev Get User Total Staked Allocation
     * @param _user User address
     * @param _boosterRunning Booster progress
     */
    function getUserAllocation(address _user, uint64 _boosterRunning) public view returns(uint128 userAlloc){
        if(isEligible(_user, _boosterRunning)){
            uint128 saleAmount = sale;
            uint128 userStakedToken = _boosterRunning == 1 ? userStaked[_user] : getUserTotalStaked(_user);

            if(_boosterRunning == 1){
                if(userStakedToken > 0){
                    uint128 alloc = (userStakedToken * 10**8) / candidateTotalStaked;
                    userAlloc = (alloc * (saleAmount - whitelistTotalAlloc)) / 10**8;
                }

                uint128 whitelistAmount = whitelist[_user];

                if(whitelistAmount > 0) userAlloc += whitelistAmount;
            } else if(_boosterRunning == 2){
                if(userStakedToken > 0) userAlloc = maxFCFSBuy;
            }
        }
    }
    
    /**
     * @dev Check whether buyer/participant or not
     * @param _user User address
     */
    function isBuyer(address _user) private view returns (bool){
        if(buyers.length == 0) return false;
        return (invoices[_user].length > 0);
    }
    
    /**
     * @dev Get total purchase of a user
     * @param _user User address
     */
    function getTotalPurchase(address _user) external view returns(uint128 total){
        total = purchasePerRound[_user][1] + purchasePerRound[_user][2];
    }
    
    /**
     * @dev Get booster running now, 0 = no booster running
     */
    function boosterProgress() public view returns (uint64 running){
        running = 0;
        for(uint64 i=1; i<=2; i++){
            if(uint128(block.timestamp) >= booster[i].start && uint128(block.timestamp) <= booster[i].end){
                running = i;
                break;
            }
        }
    }
    
    /**
     * @dev Get total sold tokens
     */
    function sold() public view returns(uint128 total){
        total = 0;
        for(uint64 i=1; i<=2; i++){
            total += booster[i].achieve;
        }
    }
    
    /**
     * @dev Calculate amount in
     * @param _tokenReceived Token received amount
     * @param _user User address
     * @param _running Booster running
     * @param _boosterPrice Booster running price
     */
    function amountInCalc(
        uint128 _tokenReceived,
        address _user,
        uint64 _running,
        uint128 _boosterPrice
    ) private view returns(uint128 amountInFinal, uint128 tokenReceivedFinal) {
        uint128 left = sale - sold();
        require(left > 0, "!sale");

        if(_tokenReceived > left) _tokenReceived = left;

        amountInFinal = (_tokenReceived * _boosterPrice) / 10**18;
        
        uint128 alloc;
        if(_running == 1){
            alloc = userAllocation[_user][_running];
        } else if(_running == 2){
            require(minFCFSBuy > 0 && maxFCFSBuy > 0 && _tokenReceived >= minFCFSBuy, "<min");
            alloc = maxFCFSBuy;
        }

        uint128 purchaseThisRound = purchasePerRound[_user][_running];
        require(purchaseThisRound < alloc, "max");

        if(purchaseThisRound + _tokenReceived > alloc){
            amountInFinal = ((alloc - purchaseThisRound) * _boosterPrice) / 10**18;
        }

        require(amountInFinal > 0, "small");
        tokenReceivedFinal = (amountInFinal * 10**18) / _boosterPrice;
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
        uint bal = payment.balanceOf(address(this));
        require(bal > 0, "bad");

        TransferHelper.safeTransfer(address(payment), factory.devAddr(), bal);
        
        if(boosterProgress() == 2 && !buyEnded) buyEnded = true;
    }
    
    /**
     * @dev Buy token project using token raise
     * @param _amountIn Buy amount
     */
    function buyToken(uint128 _amountIn) external isBoosterProgress isNotPaused {
        uint64 running = boosterProgress();
        
        if(running == 1){
            require(setUserAllocation(msg.sender), "bad");
            require(candidateTotalStaked > 0 && (userStaked[msg.sender] > 0 || whitelist[msg.sender] > 0), "!eligible");
        } else if(running == 2){
            require(setUserTotalStaked(msg.sender), "bad");
            require(userStaked[msg.sender] > 0, "!eligible");
        }

        uint64 buyerId = setBuyer(msg.sender);
        
        uint128 boosterPrice = booster[running].price;

        uint128 tokenReceived = (_amountIn * 10**18) / boosterPrice;
        
        (uint128 amountInFinal, uint128 tokenReceivedFinal) = amountInCalc(tokenReceived, msg.sender, running, boosterPrice);
        
        TransferHelper.safeTransferFrom(address(payment), msg.sender, address(this), amountInFinal);
        
        invoices[msg.sender].push(Invoice(buyerId, running, uint128(block.timestamp), amountInFinal, tokenReceivedFinal));
        
        revenue += amountInFinal;
        purchasePerRound[msg.sender][running] += tokenReceivedFinal;
        booster[running].achieve += tokenReceivedFinal;
        
        emit TokenBought(running, msg.sender, amountInFinal, tokenReceivedFinal);
    }

    /**
     * @dev KOM Team buy some left tokens
     * @param _tokenAmount Token amount to buy
     */
    function teamBuy(uint128 _tokenAmount) external isBoosterProgress isNotPaused {
        require(msg.sender == factory.savior() || msg.sender == owner, "??");

        uint64 running = boosterProgress();
        require(running == 2, "bad");

        uint64 buyerId = setBuyer(msg.sender);

        uint128 left = sale - sold();
        if(_tokenAmount > left) _tokenAmount = left;

        invoices[msg.sender].push(Invoice(buyerId, running, uint128(block.timestamp), 0, _tokenAmount));
        
        purchasePerRound[msg.sender][running] += _tokenAmount;
        booster[running].achieve += _tokenAmount;
        
        emit TokenBought(running, msg.sender, 0, _tokenAmount);
    }

    /**
     * @dev Set user total KOM staked
     * @param _user User address
     */
    function setUserTotalStaked(address _user) private returns(bool) {
        uint128 staked = getUserTotalStaked(_user);
        if(userStaked[_user] == 0 && staked >= uint128(minStake)) userStaked[_user] = staked;

        return true;
    }

    /**
     * @dev Set user allocation token to buy
     * @param _user User address
     */
    function setUserAllocation(address _user) private returns(bool) {
        if(userAllocation[_user][1] == 0) userAllocation[_user][1] = getUserAllocation(_user, 1);
        
        return true;
    }

    /**
     * @dev Set buyer id
     * @param _user User address
     */
    function setBuyer(address _user) private returns(uint64 buyerId){
        if(!isBuyer(_user)){
            buyers.push(_user);
            buyerId = uint64(buyers.length - 1);
            
            if(bytes(recipient[_user]).length == 0) recipient[_user] = toAsciiString(_user);
        } else{
            buyerId = invoices[_user][0].buyersIndex;
        }
    }
    
    /**
     * @dev Set recipient address
     * @param _recipient Recipient address
     */
    function setRecipient(string calldata _recipient) external isNotPaused {
        require(!buyEnded && bytes(_recipient).length != 0, "bad");

        recipient[msg.sender] = _recipient;
    }

    /**
     * @dev Migrate candidates from gov contract
     * @param _candidates Candidate address
     */
    function migrateCandidates(address[] calldata _candidates) external returns (bool) {
        require(msg.sender == gov && uint128(block.timestamp) >= calculation && uint128(block.timestamp) < booster[1].start, "bad");

        for(uint16 i=0; i<_candidates.length; i++){
            setUserTotalStaked(_candidates[i]);
            candidateTotalStaked += userStaked[_candidates[i]];
        }

        candidates = _candidates;

        return true;
    }
    
    // **** ADMIN AREA ****

    /**
     * @dev Set whitelist allocation token in 6 decimal
     * @param _user User address
     * @param _allocation Token allocation in 6 decimal
     */
    function setWhitelist_d6(address[] calldata _user, uint128[] calldata _allocation) external onlyOwner {
        require(block.timestamp < calculation && _user.length == _allocation.length, "bad");
        
        uint128 whitelistTotal = whitelistTotalAlloc;
        for(uint16 i=0; i<_user.length; i++){
            whitelists.push(_user[i]);
            whitelist[_user[i]] = (_allocation[i] * 10**18) / 10**6;
            whitelistTotal += whitelist[_user[i]];
        }

        whitelistTotalAlloc = whitelistTotal;
    }

    /**
     * @dev Update whitelist allocation token in 6 decimal
     * @param _user User address
     * @param _allocation Token allocation in 6 decimal
     */
    function updateWhitelist_d6(address[] calldata _user, uint128[] calldata _allocation) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start && _user.length == _allocation.length, "bad");

        uint128 whitelistTotal = whitelistTotalAlloc;
        for(uint16 i=0; i<_user.length; i++){
            if(whitelist[_user[i]] == 0) continue;

            uint128 oldAlloc = whitelist[_user[i]];
            whitelist[_user[i]] = (_allocation[i] * 10**18) / 10**6;
            whitelistTotal = whitelistTotal - oldAlloc + whitelist[_user[i]];
        }

        whitelistTotalAlloc = whitelistTotal;
    }

    /**
     * @dev Set Min & Max in FCFS
     * @param _minMaxFCFSBuy Min and max token to buy
     */
    function setMinMaxFCFS(uint128[2] calldata _minMaxFCFSBuy) external onlyOwner {
        if(boosterProgress() < 2) minFCFSBuy = _minMaxFCFSBuy[0];
        maxFCFSBuy = _minMaxFCFSBuy[1];
    }

    /**
     * @dev Set Calculation
     * @param _calculation Epoch date to start buy allocation calculation
     */
    function setCalculation(uint128 _calculation) external onlyOwner {
        require(uint128(block.timestamp) < calculation, "bad");

        calculation = _calculation;
    }

    /**
     * @dev Set Start
     * @param _start Epoch date to start round 1
     */
    function setStart(uint128 _start) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "bad");

        for(uint64 i=1; i<=2; i++){
            if(i==1){
                booster[i].start = _start;
            }else{
                booster[i].start = booster[i-1].end + 1;
            }
            booster[i].end = booster[i].start + 14400;
        }
    }

    /**
     * @dev Set Sale
     * @param _sale Amount token project to sell (based on token decimals of project)
     */
    function setSale(uint128 _sale) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "bad");

        sale = _sale;
    }

    /**
     * @dev Set Target
     * @param _target Target amount to raise
     */
    function setTarget(uint128 _target) external onlyOwner {
        target = _target;
    }
    
    /**
     * @dev Set Price per round
     * @param _price Token project price in each rounds in payment decimal
     */
    function setPrice(uint128[2] calldata _price) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "bad");

        for(uint64 i=1; i<=2; i++){
            booster[i].price = _price[i-1];
        }
    }

    /**
     * @dev Set Payment
     * @param _payment Tokens to raise
     */
    function setPayment(address _payment) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "bad");

        payment = IERC20(_payment);
    }

    /**
     * @dev Set Gov
     * @param _gov Governance address
     */
    function setGov(address _gov) external onlyOwner {
        require(uint128(block.timestamp) < booster[1].start, "bad");

        gov = _gov;
    }
    
    /**
     * @dev Transfer Ownership
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner{
        require(_newOwner != address(0), "bad");
        owner = _newOwner;
    }
    
    /**
     * @dev Toggle buyToken pause
     */
    function togglePause() external onlyOwner{
        isPaused = !isPaused;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPrivateGovFactory{
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

    function createProject(uint128, uint128, uint128, uint128, uint128[2] calldata, address, address) external returns (address);
    
    function transferOwnership(address) external;
    function setPayment(address) external;
    function removePayment(address) external;
    function config(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IKommunitasStaking{
    function getUserStakedTokens(address _of) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IKommunitasStakingV2{
    function getUserStakedTokensBeforeDate(address _of, uint256 _before) external view returns (uint256);
    function minPrivateSale() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

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