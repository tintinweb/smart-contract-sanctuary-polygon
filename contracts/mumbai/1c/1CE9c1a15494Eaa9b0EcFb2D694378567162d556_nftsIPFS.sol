// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract nftsIPFS {
    address payable contractOwner =
        payable(0x61EC33EcC7eD11b52327Aa065BC43aAF9A0A36Ff);
    uint256 public listingPrice = 0.025 ether;

    struct NFTs {
        string title;
        string description;
        string email;
        string category;
        uint256 fundraised;
        address creator;
        string image;
        uint256 timestamp;
        uint256 id;
    }

    mapping(uint256 => NFTs) public nftImages;

    uint256 public imagesCount = 0;

    function uploadIPFS(
        address _creator,
        string memory _image,
        string memory _title,
        string memory _description,
        string memory _email,
        string memory _category
    )
        public
        returns (
            string memory,
            string memory,
            string memory,
            address,
            string memory
        )
    {
        imagesCount++;
        NFTs storage nft = nftImages[imagesCount];
        nft.title = _title;
        nft.creator = _creator;
        nft.description = _description;
        nft.email = _email;
        nft.category = _category;
        nft.image = _image;
        nft.timestamp = block.timestamp;
        nft.id = imagesCount;
        return (_title, _description, _category, _creator, _image);
    }

    function getAllNFTs() public view returns (NFTs[] memory) {
        uint256 itemCount = imagesCount;

        NFTs[] memory items = new NFTs[](itemCount);

        for (uint256 i = 1; i <= itemCount; i++) {
            NFTs storage currentItem = nftImages[i];
            items[i - 1] = currentItem;
        }

        return items;
    }

    function getImage(
        uint256 id
    )
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            address,
            string memory,
            uint256,
            uint256
        )
    {
        NFTs memory nfts = nftImages[id];
        return (
            nfts.title,
            nfts.description,
            nfts.email,
            nfts.category,
            nfts.fundraised,
            nfts.creator,
            nfts.image,
            nfts.timestamp,
            nfts.id
        );
    }

    // Update listing price
    function updateListingPrice(
        uint256 _listingPrice,
        address owner
    ) public payable {
        require(contractOwner == owner, "Only contract owner can update!");
        listingPrice = _listingPrice;
    }

    // Donate

    function donateToImage(uint256 _id) public payable {
        uint256 amount = msg.value;
        NFTs storage nft = nftImages[_id];

        (bool sent, ) = payable(nft.creator).call{value: amount}("");

        if (sent) {
            nft.fundraised = nft.fundraised + amount;
        }
    }

    function withdraw (address _owner) external {
        require( _owner == contractOwner, "Only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "Not enough funds!");

        contractOwner.transfer(balance);   
    }
}