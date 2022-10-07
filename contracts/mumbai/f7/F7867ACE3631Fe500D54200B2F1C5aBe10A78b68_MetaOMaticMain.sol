//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./MetaOMaticUniversal.sol";

contract MetaOMaticMain  is MetaOMaticUniversal {

    //Admin Can Verify New Id
    function _verifyId(address user,address referrer) public {
        require(msg.sender == contractOwner, "Only Admin Can ?");
        require(!_IsUserExists(user), "Already Registered !"); 
        require(_IsUserExists(referrer), "Referral Not Exists !"); 
        uint32 size;
        assembly { size := extcodesize(user) }	
        require(size == 0, "Smart Contract !");
        uint TimeStamp=block.timestamp;
        _UserAffiliateDetails[user].userId = TimeStamp;
        _UserAffiliateDetails[user].sponsor = referrer;
        _UserAffiliateDetails[user].joiningDateTime= TimeStamp;

        for (uint8 i = 0; i < totalPackage; i++) {
            _UserAffiliateDetails[user].packagePurchased[i] = true;
            _UserAffiliateDetails[user].purchasedDateTime[i] = TimeStamp;
            _UserAffiliateDetails[user].selfInvestment+=packagePrice[i];
            totalPackagePurchased+=packagePrice[i];
            if(i==0){_PlaceInUp10(user,1,1);_SystemPackageId[0].total10Id += 1;}
             else if(i==1){_PlaceInUp20(user,1,1);_SystemPackageId[0].total20Id += 1;}
             else if(i==2){_PlaceInUp40(user,1,1);_SystemPackageId[0].total40Id += 1;}
             else if(i==3){_PlaceInUp80(user,1,1);_SystemPackageId[0].total80Id += 1;}
             else if(i==4){_PlaceInUp160(user,1,1);_SystemPackageId[0].total160Id += 1;}
             else if(i==5){_PlaceInUp320(user,1,1);_SystemPackageId[0].total320Id += 1;}
             m6contract.placeInM6(user,referrer,i);
               //Manage Upline Data Start Here
             if (_UserAffiliateDetails[user].sponsor != address(0)) {	   
                 //Level Wise Business & Id Count
             address upline = _UserAffiliateDetails[user].sponsor;
             for (uint SpCount = 0; SpCount < 10000000; SpCount++) {
             if (upline != address(0)) {
             _UserAffiliateDetails[upline].levelWiseBusiness[SpCount] += packagePrice[i];
             _UserAffiliateDetails[upline].refs[SpCount] += 1;
              upline = _UserAffiliateDetails[upline].sponsor;
                    } 
              else break;
                     }
                  }
                //Manage Upline Data End Here
             _refPayout(user,((packagePrice[i]*m6per)/100));
            }
        
        userIdToAddress[TimeStamp] = user;
        totalNumberofUsers +=1;
        emit VerifyId(user);
    }

    function _Joining(address referrer) external payable {
      registration(msg.sender, referrer,msg.value);
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
        //Manage Upline Data Start Here
        if (_UserAffiliateDetails[user].sponsor != address(0)) {	   
           //Level Wise Business & Id Count
            address upline = _UserAffiliateDetails[user].sponsor;
            for (uint i = 0; i < 10000000; i++) {
            if (upline != address(0)) {
             _UserAffiliateDetails[upline].levelWiseBusiness[i] += amount;
             _UserAffiliateDetails[upline].refs[i] += 1;
             upline = _UserAffiliateDetails[upline].sponsor;
               } 
               else break;
            }
        }
        //Manage Upline Data End Here
            _UserAffiliateDetails[user].joiningDateTime= TimeStamp;
            _UserAffiliateDetails[user].packagePurchased[0] = true;
            _UserAffiliateDetails[user].purchasedDateTime[0] = TimeStamp;
            _UserAffiliateDetails[user].selfInvestment+=packageprice; 
            userIdToAddress[TimeStamp] = user;
            totalNumberofUsers +=1;
            totalPackagePurchased+=packageprice;
            _SystemPackageId[0].total10Id += 1;
            _PlaceInUp10(user,1,1);
            uint256 M6Amount=((((packageprice*m6per)/100)*60)/100);
            m6contract._verifyInMatic{value:M6Amount}();
            m6contract.placeInM6(user,referrer,0);
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
          //Manage Upline Data Start Here
          if (_UserAffiliateDetails[user].sponsor != address(0)) {	   
          //Level Wise Business & Id Count
          address upline = _UserAffiliateDetails[user].sponsor;
          for (uint i = 0; i < 10000000; i++) {
          if (upline != address(0)) {
          _UserAffiliateDetails[upline].levelWiseBusiness[i] += amount;
            upline = _UserAffiliateDetails[upline].sponsor;
            } 
        else break;
          }
      }
        //Manage Upline Data End Here
         address referrer=_UserAffiliateDetails[user].sponsor;
         totalPackagePurchased+=packageprice;
        if(package==1){
            _PlaceInUp20(user,1,1);
            _SystemPackageId[0].total20Id += 1;
        }
        else if(package==2){
             _PlaceInUp40(user,1,1);
            _SystemPackageId[0].total40Id += 1;
        }
        else if(package==3){
            _PlaceInUp80(user,1,1);
            _SystemPackageId[0].total80Id += 1;
        }
        else if(package==4){
            _PlaceInUp160(user,1,1);
            _SystemPackageId[0].total160Id += 1;
        }
        else if(package==5){
            _PlaceInUp320(user,1,1);
            _SystemPackageId[0].total320Id += 1;
        }
        uint256 M6Amount=((((packageprice*m6per)/100)*60)/100);
        m6contract._verifyInMatic { value:M6Amount }();
        m6contract.placeInM6(user,referrer,package);
        _refPayout(user,((packageprice*m6per)/100));
        emit Upgrade(user,package,packageprice);
    }

    function UpdateUpBonus(address user,uint256 amount,uint UpNo) private {
      _UserIncomeDetails[user].totalUPBonus += amount;
      _UserIncomeDetails[user].totalBonus += amount;
      _UserIncomeDetails[user].creditedBonus += amount;
      _UserIncomeDetails[user].availableBonus += amount;
      totalUpIncome+=amount;
     if(UpNo==10){
        _SystemUpBonusDetails[0].totalUp10Bonus += amount;
        _UserUPBonusDetails[user].totalUp10Bonus += amount;
      }
      else if(UpNo==20){
        _SystemUpBonusDetails[0].totalUp20Bonus += amount;
        _UserUPBonusDetails[user].totalUp20Bonus += amount;
      }
      else if(UpNo==40){
        _SystemUpBonusDetails[0].totalUp40Bonus += amount;
        _UserUPBonusDetails[user].totalUp40Bonus += amount;
      }
      else if(UpNo==80){
        _SystemUpBonusDetails[0].totalUp80Bonus += amount;
        _UserUPBonusDetails[user].totalUp80Bonus += amount;
      }
      else if(UpNo==160){
        _SystemUpBonusDetails[0].totalUp160Bonus += amount;
        _UserUPBonusDetails[user].totalUp160Bonus += amount;
      }
      else if(UpNo==320){
        _SystemUpBonusDetails[0].totalUp320Bonus += amount;
        _UserUPBonusDetails[user].totalUp320Bonus += amount;
      }
      _WithdrawalAuto(payable(user));
    }

    function _PlaceInUp10(address user,uint noofentry,uint level) private {
      for(uint I=1;I<=noofentry;I++) {
          _UserUPCycleCount[user].totalUp10Id += 1;
          Up10List.push(user);
          Up10LevelCount.push(level);
          _UserUPLevelCount[user].totalUp10=level;
          uint Length=Up10List.length;
          Length -= 1;
        if((Length%upWidth)==0) {
          uint Index=Length/upWidth;
          Index -= 1;
          address placementId=Up10List[Index];
              //Calculation Start Here
            uint LevelNo=Up10LevelCount[Index];
              //Even Level
            if(LevelNo%2==0){
            _PlaceInUp10(placementId,2,(LevelNo+1));
          }
            //Odd Cycle
          else{
            uint256 CalculativeUPBonus=((packagePrice[0]*universalpoolper)/100);
            UpdateUpBonus(placementId,CalculativeUPBonus,10);
            _PlaceInUp10(placementId,1,(LevelNo+1));
              }
            }
            //Calculation End Here
          }
        }

    function _PlaceInUp20(address user,uint noofentry,uint level) private {
      for(uint I=1;I<=noofentry;I++) {
          _UserUPCycleCount[user].totalUp20Id += 1;
          Up20List.push(user);
          Up20LevelCount.push(level);
          _UserUPLevelCount[user].totalUp20=level;
          uint Length=Up20List.length;
          Length -= 1;
          if((Length%upWidth)==0) {
           uint Index=Length/upWidth;
           Index -= 1;
            address placementId=Up20List[Index];
              //Calculation Start Here
            uint LevelNo=Up20LevelCount[Index];
              //Even Level
           if(LevelNo%2==0){
              _PlaceInUp20(placementId,2,(LevelNo+1));
              }
              //Odd Cycle
           else{
              uint256 CalculativeUPBonus=((packagePrice[1]*universalpoolper)/100);
              UpdateUpBonus(placementId,CalculativeUPBonus,20);
               _PlaceInUp20(placementId,1,(LevelNo+1));
             }
           }
            //Calculation End Here
         }
      }

    function _PlaceInUp40(address user,uint noofentry,uint level) private {
      for(uint I=1;I<=noofentry;I++) {
          _UserUPCycleCount[user].totalUp40Id += 1;
          Up40List.push(user);
          Up40LevelCount.push(level);
          _UserUPLevelCount[user].totalUp40=level;
          uint Length=Up40List.length;
          Length -= 1;
          if((Length%upWidth)==0) {
            uint Index=Length/upWidth;
            Index -= 1;
            address placementId=Up40List[Index];
            //Calculation Start Here
            uint LevelNo=Up40LevelCount[Index];
            //Even Level
          if(LevelNo%2==0){
             _PlaceInUp40(placementId,2,(LevelNo+1));
          }
          //Odd Cycle
          else{
            uint256 CalculativeUPBonus=((packagePrice[2]*universalpoolper)/100);
            UpdateUpBonus(placementId,CalculativeUPBonus,40);
            _PlaceInUp40(placementId,1,(LevelNo+1));
           }
        }
         //Calculation End Here
    }
  }

    function _PlaceInUp80(address user,uint noofentry,uint level) private {
      for(uint I=1;I<=noofentry;I++) {
          _UserUPCycleCount[user].totalUp80Id += 1;
          Up80List.push(user);
          Up80LevelCount.push(level);
          _UserUPLevelCount[user].totalUp80=level;
          uint Length=Up80List.length;
          Length -= 1;
          if((Length%upWidth)==0) {
              uint Index=Length/upWidth;
              Index -= 1;
              address placementId=Up80List[Index];
              //Calculation Start Here
              uint LevelNo=Up80LevelCount[Index];
              //Even Level
              if(LevelNo%2==0){
                _PlaceInUp80(placementId,2,(LevelNo+1));
              }
              //Odd Cycle
              else{
                  uint256 CalculativeUPBonus=((packagePrice[3]*universalpoolper)/100);
                  UpdateUpBonus(placementId,CalculativeUPBonus,80);
                  _PlaceInUp80(placementId,1,(LevelNo+1));
              }
            }
            //Calculation End Here
          }
        }

    function _PlaceInUp160(address user,uint noofentry,uint level) private {
      for(uint I=1;I<=noofentry;I++) {
          _UserUPCycleCount[user].totalUp160Id += 1;
          Up160List.push(user);
          Up160LevelCount.push(level);
          _UserUPLevelCount[user].totalUp160=level;
          uint Length=Up160List.length;
          Length -= 1;
          if((Length%upWidth)==0) {
              uint Index=Length/upWidth;
              Index -= 1;
              address placementId=Up160List[Index];
              //Calculation Start Here
              uint LevelNo=Up160LevelCount[Index];
              //Even Level
              if(LevelNo%2==0){
                _PlaceInUp160(placementId,2,(LevelNo+1));
              }
              //Odd Cycle
              else{
              uint256 CalculativeUPBonus=((packagePrice[4]*universalpoolper)/100);
              UpdateUpBonus(placementId,CalculativeUPBonus,160);
            _PlaceInUp160(placementId,1,(LevelNo+1));
              }
            }
            //Calculation End Here
          }
        }

    function _PlaceInUp320(address user,uint noofentry,uint level) private {
      for(uint I=1;I<=noofentry;I++) {
          _UserUPCycleCount[user].totalUp320Id += 1;
          Up320List.push(user);
          Up320LevelCount.push(level);
          _UserUPLevelCount[user].totalUp320=level;
          uint Length=Up320List.length;
          Length -= 1;
          if((Length%upWidth)==0) {
              uint Index=Length/upWidth;
              Index -= 1;
              address placementId=Up320List[Index];
              //Calculation Start Here
              uint LevelNo=Up320LevelCount[Index];
              //Even Level
              if(LevelNo%2==0){
                _PlaceInUp320(placementId,2,(LevelNo+1));
              }
              //Odd Cycle
              else{
                  uint256 CalculativeUPBonus=((packagePrice[5]*universalpoolper)/100);
                  UpdateUpBonus(placementId,CalculativeUPBonus,480);
                  _PlaceInUp320(placementId,1,(LevelNo+1));
              }
            }
            //Calculation End Here
          }
        }

    }