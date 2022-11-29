// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "./SafeMath.sol";
interface IBEP20Token
{
    function mintTokens(address receipient, uint256 tokenAmount) external returns(bool);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address user) external view returns(uint256);
    function totalSupply() external view returns (uint256);
    function maxsupply() external view returns (uint256);
    function repurches(address _from, address _to, uint256 _value) external returns(bool);
    function burn_internal(uint256 _value, address _to) external returns (bool);
}

contract StakeLigentV1{
  AggregatorV3Interface internal priceFeed;
  IBEP20Token public token;
  using SafeMath for uint;


  struct Deposit {
	uint amountUSD;
    uint withdrawn;
    uint tokenAmount;
	uint start;
    uint withdrwanUSD;
    bool roiActive;
    uint percent;
	}
  struct Restake{
    uint amountUSD;
    uint amountBNB;
    uint start;
    bool status;
  }

	struct User {
    Deposit[] deposits;
    uint checkpoint;
    address referrer;
    address[15] refAddress;
    uint[15] refs;
    uint[15] refStageBusiness;
    uint boosterBusiness;
    uint directBusiness;
    uint bonus;
    uint totalBonus;
    uint maxDeposit;
    uint withdrawn;
    uint[15] refStageBonus;
    uint rankWithdraw;
    uint lastTotalSystemRoi;
    uint reStakeAmount;
    uint withdrawnPASSIVE;
    uint[] directRoi;
	}


  struct RankIncome{
    uint amountUSD;
    uint maturityDate;
  }

struct x5{
  uint start;
  uint last;
  uint daysCount;
  uint maxamount;
}

struct x20{
  uint start;
  uint last;
  uint daysCount;
  uint maxamount;
}

struct x100{
  uint start;
  uint last;
  uint daysCount;
  uint maxamount;

}


  uint256  public INVEST_MIN_AMOUNT;
  uint256[15] public PASSIVE_PERCENTS;
  uint[10] public refBonus;
  uint[3] public rankPercnetage;
  uint public percentDivider;
  uint public maxDeposit;
  uint public contractStart;
  address payable public ownerWallet;
  address payable public supportWallet;
  uint[15] private requireDirect;
  uint public totalUser;
  uint public timeStamp;
  uint public roiStartDate;
  uint[3] public changeDays;
  uint[2] public mainRoiPercentage;
  uint public roiPercentDecrement;
  uint public tokenPrice;
  uint[3] public boosterDays;
  uint[3] public boosterDiv;
  bool private IsInitinalized;



  mapping(address => User) public users;
  mapping (address => mapping(uint => address)) public direct_ref;
  mapping (address => mapping(uint => address[])) public refDetails;
  mapping(address =>x5) public x5Booster;
  mapping(address =>x20) public x20Booster;
  mapping(address =>x100) public x100Booster;
  mapping(address => RankIncome[]) public rankIncomes;

   modifier adminOnly() {
    require(msg.sender == ownerWallet, "admin: wut?");
    _;
}


   function initialize(address payable _ownerWallet ,address payable _supportWallet,IBEP20Token _tokenAddress) public {
        require(IsInitinalized==false,"You can use it only one time");
            ownerWallet = _ownerWallet;
            supportWallet = _supportWallet;
            priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
            INVEST_MIN_AMOUNT = 10*1e8;
            PASSIVE_PERCENTS = [1000,700,500,400,300,200,100,100,100,100,100,200,300,400,500];
            requireDirect = [0,1,2,2,3,3,4,4,5,6,7,7,7,7,7];
            percentDivider = 10000;
            refBonus = [500,400,300,200,100,100,100,100,100,200];
            rankPercnetage = [500,1000,2000];
            maxDeposit = 100000*1e8;
            contractStart = block.timestamp;
            roiPercentDecrement= 2;
            changeDays = [34,83,134];
            tokenPrice = 1e8;
            token = _tokenAddress;
            roiStartDate = block.timestamp;
            timeStamp = 1 hours;
            mainRoiPercentage = [10500,50];
            boosterDays = [5 hours,6 hours,7 hours];
            boosterDiv = [5,6,7];
            IsInitinalized = true;
    }


    function invest(address _referrer,uint _amount) public payable {
        User storage user = users[msg.sender];
        uint _amountBNB;
        uint reStakeValue = user.reStakeAmount;
        if(reStakeValue>0){
            user.reStakeAmount = 0;
          _amount = _amount.add(reStakeValue);
          _amountBNB = getCalculatedBnbRecieved(reStakeValue);
        }
        uint256 usdValue = uint256(TotalusdPrice(int(msg.value.add(_amountBNB))));
        uint count = user.deposits.length;
        if(count>0){
        if(user.deposits[count-1].roiActive ==true){
            revert("Your last Roi is not completed");
        }
        }
        require(usdValue >= INVEST_MIN_AMOUNT,"min amount is $100");
        require((users[_referrer].deposits.length > 0 && _referrer != msg.sender) || ownerWallet == msg.sender,  "No upline found");
        require(_amount.mod(INVEST_MIN_AMOUNT) == 0 && _amount >= INVEST_MIN_AMOUNT, "mod err");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "less before");
        if(user.maxDeposit == 0){
            user.maxDeposit = _amount;
        }else if(user.maxDeposit < _amount){
            user.maxDeposit = _amount;
        }

        if (user.referrer == address(0) && ownerWallet != msg.sender) {
			        user.referrer = _referrer;
        }
        address upline = user.referrer;
          for(uint i=0; i<15; i++){
             if (upline != address(0)){
                if(user.deposits.length == 0 ){
                    users[upline].refs[i] += 1;
                    refDetails[upline][i+1].push(msg.sender);
                }
                if(i==0 && user.deposits.length == 0){
                    uint  roi = current_Total_Roi();
                    users[upline].boosterBusiness =  users[upline].boosterBusiness.add(_amount);
                    users[upline].directRoi.push(roi);

                }
                users[upline].refStageBusiness[i] = users[upline].refStageBusiness[i].add(_amount);
                if(i < 10 && users[upline].refs[0] >= requireDirect[i]){
                    uint bonus = _amount.mul(refBonus[i]).div(percentDivider);
                    users[upline].bonus = users[upline].bonus.add(bonus);
                    users[upline].refStageBonus[i] = users[upline].refStageBonus[i].add(bonus);
                }

             }else break;
                 upline = users[upline].referrer;
          }

        if(user.referrer != address(0) && user.deposits.length == 0 ){
            direct_ref[user.referrer][users[user.referrer].refs[0]-1] = msg.sender;
        }
        if(user.deposits.length == 0){
            totalUser++;
            user.checkpoint = block.timestamp;
        }

     uint  _percent = current_Total_Roi();
     user.lastTotalSystemRoi = _percent;
     uint time;
     if(block.timestamp<roiStartDate){
        time = roiStartDate;
     }else{
        time = block.timestamp;
     }
       user.deposits.push(Deposit(_amount,0,0, time, 0,true,_percent));
       upline = user.referrer;
       if(upline != address(0)){
        calaculateBosterRoi(upline);
       }
       


    }

        function current_Total_Roi() public view returns(uint){
        uint roistartTimestamp = roiStartDate; 
        uint currentTimestamp = block.timestamp;

        uint decresing_percentage = roiPercentDecrement;
        uint start_percentage = mainRoiPercentage[0];

         uint maxDecimalsum = 15150;
         uint cur_decrimentalTotal;

        if(currentTimestamp > roistartTimestamp){

        uint numDays = (currentTimestamp - roistartTimestamp)/timeStamp;
        numDays = numDays*10;//diff in days
        if(numDays >0){
             uint decrimentalTotal =  numDays/2*(2*start_percentage-(numDays-10)*(decresing_percentage));
             decrimentalTotal = decrimentalTotal.div(100);
            cur_decrimentalTotal = (decrimentalTotal >= maxDecimalsum ) ?  maxDecimalsum : decrimentalTotal;

        }
       
        }

        return cur_decrimentalTotal;


    }

     function totalRoi(address _user, uint i, bool passive) public view returns (uint total){

        uint roistartTimestamp = roiStartDate; 
        uint lastTotalDecimal;

        uint currentTimestamp = block.timestamp;
        uint end_percentage = mainRoiPercentage[1];
        if(passive == true){
             lastTotalDecimal = users[_user].deposits[i].percent;
        }else{
             lastTotalDecimal = users[_user].lastTotalSystemRoi;
        }
       


        if(currentTimestamp > roistartTimestamp){

        uint numDays = (currentTimestamp - roistartTimestamp)/timeStamp;//diff in days
        uint variabledays = numDays;
        if(variabledays >= 101){
            variabledays = 101;
        }


        uint userroi = (current_Total_Roi() - lastTotalDecimal);

        uint continue_percentage = 0;
        if(numDays > variabledays){
            continue_percentage = end_percentage*(numDays-variabledays);
        }

        total = userroi+continue_percentage;

        }
        
    }

    function totalPassiveRoi(uint percent) public view returns (uint total){

        uint roistartTimestamp = roiStartDate; 
        uint lastTotalDecimal;

        uint currentTimestamp = block.timestamp;
        uint end_percentage = mainRoiPercentage[1];
        lastTotalDecimal =percent;
 

    
       


        if(currentTimestamp > roistartTimestamp){

        uint numDays = (currentTimestamp - roistartTimestamp)/timeStamp;//diff in days
        uint variabledays = numDays;
        if(variabledays >= 101){
            variabledays = 101;
        }


        uint userroi = (current_Total_Roi() - lastTotalDecimal);

        uint continue_percentage = 0;
        if(numDays > variabledays){
            continue_percentage = end_percentage*(numDays-variabledays);
        }

        total = userroi+continue_percentage;

        }
        
    }

    // function investToken(address _referrer,uint _token) public {
    //     User storage user = users[msg.sender];
    //     uint _amountBNB;
    //     uint usdFromToken = _token.mul(tokenPrice).div(1e8);
    //     uint remaingAmount = usdFromToken.mod(INVEST_MIN_AMOUNT);
    //     uint _amount = usdFromToken.sub(remaingAmount);
    //     uint reStakeValue = user.reStakeAmount;
    //     if(reStakeValue>0){
    //       _amount = _amount.add(reStakeValue);
    //       _amountBNB = getCalculatedBnbRecieved(reStakeValue);
    //     }
    //     require(_amount >= INVEST_MIN_AMOUNT,"min amount is $100");
    //     require((users[_referrer].deposits.length > 0 && _referrer != msg.sender) || ownerWallet == msg.sender,  "No upline found");
    //     require(_amount.mod(INVEST_MIN_AMOUNT) == 0 && _amount >= INVEST_MIN_AMOUNT, "mod err");
    //     require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "less before");
    //     if(user.maxDeposit == 0){
    //         user.maxDeposit = _amount;
    //     }else if(user.maxDeposit < _amount){
    //         user.maxDeposit = _amount;
    //     }

    //     if (user.referrer == address(0) && ownerWallet != msg.sender) {
	// 		        user.referrer = _referrer;
    //     }
    //     address upline = user.referrer;
    //       for(uint i=0; i<15; i++){
    //          if (upline != address(0)){
    //             if(user.deposits.length == 0 ){
    //                 users[upline].refs[i] += 1;
    //                 refDetails[upline][i+1].push(msg.sender);
    //             }

    //             users[upline].refStageBusiness[i] = users[upline].refStageBusiness[i].add(_amount);
    //             if(i < 10){
    //                 uint bonus = _amount.mul(refBonus[i]).div(percentDivider);
    //                 users[upline].bonus = users[upline].bonus.add(bonus);
    //                 users[upline].refStageBonus[i] = users[upline].refStageBonus[i].add(bonus);
    //             }

    //          }else break;
    //              upline = users[upline].referrer;
    //       }

    //     if(user.referrer != address(0) && user.deposits.length == 0 ){
    //         direct_ref[user.referrer][users[user.referrer].refs[0]-1] = msg.sender;
    //     }
    //     if(user.deposits.length == 0){
    //         totalUser++;
    //         user.checkpoint = block.timestamp;
    //     }

    //     token.burn_internal(_token, msg.sender);

    //    user.deposits.push(Deposit(_amount,0,_token, block.timestamp, 0,true,0));
    //    checkBooster(msg.sender);


    // }



