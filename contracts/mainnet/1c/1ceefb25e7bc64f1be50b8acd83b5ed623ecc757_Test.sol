/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Test {
    struct TestData {
        string name;
        bool value;
    }

    event Log(TestData indexed a, TestData[] indexed b, TestData c, TestData[] d);

    TestData testData;
    TestData[] data;
    function store(bool val, string calldata name) public {
        data.push(testData);
        testData.name = name;
        testData.value = val;

        data.push(testData);
        emit Log(testData, data, testData, data);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (bool){
        return testData.value;
    }
}