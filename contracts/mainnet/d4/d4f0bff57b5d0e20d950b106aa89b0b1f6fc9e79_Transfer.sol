/**
 *Submitted for verification at polygonscan.com on 2023-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMathInt {
    
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

}


contract Transfer{
    using SafeMath for uint256;

    

    mapping(address=>uint) public referral_balances;
    uint public deposit_one_percentage = 10;
    uint[10] public f_percentages = [10, 5, 3, 2, 1, 1, 1, 1, 1, 1];

    address payable company;

    constructor(address payable _company){
        //
        company = _company;
    }

/*        Read contract          */
    
    function balance() public view returns(uint){
        return address(this).balance;
    }

    function setDeposit_one_percentage(uint _percentage) public{
        require(msg.sender == company, "You are not othorised");
        deposit_one_percentage = _percentage;

    }
    function  setF_percentages(uint _index, uint _percentage) public{
        require(msg.sender == company, "You are not othorised");
        require(_index<10, "invalid index");
        f_percentages[_index-1] = _percentage;

    }




    /*        Write contract     */


    function depositOneReferral(address _friend) public payable{
        require(msg.sender == _friend, "Can't referrer youself");
        referral_balances[_friend] +=(msg.value*deposit_one_percentage)/100;
        
    }


    function depositTenReferral(address _f1, address _f2, address _f3, address _f4, address _f5, address _f6, address _f7, address _f8, address _f9, address _f10) public payable{
        referral_balances[_f1] += (msg.value*f_percentages[0])/100;
        referral_balances[_f2] += (msg.value*f_percentages[1])/100;
        referral_balances[_f3] += (msg.value*f_percentages[2])/100;
        referral_balances[_f4] += (msg.value*f_percentages[3])/100;
        referral_balances[_f5] += (msg.value*f_percentages[4])/100;
        referral_balances[_f6] += (msg.value*f_percentages[5])/100;
        referral_balances[_f7] += (msg.value*f_percentages[6])/100;
        referral_balances[_f8] += (msg.value*f_percentages[7])/100;
        referral_balances[_f9] += (msg.value*f_percentages[8])/100;
        referral_balances[_f10] += (msg.value*f_percentages[9])/100;

    }

    /*
        @params _amount in wai
    */
    function withdraw(uint _amount) public{
        require(_amount<= referral_balances[msg.sender], "Not enough balance");
        payable(msg.sender).transfer(_amount);
    }

    function setComapny(address payable _address) public{
        require(msg.sender == company, "You are not othorised");
        company = _address;
    }

    function companyWithdraw() public {
        require(msg.sender == company, "You are not othorised");

        company.transfer(address(this).balance);
    }

}