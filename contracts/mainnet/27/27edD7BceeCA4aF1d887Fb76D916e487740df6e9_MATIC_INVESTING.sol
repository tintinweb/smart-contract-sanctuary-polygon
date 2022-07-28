/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

/***
 *
 * ███╗   ███╗ █████╗ ████████╗██╗ ██████╗    ██╗███╗   ██╗██╗   ██╗███████╗███████╗████████╗██╗███╗   ██╗ ██████╗ 
 * ████╗ ████║██╔══██╗╚══██╔══╝██║██╔════╝    ██║████╗  ██║██║   ██║██╔════╝██╔════╝╚══██╔══╝██║████╗  ██║██╔════╝ 
 * ██╔████╔██║███████║   ██║   ██║██║         ██║██╔██╗ ██║██║   ██║█████╗  ███████╗   ██║   ██║██╔██╗ ██║██║  ███╗
 * ██║╚██╔╝██║██╔══██║   ██║   ██║██║         ██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  ╚════██║   ██║   ██║██║╚██╗██║██║   ██║
 * ██║ ╚═╝ ██║██║  ██║   ██║   ██║╚██████╗    ██║██║ ╚████║ ╚████╔╝ ███████╗███████║   ██║   ██║██║ ╚████║╚██████╔╝
 * ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝    ╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚══════╝╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
 *   *cc                                                                                                             
 *
 *
 *      * Benefits *
 *      ************
 *      🚀 Get 3 Matic Free 
 *      🚀 ROI 5% Daily (all Bonus)
 *      🚀 Earn up to 300%
 *      withdrawal at any time: Minumum 10 Matic
 *
 *      Referral Earnings
 *      🚀 5% first Level
 *      🚀 4% Second Level
 *      🚀 3% Third Level
 *      🚀 2% Second Level
 *      🚀 1% Third Level
 *
 * 		More information:
 * 		-Telegram: https://t.me/maticinvesting
 * 		-Web:  https://maticinvesting.online
 *
 *
 */


// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.6;

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}




library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}



struct daysPercent {
    uint8 life_days;
    uint8 percent;
}

struct DepositStruct {
    uint256 amount;
    uint40 time;
    uint256 withdrawn;
}

struct Investor {
    address daddy;
    uint256 dividends;
    uint256 matchBonus;
    uint40 lastPayout;
    uint256 lastWithdrawn;
    uint256 totalInvested;
    uint256 toatlReinvested;
    uint256 totalWithdrawn;
    uint256 totalBonus;
    DepositStruct [] depositsArray;
    mapping(uint256=>uint256) referralEarningsL;  
    uint256[5] structure;
    uint256 directPaiReferralCount;
    uint256 reinvestCount;
}

