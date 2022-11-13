// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

contract ArrayTestContract {
    mapping(uint256 => bytes) random_data;

    uint256 public counter = 0;

    constructor() public {
        bytes
            memory random208Bytes = hex"c0601d3fc126ee00e5ce9a4d9dc5a2be9b0da6c043159809b69d1052fe0dfa292739fcbd471885a829ce79f255ea0067fa4d3f563c47406185bb142934afdc3c2566e3407a43df01d4dcd5d5f6b1c812197db1260163a0fddf3ffe2988f3577e77880e04755440dec04f80b62b48f8f414dedd8ed5a1207e9e8b1175a69d204d50d1fa60fa298e74fa63577071baa55b34ed5c95c110858e5b657060071db22971a70498f16beb543a6c629c4cb34d4ee056e2139a3dc703f62b026b3782816033b0ba247a2ab8fd31a9c7f3823b4509";

        for (uint256 i = 0; i < 100; i++) {
            random_data[i] = random208Bytes;
        }
    }

    function addData(bytes calldata randomData) external {
        require(
            randomData.length == (48 + 32 + 96 + 32),
            "Data not encoded properly"
        );
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