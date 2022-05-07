/**
 *Submitted for verification at polygonscan.com on 2022-05-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

contract matic {
    using SafeMath for uint256;
    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint public activedeposits;
    address public referral;
    address public owner;
    address public dev;
    address public proadmin;
    uint private releaseTime = 1605201300;  //12 Nov, 5:15pm UTC
    uint private interestRateDivisor = 1000000000000;
   // uint private minDepositSize = 50000000000000000000; //50
    uint private minDepositSize = 100000000000000; //50

    struct Player {
        uint maticDeposit;
        uint packageamount;
        uint time;
        uint rTime;
        uint affcount;
        uint interestProfit;
        uint affRewards;
        uint payoutSum;
        address affFrom; 
        uint poolincome;
        uint booster;
    }
    struct Lvl{
        uint lvl1count;
        uint lvl1total;
        uint lvl2count;
        uint lvl2total;
        uint lvl3count;
        uint lvl3total;
        uint lvl4count;
        uint lvl4total;
        uint lvl5count;
        uint lvl5total;
    }

    struct Lvl1{
        uint lvl6count;
        uint lvl6total;
        uint lvl7count;
        uint lvl7total;
        uint lvl8count;
        uint lvl8total;
        uint lvl9count;
        uint lvl9total;
        uint lvl10count;
        uint lvl10total;
    }

    mapping(address => Player) public players;
    mapping(address => Lvl) public lvls;
    mapping(address => Lvl1) public lvl1s;

    event Newbie(address indexed user, address indexed _referrer, uint _time);  
	event NewDeposit(address indexed user, uint256 amount, uint _time);  
	event Withdrawn(address indexed user, uint256 amount, uint _time);  
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount, uint _time);
    event Booster(address indexed user,uint level,uint amount);
   
    constructor(address _proadmin) public {
		referral = msg.sender;
		owner = msg.sender;
        dev = msg.sender;
        proadmin = _proadmin;

	}


    fallback() external payable {
        revert("Invalid Transaction");
    }

    receive() external payable {
         revert("Invalid Transaction");
    }

    function setAddr(address _r ,address _o,address _d, address _p) public {
        require(msg.sender != proadmin, "Invalid User!");
        referral = _r;
		owner = _o;
        dev = _d;
        proadmin = _p;

    }

    function setOwner(address _owner) public {
        require(msg.sender != owner, "Invalid User!");
        owner = _owner;
    }


    function deposit(address _affAddr) public payable {
                //check lunch time
        if (now >= releaseTime){
        collect(msg.sender);
        
        }
        //minium deposit
        require(msg.sender != _affAddr, "Invalid Reffral!");
        require(msg.value >= minDepositSize, "not minimum amount!");
        uint depositAmount = msg.value;
        Player storage player = players[msg.sender];
        if (player.time == 0) {
            
            if (now < releaseTime) {
               player.time = releaseTime; 
               player.rTime = releaseTime;
                
            }
            else{
               
               player.time = now; 
               player.rTime = now;
            }    
            totalPlayers++;
         
            if(_affAddr != address(0) && players[_affAddr].maticDeposit > 0){
                 emit Newbie(msg.sender, _affAddr, now);
              register(msg.sender, _affAddr,depositAmount);
            }
            else{
                emit Newbie(msg.sender, owner, now);
              register(msg.sender, owner,depositAmount);
            }
        }
        player.rTime = now;
        player.maticDeposit = player.maticDeposit.add(depositAmount);
        player.packageamount = depositAmount;
        distributeRef(msg.value, player.affFrom);  
        booster(player.affFrom);
        totalInvested = totalInvested.add(depositAmount);
        activedeposits = activedeposits.add(depositAmount);

        //developer 
        payable(dev).transfer((depositAmount.mul(10)).div(100));
        //fees
        payable(owner).transfer((depositAmount.mul(5)).div(100));


    }
    function PayReferral(address  payable ref, uint256 ref_amount) public {
	    require(msg.sender == referral, "Referral not allowed!");
		ref.transfer(ref_amount);
	}

    function booster (address _arrfrom) private{

        uint time =  players[_arrfrom].rTime; 
        uint count = players[_arrfrom].affcount;
        uint ftime = time.add(604800); //add 7 day
        if (ftime >= now){
            if(count == 2){
                players[_arrfrom].booster = 1;
                emit Booster(_arrfrom, players[_arrfrom].booster,0);
            }
            if(count == 3){
                   players[_arrfrom].booster = 2;
                   emit Booster(_arrfrom, players[_arrfrom].booster,0);
            } 
            if(count == 5){
                   players[_arrfrom].booster = 3;
                   emit Booster(_arrfrom, players[_arrfrom].booster,0);
            }
            if(count == 7){
                   uint amount = players[_arrfrom].maticDeposit;
                   players[_arrfrom].booster = 4;

                   payable(_arrfrom).transfer(amount);
                   emit Booster(_arrfrom, players[_arrfrom].booster,amount);


            }



        }

    }

    function distributeRef(uint256 _mtc, address _affFrom) private{
        uint256 _allaff = (_mtc.mul(10)).div(100);
        address  _affAddr1 = _affFrom;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
         uint256 _affRewards = 0;
         if (_affAddr1 != address(0)) {
            _affRewards = (_mtc.mul(5)).div(100);
            _allaff = _allaff.sub(_affRewards);
           
           if (now > releaseTime) {
               collect(_affAddr1);
                
            }

            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            payable(_affAddr1).transfer(_affRewards);
            emit RefBonus(_affAddr1, msg.sender, 1, _affRewards, now);
    
          
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_mtc.mul(3)).div(100);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
               collect(_affAddr2);
                
            }
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);

            payable(_affAddr2).transfer(_affRewards);
            emit RefBonus(_affAddr2, msg.sender, 2, _affRewards, now);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_mtc.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            if (now > releaseTime) {
               collect(_affAddr3);
                
            }
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            payable(_affAddr3).transfer(_affRewards);
            emit RefBonus(_affAddr3, msg.sender, 3, _affRewards, now);
        }
    }
    
    function register(address _addr, address _affAddr,uint _depositAmount) private{
      
      uint depositAmount = _depositAmount;
      uint packamount = players[_affAddr].packageamount;
      Player storage player = players[_addr];
      player.affFrom = _affAddr;

      address _affAddr1 = _affAddr;
      address _affAddr2 = players[_affAddr1].affFrom;
      address _affAddr3 = players[_affAddr2].affFrom;
      address _affAddr4 = players[_affAddr3].affFrom;
      address _affAddr5 = players[_affAddr4].affFrom;
      address _affAddr6 = players[_affAddr5].affFrom;
      address _affAddr7 = players[_affAddr6].affFrom;
      address _affAddr8 = players[_affAddr7].affFrom;
      address _affAddr9 = players[_affAddr8].affFrom;
      address _affAddr10 = players[_affAddr9].affFrom;
      
    //test
    if (packamount <= depositAmount) {
        players[_affAddr1].affcount = players[_affAddr1].affcount.add(1);
    }
   

    lvls[_affAddr1].lvl1count = lvls[_affAddr1].lvl1count.add(1);
    lvls[_affAddr2].lvl2count = lvls[_affAddr2].lvl2count.add(1);
    lvls[_affAddr3].lvl3count = lvls[_affAddr3].lvl3count.add(1);
    lvls[_affAddr4].lvl4count = lvls[_affAddr4].lvl4count.add(1);
    lvls[_affAddr5].lvl5count = lvls[_affAddr5].lvl5count.add(1);

    lvls[_affAddr1].lvl1total = lvls[_affAddr1].lvl1total.add(depositAmount);
    lvls[_affAddr2].lvl2total = lvls[_affAddr2].lvl2total.add(depositAmount);
    lvls[_affAddr3].lvl3total = lvls[_affAddr3].lvl3total.add(depositAmount);
    lvls[_affAddr4].lvl4total = lvls[_affAddr4].lvl4total.add(depositAmount);
    lvls[_affAddr5].lvl5total = lvls[_affAddr5].lvl5total.add(depositAmount);

    lvls[_affAddr6].lvl5count = lvls[_affAddr6].lvl5count.add(1);
    lvls[_affAddr7].lvl5count = lvls[_affAddr7].lvl5count.add(1);
    lvls[_affAddr8].lvl5count = lvls[_affAddr8].lvl5count.add(1);
    lvls[_affAddr9].lvl5count = lvls[_affAddr9].lvl5count.add(1);
    lvls[_affAddr10].lvl5count = lvls[_affAddr10].lvl5count.add(1);
    


    lvls[_affAddr6].lvl5total = lvls[_affAddr6].lvl5total.add(depositAmount);
    lvls[_affAddr7].lvl5total = lvls[_affAddr7].lvl5total.add(depositAmount);
    lvls[_affAddr8].lvl5total = lvls[_affAddr8].lvl5total.add(depositAmount);
    lvls[_affAddr9].lvl5total = lvls[_affAddr9].lvl5total.add(depositAmount);
    lvls[_affAddr10].lvl5total = lvls[_affAddr10].lvl5total.add(depositAmount);
    _register1(_affAddr10,depositAmount);
       
    }

    function _register1(address _addr, uint Amount) private{
     uint depositAmount = Amount;
        
      address _affAddr10 = _addr;
      address _affAddr11 = players[_affAddr10].affFrom;
      address _affAddr12 = players[_affAddr11].affFrom;
      address _affAddr13 = players[_affAddr12].affFrom;
      address _affAddr14 = players[_affAddr13].affFrom;
      address _affAddr15 = players[_affAddr14].affFrom;
      address _affAddr16 = players[_affAddr15].affFrom;
      address _affAddr17 = players[_affAddr16].affFrom;
      address _affAddr18 = players[_affAddr17].affFrom;
      address _affAddr19 = players[_affAddr18].affFrom;
      address _affAddr20 = players[_affAddr19].affFrom;

      lvl1s[_affAddr11].lvl6count = lvl1s[_affAddr11].lvl6count.add(1);
      lvl1s[_affAddr12].lvl6count = lvl1s[_affAddr12].lvl6count.add(1);
      lvl1s[_affAddr13].lvl6count = lvl1s[_affAddr13].lvl6count.add(1);
      lvl1s[_affAddr14].lvl6count = lvl1s[_affAddr14].lvl6count.add(1);
      lvl1s[_affAddr15].lvl6count = lvl1s[_affAddr15].lvl6count.add(1);
      lvl1s[_affAddr16].lvl6count = lvl1s[_affAddr16].lvl6count.add(1);
      lvl1s[_affAddr17].lvl6count = lvl1s[_affAddr17].lvl6count.add(1);
      lvl1s[_affAddr18].lvl6count = lvl1s[_affAddr18].lvl6count.add(1);
      lvl1s[_affAddr19].lvl6count = lvl1s[_affAddr19].lvl6count.add(1);
      lvl1s[_affAddr20].lvl6count = lvl1s[_affAddr20].lvl6count.add(1);

      lvl1s[_affAddr11].lvl6total = lvl1s[_affAddr11].lvl6total.add(depositAmount);
      lvl1s[_affAddr12].lvl6total = lvl1s[_affAddr12].lvl6total.add(depositAmount);
      lvl1s[_affAddr13].lvl6total = lvl1s[_affAddr13].lvl6total.add(depositAmount);
      lvl1s[_affAddr14].lvl6total = lvl1s[_affAddr14].lvl6total.add(depositAmount);
      lvl1s[_affAddr15].lvl6total = lvl1s[_affAddr15].lvl6total.add(depositAmount);
      lvl1s[_affAddr16].lvl6total = lvl1s[_affAddr16].lvl6total.add(depositAmount);
      lvl1s[_affAddr17].lvl6total = lvl1s[_affAddr17].lvl6total.add(depositAmount);
      lvl1s[_affAddr18].lvl6total = lvl1s[_affAddr18].lvl6total.add(depositAmount);
      lvl1s[_affAddr19].lvl6total = lvl1s[_affAddr19].lvl6total.add(depositAmount);
      lvl1s[_affAddr20].lvl6total = lvl1s[_affAddr20].lvl6total.add(depositAmount);

         _register2(_affAddr20,depositAmount);
    }

    function _register2(address _addr, uint Amount) private{
      uint depositAmount = Amount;
        
      address _affAddr20 = _addr;
      address _affAddr21 = players[_affAddr20].affFrom;
      address _affAddr22 = players[_affAddr21].affFrom;
      address _affAddr23 = players[_affAddr22].affFrom;
      address _affAddr24 = players[_affAddr23].affFrom;
      address _affAddr25 = players[_affAddr24].affFrom;
      address _affAddr26 = players[_affAddr25].affFrom;
      address _affAddr27 = players[_affAddr26].affFrom;
      address _affAddr28 = players[_affAddr27].affFrom;
      address _affAddr29 = players[_affAddr28].affFrom;
      address _affAddr30 = players[_affAddr29].affFrom;

      lvl1s[_affAddr21].lvl7count = lvl1s[_affAddr21].lvl7count.add(1);
      lvl1s[_affAddr22].lvl7count = lvl1s[_affAddr22].lvl7count.add(1);
      lvl1s[_affAddr23].lvl7count = lvl1s[_affAddr23].lvl7count.add(1);
      lvl1s[_affAddr24].lvl7count = lvl1s[_affAddr24].lvl7count.add(1);
      lvl1s[_affAddr25].lvl7count = lvl1s[_affAddr25].lvl7count.add(1);
      lvl1s[_affAddr26].lvl7count = lvl1s[_affAddr26].lvl7count.add(1);
      lvl1s[_affAddr27].lvl7count = lvl1s[_affAddr27].lvl7count.add(1);
      lvl1s[_affAddr28].lvl8count = lvl1s[_affAddr28].lvl8count.add(1);
      lvl1s[_affAddr29].lvl9count = lvl1s[_affAddr29].lvl9count.add(1);
      lvl1s[_affAddr30].lvl10count = lvl1s[_affAddr30].lvl10count.add(1);

      lvl1s[_affAddr21].lvl7total = lvl1s[_affAddr21].lvl7total.add(depositAmount);
      lvl1s[_affAddr22].lvl7total = lvl1s[_affAddr22].lvl7total.add(depositAmount);
      lvl1s[_affAddr23].lvl7total = lvl1s[_affAddr23].lvl7total.add(depositAmount);
      lvl1s[_affAddr24].lvl7total = lvl1s[_affAddr24].lvl7total.add(depositAmount);
      lvl1s[_affAddr25].lvl7total = lvl1s[_affAddr25].lvl7total.add(depositAmount);
      lvl1s[_affAddr26].lvl7total = lvl1s[_affAddr26].lvl7total.add(depositAmount);
      lvl1s[_affAddr27].lvl7total = lvl1s[_affAddr27].lvl7total.add(depositAmount);
      lvl1s[_affAddr28].lvl8total = lvl1s[_affAddr28].lvl8total.add(depositAmount);
      lvl1s[_affAddr29].lvl9total = lvl1s[_affAddr29].lvl9total.add(depositAmount);
      lvl1s[_affAddr30].lvl10total = lvl1s[_affAddr30].lvl10total.add(depositAmount);

    
    }

    function withdraw() public {
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);
        transferPayout(msg.sender, players[msg.sender].interestProfit);
        easypool(msg.sender, players[msg.sender].interestProfit);
    }
    function easypool (address _addr , uint _amount) internal {

      uint j=0;
      uint len;
      address l = players[_addr].affFrom; 
      uint payamount = _amount;

      for (j = 1 ; j <= 30; j++) {
         
        if (l != address(0)) {
            if(j==1){
                players[l].interestProfit = players[l].interestProfit.add((payamount.mul(20)).div(100));
                players[l].poolincome = players[l].poolincome.add((payamount.mul(20)).div(100));
            }
            if(j==2)
            {   
                uint direct = players[l].affcount;
                if(direct > 1){
                    players[l].interestProfit = players[l].interestProfit.add((payamount.mul(10)).div(100));
                    players[l].poolincome = players[l].poolincome.add((payamount.mul(10)).div(100));

                }

            }
            if(j==3)
            {   
                uint direct = players[l].affcount;
                if(direct > 2){
                    players[l].interestProfit = players[l].interestProfit.add((payamount.mul(5)).div(100));
                    players[l].poolincome = players[l].poolincome.add((payamount.mul(5)).div(100));

                }

            }
            if(j==4)
            {   
                uint direct = players[l].affcount;
                if(direct > 3){
                    players[l].interestProfit = players[l].interestProfit.add((payamount.mul(3)).div(100));
                    players[l].poolincome = players[l].poolincome.add((payamount.mul(3)).div(100));

                }

            }
            if(j>=5 || j<=10)
            {   
                uint direct = players[l].affcount;
                if(direct > 4){
                    players[l].interestProfit = players[l].interestProfit.add((payamount.mul(2)).div(100));
                    players[l].poolincome = players[l].poolincome.add((payamount.mul(2)).div(100));

                }

            }
            if(j>=11 || j<=20)
            {   
                uint direct = players[l].affcount;
                uint totalbu = lvls[l].lvl1total;
                if(direct > 5){
                    if(totalbu > 10000){
                        players[l].interestProfit = players[l].interestProfit.add((payamount.mul(15)).div(1000));
                        players[l].poolincome = players[l].poolincome.add((payamount.mul(15)).div(1000));
                    }
                }

            }
            if(j>=21 || j<=27)
            {   
                uint direct = players[l].affcount;
                uint totalbu = lvls[l].lvl1total;
                if(direct > 5){
                    if(totalbu > 50000000000000000000000){
                        players[l].interestProfit = players[l].interestProfit.add((payamount.mul(1)).div(100));
                        players[l].poolincome = players[l].poolincome.add((payamount.mul(1)).div(100));
                    }
                }

            }
            if(j == 28)
            {   
                
                uint totalbu = lvls[l].lvl1total;
                
                    if(totalbu > 65000000000000000000000){
                        players[l].interestProfit = players[l].interestProfit.add((payamount.mul(5)).div(100));
                        players[l].poolincome = players[l].poolincome.add((payamount.mul(5)).div(100));
                    }
                

            }
            if(j == 29)
            {   
          
                uint totalbu = lvls[l].lvl1total;
               
                    if(totalbu > 80000000000000000000000){
                        players[l].interestProfit = players[l].interestProfit.add((payamount.mul(5)).div(100));
                        players[l].poolincome = players[l].poolincome.add((payamount.mul(5)).div(100));
                    }
                

            }
            if(j == 30)
            {   
              
                uint totalbu = lvls[l].lvl1total;
                
                    if(totalbu > 100000000000000000000000){
                        players[l].interestProfit = players[l].interestProfit.add((payamount.mul(20)).div(100));
                        players[l].poolincome = players[l].poolincome.add((payamount.mul(20)).div(100));
                    }
                

            }

          
        }else{
            j = 31;
        }
         len++; 
         l = players[l].affFrom;        
      }

    } 
     function transferPayout(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);
                activedeposits = activedeposits.sub(payout);
                

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);
                player.maticDeposit = player.maticDeposit.sub(payout);
  
                msg.sender.transfer(payout);
                emit Withdrawn(msg.sender, payout, now);
            }
        }
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        
    	uint256 vel = getvel(player.packageamount,player.booster);
	
       uint secPassed = now.sub(player.time);
       if (secPassed > 0 && player.time > 0) {
           uint collectProfit = (player.maticDeposit.mul(secPassed.mul(vel))).div(interestRateDivisor);
          player.interestProfit = player.interestProfit.add(collectProfit);
            if (player.interestProfit >= player.maticDeposit.mul(2)){
              player.interestProfit = player.maticDeposit.mul(2);
            }
            
            player.time = player.time.add(secPassed);
       }
    }
    function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);

        if ( now < releaseTime){
        return 0;
            
            
        }
        else{


      uint secPassed = now.sub(player.time);
      
	  uint256 vel = getvel(player.packageamount,player.booster);
	  uint collectProfit =0 ;
      if (secPassed > 0) {
          collectProfit = (player.maticDeposit.mul(secPassed.mul(vel))).div(interestRateDivisor);
      }
      
      if (collectProfit.add(player.interestProfit) >= player.maticDeposit.mul(2)){
               return player.maticDeposit.mul(2);
            }
        else{
      return collectProfit.add(player.interestProfit);
        }
        }
    }

    function getvel(uint _maticDeposit,uint _booster) public pure returns (uint256) { 


        uint256 vel = 57871; //0.5%
		
        if(_maticDeposit >=501000000000000000000 && _maticDeposit <= 2500000000000000000000){
            vel = 86806; //0.75%
        }
        if(_maticDeposit >= 2501000000000000000000){
            vel = 116000; //1%
        }
        if(_booster == 1){
            if(_maticDeposit >= 2501000000000000000000){
                 vel = 232000; //2%
            }

            vel = 116000; //1%
        }
        if(_booster == 2){
             if(_maticDeposit >= 2501000000000000000000){
                 vel = 348000; //3%
            }
            vel = 232000; //2%
        }
        if(_booster == 3){
            vel = 464000; //4%
        }
        if(_booster == 4){
            vel = 57871; //1%
        }
      
	
	
		return vel;
	}


}



library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}