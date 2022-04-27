// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// This is an NFT for H4NDS https://twitter.com/?
// Smart contract developed by Ian Cherkowski https://twitter.com/IanCherkowski
// Thanks to chiru-labs for their gas friendly ERC721A implementation.
//

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

contract H4NDS is
    ERC721A,
    ReentrancyGuard,
    Ownable,
    ERC2981
{
    event PaymentReceived(address from, uint256 amount);

    string private constant _name = "H4NDS";
    string private constant _symbol = "H4NDS";
    string public baseURI = "https://ipfs.io/ipfs/Qma312xt4FhvCYA2zwV8ot72GQJzPyfE5Yit9P54beyPEc/";
    uint256 public maxMint = 20;
    uint256 public maxPresale = 3;
    uint256 public mainCost = 0.12 ether;
    uint256 public preCost = 0.08 ether;
    uint256 public maxGift = 200;
    uint256 public maxSupply = 4444;
    uint256 public presaleStart = 14967074; // 6/12/22 9:40 AM PST
    uint256 public mainStart = 14977074; // 6/13/22 10:37 PM PST https://etherscan.io/block/countdown/14967074
    uint256 public presaleCount;
    uint256 public presaleLimit = 2222;
    uint256 public commission = 15;
    bool public freezeURI = false;
	bool public mintPause = false;
	mapping(address => uint256) public presaleList;
    mapping(address => bool) public affiliateList;
    bytes32 public whitelistMerkleRoot;

    constructor() ERC721A(_name, _symbol) payable {
        _setDefaultRoyalty(address(this), 500);
    }

    // @dev needed to enable receiving to test withdrawls
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

	// @dev owner can mint to a list of addresses with the quantity entered
	function gift(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 numTokens = 0;
        uint256 i;
        
        require(recipients.length == amounts.length, "H4NDS: The number of addresses is not matching the number of amounts");

        //find total to be minted
        for (i = 0; i < recipients.length; i++) {
            require(Address.isContract(recipients[i]) == false, "H4NDS: no contracts");
            numTokens += amounts[i];
        }

        require(totalSupply() + numTokens <= maxSupply, "H4NDS: Can't mint more than the max supply");
        require(totalSupply() + numTokens <= maxGift, "H4NDS: Can't mint more than the max gift");

        //mint to the list
        for (i = 0; i < amounts.length; i++) {
            _safeMint(recipients[i], amounts[i]);
        }
	}

    // @dev public minting, accepts affiliate address
	function mint(uint256 _mintAmount, address affiliate, bytes32[] calldata merkleProof) external payable nonReentrant {
        uint256 supply = totalSupply();

        require(Address.isContract(msg.sender) == false, "H4NDS: no contracts");
        require(!mintPause, "H4NDS: Minting paused");
        require(block.number > presaleStart, "H4NDS: Minting not started yet");
        require(_mintAmount > 0, "H4NDS: Cant mint 0");
        require(_mintAmount <= maxMint, "H4NDS: Must mint less than the max");
        require(supply + _mintAmount <= maxSupply, "H4NDS: Cant mint more than max supply");
        require(msg.value >= cost() * _mintAmount, "H4NDS: Must send eth of cost per nft");

        if (block.number < mainStart) {
            require(supply + _mintAmount <= presaleLimit, "H4NDS: Cant mint more than presale supply");
            require(isValidMerkleProof(merkleProof), "H4NDS: Not in presale list");

            require(presaleList[msg.sender] + _mintAmount <= maxPresale, "H4NDS: Exceeds presale limit");
            presaleList[msg.sender] += _mintAmount;
        }

        _safeMint(msg.sender, _mintAmount);

        //if address is owner then no payout
        if (affiliate != owner() && commission > 0) {
            //if only recorded affiliates can receive payout
            if (affiliateList[affiliate]) {
                //pay out the affiliate
                Address.sendValue(payable(affiliate), msg.value * _mintAmount * commission / 100);
            }
        }
	}

    function isValidMerkleProof(bytes32[] calldata merkleProof) public view returns (bool) {
        return MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    // @dev record affiliate address
	function allowAffiliate(address newAffiliate, bool allow) external onlyOwner {
        require(Address.isContract(newAffiliate) == false, "H4NDS: no contracts");
        affiliateList[newAffiliate] = allow;
	}

    // @dev set commission amount in percentage
 	function setCommission(uint256 _newCommission) external onlyOwner {
        require(_newCommission < 100, "H4NDS: must be percentage");
    	commission = _newCommission;
	}

	// @dev record addresses of presale list
	function presaleSet(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
        uint256 previous;


        require(_addresses.length == _amounts.length,
            "H4NDS: The number of addresses is not matching the number of amounts");

        for(uint256 i; i < _addresses.length; i++) {
            require(Address.isContract(_addresses[i]) == false, "H4NDS: no contracts");
            require(_amounts[i] <= maxMint, "H4NDS: Max per wallet");

            previous = presaleList[_addresses[i]];
            presaleList[_addresses[i]] = _amounts[i];
            presaleCount = presaleCount + _amounts[i] - previous;
        }
	}

    function cost() public view returns (uint256) {
        uint256 _cost;
        if (block.number < mainStart) {
            _cost = preCost;
        } else {
            _cost = mainCost;
        }
        return _cost;
    }

    // @dev set cost of minting
	function setMainCost(uint256 _newCost) external onlyOwner {
    	mainCost = _newCost;
	}
		
    // @dev set presale cost of minting
	function setPreCost(uint256 _newCost) external onlyOwner {
    	preCost = _newCost;
	}
		
    // @dev set presale cost of minting
	function setPresaleLimit(uint256 _new) external onlyOwner {
    	presaleLimit = _new;
	}

    // @dev max mint amount per transaction
    function setMaxPresale(uint256 _newMaxMintAmount) external onlyOwner {
	    maxPresale = _newMaxMintAmount;
	}

    // @dev max mint amount per transaction
    function setMaxMint(uint256 _newMaxMintAmount) external onlyOwner {
	    maxMint = _newMaxMintAmount;
	}

    // @dev max mint amount per transaction
    function setMaxGift(uint256 _newMax) external onlyOwner {
	    maxGift = _newMax;
	}

    // @dev unpause main minting stage
	function setMintPause(bool _status) external onlyOwner {
    	mintPause = _status;
	}
	
    // @dev main minting start block
	function setMainStart(uint256 _start) external onlyOwner {
        require(presaleStart < _start, "H4NDS: main must start after presale");
    	mainStart = _start;
	}
	
    // @dev presale start block
	function setPresaleStart(uint256 _start) external onlyOwner {
    	presaleStart = _start;
	}

    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        require(freezeURI == false, "H4NDS: uri is frozen");
        baseURI = _baseTokenURI;
    }

    // @dev freeze the URI
    function setFreezeURI() external onlyOwner {
        freezeURI = true;
    }

    // @dev show the baseuri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev used to reduce the max supply instead of a burn
    function reduceMaxSupply(uint256 newMax) external onlyOwner {
        require(newMax < maxSupply, "H4NDS: New maximum must be less than existing maximum");
        require(newMax >= totalSupply(), "H4NDS: New maximum can't be less than minted count");
        maxSupply = newMax;
    }

    /**
     * @dev External onlyOwner version of {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // @dev used to withdraw erc20 tokens like DAI
    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    // @dev used to withdraw eth
    function withdraw(address payable to) external onlyOwner {
        Address.sendValue(to,address(this).balance);
    }
}