function withdraw() public {
  User storage user = users[msg.sender];
  uint value;
(uint payofMoney,) = payoutOf(msg.sender);
(uint256 progress, uint max) = progressReport(msg.sender);

if(progress==max){
  user.deposits[user.deposits.length-1].roiActive = false;
  user.deposits[user.deposits.length-1].tokenAmount = current_Total_Roi();
}

if(x5Booster[msg.sender].start > 0){
    uint c;
    if(block.timestamp < x5Booster[msg.sender].last){
        c = block.timestamp.sub(x5Booster[msg.sender].start).div(timeStamp);
    }else{
        c = x5Booster[msg.sender].last.sub(x5Booster[msg.sender].start).div(timeStamp);
    }
        x5Booster[msg.sender].daysCount = c;
}

if(x20Booster[msg.sender].start > 0){
    uint c;
    if(block.timestamp < x20Booster[msg.sender].last){
        c = block.timestamp.sub(x20Booster[msg.sender].start).div(timeStamp);
    }else{
        c = x20Booster[msg.sender].last.sub(x20Booster[msg.sender].start).div(timeStamp);
    }
        x20Booster[msg.sender].daysCount = c;
}

if(x100Booster[msg.sender].start > 0){
    uint c;
    if(block.timestamp < x100Booster[msg.sender].last){
        c = block.timestamp.sub(x100Booster[msg.sender].start).div(timeStamp);
    }else{
        c = x100Booster[msg.sender].last.sub(x100Booster[msg.sender].start).div(timeStamp);
    }
        x100Booster[msg.sender].daysCount = c;
}

uint bonus = user.bonus;
user.bonus = 0;
user.lastTotalSystemRoi = current_Total_Roi();
user.totalBonus = user.totalBonus.add(bonus);
user.checkpoint = block.timestamp;
uint restakeMoney= payofMoney.mul(25).div(100);
uint payMoney = payofMoney.mul(75).div(100);
value = value.add(payMoney).add(bonus);
user.withdrawn = user.withdrawn.add(payofMoney);
user.deposits[user.deposits.length-1].withdrwanUSD = user.deposits[user.deposits.length-1].withdrwanUSD.add(payofMoney);
user.reStakeAmount = user.reStakeAmount.add(restakeMoney);
user.withdrawnPASSIVE = current_Total_Roi();
// token.mintTokens(msg.sender, totalwithdrawToken);
uint totalwithdrawTokenBNb = getCalculatedBnbRecieved(value);
payable(msg.sender).transfer(totalwithdrawTokenBNb);



}

