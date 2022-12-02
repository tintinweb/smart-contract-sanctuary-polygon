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

contract LandSalePayment is Ownable, ReentrancyGuard{
    using SafeMath for uint256;

    IERC20 private FT;
    IERC721 private NFT;

    string[] private _categoryArr;

    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public slotCount;
    uint256 public TVKinUSDprice;
    uint256 public ETHinUSDprice;

    address private adminAddress;
    address payable private withdrawAddress;

    mapping (uint256 => string) private tokenLandCategory;
    mapping (string => categoryDetail) private landCategory;
    mapping (uint256 => slotDetails) private slot;
    mapping (bytes => bool) private signature;

    struct categoryDetail{
        uint256 priceInUSD;
        // uint256 priceInETH;
        uint256 mintedCategorySupply;
        uint256 maxCategorySupply;
        bool status;
    }

    struct slotDetails{
        uint256 startTime;
        uint256 endTime;
        mapping (string => bool) categoryEnabled;
    }

    constructor(address _FTaddress, address _NFTaddress, string[] memory _category, uint256[] memory _priceInUSD, uint256[] memory _maxCategorySupply/*, uint256[] memory _slot, uint256[] memory _startTime, uint256[] memory _endTime, bool[][] memory _status*/){

        FT = IERC20(_FTaddress);
        NFT = IERC721(_NFTaddress);
       
        adminAddress = 0x23Fb1484a426fe01F8883a8E27f61c1a7F35dA37;//0x7999a633f5587abd3aE670a230445e282e336aC0;

        slotCount = 0;
        TVKinUSDprice = 31_570_000000000000000;
        ETHinUSDprice =       779_000000000000;
        maxSupply = 80;

        _categoryArr.push("SMALL");
        _categoryArr.push("MEDIUM");
        _categoryArr.push("LARGE");
        _categoryArr.push("CONDO");
        _categoryArr.push("GIGA");

        for(uint index=0; index<_categoryArr.length; index++){
            addNewLandCategory(_category[index], _priceInUSD[index], _maxCategorySupply[index]);
        }

        // for(uint index=0; index<_slot.length; index++){
        //     addNewSlot(_slot[index], _startTime[index], _endTime[index], _categoryArr, _status[index]);
        // }

        set();

    }

    function set() internal {
        slot[1].startTime = 1669795200;
        slot[1].endTime = 1669795500;

        slot[2].startTime = 1669795620;
        slot[2].endTime = 1669795920;

        slot[3].startTime = 1669796040;
        slot[3].endTime = 1669796340;

        slot[4].startTime = 1669796460;
        slot[4].endTime = 1669796760;

        slot[5].startTime = 1669796880;
        slot[5].endTime = 1669797180;

        slot[6].startTime = 1669797300;
        slot[6].endTime = 1669797600;

        slot[7].startTime = 1669797720;
        slot[7].endTime = 1669798020;

        slot[8].startTime = 1669798140;
        slot[8].endTime = 1669798440;

        slot[9].startTime = 1669798560;
        slot[9].endTime = 1669798860;

        slot[10].startTime = 1669798980;
        slot[10].endTime = 1669799280;

        slot[11].startTime = 1669799400;
        slot[11].endTime = 1669799700;

        slot[12].startTime = 1669799820;
        slot[12].endTime = 1669800120;

        slot[13].startTime = 1669800240;
        slot[13].endTime =1669800540;

        slot[14].startTime = 1669800660;
        slot[14].endTime = 1669800960;

        slot[15].startTime = 1669801080;
        slot[15].endTime = 1669801380;

        slot[16].startTime = 1669801500;
        slot[16].endTime = 1669801800;

        
        slot[1].categoryEnabled["SMALL"] = false;
        slot[2].categoryEnabled["SMALL"] = false;
        slot[3].categoryEnabled["SMALL"] = false;
        slot[4].categoryEnabled["SMALL"] = false;
        slot[5].categoryEnabled["SMALL"] = true;
        slot[6].categoryEnabled["SMALL"] = true;
        slot[7].categoryEnabled["SMALL"] = true;
        slot[8].categoryEnabled["SMALL"] = true;
        slot[9].categoryEnabled["SMALL"] = true;
        slot[10].categoryEnabled["SMALL"] = true;
        slot[11].categoryEnabled["SMALL"] = true;
        slot[12].categoryEnabled["SMALL"] = true;
        slot[13].categoryEnabled["SMALL"] = true;
        slot[14].categoryEnabled["SMALL"] = true;
        slot[15].categoryEnabled["SMALL"] = true;
        slot[16].categoryEnabled["SMALL"] = true;

       
        slot[1].categoryEnabled["MEDIUM"] = false;
        slot[2].categoryEnabled["MEDIUM"] = false;
        slot[3].categoryEnabled["MEDIUM"] = false;
        slot[4].categoryEnabled["MEDIUM"] = false;
        slot[5].categoryEnabled["MEDIUM"] = false;
        slot[6].categoryEnabled["MEDIUM"] = false;
        slot[7].categoryEnabled["MEDIUM"] = false;
        slot[8].categoryEnabled["MEDIUM"] = false;
        slot[9].categoryEnabled["MEDIUM"] = true;
        slot[10].categoryEnabled["MEDIUM"] = true;
        slot[11].categoryEnabled["MEDIUM"] = true;
        slot[12].categoryEnabled["MEDIUM"] = true;
        slot[13].categoryEnabled["MEDIUM"] = true;
        slot[14].categoryEnabled["MEDIUM"] = true;
        slot[15].categoryEnabled["MEDIUM"] = true;
        slot[16].categoryEnabled["MEDIUM"] = true;
        
        
        slot[1].categoryEnabled["LARGE"] = true;
        slot[2].categoryEnabled["LARGE"] = true;
        slot[3].categoryEnabled["LARGE"] = true;
        slot[4].categoryEnabled["LARGE"] = true;
        slot[5].categoryEnabled["LARGE"] = true;
        slot[6].categoryEnabled["LARGE"] = true;
        slot[7].categoryEnabled["LARGE"] = true;
        slot[8].categoryEnabled["LARGE"] = true;
        slot[9].categoryEnabled["LARGE"] = true;
        slot[10].categoryEnabled["LARGE"] = true;
        slot[11].categoryEnabled["LARGE"] = true;
        slot[12].categoryEnabled["LARGE"] = true;
        slot[13].categoryEnabled["LARGE"] = true;
        slot[14].categoryEnabled["LARGE"] = true;
        slot[15].categoryEnabled["LARGE"] = true;
        slot[16].categoryEnabled["LARGE"] = true;

        
        slot[1].categoryEnabled["CONDO"] = true;
        slot[2].categoryEnabled["CONDO"] = true;
        slot[3].categoryEnabled["CONDO"] = true;
        slot[4].categoryEnabled["CONDO"] = true;
        slot[5].categoryEnabled["CONDO"] = true;
        slot[6].categoryEnabled["CONDO"] = true;
        slot[7].categoryEnabled["CONDO"] = true;
        slot[8].categoryEnabled["CONDO"] = true;
        slot[9].categoryEnabled["CONDO"] = true;
        slot[10].categoryEnabled["CONDO"] = true;
        slot[11].categoryEnabled["CONDO"] = true;
        slot[12].categoryEnabled["CONDO"] = true;
        slot[13].categoryEnabled["CONDO"] = true;
        slot[14].categoryEnabled["CONDO"] = true;
        slot[15].categoryEnabled["CONDO"] = true;
        slot[16].categoryEnabled["CONDO"] = true;

        
        slot[1].categoryEnabled["GIGA"] = true;
        slot[2].categoryEnabled["GIGA"] = true;
        slot[3].categoryEnabled["GIGA"] = true;
        slot[4].categoryEnabled["GIGA"] = true;
        slot[5].categoryEnabled["GIGA"] = true;
        slot[6].categoryEnabled["GIGA"] = true;
        slot[7].categoryEnabled["GIGA"] = true;
        slot[8].categoryEnabled["GIGA"] = true;
        slot[9].categoryEnabled["GIGA"] = true;
        slot[10].categoryEnabled["GIGA"] = true;
        slot[11].categoryEnabled["GIGA"] = true;
        slot[12].categoryEnabled["GIGA"] = true;
        slot[13].categoryEnabled["GIGA"] = true;
        slot[14].categoryEnabled["GIGA"] = true;
        slot[15].categoryEnabled["GIGA"] = true;
        slot[16].categoryEnabled["GIGA"] = true;
    }

    function buyLandWithTVK(uint256 _slot, string memory _category, uint256 _tokenId, bytes32 _hash, bytes memory _signature) public {
        require(block.timestamp >= slot[1].startTime,"LandSale: Sale not started yet.");
        require(landCategory[_category].status,"Invalid caetgory.");
        require(recover(_hash,_signature) == adminAddress,"Invalid signature.");
        require(!signature[_signature],"Signature already used!");
        require(FT.allowance(msg.sender,address(this)) >= getlandpriceInTVK(_category),"Dapp: Allowance to spend token not enough.");

        FT.transferFrom(msg.sender,address(this),getlandpriceInTVK(_category));
        signature[_signature] = true;

        buyLand(_slot,_category, _tokenId);
        
        emit landBoughtWithTVK(_slot, _category, _tokenId, getlandpriceInTVK(_category), _signature);
    }

    event landBoughtWithTVK(uint256 slot, string category, uint256 tokenId, uint256 price, bytes signature);

    function buyLandWithETH(uint256 _slot, string memory _category, uint256 _tokenId, bytes32 _hash, bytes memory _signature) public payable {
        require(msg.value == getlandPriceInETH(_category),"Invalid payment");
        require(landCategory[_category].status,"Invalid caetgory");
        require(recover(_hash,_signature) == adminAddress,"Invalid signature.");
        require(!signature[_signature],"Signature already used!");

        buyLand(_slot, _category, _tokenId);

        signature[_signature] = true;

        emit landBoughtWithETH(_slot, _category, _tokenId, msg.value, _signature);
    }

    event landBoughtWithETH(uint256 slot, string category, uint256 tokenId, uint256 price, bytes signature);

    function adminMint(uint256 _slot, string memory, uint256 _tokenId, string memory _category, bytes32 _hash, bytes memory _signature) public onlyOwner {
        require(block.timestamp >= slot[1].startTime,"LandSale: Sale not started yet.");
        require(landCategory[_category].status,"Invalid caetgory.");
        require(recover(_hash,_signature) == adminAddress,"Invalid signature.");
        require(!signature[_signature],"Signature already used!");

        signature[_signature] = true;

        buyLand(_slot,_category, _tokenId);

        emit adminMintedItem(_slot, _category, _tokenId, _signature);
    }

    event adminMintedItem(uint256 slot, string category, uint256 tokenId, bytes signature);

    function buyLand(uint256 _slot, string memory _category, uint256 _tokenId) internal {

        if(_slot == slotCount && block.timestamp>=slot[_slot].startTime){
            require(slot[_slot].categoryEnabled[_category],"Landsale: This land category cannot be bought in this slot");

            mintLand(_category, _tokenId);
        }
        else if(block.timestamp>=slot[_slot].startTime && block.timestamp<=slot[_slot].endTime){
            require(slot[_slot].categoryEnabled[_category],"Landsale: This land category cannot be bought in this slot");

            mintLand(_category, _tokenId);

        }
        else if(block.timestamp>slot[_slot].endTime){

            revert("Slot ended");

        }
        else if(block.timestamp<slot[_slot].startTime){

            revert("Slot not started yet");

        }
        
    }

    function mintLand(string memory _category, uint256 _tokenId) internal {
        require(landCategory[_category].mintedCategorySupply.add(1) <= landCategory[_category].maxCategorySupply,"LandSale: max category supply reached");

        landCategory[_category].mintedCategorySupply++;
        totalSupply++;
        tokenLandCategory[_tokenId] = _category;

        NFT.mint(msg.sender,_tokenId);
    }

    function addNewLandCategory(string memory _category, uint256 _priceInUSD, uint256 _maxCategorySupply) public onlyOwner{
        require(landCategory[_category].status == false,"LandSale: Already existing category.");
        require(_priceInUSD > 0,"LandSale: Invalid price in TVK.");
        require(_maxCategorySupply > 0,"LandSale: Invalid max Supply");

        landCategory[_category].priceInUSD = _priceInUSD.mul(1 ether);
        landCategory[_category].status = true;
        landCategory[_category].maxCategorySupply = _maxCategorySupply;

        emit newLandCategoryAdded(_category,_priceInUSD, _maxCategorySupply);
    }

    event newLandCategoryAdded(string category, uint256 price, uint256 maxCategorySupply);

    function addNewSlot(uint256 _slot, uint256 _startTime, uint256 _endTime, string[] memory _category, bool[] memory _status) public onlyOwner{
        require(_startTime > 0,"invalid start time");
        require(_endTime > 0,"invalid end time");
        require(_category.length == _status.length,"invalid length of category and status");

        slot[_slot].startTime = _startTime;
        slot[_slot].endTime = _endTime;

        for(uint index=0; index<_category.length; index++){
            slot[_slot].categoryEnabled[_category[index]] = _status[index];
        }
        slotCount++;

        emit newSlotAdded(_slot, _startTime, _endTime, _category, _status);
    }

    event newSlotAdded(uint256 slot, uint256 startTime, uint256 endTime, string[] category, bool[] status);

    function updateTVKInUSDPrice(uint256 _TVKinUSDprice) public onlyOwner{
        require(_TVKinUSDprice > 0,"");

        TVKinUSDprice = _TVKinUSDprice;

        emit TVKinUSDPriceUpdated(_TVKinUSDprice);
    }

    event TVKinUSDPriceUpdated(uint256 price);

    function updateETHInUSDPrice(uint256 _ETHinUSDprice) public onlyOwner{
        require(_ETHinUSDprice>0,"");

        TVKinUSDprice = _ETHinUSDprice;
        
        emit ETHinUSDPriceUpdated(_ETHinUSDprice);
    }

    event ETHinUSDPriceUpdated(uint256 price);

    function updateLandCategorypriceInUSD(string memory _category, uint256 _price) public onlyOwner{
        require(landCategory[_category].status == true,"LandSale: Non-Existing category.");
        require(_price > 0,"LandSale: Invalid price.");

        landCategory[_category].priceInUSD = _price;

        emit landCategoryPriceUpdated(_category, _price);
    }

    event landCategoryPriceUpdated(string category, uint256 price);

    function updateCategoryAvailabilityStatusInSlot(string memory _category,uint256 _slot, bool _status) public onlyOwner{
        require(landCategory[_category].status,"");

        slot[_slot].categoryEnabled[_category] = _status;

        emit categoryAvailabilityInSlotUpdated(_category,_slot,_status);
    }

    event categoryAvailabilityInSlotUpdated(string category, uint256 slot, bool status);

    function updateSlotStartTime(uint256 _slot, uint256 _startTime) public onlyOwner{
        require(_slot>0  && _slot<=8,"Invalid slot.");
        require(_startTime>0,"Invalid start time.");

        slot[_slot].startTime = _startTime;

        emit slotStartTimeUpdated(_slot,_startTime);
    }

    event slotStartTimeUpdated(uint256 slot, uint256 startTime);

    function updateSlotEndTime(uint256 _slot, uint256 _endTime) public onlyOwner{
        require(_slot>0  && _slot<=8,"Invalid slot.");
        require(_endTime>0,"Invalid start time.");

        slot[_slot].endTime = _endTime;

        emit slotEndTimeUpdated(_slot,_endTime);
    }

    event slotEndTimeUpdated(uint256 slot, uint256 endTime);

    function updateAdminAddress(address _address) public onlyOwner{
        require(_address != address(0),"Invalid address!");

        adminAddress = _address;

        emit adminAddressUpdated(_address);
    }

    event adminAddressUpdated(address newAddress);

    function updateFTAddress(address _address) public onlyOwner{
        require(_address != address(0),"Invalid address!");

        FT = IERC20(_address);

        emit FTAddressUpdated(_address);
    }

    event FTAddressUpdated(address newAddress);

    function updateNFTAddress(address _address) public onlyOwner{
        require(_address != address(0),"Invalid address!");

        NFT = IERC721(_address);

        emit NFTAddressUpdated(_address);
    }

    event NFTAddressUpdated(address newAddress);

    function updateWithdrawAddress(address payable _withdrawAddress) public onlyOwner{

        require(_withdrawAddress != address(0),"Dapp: Invalid address.");

        withdrawAddress = _withdrawAddress;

        emit withdrawAddressUpdated(_withdrawAddress);

    }

    event withdrawAddressUpdated(address newAddress);

    function withdrawEthFunds(uint256 _amount) public onlyOwner nonReentrant{

        require(_amount > 0,"Dapp: invalid amount.");

        withdrawAddress.transfer(_amount);

        emit ETHFundsWithdrawn(_amount);

    }

    event ETHFundsWithdrawn(uint256 amount);

    function withdrawTokenFunds(uint256 _amount) public onlyOwner nonReentrant{

        require(_amount > 0,"Dapp: invalid amount.");

        FT.transfer(withdrawAddress,_amount);

        emit TVKFundsWithdrawn(_amount);

    }

    event TVKFundsWithdrawn(uint256 amount);

    function getTokenBalance() public view returns(uint256){

        return FT.balanceOf(address(this));

    }

    function getWithdrawAddress() public view returns(address){

        return withdrawAddress;

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

    function getCategoryDetailsBySlot(string memory _category, uint256 _slot) public view returns(bool _status){
        _status = slot[_slot].categoryEnabled[_category];
    }

    function getCategoryDetails(string memory _category) public view returns(uint256 _priceInUSD, uint256 _maxSlotCategorySupply, uint256 _mintedCategorySupply, bool _status){
        _priceInUSD = landCategory[_category].priceInUSD;
        _mintedCategorySupply = landCategory[_category].mintedCategorySupply;
        _maxSlotCategorySupply = landCategory[_category].maxCategorySupply;
        _status = landCategory[_category].status;
    }

    function getlandpriceInTVK(string memory _category) public view returns(uint256 _price){
        _price = (landCategory[_category].priceInUSD.mul(TVKinUSDprice)).div(1 ether);
    }

    function getlandPriceInETH(string memory _category) public view returns(uint256 _price){
        _price = (landCategory[_category].priceInUSD.mul(ETHinUSDprice)).div(1 ether);
    }

    function checkSignatureValidity(bytes memory _signature) public view returns(bool){
        return signature[_signature];
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