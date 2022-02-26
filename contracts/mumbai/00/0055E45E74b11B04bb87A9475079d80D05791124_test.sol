/**
 *Submitted for verification at polygonscan.com on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
contract test{
uint public a=0;

function zero()external{
    a=0;
}
function inc(uint _a)external {
if (_a<30){
a++;
}
else if(_a<50){
 a+=5;
}
else if(_a<100){
 a+=10;
}
else if(_a>=100){
 a+=100;
}




}





}