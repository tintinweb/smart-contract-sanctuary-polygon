/**
 *Submitted for verification at polygonscan.com on 2023-01-02
*/

// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0;

interface web3DefiInterface {
    function withdrawBal(address _to, uint256 amount) external;
}

contract SupportFund {
    web3DefiInterface public mainContract;

    function setContract(address _contract) public {
        mainContract = web3DefiInterface(_contract);
    }

    function withdraw(address _to, uint256 _amount) public {
        mainContract.withdrawBal(_to, _amount);
    }
}