// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

contract TestContract  {
    uint256 firstNum = 0;

    mapping(uint256 => uint256) private _firstMapping;
    mapping(uint256 => uint256) private _secondMapping;

    event FirstNumCreated(uint256 indexed testId, uint256 testNumber);
    event SecondNumCreated(uint256 indexed testId, uint256 testNumber);

    constructor() { }

    struct TestFunctionTwoParams {
        uint256 testId;
        uint256 testNumber;
    }

   function testFunctionOne(
        uint256 testNumber
    ) external returns (bool) {
        firstNum = testNumber;
        return true;
    }


    function testFunctionTwo(
        TestFunctionTwoParams memory params
    ) external returns (uint256) {
        _firstMapping[params.testId] = params.testNumber;

        emit FirstNumCreated({
            testId: params.testId,
            testNumber: params.testNumber
        });

        return params.testNumber;
    }

    function testFunctionThree(
        uint256 testId,
        uint256 testNumber
    ) external returns (uint256) {
        _secondMapping[testId] = testNumber;

        emit SecondNumCreated({
            testId: testId,
            testNumber: testNumber
        });

        return testNumber;
    }

  function getFunctionTwo(
        uint256 testId
    ) public view returns (uint256) {
        return _firstMapping[testId];
    }

  function getFunctionThree(
        uint256 testId
    ) public view returns (uint256) {
        return _secondMapping[testId];
    }
}