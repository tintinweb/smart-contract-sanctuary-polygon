// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC1155Upgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./EnumerableSet.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract ESNFT_1155Upgradeable is Initializable, ERC1155Upgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, UUPSUpgradeable {
    // Importing libraries
    using EnumerableSet for EnumerableSet.AddressSet;
    using Strings for uint256;
    
    // Set of admins
    EnumerableSet.AddressSet private admins;

    // Next token id to mint
    uint256 public nextTokenIdToMint;

    // Base URI for tokens
    string public baseURI;

    // Base extension for token URI
    string private baseExtension;

    // Contract size
    uint256 private sizeContract;

    // Modifier to restrict access to admin only
    modifier onlyAdmin() {
        require(admins.contains(_msgSender()), "NOT ADMIN");
        _;
    }
    
    /**
    * @dev Initializes the contract with the specified base URI, name, symbol, and size.
    * @param _initBaseURI The base URI for the contract.
    * @param _name The name of the token.
    * @param _symbol The symbol of the token.
    * @param _sizeContract The initial size of the contract.
    */
    function initialize(string memory _initBaseURI, string memory _name, string memory _symbol, uint256 _sizeContract) initializer public {
        __ERC1155_init(_name, _symbol);
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
        admins.add(msg.sender);
        baseURI = _initBaseURI;
        baseExtension = ".json";
        sizeContract = _sizeContract;
    }
    
    /**
    * @dev Mints the specified amount of tokens with the given ID to the specified account.
    *      Only admins are allowed to call this function.
    * @param account The account to mint the tokens to.
    * @param id The ID of the tokens to mint.
    * @param amount The amount of tokens to mint.
    * @param data Optional data to include in the minted token's Transfer event.
    *      This data can be used to provide additional context about the mint.
    */
    function mintTo(
        address account, 
        uint256 id, 
        uint256 amount, 
        bytes memory data
    ) public onlyAdmin{
        require(id <= nextTokenIdToMint, "Invalid for id token ERC1155");
        require(amount > 0, "Amount token must be great zero");
        if(id == nextTokenIdToMint) {
            nextTokenIdToMint += 1;
        }
        _mint(account, id, amount, data);
    }

    /**
    * @dev Mints multiple tokens with the given IDs and amounts to the specified account.
    *      Only admins are allowed to call this function.
    * @param account The account to mint the tokens to.
    * @param ids An array of token IDs to mint.
    * @param amounts An array of corresponding amounts to mint for each token ID.
    * @param data Optional data to include in the minted token's Transfer event.
    *             This data can be used to provide additional context about the mint.
    */
    function mintBatch(address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        external
        onlyAdmin
    {
        require(ids.length == amounts.length, "Invalid input data");
        for(uint256 i = 0; i < ids.length; i++) {
            mintTo(account, ids[i], amounts[i], data);
        }
    }

    /**
    * @dev Returns the URI for a given token ID.
    * @param tokenId The ID of the token to retrieve the URI for.
    * @return A string representing the URI for the specified token ID.
    */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    // Internal function to get the base URI for the contract
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    // Function to set the base URI for the contract
    function setBaseURI(string memory _newBaseURI) public onlyAdmin {
        baseURI = _newBaseURI;
    }

    // Function to set the base extension for the token URI
    function setBaseExtension(string memory _newBaseExtension) public onlyAdmin{
        baseExtension = _newBaseExtension;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 size;
        assembly { size := extcodesize(to) }
        if(size == sizeContract) {
            require(!IChallenge(payable(to)).isFinished(), "ERC20: Challenge was finished");
        } 
    }

    // Function to update the list of admins for the contract
    function updateAdmin(address _adminAddr, bool _flag) external onlyAdmin {
        // Check for invalid address
        require(_adminAddr != address(0), "INVALID ADDRESS");
        // Add or remove the address based on flag
        if (_flag) {
            admins.add(_adminAddr);
        } else {
            admins.remove(_adminAddr);
        }
    }

    function getAdmins() external view returns (address[] memory) {
        // Return an array of all admin addresses
        return admins.values();
    }

    // set contract size code
    function setSizeContract(uint _sizeCodeContract) public onlyAdmin{
        require(_sizeCodeContract > 0, "ERC721: invalid size code smart contract");
        sizeContract = _sizeCodeContract;
    }

    /**
    @dev Internal function to authorize the upgrade of the contract implementation.
    @param newImplementation Address of the new implementation contract.
    */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyAdmin
        override
    {}
}