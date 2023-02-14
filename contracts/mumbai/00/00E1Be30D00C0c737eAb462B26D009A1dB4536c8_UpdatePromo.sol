// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;



contract UpdatePromo {

  mapping(string => mapping(uint256 => bool)) public promoIsValid; 
    
  mapping(string => mapping(uint256 => bool)) public promoIsValidForTicket; 
    event PromoCodeUpdate(string value); 


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
    ) external   {
        if(_eventIDs.length > 1){
        for (uint256 i = 0; i < _eventIDs.length; i++) {
            for (uint256 j = 0; j < _promoCodes.length; j++) 
            {
                promoIsValid[promoCode[j]][_eventIDs[i]] = true;
                promoCodeDetails[promoCode[j]] = _promoCodes[j];
            }
        }
         }
         //we can add here a logic to remove the if else to store a Ticket Id for free case
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

    function updatePromoFuntion (
        uint64 eventId, //new event to change the promoEvent
        uint64 eventIDs,
        string memory promoCode,
        PromoCodes[] memory _promoCodes
    ) external{
              require(promoIsValid[promoCode][eventIDs], "InvalidPromoForEvent");
              if(eventId == eventIDs)
              {
                    if(promoCodeDetails[promoCode].isFree)
                          {         
                   if(promoCodeDetails[promoCode].tiketIDs != _promoCodes[0].tiketIDs)
                   {
                    promoIsValidForTicket[promoCode][promoCodeDetails[promoCode].tiketIDs] = false; 
                    promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                    promoCodeDetails[promoCode] = _promoCodes[0];
                   }
                   else{
                     promoCodeDetails[promoCode] = _promoCodes[0];

                   }

       }
       else {
                promoCodeDetails[promoCode] = _promoCodes[0];
                    if(promoCodeDetails[promoCode].isFree){
                   promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                    }
                   promoIsValid[promoCode][eventIDs] = true;
  }
              } 
              else if(eventId != 0){
                    promoIsValid[promoCode][eventIDs] = false;
                   promoIsValid[promoCode][eventId] = true;
                   if(promoCodeDetails[promoCode].isFree){
                     if(promoCodeDetails[promoCode].tiketIDs != _promoCodes[0].tiketIDs)
                   {
                    promoIsValidForTicket[promoCode][promoCodeDetails[promoCode].tiketIDs] = false; 
                    promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                    promoCodeDetails[promoCode] = _promoCodes[0];
                   }
                   else{
                       promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                       promoCodeDetails[promoCode] = _promoCodes[0];
                   }
                   }
                   else {
                              promoCodeDetails[promoCode] = _promoCodes[0];
                   }
                   if(promoCodeDetails[promoCode].isFree){
                   promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
              }
              }
              else if(eventId == 0){
                       if(promoCodeDetails[promoCode].isFree){
                          if(promoCodeDetails[promoCode].tiketIDs != _promoCodes[0].tiketIDs){
                    promoIsValidForTicket[promoCode][promoCodeDetails[promoCode].tiketIDs] = false; 
                    promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                    promoCodeDetails[promoCode] = _promoCodes[0];
                          }
                          else {
                              promoCodeDetails[promoCode] = _promoCodes[0];
                              if(promoCodeDetails[promoCode].isFree){
                             promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                              }
                          }
              }

                                  promoIsValid[promoCode][eventIDs] = true;
                                 promoCodeDetails[promoCode] = _promoCodes[0];
                                 if(promoCodeDetails[promoCode].isFree){
                        promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                                 }
              }}
    }