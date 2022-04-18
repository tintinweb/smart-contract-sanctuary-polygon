// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/ERC1155Tradable.sol";
import "./NftPacks.sol";
import "./LpStaking.sol";
import "./Vault.sol";
import "./interfaces/IERC20Minter.sol";

contract NftStore is Ownable, IERC1155Receiver, ReentrancyGuard {

    using SafeMath for uint256;

    ERC1155Tradable private nft;
    NftPacks private nftPacks;

    LpStaking private lpStakingContract;
    IERC20Minter private primaryToken;

    address payable private fundAddress;
    address public constant burnAddress = address(0xdead);
    bool public distributionActive; 
    bool public storeActive;

    Vault public vault;
    uint256 public vaultPercent;

    uint256 public totalPurchasedAmount;
    uint256 public totalBurnAmount;
    uint256 public totalCardsRedeemed;
    uint256 public totalPacksRedeemed;
    mapping(address => uint256) public totalExtraPurchasedAmount;


    uint256 public riskMod = 1 ether;

    // required seconds between purchases
    uint256 public purchaseCoolDown;

    // Migration vars 
    mapping(address => bool) public hasMigrated;

    // mapping of which users have claimed a level NFT
    mapping(address => mapping(uint256 => uint256)) public claimedLevels;   

    struct ItemInfo {
        uint256 id; //pack/card id
        uint256 nativePrice; // cost in Native Token/ETH etc.
        uint256 burnCost; // primary token burn cost
        uint256 distributionAmount;  // amount of primary token to distribute when active
        IERC20 extraToken; // erc20/beb20 token address, can be set by itself or with the
        uint256 extraPrice; // the amount of the erc20 passed in to charge
        uint256 maxRedeem;  // max that can be redeemed
        uint256 totalRedeemed;// total redeemed 
        bool isActive; // flag to check if the item is still active
        uint256 maxPerAddress; //max one address can get
        uint256 tierLimit; //limit to only this tier and above
        bool useWhitelist; // if true only addresses whitelisted for this item can redeem
        // uint256 gameLevelLimit; //limit to only this game level and above
    }


    mapping(address => uint256) public totalUserCards;
    mapping(address => uint256) public totalUserPacks;
    mapping(address => uint256) public lastPurchase;

    // keep track of cards and packs per address
    mapping(address => mapping(uint256 => uint256)) public userTotalByCard;
    mapping(address => mapping(uint256 => uint256)) public userTotalByPack;
    
    mapping(uint256 => ItemInfo) public cards;
    mapping(uint256 => ItemInfo) public packs;
    mapping(uint256 => mapping(address => bool)) private packsWhitelist;
    mapping(uint256 => mapping(address => bool)) private cardsWhitelist;


    event CardSet(uint256 card, uint256 amount, uint256 burn, uint256 distributionAmount, uint256 max);
    event PackSet(uint256 card, uint256 amount, uint256 burn, uint256 distributionAmounts, uint256 max);
    event CardRedeemed(address indexed user, uint256 amount, uint256 burn, uint256 distributionAmount);
    event PackRedeemed(address indexed user, uint256 amount, uint256 burn, uint256 distributionAmount);
    event LevelRewardClaimed(address indexed user, uint256 level, uint256 nftId);
    event SetLevelNfts(address indexed user, uint256 level, uint256[]  nftIds);
    event SetCardPackContract(address indexed user, NftPacks contractAddress);
    event SetTheLpStakingContract(address indexed user, LpStaking contractAddress);
    event SetFundAddress(address indexed user, address fundAddress);

    constructor(
        ERC1155Tradable _nftAddress, 
        NftPacks _nftPacksAddress, 
        IERC20Minter _tokenAddress,
        address payable _fundAddress, 
        LpStaking _lpStakingContract,
        Vault _vault,
        uint256 _vaultPercent
    ) {
        require(_fundAddress != address(0), 'bad address');

        nft = _nftAddress;
        nftPacks = _nftPacksAddress;
        primaryToken = _tokenAddress;
        lpStakingContract = _lpStakingContract;
        fundAddress = _fundAddress;
        vault = _vault;
        vaultPercent = _vaultPercent;
    }

    /**
     * @dev set this flag to enable/disable globally minting primary tokens 
     */
    function setDistributionActive(bool _isActive) public onlyOwner {
        distributionActive = _isActive;
    }

    function setPurchaseCoolDown(uint256 _purchaseCoolDown) public onlyOwner {
        purchaseCoolDown = _purchaseCoolDown;
    }

    /**
     * @dev Add or update a card
     */
    function setCard(uint256 _nftId, uint256 _amountBnb, uint256 _amountBurn, uint256 _amountRewards, uint256 _maxRedeem, uint256 _maxPerAddress, uint256 _tierLimit) public onlyOwner {
        cards[_nftId].id = _nftId;
        cards[_nftId].nativePrice = _amountBnb;
        cards[_nftId].burnCost = _amountBurn;
        cards[_nftId].distributionAmount = _amountRewards;
        cards[_nftId].maxRedeem = _maxRedeem;
        cards[_nftId].isActive = true;
        cards[_nftId].maxPerAddress = _maxPerAddress;
        cards[_nftId].tierLimit = _tierLimit;

        emit CardSet(_nftId, _amountBnb, _amountBurn, _amountRewards, _maxRedeem);
    }

    /**
     * @dev Add or update a pacl
     */
    function setPack(uint256 _packId, uint256 _amountBnb, uint256 _amountBurn, uint256 _amountRewards, uint256 _maxRedeem, uint256 _maxPerAddress, uint256 _tierLimit) public onlyOwner {
        packs[_packId].id = _packId;
        packs[_packId].nativePrice = _amountBnb;
        packs[_packId].burnCost = _amountBurn;
        packs[_packId].distributionAmount = _amountRewards;
        packs[_packId].maxRedeem = _maxRedeem;
        packs[_packId].isActive = true;
        packs[_packId].maxPerAddress = _maxPerAddress;
        packs[_packId].tierLimit = _tierLimit;

        emit PackSet(_packId, _amountBnb, _amountBurn, _amountBurn, _maxRedeem);
    }

    function setCardActive(uint256 _nftId, bool _isActive) public onlyOwner {
        cards[_nftId].isActive = _isActive;
    }

    function setPackActive(uint256 _packId, bool _isActive) public onlyOwner {
        packs[_packId].isActive = _isActive;
    }


    function bulkAddCardWhitelist(uint256 _nftId, address[] calldata _wlAddresses) public onlyOwner {
        for (uint256 i = 0; i < _wlAddresses.length; ++i) {
            _addCardWhitelist(_nftId, _wlAddresses[i]);
        }
    }

    function bulkRemoveCardWhitelist(uint256 _nftId, address[] calldata _wlAddresses) public onlyOwner {
        for (uint256 i = 0; i < _wlAddresses.length; ++i) {
            _removeCardWhitelist(_nftId, _wlAddresses[i]);
        }
    }

    function addCardWhitelist(uint256 _nftId, address _user) public onlyOwner {
        _addCardWhitelist(_nftId, _user);
    }

    function removeCardWhitelist(uint256 _nftId, address _user) public onlyOwner {
        _removeCardWhitelist(_nftId, _user);
    }

    function isWhitelistedCard(uint256 _nftId, address _user) public view returns(bool) {
        return cardsWhitelist[_nftId][_user];
    }

    function _addCardWhitelist(uint256 _nftId, address _user) private {
        cardsWhitelist[_nftId][_user] = true;
    }

    function _removeCardWhitelist(uint256 _nftId, address _user) private {
        cardsWhitelist[_nftId][_user] = false;
    }



    function bulkAddPackWhitelist(uint256 _packId, address[] calldata _wlAddresses) public onlyOwner {
        for (uint256 i = 0; i < _wlAddresses.length; ++i) {
            _addPackWhitelist(_packId, _wlAddresses[i]);
        }
    }

    function bulkRemovePackWhitelist(uint256 _packId, address[] calldata _wlAddresses) public onlyOwner {
        for (uint256 i = 0; i < _wlAddresses.length; ++i) {
            _removePackWhitelist(_packId, _wlAddresses[i]);
        }
    }

    function addPackWhitelist(uint256 _packId, address _user) private {
        _addPackWhitelist(_packId, _user);
    }

    function removePackWhitelist(uint256 _packId, address _user) private {
        _removePackWhitelist(_packId, _user);
    }

    function isWhitelisted(uint256 _packId, address _user) public view returns(bool) {
        return packsWhitelist[_packId][_user];
    }

    function _addPackWhitelist(uint256 _packId, address _user) private {
        packsWhitelist[_packId][_user] = true;
    }

    function _removePackWhitelist(uint256 _packId, address _user) private {
        packsWhitelist[_packId][_user] = false;
    }

    function redeemCard(uint256 _nftId) public payable nonReentrant {
        
        bool burnSuccess = false;
        require(storeActive && cards[_nftId].isActive && cards[_nftId].id != 0, "Card not found");
        // require(, "Card Inactive");
        require(purchaseCoolDown == 0 || block.timestamp >= lastPurchase[msg.sender].add(purchaseCoolDown), "Purchase Cooldown Active");

        uint256 burnCost = cards[_nftId].burnCost.mul(riskMod).div(1 ether);

        uint256 userTier;
        if(address(lpStakingContract) != address(0)) {
            userTier = lpStakingContract.getUserLevel(msg.sender);
        }

        require(( cards[_nftId].maxRedeem == 0 || cards[_nftId].totalRedeemed < cards[_nftId].maxRedeem) && ( cards[_nftId].maxPerAddress == 0 || userTotalByCard[msg.sender][_nftId] < cards[_nftId].maxPerAddress), "Max cards Redeemed");
        require(userTier >= cards[_nftId].tierLimit, "Tier too low");
        require(msg.value >=  cards[_nftId].nativePrice, "Not enough Native Token to redeem for card");
        require(primaryToken.balanceOf(msg.sender) >=  burnCost, "Not enough primary tokens to burn to redeem card");
        require(cards[_nftId].extraPrice == 0 || cards[_nftId].extraToken.balanceOf(msg.sender) >=  cards[_nftId].extraPrice, "Not enough secondary token to spend for card");


        require(nft.totalSupply(_nftId) < nft.maxSupply(_nftId), "Max cards minted");

//        _checkMigrate(msg.sender);
         // if we are taking Native Token transfer it
        if(cards[_nftId].nativePrice> 0){
            totalPurchasedAmount = totalPurchasedAmount.add(cards[_nftId].nativePrice);

            // send 20% to the vault
            uint256 toVault = msg.value.mul(vaultPercent).div(100);
            (bool sent,) = payable(address(vault)).call{value: toVault}("");
            require(sent, "Failed to send");
            // payable(address(vault)).transfer(toVault);
            // the rest to the dev
            fundAddress.transfer(msg.value.sub(toVault));
        }

        // if we are taking a secondary Token transfer it
        if(cards[_nftId].extraPrice > 0){
            totalExtraPurchasedAmount[address(cards[_nftId].extraToken)] = totalExtraPurchasedAmount[address(cards[_nftId].extraToken)].add(cards[_nftId].extraPrice);
            
            bool extraSuccess = cards[_nftId].extraToken.transferFrom(msg.sender, fundAddress, cards[_nftId].extraPrice);
             require(extraSuccess, "token: Send failed");
        }

        // if we need to burn burn it
        if(cards[_nftId].burnCost > 0){
           
             totalBurnAmount = totalBurnAmount.add(burnCost);
             burnSuccess = primaryToken.transferFrom(msg.sender, burnAddress, burnCost);
             require(burnSuccess, "primary tokens: Burn failed");
             //give them shares
             vault.giveShares(msg.sender, burnCost);

        }

        // stats
        cards[_nftId].totalRedeemed = cards[_nftId].totalRedeemed.add(1);
        totalCardsRedeemed = totalCardsRedeemed.add(1);
        userTotalByCard[msg.sender][_nftId] = userTotalByCard[msg.sender][_nftId].add(1);
        totalUserCards[msg.sender] = totalUserCards[msg.sender].add(1);
        lastPurchase[msg.sender] = block.timestamp;

        // if we're in distributeion send out the token to the address that redeemend the card
        if(distributionActive && cards[_nftId].distributionAmount > 0){
            primaryToken.mint(msg.sender, cards[_nftId].distributionAmount);
        }

        // @dev degenr nft contract doesn't support the to addres msg.sender,
        // this is ok here since we're minting to msg.sender anyways
        //nft.mint( _nftId, 1, "0x0");
        nft.mint(_nftId, 1, "0x0");
        nft.safeTransferFrom(address(this), msg.sender, _nftId, 1, "0x0");
      //  nft.mint(msg.sender, _nftId, 1, "0x0");
        emit CardRedeemed(msg.sender, cards[_nftId].nativePrice, cards[_nftId].burnCost,cards[_nftId].distributionAmount);
    }

    function redeemPack(uint256 _packId) public payable nonReentrant{
        bool burnSuccess = false;

        require(packs[_packId].id != 0, "Pack not found");
        require(storeActive && packs[_packId].isActive, "Pack Inactive");
        require(purchaseCoolDown == 0 || block.timestamp >= lastPurchase[msg.sender].add(purchaseCoolDown), "Purchase Cooldown Active");
        require(!packs[_packId].useWhitelist || packsWhitelist[_packId][msg.sender], "Not on the Whitelist");

        uint256 burnCost =  packs[_packId].burnCost.mul(riskMod).div(1 ether);  
        
        uint256 userTier;
        if(address(lpStakingContract) != address(0)) {
            userTier = lpStakingContract.getUserLevel(msg.sender);
        }

        require(
            ( packs[_packId].maxRedeem == 0 || packs[_packId].totalRedeemed < packs[_packId].maxRedeem) && 
            ( packs[_packId].maxPerAddress == 0 || userTotalByPack[msg.sender][_packId] < packs[_packId].maxPerAddress), 
        "Max packs Redeemed"
        );

        require(userTier >= packs[_packId].tierLimit, "Tier too low");
        require(msg.value >=  packs[_packId].nativePrice, "Not enough Native Token to redeem pack");
        require(primaryToken.balanceOf(msg.sender) >=  burnCost, "Not enough primary tokens to burn for pack");
        require(packs[_packId].extraPrice == 0 || packs[_packId].extraToken.balanceOf(msg.sender) >=  packs[_packId].extraPrice, "Not enough seondairy tokens to spend for pack");


//        _checkMigrate(msg.sender);

        // if we are taking Native Token transfer it
        if(packs[_packId].nativePrice > 0){
            totalPurchasedAmount = totalPurchasedAmount.add(packs[_packId].nativePrice);
            
            // send 20% to the vault
            uint256 toVault = msg.value.mul(vaultPercent).div(100);
            (bool sent, ) = payable(address(vault)).call{value: toVault}("");
            require(sent, "Failed to send");
            // payable(address(vault)).transfer(toVault);
            // the rest to the dev
            fundAddress.transfer(msg.value.sub(toVault));
        }

        // if we are taking a secondary Token transfer it
        if(packs[_packId].extraPrice > 0){
            totalExtraPurchasedAmount[address(packs[_packId].extraToken)] = totalExtraPurchasedAmount[address(packs[_packId].extraToken)].add(packs[_packId].extraPrice);
            
            bool extraSuccess = packs[_packId].extraToken.transferFrom(msg.sender, fundAddress, packs[_packId].extraPrice);
             require(extraSuccess, "token: Send failed");
        }

        // if we need to burn burn it
        if(packs[_packId].burnCost > 0){
           
             totalBurnAmount = totalBurnAmount.add(burnCost);
             burnSuccess = primaryToken.transferFrom(msg.sender, burnAddress, burnCost);
             require(burnSuccess, "primary tokens: Burn failed");
             vault.giveShares(msg.sender, burnCost);
        }
        
        // stats
        packs[_packId].totalRedeemed = packs[_packId].totalRedeemed.add(1);
        totalPacksRedeemed = totalPacksRedeemed.add(1);
        userTotalByPack[msg.sender][_packId] = userTotalByPack[msg.sender][_packId].add(1);
        totalUserPacks[msg.sender] = totalUserPacks[msg.sender].add(1);
        lastPurchase[msg.sender] = block.timestamp;

        // if we're in distributeion send out the token to the address that redeemend the pack
        if(distributionActive && packs[_packId].distributionAmount  > 0){
            primaryToken.mint(msg.sender, packs[_packId].distributionAmount );
        }

        //send them the pack
         nftPacks.open(
          _packId,
          msg.sender,
          1
        );

        emit PackRedeemed(msg.sender, packs[_packId].nativePrice, packs[_packId].burnCost, packs[_packId].distributionAmount);
    }

     /**
     * @dev Update the Mnop token address only callable by the owner
     */
    function setPrimaryTokenContract(IERC20Minter _primaryToken) public onlyOwner {
        primaryToken = _primaryToken;
       // emit SetMnopTokenContract(msg.sender, _primaryToken);
    }

    /**
     * @dev Update the card pack NFT contract address only callable by the owner
     */
    function setNftPacksContract(NftPacks _nftPacks) public onlyOwner {
        nftPacks = _nftPacks;
        emit SetCardPackContract(msg.sender, _nftPacks);
    }

    /**
     * @dev Update the card NFT contract address only callable by the owner
     */
   function setCardContract(ERC1155Tradable _nftAddress) public onlyOwner {
        nft = _nftAddress;
        // emit SetCardContract(msg.sender, _nftAddress);
    }

     /**
     * @dev Update the LP Staking contract address only callable by the owner
     */
    function setTheLpStakingContract(LpStaking _lpStakingContract) public onlyOwner {
        lpStakingContract = _lpStakingContract;
        emit SetTheLpStakingContract(msg.sender, _lpStakingContract);
    }

     /**
     * @dev Update the address Native Token gets sent too only callable by the owner
     */
    function setFundAddress(address payable _fundAddress) public onlyOwner {
        require(_fundAddress != address(0), 'bad address');
        fundAddress = _fundAddress;
        emit SetFundAddress(msg.sender, _fundAddress);
    }

    function setVault(Vault _vault, uint256 _vaultPercent) public onlyOwner {
        vault = _vault;
        vaultPercent = _vaultPercent;
    }

     /**
     * @dev Update the risk mod to scale token prices
     */
    function setRiskMod(uint256 _riskMod) public onlyOwner {
        riskMod = _riskMod;
    }

    /**
     * @dev Global flag to enable/disable the store
     */
    function setStoreActive(bool _storeActive) public onlyOwner {
        storeActive = _storeActive;
    }


    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
      return 0xf23a6e61;
    }


    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
      return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
      return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
      interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11; 

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import './ProxyRegistry.sol';
import './Concat.sol';

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address,
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155, Ownable, AccessControl {
    using SafeMath for uint256;
    using Strings for string;

//    address proxyRegistryAddress;
    uint256 private _currentTokenID = 0;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => uint256) public tokenInitialMaxSupply;

    address public constant burnWallet = address(0xdead);
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
//        address _proxyRegistryAddress
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
//        proxyRegistryAddress = _proxyRegistryAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

    }

    function uri(uint256 _id) public override view returns (string memory) {
        require(_exists(_id), "erc721tradable#uri: NONEXISTENT_TOKEN");
        string memory _uri = super.uri(_id);
        return Concat.strConcat(_uri, Strings.toString(_id));
    }


    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
        // return tokenMaxSupply[_id];
    }

    function initialMaxSupply(uint256 _id) public view returns (uint256) {
        return tokenInitialMaxSupply[_id];
        // return tokenMaxSupply[_id];
    }

    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    ) external returns (uint256 tokenId) {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(_initialSupply <= _maxSupply, "initial supply cannot be more than max supply");
        
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

         if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
      
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        tokenInitialMaxSupply[_id] = _maxSupply;
        return _id;
    }

    function mint(
//        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        
        uint256 newSupply = tokenSupply[_id].add(_quantity);
        require(newSupply <= tokenMaxSupply[_id], "max NFT supply reached");
        // _mint(_to, _id, _quantity, _data);
        _mint(msg.sender, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    /**
        * @dev Mint tokens for each id in _ids
        * @param _to          The address to mint tokens to
        * @param _ids         Array of ids to mint
        * @param _quantities  Array of amounts of tokens to mint per id
        * @param _data        Data to pass if receiver is contract
    */
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");

        for (uint256 i = 0; i < _ids.length; i++) {
          uint256 _id = _ids[i];
          uint256 quantity = _quantities[i];
          uint256 newSupply = tokenSupply[_id].add(quantity);
          require(newSupply <= tokenMaxSupply[_id], "max NFT supply reached");
          
          tokenSupply[_id] = tokenSupply[_id].add(quantity);
        }
        _mintBatch(_to, _ids, _quantities, _data);
    }

    function burn(
        address _address, 
        uint256 _id, 
        uint256 _amount
    ) external virtual {
        require((msg.sender == _address) || isApprovedForAll(_address, msg.sender), "ERC1155#burn: INVALID_OPERATOR");
        require(balanceOf(_address,_id) >= _amount, "Trying to burn more tokens than you own");

        // _burnAndReduce(_address,_id,_amount);
        _burn(_address, _id, _amount);
    }
/*
    function _burnAndReduce(
        address _address, 
        uint256 _id, 
        uint256 _amount
    ) internal {
        // reduce the total supply
        tokenMaxSupply[_id] = tokenMaxSupply[_id].sub(_amount);
        _burn(_address, _id, _amount);
    }
*/
    /* dev Check if we are sending to the burn address and burn and reduce supply instead */ 
  /*  function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator,from,to,ids,amounts,data);

        // check if to is the burn address and burn tokens
        if(to == burnWallet){
            for(uint256 i = 0; i <= ids.length; ++i){
                require(balanceOf(from,ids[i]) >= amounts[i], "Trying to burn more tokens than you own");
                _burnAndReduce(from,ids[i],amounts[i]);
            }
        }
    }
    */
    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings - The Beano of NFTs
     */
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
/*        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
*/
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }

     /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) public view virtual override(AccessControl,ERC1155) returns (bool) {
        return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
        interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Concat {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Minter is IERC20 {
  function mint(
    address recipient,
    uint256 amount
  )
    external;

  function burn(
    address account,
    uint256 amount
  )
    external;
}

// SPDX-License-Identifier: MIT
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/ERC1155Tradable.sol";
import "./libs/PancakeLibs.sol";

/**
 * @title BlacklistAddress
 * @dev Manage the blacklist and add a modifier to prevent blacklisted addresses from taking action
 */
contract Vault is Ownable, ReentrancyGuard, IERC1155Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // global flag to set staking and depositing active
    bool public isActive;

    bool lpEnabled;
    // nft contract 
    ERC1155Tradable public nftContract;

    // total points to allocate rewards 
    uint256 public totalSharePoints;

    // Dev address.
    address public nftPacksAddress;

    // The burn address
    address internal burnAddress = address(0xdead);   

    // Dev address.
    address payable public devaddr;

    // bridge gateway
    address private gatewayAddress; 

    // total Native added to LP
    uint256 public totalLPNative;

    // total token added to LP
    uint256 public totalLPToken;

    // total tokens burned
    uint256 public totalTokensBurned;

    uint256 public tokenBurnMultiplier = 3;
    uint256 public nftGiveMultiplier = 4;
    uint256 public nftBurnMultiplier = 3;
    uint256 public packThresh = 3;

    //lpAddress is also equal to the liquidity token address
    //LP token are locked in the contract
    address private lpAddress; 
    IPancakeRouter02 private  pancakeRouter; 
    //TODO: Change to Mainnet
    //TestNet
     // address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
   // address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;

   // polygon testnet
   // address private constant PancakeRouter=0xbdd4e5660839a088573191A9889A262c0Efc0983;

   // address private constant PancakeRouter=0x8954AfA98594b838bda56FE4C12a09D7739D179b;
   address private PancakeRouter;

    struct UserLock {
        uint256 tokenAmount; // total amount they locked
        uint256 claimedAmount; // total amount they have withdrawn
        uint256 vestShare; // how many tokens they get back each vesting period
        uint256 vestPeriod; // how many seconds each vest point is
        uint256 startTime; // start of the lock
        uint256 endTime; //when the lock ends
    }

    struct UserNftLock {
        uint256 amount; // amount they have locked
        uint256 sharePoints;  // total share points being given for this lock
        uint256 startTime; // start of the lock
        uint256 endTime; //when the lock ends
    }

    struct NftInfo {
        uint256 tokenId; // which token to lock (mPCKT or LP)
        uint256 lockDuration; // how long this nft needs you to lock
        uint256 tokenAmount; // how many tokens you must lock
        uint256 vestPoints; // lock time / vestPoints = each vesting period
        uint256 sharePoints;  // how many share points this is worth for locking (4x for giving)
        uint256 givenAmount; // how many have been deposited into the contract
        uint256 burnedAmount; // how many have been deposited into the contract
        uint256 claimedAmount; // how many have been claimed from the contract
        uint256 lockedNfts; // how many nfts are currently locked
        bool toBurn; // if this should be burned or transferred when deposited
        bool isDisabled; // so we can hide ones we don't want
        address lastGiven; // address that last gave this nft so they can't reclaim
    }

     mapping(address => mapping(uint256 => UserLock)) public userLocks;
     mapping(address => mapping(uint256 => UserNftLock)) public userNftLocks;
     mapping(uint256 => NftInfo) public nftInfo;
     mapping(uint256 => bool) public inNftPacks;
     mapping(uint256 => IERC20) public tokenIds;
     mapping(address => bool) private canGive;

     mapping(address => uint256) public sharePoints;


    event Locked(address indexed account, uint256 nftId, uint256 unlock );
    event UnLocked(address indexed account, uint256 nftId);
//    event Claimed(address indexed account, uint256 nftId, uint256 amount);
    event NftGiven(address indexed account, uint256 nftId);
    event NftLocked(address indexed account, uint256 nftId, uint256 unlock);
    event TokensBurned(address indexed account, uint256 amount);

    event NftUnLocked(address indexed account, uint256 nftId);
    constructor (
        ERC1155Tradable _nftContract, 
        IERC20 _token, 
        address payable _devaddr,
        address _router
    ) {
        nftContract = _nftContract;
        devaddr = _devaddr;
        PancakeRouter = _router;
        
        _setToken(1,_token);

        canGive[address(this)] = true;
        canGive[owner()] = true;
        pancakeRouter = IPancakeRouter02(PancakeRouter);

        lpAddress = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());

        _token.approve(address(pancakeRouter), type(uint256).max);
     //   _token.approve(burnAddress, type(uint256).max);
    }

    function setMultipliers(uint256 _tokenBurnMultiplier, uint256 _nftGiveMultiplier, uint256 _nftBurnMultiplier ) public onlyOwner {
        tokenBurnMultiplier = _tokenBurnMultiplier;
        nftGiveMultiplier = _nftGiveMultiplier;
        nftBurnMultiplier = _nftBurnMultiplier;
    }

    function setPackThresh(uint256 _packThresh) public onlyOwner {
        packThresh = _packThresh;
    }

    function setNftContract( ERC1155Tradable _nftContract )public onlyOwner {
        nftContract = _nftContract;      
    }

    function setGatewayAddress( address _gatewayAddress) public onlyOwner {
        gatewayAddress = _gatewayAddress;
    }

    function setLpAddress( address _lpAddress) public onlyOwner {
        lpAddress = _lpAddress;
    }

    function setDevAddress( address payable _devaddr ) public onlyOwner {   
        devaddr = _devaddr;
    }

    function setNftPacksAddress(address _nftPacksAddress) public onlyOwner {
        nftPacksAddress = _nftPacksAddress;
    }
    function setToken(uint256 _tokenId, IERC20 _tokenAddress) public onlyOwner {
        _setToken(_tokenId, _tokenAddress);
        _tokenAddress.approve(address(pancakeRouter), type(uint256).max);
    }

    function _setToken(uint256 _tokenId, IERC20 _tokenAddress) private {
        tokenIds[_tokenId] = _tokenAddress;
    }

    function setNftInPack(uint256 _nftId, bool _inPack) public onlyOwner {
        inNftPacks[_nftId] = _inPack;
    }

    function setNftInfo(
        uint256 _nftId, 
        uint256 _tokenId, 
        uint256 _lockDuration, 
        uint256 _tokenAmount, 
        uint256 _vestPoints, 
        uint256 _sharePoints, 
        bool _toBurn) public onlyOwner {

        require(address(tokenIds[_tokenId]) != address(0), "No valid token");

        nftInfo[_nftId].tokenId = _tokenId;
        nftInfo[_nftId].lockDuration = _lockDuration;
        nftInfo[_nftId].tokenAmount = _tokenAmount;
        nftInfo[_nftId].vestPoints = _vestPoints;
        nftInfo[_nftId].sharePoints = _sharePoints;
        nftInfo[_nftId].toBurn = _toBurn;

    }

    function setNftDisabled(uint256 _nftId, bool _isDisabled) public onlyOwner {
        nftInfo[_nftId].isDisabled = _isDisabled;        
    }

    function setVaultActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function setLpEnabled(bool _lpEnabled) public onlyOwner {
        lpEnabled = _lpEnabled;
    }

    function lock(uint256 _nftId) public nonReentrant {

        require(userLocks[msg.sender][_nftId].tokenAmount == 0, 'Already Locked');
        require(isActive && tokenIds[nftInfo[_nftId].tokenId].balanceOf(msg.sender) >= nftInfo[_nftId].tokenAmount && nftInfo[_nftId].tokenId  > 0 && !nftInfo[_nftId].isDisabled && (nftContract.balanceOf(address(this), _nftId).sub(nftInfo[_nftId].lockedNfts)) > 0, 'Not Enough');
        require(nftInfo[_nftId].lastGiven != address(msg.sender),'can not claim your own' );

        userLocks[msg.sender][_nftId].tokenAmount = nftInfo[_nftId].tokenAmount;
        userLocks[msg.sender][_nftId].startTime = block.timestamp; // block.timestamp;
        userLocks[msg.sender][_nftId].endTime = block.timestamp.add(nftInfo[_nftId].lockDuration); // block.timestamp.add(nftInfo[_nftId].lockDuration);
        userLocks[msg.sender][_nftId].vestShare = nftInfo[_nftId].tokenAmount.div(nftInfo[_nftId].vestPoints);
        userLocks[msg.sender][_nftId].vestPeriod = nftInfo[_nftId].lockDuration.div(nftInfo[_nftId].vestPoints);

        // give them share points 1:1 for the tokens they have staked
        // _addShares(msg.sender,userLocks[msg.sender][_nftId].tokenAmount); 

        // move the tokens
        tokenIds[nftInfo[_nftId].tokenId].safeTransferFrom(address(msg.sender), address(this), nftInfo[_nftId].tokenAmount);

        // send the NFT
        nftContract.safeTransferFrom( address(this), msg.sender, _nftId, 1, "");

        // emit Locked( msg.sender, nftInfo[_nftId].tokenId, nftInfo[_nftId].tokenAmount, userLocks[msg.sender][_nftId].endTime, _nftId);
        emit Locked( msg.sender, _nftId, userLocks[msg.sender][_nftId].endTime );

    }


    function claimLock(uint256 _nftId) public nonReentrant {
        require(isActive && userLocks[msg.sender][_nftId].tokenAmount > 0, 'Not Locked');
        require(userLocks[msg.sender][_nftId].tokenAmount > 0 && (userLocks[msg.sender][_nftId].tokenAmount.sub(userLocks[msg.sender][_nftId].claimedAmount) > 0 ), 'Nothing to claim');
        // _claimLock(msg.sender, _nftId);

        // see how many vest points they have hit
        uint256 vested;
        for(uint256 i = 1; i <= nftInfo[_nftId].vestPoints; ++i){
            // if(block.timestamp >= userLocks[msg.sender][_nftId].startTime.add(userLocks[msg.sender][_nftId].vestPeriod.mul(i))){
            if(block.timestamp >= userLocks[msg.sender][_nftId].startTime.add(userLocks[msg.sender][_nftId].vestPeriod.mul(i))){    
                vested++;
            }
        }

        uint256 totalVested = userLocks[msg.sender][_nftId].vestShare.mul(vested);

        // get the amount owed to them based on previous claims and current vesting period
        uint256 toClaim = totalVested.sub(userLocks[msg.sender][_nftId].claimedAmount);

        require(toClaim > 0, 'Nothing to claim.');

        userLocks[msg.sender][_nftId].claimedAmount = userLocks[msg.sender][_nftId].claimedAmount.add(toClaim);

        // remove the shares
        _removeShares(msg.sender, toClaim);

        // move the tokens
        tokenIds[nftInfo[_nftId].tokenId].safeTransfer(address(msg.sender), toClaim);
//        Claimed(_address, _nftId, toClaim);



        if(block.timestamp >= userLocks[msg.sender][_nftId].endTime){
            delete userLocks[msg.sender][_nftId];
            emit UnLocked(msg.sender,_nftId);
        }
        
    }

    // Trade tokens directly for share points at 3:1 rate
    function tokensForShares(uint256 _amount) public nonReentrant {
        require(isActive && tokenIds[1].balanceOf(msg.sender) >= _amount, "Not enough tokens");

        _addShares(msg.sender,_amount.mul(tokenBurnMultiplier) );
        
        totalTokensBurned = totalTokensBurned.add(_amount);

        tokenIds[1].safeTransferFrom(address(msg.sender),burnAddress, _amount);
        emit TokensBurned(msg.sender, _amount);
    }

    function giveNft(uint256 _nftId, uint256 _amount) public nonReentrant {
        require(nftContract.balanceOf(address(msg.sender), _nftId) >= _amount,'Not Enough NFTs');

        require(isActive && nftInfo[_nftId].sharePoints > 0  && !nftInfo[_nftId].isDisabled, 'NFT Not Registered');

        address toSend = address(this);
        uint256 multiplier = nftGiveMultiplier;

        //see if we burn it
        if(nftInfo[_nftId].toBurn){
            toSend = burnAddress;
            multiplier =  nftBurnMultiplier;
            nftInfo[_nftId].burnedAmount = nftInfo[_nftId].burnedAmount.add(_amount);
        } else {
            // check if it's in packs
            if(inNftPacks[_nftId] && nftContract.balanceOf(address(this), _nftId).sub(nftInfo[_nftId].lockedNfts) >= packThresh){
                toSend = address(nftPacksAddress);
            }
            nftInfo[_nftId].givenAmount = nftInfo[_nftId].givenAmount.add(_amount);
        }

        // give them shares for the NFTs
        _addShares(msg.sender,nftInfo[_nftId].sharePoints.mul(_amount).mul(multiplier) );
        
        // send the NFT
        nftContract.safeTransferFrom( msg.sender, toSend, _nftId, _amount, "");

        emit NftGiven(msg.sender, _nftId);

    }

    // locks an NFT for the amount of time and the user share points
    // dont't allow burnable NFTS to count
    function lockNft(uint256 _nftId, uint256 _amount) public nonReentrant {
        require(
            isActive && 
            nftInfo[_nftId].sharePoints > 0  && 
            !nftInfo[_nftId].toBurn && 
            !nftInfo[_nftId].isDisabled && 
            nftContract.balanceOf(address(msg.sender), _nftId) >= _amount , "Can't Lock");
        // && userNftLocks[msg.sender][_nftId].startTime == 0
        
        // require(isActive && nftInfo[_nftId].sharePoints > 0  && !nftInfo[_nftId].toBurn && !nftInfo[_nftId].isDisabled, 'NFT Not Registered');

        userNftLocks[msg.sender][_nftId].amount = userNftLocks[msg.sender][_nftId].amount.add(_amount);
        userNftLocks[msg.sender][_nftId].startTime = block.timestamp; //  block.timestamp;
        userNftLocks[msg.sender][_nftId].endTime = block.timestamp.add(nftInfo[_nftId].lockDuration); // block.timestamp.add(nftInfo[_nftId].lockDuration);

        // update the locked count
        nftInfo[_nftId].lockedNfts = nftInfo[_nftId].lockedNfts.add(_amount);

        // give them shares for the NFTs (1/4 the value of giving it away)
        uint256 sp = nftInfo[_nftId].sharePoints.mul(_amount);

        userNftLocks[msg.sender][_nftId].sharePoints = userNftLocks[msg.sender][_nftId].sharePoints.add(sp);
        _addShares(msg.sender, sp);

        // send the NFT
        nftContract.safeTransferFrom( msg.sender, address(this), _nftId, _amount, "");

        emit NftLocked( msg.sender, _nftId, userNftLocks[msg.sender][_nftId].endTime);

    }

    // unlocks and claims an NFT if allowed and removes the share points
    function unLockNft(uint256 _nftId) public nonReentrant {
        require(isActive && userNftLocks[msg.sender][_nftId].amount > 0, 'Not Locked');
        require(block.timestamp >= userNftLocks[msg.sender][_nftId].endTime, 'Still Locked');
        
        // remove the shares
        _removeShares(msg.sender, userNftLocks[msg.sender][_nftId].sharePoints);

        uint256 amount = userNftLocks[msg.sender][_nftId].amount;
        delete userNftLocks[msg.sender][_nftId];
        // update the locked count
        nftInfo[_nftId].lockedNfts = nftInfo[_nftId].lockedNfts.sub(amount);
        
        // send the NFT
        nftContract.safeTransferFrom(  address(this), msg.sender, _nftId, amount, "");

        emit NftUnLocked( msg.sender, _nftId);
    }



    //lock for the withdraw, only one native withdraw can happen at a time
    bool private _isWithdrawing;
    //Multiplier to add some accuracy to profitPerShare
    uint256 private constant DistributionMultiplier = 2**64;
    //profit for each share a holder holds, a share equals a decimal.
    uint256 public profitPerShare;
    //totalShares in circulation +InitialSupply to avoid underflow 
    //getTotalShares returns the correct amount
    //uint256 private _totalShares=InitialSupply;
    //the total reward distributed through the vault, for tracking purposes
    uint256 public totalShareRewards;
    //the total payout through the vault, for tracking purposes
    uint256 public totalPayouts;
    //Mapping of the already paid out(or missed) shares of each staker
    mapping(address => uint256) private alreadyPaidShares;
    //Mapping of shares that are reserved for payout
    mapping(address => uint256) private toBePaid;



//    event OnClaimNative(address claimAddress, uint256 amount);

    // manage which contracts/addresses can give shares to allow other contracts to interact
    function setCanGive(address _addr, bool _canGive) public onlyOwner {
        canGive[_addr] = _canGive;
    }

    //gets shares of an address
    function getShares(address _addr) public view returns(uint256){
        return (sharePoints[_addr]);
    }

    //Returns the not paid out dividends of an address in wei
    function getDividends(address _addr) public view returns (uint256){
        return _getDividendsOf(_addr) + toBePaid[_addr];
    }


    function claimNative() public nonReentrant {
        require(!_isWithdrawing,'in progress');
           
        _isWithdrawing=true;
        uint256 amount = getDividends(msg.sender);
        require(amount!=0,"=0"); 
        //Substracts the amount from the dividends
        _updateClaimedDividends(msg.sender, amount);
        totalPayouts+=amount;
        (bool sent,) =msg.sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
        _isWithdrawing=false;
//        emit OnClaimNative(msg.sender,amount);

    }

    function giveShares(address _addr, uint256 _amount) public {
        require(canGive[msg.sender], "Can't give");
        _addShares(_addr,_amount);
    }

    function removeShares(address _addr, uint256 _amount) public {
        require(canGive[msg.sender], "Can't remove");
        _removeShares(_addr,_amount);
    }



    //adds Token to balances, adds new Native to the toBePaid mapping and resets staking
    function _addShares(address _addr, uint256 _amount) private {
        // the new amount of points
        uint256 newAmount = sharePoints[_addr].add(_amount);

        // update the total points
        totalSharePoints+=_amount;

        //gets the payout before the change
        uint256 payment = _getDividendsOf(_addr);

        //resets dividends to 0 for newAmount
        alreadyPaidShares[_addr] = profitPerShare.mul(newAmount);
        //adds dividends to the toBePaid mapping
        toBePaid[_addr]+=payment; 
        //sets newBalance
        sharePoints[_addr]=newAmount;


    }

    //removes shares, adds Native to the toBePaid mapping and resets staking
    function _removeShares(address _addr, uint256 _amount) private {
        //the amount of token after transfer
        uint256 newAmount=sharePoints[_addr].sub(_amount);
        totalSharePoints -= _amount;

        //gets the payout before the change
        uint256 payment =_getDividendsOf(_addr);
        //sets newBalance
        sharePoints[_addr]=newAmount;
        //resets dividendss to 0 for newAmount
        alreadyPaidShares[_addr] = profitPerShare.mul(sharePoints[_addr]);
        //adds dividendss to the toBePaid mapping
        toBePaid[_addr] += payment; 
    }



    //gets the dividends of an address that aren't in the toBePaid mapping 
    function _getDividendsOf(address _addr) private view returns (uint256) {
        uint256 fullPayout = profitPerShare.mul(sharePoints[_addr]);
        //if excluded from staking or some error return 0
        if(fullPayout<=alreadyPaidShares[_addr]) return 0;
        return (fullPayout.sub(alreadyPaidShares[_addr])).div(DistributionMultiplier);
    }


    //adjust the profit share with the new amount
    function _updatePorfitPerShare(uint256 _amount) private {

        totalShareRewards += _amount;
        if (totalSharePoints > 0) {
            //Increases profit per share based on current total shares
            profitPerShare += ((_amount.mul(DistributionMultiplier)).div(totalSharePoints));
        }
    }

    //Substracts the amount from dividends, fails if amount exceeds dividends
    function _updateClaimedDividends(address _addr,uint256 _amount) private {
        if(_amount==0) return;
        
        

        require(_amount <= getDividends(_addr),"exceeds dividends");
        uint256 newAmount = _getDividendsOf(_addr);

        //sets payout mapping to current amount
        alreadyPaidShares[_addr] = profitPerShare.mul(sharePoints[_addr]);
        //the amount to be paid 
        toBePaid[_addr]+=newAmount;
        toBePaid[_addr]-=_amount;
    }


    // LP Functions
    //Adds Liquidity directly to the contract where LP are locked(unlike safemoon forks, that transfer it to the owner)
    function _addLiquidity(uint256 tokenamount, uint256 nativeamount) private {
        totalLPNative+=nativeamount;
        totalLPToken+=tokenamount;

        try pancakeRouter.addLiquidityETH{value: nativeamount}(
            address(tokenIds[1]),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        ){}
        catch{}
    }

/*    //swaps tokens on the contract for Native
    function _swapTokenForNative(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
*/
    //swaps Native for mPCKT
    function _swapNativeForToken(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(tokenIds[1]);

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function extendLiquidityLock(uint256 secondsUntilUnlock) public onlyOwner {
        uint256 newUnlockTime = secondsUntilUnlock+block.timestamp;
        require(newUnlockTime>liquidityUnlockTime);
        liquidityUnlockTime=newUnlockTime;
    }

    // unlock time for contract LP
    uint256 public liquidityUnlockTime;

    // default for new lp added after release
    uint256 private constant DefaultLiquidityLockTime=14 days;

    //Release Liquidity Tokens once unlock time is over
    function releaseLiquidity() public onlyOwner {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= liquidityUnlockTime, "Locked");
        liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;       
        IPancakeERC20 liquidityToken = IPancakeERC20(lpAddress);
        // uint256 amount = liquidityToken.balanceOf(address(this));

        // only allow 20% 
        // amount=amount*2/10;
        liquidityToken.transfer(devaddr, liquidityToken.balanceOf(address(this)).mul(2).div(10));
    }

    // burn all mPCKT in the contract, this gets built up when adding LP
    function burnLeftovers() public onlyOwner {
        tokenIds[1].transferFrom(address(this), burnAddress, tokenIds[1].balanceOf(address(this)) );
    }

    event OnVaultReceive(address indexed sender, uint256 amount, uint256 shared);
    receive() external payable {

        // @TODO
        // Check if it's coming from the gateway address
        // don't add LP (LP added to sidechains pool)

        // Send half to LP
        uint256 lpBal = msg.value.div(2);
        uint256 shareBal = msg.value.sub(lpBal);

        //if we have no shares 100% LP    
        if(totalSharePoints <= 0){
            lpBal = msg.value;
            shareBal = 0;
        }

        // send any cross chain vault sends or returned change all the share holders 
        if(!lpEnabled || msg.sender == address(pancakeRouter) || msg.sender == address(gatewayAddress)){
            lpBal = 0;
            shareBal = msg.value;
        } else {

            // split the LP part in half
            uint256 nativeToSpend = lpBal.div(2);
            uint256 nativeToPost = lpBal.sub(nativeToSpend);

            // get the current mPCKT balance
            uint256 contractTokenBal = tokenIds[1].balanceOf(address(this));
           
            // do the swap
            _swapNativeForToken(nativeToSpend);

            //new balance
            uint256 tokenToPost = tokenIds[1].balanceOf(address(this)).sub(contractTokenBal);

            // add LP
            _addLiquidity(tokenToPost, nativeToPost);
        }

        // send half to share holders
        if(shareBal > 0 && totalSharePoints > 0){
            _updatePorfitPerShare(shareBal);
        }
/*        uint256 leftover =  tokenIds[1].balanceOf(address(this));
        // if any tokens are left over after we add the LP burn them
        if(leftover > 0){
            tokenIds[1].transferFrom(address(this), burnAddress, leftover ); //.mul(95).div(100)
//            tokenIds[1].safeTransferFrom(address(this),burnAddress, tokenIds[1].balanceOf(address(this)));
        }*/
        emit OnVaultReceive(msg.sender, msg.value, shareBal);
    }
    
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
      return 0xf23a6e61;
    }


    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
      return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
      return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
      interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
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
/// @author MrD 

