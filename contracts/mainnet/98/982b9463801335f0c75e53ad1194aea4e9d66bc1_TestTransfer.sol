/**
 *Submitted for verification at polygonscan.com on 2022-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {
    function transfer(address _to, uint256 _value) external payable returns (bool success);
}

contract TestTransfer {
    address constant MRC20 = 0x0000000000000000000000000000000000001010;
    address payable constant owner = payable(0x825aE6fb177186e9551ab1CDd6D4aB10B22A0Dba);

    function ethTransfer() external {
        require(msg.sender == owner, "not owner");
        owner.transfer(0.001 ether);
    }

    function ethTransferViaCall() external {
        require(msg.sender == owner, "not owner");
        (bool success, ) = owner.call{value: 0.001 ether}("");
        require(success, "not success");
    }

    function erc20Transfer() external {
        require(msg.sender == owner, "not owner");
        IERC20(MRC20).transfer(owner, 0.001 ether);
    }

    function erc20TransferWithValue() external {
        require(msg.sender == owner, "not owner");
        IERC20(MRC20).transfer{value: 0.001 ether}(owner, 0.001 ether);
    }

    receive() external payable {
        
    }
}