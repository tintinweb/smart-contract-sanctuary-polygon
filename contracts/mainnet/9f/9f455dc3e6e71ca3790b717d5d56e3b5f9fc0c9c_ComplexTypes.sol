/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract ComplexTypes {
    struct StructType {
        uint256 a;
        bool b;
    }

    struct NestedStructType {
        string a;
        StructType b;
    }

    mapping (address => StructType) public addressToStructMapping;
    mapping (address => StructType[]) public addressToStructArrayMapping;
    mapping (address => NestedStructType) public addressToNestedStructMapping;
    mapping (address => NestedStructType[]) public addressToNestedStructArrayMapping;
    mapping (address => mapping (address => StructType[])) public addressToAddressToStructArrayMapping;
    mapping (address => mapping (address => NestedStructType[])) public addressToAddressToNestedStructArrayMapping;

    mapping (address => mapping (address => StructType[3])) public addressToAddressToStructStaticArrayMapping;

    function setAddressToStructMapping(address index, StructType calldata newValue) public {
        addressToStructMapping[index] = newValue;
    }

    function setAddressToStructArrayMapping(address index, StructType[] calldata newValue) public {
        for(uint8 i = 0; i < newValue.length; ++i ) {
            addressToStructArrayMapping[index].push(newValue[i]);
        }
    }

    function setAddressToNestedStructMapping(address index, NestedStructType calldata newValue) public {
        addressToNestedStructMapping[index] = newValue;
    }

    function setAddressToNestedStructArrayMapping(address index, NestedStructType[] calldata newValue) public {
        for(uint8 i = 0; i < newValue.length; ++i ) {
            addressToNestedStructArrayMapping[index].push(newValue[i]);
        }
    }


    function setAddressToAddressToStructArrayMapping(address index1, address index2, StructType[] calldata newValue) public {
        for(uint8 i = 0; i < newValue.length; ++i ) {
            addressToAddressToStructArrayMapping[index1][index2].push(newValue[i]);
        }
    }


    function setAddressToAddressToNestedStructArrayMapping(address index1, address index2, NestedStructType[] calldata newValue) public {
        for(uint8 i = 0; i < newValue.length; ++i ) {
            addressToAddressToNestedStructArrayMapping[index1][index2].push( newValue[i]);
        }
    }

    function setAddressToAddressToStructStaticArrayMapping(address index1, address index2, StructType[3] calldata newValue) public {
        for(uint8 i = 0; i < newValue.length; ++i ) {
            addressToAddressToStructStaticArrayMapping[index1][index2][i] = newValue[i];
        }
    }

}