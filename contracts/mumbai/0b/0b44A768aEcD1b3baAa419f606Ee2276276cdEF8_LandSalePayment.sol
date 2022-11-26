// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20{
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721{
    function mint(address to, uint256 tokenId) external;
}

contract LandSalePayment is Ownable{
    using SafeMath for uint256;

    IERC20 private FT;
    IERC721 private NFT;

    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public slotCount;

    address private adminAddress;

    mapping (uint256 => string) private tokenLandCategory;
    mapping (string => categoryDetail) private landCategory;
    mapping (uint256 => slotDetails) private slot;
    mapping (bytes => bool) public signature;

    struct categoryDetail{
        uint256 priceInTVK;
        uint256 priceInETH;
        uint256 mintedCategorySupply;
        uint256 maxCategorySupply;
        bool status;
    }

    struct slotDetails{
        uint256 startTime;
        uint256 endTime;
        mapping (string => slotCategoryDetails) slotCategory;
    }

    struct slotCategoryDetails{
        uint256 maxSlotCategorySupply;
        uint256 mintedSlotCategorySupply;
    }

    constructor(address FTaddress, address NFTaddress){

        FT = IERC20(FTaddress);
        NFT = IERC721(NFTaddress);
       
        adminAddress = 0x23Fb1484a426fe01F8883a8E27f61c1a7F35dA37;

        slot[1].startTime = 1669199400;
        slot[1].endTime = 1669199700;

        slot[2].startTime = 1669199820;
        slot[2].endTime = 1669200120;

        slot[3].startTime = 1669200240;
        slot[3].endTime = 1669200540;

        slot[4].startTime = 1669200660;
        slot[4].endTime = 1669200960;

        slot[5].startTime = 1669201080;
        slot[5].endTime = 1669201380;

        slot[6].startTime = 1669201500;
        slot[6].endTime = 1669201800;

        slot[7].startTime = 1669201920;
        slot[7].endTime = 1669202220;

        slot[8].startTime = 1669202340;
        slot[8].endTime = 1669202640;

        landCategory["SMALL"].status = true;
        landCategory["SMALL"].priceInTVK = 100_000000000000000000;
        landCategory["SMALL"].priceInETH = 1_000000000000000000;
        landCategory["SMALL"].maxCategorySupply = 16;
        slot[1].slotCategory["SMALL"].maxSlotCategorySupply = 2;
        slot[2].slotCategory["SMALL"].maxSlotCategorySupply = 2;
        slot[3].slotCategory["SMALL"].maxSlotCategorySupply = 2;
        slot[4].slotCategory["SMALL"].maxSlotCategorySupply = 2;
        slot[5].slotCategory["SMALL"].maxSlotCategorySupply = 2;
        slot[6].slotCategory["SMALL"].maxSlotCategorySupply = 2;
        slot[7].slotCategory["SMALL"].maxSlotCategorySupply = 2;
        slot[8].slotCategory["SMALL"].maxSlotCategorySupply = 2;

        landCategory["MEDIUM"].status = true;
        landCategory["MEDIUM"].priceInTVK = 200_000000000000000000;
        landCategory["MEDIUM"].priceInETH = 2_000000000000000000;
        landCategory["MEDIUM"].maxCategorySupply = 16;
        slot[1].slotCategory["MEDIUM"].maxSlotCategorySupply = 2;
        slot[2].slotCategory["MEDIUM"].maxSlotCategorySupply = 2;
        slot[3].slotCategory["MEDIUM"].maxSlotCategorySupply = 2;
        slot[4].slotCategory["MEDIUM"].maxSlotCategorySupply = 2;
        slot[5].slotCategory["MEDIUM"].maxSlotCategorySupply = 2;
        slot[6].slotCategory["MEDIUM"].maxSlotCategorySupply = 2;
        slot[7].slotCategory["MEDIUM"].maxSlotCategorySupply = 2;
        slot[8].slotCategory["MEDIUM"].maxSlotCategorySupply = 2;
        
        landCategory["LARGE"].status = true;
        landCategory["LARGE"].priceInTVK = 300_000000000000000000;
        landCategory["LARGE"].priceInETH = 3_000000000000000000;
        landCategory["LARGE"].maxCategorySupply = 16;
        slot[1].slotCategory["LARGE"].maxSlotCategorySupply = 2;
        slot[2].slotCategory["LARGE"].maxSlotCategorySupply = 2;
        slot[3].slotCategory["LARGE"].maxSlotCategorySupply = 2;
        slot[4].slotCategory["LARGE"].maxSlotCategorySupply = 2;
        slot[5].slotCategory["LARGE"].maxSlotCategorySupply = 2;
        slot[6].slotCategory["LARGE"].maxSlotCategorySupply = 2;
        slot[7].slotCategory["LARGE"].maxSlotCategorySupply = 2;
        slot[8].slotCategory["LARGE"].maxSlotCategorySupply = 2;

        landCategory["CONDO"].status = true;
        landCategory["CONDO"].priceInTVK = 50_000000000000000000;
        landCategory["CONDO"].priceInETH = 500000000000000000;
        landCategory["CONDO"].maxCategorySupply = 16;
        slot[1].slotCategory["CONDO"].maxSlotCategorySupply = 2;
        slot[2].slotCategory["CONDO"].maxSlotCategorySupply = 2;
        slot[3].slotCategory["CONDO"].maxSlotCategorySupply = 2;
        slot[4].slotCategory["CONDO"].maxSlotCategorySupply = 2;
        slot[5].slotCategory["CONDO"].maxSlotCategorySupply = 2;
        slot[6].slotCategory["CONDO"].maxSlotCategorySupply = 2;
        slot[7].slotCategory["CONDO"].maxSlotCategorySupply = 2;
        slot[8].slotCategory["CONDO"].maxSlotCategorySupply = 2;

        landCategory["GIGA"].status = true;
        landCategory["GIGA"].priceInTVK = 1000_000000000000000000;
        landCategory["GIGA"].priceInETH = 10_000000000000000000;
        landCategory["GIGA"].maxCategorySupply = 16;
        slot[1].slotCategory["GIGA"].maxSlotCategorySupply = 2;
        slot[2].slotCategory["GIGA"].maxSlotCategorySupply = 2;
        slot[3].slotCategory["GIGA"].maxSlotCategorySupply = 2;
        slot[4].slotCategory["GIGA"].maxSlotCategorySupply = 2;
        slot[5].slotCategory["GIGA"].maxSlotCategorySupply = 2;
        slot[6].slotCategory["GIGA"].maxSlotCategorySupply = 2;
        slot[7].slotCategory["GIGA"].maxSlotCategorySupply = 2;
        slot[8].slotCategory["GIGA"].maxSlotCategorySupply = 2;

        slotCount = 8;
    }

    function buyLandWithTVK(uint256 _slot, string memory _category, uint256 _tokenId, bytes32 _hash, bytes memory _signature) public {
        require(block.timestamp >= slot[1].startTime,"LandSale: Sale not started yet.");
        require(landCategory[_category].status,"Invalid caetgory.");
        require(recover(_hash,_signature) == adminAddress,"Invalid signature.");
        require(FT.allowance(msg.sender,address(this)) >= landCategory[_category].priceInTVK,"Dapp: Allowance to spend token not enough.");

        FT.transferFrom(msg.sender,address(this),landCategory[_category].priceInTVK);
        signature[_signature] = true;

        buyLand(_slot,_category, _tokenId);
        
    }

    function buyLandWithETH(uint256 _slot, string memory _category, uint256 _tokenId, bytes32 _hash, bytes memory _signature) public payable {
        require(msg.value == landCategory[_category].priceInETH,"Invalid payment");
        require(landCategory[_category].status,"Invalid caetgory");
        require(recover(_hash,_signature) == adminAddress,"Invalid signature.");

        buyLand(_slot, _category, _tokenId);

        signature[_signature] = true;
    }

    // function adminMint(uint256[] memory _tokenID, string[] memory _category, bytes32 _hash, bytes memory _signature) public {
    //     require(_tokenID.length == _category.length,"LandSale: Invalid token ID and category count!");
    //     require(recover(_hash,_signature) == adminAddress,"Invalid signature.");


    // }

    function buyLand(uint256 _slot, string memory _category, uint256 _tokenId) internal {
        //slot 1
        if(block.timestamp>=slot[_slot].startTime && block.timestamp<=slot[_slot].endTime){
            require(slot[_slot].slotCategory[_category].mintedSlotCategorySupply.add(1) <= slot[_slot].slotCategory[_category].maxSlotCategorySupply,"exceed slot 1");

            mintLand(_slot,_category, _tokenId);

        }
        else{
            revert("Slot break in progress or sale has ended");
        }
    }

    function mintLand(uint256 _slot, string memory _category, uint256 _tokenId) internal {
        require(landCategory[_category].mintedCategorySupply.add(1) <= landCategory[_category].maxCategorySupply,"LandSale: max category supply reached");

        landCategory[_category].mintedCategorySupply++;
        slot[_slot].slotCategory[_category].mintedSlotCategorySupply++;
        totalSupply++;
        tokenLandCategory[_tokenId] = _category;

        NFT.mint(msg.sender,_tokenId);
    }

    function addNewLandCategory(string memory _category, uint256 _priceInTVK, uint256 _priceInETH, uint256 _maxCategorySupply) public onlyOwner{
        require(landCategory[_category].status == false,"LandSale: Already existing category.");
        require(_priceInTVK > 0,"LandSale: Invalid price in TVK.");
        require(_priceInETH > 0,"LandSale: Invalid price in ETH.");
        require(_maxCategorySupply > 0,"LandSale: Invalid max Supply");

        landCategory[_category].priceInTVK = _priceInTVK;
        landCategory[_category].priceInETH = _priceInETH;
        landCategory[_category].status = false;
        landCategory[_category].maxCategorySupply = _maxCategorySupply;
    }

    function updateLandCategoryPriceInTVK(string memory _category, uint256 _price) public onlyOwner{
        require(landCategory[_category].status == true,"LandSale: Non-Existing category.");
        require(_price > 0,"LandSale: Invalid price.");

        landCategory[_category].priceInTVK = _price;
    
    }

    function updateLandCategoryPriceInETH(string memory _category, uint256 _price) public onlyOwner{
        require(landCategory[_category].status == true,"LandSale: Non-Existing category.");
        require(_price > 0,"LandSale: Invalid price.");

        landCategory[_category].priceInETH = _price;  
    }

    function updateSlotMaxSupplyByCategory(uint256 _slot, string memory _category, uint256 _maxSlotCategorySupply) public onlyOwner{
        require(_slot>0  && _slot<=8,"Invalid slot.");
        require(landCategory[_category].status,"Invalid category.");
        require(_maxSlotCategorySupply > 0,"Invalid maximum supply");

        slot[_slot].slotCategory[_category].maxSlotCategorySupply = _maxSlotCategorySupply;
    }

    function updateSlotStartTime(uint256 _slot, uint256 _startTime) public onlyOwner{
        require(_slot>0  && _slot<=8,"Invalid slot.");
        require(_startTime>0,"Invalid start time.");

        slot[_slot].startTime = _startTime;
    }

    function updateSlotEndTime(uint256 _slot, uint256 _endTime) public onlyOwner{
        require(_slot>0  && _slot<=8,"Invalid slot.");
        require(_endTime>0,"Invalid start time.");

        slot[_slot].endTime = _endTime;
    }

    function addNewSlot(uint256 _slot, uint256 _startTime, uint256 _endTime, string[] memory _category, uint256[] memory _maxSlotCategorySupply) public onlyOwner{
        require(_slot > 0,"");
        require(_startTime > 0,"");
        require(_endTime > 0,"");
        require(_category.length == _maxSlotCategorySupply.length,"");

        slot[_slot].startTime = _startTime;
        slot[_slot].endTime = _endTime;

        for(uint index=0; index<_category.length; index++){
            slot[_slot].slotCategory[_category[index]].maxSlotCategorySupply = _maxSlotCategorySupply[index];
        }
    }

    function updateAdminAddress(address _address) public onlyOwner{
        require(_address != address(0),"Invalid address!");

        adminAddress = _address;
    }

    function updateFTAddress(address _address) public onlyOwner{
        require(_address != address(0),"Invalid address!");

        FT = IERC20(_address);
    }

    function updateNFTAddress(address _address) public onlyOwner{
        require(_address != address(0),"Invalid address!");

        NFT = IERC721(_address);
    }

    function getAdminAddress() public view returns(address _adminAddress){
        _adminAddress = adminAddress;
    }

    function getFTAddress() public view returns(IERC20 _FT){
        _FT = FT;
    }

    function getNFTAddress() public view returns(IERC721 _NFT){
        _NFT = NFT;
    }

    function getSlotStartTimeAndEndTime(uint256 _slot) public view returns(uint256 _startTime, uint256 _endTime){
        _startTime = slot[_slot].startTime;
        _endTime = slot[_slot].endTime;
    }

    function getCategoryDetailsBySlot(string memory _category, uint256 _slot) public view returns(uint256 _maxSlotCategorySupply, uint256 _mintedSlotCategorySupply){
        _maxSlotCategorySupply = slot[_slot].slotCategory[_category].maxSlotCategorySupply;
        _mintedSlotCategorySupply = slot[_slot].slotCategory[_category].mintedSlotCategorySupply;
    }

    function getCategoryDetails(string memory _category) public view returns(uint256 _priceInETH, uint256 _priceInTVK, uint256 _maxSlotCategorySupply, uint256 _mintedCategorySupply, bool _status){
        _priceInETH = landCategory[_category].priceInETH;
        _priceInTVK = landCategory[_category].priceInTVK;
        _mintedCategorySupply = landCategory[_category].mintedCategorySupply;
        _maxSlotCategorySupply = landCategory[_category].maxCategorySupply;
        _status = landCategory[_category].status;
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param _hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param _signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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