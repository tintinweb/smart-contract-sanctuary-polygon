// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./NFTEditionLibrary.sol";
import "./interfaces/IOwnicController.sol";
import "./interfaces/INFTController.sol";

import "./NFTPower.sol";

contract OwnicController is IOwnicController, INFTController, Initializable, AccessControlUpgradeable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using NFTEditionLibrary for address;
    address public eternalStorage;
    NFTPower public nftPower;

    event PlayerEditionAdded(uint256 indexed _editionId);
    event PlayerEditionDiscountAdded(uint256 indexed _editionId);
    event PlayerClassTypeAdded(uint256 indexed _typeId);
    event InflationChanged(uint256 _inflationRate);
    event EditionItemMinted(uint256 indexed _editionId, uint256 indexed _tokenId);

    address public dynamicNFTCollectionAddress;

    function initialize(address _eternalStorage, address _dynamicNFTCollectionAddress, address _nftPower) public initializer {
        eternalStorage = _eternalStorage;
        dynamicNFTCollectionAddress = _dynamicNFTCollectionAddress;
        nftPower = NFTPower(_nftPower);

        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addPlayerEdition(
        uint256 editionId, uint256 _playerId, bytes32 _name, uint16 _classId, bytes32 _position,
        uint16 _overall, uint256 _powerRate, uint256 _price, bool _zeroAllowed) external override onlyRole(DEFAULT_ADMIN_ROLE)
    {

        uint256 _editionId = eternalStorage.addPlayerEdition(editionId, _playerId, _name, _classId, _position, _overall);

        eternalStorage.addPriceToPlayerEdition(editionId, _price, _zeroAllowed);
        nftPower.setEditionPower(editionId, _powerRate);

        emit PlayerEditionAdded(_editionId);
    }

    function addPriceToPlayerEdition(uint256 editionId, uint256 _price, bool _zeroAllowed) external override onlyRole(DEFAULT_ADMIN_ROLE)
    {
        eternalStorage.addPriceToPlayerEdition(editionId, _price, _zeroAllowed);
    }

    function addTraitToPlayerEdition(uint256 _editionId, bytes32 _trait, uint16 _value) external override onlyRole(DEFAULT_ADMIN_ROLE)
    {
        eternalStorage.addTraitToPlayerEdition(_editionId, _trait, _value);
    }

    function addPlayerEditionDiscount(uint256 _editionId, uint256 _duration, uint256 _discountPrice, bool _discountStatic) external override onlyRole(DEFAULT_ADMIN_ROLE)
    {
        eternalStorage.addPlayerEditionDiscount(_editionId, block.timestamp, _duration, _discountPrice, _discountStatic);
        emit PlayerEditionDiscountAdded(_editionId);
    }

    function addPlayerClassType(bytes32 _name, uint16 _typeId, uint16 _mintMax, bytes32 _subGroup) external override onlyRole(DEFAULT_ADMIN_ROLE)
    {
        eternalStorage.addPlayerClassType(_name, _typeId, _mintMax, _subGroup);
        emit PlayerClassTypeAdded(_typeId);
    }

    function handleMint(uint256 _editionId, uint256 _tokenId) external override {
        require(
            IAccessControlUpgradeable(dynamicNFTCollectionAddress).hasRole(MINTER_ROLE, _msgSender()),
            "invalid caller"
        );

        require(eternalStorage.getEditionCanMinted(_editionId) > 0, string(abi.encodePacked("Edition ", Strings.toString(uint256(_editionId)), " can't be minted")));

        eternalStorage.reduceEditionCanMinted(_editionId, _tokenId);
        nftPower.handleMint(_editionId, _tokenId);
        emit EditionItemMinted(_editionId, _tokenId);
    }

    function updatePower(uint256 _editionId, uint256 _tokenId) public override {
        nftPower.updatePower(_editionId, _tokenId);
    }

    function getPlayerEdition(uint256 editionId) external override view returns (bytes32, uint16, bytes32, uint256, uint16, uint16, uint16)
    {
        return eternalStorage.getPlayerEdition(editionId);
    }

    function getEditionPower(uint256 editionId) external view override returns (uint16)
    {
        return nftPower.getEditionPower(editionId);
    }

    function getNftPower(uint256 nftId) external view override returns (uint16)
    {
        return nftPower.getNftPower(nftId, eternalStorage.getPlayerEditionIdByNftId(nftId));
    }

    function getNftCustomPower(uint256 nftId) external view override returns (uint16)
    {
        return nftPower.getNftCustomPower(nftId);
    }

    function getEditionId(uint256 tokenId) external override view returns (uint256) {
        return eternalStorage.getPlayerEditionIdByNftId(tokenId);
    }

    function getPlayerEditionTrait(uint256 editionId) external override view returns (bytes32, uint16)
    {
        return eternalStorage.getPlayerEditionTrait(editionId);
    }

    function getPlayerEditionId(uint16 _class, bytes32 _position, uint256 _index) external override view returns (uint256)
    {
        return eternalStorage.getPlayerEditionId(_class, _position, _index);
    }

    function getPlayerEditionIdByClassId(uint16 _class, uint256 _index) external override view returns (uint256)
    {
        return eternalStorage.getPlayerEditionIdByClassId(_class, _index);
    }

    function getEditionPrice(uint256 _editionId) external override view returns (uint256)
    {
        return eternalStorage.getEditionPrice(_editionId);
    }

    function getEditionPriceCalculated(uint256 _editionId, bytes32 _subGroup) external override view returns (uint256)
    {
        return eternalStorage.getEditionPriceCalculated(_editionId, _subGroup);
    }

    function getEditionCanMinted(uint256 _editionId) external override view returns (uint256)
    {
        return eternalStorage.getEditionCanMinted(_editionId);
    }

    function getEditionIdFromRandom(uint256 _seed, bytes32 _subGroup) external override view returns (uint256)
    {
        uint256 classPart = _getRandom(_seed, keccak256("ClassPart"));
        uint256 offsetPart = _getRandom(_seed, keccak256("OffsetPart"));

        return getEditionIdFromClassPartAndOffset(classPart, offsetPart, _subGroup);
    }

    function getEditionIdFromRandomWithClassId(uint256 _seed, uint16 _classId) external override view returns (uint256)
    {
        uint256 offsetPart = _getRandom(_seed, keccak256("OffsetByClassPart"));
        return getEditionIdFromClassPartAndOffsetWithClassId(offsetPart, _classId);
    }

    function getClassByRarity(uint8 _index) external override view returns (uint16, uint16)
    {
        return eternalStorage.getClassByRarity(_index);
    }

    function getEditionsCount() external override view returns (uint256)
    {
        return eternalStorage.getEditionsCount();
    }

    function getCardsCountByClass(uint16 _classId) public override view returns (uint256) {
        return eternalStorage.getCardsCountByClass(_classId);
    }

    function getEditionIdFromClassPartAndOffset(uint256 classPart, uint256 offsetPart, bytes32 _subGroup) public view returns (uint256)
    {
        uint16 classIdByRarity;
        uint16 classRarity;
        uint256 totalCardsOnPosition;

        for (uint8 i = 0; i < 100; i++) {
            (classIdByRarity, classRarity) = eternalStorage.getClassByRarity(i);

            if (_subGroup != "" && !eternalStorage.getClassIsInSubgroup(classIdByRarity, _subGroup)) {
                continue;
            }

            totalCardsOnPosition += eternalStorage.getCardsCountByClass(classIdByRarity);
        }

        uint256 classOffset = classPart % totalCardsOnPosition;
        uint256 currentClassOffset = 0;
        uint256 countByClass = 0;

        for (uint8 i = 0; i < 100; i++) {
            (classIdByRarity, classRarity) = eternalStorage.getClassByRarity(i);

            if (_subGroup != "" && !eternalStorage.getClassIsInSubgroup(classIdByRarity, _subGroup)) {
                continue;
            }

            countByClass = eternalStorage.getEditionsCountByClassId(classIdByRarity);

            currentClassOffset += countByClass * classRarity;

            if (countByClass == 0) {
                continue;
            }

            if (classOffset < currentClassOffset) {
                break;
            }
        }

        return eternalStorage.getPlayerEditionIdByClassId(classIdByRarity, (offsetPart % countByClass) + 1);
    }

    function getEditionIdFromClassPartAndOffsetWithClassId(uint256 offsetPart, uint16 _classId) public view returns (uint256)
    {
        uint256 countByClass = eternalStorage.getEditionsCountByClassId(_classId);
        return eternalStorage.getPlayerEditionIdByClassId(_classId, (offsetPart % countByClass) + 1);
    }

    function getEditionsCountByClassId(uint16 _classId) public view returns (uint256){
        return eternalStorage.getEditionsCountByClassId(_classId);
    }

    function _getRandom(uint256 _seed, bytes32 order) public view returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, _seed, order)));
    }

    function getIndexByClass(uint256 _editionId) public view returns (uint256){
        return eternalStorage.getIndexByClass(_editionId);
    }

    function reduceEditionCanMinted(uint256 _editionId, uint256 _tokenId) public {
        eternalStorage.reduceEditionCanMinted(_editionId, _tokenId);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";

// https://docs.synthetix.io/contracts/source/contracts/state
abstract contract State is Owned {

    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);

}

pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/contracts/owned
// SPDX-License-Identifier: MIT
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";
import "./State.sol";

// https://docs.synthetix.io/contracts/source/contracts/eternalstorage
/**
 * @notice  This contract is based on the code available from this blog
 * https://blog.colony.io/writing-upgradeable-contracts-in-solidity-6743f0eecc88/
 * Implements support for storing a keccak256 key and value pairs. It is the more flexible
 * and extensible option. This ensures data schema changes can be implemented without
 * requiring upgrades to the storage contract.
 */
contract EternalStorage is Owned, State {

    constructor(address _owner, address _associatedContract) Owned(_owner) State(_associatedContract) {}

    /* ========== DATA TYPES ========== */
    mapping(bytes32 => uint) internal UIntStorage;
    // @notice added by OWNIC
    mapping(bytes32 => uint16) internal UInt16Storage;
    mapping(bytes32 => string) internal StringStorage;
    mapping(bytes32 => address) internal AddressStorage;
    mapping(bytes32 => bytes) internal BytesStorage;
    mapping(bytes32 => bytes32) internal Bytes32Storage;
    mapping(bytes32 => bool) internal BooleanStorage;
    mapping(bytes32 => int) internal IntStorage;

    // UIntStorage;
    function getUIntValue(bytes32 record) external view returns (uint) {
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) external onlyAssociatedContract {
        UIntStorage[record] = value;
    }

    function deleteUIntValue(bytes32 record) external onlyAssociatedContract {
        delete UIntStorage[record];
    }

    // UInt16Storage;
    function getUInt16Value(bytes32 record) external view returns (uint16) {
        return UInt16Storage[record];
    }

    function setUInt16Value(bytes32 record, uint16 value) external onlyAssociatedContract {
        UInt16Storage[record] = value;
    }

    function deleteUInt16Value(bytes32 record) external onlyAssociatedContract {
        delete UInt16Storage[record];
    }

    // StringStorage
    function getStringValue(bytes32 record) external view returns (string memory) {
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string calldata value) external onlyAssociatedContract {
        StringStorage[record] = value;
    }

    function deleteStringValue(bytes32 record) external onlyAssociatedContract {
        delete StringStorage[record];
    }

    // AddressStorage
    function getAddressValue(bytes32 record) external view returns (address) {
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) external onlyAssociatedContract {
        AddressStorage[record] = value;
    }

    function deleteAddressValue(bytes32 record) external onlyAssociatedContract {
        delete AddressStorage[record];
    }

    // BytesStorage
    function getBytesValue(bytes32 record) external view returns (bytes memory) {
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes calldata value) external onlyAssociatedContract {
        BytesStorage[record] = value;
    }

    function deleteBytesValue(bytes32 record) external onlyAssociatedContract {
        delete BytesStorage[record];
    }

    // Bytes32Storage
    function getBytes32Value(bytes32 record) external view returns (bytes32) {
        return Bytes32Storage[record];
    }

    function setBytes32Value(bytes32 record, bytes32 value) external onlyAssociatedContract {
        Bytes32Storage[record] = value;
    }

    function deleteBytes32Value(bytes32 record) external onlyAssociatedContract {
        delete Bytes32Storage[record];
    }

    // BooleanStorage
    function getBooleanValue(bytes32 record) external view returns (bool) {
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) external onlyAssociatedContract {
        BooleanStorage[record] = value;
    }

    function deleteBooleanValue(bytes32 record) external onlyAssociatedContract {
        delete BooleanStorage[record];
    }

    // IntStorage
    function getIntValue(bytes32 record) external view returns (int) {
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) external onlyAssociatedContract {
        IntStorage[record] = value;
    }

    function deleteIntValue(bytes32 record) external onlyAssociatedContract {
        delete IntStorage[record];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IPowerReconstructConsumer {

    function handlePowerChange(uint256 tokenId, uint16 addedPower) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @notice added by OWNIC
interface IOwnicController {

    // TODO test 2
    function addPlayerEdition(uint256 editionId, uint256 _playerId, bytes32 _name, uint16 _class, bytes32 _position, uint16 _overall, uint256 _powerRate, uint256 _price, bool _isZeroAllowed) external;

    function addPriceToPlayerEdition(uint256 editionId, uint256 _price, bool _isZeroAllowed) external;

    function addPlayerEditionDiscount(uint256 _editionId, uint256 _duration, uint256 _discountPrice, bool _discountStatic) external;

    function addTraitToPlayerEdition(uint256 _editionId, bytes32 _trait, uint16 _value) external;

    // TODO test 1
    function addPlayerClassType(bytes32 _name, uint16 _typeId, uint16 _mintMax, bytes32 _subGroup) external;

    function handleMint(uint256 _editionId, uint256 _tokenId) external;

    function updatePower(uint256 _editionId, uint256 _tokenId) external;

    function getPlayerEdition(uint256 editionId) external returns (bytes32, uint16, bytes32, uint256, uint16, uint16, uint16);

    function getPlayerEditionTrait(uint256 editionId) external returns (bytes32, uint16);

    function getPlayerEditionId(uint16 _class, bytes32 _position, uint256 _index) external returns (uint256);

    function getPlayerEditionIdByClassId(uint16 _class, uint256 _index) external view returns (uint256);

    function getEditionPrice(uint256 _editionId) external view returns (uint256);

    function getEditionPriceCalculated(uint256 _editionId, bytes32 _subGroup) external view returns (uint256);

    function getEditionCanMinted(uint256 _editionId) external view returns (uint256);

    function getEditionIdFromRandom(uint256 _seed, bytes32 _subGroup) external view returns (uint256);

    function getEditionIdFromRandomWithClassId(uint256 _seed, uint16 _classId) external view returns (uint256);

    function getClassByRarity(uint8 _index) external view returns (uint16, uint16);

    function getEditionsCount() external view returns (uint256);

    function getCardsCountByClass(uint16 _classId) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTPower {

    // Views
    function getEditionCurrentNonce(uint256 editionId) external view returns (uint256);

    function getNftCurrentNonce(uint256 nftId) external view returns (uint256);

    function getEditionPowerByNonce(uint256 editionId, uint256 nonce) external view returns (uint256);

    function getNftPowerByNonce(uint256 nftId, uint256 nonce) external view returns (uint256);

    function getNftPower(uint256 tokenId, uint256 editionId) external view returns (uint16);

    function getNftCustomPower(uint256 tokenId) external view returns (uint16);

    function getEditionPower(uint256 editionId) external view returns (uint16);



    function handleMint(uint256 editionId, uint256 tokenId) external;

    function updatePower(uint256 editionId, uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTController {

    // Views
    function getNftPower(uint256 nftId) external view returns (uint16);

    function getNftCustomPower(uint256 nftId) external view returns (uint16);

    function getEditionPower(uint256 editionId) external view returns (uint16);

    function getEditionId(uint256 tokenId) external view returns (uint256);

}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPowerReconstructConsumer.sol";
import "./interfaces/INFTPower.sol";


contract NFTPower is AccessControlEnumerable, INFTPower, Ownable {

    /* ========== STATE VARIABLES ========== */

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    bytes32 public constant OWNIC_CONTROLLER = keccak256("OWNIC_CONTROLLER");

    using SafeMath for uint256;
    using SafeCast for uint256;

    // TODO change to consumer list
    IPowerReconstructConsumer public powerReconstructConsumer;

    address private signer;

    mapping(uint256 => uint256) private nftCurrentNonce;
    mapping(uint256 => uint256) private editionCurrentNonce;

    mapping(uint256 => uint256) private nftCreatedAtEditionNonce;
    mapping(uint256 => uint256) private nftPowerUpdatedAtEditionNonce;

    mapping(bytes32 => uint256) private nftPowerByNonce;
    mapping(bytes32 => uint256) private editionPowerByNonce;


    constructor(address _signer, address _powerReconstructConsumer) public {

        signer = _signer;

        if (_powerReconstructConsumer != address(0)) {
            powerReconstructConsumer = IPowerReconstructConsumer(_powerReconstructConsumer);
        }

        _setupRole(DEFAULT_ADMIN_ROLE, signer);
        _setupRole(SIGNER_ROLE, signer);
    }


    function powerProofNft(uint256 nftId, uint256 nonce, uint256 powerAdded, bytes memory signature) external {

        require(nftCurrentNonce[nftId] + 1 == nonce, "nonce value is not valid");

        uint256 _oldPower = nftPowerByNonce[keccak256(abi.encodePacked(nftId, nonce - 1))];

        bytes32 hashWithoutPrefix = keccak256(abi.encodePacked(uint256(0), nftId, nonce, powerAdded, _oldPower, toUint(address(this))));

        verifySigner(hashWithoutPrefix, signature);

        uint256 _updatedPower = _oldPower + powerAdded;
        nftPowerByNonce[keccak256(abi.encodePacked(nftId, nonce))] = _updatedPower;

        nftCurrentNonce[nftId] = nonce;
    }

    function powerProofEdition(uint256 editionId, uint256 nonce, uint256 powerAdded, bytes memory signature) external {

        require(editionCurrentNonce[editionId] + 1 == nonce, "nonce value is not valid");

        uint256 _oldPower = editionPowerByNonce[keccak256(abi.encodePacked(editionId, nonce - 1))];

        bytes32 hashWithoutPrefix = keccak256(abi.encodePacked(uint256(1), editionId, nonce, powerAdded, _oldPower, toUint(address(this))));

        verifySigner(hashWithoutPrefix, signature);

        uint256 _updatedPower = _oldPower + powerAdded;
        editionPowerByNonce[keccak256(abi.encodePacked(editionId, nonce))] = _updatedPower;

        editionCurrentNonce[editionId] = nonce;
    }

    function setControllerRole(address ownicControllerAddress) public onlyOwner {
        _setupRole(OWNIC_CONTROLLER, ownicControllerAddress);
    }

    function setReconstructConsumer(address _powerReconstructConsumer) public onlyOwner {
        powerReconstructConsumer = IPowerReconstructConsumer(_powerReconstructConsumer);
    }

    function setEditionPower(uint256 editionId, uint256 _power) public {
        require(getNftCurrentNonce(editionId) == 0, "power already updated");
        require(_power >= 1, "power must be more the 1");
        nftCurrentNonce[editionId] = _power;
        nftPowerByNonce[keccak256(abi.encodePacked(editionId, nftCurrentNonce[editionId]))] = _power;
    }


    function getEditionCurrentNonce(uint256 editionId) public view override returns (uint256){
        return editionCurrentNonce[editionId];
    }

    function getNftCurrentNonce(uint256 nftId) public view override returns (uint256){
        return nftCurrentNonce[nftId];
    }

    function getEditionPowerByNonce(uint256 editionId, uint256 nonce) public view override returns (uint256){
        return editionPowerByNonce[keccak256(abi.encodePacked(editionId, nonce))];
    }

    function getNftPowerByNonce(uint256 nftId, uint256 nonce) public view override returns (uint256){
        return nftPowerByNonce[keccak256(abi.encodePacked(nftId, nonce))];
    }

    function getNftPower(uint256 nftId, uint256 editionId) public view override returns (uint16){
        uint256 lastPower = getEditionPowerByNonce(editionId, nftPowerUpdatedAtEditionNonce[nftId]);
        uint256 customPower = getNftCustomPower(nftId);
        uint256 createdPower = getEditionPowerByNonce(editionId, nftCreatedAtEditionNonce[nftId]);

        return SafeCast.toUint16(lastPower + customPower - createdPower);
    }

    function getNftCustomPower(uint256 nftId) public view override returns (uint16) {
        return SafeCast.toUint16(getNftPowerByNonce(nftId, getNftCurrentNonce(nftId)).sub(getNftPowerByNonce(nftId, nftCreatedAtEditionNonce[nftId])));
    }

    function getEditionPower(uint256 editionId) public view override returns (uint16) {
        return SafeCast.toUint16(getEditionPowerByNonce(editionId, getEditionCurrentNonce(editionId)));
    }

    function handleMint(uint256 editionId, uint256 nftId) public override {
        require(hasRole(OWNIC_CONTROLLER, _msgSender()), "caller must be controller");

        nftCreatedAtEditionNonce[nftId] = editionCurrentNonce[editionId];
    }

    function updatePower(uint256 editionId, uint256 nftId) public override {
        require(hasRole(OWNIC_CONTROLLER, _msgSender()), "caller must be controller");

        uint16 before = getNftPower(editionId, nftId);
        nftPowerUpdatedAtEditionNonce[nftId] = getEditionCurrentNonce(editionId);
        uint16 then = getNftPower(editionId, nftId);

        if (address(powerReconstructConsumer) != address(0)) {
            powerReconstructConsumer.handlePowerChange(nftId, then - before);
        }
    }


    function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
        // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
        // second 32 bytes.
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function verifySigner(bytes32 hashWithoutPrefix, bytes memory signature) internal view {
        // This recreates the message hash that was signed on the client.
        bytes32 hash = prefixed(hashWithoutPrefix);
        // Verify that the message's signer is the owner
        address recoveredSigner = recoverSigner(hash, signature);

        require(hasRole(SIGNER_ROLE, recoveredSigner), "must be signer");

    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function toUint(address _address) internal pure virtual returns (uint256) {
        return uint256(uint160(_address));
    }

}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./storage/EternalStorage.sol";

// @notice added by OWNIC
library NFTEditionLibrary {

    using SafeMath for uint256;

    // get current(edition witch have at ones one item to mint) number off addition by _classId
    function getEditionsCountByClassId(address _storageContract, uint16 _classId) public view returns (uint256)
    {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked(_classId, "Count")));
    }

    // get current(edition witch have at ones one item to mint) number off all editions
    function getEditionsCount(address _storageContract) public view returns (uint256)
    {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("AllCount")));
    }

    function getIndexByClass(address _storageContract, uint256 _editionId) public view returns (uint256)
    {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("edition_index_in_class", _editionId)));
    }

    function getPlayerEdition(address _storageContract, uint256 editionId) public view returns (bytes32, uint16, bytes32, uint256, uint16, uint16, uint16)
    {
        return (
        EternalStorage(_storageContract).getBytes32Value(keccak256(abi.encodePacked("edition_name", editionId))),
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_class", editionId))),
        EternalStorage(_storageContract).getBytes32Value(keccak256(abi.encodePacked("edition_position", editionId))),
        EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("edition_price", editionId))),
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_overall", editionId))),
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_mint_max", editionId))),
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_minted", editionId)))
        );
    }

    function getPlayerEditionTrait(address _storageContract, uint256 _editionId) public view returns (bytes32, uint16)
    {
        return (
        EternalStorage(_storageContract).getBytes32Value(keccak256(abi.encodePacked(_editionId, "Trait"))),
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked(_editionId, "TraitValue")))
        );
    }

    function getPlayerEditionId(address _storageContract, uint16 _classId, bytes32 _position, uint256 _index) public view returns (uint256)
    {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked(_classId, _position, _index)));
    }

    function getPlayerEditionIdByClassId(address _storageContract, uint16 _classId, uint256 _index) public view returns (uint256)
    {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("indexed_by_class", _classId, _index)));
    }

    function getCardsCountByClass(address _storageContract, uint16 _classId) public view returns (uint256) {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("cards_count_by_class", _classId)));
    }

    function getPlayerEditionIdByNftId(address _storageContract, uint256 tokenId) public view returns (uint256)
    {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("nft_edition_mapping", tokenId)));
    }

    function getEditionPrice(address _storageContract, uint256 _editionId) public view returns (uint256)
    {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("edition_price", _editionId)));
    }

    function getEditionPriceCalculated(address _storageContract, uint256 _editionId, bytes32 _subGroup) public view returns (uint256)
    {
        uint256 _price = getEditionPrice(_storageContract, _editionId);

        if (_subGroup != "") {
            uint16 clasId = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_class", _editionId)));

            require(
                EternalStorage(_storageContract).getBooleanValue(keccak256(abi.encodePacked("class_type_sub_group", _subGroup, clasId))),
                "class can't minted by this subgroup"
            );
        }

        uint256 _discountStartedAt = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("discount_started_at", _editionId)));

        if (_discountStartedAt == 0) {
            return _price;
        }

        uint256 _secondsPassed = 0;

        if (block.timestamp > _discountStartedAt) {
            _secondsPassed = block.timestamp - _discountStartedAt;
        }
        uint256 _duration = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("discount_duration", _editionId)));
        uint256 _discountPrice = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("discount_price", _editionId)));
        bool _discountStatic = EternalStorage(_storageContract).getBooleanValue(keccak256(abi.encodePacked("discount_static", _editionId)));

        if (_secondsPassed >= _duration) {
            return _price;
        } else if (_discountStatic) {
            return _discountPrice;
        } else {
            uint256 _totalPriceChange = _price - _discountPrice;
            uint256 _currentPriceChange = _totalPriceChange * _secondsPassed / _duration;
            return _discountPrice + _currentPriceChange;
        }
    }

    function getEditionCanMinted(address _storageContract, uint256 _editionId) public view returns (uint16)
    {
        uint16 mintMax = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_mint_max", _editionId)));
        uint16 minted = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_minted", _editionId)));
        return mintMax - minted;
    }

    function getClassByRarity(address _storageContract, uint8 _index) public view returns (uint16, uint16)
    {
        uint16 classId = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("class_type_id_by_rarity", _index)));

        return (
        classId,
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("class_type_rarity", classId)))
        );
    }

    function getClassIsInSubgroup(address _storageContract, uint16 _classId, bytes32 _subGroup) public view returns (bool)
    {
        return (EternalStorage(_storageContract).getBooleanValue(keccak256(abi.encodePacked("class_type_sub_group", _subGroup, _classId))));
    }

    function addPlayerEdition(
        address _storageContract,
        uint256 editionId, uint256 _playerId, bytes32 _name, uint16 _classId, bytes32 _position, uint16 _overall) public returns (uint256)
    {
        require(editionId > 0 && _classId > 0 && _playerId > 0);
        uint256 savedPlayer = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("edition_player_id", editionId)));

        require(savedPlayer == 0, "edition already saved");

        uint16 mintMax = getMintMax(_storageContract, _classId);
        require(mintMax > 0);

        saveEditionInfo(_storageContract, editionId, _playerId, _name, _classId, _position, _overall, mintMax);
        updateCountByClassId(_storageContract, editionId, _classId);
        updateTotalPlayersCount(_storageContract);

        return editionId;
    }

    function addPriceToPlayerEdition(address _storageContract, uint256 editionId, uint256 _price, bool _zeroAllowed) public
    {
        require(_price > 0 || _zeroAllowed == true);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("edition_price", editionId)), _price);
    }

    function getMintMax(address _storageContract, uint16 _classId) public view returns (uint16){
        return EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("class_type_rarity", _classId)));
    }

    // TODO add sport type
    function saveEditionInfo(address _storageContract, uint256 editionId, uint256 _playerId, bytes32 _name, uint16 _classId, bytes32 _position, uint16 _overall, uint16 mintMax) public {
        EternalStorage(_storageContract).setBytes32Value(keccak256(abi.encodePacked("edition_name", editionId)), _name);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("edition_player_id", editionId)), _playerId);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("edition_class", editionId)), _classId);
        EternalStorage(_storageContract).setBytes32Value(keccak256(abi.encodePacked("edition_position", editionId)), _position);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("edition_mint_max", editionId)), mintMax);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("edition_minted", editionId)), 0);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("edition_overall", editionId)), _overall);
        EternalStorage(_storageContract).setBooleanValue(keccak256(abi.encodePacked("edition_enabled", editionId)), true);
    }

    function updateCountByClassId(address _storageContract, uint256 editionId, uint16 _classId) public {
        uint256 countAllByClass = getEditionsCountByClassId(_storageContract, _classId);
        uint256 allCardsByClass = getCardsCountByClass(_storageContract, _classId);
        uint16 mintMax = getMintMax(_storageContract, _classId);

        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("cards_count_by_class", _classId)), allCardsByClass + mintMax);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked(_classId, "Count")), countAllByClass + 1);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("indexed_by_class", _classId, countAllByClass + 1)), editionId);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("edition_index_in_class", editionId)), countAllByClass + 1);
    }

    function updateTotalPlayersCount(address _storageContract) public {
        uint256 countAll = getEditionsCount(_storageContract);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("AllCount")), countAll + 1);
    }

    function addTraitToPlayerEdition(address _storageContract, uint256 _editionId, bytes32 _trait, uint16 _value) public
    {
        EternalStorage(_storageContract).setBytes32Value(keccak256(abi.encodePacked(_editionId, "Trait")), _trait);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked(_editionId, "TraitValue")), _value);
    }

    function addPlayerEditionDiscount(
        address _storageContract, uint256 _editionId,
        uint256 _discountStartedAt, uint256 _duration, uint256 _discountPrice, bool _discountStatic) public returns (uint256)
    {
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("discount_started_at", _editionId)), _discountStartedAt);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("discount_duration", _editionId)), _duration);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("discount_price", _editionId)), _discountPrice);
        EternalStorage(_storageContract).setBooleanValue(keccak256(abi.encodePacked("discount_static", _editionId)), _discountStatic);
        return getEditionPriceCalculated(_storageContract, _editionId, "");
    }

    // change
    function reduceEditionCanMinted(address _storageContract, uint256 _editionId, uint256 _tokenId) public
    {
        uint16 _classId = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_class", _editionId)));

        uint256 allCardsByClass = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("cards_count_by_class", _classId)));
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("cards_count_by_class", _classId)), allCardsByClass - 1);

        uint16 minted = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_minted", _editionId)));
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("edition_minted", _editionId)), minted + 1);

        uint16 mintMax = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_mint_max", _editionId)));

        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("nft_edition_mapping", _tokenId)), _editionId);

        if (mintMax - minted == 1) {
            bytes32 _position = EternalStorage(_storageContract).getBytes32Value(keccak256(abi.encodePacked("edition_position", _editionId)));

            // get all counts
            uint256 countByClass = getEditionsCountByClassId(_storageContract, _classId);

            // reduce all counts
            EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked(_classId, "Count")), countByClass - 1);


            // get editions current indexes to swap with last
            uint256 indexByClass = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("edition_index_in_class", _editionId)));

            // get last indexes to swap with current
            uint256 lastEditionToSwapIndexByClass = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("indexed_by_class", _classId, countByClass)));

            // swap
            EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("indexed_by_class", _classId, indexByClass)), lastEditionToSwapIndexByClass);

            // last slot clear
            EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("indexed_by_class", _classId, countByClass)), 0);

            // clear current edition legacy index data
            EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("edition_index_in_class", _editionId)), 0);

            // change index to item witch moved from last position to cleared edition position
            if (_editionId != lastEditionToSwapIndexByClass) {
                EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("edition_index_in_class", lastEditionToSwapIndexByClass)), indexByClass);
            }
        }
    }

    function addPlayerClassType(address _storageContract, bytes32 _name, uint16 _typeId, uint16 _rarity, bytes32 _subGroup) public
    {
        // TODO add check _typeId > 0

        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("class_type_id", _typeId)), _typeId);
        EternalStorage(_storageContract).setBytes32Value(keccak256(abi.encodePacked("class_type_name", _typeId)), _name);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("class_type_rarity", _typeId)), _rarity);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("class_type_rarity", _typeId)), _rarity);
        EternalStorage(_storageContract).setBooleanValue(keccak256(abi.encodePacked("class_type_sub_group", _subGroup, _typeId)), true);

        bool alreadyInserted = false;
        uint16 lastClassRarity = 0;
        uint16 lastClassIdByRarity = 0;

        for (uint8 i = 0; i < 100; i++) {

            uint16 curClassIdByRarity = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("class_type_id_by_rarity", i)));
            uint16 curClassRarity = 0;

            if (curClassIdByRarity > 0) {
                curClassRarity = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("class_type_rarity", curClassIdByRarity)));
            }

            if (!alreadyInserted) {
                if (_rarity > curClassRarity) {
                    EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("class_type_id_by_rarity", i)), _typeId);
                    alreadyInserted = true;
                }
            } else {

                EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("class_type_id_by_rarity", i)), lastClassIdByRarity);
            }

            lastClassRarity = curClassRarity;
            lastClassIdByRarity = curClassIdByRarity;

            if (curClassIdByRarity == 0) {
                break;
            }
        }
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
library EnumerableSet {
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
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

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}