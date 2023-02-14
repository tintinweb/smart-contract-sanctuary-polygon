//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Managable.sol";

import "./IBot.sol";
import "./IERC20Burnable.sol";
import "./IBotMetadata.sol";
import "./Ships/IShip.sol";
import "./Ships/IShipMetadata.sol";
import "./ITokenPaymentSplitter.sol";
import "./IRewardsSpender.sol";


contract DamageFix is Managable, Pausable {
    using SafeERC20 for IERC20;

    address public botAddress;
    address public botTeamAddress;
    address public botMetadataAddress;
    address public shipAddress;
    address public shipTeamAddress;
    address public shipMetadataAddress;
    address public oilAddress;
    address public treasuryAddress;
    address public rewardsSpenderAddress;
    uint256 public durabilityPrice;
    uint256 public shipCoefficient; // is equal to real coefficient * 10000
    uint256 public waitTime;
    uint256 public bitsOilRatio; // value of one BITS in Oil * 10000
    uint256 public commissionPercentage; // commission percentage * 10000

    mapping(address => mapping(uint => FixedItem)) public fixedItems; //nft address -> nftId -> FixedItem details

    address public immutable BITS_ADDRESS;

    struct FixedItem {
        uint32 _nextFixTime;
        uint32 _fixEnd;
        uint192 oilPrice;
    }

    event ChangedBotAddress(address _addr);
    event ChangedBotTeamAddress(address _addr);
    event ChangedBotMetadataAddress(address _addr);
    event ChangedShipAddress(address _addr);
    event ChangedShipTeamAddress(address _addr);
    event ChangedShipMetadataAddress(address _addr);
    event ChangedOilAddress(address _addr);
    event ChangedTreasuryAddress(address _addr);
    event ChangedRewardsSpenderAddress(address _addr);
    event ChangedDurabilityPrice(uint256 _price);
    event ChangedShipCoefficient(uint256 _coeff);
    event ChangedWaitTime(uint256 _waitTime);
    event ChangedBitsOilRatio(uint256 _ratio);
    event ChangedCommissionPercentage(uint256 _commissionPercentage);
    event EarlyClaimBreedAmounts (uint256 indexed _earlyClaimId, uint256 indexed _tokenId, uint256 _oilClaim, uint256 _bitsClaim);

    event DurabilityFixed(
        address indexed _nft,
        uint indexed _nftId,
        address indexed _owner,
        uint _durabilityFixed,
        uint _oilPrice,
        uint _bitsCommission,
        uint _fixStart,
        uint _nextFixTime,
        uint _fixEnd
    );

    event SpeedUp(
        address indexed _nft,
        uint indexed _nftId,
        address indexed _owner,
        uint _oilPrice,
        uint _bitsCommission,
        uint _nextFixTime,        
        uint _fixEnd
    );

    /// @notice @param _shipCoefficient is equal to real coefficient * 10000
    /// @notice @param _bitsOilRatio is equal to value of one BITS in Oil * 10000
    /// @notice @param _comissionPercentage is equal to commision percentage * 10000
    constructor(
        address _botAddress,
        address _botMetadataAddress,
        address _shipAddress,
        address _shipMetadataAddress,
        address _oilAddress,
        address _bitAddress,
        address _treasuryAddress,
        uint _durabilityPrice,
        uint _shipCoefficient,
        uint _waitTime,
        uint _bitsOilRatio,
        uint _comissionPercentage
    ) {
        _setBotAddress(_botAddress);
        _setBotMetadataAddress(_botMetadataAddress);
        _setShipAddress(_shipAddress);
        _setShipMetadataAddress(_shipMetadataAddress);
        _setOilAddress(_oilAddress);
        BITS_ADDRESS = _bitAddress;
        _setTreasuryAddress(_treasuryAddress);
        _setDurabilityPrice(_durabilityPrice);
        _setShipCoefficient(_shipCoefficient);
        _setWaitTime(_waitTime);
        _setBitsOilRatio(_bitsOilRatio);
        _setComsissionPercentage(_comissionPercentage);
        _addManager(msg.sender);
    }

    function fixDurability (address _owner, uint _durability, address _nft, uint _nftId, bool _speedUp) external whenNotPaused {
        (uint _oilPrice, uint _bitsPrice) = _fixDurability (_owner, _durability, _nft, _nftId, _speedUp);

        IERC20Burnable(oilAddress).burnFrom(_owner, _oilPrice);

        if(_bitsPrice > 0){
            require(IERC20(BITS_ADDRESS).transferFrom(msg.sender, address(this), _bitsPrice));
            IERC20(BITS_ADDRESS).approve(treasuryAddress, _bitsPrice);
            ITokenPaymentSplitter(treasuryAddress).split(BITS_ADDRESS, msg.sender, _bitsPrice);
        }
    }

    function fixWithEarlyClaim (
        address _owner,
        uint _durability,
        address _nft,
        uint _nftId,
        bool _speedUp,
        IRewardsSpender.EarlyClaim calldata _earlyClaim,
        bytes calldata _signature
    ) external whenNotPaused {
        require(_earlyClaim.addr == msg.sender, "not claim owner");
        require(address(this) == _earlyClaim.contractAddr, "not allowed");
        require(_earlyClaim.parts.length == 1, "wrong token number");
    
        (uint _oilPrice, uint _bitsPrice) = _fixDurability (_owner, _durability, _nft, _nftId, _speedUp);

        IRewardsSpender.Rewarder memory _rewarder1 = IRewardsSpender(rewardsSpenderAddress).rewarders(_earlyClaim.parts[0].name);
        require(_rewarder1.addr == oilAddress, "wrong token");
        require(( _earlyClaim.parts[0].amountUserWallet + _earlyClaim.parts[0].amountClaim) == _oilPrice, "wrong ac");

        {
            try IRewardsSpender(rewardsSpenderAddress).earlyClaim(_earlyClaim, _signature) returns (bool result) {
                require(result, "EarlyClaim fail");
            } catch Error (string memory _reason) {
                revert(_reason);
            } catch {
                revert();
            }
        }

        IERC20Burnable(oilAddress).burnFrom(_owner, _oilPrice);

        if(_bitsPrice > 0){
            require(IERC20(BITS_ADDRESS).transferFrom(msg.sender, address(this), _bitsPrice));
            IERC20(BITS_ADDRESS).approve(treasuryAddress, _bitsPrice);
            ITokenPaymentSplitter(treasuryAddress).split(BITS_ADDRESS, msg.sender, _bitsPrice);
        }
    }

    function _fixDurability (address _owner, uint _durability, address _nft, uint _nftId, bool _speedUp) internal returns (uint _oilPrice, uint _bitsPrice) {
        uint _fixEnd;
        uint _nextFixTime;

        FixedItem memory _item = fixedItems[_nft][_nftId];
        require (_durability > 0, "Durability fix is zero");
        require(uint(_item._fixEnd) < block.timestamp, "Item is being fixed");
        require(uint(_item._nextFixTime) < block.timestamp, "Fix Timeout not finished");

        if(_nft == botAddress){
            _checkGenes(true, _nftId);
            _oilPrice = _durability * durabilityPrice;
        } else if (_nft == shipAddress){
            _checkGenes(false, _nftId);
            _oilPrice = _durability * durabilityPrice * shipCoefficient / 10000;
        } else {
            revert("Incorrect NFT");
        }
        
        if(_speedUp == true){
            _oilPrice *= 2;
            _nextFixTime = block.timestamp + 600;            
            _fixEnd = block.timestamp;
        } else {
            _nextFixTime = block.timestamp + waitTime;            
            _fixEnd = block.timestamp + waitTime;
        }

        _bitsPrice = _getBitsPrice(_oilPrice);

        fixedItems[_nft][_nftId] = FixedItem(uint32(_nextFixTime), uint32(_fixEnd), uint192(_oilPrice));

        emit DurabilityFixed(_nft, _nftId, _owner, _durability, _oilPrice, _bitsPrice, block.timestamp,_nextFixTime, _fixEnd);

        return (_oilPrice, _bitsPrice);
    }


    function speedUpFix (address _nft, uint _nftId) external whenNotPaused {

        (uint _oilPrice, uint _bitsPrice) = _speedUpFix(_nft, _nftId);

        IERC20Burnable(oilAddress).burnFrom(msg.sender, _oilPrice);

        if(_bitsPrice > 0){
            require(IERC20(BITS_ADDRESS).transferFrom(msg.sender, address(this), _bitsPrice));
            IERC20(BITS_ADDRESS).approve(treasuryAddress, _bitsPrice);
            ITokenPaymentSplitter(treasuryAddress).split(BITS_ADDRESS, msg.sender, _bitsPrice);
        }
    }

    function speedUpFixWithEarlyClaim (
        address _nft,
        uint _nftId,
        IRewardsSpender.EarlyClaim calldata _earlyClaim,
        bytes calldata _signature
    ) external whenNotPaused {

        require(_earlyClaim.addr == msg.sender, "not claim owner");
        require(address(this) == _earlyClaim.contractAddr, "not allowed");
        require(_earlyClaim.parts.length == 1, "wrong token number");

        (uint _oilPrice, uint _bitsPrice) = _speedUpFix(_nft, _nftId);

        IRewardsSpender.Rewarder memory _rewarder1 = IRewardsSpender(rewardsSpenderAddress).rewarders(_earlyClaim.parts[0].name);
        require(_rewarder1.addr == oilAddress, "wrong token");
        require(( _earlyClaim.parts[0].amountUserWallet + _earlyClaim.parts[0].amountClaim) >= _oilPrice && ( _earlyClaim.parts[0].amountUserWallet + _earlyClaim.parts[0].amountClaim) <= _oilPrice + 100000000000000000 , "wrong ac");

        {
            try IRewardsSpender(rewardsSpenderAddress).earlyClaim(_earlyClaim, _signature) returns (bool result) {
                require(result, "EarlyClaim fail");
            } catch Error (string memory _reason) {
                revert(_reason);
            } catch {
                revert();
            }
        }

        IERC20Burnable(oilAddress).burnFrom(msg.sender, _oilPrice);

        if(_bitsPrice > 0){
            require(IERC20(BITS_ADDRESS).transferFrom(msg.sender, address(this), _bitsPrice));
            IERC20(BITS_ADDRESS).approve(treasuryAddress, _bitsPrice);
            ITokenPaymentSplitter(treasuryAddress).split(BITS_ADDRESS, msg.sender, _bitsPrice);
        }
    }


    function _speedUpFix (address _nft, uint _nftId) internal returns (uint _oilPrice,uint _bitsPrice) {
        require(_nft == botAddress || _nft == shipAddress, "Incorrect NFT");

        FixedItem memory _item = fixedItems[_nft][_nftId];
        require(uint(_item._fixEnd) > block.timestamp, "No item Or Already Fixed");
        uint _timeLeft = uint(_item._fixEnd) - block.timestamp;
        _oilPrice = (uint(_item.oilPrice) * _timeLeft) / waitTime;

        uint _nextFixTime = block.timestamp + 600;
        _item._nextFixTime = uint32(_nextFixTime);
        _item._fixEnd = uint32(block.timestamp);
        _item.oilPrice += uint192(_oilPrice);
        fixedItems[_nft][_nftId] = _item;

         _bitsPrice = _getBitsPrice(_oilPrice);

        emit SpeedUp(_nft, _nftId, msg.sender, _oilPrice, _bitsPrice, _nextFixTime, block.timestamp);

        return (_oilPrice, _bitsPrice);
    }


    function _checkToken(address _rewardedToken, uint _tokenPrice, uint _oilPrice, uint _amountUserWallet, uint _amountClaim, address _token) internal pure {
        if(_rewardedToken == _token){
            require(( _amountUserWallet + _amountClaim) == _tokenPrice, "wrong ac");
        } else {
            require(( _amountUserWallet + _amountClaim) == _oilPrice, "wrong ac");
        }
    }

    function getFixedItemDetails(address _nft, uint _nftId) public view returns (uint _nextFixTime, uint _fixEnd, uint _oilPrice){
        FixedItem memory _item = fixedItems[_nft][_nftId];
        _nextFixTime = uint(_item._nextFixTime);
        _fixEnd = uint(_item._fixEnd);
        _oilPrice = uint(_item.oilPrice);
    }

    function setBotAddress(address _addr) external onlyManager {
        _setBotAddress(_addr);
    }

    function setBotMetadataAddress(address _addr) external onlyManager {
        _setBotMetadataAddress(_addr);
    }    

    function setShipAddress(address _shipAddress) external onlyManager {
        _setShipAddress(_shipAddress);
    }

    function setShipMetadataAddress(address _shipMetadataAddress) external onlyManager {
        _setShipMetadataAddress(_shipMetadataAddress);
    }

    function setOilAddress(address _addr) external onlyManager {
        _setOilAddress(_addr);
    }

    function setBotTeamAddress(address _addr) external onlyManager {
        _setBotTeamAddress(_addr);
    }     

    function setShipTeamAddress(address _addr) external onlyManager {
        _setShipTeamAddress(_addr);
    }

    function setTreasuryAddress(address _addr) external onlyManager {
        _setTreasuryAddress(_addr);
    }  

    function setRewardsSpenderAddress(address _addr) external onlyManager {
        _setRewardsSpenderAddress(_addr);
    }

    function setDurabilityPrice(uint256 _price) external onlyManager {
        _setDurabilityPrice(_price);
    }

    /// @notice @param _coeff is equal to real coefficient * 10000
    function setShipCoefficient(uint256 _coeff) external onlyManager {
        _setShipCoefficient(_coeff);
    }

    function setWaitTime(uint256 _waitTime) external onlyManager {
        _setWaitTime(_waitTime);
    }      

    /// @notice @param _bitsOilRatio is equal to value of one BITS in Oil * 10000
    function setBitsOilRatio(uint256 _bitsOilRatio) external onlyManager {
        _setBitsOilRatio(_bitsOilRatio);
    }

    /// @notice @param _commissionPercentage is equal to commission percentage * 10000
    function setComsissionPercentage(uint _commissionPercentage) external onlyManager {
        _setComsissionPercentage(_commissionPercentage);
    }

    function togglePause() external onlyManager {
        if(paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function _checkGenes (bool _isBot, uint _nftId) private view {
        uint genes;
        if(_isBot == true){
            genes = IBotMetadata(botMetadataAddress).getBot(_nftId).genes;
            require(genes != 0, "No Bot");
        } else {
            genes = IShipMetadata(shipMetadataAddress).getShip(_nftId).genes;
            require(genes != 0, "No Ship");
        }
    }

    function _getBitsPrice(uint _oilPrice) private view  returns (uint _bitsPrice) {
        uint _bitsOilRatio = bitsOilRatio;
        _bitsPrice = (_oilPrice * 10000 / _bitsOilRatio) * commissionPercentage / (10000*100);
        return _bitsPrice;
    }     

    function _setBotAddress(address _addr) internal {
        botAddress = _addr;
        emit ChangedBotAddress(_addr);
    }

    function _setBotTeamAddress(address _addr) internal {
        botTeamAddress = _addr;
        emit ChangedBotTeamAddress(_addr);
    }

    function _setBotMetadataAddress(address _addr) internal {
        botMetadataAddress = _addr;
        emit ChangedBotMetadataAddress(_addr);
    }    

    function _setShipAddress(address _shipAddress) internal {
        shipAddress = _shipAddress;
        emit ChangedShipAddress(_shipAddress);
    }

    function _setShipTeamAddress(address _addr) internal {
        shipTeamAddress = _addr;
        emit ChangedShipTeamAddress(_addr);
    }

    function _setShipMetadataAddress(address _shipMetadataAddress) internal {
        shipMetadataAddress = _shipMetadataAddress;
        emit ChangedShipMetadataAddress(_shipMetadataAddress);
    }

    function _setOilAddress(address _addr) internal {
       oilAddress = _addr;
       emit ChangedOilAddress(_addr);  
    }

    function _setTreasuryAddress(address _addr) internal {
        treasuryAddress = _addr;
        emit ChangedTreasuryAddress(_addr);
    }   

    function _setRewardsSpenderAddress(address _addr) internal {
        rewardsSpenderAddress = _addr;
        emit ChangedRewardsSpenderAddress(_addr);
    }

    function _setDurabilityPrice(uint256 _price) internal {
        durabilityPrice = _price;
        emit ChangedDurabilityPrice(_price);
    }      

    /// @notice @param _coeff is equal to real coefficient * 10000   
    function _setShipCoefficient(uint256 _coeff) internal {
        shipCoefficient = _coeff;
        emit ChangedShipCoefficient(_coeff);
    }

    function _setWaitTime(uint256 _waitTime) internal {
        waitTime = _waitTime;
        emit ChangedWaitTime(_waitTime);
    }

    /// @notice @param _bitsOilRatio is equal to value of one BITS in Oil * 10000
    function _setBitsOilRatio(uint256 _bitsOilRatio) internal {
        bitsOilRatio = _bitsOilRatio;
        emit ChangedBitsOilRatio(_bitsOilRatio);
    }  

    /// @notice @param _commissionPercentage is equal to commission percentage * 10000
    function _setComsissionPercentage(uint _commissionPercentage) internal {
        commissionPercentage = _commissionPercentage;
        emit ChangedCommissionPercentage(_commissionPercentage);        
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Managable {
    mapping(address => bool) private managers;
    address[] private managersAddresses;

    event AddedManager(address _address);
    event RemovedManager(address _address);

    modifier onlyManager() {
        require(managers[msg.sender], "caller is not manager");
        _;
    }

    function getManagers() public view returns (address[] memory) {
        return managersAddresses;
    }

    function transferManager(address _manager) external onlyManager {
        _removeManager(msg.sender);
        _addManager(_manager);
    }

    function addManager(address _manager) external onlyManager {
        _addManager(_manager);
    }

    function removeManager(address _manager) external onlyManager {
        uint index;
        for(uint i = 0; i < managersAddresses.length; i++) {
            if(managersAddresses[i] == _manager) {
                index = i;
                break;
            }
        }

        managersAddresses[index] = managersAddresses[managersAddresses.length - 1];
        managersAddresses.pop();

        _removeManager(_manager);
    }

    function _addManager(address _manager) internal {
        managers[_manager] = true;
        managersAddresses.push(_manager);
        emit AddedManager(_manager);
    }

    function _removeManager(address _manager) internal {
        managers[_manager] = false;
        emit RemovedManager(_manager);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBot is IERC721 {
    function mint(address _to) external returns(uint256);
    function mintTokenId(address _to, uint256 _tokenId) external;
    function burn(uint256 tokenId) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LibBot.sol";

interface IBotMetadata {
    function setBot(uint256 _tokenId, LibBot.Bot calldata _bot) external;
    function getBot(uint256 _tokenId) external view returns(LibBot.Bot memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IShip is IERC721 {
    function mint(address _to) external returns(uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LibShip.sol";

interface IShipMetadata {
    function setShip(uint256 _tokenId, LibShip.Ship calldata _ship) external;
    function getShip(uint256 _tokenId) external view returns(LibShip.Ship memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITokenPaymentSplitter {
    function split(address _token, address _sender, uint256 _amount) external payable ;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRewardsSpender {

    struct EarlyClaim {
        uint256 id;
        address addr;
        address contractAddr;
        uint256 deadline;
        EarlyPart[] parts;
    }

    struct EarlyPart {
        string name;
        uint256 id;
        uint256 amountUserWallet;
        uint256 amountClaim;
    }

    struct Rewarder {
        address addr;
        RewardType typ;
    }

    enum RewardType{ERC20, ERC1155}

    function earlyClaim(EarlyClaim calldata _earlyClaim, bytes calldata _signature) external returns (bool);

    function rewarders(string calldata _name) external view returns (Rewarder calldata);
        
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibBot {
    struct Bot {
        uint256 id;
        uint256 genes;
        uint256 birthTime;
        uint64 matronId;
        uint64 sireId;
        uint8 generation;
        uint8 breedCount;
        uint256 lastBreed;
        uint256 revealCooldown;
    }

    function from(Bot calldata bot) public pure returns (uint256[] memory) {
        uint256[] memory _data = new uint256[](9);
        _data[0] = bot.id;
        _data[1] = bot.genes;
        _data[2] = bot.birthTime;
        _data[3] = uint256(bot.matronId);
        _data[4] = uint256(bot.sireId);
        _data[5] = uint256(bot.generation);
        _data[6] = uint256(bot.breedCount);
        _data[7] = bot.lastBreed;
        _data[8] = bot.revealCooldown;

        return _data;
    }

    function into(uint256[] calldata data) public pure returns (Bot memory) {
        Bot memory bot = Bot({
            id: data[0],
            genes: data[1],
            birthTime: data[2],
            matronId: uint64(data[3]),
            sireId: uint64(data[4]),
            generation: uint8(data[5]),
            breedCount: uint8(data[6]),
            lastBreed: data[7],
            revealCooldown: data[8]      
        });

        return bot;
    }    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibShip {
    struct Ship {
        uint256 genes;
        uint48 id;
        uint48 birthTime;
        uint48 var1;
        uint48 var2;
        uint32 var3;
        uint32 var4;
    }
}