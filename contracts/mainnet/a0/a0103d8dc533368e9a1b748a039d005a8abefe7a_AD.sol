/**
 *Submitted for verification at polygonscan.com on 2022-03-29
*/

pragma solidity ^0.8.0;

contract AD {

    uint256 public number = 0;
    uint256 public cost = 1 ether;

    function changeNumber(uint256 _number) public payable{
        require(msg.value >= cost, "You have to send at least 1 MATIC");
        number = _number;
    }

      
    //Get Polygon balance
    function getBalance() public view returns (uint256){
        return (address(this).balance);
    }


    //Withdraw functions
    function withdrawMatic() public payable {
        // require(address(this).balance > 1 ether, "There is not enough matic in the contract");
        payable(msg.sender).transfer(address(this).balance);
    }


}