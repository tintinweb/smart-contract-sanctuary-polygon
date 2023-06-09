/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

/** 
 *  SourceUnit: /home/nuelgeek/codegeek/Web3 Solidity Developer Task/contracts/CappedSet.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.9;

contract CappedSet {

    // Represents an element in the capped set.
    // It stores the value and index of the element.
    struct Element {
        uint256 value;
        uint256 index;
    }
    
    // Each element is associated with an address and contains the value and index of the element
    mapping(address => Element) private elements;
    address[] private elementAddresses;
    uint256 public maxSize;
    uint256 public lowestValue;
    uint256 private lowestValueAddressIndex;

    constructor(uint256 _maxSize) {
        require(_maxSize > 0, "Max size must be greater than 0");
        maxSize = _maxSize;
    }

    /**
        Inserts a new address-value pair into the capped set.

        @param addr The address to insert.

        @param value The corresponding value to insert.

        @return The address and value of the inserted element or the current lowest value element.

        @dev The function enforces the requirement that the address is not the zero address and the value is greater than zero.

        If it is the first value inserted, it initializes the capped set and returns the default values.

        If the set is not full, it adds the element and updates the lowest value if necessary.

        If the set is full, it replaces the lowest value element with the new element and updates the lowest value.

        It then rechecks the lowest value among the remaining elements and returns the appropriate address-value pair.
    */

    function insert(address addr, uint256 value) external returns (address, uint256) {
        require(addr != address(0), "Invalid address");
        require(value > 0, "Value must be greater than 0");

        // If this the first value insterted
        if (elementAddresses.length == 0) {
            elementAddresses.push(addr);
            elements[addr].value = value;
            elements[addr].index = 0;
            lowestValue = value;
            lowestValueAddressIndex = elements[addr].index;
            return (address(0), 0);
        }

        if (elementAddresses.length < maxSize) {
            elementAddresses.push(addr);
            elements[addr].value = value;
            elements[addr].index = elementAddresses.length - 1;

            if (value < lowestValue) {
                lowestValue = value;
                lowestValueAddressIndex = elements[addr].index;
                return (addr, value);
            }else {
                return (elementAddresses[lowestValueAddressIndex], lowestValue);
            }     
        }

        if (value == lowestValue) {
            return (elementAddresses[lowestValueAddressIndex], lowestValue);
        }
   
        address evictedAddress = elementAddresses[lowestValueAddressIndex];
        uint256 currentLowest = elements[evictedAddress].value;

        // Retained the container of the current lowest elements(value and address) and replaced the value with the new element. 
        elementAddresses[lowestValueAddressIndex] = addr;
        elements[addr].value = value;
        elements[addr].index = lowestValueAddressIndex;
        lowestValue = value;
        
        if (value < currentLowest) {
            lowestValueAddressIndex = elements[addr].index;
            return (addr, value);
        }else{
            for (uint256 i = 0; i < elementAddresses.length; i++) {
                address currentAddress = elementAddresses[i];
                if (elements[currentAddress].value < lowestValue) {
                    lowestValue = elements[currentAddress].value;
                    lowestValueAddressIndex = elements[currentAddress].index;
               }
                    
            }
        }
        
        return (elementAddresses[lowestValueAddressIndex], lowestValue);
    }

    /**
        Updates the value of an existing element in the capped set.

        @param addr The address of the element to update.

        @param newValue The new value to assign to the element.

        @return The address and value of the updated element or the current lowest value element.

        @dev The function enforces the requirement that the address is not the zero address, exists in the set,

        and the new value is greater than zero and different from the current value.

        It updates the value of the element and checks if the lowest value needs to be updated.

        If the new value is lower than the current lowest value, it updates the lowest value and address.

        Otherwise, it finds the new lowest value among the remaining elements and returns the appropriate address-value pair.
    */

    function update(address addr, uint256 newValue) external returns (address, uint256) {
        require(addr != address(0), "Invalid address");
        require(newValue > 0, "Value must be greater than 0");
        require(addr == elementAddresses[elements[addr].index], "Address doesn't exist, use insert function");
        require(newValue != elements[addr].value, "You can't update the value with the same value");

        elements[addr].value = newValue;

        if (newValue < lowestValue) {
            lowestValueAddressIndex = elements[addr].index;
            lowestValue = newValue;
            return (addr, newValue);
        }else{
            (lowestValue, lowestValueAddressIndex) = findLowestValue();
        }

        return (elementAddresses[lowestValueAddressIndex], lowestValue);
    }

    /**
        Removes an existing element from the capped set.

        @param addr The address of the element to remove.

        @return The address and value of the removed element or the current lowest value element.

        @dev The function enforces the requirement that the address is not the zero address, the set is not empty,

        and the address exists in the set.

        If there is only one element in the set, it removes the element, updates the lowest value and address to zero,

        and returns the appropriate address-value pair.

        Otherwise, it removes the element by swapping it with the last element, updates the corresponding mappings,

        and checks if the lowest value needs to be updated.

        If the value of the removed element was the lowest value, it finds the new lowest value among the remaining elements.

        If the value of the last element was the lowest value, it updates the lowest value address index accordingly.

        Finally, it returns the address-value pair of the current lowest value element.
    */

    function remove(address addr) external returns (address, uint256) {
        require(addr != address(0), "Invalid address");
        require(elementAddresses.length > 0, "Set is empty");
        require(elementAddresses[elements[addr].index] == addr, "Address doesn't exist");

        if( elementAddresses.length == 1){
            delete elements[addr];
            elementAddresses.pop();
            lowestValueAddressIndex = 0;
            lowestValue = 0;
            return (address(0), 0);
        }
        
        uint256 indexToRemove = elements[addr].index;
        uint256 valueOfIndexToRemove = elements[addr].value;
        address lastAddress = elementAddresses[elementAddresses.length - 1];

        if (indexToRemove == elementAddresses.length - 1){
            elementAddresses.pop();
            delete elements[addr];
    
        }else{

            elements[lastAddress].index = indexToRemove;
            elementAddresses[indexToRemove] = lastAddress;
            elementAddresses.pop();

            delete elements[addr];
        }


        if (valueOfIndexToRemove == lowestValue) {
            (lowestValue, lowestValueAddressIndex) = findLowestValue();
        } else if (elements[lastAddress].value == lowestValue) {
            lowestValueAddressIndex = indexToRemove;
        }

        return (elementAddresses[lowestValueAddressIndex], lowestValue);
    }


     /**

        Retrieves the value of an element in the capped set.

        @param addr The address of the element.

        @return The value of the element.

        @dev The function enforces the requirement that the address is not the zero address,
        
        the set is not empty, and the address exists in the set.

        It returns the value of the element associated with the given address.
    */

    function getValue(address addr) external view returns (uint256) {
        require(addr != address(0), "Invalid address");
        require(elementAddresses.length > 0, "Set is empty");
        require(addr == elementAddresses[elements[addr].index], "Address doesn't exist");
        return elements[addr].value;
    }

    /**
        Finds the lowest value among the elements in the capped set.

        @return The lowest value and its corresponding index in the element addresses array.

        @dev The function iterates through the element addresses array to find the lowest value.

        It initializes the lowest with the maximum possible value and compares it with each element's value.

        If a lower value is found, it updates the lowest value and its index.

        Finally, it returns the lowest value and its index.
    */

    function findLowestValue() public  view returns (uint256, uint256) {
        uint256 lowest = lowestValue;
        uint256 lowestIndex = lowestValueAddressIndex;

        for (uint256 i = 0; i < elementAddresses.length; i++) {
            lowest = type(uint256).max; // Initialize lowest with the maximum possible value
            address currentAddress = elementAddresses[i];
            uint256 currentValue = elements[currentAddress].value;
            if (currentValue < lowest) {
                lowest = currentValue;
                lowestIndex = i;
            }
        }

        return (lowest, lowestIndex);
    }


}