/**
 *Submitted for verification at polygonscan.com on 2023-06-17
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17; 

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
contract owned
{
    address internal owner;
    address internal newOwner;
    address public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



//*******************************************************************//
//------------------         token interface        -------------------//
//*******************************************************************//

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }



//*******************************************************************//
//------------------        MAIN contract         -------------------//
//*******************************************************************//

contract Meta_Power_Main is owned {


    uint public minInvestAmount;
    uint public maxInvestAmount;

    address public tokenAddress;
    uint public oneDay = 1 days; // this can be changed for testing,  like '30 min' , '100' etc
    uint public maxPayout = 30000; // = 300%

     struct userInfo {
        uint joinTime;
        address referrer;
        uint investedAmount;
        uint returnPercent;
        uint lastWithdrawTime;
        uint totalPaidROI;
        bool capped;
    }

    mapping(address => uint) public totalBusiness;
    mapping(address => uint) public totalBusinessFrom;
    mapping(address => uint) public totalInvest;
    mapping(address => uint) public totalPaid;

    mapping ( address => address[]) public referred;
    mapping ( address => uint) public bonus; // 
    mapping ( address => uint[10]) public lastBonusTime; // 
    mapping ( address => uint[10]) public totalBonusPaid; //
    mapping (address => uint) public referralWithdraw;
    mapping (address => uint) public totalReferralWithdraw;
    mapping (address => uint) public mentorGain;
    mapping (address => uint) public totalMentorGain;

    mapping (address => uint) public totalTeam;

    mapping ( address => userInfo[]) public userInfos;
    mapping(address => uint) public investIndexCount;





    uint public defaultROI = 50 ; // equal to 0.5% daily 
                             
    uint public div = 10 ** 4; // for roi percent calculation
    uint[10] public levelIncome; // values in percent
    uint[10] public mentorROI; // values in percent
    uint[10] public bonusTarget; // values in percent
    uint[10] public rewardBonus; // values in percent

    constructor () {


    }

    function initialise0 () public onlyOwner returns(bool) {
        require(investIndexCount[msg.sender] == 0, "can't call twice");
        userInfo memory UserInfo;

        UserInfo = userInfo({
            joinTime: block.timestamp,
            referrer: msg.sender,
            investedAmount: 1,  
            returnPercent: defaultROI,
            lastWithdrawTime: block.timestamp,
            totalPaidROI: 0,
            capped: false
        });
        userInfos[msg.sender].push(UserInfo);
        investIndexCount[msg.sender] = 1;
        return true;
    }


    function initialize1() public onlyOwner returns (bool) {

        require(levelIncome[0] == 0, "can't call twice");

        levelIncome[0] = 1000; // for level 1
        levelIncome[1] = 200; // for level 2
        levelIncome[2] = 100; // for level 3
        levelIncome[3] = 100; // for level 4
        levelIncome[4] = 50; // for level 5
        levelIncome[5] = 50; // for level 6
        levelIncome[6] = 25; // for level 7
        levelIncome[7] = 25; // for level 8
        levelIncome[8] = 25; // for level 9
        levelIncome[9] = 25; // for level 10

        mentorROI[0] = 1500; // for level 1
        mentorROI[1] = 1000; // for level 2
        mentorROI[2] = 100; // for level 3
        mentorROI[3] = 400; // for level 4
        mentorROI[4] = 200; // for level 5
        mentorROI[5] = 200; // for level 6
        mentorROI[6] = 300; // for level 7
        mentorROI[7] = 400; // for level 8
        mentorROI[8] = 200; // for level 9
        mentorROI[9] = 300; // for level 10

        bonusTarget[0] = 2000 * (10 ** 18); // for level 1
        bonusTarget[1] = 5000 * (10 ** 18); // for level 2
        bonusTarget[2] = 15000 * (10 ** 18); // for level 3
        bonusTarget[3] = 35000 * (10 ** 18); // for level 4
        bonusTarget[4] = 90000 * (10 ** 18); // for level 5
        bonusTarget[5] = 150000 * (10 ** 18); // for level 6
        bonusTarget[6] = 300000 * (10 ** 18); // for level 7
        bonusTarget[7] = 600000 * (10 ** 18); // for level 8
        bonusTarget[8] = 1000000 * (10 ** 18); // for level 9
        bonusTarget[9] = 1500000 * (10 ** 18); // for level 10

        rewardBonus[0] = 1 * (10 ** 18); // for level 1
        rewardBonus[1] = 25 * (10 ** 17); // for level 2
        rewardBonus[2] = 11 * (10 ** 18); // for level 3
        rewardBonus[3] = 24 * (10 ** 18); // for level 4
        rewardBonus[4] = 55 * (10 ** 18); // for level 5
        rewardBonus[5] = 120 * (10 ** 18); // for level 6
        rewardBonus[6] = 240 * (10 ** 18); // for level 7
        rewardBonus[7] = 440 * (10 ** 18); // for level 8
        rewardBonus[8] = 740 * (10 ** 18); // for level 9
        rewardBonus[9] = 1001 * (10 ** 18); // for level 10
        return true;
    }


    function setTokenAddress(address _tokenAddress) public onlyOwner returns(bool){
        tokenAddress = _tokenAddress;
        return true;
    }

    function setInvestAmountCap(uint _min, uint _max) public onlyOwner returns(bool){
        minInvestAmount = _min;
        maxInvestAmount = _max;
        return true;
    }

    event newJnvestEv(address user, address referrer,uint amount,uint eventTime);
    event nextJnvestEv(address user, uint amount,uint eventTime, uint investIndex);
    event directPaidEv(address paidTo,uint level,uint amount,address user,uint eventTime);

    event bonusEv(address receiver,address sender,uint newPercent,uint eventTime);

    function firstInvest(address _referrer, uint _amount) public returns(bool) {
        require(userInfos[msg.sender].length == 0, "already invested");
        require(userInfos[_referrer].length > 0, "Invalid referrer");
        require(_amount >= minInvestAmount && _amount <= maxInvestAmount, "Invalid Amount");
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        userInfo memory UserInfo;

        UserInfo = userInfo({
            joinTime: block.timestamp,
            referrer: _referrer,
            investedAmount: _amount,  
            returnPercent: defaultROI,
            lastWithdrawTime: block.timestamp,
            totalPaidROI: 0,
            capped: false
        });
        userInfos[msg.sender].push(UserInfo);
        totalInvest[msg.sender] += _amount;
        investIndexCount[msg.sender] = 1;
        referred[_referrer].push(msg.sender);

        emit newJnvestEv(msg.sender, _referrer, _amount, block.timestamp);


        // pay direct
        address _ref = _referrer;
        address lastRef = msg.sender;
        

        for(uint i=0;i<10;i++) {
            totalBusiness[_ref] += _amount;
            totalTeam[_ref] += 1;
            totalBusinessFrom[lastRef] += _amount;
            uint amt = _amount * levelIncome[i] / 10000;
            
            // chek for max pay limit
            uint tp = totalPaid[_ref];
            if ( tp + amt > totalInvest[_ref]  * maxPayout / 10000  ) {
                amt = (totalInvest[_ref] * maxPayout / 10000 ) - tp;
                capReached(_ref);
            }
            referralWithdraw[_ref] += amt;
            totalReferralWithdraw[_ref] += amt;
            totalPaid[_ref] += amt;

            emit directPaidEv(_ref, i, amt, msg.sender, block.timestamp);
            lastRef = _ref;
            _ref = userInfos[_ref][0].referrer;
        }

        userInfo memory temp = userInfos[_referrer][0];
        //if booster
        if(!temp.capped && block.timestamp - temp.joinTime <= 30 * oneDay && _amount >= temp.investedAmount && temp.investedAmount >= ( 10* ( 10**19 ) ) && _amount >= (10 * (10 ** 19)) && temp.returnPercent < 125 ) {
            temp.returnPercent = temp.returnPercent + 10; // increase = 0.1 % daily 
            if ( temp.returnPercent > 100 )  temp.returnPercent = 125; // persecond increase = 1.25 %
            emit bonusEv(_referrer, msg.sender, temp.returnPercent, block.timestamp);
            userInfos[_referrer][0].returnPercent = temp.returnPercent;
        }

        return true;
    }

    function nextInvest(uint _amount) public returns(bool) {

        require(_amount >= minInvestAmount && _amount <= maxInvestAmount, "Invalid Amount");
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        userInfo memory UserInfo;

        UserInfo = userInfo({
            joinTime: block.timestamp,
            referrer: userInfos[msg.sender][0].referrer,
            investedAmount: _amount,  
            returnPercent: defaultROI,
            lastWithdrawTime: block.timestamp,
            totalPaidROI: 0,
            capped : false
        });
        userInfos[msg.sender].push(UserInfo);
        totalInvest[msg.sender] += _amount;
        uint len = userInfos[msg.sender].length;
        investIndexCount[msg.sender] = len;

        emit nextJnvestEv(msg.sender, _amount, block.timestamp,len -1 );


        // pay direct
        address _ref = userInfos[msg.sender][0].referrer;
        address lastRef = msg.sender;

        for(uint i=0;i<10;i++) {
            totalBusiness[_ref] += _amount;
            totalBusinessFrom[lastRef] += _amount;

            uint amt = _amount * levelIncome[i] / 10000;
            
            // chek for max pay limit
            uint tp = totalPaid[_ref];
            if ( tp + amt > totalInvest[_ref]  * maxPayout / 10000  ) {

                amt = (totalInvest[_ref] * maxPayout / 10000 ) - tp;
                capReached(_ref);
            }
            referralWithdraw[_ref] += amt;
            totalReferralWithdraw[_ref] += amt;
            totalPaid[_ref] += amt;

            emit directPaidEv(_ref, i, amt, msg.sender, block.timestamp);
            lastRef = _ref;
            _ref = userInfos[_ref][0].referrer;
        }
        return true;
    }



    function withdraw(address forUser) public returns(bool) {
        withdrawReferral(forUser);
        withdrawROI(forUser);
        withdrawBonus(forUser);
        withdrawMentorGain(forUser);
        return true;
    }

    function withdrawReferral(address forUser) internal returns(bool) {
        uint amt = referralWithdraw[forUser];
        referralWithdraw[forUser] = 0;
        tokenInterface(tokenAddress).transfer(forUser,amt);        
        return true;
    }

    event withdrawROIEv(address caller,uint roiAmount,uint forDay,uint percent, uint eventTime );
    event mentorPaidEv(address paidTo,uint level,uint amount,address user,uint eventTime);
    function withdrawROI(address forUser) internal returns(bool) {
       
       uint tp = totalPaid[forUser];
       uint totalRoiAmount;

       uint lenth = userInfos[forUser].length;

       for(uint forIndex = 0; forIndex < lenth; forIndex++) {

            userInfo memory temp = userInfos[forUser][forIndex];
            if(tp < totalInvest[forUser] * maxPayout / 10000 && ! temp.capped ) {
                uint totalDays = (block.timestamp - temp.lastWithdrawTime) / oneDay;
                if (totalDays > 0) {
                    uint roiAmount = totalDays *  temp.investedAmount *  temp.returnPercent / div;

                    // chek for max pay limit
                    if ( tp + roiAmount >= totalInvest[forUser]  * maxPayout / 10000  ) {
                        roiAmount = (totalInvest[forUser]  * maxPayout / 10000) - tp;
                        capReached(forUser);
                    }
                    totalRoiAmount += roiAmount;
                    userInfos[forUser][forIndex].totalPaidROI += roiAmount;
                    userInfos[forUser][forIndex].lastWithdrawTime = block.timestamp;           
                    emit withdrawROIEv(forUser, roiAmount, totalDays,temp.returnPercent, block.timestamp );
                }
            }
       }


        totalPaid[forUser] += totalRoiAmount;                
        tokenInterface(tokenAddress).transfer(forUser,totalRoiAmount);
                 

        if ( totalRoiAmount > 0) {
                // pay mentor
                address _ref = userInfos[forUser][0].referrer;
                for(uint i=0;i<10;i++) {
                    uint amt = totalRoiAmount * mentorROI[i] / 10000;

                    // chek for max pay limit
                    uint tpd = totalPaid[_ref];
                    if ( tpd + amt > totalInvest[_ref]  * maxPayout / 10000  ) {
                        
                        amt = (totalInvest[_ref] * maxPayout / 10000 ) - tpd;
                        capReached(_ref);
                    }
                    totalPaid[_ref] += amt;

                    mentorGain[_ref] += amt;
                    totalMentorGain[_ref] += amt;
                    //tokenInterface(tokenAddress).transfer(_ref,amt);
                    emit mentorPaidEv(_ref, i, amt, forUser, block.timestamp);
                    _ref = userInfos[_ref][0].referrer;
                }  

        }

        return true;
    }

    function capReached(address _user) internal returns(bool) {
        uint len = userInfos[_user].length;
        for(uint i=0;i<len;i++) {
            userInfos[_user][i].capped = true;
        }
        return true;
    } 

    function viewMyRoi(address forUser) public view returns(uint) {
       
       uint tp = totalPaid[forUser];
       uint totalRoiAmount;

       uint lenth = userInfos[forUser].length;

       for(uint forIndex = 0; forIndex < lenth; forIndex++) {

            userInfo memory temp = userInfos[forUser][forIndex];
            if(tp < totalInvest[forUser] * maxPayout / 10000 && ! temp.capped ) {
                uint totalDays = (block.timestamp - temp.lastWithdrawTime) / oneDay;
                if (totalDays > 0) {
                    uint roiAmount = totalDays *  temp.investedAmount *  temp.returnPercent / div;

                    // chek for max pay limit
                    if ( tp + roiAmount >= totalInvest[forUser]  * maxPayout / 10000  ) {
                        roiAmount = (totalInvest[forUser]  * maxPayout / 10000) - tp;
                    }
                    totalRoiAmount += roiAmount;
               }
            }
       }
        return totalRoiAmount;
    }

    function withdrawMentorGain(address forUser) internal returns(bool) {
        if (mentorGain[forUser] > 0) {
            uint amt = mentorGain[forUser];
            mentorGain[forUser] = 0;
            tokenInterface(tokenAddress).transfer(forUser,amt);
        }
        return true;
    }

    function claimRewardBonus() public returns(bool) {
        withdrawBonus(msg.sender);
        for(uint i=9;i>=0;i--) {
            if(totalBusiness[msg.sender] >= bonusTarget[i] && eligible(msg.sender,bonusTarget[i])) {
                bonus[msg.sender] = i+1;
                lastBonusTime[msg.sender][i] = block.timestamp;
                break;
            }

        }
        return true;
    }

    function eligible(address _user, uint amount) public view returns(bool) {
        uint sum;
        uint len = referred[_user].length;
        address _ref;
        if (len > 0) {
            for(uint i=0;i<len;i++) {
                _ref = referred[_user][i];
                if(totalBusinessFrom[_ref] >= amount * 4/10 && ( sum == 0 || sum == 3 || sum == 6 )) sum += 4;
                else if (totalBusinessFrom[_ref] >= amount * 3/10) sum += 3;
                if(sum == 10) return true;
            }
        }
        else return false;

    }
    
    function recover(uint _amount) public returns (bool) {
        require(msg.sender == owner, "restricted call");
        payable(msg.sender).transfer(address(this).balance);
        tokenInterface(tokenAddress).transfer(msg.sender,_amount);
        return true;
    }


    event withdrawBonusEv(address user,uint totalBonus,uint eventTime);
    function withdrawBonus(address forUser) internal returns(bool) {
        uint totalBonus;
        for(uint i=0;i<10;i++) {
            uint bp = totalBonusPaid[forUser][i];
            if (bonus[forUser] == i+1 && bp < 150 * rewardBonus[i]) {
                uint day = ( block.timestamp - lastBonusTime[forUser][i] ) / oneDay ;
                uint amt = rewardBonus[i] * day;
                if(bp + amt > 150 * rewardBonus[i]) amt = (150 * rewardBonus[i]) - bp;
                totalBonusPaid[forUser][i] += amt;
                totalBonus += amt;
                lastBonusTime[forUser][i] = block.timestamp;
                break;
            }
        } 
        if(totalBonus > 0 ) {

            tokenInterface(tokenAddress).transfer(forUser,totalBonus);
            emit withdrawBonusEv(forUser, totalBonus, block.timestamp);
        }       
        return true;
    }

    function viewMyBonus(address forUser) public view returns(uint) {

         uint totalBonus;
        for(uint i=0;i<10;i++) {
            uint bp = totalBonusPaid[forUser][i];
            if (bonus[forUser] == i+1 && bp < 150 * rewardBonus[i]) {
                uint day = ( block.timestamp - lastBonusTime[forUser][i] ) / oneDay ;
                uint amt = rewardBonus[i] * day;
                if(bp + amt > 150 * rewardBonus[i]) amt = (150 * rewardBonus[i]) - bp;

                totalBonus += amt;
                break;
            }
        } 

        return totalBonus;
    }

    function totalDirect(address _user) public view returns(uint) {
        return referred[_user].length;
    }

    function totalROI(address _user) public view returns(uint) { 
        uint len = investIndexCount[_user];
        uint amt;
        for(uint i=0;i<len;i++) {
            amt += userInfos[_user][i].totalPaidROI;
        }
        return amt;
    }

    event Received(address sender,uint coinAmount);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    
}