// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC1155.sol";
import "./LeapToTheFuture.sol";
import "./ParisNftDay2022.sol";
import "./Pbws2022.sol";

contract GiftBagDropper is Ownable {

    LeapToTheFuture private leapToTheFuture = LeapToTheFuture(0x6f491918cb0030B2a58aae2d265b9583EB5F2912);

    ParisNftDay2022 private parisNftDay2022 = ParisNftDay2022(0xbc932bD9C67A87a2B12603F3Ce4d919dA1Cf4d29);

    Pbws2022 private pbws2022 = Pbws2022(0xB9d91a4FeA14bBc0DD642c20C729d11e3aa72979);

    IERC1155 private kalissaVisitCard = IERC1155(0x2953399124F0cBB46d2CbACD8A89cF0599974963);

    constructor(){}

    function drop(address targetAddress, bool bigBag) external onlyOwner {
        if(leapToTheFuture.totalSupply()<1070){
            leapToTheFuture.drop(targetAddress);
        }
        parisNftDay2022.drop(targetAddress, bigBag ? 2 : 1);
        pbws2022.drop(targetAddress, bigBag ? 2 : 1);
        kalissaVisitCard.safeTransferFrom(msg.sender, targetAddress, 79171102851626454107633356906327179233133378767603269003632620124106024560400, 1, "");
    }


}