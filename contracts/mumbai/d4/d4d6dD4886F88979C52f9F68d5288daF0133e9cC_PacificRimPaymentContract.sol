// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
}

contract PacificRimPaymentContract is Ownable {
    using SafeMath for uint256;

    IERC721 NFT; // ERC721 contract instance

    uint256 private ethAmount; // amount of each nft 0 at the time of deployment
    uint256 private cappedSupply; // capped supply 5000
    uint256 private mintedSupply; // minted supply 0 at deployment time
    uint256 private preSaleTime; // starting time of presale
    uint256 private preSaleDuration; // duration of presale mint
    uint256 private preSaleMintLimit; // in case of pre sale mint and whitelist mint
    uint256 private whitelistSaleTime; // starting time of whitelist
    uint256 private whitelistSaleDuration; // duration of whitelist mint
    uint256 private whitelistSaleMintLimit; // in case of pre sale mint and whitelist mint
    uint256 private publicSaleTime; // starting time of public sale
    uint256 private publicSaleDuration; // duration of public sale mint

    address payable private withdrawAddress; // address who can withdraw eth
    address private signatureAddress;

    mapping(address => uint256) private mintBalancePreSale; // in case of presale mint and whitlist mint
    mapping(address => uint256) private mintBalanceWhitelistSale;
    mapping (bytes => bool) private signatures;

    event PreSaleMint(address indexed to, uint256 indexed tokenId);
    event WhitelistSaleMint(address indexed to, uint256 indexed tokenId);
    event PublicSaleMint(address indexed to, uint256 indexed tokenId);
    event preSaleTimeUpdate(uint256 indexed time);
    event preSaleDurationUpdate(uint256 indexed duration);
    event whitelistSaleTimeUpdate(uint256 indexed time);
    event whitelistSaleDurationUpdate(uint256 indexed duration);
    event publicSaleTimeUpdate(uint256 indexed time);
    event publicSaleDurationUpdate(uint256 indexed duration);
    event ETHFundsWithdrawn(uint256 indexed amount, address indexed _address);
    event withdrawAddressUpdated(address indexed newAddress);
    event NFTAddressUpdated(address indexed newAddress);
    event UpdateETHAmount(address indexed owner, uint256 indexed amount);
    event signatureAddressUpdated(address indexed _address);

    event WithdrawETH(uint256 indexed amount, address indexed to); // withdraw eth event
    event Airdrop(address[] indexed to, uint256[] indexed tokenId);
    
    event MintingDuration(uint256 indexed presaleDuration,uint256 indexed whitelistDuration,uint256 indexed publicsaleDuration);
    event MintingStartingTime(uint256 indexed presaleTime,uint256 indexed whitelistTime,uint256 indexed publicsaleTime);
    event CappedSupply(address indexed owner, uint256 indexed supply);
    event PerTransactionCount(address indexed owner, uint256 indexed count);
    event MintingLimit(address indexed owner, uint256 indexed limit);
    event ContractAddress(address indexed owner,address indexed contractAddress);

    constructor(address _NFTaddress,address payable _withdrawAddress) {
        NFT = IERC721(_NFTaddress);

        ethAmount = 0 ether;
        cappedSupply = 5000;
        mintedSupply = 0;
        preSaleMintLimit = 2;
        whitelistSaleMintLimit = 1;

        preSaleTime = 1670853076; // presale 23-12-22 00:00:00
        preSaleDuration = 5 minutes;

        whitelistSaleTime = 1670893169; // whitelist mint 23-12-22 00:15:00
        whitelistSaleDuration = 5 minutes;

        publicSaleTime = 1679854169; // public sale 23-12-22 01:00:00
        publicSaleDuration = 7 minutes;

        withdrawAddress = _withdrawAddress;
        signatureAddress = 0x23Fb1484a426fe01F8883a8E27f61c1a7F35dA37;//0x7999a633f5587abd3aE670a230445e282e336aC0;
    }

    function presaleMint(uint256 _tokenId, bytes32 _hash, bytes memory _signature) public payable{
        require(msg.value == ethAmount,"Dapp: Invalid value!");
        require(block.timestamp >= preSaleTime,"Dapp: Presale not started!");
        require(block.timestamp <= preSaleTime.add(preSaleDuration),"Dapp: Presale ended!");
        require(mintBalancePreSale[msg.sender].add(1) <= preSaleMintLimit,"Dapp: Wallet's presale mint limit exceeded!");
        require(mintedSupply.add(1) <= cappedSupply,"Dapp: Max supply limit exceeded!");
        require(recover(_hash,_signature) == signatureAddress,"Dapp: Invalid signature!");
        require(!signatures[_signature],"Dapp: Signature already used!");

        NFT.mint(msg.sender, _tokenId);
        mintedSupply++;
        mintBalancePreSale[msg.sender]++;

        signatures[_signature] = true;

        emit PreSaleMint(msg.sender, _tokenId);
    }

    function whitelistMint(uint256 _tokenId, bytes32 _hash, bytes memory _signature) public payable{
        require(msg.value == ethAmount,"Dapp: Invalid value!");
        require(block.timestamp >= whitelistSaleTime,"Dapp: Whitelisted sale not started!");
        require(block.timestamp <= whitelistSaleTime.add(whitelistSaleDuration),"Dapp: Whitelisted sale ended!");
        require(mintBalanceWhitelistSale[msg.sender].add(1) <= whitelistSaleMintLimit,"Dapp: Wallet's whitelisted sale mint limit exceeded!");
        require(mintedSupply.add(1) <= cappedSupply,"Dapp: Max supply limit exceeded!");
        require(recover(_hash,_signature) == signatureAddress,"Dapp: Invalid signature!");
        require(!signatures[_signature],"Dapp: Signature already used!");

        NFT.mint(msg.sender, _tokenId);
        mintedSupply++;
        mintBalanceWhitelistSale[msg.sender]++;

        signatures[_signature] = true;

        emit WhitelistSaleMint(msg.sender, _tokenId);
    }

    function publicMint(uint256 _tokenId, bytes32 _hash, bytes memory _signature) public payable{
        require(msg.value == ethAmount,"Dapp: Invalid value!");
        require(block.timestamp >= publicSaleTime,"Dapp: Public sale not started!");
        require(block.timestamp <= publicSaleTime.add(publicSaleDuration),"Dapp: Public sale ended!");
        require(mintedSupply.add(1) <= cappedSupply,"Dapp: Max supply limit exceeded!");
        require(recover(_hash,_signature) == signatureAddress,"Dapp: Invalid signature!");
        require(!signatures[_signature],"Dapp: Signature already used!");

        NFT.mint(msg.sender, _tokenId);
        mintedSupply++;

        signatures[_signature] = true;

        emit PublicSaleMint(msg.sender, _tokenId);
    }

    function updatePresaleTime(uint256 _presaleTime) public onlyOwner{
        require(_presaleTime>block.timestamp,"Dapp: Start time should be greater than current time!");

        preSaleTime = _presaleTime;

        emit preSaleTimeUpdate(_presaleTime);
    }

    function updatePresaleDuration(uint256 _presaleDuration) public onlyOwner{
        require(_presaleDuration>0,"Dapp: Invalid duration value!");

        preSaleDuration = _presaleDuration;

        emit preSaleDurationUpdate(_presaleDuration);
    }

    function updateWhitelistSaleTime(uint256 _whitelistSaleTime) public onlyOwner{
        require(_whitelistSaleTime>preSaleTime.add(preSaleDuration),"Dapp: Whitelist sale start time should be greater than presale duration!");

        whitelistSaleTime = _whitelistSaleTime;

        emit whitelistSaleTimeUpdate(_whitelistSaleTime);
    }

    function updateWhitelistSaleDuration(uint256 _whitelistSaleDuration) public onlyOwner{
        require(_whitelistSaleDuration>0,"Dapp: Invalid duration value!");

        whitelistSaleDuration = _whitelistSaleDuration;

        emit whitelistSaleDurationUpdate(_whitelistSaleDuration);
    }

    function updatePublicSaleTime(uint256 _publicSaleTime) public onlyOwner{
        require(_publicSaleTime>whitelistSaleTime.add(whitelistSaleDuration),"Dapp: Public sale start time should be greater than whitelist sale duration!");

        publicSaleTime = _publicSaleTime;

        emit publicSaleTimeUpdate(_publicSaleTime);
    }

    function updatePublicSaleDuration(uint256 _publicSaleDuration) public onlyOwner{
        require(_publicSaleDuration>0,"Dapp: Invalid duration value!");

        publicSaleDuration = _publicSaleDuration;

        emit publicSaleDurationUpdate(_publicSaleDuration);
    }

    function withdrawEthFunds(uint256 _amount) public onlyOwner {

        require(_amount > 0,"Dapp: invalid amount.");

        withdrawAddress.transfer(_amount);
        emit ETHFundsWithdrawn(_amount, msg.sender);

    }

    function updateWithdrawAddress(address payable _withdrawAddress) public onlyOwner{
        require(_withdrawAddress != withdrawAddress,"Dapp: Invalid address.");
        require(_withdrawAddress != address(0),"Dapp: Invalid address.");

        withdrawAddress = _withdrawAddress;
        emit withdrawAddressUpdated(_withdrawAddress);

    }

    function airdrop(address[] memory to, uint256[] memory tokenId) public onlyOwner{
        require(to.length == tokenId.length,"Dapp: Length of token id and address are not equal!");
        require(mintedSupply + tokenId.length <= cappedSupply,"Dapp: Capped value rached!");
        for (uint index = 0; index < to.length; index++) {
            NFT.mint(to[index], tokenId[index]);
            mintedSupply++;
        }
        emit Airdrop(to, tokenId);
    }

    function updateCappedValue(uint256 _value) public onlyOwner {
        require(_value > mintedSupply, "Dapp: Invalid capped value!");
        require(_value != 0, "Dapp: Capped value cannot be zero!");
        cappedSupply = _value;
        emit CappedSupply(msg.sender, _value);
    }

    function updatePreSaleMintLimit(uint256 _limit) public onlyOwner {
        require(_limit != 0, "Dapp: Cannot set to zero!");
        preSaleMintLimit = _limit;
        emit MintingLimit(msg.sender, _limit);
    }

    function updateWhitelistSaleMintLimit(uint256 _limit) public onlyOwner {
        require(_limit != 0, "Dapp: Cannot set to zero!");
        whitelistSaleMintLimit = _limit;
        emit MintingLimit(msg.sender, _limit);
    }

    function updateNFTAddress(address _address) public onlyOwner {
        require(_address != address(0),"Dapp: Invalid address!");
        require(IERC721(_address) != NFT, "Dapp: Address already exist.");
        NFT = IERC721(_address);

        emit NFTAddressUpdated(_address);
    }

    function updateEthAmount(uint256 _amount) public onlyOwner {
        require(_amount != 0, "Dapp: Invalid amount!");
        ethAmount = _amount;
        emit UpdateETHAmount(msg.sender, _amount);
    }

    function updateSignatureAddress(address _signatureAddress) public onlyOwner{
        require(_signatureAddress != address(0),"Dapp: Invalid address!");
        require(_signatureAddress != signatureAddress,"Dapp! Old address passed again!");

        signatureAddress = _signatureAddress;

        emit signatureAddressUpdated(_signatureAddress);
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

    function getSignatureAddress() public view returns(address _signatureAddress){
        _signatureAddress = signatureAddress;
    }

    function checkSignatureValidity(bytes memory _signature) public view returns(bool){
        return signatures[_signature];
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