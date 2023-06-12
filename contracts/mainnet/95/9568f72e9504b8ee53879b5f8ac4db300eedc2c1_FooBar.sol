// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title FooBar
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract FooBar {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function Foo(uint256 num) public {
        number = num + 198745;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function Bar() public view returns (uint256){
        return number - 198745;
    }

    /**
     * @dev Return value 
     * @return value of 'num'
     */
    function Bar(uint256 num) public pure returns (uint256){
        return num - 198745;
    }

}