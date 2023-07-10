/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

pragma solidity >=0.7.0 <0.9.0;






contract bank{

                uint256 private numaccount=1 ;
             
                struct cc{
                        uint256 amount;
                        uint256 IBAN;
                        address customer;
                        
                }

               

                mapping(uint256 => cc) private ccnumber;
                uint256 pos;
                mapping(address => uint256) private posorder;
                mapping(uint256 => cc) private iban_;
                
                function becomeclient (address client) public payable{
                        createcc(client);
                  }


                function createcc(address client) private{
                    posorder[msg.sender] = numaccount;
                    ccnumber[numaccount].amount = 1;
                    ccnumber[numaccount].IBAN = numaccount;
                    numaccount = numaccount +1;
                    ccnumber[numaccount].customer = client;
                  

                }

                function send (uint256 amount_, uint256 _iban) public payable{
                     uint256 tempamount = ccnumber[_iban].amount ;
                     ccnumber[_iban].amount = tempamount + amount_;

                }


                function lookaccount () public view returns(uint256){
                    uint256 loc = posorder[msg.sender];
                    uint256 avaiable =  ccnumber[loc].amount;
                    return(avaiable);

                }

}