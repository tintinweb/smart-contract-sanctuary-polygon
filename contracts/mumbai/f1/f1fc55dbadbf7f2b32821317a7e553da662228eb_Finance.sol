/**
 *Submitted for verification at polygonscan.com on 2022-03-19
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Finance {

    uint256 number;
    function profit(uint revenue, uint expenditure) public {
        number = revenue - expenditure;
    }
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}