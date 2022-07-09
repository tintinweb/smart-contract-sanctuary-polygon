// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./BaseAuctionReceiver.sol";
import "./requests/RandomConsumerBase.sol";
import "./structs/DragonInfoV2.sol";
import "./structs/BreedInfo.sol";
import "./DragonCreator.sol";
import "./DragonToken.sol";
import "./DragonGenes.sol";

contract DragonCrossbreed is BaseAuctionReceiver, ReentrancyGuard, RandomConsumerBase {

    using Address for address;

    uint constant HOURS_MAX_PERIOD = 24 * 100; //100 days

    uint[] private _platformPrices;

    address private _dragonCreatorAddress;
    address private _dragonRandomnessAddress;
    address private _dragonGenesAddress;

    mapping(address => uint) private _rewards;
    mapping(bytes32 => address) private _owners;
    mapping(bytes32 => uint) private _requestData;

    event Breed(address indexed sender, uint dragon1Id, uint dragon2Id, uint platformPrice, uint rentPrice);
    event RewardAdded(address indexed operator, address indexed to, uint amount);
    event RewardClaimed(address indexed claimer, address indexed to, uint amount);

    constructor(
        address accessControl, 
        address dragonToken, 
        address coinContract,
        address dragonCreator,
        address randomCoordinator, 
        uint fees100) 
        BaseAuctionReceiver(accessControl, dragonToken, coinContract, fees100) 
        RandomConsumerBase(randomCoordinator) {
        
        _numOfPriceChangesPerHour = 30;
        _dragonCreatorAddress = dragonCreator;
        _platformPrices = [20*1e18, 100*1e18, 500*1e18, 1000*1e18, 3000*1e18];
    }

    function maxTotalPeriod() public override virtual pure returns (uint) {
        return HOURS_MAX_PERIOD;
    }

    function dragonGenesAddress() public view returns (address) {
        return _dragonGenesAddress;
    }

    function setDragonGenesAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _dragonGenesAddress;
        _dragonGenesAddress = newAddress;
        emit AddressChanged("dragonGenes", previousAddress, newAddress);
    }

    function dragonCreatorAddress() public view returns (address) {
        return _dragonCreatorAddress;
    }

    function setDragonCreatorAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _dragonCreatorAddress;
        _dragonCreatorAddress = newAddress;
        emit AddressChanged("dragonCreator", previousAddress, newAddress);
    }

    function platformPrice(uint breedsCount) public view returns (uint) {
        return _platformPrices[breedsCount % _platformPrices.length];
    }

    function setPlatformPrices(uint[] calldata newPlatformPrices) 
    external onlyRole(CFO_ROLE) {
        _platformPrices = newPlatformPrices;
    }

    function calcCommonRareEpicGenesCount(uint genes1, uint genes2) internal pure returns (uint, uint) {
        uint mask = DragonInfo.MASK;
        
        uint countRare = 0;
        uint countEpic = 0;

        for (uint i = 0; i < 10; i++) { //just Epic and Rare genes are important to count
            if (genes1 & mask > 0 && genes2 & mask > 0) {
                if (i < 5) {
                    countEpic++;
                }
                else {
                    countRare++;
                }
            }
            mask = mask >> 4;
        }
        return (countRare, countEpic);
    }

    function processERC721(address from, uint tokenId, bytes calldata data) 
        internal virtual override {
        DragonToken dt = DragonToken(tokenContract());
        DragonInfoV2.Details memory info = dt.dragonInfo(tokenId);
        require(info.dragonType != DragonInfo.Types.Legendary && info.mutatedFromId == 0, 
            "DC: the dragon cannot be a legendary-type or mutant");
        super.processERC721(from, tokenId, data);
    }

    function breed(uint myDragonId, uint anotherDragonId, uint amount) 
    external 
    nonReentrant
    whenNotPaused {
        DragonToken dragonToken = DragonToken(tokenContract());

        require(
            dragonToken.ownerOf(myDragonId) == _msgSender(), 
            "DC: the caller is not an owner"
        );
        require(
            isLocked(anotherDragonId) || dragonToken.ownerOf(anotherDragonId) == _msgSender(), 
            "DC: another dragon is not locked nor doesn't belong to the caller"
        );

        DragonInfoV2.Details memory parent1 = dragonToken.dragonInfo(myDragonId);
        DragonInfoV2.Details memory parent2 = dragonToken.dragonInfo(anotherDragonId);

        if (myDragonId > 0 && anotherDragonId > 0) { //if not 1st-generation dragons
            require(myDragonId != anotherDragonId, "DC: parent dragons must be different");
            require(
                parent1.dragonType != DragonInfo.Types.Legendary 
                && parent2.dragonType != DragonInfo.Types.Legendary, 
                "DC: neither of the parent dragons can be of Legendary-type"
            );
            require(!dragonToken.isSiblings(myDragonId, anotherDragonId), 
                "DC: the parent dragons must not be siblings");
            require(
                !dragonToken.isParent(myDragonId, anotherDragonId) && !dragonToken.isParent(anotherDragonId, myDragonId), 
                "DC: neither of the parent dragons must be a parent or child of another"
            );
        }

        (uint countRare, uint countEpic) = calcCommonRareEpicGenesCount(parent1.genes, parent2.genes);
        uint _platformPrice = platformPrice(dragonToken.breedsCount(myDragonId));
        uint _rentPrice = 0;
    
        if (isLocked(anotherDragonId)) {
            _rentPrice = priceOf(anotherDragonId);
        }

        require(amount >= (_platformPrice + _rentPrice), "DC: incorrect amount");

        if (amount > 0) {
            IERC20(coinContract()).transferFrom(_msgSender(), address(this), amount);
        }
        
        bytes32 requestId = requestRandomness();
        BreedInfo.Details memory info = BreedInfo.Details({
            dragon1Id: myDragonId,
            dragon2Id: anotherDragonId,
            commonRare: countRare,
            commonEpic: countEpic,
            rentPrice: _rentPrice
        });

        _requestData[requestId] = BreedInfo.getValue(info);
        _owners[keccak256(abi.encodePacked(requestId, myDragonId))] = 
            dragonToken.ownerOf(myDragonId);
        _owners[keccak256(abi.encodePacked(requestId, anotherDragonId))] = 
                isLocked(anotherDragonId) ?
                holderOf(anotherDragonId) :
                dragonToken.ownerOf(anotherDragonId);
        
        dragonToken.incrementBreed(myDragonId);
        dragonToken.incrementBreed(anotherDragonId);

        emit Breed(_msgSender(), myDragonId, anotherDragonId, _platformPrice, _rentPrice);
    }

    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        BreedInfo.Details memory breedDetails = BreedInfo.getDetails(_requestData[requestId]);  
        
        DragonGenes dragonGenes = DragonGenes(dragonGenesAddress());

        bytes32 dragon1OwnerKey = keccak256(abi.encodePacked(requestId, breedDetails.dragon1Id));
        bytes32 dragon2OwnerKey = keccak256(abi.encodePacked(requestId, breedDetails.dragon2Id));

        uint newGenes = dragonGenes.breedNew(tokenContract(), breedDetails, randomness);
        if (breedDetails.rentPrice > 0) {
            IERC20(coinContract()).transfer(
                _owners[dragon2OwnerKey],
                breedDetails.rentPrice - calcFees(breedDetails.rentPrice, feesPercent())
            );
        }
        DragonCreator(dragonCreatorAddress()).giveBirth(
            breedDetails.dragon1Id, 
            breedDetails.dragon2Id, 
            newGenes, 
            _owners[dragon1OwnerKey]
        );
        
        delete _requestData[requestId];
        delete _owners[dragon1OwnerKey];
        delete _owners[dragon2OwnerKey];
    }

    function addReward(address to, uint amount) external onlyRole(COO_ROLE) {
        require(!Address.isContract(to), "DC: bad address");
        _rewards[to] += amount;
        emit RewardAdded(_msgSender(), to, amount);
    }

    function claimReward(address to, uint amount) external nonReentrant {
        require(!Address.isContract(to), "DC: bad address");
        require(amount <= _rewards[_msgSender()], "DC: too big amount");
        
        IERC20(coinContract()).transfer(to, amount);
        _rewards[_msgSender()] -= amount;

        emit RewardClaimed(_msgSender(), to, amount);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./utils/BytesLib.sol";
import "./LockableReceiver.sol";

abstract contract BaseAuctionReceiver is LockableReceiver {
    
    enum PriceDirection { NONE, UP, DOWN }

    struct PriceSettings { 
        uint startingPrice;
        uint finalPrice;
        uint priceChangePeriod; //in hours
        uint priceChangeStep; 
        PriceDirection direction;
        uint timestampAddedAt; 
    }

    using SafeMath for uint;

    mapping(uint => PriceSettings) internal _priceSettings;
    uint internal _numOfPriceChangesPerHour;
    uint private _fees100;

    constructor (address accessControl, address dragonToken, address coinContract, uint fees100) 
    LockableReceiver(accessControl, dragonToken, coinContract) {
        _fees100 = fees100;
        _numOfPriceChangesPerHour = 60;
    }

    function weiMinPrice() public virtual pure returns (uint) {
        return 0;
    }

    function maxTotalPeriod() public virtual pure returns (uint) {
        return 0;
    }

    function setNumOfPriceChangesPerHour(uint newValue) external virtual onlyRole(CFO_ROLE) {
        _numOfPriceChangesPerHour = newValue;
    }

    /**
    * Defines how often the price is changed during 1 hour. 60 by default (every minute).
    */
    function numOfPriceChangesPerHour() public virtual view returns (uint) {
        return _numOfPriceChangesPerHour;
    }

    function feesPercent() public virtual view returns (uint) {
        return _fees100;
    }

    function setFeesPercent(uint newValue) external virtual onlyRole(CFO_ROLE) {
        _fees100 = newValue;
    }

    function calcFees(uint weiAmount, uint fees100) internal virtual pure returns (uint) {
        return weiAmount.div(1e4).mul(fees100);
    }

    function readPriceSettings(bytes calldata data) internal virtual pure returns (uint, uint, uint) {
        uint weiStartingPrice = BytesLib.toUint256(data, 0);
        uint weiFinalPrice = BytesLib.toUint256(data, 0x20);
        uint totalPriceChangePeriod = BytesLib.toUint256(data, 0x40);
        return (weiStartingPrice, weiFinalPrice, totalPriceChangePeriod);
    } 

    function processERC721(address /*from*/, uint tokenId, bytes calldata data) 
        internal virtual override {

        (uint weiStartingPrice, uint weiFinalPrice, uint totalPriceChangePeriod) = 
            readPriceSettings(data);

        uint _weiMinPrice = weiMinPrice();
        uint _maxTotalPeriod = maxTotalPeriod();

        if (_weiMinPrice > 0) {
            require(weiStartingPrice >= _weiMinPrice && weiFinalPrice >= _weiMinPrice, 
                "BCA: either start or final price is too small");
        }
        if (_maxTotalPeriod > 0) {
            require(totalPriceChangePeriod <= _maxTotalPeriod, 
                "BCA: the price change period is too big");
            require(totalPriceChangePeriod >= 12 && totalPriceChangePeriod.mod(12) == 0, 
                "BCA: the price change period should be a multiple of 0.5 days");
        }

        uint step;
        PriceDirection d;
        (step, d) = calcPriceChangeStep(
            weiStartingPrice, weiFinalPrice, totalPriceChangePeriod);
        PriceSettings memory settings = PriceSettings ({
            startingPrice: weiStartingPrice,
            finalPrice: weiFinalPrice,
            priceChangePeriod: totalPriceChangePeriod,
            priceChangeStep: step,
            direction: d,
            timestampAddedAt: block.timestamp
        });
        _priceSettings[tokenId] = settings;
    }

    function priceSettingsOf(uint tokenId) public view returns (PriceSettings memory) {
        return _priceSettings[tokenId];
    }

    function priceOf(uint tokenId) public view returns (uint) {
        PriceSettings memory settings = priceSettingsOf(tokenId);
        if (settings.direction == PriceDirection.NONE) {
            return settings.startingPrice;
        }

        uint max = Math.max(settings.startingPrice, settings.finalPrice);
        uint min = Math.min(settings.startingPrice, settings.finalPrice);
        uint diff = max.sub(min);

        uint totalNumOfPeriodsToFinalPrice = diff.div(settings.priceChangeStep);
        uint numOfPeriods = 
            (block.timestamp - settings.timestampAddedAt).div(60)
            .mul(numOfPriceChangesPerHour()).div(60);

        uint result;
        if (numOfPeriods > totalNumOfPeriodsToFinalPrice) {
            result = settings.finalPrice;
        }
        else if (settings.direction == PriceDirection.DOWN) {
            result = settings.startingPrice.sub(settings.priceChangeStep.mul(numOfPeriods));
        }
        else {
            result = settings.startingPrice.add(settings.priceChangeStep.mul(numOfPeriods));
        }
        return result;
    }

    function calcPriceChangeStep(
        uint weiStartingPrice, 
        uint weiFinalPrice, 
        uint totalPriceChangePeriod) internal virtual view returns (uint, PriceDirection) {

        if (weiStartingPrice == weiFinalPrice) {
            return (0, PriceDirection.NONE);
        }

        uint max = Math.max(weiStartingPrice, weiFinalPrice);
        uint min = Math.min(weiStartingPrice, weiFinalPrice);
        uint diff = max.sub(min);
        PriceDirection direction = PriceDirection.DOWN;
        if (max == weiFinalPrice) {
            direction = PriceDirection.UP;
        }
        return (diff.div(totalPriceChangePeriod.mul(numOfPriceChangesPerHour())), direction);
    }

    function withdraw(uint tokenId) public virtual override onlyHolder(tokenId) {
        delete _priceSettings[tokenId];
        super.withdraw(tokenId);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../access/BaseAccessControl.sol";
import "./RandomCoordinator.sol";

abstract contract RandomConsumerBase is BaseAccessControl {    
    using Counters for Counters.Counter;

    address internal _randomCoordinator;
    Counters.Counter private _requestsId;

    constructor(address coordinator) {
        _randomCoordinator = coordinator;
    }

    function randomCoordinator() public view returns (address) {
        return _randomCoordinator;
    }

    function setRandomCoordinator(address newAddress) external onlyRole(COO_ROLE) {
        _randomCoordinator = newAddress;
    }

    function requestRandomness() internal returns (bytes32) {
        _requestsId.increment();
        bytes32 newRequestId = keccak256(abi.encodePacked(
            uint(_requestsId.current()), 
            block.number, 
            address(this)));

        RandomCoordinator(randomCoordinator()).sendRequest(newRequestId);
        
        return newRequestId;
    }

    function rawFulfillRandomness(bytes32 requestId, uint randomness) external {
        require(_msgSender() == randomCoordinator(), "Call is not allowed");
        fulfillRandomness(requestId, randomness);
    }

    function fulfillRandomness(bytes32 requestId, uint randomness) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./DragonInfo.sol";

library DragonInfoV2 {

    struct Details { 
        uint genes;
        uint eggId;
        uint parent1Id;
        uint parent2Id;
        uint generation;
        uint strength;
        uint mutatedToId;
        uint mutatedFromId;
        DragonInfo.Types dragonType;
    }

    function fromV1(uint value) internal pure returns (Details memory) {
        DragonInfo.Details memory v1details = DragonInfo.getDetails(value);
        return Details ({
            genes: v1details.genes,
            eggId: v1details.eggId, 
            parent1Id: v1details.parent1Id,
            parent2Id: v1details.parent2Id,
            generation: v1details.generation,
            strength: v1details.strength,
            dragonType: v1details.dragonType,
            mutatedToId: 0,
            mutatedFromId: 0
        });
    }

    function getDetails(uint value) internal pure returns (Details memory) {
        return Details (
            {
                genes: uint256(uint104(value)),
                parent1Id: uint256(uint24(value >> 104)),
                parent2Id: uint256(uint24(value >> 128)),
                generation: uint256(uint8(value >> 152)),
                strength: uint256(uint16(value >> 160)),
                dragonType: DragonInfo.Types(uint8(value >> 176)),
                eggId: uint256(uint16(value >> 184)),
                mutatedToId: uint256(uint24(value >> 200)),
                mutatedFromId: uint256(uint24(value >> 224))
            }
        );
    }

    function getValue(Details memory details) internal pure returns (uint) {
        uint result = uint(details.genes);
        result |= details.parent1Id << 104;
        result |= details.parent2Id << 128;
        result |= details.generation << 152;
        result |= details.strength << 160;
        result |= uint(details.dragonType) << 176;
        result |= details.eggId << 184;
        result |= details.mutatedToId << 200;
        result |= details.mutatedFromId << 224;
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library BreedInfo {

    struct Details {
        uint dragon1Id;
        uint dragon2Id;
        uint commonRare;
        uint commonEpic;
        uint rentPrice;
    }

    function getValue(Details memory info) internal pure returns (uint) {
        uint result = uint(info.dragon1Id);
        result |= info.dragon2Id << 32;
        result |= info.commonRare << 64;
        result |= info.commonEpic << 96;
        result |= info.rentPrice << 128;
        return result;
    }

    function getDetails(uint value) internal pure returns (Details memory) {
        return Details (
            {
                dragon1Id: uint256(uint32(value)),
                dragon2Id: uint256(uint32(value >> 32)),
                commonRare: uint256(uint32(value >> 64)),
                commonEpic: uint256(uint32(value >> 96)),
                rentPrice: uint256(value >> 128)
            }
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "./structs/DragonInfo.sol";
import "./access/BaseAccessControl.sol";
import "./DragonToken.sol";

contract DragonCreator is BaseAccessControl {
    
    using Address for address;

    address private _tokenContractAddress;

    mapping(DragonInfo.Types => uint) private _zeroDragonsIssueLimits;
    mapping(address => bool) private _giveBirthCallers;

    bool private _isChangeOfIssueLimitsAllowed;

    event DragonCreated(
        uint dragonId, 
        uint eggId,
        uint parent1Id,
        uint parent2Id,
        uint generation,
        DragonInfo.Types t,
        uint mutatedFromId,
        uint mutatedToId,
        uint genes,
        address indexed creator,
        address indexed to);

    constructor(address accessControl, address tknContract) BaseAccessControl(accessControl) {
        _tokenContractAddress = tknContract;
        _isChangeOfIssueLimitsAllowed = true;
    }

    function tokenContract() public view returns (address) {
        return _tokenContractAddress;
    }

    function setTokenContract(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _tokenContractAddress;
        _tokenContractAddress = newAddress;
        emit AddressChanged("tokenContract", previousAddress, newAddress);
    }

    function isChangeOfIssueLimitsAllowed() public view returns (bool) {
        return _isChangeOfIssueLimitsAllowed;
    }

    function currentIssueLimitFor(DragonInfo.Types _dragonType) external view returns (uint) {
        return _zeroDragonsIssueLimits[_dragonType];
    }

    function updateIssueLimitFor(DragonInfo.Types _dragonType, uint newValue) external onlyRole(CEO_ROLE) {
        require(isChangeOfIssueLimitsAllowed(), 
            "DragonCreator: updating the issue limits is not allowed anymore");
        _zeroDragonsIssueLimits[_dragonType] = newValue;
    }

    function blockUpdatingIssueLimitsForever() external onlyRole(CEO_ROLE) {
        _isChangeOfIssueLimitsAllowed = false;
    }

    function setAllowed(address caller, bool allowed) external onlyRole(COO_ROLE) {
        _giveBirthCallers[caller] = allowed;
    }

    function issue(uint genes, address to) external onlyRole(CEO_ROLE) returns (uint) {
        DragonInfo.Types dragonType = DragonInfo.calcType(genes);
        uint currentLimit = _zeroDragonsIssueLimits[dragonType];
        require(dragonType != DragonInfo.Types.Unknown, "DragonCreator: unable to identify a type of the given dragon");
        require(currentLimit > 0, "DragonCreator: the issue limit has exceeded");
        _zeroDragonsIssueLimits[dragonType] = currentLimit - 1;

        return _createDragon(0, 0, 0, genes, dragonType, to);
    }

    function giveBirth(uint eggId, uint genes, address to) external returns (uint) {
        require(!Address.isContract(to), "DragonCreator: address cannot be contract");
        require(_giveBirthCallers[_msgSender()], "DragonCreator: not enough privileges to call the method");    
        return _createDragon(eggId, 0, 0, genes, DragonInfo.Types.Unknown, to);
    }

    function giveBirth(uint parent1Id, uint parent2Id, uint genes, address to) external returns (uint) {
        require(!Address.isContract(to), "DragonCreator: address cannot be contract");
        require(_giveBirthCallers[_msgSender()], "DragonCreator: not enough privileges to call the method");
        return _createDragon(0, parent1Id, parent2Id, genes, DragonInfo.Types.Unknown, to);
    }

    function _createDragon(
        uint _eggId, 
        uint _parent1Id, 
        uint _parent2Id, 
        uint _genes, 
        DragonInfo.Types _dragonType, 
        address to) internal returns (uint) {
        DragonToken dragonToken = DragonToken(tokenContract());
        uint generation1 = 0;
        uint generation2 = 0;

        if (_parent1Id > 0 && _parent2Id > 0) { //if not 1st-generation dragons
            DragonInfoV2.Details memory parent1Details = dragonToken.dragonInfo(_parent1Id);
            DragonInfoV2.Details memory parent2Details = dragonToken.dragonInfo(_parent2Id);
            
            generation1 = parent1Details.generation;
            generation2 = parent2Details.generation;

            require(_parent1Id != _parent2Id, "DragonCreator: parent dragons must be different");
            require(
                parent1Details.dragonType != DragonInfo.Types.Legendary 
                && parent2Details.dragonType != DragonInfo.Types.Legendary, 
                "DragonCreator: neither of the parent dragons can be of Legendary-type"
            );
            require(!dragonToken.isSiblings(_parent1Id, _parent2Id), "DragonCreator: the parent dragons must not be siblings");
            require(
                !dragonToken.isParent(_parent1Id, _parent2Id) && !dragonToken.isParent(_parent2Id, _parent1Id), 
                "DragonCreator: neither of the parent dragons must be a parent or child of another"
            );
        }

        bool mutation = _parent1Id > 0 && _parent2Id == 0; //check, if it's a mutation

        DragonInfoV2.Details memory info = DragonInfoV2.Details({ 
            eggId: _eggId,
            parent1Id: mutation ? 0 : _parent1Id,
            parent2Id: mutation ? 0 : _parent2Id,
            generation: mutation ? 1 : DragonInfo.calcGeneration(generation1, generation2),
            dragonType: (_dragonType == DragonInfo.Types.Unknown) ? DragonInfo.calcType(_genes) : _dragonType,
            strength: 0, //DragonInfo.calcStrength(_genes),
            genes: _genes,
            mutatedFromId: mutation ? _parent1Id : 0,
            mutatedToId: 0
        });

        uint newDragonId = dragonToken.mint(to, info);
        
        emit DragonCreated(
            newDragonId, info.eggId,
            info.parent1Id, info.parent2Id, 
            info.generation, info.dragonType, 
            info.mutatedFromId, info.mutatedToId,
            info.genes, _msgSender(), to);

        return newDragonId; 
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./access/BaseAccessControl.sol";
import "./structs/DragonInfoV2.sol";

contract DragonToken is ERC721Burnable, BaseAccessControl {

    using Address for address;
    using Counters for Counters.Counter;

    string public constant NONEXISTENT_TOKEN_ERROR = "DragonToken: nonexistent token";
    string public constant NOT_ENOUGH_PRIVILEGES_ERROR = "DragonToken: not enough privileges to call the method";
    string public constant DRAGON_EXISTS_ERROR = "DragonToken: a dragon with such ID already exists";
    string public constant BAD_CID_ERROR = "DragonToken: bad CID";
    string public constant CID_SET_ERROR = "DragonToken: CID is already set";
    
    Counters.Counter private _dragonIds;

    // Mapping token id to dragon details
    mapping(uint => uint) private _info;
    // Mapping token id to its breed counts
    mapping(uint => uint) private _countOfBreeds;
    // Mapping token id to its fight counts
    mapping(uint => uint) private _countOfFights;
    // Mapping token id to cid
    mapping(uint => string) private _cids;

    string private _defaultMetadataCid;
    address private _dragonCreator;
    address private _dragonReplicator;
    address private _crossbreed;
    address private _arena;

    constructor(uint dragonSeed, string memory defaultCid, address accessControl) 
    ERC721("CryptoDragons", "CD")
    BaseAccessControl(accessControl) {  
        _dragonIds = Counters.Counter({ _value: dragonSeed });
        _defaultMetadataCid = defaultCid;
    }

    function approveAndCall(address spender, uint256 tokenId, bytes calldata extraData) external returns (bool success) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        _approve(spender, tokenId);
        (bool _success, ) = 
            spender.call(
                abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes)", 
                _msgSender(), 
                tokenId, 
                address(this), 
                extraData) 
            );
        if(!_success) { 
            revert("DragonToken: spender internal error"); 
        }
        return true;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        string memory cid = _cids[tokenId];
        return string(abi.encodePacked("ipfs://", (bytes(cid).length > 0) ? cid : defaultMetadataCid()));
    }

    function dragonCreatorAddress() public view returns(address) {
        return _dragonCreator;
    }

    function setDragonCreatorAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _dragonCreator;
        _dragonCreator = newAddress;
        emit AddressChanged("dragonCreator", previousAddress, newAddress);
    }

    function dragonReplicatorAddress() public view returns(address) {
        return _dragonReplicator;
    }

    function setDragonReplicatorAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _dragonReplicator;
        _dragonReplicator = newAddress;
        emit AddressChanged("dragonReplicator", previousAddress, newAddress);
    }

    function crossbreedAddress() public view returns(address) {
        return _crossbreed;
    }

    function setCrossbreedAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _crossbreed;
        _crossbreed = newAddress;
        emit AddressChanged("crossbreed", previousAddress, newAddress);
    }

    function arenaAddress() public view returns(address) {
        return _arena;
    }

    function setArenaAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _arena;
        _arena = newAddress;
        emit AddressChanged("arena", previousAddress, newAddress);
    }

    function hasMetadataCid(uint tokenId) public view returns(bool) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        return bytes(_cids[tokenId]).length > 0;
    }

    function setMetadataCid(uint tokenId, string calldata cid) external onlyRole(COO_ROLE) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        require(bytes(cid).length >= 46, BAD_CID_ERROR);
        require(!hasMetadataCid(tokenId), CID_SET_ERROR);
        _cids[tokenId] = cid;
    }

    function defaultMetadataCid() public view returns (string memory){
        return _defaultMetadataCid;
    }

    function setDefaultMetadataCid(string calldata newDefaultCid) external onlyRole(COO_ROLE) {
        _defaultMetadataCid = newDefaultCid;
    }

    function dragonInfoV1(uint dragonId) external view returns (DragonInfo.Details memory) {
        require(_exists(dragonId), NONEXISTENT_TOKEN_ERROR);
        return DragonInfo.getDetails(_info[dragonId]);
    }

    function dragonInfo(uint dragonId) public view returns (DragonInfoV2.Details memory) {
        require(_exists(dragonId), NONEXISTENT_TOKEN_ERROR);
        return DragonInfoV2.getDetails(_info[dragonId]);
    }

    function breedsCount(uint dragonId) external view returns (uint) {
        require(_exists(dragonId), NONEXISTENT_TOKEN_ERROR);
        return _countOfBreeds[dragonId];
    }

    function fightsCount(uint dragonId) external view returns (uint) {
        require(_exists(dragonId), NONEXISTENT_TOKEN_ERROR);
        return _countOfFights[dragonId];
    }

    function strengthOf(uint dragonId) external view returns (uint) {
        DragonInfoV2.Details memory details = dragonInfo(dragonId);
        return details.strength > 0 ? details.strength : DragonInfo.calcStrength(details.genes);
    }

    function isFirstborn(uint dragonId) external view returns (bool) {
        DragonInfoV2.Details memory info = dragonInfo(dragonId);
        return info.eggId > 0;
    }

    function isMutant(uint dragonId) external view returns (bool) {
        DragonInfoV2.Details memory info = dragonInfo(dragonId);
        return info.mutatedFromId > 0;
    }

    function canBeMutated(uint dragonId) external view returns (bool) {
        DragonInfoV2.Details memory info = dragonInfo(dragonId);
        return info.eggId > 0 &&  info.mutatedToId == 0;
    }

    function isSiblings(uint dragon1Id, uint dragon2Id) external view returns (bool) {
        DragonInfoV2.Details memory info1 = dragonInfo(dragon1Id);
        DragonInfoV2.Details memory info2 = dragonInfo(dragon2Id);
        return 
            (info1.generation > 1 && info2.generation > 1) && //the 1st generation of dragons doesn't have siblings
            (info1.parent1Id == info2.parent1Id || info1.parent1Id == info2.parent2Id || 
            info1.parent2Id == info2.parent1Id || info1.parent2Id == info2.parent2Id);
    }

    function isParent(uint dragon1Id, uint dragon2Id) external view returns (bool) {
        DragonInfoV2.Details memory info = dragonInfo(dragon1Id);
        return info.parent1Id == dragon2Id || info.parent2Id == dragon2Id;
    }

    function mint(address to, DragonInfoV2.Details calldata info) external returns (uint) {
        require(_msgSender() == dragonCreatorAddress(), NOT_ENOUGH_PRIVILEGES_ERROR);
        
        _dragonIds.increment();
        uint newDragonId = uint(_dragonIds.current());
        
        _info[newDragonId] = DragonInfoV2.getValue(info);
        _mint(to, newDragonId);

        if (info.mutatedFromId > 0) { // if it's a mutant
            _setMutant(info.mutatedFromId, newDragonId);
        }

        return newDragonId;
    }

    function incrementFight(uint dragonId) external returns (uint) {
        require(_msgSender() == arenaAddress(), NOT_ENOUGH_PRIVILEGES_ERROR);
        _countOfFights[dragonId]++;
        return _countOfFights[dragonId];
    }

    function incrementBreed(uint dragonId) external returns (uint) {
        require(_msgSender() == crossbreedAddress(), NOT_ENOUGH_PRIVILEGES_ERROR);
        _countOfBreeds[dragonId]++;
        return _countOfBreeds[dragonId];
    }

    function mintReplica(address to, uint dragonId, uint value, string memory cid) external returns (uint) {
        require(_msgSender() == dragonReplicatorAddress(), NOT_ENOUGH_PRIVILEGES_ERROR);
        require(_info[dragonId] == 0, DRAGON_EXISTS_ERROR);
        
        _info[dragonId] = DragonInfoV2.getValue(DragonInfoV2.fromV1(value));
        _cids[dragonId] = cid;
        
        _mint(to, dragonId);

        return dragonId;
    }

    function setStrength(uint dragonId) external returns (uint) {
        DragonInfoV2.Details memory details = dragonInfo(dragonId);
        if (details.strength == 0) {
            details.strength = DragonInfo.calcStrength(details.genes);
            _info[dragonId] = DragonInfoV2.getValue(details);
        }
        return details.strength;
    }

    function _setMutant(uint dragonId, uint mutantDragonId) internal {
        DragonInfoV2.Details memory details = dragonInfo(dragonId);
        details.mutatedToId = mutantDragonId;
        _info[dragonId] = DragonInfoV2.getValue(details);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./access/BaseAccessControl.sol";
import "./structs/DragonInfoV2.sol";
import "./structs/BreedInfo.sol";
import "./utils/GenesLib.sol";
import "./utils/Random.sol";
import "./DragonToken.sol";


contract DragonGenes is BaseAccessControl {

    uint constant THRESHOLD_DENOMINATOR = 100*1e8;

    uint[10] private _bonusesCommonThresholds;
    uint[5] private _probabilityRareThresholds;
    uint[5] private _probabilityEpicThresholds;

    address private _dragonCrossbreedAddress;

    GenesLib.GenesRange private COMMON_RANGE;
    GenesLib.GenesRange private RARE_RANGE;
    GenesLib.GenesRange private EPIC_RANGE;

    constructor(address accessControl, address crossbreedAddress) 
    BaseAccessControl(accessControl) {
        _dragonCrossbreedAddress = crossbreedAddress;

        _bonusesCommonThresholds = [
            1953125, 3906250, 7812500, 15625000, 31250000,
            62500000, 125000000, 250000000, 500000000, 1000000000
        ];
        _probabilityRareThresholds = [1000000000, 500000000, 250000000, 125000000, 62500000];
        _probabilityEpicThresholds = [0, 15625000, 7812500, 3906250, 1953125];

        COMMON_RANGE = GenesLib.GenesRange({from: 0, to: 15});
        RARE_RANGE = GenesLib.GenesRange({from: 15, to: 20});
        EPIC_RANGE = GenesLib.GenesRange({from: 20, to: 25});
    }

    function bonusCommonThresholdAt(uint index) external view returns (uint) {
        return _bonusesCommonThresholds[index];
    } 

    function setBonusCommonThreshold(uint[10] calldata newBonusesCommonThresholds) external onlyRole(CFO_ROLE) {
        _bonusesCommonThresholds = newBonusesCommonThresholds;
    }

    function probabilityRareThresholdAt(uint index) external view returns (uint) {
        return _probabilityRareThresholds[index];
    } 

    function setProbabilityRareThreshold(uint[5] calldata newProbabilityRareThresholds) external onlyRole(CFO_ROLE) {
        _probabilityRareThresholds = newProbabilityRareThresholds;
    }

    function probabilityEpicThresholdAt(uint index) external view returns (uint) {
        return _probabilityEpicThresholds[index];
    } 

    function setProbabilityEpicThreshold(uint[5] calldata newProbabilityEpicThresholds) external onlyRole(CFO_ROLE) {
        _probabilityEpicThresholds = newProbabilityEpicThresholds;
    }

    function dragonCrossbreedAddress() public view returns (address) {
        return _dragonCrossbreedAddress;
    }

    function setDragonCrossbreedAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _dragonCrossbreedAddress;
        _dragonCrossbreedAddress = newAddress;
        emit AddressChanged("dragonCrossbreed", previousAddress, newAddress);
    }

    function breedNew (address tokenContractAddress, BreedInfo.Details calldata breedDetails, uint randomness) 
    external view returns (uint) {
        require(_msgSender() == dragonCrossbreedAddress(), "DragonGenes: not enough privileges to call the method");
        DragonToken dragonToken = DragonToken(tokenContractAddress);

        uint newGenes = 0;
        uint randomValue = Random.rand(randomness);
        uint derivedRandomValue = Random.rand(randomValue ^ randomness);    

        DragonInfoV2.Details memory parent1 = dragonToken.dragonInfo(breedDetails.dragon1Id);
        DragonInfoV2.Details memory parent2 = dragonToken.dragonInfo(breedDetails.dragon2Id);

        if (parent1.dragonType == DragonInfo.Types.Common && parent2.dragonType == DragonInfo.Types.Common) {
            (uint y, uint z) = _randomCountOfNewRareEpic(randomValue);
            if (y > 0) {
                uint[] memory positions = GenesLib.randomGenePositions(RARE_RANGE, y, randomValue);
                newGenes = GenesLib.randomSetGenesToPositions(newGenes, positions, randomValue, false);
            }
            if (z > 0) {
                uint[] memory positions = GenesLib.randomGenePositions(EPIC_RANGE, z, randomValue);
                newGenes = GenesLib.randomSetGenesToPositions(newGenes, positions, randomValue, false);
            }
            if (newGenes == 0 && _randomNewRare(0, derivedRandomValue)) { //if the bonuses above were not triggered
                uint[] memory positions = GenesLib.randomGenePositions(RARE_RANGE, 1, derivedRandomValue);
                newGenes = GenesLib.randomSetGenesToPositions(newGenes, positions, derivedRandomValue, false);
            }
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, COMMON_RANGE, randomValue, true);
        }
        else if (parent1.dragonType == DragonInfo.Types.Epic20 && parent2.dragonType == DragonInfo.Types.Epic20) {
            //add Epic gene
            uint[] memory positions = GenesLib.randomGenePositions(EPIC_RANGE, 1, randomValue);
            newGenes = GenesLib.randomSetGenesToPositions(newGenes, positions, randomValue, false);
            //inherit Common
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, COMMON_RANGE, randomValue, true);
            //inherit Rare
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, RARE_RANGE, randomValue, false);
        }
        else {
            //inherit Common
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, COMMON_RANGE, randomValue, true);
            //inherit Rare
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, RARE_RANGE, randomValue, false);
            //inherit Epic
            newGenes = GenesLib.randomInheritGenesInRange(newGenes, parent1.genes, parent2.genes, EPIC_RANGE, randomValue, false);

            if (breedDetails.commonRare < 5 && _randomNewRare(breedDetails.commonRare, randomValue)) {
                (uint count, uint[] memory positions) = GenesLib.zeroGenePositionsInRange(newGenes, RARE_RANGE);
                uint pos = Random.randFrom(positions, 0, count, derivedRandomValue);
                newGenes = GenesLib.setGeneLevelTo(newGenes, GenesLib.randomGeneLevel(derivedRandomValue, false), pos);
            }
            else if (breedDetails.commonRare == 5 && breedDetails.commonEpic < 5 && _randomNewEpic(breedDetails.commonEpic, randomValue)) {
                (uint count, uint[] memory positions) = GenesLib.zeroGenePositionsInRange(newGenes, EPIC_RANGE);
                uint pos = Random.randFrom(positions, 0, count, derivedRandomValue);
                newGenes = GenesLib.setGeneLevelTo(newGenes, GenesLib.randomGeneLevel(derivedRandomValue, false), pos);
            }
        }

        return newGenes;
    }

    function _randomCountOfNewRareEpic(uint randomValue) internal view returns (uint, uint) {
        uint r = randomValue % THRESHOLD_DENOMINATOR;
        return 
            (r <= _bonusesCommonThresholds[0]) ? (5, 5) :
            (r <= _bonusesCommonThresholds[1]) ? (5, 4) :
            (r <= _bonusesCommonThresholds[2]) ? (5, 3) :
            (r <= _bonusesCommonThresholds[3]) ? (5, 2) :
            (r <= _bonusesCommonThresholds[4]) ? (5, 1) :
            (r <= _bonusesCommonThresholds[5]) ? (5, 0) :
            (r <= _bonusesCommonThresholds[6]) ? (4, 0) :
            (r <= _bonusesCommonThresholds[7]) ? (3, 0) :
            (r <= _bonusesCommonThresholds[8]) ? (2, 0) :
            (r <= _bonusesCommonThresholds[9]) ? (1, 0) :
            (0, 0);
    }

    function _randomNewRare(uint currentRareCount, uint randomValue) internal view returns (bool) {
        uint r = randomValue % THRESHOLD_DENOMINATOR;
        return r < _probabilityRareThresholds[currentRareCount];
    }

    function _randomNewEpic(uint currentEpicCount, uint randomValue) internal view returns (bool) {
        uint r = randomValue % THRESHOLD_DENOMINATOR;
        return r < _probabilityEpicThresholds[currentEpicCount];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }
    
    function toUint256(bytes memory _bytes, uint _start) internal pure returns (uint) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toTuple128(bytes memory _bytes, uint256 _start) internal pure returns (uint, uint) {
        require(_bytes.length >= _start + 32, "toTuple16_outOfBounds");
        uint tempUint;
        uint n1;
        uint n2;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
            n1 := and(shr(0x80, tempUint), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            n2 := and(tempUint, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }

        return (n1, n2);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./access/BaseAccessControl.sol";

abstract contract LockableReceiver is BaseAccessControl, Pausable, IERC721Receiver {
    
    using Address for address payable;

    address private _tokenContractAddress;
    address private _coinContractAddress;
    mapping(uint => address) private _lockedTokens;

    event TokenLocked(uint tokenId, address indexed holder);
    event TokenWithdrawn(uint tokenId, address indexed holder);
    event EthersWithdrawn(address indexed operator, address indexed to, uint amount);
    event CoinsWithdrawn(address indexed operator, address indexed to, uint amount);

    constructor (address accessControl, address tokenContractAddress, address coinContractAddress) 
    BaseAccessControl(accessControl) {
        _tokenContractAddress = tokenContractAddress;
        _coinContractAddress = coinContractAddress;
    }

    modifier whenLocked(uint tokenId) {
        require(isLocked(tokenId), "LockableReceiver: token must be locked");
        _;
    }

    modifier onlyHolder(uint tokenId) {
        require(holderOf(tokenId) == _msgSender(), "LockableReceiver: caller is not the token holder");
        _;
    }

    function onERC721Received(address operator, address /*from*/, uint /*tokenId*/, bytes calldata /*data*/) 
        external 
        virtual 
        override 
        whenNotPaused 
        returns (bytes4) {
        require(operator == address(this), "LockableReceiver: the caller is not a valid operator");
        return this.onERC721Received.selector;
    }

    function receiveApproval(address sender, uint tokenId, address _tokenContract, bytes calldata data) external virtual {
        require(tokenContract() == _msgSender(), "LockableReceiver: not enough privileges to call the method");
        require(_tokenContract == tokenContract(), "LockableReceiver: unable to receive the given token");
    
        IERC721(tokenContract()).safeTransferFrom(sender, address(this), tokenId, data);
        
        _lock(tokenId, sender);
        processERC721(sender, tokenId, data);
    }

    function processERC721(address from, uint tokenId, bytes calldata data) internal virtual {
    }

    function _lock(uint tokenId, address holder) internal {
        _lockedTokens[tokenId] = holder;
        emit TokenLocked(tokenId, holder);
    }

    function _unlock(uint tokenId) internal {
        delete _lockedTokens[tokenId];
    }

    function tokenContract() public view returns (address) {
        return _tokenContractAddress;
    }

    function setTokenContract(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _tokenContractAddress;
        _tokenContractAddress = newAddress;
        emit AddressChanged("tokenContract", previousAddress, newAddress);
    }

    function coinContract() public view returns (address) {
        return _coinContractAddress;
    }

    function setCoinContract(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _coinContractAddress;
        _coinContractAddress = newAddress;
        emit AddressChanged("coinContract", previousAddress, newAddress);
    }

    function pause() external onlyRole(COO_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(COO_ROLE) {
        _unpause();
    }

    function isLocked(uint tokenId) public view returns (bool) {
        return _lockedTokens[tokenId] != address(0);
    }

    function holderOf(uint tokenId) public view returns (address) {
        return _lockedTokens[tokenId];
    }

    function withdrawEthers(uint amount, address payable to) external virtual onlyRole(CFO_ROLE) {
        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }

    function withdrawCoins(uint amount, address to) external virtual onlyRole(CFO_ROLE) {
        IERC20(coinContract()).transfer(to, amount);
        emit CoinsWithdrawn(_msgSender(), to, amount);
    }

    function withdraw(uint tokenId) public virtual onlyHolder(tokenId) {
        _transferTokenToHolder(tokenId);
        emit TokenWithdrawn(tokenId, _msgSender());
    }

    function _transferTokenToHolder(uint tokenId) internal virtual {
        address holder = holderOf(tokenId);
        if (holder != address(0)) {
            IERC721(tokenContract()).safeTransferFrom(address(this), holder, tokenId);
            _unlock(tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IChangeableVariables.sol";

abstract contract BaseAccessControl is Context, IChangeableVariables {

    bytes32 public constant CEO_ROLE = keccak256("CEO");
    bytes32 public constant CFO_ROLE = keccak256("CFO");
    bytes32 public constant COO_ROLE = keccak256("COO");

    address private _accessControl;

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    constructor (address accessControl) Context() {
        _accessControl = accessControl;
    }

    function accessControlAddress() public view returns (address) {
        return _accessControl;
    }

    function setAccessControlAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _accessControl;
        _accessControl = newAddress;
        emit AddressChanged("accessControl", previousAddress, newAddress);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        IAccessControl accessControl = IAccessControl(accessControlAddress());
        return accessControl.hasRole(role, account) || accessControl.hasRole(CEO_ROLE, account);
    }

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
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IChangeableVariables {
    event AddressChanged(string fieldName, address previousAddress, address newAddress);
    event ValueChanged(string fieldName, uint previousValue, uint newValue);
    event BoolValueChanged(string fieldName, bool previousValue, bool newValue);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../access/BaseAccessControl.sol";
import "./RandomConsumerBase.sol";

contract RandomCoordinator is BaseAccessControl {
    
    mapping (address => bool) private _allowedConsumers;
    mapping (bytes32 => address) private _requests;

    event RequestSent(address indexed consumer, bytes32 requestId);
    event RequestFulfilled(address indexed consumer, bytes32 requestId);

    constructor(address accessControl) 
    BaseAccessControl(accessControl) {
    }

    function setAllowed(address consumer, bool allowed) external onlyRole(COO_ROLE) {
        _allowedConsumers[consumer] = allowed;
    }

    function sendRequest(bytes32 requestId) external {
        require(_allowedConsumers[_msgSender()], "RandomCoordinator: only allowed consumers can invoke");
        _requests[requestId] = _msgSender();

        emit RequestSent(_msgSender(), requestId);
    }

    function fulfillRequest(bytes32 requestId, uint randomness) external onlyRole(COO_ROLE) {
        address consumer = _requests[requestId];
        require(consumer != address(0), "RandomCoordinator: nonexistent request");
        RandomConsumerBase(consumer).rawFulfillRandomness(requestId, randomness);
        emit RequestFulfilled(consumer, requestId);

        delete _requests[requestId];
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library DragonInfo {
    
    uint constant MASK = 0xF000000000000000000000000;

    enum Types { 
        Unknown,
        Common, 
        Rare16, 
        Rare17, 
        Rare18, 
        Rare19,
        Epic20, 
        Epic21,
        Epic22,
        Epic23,
        Epic24, 
        Legendary
    }

    struct Details { 
        uint genes;
        uint eggId;
        uint parent1Id;
        uint parent2Id;
        uint generation;
        uint strength;
        Types dragonType;
    }

    function getDetails(uint value) internal pure returns (Details memory) {
        return Details (
            {
                genes: uint256(uint104(value)),
                parent1Id: uint256(uint32(value >> 104)),
                parent2Id: uint256(uint32(value >> 136)),
                generation: uint256(uint16(value >> 168)),
                strength: uint256(uint16(value >> 184)),
                dragonType: Types(uint16(value >> 200)),
                eggId: uint256(uint32(value >> 216))
            }
        );
    }

    function getValue(Details memory details) internal pure returns (uint) {
        uint result = uint(details.genes);
        result |= details.parent1Id << 104;
        result |= details.parent2Id << 136;
        result |= details.generation << 168;
        result |= details.strength << 184;
        result |= uint(details.dragonType) << 200;
        result |= details.eggId << 216;
        return result;
    }

    function calcType(uint genes) internal pure returns (Types) {
        uint mask = MASK;
        uint numRare = 0;
        uint numEpic = 0;
        for (uint i = 0; i < 10; i++) { //just Rare and Epic genes are important to check
            if (genes & mask > 0) {
                if (i < 5) { //Epic-range
                    numEpic++;
                }
                else { //Rare-range
                    numRare++;
                }
            }
            mask = mask >> 4;
        }
        Types result = Types.Unknown;
        if (numEpic == 5 && numRare == 5) {
            result = Types.Legendary;
        }
        else if (numEpic < 5 && numRare == 5) {
            result = Types(6 + numEpic);
        }
        else if (numEpic == 0 && numRare < 5) {
            result = Types(1 + numRare);
        }
        else if (numEpic == 0 && numRare == 0) {
            result = Types.Common;
        }

        return result;
    }

    function calcStrength(uint genes) internal pure returns (uint) {
        uint mask = MASK;
        uint strength = 0;
        for (uint i = 0; i < 25; i++) { 
            uint gLevel = (genes & mask) >> ((24 - i) * 4);
            if (i < 6) { //Epic
                strength += 3 * (25 - i) * gLevel;
            } 
            else if (i < 10) { //Rare 
                strength += 2 * (25 - i) * gLevel;
            }
            else { //Common-range
                if (gLevel > 0) {
                    strength += (25 - i) * gLevel;
                }
                else {
                    strength += (25 - i);
                }
            }
            mask = mask >> 4;
        }
        return strength;
    }

    function calcGeneration(uint g1, uint g2) internal pure returns (uint) {
        return (g1 >= g2 ? g1 : g2) + 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Random.sol";

library GenesLib {
    using SafeMath for uint;
    uint private constant MAGIC_NUM = 0x123456789ABCDEF;

    struct GenesRange {
        uint from;
        uint to;
    }

    function setGeneLevelTo(uint genes, uint level, uint position) internal pure returns (uint) {
        return genes | uint(level << (position * 4));
    }

    function geneLevelAt(uint genes, uint position) internal pure returns (uint) {
        return (genes >> (position * 4)) & 0xF;
    }

    function zeroGenePositionsInRange(uint genes, GenesRange memory range) 
    internal pure returns (uint, uint[] memory) {
        uint[] memory zeroPositions = new uint[](range.to - range.from);
        uint count = 0;
        for (uint pos = range.from; pos < range.to; pos++) {
            uint level = geneLevelAt(genes, pos);
            if (level == 0) {
                zeroPositions[count] = pos;
                count++;
            }
        }
        return (count, zeroPositions);
    }

    function randomGeneLevel(uint randomValue, bool includeZero) internal pure returns (uint) {
        if (includeZero) {
            return randomValue.mod(16);
        }
        else {
            return 1 + randomValue.mod(15);
        }
    }

    function randomInheritGenesInRange(uint genes, uint parent1Genes, uint parent2Genes,
        GenesRange memory range, uint randomValue, bool includeZero) internal pure returns (uint) {
        
        for (uint pos = range.from; pos < range.to; pos++) {
            uint geneLevel1 = geneLevelAt(parent1Genes, pos);
            uint geneLevel2 = geneLevelAt(parent2Genes, pos);

            if (includeZero || (geneLevel1 > 0 && geneLevel2 > 0)) {
                uint d = (pos % 2 == 0) ? ((randomValue >> pos) + (MAGIC_NUM >> pos)) : ~(randomValue >> pos);
                uint r = d.mod(100);
                
                if (r < 45) { //45%
                    genes = setGeneLevelTo(genes, geneLevel1, pos);
                }
                else if (r >= 45 && r < 90) { //45%
                    genes = setGeneLevelTo(genes, geneLevel2, pos);
                }
                else { //10%
                    uint level = randomGeneLevel(d, includeZero);
                    genes = setGeneLevelTo(genes, level, pos);
                }
            }
        }
        return genes;
    }

    function randomSetGenesToPositions(uint genes, uint[] memory positions, uint randomValue, bool includeZero) 
    internal pure returns (uint) {
        for (uint i = 0; i < positions.length; i++) {
            genes = setGeneLevelTo(genes, randomGeneLevel(
                (i % 2 > 0) ? ((randomValue >> i) + (MAGIC_NUM >> i)) : ~(randomValue >> i), 
                includeZero), positions[i]);
        }
        return genes;
    }

    function randomGenePositions(GenesRange memory range, uint count, uint randomValue) 
    internal pure returns (uint[] memory) {
        if (count > 0) {
            uint[] memory shuffledRangeArray = 
                Random.shuffle(createOrderedRangeArray(range.from, range.to), randomValue);
            uint[] memory positions = new uint[](count);
            for (uint i = 0; i < count; i++) {
                positions[i] = shuffledRangeArray[i];
            }
            return positions;
        }
        return new uint[](0);
    }

    function createOrderedRangeArray(uint from, uint to) internal pure returns (uint[] memory) {
        uint[] memory rangeArray = new uint[](to - from) ;
        for (uint i = 0; i < rangeArray.length; i++) {
            rangeArray[i] = from + i;
        }
        return rangeArray;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library Random {
    function rand(uint salt) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, salt)));
    }

    function randFrom(uint[] memory array, uint from, uint to, uint randomValue)
    internal pure returns (uint) {
        uint count = to - from;
        return array[from + randomValue % count];
    }

    function shuffle(uint[] memory array, uint randomValue) internal pure returns (uint[] memory) {
        for (uint i = 0; i < array.length; i++) {
            uint n = i + randomValue % (array.length - i);
            uint temp = array[n];
            array[n] = array[i];
            array[i] = temp;
        }
        return array;
    }
}