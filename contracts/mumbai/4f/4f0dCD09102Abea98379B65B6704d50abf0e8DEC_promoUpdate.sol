// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;



contract promoUpdate {

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

    function updatePromo (
        uint64 eventId, //new event to change the promoEvent
        uint64 eventIDs,
        string memory promoCode,
        PromoCodes[] memory _promoCodes
    ) external {

        require(promoIsValid[promoCode][eventIDs], "InvalidPromoForEvent");
       if (eventId == 0){
   if(promoCodeDetails[promoCode].isFree)
  //first if
            {         
               require(promoIsValidForTicket[promoCode][promoCodeDetails[promoCode].tiketIDs],"InvalidPromoForTicket");
                   if(promoCodeDetails[promoCode].tiketIDs == _promoCodes[0].tiketIDs)
                   {
                   promoCodeDetails[promoCode] = _promoCodes[0];
                   }
                   else {
                    promoIsValidForTicket[promoCode][promoCodeDetails[promoCode].tiketIDs] = false; 
                    promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                    if(_promoCodes[0].tiketIDs > 0){
                        promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                    }
                    promoCodeDetails[promoCode] = _promoCodes[0];
                   }
                    promoIsValid[promoCode][eventIDs] = true;
       }
       else {
                promoCodeDetails[promoCode] = _promoCodes[0];
                    if(promoCodeDetails[promoCode].isFree){
                   promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                    }
                   promoIsValid[promoCode][eventIDs] = true;
  }// first else
         }
         else{
             if(promoCodeDetails[promoCode].isFree){
                                    if(promoCodeDetails[promoCode].tiketIDs == _promoCodes[0].tiketIDs)
                                    {
                                           promoCodeDetails[promoCode] = _promoCodes[0];

                                    }
                                    else{
              promoIsValidForTicket[promoCode][promoCodeDetails[promoCode].tiketIDs] = false; 
                   promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 

                                    }

             }
                   promoIsValid[promoCode][eventIDs] = false;
                   promoIsValid[promoCode][eventId] = true;
                   promoCodeDetails[promoCode] = _promoCodes[0];
                   if(promoCodeDetails[promoCode].isFree){
                   promoIsValidForTicket[promoCode][_promoCodes[0].tiketIDs] = true; 
                   }
         }
} // function close brackets
} // smart contract end


















     // promoIsValid[promoCode][eventIDs] = true;

        //     if(eventIDs == eventId){
        //                promoIsValid[promoCode][eventId] = true;
        //     }
        // else {
        //            promoIsValid[promoCode][eventIDs] = true;

        // }







    // function updatePromoCode(
    //     uint64  eventIDs, // want to update id on event
    //     string memory promoCode,// want to update id on event
    //     uint64  _eventIDs,  // new id on event
    //     string memory _promoCode, // new promoCodeName
    //     PromoCodes[] memory _promoCodes //new data for promoCodeTuples
    // ) external  {
      
    //   require(promoIsValid[promoCode][eventIDs],"InvalidPromoForUpdate");

    //   if(promoCodeDetails[promoCode].isFree){
    //          require(promoIsValidForTicket[promoCode][promoCodeDetails[promoCode].tiketIDs],"PromoCodeIsNotValidForTicket");
    //         promoIsValid[promoCode][eventIDs] = false;
    //         promoIsValid[_promoCode][_eventIDs] = true;
    //         promoCodeDetails[_promoCode] = _promoCodes[0];
    //         if(promoCodeDetails[_promoCode].isFree){
    //         promoIsValidForTicket[promoCode][promoCodeDetails[promoCode].tiketIDs]= false;
    //         promoIsValidForTicket[_promoCode][_promoCodes[0].tiketIDs] = true; 
    //         }
    //         else{
    //                         promoIsValid[promoCode][eventIDs] = false;
    //                         promoIsValid[_promoCode][_eventIDs] = true;

    //         }
    //     //   promoIsValidForTicket[promoCode[0]][_promoCodes[0].tiketIDs] = false; 
    //                 //  promoIsValidForTicket[_promoCode][_eventIDs] = true;

    //   }

    //   // first if
    //   else 
    //   {
    //        promoIsValid[promoCode][eventIDs] = false;
    //        promoIsValid[_promoCode][_eventIDs] = true;
    //        promoCodeDetails[_promoCode] = _promoCodes[0];
    //        if(promoCodeDetails[_promoCode].isFree)
    //        {
    //         promoIsValidForTicket[promoCode][promoCodeDetails[promoCode].tiketIDs]= false;
    //         promoIsValidForTicket[_promoCode][_promoCodes[0].tiketIDs] = true; 
    //        }
    //   }

    // }