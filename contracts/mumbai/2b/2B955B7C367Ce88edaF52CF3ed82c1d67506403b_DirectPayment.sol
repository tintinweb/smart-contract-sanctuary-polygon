pragma solidity ^0.8.0;

contract DirectPayment {

    event PaymentSent(address indexed from, address indexed to);

    /**
     * @dev Transfer a specified amount of ether from one account to another.
     * @param to The address of the recipient.
     * @param amount The amount of ether to be transferred.
     */
    function transferEther(address payable to, uint256 amount) public payable {
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        require(msg.value == amount, "Incorrect value sent");

        to.transfer(amount);

        emit PaymentSent(msg.sender, to);
    }
}