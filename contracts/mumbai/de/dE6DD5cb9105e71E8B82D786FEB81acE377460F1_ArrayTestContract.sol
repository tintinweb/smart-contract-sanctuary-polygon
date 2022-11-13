// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

contract ArrayTestContract {
    mapping(uint256 => bytes) random_data;

    uint256 public counter = 0;

    function tokensReceived(bytes calldata randomData) external {
        random_data[counter] = randomData;
        counter += 1;
    }

    function getRandomData()
        public
        view
        returns (bytes[] memory returnedArray)
    {
        returnedArray = new bytes[](counter);
        for (uint256 i = 0; i < counter; i++) returnedArray[i] = random_data[i];
    }

    function getRandomDataByIndex(uint256 index)
        public
        view
        returns (bytes memory)
    {
        return random_data[index];
    }
}