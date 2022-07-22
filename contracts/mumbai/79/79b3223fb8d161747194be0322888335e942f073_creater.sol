/**
 *Submitted for verification at polygonscan.com on 2022-07-22
*/

contract callerr{

uint num;
function wae(uint input) public returns (uint){
num+=input;
return input*input;    
}

function getNum()public returns (uint){
    return num;
}

}

contract creater{

callerr public contract12;
callerr[] public arrayContract;

function newCOntract2() public {
    arrayContract.push( new callerr());

}

function tesing(callerr input, uint num) public returns (uint){
return input.wae(num);
}

function tesing(callerr input) public returns (uint){
return input.getNum();
}

}