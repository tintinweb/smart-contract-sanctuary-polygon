/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract hisVows {

    string public theVows = "My serenity My peace / 2 turtles A quiet calmness My best friend Love so true / Tu eres toda mi vida El amor de mi vida / We weren't looking for love / We went through some tough times / We counted our 5 dates / Harry may have sealed the deal even though I told you I loved you about 3 hours after you guys met / I love you Perla Perez / I want to challenge you, I want to awaken you, I want to give you my support / I commit to being my the absolute best version I can be of myself for you and for us / I promise to motivate when times are tough. To be that positive light that was so strong when we first started dating / Through good and bad, through sickness and in health, I promise to love you and cherish your love / If we continue to love and value each other and prioritize each other we will be able to thrive and grow together as an incredible team / I know we have such strong support from your family and mine, I promise to use our support systems when we both may need a little kick in the butt" ;
    string public theDate = "December 27th, 2021";

    function getTheVows() public view returns (string memory) {
        return theVows;
    }

    function getTheDate() public view returns (string memory) {
        return theDate;
    }

}