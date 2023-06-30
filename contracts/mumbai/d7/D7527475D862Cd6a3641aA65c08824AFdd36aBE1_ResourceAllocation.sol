/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract ResourceAllocation {
    uint constant MIN_MERGE = 32;

    uint[] public arr;
    uint[] public tempArray;

    mapping(address => uint) public _userbids;
    mapping(uint => address[]) public bids;
    mapping(uint => address) public _userposition;
    mapping(uint => uint) private bidAmountCounter;
    uint public queueCounter = 0;
    address address1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address address2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address address3 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address address4 = 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678;

    constructor() {}

    function getArr() public view returns (uint[] memory) {
        return arr;
    }

    function getTempArray() public view returns (uint[] memory) {
        return tempArray;
    }

    function test() external {
        insertBid(address1, 10);
        insertBid(address2, 31);
        insertBid(address3, 3);
        insertBid(address4, 10);
        prepareArray();
    }

    function prepareArray() public {
        insertArray(0, true);
        for (uint i = 0; i < 4; i++) {
            insertArray(_userbids[_userposition[i]], false);
        }
        tempArray = new uint[](arr.length);
    }

    function insertBid(address _address, uint _bidamount) public {
        uint counter = bidAmountCounter[_bidamount];
        counter++;
        bidAmountCounter[_bidamount] = counter;

        bids[_bidamount].push(_address);
        _userbids[_address] = _bidamount;
        _userposition[queueCounter++] = _address;
    }

    function getAddressCountForBid(uint _bidamount) public view returns (uint) {
        return bidAmountCounter[_bidamount];
    }

    function getAddressForBid(uint _bidamount, uint position) public view returns (address) {
        uint count = bidAmountCounter[_bidamount];
        require(position <= count, "Position does not exist");
        return bids[_bidamount][position];
    }

    function insertArray(uint _value, bool restart) private {
        // Empty the current array
        if (restart) {
            delete arr;
            delete tempArray;
        }
        arr.push(_value);
    }

    function sort() public returns (uint[] memory) {
        uint arraySize = arr.length;
        for (uint i = 0; i < arraySize; i += MIN_MERGE) {
            insertionSort(i, min(i + MIN_MERGE - 1, arraySize - 1));
        }

        uint size = MIN_MERGE;
        while (size < arraySize)
        {   
            for (uint left = 0; left < arraySize; left += 2 * size)
            {
                uint mid = left + size - 1;
                uint right = min((left + 2 * size - 1), (arraySize - 1));
                merge(left, mid, right);
            }
            size = 2 * size;
        }

        return arr;
    }

    function insertionSort(uint left, uint right) public {
        for (uint i = left + 1; i <= right; i++) {
            uint temp = arr[i];
            uint j = i - 1;
            // Add a check to prevent underflow.
            while (j >= left && arr[j] < temp) {
                arr[j + 1] = arr[j];
                if (j == 0) {
                    break;
                }
                j--;
            }
            arr[j + 1] = temp;
        }
    }



    function merge(uint left, uint mid, uint right) public {
        uint leftEnd = mid;
        uint rightStart = mid + 1;
        uint tempIndex = left;
        uint numElements = right - left + 1;

        while (left <= leftEnd && rightStart <= right) {
            if (arr[left] >= arr[rightStart]) {
                tempArray[tempIndex++] = arr[left++];
            } else {
                tempArray[tempIndex++] = arr[rightStart++];
            }
        }

        while (left <= leftEnd) {
            tempArray[tempIndex++] = arr[left++];
        }

        while (rightStart <= right) {
            tempArray[tempIndex++] = arr[rightStart++];
        }

        for (uint i = 0; i < numElements; i++)
        {
            arr[right] = tempArray[right];
            if(right == 0){
                break;
            }
            right--;
        }
    }

    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}