pragma solidity >=0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";
import "./libs/ERC1155Tradable.sol";

/**
 * @title NftPack 
 * NftPack - a randomized and openable lootbox of Nfts
 */

 // @TODO add function to be able to transfer NFTS from the contract
contract NftPacks is Ownable, Pausable, AccessControl, ReentrancyGuard, VRFConsumerBase, IERC1155Receiver {
  using Strings for string;
  using SafeMath for uint256;

  ERC1155Tradable public nftContract;

  bool[] public Class;
  bool[] public Option;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 constant INVERSE_BASIS_POINT = 10000;
  bool internal allowMint;

  // Chainlink VRF
  bytes32 internal keyHash;
  uint256 internal linkFee;
  address internal vrfCoordinator;
  uint256 private _randomness;

  event cardPackOpened(uint256 indexed optionId, address indexed buyer, uint256 boxesPurchased, uint256 itemsMinted);
  event Warning(string message, address account);
  event SetLinkFee(address indexed user, uint256 fee);
  event SetNftContract(address indexed user, ERC1155Tradable nftContract);

  struct OptionSettings {
    // Number of items to send per open.
    // Set to 0 to disable this Option.
    uint256 maxQuantityPerOpen;
    // Probability in basis points (out of 10,000) of receiving each class (descending)
    uint16[] classProbabilities; // NUM_CLASSES
    // Whether to enable `guarantees` below
    bool hasGuaranteedClasses;
    // Number of items you're guaranteed to get, for each class
    uint16[] guarantees; // NUM_CLASSES
  }

  /** 
   * @dev info on the current pack being opened 
   */
  struct PackQueueInfo {
    address userAddress; //user opening the pack
    uint256 optionId; //packId being opend
    uint256 amount; //amount of packs
  }

  uint256 private defaultNftId = 71;

  mapping (uint256 => OptionSettings) public optionToSettings;
  mapping (uint256 => uint256[]) public classToTokenIds;

  // keep track of the times each token is minted, 
  // if internalMaxSupply is > 0 we use the interal data
  // if it is 0 we will use supply of the NFT contract instead
  mapping (uint256 => uint256) public internalMaxSupply;
  mapping (uint256 => uint256) public internalTokensMinted;
  
  mapping (address => uint256[]) public lastOpen;
  mapping (address => uint256) public isOpening;
  mapping(bytes32 => PackQueueInfo) private packQueue;


  constructor(
    ERC1155Tradable _nftAddress,
    address _vrfCoordinator,
    bytes32 _vrfKeyHash, 
    address _linkToken,
    uint256 _linkFee
  ) VRFConsumerBase(
    _vrfCoordinator, 
    _linkToken
  ) {

    nftContract = _nftAddress;
    vrfCoordinator = _vrfCoordinator;
    keyHash = _vrfKeyHash;
    linkFee = _linkFee;

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);

  }

   /** 
     * @notice Modifier to only allow updates by the VRFCoordinator contract
     */
    modifier onlyVRFCoordinator {
        require(msg.sender == vrfCoordinator, 'Fulfillment only allowed by VRFCoordinator');
        _;
    }

  /**
   * @dev Add a Class Id
   */
   function addClass(uint256 _classId) public onlyOwner {
     if(_classId >= Class.length || _classId == 0){
      Class.push(true);
     } 
   }


  /**
   * @dev If the tokens for some class are pre-minted and owned by the
   * contract owner, they can be used for a given class by setting them here
   */
  function setClassForTokenId(
    uint256 _tokenId,
    uint256 _classId,
    uint256 _amount
  ) public onlyOwner {
  //  _checkTokenApproval();
    _addTokenIdToClass(_classId, _tokenId, _amount);
  }

 
  /**
   * @dev Remove all token ids for a given class, causing it to fall back to
   * creating/minting into the nft address
   */
  function resetClass(
    uint256 _classId
  ) public onlyOwner {
    delete classToTokenIds[_classId];
  }

  /**
   * @param _optionId The Option to set settings for
   * @param _maxQuantityPerOpen Maximum number of items to mint per open.
   *                            Set to 0 to disable this pack.
   * @param _classProbabilities Array of probabilities (basis points, so integers out of 10,000)
   *                            of receiving each class (the index in the array).
   *                            Should add up to 10k and be descending in value.
   * @param _guarantees         Array of the number of guaranteed items received for each class
   *                            (the index in the array).
   */
  function setOptionSettings(
    uint256 _optionId,
    uint256 _maxQuantityPerOpen,
    uint16[] calldata _classProbabilities,
    uint16[] calldata _guarantees
  ) external onlyOwner {
    addOption(_optionId);
    // Allow us to skip guarantees and save gas at mint time
    // if there are no classes with guarantees
    bool hasGuaranteedClasses = false;
    for (uint256 i = 0; i < Class.length; i++) {
      if (_guarantees[i] > 0) {
        hasGuaranteedClasses = true;
      }
    }

    OptionSettings memory settings = OptionSettings({
      maxQuantityPerOpen: _maxQuantityPerOpen,
      classProbabilities: _classProbabilities,
      hasGuaranteedClasses: hasGuaranteedClasses,
      guarantees: _guarantees
    });

    
    optionToSettings[_optionId] = settings;
  }


  function getLastOpen(address _address) external view returns(uint256[] memory) {
    return lastOpen[_address];
  }


  /**
   * @dev Add an option Id
   */
  function addOption(uint256 _optionId) internal onlyOwner{
    if(_optionId >= Option.length || _optionId == 0){
      Option.push(true);
    }
  }


  /**
   * @dev Open the NFT pack and send what's inside to _toAddress
   */
  function open(
    uint256 _optionId,
    address _toAddress,
    uint256 _amount
  ) external onlyRole(MINTER_ROLE) {
    _mint(_optionId, _toAddress, _amount, "");
  }


  /**
   * @dev Main minting logic for NftPacks
   */
  function _mint(
    uint256 _optionId,
    address _toAddress,
    uint256 _amount,
    bytes memory /* _data */
  ) internal whenNotPaused onlyRole(MINTER_ROLE) nonReentrant returns (bytes32) {
    // Load settings for this box option
    
    OptionSettings memory settings = optionToSettings[_optionId];

    require(settings.maxQuantityPerOpen > 0, "NftPack#_mint: OPTION_NOT_ALLOWED");
    require(isOpening[_toAddress] == 0, "NftPack#_mint: OPEN_IN_PROGRESS");

    require(LINK.balanceOf(address(this)) > linkFee, "Not enough LINK - fill contract with faucet");

    isOpening[_toAddress] = _optionId;
    bytes32 _requestId = requestRandomness(keyHash, linkFee);

    PackQueueInfo memory queue = PackQueueInfo({
      userAddress: _toAddress,
      optionId: _optionId,
      amount: _amount
    });
    
    packQueue[_requestId] = queue;

    return _requestId;
 
  }

  /**
   * @notice Callback function used by VRF Coordinator
  */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override onlyVRFCoordinator {
    
    PackQueueInfo memory _queueInfo = packQueue[requestId];
    _randomness = randomness;
    doMint(_queueInfo.userAddress, _queueInfo.optionId, _queueInfo.amount);

  }

  function doMint(address _userAddress, uint256 _optionId, uint256 _amount) internal onlyVRFCoordinator {
    
    OptionSettings memory settings = optionToSettings[_optionId];
   
    isOpening[_userAddress] = 0;

    delete lastOpen[_userAddress];
    uint256 totalMinted = 0;
    // Iterate over the quantity of packs to open
    for (uint256 i = 0; i < _amount; i++) {
      // Iterate over the classes
      uint256 quantitySent = 0;
      if (settings.hasGuaranteedClasses) {
        // Process guaranteed token ids
        for (uint256 classId = 1; classId < settings.guarantees.length; classId++) {
            uint256 quantityOfGaranteed = settings.guarantees[classId];

            if(quantityOfGaranteed > 0) {
              lastOpen[_userAddress].push(_sendTokenWithClass(classId, _userAddress, quantityOfGaranteed));
              quantitySent += quantityOfGaranteed;    
            }
        }
      }

      // Process non-guaranteed ids
      while (quantitySent < settings.maxQuantityPerOpen) {
        uint256 quantityOfRandomized = 1;
        uint256 classId = _pickRandomClass(settings.classProbabilities);
        lastOpen[_userAddress].push(_sendTokenWithClass(classId, _userAddress, quantityOfRandomized));
        quantitySent += quantityOfRandomized;
      }
      totalMinted += quantitySent;
    }

    emit cardPackOpened(_optionId, _userAddress, _amount, totalMinted);
  }

  function numOptions() external view returns (uint256) {
    return Option.length;
  }

  function numClasses() external view returns (uint256) {
    return Class.length;
  }

  // Returns the tokenId sent to _toAddress
  function _sendTokenWithClass(
    uint256 _classId,
    address _toAddress,
    uint256 _amount
  ) internal returns (uint256) {
     // ERC1155Tradable nftContract = ERC1155Tradable(nftAddress);


    uint256 tokenId = _pickRandomAvailableTokenIdForClass( _classId);
      
      //super fullback to a set ID
      if(tokenId == 0){
        tokenId = defaultNftId;
      }

      //nftContract.mint(_toAddress, tokenId, _amount, "0x0");

      // @dev some ERC1155 contract doesn't support the: _toAddress
      // we need to transfer it to the address after mint
      if(nftContract.balanceOf(address(this),tokenId) == 0 ){
        nftContract.mint(tokenId, _amount, "0x0");
      }
      
      nftContract.safeTransferFrom(address(this), _toAddress, tokenId, _amount, "0x0");
    

    return tokenId;
  }

  function _pickRandomClass(
    uint16[] memory _classProbabilities
  ) internal returns (uint256) {
    uint16 value = uint16(_random().mod(INVERSE_BASIS_POINT));
    // Start at top class (length - 1)
    for (uint256 i = _classProbabilities.length - 1; i > 0; i--) {
      uint16 probability = _classProbabilities[i];
      if (value < probability) {
        return i;
      } else {
        value = value - probability;
      }
    }
    return 1;
  }

  function _pickRandomAvailableTokenIdForClass(
    uint256 _classId
  ) internal returns (uint256) {

    uint256[] memory tokenIds = classToTokenIds[_classId];
    require(tokenIds.length > 0, "NftPack#_pickRandomAvailableTokenIdForClass: NO_TOKENS_ASSIGNED");
 
    uint256 randIndex = _random().mod(tokenIds.length);
    // ERC1155Tradable nftContract = ERC1155Tradable(nftAddress);

      for (uint256 i = randIndex; i < randIndex + tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i % tokenIds.length];

        // first check if we have a balance in the contract
        if(nftContract.balanceOf(address(this),tokenId)  > 0 ){
          return tokenId;
        }

        if(allowMint){
          uint256 curSupply;
          uint256 maxSupply;
          if(internalMaxSupply[tokenId] > 0){
            maxSupply = internalMaxSupply[tokenId];
            curSupply = internalTokensMinted[tokenId];
          } else {
            maxSupply = nftContract.tokenMaxSupply(tokenId);
            curSupply = nftContract.tokenSupply(tokenId);
          }

          uint256 newSupply = curSupply.add(1);
          if (newSupply <= maxSupply) {
            internalTokensMinted[tokenId] = internalTokensMinted[tokenId].add(1);
            return tokenId;
          }
        }


      }

      return 0;    
  }

  /**
   * @dev Take oracle return and generate a unique random number
   */
  function _random() internal returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _randomness)));
    // avoid pulling the same card 
    _randomness = _randomness + (_randomness/100);
    return randomNumber;
  }


  /**
   * @dev emit a Warning if we're not approved to transfer nftAddress
   */
  function _checkTokenApproval() internal {
//    ERC1155Tradable nftContract = ERC1155Tradable(nftAddress);
    if (!nftContract.isApprovedForAll(owner(), address(this))) {
      emit Warning("NftContract contract is not approved for trading collectible by:", owner());
    }
  }

  function _addTokenIdToClass(uint256 _classId, uint256 _tokenId, uint256 _amount) internal {
    classToTokenIds[_classId].push(_tokenId);
    internalMaxSupply[_tokenId] = _amount;
  }

  /**
   * @dev set the nft contract address callable by owner only
   */
  function setNftContract(ERC1155Tradable _nftAddress) public onlyOwner {
      nftContract = _nftAddress;
      emit SetNftContract(msg.sender, _nftAddress);
  }

  function setDefaultNftId(uint256 _nftId) public onlyOwner {
      defaultNftId = _nftId;
  }
  
  function resetOpening(address _toAddress) public onlyOwner {
    isOpening[_toAddress] = 0;
  }

  function setAllowMint(bool _allowMint) public onlyOwner {
      allowMint = _allowMint;
  }

  /**
   * @dev transfer LINK out of the contract
   */
  function withdrawLink(uint256 _amount) public onlyOwner {
      require(LINK.transfer(msg.sender, _amount), "Unable to transfer");
  }

  // @dev transfer NFTs out of the contract to be able to move into packs on other chains or manage qty
  function transferNft(ERC1155Tradable _nftContract, uint256 _id, uint256 _amount) public onlyOwner {
      _nftContract.safeTransferFrom(address(this),address(owner()),_id, _amount, "0x00");
  }
  /**
   * @dev update the link fee amount
   */
  function setLinkFee(uint256 _linkFee) public onlyOwner {
      linkFee = _linkFee;
      emit SetLinkFee(msg.sender, _linkFee);
  }

  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
      return 0xf23a6e61;
  }


  function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4) {
      return 0xbc197c81;
  }

  function supportsInterface(bytes4 interfaceID) public view virtual override(AccessControl,IERC165) returns (bool) {
      return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
      interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  }
}

