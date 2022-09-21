/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Tokeybuy {
    address public beneficiary = 0x6486EFE0EBfE4F0FeB7b528CC857cbb7A6c987F1;  /** indirizzo del account dove andranno i cambi*/
    uint public amountRaised = 0;
    uint public tokenquantity = 0;
    uint public price = 0.001 * 1 ether;
    token public tokenReward = token(0x91B30BE6E9129f595348EB27717291f3e467B677); /** Indirizzo Del Token KPL */
    mapping(address => uint256) public balanceOf;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constructor function
     *
     * Setup the owner
     */
	 
    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */


    function () payable {
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount * 1000000000000000000 / price);
        FundTransfer(msg.sender, amount, true);
        if ( msg.sender != beneficiary) 
           { 
            GoalReached(beneficiary, amountRaised);                      
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
                amountRaised=0;
                                                }
           }
    }

    function setrewardaddress(address _rw) public 
    { 
        tokenReward = token(_rw);
    }

    function setbeneficiaryaddress(address _be) public 
    { 
        beneficiary = _be;
    }

    function setprice(uint _pr) public 
    { 
        price = _pr * 1 ether;
    }

}