// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "./balancer/IFlashLoanRecipient.sol";
//import "./balancer/IBalancerVault.sol";
//import "hardhat/console.sol";

contract ftest {
    event eLog3(uint256 nn,string name,bytes b);

    constructor() {
    }
    function test(bytes memory data)public
    {
	uint256 nn = 0;
	emit eLog3(nn++,"data",data);
    }
    function test2(bytes memory data)public
    {
	address[] memory addr;
	uint256[] memory amounts;
	bytes memory d;
	uint256 nn = 0;
	emit eLog3(nn++,"data",data);
	(addr,amounts,d) = abi.decode(data,(address[],uint256[],bytes));
    }
    function test3(bytes memory data)public
    {
    }
}