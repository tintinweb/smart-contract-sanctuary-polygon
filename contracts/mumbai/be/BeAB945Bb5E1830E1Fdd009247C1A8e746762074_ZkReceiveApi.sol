// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "../interfaces/IZKHole.sol";

contract ZkReceiveApi {
    IZKHole public zkHole;

    constructor(address zkHoleAddress) {
        zkHole = IZKHole(zkHoleAddress);
    }

    function zkReceiveWithPayload(
        bytes memory proofBlob,
        bytes32[] memory merkleProof
    ) view public returns (bytes memory payload){
        (IZKHole.VM memory vm, bool valid, string memory reason) = zkHole.parseAndVerifyProof(proofBlob, merkleProof);
        require(valid, reason);
        return vm.payload;
    }

    function zkReceiveWithPayload2(
        bytes memory proofBlob,
        bytes32[] memory merkleProof
    ) view public returns (uint16 emitterChainId,
        bytes32 emitterAddress,
        uint64 sequence,
        bytes memory payload,
        bytes32 hash){
        (IZKHole.VM memory vm, bool valid, string memory reason) = zkHole.parseAndVerifyProof(proofBlob, merkleProof);
        require(valid, reason);
        return (vm.emitterChainId, vm.emitterAddress, vm.sequence, vm.payload, vm.hash);
    }


}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../Structs.sol";

interface IZKHole is Structs {
    event LogMessagePublished(
        address indexed sender,
        uint64 sequence,
        bytes payload
    );

    function publishMessage(bytes memory payload)
    external
    payable
    returns (uint64 sequence);

    function parseAndVerifyProof(
        bytes memory proofBlob,
        bytes32[] memory merkleProof
    )
    external
    view
    returns (
        Structs.VM memory vm,
        bool valid,
        string memory reason
    );
}

// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface Structs {
	struct Provider {
		uint16 chainId;
	}

	struct VM {
		uint16 emitterChainId;
		bytes32 emitterAddress;
		uint64 sequence;
		bytes payload;
		bytes32 hash;
	}
}