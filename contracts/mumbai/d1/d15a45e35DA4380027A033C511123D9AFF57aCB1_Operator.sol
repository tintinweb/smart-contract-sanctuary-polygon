// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.11;

import "./Trait.sol";

interface IBaseNFT721 {
    function setRoyalty(address receiver, uint96 fee) external;

    function createCollectible(address creator, string memory tokenURI)
        external
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function changeName(uint256 tokenId, string memory newName) external;

    function mint(
        address _creator,
        string calldata _tokenURI,
        address receiver
    ) external returns (uint256 _tokenId);

    function setStats(uint256 tokenId, Trait.Property[] calldata properties)
        external;

    function addProperty(string memory property) external;
}

contract Operator {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event MinterAdded(address indexed minter);

    event MinterRemoved(address indexed minter);

    event CelebrityAdminAdded(address indexed admin);

    event CelebrityAdminRemoved(address indexed admin);

    event NameChanged(
        address indexed nftaddress,
        uint256 indexed tokenId,
        string name
    );

    address public owner;
    mapping(address => bool) private celebrityAdmin;
    mapping(address => bool) private minters;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyMinters() {
        require(minters[msg.sender], "Minter: caller doesn't have minter Role");
        _;
    }

    function transferOwnership(address newOwner)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function addCelebrityAdmin(address _celebrityAdmin)
        external
        onlyOwner
        returns (bool)
    {
        require(
            !celebrityAdmin[_celebrityAdmin],
            "Celebrity Admin already exist"
        );
        celebrityAdmin[_celebrityAdmin] = true;
        emit CelebrityAdminAdded(_celebrityAdmin);
        return true;
    }

    function removeCelebrityAdmin(address _celebrityAdmin)
        external
        onlyOwner
        returns (bool)
    {
        require(
            celebrityAdmin[_celebrityAdmin],
            "Celebrity Admin does not exist"
        );
        celebrityAdmin[_celebrityAdmin] = false;
        emit CelebrityAdminRemoved(_celebrityAdmin);
        return true;
    }

    function isCelebrityAdmin(address _celebrityAdmin)
        external
        view
        returns (bool)
    {
        return celebrityAdmin[_celebrityAdmin];
    }

    function addMinter(address _minter) external returns (bool) {
        require(
            celebrityAdmin[msg.sender],
            "Only celebrity admin can add minter"
        );
        require(!minters[_minter], "Minter already exist");
        minters[_minter] = true;
        emit MinterAdded(_minter);
        return true;
    }

    function removeMinter(address _minter) external returns (bool) {
        require(
            celebrityAdmin[msg.sender],
            "Only celebrity admin can remove minter"
        );
        require(minters[_minter], "Minter does not exist");
        minters[_minter] = false;
        emit MinterRemoved(_minter);
        return true;
    }

    function mint721(
        address nftAddress,
        address creator,
        string calldata tokenURI,
        address receiver
    ) external onlyMinters returns (bool) {
        IBaseNFT721(nftAddress).mint(creator, tokenURI, receiver);
        return true;
    }

    function batchMint721(
        address nftAddress,
        address creator,
        string[] calldata tokenURIs,
        address[] calldata receivers
    ) external virtual onlyMinters returns (uint256[] memory tokenIds) {
        require(tokenURIs.length > 0, "Mint: invalid length");
        tokenIds = new uint256[](tokenURIs.length);
        for (uint256 i = 0; i < tokenURIs.length; i++) {
            tokenIds[i] = IBaseNFT721(nftAddress).mint(
                creator,
                tokenURIs[i],
                receivers[i]
            );
        }
        return tokenIds;
    }

    function safeTransfer721(
        address nftAddress,
        address from,
        address to,
        uint256 tokenId
    ) external onlyMinters returns (bool) {
        require(
            to != address(0),
            "receiver address should not be zero address"
        );
        IBaseNFT721(nftAddress).safeTransferFrom(from, to, tokenId, "");
        return true;
    }

    function setRoyaltyFee(
        address nftAddress,
        address receiver,
        uint96 royaltyFee
    ) external returns (bool) {
        require(
            celebrityAdmin[msg.sender],
            "Operator: caller doesn't have role"
        );
        IBaseNFT721(nftAddress).setRoyalty(receiver, royaltyFee);
        return true;
    }

    function setNameForToken(
        address nftAddress,
        uint256 tokenId,
        string memory name
    ) external onlyMinters returns (bool) {
        IBaseNFT721(nftAddress).changeName(tokenId, name);
        emit NameChanged(nftAddress, tokenId, name);
        return true;
    }

    function isMinter(address _minter) external view returns (bool) {
        return minters[_minter];
    }

    function setStats(
        address nftAddress,
        uint256 tokenId,
        Trait.Property[] calldata properties
    ) external onlyMinters {
        IBaseNFT721(nftAddress).setStats(tokenId, properties);
    }

    function setProperty(address nftAddress, string memory propertyName)
        external
        onlyMinters
    {
        IBaseNFT721(nftAddress).addProperty(propertyName);
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.11;

library Trait {
    struct Rate {
        uint256 value;
        uint256 max;
    }
    struct Property {
        string name;
        Rate rate;
    }
}