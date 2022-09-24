// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.7;

//interface////////////////////////////////////////////////////////////////////////////////////// done

interface myInterface {
    function name() external  returns(string memory) ;
    function money() external;
}



//abstract/////////////////////////////////////////////////////////////////////////////////////// done

abstract contract myAbstract{
uint256 public carWheels = 4;
string public companyName;
function fun() internal pure  virtual returns(string memory) {
        return "hello";
}
function test() internal virtual;

constructor(){
    companyName = "gautam ka startup";
}

}

//mibrary//////////////////////////////////////////////////////////////////////////////////////////

library myLibrary{

    function sum(uint256 a,uint256 b) internal pure returns(uint256){
            return a+b;
    }

}

//parent///////////////////////////////////////////////////////////////////////////////////////////

contract parent{

    string public parantName = "papa ji";

    function papakafunction() virtual public{

    }


}

contract myContract is parent,myInterface,myAbstract{

     string public override name = "hello";

    function money() override public {

    }

     function test() override internal {

     }

     using myLibrary for uint256;

     uint256 maths=10;

     function sum(uint256 a) public view returns(uint256){
         return maths.sum(a);
     }

    function papakafunction() virtual override  public{

    }

}

contract child is myContract{



}