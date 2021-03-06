// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./WorldRandomDragon.sol";
import "./WorldRouter.sol";

contract World is Initializable, WorldRandomDragon, WorldRouter {

    function initialize() external initializer {
        WorldRandomDragon.__WorldRandomDragon_init();
        WorldRouter.__WorldRouter_init();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./WorldStorage.sol";

abstract contract WorldRandomDragon is WorldStorage {

    function __WorldRandomDragon_init() internal initializer {
        WorldStorage.__WorldStorage_init();
    }

    function setDragonBonus(uint256 _dragonBonusForSameLocation) external onlyAdminOrOwner {
        require(_dragonBonusForSameLocation >= 0 && _dragonBonusForSameLocation <= 100, "Bad dragon bonus");
        dragonBonusForSameLocation = _dragonBonusForSameLocation;
    }

    function getRandomDragonOwner(uint256 _randomSeed, Location _locationOfEvent) external view override returns(address) {
        if(totalRankStaked == 0) {
            return address(0x0);
        }
        uint256 bucket = _randomSeed % totalRankStaked; // choose a value from 0 to total rank staked
        uint256 cumulative;
        _randomSeed >>= 32; // shuffle seed for new random
        uint256 rankPicked;
        // loop through each bucket of Dragons with the same rank score
        for (uint i = 5; i <= 8; i++) {
            cumulative += numberOfDragonsStakedAtRank(i) * rankToPoints[i];
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) {
                continue;
            }
            rankPicked = i;
            break;
        }
        if(rankPicked == 0) {
            return address(0);
        }
        // Guaranteed to have a dragon in at least 1 location because we found a rank above.

        uint256 _dragonsAtTG = numberOfDragonsStakedAtLocationAtRank(Location.TRAINING_GROUNDS, rankPicked);
        uint256 _dragonsAtRift = numberOfDragonsStakedAtLocationAtRank(Location.RIFT, rankPicked);

        // Assign bonus allocation points to dragons staked in the event's location. This allows for these dragons to have a higher chance of being selected over dragons NOT in this area.
        // We will use the same logic as above, cumulative point selection to determine the bucket to choose from.

        // Math is not at risk of overflowing because there are only 4000 dragons and the allocation points are small.
        uint256 _rangePerTGDragon = (100 + (_locationOfEvent == Location.TRAINING_GROUNDS ? dragonBonusForSameLocation : 0));
        uint256 _dragonsAtTGRange = _dragonsAtTG * _rangePerTGDragon;

        uint256 _rangePerRiftDragon = (100 + (_locationOfEvent == Location.RIFT ? dragonBonusForSameLocation : 0));
        uint256 _dragonsAtRiftRange = _dragonsAtRift * _rangePerRiftDragon;

        uint256 _totalRange = _dragonsAtTGRange + _dragonsAtRiftRange;

        uint256 _numberInRange = _randomSeed % _totalRange;

        uint256 _chosenDragonId;
        if(_numberInRange < _dragonsAtTGRange) {
            // One of the TG dragons got it. Use integer division to figure out WHICH dragon got it.
            uint256 _indexOfChosenDragon = _numberInRange / _rangePerTGDragon;
            _chosenDragonId = dragonAtLocationAtRankAtIndex(Location.TRAINING_GROUNDS, rankPicked, _indexOfChosenDragon);
        } else if(_numberInRange < _dragonsAtTGRange + _dragonsAtRiftRange) {
            uint256 _indexOfChosenDragon = _numberInRange / _rangePerRiftDragon;
            _chosenDragonId = dragonAtLocationAtRankAtIndex(Location.RIFT, rankPicked, _indexOfChosenDragon);
        } else {
            revert("Not possible currently.");
        }

        return ownerOfTokenId(_chosenDragonId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./WorldStorage.sol";

abstract contract WorldRouter is WorldStorage {

    function __WorldRouter_init() internal initializer {
        WorldStorage.__WorldStorage_init();
    }

    function startStakeWizards(uint256[] calldata _tokenIds, Location _location) external override contractsAreSet whenNotPaused {
        require(_isValidWizardLocation(_location), "Invalid wizard location");
        require(_tokenIds.length > 0, "no token ids specified");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            require(!isTokenInWorld(_tokenId), "Token already in world");
            require(wnd.isWizard(_tokenId), "Token is not wizard");

            address _tokenOwner = wnd.ownerOf(_tokenId);
            require(_tokenOwner == msg.sender || isAdmin(msg.sender), "Invalid permission");

            _getWizardStakableForLocation(_location).startStake(_tokenId, _tokenOwner);
        }
    }

    function finishStakeWizards(uint256[] calldata _tokenIds, Location _location) external override contractsAreSet whenNotPaused {
        require(_isValidWizardLocation(_location), "Invalid location");
        require(_tokenIds.length > 0, "no token ids specified");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            require(locationOfToken(_tokenId) == _getStartStakeLocation(_location), "Bad location");
            require(isOwnerOfTokenId(_tokenId, msg.sender) || isAdmin(msg.sender), "Invalid permission");

            _getWizardStakableForLocation(_location).finishStake(_tokenId);
        }
    }

    function startUnstakeWizards(uint256[] calldata _tokenIds, Location _location) external override contractsAreSet whenNotPaused {
        require(_isValidWizardLocation(_location), "Invalid wizard location");
        require(_tokenIds.length > 0, "no token ids specified");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            require(locationOfToken(_tokenId) == _location, "Invalid wizard location");
            require(isOwnerOfTokenId(_tokenId, msg.sender) || isAdmin(msg.sender), "Invalid permission");

            _getWizardStakableForLocation(_location).startUnstake(_tokenId);
        }
    }

    function finishUnstakeWizards(uint256[] calldata _tokenIds, Location _location) external override contractsAreSet whenNotPaused {
        require(_isValidWizardLocation(_location), "Invalid location");
        require(_tokenIds.length > 0, "no token ids specified");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(locationOfToken(_tokenId) == _getStartUnstakeLocation(_location), "Bad location");
            require(isOwnerOfTokenId(_tokenId, msg.sender) || isAdmin(msg.sender), "Invalid permission");

            _getWizardStakableForLocation(_location).finishUnstake(_tokenId);
        }
    }

    function stakeDragons(uint256[] calldata _tokenIds, Location _location) external override contractsAreSet whenNotPaused {
        require(_isValidDragonLocation(_location), "Invalid location");
        require(_tokenIds.length > 0, "no token ids specified");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            require(!isTokenInWorld(_tokenId), "Token already in world");
            require(!wnd.isWizard(_tokenId), "Token is not dragon");

            address _tokenOwner = wnd.ownerOf(_tokenId);
            require(_tokenOwner == msg.sender || isAdmin(msg.sender), "Not owner or admin");

            _getDragonStakableForLocation(_location).stake(_tokenId, _tokenOwner);
        }
    }

    function unstakeDragons(uint256[] calldata _tokenIds, Location _location) external override contractsAreSet whenNotPaused {
        require(_isValidDragonLocation(_location), "Invalid location");
        require(_tokenIds.length > 0, "no token ids specified");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            require(locationOfToken(_tokenId) == _location, "Bad location");
            require(isOwnerOfTokenId(_tokenId, msg.sender) || isAdmin(msg.sender), "Invalid permission");

            _getDragonStakableForLocation(_location).unstake(_tokenId);
        }
    }

    function _isValidWizardLocation(Location _location) private pure returns(bool) {
        return _location == Location.TRAINING_GROUNDS;
    }

    function _isValidDragonLocation(Location _location) private pure returns(bool) {
        return _location == Location.TRAINING_GROUNDS || _location == Location.RIFT;
    }

    function _getStartStakeLocation(Location _location) private pure returns(Location) {
        if(_location == Location.TRAINING_GROUNDS) {
            return Location.TRAINING_GROUNDS_ENTERING;
        } else {
            revert("Bad location");
        }
    }

    function _getStartUnstakeLocation(Location _location) private pure returns(Location) {
        if(_location == Location.TRAINING_GROUNDS) {
            return Location.TRAINING_GROUNDS_LEAVING;
        } else {
            revert("Bad location");
        }
    }

    function _getWizardStakableForLocation(Location _location) private view returns(IWizardStakable) {
        if(_location == Location.TRAINING_GROUNDS_ENTERING || _location == Location.TRAINING_GROUNDS_LEAVING || _location == Location.TRAINING_GROUNDS) {
            return trainingGrounds;
        } else {
            revert("Unable to find stakable");
        }
    }

    function _getDragonStakableForLocation(Location _location) private view returns(IDragonStakable) {
        if(_location == Location.TRAINING_GROUNDS) {
            return trainingGrounds;
        } else if(_location == Location.RIFT) {
            return rift;
        } else {
            revert("Unable to find stkable");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./WorldContracts.sol";

// Contains the storage for where dragons and wizards are and how many of them there are.
abstract contract WorldStorage is Initializable, WorldContracts {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function __WorldStorage_init() internal initializer {
        WorldContracts.__WorldContracts_init();
    }

    function addWizardToWorld(uint256 _tokenId, address _owner, Location _location) external override onlyAdminOrOwner contractsAreSet {
        wizardIdSet.add(_tokenId);
        tokenIdToLocation[_tokenId] = _location;
        locationToWizardIdSet[_location].add(_tokenId);
        tokenIdToOwner[_tokenId] = _owner;

        wnd.adminTransferFrom(_owner, address(this), _tokenId);
    }

    function addDragonToWorld(uint256 _tokenId, address _owner, Location _location) external override onlyAdminOrOwner contractsAreSet {
        WizardDragon memory s = wnd.getTokenTraits(_tokenId);
        require(!s.isWizard, "Token not a dragon");
        totalRankStaked += rankToPoints[s.rankIndex];
        dragonIdSet.add(_tokenId);
        tokenIdToLocation[_tokenId] = _location;
        locationToRankToDragonIdSet[_location][s.rankIndex].add(_tokenId);
        tokenIdToOwner[_tokenId] = _owner;

        wnd.adminTransferFrom(_owner, address(this), _tokenId);
    }

    function removeWizardFromWorld(uint256 _tokenId, address _owner) external override onlyAdminOrOwner contractsAreSet {
        wizardIdSet.remove(_tokenId);
        Location _oldLocation = tokenIdToLocation[_tokenId];
        delete tokenIdToLocation[_tokenId];
        locationToWizardIdSet[_oldLocation].remove(_tokenId);
        delete tokenIdToOwner[_tokenId];

        wnd.adminTransferFrom(address(this), _owner, _tokenId);
    }

    function removeDragonFromWorld(uint256 _tokenId, address _owner) external override onlyAdminOrOwner contractsAreSet {
        WizardDragon memory s = wnd.getTokenTraits(_tokenId);
        require(!s.isWizard, "Token not a dragon");
        totalRankStaked -= rankToPoints[s.rankIndex];
        dragonIdSet.remove(_tokenId);
        Location _oldLocation = tokenIdToLocation[_tokenId];
        delete tokenIdToLocation[_tokenId];
        locationToRankToDragonIdSet[_oldLocation][s.rankIndex].remove(_tokenId);
        delete tokenIdToOwner[_tokenId];

        wnd.adminTransferFrom(address(this), _owner, _tokenId);
    }

    function changeLocationOfWizard(uint256 _tokenId, Location _location) external override onlyAdminOrOwner {
        require(wizardIdSet.contains(_tokenId), "Wizard not in world");
        Location _currentLocation = tokenIdToLocation[_tokenId];
        if(_currentLocation == _location) {
            return;
        }

        locationToWizardIdSet[_currentLocation].remove(_tokenId);
        locationToWizardIdSet[_location].add(_tokenId);
        tokenIdToLocation[_tokenId] = _location;
    }

    function totalNumberOfWizards() external view override returns(uint256) {
        return wizardIdSet.length();
    }

    function totalNumberOfDragons() public view override returns(uint256) {
        return dragonIdSet.length();
    }

    function locationOfToken(uint256 _tokenId) public view override returns(Location) {
        return tokenIdToLocation[_tokenId];
    }

    function setStakeableDragonLocations(Location[] calldata _locations) public override {
        stakeableDragonLocations = _locations;
    }

    function getStakeableDragonLocations() public view override returns(Location[] memory) {
        return stakeableDragonLocations;
    }

    function numberOfDragonsStakedAtRank(uint256 _rank) public view override returns(uint256 numStaked) {
        for (uint256 i = 0; i < stakeableDragonLocations.length; i++) {
            numStaked += locationToRankToDragonIdSet[stakeableDragonLocations[i]][_rank].length();
        }
    }

    function numberOfDragonsStakedAtLocationAtRank(Location _location, uint256 _rank) public view override returns(uint256) {
        return locationToRankToDragonIdSet[_location][_rank].length();
    }

    function numberOfWizardsStakedAtLocation(Location _location) public view override returns(uint256) {
        return locationToWizardIdSet[_location].length();
    }

    function dragonAtLocationAtRankAtIndex(Location _location, uint256 _rank, uint256 _index) public view override returns(uint256) {
        return locationToRankToDragonIdSet[_location][_rank].at(_index);
    }

    // Do not call via another contract. Should be strictly UI, as this is a gassy operation.
    function getDragonsAtLocationForOwner(Location _location, address _owner) external view override returns(uint256[] memory){
        uint256 totalCount = totalNumberOfDragons();
        uint256 count;
        for (uint256 i = 0; i < totalCount; i++) {
            uint256 _tokenId = dragonIdSet.at(i);
            if(isOwnerOfTokenId(_tokenId, _owner) && locationOfToken(_tokenId) == _location){
                count++;
            }
        }

        uint256[] memory tokenIds = new uint256[](count);
        uint256 temp = 0;
        for (uint256 i = 0; i < totalCount; i++) {
            uint256 _tokenId = dragonIdSet.at(i);
            if(isOwnerOfTokenId(_tokenId, _owner) && locationOfToken(_tokenId) == _location){
                tokenIds[temp] = _tokenId;
                temp++;
            }
        }
        return tokenIds;
    }

    // Do not call via another contract. Should be strictly UI, as this is a gassy operation.
    function getWizardsAtLocationForOwner(Location _location, address _owner) external view override returns(uint256[] memory){
        uint256 totalCount = numberOfWizardsStakedAtLocation(_location);
        uint256 count;
        for (uint256 i = 0; i < totalCount; i++) {
            uint256 _tokenId = wizardAtLocationAtIndex(_location, i);
            if(isOwnerOfTokenId(_tokenId, _owner)){
                count++;
            }
        }

        uint256[] memory tokenIds = new uint256[](count);
        uint256 temp = 0;
        for (uint256 i = 0; i < totalCount; i++) {
            uint256 _tokenId = wizardAtLocationAtIndex(_location, i);
            if(isOwnerOfTokenId(_tokenId, _owner)){
                tokenIds[temp] = _tokenId;
                temp++;
            }
        }
        return tokenIds;
    }

    function wizardAtLocationAtIndex(Location _location, uint256 _index) public view override returns(uint256) {
        return locationToWizardIdSet[_location].at(_index);
    }

    function ownerOfTokenId(uint256 _tokenId) public view override returns(address) {
        return tokenIdToOwner[_tokenId];
    }

    function isOwnerOfTokenId(uint256 _tokenId, address _owner) public view override returns(bool) {
        return ownerOfTokenId(_tokenId) == _owner;
    }

    function isTokenInWorld(uint256 _tokenId) public view override returns(bool) {
        return tokenIdToOwner[_tokenId] != address(0);
    }

    /** This function is only here in case it is required to tweak the rankToPoints mapping for probability distribution on random dragon selection.
      * In the most perfect of worlds, this will never be called. If it does, it assumes that the _rankStaked parameter is calculated by new rankToPoints mappings for each dragon staked. */
    function setTotalRankStaked(uint256 _rankStaked) external onlyAdminOrOwner {
        totalRankStaked = _rankStaked;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./WorldState.sol";
import "./IWorld.sol";
import "../rift/IRift.sol";
import "../traininggrounds/ITrainingGrounds.sol";
import "../tokens/wnd/IWnD.sol";

// Contains the storage for where dragons and wizards are and how many of them there are.
abstract contract WorldContracts is Initializable, IWorld, WorldState {

    function __WorldContracts_init() internal initializer {
        WorldState.__WorldState_init();
    }

    function setContracts(address _trainingGroundsAddress, address _wndAddress, address _riftAddress) external onlyAdminOrOwner {
        require(_trainingGroundsAddress != address(0)
            && _riftAddress != address(0)
            && _wndAddress != address(0), "Bad addresses");

        trainingGrounds = ITrainingGrounds(_trainingGroundsAddress);
        wnd = IWnD(_wndAddress);
        rift = IRift(_riftAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "World: Contracts not set");

        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(trainingGrounds) != address(0)
            && address(rift) != address(0)
            && address(wnd) != address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../shared/AdminableUpgradeable.sol";
import "../tokens/wnd/IWnD.sol";
import "../world/IWorld.sol";
import "../rift/IRift.sol";
import "../traininggrounds/ITrainingGrounds.sol";
import "../trainingproficiency/ITrainingProficiency.sol";
import "../../shared/randomizercl/IRandomizerCL.sol";

contract WorldState is Initializable, ERC721HolderUpgradeable, AdminableUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    EnumerableSetUpgradeable.UintSet internal dragonIdSet;
    EnumerableSetUpgradeable.UintSet internal wizardIdSet;
    mapping(uint256 => Location) internal tokenIdToLocation;
    mapping(uint256 => address) internal tokenIdToOwner;
    // Location enum -> rank -> id set
    mapping(Location => mapping(uint256 => EnumerableSetUpgradeable.UintSet)) internal locationToRankToDragonIdSet;
    mapping(Location => EnumerableSetUpgradeable.UintSet) internal locationToWizardIdSet;
    uint256 internal totalRankStaked;
    Location[] internal stakeableDragonLocations;
    // rank -> number of points to add the the total staked values for picking random dragons with.
    // This is needed to ensure a fair probability of selection is achieved per rank correlating with its rareness.
    mapping(uint256 => uint256) internal rankToPoints;

    ITrainingGrounds public trainingGrounds;
    IWnD public wnd;
    IRift public rift;

    // A number from 0-100 which is the bonus dragons staked at a given location receive.
    uint256 public dragonBonusForSameLocation;

    function __WorldState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();

        dragonBonusForSameLocation = 15;
        stakeableDragonLocations = [Location.RIFT, Location.TRAINING_GROUNDS];
        rankToPoints[5] = 4;
        rankToPoints[6] = 7;
        rankToPoints[7] = 11;
        rankToPoints[8] = 20;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWorldReadOnly {
    // Returns the total number of wizards staked somewhere in the world. Does not include in route wizards.
    function totalNumberOfWizards() external view returns(uint256);

    // Returns the total number of dragons staked somewhere in the world.
    function totalNumberOfDragons() external view returns(uint256);

    // Returns the location of the token. If it returns NONEXISTENT, the token is not staked in the world.
    function locationOfToken(uint256 _tokenId) external view returns(Location);

    // Returns if the token exists in the world. This also means the world contract holds the token.
    function isTokenInWorld(uint256 _tokenId) external view returns(bool);

    function getStakeableDragonLocations() external view returns(Location[] memory);

    function numberOfDragonsStakedAtRank(uint256 _rank) external view returns(uint256);

    // Returns the number of dragons that are staked at the given location and rank.
    function numberOfDragonsStakedAtLocationAtRank(Location _location, uint256 _rank) external view returns(uint256);

    // Returns the number of wizards that are staked at the given location.
    function numberOfWizardsStakedAtLocation(Location _location) external view returns(uint256);

    // Returns the dragon ID that is at the given location at the given index. Will revert if invalid index.
    function dragonAtLocationAtRankAtIndex(Location _location, uint256 _rank, uint256 _index) external view returns(uint256);

    // Returns the wizard ID that is at the given location at the given index. Will revert if invalid index.
    function wizardAtLocationAtIndex(Location _location, uint256 _index) external view returns(uint256);

    // Returns all dragons at the given location for the given owner. Avoid using in a contract-to-contract call.
    function getDragonsAtLocationForOwner(Location _location, address _owner) external view returns(uint256[] memory);

    // Returns all dragons at the given location for the given owner. Avoid using in a contract-to-contract call.
    function getWizardsAtLocationForOwner(Location _location, address _owner) external view returns(uint256[] memory);

    // The owner of the given token.
    function ownerOfTokenId(uint256 _tokenId) external view returns(address);

    // Returns if the passed in address is the owner of the token id.
    function isOwnerOfTokenId(uint256 _tokenId, address _owner) external view returns(bool);

    // Returns a random dragon owner based on the given seed.
    // Dragons that are staked at the given location have an increased odds of being selected.
    // If _locationOfEvent is set to NONEXISTENT, all dragons staked in the world will have the same odds.
    // If this function returns 0, there was not a random dragon staked.
    function getRandomDragonOwner(uint256 _randomSeed, Location _locationOfEvent) external view returns(address);
}

interface IWorldEditable {

    // Begins staking the given wizard at the given location. Must be approved to transfer from their wallet to this contract.
    // May revert for various reasons.
    function startStakeWizards(uint256[] calldata _tokenIds, Location _location) external;

    // Finishes the stake for the given wizard ID. Must be called after the random has been seeded.
    function finishStakeWizards(uint256[] calldata _tokenIds, Location _location) external;

    // Unstakes the given wizard from the given location.
    // May revert for various reasons.
    function startUnstakeWizards(uint256[] calldata _tokenIds, Location _location) external;

    // Finishes the unstake process for the given wizard id. Must be called after the random has been seeded.
    function finishUnstakeWizards(uint256[] calldata _tokenIds, Location _location) external;

    // Stakes the given dragon at the given location. Must be approved to transfer from their wallet to this contract.
    // May revert for various reasons.
    function stakeDragons(uint256[] calldata _tokenIds, Location _location) external;

    // Unstakes the given dragon at the given location. Must be approved to transfer from their wallet to this contract.
    // May revert for various reasons.
    function unstakeDragons(uint256[] calldata _tokenIds, Location _location) external;

    // When calling, should already have ensured this is a wizard and is not in the world already.
    // Transfers the 721 to the world contract.
    // Admin only.
    function addWizardToWorld(uint256 _tokenId, address _owner, Location _location) external;

    // When calling, should already have ensured this is a wizard and is not in the world already.
    // Transfers the 721 to the world contract.
    // Admin only.
    function addDragonToWorld(uint256 _tokenId, address _owner, Location _location) external;

    // Game logic should already validate that this is an option.
    // Transfers the 721 to the _owner.
    // Admin only.
    function removeWizardFromWorld(uint256 _tokenId, address _owner) external;

    // Game logic should already validate that this is an option.
    // Transfers the 721 to the _owner.
    // Admin only.
    function removeDragonFromWorld(uint256 _tokenId, address _owner) external;

    // When calling, game logic should already validate who owns the token, if they have permission, and that
    // the destination location makes sense.
    // Only callable by admin/owner.
    function changeLocationOfWizard(uint256 _tokenId, Location _location) external;

    function setStakeableDragonLocations(Location[] calldata _locations) external;
}

interface IWorld is IWorldEditable, IWorldReadOnly {

}

enum Location {
    NONEXISTENT,
    RIFT,
    TRAINING_GROUNDS_ENTERING,
    TRAINING_GROUNDS,
    TRAINING_GROUNDS_LEAVING
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IDragonStakable.sol";

interface IRift is IDragonStakable {

    // Returns the rift tier for the given user based on how much GP is staked at the rift.
    function getRiftTier(address _address) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IWizardStakable.sol";
import "../shared/IDragonStakable.sol";

interface ITrainingGrounds is IWizardStakable, IDragonStakable {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IWnDRoot {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function getTokenTraits(uint256 _tokenId) external returns(WizardDragon memory);
    function ownerOf(uint256 _tokenId) external returns(address);
    function approve(address _to, uint256 _tokenId) external;
}

interface IWnD is IERC721EnumerableUpgradeable {
    function mint(address _to, uint256 _tokenId, WizardDragon calldata _traits) external;
    function burn(uint256 _tokenId) external;
    function isWizard(uint256 _tokenId) external view returns(bool);
    function getTokenTraits(uint256 _tokenId) external view returns(WizardDragon memory);
    function exists(uint256 _tokenId) external view returns(bool);
    function adminTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

struct WizardDragon {
    bool isWizard;
    uint8 body;
    uint8 head;
    uint8 spell;
    uint8 eyes;
    uint8 neck;
    uint8 mouth;
    uint8 wand;
    uint8 tail;
    uint8 rankIndex;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrainingProficiency {

    // Returns the proficiency for the given Wizard.
    function proficiencyForWizard(uint256 _tokenId) external view returns(uint8);

    // Increases the proficiency of the given wizard by 1.
    // Only admin.
    function increaseProficiencyForWizard(uint256 _tokenId) external;
    // Resets the proficiency of the given wizard.
    // Only admin.
    function resetProficiencyForWizard(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomizerCL {
    // Returns a request ID for the random number. This should be kept and mapped to whatever the contract
    // is tracking randoms for.
    // Admin only.
    function getRandomNumber() external returns(bytes32);

    // Returns the random for the given request ID.
    // Will revert if the random is not ready.
    function randomForRequestID(bytes32 _requestID) external view returns(uint256);

    // Returns if the request ID has been fulfilled yet.
    function isRequestIDFulfilled(bytes32 _requestID) external view returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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

interface IDragonStakable {
    function stake(uint256 _tokenId, address _owner) external;
    function unstake(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWizardStakable {
    function startStake(uint256 _tokenId, address _owner) external;
    function finishStake(uint256 _tokenId) external;

    function startUnstake(uint256 _tokenId) external;
    function finishUnstake(uint256 _tokenId) external;
}