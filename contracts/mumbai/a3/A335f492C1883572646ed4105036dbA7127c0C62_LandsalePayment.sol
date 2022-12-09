// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20{
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721{
    function mint(address to, uint256 tokenId) external;
}

contract LandsalePayment is Ownable, ReentrancyGuard{
    using SafeMath for uint256;

    IERC20 private TVK;
    IERC721 private NFT;

    uint256 private totalSupply;
    uint256 private maxSupply;
    uint256 private slotCount;
    uint256 private TVKperUSDprice;
    uint256 private ETHperUSDprice;

    address private signatureAddress; //for admin signature verification
    address payable private withdrawAddress;

    bool private ethPaymentEnabled;

    mapping (uint256 => string) private tokenLandCategory;
    mapping (string => categoryDetail) private landCategory;
    mapping (uint256 => slotDetails) private slot;
    mapping (bytes => bool) private signatures;

    struct categoryDetail{
        uint256 priceInUSD;
        uint256 mintedCategorySupply;
        uint256 maxCategorySupply;
        uint256 startRange;
        uint256 endRange;
        bool status;
        bool slotIndependent;
    }

    struct slotDetails{
        uint256 startTime;
        uint256 endTime;
        mapping (string => slotCategoryDetails) slotSupply;
    }

    struct slotCategoryDetails{
        uint256 maxSlotCategorySupply;
        uint256 mintedSlotCategorySupply;
    }

    event landBoughtWithTVK(uint256 slot, string indexed category, uint256 indexed tokenId, uint256 indexed price, bytes signature, address beneficiary);
    event landBoughtWithETH(uint256 slot, string indexed category, uint256 indexed tokenId, uint256 indexed price, bytes signature, address beneficiary);
    event adminMintedItem(string indexed category, uint256[] tokenId, address[] beneficiary);
    event newLandCategoryAdded(string indexed category, uint256 indexed price, uint256 indexed maxCategorySupply);
    event landCategorySupplyIncreased(uint256 indexed additionalSupply, string indexed category);
    event landCategorySupplyDecreased(uint256 indexed additionalSupply, string indexed category);
    event newSlotAdded(uint256 indexed slot, uint256 indexed startTime, uint256 indexed endTime, string[] category, uint256[] slotSupply);
    event TVKperUSDpriceUpdated(uint256 indexed price);
    event ETHperUSDpriceUpdated(uint256 indexed price);
    event landCategoryPriceUpdated(string indexed category, uint256 indexed price);
    event categoryAvailabilityInSlotUpdated(string indexed category, uint256 indexed slot, uint256 indexed slotSupply);
    event slotStartTimeUpdated(uint256 indexed slot, uint256 indexed startTime);
    event slotEndTimeUpdated(uint256 indexed slot, uint256 indexed endTime);
    event adminAddressUpdated(address indexed newAddress);
    event TVKAddressUpdated(address indexed newAddress);
    event NFTAddressUpdated(address indexed newAddress);
    event withdrawAddressUpdated(address indexed newAddress);
    event ETHFundsWithdrawn(uint256 indexed amount);
    event TVKFundsWithdrawn(uint256 indexed amount);

    constructor(address _TVKaddress, address _NFTaddress, string[] memory _category,bool[] memory _slotDependency, uint256[4][5] memory _categoryDetail, uint256[3][13] memory _slot, uint256[5][13] memory _slotSupply, address payable _withdrawAddress){

        TVK = IERC20(_TVKaddress);
        NFT = IERC721(_NFTaddress);
       
        signatureAddress = 0x23Fb1484a426fe01F8883a8E27f61c1a7F35dA37;//0x7999a633f5587abd3aE670a230445e282e336aC0;
        withdrawAddress = _withdrawAddress;

        TVKperUSDprice = 31_570_000000000000000;
        ETHperUSDprice = 779_000000000000;
        maxSupply = 1002;

        for(uint index=0; index<_category.length; index++){
            landCategory[_category[index]].priceInUSD = _categoryDetail[index][0].mul(1 ether);
            landCategory[_category[index]].status = true;
            landCategory[_category[index]].maxCategorySupply = _categoryDetail[index][1];
            landCategory[_category[index]].slotIndependent = _slotDependency[index];
            landCategory[_category[index]].startRange = _categoryDetail[index][2];
            landCategory[_category[index]].endRange = _categoryDetail[index][3];
        }

        for(uint index=0; index<_slot.length; index++){
            slot[_slot[index][0]].startTime = _slot[index][1];
            slot[_slot[index][0]].endTime = _slot[index][2];
    
            slotCount++;

            slot[_slot[index][0]].slotSupply[_category[0]].maxSlotCategorySupply = _slotSupply[index][0];
            slot[_slot[index][0]].slotSupply[_category[1]].maxSlotCategorySupply = _slotSupply[index][1];
            slot[_slot[index][0]].slotSupply[_category[2]].maxSlotCategorySupply = _slotSupply[index][2];
            slot[_slot[index][0]].slotSupply[_category[3]].maxSlotCategorySupply = _slotSupply[index][3];
            slot[_slot[index][0]].slotSupply[_category[4]].maxSlotCategorySupply = _slotSupply[index][4];
            
        }

    }

    function buyLandWithTVK(uint256 _slot, string memory _category, uint256 _tokenId, bytes32 _hash, bytes memory _signature) public {
        require(block.timestamp >= slot[1].startTime,"LandSale: Sale not started yet!");
        require(landCategory[_category].status,"Invalid caetgory!");
        require(_tokenId>=landCategory[_category].startRange && _tokenId<=landCategory[_category].endRange,"Landsale! Invalid token id for category range!");
        require(recover(_hash,_signature) == signatureAddress,"Landsale: Invalid signature!");
        require(!signatures[_signature],"Landsale: Signature already used!");
        require(TVK.allowance(msg.sender,address(this)) >= getlandpriceInTVK(_category),"Landsale: Allowance to spend token not enough!");

        TVK.transferFrom(msg.sender,address(this),getlandpriceInTVK(_category));

        checkSlot(_slot, _category, _tokenId, msg.sender);

        signatures[_signature] = true;
        
        emit landBoughtWithTVK(_slot, _category, _tokenId, getlandpriceInTVK(_category), _signature, msg.sender);
    }

    function buyLandWithETH(uint256 _slot, string memory _category, uint256 _tokenId, bytes32 _hash, bytes memory _signature) public payable {
        require(ethPaymentEnabled,"Landsale: Eth payment disabled!");
        require(block.timestamp >= slot[1].startTime,"LandSale: Sale not started yet!");
        require(msg.value == getlandPriceInETH(_category),"Landsale: Invalid payment!");
        require(landCategory[_category].status,"Landsale: Invalid caetgory!");
        require(_tokenId>=landCategory[_category].startRange && _tokenId<=landCategory[_category].endRange,"Landsale! Invalid token id for category range!");
        require(recover(_hash,_signature) == signatureAddress,"Landsale: Invalid signature!");
        require(!signatures[_signature],"Landsale: Signature already used!");

        checkSlot(_slot, _category, _tokenId, msg.sender);

        signatures[_signature] = true;

        emit landBoughtWithETH(_slot, _category, _tokenId, msg.value, _signature, msg.sender);
    }

    function adminMint(uint256[] memory _tokenId, string memory _category, address[] memory _beneficiary) public onlyOwner {
        require(landCategory[_category].status,"Landsale: Invalid caetgory!");
        require(landCategory[_category].mintedCategorySupply.add(_tokenId.length) <= landCategory[_category].maxCategorySupply,"LandSale: Max category supply reached!");
        require(totalSupply.add(_tokenId.length) <= maxSupply,"Landsale: Max total supply reached!");
        require(_tokenId.length == _beneficiary.length,"Landsale: Token ids and beneficiary addresses are not equal.");

        for(uint index=0; index<_tokenId.length; index++){
            
            NFT.mint(_beneficiary[index],_tokenId[index]);
            tokenLandCategory[_tokenId[index]] = _category;

        }

        landCategory[_category].mintedCategorySupply = landCategory[_category].mintedCategorySupply.add(_tokenId.length);
        totalSupply = totalSupply.add(_tokenId.length);
        
        emit adminMintedItem(_category, _tokenId, _beneficiary);
    }

    function checkSlot(uint256 _slot, string memory _category, uint256 _tokenId, address _beneficiary) internal {

        if(landCategory[_category].slotIndependent){
            mintToken(_slot,_category, _tokenId, _beneficiary);

        }
        else if(block.timestamp>=slot[_slot].startTime && block.timestamp<=slot[_slot].endTime){
            require(slot[_slot].slotSupply[_category].maxSlotCategorySupply > 0,"Landsale: This land category cannot be bought in this slot!");

            mintToken(_slot,_category, _tokenId, _beneficiary);

        }
        else if(block.timestamp>slot[_slot].endTime){

            revert("Landsale: Slot ended!");

        }
        else if(block.timestamp<slot[_slot].startTime){

            revert("Landsale: Slot not started yet!");

        }
        
    }

    function mintToken(uint256 _slot,string memory _category, uint256 _tokenId, address _beneficiary) internal {
        require(landCategory[_category].mintedCategorySupply.add(1) <= landCategory[_category].maxCategorySupply,"LandSale: Max category supply reached!");
        require(slot[_slot].slotSupply[_category].mintedSlotCategorySupply.add(1) < slot[_slot].slotSupply[_category].maxSlotCategorySupply,"Landsale: Max slot category supply reached!");
        require(totalSupply.add(1) < maxSupply,"Landsale: Max total supply reached!");
        
        slot[_slot].slotSupply[_category].mintedSlotCategorySupply++;
        landCategory[_category].mintedCategorySupply++;
        totalSupply++;
        tokenLandCategory[_tokenId] = _category;

        NFT.mint(_beneficiary,_tokenId);
    }

    function ethPaymentToggle() public onlyOwner{
        if(ethPaymentEnabled){
            ethPaymentEnabled = false;
        }
        else{
            ethPaymentEnabled = true;
        }
    }

    function addNewLandCategory(string memory _category, bool _slotIndependency, uint256 _priceInUSD, uint256 _maxCategorySupply, uint256 _categoryStartRange, uint256 _categoryEndRange) public onlyOwner{
        require(landCategory[_category].status == false,"LandSale: Category already exist!");
        require(_priceInUSD > 0,"LandSale: Invalid price in TVK!");
        require(_maxCategorySupply > 0,"LandSale: Invalid max Supply!");

        landCategory[_category].priceInUSD = _priceInUSD.mul(1 ether);
        landCategory[_category].status = true;
        landCategory[_category].maxCategorySupply = _maxCategorySupply;
        landCategory[_category].slotIndependent = _slotIndependency;
        landCategory[_category].startRange = _categoryStartRange;
        landCategory[_category].endRange = _categoryEndRange;

        maxSupply = maxSupply.add(_maxCategorySupply);

        for(uint index=1; index<=slotCount; index++){
            slot[index].slotSupply[_category].maxSlotCategorySupply = _maxCategorySupply;
        }

        emit newLandCategoryAdded(_category,_priceInUSD, _maxCategorySupply);
    }

    function addNewSlot(uint256 _slot, uint256 _startTime, uint256 _endTime, string[] memory _category, uint256[] memory _slotSupply) public onlyOwner{
        require(_startTime > 0,"Landsale: Invalid start time!");
        require(_endTime > 0,"Landsale: Invalid end time!");
        require(_category.length == _slotSupply.length,"Landsale: Invalid length of category and status!");

        slot[_slot].startTime = _startTime;
        slot[_slot].endTime = _endTime;

        for(uint index=0; index<_category.length; index++){
            slot[_slot].slotSupply[_category[index]].maxSlotCategorySupply = _slotSupply[index];
        }
        slotCount++;

        emit newSlotAdded(_slot, _startTime, _endTime, _category, _slotSupply);
    }

    function updateTVKperUSDprice(uint256 _TVKperUSDprice) public onlyOwner{
        require(_TVKperUSDprice > 0,"Landsale: Invalid price!");

        TVKperUSDprice = _TVKperUSDprice;

        emit TVKperUSDpriceUpdated(_TVKperUSDprice);
    }

    function updateETHperUSDprice(uint256 _ETHperUSDprice) public onlyOwner{
        require(_ETHperUSDprice>0,"Landsale: Invalid price!");

        TVKperUSDprice = _ETHperUSDprice;
        
        emit ETHperUSDpriceUpdated(_ETHperUSDprice);
    }

    function updateLandCategoryPriceInUSD(string memory _category, uint256 _price) public onlyOwner{
        require(landCategory[_category].status == true,"LandSale: Non-Existing category!");
        require(_price > 0,"LandSale: Invalid price!");

        landCategory[_category].priceInUSD = _price;

        emit landCategoryPriceUpdated(_category, _price);
    }

    function updateCategorySupplyInSlot(string memory _category,uint256 _slot, uint256 _slotSupply) public onlyOwner{
        require(landCategory[_category].status,"Landsale: Invalid category!");
        require(landCategory[_category].maxCategorySupply>=_slotSupply,"LandSale: Slot supply cannot be greater than max category supply!");

        slot[_slot].slotSupply[_category].maxSlotCategorySupply = _slotSupply;

        emit categoryAvailabilityInSlotUpdated(_category,_slot,_slotSupply);
    }

    function updateSlotStartTime(uint256 _slot, uint256 _startTime) public onlyOwner{
        require(_slot>0  && _slot<=slotCount,"Landsale: Invalid slot!");
        require(_startTime>0,"Landsale: Invalid start time!");

        slot[_slot].startTime = _startTime;

        emit slotStartTimeUpdated(_slot,_startTime);
    }

    function updateSlotEndTime(uint256 _slot, uint256 _endTime) public onlyOwner{
        require(_slot>0  && _slot<=slotCount,"Landsale: Invalid slot!");
        require(_endTime>0,"Landsale: Invalid start time!");

        slot[_slot].endTime = _endTime;

        emit slotEndTimeUpdated(_slot,_endTime);
    }

    function updateSignatureAddress(address _signatureAddress) public onlyOwner{
        require(_signatureAddress != address(0),"Landsale: Invalid address!");

        signatureAddress = _signatureAddress;

        emit adminAddressUpdated(_signatureAddress);
    }

    function updateTVKAddress(address _address) public onlyOwner{
        require(_address != address(0),"Landsale: Invalid address!");

        TVK = IERC20(_address);

        emit TVKAddressUpdated(_address);
    }

    function updateNFTAddress(address _address) public onlyOwner{
        require(_address != address(0),"Landsale: Invalid address!");

        NFT = IERC721(_address);

        emit NFTAddressUpdated(_address);
    }

    function updateWithdrawAddress(address payable _withdrawAddress) public onlyOwner{

        require(_withdrawAddress != address(0),"Landsale: Invalid address!");

        withdrawAddress = _withdrawAddress;

        emit withdrawAddressUpdated(_withdrawAddress);

    }

    function withdrawEthFunds(uint256 _amount) public onlyOwner nonReentrant{

        require(_amount > 0,"Landsale: invalid amount!");

        withdrawAddress.transfer(_amount);

        emit ETHFundsWithdrawn(_amount);

    }

    function withdrawTokenFunds(uint256 _amount) public onlyOwner nonReentrant{
        require(_amount > 0,"Landsale: invalid amount!");

        TVK.transfer(withdrawAddress,_amount);

        emit TVKFundsWithdrawn(_amount);

    }

    function updateCategoryToSlotIndependent(string memory _category,bool _slotDependency) public onlyOwner{
        require(landCategory[_category].status,"Landsale: Invlaid category!");

        landCategory[_category].slotIndependent = _slotDependency;
    }

    function getTokenBalance() public view returns(uint256){

        return TVK.balanceOf(address(this));

    }

    function getWithdrawAddress() public view returns(address){

        return withdrawAddress;

    }

    function getSignatureAddress() public view returns(address _signatureAddress){
        _signatureAddress = signatureAddress;
    }

    function getTVKAddress() public view returns(IERC20 _TVK){
        _TVK = TVK;
    }

    function getNFTAddress() public view returns(IERC721 _NFT){
        _NFT = NFT;
    }

    function getSlotStartTimeAndEndTime(uint256 _slot) public view returns(uint256 _startTime, uint256 _endTime){
        _startTime = slot[_slot].startTime;
        _endTime = slot[_slot].endTime;
    }

    function getCategorySupplyBySlot(string memory _category, uint256 _slot) public view returns(uint256 _slotSupply){
        _slotSupply = slot[_slot].slotSupply[_category].maxSlotCategorySupply;
    }

    function getCategoryDetails(string memory _category) public view returns(uint256 _priceInUSD, uint256 _maxSlotCategorySupply, uint256 _mintedCategorySupply, bool _status, bool _slotIndependent){
        _priceInUSD = landCategory[_category].priceInUSD;
        _mintedCategorySupply = landCategory[_category].mintedCategorySupply;
        _maxSlotCategorySupply = landCategory[_category].maxCategorySupply;
        _status = landCategory[_category].status;
        _slotIndependent = landCategory[_category].slotIndependent;
    }

    function getCategoryRanges(string memory _category) public view returns(uint256 _startRange, uint256 _endRange){
        _startRange = landCategory[_category].startRange;
        _endRange = landCategory[_category].endRange;
    }

    function getlandpriceInTVK(string memory _category) public view returns(uint256 _price){
        _price = (landCategory[_category].priceInUSD.mul(TVKperUSDprice)).div(1 ether);
    }

    function getlandPriceInETH(string memory _category) public view returns(uint256 _price){
        _price = (landCategory[_category].priceInUSD.mul(ETHperUSDprice)).div(1 ether);
    }

    function checkSignatureValidity(bytes memory _signature) public view returns(bool){
        return signatures[_signature];
    }

    function getTokenLandCategory(uint256 _tokenId) public view returns (string memory){
        return tokenLandCategory[_tokenId];
    }

    function getTotalSupply() public view returns(uint256){
        return totalSupply;
    }

    function getMaxSupply() public view returns(uint256){
        return maxSupply;
    }

    function getSlotCount() public view returns(uint256){
        return slotCount;
    }

    function getTVKperUSDprice() public view returns(uint256){
        return TVKperUSDprice;
    }

    function getETHperUSDprice() public view returns(uint256){
        return ETHperUSDprice;
    }

    function getETHPaymentEnabled() public view returns(bool){
        return ethPaymentEnabled;
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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