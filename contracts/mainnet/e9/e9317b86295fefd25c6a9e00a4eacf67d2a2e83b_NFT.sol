// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
contract NFT is ERC721A, Ownable, ReentrancyGuard {
    // Max supply 
    uint256 public maxSupply;

    // Admin mapping
    mapping(address => bool) public isAdmin;
    // Modifier to protect functions that should only be callable by admin or owner
    modifier onlyAdmin() {
        require(isAdmin[_msgSender()] || _msgSender() == owner(), "OnlyAdmin: sender is not admin or owner");
        _;
    }

    // Merkle Root
    bytes32 public alRoot;

    // Public and Allow-List Prices
    uint256 public price;
    uint256 public alPrice;

    // 0 - closed
    // 1 - allow list only
    // 2 - public
    uint256 public state;
    
    event minted(address minter, uint256 price, address recipient, uint256 amount);
    event stateChanged(uint256 _state);

    constructor (
        string memory _name,     // 
        string memory _symbol,   // 
        uint256 _maxSupply,     // 
        uint256 _price,         // 
        uint256 _alPrice,        //
        string memory _uri
    ) 
    ERC721A(_name, _symbol) 
    {
        maxSupply = _maxSupply;
        price = _price;
        alPrice = _alPrice;
        URI = _uri;

        isAdmin[_msgSender()] = true;
    }

    function isAllowListed(address _recipient, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        bool isal = MerkleProof.verify(_merkleProof, alRoot, leaf);
        return isal;
    }

    function mint(uint256 amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(state > 0, "Sale is closed");
        require(totalSupply() + amount <= maxSupply, "NFT: exceeds max supply");

        uint256 mintPrice = price;

        if(state == 1) {
            require(isAllowListed(_msgSender(), _merkleProof), "NFT: Allow list only");
            mintPrice = alPrice;
        } else if(state == 2) {
            if(isAllowListed(_msgSender(), _merkleProof)) {
                mintPrice = alPrice;
            }
        }

        require(msg.value == mintPrice * amount, "NFT: incorrect amount of ETH sent");
        
        _safeMint(_msgSender(), amount);
        emit minted(_msgSender(), msg.value, _msgSender(), amount);
    }

    function ownerMint(uint amount, address _recipient) external onlyOwner {
        require(totalSupply() + amount <= maxSupply,  "exceeds max supply");
        _safeMint(_recipient, amount);
        emit minted(_msgSender(), 0, _recipient, amount);
    }

    function withdraw(uint256 amount, address payable recipient) external onlyOwner {
        (bool success,) = recipient.call{value: amount}("");
        require(success, "Transfer fail");
    }

    function setURI(string memory _uri) external onlyAdmin {
        URI = _uri;
    }

    function setState(uint256 _state) external onlyAdmin {
        require(_state <= 2, "State can only be from 0 to 2, inclusive");
        state = _state;
        emit stateChanged(state);
    }
    
    function setALRoot(bytes32 root) external onlyAdmin {
        alRoot = root;
    }

    function setAdmin(address _admin, bool _isAdmin) public onlyOwner {
        isAdmin[_admin] = _isAdmin;
    }

    function setPrice(uint256 _price) external onlyAdmin {
        price = _price;
    }

    function setALPrice(uint256 _alPrice) external onlyAdmin {
        alPrice = _alPrice;
    }
}