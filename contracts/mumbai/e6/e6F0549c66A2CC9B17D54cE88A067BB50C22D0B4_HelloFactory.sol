/**
 *Submitted for verification at polygonscan.com on 2023-04-13
*/

pragma solidity 0.8.19;

contract Hello {
}

contract HelloFactory {
    event DeployedTo(address);

    function deployHello() external {
        address addr1 = address(new Hello());
        emit DeployedTo(addr1);
        address addr2 = address(new Hello());
        emit DeployedTo(addr2);
    }
}