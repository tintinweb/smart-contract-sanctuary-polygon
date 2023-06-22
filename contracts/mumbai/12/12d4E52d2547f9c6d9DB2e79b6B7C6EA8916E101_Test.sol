// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract Test {
    //address public owner;
    uint256 public number;

    /*modifier onlyOwner {
        require(msg.sender == owner, "Random.onlyOwner");
        _;
    }*/

    function setNumber(uint256 _number) external {
        number = _number;

        //(uint256 fee, address feeToken) = _getFeeDetails();
        //_transfer(fee, feeToken);
    }

    /*function withdraw(address payable to, uint256 amount) external onlyOwner {
        (bool sent,) = to.call{value: amount}("");
        require(sent, "Random.withdraw: failed to withdraw");
    }*/
}