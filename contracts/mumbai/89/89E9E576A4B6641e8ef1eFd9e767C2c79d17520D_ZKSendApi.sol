// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.0;

import "../interfaces/IZKHole.sol";

contract ZKSendApi {
    IZKHole public zkHole;

    constructor(address zkHoleAddress) {
        zkHole = IZKHole(zkHoleAddress);
    }

    function zkSendWithPayload(bytes memory payload) public payable returns (uint64 sequence){
        sequence = zkHole.publishMessage{value : msg.value}(payload);
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