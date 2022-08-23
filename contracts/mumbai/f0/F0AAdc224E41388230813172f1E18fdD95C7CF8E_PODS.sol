/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// SPDX-License-Identifier: MIT
// $$$$$$$\                  $$\           
// $$  __$$\                 $$ |          
// $$ |  $$ | $$$$$$\   $$$$$$$ | $$$$$$$\ 
// $$$$$$$  |$$  __$$\ $$  __$$ |$$  _____|
// $$  ____/ $$ /  $$ |$$ /  $$ |\$$$$$$\  
// $$ |      $$ |  $$ |$$ |  $$ | \____$$\ 
// $$ |      \$$$$$$  |\$$$$$$$ |$$$$$$$  |
// \__|       \______/  \_______|\_______/ 
                                        
                       
// deployed on Polygon Testnet: 0xF0AAdc224E41388230813172f1E18fdD95C7CF8E
pragma solidity ^0.8.7;

contract PODS {
    event PodCreated(
        bytes32 indexed podId,
        address indexed podOwner,
        address[] podMates,
        bytes32 contentId,
        string contentUri
    );

    struct Pod {
        address owner;
        bytes32 contentId;
        address[] podMates;
    }

    mapping(bytes32 => Pod) podRegistry;

    function createPod(
        string calldata _contentUri,
        address[] calldata _podMates
    ) external {
        address _owner = msg.sender;
        bytes32 _contentId = keccak256(abi.encode(_contentUri));
        bytes32 _podID = keccak256(
            abi.encodePacked(_owner, block.timestamp, _contentId)
        );

        podRegistry[_podID].owner = _owner;
        podRegistry[_podID].contentId = _contentId;
        podRegistry[_podID].podMates = _podMates;
        emit PodCreated(_podID, _owner, _podMates, _contentId, _contentUri);
    }
}