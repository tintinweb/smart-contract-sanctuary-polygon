/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ERC1155I Implementation
// Thanks Solmate for inspiration

interface ERC1155TokenReceiver {
    function onERC1155Received(address operator_, address from_, uint256 id_,
        uint256 amount_, bytes calldata data_) external returns (bytes4);
    function onERC1155BatchReceived(address operator_, address from_,
        uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_)
        external returns (bytes4);
}

contract ERC1155IEnumerable {
    
    // Base Info
    string public name; 
    string public symbol; 

    // Setting Name and Symbol (Missing in ERC1155 Generally)
    constructor(string memory name_, string memory symbol_) {
        name = name_; 
        symbol = symbol_; 
    }

    // Events
    event TransferSingle(address indexed operator_, address indexed from_, 
        address indexed to_, uint256 id_, uint256 amount_);
    event TransferBatch(address indexed operator_, address indexed from_, 
        address indexed to_, uint256[] ids_, uint256[] amounts_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, 
        bool approved_);
    event URI(string value_, uint256 indexed id_);

    // ERC1155 Mappings
    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // ERC1155G Enumerable Ownership
    mapping(uint256 => address[]) public tokenToOwners;
    mapping(uint256 => mapping(address => uint256)) public tokenToOwnersToIndex;

    // Used for getOwnersOfTokenIdAndBalance view function
    struct TokenBalances {
        address owner;
        uint256 balance;
    }

    function _addEnumerableData(address address_, uint256 id_) internal {
        // If the user does not have any balance
        if (balanceOf[address_][id_] == 0) {
            // Find the next index
            uint256 _nextIndex = tokenToOwners[id_].length;
            // Add the address to owners list of the tokenId
            tokenToOwners[id_].push(address_);
            // Add their location in array to index data
            tokenToOwnersToIndex[id_][address_] = _nextIndex;
        }
    }
    function _removeEnumerableData(address address_, uint256 id_) internal {
        // If the user balance after deduction is 0
        if (balanceOf[address_][id_] == 0) {
            // Find the user in enumerable index
            uint256 _userIndex = tokenToOwnersToIndex[id_][address_];
            // Get the last index
            uint256 _lastIndex = tokenToOwners[id_].length - 1;
            // If the owner is not at the last index 
            if (_userIndex != _lastIndex) {
                address _userAtLastIndex = tokenToOwners[id_][_lastIndex];
                // Replace _userIndex slot with _lastIndex slot
                tokenToOwners[id_][_userIndex] = _userAtLastIndex;
                // Write the new index for the user
                tokenToOwnersToIndex[id_][_userAtLastIndex] = _userIndex;
            }

            // Now, delete the last index
            tokenToOwners[id_].pop();
            // And remove the user from the index data
            delete tokenToOwnersToIndex[id_][address_];
        }
    }
    function getOwnersOfTokenId(uint256 id_) public view returns (address[] memory) {
        return tokenToOwners[id_];
    }
    function getOwnersOfTokenIdAndBalance(uint256 id_) public view 
    returns (TokenBalances[] memory) {
        address[] memory _owners = getOwnersOfTokenId(id_);
        uint256 _ownersLength = _owners.length;
        TokenBalances[] memory _TokenBalancesAll = new TokenBalances[] (_ownersLength);

        for (uint256 i = 0; i < _ownersLength; i++) {
            address _currentOwner = _owners[i];
            _TokenBalancesAll[i] = TokenBalances(
                _currentOwner,
                balanceOf[_currentOwner][id_]
            );
        }
        return _TokenBalancesAll;
    }
    function getTotalSupplyOfIds(uint256[] calldata ids_) public view returns (uint256) {
        uint256 _tokens;
        for (uint256 i = 0; i < ids_.length; i++) {
            _tokens += getOwnersOfTokenId(ids_[i]).length;
        }
        return _tokens;
    }
    
    // URI Display Type Setting (Default to ERC721 Style)
        // 1 - ERC1155 Style
        // 2 - ERC721 Style
        // 3 - Mapping Style
    uint256 public URIType = 2; 
    function _setURIType(uint256 uriType_) internal virtual {
        URIType = uriType_;
    }   

    // ERC1155 URI
    string public _uri;
    function _setURI(string memory uri_) internal virtual { _uri = uri_; }
    
    // ERC721 URI (Override)
    string internal baseTokenURI; 
    string internal baseTokenURI_EXT;

    function _setBaseTokenURI(string memory uri_) internal virtual { 
        baseTokenURI = uri_; }
    function _setBaseTokenURI_EXT(string memory ext_) internal virtual {
        baseTokenURI_EXT = ext_; }
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
            48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    // Mapping Style URI (Override)
    mapping(uint256 => string) public tokenIdToURI;
    
    function _setURIOfToken(uint256 id_, string memory uri_) internal virtual {
        tokenIdToURI[id_] = uri_; }


    // URI (0xInuarashi Version)
    function uri(uint256 id_) public virtual view returns (string memory) {
        // ERC1155
        if (URIType == 1) return _uri;
        // ERC721
        else if (URIType == 2) return 
            string(abi.encodePacked(baseTokenURI, _toString(id_), baseTokenURI_EXT));
        // Mapping 
        else if (URIType == 3) return tokenIdToURI[id_];
        else return "";
    }

    // TokenURI (Because ERC1155 is weird)
    function tokenURI(uint256 tokenId_) public virtual view returns (string memory) {
        return string(abi.encodePacked(
            baseTokenURI, _toString(tokenId_), baseTokenURI_EXT));
    }

    // Internal Logics
    function _isSameLength(uint256 a, uint256 b) internal pure returns (bool) {
        return a == b;
    }
    function _isApprovedOrOwner(address from_) internal view returns (bool) {
        return msg.sender == from_ 
            || isApprovedForAll[from_][msg.sender];
    }
    function _ERC1155Supported(address from_, address to_, uint256 id_,
    uint256 amount_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) :
            ERC1155TokenReceiver(to_).onERC1155Received(
                msg.sender, from_, id_, amount_, data_) ==
            ERC1155TokenReceiver.onERC1155Received.selector,
                "_ERC1155Supported(): Unsupported Recipient!"
        );
    }
    function _ERC1155BatchSupported(address from_, address to_, uint256[] memory ids_,
    uint256[] memory amounts_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) :
            ERC1155TokenReceiver(to_).onERC1155BatchReceived(
                msg.sender, from_, ids_, amounts_, data_) ==
            ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "_ERC1155BatchSupported(): Unsupported Recipient!"
        );
    }

    // ERC1155 Logics
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        isApprovedForAll[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    function _transfer(address from_, address to_, uint256 id_, uint256 amount_) 
    internal {
        // _addEnumerableData is done before any balance calculation
        _addEnumerableData(to_, id_);

        // Balance calculation
        balanceOf[to_][id_] += amount_;
        balanceOf[from_][id_] -= amount_;
        
        // _removeEnumerableData is done after all balance calculation has been done
        _removeEnumerableData(from_, id_);
    }
    function safeTransferFrom(address from_, address to_, uint256 id_, 
    uint256 amount_, bytes memory data_) public virtual {
        require(_isApprovedOrOwner(from_));
        
        _transfer(from_, to_, id_, amount_);

        emit TransferSingle(msg.sender, from_, to_, id_, amount_);

        _ERC1155Supported(from_, to_, id_, amount_, data_);
    }
    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_,
    uint256[] memory amounts_, bytes memory data_) public virtual {
        require(_isSameLength(ids_.length, amounts_.length));
        require(_isApprovedOrOwner(from_));

        for (uint256 i = 0; i < ids_.length; i++) {
            _transfer(from_, to_, ids_[i], amounts_[i]);
        }

        emit TransferBatch(msg.sender, from_, to_, ids_, amounts_);

        _ERC1155BatchSupported(from_, to_, ids_, amounts_, data_);
    }

    // Internal Mint / Burn Logic
    function _mintInternal(address to_, uint256 id_, uint256 amount_) internal {
        // _addEnumerable data is done before any balance calculation
        _addEnumerableData(to_, id_);
        balanceOf[to_][id_] += amount_;
    }
    function _mint(address to_, uint256 id_, uint256 amount_, bytes memory data_)
    internal {
        _mintInternal(to_, id_, amount_);

        emit TransferSingle(msg.sender, address(0), to_, id_, amount_);

        _ERC1155Supported(address(0), to_, id_, amount_, data_);
    }
    function _batchMint(address to_, uint256[] memory ids_, uint256[] memory amounts_,
    bytes memory data_) internal {
        require(_isSameLength(ids_.length, amounts_.length));

        for (uint256 i = 0; i < ids_.length; i++) {
            _mintInternal(to_, ids_[i], amounts_[i]);
        }

        emit TransferBatch(msg.sender, address(0), to_, ids_, amounts_);

        _ERC1155BatchSupported(address(0), to_, ids_, amounts_, data_);
    }

    function _burnInternal(address from_, uint256 id_, uint256 amount_) internal {
        balanceOf[from_][id_] -= amount_;
        
        // _removeEnumerableData is done after all balance calculation has been done
        _removeEnumerableData(from_, id_);
    }
    function _burn(address from_, uint256 id_, uint256 amount_) internal {
        _burnInternal(from_, id_, amount_);
        emit TransferSingle(msg.sender, from_, address(0), id_, amount_);
    }
    function _batchBurn(address from_, uint256[] memory ids_, 
    uint256[] memory amounts_) internal {
        require(_isSameLength(ids_.length, amounts_.length));
        
        for (uint256 i = 0; i < ids_.length; i++) {
            _burnInternal(from_, ids_[i], amounts_[i]);
        }

        emit TransferBatch(msg.sender, from_, address(0), ids_, amounts_);
    }


    // ERC165 Logic
    function supportsInterface(bytes4 interfaceId_) public pure virtual returns (bool) {
        return 
        interfaceId_ == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
        interfaceId_ == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
        interfaceId_ == 0x0e89341c;   // ERC165 Interface ID for ERC1155MetadataURI
    }

    // View Functions
    function balanceOfBatch(address[] memory owners_, uint256[] memory ids_) public
    view virtual returns (uint256[] memory) {
        require(_isSameLength(owners_.length, ids_.length));

        uint256[] memory _balances = new uint256[](owners_.length);

        for (uint256 i = 0; i < owners_.length; i++) {
            _balances[i] = balanceOf[owners_[i]][ids_[i]];
        }
        return _balances;
    }
}

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

