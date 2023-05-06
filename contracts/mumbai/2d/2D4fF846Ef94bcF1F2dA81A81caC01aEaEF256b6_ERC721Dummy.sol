// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
contract ERC721Dummy {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory){
        return "";
    }

    struct OwnerInfo{
        uint128 balance;
        uint128 nonce;
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => OwnerInfo) internal _balanceOf;

    uint128 internal wipeNonce;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");

        OwnerInfo memory ownerInfo = _balanceOf[owner];
        if(ownerInfo.nonce != wipeNonce){
            revert("ITEM_WIPED");
        }
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");
        OwnerInfo memory ownerInfo = _balanceOf[owner];

        if(ownerInfo.nonce != wipeNonce){
            return 0;
        }

        return ownerInfo.balance;
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        name = "TEST ERC721";
        symbol = "t721";
    }

    /*//////////////////////////////////////////////////////////////
                              DEBUG LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 id) public {
        _mint(to, id);
    }

    function batchMint(address to, uint256[] memory ids) public {
        for (uint256 i = 0; i < ids.length; i++) {
            _mint(to, ids[i]);
        }
    }

    function forceBurn(uint id) public{
        _burn(id);
    }

    function batchForceBurn(uint[] memory ids) public{
        for (uint256 i = 0; i < ids.length; i++) {
            _burn(ids[i]);
        }
    }

    function wipeAll() public{
        wipeNonce++;
    }

    function wipeAddress(address addr) public{
        _balanceOf[addr].nonce = 340282366920938463463374607431768211455;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        uint128 curWipeNonce = wipeNonce;
        OwnerInfo storage ownerInfo = _balanceOf[from];
        OwnerInfo storage recepientInfo = _balanceOf[to];

        if(ownerInfo.nonce != wipeNonce){
            revert("ITEM HAS BEEN WIPED");
        }

        if(recepientInfo.nonce != wipeNonce){
            recepientInfo.nonce = curWipeNonce;
            recepientInfo.balance = 1;
        }
        else{
            recepientInfo.balance++;
        }

        ownerInfo.balance--;
        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0) || _balanceOf[_ownerOf[id]].nonce != wipeNonce, "ALREADY_MINTED");


        OwnerInfo storage ownerInfo = _balanceOf[to];

        if(ownerInfo.nonce != wipeNonce){
            ownerInfo.nonce = wipeNonce;
            ownerInfo.balance = 1;
        }
        else{
            ownerInfo.balance++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        OwnerInfo storage ownerInfo = _balanceOf[owner];

        require(ownerInfo.nonce == wipeNonce, "ITEM HAS BEEN WIPED");

        // Ownership check above ensures no underflow.
        unchecked {
            ownerInfo.balance--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    function burn(uint256 id) public virtual {
        address owner = _ownerOf[id];
        
        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        _burn(id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}