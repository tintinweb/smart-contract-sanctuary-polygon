// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./base64.sol";

contract Astrobirdz is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter public tokenIds;

    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;
   
    address private _tokenAddress;

    string private _eggUri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/video_2022-04-15_14-40-52.mp4";

    // Rarity Classes
    enum Class {
    Common,
    Uncommon,
    Rare,
    Legendary
  }
  

    uint private _seed;

    
   uint8 private _burnPercent = 25;
    uint8 constant NUM_CLASSES = 4;
    // Starts From 0
    uint8 private constant UNIQUENFTS = 6;
   uint8 private _commonMatureAPY = 10;
   uint8 private _commonMaxMatureAPY = 15;
   uint8 private _unCommonMatureAPY = 15;
   uint8 private _unCommonMaxMatureAPY = 20;
   uint8 private _rareMatureAPY = 25;
   uint8 private _rareMaxMatureAPY = 30;
   uint8 private _legendaryMatureAPY = 50;
   uint8 private _legendaryMaxMatureAPY = 70;
   uint public commonMatureCost = 30000 * 10**18;
   uint public commonMaxMatureCost = 50000 * 10**18;
   uint public unCommonMatureCost = 50000 * 10**18;
   uint public unCommonMaxMatureCost = 70000 * 10**18;
   uint public rareMatureCost = 100000 * 10**18;
   uint public rareMaxMatureCost = 150000 * 10**18;
   uint public legendaryMatureCost = 150000 * 10**18;
   uint public legendaryMaxMatureCost = 200000 * 10**18;
   

    struct Attributes {
        string uniqueAttribute;
        uint8 speice;
        uint8 rarity;
        uint8 cannon;
        uint8 laser;
        uint8 bomb;
        uint8 shields;
        uint8 armour;
        uint8 health;
        //check if attributes are setted
        bool set;
    }

    struct EggHatch {
        uint hatchTime;
        bool hasAlreadyHatched;
        bool isHatching;
    }

    mapping(uint=>Attributes) private _tokenIdToAttributes;
    mapping(uint=>EggHatch) private _eggHatch;
    mapping(uint=>string) private _nftToUniqueAttr;
    

    // baby.mature,max mature bird level
    mapping(uint=>uint) public level;
    mapping(uint=>uint) private _rewardTime;

    event EggMinted(address indexed, uint indexed);
    event EggLocked(uint indexed, uint indexed);
    event EggRarity(uint indexed, uint indexed);
    event UpgradeMature(uint indexed, uint indexed);
    event UpgradeMaxMature(uint indexed, uint indexed);
    event Reward(uint indexed, uint indexed, uint indexed);

    constructor(address tokenAddress) ERC721("Astrobirdz", "ABZ") {
        _tokenAddress = tokenAddress;
    }

    function matureBirdCost(uint _tokenId) external view returns(uint) {
        require(ownerOf(_tokenId) == msg.sender, "not owner");
        require(level[_tokenId] == 1, "not baby bird, only baby bird can be upgraded");
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint8 rar = attr.rarity;
        uint cost;
        if(rar == 0) {
            cost = commonMatureCost;
        } else  if(rar == 1) {
            cost = unCommonMatureCost;
        } else  if(rar == 2) {
            cost = rareMatureCost;
        } else  if(rar == 3) {
            cost = legendaryMaxMatureCost;
        } 
        return cost;
    }

    function maxMatureBirdCost(uint _tokenId) external view returns(uint) {
        require(ownerOf(_tokenId) == msg.sender, "not owner");
        require(level[_tokenId] == 2, "not mature bird, only mature bird can be upgraded");
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint8 rar = attr.rarity;
        uint cost;
        if(rar == 0) {
            cost = commonMaxMatureCost;
        } else  if(rar == 1) {
            cost = unCommonMaxMatureCost;
        } else  if(rar == 2) {
            cost = rareMaxMatureCost;
        } else  if(rar == 3) {
            cost = legendaryMaxMatureCost;
        } 
        return cost;
    }

    function getRarity(uint _tokenId) external view returns(string memory) {
        require(ownerOf(_tokenId) == msg.sender, "Not Owner");
        require(level[_tokenId] > 0, "not hatched yet");
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint8 rar = attr.rarity;
        if(rar == 0) {
            return "Common";
        } else if(rar == 1) {
            return "UnCommon";
        } else if(rar == 2) {
            return "Rare";
        } else if(rar == 3) {
            return "Legendary";
        }
        return "Common";
    } 

    function changeCommonAPY(uint8 b, uint8 c) external onlyOwner {
        _commonMatureAPY = b;
        _commonMaxMatureAPY = c;   
    } 

    
    function changeUnCommonAPY(uint8 b, uint8 c) external onlyOwner {
        _unCommonMatureAPY = b;
        _unCommonMaxMatureAPY = c;   
    } 

    
    function changeRareAPY(uint8 b, uint8 c) external onlyOwner {
        _rareMatureAPY = b;
        _rareMaxMatureAPY = c;   
    } 

    
    function changeLegendaryAPY(uint8 b, uint8 c) external onlyOwner {
        _legendaryMatureAPY = b;
        _legendaryMaxMatureAPY = c;   
    } 

    function changeCost(uint a, uint b, uint c, uint d, uint e, uint f, uint g, uint h) external onlyOwner {
        commonMatureCost = a;
        commonMaxMatureCost = b;
        unCommonMatureCost = c;
        unCommonMaxMatureCost = d;
        rareMatureCost = e;
        rareMaxMatureCost = f;
        legendaryMatureCost = g;
        legendaryMaxMatureCost = h;
    }

     function setSeed(uint _s) external onlyOwner {
        _seed = _s;
    } 

    function changeTokenAddress(address _addr) external onlyOwner {
        _tokenAddress = _addr;
    }

    function mintEgg(uint tNumber)
        public
    {
        for(uint8 i = 0; i<tNumber; i++) {
             tokenIds.increment();

             uint256 newItemId = tokenIds.current();
            _mint(msg.sender, newItemId);

            level[newItemId] = 0;
        }
       emit EggMinted(msg.sender, tNumber);
    }


    function lockInIncubator(uint _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Not Owner");
        EggHatch memory eggHatch = _eggHatch[_tokenId];
        require(eggHatch.hasAlreadyHatched == false, "already hatched");

        eggHatch.isHatching = true;
        eggHatch.hasAlreadyHatched = true;
        eggHatch.hatchTime = block.timestamp + 1 weeks;
         _eggHatch[_tokenId] = eggHatch;
        emit EggLocked(_tokenId, eggHatch.hatchTime);
    }

    function hatchRemainingTime(uint _tokenId) public view returns(uint) {
        require(ownerOf(_tokenId) == msg.sender, "Not Owner");
         EggHatch memory eggHatch = _eggHatch[_tokenId];
         if(eggHatch.hatchTime <= block.timestamp) {
             return 0;
         }
         uint remainTime = eggHatch.hatchTime - block.timestamp;
         return remainTime;
    }

    function hatchEgg(uint _tokenId) public {
    require(ownerOf(_tokenId) == msg.sender, "Not Owner");
    EggHatch memory eggHatch = _eggHatch[_tokenId];
    require(eggHatch.isHatching == true, "Not Hatching");
    require(eggHatch.hatchTime <= block.timestamp,"Hatch Time Hasn't Passed Yet");
    
    eggHatch.isHatching = false;
    _eggHatch[_tokenId] = eggHatch;

    //Mature Bird
    level[_tokenId] = 1;

    Attributes memory _attr = selectRandomNftWithAttributes(_tokenId);
    _attr = selectAttrbiutes(_attr);
    _tokenIdToAttributes[_tokenId] = _attr;
    _rewardTime[_tokenId] = block.timestamp;
    emit EggRarity(_tokenId, _attr.rarity);
    }

    function selectRandomNftWithAttributes(uint _tokenId) internal returns(Attributes memory) {
        uint _rand = randomUniqueNft();
        Attributes memory _attr = _tokenIdToAttributes[_tokenId];
        if(_rand == 0) {
            _attr.uniqueAttribute = "Powerful Sharp Feet";
            _attr.speice = 0;
        } else if(_rand == 1) {
            _attr.uniqueAttribute = "Powerful Beak";
            _attr.speice = 1;
        } else if(_rand == 2) {
            _attr.uniqueAttribute = "Speed";
            _attr.speice = 2;
        } else if(_rand == 3) {
            _attr.uniqueAttribute = "Camoflauge";
            _attr.speice = 3;
        } else if(_rand == 4) {
            _attr.uniqueAttribute = "Strength";
            _attr.speice = 4;
        } else if(_rand == 5) {
            _attr.uniqueAttribute = "Intelligence";
            _attr.speice = 5;
        } 

        return _attr;
    }

     function randomUniqueNft() internal view returns (uint) {
        uint rand =  uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _seed)));
        return rand % UNIQUENFTS;
    }

    function randRarity(uint _randomNum, uint _num) internal view returns(uint8) {
         uint rand =  uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _seed, _randomNum))) % _num;
         return uint8(rand);
    }


    function randomNumProb() internal view returns(Class) {
        uint rand =  uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _seed))) % 100;
        uint[] memory _classProbabilities = new uint[](4);
        _classProbabilities[0] = 68;
        _classProbabilities[1] = 20;
        _classProbabilities[2] = 10;
        _classProbabilities[3] = 2;
        
         // Start at top class (length - 1)
        // skip common (0), we default to it
        for (uint i = _classProbabilities.length - 1; i > 0; i--) {
            uint probability = _classProbabilities[i];
            if(rand < probability) {
                return Class(i);
            } else {
                rand = rand - probability;
            }
        }

        return Class.Common; 
    }

    function selectAttrbiutes(Attributes memory attr) internal view returns(Attributes memory){
        Class _class = randomNumProb();
        
        
        if(_class == Class.Common) {
            
            attr.rarity = 0;
            attr.cannon = randRarity(230, 34);
            attr.laser = randRarity(10230, 34);
            attr.bomb = randRarity(12200, 34);
            attr.shields = randRarity(10560, 34);
            attr.armour = randRarity(10740, 34);
            attr.health = randRarity(10450, 34);
            attr.set = true;
            return attr;

        } else if(_class == Class.Uncommon) {
            
            attr.rarity = 1;
           attr.cannon = randRarity(230, 15) + 35;
            attr.laser = randRarity(10230, 15) + 35;
            attr.bomb = randRarity(12200, 15) + 35;
            attr.shields = randRarity(10560, 15) + 35;
            attr.armour = randRarity(10740, 15) + 35;
            attr.health = randRarity(10450, 15) + 35;
            attr.set = true;
            return attr;

        } else if(_class == Class.Rare) {

            attr.rarity = 2;
            attr.cannon = randRarity(230, 25) + 50;
            attr.laser = randRarity(10230, 25) + 50;
            attr.bomb = randRarity(12200, 25) + 50;
            attr.shields = randRarity(10560, 25) + 50;
            attr.armour = randRarity(10740, 25) + 50;
            attr.health = randRarity(10450, 25) + 50;
            attr.set = true;
            return attr;

        } else if(_class == Class.Legendary) {

            attr.rarity = 3;
            attr.cannon = randRarity(230, 25) + 75;
            attr.laser = randRarity(10230, 25) + 75;
            attr.bomb = randRarity(12200, 25) + 75;
            attr.shields = randRarity(10560, 25) + 75;
            attr.armour = randRarity(10740, 25) + 75;
            attr.health = randRarity(10450, 25) + 75;
            attr.set = true;
            return attr;

        }

    }

    function upgradeToMatureBird(uint _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "not owner");
        require(level[_tokenId] == 1, "not baby bird, only baby bird can be upgraded");
        IERC20 token = IERC20(_tokenAddress);
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint8 rar = attr.rarity;
        uint cost;
        if(rar == 0) {
            cost = commonMatureCost;
        } else  if(rar == 1) {
            cost = unCommonMatureCost;
        } else  if(rar == 2) {
            cost = rareMatureCost;
        } else  if(rar == 3) {
            cost = legendaryMaxMatureCost;
        } 
        uint balance = token.balanceOf(msg.sender);
        require(balance >= cost, "low balance");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= cost, "Check the token allowance");
        uint burnAmount = cost.mul(_burnPercent).div(100);
        token.transferFrom(msg.sender, address(this), cost);
        token.transfer(_burnAddress, burnAmount);
        level[_tokenId] = 2;
        emit UpgradeMature(_tokenId, cost);
    }

    function upgradeToMaxMatureBird(uint _tokenId) external {
         require(ownerOf(_tokenId) == msg.sender, "not owner");
        require(level[_tokenId] == 2, "not mature bird, only mature bird can be upgraded");
        IERC20 token = IERC20(_tokenAddress);
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint8 rar = attr.rarity;
        uint cost;
        if(rar == 0) {
            cost = commonMaxMatureCost;
        } else  if(rar == 1) {
            cost = unCommonMaxMatureCost;
        } else  if(rar == 2) {
            cost = rareMaxMatureCost;
        } else  if(rar == 3) {
            cost = legendaryMaxMatureCost;
        } 
        uint balance = token.balanceOf(msg.sender);
        require(balance >= cost, "low balance");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= cost, "Check the token allowance");
        uint burnAmount = cost.mul(_burnPercent).div(100);
        uint remainingTokens = cost - burnAmount;
        token.transferFrom(msg.sender, address(this), remainingTokens);
        token.transfer(_burnAddress, burnAmount);
        level[_tokenId] = 3;
        emit UpgradeMaxMature(_tokenId, cost);
    }


    function withdrawReward(uint _tokenId) external returns(uint) {
        require(ownerOf(_tokenId) == msg.sender, "not Owner");
        require(level[_tokenId] > 0, "Please incubate and hatch the egg first");
        Attributes memory attr = _tokenIdToAttributes[_tokenId];
        uint per;
        if(attr.rarity == 0) {
            if(level[_tokenId] == 2) {
                per = _commonMatureAPY;
            } else if(level[_tokenId] == 3) {
                per = _commonMaxMatureAPY;
            }
        } else if(attr.rarity == 1) {
           if(level[_tokenId] == 2) {
                per = _unCommonMatureAPY;
            } else if(level[_tokenId] == 3) {
                per = _unCommonMaxMatureAPY;
            }
        } else if(attr.rarity == 2) {
             if(level[_tokenId] == 2) {
                per = _rareMatureAPY;
            } else if(level[_tokenId] == 3) {
                per = _rareMaxMatureAPY;
            }
        } else if(attr.rarity == 3) {
            if(level[_tokenId] == 2) {
                per = _legendaryMatureAPY;
            } else if(level[_tokenId] == 3) {
                per = _legendaryMaxMatureAPY;
            }
        }
        per = per * 1000000000;
        uint perInSec = per / 31536000;
        uint bal = IERC20(_tokenAddress).balanceOf(address(this));
        bal = bal.div(1000000000);
        uint r =  bal.mul(perInSec).div(100);
        uint t = (block.timestamp).sub(_rewardTime[_tokenId]);
        r = r.mul(t);
        _rewardTime[_tokenId] = block.timestamp;
        IERC20(_tokenAddress).transfer(msg.sender, r);
        emit Reward(_tokenId, t, r);
        return r;
    }

     function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

   

     function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
         if(_tokenIdToAttributes[tokenId].set == false) {
             string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', uint2str(tokenId), '",',
                    '"image_data": "', _eggUri, '",',
                    '"description": "', 'An Egg"',
                    '}'   
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
        }

         string memory uri = "";

         if(level[tokenId] == 1) {
             if(_tokenIdToAttributes[tokenId].speice == 0) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/baby-eagle-complete.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 1) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Baby%20-%20Cockatiel.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 2) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Baby%20-%20Sparrow.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 3) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Baby%20-%20Cardinal.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 4) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Baby%20-%20Vulture.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 5) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Baby%20-%20Swan.mp4";
             }
         } else if(level[tokenId] == 2) {
              if(_tokenIdToAttributes[tokenId].speice == 0) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Golden%20Eagle.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 1) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Cockateil.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 2) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Sparrow.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 3) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Cardinal.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 4) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Vulture.mp4";
             } else if(_tokenIdToAttributes[tokenId].speice == 5) {
                 uri = "https://gateway.pinata.cloud/ipfs/QmVWCtAxaRVktazv4JddXMhMZYAUNRWrvZoDGQhmuy64Hp/Adult%20-%20Swan.mp4";
             }
         }

         string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', uint2str(tokenId), '",',
                    '"image_data": "', uri, '",',
                    // '"description": "', 'Bird"', ',',
                    '"attributes": [{"trait_type": "Cannon", "value": "', uint2str(_tokenIdToAttributes[tokenId].cannon), '"},',
                    '{"trait_type": "Attribute", "value": "', _tokenIdToAttributes[tokenId].uniqueAttribute, '"},',
                    '{"trait_type": "Laser", "value": "', uint2str(_tokenIdToAttributes[tokenId].laser), '"},',
                    '{"trait_type": "Bomb", "value": "', uint2str(_tokenIdToAttributes[tokenId].bomb), '"},',
                    '{"trait_type": "Shields", "value": "', uint2str(_tokenIdToAttributes[tokenId].shields), '"},',
                    '{"trait_type": "Armour", "value": "', uint2str(_tokenIdToAttributes[tokenId].armour), '"},',
                    '{"trait_type": "Health", "value": "', uint2str(_tokenIdToAttributes[tokenId].health), '"}',
                    ']}'
                    
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
     }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
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

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}