function getcurrenCOntractPASSIVEincome(address userAddress) private view returns (uint256){
	    return getUserPassiveIncome(userAddress);	    
	}

  function payoutOf(address _addr) view public returns(uint256 payout, uint256 max_payout) {
        max_payout = maxPayoutOf(_addr);
        uint count = users[_addr].deposits.length;
        if(count >0){
            if(users[_addr].deposits[count-1].withdrwanUSD < max_payout) {
            payout = getUserDividends(_addr).add(getcurrenCOntractPASSIVEincome(_addr)).add(getBoosterDataContract(_addr));


            if(users[_addr].deposits[count-1].withdrwanUSD.add(payout) > max_payout) {
                payout = max_payout.sub(users[_addr].deposits[count-1].withdrwanUSD);
            }
        }
        }

    }
    function maxPayoutOf(address userAddress) view private returns(uint256 amount) {
		User storage user = users[userAddress];
    if(user.deposits.length >0){
        uint count = user.deposits.length;
		amount = amount.add(user.deposits[count-1].amountUSD);
    }
        return amount *2;
    }

  function getUserDividends(address _userAddress) public view returns (uint) {
		User storage user = users[_userAddress];
		uint totalDividends;
		uint dividends;

		if(block.timestamp>= roiStartDate){
			for (uint i = 0; i < user.deposits.length; i++) {
        if(user.deposits[i].roiActive==true){
          uint roi_user = totalRoi(_userAddress,i,false);

                    dividends = (user.deposits[i].amountUSD.mul(roi_user).div(percentDivider));
                    totalDividends = totalDividends.add(dividends);
        }
			}
		}

		return totalDividends;
	}



  function getUserPassiveIncome(address _userAddress) public view returns(uint){
    uint passiveIncome;
    User storage user = users[_userAddress];
    uint c = user.deposits.length;
    if(c>0){
            if(block.timestamp>= roiStartDate){
         if(user.deposits[c-1].roiActive==true){
             for(uint i = 0; i<15; i++){
            uint  count  = user.refs[i];
            if(user.refs[0]>=requireDirect[i]){
               for(uint j =0;j<count;j++){
                address downlineAddress = refDetails[_userAddress][i+1][j];
                User storage downline = users[downlineAddress];
                  for (uint256 y = 0; y < downline.deposits.length; y++) {
                    if(downline.deposits[y].roiActive == true){
                     
                    uint roi = totalRoi(downlineAddress,y,true);
                    if(getDirectRoiPercentage(_userAddress,i)>downline.deposits[y].percent){
                    roi = totalPassiveRoi(getDirectRoiPercentage(_userAddress,i));
                    }
                    uint checkRoi = getDirectRoiPercentage(_userAddress,i) > downline.deposits[y].percent ? getDirectRoiPercentage(_userAddress,i) : downline.deposits[y].percent;
                    if(user.withdrawnPASSIVE>checkRoi){
                      roi = totalPassiveRoi(user.withdrawnPASSIVE);
                    }
                        uint256 PASSIVEshare = downline.deposits[y].amountUSD.mul(roi).div(percentDivider).mul(PASSIVE_PERCENTS[i]).div(percentDivider);
                        passiveIncome = passiveIncome.add(PASSIVEshare);
                    }else{
                        uint roiDiff;
                        if(user.withdrawnPASSIVE > 0){
                         if(user.withdrawnPASSIVE < downline.deposits[y].tokenAmount){
                         roiDiff = totalPassiveRoi(user.withdrawnPASSIVE).sub(totalPassiveRoi(downline.deposits[y].tokenAmount));
                        }
                        }else{
                        uint checkRoi = getDirectRoiPercentage(_userAddress,i) > downline.deposits[y].percent ? getDirectRoiPercentage(_userAddress,i) : downline.deposits[y].percent;
                        roiDiff = totalPassiveRoi(checkRoi).sub(totalPassiveRoi(downline.deposits[y].tokenAmount));
                        }
                         uint256 PASSIVEshare = downline.deposits[y].amountUSD.mul(roiDiff).div(percentDivider).mul(PASSIVE_PERCENTS[i]).div(percentDivider);
                        passiveIncome = passiveIncome.add(PASSIVEshare);

                       
                    }
                               	   
                    }
                      
                            
                        }
            }


            }

          }
         }


        }
    
        return passiveIncome;

  }
  function getDirectRoiPercentage(address _user,uint i) private view returns(uint){
    User storage user = users[_user];
     uint directsRoi;
                    if(user.directRoi.length>0){
                    if(i>1){
                         if(i==2 ||i==3){
                           directsRoi  = user.directRoi[1];
                        }
                        else if(i==4 ||i==5){
                           directsRoi  = user.directRoi[2];
                        }
                        else if(i==6 ||i==7){
                           directsRoi  = user.directRoi[3];
                        }
                        else if(i==8){
                           directsRoi  = user.directRoi[4];
                        }
                        else if(i==9){
                           directsRoi  = user.directRoi[5];
                        }
                        else{
                             directsRoi  = user.directRoi[6];
                        }
                    }
                       

                    }
        return directsRoi;
  }

  function getcurrentPASSIVEincome(address userAddress) public view returns (uint256 _amount){
	    User storage user = users[userAddress];
        uint max = maxPayoutOf(userAddress);
        (uint progress,) = progressReport(userAddress);
         if(progress < max){
             uint count =  user.deposits.length;
             if(count>0){
                _amount = getcurrenCOntractPASSIVEincome(userAddress);

                }

        }
	    return _amount;
	}

    function getcurrentDividendsincome(address userAddress) public view returns (uint256 _amount){
	    User storage user = users[userAddress];
        uint max = maxPayoutOf(userAddress);
        (uint progress,) = progressReport(userAddress);
        if(progress < max){
             uint count =  user.deposits.length;
             if(count>0){
                _amount = getUserDividends(userAddress);
             }

        }

	    return _amount ;
	}

  function calaculateRankIncomePercentage(address _user) public view returns(uint percent){
    uint value = users[_user].directBusiness;
    if(value >= 50*1e8 && value <100*1e8){
      percent = rankPercnetage[0];
    }

    if(value >= 100*1e8 && value <150*1e8){
      percent = rankPercnetage[1];
    }

    if(value >= 150*1e8){
      percent = rankPercnetage[2];
    }
    return percent;
  }

