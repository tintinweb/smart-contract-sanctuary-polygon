/**
 *Submitted for verification at polygonscan.com on 2022-03-10
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title TokenRecover
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Allows owner to recover any ERC20 sent into the contract
 */
contract TokenRecover is Ownable {
    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant PORTAL_AAVEGOTCHIS_NUM = 10;

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name; //The name of the item
    string description;
    string author;
    // treated as int8s array
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] traitModifiers; //[WEARABLE ONLY] How much the wearable modifies each trait. Should not be more than +-5 total
    //[WEARABLE ONLY] The slots that this wearable can be added to.
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    // this is an array of uint indexes into the collateralTypes array
    uint8[] allowedCollaterals; //[WEARABLE ONLY] The collaterals this wearable can be equipped to. An empty array is "any"
    // SVG x,y,width,height
    Dimensions dimensions;
    uint256 ghstPrice; //How much GHST this item costs
    uint256 maxQuantity; //Total number that can be minted of this item.
    uint256 totalQuantity; //The total quantity of this item minted so far
    uint32 svgId; //The svgId of the item
    uint8 rarityScoreModifier; //Number from 1-50.
    // Each bit is a slot position. 1 is true, 0 is false
    bool canPurchaseWithGhst;
    uint16 minLevel; //The minimum Aavegotchi level required to use this item. Default is 1.
    bool canBeTransferred;
    uint8 category; // 0 is wearable, 1 is badge, 2 is consumable
    int16 kinshipBonus; //[CONSUMABLE ONLY] How much this consumable boosts (or reduces) kinship score
    uint32 experienceBonus; //[CONSUMABLE ONLY]
}

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
}

struct AavegotchiInfo {
    uint256 tokenId;
    string name;
    address owner;
    uint256 randomNumber;
    uint256 status;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    int16[NUMERIC_TRAITS_NUM] modifiedNumericTraits;
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    uint256 kinship; //The kinship value of this Aavegotchi. Default is 50.
    uint256 lastInteracted;
    uint256 experience; //How much XP this Aavegotchi has accrued. Begins at 0.
    uint256 toNextLevel;
    uint256 usedSkillPoints; //number of skill points used
    uint256 level; //the current aavegotchi level
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}

interface IGotchiContract {
    function interact(uint256[] calldata _tokenIds) external;

    function ownerOf(uint256 _id) external view returns (address);

    function isPetOperatorForAll(address _owner, address _operator) external view returns (bool);

    function getAavegotchi(uint256 id) external view returns (AavegotchiInfo memory);
}

