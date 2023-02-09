pragma solidity 0.8.18;

contract PayableSample { 
   
 address payable thisContract = payable(address(this));

    receive() external payable {}

    fallback() external payable {}

      function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

     function sendViaTransfer() public payable {
         thisContract.transfer(msg.value);
    }
    function transfer(address payable _to, uint _amount) public {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

 }