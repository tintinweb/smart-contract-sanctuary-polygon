// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./BreedPlanetBase.sol";
import "./utils/ChainlinkRng.sol";

contract BornPlanet is BreedPlanetBase, ChainlinkRng {
    struct BornStruct {
        address userAddress;
        uint256 planetId;
        bool isDone;
    }

    mapping(uint256 => BornStruct) public BornStructMap; // uint256: Chainlink requestId

    event RequestBorn(uint256 requestId);
    event BornSuccess(uint256 indexed _tokenId);

    constructor(
        address _nftAddress,
        address _breedAddress,
        ChainlinkStruct memory _chainlinkStruct
    )
        BreedPlanetBase(_nftAddress, _breedAddress)
        ChainlinkRng(_chainlinkStruct)
    {}

    /// @notice request for born
    /// @param planetId planetId
    function requestBorn(uint256 planetId) external returns (uint256) {
        // dry run for check can born
        _born(msg.sender, planetId, true);

        uint256 requestId = requestRandomWords();

        BornStruct memory bornStruct = BornStruct(msg.sender, planetId, false);
        BornStructMap[requestId] = bornStruct;

        emit RequestBorn(requestId);

        return requestId;
    }

    /// @notice after chainlink fulfillRandomWords will call this, and it will run born function
    /// @param requestId requestId
    function _rngCallBack(uint256 requestId) internal virtual override {
        BornStruct memory bornStruct = BornStructMap[requestId];
        _born(bornStruct.userAddress, bornStruct.planetId, false);
        BornStructMap[requestId].isDone = true;
    }

    /// @notice planet born function
    /// @param userAddress planet user address
    /// @param planetId planetId
    /// @param isDryRun is dry run
    function _born(
        address userAddress,
        uint256 planetId,
        bool isDryRun // if isDryRun, not updatePlanetData
    ) internal {
        IApeironPlanet.PlanetData memory planetData = _getPlanetData(planetId);
        // check can born
        require(
            planetContract.ownerOf(planetId) == userAddress,
            "Planet is not owned"
        );
        require(planetData.bornTime == 0, "Planet already born");
        require(_hasParent(planetId), "Planet has no parent");
        require(
            breedPlanetDataContract.getPlanetNextBornTime(planetId) <
                block.timestamp,
            "Born time is pass for planetNextBornMap time"
        );

        if (!isDryRun) {
            // update planet.gene
            uint256 geneId = _convertToGeneId(
                _updateAttributesOnBorn(planetId)
            );

            // update planet as borned
            planetContract.updatePlanetData(planetId, geneId, 0, 0, 3, true);
            emit BornSuccess(planetId);
        }
    }

    /// @notice get Attributes on Breed, will only update 5-17
    /// @param planetId planetId
    function _updateAttributesOnBorn(uint256 planetId)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory parents = _getPlanetData(planetId).parents;
        require(parents.length >= 2, "planet have no parents");

        uint256[] memory parentAAttributes = _getPlanetAttributes(parents[0]);
        uint256[] memory parentBAttributes = _getPlanetAttributes(parents[1]);

        uint256[] memory attributes = _getPlanetAttributes(planetId);

        // body
        if (parentAAttributes[5] == 1 && parentBAttributes[5] == 1) {
            attributes[5] = 1;
        } else {
            // body: sex, 0 have 90%
            attributes[5] = (_randomRange(0, 9) <= 8) ? 0 : 1;
        }

        attributes[6] = (_randomRange(0, 1) == 0)
            ? parentAAttributes[6]
            : parentBAttributes[6]; // body: weapon
        /** 
            For the Body and Head Props,
            80% will be ParentA or ParentB
            20% will become empty (255)
        */
        // body: body props
        uint256 random = _randomRange(0, 9);
        if (random <= 3) {
            attributes[7] = parentAAttributes[7];
        } else if (random <= 7) {
            attributes[7] = parentBAttributes[7];
        } else {
            attributes[7] = 255;
        }
        // body: head props
        random = _randomRange(0, 9);
        if (random <= 3) {
            attributes[8] = parentAAttributes[8];
        } else if (random <= 7) {
            attributes[8] = parentBAttributes[8];
        } else {
            attributes[8] = 255;
        }

        // skill: pskill1, pskill2
        uint256 skillCount;
        uint256[] memory pskillArray = new uint256[](4);
        pskillArray[0] = parentAAttributes[12];
        pskillArray[1] = parentAAttributes[13];
        pskillArray[2] = parentBAttributes[12];
        pskillArray[3] = parentBAttributes[13];
        (pskillArray, skillCount) = _removeDuplicated(pskillArray);
        pskillArray = _shuffleOrdering(pskillArray, skillCount);
        attributes[12] = pskillArray[0]; // skill: pskill1
        attributes[13] = pskillArray[1]; // skill: pskill2

        attributes[14] = (_randomRange(0, 1) == 0)
            ? parentAAttributes[14]
            : parentBAttributes[14]; //class

        // handle cskill after class define
        uint256[] memory cskillArray = new uint256[](6);
        if (parentAAttributes[14] == parentBAttributes[14]) {
            // both class are same
            cskillArray[0] = parentAAttributes[9];
            cskillArray[1] = parentAAttributes[10];
            cskillArray[2] = parentAAttributes[11];
            cskillArray[3] = parentBAttributes[9];
            cskillArray[4] = parentBAttributes[10];
            cskillArray[5] = parentBAttributes[11];
            (cskillArray, skillCount) = _removeDuplicated(cskillArray);
        } else {
            // both class are different
            skillCount = 4;
            if (attributes[14] == parentAAttributes[14]) {
                cskillArray[0] = parentAAttributes[9];
                cskillArray[1] = parentAAttributes[10];
                cskillArray[2] = parentAAttributes[11];
            } else {
                cskillArray[0] = parentBAttributes[9];
                cskillArray[1] = parentBAttributes[10];
                cskillArray[2] = parentBAttributes[11];
            }
            cskillArray[3] = 255; // empty skill
        }
        // skillCount = 5

        cskillArray = _shuffleOrdering(cskillArray, skillCount);
        attributes[9] = cskillArray[0]; // skill: cskill1
        attributes[10] = cskillArray[1]; // skill: cskill2
        attributes[11] = cskillArray[2]; // skill: cskill3

        // cskill mutation, max 70%
        uint256 mutationChance; // mutationChance 0-6, default 10% mutationChance = 0
        (, mutationChance) = _checkIsGrandparentRepeat(parents[0], parents[1]);
        mutationChance = Math.min(mutationChance, 6);

        if (_randomRange(0, 9) <= mutationChance) {
            // random one skill to mutate
            attributes[11] = (attributes[10] + _randomRange(1, 22)) % 24; //skill: cskill3
            if (attributes[11] == attributes[9]) {
                attributes[11] = (attributes[11] + 1) % 24;
            }
        }

        // special gene
        attributes[15] = (_randomRange(0, 1) == 0)
            ? parentAAttributes[15]
            : parentBAttributes[15];

        // generation
        uint256 childGeneration = Math.max(
            parentAAttributes[16] * 256 + parentAAttributes[17],
            parentBAttributes[16] * 256 + parentBAttributes[17]
        ) + 1;
        attributes[16] = childGeneration / 256;
        attributes[17] = childGeneration % 256;
        return attributes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
// pragma abicoder v2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./planets/contracts/ApeironPlanetGenerator.sol";
import "./interfaces/IApeironPlanet.sol";
import "./interfaces/IBreedPlanetData.sol";

import "./planets/contracts/utils/AccessProtected.sol";

// todo _randomRange should be random orcale
contract BreedPlanetBase is ApeironPlanetGenerator, AccessProtected {
    using Address for address;

    IApeironPlanet public immutable planetContract;
    IBreedPlanetData public immutable breedPlanetDataContract;

    struct ElementStruct {
        uint256 fire;
        uint256 water;
        uint256 air;
        uint256 earth;
        uint256 domainValue;
        uint256 domainIndex; // 1: fire, 2: water, 3: air, 4: earth
    }

    constructor(address _nftAddress, address _breedAddress) {
        require(_nftAddress.isContract(), "_nftAddress must be a contract");
        require(_breedAddress.isContract(), "_breedAddress must be a contract");

        planetContract = IApeironPlanet(_nftAddress);
        breedPlanetDataContract = IBreedPlanetData(_breedAddress);
    }

    /// @notice get planetId Parent ID
    /// @param planetId planetId
    function getParentID(uint256 planetId)
        public
        view
        returns (uint256, uint256)
    {
        uint256 parentAId = 0;
        uint256 parentBId = 0;
        IApeironPlanet.PlanetData memory planetData = _getPlanetData(planetId);
        if (planetData.parents.length == 2) {
            parentAId = planetData.parents[0];
            parentBId = planetData.parents[1];
        }
        return (parentAId, parentBId);
    }

    /// @notice check planet has parent or not
    /// @param planetId planetId
    function _hasParent(uint256 planetId) internal view returns (bool) {
        if (_getPlanetData(planetId).parents.length == 2) {
            return true;
        }
        return false;
    }

    /// @notice get planetId Parent and Grandparent ID array, which Parent in first two slot
    /// @param planetId planetId
    function _getParentAndGrandparentIDArray(uint256 planetId)
        internal
        view
        returns (uint256[] memory)
    {
        require(_hasParent(planetId), "planet have no parents");
        (uint256 parentAId, uint256 parentBId) = getParentID(planetId);
        return _getParentIDArray(parentAId, parentBId);
    }

    /// @notice get planetA planetB Parent's ID array, which planetAId & planetBId in first two slot
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    function _getParentIDArray(uint256 planetAId, uint256 planetBId)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 parentCount = 2;

        if (_hasParent(planetAId)) {
            parentCount += 2;
        }
        if (_hasParent(planetBId)) {
            parentCount += 2;
        }

        uint256[] memory parents = new uint256[](parentCount);
        uint256 index = 2;
        parents[0] = planetAId;
        parents[1] = planetBId;

        if (_hasParent(planetAId)) {
            (uint256 parentAAId, uint256 parentABId) = getParentID(planetAId);
            parents[index++] = parentAAId;
            parents[index++] = parentABId;
        }

        if (_hasParent(planetBId)) {
            (uint256 parentBAId, uint256 parentBBId) = getParentID(planetBId);
            parents[index++] = parentBAId;
            parents[index] = parentBBId;
        }
        return parents; // parent count 2-6
    }

    /// @notice check planetA planetB Parent is repeated
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    function _parentIsRepeated(uint256 planetAId, uint256 planetBId)
        internal
        view
        returns (bool)
    {
        uint256[] memory parentsArray = _getParentIDArray(planetAId, planetBId);
        for (uint256 i = 0; i < parentsArray.length - 1; i++) {
            for (uint256 j = i + 1; j < parentsArray.length; j++) {
                if (parentsArray[i] == parentsArray[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /// @notice check planetA planetB Grandparent is repeated, and repeated count
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    function _checkIsGrandparentRepeat(uint256 planetAId, uint256 planetBId)
        internal
        view
        returns (bool, uint256)
    {
        bool isGrandparentRepeat = false;
        uint256 repeatCount = 0;
        uint256[] memory parentAArray;
        uint256[] memory parentBArray;
        if (_hasParent(planetAId)) {
            parentAArray = _getParentAndGrandparentIDArray(planetAId);
        } else {
            parentAArray = new uint256[](1);
            parentAArray[0] = planetAId;
        }
        if (_hasParent(planetBId)) {
            parentBArray = _getParentAndGrandparentIDArray(planetBId);
        } else {
            parentBArray = new uint256[](1);
            parentBArray[0] = planetBId;
        }
        for (uint256 i = 0; i < parentAArray.length; i++) {
            for (uint256 j = 0; j < parentBArray.length; j++) {
                if (parentAArray[i] == parentBArray[j]) {
                    isGrandparentRepeat = true;
                    repeatCount++;
                }
            }
        }
        return (isGrandparentRepeat, repeatCount);
    }

    /// @notice ease way (without any array creation) to filter out all duplicated values, the result values will be moved to the beginning of array and return the new array length
    /// @dev use new array length to retrieve the non-duplicated values from the new array
    /// @param input input array
    /// @return output array and new array length
    function _removeDuplicated(uint256[] memory input)
        internal
        pure
        returns (uint256[] memory, uint256)
    {
        uint256 availableCount = 1;
        uint256 duplicatedIndex;
        for (uint256 i = 1; i < input.length; i++) {
            duplicatedIndex = 0;
            for (uint256 j = 0; j < i; j++) {
                if (input[i] == input[j]) {
                    duplicatedIndex = i;
                    break;
                }
            }

            //without duplication
            if (duplicatedIndex == 0) {
                input[availableCount] = input[i];
                ++availableCount;
            }
        }

        return (input, availableCount);
    }

    /// @notice random shuffle array ordering
    /// @param input input array
    /// @param availableSize array size
    function _shuffleOrdering(uint256[] memory input, uint256 availableSize)
        internal
        returns (uint256[] memory)
    {
        uint256 wrapindex;
        for (uint256 i = 0; i < availableSize - 1; i++) {
            wrapindex = _randomRange(i + 1, availableSize - 1);
            (input[i], input[wrapindex]) = (input[wrapindex], input[i]);
        }

        return input;
    }

    /// @notice convert geneId To Attributes array
    /// @param _geneId geneId
    /// @param _numOfAttributes Number Of Attributes
    function _convertToAttributes(uint256 _geneId, uint256 _numOfAttributes)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory attributes = new uint256[](_numOfAttributes);

        uint256 geneId = _geneId;
        for (uint256 i = 0; i < attributes.length; i++) {
            attributes[i] = geneId % 256;
            geneId /= 256;
        }

        return attributes;
    }

    /// @notice get planet data
    /// @param planetId planetId
    function _getPlanetData(uint256 planetId)
        internal
        view
        returns (IApeironPlanet.PlanetData memory)
    {
        (IApeironPlanet.PlanetData memory planetData, ) = planetContract
            .getPlanetData(planetId);
        return planetData;
    }

    /// @notice get planet attributes
    /// @param planetId planetId
    function _getPlanetAttributes(uint256 planetId)
        internal
        view
        returns (uint256[] memory)
    {
        return _convertToAttributes(_getPlanetData(planetId).gene, 18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "../planets/contracts/utils/Random.sol";

// abstract contract ChainlinkRng is VRFConsumerBaseV2, Random, Ownable {
contract ChainlinkRng is VRFConsumerBaseV2, Random, Ownable {
    struct ChainlinkStruct {
        uint64 chainlinkSubscriptionId;
        address vrfCoordinator;
        // address linkTokenContract;
        bytes32 keyHash;
    }

    VRFCoordinatorV2Interface COORDINATOR;
    // LinkTokenInterface LINKTOKEN;

    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    // Matic testnet coordinator. For other networks,
    // address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    // address link_token_contract = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    // bytes32 keyHash =
    //     0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    bytes32 keyHash;

    // A reasonable default is 100000, but this value could be different
    // on other networks.
    // max 2500000
    uint32 callbackGasLimit = 2000000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    // Storage parameters
    uint256[] public s_randomWords;
    uint64 public s_subscriptionId;

    // constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    //     COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    //     LINKTOKEN = LinkTokenInterface(link_token_contract);
    //     s_owner = msg.sender;
    //     s_subscriptionId = subscriptionId;
    // }
    constructor(ChainlinkStruct memory _chainlinkStruct)
        VRFConsumerBaseV2(_chainlinkStruct.vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            _chainlinkStruct.vrfCoordinator
        );
        // LINKTOKEN = LinkTokenInterface(_chainlinkStruct.linkTokenContract);
        keyHash = _chainlinkStruct.keyHash;
        s_subscriptionId = _chainlinkStruct.chainlinkSubscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal virtual returns (uint256) {
        // Will revert if subscription is not set and funded.
        return
            COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {
        s_randomWords = randomWords;
        uint256 nonce = s_randomWords[0] % 100;
        _updateRandomNonce(nonce);

        _rngCallBack(requestId);
    }

    function _rngCallBack(uint256 requestId) internal virtual {}

    function setChainlinkPara(
        uint32 _gasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        bytes32 _keyHash
    ) external onlyOwner {
        callbackGasLimit = _gasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
        keyHash = _keyHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity 0.8.12;

import "./utils/Random.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract ApeironPlanetGenerator is Random {
    enum CoreType {
        Elemental,
        Mythic,
        Arcane,
        Divine,
        Primal
    }
    // enum Bloodline {
    //     Pure,    //0
    //     Duo,     //1
    //     Tri,     //2
    //     Mix      //3
    // }
    mapping(CoreType => mapping(uint256 => uint256)) bloodlineRatioPerCoreType;
    mapping(CoreType => uint256) haveTagRatioPerCoreType;

    struct PlanetTag {
        uint256 id;
        uint256 fire;
        uint256 water;
        uint256 air;
        uint256 earth;
    }
    mapping(uint256 => PlanetTag[]) planetTagsPerBloodline;

    // enum ElementType {
    //     Fire,   //0
    //     Water,  //1
    //     Air,    //2
    //     Earth   //3
    // }

    event GenerateGeneId(
        uint256 bloodline,
        uint256[] elementOrders,
        uint256[] attributes,
        uint256 geneId
    );

    constructor() {
        bloodlineRatioPerCoreType[CoreType.Primal][
            0 /*Bloodline.Pure*/
        ] = 100;

        bloodlineRatioPerCoreType[CoreType.Divine][
            0 /*Bloodline.Duo*/
        ] = 10;
        bloodlineRatioPerCoreType[CoreType.Divine][
            1 /*Bloodline.Duo*/
        ] = 90;

        bloodlineRatioPerCoreType[CoreType.Arcane][
            0 /*Bloodline.Pure*/
        ] = 2;
        bloodlineRatioPerCoreType[CoreType.Arcane][
            1 /*Bloodline.Duo*/
        ] = 30;
        bloodlineRatioPerCoreType[CoreType.Arcane][
            2 /*Bloodline.Tri*/
        ] = 68;

        bloodlineRatioPerCoreType[CoreType.Mythic][
            0 /*Bloodline.Pure*/
        ] = 1;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            1 /*Bloodline.Duo*/
        ] = 9;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            2 /*Bloodline.Tri*/
        ] = 72;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            3 /*Bloodline.Mix*/
        ] = 18;

        bloodlineRatioPerCoreType[CoreType.Elemental][
            2 /*Bloodline.Tri*/
        ] = 70;
        bloodlineRatioPerCoreType[CoreType.Elemental][
            3 /*Bloodline.Mix*/
        ] = 30;

        haveTagRatioPerCoreType[CoreType.Primal] = 0;
        haveTagRatioPerCoreType[CoreType.Divine] = 20;
        haveTagRatioPerCoreType[CoreType.Arcane] = 10;
        haveTagRatioPerCoreType[CoreType.Mythic] = 10;
        haveTagRatioPerCoreType[CoreType.Elemental] = 10;

        //18 tags for Duo
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(1, 0, 55, 0, 55)); //Archipelago
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(2, 0, 0, 0, 75)); //Tallmountain Falls
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(3, 0, 75, 0, 0)); //Deep Sea
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(4, 55, 0, 0, 55)); //Redrock Mesas
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(5, 0, 0, 0, 65)); //Mega Volcanoes
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(6, 75, 0, 0, 0)); //Pillars of Flame
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(7, 0, 0, 55, 55)); //Karsts
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(8, 0, 0, 0, 60)); //Hidden Caves
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(9, 0, 0, 75, 0)); //Floating Lands
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(10, 55, 55, 0, 0)); //Ghostlight Swamp
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(11, 0, 65, 0, 0)); //Boiling Seas
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(12, 65, 0, 0, 0)); //Flametouched Oasis
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(13, 0, 55, 55, 0)); //White Frost
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(14, 0, 50, 0, 0)); //Monsoon
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(15, 0, 0, 65, 0)); //Frozen Gale
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(16, 55, 0, 55, 0)); //Anticyclonic Storm
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(17, 60, 0, 0, 0)); //Conflagration
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(18, 0, 0, 60, 0)); //Hurricane

        //28 tags for Tri
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(19, 35, 35, 0, 35)); //Rainforest
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(20, 0, 0, 0, 55)); //Jungle Mountains
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(21, 0, 55, 0, 0)); //Tallest Trees
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(22, 55, 0, 0, 0)); //Steamwoods
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(23, 0, 40, 0, 40)); //Alpine
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(24, 40, 0, 0, 40)); //Sandy Jungle
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(25, 40, 40, 0, 0)); //Mangrove
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(26, 0, 35, 35, 35)); //Tundra
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(27, 0, 0, 0, 40)); //Snow-capped Peaks
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(28, 0, 40, 0, 0)); //Frozen Lakes
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(29, 0, 0, 55, 0)); //Taiga
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(30, 0, 35, 0, 35)); //Hibernia
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(31, 0, 0, 40, 40)); //Prairie
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(32, 0, 40, 40, 0)); //Hailstorm
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(33, 35, 0, 35, 35)); //Wasteland
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(34, 0, 0, 0, 40)); //Sheerstone Spires
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(35, 40, 0, 0, 0)); //Lava Fields
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(36, 0, 0, 40, 0)); //Howling Gales
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(37, 35, 0, 0, 35)); //Dunes
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(38, 0, 0, 35, 35)); //Barren Valleys
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(39, 40, 0, 40, 0)); //Thunder Plains
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(40, 35, 35, 35, 0)); //Salt Marsh
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(41, 0, 40, 0, 0)); //Coral Reef
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(42, 40, 0, 0, 0)); //Fire Swamp
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(43, 0, 0, 40, 0)); //Windswept Heath
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(44, 35, 35, 0, 0)); //Beachside Mire
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(45, 0, 35, 35, 0)); //Gentlesnow Bog
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(46, 35, 0, 35, 0)); //Stormy Night Swamp

        //16 tags for Mix
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(47, 35, 35, 35, 35)); //Utopia
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(48, 30, 30, 30, 30)); //Garden
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(49, 0, 0, 0, 35)); //Mountain
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(50, 0, 35, 0, 0)); //Ocean
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(51, 35, 0, 0, 0)); //Wildfire
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(52, 0, 0, 35, 0)); //Cloud
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(53, 0, 30, 0, 30)); //Forest
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(54, 30, 0, 0, 30)); //Desert
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(55, 0, 0, 30, 30)); //Hill
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(56, 30, 30, 0, 0)); //Swamp
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(57, 0, 30, 30, 0)); //Snow
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(58, 30, 0, 30, 0)); //Plains
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(59, 0, 0, 0, 30)); //Dryland
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(60, 0, 30, 0, 0)); //Marsh
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(61, 30, 0, 0, 0)); //Drought
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(62, 0, 0, 30, 0)); //Storm
    }

    function _getBloodline(CoreType coreType, uint256 randomBaseValue)
        internal
        view
        returns (uint256)
    {
        uint256 picked = 3; //Bloodline.Mix;

        uint256 baseValue = 0;
        for (
            uint256 idx = 0; /*Bloodline.Pure*/
            idx <= 3; /*Bloodline.Mix*/
            idx++
        ) {
            // from Pure to Mix
            baseValue += bloodlineRatioPerCoreType[coreType][idx];
            if (_randomRangeByBaseValue(randomBaseValue, 1, 100) <= baseValue) {
                picked = idx;
                break;
            }
        }

        return picked;
    }

    function _getPlanetTag(
        CoreType coreType,
        uint256 bloodline,
        uint256[2] memory randomBaseValues
    ) internal view returns (PlanetTag memory) {
        PlanetTag memory planetTag;
        //exclude if it is pure
        if (
            bloodline != 0 && /*Bloodline.Pure*/
            //according to ratio
            haveTagRatioPerCoreType[coreType] >=
            _randomRangeByBaseValue(randomBaseValues[0], 1, 100)
        ) {
            //random pick a tag from pool
            planetTag = planetTagsPerBloodline[bloodline][
                _randomByBaseValue(
                    randomBaseValues[1],
                    planetTagsPerBloodline[bloodline].length
                )
            ];
        }
        return planetTag;
    }

    function _getElementOrders(
        uint256 bloodline,
        PlanetTag memory planetTag,
        uint256[4] memory randomBaseValues
    ) internal pure returns (uint256[] memory) {
        uint256[4] memory orders;
        uint256[] memory results = new uint256[](1 + uint256(bloodline));
        uint256 pickedIndex;

        //have not any tag
        if (planetTag.id == 0) {
            //dominant element index
            pickedIndex = _randomByBaseValue(randomBaseValues[0], 4);
        }
        //have any tag
        else {
            uint256 possibleElementSize;
            if (planetTag.fire > 0) {
                orders[possibleElementSize++] = 0; //ElementType.Fire
            }
            if (planetTag.water > 0) {
                orders[possibleElementSize++] = 1; //ElementType.Water
            }
            if (planetTag.air > 0) {
                orders[possibleElementSize++] = 2; //ElementType.Air
            }
            if (planetTag.earth > 0) {
                orders[possibleElementSize++] = 3; //ElementType.Earth
            }

            //dominant element index (random pick from possibleElements)
            pickedIndex = orders[
                _randomByBaseValue(randomBaseValues[0], possibleElementSize)
            ];
        }

        orders[0] = 0; //ElementType.Fire
        orders[1] = 1; //ElementType.Water
        orders[2] = 2; //ElementType.Air
        orders[3] = 3; //ElementType.Earth

        //move the specified element to 1st place
        (orders[0], orders[pickedIndex]) = (orders[pickedIndex], orders[0]);
        //assign the value as result
        results[0] = orders[0];

        //process the remaining elements
        for (uint256 i = 1; i <= bloodline; i++) {
            //random pick the index from remaining elements
            pickedIndex = i + _randomByBaseValue(randomBaseValues[i], 4 - i);
            //move the specified element to {i}nd place
            (orders[i], orders[pickedIndex]) = (orders[pickedIndex], orders[i]);
            //assign the value as result
            results[i] = orders[i];
        }

        return results;
    }

    function _getMaxBetweenValueAndPlanetTag(
        uint256 value,
        uint256 elementType,
        PlanetTag memory planetTag
    ) internal pure returns (uint256) {
        if (planetTag.id > 0) {
            if (
                elementType == 0 /*ElementType.Fire*/
            ) {
                return Math.max(value, planetTag.fire);
            } else if (
                elementType == 1 /*ElementType.Water*/
            ) {
                return Math.max(value, planetTag.water);
            } else if (
                elementType == 2 /*ElementType.Air*/
            ) {
                return Math.max(value, planetTag.air);
            } else if (
                elementType == 3 /*ElementType.Earth*/
            ) {
                return Math.max(value, planetTag.earth);
            }
        }

        return value;
    }

    function _getElementValues(
        uint256 bloodline,
        PlanetTag memory planetTag,
        uint256[] memory elementOrders,
        uint256[3] memory randomBaseValues
    ) internal pure returns (uint256[4] memory) {
        require(elementOrders.length == bloodline + 1, "invalid elementOrders");

        uint256[4] memory values;

        if (
            bloodline == 0 /*Bloodline.Pure*/
        ) {
            values[uint256(elementOrders[0])] = 100;
        } else if (
            bloodline == 1 /*Bloodline.Duo*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 50, 59),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] =
                100 -
                values[uint256(elementOrders[0])];
        } else if (
            bloodline == 2 /*Bloodline.Tri*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 33, 43),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] = _randomRangeByBaseValue(
                randomBaseValues[1],
                23,
                Math.min(43, 95 - values[uint256(elementOrders[0])])
            );
            values[uint256(elementOrders[2])] =
                100 -
                values[uint256(elementOrders[0])] -
                values[uint256(elementOrders[1])];
        } else if (
            bloodline == 3 /*Bloodline.Mix*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 25, 35),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] = _randomRangeByBaseValue(
                randomBaseValues[1],
                20,
                34
            );
            values[uint256(elementOrders[2])] = _randomRangeByBaseValue(
                randomBaseValues[2],
                20,
                Math.min(
                    34,
                    95 -
                        values[uint256(elementOrders[0])] -
                        values[uint256(elementOrders[1])]
                )
            );
            values[uint256(elementOrders[3])] =
                100 -
                values[uint256(elementOrders[0])] -
                values[uint256(elementOrders[1])] -
                values[uint256(elementOrders[2])];
        }

        return values;
    }

    function _generateGeneId(CoreType coreType) internal returns (uint256) {
        uint256 bloodline = _getBloodline(coreType, _getRandomBaseValue());
        PlanetTag memory planetTag = _getPlanetTag(
            coreType,
            bloodline,
            [_getRandomBaseValue(), _getRandomBaseValue()]
        );
        uint256[] memory elementOrders = _getElementOrders(
            bloodline,
            planetTag,
            [
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue()
            ]
        );
        uint256[4] memory elementValues = _getElementValues(
            bloodline,
            planetTag,
            elementOrders,
            [
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue()
            ]
        );
        uint256[] memory attributes = new uint256[](18);
        attributes[0] = elementValues[0]; //element: fire
        attributes[1] = elementValues[1]; //element: water
        attributes[2] = elementValues[2]; //element: air
        attributes[3] = elementValues[3]; //element: earth
        attributes[4] = planetTag.id; //primeval legacy tag
        attributes[5] = _randomRange(0, 1); //body: sex
        attributes[6] = _randomRange(0, 11); //body: weapon
        attributes[7] = _randomRange(0, 3); //body: body props
        attributes[8] = _randomRange(0, 5); //body: head props
        attributes[9] = _randomRange(0, 23); //skill: cskill1
        attributes[10] = (attributes[9] + _randomRange(1, 23)) % 24; //skill: cskill2
        attributes[11] = (attributes[10] + _randomRange(1, 22)) % 24; //skill: cskill3
        if (attributes[11] == attributes[9]) {
            attributes[11] = (attributes[11] + 1) % 24;
        }
        attributes[12] = _randomRange(0, 31); //skill: pskill1
        attributes[13] = (attributes[12] + _randomRange(1, 31)) % 32; //skill: pskill2
        attributes[14] = _randomRange(0, 2); //class
        attributes[15] = _randomRange(0, 31); //special gene
        // attributes[16] = 0; //generation 1st digit
        // attributes[17] = 0; //generation 2nd digit
        uint256 geneId = _convertToGeneId(attributes);
        emit GenerateGeneId(bloodline, elementOrders, attributes, geneId);
        return geneId;
    }

    function _convertToGeneId(uint256[] memory attributes)
        internal
        pure
        returns (uint256)
    {
        uint256 geneId = 0;
        for (uint256 id = 0; id < attributes.length; id++) {
            geneId += attributes[id] << (8 * id);
        }

        return geneId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IApeironPlanet is IERC721 {
    struct PlanetData {
        uint256 gene;
        uint256 baseAge;
        uint256 evolve;
        uint256 breedCount;
        uint256 breedCountMax;
        uint256 createTime; // before hatch
        uint256 bornTime; // after hatch
        uint256 lastBreedTime;
        uint256[] relicsTokenIDs;
        uint256[] parents; //parent token ids
        uint256[] children; //children token ids
    }

    function safeMint(
        uint256 gene,
        // uint256 parentA,
        // uint256 parentB,
        uint256[] calldata parents,
        address to,
        uint256 tokenId
    ) external;

    function updatePlanetData(
        uint256 tokenId,
        uint256 gene,
        //  Add planet baseage, by absorb
        uint256 addAge,
        // evolve the planet.
        uint256 addEvolve,
        // add breed count max
        uint256 addBreedCountMax,
        // update born time to now
        bool setBornTime
    ) external;

    function getPlanetData(uint256 tokenId)
        external
        view
        returns (
            PlanetData memory, //planetData
            bool //isAlive
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBreedPlanetData {
    function updatePlanetNextBornMap(uint256 planetId, uint256 nextBornTime)
        external;

    function getPlanetNextBornTime(uint256 planetId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtected is Context, Ownable {
    mapping(address => bool) internal _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Admin
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether user has admin access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "Caller does not have Admin Access"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract Random {
    uint256 randomNonce;

    function _updateRandomNonce(uint256 _num) internal {
        randomNonce = _num;
    }
    
    function _getRandomNonce() internal view returns (uint256) {
        return randomNonce;
    }

    function __getRandomBaseValue(uint256 _nonce) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            _nonce
        )));
    }

    function _getRandomBaseValue() internal returns (uint256) {
        randomNonce++;
        return __getRandomBaseValue(randomNonce);
    }

    function __random(uint256 _nonce, uint256 _modulus) internal view returns (uint256) {
        require(_modulus >= 1, 'invalid values for random');

        return __getRandomBaseValue(_nonce) % _modulus;
    }

    function _random(uint256 _modulus) internal returns (uint256) {
        randomNonce++;
        return __random(randomNonce, _modulus);
    }

    function _randomByBaseValue(uint256 _baseValue, uint256 _modulus) internal pure returns (uint256) {
        require(_modulus >= 1, 'invalid values for random');

        return _baseValue % _modulus;
    }

    function __randomRange(uint256 _nonce, uint256 _start, uint256 _end) internal view returns (uint256) {
        if (_end > _start) {
            return _start + __random(_nonce, _end + 1 - _start);
        }
        else {
            return _end + __random(_nonce, _start + 1 - _end);
        }
    }

    function _randomRange(uint256 _start, uint256 _end) internal returns (uint256) {
        randomNonce++;
        return __randomRange(randomNonce, _start, _end);
    }

    function _randomRangeByBaseValue(uint256 _baseValue, uint256 _start, uint256 _end) internal pure returns (uint256) {
        if (_end > _start) {
            return _start + _randomByBaseValue(_baseValue, _end + 1 - _start);
        }
        else {
            return _end + _randomByBaseValue(_baseValue, _start + 1 - _end);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
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
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}