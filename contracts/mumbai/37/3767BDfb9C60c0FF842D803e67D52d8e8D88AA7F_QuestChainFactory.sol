// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IQuestChainFactory.sol";
import "./interfaces/IQuestChain.sol";

contract QuestChainFactory is IQuestChainFactory {
    uint256 public questChainCount = 0;
    mapping(uint256 => address) internal _questChains;

    event NewQuestChain(uint256 indexed index, address questChain);

    address public immutable implementation;

    constructor(address _implementation) {
        require(_implementation != address(0), "invalid implementation");
        implementation = _implementation;
    }

    function _newQuestChain(
        address _questChainAddress,
        string calldata _details
    ) internal {
        IQuestChain(_questChainAddress).init(msg.sender, _details);

        _questChains[questChainCount] = _questChainAddress;
        emit NewQuestChain(questChainCount, _questChainAddress);

        questChainCount++;
    }

    function _newQuestChainWithRoles(
        address _questChainAddress,
        string calldata _details,
        address[] calldata _editors,
        address[] calldata _reviewers
    ) internal {
        IQuestChain(_questChainAddress).initWithRoles(
            msg.sender,
            _details,
            _editors,
            _reviewers
        );

        _questChains[questChainCount] = _questChainAddress;
        emit NewQuestChain(questChainCount, _questChainAddress);

        questChainCount++;
    }

    function create(string calldata _details)
        external
        override
        returns (address)
    {
        address questChainAddress = Clones.clone(implementation);

        _newQuestChain(questChainAddress, _details);

        return questChainAddress;
    }

    function createWithRoles(
        string calldata _details,
        address[] calldata _editors,
        address[] calldata _reviewers
    ) external override returns (address) {
        address questChainAddress = Clones.clone(implementation);

        _newQuestChainWithRoles(
            questChainAddress,
            _details,
            _editors,
            _reviewers
        );

        return questChainAddress;
    }

    function predictDeterministicAddress(bytes32 _salt)
        external
        view
        override
        returns (address)
    {
        return Clones.predictDeterministicAddress(implementation, _salt);
    }

    function createDeterministic(string calldata _details, bytes32 _salt)
        external
        override
        returns (address)
    {
        address questChainAddress = Clones.cloneDeterministic(
            implementation,
            _salt
        );

        _newQuestChain(questChainAddress, _details);

        return questChainAddress;
    }

    function getQuestChainAddress(uint256 _index)
        public
        view
        returns (address)
    {
        return _questChains[_index];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IQuestChainFactory {
    function create(string calldata _details) external returns (address);

    function createWithRoles(
        string calldata _details,
        address[] calldata _editors,
        address[] calldata _reviewers
    ) external returns (address);

    function createDeterministic(string calldata _details, bytes32 _salt)
        external
        returns (address);

    function predictDeterministicAddress(bytes32 _salt)
        external
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IQuestChain {
    enum Status {
        init,
        review,
        pass,
        fail
    }

    function init(address _admin, string calldata _details) external;

    function initWithRoles(
        address _admin,
        string calldata _details,
        address[] calldata _editors,
        address[] calldata _reviewers
    ) external;

    function edit(string calldata _details) external;

    function createQuest(string calldata _details) external;

    function editQuest(uint256 _questId, string calldata _details) external;

    function submitProof(uint256 _questId, string calldata _proof) external;

    function reviewProof(
        address _quester,
        uint256 _questId,
        bool _success,
        string calldata _details
    ) external;

    function getStatus(address _quester, uint256 _questId)
        external
        view
        returns (Status);
}