// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './base64.sol';
import './Utils.sol';

/// @title Beeholder GeNFTs
/// @author espina (modified from Miguel Piedrafita's SoulMinter)
/// @notice contract to mint Soulbound NFTs

contract Beeholder{
    /// @notice Thrown when trying to transfer a Soulbound token
    error Soulbound();

    /// @notice Emitted when minting a Soulbound NFT
    /// @param from Who the token comes from. Will always be address(0)
    /// @param to The token recipient
    /// @param id The ID of the minted token
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    /// @notice The symbol for the token
    string public constant symbol = "BEE";

    /// @notice The name for the token
    string public constant name = "Beeholder";

    /// @notice The owner of this contract (set to the deployer)
    address public immutable owner = msg.sender;
    address public admin = msg.sender;


    /// @notice Get the owner of a certain tokenID
    mapping(uint256 => address) public ownerOf;

    /// @notice Get how many NFTs a certain user owns
    mapping(address => uint256) public balanceOf;

    /// @notice Get the base of ipfs URL for generative script
    string public baseAnimURL;

    /// @notice Get the base of ipfs URL for image directory
    string internal ipfsBaseURL;

    /// @dev Counter for the next tokenID, defaults to 1 for better gas on first mint
    uint256 internal nextTokenId = 1;

    constructor() payable {}

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function approve(address, uint256) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function isApprovedForAll(address, address) public pure {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function getApproved(uint256) public pure {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function setApprovalForAll(address, bool) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function transferFrom(
        address,
        address,
        uint256
    ) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual {
        revert Soulbound();
    }

    /// @notice This function was disabled to make the token Soulbound. Calling it will revert
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual {
        revert Soulbound();
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }


    /// @dev Returns an URI for a given token ID
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(ownerOf[_tokenId] != address(0), 'Token does not exist');
        return _metadata(_tokenId);
    }

    /// @dev Returns metadata as a json
    function _metadata(uint256 _tokenId) internal view returns (string memory) {
        string memory tokenName = string(abi.encodePacked('Beeholder #', utils.uint2str(_tokenId)));
        string memory tokenDescription = "BeeDAO is a web3 organization run by bees and humans. Its aim is to secure and improve the well-being of bees worldwide. Beeholder GeNFTs are soulbound tokens representing membership in the BeeDAO. These Generative NFTs transform throughout the year following the lifecycle of a bee colony.";
        string memory scriptURL = string(abi.encodePacked(baseAnimURL, "?tokenId=", utils.uint2str(_tokenId)));
        string memory imageURL = string(abi.encodePacked(ipfsBaseURL, utils.uint2str(_tokenId)));

        string memory json = string(
            abi.encodePacked('{"name":"', tokenName,
            '","description":"', tokenDescription, 
            '","image":"', imageURL,
            '","animation_url":"', scriptURL,  '"}')
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @notice Airdrop NFTs to an array of addresses
    /// @param _recipients The recipients of the NFTs
    function airdrop(address[] calldata _recipients) public {
        require(msg.sender == admin, 'Not allowed to airdop');

        for (uint i = 0; i< _recipients.length; i++){            
            unchecked {
                balanceOf[_recipients[i]]++;
            }
            ownerOf[nextTokenId] = _recipients[i];
            emit Transfer(address(0), _recipients[i], nextTokenId++);
        }
    }

    /// @notice Change the admin of the contract
    /// @param _newAdmin The admin that permission will be transferred to
    function changeAdmin(address _newAdmin) public {
        require(msg.sender == admin, 'Only admin can change');
        admin = _newAdmin;
    }

    /// @notice Change the base URL for generative script
    /// @param _newAnimURL The new base of the ipfs URL for dynamic script
    function changeAnimURL(string calldata _newAnimURL) public {
        require(msg.sender == admin, 'Only admin can change');
        baseAnimURL = _newAnimURL;
    }

    /// @notice Change the base URL for images
    /// @param _newIpfsURL The new base of the ipfs URL for image directory
    function changeIpfsBaseURL(string calldata _newIpfsURL) public {
        require(msg.sender == admin, 'Only admin can change');
        ipfsBaseURL = _newIpfsURL;
    }

    function burn(uint256 _tokenId) public {
        require(msg.sender == ownerOf[_tokenId], 'Only owner can burn');
        balanceOf[msg.sender] = 0;
        ownerOf[_tokenId] = address(0);
        emit Transfer(msg.sender, address(0), _tokenId);
    }
}