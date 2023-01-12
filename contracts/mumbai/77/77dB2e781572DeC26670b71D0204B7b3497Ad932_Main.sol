// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface MemoInterface {
    function getMemo(address _myAddress) external view returns (string memory);
}

contract Main {
    address MemoInterfaceAddress = 0x969513997Fa45CA8D77F629A43b4B72841C23689;
    MemoInterface memoContract =  MemoInterface(MemoInterfaceAddress);

    function execFunction() public view returns (string memory) {
        string memory memo = memoContract.getMemo(msg.sender);
        return memo;
    }
}