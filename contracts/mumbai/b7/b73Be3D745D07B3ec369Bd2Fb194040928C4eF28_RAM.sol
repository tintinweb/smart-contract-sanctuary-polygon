//SPDX-License-Identifier:MIT

pragma solidity 0.8.3;

contract RAM {
    string public name;
    uint256 public imageCount = 0;
    mapping(uint256 => Image) public images;

    struct Image {
        uint256 id;
        string hash;
        string description;
        address author;
        // uint256 tipAmount;
        // address payable author;
    }

    event ImageCreated(
        uint256 id,
        string hash,
        string description,
        address author
        // uint256 tipAmount,
        // address payable author
    );

    // event ImageTipped(
    //     uint256 id,
    //     string hash,
    //     string description,
    //     uint256 tipAmount,
    //     address payable author
    // );

    constructor() {
        name = "Random Access Memories";
    }

    //uploadImage() takes the IPFS-hash plus a string as description and store it in a struct
    function uploadImage(string memory _imgHash, string memory _description)
        public
    {
        // Make sure the image hash exists
        require(bytes(_imgHash).length > 0, "Must have HASH");
        // Make sure image description exists
        require(bytes(_description).length > 0, "Must have DESCRIPTION");
        // Make sure uploader address exists
        require(msg.sender != address(0), "Must have AUTHOR");

        // Increment image id
        imageCount++;

        // Add Image to the contract
        images[imageCount] = Image(
            imageCount,
            _imgHash,
            _description,
            msg.sender
            // 0,
            // msg.sender
        );
        // Trigger an event
        // emit ImageCreated(imageCount, _imgHash, _description, 0, msg.sender);
        emit ImageCreated(imageCount, _imgHash, _description, msg.sender);

    }

    // function tipImageOwner(uint256 _id) public payable {
    //     // Make sure the id is valid
    //     require(_id > 0 && _id <= imageCount, "NOT EXISTING IMAGE");
    //     // Fetch the image
    //     Image memory _image = images[_id];
    //     // Fetch the author
    //     address payable _author = _image.author;
    //     // Pay the author by sending them Ether
    //     payable(address(_author)).transfer(msg.value);
    //     // Increment the tip amount
    //     _image.tipAmount = _image.tipAmount + msg.value;
    //     // Update the image
    //     images[_id] = _image;
    //     // Trigger an event
    //     emit ImageTipped(
    //         _id,
    //         _image.hash,
    //         _image.description,
    //         _image.tipAmount,
    //         _author
    //     );
    // }
}