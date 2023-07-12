/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImageUpload {
    struct Image {
        bytes32 hash;
        uint256 timestamp;
        address uploader;
    }

    mapping(bytes32 => Image) private images;

    event ImageUploaded(bytes32 indexed imageHash, uint256 timestamp, address indexed uploader);

    function uploadImage(bytes32 _imageHash) public {
        require(images[_imageHash].hash == bytes32(0), "Image already uploaded");
        
        images[_imageHash] = Image(_imageHash, block.timestamp, msg.sender);
        emit ImageUploaded(_imageHash, block.timestamp, msg.sender);
    }

    function getImageMetadata(bytes32 _imageHash) public view returns (bytes32, uint256, address) {
        Image memory image = images[_imageHash];
        require(image.hash != bytes32(0), "Image not found");
        
        return (image.hash, image.timestamp, image.uploader);
    }
}