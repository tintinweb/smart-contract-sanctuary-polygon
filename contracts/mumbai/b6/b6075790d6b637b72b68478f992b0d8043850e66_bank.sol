/**
 *Submitted for verification at polygonscan.com on 2023-07-10
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
                
                function becomeclient () public payable{
                        createcc(msg.sender);
                  }


                function createcc(address client) private{
                    posorder[msg.sender] = numaccount;
                    ccnumber[numaccount].amount = 1;
                    ccnumber[numaccount].IBAN = numaccount;
                    numaccount = numaccount +1;
                    ccnumber[numaccount].customer = client;
                  

                }

                function send (uint256 amount_, uint256 _iban) public {
                     uint256 tempamount = ccnumber[_iban].amount ;
                     ccnumber[_iban].amount = tempamount + amount_;

                }


                function transfer (uint256 amount_, uint256 myiban, uint256 receiver) public {
                     uint256 tempamount = ccnumber[myiban].amount ;
                     ccnumber[myiban].amount = tempamount - amount_;


                     uint256 tempamount_r = ccnumber[receiver].amount ;
                     ccnumber[receiver].amount = tempamount_r + amount_;


                }


                function lookaccount () public view returns(uint256){
                    uint256 loc = posorder[msg.sender];
                    uint256 avaiable =  ccnumber[loc].amount;
                    return(avaiable);

                }

                 function lookaccount_p (address _address) public view returns(uint256){
                    uint256 loc = posorder[_address];
                    uint256 avaiable =  ccnumber[loc].amount;
                    return(avaiable);

                }

}