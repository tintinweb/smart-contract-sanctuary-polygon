// SPDX-License-Identifier: MIT

/// @title Blockchain Invaders
/// @author Jourdan Dunkley

pragma solidity >=0.8.13;
 
import "./ERC721.sol";
import "./Owned.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

/// @notice Thrown when attempting to mint while total supply has been minted.
error MintedOut();
/// @notice Thrown when minter does not have enough ether.
error NotEnoughFunds();
/// @notice Thrown when a public minter / whitelist minter has reached their mint capacity.
error AlreadyClaimed();
/// @notice Thrown when the jam sale is not active.
error PublicSaleNotActive();
/// @notice Thrown when a signer is not authorized.
error NotAuthorized();

contract BlockchainInvaders is ERC721, Owned {
    using Strings for uint256;

    /// @notice The total supply of BlockchainInvaders.
    uint256 public constant MAX_SUPPLY = 12;
    /// @notice Mint price.
    uint256 public mintPrice = 0 ether;
    uint256 public totalSupply = 0;

    /// @notice The base URI.
    string baseURI;

    /// @notice Returns true when the public sale is active, false otherwise.
    bool public publicSaleActive;

    /// @notice Keeps track of whether a public minter has already minted or not. Max 1 mint.
    mapping(address => bool) public publicClaimed;

    /// @notice Address of the signer who is allowed to burn BlockchainInvaders.
    address private invaderBurner;

    constructor(string memory _baseURI)
        ERC721("Blockchain Invaders", "BCI")
        Owned(msg.sender)
    {
        baseURI = _baseURI;
    }

    /// @notice Allows the owner to change the base URI of BlockchainInvaders's corresponding metadata.
    /// @param _uri The new URI to set the base URI to.
    function setURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    /// @notice The URI pointing to the metadata of a specific assett.
    /// @param _id The token ID of the requested ship. Hardcoded .json as suffix.
    /// @return The metadata URI.
    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _id.toString(), ".json"));
    }

    /// @notice Public BlockchainInvaders mint.
    /// @dev Allows any non-contract signer to mint a single BlockchainInvaders. Capped by 1.
    /// @dev Current supply addition can be unchecked, as it cannot overflow.
    function publicMint() public payable {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (publicClaimed[msg.sender]) revert AlreadyClaimed();
        if (totalSupply + 1 > MAX_SUPPLY) revert MintedOut();
        if ((msg.value) < mintPrice) revert NotEnoughFunds();

        unchecked {
            publicClaimed[msg.sender] = true;
            _mint(msg.sender, totalSupply);
            ++totalSupply;
        }
    }

    /// @notice Authorize a specific address to serve as the BlockchainInvaders burner. For future use.
    /// @param _newBurner The address of the new burner.
    function setinvaderBurner(address _newBurner) public onlyOwner {
        invaderBurner = _newBurner;
    }

    /// @notice Burn a BlockchainInvaders with a specific token id.
    /// @dev !NOTE: Both publicSale & jamSale should be inactive.
    /// @dev Unlikely that the totalSupply will be below 0. Hence, unchecked.
    /// @param tokenId The token ID of the ship to burn.
    function burn(uint256 tokenId) public {
        if (msg.sender != invaderBurner) revert NotAuthorized();
        unchecked {
            --totalSupply;
        }
        _burn(tokenId);
    }

    /// @notice Flip the public sale state.
    function flipPublicSaleState() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    /// @notice Set the price of mint, in case there is no mint out.
    function setPrice(uint256 _targetPrice) public onlyOwner {
        mintPrice = _targetPrice;
    }

    /// @notice Transfer all funds from contract to the contract deployer address.
    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }
}