// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/access/OwnableInternal.sol";
import "../../storage/MetaTokenHooksStorage.sol";
import "../../storage/MetaRestrictionsStorage.sol";


contract TransferRestriction is OwnableInternal {
    using MetaTokenHooksStorage for MetaTokenHooksStorage.Layout;
    using MetaRestrictionsStorage for MetaRestrictionsStorage.Layout;

    bytes32 public constant RTYPE = keccak256("TransferRestriction");

    function registerHooks() external onlyOwner {
        MetaTokenHooksStorage.layout().addBeforeTokenTransferHook(address(this), TransferRestriction.beforeMetaTokenTransfer.selector);
    }


    function beforeMetaTokenTransfer(address, address, uint256 pid) external view {
        uint256[] memory ridxs = MetaRestrictionsStorage.layout().getIndexesByType(pid, RTYPE);
        require(ridxs.length == 0, "transfer restricted");
    }

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../helpers/Hooks.sol";

library MetaTokenHooksStorage {
    using Hooks for Hooks.Hook;
    using Hooks for Hooks.Hook[];

    bytes32 internal constant STORAGE_SLOT = keccak256('allianceblock.MetaNFT.core.storage.MetaTokenHooksStorage');


    struct Layout {
        Hooks.Hook[] beforeTokenTransferHooks;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function addBeforeTokenTransferHook(Layout storage l, address facet, bytes4 selector) internal {
        l.beforeTokenTransferHooks.add(facet, selector);
    }

    function removeBeforeTokenTransferHook(Layout storage l, address facet, bytes4 selector) internal {
        l.beforeTokenTransferHooks.remove(facet, selector);
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/utils/EnumerableSet.sol";
import "../../utils/EnumerableMapMod.sol";
import "../../interfaces/IMetaRestrictions.sol";

library MetaRestrictionsStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    //using EnumerableMapMod for EnumerableMapMod.Bytes32ToBytes32Map;

    bytes32 internal constant STORAGE_SLOT = keccak256('allianceblock.MetaNFT.core.storage.MetaRestrictionsStorage');

    struct TokenRestrictions {
        uint256 idxCounter;                                             // Used to give continius idxs to restrictions
        mapping(uint256=>IMetaRestrictions.Restriction) restrictions;
        mapping(bytes32=>EnumerableSet.UintSet) byProperty; //Maps property to a set of it's restrictions
        mapping(bytes32=>EnumerableSet.UintSet) byType;     //Maps restriction type to a set of restrictions with that type
    }

    struct Layout {
        mapping(uint256=>TokenRestrictions) tokenRestrictions; //Maps nftID to restrictions storage
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function getByIndex(Layout storage l, uint256 pid, uint256 idx) internal view returns(IMetaRestrictions.Restriction memory) {
        return l.tokenRestrictions[pid].restrictions[idx];
    }

    function getIndexesByProperty(Layout storage l, uint256 pid, bytes32 property) internal view returns(uint256[] memory) {
        EnumerableSet.UintSet storage idxSet = l.tokenRestrictions[pid].byProperty[property];
        uint256[] memory idxs = new uint256[](idxSet.length());
        for(uint256 i=0; i < idxs.length; i++) {
            idxs[i] = idxSet.at(i);
        }
        return idxs;
    }

    function getIndexesByType(Layout storage l, uint256 pid, bytes32 rtype) internal view returns(uint256[] memory) {
        EnumerableSet.UintSet storage idxSet = l.tokenRestrictions[pid].byType[rtype];
        uint256[] memory idxs = new uint256[](idxSet.length());
        for(uint256 i=0; i < idxs.length; i++) {
            idxs[i] = idxSet.at(i);
        }
        return idxs;
    }


    function add(Layout storage l, uint256 pid, bytes32 property, IMetaRestrictions.Restriction memory r) internal returns(uint256) {
        TokenRestrictions storage trs = l.tokenRestrictions[pid];
        uint256 idx = ++trs.idxCounter;
        trs.restrictions[idx] = r;
        trs.byProperty[property].add(idx);
        trs.byType[r.rtype].add(idx);
        return idx;
    }

    function remove(Layout storage l, uint256 pid, bytes32 property ,uint256 idx) internal {
        TokenRestrictions storage trs = l.tokenRestrictions[pid];
        delete trs.restrictions[idx];
        trs.byProperty[property].remove(idx);
        trs.byType[property].remove(idx);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Hooks {

    struct Hook {
        address target;     // Address of the facet or external contract with the hook
        bytes4 selector;    // Hook function selector
    }

    /**
     * @notice Execute a facet hook via delegatecall
     */
    function execute(Hook storage h, bytes memory data) internal {
        bytes memory dataWithSelector = bytes.concat(h.selector, data);
        (bool success, bytes memory returnData) = h.target.delegatecall(dataWithSelector);
        if(!success) assembly {
            revert(add(returnData,32), returnData) // Reverts with an error message from the returnData
        }
    }

    /**
     * @notice Execute a hook in an external contract via low-level call
     */
    function executeExternal(Hook storage h, bytes memory data) internal {
        bytes memory dataWithSelector = bytes.concat(h.selector, data);
        (bool success, bytes memory returnData) = h.target.call(dataWithSelector);
        if(!success) assembly {
            revert(add(returnData,32), returnData) // Reverts with an error message from the returnData
        }
    }

    function add(Hook[] storage hooks, address target, bytes4 selector) internal {
        //TODO revert if exists
        hooks.push(Hook({
            target: target,
            selector: selector
        }));
    }
    
    function remove(Hook[] storage hooks, address target, bytes4 selector) internal {
        //TODO revert if not exists
        for(uint256 i=0; i < hooks.length; i++) {
            Hook storage h = hooks[i];
            if( h.target==target && h.selector==selector ) {
                if(i < hooks.length - 1) {
                    hooks[i] = hooks[hooks.length - 1];
                }
                hooks.pop();
                break;
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 * @dev derived from https://github.com/solidstate-network/solidstate-solidity/blob/master/contracts/utils/EnumerableMap.sol
 */
library EnumerableMapMod {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32ToBytes32Map {
        Map _inner;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(Bytes32ToBytes32Map storage map, uint256 index)
        internal
        view
        returns (bytes32, bytes32)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (key, value);
    }

    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        address addressKey;
        assembly {
            addressKey := mload(add(key, 20))
        }
        return (addressKey, address(uint160(uint256(value))));
    }

    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, key);
    }

    function contains(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    function length(Bytes32ToBytes32Map storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(AddressToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function get(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        view
        returns (bytes32)
    {
        return _get(map._inner, key);
    }

    function get(AddressToAddressMap storage map, address key)
        internal
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        return _set(map._inner, key, value);
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, key);
    }

    function remove(AddressToAddressMap storage map, address key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        require(
            map._entries.length > index,
            'EnumerableMap: index out of bounds'
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, 'EnumerableMap: nonexistent key');
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAttachConflictResolver.sol";

interface IMetaRestrictions {

    struct Restriction {
        bytes32 rtype;
        bytes data;
    }


    function addRestriction(uint256 pid, bytes32 prop, Restriction calldata restr) external returns (uint256 idx);
    function removeRestriction(uint256 pid, bytes32 prop, uint256 ridx) external ;
    function removeRestrictions(uint256 pid, bytes32 prop, uint256[] calldata ridxs) external;
    function getRestrictions(uint256 pid, bytes32 prop) external view returns(Restriction[] memory);
    function moveRestrictions(uint256 fromPid, uint256 toPid, bytes32 prop) external returns (uint256[] memory newIdxs);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAttachConflictResolver {
    function resolveConflictAndMoveProperty(uint256 from, uint256 to, bytes32 property) external;
}