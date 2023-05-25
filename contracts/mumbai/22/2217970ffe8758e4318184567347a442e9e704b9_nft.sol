/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
   
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

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

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity ^0.8.0;

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
        
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address=>mapping(uint256=>uint256)) userPerIdMintingTime;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        userPerIdMintingTime[from][tokenId] = 0;
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

pragma solidity ^0.8.0;

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
       
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex; 

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface Savage {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity ^0.8.0;

contract nft is ERC721Enumerable, Ownable {

    Savage public savage;
    using Strings for uint256;
    using SafeMath for uint256;

    string public baseURI;
    string private baseExtension = ".json";

    bool public revealed = false;
    string public notRevealedUri;

    //mint cost
    uint256 public presaleCost = 0.01 ether;
    uint256 public publicCost = 0.01 ether;

    //max supply
    uint256 public presaleMaxSupply = 2000;
    uint256 public publicMaxSupply = 2000;

    //max mint
    uint256 public presaleMintLimit = 3;
    uint256 public publicMintLimit = 5;

    bool public isPresaleStart = false;
    bool public isPublicStart = false;

    mapping(address => bool) public isWhitelisted;
    mapping(address=>mapping(uint256=>bool)) private isMinter;

    mapping(address=>uint256) private mintedNFTs;
    uint256 private presaleMinted;
    uint256 private publicMinted;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        Savage _savage
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        savage = _savage;
    }

    

    function mint(uint256 _mintAmount) public payable {
        require(isPresaleStart == true || isPublicStart == true, "Neither of the sale is started yet!");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");

        if(isPresaleStart == true){
            require(isWhitelisted[msg.sender]==true, "You're not whitelisted!");
            require(_mintAmount <= presaleMintLimit, "You can mint in range (1-3) NFT!");
            require(msg.value == presaleCost.mul(_mintAmount), "insufficient funds");
            
            require(presaleMinted.add(_mintAmount) <= presaleMaxSupply, "max NFT presale limit exceeded");
            require(mintedNFTs[msg.sender].add(_mintAmount) <= presaleMintLimit, "You can mint max 3 NFTs!");
           
         
            for (uint8 i = 1; i <= _mintAmount; i++) {  
                _safeMint(msg.sender, supply + i);
                userPerIdMintingTime[msg.sender][supply + i] = block.timestamp;
                isMinter[msg.sender][supply+i] = true;
            }
            mintedNFTs[msg.sender]+=_mintAmount;
            presaleMinted += _mintAmount;
        }

        else if(isPublicStart == true){
            require(_mintAmount <= publicMintLimit, "You can mint in range (1-5) NFT!");
            require(msg.value == publicCost.mul(_mintAmount), "insufficient funds");
            require(publicMinted.add(_mintAmount) <= publicMaxSupply, "max NFT presale limit exceeded");
            require(mintedNFTs[msg.sender].add(_mintAmount) <= publicMintLimit, "You can mint max 5 NFTs!");
            for (uint8 i = 1; i <= _mintAmount; i++) {  
                _safeMint(msg.sender, supply + i);
                userPerIdMintingTime[msg.sender][supply + i] = block.timestamp;
                isMinter[msg.sender][supply+i] = true;
            }
            mintedNFTs[msg.sender]+=_mintAmount;
            publicMinted += _mintAmount;
        }
        
    }


function buy(uint256 _mintAmount) public {
    require(isPresaleStart == true || isPublicStart == true, "Neither of the sale is started yet!");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");

    if (isPresaleStart == true) {
        require(isWhitelisted[msg.sender] == true,"You're not whitelisted!");
        require(_mintAmount <= presaleMintLimit,"You can mint in range (1-3) NFT!");
        uint256 requiredTokenAmount = presaleCost.mul(_mintAmount);
        require(savage.transferFrom(msg.sender, address(this), requiredTokenAmount),"Token transfer failed");
        require(presaleMinted.add(_mintAmount) <= presaleMaxSupply,"max NFT presale limit exceeded");
        require(mintedNFTs[msg.sender].add(_mintAmount) <= presaleMintLimit,"You can mint max 3 NFTs!");

        for (uint8 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
            userPerIdMintingTime[msg.sender][supply + i] = block.timestamp;
            isMinter[msg.sender][supply + i] = true;
        }
        mintedNFTs[msg.sender] += _mintAmount;
        presaleMinted += _mintAmount;
        
    } else if (isPublicStart == true) {

        require(_mintAmount <= publicMintLimit,"You can mint in range (1-5) NFT!");
        uint256 requiredTokenAmount = publicCost.mul(_mintAmount);
        require(savage.transferFrom(msg.sender, address(this), requiredTokenAmount),"Token transfer failed");
        require(publicMinted.add(_mintAmount) <= publicMaxSupply,"max NFT public limit exceeded");
        require(mintedNFTs[msg.sender].add(_mintAmount) <= publicMintLimit,"You can mint max 5 NFTs!");

        for (uint8 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
            userPerIdMintingTime[msg.sender][supply + i] = block.timestamp;
            isMinter[msg.sender][supply + i] = true;
        }
        mintedNFTs[msg.sender] += _mintAmount;
        publicMinted += _mintAmount;
    }
}



    function calculateTokens(address _user) public view returns(uint256){
        uint256 tokens;
        for(uint8 i=0; i < walletOfOwner(_user).length; i++){
            if(isMinter[_user][walletOfOwner(_user)[i]] == true && userPerIdMintingTime[_user][walletOfOwner(_user)[i]]>0){
                if(_user == ownerOf(walletOfOwner(_user)[i])){
                    tokens+=((block.timestamp - userPerIdMintingTime[_user][walletOfOwner(_user)[i]]).div(1 days)).mul(5);
                }
            } 
        }
       return tokens;
       
    }

    function calculateTokensId(address _user, uint256 _id) public view returns(uint256){
        uint256 tokens;
        if(_user == ownerOf(_id)){
            if(isMinter[_user][_id] == true && userPerIdMintingTime[_user][_id]>0){
            tokens+= ((block.timestamp - userPerIdMintingTime[_user][_id])/(1 days))*5;
            }
        }
        
        return tokens;
    }

    function claimTokens() public {
        require(calculateTokens(msg.sender) > 0,"You don't have tokens for reward!");
        uint256 tokens = calculateTokens(msg.sender)*10**18;
        savage.transfer(msg.sender,tokens);
        
        for(uint8 i=0; i < walletOfOwner(msg.sender).length; i++){
            userPerIdMintingTime[msg.sender][walletOfOwner(msg.sender)[i]] = block.timestamp; 
        }
    }

    function claimById(uint8 _tokenId) public{
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOf(_tokenId)==msg.sender,"You don't own this NFT!");
        require(calculateTokens(msg.sender) > 0,"You don't have tokens for reward!");
        uint256 tokensById = calculateTokensId(msg.sender, _tokenId)*10**18;
        savage.transfer(msg.sender,tokensById);
        userPerIdMintingTime[msg.sender][_tokenId] = block.timestamp;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //UTILITIES
    function setPresaleStatus(bool _state) public onlyOwner{
        isPresaleStart = _state;
    }

    function setPublicMintStatus(bool _state) public onlyOwner{
        isPublicStart = _state;
    }

    function setPresaleMaxSupply(uint256 _newSupply) public onlyOwner{
        presaleMaxSupply=_newSupply;
    }

    function setPublicMaxSupply(uint256 _newSupply) public onlyOwner{
        publicMaxSupply=_newSupply;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner{
        presaleCost=_newCost;
    }

    function setPublicCost(uint256 _newCost) public onlyOwner{
        publicCost=_newCost;
    }

    function addWhitelist(address[] memory _addresses) external onlyOwner {
        for(uint i = 0; i < _addresses.length; i++) {
        isWhitelisted[_addresses[i]] = true;
        }
    }

    function removeWhitelist(address[] memory _addresses) external onlyOwner {
            for(uint i = 0; i < _addresses.length; i++) {
            isWhitelisted[_addresses[i]] = false;
            }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory){
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function reveal() public onlyOwner {
      revealed = true;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        publicMintLimit = _limit;
    }

    function setNftPresaleLimit(uint256 _limit) public onlyOwner {
        presaleMintLimit = _limit;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function contractBalance() public view returns(uint256){
        return address(this).balance;
    }

    function contractTokenBalance() public view returns (uint256) {
    return savage.balanceOf(address(this));
      }


    function withdraw(uint256 _amount) public payable onlyOwner {
        require(contractBalance() >= 0, "contract has no ethers!");
        require(_amount <= contractBalance(), "contract has not enough ethers!");
        require(_amount > 0, "Enter more than 0 amount!");
        uint256 balance = contractBalance();
        balance -= _amount;
        (bool os, ) = payable(owner()).call{value: _amount}("");
        require(os);
        
    }

   function withdrawTokon(uint256 _amount) public onlyOwner {
        require(contractTokenBalance() >= 0, "contract has no ethers!");
        require(_amount <= contractTokenBalance(), "contract has not enough ethers!");
        require(_amount > 0, "Enter more than 0 amount!");
         bool success = savage.transfer(owner(), _amount);
        require(success, "Token transfer failed"); 
    }
}