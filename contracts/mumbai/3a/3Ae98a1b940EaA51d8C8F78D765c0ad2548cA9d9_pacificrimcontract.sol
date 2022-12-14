// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokneId) external view returns (address owner);
}

contract pacificrimcontract is Ownable {
    using SafeMath for uint256;

    IERC721 NFT; // ERC721 contract instance

    uint256 public ethAmount; // amount of each nft 0 at the time of deployment

    uint256 public cappedSupply; // capped supply 5000
    uint256 public mintedSupply; // minted supply 0 at deployment time

    uint256 public preSaleTime; // starting time of presale
    uint256 public preSaleDuration; // duration of presale mint
    uint256 public preSaleMintLimit; // in case of pre sale mint and whitelist mint

    uint256 public whitelistSaleTime; // starting time of whitelist
    uint256 public whitelistSaleDuration; // duration of whitelist mint
    uint256 public whitelistSaleMintLimit; // in case of pre sale mint and whitelist mint

    uint256 public publicSaleTime; // starting time of public sale
    uint256 public publicSaleDuration; // duration of public sale mint

    address payable public withdrawAddress; // address who can withdraw eth

    mapping(address => uint256) public mintBalancePreSale; // in case of presale mint and whitlist mint
    mapping(address => uint256) public mintBalanceWhitelistSale;

    event WithdrawETH(uint256 indexed amount, address indexed to); // withdraw eth event
    event Airdrop(address[] indexed to, uint256[] indexed tokenId);
    event PresaleMint(address indexed to, uint256[] indexed tokenId);
    event WhitelistMint(address indexed to, uint256[] indexed tokenId);
    event PublicSale(address indexed to, uint256[] indexed tokenId);
    event MintingDuration(uint256 indexed presaleDuration,uint256 indexed whitelistDuration,uint256 indexed publicsaleDuration);
    event MintingStartingTime(uint256 indexed presaleTime,uint256 indexed whitelistTime,uint256 indexed publicsaleTime);
    event CappedSupply(address indexed owner, uint256 indexed supply);
    event PerTransactionCount(address indexed owner, uint256 indexed count);
    event MintingLimit(address indexed owner, uint256 indexed limit);
    event ContractAddress(address indexed owner,address indexed contractAddress);
    event UpdateAmount(address indexed owner, uint256 indexed amount);
    event WithdrawAddress(address indexed owner,address indexed withdrawAddress);

    constructor(address _NFTaddress,uint256 _presaleTime,uint256 _whitelistTime,uint256 _publicsaleTime,address payable _withdrawAddress) {
        NFT = IERC721(_NFTaddress);

        ethAmount = 0 ether;
        cappedSupply = 5000;
        mintedSupply = 0;
        // perTransactionCount = 5;
        preSaleMintLimit = 2;
        whitelistSaleMintLimit = 1;

        preSaleTime = _presaleTime; // 1670853076; // presale 23-12-22 00:00:00
        preSaleDuration = 5 minutes;

        whitelistSaleTime = _whitelistTime; //1670893169; // whitelist mint 23-12-22 00:15:00
        whitelistSaleDuration = 5 minutes;

        publicSaleTime = _publicsaleTime; //1679854169; // public sale 23-12-22 01:00:00
        publicSaleDuration = 7 minutes;

        withdrawAddress = _withdrawAddress;
    }

    function presaleMint(uint256 _tokenId) public payable{
        require(msg.value == ethAmount,"");
        require(block.timestamp >= preSaleTime,"");
        require(block.timestamp<= preSaleTime.add(preSaleDuration),"");
        require(mintBalancePreSale[msg.sender].add(1) < preSaleMintLimit,"");
        require(mintedSupply.add(1) <= cappedSupply,"");

        NFT.mint(msg.sender, _tokenId);
        mintedSupply++;
        mintBalancePreSale[msg.sender]++;

    }

    function whitelistMint(uint256 _tokenId) public payable{
        require(msg.value == ethAmount,"");
        require(block.timestamp >= whitelistSaleTime,"");
        require(block.timestamp<= whitelistSaleTime.add(whitelistSaleDuration),"");
        require(mintBalanceWhitelistSale[msg.sender].add(1) < whitelistSaleMintLimit,""); //= sign
        require(mintedSupply.add(1) <= cappedSupply,"");

        NFT.mint(msg.sender, _tokenId);
        mintedSupply++;
        mintBalanceWhitelistSale[msg.sender]++;
    }

    function publicMint(uint256 _tokenId) public payable{
        require(msg.value == ethAmount,"");
        require(block.timestamp >= publicSaleTime,"");
        require(block.timestamp<= publicSaleTime.add(publicSaleDuration),"");
        require(mintedSupply.add(1) <= cappedSupply,"");

        NFT.mint(msg.sender, _tokenId);
        mintedSupply++;
    }

    function updatePresaleTime(uint256 _presaleTime) public{
        require(_presaleTime>block.timestamp,"");

        preSaleTime = _presaleTime;
    }

    function updatePresaleDuration(uint256 _presaleDuration) public{
        require(_presaleDuration>0,"");

        preSaleDuration = _presaleDuration;
    }

    function updateWhitelistSaleTime(uint256 _whitelistSaleTime) public{
        require(_whitelistSaleTime>preSaleTime.add(preSaleDuration),"");

        whitelistSaleTime = _whitelistSaleTime;
    }

    function updateWhitelistSaleDuration(uint256 _whitelistSaleDuration) public{
        require(_whitelistSaleDuration>0,"");

        whitelistSaleDuration = _whitelistSaleDuration;
    }

    function updatePublicSaleTime(uint256 _publicSaleTime) public{
        require(_publicSaleTime>whitelistSaleTime.add(whitelistSaleDuration),"");

        publicSaleTime = _publicSaleTime;
    }

    function updatePublicSaleDuration(uint256 _publicSaleDuration) public{
        require(_publicSaleDuration>0,"");

        publicSaleDuration = _publicSaleDuration;
    }

    function withdrawEthFunds(uint256 _amount) public onlyOwner{

        require(_amount > 0,"Dapp: invalid amount.");

        withdrawAddress.transfer(_amount);
        // emit ethFundsWithdraw(_amount, msg.sender);

    }

    function updateWithdrawAddress(address payable _withdrawAddress) public onlyOwner{
        require(_withdrawAddress != withdrawAddress,"Dapp: Invalid address.");
        require(_withdrawAddress != address(0),"Dapp: Invalid address.");

        withdrawAddress = _withdrawAddress;
        // emit withdrawAddressUpdated(_withdrawAddress);

    }

    function airdrop(address[] memory to, uint256[] memory tokenId) public onlyOwner{
        require(to.length == tokenId.length,"length of token id and address should be same");
        require(mintedSupply + tokenId.length <= cappedSupply,"capped value rached");
        for (uint256 i = 0; i < to.length; i++) {
            require(mintedSupply <= cappedSupply,"capped value reached can't mint");
            NFT.mint(to[i], tokenId[i]);
            mintedSupply++;
        }
        emit Airdrop(to, tokenId);
    }

    function updateCappedValue(uint256 _value) public onlyOwner {
        require(_value > mintedSupply, "invlid capped value");
        require(_value != 0, "capped value cannot be zero");
        cappedSupply = _value;
        emit CappedSupply(msg.sender, _value);
    }

    function updatePreSaleMintLimit(uint256 _limit) public onlyOwner {
        require(_limit != 0, "cannot set to zero");
        preSaleMintLimit = _limit;
        emit MintingLimit(msg.sender, _limit);
    }

    function updateWhitelistSaleMintLimit(uint256 _limit) public onlyOwner {
        require(_limit != 0, "cannot set to zero");
        whitelistSaleMintLimit = _limit;
        emit MintingLimit(msg.sender, _limit);
    }

    function updateNFTAddress(address _address) public onlyOwner {
        require(_address != address(0),"address can't be set to address of zero");
        require(IERC721(_address) != NFT, "Payment: Address already exist.");
        NFT = IERC721(_address);
    }

    function updateEthAmount(uint256 _amount) public onlyOwner {
        require(_amount != 0, "invalid amount");
        ethAmount = _amount;
        emit UpdateAmount(msg.sender, _amount);
    }

    function getEthAmount() public view returns(uint256){
        return ethAmount;
    }

    function getCappedSupply() public view returns(uint256){
        return cappedSupply;
    }

    function getmintedSupply() public view returns(uint256){
        return mintedSupply;
    }

    function getPreSaleTime() public view returns(uint256){
        return preSaleTime;
    }

    function getPreSaleDuration() public view returns(uint256){
        return preSaleDuration;
    }

    function getPreSaleMintLimit() public view returns(uint256){
        return preSaleMintLimit;
    }

    function getWhitelistSaleTime() public view returns(uint256){
        return whitelistSaleTime;
    }

    function getWhitelistSaleDuration() public view returns(uint256){
        return whitelistSaleDuration;
    }

    function getWhitelistSaleMintLimit() public view returns(uint256){
        return whitelistSaleMintLimit;
    }

    function getPublicSaleTime() public view returns(uint256){
        return publicSaleTime;
    }

    function getPublicSaleDuration() public view returns(uint256){
        return publicSaleDuration;
    }

    function getWithdrawAddress() public view returns(address){
        return withdrawAddress;
    }

    function getMintBalancePreSale(address _address) public view returns(uint256){
        return mintBalancePreSale[_address];
    }
    
    function getMintBalanceWhitelistedSale(address _address) public view returns(uint256){
        return mintBalanceWhitelistSale[_address];
    }

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