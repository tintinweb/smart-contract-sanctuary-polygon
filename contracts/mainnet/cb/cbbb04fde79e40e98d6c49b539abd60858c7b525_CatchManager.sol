// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CatchManager {
    struct CatchConfig {
        address to;
        string functionSignature;
        string cacheIfEqualTo;
    }

    CatchConfig[] public catchConfigs;

    function pushCatchConfig(
        address _to,
        string memory _functionSignature,
        string memory _cacheIfEqualTo
    ) public {
        catchConfigs.push(
            CatchConfig(_to, _functionSignature, _cacheIfEqualTo)
        );
    }

    function removeCatchConfig(uint index) public {
        require(index < catchConfigs.length, "Index out of bounds");

        for (uint i = index; i < catchConfigs.length - 1; i++) {
            catchConfigs[i] = catchConfigs[i + 1];
        }

        catchConfigs.pop();
    }

    function getAllCatchConfigs()
        public
        view
        returns (address[] memory, string[] memory, string[] memory)
    {
        uint256 length = catchConfigs.length;

        address[] memory tos = new address[](length);
        string[] memory functionSignatures = new string[](length);
        string[] memory cacheIfEqualTos = new string[](length);

        for (uint i = 0; i < length; i++) {
            tos[i] = catchConfigs[i].to;
            functionSignatures[i] = catchConfigs[i].functionSignature;
            cacheIfEqualTos[i] = catchConfigs[i].cacheIfEqualTo;
        }

        return (tos, functionSignatures, cacheIfEqualTos);
    }
}