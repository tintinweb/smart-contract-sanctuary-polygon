/**
 *Submitted for verification at polygonscan.com on 2022-11-03
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IObservabilityEvents {
    /// > [[[[[[[[[[[ Factory events ]]]]]]]]]]]

    event CloneDeployed(
        address indexed factory,
        address indexed owner,
        address indexed clone
    );

    event FactoryImplementationSet(
        address indexed factory,
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /// > [[[[[[[[[[[ Clone events ]]]]]]]]]]]

    event ContentSet(
        address indexed clone,
        uint256 indexed contentId,
        string content,
        address indexed owner
    );

    event ContentRemoved(address indexed clone, uint256 indexed contentId);

    event PlatformMetadataSet(address indexed clone, string metadata);

    event RoleSet(
        address indexed clone,
        address indexed account,
        uint8 indexed role
    );
}

interface IObservability {
    function emitDeploymentEvent(address owner, address clone) external;

    function emitFactoryImplementationSet(
        address oldImplementation,
        address newImplementation
    ) external;

    function emitContentSet(
        uint256 contentId,
        string calldata content,
        address owner
    ) external;

    function emitContentRemoved(uint256 contentId) external;

    function emitPlatformMetadataSet(string calldata metadata) external;

    function emitRoleSet(address account, uint8 role) external;
}

contract Observability is IObservability, IObservabilityEvents {
    /// > [[[[[[[[[[[ Factory functions ]]]]]]]]]]]

    function emitDeploymentEvent(address owner, address clone)
        external
        override
    {
        emit CloneDeployed(msg.sender, owner, clone);
    }

    function emitFactoryImplementationSet(
        address oldImplementation,
        address newImplementation
    ) external override {
        emit FactoryImplementationSet(
            msg.sender,
            oldImplementation,
            newImplementation
        );
    }

    /// > [[[[[[[[[[[ Clone functions ]]]]]]]]]]]

    function emitContentSet(
        uint256 contentId,
        string calldata content,
        address owner
    ) external override {
        emit ContentSet(msg.sender, contentId, content, owner);
    }

    function emitContentRemoved(uint256 contentId) external override {
        emit ContentRemoved(msg.sender, contentId);
    }

    function emitPlatformMetadataSet(string calldata metadata)
        external
        override
    {
        emit PlatformMetadataSet(msg.sender, metadata);
    }

    function emitRoleSet(address account, uint8 role) external override {
        emit RoleSet(msg.sender, account, role);
    }
}