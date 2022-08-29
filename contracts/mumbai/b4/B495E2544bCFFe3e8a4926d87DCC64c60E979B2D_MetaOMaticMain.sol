//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./MetaOMaticUniversal.sol";

contract MetaOMaticMain  is MetaOMaticUniversal {

    //Admin Can Verify New Id
    function _verifyId(address user,address referrer,bool allpackage,uint package) public {
        uint packageprice=packagePrice[package];
        require(msg.sender == contractOwner, "Only Admin ?");
        require(!_IsUserExists(user), "Already Registered !"); 
        require(_IsUserExists(referrer), "Referral Not Exists !"); 
        require(package >= 0 && package < totalPackage, "Invalid Package !");    
        if(package>=1)
        {
            require(_UserAffiliateDetails[user].packagePurchased[package-1], "Buy Previous Package First !");
        }
        uint32 size;
        assembly { size := extcodesize(user) }	
        require(size == 0, "Smart Contract !");
        uint TimeStamp=block.timestamp;
        _UserAffiliateDetails[user].userId = TimeStamp;
        _UserAffiliateDetails[user].sponsor = referrer;
        _UserAffiliateDetails[user].joiningDateTime= TimeStamp;
        if(allpackage==false) {
          _UserAffiliateDetails[user].packagePurchased[package] = true;
          _UserAffiliateDetails[user].purchasedDateTime[package] = TimeStamp;
          _UserAffiliateDetails[user].selfInvestment+=packageprice; 
          totalPackagePurchased+=packageprice;
          if(package==0){_PlaceInUp15(user,1);_SystemPackageId[0].total15Id += 1;}
          else if(package==1){_PlaceInUp30(user,1);_SystemPackageId[0].total30Id += 1;}
          else if(package==2){_PlaceInUp60(user,1);_SystemPackageId[0].total60Id += 1;}
          else if(package==3){_PlaceInUp120(user,1);_SystemPackageId[0].total120Id += 1;}
          else if(package==4){_PlaceInUp240(user,1);_SystemPackageId[0].total240Id += 1;}
          else if(package==5){_PlaceInUp480(user,1);_SystemPackageId[0].total480Id += 1;}
          m6contract.placeInM6(user,referrer,0,package);
          _refPayout(user,((packageprice*m6per)/100));
        }
        else {
            for (uint8 i = 0; i < totalPackage; i++) {
               _UserAffiliateDetails[user].packagePurchased[i] = true;
               _UserAffiliateDetails[user].purchasedDateTime[i] = TimeStamp;
               _UserAffiliateDetails[user].selfInvestment+=packagePrice[i];
               totalPackagePurchased+=packagePrice[i];
               if(i==0){_PlaceInUp15(user,1);_SystemPackageId[0].total15Id += 1;}
               else if(i==1){_PlaceInUp30(user,1);_SystemPackageId[0].total30Id += 1;}
               else if(i==2){_PlaceInUp60(user,1);_SystemPackageId[0].total60Id += 1;}
               else if(i==3){_PlaceInUp120(user,1);_SystemPackageId[0].total120Id += 1;}
               else if(i==4){_PlaceInUp240(user,1);_SystemPackageId[0].total240Id += 1;}
               else if(i==5){_PlaceInUp480(user,1);_SystemPackageId[0].total480Id += 1;}
               m6contract.placeInM6(user,referrer,0,i);
               _refPayout(user,((packagePrice[i]*m6per)/100));
            }
        }
        userIdToAddress[TimeStamp] = user;
        totalNumberofUsers +=1;
        emit VerifyId(user,package,packageprice);
    }

    function _Joining(address referrer) external payable {
      registration(msg.sender, referrer,msg.value);
    }

    function _Withdrawal() public {
      uint256 amount = _UserIncomeDetails[msg.sender].availableBonus;
      _UserIncomeDetails[msg.sender].usedWallet += amount;
      _UserIncomeDetails[msg.sender].availableBonus -= amount; 
      _SafeTransfer(msg.sender,amount);
      emit Withdrawn(msg.sender,amount);
    }

    function registration(address user, address referrer,uint256 amount) private {     
        uint packageprice=packagePrice[0];
        require(!_IsUserExists(user), "Already Registered !"); 
        require(_IsUserExists(referrer), "Referral Not Exists !"); 
        require(amount == packageprice,"Invalid Package !"); 
        uint32 size;
        assembly { size := extcodesize(user) }	
        require(size == 0, "Smart Contract !"); 
        uint TimeStamp=block.timestamp;
        _UserAffiliateDetails[user].userId = TimeStamp;
        _UserAffiliateDetails[user].sponsor = referrer;
        _UserAffiliateDetails[user].joiningDateTime= TimeStamp;
        _UserAffiliateDetails[user].packagePurchased[1] = true;
        _UserAffiliateDetails[user].purchasedDateTime[1] = TimeStamp;
        _UserAffiliateDetails[user].selfInvestment+=packageprice; 
        userIdToAddress[TimeStamp] = user;
        totalNumberofUsers +=1;
        totalPackagePurchased+=packageprice;
        _SystemPackageId[0].total15Id += 1;
        _PlaceInUp15(user,1);
        uint256 M6Amount=((((packageprice*m6per)/100)*60)/100);
        m6contract._verifyInMatic { value:M6Amount };
        m6contract.placeInM6(user,referrer,0,0);
        _refPayout(user,((packageprice*m6per)/100));
        emit Joining(user,packageprice,referrer);
    }

    function _Upgrade(uint package) external payable {
      upgradePackage(msg.sender, package,msg.value);
    }

    function upgradePackage(address user,uint package,uint256 amount) private {
        uint packageprice=packagePrice[package];     
        require(_IsUserExists(user), "Not Registered Yet !");
        require(!_UserAffiliateDetails[user].packagePurchased[package], "Already Upgraded !"); 
        require(package >= 1 && package < totalPackage, "Invalid Package !");    
        require(_UserAffiliateDetails[user].packagePurchased[package-1], "Buy Previous Package First !");
        require(amount == packageprice , "Invalid Package Price !");
        uint32 size;
        assembly { size := extcodesize(user) }	
        require(size == 0, "Smart Contract !");
        uint TimeStamp=block.timestamp;
        _UserAffiliateDetails[user].packagePurchased[package] = true;
        _UserAffiliateDetails[user].purchasedDateTime[package] = TimeStamp;
        _UserAffiliateDetails[user].selfInvestment+=packageprice;
         address referrer=_UserAffiliateDetails[user].sponsor;
         totalPackagePurchased+=packageprice;
        if(package==1){
            _PlaceInUp30(user,1);
            _SystemPackageId[0].total30Id += 1;
        }
        else if(package==2){
             _PlaceInUp60(user,1);
            _SystemPackageId[0].total60Id += 1;
        }
        else if(package==3){
            _PlaceInUp120(user,1);
            _SystemPackageId[0].total120Id += 1;
        }
        else if(package==4){
            _PlaceInUp240(user,1);
            _SystemPackageId[0].total240Id += 1;
        }
        else if(package==5){
            _PlaceInUp480(user,1);
            _SystemPackageId[0].total480Id += 1;
        }
        uint256 M6Amount=((((packageprice*m6per)/100)*60)/100);
        m6contract._verifyInMatic { value:M6Amount };
        m6contract.placeInM6(user,referrer,0,package);
        _refPayout(user,((packageprice*m6per)/100));
        emit Upgrade(user,package,packageprice);
    }

    function UpdateUpBonus(address user,uint256 amount,uint UpNo) private {
      _UserIncomeDetails[user].totalUPBonus += amount;
      _UserIncomeDetails[user].totalBonus += amount;
      _UserIncomeDetails[user].creditedBonus += amount;
      _UserIncomeDetails[user].availableBonus += amount;
      totalUpIncome+=amount;
      if(UpNo==15){
        _SystemUpBonusDetails[0].totalUp15Bonus += amount;
        _UserUPBonusDetails[user].totalUp15Bonus += amount;
      }
      else if(UpNo==30){
        _SystemUpBonusDetails[0].totalUp30Bonus += amount;
        _UserUPBonusDetails[user].totalUp30Bonus += amount;
      }
      else if(UpNo==60){
        _SystemUpBonusDetails[0].totalUp60Bonus += amount;
        _UserUPBonusDetails[user].totalUp60Bonus += amount;
      }
      else if(UpNo==120){
        _SystemUpBonusDetails[0].totalUp120Bonus += amount;
        _UserUPBonusDetails[user].totalUp120Bonus += amount;
      }
      else if(UpNo==240){
        _SystemUpBonusDetails[0].totalUp240Bonus += amount;
        _UserUPBonusDetails[user].totalUp240Bonus += amount;
      }
      else if(UpNo==480){
        _SystemUpBonusDetails[0].totalUp480Bonus += amount;
        _UserUPBonusDetails[user].totalUp480Bonus += amount;
      }
      _WithdrawalAuto(address(uint160(user)));
    }

    function _PlaceInUp15(address user,uint noofentry) private {
      for(uint I=1;I<=noofentry;I++){
       Up15List.push(user);
      _UserUPCycleCount[user].totalUp15Id += 1;
      uint Length=Up15List.length;
      Length -= 1;
      if((Length%upWidth)==0){
         uint Index=Length/upWidth;
         Index -= 1;
         address placementId=Up15List[Index];
         //Calculation Start Here
         uint UplineCycleNo=_UserUPCycleCount[placementId].totalUp15Id;
         //Odd Cycle 0 % 2 Not Possible So Supposing It's Odd Number
         if(UplineCycleNo==0){
            _PlaceInUp15(placementId,1);
             uint256 CalculativeUPBonus=((packagePrice[0]*universalpoolper)/100);
             UpdateUpBonus(placementId,CalculativeUPBonus,15);
         }
         else {
           //Even Cycle
           if(UplineCycleNo%2==0){
             _PlaceInUp15(placementId,2);
           }
           //Odd Cycle
           else{
             _PlaceInUp15(placementId,1);
              uint256 CalculativeUPBonus=((packagePrice[0]*universalpoolper)/100);
              UpdateUpBonus(placementId,CalculativeUPBonus,15);
           }
         }
         //Calculation End Here
       }
      }
    }

    function _PlaceInUp30(address user,uint noofentry) private {
      for(uint I=1;I<=noofentry;I++){
       Up30List.push(user);
       _UserUPCycleCount[user].totalUp30Id += 1;
      uint Length=Up30List.length;
      Length -= 1;
      if((Length%upWidth)==0){
         uint Index=Length/upWidth;
         Index -= 1;
         address placementId=Up30List[Index];
         //Calculation Start Here
         uint UplineCycleNo=_UserUPCycleCount[placementId].totalUp30Id;
         //Odd Cycle 0 % 2 Not Possible So Supposing It's Odd Number
         if(UplineCycleNo==0){
            _PlaceInUp30(placementId,1);
             uint256 CalculativeUPBonus=((packagePrice[1]*universalpoolper)/100);
             UpdateUpBonus(placementId,CalculativeUPBonus,30);
         }
         else {
           //Even Cycle
           if(UplineCycleNo%2==0){
             _PlaceInUp30(placementId,2);
           }
           //Odd Cycle
           else{
             _PlaceInUp30(placementId,1);
              uint256 CalculativeUPBonus=((packagePrice[1]*universalpoolper)/100);
              UpdateUpBonus(placementId,CalculativeUPBonus,30);
           }
         }
         //Calculation End Here
       }
      }
    }

    function _PlaceInUp60(address user,uint noofentry) private {
      for(uint I=1;I<=noofentry;I++){
       Up60List.push(user);
       _UserUPCycleCount[user].totalUp60Id += 1;
      uint Length=Up60List.length;
      Length -= 1;
      if((Length%upWidth)==0){
         uint Index=Length/upWidth;
         Index -= 1;
         address placementId=Up60List[Index];
         //Calculation Start Here
         uint UplineCycleNo=_UserUPCycleCount[placementId].totalUp60Id;
         //Odd Cycle 0 % 2 Not Possible So Supposing It's Odd Number
         if(UplineCycleNo==0){
            _PlaceInUp60(placementId,1);
             uint256 CalculativeUPBonus=((packagePrice[2]*universalpoolper)/100);
             UpdateUpBonus(placementId,CalculativeUPBonus,60);
         }
         else {
           //Even Cycle
           if(UplineCycleNo%2==0){
             _PlaceInUp60(placementId,2);
           }
           //Odd Cycle
           else{
             _PlaceInUp60(placementId,1);
              uint256 CalculativeUPBonus=((packagePrice[2]*universalpoolper)/100);
              UpdateUpBonus(placementId,CalculativeUPBonus,60);
           }
         }
         //Calculation End Here
       }
      }
    }

    function _PlaceInUp120(address user,uint noofentry) private {
      for(uint I=1;I<=noofentry;I++){
       Up120List.push(user);
       _UserUPCycleCount[user].totalUp120Id += 1;
      uint Length=Up120List.length;
      Length -= 1;
      if((Length%upWidth)==0){
         uint Index=Length/upWidth;
         Index -= 1;
         address placementId=Up120List[Index];
         //Calculation Start Here
         uint UplineCycleNo=_UserUPCycleCount[placementId].totalUp120Id;
         //Odd Cycle 0 % 2 Not Possible So Supposing It's Odd Number
         if(UplineCycleNo==0){
            _PlaceInUp120(placementId,1);
             uint256 CalculativeUPBonus=((packagePrice[3]*universalpoolper)/100);
             UpdateUpBonus(placementId,CalculativeUPBonus,120);
         }
         else {
           //Even Cycle
           if(UplineCycleNo%2==0){
             _PlaceInUp120(placementId,2);
           }
           //Odd Cycle
           else{
             _PlaceInUp120(placementId,1);
              uint256 CalculativeUPBonus=((packagePrice[3]*universalpoolper)/100);
              UpdateUpBonus(placementId,CalculativeUPBonus,120);
           }
         }
         //Calculation End Here
       }
      }
    }

    function _PlaceInUp240(address user,uint noofentry) private {
      for(uint I=1;I<=noofentry;I++){
       Up240List.push(user);
       _UserUPCycleCount[user].totalUp240Id += 1;
      uint Length=Up240List.length;
      Length -= 1;
      if((Length%upWidth)==0){
         uint Index=Length/upWidth;
         Index -= 1;
         address placementId=Up240List[Index];
         //Calculation Start Here
         uint UplineCycleNo=_UserUPCycleCount[placementId].totalUp240Id;
         //Odd Cycle 0 % 2 Not Possible So Supposing It's Odd Number
         if(UplineCycleNo==0){
            _PlaceInUp240(placementId,1);
             uint256 CalculativeUPBonus=((packagePrice[4]*universalpoolper)/100);
             UpdateUpBonus(placementId,CalculativeUPBonus,240);
         }
         else {
           //Even Cycle
           if(UplineCycleNo%2==0){
             _PlaceInUp240(placementId,2);
           }
           //Odd Cycle
           else{
             _PlaceInUp240(placementId,1);
              uint256 CalculativeUPBonus=((packagePrice[4]*universalpoolper)/100);
              UpdateUpBonus(placementId,CalculativeUPBonus,240);
           }
         }
         //Calculation End Here
       }
      }
    }

    function _PlaceInUp480(address user,uint noofentry) private {
      for(uint I=1;I<=noofentry;I++){
       Up480List.push(user);
       _UserUPCycleCount[user].totalUp480Id += 1;
      uint Length=Up480List.length;
      Length -= 1;
      if((Length%upWidth)==0){
         uint Index=Length/upWidth;
         Index -= 1;
         address placementId=Up480List[Index];
         //Calculation Start Here
         uint UplineCycleNo=_UserUPCycleCount[placementId].totalUp480Id;
         //Odd Cycle 0 % 2 Not Possible So Supposing It's Odd Number
         if(UplineCycleNo==0){
            _PlaceInUp480(placementId,1);
             uint256 CalculativeUPBonus=((packagePrice[5]*universalpoolper)/100);
             UpdateUpBonus(placementId,CalculativeUPBonus,480);
         }
         else {
           //Even Cycle
           if(UplineCycleNo%2==0){
             _PlaceInUp480(placementId,2);
           }
           //Odd Cycle
           else{
             _PlaceInUp480(placementId,1);
              uint256 CalculativeUPBonus=((packagePrice[5]*universalpoolper)/100);
              UpdateUpBonus(placementId,CalculativeUPBonus,480);
           }
         }
         //Calculation End Here
       }
      }
    }
}