contract MATIC_INVESTING {
    using SafeMath for uint256;
    using SafeMath for uint40;

    uint256 public contractInvested;
    uint256 public contractWithdrawn;
    uint256 public matchBonus;
    uint256 public totalUsers;

    uint256 constant public ceoFee = 40;
    uint256 constant public devFee = 40;
    uint256 constant public adminFee = 40;
    uint256 constant public marketingFee = 30;
    address payable public ceoWallet = payable(0x26655ec7006B17b6c1f5eC82edDe18A93a33702A);
    address payable public devWallet = payable(0x7EDdf6Cd6e3B9BB5262eF59fba576e3f1Ec499B2);
    address payable public adminWallet = payable(0x198be84A35Bb42BF7da19a7Cc48BF1a3783a8e60);
    address payable public marketingWallet = payable(0x3cA2698F0d021ef32Baa5e0aD53cB8ADe0B531d1);

    uint16 constant percentDivider = 1000;
    uint8[5] public referralBonus = [50,40,30,20,10];
    uint40 public TIME_STEP = 24 hours;
    uint8 public Daily_ROI = 10;
    uint8 public MAX_ROI = 50;
    uint256 public MIN_INVESTMENT = 10 ether;
    uint256 public MIN_WITHDRAW = 10 ether;
    uint256 public MIN_REINVESTMENT = 100 ether;
    uint256 public REFERRAL_STEP = 10;
    uint256 public REGISTRATION_BONUS = 3 ether;

  
    mapping(address => Investor) public investorsMap;
    mapping(address=>bool) public isExist;

   

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
  
    constructor() {
        
    }

    function _payInvestor(address _addr) private {
        uint256 payout = calcPayoutInternal(_addr);
        if (payout > 0) {
            investorsMap[_addr].lastPayout = uint40(block.timestamp);
            investorsMap[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = investorsMap[_addr].daddy;
        uint i = 0;
        for (i = 0; i < 5; i ++) {
            if(up == address(0)) break;
            uint256 bonus = _amount * referralBonus[i] / percentDivider;
            investorsMap[up].matchBonus += bonus;
            investorsMap[up].totalBonus += bonus;
            matchBonus += bonus;
            emit MatchPayout(up, _addr, bonus);
            investorsMap[up].referralEarningsL[i]=investorsMap[up].referralEarningsL[i].add(bonus);
            up = investorsMap[up].daddy;
        }
        
        for(uint256 j=i;j< 5;j++){
            uint256 bonus = _amount * referralBonus[j] / percentDivider;
            
            investorsMap[ceoWallet].matchBonus +=  bonus.mul(60).div(100);
            investorsMap[ceoWallet].totalBonus += bonus.mul(60).div(100);
            
            investorsMap[devWallet].matchBonus +=  bonus.mul(40).div(100);
            investorsMap[devWallet].totalBonus += bonus.mul(40).div(100);
        }
    }

    function _setUpdaddy(address _addr, address _upline) private {
        if (investorsMap[_addr].daddy == address(0) && _addr != ceoWallet && investorsMap[_upline].depositsArray.length > 0) {

            investorsMap[_addr].daddy = _upline;

            for(uint i = 0; i < 5; i++) {
                investorsMap[_upline].structure[i]++;

                _upline = investorsMap[_upline].daddy;

                if(_upline == address(0)) break;
            }

        }
    }

    function register(address _upline) external
    {
        Investor storage investor = investorsMap[msg.sender];

        require(!isExist[msg.sender],"Allready registered");
        _setUpdaddy(msg.sender, _upline);
        investor.depositsArray.push(DepositStruct({
            amount: REGISTRATION_BONUS,
            time: uint40(block.timestamp),
            withdrawn:0
        }));
        investor.totalInvested += REGISTRATION_BONUS;
        investor.lastWithdrawn = uint40(block.timestamp);
        isExist[msg.sender] = true;
        totalUsers++;
    }

    function deposit() external payable{ 
        uint256 amount = msg.value;
        require(amount >= MIN_INVESTMENT, "Minimum deposit amount is 10 Matic");

        Investor storage investor = investorsMap[msg.sender];
        require(isExist[msg.sender],"Not registered");
        require(investor.depositsArray.length < 100, "Max 100 deposits per address");

        uint256 cfee  = amount.mul(ceoFee).div(percentDivider);
        ceoWallet.transfer(cfee);
        devWallet.transfer(cfee);
        adminWallet.transfer(cfee);

        uint256 mfee  = amount.mul(marketingFee).div(percentDivider);
        marketingWallet.transfer(mfee);


        if(investor.depositsArray.length==1)
        {
            investorsMap[investor.daddy].directPaiReferralCount++; 
        }
        
        investor.lastWithdrawn = uint40(block.timestamp);
        investor.depositsArray.push(DepositStruct({
            amount: amount,
            time: uint40(block.timestamp),
            withdrawn:0
        }));
        
         
        
        investor.totalInvested += amount;
        contractInvested += amount;

        _refPayout(msg.sender, amount);

        emit NewDeposit(msg.sender, amount);

    }

    function reinvest() external{ 
        _payInvestor(msg.sender);
        Investor storage investor = investorsMap[msg.sender];

        uint256 amount = investor.dividends + investor.matchBonus;

        require(amount >= MIN_REINVESTMENT, "Minimum deposit amount is 10 MATIC");
        

        require(investor.depositsArray.length < 100, "Max 100 deposits per address");

        investor.depositsArray.push(DepositStruct({
            amount: amount,
            time: uint40(block.timestamp),
            withdrawn:0
        }));

        investor.dividends = 0;
        investor.matchBonus = 0;
        investor.totalWithdrawn += amount;

        investor.toatlReinvested += amount;
        investor.totalInvested += amount;
        contractInvested += amount;
        investor.reinvestCount++;

        _refPayout(msg.sender, amount);

        emit NewDeposit(msg.sender, amount);

    }



    function withdraw() external { 
        Investor storage investor = investorsMap[msg.sender];
       
        _payInvestor(msg.sender);

        require(investor.dividends > 0 || investor.matchBonus > 0);

        uint256 amount = investor.dividends + investor.matchBonus;

        require(amount>=MIN_WITHDRAW,"Below min withdraw");

        investor.dividends = 0;
        investor.matchBonus = 0;
        investor.totalWithdrawn += amount;
        investor.lastWithdrawn = uint40(block.timestamp);

        contractWithdrawn += amount;

        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function getUserPercent(address userAddress) public view returns (uint256 roiPer)
    {
        Investor storage investor = investorsMap[userAddress];
		
			uint256 timeMultiplier = (investor.directPaiReferralCount).div(REFERRAL_STEP);
            uint256 holdBonus = ((block.timestamp).sub(investor.lastWithdrawn)).div(TIME_STEP);
            if(holdBonus>10)
            {
                holdBonus = 10;
            }
            uint256 roi = Daily_ROI + timeMultiplier + investor.reinvestCount+holdBonus;
			if (roi > MAX_ROI) {
                roi = MAX_ROI;
            }
			return roi;
		
    }

    function getCurrentPercent(address userAddress) external view returns (uint256 _referralPer,uint256 _holdBonus,uint256 _roiPer)
    {
        Investor storage investor = investorsMap[userAddress];
		
			uint256 timeMultiplier = (investor.directPaiReferralCount).div(REFERRAL_STEP);
            uint256 holdBonus = ((block.timestamp).sub(investor.lastWithdrawn)).div(TIME_STEP);
            if(holdBonus>10)
            {
                holdBonus = 10;
            }
           
			return (timeMultiplier,holdBonus,investor.reinvestCount);
    }


    
    function calcPayoutInternal(address _addr) internal returns (uint256 value) {
        Investor storage investor = investorsMap[_addr];
        uint256 roiPer = getUserPercent(_addr);

        for (uint256 i = 0; i < investor.depositsArray.length; i++) {
            DepositStruct storage iterDeposits = investor.depositsArray[i];
            
            uint40 time_end = iterDeposits.time + 300 * TIME_STEP;
            uint40 from = investor.lastPayout > iterDeposits.time ? investor.lastPayout : iterDeposits.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);
            uint256 dividends = 0;
            if (from < to) {

                dividends = iterDeposits.amount.mul(to.sub(from)).mul(roiPer).div(TIME_STEP.mul(percentDivider));

                if(dividends.add(iterDeposits.withdrawn)>=iterDeposits.amount.mul(3)){
                    dividends = iterDeposits.amount.mul(3).sub(iterDeposits.withdrawn);
                }
                
            }
           
            value +=dividends;
            iterDeposits.withdrawn = iterDeposits.withdrawn.add(dividends);
        }
        return value;
    }

   
   
    function calcPayout(address _addr) view external returns (uint256 value) {
        Investor storage investor = investorsMap[_addr];
        uint256 roiPer = getUserPercent(_addr);

        for (uint256 i = 0; i < investor.depositsArray.length; i++) {
            DepositStruct storage iterDeposits = investor.depositsArray[i];
            
            uint40 time_end = iterDeposits.time + 300 * TIME_STEP;
            uint40 from = investor.lastPayout > iterDeposits.time ? investor.lastPayout : iterDeposits.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);
            uint256 dividends = 0 ;
            if (from < to) {
                dividends = iterDeposits.amount.mul(to.sub(from)).mul(roiPer).div(TIME_STEP.mul(percentDivider));
                if(dividends.add(iterDeposits.withdrawn)>=iterDeposits.amount.mul(3)){
                    dividends = iterDeposits.amount.mul(3).sub(iterDeposits.withdrawn);
                }
            }
           
            value +=dividends;

        }
        return value;
    }
    
    function getAllDeposits(address _addr) view external returns(DepositStruct[] memory deposits){
        Investor storage investor = investorsMap[_addr];
        return investor.depositsArray;
    }

    function depositeCount(address _addr) view external returns(uint256 count){
        Investor storage investor = investorsMap[_addr];
        return investor.depositsArray.length;
    }

   function getDeposite(address _addr,uint256 index) view external returns(DepositStruct memory deposits){
        Investor storage investor = investorsMap[_addr];
        return investor.depositsArray[index];
    }

    function userInfo(address _addr) view external returns( 
        uint256 for_withdraw, 
        uint256 totalInvested, 
        uint256 totalWithdrawn, 
        uint256 totalBonus,
        uint256 _matchBonus,
        uint256 userPercent
        ) {
        Investor storage investor = investorsMap[_addr];
        uint256 payout = this.calcPayout(_addr);
        return (
            payout + investor.dividends,
            investor.totalInvested,
            investor.totalWithdrawn,
            investor.totalBonus,
            investor.matchBonus,
            getUserPercent(_addr)
            );
    }

    function referralEarningInfo(address _addr) view external returns( 
        uint256[5] memory structure,
        uint256[5] memory referralEarningsL
    )
    {
                Investor storage investor = investorsMap[_addr];

         for(uint8 i = 0; i <5; i++) {
            structure[i] = investor.structure[i];
            referralEarningsL[i]=investor.referralEarningsL[i];
        }

        return (
            structure,
            referralEarningsL
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus,uint256 _totalUsers) {
        return (contractInvested, contractWithdrawn, matchBonus,totalUsers);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
  
    


}