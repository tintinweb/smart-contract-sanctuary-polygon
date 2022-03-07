// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/*


  █████████  █████   ███   █████
 ███░░░░░███░░███   ░███  ░░███ 
░███    ░░░  ░███   ░███   ░███ 
░░█████████  ░███   ░███   ░███ 
 ░░░░░░░░███ ░░███  █████  ███  
 ███    ░███  ░░░█████░█████░   
░░█████████     ░░███ ░░███     
 ░░░░░░░░░       ░░░   ░░░      


*/
                                

import {ITickingMetadata} from "./TickingMetadata.sol";


interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract Ticking is ERC721, ERC721Metadata {
 
    
    ITickingMetadata public _metadataGenerator;
    
    string private _name;

    string private _symbol;

    uint public constant MAX_SUPPLY = 144;
 
    uint256 public _nextMintId;
 
    uint256 public _countToken;

    address public _soldierwork;



    // Mapping owner address to token count.
    mapping (address => uint256) private _balances;


    // Mapping from token ID to owner address.
    mapping (uint256 => address) private _owners;

    // Mapping from token ID to approved address.
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from token ID to block time 
    mapping (uint256 => uint256) private _block_time;

    // Mapping from token ID to color properties.
    mapping (uint256 => mapping (uint256 => string)) private _colors;

    // Mapping from owner to operator approvals.
    mapping (address => mapping (address => bool)) private _operatorApprovals;




    modifier onlySoldierWork() {
        require(_msgSender() == _soldierwork, "msg.sender is not SoldierWork");
        _;
    }


  
    constructor(address metadataGenerator_, address soldierwork_) {
        _nextMintId = 1;
        _metadataGenerator = ITickingMetadata(metadataGenerator_);
        _name = "ticking";
        _symbol = "T.";
        _soldierwork = soldierwork_; 

    }
        
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    } 

    function totalSupply() public view returns (uint256) {
        return _countToken;
    }

    function _transfer(
        address owner,
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(owner == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        

        // Clear approvals from the previous owner
        _approve(owner, address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        // Update clock time per blockchain activity
        _block_time[tokenId] = block.timestamp;

        emit Transfer(from, to, tokenId);

    }



    function setSoldierWork(address soldierwork_) external onlySoldierWork {  
        _soldierwork = soldierwork_;
    }


    function setMetadataGenerator(address metadataGenerator_) external onlySoldierWork {  
        _metadataGenerator = ITickingMetadata(metadataGenerator_);
    }
   

    function ownerOf(uint256 tokenId) public view override returns (address owner) {
        owner = _owners[tokenId]; 
        require(owner != address(0), "ERC721: nonexistent token");
    }

    // Generate NFTs for this collection
    // Colors are identical elements for uniqeness
     function mint(string memory _color1, string memory _color2, string memory _color3) external onlySoldierWork {
        require(_countToken + 1 <= MAX_SUPPLY, "Not enough NFTs left!");    
        require(_nextMintId - 1 <= MAX_SUPPLY, "Not enough NFTs left!");  

        uint256 index = _nextMintId; 
        uint256 newlyMintedCount = 0;
        newlyMintedCount++;

        _owners[index] = _soldierwork;


        _colors[index][1] = _color1;
        _colors[index][2] = _color2;
        _colors[index][3] = _color3;

        _block_time[index] = block.timestamp;
                
             
        emit Transfer(address(0), _soldierwork, index);
            
            
            // update counters for loop
        index++;
        

        // return new token id index to storage
        _nextMintId = index;  

        // update token supply and balances based on batch mint
        _countToken += newlyMintedCount;
        _balances[_soldierwork] += newlyMintedCount;

        

    
                
    }


    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        (address owner, bool isApprovedOrOwner) = _isApprovedOrOwner(_msgSender(), tokenId);
        require(isApprovedOrOwner, "ERC721: transfer caller is not owner nor approved");
        _transfer(owner, from, to, tokenId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];        
    }

    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(owner, to, tokenId);
    }

    function _approve(address owner, address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: nonexistent token");       
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

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (address owner, bool isApprovedOrOwner) {
        owner = _owners[tokenId];

        require(owner != address(0), "ERC721: nonexistent token");

        isApprovedOrOwner = (spender == owner || _tokenApprovals[tokenId] == spender || isApprovedForAll(owner, spender));
    }   

    function tokenURI(uint256 tokenId) public virtual view override returns (string memory) {
        require(_exists(tokenId), "ERC721: nonexistent token");
        
        return _metadataGenerator.tokenMetadata(
            tokenId,
            _block_time[tokenId],
            _colors[tokenId][1],
            _colors[tokenId][2],
            _colors[tokenId][3]);
    }




    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
        return true;
    }    

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _ERC2981_ = 0x2a55205a;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;
        return interfaceId == _ERC165_ 
            || interfaceId == _ERC721_
            || interfaceId == _ERC2981_
            || interfaceId == _ERC721Metadata_;
    }


    function burn(uint256 tokenId) public {
        (address owner, bool isApprovedOrOwner) = _isApprovedOrOwner(_msgSender(), tokenId);
        require(isApprovedOrOwner, "ERC721: caller is not owner nor approved");

        _burnNoEmitTransfer(owner, tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _burnNoEmitTransfer(address owner, uint256 tokenId) internal {
        _approve(owner, address(0), tokenId);

        

        
        delete _owners[tokenId];

        _countToken -= 1;
        _balances[owner] -= 1;        

    }
}