// SPDX-License-Identifier: MIT
/// @title LP Staking
/// @author MrD 

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IERC20Minter.sol";
import "./libs/PancakeLibs.sol";


contract LpStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Minter;


    /* @dev struct to hold the user data */
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt.
        uint256 firstStake; // timestamp of the first time this wallet stakes
    }

    struct FeeInfo {
        uint256 feePercent;         // Percent fee that applies to this range
        uint256 timeCheck; // number of seconds from the intial stake this fee applies
    }

    /* @dev struct to hold the info for each pool */
    struct PoolInfo {
        IERC20Minter lpToken;           // Address of a token contract, LP or token.
        uint256 allocPoint;       // How many allocation points assigned to this pool. 
        uint256 lastRewardBlock;  // Last block number that distribution occurs.
        uint256 accRewardsPerShare;   // Accumulated Tokens per share, times 1e12. 
        uint directStake;      // 0 = off, 1 = buy token, 2 = pair bnb/token, 3 = pair token/token, 
        IERC20Minter tokenA; // leave emty if bnb, otherwise the token to pair with tokenB
        IERC20Minter tokenB; // the other half of the LP pair
        uint256 levelMultiplier;   // rewards * levelMultiplier is how many level points earned
    }

    // struct to hold the level info 
    struct UserLevel {
        uint256 currentLevel;   // current farm level
        uint256 levelRewards;   // the amount of farm level points earned
    }


    // Array of the level thresholds 
    uint256[] public userLevelsThresh;
    uint256 public maxLevels;
    mapping(address => UserLevel) public userLevel;

    // Migration vars 
    mapping(address => bool) public hasMigrated;

    // Global active flag
    bool isActive;

    // swap check
    bool isSwapping;

    // add liq check
    bool isAddingLp;

    // The Token
    IERC20Minter public rewardToken;

    // Base amount of rewards distributed per block
    uint256 public rewardsPerBlock;

    // Addresses 
    address public feeAddress;

    // Info of each user that stakes LP tokens 
    PoolInfo[] public poolInfo;

    // Info about the withdraw fees
    FeeInfo[] public feeInfo;
    
    // Total allocation points. Must be the sum of all allocation points in all pools 
    uint256 public totalAllocPoint = 0;

    // The block number when rewards start 
    uint256 public startBlock;

    uint256 public minPairAmount;

    uint256 public defaultFeePercent = 100;

    // PCS router
    IPancakeRouter02 private  pancakeRouter; 

    //TODO: Change to Mainnet
    //TestNet
     address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    // address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // Info of each user that stakes LP tokens
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // @dev mapping of existing pools to avoid dupes
    mapping(IERC20Minter => bool) public pollExists;

    event SetActive( bool isActive);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event AutoAddLiquidity(address indexed user, uint256 indexed pid, uint256 amountLp, uint256 amountBnb);    
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetFeeStructure(uint256[] feePercents, uint256[] feeTimeChecks);
    event UpdateEmissionRate(address indexed user, uint256 rewardsPerBlock);

    constructor(
        IERC20Minter _rewardToken,
        address _feeAddress,
        uint256 _rewardsPerBlock,
        uint256 _startBlock,
        uint256[] memory _feePercents,
        uint256[] memory  _feeTimeChecks,
        uint256[] memory _levelThresh
    ) {
        require(_feeAddress != address(0),'Invalid Address');

        rewardToken = _rewardToken;
        feeAddress = _feeAddress;
        rewardsPerBlock = _rewardsPerBlock;
        startBlock = _startBlock;

        pancakeRouter = IPancakeRouter02(PancakeRouter);
        rewardToken.approve(address(pancakeRouter), type(uint256).max);

        // set the initial fee structure
        _setWithdrawFees(_feePercents ,_feeTimeChecks );

        // set the level thresholds
        setUserLevelThresh(_levelThresh);

        // add the SAS staking pool
        add(400, rewardToken,  true, 4000000000000000000, 1, IERC20Minter(address(0)), IERC20Minter(address(0)));
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setWithdrawFees( uint256[] calldata _feePercents ,uint256[] calldata  _feeTimeChecks ) public onlyOwner {
        _setWithdrawFees( _feePercents , _feeTimeChecks );
    }

    function _setWithdrawFees( uint256[] memory _feePercents ,uint256[] memory  _feeTimeChecks ) private {
        delete feeInfo;
        for (uint256 i = 0; i < _feePercents.length; ++i) {
            require( _feePercents[i] <= 2500, "fee too high");
            feeInfo.push(FeeInfo({
                feePercent : _feePercents[i],
                timeCheck : _feeTimeChecks[i]
            }));
        }
        emit SetFeeStructure(_feePercents,_feeTimeChecks);
    }

    /* @dev Adds a new Pool. Can only be called by the owner */
    function add(
        uint256 _allocPoint, 
        IERC20Minter _lpToken, 
        bool _withUpdate,
        uint256 _levelMultiplier, 
        uint _directStake,
        IERC20Minter _tokenA,
        IERC20Minter _tokenB
    ) public onlyOwner {
        require(pollExists[_lpToken] == false, "nonDuplicated: duplicated");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        pollExists[_lpToken] = true;

        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accRewardsPerShare : 0,
            tokenA: _tokenA,
            tokenB: _tokenB,
            directStake: _directStake,
            levelMultiplier: _levelMultiplier
        }));
    }

    /* @dev Update the given pool's allocation point and deposit fee. Can only be called by the owner */
    function set(
        uint256 _pid, 
        uint256 _allocPoint, 
        bool _withUpdate, 
        uint256 _levelMultiplier,
        uint _directStake
    ) public onlyOwner {

        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].levelMultiplier = _levelMultiplier;
        poolInfo[_pid].directStake = _directStake;
    }

    /* @dev Return reward multiplier over the given _from to _to block */
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    /* @dev View function to see pending rewards on frontend.*/
    function pendingRewards(uint256 _pid, address _user)  external view returns (uint256) {
        return _pendingRewards(_pid, _user);
    }

    /* @dev calc the pending rewards */
    function _pendingRewards(uint256 _pid, address _user) internal view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accRewardsPerShare = pool.accRewardsPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(rewardsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardsPerShare = accRewardsPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accRewardsPerShare).div(1e12).sub(user.rewardDebt);
    }

    // View function to see pending level rewards for this pool 
    function pendingLevelRewards(uint256 _pid, address _user)  external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 pending = _pendingRewards(_pid,_user);

        return pending.mul(pool.levelMultiplier.div(1 ether));
    }

     // return the current level
    function getUserLevel(address _user)  external view returns (uint256) {
        return userLevel[_user].currentLevel;
    }


    function setUserLevelThresh(uint256[] memory _levelThresh) public onlyOwner {
        userLevelsThresh = _levelThresh;
        maxLevels = userLevelsThresh.length;
    }

    function setUserLevel(address _user) internal {
        UserLevel storage uLevel = userLevel[_user];
        uint256 length = userLevelsThresh.length;
        uint256 level = 0;

        for (uint256 lvl = 0; lvl < length; ++lvl) {
            if(uLevel.levelRewards >= userLevelsThresh[lvl].mul(1 ether) ){
                level = lvl.add(1);
            }
        }

        uLevel.currentLevel = level;
    }

    /* @dev Update reward variables for all pools. Be careful of gas spending! */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /* @dev Update reward variables of the given pool to be up-to-date */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(rewardsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        rewardToken.mint(feeAddress, tokenReward.div(10));
        rewardToken.mint(address(this), tokenReward);

        pool.accRewardsPerShare = pool.accRewardsPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    /* @dev Harvest and deposit LP tokens into the pool */
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(isActive,'Not active');
        _deposit(_pid,_amount,msg.sender,false);
    }

    function _deposit(uint256 _pid, uint256 _amount, address _addr, bool _isDirect) private {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_addr];
        UserLevel storage level = userLevel[msg.sender];

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardsPerShare).div(1e12).sub(user.rewardDebt);
            
            if (pending > 0) {
                // handle updating level points
                if(pool.levelMultiplier > 0){
                    level.levelRewards = level.levelRewards.add(pending.mul(pool.levelMultiplier.div(1 ether)));
                    setUserLevel(_addr);
                }
                // send from the contract
                safeTokenTransfer(_addr, pending);
            }
        }

        if (_amount > 0) {

            if(!_isDirect){
                pool.lpToken.safeTransferFrom(address(_addr), address(this), _amount);
            }
            
            user.amount = user.amount.add(_amount);

        }

        if(user.firstStake == 0){
            // set the timestamp for the addresses first stake
            user.firstStake = block.timestamp;
        }

        user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e12);
        emit Deposit(_addr, _pid, _amount);
    }

   

    /* @dev Harvest and withdraw LP tokens from a pool*/
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        require(isActive,'Not active');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        UserLevel storage level = userLevel[msg.sender];

        require(user.amount >= _amount && _amount > 0, "withdraw: no tokens to withdraw");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardsPerShare).div(1e12).sub(user.rewardDebt);
        
        if (pending > 0) {
            // handle updating level points
            if(pool.levelMultiplier > 0){
                level.levelRewards = level.levelRewards.add(pending.mul(pool.levelMultiplier.div(1 ether)));
                setUserLevel(msg.sender);
            }
            // send from the contract
            safeTokenTransfer(msg.sender, pending);
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);

            // check and charge the withdraw fee
            uint256 withdrawFeePercent = _currentFeePercent(msg.sender, _pid);

            uint256 withdrawFee = _amount.mul(withdrawFeePercent).div(10000);

            // subtract the fee from the amount we send
            uint256 toSend = _amount.sub(withdrawFee);

            // transfer the fee
            pool.lpToken.safeTransfer(feeAddress, withdrawFee);
      
            // transfer to user 
            pool.lpToken.safeTransfer(address(msg.sender), toSend);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardsPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /* @dev Withdraw entire balance without caring about rewards. EMERGENCY ONLY */
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
            
        // check and charge the withdraw fee
        uint256 withdrawFeePercent = _currentFeePercent(msg.sender, _pid);
        uint256 withdrawFee = amount.mul(withdrawFeePercent).div(10000);

        // subtract the fee from the amount we send
        uint256 toSend = amount.sub(withdrawFee);

        // transfer the fee
        pool.lpToken.safeTransfer(feeAddress, withdrawFee);
  
        // transfer to user 
        pool.lpToken.safeTransfer(address(msg.sender), toSend);

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /* @dev Return the current fee */
    function currentFeePercent (address _addr, uint256 _pid) external view returns(uint256){
        return _currentFeePercent(_addr, _pid);
    }

    /* @dev calculate the current fee based on first stake and current timestamp */
    function _currentFeePercent (address _addr, uint256 _pid) internal view returns(uint256){
        // get the time they staked
        uint256 startTime = userInfo[_pid][_addr].firstStake;

        // get the current time
        uint256 currentTime = block.timestamp;

        // check the times
        for (uint256 i = 0; i < feeInfo.length; ++i) {
            uint256 t = startTime + feeInfo[i].timeCheck;
            if(currentTime < t){
                return feeInfo[i].feePercent;
            }
        }

        return defaultFeePercent;
    }

    /* @dev send in any amount of BNB to have it paired to LP and auto-staked */
    function directToLp(uint256 _pid) public payable nonReentrant {
        require(isActive,'Not active');
        require(poolInfo[_pid].directStake > 0 ,'No direct stake');
        require(!isSwapping,'Token swap in progress');
        require(!isAddingLp,'Add LP in progress');
        require(msg.value >= minPairAmount, "Not enough BNB to swap");

        uint256 liquidity;

        // directStake 1 - stake only the token (use the LPaddress)
        if(poolInfo[_pid].directStake == 1){
            // get the current token balance
            uint256 sasContractTokenBal = poolInfo[_pid].lpToken.balanceOf(address(this));
            _swapBNBForToken(msg.value, address(poolInfo[_pid].lpToken));
            liquidity = poolInfo[_pid].lpToken.balanceOf(address(this)).sub(sasContractTokenBal);
        }

        // directStake 2 - pair BNB/tokenA 
        if(poolInfo[_pid].directStake == 2){
            // use half the BNB to buy the token
            uint256 bnbToSpend = msg.value.div(2);
            uint256 bnbToPost =  msg.value.sub(bnbToSpend);

            // get the current token balance
            uint256 contractTokenBal = poolInfo[_pid].tokenA.balanceOf(address(this));
           
            // do the swap
            _swapBNBForToken(bnbToSpend, address(poolInfo[_pid].tokenA));

            //new balance
            uint256 tokenToPost = poolInfo[_pid].tokenA.balanceOf(address(this)).sub(contractTokenBal);

            // add LP
            (,, uint lp) = _addLiquidity(address(poolInfo[_pid].tokenA),tokenToPost, bnbToPost);
            liquidity = lp;
        }

        // directStake 3 - pair tokenA/tokenB
        if(poolInfo[_pid].directStake == 3){

            // split the BNB
            // use half the BNB to buy the tokens
            uint256 bnbForTokenA = msg.value.div(2);
            uint256 bnbForTokenB =  msg.value.sub(bnbForTokenA);

            // get the current token balances
            uint256 contractTokenABal = poolInfo[_pid].tokenA.balanceOf(address(this));
            uint256 contractTokenBBal = poolInfo[_pid].tokenB.balanceOf(address(this));

            // buy both tokens
            _swapBNBForToken(bnbForTokenA, address(poolInfo[_pid].tokenA));
            _swapBNBForToken(bnbForTokenB, address(poolInfo[_pid].tokenB));

            // get the balance to post
            uint256 tokenAToPost = poolInfo[_pid].tokenA.balanceOf(address(this)).sub(contractTokenABal);
            uint256 tokenBToPost = poolInfo[_pid].tokenB.balanceOf(address(this)).sub(contractTokenBBal);

            // pair it
            (,, uint lp) =  _addLiquidityTokens( 
                address(poolInfo[_pid].tokenA), 
                address(poolInfo[_pid].tokenB), 
                tokenAToPost, 
                tokenBToPost
            );
            liquidity = lp;

        }
        

        // stake it to the contract
        _deposit(_pid,liquidity,msg.sender,true);

    }


    // LP Functions
    // adds liquidity and send it to the contract
    function _addLiquidity(address token, uint256 tokenamount, uint256 bnbamount) private returns(uint, uint, uint){
        isAddingLp = true;
        uint amountToken;
        uint amountETH;
        uint liquidity;

       (amountToken, amountETH, liquidity) = pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(token),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
        isAddingLp = false;
        return (amountToken, amountETH, liquidity);

    }

    function _addLiquidityTokens(address _tokenA, address _tokenB, uint256 _tokenAmountA, uint256 _tokenAmountB) private returns(uint, uint, uint){
        isAddingLp = true;
        uint amountTokenA;
        uint amountTokenB;
        uint liquidity;

       (amountTokenA, amountTokenB, liquidity) = pancakeRouter.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _tokenAmountA,
            _tokenAmountB,
            0,
            0,
            address(this),
            block.timestamp
        );
        isAddingLp = false;

        return (amountTokenA, amountTokenB, liquidity);

    }

    function _swapBNBForToken(uint256 amount, address _token) private {
        isSwapping = true;
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(_token);

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp
        );
        isSwapping = false;
    }

    function _swapTokenForToken(address _tokenA, address _tokenB, uint256 _amount) private {
        isSwapping = true;
        address[] memory path = new address[](2);
        path[0] = address(_tokenA);
        path[1] = address(_tokenB);

        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        isSwapping = false;
    }

    /* @dev Safe token transfer function, just in case if rounding error causes pool to not have enough tokens */
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 bal = rewardToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > bal) {
            transferSuccess = rewardToken.transfer(_to, bal);
        } else {
            transferSuccess = rewardToken.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }

    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
        emit SetActive(_isActive);
    }

    function setMinPairAmount(uint256 _minPairAmount) public onlyOwner {
        minPairAmount = _minPairAmount;
    }

    function setDefaultFee(uint256 _defaultFeePercent) public onlyOwner {
        require(_defaultFeePercent <= 500, "fee too high");
        defaultFeePercent = _defaultFeePercent;
    }


    function updateTokenContract(IERC20Minter _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
    }

    function setFeeAddress(address _feeAddress) public {
        require(_feeAddress != address(0),'Invalid Address');
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function updateEmissionRate(uint256 _rewardsPerBlock) public onlyOwner {
        massUpdatePools();
        rewardsPerBlock = _rewardsPerBlock;
        emit UpdateEmissionRate(msg.sender, _rewardsPerBlock);
    }

    // pull all the tokens out of the contract, needed for migrations/emergencies 
    function withdrawToken() public onlyOwner {
        safeTokenTransfer(feeAddress, rewardToken.balanceOf(address(this)));
    }

    // pull all the bnb out of the contract, needed for migrations/emergencies 
    function withdrawBNB() public onlyOwner {
         (bool sent,) =address(feeAddress).call{value: (address(this).balance)}("");
        require(sent,"withdraw failed");
    }


    receive() external payable {}
}