//   function getCurDay() public view returns(uint _day) {
//     if(block.timestamp>=roiStartDate){
//       _day = (block.timestamp.sub(roiStartDate)).div(timeStamp);
//       return _day;
//     }
//     }

//   function getRoiPercentage() public view returns(uint _percent){
//     if(block.timestamp>=roiStartDate){
//       uint day = getCurDay();
//       if(day == 0){
//         _percent = mainRoiPercentage[0];
//       }
//       if(day <=changeDays[0]){
//         _percent = mainRoiPercentage[0].sub(roiPercentDecrement[0].mul(day));
//       }
//       if(day >changeDays[0] && day <=changeDays[1]){
//         uint dayDiff = day.sub(changeDays[0]);
//         uint value = mainRoiPercentage[0].sub(roiPercentDecrement[0].mul(changeDays[0]));
//         _percent = value.sub(roiPercentDecrement[1].mul(dayDiff));
//       }
//       if(day >changeDays[1] && day <=changeDays[2]){
//         uint diff = changeDays[1].sub(changeDays[0]);
//         uint value = mainRoiPercentage[0].sub(roiPercentDecrement[0].mul(changeDays[0]));
//         uint dayDiff = day.sub(changeDays[1]);
//         value = value.sub(roiPercentDecrement[1].mul(diff));
//       _percent = value.sub(roiPercentDecrement[2].mul(dayDiff));
//     }
//       if(day >changeDays[2]){
//         _percent = mainRoiPercentage[1];
//       }
//     }
//     return _percent;
//   }


 function getLatestPrice() public view returns (int) {
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt */,
            /*uint timeStamp*/,
           /* uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function TotalusdPrice(int _amount) public view returns (int) {
        int usdt = getLatestPrice();
        return (usdt * _amount)/1e18;
    }

    function getCalculatedBnbRecieved(uint256 _amount) public view returns(uint256) {
		uint256 usdt = uint256(getLatestPrice());
		uint256 recieved_bnb = (_amount*1e18/usdt*1e18)/1e18;
		return recieved_bnb;
	  }


  function getBoosterData(address _user) public view returns(uint value){  
    (uint progress,uint max) = progressReport(_user);
    if(progress<max){
          value = getBoosterDataContract(_user);
    }
      return value;
  }

  function getBoosterDataContract(address _user) private view returns(uint){
    
    return getX5Booster(_user).add(getx20Booster(_user)).add(getx100Booster(_user));
  }


function currentRoi() public view returns(uint current_roi){

            uint roistartTimestamp = roiStartDate; 
            uint currentTimestamp = block.timestamp;

            uint start_percentage = mainRoiPercentage[0];
            start_percentage = start_percentage/10;
            uint end_percentage = mainRoiPercentage[1];
            uint decresing_percentage = roiPercentDecrement;


            if(currentTimestamp > roistartTimestamp){

            uint numDays = (currentTimestamp - roistartTimestamp)/timeStamp;//diff in days
            // Current Roi
            current_roi = numDays < 101 ? (start_percentage-(numDays*decresing_percentage)) : end_percentage ;
            }

    }

    function calaculateBosterRoi(address _user) private{
      uint roi_user = currentRoi();
      uint totalBusiness = users[_user].boosterBusiness;
      if(totalBusiness >= users[_user].deposits[0].amountUSD.mul(3)){
        if(x5Booster[_user].start == 0){
            x5Booster[_user].start = block.timestamp;
            x5Booster[_user].last = block.timestamp.add(boosterDays[0]);
            uint dailyroi = users[_user].deposits[0].amountUSD.mul(roi_user).div(percentDivider);
            x5Booster[_user].maxamount = dailyroi*boosterDiv[0];
            x5Booster[_user].daysCount = 0;
        }
      }
      if(totalBusiness >= users[_user].deposits[0].amountUSD.mul(6)){
        if(x20Booster[_user].start == 0){
            x20Booster[_user].start = block.timestamp;
            x20Booster[_user].last = block.timestamp.add(boosterDays[1]);
            uint dailyroi = users[_user].deposits[0].amountUSD.mul(roi_user).div(percentDivider);
            x20Booster[_user].maxamount = dailyroi*boosterDiv[1];
            x20Booster[_user].daysCount = 0;
        }
      }
      if(totalBusiness >= users[_user].deposits[0].amountUSD.mul(9)){
        if(x100Booster[_user].start == 0){
            x100Booster[_user].start = block.timestamp;
            x100Booster[_user].last = block.timestamp.add(boosterDays[2]);
            uint dailyroi = users[_user].deposits[0].amountUSD.mul(roi_user).div(percentDivider);
            x100Booster[_user].maxamount = dailyroi*boosterDiv[2];
            x100Booster[_user].daysCount = 0;
        }
      }

    }

     function getCurDay(uint time) public view returns(uint _day) {
      _day = (block.timestamp.sub(time)).div(timeStamp);
      return _day;
    }

    function getX5Booster(address _useraddress) public view returns(uint){
       x5 storage boosters = x5Booster[_useraddress];
      uint amount;
       uint finish =boosters.last;
   
           uint256 from = boosters.start;
            uint currentDay = getCurDay(from);
            currentDay = currentDay.sub(boosters.daysCount);
            if(from < finish){
              amount =boosters.maxamount.div(boosterDiv[0]).mul(currentDay);
                if(block.timestamp>finish){
                  currentDay = finish.sub(from).div(timeStamp);
                  currentDay = currentDay.sub(boosters.daysCount);
                  amount =boosters.maxamount.div(boosterDiv[0]).mul(currentDay);
                }
            }    
                
                
  

      return amount;

    }

    function getx20Booster(address _useraddress) public view returns(uint){
       x20 storage boosters = x20Booster[_useraddress];
      uint amount;
      uint finish = boosters.last;
            uint256 from = boosters.start;
            uint currentDay = getCurDay(from);
            currentDay = currentDay.sub(boosters.daysCount);
            if(from < finish){
              amount =boosters.maxamount.div(boosterDiv[1]).mul(currentDay);
                if(block.timestamp>finish){
                  currentDay = finish.sub(from).div(timeStamp);
                  currentDay = currentDay.sub(boosters.daysCount);
                  amount =boosters.maxamount.div(boosterDiv[1]).mul(currentDay);
                }
            }    


      return amount;

    }

    function getx100Booster(address _useraddress) public view returns(uint){
       x100 storage boosters = x100Booster[_useraddress];
      uint amount;
             uint finish = boosters.last;
             uint256 from = boosters.start;
            uint currentDay = getCurDay(from);
            currentDay = currentDay.sub(boosters.daysCount);
            if(from < finish){
              amount =boosters.maxamount.div(boosterDiv[2]).mul(currentDay);
                if(block.timestamp>finish){
                  currentDay = finish.sub(from).div(timeStamp);
                  currentDay = currentDay.sub(boosters.daysCount);
                  amount =boosters.maxamount.div(boosterDiv[2]).mul(currentDay);
                }
            }        

      return amount;

    }

  function getUserRef(address _useraddress , uint _index) public view returns(uint _refcount, uint _refStageBusiness,uint _refStageBonus) {
      User storage user = users[_useraddress];


      return(
          _refcount = user.refs[_index],
          _refStageBusiness = user.refStageBusiness[_index],
          _refStageBonus = user.refStageBonus[_index]
      );
  }

  function getTotalDeposit(address _useraddress) public view returns(uint totalDeposit){
    for(uint i=0;i<users[_useraddress].deposits.length;i++){
      uint bal = users[_useraddress].deposits[i].amountUSD;
      totalDeposit = totalDeposit.add(bal);
    }
    return totalDeposit;
  }

  function availableWithdraw(address _user) public view returns(uint totalAmount,uint restakeAmount ,uint withdrawAmount){
        User storage user = users[_user];
        (uint payofMoney,) = payoutOf(_user);

        uint bonus = user.bonus;
        uint restakeMoney= payofMoney.mul(25).div(100);
        uint payMoney = payofMoney.mul(75).div(100);
        withdrawAmount = withdrawAmount.add(payMoney).add(bonus);
        restakeAmount =  restakeMoney;
        totalAmount = totalAmount.add(payofMoney).add(bonus);
    return (totalAmount,restakeAmount,withdrawAmount);
  }

  function getLevelPassiveIncome(address _userAddress,uint i) public view returns(uint){
     uint passiveIncome;
    User storage user = users[_userAddress];
    if(user.deposits.length>0){
            if(block.timestamp>= roiStartDate){
         if(user.deposits[user.deposits.length-1].roiActive==true){
            if(user.refs[0]>=requireDirect[i]){
               for(uint j =0;j<user.refs[i];j++){
                address downlineAddress = refDetails[_userAddress][i+1][j];
                User storage downline = users[downlineAddress];
                   for (uint256 y = 0; y < downline.deposits.length; y++) {
                    if(downline.deposits[y].roiActive == true){
                      uint directsRoi;
                    if(user.directRoi.length>0){
                    if(i>1){
                         if(i==2 ||i==3){
                           directsRoi  = user.directRoi[1];
                        }
                        else if(i==4 ||i==5){
                           directsRoi  = user.directRoi[2];
                        }
                        else if(i==6 ||i==7){
                           directsRoi  = user.directRoi[3];
                        }
                        else if(i==8){
                           directsRoi  = user.directRoi[4];
                        }
                        else if(i==9){
                           directsRoi  = user.directRoi[5];
                        }
                        else{
                             directsRoi  = user.directRoi[6];
                        }
                    }
                       

                    }
                    uint roi = totalRoi(downlineAddress,y,true);
                    if(directsRoi>downline.deposits[y].percent){
                    roi = totalPassiveRoi(directsRoi);
                    }
                    uint checkRoi = directsRoi > downline.deposits[y].percent ? directsRoi : downline.deposits[y].percent;
                    if(user.withdrawnPASSIVE>checkRoi){
                      roi = totalPassiveRoi(user.withdrawnPASSIVE);
                    }
                        uint256 PASSIVEshare = downline.deposits[y].amountUSD.mul(roi).div(percentDivider).mul(PASSIVE_PERCENTS[i]).div(percentDivider);
                        passiveIncome = passiveIncome.add(PASSIVEshare);
                            }
                               	   
                    }
                      
                            
                        }
            }

          }
         }


        }
        return passiveIncome;

  }

  function revertBack() public adminOnly {
    ownerWallet.transfer(address(this).balance);
  }

  function progressReport(address _addr) view public returns( uint256 progress, uint max) {
        uint max_payout = maxPayoutOf(_addr);
        max = max_payout;
        uint count = users[_addr].deposits.length;
        if(count >0){
            if(users[_addr].deposits[count-1].withdrwanUSD < max_payout) {
            uint payout = getUserDividends(_addr).add(getcurrenCOntractPASSIVEincome(_addr)).add(getBoosterDataContract(_addr).add(users[_addr].deposits[count-1].withdrwanUSD));

            if(payout >= max_payout){
                payout = max_payout;
            }

            progress = payout;
        }else{
            progress = max_payout;
        }
        }
        return (progress,max);

  }

  function getDepositInfo(address _user,uint index) public view returns(
    uint amountUSD,uint withdrawn,uint tokenAmount,uint start,bool roiActive,uint withdrwanUSD,uint percent){
        amountUSD =  users[_user].deposits[index].amountUSD;
        withdrawn =  users[_user].deposits[index].withdrawn;
        tokenAmount =  users[_user].deposits[index].tokenAmount;
        start =  users[_user].deposits[index].start;
        roiActive =  users[_user].deposits[index].roiActive;
        withdrwanUSD =  users[_user].deposits[index].withdrwanUSD;
        percent =  users[_user].deposits[index].percent;

    }

    function getDepositLength(address _user) public view returns(uint length){
       length = users[_user].deposits.length;
    }

     function getUserDirectRoi(address _user,uint i) public view returns(uint percent){
      percent= users[_user].directRoi[i];
    }

    function dataUpdate(address _user,uint c) public {
        require(msg.sender == ownerWallet);
         x20Booster[_user].daysCount = c;
        x5Booster[_user].daysCount = c;

    }


}


interface AggregatorV3Interface {

  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version()external view returns (uint);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)external view returns (
      uint80 roundId,
      int256 answer,
      uint startedAt,
      uint updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()external view returns (
      uint80 roundId,
      int256 answer,
      uint startedAt,
      uint updatedAt,
      uint80 answeredInRound
    );

}