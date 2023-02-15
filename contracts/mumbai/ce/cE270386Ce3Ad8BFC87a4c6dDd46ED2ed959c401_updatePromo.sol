// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract updatePromo{
    mapping(string => mapping(uint256 => bool)) public promoIsValid; 
    
    mapping(string => mapping(uint256 => bool))  public promoIsValidForTicket; 


    mapping(string => PromoCodes) public promoCodeDetails;

    struct PromoCodes {
        uint256 discountPercentage;
        uint256 promoStartDate;
        uint256 promoEndDate;
        uint256 fixedDiscount;
        uint256 maxUsers;         
        uint256 claimedUsers;       
        uint256 maxDiscountAmount;
        bool discountIsPercentage;
        bool isFree;
        uint256 tiketIDs; 
    }



    //AddPromoCode
       function addPromoCodes(
        uint64[] memory _eventIDs, 
        string[] memory promoCode,
        PromoCodes[] memory _promoCodes
    ) external 
    // onlyOwner whenNotPaused
       {
        if(_eventIDs.length > 1){
        for (uint256 i = 0; i < _eventIDs.length; i++) {
            for (uint256 j = 0; j < _promoCodes.length; j++) 
            {
                promoIsValid[promoCode[j]][_eventIDs[i]] = true;
                promoCodeDetails[promoCode[j]] = _promoCodes[j];
            }
        }
         }
         else if(promoCode.length == 1)
         { 
            promoIsValid[promoCode[0]][_eventIDs[0]] = true;
            promoCodeDetails[promoCode[0]] = _promoCodes[0];

            if(promoCodeDetails[promoCode[0]].isFree)
          {    
               promoIsValidForTicket[promoCode[0]][_promoCodes[0].tiketIDs] = true; 
       }
       }
      
    }
 // updatePromoCode
   function updatePromoCode ( uint64 eventIDs, string memory promoCode, PromoCodes[] memory _promoCodes ) external
    // onlyOwner whenNotPaused
    {
                      if(promoCodeDetails[promoCode].isFree){
                        if(_promoCodes[0].isFree){
                                promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                                promoCodeDetails[promoCode] = _promoCodes[0];
                        }
                        else{

                            promoIsValidForTicket[promoCode][promoCodeDetails[promoCode].tiketIDs] = false; 
                             promoCodeDetails[promoCode] = _promoCodes[0];

                        }

                       promoIsValid[promoCode][eventIDs] = true;
                      
                      }
                      else
                      {
                              promoIsValid[promoCode][eventIDs] = true;
                             promoCodeDetails[promoCode] = _promoCodes[0];
                         if(promoCodeDetails[promoCode].isFree){
                            promoIsValidForTicket[promoCode][promoCodeDetails[promoCode].tiketIDs] = true; 
                         }
   }
}


}
// 03 Feb Friday 11:00 am 
// 08 Feb Friday 3:54 am 
// 14 Feb Tuesday 4:00 pm