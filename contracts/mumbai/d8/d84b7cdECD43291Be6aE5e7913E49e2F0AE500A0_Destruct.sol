pragma solidity 0.8.14;

contract Destruct {
    receive() external payable {}

    function destruct() public {
        selfdestruct(payable(msg.sender));
    }
}