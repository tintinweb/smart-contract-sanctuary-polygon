/**
 100% Decentalize Smart Contract For Vara Gold Community
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./VaraUniversal.sol";

contract VaraGoldMainSC  is VaraGoldUniversalSC {

    //Admin Can Verify New Id
    function _verifyId(address user,address referrer) public {
        require(msg.sender == contractOwner, "Only Admin ?");
        uint256 amount=joiningAmount;
        uint side=_UserAffiliateDetails[referrer].referralLinkSide;
        Join(amount,user,referrer,side);
    }

    function _Joining(uint256 amount,address referrer) public {
       uint side=_UserAffiliateDetails[referrer].referralLinkSide;
       Join(amount,msg.sender,referrer,side);  
    } 

    function Join(uint256 amount,address user,address referrer,uint side) private{
        require(amount == joiningAmount,'Insufficient Joining Amount !');
        require(_UserAffiliateDetails[user].selfInvestment == 0,'Already Registered !');
        require(_UserAffiliateDetails[user].userId == 0,'Already Registered !');
        UserAffiliateDetails storage userAffiliateDetails = _UserAffiliateDetails[user];
        userAffiliateDetails.selfInvestment += amount;
        userAffiliateDetails.selfSide = side;
        userAffiliateDetails.referralLinkSide = side;
        userAffiliateDetails.isIncomeBlocked = false;
        _UserBusinessDetails[user].isBoosterApplicable = false;
        _UserBusinessDetails[user].isEligibleForMatching = false;
        userAffiliateDetails.joiningDateTime = block.timestamp; 
        //Manage Referral Systeh Start Here
        if (userAffiliateDetails.sponsor == address(0) && (_UserAffiliateDetails[referrer].userId > 0 || referrer == contractOwner) && referrer != user ) {
            userAffiliateDetails.sponsor = referrer;
            _UserAffiliateDetails[referrer].noofDirect +=1;
            if(side==1){
              _UserAffiliateDetails[referrer].noofDirectLeft +=1;
            }
            else if(side==2){ 
              _UserAffiliateDetails[referrer].noofDirectRight +=1;
            }
            if(_UserAffiliateDetails[referrer].noofDirectLeft>=binaryEligibilityLeftRequire && _UserAffiliateDetails[referrer].noofDirectRight>=binaryEligibilityRightRequire){
                _UserBusinessDetails[referrer].isEligibleForMatching=true;
                matchingIncomeQualifier.push(referrer);
            }
            uint noofDays=view_DiffTwoDateInternal(_UserAffiliateDetails[referrer].joiningDateTime,block.timestamp);
            if(noofDays<=noofDaysForBooster){
                if(_UserBusinessDetails[referrer].isEligibleForMatching && _UserAffiliateDetails[referrer].noofDirect>=noofDirectforBooster){
                   _UserBusinessDetails[referrer].isBoosterApplicable=true;
                }
            }
        }   	
        require(userAffiliateDetails.sponsor != address(0) || user == contractOwner, "No upline");
        if (userAffiliateDetails.sponsor != address(0)) {	   
        //Level Wise Business & Id Count
        address upline = userAffiliateDetails.sponsor;
        for (uint i = 0; i < ref_bonuses.length; i++) {
            if (upline != address(0)) {
                _UserBusinessDetails[upline].levelWiseBusiness[i] += amount;
                if(userAffiliateDetails.userId == 0){
                    _UserBusinessDetails[upline].refs[i] += 1;
                }
                upline = _UserAffiliateDetails[upline].sponsor;
            } 
            else break;
        }
      }
      if(userAffiliateDetails.userId == 0) {
        userAffiliateDetails.userId = block.timestamp;
        UserWalletDetails storage userWalletDetails = _UserWalletDetails[userAffiliateDetails.userId];
        userWalletDetails.UserWalletAddress=user;
      }
      //Manage Referral System End Here
      //Referral Income Distribution
	    _refPayout(user);
      //Level Income Distribution
	    _levelPayout(user);
      //Binary Placement
      _PlaceInMatchingTree(user,referrer,side,amount);
      //Placement In Ring
      ringcontract.placeInRing(user);
      totalNumberofUsers+=1;
      nativetoken.transferFrom(user, address(this), amount);
      emit Joining(user,amount,referrer,side);
    }

    //Admin Can Verify Withdrawal
    function _verifyWithdrawal(address user,uint256 amount) public {
        require(msg.sender == contractOwner, "Only Admin ?");
        Withdraw(user,amount);
    }

    function _Withdrawal(uint256 amount) public {  
       Withdraw(msg.sender,amount);
    }

    function  Withdraw(address user,uint256 amount) private{
       uint256 rewardRing=ringcontract.getRingBous(user);
      _UserIncomeDetails[user].totalRingBonus += rewardRing;
      _UserIncomeDetails[user].totalBonus += rewardRing;
      _UserIncomeDetails[user].creditedWallet += rewardRing;
      _UserIncomeDetails[user].availableWallet += rewardRing;
      ringcontract.updateRingBous(user);
      uint256 AvailableWallet = _UserIncomeDetails[user].availableWallet;
      require(AvailableWallet >= amount,'Insufficient Fund For Withdrawal !');
      require(amount >= minimumWithdrawal,'You Must Enter Minimum Withdrawal Amount !');
      require(AvailableWallet >= minimumWithdrawal,'You Must Have Minimum Withdrawal Amount !');
      uint256 adminCharge=0;
      if(amount>=tierFromWithdrawal[0] && amount<=tierToWithdrawal[0]){
        adminCharge=tierAdminCharge[0];
      }
      else if(amount>=tierFromWithdrawal[1] && amount<=tierToWithdrawal[1]) {
        adminCharge=tierAdminCharge[1];
      }
      else if(amount>= tierFromWithdrawal[2]){
        adminCharge=tierAdminCharge[2];
      }
      uint256 _fees = (amount*adminCharge)/100;
      uint256 actualAmountToSend = (amount-_fees);
      adminChargeCollected += _fees;
      _UserIncomeDetails[user].usedWallet += amount;
      _UserIncomeDetails[user].availableWallet -= amount; 
      nativetoken.transfer(user, actualAmountToSend);   
      emit Withdrawn(user,amount);
    }

    function _InternalTransfer(uint256 userId,uint256 amount) public {  
        Internal(msg.sender,userId,amount);
    }

    function Internal(address user,uint256 userId,uint256 amount) private{
      uint256 rewardRing=ringcontract.getRingBous(user);
      _UserIncomeDetails[user].totalRingBonus += rewardRing;
      _UserIncomeDetails[user].totalBonus += rewardRing;
      _UserIncomeDetails[user].creditedWallet += rewardRing;
      _UserIncomeDetails[user].availableWallet += rewardRing;
      ringcontract.updateRingBous(user);
      uint256 AvailableWallet = _UserIncomeDetails[user].availableWallet;
      require(AvailableWallet >= amount,'Insufficient Fund For Transfer !');
      require(amount >= minimumTransfer,'You Must Enter Minimum Transfer Amount !');
      require(AvailableWallet >= minimumTransfer,'You Must Have Minimum Transfer Amount !');
      //Update Sender Wallet Details Here
      _UserIncomeDetails[user].usedWallet += amount;
      _UserIncomeDetails[user].totalTransfered += amount;
      _UserIncomeDetails[user].availableWallet -= amount;    
      //Update Receiver Wallet Details Here
      address walletAddress = _UserWalletDetails[userId].UserWalletAddress;
      _UserIncomeDetails[walletAddress].creditedWallet += amount;
      _UserIncomeDetails[walletAddress].totalReceived += amount;
      _UserIncomeDetails[walletAddress].availableWallet += amount; 
      emit InternalTransfer(user,userId,amount);
    }

    function _PlaceInMatchingTree(address user,address referrer,uint side,uint256 amount) internal {
        if(side==1){ _PlaceInLeft(user,referrer,amount);}
        else if(side==2){ _PlaceInRight(user,referrer,amount);}
    }

    function _PlaceInLeft(address user,address referrer,uint256 amount) internal {
        address left=_UserAffiliateDetails[referrer].left;
        address parent=referrer;
        while(true) {
          if (left != 0x0000000000000000000000000000000000000000) {
              parent=left;
              left=_UserAffiliateDetails[left].left;
           } 
          else break;
          }
        _UserAffiliateDetails[user].parent=parent;
        _UserAffiliateDetails[parent].left=user;
        _UpdateBusiness(user,amount);
    }

    function _PlaceInRight(address user,address referrer,uint256 amount) internal {
        address right=_UserAffiliateDetails[referrer].right;
        address parent=referrer;
        while(true){
          if (right != 0x0000000000000000000000000000000000000000) {
              parent=right;
              right=_UserAffiliateDetails[right].right;
          } 
          else break;
        }  
        _UserAffiliateDetails[user].parent=parent;
        _UserAffiliateDetails[parent].right=user;
        _UpdateBusiness(user,amount);
    }

    function _UpdateBusiness(address user,uint256 amount) internal { 
        uint side=_UserAffiliateDetails[user].selfSide;
        address parent=_UserAffiliateDetails[user].parent;
        while(true) {
          if (parent != 0x0000000000000000000000000000000000000000) {
              if(side==1){
                _UserBusinessDetails[parent].currentleftbusiness += amount;
              }
              else if(side==2){
                _UserBusinessDetails[parent].currentrightbusiness += amount;
              }
              side=_UserAffiliateDetails[parent].selfSide;
              parent=_UserAffiliateDetails[parent].parent;
          } 
          else break;
        }
    }
       
}