/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// File: ClaimNFT.sol


pragma solidity 0.8.9;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

contract ClaimNFT {

    event RegistrationERC721(address indexed from, address indexed to, uint256 indexed tokenId, address contractAddress);
    event ERC721Claim(address indexed to, uint256 indexed tokenId, address contractAddress);
    event RegistrationERC1155(address indexed from, uint256 indexed tokenId, uint256 indexed supply, address contractAddress);
    event ERC1155Claim(address indexed to, uint256 indexed tokenId, uint256 indexed supply, address contractAddress);

    constructor() {}


    struct RegisterERC1155 {
        address contractAddress;
        address owner;
        uint256 tokenId;
        uint256 supply;
    }

    struct RegisterERC721 {
        address contractAddress;
        address owner;
        address to;
        uint256 tokenId;
        bool status;
    }

    mapping(string => RegisterERC721) public registrationRecordERC721;
    mapping(string => RegisterERC1155) public registrationRecordERC1155;
    mapping(string => mapping(address => bool)) public isClaimed;
    mapping(string => uint256) public totalERC1155Claimed;


    function registerERC721(string memory _sessionId, address _contractAddress, uint256 _tokenId, address _owner, address _to) external {
        require(registrationRecordERC721[_sessionId].contractAddress == address(0), "Session already exist!");
        require(IERC721(_contractAddress).ownerOf(_tokenId) == msg.sender, "Claim: ERC721, The provided address is not the owner");
        RegisterERC721 memory data = RegisterERC721({
            contractAddress: _contractAddress,
            owner: _owner,
            to: _to,
            tokenId: _tokenId,
            status: false
        });

        registrationRecordERC721[_sessionId] = data;
        emit RegistrationERC721(_owner, _to, _tokenId, _contractAddress);
    }

    function registerERC1155(string memory _sessionId, address _contractAddress, uint256 _tokenId, address _owner, uint256 _supply) external {
        require(registrationRecordERC1155[_sessionId].contractAddress == address(0), "Session already exist!");
        require(IERC1155(_contractAddress).balanceOf(_owner, _tokenId) >= _supply, "Claim: ERC1155, Insufficient balance");
        RegisterERC1155 memory data = RegisterERC1155({
            contractAddress: _contractAddress,
            owner: _owner,
            tokenId: _tokenId,
            supply: _supply
        });

        registrationRecordERC1155[_sessionId] = data;
        emit RegistrationERC1155(_owner, _tokenId, _supply, _contractAddress);
    }

    function claimSingleERC721(string memory _sessionId) public {
        RegisterERC721 memory data = registrationRecordERC721[_sessionId];
        require(msg.sender == data.to, "Address not reserved!");
        require(data.status == false, "Session expired!");
        data.status = true;
        registrationRecordERC721[_sessionId] = data;
        IERC721 contract721 = IERC721(data.contractAddress);
        contract721.safeTransferFrom(data.owner, data.to, data.tokenId);
        emit ERC721Claim(data.to, data.tokenId, data.contractAddress);
    }

    function claimSingleERC1155(string memory _sessionId) public {
        RegisterERC1155 memory data = registrationRecordERC1155[_sessionId];
        require(!isClaimed[_sessionId][msg.sender], "Already claimed!");
        require(totalERC1155Claimed[_sessionId] < data.supply, "All tokens claimed");
        totalERC1155Claimed[_sessionId] += 1;
        isClaimed[_sessionId][msg.sender] = true;
        IERC1155 contract1155 = IERC1155(data.contractAddress);
        contract1155.safeTransferFrom(data.owner, msg.sender, data.tokenId, 1, "0x");
        emit ERC1155Claim(msg.sender, data.tokenId, 1, data.contractAddress);
    }

}