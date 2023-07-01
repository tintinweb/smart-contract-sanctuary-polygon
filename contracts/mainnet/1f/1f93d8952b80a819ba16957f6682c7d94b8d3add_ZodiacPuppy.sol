// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "ERC721.sol";
import {DefaultOperatorFilterer} from "DefaultOperatorFilterer.sol";
import {Ownable} from "Ownable.sol";
import "Counters.sol";
import "Strings.sol";
import "ERC2981.sol";
import "IERC20.sol";

/**
 * @title  ExampleERC721
 * @notice This example contract is configured to use the DefaultOperatorFilterer, which automatically registers the
 *         token and subscribes it to OpenSea's curated filters.
 *         Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that
 *         the msg.sender (operator) is allowed by the OperatorFilterRegistry. Adding the onlyAllowedOperatorApproval
 *         modifier to the approval methods ensures that owners do not approve operators that are not allowed.
 */
contract ZodiacPuppy is ERC721, DefaultOperatorFilterer, Ownable, ERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;

    IERC20 public token;

    string private baseURI;
    string public baseExtension = ".json";
    string public contractURI;

    bool public public_mint_status = true;

    uint256 public MAX_SUPPLY = 12000;
    uint256 public publicSaleCost;
    uint256 public max_per_wallet = 12000;
    uint256 public max_per_txn = 12000; 
    uint256 public totalSupply;    
    uint256 public decimals = 6;
    uint96 royaltyFeesInBips;

    address royaltyAddress;    
    address public token_Contract = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public premintwallet = 0xAb70FABa7c77C04Dd6aF16C2641aA0B1Ad09d3f6;

    mapping(uint256 => uint256) public count;
    mapping(uint256 => uint256) public sectionPrice;
    mapping(uint256 => uint256) public sectionCount;  

    constructor(
        string memory _name,
        string memory _symbol
        
    ) ERC721(_name, _symbol) {
        baseURI = "https://bafybeidmvkfihm56jwdpm6ski2ijarm4myzhwsxzhnu6mzllud436fmx2a.ipfs.nftstorage.link/";
        setRoyaltyInfo(owner(),500);
        token = IERC20(token_Contract);
    }

    function preMintNFTs(uint256 startingID, uint256 endingID) public onlyOwner {
        for (uint256 i = startingID; i <= endingID; i++) {
            _safeMint(premintwallet, i);
            totalSupply++;
        }        
    }

    function mint(uint256 _mintAmount, uint256 _priceSection) public payable {
    require(totalSupply + _mintAmount <= MAX_SUPPLY, "Maximum supply exceeds");
        
    uint256 startTokenId;
    uint256 endTokenId;
    
    // Define the start and end token IDs based on the selected price section
    if (_priceSection == 1) {
        startTokenId = 76;
        endTokenId = 200;
        sectionCount[1] = sectionCount[1] + _mintAmount;        
    } else if (_priceSection == 2) {
        startTokenId = 502;
        endTokenId = 1000;
        sectionCount[2] = sectionCount[2] + _mintAmount;  
    } else if (_priceSection == 3) {
        startTokenId = 1077;
        endTokenId = 1200;
        sectionCount[3] = sectionCount[3] + _mintAmount;  
    } else if (_priceSection == 4) {
        startTokenId = 1502;
        endTokenId = 2000;
        sectionCount[4] = sectionCount[4] + _mintAmount;  
    } else if (_priceSection == 5) {
        startTokenId = 2077;
        endTokenId = 2200;
        sectionCount[5] = sectionCount[5] + _mintAmount;  
    } else if (_priceSection == 6) {
        startTokenId = 2502;
        endTokenId = 3000;
        sectionCount[6] = sectionCount[6] + _mintAmount;  
    } else if (_priceSection == 7) {
        startTokenId = 3077;
        endTokenId = 3200;
        sectionCount[7] = sectionCount[7] + _mintAmount;  
    } else if (_priceSection == 8) {
        startTokenId = 3502;
        endTokenId = 4000;
        sectionCount[8] = sectionCount[8] + _mintAmount;  
    } else if (_priceSection == 9) {
        startTokenId = 4077;
        endTokenId = 4200;
        sectionCount[9] = sectionCount[9] + _mintAmount;  
    } else if (_priceSection == 10) {
        startTokenId = 4502;
        endTokenId = 5000;
        sectionCount[10] = sectionCount[10] + _mintAmount;  
    } else if (_priceSection == 11) {
        startTokenId = 5077;
        endTokenId = 5200;
        sectionCount[11] = sectionCount[11] + _mintAmount;  
    } else if (_priceSection == 12) {
        startTokenId = 5502;
        endTokenId = 6000;
        sectionCount[12] = sectionCount[12] + _mintAmount;  
    } else if (_priceSection == 13) {
        startTokenId = 6077;
        endTokenId = 6200;
        sectionCount[13] = sectionCount[13] + _mintAmount;  
    } else if (_priceSection == 14) {
        startTokenId = 6502;
        endTokenId = 7000;
        sectionCount[14] = sectionCount[14] + _mintAmount;  
    } else if (_priceSection == 15) {
        startTokenId = 7077;
        endTokenId = 7200;
        sectionCount[15] = sectionCount[15] + _mintAmount;  
    } else if (_priceSection == 16) {
        startTokenId = 7502;
        endTokenId = 8000;
        sectionCount[16] = sectionCount[16] + _mintAmount;  
    } else if (_priceSection == 17) {
        startTokenId = 8077;
        endTokenId = 8200;
        sectionCount[17] = sectionCount[17] + _mintAmount;  
    } else if (_priceSection == 18) {
        startTokenId = 8502;
        endTokenId = 9000;
        sectionCount[18] = sectionCount[18] + _mintAmount;  
    } else if (_priceSection == 19) {
        startTokenId = 9077;
        endTokenId = 9200;
        sectionCount[19] = sectionCount[19] + _mintAmount;  
    } else if (_priceSection == 20) {
        startTokenId = 9502;
        endTokenId = 10000;
        sectionCount[20] = sectionCount[20] + _mintAmount;  
    } else if (_priceSection == 21) {
        startTokenId = 10077;
        endTokenId = 10200;
        sectionCount[21] = sectionCount[21] + _mintAmount;  
    } else if (_priceSection == 22) {
        startTokenId = 10502;
        endTokenId = 11000;
        sectionCount[22] = sectionCount[22] + _mintAmount;  
    } else if (_priceSection == 23) {
        startTokenId = 11077;
        endTokenId = 11200;
        sectionCount[23] = sectionCount[23] + _mintAmount;  
    } else if (_priceSection == 24) {
        startTokenId = 11502;
        endTokenId = 12000;
        sectionCount[24] = sectionCount[24] + _mintAmount;  
    } else {
        revert("Invalid price section");
    }
    
    publicSaleCost = sectionPrice[_priceSection];

    if (msg.sender != owner()) {
        require(public_mint_status, "Public mint not available");
        require(_mintAmount + balanceOf(msg.sender) <= max_per_wallet, "Max per wallet exceeds");
        require(_mintAmount <= max_per_txn, "Per txn Limit Reached");
        require(token.balanceOf(msg.sender) >= (publicSaleCost * 10 ** decimals) * _mintAmount, "You do not have enough tokens to perform the transaction");
        token.transferFrom(msg.sender, owner(), (publicSaleCost * 10 ** decimals) * _mintAmount);
    }

    for (uint256 i = 0; i < _mintAmount; i++) {
        uint256 tokenId = startTokenId + count [_priceSection];
        
        if (tokenId >= startTokenId && tokenId <= endTokenId) {
            if (!_exists(tokenId)) {
                count[_priceSection]++;
                totalSupply++;
                _safeMint(msg.sender, tokenId);                
            } else {
                tokenId++;
                count [_priceSection]++;
                totalSupply++;
                _safeMint(msg.sender, tokenId);               
            }
        } else {
            revert("Token ID not within the selected price section");
        }
        
    }

}

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
                )
                : "";
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setPublic_mint_status(bool _public_mint_status) public onlyOwner {
        public_mint_status = _public_mint_status;
    }

    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }

    function setMax_per_wallet(uint256 _max_per_wallet) public onlyOwner {
        max_per_wallet = _max_per_wallet;
    }

    function setMax_per_txn(uint256 _max_per_txn) public onlyOwner {
        max_per_txn = _max_per_txn;
    }

    function setDecimals(uint256 _decimals) public onlyOwner {
        decimals = _decimals;
    }

    function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setPremintwallet(address _premintwallet) public onlyOwner {
        premintwallet = _premintwallet;
    }
    
    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setTokenContract(address _tokenContract) public onlyOwner{
    token = IERC20(_tokenContract);
    token_Contract = _tokenContract;
    }

    function setSectionPrice(uint256 sectionNumber, uint256 _price) public onlyOwner {
        sectionPrice[sectionNumber] = _price;
    }

    function setBulkSetPrice(uint256[] memory _price) public onlyOwner {
        for(uint256 x = 1; x <= 24; x++){
        sectionPrice[x] = _price[x-1];
        
        }
    }

}