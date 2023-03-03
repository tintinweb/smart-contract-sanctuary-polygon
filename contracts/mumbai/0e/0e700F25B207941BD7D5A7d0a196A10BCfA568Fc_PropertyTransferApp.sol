// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract PropertyTransferApp {

    address public contractOwner;

    constructor() public {

        contractOwner = msg.sender;

    }

    modifier onlyOwner() {

        require(msg.sender == contractOwner);

        _;

    }

    struct Property {

        uint256 id;

        string name;

        string owner;

        uint256 value;

        uint256 area;

    }

    //mapping(key => value) mapping name;

    //1 => (23456, villa, alice, 8000, 1250);

    //2 => (same details);

    mapping(uint256 => Property) public properties;

    function addProperty(

        uint256 _propertyid,

        string memory _name,

        string memory _owner,

        uint256 _value,

        uint256 _area

    ) public onlyOwner {

        properties[_propertyid].name = _name;

        properties[_propertyid].owner = _owner;

        properties[_propertyid].value = _value;

        properties[_propertyid].area = _area;

    }
function queryPropertyById(uint256 _propertyid)

        public view returns (

            string memory name,

            string memory owner,

            uint256 area,

            uint256 value

        )

    {

        return (

            properties[_propertyid].name,

            properties[_propertyid].owner,

            properties[_propertyid].area,

            properties[_propertyid].value

        );

    }

    function transferPropertyOwnership(

        uint256 _propertyid,

        string memory _newOwner) public {

        properties[_propertyid].owner = _newOwner;

    }

}