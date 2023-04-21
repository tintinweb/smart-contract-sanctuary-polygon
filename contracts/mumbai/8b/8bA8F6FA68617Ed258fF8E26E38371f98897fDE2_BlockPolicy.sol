/// SPDX-License-Identifier: MIT

pragma solidity >=0.7.3;

contract BlockPolicy {
    struct Policy {
        string section;
        string startDate;
        string endDate;
        string attribute;
        uint256 price;
        uint256 prize;
        string description;
        string id;

    }

    event idEmitted(string _id);
    mapping(string => Policy) public policies;
    string id;

    constructor() {
    }

    function addPolicy(
        string memory _section,
        string memory _startDate,
        string memory _endDate,
        string memory _attribute,
        uint256 _price,
        uint256 _prize,
        string memory _description,
        string memory _id
    ) public returns (string memory identifier)  {
        policies[_id] = Policy(_section, _startDate, _endDate, _attribute, _price, _prize, _description, _id);
        emit idEmitted(_id);
        return _id;
    }
}