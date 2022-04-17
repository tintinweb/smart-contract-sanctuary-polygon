// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ParisNftDay2022.sol";
import "./LeapToTheFuture.sol";
import "./Pbws2022.sol";

contract GiftBagDropper is Ownable {

    LeapToTheFuture private leapToTheFuture = LeapToTheFuture(0x0424D526FEdebf9A6585aC20034cCe097531084B);

    ParisNftDay2022 private parisNftDay2022 = ParisNftDay2022(0xCE51d67d1AFCD5e134AB671b73B4E0f5e7ee0412);

    Pbws2022 private pbws2022 = Pbws2022(0x6Fb590c5C8169808Ad9825EA791DCd5C3D4b1d82);

 //   IERC1155 private kalissaVisitCard = IERC1155(0x2953399124F0cBB46d2CbACD8A89cF0599974963);

    constructor(){}

    function drop(address targetAddress, bool bigBag) external onlyOwner {
        if(leapToTheFuture.totalSupply()<1070){
            leapToTheFuture.drop(targetAddress);
        }
        parisNftDay2022.drop(targetAddress, bigBag ? 2 : 1);
        pbws2022.drop(targetAddress, bigBag ? 2 : 1);
 //       kalissaVisitCard.safeTransferFrom(msg.sender, targetAddress, 79171102851626454107633356906327179233133378767603269003632620124106024560400, 1, "");
    }


}