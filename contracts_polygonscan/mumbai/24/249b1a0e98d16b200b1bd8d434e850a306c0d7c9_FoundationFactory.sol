/**
 *Submitted for verification at polygonscan.com on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.4.23 <0.9.0;

contract Foundation {
    string public name;
    address public _owner;
    int public contractCounter = 0;

    constructor(
        string memory _name,
        address _owner
       
    ) public {
        name = _name;
        _owner = msg.sender;
        contractCounter = contractCounter + 1;
    }

}

pragma solidity >0.4.23 <0.9.0;
contract FoundationFactory {

    Foundation[] private _foundations;
    function createFoundation(
        string memory name,
        int contractID
       
         
    ) public {
        Foundation foundation = new Foundation(
            name,
            msg.sender
        );
        _foundations.push(foundation);
    }
    function allFoundations(uint256 limit, uint256 offset)
        public
        view
        returns (Foundation[] memory coll)
    {
        return coll;
    }
}