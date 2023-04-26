/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

contract X {
    event Fallback(address indexed sender, uint256 indexed value, bytes data);

    fallback() external payable {
        emit Fallback(msg.sender, msg.value, msg.data);
    }
}