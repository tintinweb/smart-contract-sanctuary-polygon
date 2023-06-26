//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Restricted.sol";

contract Referal_Matching is RestrictedFunctions {

   constructor (IBEP20 _usdt) {
      USDT = _usdt;
      isRegistered[owner()] = true;
   }

   function join (address _ref,uint256 _package, uint8 _flag) external isLock {
      require (package[_package] > 0,'Invalid package');
      address user = _msgSender();
      uint256 _amount = package[_package];
      ROI storage roi = ROI_DATA[user];
      require(user != _ref,'Incorrect ref');
      require(isRegistered[_ref],'Invalid ref');
      require(roi.amount == 0,'Only one active package for user');
      tokenSafeTransferFrom(USDT,user,address(this),_amount);
      roi.earnLimit = _amount * revenue;
      roi.amount = _amount;
      roi.depositTime = block.timestamp;
      roi.user = user;
      isRegistered[user] = true;
      (address ref1,address ref2) = updateReferals(_ref);
      roi.referer = ref1;
      ROI_DATA[ref1].refEarned += _amount * ref_1_Percent / 100e18;
      ROI_DATA[ref2].refEarned += _amount * ref_2_Percent / 100e18;
      emit ReferalCommission ([ref1,ref2],[_amount * ref_1_Percent / 100e18,_amount * ref_2_Percent / 100e18]);
      _match(user,ref1,_flag);
      emit Join(user, ref1, ref2, _package, _amount, roi.depositTime);
   }

   function updateReferals (address _ref) internal view returns (address,address) {

          address[] memory referals = new address[](2);
          referals[0] = _ref;
          referals[1] = ROI_DATA[_ref].referer;

          if (referals[1] == address(0)) {
             referals[1] = owner();
             return addressValidate(referals);
          }
          return addressValidate(referals);
      
   }

   function addressValidate (address[]memory _ref) internal view returns(address,address) {
      address ref1 = transformedAddress[_ref[0]] == address(0) ? _ref[0]:transformedAddress[_ref[0]];
      address ref2 = transformedAddress[_ref[1]] == address(0) ? _ref[1]:transformedAddress[_ref[1]];
      return (ref1,ref2);
   }
   
   function _match (address _user,address _referer,uint8 _flag) internal {
      ROI storage roi = ROI_DATA[_referer];
      uint256 userAmt = ROI_DATA[_user].amount;

      if (_flag == 1) {
         roi.left_side_ref.push(_user);
         roi.left_match_amt +=userAmt;
      }
      else {
         roi.right_side_ref.push(_user);
         roi.right_match_amt +=userAmt;
      }

      if (roi.left_side_ref.length == 0 || roi.right_side_ref.length == 0)
      return;

      if (roi.left_match_amt == 0 ||  roi.right_match_amt == 0)
      return;

      uint256 matchAmt;
      if (roi.left_match_amt <= roi.right_match_amt) {
          matchAmt = roi.left_match_amt;
          roi.left_match_amt = 0;
          roi.right_match_amt -= matchAmt;
      } 
      else {
          matchAmt = roi.right_match_amt;
          roi.right_match_amt = 0;
          roi.left_match_amt -= matchAmt;
      }
      matchCount[_referer]++;
      updateMatchBonus(_referer, matchCount[_referer], matchAmt,match_level_1);

      address refOfref = roi.referer;

      if (refOfref == address(0))
      return;
      else {
         matchCount[refOfref]++;
         updateMatchBonus(refOfref, matchCount[refOfref],matchAmt, match_level_2);
      }
   }

   function updateMatchBonus (address ref, uint16 count, uint256 matchAmt,uint256 percent) internal  {
      Matching storage matching = matchDetails[ref][count];
      matching.startTime = block.timestamp;
      matching.amt = matchAmt * percent / 100e18;
   }

   function viewUserDetails (address _user) external view returns(ROI memory) {
      return ROI_DATA[_user];
   }

}