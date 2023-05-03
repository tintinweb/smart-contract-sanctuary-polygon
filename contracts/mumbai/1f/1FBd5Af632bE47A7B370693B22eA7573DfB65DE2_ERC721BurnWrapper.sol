// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract ERC721BurnWrapper {
    /// @dev 0x4c084f14
    error NotOwnerOfToken();
    /// @dev 0x48f5c3ed
    error InvalidCaller();

    // storage
    address public rawFusionHolder;

    event BatchBurn(
        address indexed contractAddress,
        uint256[] tokenIds
    );

    event RawFusionHolderIsSet(address _rawFusionHolder);

    // solhint-disable-next-line no-empty-blocks
    constructor(address _rawFusionHolder) {
        require(_rawFusionHolder != address(0), "Invalid address");
        rawFusionHolder = _rawFusionHolder;
        emit RawFusionHolderIsSet(_rawFusionHolder);
    }

    modifier noZero() {
        if (msg.sender == address(0)) revert InvalidCaller();
        _;
    }

    function setRawFusionHolder(address _rawFusionHolder) external {
        require(_rawFusionHolder != address(0), "Invalid address");
        rawFusionHolder = _rawFusionHolder;
        emit RawFusionHolderIsSet(_rawFusionHolder);
    }

    /// @notice burn multiple token by transferring it to zero address.
    /// @param erc721Contract the address of the nft contract
    /// @param tokenIds the list of tokens that will be transferred
    function safeBatchBurn(
        IERC721 erc721Contract,
        uint256[] calldata tokenIds
    ) external noZero {
        uint256 length = tokenIds.length;
        address to = rawFusionHolder;
        for (uint256 i; i < length; ) {
            uint256 tokenId = tokenIds[i];
            address owner = erc721Contract.ownerOf(tokenId);
            if (msg.sender != owner) {
                revert NotOwnerOfToken();
            }
            erc721Contract.safeTransferFrom(owner, to, tokenId);
            unchecked {
                ++i;
            }
        }
        emit BatchBurn(address(erc721Contract), tokenIds);
    }
}