/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract UploadImage {

    event NewImageUploaded(
        bytes32 imageID,
        address creatorAddress,
        uint256 imageTimestamp,
        string imageDataCID
    );

    event NewLike(bytes32 imageID, address userAddress);

    struct UploadNewImage {
        bytes32 imageId;
        string imageDataCID;
        address imageOwner;
        uint256 imageTimestamp;
        address[] numberOfLikes;
    }

    mapping(bytes32 => UploadNewImage) public idToImage;

    function createNewImage(
        uint256 imageTimestamp,
        string calldata imageDataCID
    ) external {
        bytes32 imageId = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                imageTimestamp
            )
        );

        address[] memory numberOfLikes;

        idToImage[imageId] = UploadNewImage(
            imageId,
            imageDataCID,
            msg.sender,
            imageTimestamp,
            numberOfLikes
        );

        emit NewImageUploaded(
            imageId,
            msg.sender,
            imageTimestamp,
            imageDataCID
        );
    }

    function likeImage(bytes32 imageId) external{
            UploadNewImage storage myImage = idToImage[imageId];

          for (uint8 i = 0; i < myImage.numberOfLikes.length; i++) {
            require(myImage.numberOfLikes[i] != msg.sender, "ALREADY LIKED IMAGE");
        }

        myImage.numberOfLikes.push(msg.sender);

        emit NewLike(imageId, msg.sender);

    }
}