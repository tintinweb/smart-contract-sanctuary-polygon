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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Depictorial is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _AtomicIds;
    Counters.Counter private _CollectionIds;
    Counters.Counter private _LicenseIds;
    Counters.Counter private _PurchaseIds;
    address owner;
    // platform fee
    uint256 private platformFee = 25;
    uint256 private deno = 1000;
    // asset limit for a collection
    uint256 private assetLimit = 100;
    enum Type {
        Atomic,
        Collection
    }
    enum DeItemType {
        Image,
        Video,
        Audio
    }
    struct User {
        address payable userAddress;
        uint256[] collectionIds;
        uint256[] atomicIds;
        uint256[] licenseIds;
        uint256[] purchaseIds;
    }

    struct Licecnse {
        uint256 Id;
        address payable Owner;
        uint256 Price;
        uint Duration;
    }
    struct Purchase {
        uint256 Id;
        address payable Buyer;
        uint256 licenseId;
        uint256 DeItemId;
        Type AssetType;
    }
    struct DeItem {
        uint256 Id;
        Type AssetType;
        DeItemType ItemType;
        address payable Owner;
        uint256[] licenseIds;
        string metaData;
    }

    mapping(address => User) public users;
    DeItem[] public collections;
    DeItem[] public atomics;
    Licecnse[] public licenses;
    Purchase[] public purchases;

    constructor() {
        owner = msg.sender;
        collections.push(
            DeItem({
                Id: 0,
                AssetType: Type.Collection,
                ItemType: DeItemType.Image,
                Owner: payable(address(0)),
                licenseIds: new uint256[](0),
                metaData: "Default Collection"
            })
        );
        atomics.push(
            DeItem({
                Id: 0,
                AssetType: Type.Atomic,
                ItemType: DeItemType.Image,
                Owner: payable(address(0)),
                licenseIds: new uint256[](0),
                metaData: "Default Atomic"
            })
        );
        licenses.push(
            Licecnse({Id: 0, Owner: payable(address(0)), Price: 0, Duration: 0})
        );
        purchases.push(
            Purchase({
                Id: 0,
                Buyer: payable(address(0)),
                licenseId: 0,
                DeItemId: 0,
                AssetType: Type.Atomic
            })
        );
        registerUser();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    //  modifier function to check if the user is registered
    modifier isRegistered() {
        require(
            users[msg.sender].userAddress == msg.sender,
            "You are not registered"
        );
        _;
    }

    // function to register a user, from msg.sender, return the user Id
    function registerUser() public returns (bool) {
        if (users[msg.sender].userAddress != address(0)) {
            return true;
        }
        users[msg.sender] = User({
            userAddress: payable(msg.sender),
            atomicIds: new uint256[](0),
            collectionIds: new uint256[](0),
            licenseIds: new uint256[](0),
            purchaseIds: new uint256[](0)
        });
        return true;
    }

    // function to register a user, from msg.sender, return the user Id
    function registerUser(address _addr) public onlyOwner returns (bool) {
        if (users[msg.sender].userAddress != address(0)) {
            return true;
        }
        users[msg.sender] = User({
            userAddress: payable(_addr),
            atomicIds: new uint256[](0),
            collectionIds: new uint256[](0),
            licenseIds: new uint256[](0),
            purchaseIds: new uint256[](0)
        });
        return true;
    }

    // function to check if the user is registered
    function isUserRegistered() public view returns (bool) {
        if (users[msg.sender].userAddress != address(0)) {
            return true;
        }
        return false;
    }

    // function to create a license, return the license Id
    function createLicense(
        uint256 _price,
        uint256 _duration
    ) public isRegistered returns (uint256) {
        _LicenseIds.increment();
        uint256 newLicenseId = _LicenseIds.current();
        licenses.push(
            Licecnse({
                Id: newLicenseId,
                Owner: payable(msg.sender),
                Price: _price,
                Duration: _duration
            })
        );
        users[msg.sender].licenseIds.push(newLicenseId);
        return newLicenseId;
    }

    // function to create a DeItem given the assetType , ItemType,licenseIds , metaData and store it in the user struct as well and return the DeItem Id
    function createDeItem(
        Type _assetType,
        DeItemType _itemType,
        uint256[] memory _licenseIds,
        string memory _metaData
    ) public isRegistered returns (uint256) {
        if (_assetType == Type.Atomic) {
            _AtomicIds.increment();
            uint256 newAtomicId = _AtomicIds.current();
            atomics.push(
                DeItem({
                    Id: newAtomicId,
                    AssetType: _assetType,
                    ItemType: _itemType,
                    Owner: payable(msg.sender),
                    licenseIds: _licenseIds,
                    metaData: _metaData
                })
            );
            users[msg.sender].atomicIds.push(newAtomicId);
            return newAtomicId;
        } else {
            _CollectionIds.increment();
            uint256 newCollectionId = _CollectionIds.current();
            collections.push(
                DeItem({
                    Id: newCollectionId,
                    AssetType: _assetType,
                    ItemType: _itemType,
                    Owner: payable(msg.sender),
                    licenseIds: _licenseIds,
                    metaData: _metaData
                })
            );
            users[msg.sender].collectionIds.push(newCollectionId);
            return newCollectionId;
        }
    }

    // function to buy a DeItem given the licenseId , DeItemId and assetType
    function buyDeItem(
        uint256 _licenseId,
        uint256 _deItemId,
        Type _assetType
    ) public payable isRegistered returns (uint256) {
        require(
            licenses[_licenseId].Owner != address(0),
            "License does not exist"
        );
        // require(
        //     licenses[_licenseId].Price == msg.value,
        //     "Price does not match"
        // );
        require(
            licenses[_licenseId].Owner != msg.sender,
            "You are the owner of the license"
        );
        if (_assetType == Type.Atomic) {
            require(
                atomics[_deItemId].Owner != address(0),
                "Atomic does not exist"
            );
            require(
                atomics[_deItemId].Owner != msg.sender,
                "You are the owner of the Atomic"
            );
            atomics[_deItemId].Owner.transfer(msg.value);
            // atomics[_deItemId].Owner = payable(msg.sender);
        } else {
            require(
                collections[_deItemId].Owner != address(0),
                "Collection does not exist"
            );
            require(
                collections[_deItemId].Owner != msg.sender,
                "You are the owner of the Collection"
            );
            collections[_deItemId].Owner.transfer(msg.value);
            // collections[_deItemId].Owner = payable(msg.sender);
        }
        _PurchaseIds.increment();
        uint256 newPurchaseId = _PurchaseIds.current();
        purchases.push(
            Purchase({
                Id: newPurchaseId,
                Buyer: payable(msg.sender),
                licenseId: _licenseId,
                DeItemId: _deItemId,
                AssetType: _assetType
            })
        );
        users[msg.sender].purchaseIds.push(newPurchaseId);
        return newPurchaseId;
    }

    // function to get the atomic details and the license details and the collection details and the purchase details , given the user address
    function getUserDetails(
        address _addr
    )
        public
        view
        returns (
            DeItem[] memory atomicDetails,
            DeItem[] memory collectionDetails,
            Licecnse[] memory licenseDetails,
            Purchase[] memory purchaseDetails
        )
    {
        return (
            getDeItems(users[_addr].atomicIds, Type.Atomic),
            getDeItems(users[_addr].collectionIds, Type.Collection),
            getLicenses(users[_addr].licenseIds),
            getPurchases(users[_addr].purchaseIds)
        );
    }

    function getDeItems(
        uint256[] memory _deItemIds,
        Type _assetType
    ) internal view returns (DeItem[] memory DeItems) {
        if (_assetType == Type.Atomic) {
            return getDeItemsByType(_deItemIds, Type.Atomic);
        } else {
            return getDeItemsByType(_deItemIds, Type.Collection);
        }
    }

    // given an array of licenseIds, return the array of licenses
    function getLicenses(
        uint256[] memory _licenseIds
    ) internal view returns (Licecnse[] memory Licenses) {
        Licecnse[] memory _licenses = new Licecnse[](_licenseIds.length);
        for (uint256 i = 0; i < _licenseIds.length; i++) {
            _licenses[i] = licenses[_licenseIds[i]];
        }
        return _licenses;
    }

    function getPurchases(
        uint256[] memory _purchaseIds
    ) internal view returns (Purchase[] memory Purchases) {
        Purchase[] memory _purchases = new Purchase[](_purchaseIds.length);
        for (uint256 i = 0; i < _purchaseIds.length; i++) {
            _purchases[i] = purchases[_purchaseIds[i]];
        }
        return _purchases;
    }

    // given an array of DeItemIds and DeItemType, return the array of DeItems

    function getDeItemsByType(
        uint256[] memory _deItemIds,
        Type _assetType
    ) public view returns (DeItem[] memory DeItems) {
        DeItem[] memory _deItems = new DeItem[](_deItemIds.length);
        if (_assetType == Type.Atomic) {
            for (uint256 i = 0; i < _deItemIds.length; i++) {
                _deItems[i] = atomics[_deItemIds[i]];
            }
        } else {
            for (uint256 i = 0; i < _deItemIds.length; i++) {
                _deItems[i] = collections[_deItemIds[i]];
            }
        }
        return _deItems;
    }

    // get all atomics in the platform
    function getAllAtomics() public view returns (DeItem[] memory) {
        return atomics;
    }

    // get all collections in the platform

    function getAllCollections() public view returns (DeItem[] memory) {
        return collections;
    }

    // get all licenses in the platform
    function getAllLicenses() public view returns (Licecnse[] memory) {
        return licenses;
    }

    //owner can withdraw the funds
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // self destruct function to destroy the contract
    function destroy() public onlyOwner {
        selfdestruct(payable(owner));
    }
}