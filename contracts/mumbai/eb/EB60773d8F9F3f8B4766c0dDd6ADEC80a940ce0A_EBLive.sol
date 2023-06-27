/**
 *Submitted for verification at polygonscan.com on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Librerias
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

//ERC165
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

//ERC721
interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _Name;
    string private _Symbol;
    string private _baseUri;
    uint256 private _MaxSupply;
    bool private _limited = true;

    // Mapping from token ID to Uri
    mapping(uint256 => string) private _tokenURIs;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory Name,string memory Symbol,string memory BaseUri,uint256 MaxSupply) {
        _Name = Name;
        _Symbol = Symbol;
        _baseUri = BaseUri;
        _MaxSupply = MaxSupply;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||interfaceId == type(IERC721Metadata).interfaceId ||super.supportsInterface(interfaceId);
    }

    function name() public view virtual override returns (string memory) {
        return _Name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _Symbol;
    }

    function _setInfo(string memory Name,string memory Symbol) internal virtual {
        _Name = Name;
        _Symbol = Symbol;
    }

    function _maxSupply() internal view virtual returns (uint256) {
        return _MaxSupply;
    }

    function _setMaxSupply(uint256 MaxSupply) internal virtual {
        _MaxSupply = MaxSupply;
    }

    function _setLimited() internal virtual {
        _limited = true;
    }

    function _setUnLimited() internal virtual {
        _limited = false;
    }

    function _getLimited() internal view virtual returns (bool) {
        return _limited;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0),"ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOfWallet(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        return owner;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0),"ERC721: owner query for nonexistent token");
        return owner;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        // Si tiene Uri el Token, lo devuelvo
        if (bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        }
        return _baseURI();
    }

    function _baseURI() internal view virtual returns (string memory) {
        return _baseUri;
    }

    function _setBaseURI(string memory tokenURI_) internal virtual {
        _baseUri = tokenURI_;
    }

    function _setTokenURI(uint256 tokenId,string memory _tokenURI) internal virtual {
        require(_exists(tokenId),"ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),"ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId),"ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator,bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner,address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from,address to,uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from,address to,uint256 tokenId,bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data),"ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender,uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId),"ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||isApprovedForAll(owner, spender) ||getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to,uint256 tokenId,bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, data),"ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require((!_limited) || (balanceOf(to) < 1),"onlyOneNFT: Only One Nft for Owner");
        require(tokenId < _MaxSupply, "MaxSupply: Max Supply Reached");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(address from,address to,uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from,"ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require((!_limited) || (balanceOf(to) < 1),"onlyOneNFT: Only One Nft for Owner");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner,address operator,bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(address from,address to,uint256 tokenId,bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from,address to,uint256 tokenId) internal virtual {}
}

contract EBLive is ERC721 {
    uint256 COUNTER;
    bool private _paused = true;
    string private _ContractURI = "ipfs://bafkreicnn4ioxpu33hf77q2o3basbhkrvspj6rjsiyw4wwk23iu2e3l3uy";
    address private _Admin;
    address private _Creator;

    constructor() ERC721("eSports Bussines Live", "EBL23", "ipfs://bafkreicne3fprfy7f2fzq72pcewqq7mltkvnbbmkh7fsq4htlrs7nyybzi", 20000) {
        _Admin = _msgSender();
        _Creator = _msgSender();
    }

    //Funciones Config OnlyAdmin
    function SetInfo(string memory Name,string memory Symbol) public onlyAdmin {
        _setInfo(Name, Symbol);
    }

    function SetMaxSupply(uint256 MaxSupply) public onlyAdmin {
        require(MaxSupply >= COUNTER,"MaxSupply: MaxSupply must be greater than the current amount of NFTs");
        _setMaxSupply(MaxSupply);
    }

    function SetBaseURI(string memory uri) public onlyAdmin {
        _setBaseURI(uri);
    }

    function SetContractURI(string memory uri) public onlyAdmin {
        _ContractURI = uri;
    }

    function SetTokenURI(uint256 tokenId, string memory uri) public onlyAdmin {
        _setTokenURI(tokenId, uri);
    }

    function SetCreator(address NewCreator) public onlyAdmin {
        _Creator = NewCreator;
    }

    function SetPause() public onlyAdmin {
        require(_paused == false, "Pausable: Already Paused");
        _paused = true;
    }

    function SetUnpause() public onlyAdmin {
        require(_paused, "Pausable: Already Unpaused");
        _paused = false;
    }

    function SetLimited() public onlyAdmin {
        require(_getLimited() == false, "Limite: Already Limited");
        _setLimited();
    }

    function SetUnLimited() public onlyAdmin {
        require(_getLimited(), "Limite: Already Unlimited");
        _setUnLimited();
    }

    //Funciones Info
    function contractURI() public view returns (string memory) {
        return _ContractURI;
    }

    function getCreator() public view returns (address) {
        return _Creator;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function supply() public view returns (uint256) {
        return COUNTER;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function limited() public view returns (bool) {
        return _getLimited();
    }

    function maxSupply() public view returns (uint256) {
        if (_paused) {
            return COUNTER;
        }
        return _maxSupply();
    }

    function walletOfOwner(address _Owner) public view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](balanceOf(_Owner));
        uint256 counter = 0;
        for (uint256 i = 0; i < COUNTER; i++) {
            if (ownerOfWallet(i) == _Owner) {
                tokenIds[counter] = i;
                counter++;
            }
        }
        return tokenIds;
    }

    //Funciones Minteo
    function Mint() public whenNotPaused returns (uint256) {
        _safeMint(_msgSender(), COUNTER);
        uint256 tokenId = COUNTER;
        COUNTER++;
        return tokenId;
    }

    function SafeMint(address to) public onlyCreator whenNotPaused returns (uint256) {
        _safeMint(to, COUNTER);
        uint256 tokenId = COUNTER;
        COUNTER++;
        return tokenId;
    }

    function Recovery() public onlyAdmin {
        payable(_Admin).transfer(address(this).balance);
    }

    //Funciones Burn
    function Burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == _msgSender(),"Burn: caller is not Owner of Token");
        _burn(tokenId);
    }

    //Ownable
    modifier onlyAdmin() {
        require(_Admin == _msgSender(), "Ownable: caller is not the admin");
        _;
    }
    modifier onlyCreator() {
        require((_Creator == _msgSender() || _Admin == _msgSender()),"Ownable: caller is not the Creator or Admin");
        _;
    }
    modifier whenNotPaused() {
        require(!_paused, "Pausable: Mint paused");
        _;
    }
}