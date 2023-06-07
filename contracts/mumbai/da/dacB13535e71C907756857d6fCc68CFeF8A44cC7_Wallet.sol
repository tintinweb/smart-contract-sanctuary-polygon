/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

error Wallet__isNotOwner();

contract Wallet {
    address payable public owner;

    constructor(address payable _owner) {
        owner = _owner;
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        if (msg.sender != owner) revert Wallet__isNotOwner();
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}