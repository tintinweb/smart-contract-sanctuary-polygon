/**
 *Submitted for verification at polygonscan.com on 2022-05-18
*/

pragma solidity^0.8.0;

contract demo{
     event Event1(uint num,address lender);
     event Event2(address lender,string name);
     event Event3(uint num,address lender);


     function func1(uint _num,address addrr) external{
         emit Event1(_num,addrr);
     }
     function func2(string calldata  _name,address addrr) external{
         emit Event2(addrr,_name);
     }
     function func3(uint _num,address addrr) external{
         emit Event3(_num,addrr);
     }
}