abstract contract Minterable is Ownable {
    mapping(address => bool) public minters;
    modifier onlyMinter { require(minters[msg.sender], "Not Minter!"); _; }
    function setMinter(address address_, bool bool_) external onlyOwner {
        minters[address_] = bool_;
    }
}

abstract contract Burnerable is Ownable {
    mapping(address => bool) public burners;
    modifier onlyBurner { require(burners[msg.sender], "Not Burner!"); _; }
    function setBurner(address address_, bool bool_) external onlyOwner {
        burners[address_] = bool_;
    }
}

contract ERC1155GEnumerable is ERC1155IEnumerable, Ownable, Minterable, Burnerable {
    
    ///// Set the name and symbol of ERC1155I ///
    constructor(string memory name_, string memory symbol_) 
        ERC1155IEnumerable(name_, symbol_) {}

    // Internal ETH Fallback + Sending to give some MATIC or NATIVETOKEN for user 
    event Received(address from, uint amount);
    receive() external payable { emit Received(msg.sender, msg.value); }
    function _sendETH(address payable address_, uint256 amount_) internal {
        (bool success, ) = payable(address_).call{value: amount_}("");
        require(success, "Transfer failed");
    }

    ///// Adding all Ownable Functions for convenience /////
    // URI Type
    function setURIType(uint256 uriType_) external onlyOwner {
        _setURIType(uriType_); }

    // Type 1 URI
    function setURI(string calldata uri_) external onlyOwner { _setURI(uri_); }
    
    // Type 2 URI
    function setBaseTokenURI(string calldata uri_) external onlyOwner { 
        _setBaseTokenURI(uri_); }
    function setBaseTokenURI_EXT(string calldata ext_) external onlyOwner { 
        _setBaseTokenURI_EXT(ext_); }

    // Type 3 URI
    function setURIOfToken(uint256 id_, string calldata uri_) external onlyOwner {
        _setURIOfToken(id_, uri_); }

    // Here, we implement the soulbound function overrides.
    // Also, it uses require statements instead of revert or complete removal for 
    // global compliance of verification bots (some bots break on function reverts)
    function safeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_,
    bytes memory data_) public override {
        // We require amount_ to be 0 effectively disabling transfers
        require(amount_ == 0, "ERC1155G: safeTransferFrom(): Soulbound!");
    }
    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_,
    uint256[] memory amounts_, bytes memory data_) public override {
        require(_isSameLength(ids_.length, amounts_.length),
            "ERC1155G: safeBatchTransferFrom(): Array Lengths Mismatch!");

        for (uint256 i = 0; i < amounts_.length; i++) {
            require(amounts_[i] == 0,
                "ERC1155G: safeBatchTransferFrom(): Soulbound!");
        }
    }
    function setApprovalForAll(address operator_, bool approved_) public override {
        // We require approved_ to false effectively disabling approvals
        require(!approved_, "ERC1155G: setApprovalForAll(): Soulbound!");
    }

    // Here, we add some airdrop and burning logic for project creators to have access.
    // These are accessed through my Burnable and Mintable modules.
    function _airdrop(address to_, uint256 id_, uint256 amount_, 
    bytes memory data_) internal {
        // // This makes sure we are not airdropping anyone duplicate tokens.
        // require(balanceOf[to_][id_] == 0,
        //     "ERC1155G: _airdrop(): user already has token!");

        // GAS Chip Specific Modification
        for(uint256 i = 0; i <= 3; i++) {
            require(balanceOf[to_][i] == 0,
                "ERC1155G: GAS Chip _airdrop(): user already has a chip!");
        }

        _mint(to_, id_, amount_, data_);
    }

    // This _ownerMint function overrides the balanceOf check. This is used generally
    // only to grant certain specific users above the allowed amount of tokens! 
    // Use wisely!
    function ownerAirdropOverride(address to_, uint256 id_, uint256 amount_,
    bytes memory data_) external onlyOwner {
        _mint(to_, id_, amount_, data_);
    }

    // Airdrop (Minterable)
    function airdropSingleToManyPlusETHInBalance(address payable[] calldata tos_, 
    uint256 id_, uint256 amount_, uint256 ethAmount_, bytes calldata data_) 
    external onlyMinter {
        // Contract Balance should be higher than amount to send
        require(address(this).balance >= ethAmount_ * tos_.length,
            "ERC1155G: airdropSingleToManyPlusETHInBalance(): Not enough ETH balance!");
        
        // Start airdropping and sending everyone ETH
        for (uint256 i = 0; i < tos_.length; i++) {
            _airdrop(tos_[i], id_, amount_, data_);
            _sendETH(tos_[i], ethAmount_);
        }
    }
    function airdropSingleToManyPlusETHInMsgValue(address payable[] calldata tos_,
    uint256 id_, uint256 amount_, uint256 ethAmount_, bytes calldata data_)
    external payable onlyMinter {
        // msg.value should be the same as amount to send
        require(msg.value == ethAmount_ * tos_.length,
            "ERC1155G: airdropSingleToManyPlusETHInMsgValue(): Incorrect msg.value!");
        
        // Start airdropping and sending everyone ETH
        for (uint256 i = 0; i < tos_.length; i++) {
            _airdrop(tos_[i], id_, amount_, data_);
            _sendETH(tos_[i], ethAmount_);
        }
    }

    // BurnFrom (Burnerable)
    function burnFromSingle(address[] calldata froms_, uint256 id_, uint256 amount_) 
    external onlyBurner {
        // Start burning 
        for (uint256 i = 0; i < froms_.length; i++) {
            // This will revert an underflow if burn amount exceeds balanceOf
            _burn(froms_[i], id_, amount_);
        }
    }
    function burnFromMany(address[] calldata froms_, uint256[] calldata ids_,
    uint256[] calldata amounts_) external onlyBurner {
        // Make sure all the calldata arrays are the same length
        require(_isSameLength(froms_.length, ids_.length) 
            && _isSameLength(froms_.length, amounts_.length),
            "ERC1155G: burnFromMany(): Array lengths mismatch!");
        
        // Start burning 
        for (uint256 i = 0; i < froms_.length; i++) {
            // This will revert an underflow if burn amount exceeds balanceOf
            _burn(froms_[i], ids_[i], amounts_[i]);
        }
    }
}

contract GASChip is ERC1155GEnumerable {
    // Set the name and symbol
    constructor()  ERC1155GEnumerable("Gangster All Star Chips", "GASCHIP") {}
    function setName(string calldata name_) external onlyOwner { name = name_; }
    function setSymbol(string calldata symbol_) external onlyOwner { symbol = symbol_; }

    ///// Choose Your Gang Functions /////
    function _gangIsChoosable(uint256 gangId_) internal pure returns (bool) {
        return gangId_ == 1 || gangId_ == 2 || gangId_ == 3;
    }
    function chooseGang(uint256 gangId_) external {
        require(balanceOf[msg.sender][0] > 0,
            "You don't have a blank chip!");
        require(_gangIsChoosable(gangId_),
            "You cannot choose this gang!");
        
        // Burn the blank chip from msg.sender
        _burn(msg.sender, 0, 1);

        // Mint the gang chip for msg.sender
        _mint(msg.sender, gangId_, 1, "");
    }
}