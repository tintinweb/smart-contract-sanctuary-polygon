/**
 *Submitted for verification at polygonscan.com on 2022-09-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract datamemory {

            string public my_name = "habib" ;


 

 function set_my_new_name( string memory _name) public returns(string memory){

     my_name =_name ; 



    return my_name ; 


 }
    

}