contract GotchiCareCenter is TokenRecover {
    uint256 public pricePerPetPerDay = 0.05 ether;
    address public gotchiContract = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
    address public gelatoContract = 0x527a819db1eb0e34426297b03bae11F2f8B3A19E;

    mapping(uint256 => address) public pets; // Gotchi => owner
    mapping(address => uint256) public balances; // Owner => balance
    mapping(uint256 => uint256) public indexes; // Gotchi => array index;
    mapping(uint256 => uint256) public interactions; // Gotchi => timestamp;
    uint256[] public petIds;
    uint256 public feeEarned;
    uint256 public lastFeeChargedAt;
    uint256 public maxGasPriceAllowed = 8 * 1e9; // 80gwei

    constructor() {
        //  maxGasPriceAllowed = 80 gwei;
    }

    function interactWith() public view returns (uint256[] memory ids) {
        ids = new uint256[](petIds.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < petIds.length; i++) {
            if (
                petIds[i] > 0 &&
                balances[pets[petIds[i]]] >= pricePerPetPerDay &&
                IGotchiContract(gotchiContract).isPetOperatorForAll(
                    IGotchiContract(gotchiContract).ownerOf(petIds[i]),
                    gelatoContract
                )
            ) {
                uint256 lastInteracted = IGotchiContract(gotchiContract).getAavegotchi(petIds[i]).lastInteracted;

                if (lastInteracted + 12 hours <= block.timestamp) {
                    ids[i] = petIds[i];
                    counter++;
                }
            }
        }
    }

    function interact() external view returns (bool canExec, bytes memory execPayload) {
        canExec = false;
        uint256[] memory ids = interactWith();

        if (ids.length > 0) {
            canExec = true;
        }

        if (tx.gasprice > maxGasPriceAllowed) {
            canExec = false;
        }

        execPayload = abi.encodeWithSelector(IGotchiContract.interact.selector, ids);
    }

    function setGotchiContractAddress(address _gotchiContract) public onlyOwner {
        gotchiContract = _gotchiContract;
    }

    function setGelatoContractAddress(address _gelatoContract) public onlyOwner {
        gelatoContract = _gelatoContract;
    }

    function setMaxGasPriceAllowed(uint256 _gasPrice) public onlyOwner {
        maxGasPriceAllowed = _gasPrice * 1e9;
    }

    function addPetCare(uint256 id) external payable {
        require(pets[id] == address(0), "Pet is already added");
        require(IGotchiContract(gotchiContract).ownerOf(id) == msg.sender, "You are not the owner of this Pet");
        require(balances[msg.sender] >= pricePerPetPerDay || msg.value >= pricePerPetPerDay);
        pets[id] = msg.sender;
        indexes[id] = petIds.length;
        petIds.push(id);

        balances[msg.sender] += msg.value;
        balances[msg.sender] -= pricePerPetPerDay;

        feeEarned += pricePerPetPerDay;
    }

    function stopPetCare(uint256 id) external {
        require(pets[id] != address(0), "Pet is not added");
        require(
            IGotchiContract(gotchiContract).ownerOf(id) == msg.sender || msg.sender == owner(),
            "You are not the owner of this Pet"
        );
        delete petIds[indexes[id]];
        delete pets[id];
    }

    function getPricePerPetPerDay() external view returns (uint256) {
        return pricePerPetPerDay;
    }

    function setPricePerPetPerDay(uint256 amount) external onlyOwner returns (uint256) {
        pricePerPetPerDay = amount;
        return pricePerPetPerDay;
    }

    function withdrawFromMyBalance(uint256 _amount) external {
        uint256 amount = balances[msg.sender];

        if (amount >= _amount) {
            balances[msg.sender] -= _amount;
            payable(msg.sender).transfer(amount);
        } else {
            revert("Invalid");
        }
    }

    function withdrawEarnings() external onlyOwner {
        uint256 amount = feeEarned;
        feeEarned = 0;
        payable(msg.sender).transfer(amount);
    }

    function withdrawEverythingFromMyBalance() external {
        uint256 amount = balances[msg.sender];

        require(amount > 0, "nothing to withdraw");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function refundAmountFromBalance(address _address, uint256 _amount) external onlyOwner {
        require(balances[_address] >= _amount, "Insufficient balance");

        balances[_address] -= _amount;
        payable(_address).transfer(_amount);
    }

    function chargeDailyFee() public {
        require(lastFeeChargedAt == 0 || block.timestamp >= lastFeeChargedAt + 1 days);
        lastFeeChargedAt = block.timestamp;

        uint256[] memory ids = interactWith();

        for (uint256 i = 0; i < ids.length; i++) {
            if (balances[pets[ids[i]]] >= pricePerPetPerDay) {
                balances[pets[ids[i]]] -= pricePerPetPerDay;
                feeEarned += pricePerPetPerDay;
            }
        }
    }

    function getFeeEarned() public view returns (uint256) {
        return feeEarned;
    }

    function getBalanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function getAavegotchi(uint256 _id) public view returns (AavegotchiInfo memory) {
        return IGotchiContract(gotchiContract).getAavegotchi(_id);
    }

    function getLastInteractedAt(uint256 _id) public view returns (uint256) {
        return IGotchiContract(gotchiContract).getAavegotchi(_id).lastInteracted;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    fallback() external payable {
        balances[msg.sender] += msg.value;
    }
}